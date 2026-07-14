import * as jose from 'jose';
import type { Env, AppleJWTPayload } from './types';

// Apple's public key endpoint
const APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys';

// Cache for Apple's public keys
let cachedKeys: jose.JSONWebKeySet | null = null;
let keysCachedAt = 0;
const KEYS_CACHE_TTL = 3600000; // 1 hour

/**
 * Fetch Apple's public keys for JWT verification
 */
async function getApplePublicKeys(): Promise<jose.JSONWebKeySet> {
  const now = Date.now();

  if (cachedKeys && now - keysCachedAt < KEYS_CACHE_TTL) {
    return cachedKeys;
  }

  const response = await fetch(APPLE_KEYS_URL);
  if (!response.ok) {
    throw new Error('Failed to fetch Apple public keys');
  }

  cachedKeys = (await response.json()) as jose.JSONWebKeySet;
  keysCachedAt = now;
  return cachedKeys;
}

/**
 * Validate an Apple Sign-In identity token
 * Returns the user ID if valid, null otherwise
 */
export async function validateAppleToken(
  authHeader: string | null,
  env: Env
): Promise<string | null> {
  if (!authHeader) {
    return null;
  }

  // Extract token from "Bearer <token>" format
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : authHeader;

  if (!token) {
    return null;
  }

  try {
    // Get Apple's public keys
    const keys = await getApplePublicKeys();
    const JWKS = jose.createLocalJWKSet(keys);

    // Apple identity tokens use the app's bundle ID as `aud` (not the Team ID).
    const { payload } = await jose.jwtVerify(token, JWKS, {
      issuer: 'https://appleid.apple.com',
      audience: env.APPLE_BUNDLE_ID,
    });

    const applePayload = payload as unknown as AppleJWTPayload;

    // Ensure token hasn't expired
    if (applePayload.exp * 1000 < Date.now()) {
      console.error('Token expired');
      return null;
    }

    // Return the user's unique identifier
    return applePayload.sub;
  } catch (error) {
    console.error('Token validation failed:', error);
    return null;
  }
}

/** Response header used for sliding session refresh on authenticated API calls. */
export const SESSION_TOKEN_HEADER = 'X-Session-Token';

/** Sliding session lifetime. Clients must persist refreshed tokens from responses. */
export const SESSION_TOKEN_TTL = '7d';
const SESSION_VERSION_TTL_SECONDS = 8 * 24 * 60 * 60;

/** A JWT that has passed signature validation and is tied to one account revision. */
export interface ValidatedSession {
  userId: string;
  version: number;
}

function sessionVersionKey(userId: string): string {
  return `auth:session-version:${userId}`;
}

async function currentSessionVersion(userId: string, env: Env): Promise<number> {
  const storedVersion = await env.KV.get(sessionVersionKey(userId));
  const parsedVersion = Number(storedVersion);
  return Number.isInteger(parsedVersion) && parsedVersion > 0 ? parsedVersion : 1;
}

/**
 * Invalidate every existing session for a user. The record outlives the
 * maximum JWT lifetime so an old token cannot become valid again.
 */
export async function revokeAllSessions(userId: string, env: Env): Promise<void> {
  const nextVersion = (await currentSessionVersion(userId, env)) + 1;
  await env.KV.put(sessionVersionKey(userId), String(nextVersion), {
    expirationTtl: SESSION_VERSION_TTL_SECONDS,
  });
}

/**
 * Create a session token for the user
 * This is a simpler JWT we issue after Apple Sign-In verification
 */
export async function createSessionToken(
  userId: string,
  env: Env,
  version?: number
): Promise<string> {
  const secret = new TextEncoder().encode(env.JWT_SECRET);
  const sessionVersion = version ?? await currentSessionVersion(userId, env);

  const token = await new jose.SignJWT({ sub: userId, sv: sessionVersion })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(SESSION_TOKEN_TTL)
    .setIssuer('bookquotes-proxy')
    .sign(secret);

  return token;
}

/**
 * Validate a session token
 * Returns user ID if valid, null otherwise
 */
export async function validateSession(
  authHeader: string | null,
  env: Env
): Promise<ValidatedSession | null> {
  if (!authHeader) {
    return null;
  }

  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : authHeader;

  if (!token) {
    return null;
  }

  try {
    const secret = new TextEncoder().encode(env.JWT_SECRET);

    const { payload } = await jose.jwtVerify(token, secret, {
      issuer: 'bookquotes-proxy',
    });

    const userId = payload.sub;
    const tokenVersion = payload.sv;
    if (
      typeof userId !== 'string'
      || typeof tokenVersion !== 'number'
      || !Number.isInteger(tokenVersion)
    ) {
      return null;
    }

    const session: ValidatedSession = { userId, version: tokenVersion };
    return await isSessionCurrent(session, env) ? session : null;
  } catch (error) {
    console.error('Session token validation failed:', error);
    return null;
  }
}

/**
 * Recheck a request's original session revision before a sensitive operation or
 * response refresh. A token minted with that same revision stays invalid if a
 * concurrent account deletion wins immediately after this check.
 */
export async function isSessionCurrent(
  session: ValidatedSession,
  env: Env
): Promise<boolean> {
  return session.version === await currentSessionVersion(session.userId, env);
}

/** Backwards-compatible user ID helper for callers that do not need the revision. */
export async function validateSessionToken(
  authHeader: string | null,
  env: Env
): Promise<string | null> {
  return (await validateSession(authHeader, env))?.userId ?? null;
}
