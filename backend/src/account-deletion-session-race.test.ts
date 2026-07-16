import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Env } from './types';

function deferred<T>() {
  let resolve: (value: T) => void = () => undefined;
  const promise = new Promise<T>((completion) => {
    resolve = completion;
  });
  return { promise, resolve };
}

const mocks = vi.hoisted(() => {
  const state = {
    revoked: false,
    sessionChecks: 0,
    finalSessionCheck: deferred<boolean>(),
  };
  return {
    state,
    revokeAllSessions: vi.fn(async () => {
      state.revoked = true;
    }),
    deleteUserAccountData: vi.fn(async () => undefined),
    validateSession: vi.fn(async () => ({ userId: 'reader-1', version: 1 })),
    reconcileSubscription: vi.fn(),
    isSessionCurrent: vi.fn(async () => {
      state.sessionChecks += 1;
      return state.sessionChecks === 1 ? true : state.finalSessionCheck.promise;
    }),
  };
});

vi.mock('./auth', () => ({
  validateAppleToken: vi.fn(),
  validateSession: mocks.validateSession,
  isSessionCurrent: mocks.isSessionCurrent,
  createSessionToken: vi.fn(),
  revokeAllSessions: mocks.revokeAllSessions,
  SESSION_TOKEN_HEADER: 'X-Session-Token',
}));

vi.mock('./subscription', () => ({
  getSubscription: vi.fn(async () => null),
  handleAppStoreNotification: vi.fn(),
  hasActiveSubscription: vi.fn(async () => false),
  reconcileSubscription: mocks.reconcileSubscription,
  rememberUserAppAccountToken: vi.fn(),
  toClientSubscriptionStatus: vi.fn(() => 'none'),
}));

vi.mock('./account-data', () => ({
  deleteUserAccountData: mocks.deleteUserAccountData,
}));

class RecordingRateLimiterNamespace {
  readonly actions: string[] = [];

  idFromName(name: string): DurableObjectId {
    return { toString: () => name, equals: () => false } as DurableObjectId;
  }

  get(): DurableObjectStub {
    return {
      fetch: async (_input: RequestInfo | URL, init?: RequestInit) => {
        const body = JSON.parse(String(init?.body ?? '{}')) as { action?: string };
        if (body.action) {
          this.actions.push(body.action);
        }
        return Response.json({ allowed: true, currentUsage: 0, limit: 1000 });
      },
    } as unknown as DurableObjectStub;
  }
}

function makeEnv(limiter: RecordingRateLimiterNamespace): Env {
  return {
    KV: {} as KVNamespace,
    EXTRACTION_LIMITER: limiter as unknown as DurableObjectNamespace,
    GEMINI_API_KEY: 'test-gemini-key',
    APPLE_TEAM_ID: 'test-team',
    JWT_SECRET: 'test-secret',
    APPLE_BUNDLE_ID: 'com.bookquotes.test',
    APPLE_IAP_KEY_ID: 'test-key',
    APPLE_IAP_ISSUER_ID: 'test-issuer',
    APPLE_IAP_PRIVATE_KEY: 'test-private-key',
    ENVIRONMENT: 'test',
    ALLOW_AUTHENTICATED_EXTRACTION: 'true',
    AUTHENTICATED_EXTRACTION_BYPASS_UNTIL: '2099-01-01T00:00:00Z',
    HF_API_TOKEN: 'hf-test-token',
    HF_MODEL_ID: 'Qwen/Qwen2.5-VL-72B-Instruct:hf-inference',
  };
}

function extractionRequest(): Request {
  return new Request('https://api.bookquotes.uk/api/extract-quotes-hf', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer session-token',
      'Content-Type': 'application/json',
      'Idempotency-Key': 'account-delete-race-0001',
    },
    body: JSON.stringify({
      contents: [{
        parts: [
          { text: 'Extract the marked quote.' },
          { inlineData: { mimeType: 'image/jpeg', data: 'dGVzdA==' } },
        ],
      }],
    }),
  });
}

function subscriptionSyncRequest(): Request {
  return new Request('https://api.bookquotes.uk/api/subscription/sync', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer session-token',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ transactionId: '123' }),
  });
}

describe('account deletion request races', () => {
  afterEach(() => {
    vi.clearAllMocks();
    vi.unstubAllGlobals();
    mocks.state.revoked = false;
    mocks.state.sessionChecks = 0;
    mocks.state.finalSessionCheck = deferred<boolean>();
  });

  it('does not forward a pre-authorized extraction after deletion revokes its session', async () => {
    const { default: worker } = await import('./index');
    const limiter = new RecordingRateLimiterNamespace();
    const providerFetch = vi.fn();
    mocks.state.sessionChecks = 0;
    vi.stubGlobal('fetch', providerFetch);

    const extraction = worker.fetch(extractionRequest(), makeEnv(limiter));
    await vi.waitFor(() => {
      expect(mocks.isSessionCurrent).toHaveBeenCalledTimes(2);
    });

    const deletion = await worker.fetch(
      new Request('https://api.bookquotes.uk/api/auth/account', {
        method: 'DELETE',
        headers: { Authorization: 'Bearer session-token' },
      }),
      makeEnv(limiter)
    );
    mocks.state.finalSessionCheck.resolve(false);

    const extractionResponse = await extraction;
    const extractionBody = await extractionResponse.json() as { code: string };

    expect(deletion.status).toBe(200);
    expect(mocks.revokeAllSessions).toHaveBeenCalledWith('reader-1', expect.anything());
    expect(extractionResponse.status).toBe(401);
    expect(extractionBody.code).toBe('AUTH_SESSION_REVOKED');
    expect(providerFetch).not.toHaveBeenCalled();
    expect(limiter.actions).toContain('release');
  });

  it('does not reconcile a subscription after deletion revokes the request session', async () => {
    const { default: worker } = await import('./index');
    const limiter = new RecordingRateLimiterNamespace();
    mocks.state.sessionChecks = 0;

    const sync = worker.fetch(subscriptionSyncRequest(), makeEnv(limiter));
    await vi.waitFor(() => {
      expect(mocks.isSessionCurrent).toHaveBeenCalledTimes(2);
    });

    const deletion = await worker.fetch(
      new Request('https://api.bookquotes.uk/api/auth/account', {
        method: 'DELETE',
        headers: { Authorization: 'Bearer session-token' },
      }),
      makeEnv(limiter)
    );
    mocks.state.finalSessionCheck.resolve(false);

    const syncResponse = await sync;
    const syncBody = await syncResponse.json() as { code: string };

    expect(deletion.status).toBe(200);
    expect(syncResponse.status).toBe(401);
    expect(syncBody.code).toBe('AUTH_SESSION_REVOKED');
    expect(mocks.reconcileSubscription).not.toHaveBeenCalled();
  });
});
