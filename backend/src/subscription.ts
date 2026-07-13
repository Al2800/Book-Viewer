import * as jose from 'jose';
import { verifyAndDecodeSignedPayload } from './app-store-jws';
import type {
  AppStoreEnvironment,
  ClientSubscriptionStatus,
  Env,
  SubscriptionOwnerRecord,
  SubscriptionRecord,
  SubscriptionStatus,
  SubscriptionSyncRequest,
  SubscriptionSyncResponse,
} from './types';
import {
  appAccountTokenKey,
  appAccountTokenSeed,
  notificationKey,
  originalTransactionOwnerKey,
  subscriptionKey,
} from './subscription-keys';

const APP_STORE_API_BASE: Record<AppStoreEnvironment, string> = {
  Production: 'https://api.storekit.itunes.apple.com',
  Sandbox: 'https://api.storekit-sandbox.itunes.apple.com',
};

const ACTIVE_SUBSCRIPTION_STATUSES = new Set<SubscriptionStatus>([
  'trial',
  'active',
  'billing_retry',
  'grace_period',
]);

const PRODUCT_IDS = new Set([
  'com.bookquotes.monthly',
  'com.bookquotes.yearly',
]);

const INTRODUCTORY_OFFER_TYPE = 1;
const AUTO_RENEW_STATUS_ON = 1;
const BILLING_RETRY_STATUS = 3;
const GRACE_PERIOD_STATUS = 4;

let cachedAppStoreSigningKey: jose.KeyLike | Uint8Array | null = null;
let cachedSigningKeyPem: string | null = null;

type SubscriptionSource = SubscriptionRecord['source'];

interface AppStoreTransactionInfoResponse {
  signedTransactionInfo: string;
}

interface AppStoreStatusResponse {
  data?: Array<{
    lastTransactions?: AppStoreLastTransaction[];
  }>;
}

interface AppStoreLastTransaction {
  status: number;
  originalTransactionId: string;
  signedTransactionInfo: string;
  signedRenewalInfo?: string;
}

interface AppStoreTransactionPayload {
  appAccountToken?: string;
  bundleId?: string;
  environment?: string;
  expiresDate?: number;
  inAppOwnershipType?: string;
  offerIdentifier?: string;
  offerType?: number;
  originalTransactionId?: string;
  productId?: string;
  purchaseDate?: number;
  revocationDate?: number;
  revocationReason?: number;
  signedDate?: number;
  transactionId?: string;
}

interface AppStoreRenewalInfoPayload {
  appAccountToken?: string;
  autoRenewStatus?: number;
  environment?: string;
  expirationIntent?: number;
  gracePeriodExpiresDate?: number;
  isInBillingRetryPeriod?: boolean;
  offerIdentifier?: string;
  offerType?: number;
  originalTransactionId?: string;
  signedDate?: number;
}

interface AppStoreNotificationBody {
  signedPayload?: string;
}

interface AppStoreNotificationPayload {
  notificationUUID?: string;
  data?: {
    appAppleId?: number;
    bundleId?: string;
    environment?: string;
    signedRenewalInfo?: string;
    signedTransactionInfo?: string;
  };
}

interface VerifiedSubscriptionResult {
  record: SubscriptionRecord;
  ownershipSource: SubscriptionOwnerRecord['source'];
}

class AppStoreAPIError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly details?: unknown
  ) {
    super(message);
    this.name = 'AppStoreAPIError';
  }
}

function normalizePrivateKey(rawKey: string): string {
  return rawKey.includes('-----BEGIN PRIVATE KEY-----')
    ? rawKey
    : rawKey.replace(/\\n/g, '\n');
}

async function getAppStoreSigningKey(env: Env): Promise<jose.KeyLike | Uint8Array> {
  const normalizedPem = normalizePrivateKey(env.APPLE_IAP_PRIVATE_KEY);

  if (cachedAppStoreSigningKey && cachedSigningKeyPem === normalizedPem) {
    return cachedAppStoreSigningKey;
  }

  cachedAppStoreSigningKey = await jose.importPKCS8(normalizedPem, 'ES256');
  cachedSigningKeyPem = normalizedPem;
  return cachedAppStoreSigningKey;
}

async function createAppStoreBearerToken(env: Env): Promise<string> {
  const signingKey = await getAppStoreSigningKey(env);

  return new jose.SignJWT({ bid: env.APPLE_BUNDLE_ID })
    .setProtectedHeader({ alg: 'ES256', kid: env.APPLE_IAP_KEY_ID, typ: 'JWT' })
    .setIssuer(env.APPLE_IAP_ISSUER_ID)
    .setAudience('appstoreconnect-v1')
    .setIssuedAt()
    .setExpirationTime('5m')
    .sign(signingKey);
}

function parseAppStoreEnvironment(raw?: string | null): AppStoreEnvironment | undefined {
  if (!raw) {
    return undefined;
  }

  const normalized = raw.toLowerCase();
  if (normalized === 'sandbox' || normalized === 'localtesting' || normalized === 'xcode') {
    return 'Sandbox';
  }
  if (normalized === 'production') {
    return 'Production';
  }
  return undefined;
}

function getEnvironmentProbeOrder(
  hint: AppStoreEnvironment | undefined,
  workerEnvironment: string
): AppStoreEnvironment[] {
  if (hint) {
    return hint === 'Sandbox'
      ? ['Sandbox', 'Production']
      : ['Production', 'Sandbox'];
  }

  return workerEnvironment === 'production'
    ? ['Production', 'Sandbox']
    : ['Sandbox', 'Production'];
}

async function fetchAppStoreResource<T>(
  path: string,
  appStoreEnvironment: AppStoreEnvironment,
  env: Env
): Promise<T> {
  const token = await createAppStoreBearerToken(env);
  const response = await fetch(`${APP_STORE_API_BASE[appStoreEnvironment]}${path}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
      'User-Agent': 'BookQuotes/1.0',
    },
  });

  const responseText = await response.text();
  const parsedBody = responseText ? JSON.parse(responseText) : null;

  if (!response.ok) {
    throw new AppStoreAPIError(
      `App Store API request failed (${response.status})`,
      response.status,
      parsedBody
    );
  }

  return parsedBody as T;
}

function shouldTryOtherEnvironment(error: unknown): boolean {
  return error instanceof AppStoreAPIError && (error.status === 400 || error.status === 404);
}

async function decodeSignedPayload<T>(signedPayload: string): Promise<T> {
  return verifyAndDecodeSignedPayload<T>(signedPayload);
}

function requireAllowedProductId(productId: string | undefined): string {
  if (!productId || !PRODUCT_IDS.has(productId)) {
    throw new Error(`Unexpected subscription product: ${productId ?? 'unknown'}`);
  }

  return productId;
}

function computeAccessUntil(record: SubscriptionRecord): string | undefined {
  if (record.status === 'grace_period' && record.gracePeriodExpiresAt) {
    return record.gracePeriodExpiresAt;
  }

  return record.expiresAt;
}

function computeSubscriptionTtl(record: SubscriptionRecord): number {
  const accessUntil = computeAccessUntil(record);
  if (!accessUntil) {
    return 86400 * 30;
  }

  return Math.max(
    86400,
    Math.ceil((new Date(accessUntil).getTime() - Date.now()) / 1000) + 86400 * 30
  );
}

function parseStoredSubscription(raw: string): SubscriptionRecord | null {
  try {
    const parsed = JSON.parse(raw) as Partial<SubscriptionRecord> & {
      userId?: string;
      productId?: string;
      status?: string;
      expiresAt?: string;
      originalTransactionId?: string;
    };

    if (!parsed.userId || !parsed.productId || !parsed.status) {
      return null;
    }

    if (parsed.schemaVersion === 2 && parsed.originalTransactionId && parsed.latestTransactionId && parsed.lastVerifiedAt && parsed.environment) {
      return parsed as SubscriptionRecord;
    }

    return {
      schemaVersion: 2,
      userId: parsed.userId,
      status: (parsed.status as SubscriptionStatus) ?? 'expired',
      productId: parsed.productId,
      expiresAt: parsed.expiresAt,
      originalTransactionId: parsed.originalTransactionId ?? '',
      latestTransactionId: parsed.originalTransactionId ?? 'legacy',
      environment: 'Production',
      lastVerifiedAt: parsed.expiresAt ?? new Date(0).toISOString(),
      source: 'legacy_claim',
    };
  } catch {
    return null;
  }
}

async function getOriginalTransactionOwner(
  originalTransactionId: string,
  env: Env
): Promise<SubscriptionOwnerRecord | null> {
  const data = await env.KV.get(originalTransactionOwnerKey(originalTransactionId));
  if (!data) {
    return null;
  }

  try {
    return JSON.parse(data) as SubscriptionOwnerRecord;
  } catch {
    return null;
  }
}

async function getUserIdForAppAccountToken(
  appAccountToken: string,
  env: Env
): Promise<string | null> {
  return env.KV.get(appAccountTokenKey(appAccountToken));
}

async function persistNotificationMarker(notificationUUID: string, env: Env): Promise<void> {
  await env.KV.put(notificationKey(notificationUUID), new Date().toISOString(), {
    expirationTtl: 86400 * 30,
  });
}

async function hasProcessedNotification(notificationUUID: string, env: Env): Promise<boolean> {
  const existing = await env.KV.get(notificationKey(notificationUUID));
  return existing !== null;
}

function buildClientSubscriptionStatus(
  subscription: SubscriptionRecord | null
): ClientSubscriptionStatus {
  if (!subscription) {
    return 'none';
  }

  if (subscriptionHasAccess(subscription)) {
    return subscription.status === 'trial' ? 'trial' : 'active';
  }

  if (subscription.status === 'canceled' || subscription.status === 'revoked') {
    return 'canceled';
  }

  return 'expired';
}

function buildSyncResponse(
  subscription: SubscriptionRecord | null,
  source: SubscriptionSyncResponse['source']
): SubscriptionSyncResponse {
  const checkedAt = new Date().toISOString();

  if (!subscription) {
    return {
      ok: true,
      status: 'none',
      rawStatus: 'none',
      checkedAt,
      source,
    };
  }

  return {
    ok: true,
    status: buildClientSubscriptionStatus(subscription),
    rawStatus: subscription.status,
    expiresAt: computeAccessUntil(subscription),
    productId: subscription.productId,
    checkedAt,
    source,
  };
}

function normalizeStatus(
  appStoreStatus: number,
  transaction: AppStoreTransactionPayload,
  renewalInfo?: AppStoreRenewalInfoPayload
): SubscriptionStatus {
  if (transaction.revocationDate) {
    return 'revoked';
  }

  switch (appStoreStatus) {
    case GRACE_PERIOD_STATUS:
      return 'grace_period';
    case BILLING_RETRY_STATUS:
      return 'billing_retry';
    case 2:
      return 'expired';
    case 5:
      return 'revoked';
    case 1:
    default:
      return transaction.offerType === INTRODUCTORY_OFFER_TYPE && !renewalInfo?.isInBillingRetryPeriod
        ? 'trial'
        : 'active';
  }
}

function createSubscriptionRecord(params: {
  userId: string;
  source: SubscriptionSource;
  appStoreStatus: number;
  environment: AppStoreEnvironment;
  transaction: AppStoreTransactionPayload;
  renewalInfo?: AppStoreRenewalInfoPayload;
}): SubscriptionRecord {
  const { userId, source, appStoreStatus, environment, transaction, renewalInfo } = params;
  const originalTransactionId = transaction.originalTransactionId;
  const latestTransactionId = transaction.transactionId;
  const productId = requireAllowedProductId(transaction.productId);

  if (!originalTransactionId || !latestTransactionId) {
    throw new Error('Verified transaction is missing required identifiers');
  }

  const renewalOfferType = renewalInfo?.offerType;
  const renewalOfferIdentifier = renewalInfo?.offerIdentifier;

  return {
    schemaVersion: 2,
    userId,
    status: normalizeStatus(appStoreStatus, transaction, renewalInfo),
    productId,
    expiresAt: transaction.expiresDate
      ? new Date(transaction.expiresDate).toISOString()
      : undefined,
    gracePeriodExpiresAt: renewalInfo?.gracePeriodExpiresDate
      ? new Date(renewalInfo.gracePeriodExpiresDate).toISOString()
      : undefined,
    originalTransactionId,
    latestTransactionId,
    appAccountToken: transaction.appAccountToken ?? renewalInfo?.appAccountToken,
    environment,
    autoRenewStatus: renewalInfo?.autoRenewStatus === undefined
      ? undefined
      : renewalInfo.autoRenewStatus === AUTO_RENEW_STATUS_ON,
    isInBillingRetryPeriod: renewalInfo?.isInBillingRetryPeriod,
    offerType: renewalOfferType ?? transaction.offerType,
    offerIdentifier: renewalOfferIdentifier ?? transaction.offerIdentifier,
    ownershipType: transaction.inAppOwnershipType,
    revocationDate: transaction.revocationDate
      ? new Date(transaction.revocationDate).toISOString()
      : undefined,
    revocationReason: transaction.revocationReason,
    transactionSignedDate: transaction.signedDate
      ? new Date(transaction.signedDate).toISOString()
      : undefined,
    renewalSignedDate: renewalInfo?.signedDate
      ? new Date(renewalInfo.signedDate).toISOString()
      : undefined,
    lastVerifiedAt: new Date().toISOString(),
    source,
  };
}

async function resolveEnvironmentTransaction(
  transactionId: string,
  env: Env,
  environmentHint?: AppStoreEnvironment
): Promise<{
  appStoreEnvironment: AppStoreEnvironment;
  transaction: AppStoreTransactionPayload;
}> {
  const environments = getEnvironmentProbeOrder(environmentHint, env.ENVIRONMENT);
  let lastError: unknown;

  for (const appStoreEnvironment of environments) {
    try {
      const response = await fetchAppStoreResource<AppStoreTransactionInfoResponse>(
        `/inApps/v1/transactions/${transactionId}`,
        appStoreEnvironment,
        env
      );

      const transaction = await decodeSignedPayload<AppStoreTransactionPayload>(
        response.signedTransactionInfo
      );

      return { appStoreEnvironment, transaction };
    } catch (error) {
      lastError = error;
      if (!shouldTryOtherEnvironment(error)) {
        throw error;
      }
    }
  }

  throw lastError ?? new Error('Unable to verify transaction with App Store');
}

async function fetchLatestSubscriptionState(
  originalTransactionId: string,
  appStoreEnvironment: AppStoreEnvironment,
  env: Env
): Promise<{
  appStoreStatus: number;
  transaction: AppStoreTransactionPayload;
  renewalInfo?: AppStoreRenewalInfoPayload;
}> {
  const response = await fetchAppStoreResource<AppStoreStatusResponse>(
    `/inApps/v1/subscriptions/${originalTransactionId}`,
    appStoreEnvironment,
    env
  );

  const candidates = response.data?.flatMap((group) => group.lastTransactions ?? []) ?? [];
  if (candidates.length === 0) {
    throw new Error('App Store did not return any subscription states');
  }

  let matchingTransaction: AppStoreLastTransaction | undefined;
  for (const candidate of candidates) {
    if (candidate.originalTransactionId === originalTransactionId) {
      matchingTransaction = candidate;
      break;
    }

    const decodedCandidate = await decodeSignedPayload<AppStoreTransactionPayload>(
      candidate.signedTransactionInfo
    );
    if (decodedCandidate.originalTransactionId === originalTransactionId) {
      matchingTransaction = candidate;
      break;
    }
  }

  const selected = matchingTransaction ?? candidates[0];
  const transaction = await decodeSignedPayload<AppStoreTransactionPayload>(
    selected.signedTransactionInfo
  );
  const renewalInfo = selected.signedRenewalInfo
    ? await decodeSignedPayload<AppStoreRenewalInfoPayload>(selected.signedRenewalInfo)
    : undefined;

  return {
    appStoreStatus: selected.status,
    transaction,
    renewalInfo,
  };
}

async function verifyOwnershipForUser(
  userId: string,
  transaction: AppStoreTransactionPayload,
  env: Env,
  allowLegacyClaim: boolean
): Promise<SubscriptionOwnerRecord['source']> {
  const expectedAppAccountToken = await deriveAppAccountToken(userId);
  const verifiedAppAccountToken = transaction.appAccountToken?.toLowerCase();

  if (verifiedAppAccountToken) {
    if (verifiedAppAccountToken !== expectedAppAccountToken.toLowerCase()) {
      throw new Error('Verified transaction belongs to a different signed-in user');
    }

    return 'verified_app_account_token';
  }

  const originalTransactionId = transaction.originalTransactionId;
  if (!originalTransactionId) {
    throw new Error('Verified transaction is missing original transaction id');
  }

  const existingOwner = await getOriginalTransactionOwner(originalTransactionId, env);
  if (existingOwner && existingOwner.userId !== userId) {
    throw new Error('Subscription is already linked to another user');
  }

  if (!allowLegacyClaim) {
    throw new Error('Verified transaction is missing appAccountToken');
  }

  return 'legacy_claim';
}

async function resolveVerifiedSubscriptionForUser(params: {
  userId: string;
  transactionId: string;
  env: Env;
  environmentHint?: AppStoreEnvironment;
  allowLegacyClaim: boolean;
  source: SubscriptionSource;
}): Promise<VerifiedSubscriptionResult> {
  const { userId, transactionId, env, environmentHint, allowLegacyClaim, source } = params;
  const verifiedTransaction = await resolveEnvironmentTransaction(transactionId, env, environmentHint);
  const transaction = verifiedTransaction.transaction;

  if (transaction.bundleId !== env.APPLE_BUNDLE_ID) {
    throw new Error('Verified transaction bundle does not match this app');
  }

  const ownershipSource = await verifyOwnershipForUser(
    userId,
    transaction,
    env,
    allowLegacyClaim
  );

  const originalTransactionId = transaction.originalTransactionId;
  if (!originalTransactionId) {
    throw new Error('Verified transaction is missing original transaction id');
  }

  const latestState = await fetchLatestSubscriptionState(
    originalTransactionId,
    verifiedTransaction.appStoreEnvironment,
    env
  );

  if (latestState.transaction.bundleId !== env.APPLE_BUNDLE_ID) {
    throw new Error('Latest subscription state bundle does not match this app');
  }

  if (latestState.transaction.originalTransactionId !== originalTransactionId) {
    throw new Error('App Store returned mismatched original transaction id');
  }

  const record = createSubscriptionRecord({
    userId,
    source,
    appStoreStatus: latestState.appStoreStatus,
    environment: verifiedTransaction.appStoreEnvironment,
    transaction: latestState.transaction,
    renewalInfo: latestState.renewalInfo,
  });

  return { record, ownershipSource };
}

async function resolveStoredSubscriptionForUser(
  userId: string,
  env: Env,
  source: SubscriptionSource
): Promise<VerifiedSubscriptionResult | null> {
  const existingSubscription = await getSubscription(userId, env);

  if (!existingSubscription?.originalTransactionId) {
    return null;
  }

  const latestState = await fetchLatestSubscriptionState(
    existingSubscription.originalTransactionId,
    existingSubscription.environment,
    env
  );

  const ownershipSource = await verifyOwnershipForUser(
    userId,
    latestState.transaction,
    env,
    existingSubscription.source === 'legacy_claim'
  );

  return {
    record: createSubscriptionRecord({
      userId,
      source,
      appStoreStatus: latestState.appStoreStatus,
      environment: existingSubscription.environment,
      transaction: latestState.transaction,
      renewalInfo: latestState.renewalInfo,
    }),
    ownershipSource,
  };
}

async function persistOwnership(
  record: SubscriptionRecord,
  ownershipSource: SubscriptionOwnerRecord['source'],
  env: Env
): Promise<void> {
  const ttl = computeSubscriptionTtl(record);
  const writes: Promise<void>[] = [
    env.KV.put(subscriptionKey(record.userId), JSON.stringify(record), {
      expirationTtl: ttl,
    }),
  ];

  if (record.originalTransactionId) {
    const ownerRecord: SubscriptionOwnerRecord = {
      userId: record.userId,
      originalTransactionId: record.originalTransactionId,
      linkedAt: new Date().toISOString(),
      source: ownershipSource,
    };

    writes.push(
      env.KV.put(
        originalTransactionOwnerKey(record.originalTransactionId),
        JSON.stringify(ownerRecord),
        { expirationTtl: ttl }
      )
    );
  }

  if (record.appAccountToken) {
    writes.push(
      env.KV.put(appAccountTokenKey(record.appAccountToken), record.userId, {
        expirationTtl: ttl,
      })
    );
  }

  await Promise.all(writes);
}

function extractSignedNotificationPayload(body: string): string {
  const trimmed = body.trim();
  if (!trimmed) {
    throw new Error('Notification payload was empty');
  }

  if (!trimmed.startsWith('{')) {
    return trimmed;
  }

  const parsed = JSON.parse(trimmed) as AppStoreNotificationBody;
  if (!parsed.signedPayload) {
    throw new Error('Notification body did not contain signedPayload');
  }

  return parsed.signedPayload;
}

async function resolveNotificationUserId(
  transaction: AppStoreTransactionPayload,
  env: Env
): Promise<string | null> {
  if (transaction.appAccountToken) {
    const userId = await getUserIdForAppAccountToken(transaction.appAccountToken, env);
    if (userId) {
      return userId;
    }
  }

  if (transaction.originalTransactionId) {
    const owner = await getOriginalTransactionOwner(transaction.originalTransactionId, env);
    if (owner) {
      return owner.userId;
    }
  }

  return null;
}

export async function deriveAppAccountToken(userId: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(appAccountTokenSeed(userId))
  );

  const bytes = new Uint8Array(digest).slice(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  const hex = Array.from(bytes, (value) => value.toString(16).padStart(2, '0')).join('');
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20),
  ].join('-');
}

export async function rememberUserAppAccountToken(
  userId: string,
  env: Env
): Promise<string> {
  const appAccountToken = await deriveAppAccountToken(userId);
  await env.KV.put(appAccountTokenKey(appAccountToken), userId);
  return appAccountToken;
}

/**
 * Get subscription status for a user
 */
export async function getSubscription(
  userId: string,
  env: Env
): Promise<SubscriptionRecord | null> {
  const data = await env.KV.get(subscriptionKey(userId));
  if (!data) {
    return null;
  }

  return parseStoredSubscription(data);
}

/**
 * Check if user has an active subscription
 */
export async function hasActiveSubscription(
  userId: string,
  env: Env
): Promise<boolean> {
  const subscription = await getSubscription(userId, env);
  return subscriptionHasAccess(subscription);
}

export function subscriptionHasAccess(
  subscription: SubscriptionRecord | null
): boolean {
  if (!subscription || !ACTIVE_SUBSCRIPTION_STATUSES.has(subscription.status)) {
    return false;
  }

  const accessUntil = computeAccessUntil(subscription);
  if (!accessUntil) {
    return false;
  }

  return new Date(accessUntil).getTime() > Date.now();
}

export function toClientSubscriptionStatus(
  subscription: SubscriptionRecord | null
): ClientSubscriptionStatus {
  return buildClientSubscriptionStatus(subscription);
}

/**
 * Persist verified subscription status.
 */
export async function updateSubscription(
  userId: string,
  subscription: SubscriptionRecord,
  env: Env
): Promise<void> {
  if (userId !== subscription.userId) {
    throw new Error('Subscription user mismatch');
  }

  await persistOwnership(subscription, subscription.source === 'legacy_claim' ? 'legacy_claim' : 'verified_app_account_token', env);
}

export async function reconcileSubscription(
  userId: string,
  request: SubscriptionSyncRequest,
  env: Env
): Promise<SubscriptionSyncResponse> {
  await rememberUserAppAccountToken(userId, env);

  if (request.transactionId) {
    const verified = await resolveVerifiedSubscriptionForUser({
      userId,
      transactionId: request.transactionId,
      env,
      environmentHint: parseAppStoreEnvironment(request.environment),
      allowLegacyClaim: true,
      source: 'app_store_server_api',
    });

    await persistOwnership(verified.record, verified.ownershipSource, env);
    return buildSyncResponse(verified.record, 'app_store_server_api');
  }

  const refreshed = await resolveStoredSubscriptionForUser(
    userId,
    env,
    'app_store_server_api'
  );

  if (!refreshed) {
    return buildSyncResponse(null, 'cache');
  }

  await persistOwnership(refreshed.record, refreshed.ownershipSource, env);
  return buildSyncResponse(refreshed.record, 'app_store_server_api');
}

/**
 * Handle App Store Server Notification v2.
 * We use the notification as a trigger and reconcile against the App Store Server API
 * before mutating entitlements.
 */
export async function handleAppStoreNotification(
  body: string,
  env: Env
): Promise<{ success: boolean; message: string }> {
  try {
    const signedPayload = extractSignedNotificationPayload(body);
    const notification = await decodeSignedPayload<AppStoreNotificationPayload>(signedPayload);
    const notificationUUID = notification.notificationUUID;

    if (notificationUUID && await hasProcessedNotification(notificationUUID, env)) {
      return { success: true, message: 'Duplicate notification ignored' };
    }

    if (notification.data?.bundleId && notification.data.bundleId !== env.APPLE_BUNDLE_ID) {
      return { success: false, message: 'Notification bundle id mismatch' };
    }

    const signedTransactionInfo = notification.data?.signedTransactionInfo;
    if (!signedTransactionInfo) {
      if (notificationUUID) {
        await persistNotificationMarker(notificationUUID, env);
      }
      return { success: true, message: 'Notification contained no subscription transaction info' };
    }

    const hintedTransaction = await decodeSignedPayload<AppStoreTransactionPayload>(signedTransactionInfo);
    const userId = await resolveNotificationUserId(hintedTransaction, env);

    if (!userId) {
      return { success: true, message: 'Notification ignored until subscription ownership is known' };
    }

    const transactionId = hintedTransaction.transactionId ?? hintedTransaction.originalTransactionId;
    if (!transactionId) {
      return { success: false, message: 'Notification was missing transaction identifiers' };
    }

    const verified = await resolveVerifiedSubscriptionForUser({
      userId,
      transactionId,
      env,
      environmentHint: parseAppStoreEnvironment(notification.data?.environment),
      allowLegacyClaim: true,
      source: 'app_store_server_notification',
    });

    await persistOwnership(verified.record, verified.ownershipSource, env);

    if (notificationUUID) {
      await persistNotificationMarker(notificationUUID, env);
    }

    return {
      success: true,
      message: `Updated subscription for user ${userId}`,
    };
  } catch (error) {
    console.error('Failed to handle App Store notification:', error);
    return { success: false, message: 'Failed to process notification' };
  }
}
