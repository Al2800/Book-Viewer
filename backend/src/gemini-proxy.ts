import type { Env, GeminiRequest } from './types';

const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';
const MAX_REQUEST_BYTES = 7_000_000;
const MAX_PROMPT_CHARS = 12_000;
const MAX_INLINE_IMAGE_BYTES = 4_500_000;
const FIXED_GENERATION_CONFIG = {
  temperature: 0.1,
  maxOutputTokens: 4096,
  responseMimeType: 'application/json',
};

export class RequestValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RequestValidationError';
  }
}

function estimateBase64Bytes(base64: string): number {
  const normalized = base64.trim();
  const padding =
    normalized.endsWith('==') ? 2 : normalized.endsWith('=') ? 1 : 0;
  return Math.floor((normalized.length * 3) / 4) - padding;
}

export function sanitizeGeminiRequestPayload(body: unknown): GeminiRequest {
  if (!body || typeof body !== 'object') {
    throw new RequestValidationError('Invalid request body');
  }

  const rawContents = (body as GeminiRequest).contents;
  if (!Array.isArray(rawContents) || rawContents.length !== 1) {
    throw new RequestValidationError('Exactly one content payload is required');
  }

  const rawParts = rawContents[0]?.parts;
  if (!Array.isArray(rawParts) || rawParts.length === 0 || rawParts.length > 2) {
    throw new RequestValidationError('Request must contain one prompt and one image');
  }

  let promptText: string | undefined;
  let inlineData: { mimeType: string; data: string } | undefined;

  for (const part of rawParts) {
    if (part?.text !== undefined) {
      if (promptText !== undefined) {
        throw new RequestValidationError('Only one prompt is allowed');
      }

      if (typeof part.text !== 'string') {
        throw new RequestValidationError('Prompt must be a string');
      }

      const trimmed = part.text.trim();
      if (!trimmed) {
        throw new RequestValidationError('Prompt is required');
      }

      if (trimmed.length > MAX_PROMPT_CHARS) {
        throw new RequestValidationError('Prompt exceeds maximum length');
      }

      promptText = trimmed;
    }

    if (part?.inlineData !== undefined) {
      if (inlineData !== undefined) {
        throw new RequestValidationError('Only one image is allowed');
      }

      const candidate = part.inlineData;
      if (
        !candidate
        || typeof candidate.mimeType !== 'string'
        || typeof candidate.data !== 'string'
      ) {
        throw new RequestValidationError('Image payload is invalid');
      }

      if (!['image/jpeg', 'image/png'].includes(candidate.mimeType)) {
        throw new RequestValidationError('Unsupported image format');
      }

      const estimatedBytes = estimateBase64Bytes(candidate.data);
      if (!Number.isFinite(estimatedBytes) || estimatedBytes <= 0) {
        throw new RequestValidationError('Image payload is invalid');
      }

      if (estimatedBytes > MAX_INLINE_IMAGE_BYTES) {
        throw new RequestValidationError('Image payload exceeds maximum size');
      }

      inlineData = {
        mimeType: candidate.mimeType,
        data: candidate.data,
      };
    }
  }

  if (!promptText || !inlineData) {
    throw new RequestValidationError('Request must include one prompt and one image');
  }

  return {
    contents: [
      {
        parts: [
          { text: promptText },
          { inlineData },
        ],
      },
    ],
    generationConfig: FIXED_GENERATION_CONFIG,
  };
}

export async function parseGeminiRequest(request: Request): Promise<GeminiRequest> {
  const declaredLength = request.headers.get('Content-Length');
  if (declaredLength) {
    const parsedLength = Number.parseInt(declaredLength, 10);
    if (Number.isFinite(parsedLength) && parsedLength > MAX_REQUEST_BYTES) {
      throw new RequestValidationError('Request body exceeds maximum size');
    }
  }

  const rawBody = await request.text();
  if (rawBody.length > MAX_REQUEST_BYTES) {
    throw new RequestValidationError('Request body exceeds maximum size');
  }

  let parsedBody: unknown;
  try {
    parsedBody = JSON.parse(rawBody);
  } catch {
    throw new RequestValidationError('Malformed JSON body');
  }

  return sanitizeGeminiRequestPayload(parsedBody);
}

export async function proxyToGemini(
  endpoint: string,
  body: GeminiRequest,
  env: Env,
  responseHeaders: HeadersInit
): Promise<Response> {
  const url = `${GEMINI_API_BASE}${endpoint}?key=${env.GEMINI_API_KEY}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const responseBody = await response.text();
  return new Response(responseBody, {
    status: response.status,
    headers: {
      'Content-Type': 'application/json',
      ...responseHeaders,
    },
  });
}
