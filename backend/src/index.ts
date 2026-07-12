import type {
  Env,
  GeminiRequest,
  ErrorResponse,
  UsageResponse,
  SubscriptionSyncRequest,
} from './types';
import {
  validateSessionToken,
  validateAppleToken,
  createSessionToken,
  SESSION_TOKEN_HEADER,
} from './auth';
import {
  getSubscription,
  handleAppStoreNotification,
  hasActiveSubscription,
  reconcileSubscription,
  rememberUserAppAccountToken,
  toClientSubscriptionStatus,
} from './subscription';
import { checkRateLimit, incrementUsage, getUsageStats } from './rate-limit';
import { proxyToHuggingFaceQuoteExtractor } from './huggingface-quote-extraction';

// Gemini API base URL
const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';

// CORS headers for iOS app
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Expose-Headers': SESSION_TOKEN_HEADER,
};

const MAX_REQUEST_BYTES = 7_000_000;
const MAX_PROMPT_CHARS = 12_000;
const MAX_INLINE_IMAGE_BYTES = 4_500_000;
const FIXED_GENERATION_CONFIG = {
  temperature: 0.1,
  maxOutputTokens: 4096,
  responseMimeType: 'application/json',
};

class RequestValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RequestValidationError';
  }
}

/**
 * Create JSON response with CORS headers
 */
function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}

/**
 * Attach a freshly minted session JWT so active clients slide their 7-day expiry.
 */
async function withSessionRefresh(
  response: Response,
  userId: string,
  env: Env
): Promise<Response> {
  try {
    const token = await createSessionToken(userId, env);
    const headers = new Headers(response.headers);
    headers.set(SESSION_TOKEN_HEADER, token);
    headers.set('Access-Control-Expose-Headers', SESSION_TOKEN_HEADER);
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  } catch (error) {
    console.error('Failed to mint refreshed session token:', error);
    return response;
  }
}

/**
 * Create error response
 */
function errorResponse(error: string, code: string, status: number, details?: string): Response {
  const body: ErrorResponse = { error, code, details };
  return jsonResponse(body, status);
}

/**
 * Handle CORS preflight requests
 */
function handleOptions(): Response {
  return new Response(null, {
    status: 204,
    headers: CORS_HEADERS,
  });
}

function getClientKey(request: Request, userId: string): string {
  const forwardedIp = request.headers.get('CF-Connecting-IP')
    ?? request.headers.get('X-Forwarded-For')?.split(',')[0]?.trim();

  if (forwardedIp && forwardedIp.length > 0) {
    return forwardedIp;
  }

  return `user:${userId}`;
}

function allowsAuthenticatedExtraction(env: Env): boolean {
  return env.ALLOW_AUTHENTICATED_EXTRACTION === 'true';
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

async function parseGeminiRequest(request: Request): Promise<GeminiRequest> {
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

/**
 * Proxy request to Gemini API
 */
async function proxyToGemini(
  endpoint: string,
  body: GeminiRequest,
  env: Env
): Promise<Response> {
  const url = `${GEMINI_API_BASE}${endpoint}?key=${env.GEMINI_API_KEY}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  // Pass through Gemini response with CORS headers
  const responseBody = await response.text();
  return new Response(responseBody, {
    status: response.status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}

/**
 * Main request handler
 */
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return handleOptions();
    }

    // Health check endpoint
    if (path === '/health' || path === '/') {
      return jsonResponse({ status: 'ok', version: '1.0.0' });
    }

    // Apple Sign-In - exchange Apple token for session token
    if (path === '/api/auth/apple' && request.method === 'POST') {
      const authHeader = request.headers.get('Authorization');
      const userId = await validateAppleToken(authHeader, env);

      if (!userId) {
        return errorResponse('Invalid Apple token', 'AUTH_INVALID', 401);
      }

      const subscription = await getSubscription(userId, env);
      await rememberUserAppAccountToken(userId, env);

      // Create session token
      const sessionToken = await createSessionToken(userId, env);

      return jsonResponse({
        token: sessionToken,
        subscription: {
          status: toClientSubscriptionStatus(subscription),
          expiresAt: subscription?.gracePeriodExpiresAt ?? subscription?.expiresAt,
        },
      });
    }

    // App Store Server Notification webhook
    if (path === '/api/subscription-webhook' && request.method === 'POST') {
      try {
        const body = await request.text();
        const result = await handleAppStoreNotification(body, env);
        return jsonResponse(result);
      } catch (error) {
        console.error('Webhook error:', error);
        return errorResponse('Webhook processing failed', 'WEBHOOK_ERROR', 500);
      }
    }

    // All other API routes require authentication
    const authHeader = request.headers.get('Authorization');
    const userId = await validateSessionToken(authHeader, env);

    if (!userId) {
      return errorResponse('Authentication required', 'AUTH_REQUIRED', 401);
    }

    const respond = (response: Response) => withSessionRefresh(response, userId, env);

    // Usage stats endpoint
    if (path === '/api/usage' && request.method === 'GET') {
      const stats = await getUsageStats(userId, env);
      const subscription = await getSubscription(userId, env);

      const response: UsageResponse = {
        extractionsThisMonth: stats.extractionsThisMonth,
        extractionsLimit: stats.extractionsLimit,
        subscriptionStatus: toClientSubscriptionStatus(subscription),
        expiresAt: subscription?.gracePeriodExpiresAt ?? subscription?.expiresAt,
      };

      return respond(jsonResponse(response));
    }

    if (path === '/api/subscription/sync' && request.method === 'POST') {
      try {
        const body = (await request.json()) as SubscriptionSyncRequest;
        const syncResponse = await reconcileSubscription(userId, body, env);
        return respond(jsonResponse(syncResponse));
      } catch (error) {
        console.error('Subscription sync error:', error);
        return respond(errorResponse(
          'Failed to verify subscription with App Store',
          'SUBSCRIPTION_SYNC_FAILED',
          500
        ));
      }
    }

    // Check subscription status
    const hasSubscription = await hasActiveSubscription(userId, env);
    if (!hasSubscription && !allowsAuthenticatedExtraction(env)) {
      return respond(errorResponse(
        'Active subscription required',
        'SUBSCRIPTION_REQUIRED',
        402,
        'Please subscribe to use this feature'
      ));
    }

    // Book cover metadata extraction
    if (path === '/api/extract-cover' && request.method === 'POST') {
      const clientKey = getClientKey(request, userId);

      // Check rate limit
      const rateCheck = await checkRateLimit(userId, env, clientKey);
      if (!rateCheck.allowed) {
        return respond(errorResponse(
          rateCheck.reason || 'Rate limit exceeded',
          'RATE_LIMIT',
          429
        ));
      }

      try {
        const body = await parseGeminiRequest(request);

        // Proxy to Gemini
        const response = await proxyToGemini(
          '/models/gemini-2.0-flash:generateContent',
          body,
          env
        );

        // Track usage on success
        if (response.ok) {
          await incrementUsage(userId, env);
        }

        return respond(response);
      } catch (error) {
        if (error instanceof RequestValidationError) {
          return respond(errorResponse(error.message, 'INVALID_REQUEST', 400));
        }
        console.error('Cover extraction error:', error);
        return respond(errorResponse('Extraction failed', 'EXTRACTION_ERROR', 500));
      }
    }

    // Quote extraction
    if (path === '/api/extract-quotes' && request.method === 'POST') {
      const clientKey = getClientKey(request, userId);

      // Check rate limit
      const rateCheck = await checkRateLimit(userId, env, clientKey);
      if (!rateCheck.allowed) {
        return respond(errorResponse(
          rateCheck.reason || 'Rate limit exceeded',
          'RATE_LIMIT',
          429
        ));
      }

      try {
        const body = await parseGeminiRequest(request);

        // Proxy to Gemini
        const response = await proxyToGemini(
          '/models/gemini-2.0-flash:generateContent',
          body,
          env
        );

        // Track usage on success
        if (response.ok) {
          await incrementUsage(userId, env);
        }

        return respond(response);
      } catch (error) {
        if (error instanceof RequestValidationError) {
          return respond(errorResponse(error.message, 'INVALID_REQUEST', 400));
        }
        console.error('Quote extraction error:', error);
        return respond(errorResponse('Extraction failed', 'EXTRACTION_ERROR', 500));
      }
    }

    // Model-assisted quote extraction through Hugging Face.
    if (path === '/api/extract-quotes-hf' && request.method === 'POST') {
      const clientKey = getClientKey(request, userId);

      const rateCheck = await checkRateLimit(userId, env, clientKey);
      if (!rateCheck.allowed) {
        return respond(errorResponse(
          rateCheck.reason || 'Rate limit exceeded',
          'RATE_LIMIT',
          429
        ));
      }

      if (!env.HF_API_TOKEN) {
        return respond(errorResponse(
          'Hugging Face extraction is not configured',
          'HF_NOT_CONFIGURED',
          503
        ));
      }

      try {
        const body = await parseGeminiRequest(request);
        const response = await proxyToHuggingFaceQuoteExtractor(body, {
          token: env.HF_API_TOKEN,
          modelId: env.HF_MODEL_ID,
        });

        if (response.ok) {
          await incrementUsage(userId, env);
        }

        return respond(new Response(await response.text(), {
          status: response.status,
          headers: {
            'Content-Type': 'application/json',
            ...CORS_HEADERS,
          },
        }));
      } catch (error) {
        if (error instanceof RequestValidationError) {
          return respond(errorResponse(error.message, 'INVALID_REQUEST', 400));
        }
        console.error('Hugging Face quote extraction error:', error);
        return respond(errorResponse('Model-assisted extraction failed', 'HF_EXTRACTION_ERROR', 500));
      }
    }

    // 404 for unknown routes
    return respond(errorResponse('Not found', 'NOT_FOUND', 404));
  },
};
