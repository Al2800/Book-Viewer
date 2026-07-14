import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Env } from './types';

vi.mock('./auth', () => ({
  validateAppleToken: vi.fn(),
  validateSessionToken: vi.fn(async () => 'test-user'),
  createSessionToken: vi.fn(async () => 'refreshed-session-token'),
  revokeAllSessions: vi.fn(),
  SESSION_TOKEN_HEADER: 'X-Session-Token',
}));

vi.mock('./subscription', () => ({
  getSubscription: vi.fn(async () => null),
  handleAppStoreNotification: vi.fn(),
  hasActiveSubscription: vi.fn(async () => false),
  reconcileSubscription: vi.fn(),
  rememberUserAppAccountToken: vi.fn(),
  toClientSubscriptionStatus: vi.fn(() => 'none'),
}));

vi.mock('./account-data', () => ({
  deleteUserAccountData: vi.fn(),
}));

class MockKVNamespace {
  private store = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key) ?? null;
  }

  async put(key: string, value: string): Promise<void> {
    this.store.set(key, value);
  }
}

class AllowingRateLimiterNamespace {
  idFromName(name: string): DurableObjectId {
    return { toString: () => name, equals: () => false } as DurableObjectId;
  }

  get(): DurableObjectStub {
    return {
      fetch: async (_input: RequestInfo | URL, init?: RequestInit) => {
        const body = JSON.parse(String(init?.body ?? '{}')) as { action?: string };
        if (body.action === 'usage') {
          return Response.json({
            extractionsThisMonth: 0,
            extractionsLimit: 1000,
            resetDate: '2026-08-01T00:00:00.000Z',
          });
        }
        return Response.json({ allowed: true, currentUsage: 0, limit: 1000 });
      },
    } as unknown as DurableObjectStub;
  }
}

class RejectingRateLimiterNamespace {
  idFromName(name: string): DurableObjectId {
    return { toString: () => name, equals: () => false } as DurableObjectId;
  }

  get(): DurableObjectStub {
    return {
      fetch: async () => Response.json({
        allowed: false,
        code: 'RATE_LIMIT',
        reason: 'Too many requests per minute',
        currentUsage: 30,
        limit: 30,
      }),
    } as unknown as DurableObjectStub;
  }
}

function makeEnv(overrides: Partial<Env> = {}): Env {
  return {
    KV: new MockKVNamespace() as unknown as KVNamespace,
    EXTRACTION_LIMITER: new AllowingRateLimiterNamespace() as unknown as DurableObjectNamespace,
    GEMINI_API_KEY: 'test-gemini-key',
    APPLE_TEAM_ID: 'test-team',
    JWT_SECRET: 'test-secret',
    APPLE_BUNDLE_ID: 'com.bookquotes.test',
    APPLE_IAP_KEY_ID: 'test-key',
    APPLE_IAP_ISSUER_ID: 'test-issuer',
    APPLE_IAP_PRIVATE_KEY: 'test-private-key',
    ENVIRONMENT: 'production',
    ...overrides,
  };
}

function makeExtractionRequest(path = '/api/extract-quotes'): Request {
  return new Request(`https://api.bookquotes.uk${path}`, {
    method: 'POST',
    headers: {
        Authorization: 'Bearer test-session-token',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'test-request-key-0001',
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: 'Extract quotes from this page.' },
            {
              inlineData: {
                mimeType: 'image/jpeg',
                data: 'dGVzdA==',
              },
            },
          ],
        },
      ],
    }),
  });
}

describe('extraction access policy', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('allows authenticated beta extraction without an active subscription when explicitly enabled', async () => {
    const { default: worker } = await import('./index');
    const geminiFetch = vi.fn(async () => new Response(
      JSON.stringify({
        candidates: [
          {
            content: {
              parts: [
                {
                  text: JSON.stringify({
                    quotes: [
                      {
                        text: 'The truth is rarely pure and never simple.',
                        pageNumber: 12,
                        confidence: 0.92,
                      },
                    ],
                  }),
                },
              ],
            },
            finishReason: 'STOP',
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    ));

    vi.stubGlobal('fetch', geminiFetch);

    const response = await worker.fetch(
      makeExtractionRequest(),
      makeEnv({ ALLOW_AUTHENTICATED_EXTRACTION: 'true' })
    );

    expect(response.status).toBe(200);
    expect(geminiFetch).toHaveBeenCalledOnce();
  });

  it('keeps subscription enforcement when authenticated extraction is not explicitly enabled', async () => {
    const { default: worker } = await import('./index');
    const geminiFetch = vi.fn();
    vi.stubGlobal('fetch', geminiFetch);

    const response = await worker.fetch(
      makeExtractionRequest(),
      makeEnv({ ALLOW_AUTHENTICATED_EXTRACTION: undefined })
    );
    const body = await response.json() as { code: string };

    expect(response.status).toBe(402);
    expect(body.code).toBe('SUBSCRIPTION_REQUIRED');
    expect(geminiFetch).not.toHaveBeenCalled();
  });

  it('rejects an exhausted reservation before forwarding an image to Gemini', async () => {
    const { default: worker } = await import('./index');
    const geminiFetch = vi.fn();
    vi.stubGlobal('fetch', geminiFetch);

    const response = await worker.fetch(
      makeExtractionRequest(),
      makeEnv({
        ALLOW_AUTHENTICATED_EXTRACTION: 'true',
        EXTRACTION_LIMITER: new RejectingRateLimiterNamespace() as unknown as DurableObjectNamespace,
      })
    );
    const body = await response.json() as { code: string };

    expect(response.status).toBe(429);
    expect(body.code).toBe('RATE_LIMIT');
    expect(geminiFetch).not.toHaveBeenCalled();
  });

  it('returns a clear error when Hugging Face extraction is not configured', async () => {
    const { default: worker } = await import('./index');
    const hfFetch = vi.fn();
    vi.stubGlobal('fetch', hfFetch);

    const response = await worker.fetch(
      makeExtractionRequest('/api/extract-quotes-hf'),
      makeEnv({ ALLOW_AUTHENTICATED_EXTRACTION: 'true' })
    );
    const body = await response.json() as { code: string };

    expect(response.status).toBe(503);
    expect(body.code).toBe('HF_NOT_CONFIGURED');
    expect(hfFetch).not.toHaveBeenCalled();
  });

  it('allows configured Hugging Face extraction through the same authenticated beta gate', async () => {
    const { default: worker } = await import('./index');
    const hfFetch = vi.fn(async () => new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: JSON.stringify({
                quotes: [
                  {
                    text: 'The marked passage is here.',
                    markingType: 'marginLine',
                    confidence: 0.91,
                  },
                ],
                processingNotes: 'Qwen model-assisted extraction',
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    ));
    vi.stubGlobal('fetch', hfFetch);

    const response = await worker.fetch(
      makeExtractionRequest('/api/extract-quotes-hf'),
      makeEnv({
        ALLOW_AUTHENTICATED_EXTRACTION: 'true',
        HF_API_TOKEN: 'hf-test-token',
        HF_MODEL_ID: 'Qwen/Qwen2.5-VL-72B-Instruct:hf-inference',
      })
    );
    const body = await response.json() as {
      candidates: Array<{ content: { parts: Array<{ text: string }> } }>;
    };
    const quoteResult = JSON.parse(body.candidates[0]?.content.parts[0]?.text ?? '{}');

    expect(response.status).toBe(200);
    expect(hfFetch).toHaveBeenCalledOnce();
    expect(quoteResult.quotes[0].text).toBe('The marked passage is here.');
    expect(quoteResult.quotes[0].markingType).toBe('marginLine');
  });

  it('rejects an unapproved Hugging Face provider before reading or forwarding the image', async () => {
    const { default: worker } = await import('./index');
    const hfFetch = vi.fn();
    vi.stubGlobal('fetch', hfFetch);

    const response = await worker.fetch(
      makeExtractionRequest('/api/extract-quotes-hf'),
      makeEnv({
        ALLOW_AUTHENTICATED_EXTRACTION: 'true',
        HF_API_TOKEN: 'hf-test-token',
        HF_MODEL_ID: 'Qwen/Qwen2.5-VL-72B-Instruct:preferred',
      })
    );
    const body = await response.json() as { code: string };

    expect(response.status).toBe(503);
    expect(body.code).toBe('HF_PROVIDER_NOT_APPROVED');
    expect(hfFetch).not.toHaveBeenCalled();
  });
});
