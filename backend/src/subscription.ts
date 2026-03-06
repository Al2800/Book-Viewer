import type { Env, SubscriptionRecord } from './types';

/**
 * Get subscription status for a user
 */
export async function getSubscription(
  userId: string,
  env: Env
): Promise<SubscriptionRecord | null> {
  const key = `sub:${userId}`;
  const data = await env.KV.get(key);

  if (!data) {
    return null;
  }

  try {
    return JSON.parse(data) as SubscriptionRecord;
  } catch {
    return null;
  }
}

/**
 * Check if user has an active subscription
 */
export async function hasActiveSubscription(
  userId: string,
  env: Env
): Promise<boolean> {
  const subscription = await getSubscription(userId, env);

  if (!subscription) {
    return false;
  }

  // Check status
  if (subscription.status !== 'active' && subscription.status !== 'trial') {
    return false;
  }

  // Check expiration
  const expiresAt = new Date(subscription.expiresAt);
  if (expiresAt < new Date()) {
    return false;
  }

  return true;
}

/**
 * Update subscription status from App Store Server Notification
 */
export async function updateSubscription(
  userId: string,
  subscription: SubscriptionRecord,
  env: Env
): Promise<void> {
  const key = `sub:${userId}`;
  await env.KV.put(key, JSON.stringify(subscription), {
    // Set expiration slightly after subscription expiration for cleanup
    expirationTtl: Math.max(
      86400, // Minimum 1 day
      Math.ceil(
        (new Date(subscription.expiresAt).getTime() - Date.now()) / 1000
      ) + 86400 * 7 // Plus 7 days grace
    ),
  });
}

/**
 * Handle App Store Server Notification v2
 * See: https://developer.apple.com/documentation/appstoreservernotifications
 */
export async function handleAppStoreNotification(
  signedPayload: string,
  env: Env
): Promise<{ success: boolean; message: string }> {
  // In production, you would:
  // 1. Verify the signed payload using Apple's public key
  // 2. Decode the JWS to get the notification data
  // 3. Extract the transaction info and renewal info
  // 4. Update the user's subscription status

  // For now, we'll implement a simplified version
  // that expects the decoded payload directly

  try {
    // Parse the notification (simplified - real implementation needs JWS verification)
    const notification = JSON.parse(signedPayload);

    const { notificationType, data } = notification;
    const { signedTransactionInfo } = data || {};

    if (!signedTransactionInfo) {
      return { success: false, message: 'Missing transaction info' };
    }

    // In production, decode and verify signedTransactionInfo
    // For now, we'll use a simplified structure
    const transactionInfo = JSON.parse(signedTransactionInfo);
    const userId = transactionInfo.appAccountToken; // Set during purchase

    if (!userId) {
      return { success: false, message: 'Missing user ID in transaction' };
    }

    // Map notification type to subscription status.
    let status: SubscriptionRecord['status'] = 'active';
    const activeTypes = new Set(['SUBSCRIBED', 'DID_RENEW', 'DID_CHANGE_RENEWAL_STATUS']);
    const expiredTypes = new Set(['EXPIRED', 'GRACE_PERIOD_EXPIRED']);
    const canceledTypes = new Set(['REFUND', 'REVOKE']);

    if (activeTypes.has(notificationType)) {
      status = 'active';
    } else if (expiredTypes.has(notificationType)) {
      status = 'expired';
    } else if (canceledTypes.has(notificationType)) {
      status = 'canceled';
    } else {
      // Unknown notification type, don't change status
      return { success: true, message: `Ignored notification: ${notificationType}` };
    }

    const subscription: SubscriptionRecord = {
      userId,
      status,
      productId: transactionInfo.productId || 'unknown',
      expiresAt: new Date(transactionInfo.expiresDate || Date.now()).toISOString(),
      originalTransactionId: transactionInfo.originalTransactionId,
    };

    await updateSubscription(userId, subscription, env);

    return { success: true, message: `Updated subscription: ${status}` };
  } catch (error) {
    console.error('Failed to handle App Store notification:', error);
    return { success: false, message: 'Failed to process notification' };
  }
}
