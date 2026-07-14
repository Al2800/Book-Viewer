import { describe, expect, it } from 'vitest';
import { deleteUserAccountData } from './account-data';
import {
  deriveAppAccountToken,
  subscriptionHasAccess,
  toClientSubscriptionStatus,
} from './subscription';
import type { Env, SubscriptionRecord } from './types';

function makeRecord(overrides: Partial<SubscriptionRecord> = {}): SubscriptionRecord {
  return {
    schemaVersion: 2,
    userId: 'user-1',
    status: 'active',
    productId: 'com.bookquotes.monthly',
    expiresAt: new Date(Date.now() + 3600_000).toISOString(),
    originalTransactionId: 'orig-1',
    latestTransactionId: 'tx-1',
    environment: 'Production',
    lastVerifiedAt: new Date().toISOString(),
    source: 'app_store_server_api',
    ...overrides,
  };
}

class MockKV {
  store = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key) ?? null;
  }

  async put(key: string, value: string): Promise<void> {
    this.store.set(key, value);
  }

  async delete(key: string): Promise<void> {
    this.store.delete(key);
  }

  async list(options: { prefix: string; cursor?: string }) {
    const keys = [...this.store.keys()]
      .filter((key) => key.startsWith(options.prefix))
      .map((name) => ({ name }));
    return { keys, list_complete: true as const, cursor: undefined };
  }
}

function makeAccountDeletionEnv(kv: MockKV): Env {
  return {
    KV: kv as unknown as KVNamespace,
    EXTRACTION_LIMITER: {
      idFromName: (name: string) => ({ toString: () => name, equals: () => false } as DurableObjectId),
      get: () => ({ fetch: async () => Response.json({ allowed: true }) } as unknown as DurableObjectStub),
    } as unknown as DurableObjectNamespace,
  } as Env;
}

describe('deriveAppAccountToken', () => {
  it('is deterministic and UUID-shaped', async () => {
    const first = await deriveAppAccountToken('apple-user-123');
    const second = await deriveAppAccountToken('apple-user-123');
    const third = await deriveAppAccountToken('apple-user-456');

    expect(first).toBe(second);
    expect(first).not.toBe(third);
    expect(first).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
    );
  });
});

describe('subscription access mapping', () => {
  it('treats trial and active states as active for the client', () => {
    expect(toClientSubscriptionStatus(makeRecord({ status: 'trial' }))).toBe('trial');
    expect(toClientSubscriptionStatus(makeRecord({ status: 'active' }))).toBe('active');
    expect(toClientSubscriptionStatus(makeRecord({ status: 'billing_retry' }))).toBe('active');
    expect(toClientSubscriptionStatus(makeRecord({ status: 'grace_period' }))).toBe('active');
  });

  it('drops access when the entitlement window has passed', () => {
    const expired = makeRecord({
      status: 'active',
      expiresAt: new Date(Date.now() - 60_000).toISOString(),
    });

    expect(subscriptionHasAccess(expired)).toBe(false);
    expect(toClientSubscriptionStatus(expired)).toBe('expired');
  });

  it('uses grace period expiry when present', () => {
    const grace = makeRecord({
      status: 'grace_period',
      expiresAt: new Date(Date.now() - 60_000).toISOString(),
      gracePeriodExpiresAt: new Date(Date.now() + 60_000).toISOString(),
    });

    expect(subscriptionHasAccess(grace)).toBe(true);
    expect(toClientSubscriptionStatus(grace)).toBe('active');
  });

  it('maps revoked access to canceled for the client', () => {
    const revoked = makeRecord({
      status: 'revoked',
      expiresAt: new Date(Date.now() + 60_000).toISOString(),
    });

    expect(subscriptionHasAccess(revoked)).toBe(false);
    expect(toClientSubscriptionStatus(revoked)).toBe('canceled');
  });
});

describe('deleteUserAccountData', () => {
  it('removes subscription, ownership, token, and usage keys for the user', async () => {
    const kv = new MockKV();
    const userId = 'user-delete-1';
    const token = await deriveAppAccountToken(userId);
    const record = makeRecord({
      userId,
      appAccountToken: token,
      originalTransactionId: 'orig-delete-1',
    });

    await kv.put(`sub:user:${userId}`, JSON.stringify(record));
    await kv.put(
      `sub:owner:orig-delete-1`,
      JSON.stringify({
        userId,
        originalTransactionId: 'orig-delete-1',
        linkedAt: new Date().toISOString(),
        source: 'verified_app_account_token',
      })
    );
    await kv.put(`sub:token:${token}`, userId);
    await kv.put(`usage:${userId}:2026-07`, JSON.stringify({ extractionCount: 3 }));

    const env = makeAccountDeletionEnv(kv);
    await deleteUserAccountData(userId, env);

    expect(await kv.get(`sub:user:${userId}`)).toBeNull();
    expect(await kv.get(`sub:owner:orig-delete-1`)).toBeNull();
    expect(await kv.get(`sub:token:${token}`)).toBeNull();
    expect(await kv.get(`usage:${userId}:2026-07`)).toBeNull();
  });

  it('keeps ownership keys that belong to another user', async () => {
    const kv = new MockKV();
    const userId = 'user-delete-2';
    const record = makeRecord({
      userId,
      originalTransactionId: 'orig-shared-1',
    });
    const ownerRecord = {
      userId: 'other-user',
      originalTransactionId: 'orig-shared-1',
      linkedAt: new Date().toISOString(),
      source: 'verified_app_account_token',
    };

    await kv.put(`sub:user:${userId}`, JSON.stringify(record));
    await kv.put(`sub:owner:orig-shared-1`, JSON.stringify(ownerRecord));

    const env = makeAccountDeletionEnv(kv);
    await deleteUserAccountData(userId, env);

    expect(await kv.get(`sub:user:${userId}`)).toBeNull();
    expect(await kv.get(`sub:owner:orig-shared-1`)).toBe(JSON.stringify(ownerRecord));
  });
});
