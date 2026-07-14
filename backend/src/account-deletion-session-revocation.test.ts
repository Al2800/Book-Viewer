import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Env } from './types';

const mocks = vi.hoisted(() => ({
  revokeAllSessions: vi.fn(async () => undefined),
  deleteUserAccountData: vi.fn(async () => undefined),
  validateSession: vi.fn(async () => ({ userId: 'reader-1', version: 1 })),
  isSessionCurrent: vi.fn(async () => true),
}));

vi.mock('./auth', () => ({
  validateAppleToken: vi.fn(),
  validateSession: mocks.validateSession,
  isSessionCurrent: mocks.isSessionCurrent,
  createSessionToken: vi.fn(),
  revokeAllSessions: mocks.revokeAllSessions,
  SESSION_TOKEN_HEADER: 'X-Session-Token',
}));

vi.mock('./account-data', () => ({
  deleteUserAccountData: mocks.deleteUserAccountData,
}));

function makeEnv(): Env {
  return {
    KV: {} as KVNamespace,
    EXTRACTION_LIMITER: {} as DurableObjectNamespace,
    GEMINI_API_KEY: 'test',
    APPLE_TEAM_ID: 'test',
    JWT_SECRET: 'test',
    APPLE_BUNDLE_ID: 'com.bookquotes.test',
    APPLE_IAP_KEY_ID: 'test',
    APPLE_IAP_ISSUER_ID: 'test',
    APPLE_IAP_PRIVATE_KEY: 'test',
    ENVIRONMENT: 'test',
  };
}

describe('account deletion session revocation', () => {
  afterEach(() => {
    vi.clearAllMocks();
    mocks.validateSession.mockResolvedValue({ userId: 'reader-1', version: 1 });
    mocks.isSessionCurrent.mockResolvedValue(true);
  });

  it('revokes every session before deleting account records', async () => {
    const { default: worker } = await import('./index');
    const response = await worker.fetch(
      new Request('https://api.bookquotes.uk/api/auth/account', {
        method: 'DELETE',
        headers: { Authorization: 'Bearer session-token' },
      }),
      makeEnv()
    );

    expect(response.status).toBe(200);
    expect(mocks.revokeAllSessions).toHaveBeenCalledWith('reader-1', expect.anything());
    expect(mocks.deleteUserAccountData).toHaveBeenCalledWith('reader-1', expect.anything());
    expect(mocks.revokeAllSessions.mock.invocationCallOrder[0])
      .toBeLessThan(mocks.deleteUserAccountData.mock.invocationCallOrder[0] ?? Infinity);
  });
});
