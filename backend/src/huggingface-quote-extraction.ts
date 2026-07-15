import type { GeminiRequest } from './types';

const HUGGING_FACE_ROUTER_URL = 'https://router.huggingface.co/v1/chat/completions';
export const DEFAULT_HUGGING_FACE_MODEL_ID = 'Qwen/Qwen2.5-VL-72B-Instruct:hf-inference';
const MAXIMUM_RESPONSE_BYTES = 128 * 1024;
const MAXIMUM_CANDIDATE_COUNT = 30;
const MAXIMUM_QUOTE_LENGTH = 2_000;
const MAXIMUM_MARGIN_NOTE_LENGTH = 500;
const MAXIMUM_MARKING_TYPE_LENGTH = 64;
const MAXIMUM_PROCESSING_NOTES_LENGTH = 500;
const MAXIMUM_PAGE_NUMBER = 10_000;

// Changes to this list require a privacy and retention review before deployment.
const APPROVED_HUGGING_FACE_PROVIDERS = new Set(['hf-inference']);

const QUOTE_EXTRACTION_SYSTEM_PROMPT = [
  'You extract marked passages from photographed book pages.',
  'Identify only text indicated by underlines, highlights, brackets, or vertical margin marks.',
  'Return strict JSON with keys: quotes, pageNumber, processingNotes.',
  'Each quote must include text, markingType, confidence, and optional pageNumber or marginNote.',
  'Do not invent text. If no marked passage is readable, return {"quotes":[]}.',
].join(' ');

export interface HuggingFaceQuoteConfig {
  modelId?: string;
}

export interface HuggingFaceProxyConfig extends HuggingFaceQuoteConfig {
    token: string;
}

/**
 * Reject policy suffixes such as `:preferred` and `:fastest` so an operator
 * cannot silently broaden the list of third parties that receive book images.
 */
export function resolveApprovedHuggingFaceModelId(modelId?: string): string | null {
  const candidate = modelId ?? DEFAULT_HUGGING_FACE_MODEL_ID;
  const separator = candidate.lastIndexOf(':');
  if (separator <= 0 || separator === candidate.length - 1) {
    return null;
  }

  const provider = candidate.slice(separator + 1);
  return APPROVED_HUGGING_FACE_PROVIDERS.has(provider) ? candidate : null;
}

interface HuggingFaceMessageContentText {
  type: 'text';
  text: string;
}

interface HuggingFaceMessageContentImage {
  type: 'image_url';
  image_url: {
    url: string;
  };
}

type HuggingFaceMessageContent =
  | string
  | Array<HuggingFaceMessageContentText | HuggingFaceMessageContentImage>;

interface HuggingFaceMessage {
  role: 'system' | 'user';
  content: HuggingFaceMessageContent;
}

interface HuggingFaceChatCompletionRequest {
  model: string;
  messages: HuggingFaceMessage[];
  temperature: number;
  max_tokens: number;
  response_format: {
    type: 'json_object';
  };
}

interface HuggingFaceChatCompletionResponse {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
}

interface NormalizedQuoteCandidate {
  text: string;
  markingType: string;
  pageNumber?: number;
  marginNote?: string;
  confidence?: number;
}

interface NormalizedQuoteExtractionResult {
  quotes: NormalizedQuoteCandidate[];
  pageNumber?: number;
  processingNotes?: string;
}

export function buildHuggingFaceQuoteRequest(
  request: GeminiRequest,
  config: HuggingFaceQuoteConfig = {}
): HuggingFaceChatCompletionRequest {
  const { prompt, image } = extractPromptAndImage(request);

  return {
    model: config.modelId ?? DEFAULT_HUGGING_FACE_MODEL_ID,
    temperature: 0.1,
    max_tokens: 4096,
    response_format: { type: 'json_object' },
    messages: [
      {
        role: 'system',
        content: QUOTE_EXTRACTION_SYSTEM_PROMPT,
      },
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: prompt,
          },
          {
            type: 'image_url',
            image_url: {
              url: `data:${image.mimeType};base64,${image.data}`,
            },
          },
        ],
      },
    ],
  };
}

export async function proxyToHuggingFaceQuoteExtractor(
  request: GeminiRequest,
  config: HuggingFaceProxyConfig
): Promise<Response> {
  const response = await fetch(HUGGING_FACE_ROUTER_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(buildHuggingFaceQuoteRequest(request, config)),
  });

  return normalizeHuggingFaceQuoteResponse(response);
}

export async function normalizeHuggingFaceQuoteResponse(response: Response): Promise<Response> {
  const responseText = await response.text();

  if (!response.ok) {
    return new Response(responseText, {
      status: response.status,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  let completion: HuggingFaceChatCompletionResponse;
  try {
    completion = JSON.parse(responseText) as HuggingFaceChatCompletionResponse;
  } catch {
    return invalidHuggingFaceResponse('Malformed Hugging Face response');
  }

  const content = completion.choices?.[0]?.message?.content?.trim();
  if (!content) {
    return invalidHuggingFaceResponse('No content in Hugging Face response');
  }

  const normalizedContent = normalizeQuoteExtractionContent(content);
  if (!normalizedContent) {
    return invalidHuggingFaceResponse('Invalid quote extraction result');
  }

  return new Response(JSON.stringify({
    candidates: [
      {
        content: {
          parts: [
            { text: normalizedContent },
          ],
        },
        finishReason: 'STOP',
      },
    ],
  }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

/**
 * Keep the provider boundary aligned with QuoteExtractionResult.parse so a
 * syntactically successful model reply cannot be charged if the app cannot use it.
 */
function normalizeQuoteExtractionContent(content: string): string | null {
  if (new TextEncoder().encode(content).byteLength > MAXIMUM_RESPONSE_BYTES) {
    return null;
  }

  let rawResult: unknown;
  try {
    rawResult = JSON.parse(removeMarkdownFence(content));
  } catch {
    return null;
  }

  if (!isRecord(rawResult) || !Array.isArray(rawResult.quotes)
    || rawResult.quotes.length > MAXIMUM_CANDIDATE_COUNT) {
    return null;
  }

  const quotes = rawResult.quotes.flatMap((candidate) => {
    const normalized = normalizeQuoteCandidate(candidate);
    return normalized ? [normalized] : [];
  });
  if (rawResult.quotes.length > 0 && quotes.length === 0) {
    return null;
  }

  const result: NormalizedQuoteExtractionResult = { quotes };
  const pageNumber = normalizePageNumber(rawResult.pageNumber);
  if (pageNumber !== undefined) {
    result.pageNumber = pageNumber;
  }

  const processingNotes = normalizeOptionalText(
    rawResult.processingNotes,
    MAXIMUM_PROCESSING_NOTES_LENGTH
  );
  if (processingNotes !== undefined) {
    result.processingNotes = processingNotes;
  }

  return JSON.stringify(result);
}

function normalizeQuoteCandidate(value: unknown): NormalizedQuoteCandidate | null {
  if (!isRecord(value)) {
    return null;
  }

  const text = normalizeRequiredText(value.text, MAXIMUM_QUOTE_LENGTH);
  if (!text) {
    return null;
  }

  const candidate: NormalizedQuoteCandidate = {
    text,
    markingType: normalizeMarkingType(value.markingType),
  };
  const pageNumber = normalizePageNumber(value.pageNumber);
  if (pageNumber !== undefined) {
    candidate.pageNumber = pageNumber;
  }

  const marginNote = normalizeOptionalText(value.marginNote, MAXIMUM_MARGIN_NOTE_LENGTH);
  if (marginNote !== undefined) {
    candidate.marginNote = marginNote;
  }

  const confidence = normalizeConfidence(value.confidence);
  if (confidence !== undefined) {
    candidate.confidence = confidence;
  }

  return candidate;
}

function removeMarkdownFence(content: string): string {
  let cleaned = content.trim();
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.slice(7);
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.slice(3);
  }
  if (cleaned.endsWith('```')) {
    cleaned = cleaned.slice(0, -3);
  }
  return cleaned.trim();
}

function normalizeRequiredText(value: unknown, maximumLength: number): string | undefined {
  return normalizeOptionalText(value, maximumLength);
}

function normalizeOptionalText(value: unknown, maximumLength: number): string | undefined {
  if (typeof value !== 'string') {
    return undefined;
  }

  const normalized = value
    .replace(/\p{Cc}/gu, ' ')
    .trim()
    .split(/\s+/u)
    .filter(Boolean)
    .join(' ');
  return normalized && [...normalized].length <= maximumLength ? normalized : undefined;
}

function normalizePageNumber(value: unknown): number | undefined {
  return typeof value === 'number'
    && Number.isSafeInteger(value)
    && value >= 1
    && value <= MAXIMUM_PAGE_NUMBER
    ? value
    : undefined;
}

function normalizeConfidence(value: unknown): number | undefined {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return undefined;
  }
  return Math.min(Math.max(value, 0), 1);
}

function normalizeMarkingType(value: unknown): string {
  if (typeof value !== 'string') {
    return 'mixed';
  }

  let normalized = '';
  let needsSeparator = false;
  for (const character of value.toLowerCase()) {
    if (/^[a-z0-9]$/.test(character)) {
      if (needsSeparator && normalized) {
        normalized += '_';
      }
      normalized += character;
      needsSeparator = false;
    } else {
      needsSeparator = Boolean(normalized);
    }
  }

  return normalized.slice(0, MAXIMUM_MARKING_TYPE_LENGTH) || 'mixed';
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function extractPromptAndImage(request: GeminiRequest): {
  prompt: string;
  image: { mimeType: string; data: string };
} {
  const parts = request.contents[0]?.parts ?? [];
  const prompt = parts.find((part) => part.text !== undefined)?.text;
  const image = parts.find((part) => part.inlineData !== undefined)?.inlineData;

  if (!prompt || !image) {
    throw new Error('Request must include one prompt and one image');
  }

  return { prompt, image };
}

function invalidHuggingFaceResponse(message: string): Response {
  return new Response(JSON.stringify({
    error: message,
    code: 'HF_INVALID_RESPONSE',
  }), {
    status: 502,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}
