import type { Env, RateLimitConfig } from './types';

const DEFAULT_LIMITS: RateLimitConfig = {
  maxRequestsPerMinute: 30,
  maxRequestsPerIPPerMinute: 120,
  maxExtractionsPerMonth: 1000,
};

export interface RateLimitDecision {
  allowed: boolean;
  code?: 'RATE_LIMIT' | 'IDEMPOTENCY_INVALID' | 'IDEMPOTENCY_REPLAY' | 'IDEMPOTENCY_IN_PROGRESS';
  reason?: string;
  currentUsage: number;
  limit: number;
}

interface LimiterRequest {
  action: 'reserve-user' | 'reserve-ip' | 'complete' | 'release' | 'usage' | 'delete-user';
  userId?: string;
  idempotencyKey?: string;
  limits?: RateLimitConfig;
}

interface LimiterResponse {
  allowed?: boolean;
  code?: RateLimitDecision['code'];
  reason?: string;
  currentUsage?: number;
  limit?: number;
  extractionsThisMonth?: number;
  extractionsLimit?: number;
  resetDate?: string;
}

function getResetDate(): string {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)).toISOString();
}

function isValidIdempotencyKey(value: string | null): value is string {
  return value !== null
    && value.length >= 16
    && value.length <= 128
    && /^[A-Za-z0-9_-]+$/.test(value);
}

function limiterStub(env: Env, scope: string): DurableObjectStub {
  return env.EXTRACTION_LIMITER.get(env.EXTRACTION_LIMITER.idFromName(scope));
}

async function limiterRequest(
  env: Env,
  scope: string,
  body: LimiterRequest
): Promise<LimiterResponse> {
  const response = await limiterStub(env, scope).fetch('https://rate-limiter.internal/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    throw new Error(`Rate limiter returned ${response.status}`);
  }

  return response.json() as Promise<LimiterResponse>;
}

function decisionFrom(response: LimiterResponse): RateLimitDecision {
  return {
    allowed: response.allowed === true,
    code: response.code,
    reason: response.reason,
    currentUsage: response.currentUsage ?? 0,
    limit: response.limit ?? DEFAULT_LIMITS.maxExtractionsPerMonth,
  };
}

/**
 * Reserve an extraction before the request leaves BookQuotes. Both coordinators
 * are Durable Objects, so their individual counters are serialized even when
 * multiple Worker isolates receive requests at the same time.
 */
export async function reserveExtraction(
  userId: string,
  clientKey: string,
  idempotencyKey: string | null,
  env: Env,
  limits: RateLimitConfig = DEFAULT_LIMITS
): Promise<RateLimitDecision> {
  if (!isValidIdempotencyKey(idempotencyKey)) {
    return {
      allowed: false,
      code: 'IDEMPOTENCY_INVALID',
      reason: 'A valid Idempotency-Key header is required',
      currentUsage: 0,
      limit: limits.maxExtractionsPerMonth,
    };
  }

  const userDecision = decisionFrom(await limiterRequest(env, `user:${userId}`, {
    action: 'reserve-user',
    userId,
    idempotencyKey,
    limits,
  }));

  if (!userDecision.allowed) {
    return userDecision;
  }

  const ipDecision = decisionFrom(await limiterRequest(env, `ip:${clientKey}`, {
    action: 'reserve-ip',
    limits,
  }));

  if (ipDecision.allowed) {
    return userDecision;
  }

  // The IP check happens after the user reservation so a retry with the same
  // key cannot bypass monthly accounting. Release it when the provider will not
  // be called so this user can retry from another network without waiting.
  await releaseExtractionReservation(userId, idempotencyKey, env);
  return ipDecision;
}

/** Mark a provider success as billable exactly once for its idempotency key. */
export async function completeExtraction(
  userId: string,
  idempotencyKey: string,
  env: Env
): Promise<void> {
  await limiterRequest(env, `user:${userId}`, {
    action: 'complete',
    userId,
    idempotencyKey,
  });
}

/**
 * Provider failures, request validation failures, and interrupted Worker
 * requests release their monthly reservation. The per-minute attempt remains
 * counted deliberately, so failed requests cannot be used to evade abuse caps.
 */
export async function releaseExtractionReservation(
  userId: string,
  idempotencyKey: string,
  env: Env
): Promise<void> {
  await limiterRequest(env, `user:${userId}`, {
    action: 'release',
    userId,
    idempotencyKey,
  });
}

export async function getUsageStats(
  userId: string,
  env: Env,
  limits: RateLimitConfig = DEFAULT_LIMITS
): Promise<{
  extractionsThisMonth: number;
  extractionsLimit: number;
  resetDate: string;
}> {
  const response = await limiterRequest(env, `user:${userId}`, {
    action: 'usage',
    userId,
    limits,
  });

  return {
    extractionsThisMonth: response.extractionsThisMonth ?? 0,
    extractionsLimit: response.extractionsLimit ?? limits.maxExtractionsPerMonth,
    resetDate: response.resetDate ?? getResetDate(),
  };
}

/** Remove the atomic usage and idempotency records when an account is deleted. */
export async function deleteExtractionUsage(userId: string, env: Env): Promise<void> {
  await limiterRequest(env, `user:${userId}`, {
    action: 'delete-user',
    userId,
  });
}
