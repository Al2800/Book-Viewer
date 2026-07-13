import { describe, expect, it } from 'vitest';
import { sanitizeGeminiRequestPayload } from './gemini-proxy';
import { checkRateLimit } from './rate-limit';
import type { Env } from './types';

class MockKVNamespace {
  private store = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key) ?? null;
  }

  async put(key: string, value: string): Promise<void> {
    this.store.set(key, value);
  }
}

function makeEnv(): Env {
  return {
    KV: new MockKVNamespace() as unknown as KVNamespace,
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

describe('sanitizeGeminiRequestPayload', () => {
  it('keeps only the supported prompt and single-image shape', () => {
    const body = sanitizeGeminiRequestPayload({
      contents: [
        {
          parts: [
            { text: '  extract the quote  ' },
            {
              inlineData: {
                mimeType: 'image/jpeg',
                data: 'dGVzdC1pbWFnZQ==',
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.9,
        maxOutputTokens: 999999,
      },
    });

    expect(body.contents).toHaveLength(1);
    expect(body.contents[0]?.parts).toHaveLength(2);
    expect(body.contents[0]?.parts[0]?.text).toBe('extract the quote');
    expect(body.generationConfig).toEqual({
      temperature: 0.1,
      maxOutputTokens: 4096,
      responseMimeType: 'application/json',
    });
  });

  it('rejects requests with multiple images', () => {
    expect(() =>
      sanitizeGeminiRequestPayload({
        contents: [
          {
            parts: [
              { text: 'extract' },
              { inlineData: { mimeType: 'image/jpeg', data: 'YQ==' } },
              { inlineData: { mimeType: 'image/jpeg', data: 'Yg==' } },
            ],
          },
        ],
      })
    ).toThrow('Request must contain one prompt and one image');
  });

  it('rejects oversized images', () => {
    expect(() =>
      sanitizeGeminiRequestPayload({
        contents: [
          {
            parts: [
              { text: 'extract' },
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: 'A'.repeat(6_100_000),
                },
              },
            ],
          },
        ],
      })
    ).toThrow('Image payload exceeds maximum size');
  });
});

describe('checkRateLimit', () => {
  it('applies an IP/network limit across accounts', async () => {
    const env = makeEnv();
    const clientKey = '203.0.113.8';

    const first = await checkRateLimit('user-1', env, clientKey, {
      maxRequestsPerMinute: 10,
      maxRequestsPerIPPerMinute: 2,
      maxExtractionsPerMonth: 100,
    });
    const second = await checkRateLimit('user-2', env, clientKey, {
      maxRequestsPerMinute: 10,
      maxRequestsPerIPPerMinute: 2,
      maxExtractionsPerMonth: 100,
    });
    const third = await checkRateLimit('user-3', env, clientKey, {
      maxRequestsPerMinute: 10,
      maxRequestsPerIPPerMinute: 2,
      maxExtractionsPerMonth: 100,
    });

    expect(first.allowed).toBe(true);
    expect(second.allowed).toBe(true);
    expect(third.allowed).toBe(false);
    expect(third.reason).toBe('Too many requests from this network');
  });
});
