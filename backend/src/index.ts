import type {
  Env,
  ErrorResponse,
  UsageResponse,
  SubscriptionSyncRequest,
} from './types';
import {
  validateSession,
  validateAppleToken,
  createSessionToken,
  isSessionCurrent,
  revokeAllSessions,
  SESSION_TOKEN_HEADER,
  type ValidatedSession,
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
import {
  completeExtraction,
  getUsageStats,
  releaseExtractionReservation,
  reserveExtraction,
  type RateLimitDecision,
} from './rate-limit';
import {
  proxyToHuggingFaceQuoteExtractor,
  resolveApprovedHuggingFaceModelId,
} from './huggingface-quote-extraction';
import {
  parseGeminiRequest,
  proxyToGemini,
  RequestValidationError,
} from './gemini-proxy';

// CORS headers for iOS app
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Idempotency-Key',
  'Access-Control-Expose-Headers': SESSION_TOKEN_HEADER,
};

export { ExtractionRateLimiter } from './extraction-rate-limiter';

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
  session: ValidatedSession,
  env: Env
): Promise<Response> {
  try {
    // Use the request's verified revision, rather than the latest revision in
    // storage, so a concurrent account deletion can never mint a new session.
    const token = await createSessionToken(session.userId, env, session.version);
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

function logRateLimitDecision(path: string, decision: RateLimitDecision): void {
  // Keep operations observable without emitting image data, prompts, account IDs, or IP addresses.
  console.log(JSON.stringify({
    event: 'extraction_rate_limit',
    path,
    outcome: decision.allowed ? 'reserved' : 'rejected',
    code: decision.code ?? 'ALLOWED',
  }));
}

function rateLimitResponse(decision: RateLimitDecision): Response {
  const status = decision.code === 'IDEMPOTENCY_INVALID'
    ? 400
    : decision.code === 'IDEMPOTENCY_REPLAY' || decision.code === 'IDEMPOTENCY_IN_PROGRESS'
      ? 409
      : 429;
  return errorResponse(
    decision.reason || 'Rate limit exceeded',
    decision.code || 'RATE_LIMIT',
    status
  );
}

async function releaseFailedExtraction(
  userId: string,
  idempotencyKey: string,
  env: Env,
  path: string
): Promise<void> {
  try {
    await releaseExtractionReservation(userId, idempotencyKey, env);
    console.log(JSON.stringify({
      event: 'extraction_usage',
      path,
      outcome: 'released',
    }));
  } catch {
    // The reservation expires automatically, so a limiter outage cannot create a permanent charge.
    console.error(JSON.stringify({
      event: 'extraction_usage',
      path,
      outcome: 'release_deferred',
    }));
  }
}

async function completeSuccessfulExtraction(
  userId: string,
  idempotencyKey: string,
  env: Env,
  path: string
): Promise<boolean> {
  try {
    await completeExtraction(userId, idempotencyKey, env);
    console.log(JSON.stringify({
      event: 'extraction_usage',
      path,
      outcome: 'charged',
    }));
    return true;
  } catch {
    console.error(JSON.stringify({
      event: 'extraction_usage',
      path,
      outcome: 'charge_failed',
    }));
    return false;
  }
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

    // Quote pages are only sent through the explicitly approved Hugging Face route.
    // Retire the legacy Gemini endpoint before parsing or forwarding a page image.
    if (path === '/api/extract-quotes' && request.method === 'POST') {
      return errorResponse(
        'This quote extraction route is no longer available. Update BookQuotes to continue.',
        'QUOTE_EXTRACTION_ROUTE_RETIRED',
        410
      );
    }

    // All other API routes require authentication
    const authHeader = request.headers.get('Authorization');
    const session = await validateSession(authHeader, env);

    if (!session) {
      return errorResponse('Authentication required', 'AUTH_REQUIRED', 401);
    }

    const userId = session.userId;

    const revokedSessionResponse = async (): Promise<Response | null> => {
      try {
        if (await isSessionCurrent(session, env)) {
          return null;
        }
        return errorResponse('Session is no longer active', 'AUTH_SESSION_REVOKED', 401);
      } catch (error) {
        console.error('Session revision check failed:', error);
        return errorResponse('Session verification is temporarily unavailable', 'AUTH_SESSION_CHECK_FAILED', 503);
      }
    };

    const respond = async (response: Response): Promise<Response> => {
      const revoked = await revokedSessionResponse();
      if (revoked) {
        return revoked;
      }

      const refreshed = await withSessionRefresh(response, session, env);
      // Deletion can happen while the refresh token is being minted. The token
      // is still tied to the old revision, but do not return stale response data.
      return (await revokedSessionResponse()) ?? refreshed;
    };

    // Account deletion (Guideline 5.1.1) — removes server-side account/subscription cache.
    if (path === '/api/auth/account' && request.method === 'DELETE') {
      try {
        await revokeAllSessions(userId, env);
        await deleteUserAccountData(userId, env);
        return jsonResponse({ success: true, message: 'Account data deleted' });
      } catch (error) {
        console.error('Account deletion error:', error);
        return errorResponse('Failed to delete account data', 'ACCOUNT_DELETE_FAILED', 500);
      }
    }

    // Usage stats endpoint
    if (path === '/api/usage' && request.method === 'GET') {
      const revoked = await revokedSessionResponse();
      if (revoked) {
        return revoked;
      }
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
        const revoked = await revokedSessionResponse();
        if (revoked) {
          return revoked;
        }
        const body = (await request.json()) as SubscriptionSyncRequest;
        const currentSession = await revokedSessionResponse();
        if (currentSession) {
          return currentSession;
        }
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
    const revoked = await revokedSessionResponse();
    if (revoked) {
      return revoked;
    }
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
      const idempotencyKey = request.headers.get('Idempotency-Key');

      let rateCheck: RateLimitDecision;
      try {
        rateCheck = await reserveExtraction(userId, clientKey, idempotencyKey, env);
      } catch {
        return respond(errorResponse(
          'Extraction limits are temporarily unavailable',
          'RATE_LIMIT_UNAVAILABLE',
          503
        ));
      }
      logRateLimitDecision(path, rateCheck);
      if (!rateCheck.allowed) {
        return respond(rateLimitResponse(rateCheck));
      }

      try {
        const body = await parseGeminiRequest(request);
        const revoked = await revokedSessionResponse();
        if (revoked) {
          await releaseFailedExtraction(userId, idempotencyKey!, env, path);
          return revoked;
        }

        // Proxy to Gemini
        const response = await proxyToGemini(
          '/models/gemini-2.0-flash:generateContent',
          body,
          env,
          CORS_HEADERS
        );

        if (response.ok) {
          if (!await completeSuccessfulExtraction(userId, idempotencyKey!, env, path)) {
            return respond(errorResponse(
              'Extraction completed but usage could not be recorded. Please retry with the same request key.',
              'RATE_LIMIT_UNAVAILABLE',
              503
            ));
          }
        } else {
          await releaseFailedExtraction(userId, idempotencyKey!, env, path);
        }

        return respond(response);
      } catch (error) {
        await releaseFailedExtraction(userId, idempotencyKey!, env, path);
        if (error instanceof RequestValidationError) {
          return respond(errorResponse(error.message, 'INVALID_REQUEST', 400));
        }
        console.error('Cover extraction error:', error);
        return respond(errorResponse('Extraction failed', 'EXTRACTION_ERROR', 500));
      }
    }

    // Model-assisted quote extraction through Hugging Face.
    if (path === '/api/extract-quotes-hf' && request.method === 'POST') {
      const clientKey = getClientKey(request, userId);
      const idempotencyKey = request.headers.get('Idempotency-Key');

      if (!env.HF_API_TOKEN) {
        return respond(errorResponse(
          'Hugging Face extraction is not configured',
          'HF_NOT_CONFIGURED',
          503
        ));
      }

      const modelId = resolveApprovedHuggingFaceModelId(env.HF_MODEL_ID);
      if (!modelId) {
        return respond(errorResponse(
          'Hugging Face extraction provider is not approved',
          'HF_PROVIDER_NOT_APPROVED',
          503
        ));
      }

      let rateCheck: RateLimitDecision;
      try {
        rateCheck = await reserveExtraction(userId, clientKey, idempotencyKey, env);
      } catch {
        return respond(errorResponse(
          'Extraction limits are temporarily unavailable',
          'RATE_LIMIT_UNAVAILABLE',
          503
        ));
      }
      logRateLimitDecision(path, rateCheck);
      if (!rateCheck.allowed) {
        return respond(rateLimitResponse(rateCheck));
      }

      try {
        const body = await parseGeminiRequest(request);
        const revoked = await revokedSessionResponse();
        if (revoked) {
          await releaseFailedExtraction(userId, idempotencyKey!, env, path);
          return revoked;
        }
        const response = await proxyToHuggingFaceQuoteExtractor(body, {
          token: env.HF_API_TOKEN,
          modelId,
        });

        if (response.ok) {
          if (!await completeSuccessfulExtraction(userId, idempotencyKey!, env, path)) {
            return respond(errorResponse(
              'Extraction completed but usage could not be recorded. Please retry with the same request key.',
              'RATE_LIMIT_UNAVAILABLE',
              503
            ));
          }
        } else {
          await releaseFailedExtraction(userId, idempotencyKey!, env, path);
        }

        return respond(new Response(await response.text(), {
          status: response.status,
          headers: {
            'Content-Type': 'application/json',
            ...CORS_HEADERS,
          },
        }));
      } catch (error) {
        await releaseFailedExtraction(userId, idempotencyKey!, env, path);
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
