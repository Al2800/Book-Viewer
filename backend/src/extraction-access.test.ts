import { afterEach, describe, expect, it, vi } from 'vitest';
import type { Env } from './types';

vi.mock('./auth', () => ({
  validateAppleToken: vi.fn(),
  validateSessionToken: vi.fn(async () => 'test-user'),
  createSessionToken: vi.fn(),
}));

vi.mock('./subscription', () => ({
  getSubscription: vi.fn(async () => null),
  handleAppStoreNotification: vi.fn(),
  hasActiveSubscription: vi.fn(async () => false),
  reconcileSubscription: vi.fn(),
  rememberUserAppAccountToken: vi.fn(),
  toClientSubscriptionStatus: vi.fn(() => 'none'),
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

function makeEnv(overrides: Partial<Env> = {}): Env {
  return {
    KV: new MockKVNamespace() as unknown as KVNamespace,
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

function makeExtractionRequest(): Request {
  return new Request('https://api.bookquotes.uk/api/extract-quotes', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer test-session-token',
      'Content-Type': 'application/json',
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
});
