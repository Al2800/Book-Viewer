import { describe, expect, it } from 'vitest';
import { stagingURL } from './staging-worker-check-utils.mjs';

describe('stagingURL', () => {
  it('keeps verification endpoints on the configured staging origin', () => {
    const url = stagingURL(
      'https://bookquotes-staging.example.workers.dev',
      'api/extract-quotes-hf'
    );

    expect(url.href).toBe(
      'https://bookquotes-staging.example.workers.dev/api/extract-quotes-hf'
    );
  });

  it.each([
    'https://api.bookquotes.uk',
    'https://bookquotes.uk',
    'https://www.bookquotes.uk',
  ])('rejects the production API host %s', (baseURL) => {
    expect(() => stagingURL(baseURL, 'api/auth/account')).toThrow(
      'must not target the production BookQuotes API'
    );
  });

  it('rejects unsafe base URLs and cross-origin endpoint paths', () => {
    expect(() => stagingURL('file:///tmp/staging', 'api/usage')).toThrow(
      'must use http or https'
    );
    expect(() => stagingURL('https://token@example.test', 'api/usage')).toThrow(
      'must not include credentials'
    );
    expect(() => stagingURL('https://example.test', 'https://other.test/api/usage')).toThrow(
      'must remain on STAGING_BASE_URL'
    );
  });
});
