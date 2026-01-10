import type { Env, GeminiRequest, ErrorResponse, UsageResponse } from './types';
import { validateSessionToken, validateAppleToken, createSessionToken } from './auth';
import { hasActiveSubscription, handleAppStoreNotification, getSubscription, createTrialSubscription } from './subscription';
import { checkRateLimit, incrementUsage, getUsageStats } from './rate-limit';

// Gemini API base URL
const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';

// CORS headers for iOS app
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
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

      // Check if user has subscription, create trial if new
      let subscription = await getSubscription(userId, env);
      if (!subscription) {
        subscription = await createTrialSubscription(userId, env);
      }

      // Create session token
      const sessionToken = await createSessionToken(userId, env);

      return jsonResponse({
        token: sessionToken,
        subscription: {
          status: subscription.status,
          expiresAt: subscription.expiresAt,
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

    // Check subscription status
    const hasSubscription = await hasActiveSubscription(userId, env);
    if (!hasSubscription) {
      return errorResponse(
        'Active subscription required',
        'SUBSCRIPTION_REQUIRED',
        402,
        'Please subscribe to use this feature'
      );
    }

    // Usage stats endpoint
    if (path === '/api/usage' && request.method === 'GET') {
      const stats = await getUsageStats(userId, env);
      const subscription = await getSubscription(userId, env);

      const response: UsageResponse = {
        extractionsThisMonth: stats.extractionsThisMonth,
        extractionsLimit: stats.extractionsLimit,
        subscriptionStatus: subscription?.status || 'unknown',
        expiresAt: subscription?.expiresAt,
      };

      return jsonResponse(response);
    }

    // Book cover metadata extraction
    if (path === '/api/extract-cover' && request.method === 'POST') {
      // Check rate limit
      const rateCheck = await checkRateLimit(userId, env);
      if (!rateCheck.allowed) {
        return errorResponse(
          rateCheck.reason || 'Rate limit exceeded',
          'RATE_LIMIT',
          429
        );
      }

      try {
        const body = (await request.json()) as GeminiRequest;

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

        return response;
      } catch (error) {
        console.error('Cover extraction error:', error);
        return errorResponse('Extraction failed', 'EXTRACTION_ERROR', 500);
      }
    }

    // Quote extraction
    if (path === '/api/extract-quotes' && request.method === 'POST') {
      // Check rate limit
      const rateCheck = await checkRateLimit(userId, env);
      if (!rateCheck.allowed) {
        return errorResponse(
          rateCheck.reason || 'Rate limit exceeded',
          'RATE_LIMIT',
          429
        );
      }

      try {
        const body = (await request.json()) as GeminiRequest;

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

        return response;
      } catch (error) {
        console.error('Quote extraction error:', error);
        return errorResponse('Extraction failed', 'EXTRACTION_ERROR', 500);
      }
    }

    // 404 for unknown routes
    return errorResponse('Not found', 'NOT_FOUND', 404);
  },
};
