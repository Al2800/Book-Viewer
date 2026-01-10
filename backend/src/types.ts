// Environment bindings for Cloudflare Workers
export interface Env {
  // KV Namespace for subscriptions and usage
  KV: KVNamespace;

  // Secrets
  GEMINI_API_KEY: string;
  APPLE_TEAM_ID: string;
  JWT_SECRET: string;

  // Variables
  ENVIRONMENT: string;
}

// Subscription status stored in KV
export interface SubscriptionRecord {
  userId: string;
  status: 'active' | 'expired' | 'canceled' | 'trial';
  productId: string;
  expiresAt: string; // ISO date
  originalTransactionId?: string;
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
