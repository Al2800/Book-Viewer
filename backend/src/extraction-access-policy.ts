import { hasActiveSubscription } from './subscription';
import type { Env } from './types';

export type ExtractionAccessDecision =
  | {
      allowed: true;
      source: 'subscription' | 'authenticated_beta';
    }
  | {
      allowed: false;
      error: 'Active subscription required';
      code: 'SUBSCRIPTION_REQUIRED';
      status: 402;
      details: 'Please subscribe to use this feature';
    };

export function decideExtractionAccess(
  hasSubscription: boolean,
  allowsAuthenticatedExtraction: boolean
): ExtractionAccessDecision {
  if (hasSubscription) {
    return { allowed: true, source: 'subscription' };
  }

  if (allowsAuthenticatedExtraction) {
    return { allowed: true, source: 'authenticated_beta' };
  }

  return {
    allowed: false,
    error: 'Active subscription required',
    code: 'SUBSCRIPTION_REQUIRED',
    status: 402,
    details: 'Please subscribe to use this feature',
  };
}

export async function evaluateExtractionAccess(
  userId: string,
  env: Env
): Promise<ExtractionAccessDecision> {
  return decideExtractionAccess(
    await hasActiveSubscription(userId, env),
    env.ALLOW_AUTHENTICATED_EXTRACTION === 'true'
  );
}
