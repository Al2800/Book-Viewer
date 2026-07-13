const APP_ACCOUNT_NAMESPACE = 'bookquotes:subscription-account';

export function subscriptionKey(userId: string): string {
  return `sub:user:${userId}`;
}

export function originalTransactionOwnerKey(originalTransactionId: string): string {
  return `sub:owner:${originalTransactionId}`;
}

export function appAccountTokenKey(token: string): string {
  return `sub:token:${token.toLowerCase()}`;
}

export function notificationKey(notificationUUID: string): string {
  return `sub:notification:${notificationUUID}`;
}

export function appAccountTokenSeed(userId: string): string {
  return `${APP_ACCOUNT_NAMESPACE}:${userId}`;
}
