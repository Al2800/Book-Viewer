import { describe, expect, it } from 'vitest';
import { decideExtractionAccess } from './extraction-access-policy';

describe('extraction access policy', () => {
  it('allows an active subscriber without the beta bypass', () => {
    expect(decideExtractionAccess(true, false)).toEqual({
      allowed: true,
      source: 'subscription',
    });
  });

  it('allows a signed-in beta reader only when the flag is explicitly enabled', () => {
    expect(decideExtractionAccess(false, true)).toEqual({
      allowed: true,
      source: 'authenticated_beta',
    });
  });

  it('denies a non-subscriber with the existing client-facing contract', () => {
    expect(decideExtractionAccess(false, false)).toEqual({
      allowed: false,
      error: 'Active subscription required',
      code: 'SUBSCRIPTION_REQUIRED',
      status: 402,
      details: 'Please subscribe to use this feature',
    });
  });
});
