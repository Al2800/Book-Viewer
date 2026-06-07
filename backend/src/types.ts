// Environment bindings for Cloudflare Workers
export interface Env {
  // KV Namespace for subscriptions and usage
  KV: KVNamespace;

  // Secrets
  GEMINI_API_KEY: string;
  HF_API_TOKEN?: string;
  APPLE_TEAM_ID: string;
  JWT_SECRET: string;
  APPLE_BUNDLE_ID: string;
  APPLE_IAP_KEY_ID: string;
  APPLE_IAP_ISSUER_ID: string;
  APPLE_IAP_PRIVATE_KEY: string;
  APPLE_APP_ID?: string;

  // Variables
  ENVIRONMENT: string;
  ALLOW_AUTHENTICATED_EXTRACTION?: string;
  HF_MODEL_ID?: string;
}

export type SubscriptionStatus =
  | 'none'
  | 'trial'
  | 'active'
  | 'billing_retry'
  | 'grace_period'
  | 'expired'
  | 'canceled'
  | 'revoked';

export type ClientSubscriptionStatus =
  | 'none'
  | 'trial'
  | 'active'
  | 'expired'
  | 'canceled';

export type AppStoreEnvironment = 'Production' | 'Sandbox';

// Subscription status stored in KV
export interface SubscriptionRecord {
  schemaVersion: 2;
  userId: string;
  status: SubscriptionStatus;
  productId: string;
  expiresAt?: string;
  gracePeriodExpiresAt?: string;
  originalTransactionId: string;
  latestTransactionId: string;
  appAccountToken?: string;
  environment: AppStoreEnvironment;
  autoRenewStatus?: boolean;
  isInBillingRetryPeriod?: boolean;
  offerType?: number;
  offerIdentifier?: string;
  ownershipType?: string;
  revocationDate?: string;
  revocationReason?: number;
  transactionSignedDate?: string;
  renewalSignedDate?: string;
  lastVerifiedAt: string;
  source: 'app_store_server_api' | 'app_store_server_notification' | 'legacy_claim';
}

export interface SubscriptionOwnerRecord {
  userId: string;
  originalTransactionId: string;
  linkedAt: string;
  source: 'verified_app_account_token' | 'legacy_claim';
}

// Usage record stored in KV
export interface UsageRecord {
  userId: string;
  period: string; // YYYY-MM format
  extractionCount: number;
  lastUpdated: string;
}

// Rate limit configuration
export interface RateLimitConfig {
  maxRequestsPerMinute: number;
  maxRequestsPerIPPerMinute: number;
  maxExtractionsPerMonth: number;
}

// Apple Sign-In JWT payload
export interface AppleJWTPayload {
  iss: string;
  aud: string;
  exp: number;
  iat: number;
  sub: string; // User ID
  email?: string;
  email_verified?: boolean;
  is_private_email?: boolean;
  real_user_status?: number;
}

// Gemini API request/response types
export interface GeminiRequest {
  contents: Array<{
    parts: Array<{
      text?: string;
      inlineData?: {
        mimeType: string;
        data: string; // base64
      };
    }>;
  }>;
  generationConfig?: {
    temperature?: number;
    topK?: number;
    topP?: number;
    maxOutputTokens?: number;
    responseMimeType?: string;
  };
}

export interface GeminiResponse {
  candidates: Array<{
    content: {
      parts: Array<{
        text: string;
      }>;
    };
    finishReason: string;
  }>;
  usageMetadata?: {
    promptTokenCount: number;
    candidatesTokenCount: number;
    totalTokenCount: number;
  };
}

// API response types
export interface UsageResponse {
  extractionsThisMonth: number;
  extractionsLimit: number;
  subscriptionStatus: string;
  expiresAt?: string;
}

export interface ErrorResponse {
  error: string;
  code: string;
  details?: string;
}

export interface SubscriptionSyncRequest {
  transactionId?: string;
  originalTransactionId?: string;
  appAccountToken?: string;
  environment?: string;
}

export interface SubscriptionSyncResponse {
  ok: true;
  status: ClientSubscriptionStatus;
  rawStatus: SubscriptionStatus;
  expiresAt?: string;
  productId?: string;
  checkedAt: string;
  source: 'app_store_server_api' | 'cache';
}
