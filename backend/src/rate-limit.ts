import type { Env, UsageRecord, RateLimitConfig } from './types';

// Default rate limits
const DEFAULT_LIMITS: RateLimitConfig = {
  maxRequestsPerMinute: 30,
  maxExtractionsPerMonth: 1000,
};

/**
 * Get the current month period string (YYYY-MM)
 */
function getCurrentPeriod(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

/**
 * Get usage record for a user
 */
export async function getUsage(
  userId: string,
  env: Env
): Promise<UsageRecord> {
  const period = getCurrentPeriod();
  const key = `usage:${userId}:${period}`;
  const data = await env.KV.get(key);

  if (!data) {
    return {
      userId,
      period,
      extractionCount: 0,
      lastUpdated: new Date().toISOString(),
    };
  }

  try {
    return JSON.parse(data) as UsageRecord;
  } catch {
    return {
      userId,
      period,
      extractionCount: 0,
      lastUpdated: new Date().toISOString(),
    };
  }
}

/**
 * Increment extraction count for a user
 */
export async function incrementUsage(
  userId: string,
  env: Env
): Promise<UsageRecord> {
  const usage = await getUsage(userId, env);
  usage.extractionCount += 1;
  usage.lastUpdated = new Date().toISOString();

  const key = `usage:${userId}:${usage.period}`;

  // Set TTL to end of next month (cleanup old records)
  const now = new Date();
  const endOfNextMonth = new Date(now.getFullYear(), now.getMonth() + 2, 1);
  const ttl = Math.ceil((endOfNextMonth.getTime() - now.getTime()) / 1000);

  await env.KV.put(key, JSON.stringify(usage), {
    expirationTtl: ttl,
  });

  return usage;
}

/**
 * Check if user has exceeded rate limits
 */
export async function checkRateLimit(
  userId: string,
  env: Env,
  limits: RateLimitConfig = DEFAULT_LIMITS
): Promise<{
  allowed: boolean;
  reason?: string;
  currentUsage: number;
  limit: number;
}> {
  // Check monthly extraction limit
  const usage = await getUsage(userId, env);

  if (usage.extractionCount >= limits.maxExtractionsPerMonth) {
    return {
      allowed: false,
      reason: 'Monthly extraction limit exceeded',
      currentUsage: usage.extractionCount,
      limit: limits.maxExtractionsPerMonth,
    };
  }

  // Check per-minute rate limit using a sliding window
  const minuteKey = `ratelimit:${userId}:${Math.floor(Date.now() / 60000)}`;
  const minuteCountStr = await env.KV.get(minuteKey);
  const minuteCount = minuteCountStr ? parseInt(minuteCountStr, 10) : 0;

  if (minuteCount >= limits.maxRequestsPerMinute) {
    return {
      allowed: false,
      reason: 'Too many requests per minute',
      currentUsage: minuteCount,
      limit: limits.maxRequestsPerMinute,
    };
  }

  // Increment per-minute counter
  await env.KV.put(minuteKey, String(minuteCount + 1), {
    expirationTtl: 120, // 2 minutes TTL
  });

  return {
    allowed: true,
    currentUsage: usage.extractionCount,
    limit: limits.maxExtractionsPerMonth,
  };
}

/**
 * Get usage statistics for API response
 */
export async function getUsageStats(
  userId: string,
  env: Env,
  limits: RateLimitConfig = DEFAULT_LIMITS
): Promise<{
  extractionsThisMonth: number;
  extractionsLimit: number;
  resetDate: string;
}> {
  const usage = await getUsage(userId, env);

  // Calculate reset date (first of next month)
  const now = new Date();
  const resetDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  return {
    extractionsThisMonth: usage.extractionCount,
    extractionsLimit: limits.maxExtractionsPerMonth,
    resetDate: resetDate.toISOString(),
  };
}
