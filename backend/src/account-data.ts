import { deriveAppAccountToken, getSubscription } from './subscription';
import {
  appAccountTokenKey,
  originalTransactionOwnerKey,
  subscriptionKey,
} from './subscription-keys';
import type { Env, SubscriptionOwnerRecord } from './types';

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

/**
 * Delete server-side account data for a user (subscription cache, ownership links, usage).
 * Does not cancel App Store billing; the user must manage subscriptions in Apple settings.
 */
export async function deleteUserAccountData(
  userId: string,
  env: Env
): Promise<void> {
  const subscription = await getSubscription(userId, env);
  const deletes: Promise<void>[] = [env.KV.delete(subscriptionKey(userId))];

  const derivedToken = await deriveAppAccountToken(userId);
  deletes.push(env.KV.delete(appAccountTokenKey(derivedToken)));

  if (subscription?.appAccountToken) {
    deletes.push(env.KV.delete(appAccountTokenKey(subscription.appAccountToken)));
  }

  if (subscription?.originalTransactionId) {
    const owner = await getOriginalTransactionOwner(
      subscription.originalTransactionId,
      env
    );
    if (owner?.userId === userId) {
      deletes.push(
        env.KV.delete(originalTransactionOwnerKey(subscription.originalTransactionId))
      );
    }
  }

  let cursor: string | undefined;
  do {
    const listed = await env.KV.list({
      prefix: `usage:${userId}:`,
      cursor,
    });
    for (const key of listed.keys) {
      deletes.push(env.KV.delete(key.name));
    }
    cursor = listed.list_complete ? undefined : listed.cursor;
  } while (cursor);

  await Promise.all(deletes);
}
