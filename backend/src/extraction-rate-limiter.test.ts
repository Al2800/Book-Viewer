import { describe, expect, it, vi } from 'vitest';
import { ExtractionRateLimiter } from './extraction-rate-limiter';
import type { Env, RateLimitConfig } from './types';

class MemoryStorage {
  private readonly values = new Map<string, unknown>();

  async get<T>(key: string): Promise<T | undefined> {
    return this.values.get(key) as T | undefined;
  }

  async put<T>(key: string, value: T): Promise<void>;
  async put<T>(entries: Record<string, T>): Promise<void>;
  async put<T>(keyOrEntries: string | Record<string, T>, value?: T): Promise<void> {
    if (typeof keyOrEntries === 'string') {
      this.values.set(keyOrEntries, value);
      return;
    }
    for (const [key, entry] of Object.entries(keyOrEntries)) {
      this.values.set(key, entry);
    }
  }

  async delete(key: string): Promise<boolean> {
    return this.values.delete(key);
  }

  async deleteAll(): Promise<void> {
    this.values.clear();
  }

  async list<T>(options: { prefix?: string } = {}): Promise<Map<string, T>> {
    return new Map(
      [...this.values.entries()]
        .filter(([key]) => !options.prefix || key.startsWith(options.prefix))
        .map(([key, value]) => [key, value as T])
    );
  }
}

const limits: RateLimitConfig = {
  maxRequestsPerMinute: 3,
  maxRequestsPerIPPerMinute: 2,
  maxExtractionsPerMonth: 2,
};

function makeLimiterContext(legacyUsage?: number): {
  limiter: ExtractionRateLimiter;
  storage: MemoryStorage;
} {
  const storage = new MemoryStorage();
  const period = `${new Date().getUTCFullYear()}-${String(new Date().getUTCMonth() + 1).padStart(2, '0')}`;
  const env = {
    KV: {
      get: async (key: string) => key === `usage:reader-1:${period}` && legacyUsage !== undefined
        ? JSON.stringify({ extractionCount: legacyUsage })
        : null,
    },
  } as Env;
  return {
    limiter: new ExtractionRateLimiter({ storage } as unknown as DurableObjectState, env),
    storage,
  };
}

function makeLimiter(legacyUsage?: number): ExtractionRateLimiter {
  return makeLimiterContext(legacyUsage).limiter;
}

async function send(
  limiter: ExtractionRateLimiter,
  body: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const response = await limiter.fetch(new Request('https://rate-limiter.internal/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }));
  expect(response.status).toBe(200);
  return response.json() as Promise<Record<string, unknown>>;
}

describe('ExtractionRateLimiter', () => {
  it('serializes concurrent user reservations without exceeding the minute limit', async () => {
    const limiter = makeLimiter();
    const results = await Promise.all(
      Array.from({ length: 20 }, (_, index) => send(limiter, {
        action: 'reserve-user',
        userId: 'reader-1',
        idempotencyKey: `concurrent-request-${String(index).padStart(4, '0')}`,
        limits: { ...limits, maxExtractionsPerMonth: 50 },
      }))
    );

    expect(results.filter((result) => result.allowed === true)).toHaveLength(3);
    expect(results.filter((result) => result.reason === 'Too many requests per minute')).toHaveLength(17);
  });

  it('atomically enforces the network cap across concurrent accounts', async () => {
    const limiter = makeLimiter();
    const results = await Promise.all(
      Array.from({ length: 20 }, () => send(limiter, {
        action: 'reserve-ip',
        limits,
      }))
    );

    expect(results.filter((result) => result.allowed === true)).toHaveLength(2);
    expect(results.filter((result) => result.reason === 'Too many requests from this network')).toHaveLength(18);
  });

  it('charges a completed request once and reserves monthly capacity before the provider call', async () => {
    const limiter = makeLimiter();
    const firstKey = 'monthly-request-0001';
    const secondKey = 'monthly-request-0002';
    const thirdKey = 'monthly-request-0003';

    await send(limiter, { action: 'reserve-user', userId: 'reader-1', idempotencyKey: firstKey, limits });
    await send(limiter, { action: 'reserve-user', userId: 'reader-1', idempotencyKey: secondKey, limits });
    const denied = await send(limiter, {
      action: 'reserve-user', userId: 'reader-1', idempotencyKey: thirdKey, limits,
    });
    expect(denied.reason).toBe('Monthly extraction limit exceeded');

    await send(limiter, { action: 'complete', userId: 'reader-1', idempotencyKey: firstKey });
    await send(limiter, { action: 'complete', userId: 'reader-1', idempotencyKey: firstKey });
    const usage = await send(limiter, { action: 'usage', userId: 'reader-1', limits });

    expect(usage.extractionsThisMonth).toBe(1);
  });

  it('releases the monthly reservation after a provider failure while retaining the attempt rate slot', async () => {
    const limiter = makeLimiter();
    const key = 'provider-failure-0001';

    await send(limiter, { action: 'reserve-user', userId: 'reader-1', idempotencyKey: key, limits });
    await send(limiter, { action: 'release', userId: 'reader-1', idempotencyKey: key });
    const retry = await send(limiter, { action: 'reserve-user', userId: 'reader-1', idempotencyKey: key, limits });
    const usage = await send(limiter, { action: 'usage', userId: 'reader-1', limits });

    expect(retry.allowed).toBe(true);
    expect(usage.extractionsThisMonth).toBe(0);
  });

  it('uses existing KV monthly usage until the first atomic write migrates it', async () => {
    const limiter = makeLimiter(1);
    const usage = await send(limiter, { action: 'usage', userId: 'reader-1', limits });
    const reservation = await send(limiter, {
      action: 'reserve-user', userId: 'reader-1', idempotencyKey: 'legacy-usage-request-0001', limits,
    });

    expect(usage.extractionsThisMonth).toBe(1);
    expect(reservation.allowed).toBe(true);
  });

  it('removes atomic usage and idempotency records on account deletion', async () => {
    const limiter = makeLimiter();
    await send(limiter, {
      action: 'reserve-user', userId: 'reader-1', idempotencyKey: 'delete-account-request-0001', limits,
    });
    await send(limiter, { action: 'delete-user', userId: 'reader-1' });
    const usage = await send(limiter, { action: 'usage', userId: 'reader-1', limits });

    expect(usage.extractionsThisMonth).toBe(0);
  });

  it('keeps only the active minute bucket in durable storage', async () => {
    vi.useFakeTimers();
    try {
      vi.setSystemTime(new Date('2026-07-14T12:00:00.000Z'));
      const { limiter, storage } = makeLimiterContext();
      await send(limiter, {
        action: 'reserve-ip', limits: { ...limits, maxRequestsPerIPPerMinute: 10 },
      });

      vi.setSystemTime(new Date('2026-07-14T12:01:00.000Z'));
      await send(limiter, {
        action: 'reserve-ip', limits: { ...limits, maxRequestsPerIPPerMinute: 10 },
      });

      const minuteKeys = [...(await storage.list({ prefix: 'minute:' })).keys()];
      expect(minuteKeys).toHaveLength(1);
      expect(minuteKeys[0]).toBe(
        `minute:${Math.floor(new Date('2026-07-14T12:01:00.000Z').getTime() / 60_000)}`
      );
    } finally {
      vi.useRealTimers();
    }
  });
});
