# BookQuotes Backend Proxy

Cloudflare Workers serverless proxy for BookQuotes iOS app. Handles authentication, subscription validation, rate limiting, and proxies requests to the Gemini API.

## Architecture

```
iOS App → Cloudflare Workers Proxy → Gemini API
              ↓
         Validates:
         - Apple Sign-In JWT
         - App Store-verified subscription status
         - Rate limits (KV)
```

## Setup

### Prerequisites

- Node.js 18+
- Cloudflare account with Workers enabled
- Wrangler CLI (`npm install -g wrangler`)
- Apple Developer account (for Sign-In with Apple)
- Google AI Studio account (for Gemini API key)

### Installation

```bash
cd backend
npm install
```

### Configuration

1. **Create KV Namespace:**
   ```bash
   wrangler kv:namespace create KV
   wrangler kv:namespace create KV --preview
   ```
   Update `wrangler.toml` with the returned namespace IDs.

2. **Set Secrets:**
   ```bash
   wrangler secret put GEMINI_API_KEY
   wrangler secret put APPLE_TEAM_ID
   wrangler secret put JWT_SECRET
   wrangler secret put APPLE_BUNDLE_ID
   wrangler secret put APPLE_IAP_KEY_ID
   wrangler secret put APPLE_IAP_ISSUER_ID
   wrangler secret put APPLE_IAP_PRIVATE_KEY
   ```

3. **Configure Apple Sign-In:**
   - In Apple Developer Portal, create a Services ID for Sign in with Apple
   - Configure your app's bundle ID as the audience
   - Set `APPLE_TEAM_ID` to your app's bundle ID or team ID

4. **Configure App Store Server API:**
   - In App Store Connect, create an In-App Purchase key under `Users and Access > Integrations > In-App Purchase`
   - Set `APPLE_BUNDLE_ID` to `com.acampbell.bookquotes`
   - Set `APPLE_IAP_KEY_ID` and `APPLE_IAP_ISSUER_ID` from that key
   - Paste the `.p8` contents into `APPLE_IAP_PRIVATE_KEY`
   - Optional: set `APPLE_APP_ID` if you later add full notification JWS certificate-chain verification

### Development

```bash
npm run dev
```

This starts a local development server at `http://localhost:8787`.

### Deployment

```bash
# Deploy to development
npm run deploy

# Deploy to production
npm run deploy:production
```

## API Endpoints

### Authentication

#### `POST /api/auth/apple`
Exchange Apple Sign-In token for session token.

**Headers:**
- `Authorization: Bearer <apple_identity_token>`

**Response:**
```json
{
  "token": "session_token",
  "subscription": {
    "status": "trial",
    "expiresAt": "2024-01-15T00:00:00Z"
  }
}
```

### Extractions

By default, extraction endpoints require a signed-in user with an active subscription/trial record. During beta/TestFlight validation, the backend can explicitly allow signed-in users through the extraction gate with:

```text
ALLOW_AUTHENTICATED_EXTRACTION=true
```

This does not remove authentication or rate limits.

#### `POST /api/extract-cover`
Extract book metadata from cover image.

**Headers:**
- `Authorization: Bearer <session_token>`

**Body:** Gemini API request format with image data.

#### `POST /api/extract-quotes`
Extract quotes from book page image.

**Headers:**
- `Authorization: Bearer <session_token>`

**Body:** Gemini API request format with image data.

### Usage

#### `GET /api/usage`
Get current usage statistics.

**Headers:**
- `Authorization: Bearer <session_token>`

**Response:**
```json
{
  "extractionsThisMonth": 42,
  "extractionsLimit": 1000,
  "subscriptionStatus": "active",
  "expiresAt": "2024-02-15T00:00:00Z"
}
```

### Webhooks

#### `POST /api/subscription-webhook`
App Store Server Notification endpoint.

Configure this URL in App Store Connect for subscription status updates.

### Subscription Verification

#### `POST /api/subscription/sync`
Reconciles the signed-in user against the App Store Server API.

The app should send a verified StoreKit transaction identifier when it has one:

```json
{
  "transactionId": "2000000123456789",
  "originalTransactionId": "2000000098765432",
  "environment": "Sandbox"
}
```

If the device currently has no active entitlement, the app may send `{}` and the worker will refresh from the last known original transaction ID.

## Rate Limits

- **Per minute:** 30 requests
- **Per month:** 1000 extractions

## Error Responses

| Code | Status | Description |
|------|--------|-------------|
| `AUTH_REQUIRED` | 401 | Missing or invalid session token |
| `AUTH_INVALID` | 401 | Invalid Apple Sign-In token |
| `SUBSCRIPTION_REQUIRED` | 402 | No active subscription |
| `RATE_LIMIT` | 429 | Rate limit exceeded |
| `EXTRACTION_ERROR` | 500 | Gemini API error |
| `NOT_FOUND` | 404 | Unknown endpoint |

## Security

- Apple Sign-In tokens are verified against Apple's public keys
- Session tokens are signed with HS256 and expire after 7 days
- Gemini API key is never exposed to clients
- Subscription access is granted from App Store Server API state, not client-declared status
- `ALLOW_AUTHENTICATED_EXTRACTION=true` is an explicit beta policy for validating extraction before subscription purchase is available
- Subscription ownership is bound to a deterministic `appAccountToken`
- App Store notifications trigger server-side reconciliation before entitlements are mutated
- The worker stores the normalized entitlement cache in Cloudflare KV
- CORS headers allow requests from any origin (iOS app)
