import type { Env, RateLimitConfig, UsageRecord } from './types';

const RESERVATION_TTL_MS = 5 * 60 * 1000;
const COMPLETED_IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000;

interface StoredUsage extends UsageRecord {
  reservedCount: number;
}

interface IdempotencyRecord {
  period: string;
  state: 'reserved' | 'completed';
  expiresAt: number;
}

interface LimiterRequest {
  action: 'reserve-user' | 'reserve-ip' | 'complete' | 'release' | 'usage' | 'delete-user';
  userId?: string;
  idempotencyKey?: string;
  limits?: RateLimitConfig;
}

interface LimiterResult {
  allowed?: boolean;
  code?: 'RATE_LIMIT' | 'IDEMPOTENCY_INVALID' | 'IDEMPOTENCY_REPLAY' | 'IDEMPOTENCY_IN_PROGRESS';
  reason?: string;
  currentUsage?: number;
  limit?: number;
  extractionsThisMonth?: number;
  extractionsLimit?: number;
  resetDate?: string;
}

function currentPeriod(now: number): string {
  const date = new Date(now);
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

function resetDate(now: number): string {
  const date = new Date(now);
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1)).toISOString();
}

function minuteBucket(now: number): string {
  return String(Math.floor(now / 60_000));
}

function defaultUsage(userId: string, period: string, now: number): StoredUsage {
  return {
    userId,
    period,
    extractionCount: 0,
    reservedCount: 0,
    lastUpdated: new Date(now).toISOString(),
  };
}

/**
 * A named instance coordinates either one user or one network identity. Calls
 * are explicitly queued so a read-modify-write sequence cannot interleave
 * while it awaits Durable Object storage.
 */
export class ExtractionRateLimiter {
  private readonly state: DurableObjectState;
  private readonly env: Env;
  private queue: Promise<void> = Promise.resolve();

  constructor(state: DurableObjectState, env: Env) {
    this.state = state;
    this.env = env;
  }

  async fetch(request: Request): Promise<Response> {
    const body = await request.json() as LimiterRequest;
    const result = await this.serialized(() => this.handle(body));
    return Response.json(result);
  }

  private async serialized<T>(operation: () => Promise<T>): Promise<T> {
    const next = this.queue.then(operation, operation);
    this.queue = next.then(
      () => undefined,
      () => undefined
    );
    return next;
  }

  private async handle(request: LimiterRequest): Promise<LimiterResult> {
    const now = Date.now();
    await this.cleanupExpiredIdempotencyRecords(now);

    switch (request.action) {
      case 'reserve-user':
        return this.reserveUser(request, now);
      case 'reserve-ip':
        return this.reserveIP(request, now);
      case 'complete':
        return this.complete(request, now);
      case 'release':
        return this.release(request, now);
      case 'usage':
        return this.usage(request, now);
      case 'delete-user':
        return this.deleteUser();
    }
  }

  private async reserveUser(request: LimiterRequest, now: number): Promise<LimiterResult> {
    const userId = request.userId;
    const idempotencyKey = request.idempotencyKey;
    const limits = request.limits;
    if (!userId || !idempotencyKey || !limits) {
      throw new Error('Invalid user reservation request');
    }

    const period = currentPeriod(now);
    const requestKey = `idempotency:${idempotencyKey}`;
    const existing = await this.state.storage.get<IdempotencyRecord>(requestKey);
    const usage = await this.readUsage(userId, period, now);

    if (existing?.state === 'completed') {
      return {
        allowed: false,
        code: 'IDEMPOTENCY_REPLAY',
        reason: 'This extraction request was already completed',
        currentUsage: usage.extractionCount,
        limit: limits.maxExtractionsPerMonth,
      };
    }

    if (existing?.state === 'reserved') {
      return {
        allowed: false,
        code: 'IDEMPOTENCY_IN_PROGRESS',
        reason: 'This extraction request is already in progress',
        currentUsage: usage.extractionCount,
        limit: limits.maxExtractionsPerMonth,
      };
    }

    if (usage.extractionCount + usage.reservedCount >= limits.maxExtractionsPerMonth) {
      return {
        allowed: false,
        code: 'RATE_LIMIT',
        reason: 'Monthly extraction limit exceeded',
        currentUsage: usage.extractionCount,
        limit: limits.maxExtractionsPerMonth,
      };
    }

    const minute = await this.readMinuteCount(now);
    const minuteCount = minute.count;
    if (minuteCount >= limits.maxRequestsPerMinute) {
      return {
        allowed: false,
        code: 'RATE_LIMIT',
        reason: 'Too many requests per minute',
        currentUsage: minuteCount,
        limit: limits.maxRequestsPerMinute,
      };
    }

    usage.reservedCount += 1;
    usage.lastUpdated = new Date(now).toISOString();
    await this.state.storage.put({
      [this.usageKey(period)]: usage,
      [this.minuteKey(minute.bucket)]: minuteCount + 1,
      'active-minute-bucket': minute.bucket,
      [requestKey]: {
        period,
        state: 'reserved',
        expiresAt: now + RESERVATION_TTL_MS,
      } satisfies IdempotencyRecord,
    });

    return {
      allowed: true,
      currentUsage: usage.extractionCount,
      limit: limits.maxExtractionsPerMonth,
    };
  }

  private async reserveIP(request: LimiterRequest, now: number): Promise<LimiterResult> {
    const limits = request.limits;
    if (!limits) {
      throw new Error('Invalid network reservation request');
    }

    const minute = await this.readMinuteCount(now);
    const minuteCount = minute.count;
    if (minuteCount >= limits.maxRequestsPerIPPerMinute) {
      return {
        allowed: false,
        code: 'RATE_LIMIT',
        reason: 'Too many requests from this network',
        currentUsage: minuteCount,
        limit: limits.maxRequestsPerIPPerMinute,
      };
    }

    await this.state.storage.put({
      [this.minuteKey(minute.bucket)]: minuteCount + 1,
      'active-minute-bucket': minute.bucket,
    });
    return {
      allowed: true,
      currentUsage: minuteCount,
      limit: limits.maxRequestsPerIPPerMinute,
    };
  }

  private async complete(request: LimiterRequest, now: number): Promise<LimiterResult> {
    const userId = request.userId;
    const idempotencyKey = request.idempotencyKey;
    if (!userId || !idempotencyKey) {
      throw new Error('Invalid completion request');
    }

    const requestKey = `idempotency:${idempotencyKey}`;
    const record = await this.state.storage.get<IdempotencyRecord>(requestKey);
    if (!record) {
      throw new Error('Extraction reservation was not found');
    }

    const usage = await this.readUsage(userId, record.period, now);
    if (record.state === 'completed') {
      return { allowed: true, currentUsage: usage.extractionCount };
    }

    usage.reservedCount = Math.max(0, usage.reservedCount - 1);
    usage.extractionCount += 1;
    usage.lastUpdated = new Date(now).toISOString();
    record.state = 'completed';
    record.expiresAt = now + COMPLETED_IDEMPOTENCY_TTL_MS;
    await this.state.storage.put({
      [this.usageKey(record.period)]: usage,
      [requestKey]: record,
    });

    return { allowed: true, currentUsage: usage.extractionCount };
  }

  private async release(request: LimiterRequest, now: number): Promise<LimiterResult> {
    const userId = request.userId;
    const idempotencyKey = request.idempotencyKey;
    if (!userId || !idempotencyKey) {
      throw new Error('Invalid release request');
    }

    const requestKey = `idempotency:${idempotencyKey}`;
    const record = await this.state.storage.get<IdempotencyRecord>(requestKey);
    if (!record || record.state === 'completed') {
      return { allowed: true };
    }

    const usage = await this.readUsage(userId, record.period, now);
    usage.reservedCount = Math.max(0, usage.reservedCount - 1);
    usage.lastUpdated = new Date(now).toISOString();
    await this.state.storage.put(this.usageKey(record.period), usage);
    await this.state.storage.delete(requestKey);
    return { allowed: true, currentUsage: usage.extractionCount };
  }

  private async usage(request: LimiterRequest, now: number): Promise<LimiterResult> {
    const userId = request.userId;
    const limits = request.limits;
    if (!userId || !limits) {
      throw new Error('Invalid usage request');
    }

    const usage = await this.readUsage(userId, currentPeriod(now), now);
    return {
      extractionsThisMonth: usage.extractionCount,
      extractionsLimit: limits.maxExtractionsPerMonth,
      resetDate: resetDate(now),
    };
  }

  private async deleteUser(): Promise<LimiterResult> {
    await this.state.storage.deleteAll();
    return { allowed: true };
  }

  private usageKey(period: string): string {
    return `usage:${period}`;
  }

  private minuteKey(bucket: string): string {
    return `minute:${bucket}`;
  }

  private async readMinuteCount(now: number): Promise<{ bucket: string; count: number }> {
    const bucket = minuteBucket(now);
    const previousBucket = await this.state.storage.get<string>('active-minute-bucket');
    if (previousBucket && previousBucket !== bucket) {
      await this.state.storage.delete(this.minuteKey(previousBucket));
    }
    const count = (await this.state.storage.get<number>(this.minuteKey(bucket))) ?? 0;
    return { bucket, count };
  }

  private async readUsage(userId: string, period: string, now: number): Promise<StoredUsage> {
    const stored = await this.state.storage.get<StoredUsage>(this.usageKey(period));
    if (stored) {
      return stored;
    }

    // Preserve existing monthly limits during the one-way KV-to-Durable-Object
    // migration. New writes live only in this coordinator.
    const legacy = await this.env.KV.get(`usage:${userId}:${period}`);
    if (!legacy) {
      return defaultUsage(userId, period, now);
    }

    try {
      const parsed = JSON.parse(legacy) as Partial<UsageRecord>;
      if (typeof parsed.extractionCount !== 'number' || parsed.extractionCount < 0) {
        return defaultUsage(userId, period, now);
      }
      return {
        userId,
        period,
        extractionCount: Math.floor(parsed.extractionCount),
        reservedCount: 0,
        lastUpdated: typeof parsed.lastUpdated === 'string'
          ? parsed.lastUpdated
          : new Date(now).toISOString(),
      };
    } catch {
      return defaultUsage(userId, period, now);
    }
  }

  private async cleanupExpiredIdempotencyRecords(now: number): Promise<void> {
    const records = await this.state.storage.list<IdempotencyRecord>({ prefix: 'idempotency:' });
    for (const [key, record] of records) {
      if (record.expiresAt > now) {
        continue;
      }

      if (record.state === 'reserved') {
        const usage = await this.state.storage.get<StoredUsage>(this.usageKey(record.period));
        if (usage) {
          usage.reservedCount = Math.max(0, usage.reservedCount - 1);
          usage.lastUpdated = new Date(now).toISOString();
          await this.state.storage.put(this.usageKey(record.period), usage);
        }
      }
      await this.state.storage.delete(key);
    }
  }
}
