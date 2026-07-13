import type {
  Env,
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
import { deleteUserAccountData } from './account-data';
import { checkRateLimit, incrementUsage, getUsageStats } from './rate-limit';
import { proxyToHuggingFaceQuoteExtractor } from './huggingface-quote-extraction';
import {
  parseGeminiRequest,
  proxyToGemini,
  RequestValidationError,
} from './gemini-proxy';

// CORS headers for iOS app
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Expose-Headers': SESSION_TOKEN_HEADER,
};

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

    // Account deletion (Guideline 5.1.1) — removes server-side account/subscription cache.
    if (path === '/api/auth/account' && request.method === 'DELETE') {
      try {
        await deleteUserAccountData(userId, env);
        return jsonResponse({ success: true, message: 'Account data deleted' });
      } catch (error) {
        console.error('Account deletion error:', error);
        return errorResponse('Failed to delete account data', 'ACCOUNT_DELETE_FAILED', 500);
      }
    }

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
          env,
          CORS_HEADERS
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
          env,
          CORS_HEADERS
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
