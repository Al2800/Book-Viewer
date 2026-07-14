import { describe, expect, it } from 'vitest';
import {
  createSessionToken,
  revokeAllSessions,
  validateSessionToken,
} from './auth';
import type { Env } from './types';

class MemoryKV {
  private readonly values = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.values.get(key) ?? null;
  }

  async put(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

function makeEnv(): Env {
  return {
    KV: new MemoryKV() as unknown as KVNamespace,
    EXTRACTION_LIMITER: {} as DurableObjectNamespace,
    GEMINI_API_KEY: 'test',
    APPLE_TEAM_ID: 'test',
    JWT_SECRET: 'test-session-secret',
    APPLE_BUNDLE_ID: 'com.bookquotes.test',
    APPLE_IAP_KEY_ID: 'test',
    APPLE_IAP_ISSUER_ID: 'test',
    APPLE_IAP_PRIVATE_KEY: 'test',
    ENVIRONMENT: 'test',
  };
}

describe('server-side session revocation', () => {
  it('rejects a pre-deletion token and allows a newly issued session', async () => {
    const env = makeEnv();
    const oldToken = await createSessionToken('reader-1', env);

    await expect(validateSessionToken(`Bearer ${oldToken}`, env)).resolves.toBe('reader-1');

    await revokeAllSessions('reader-1', env);
    await expect(validateSessionToken(`Bearer ${oldToken}`, env)).resolves.toBeNull();

    const newToken = await createSessionToken('reader-1', env);
    await expect(validateSessionToken(`Bearer ${newToken}`, env)).resolves.toBe('reader-1');
  });
});
