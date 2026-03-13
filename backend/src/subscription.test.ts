import { describe, expect, it } from 'vitest';
import {
  deriveAppAccountToken,
  subscriptionHasAccess,
  toClientSubscriptionStatus,
} from './subscription';
import type { SubscriptionRecord } from './types';

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
