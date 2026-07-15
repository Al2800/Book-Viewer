# BookQuotes Backend Proxy

Cloudflare Workers serverless proxy for BookQuotes iOS app. Handles authentication,
subscription validation, atomic rate limiting, and quote-page extraction through the approved
Hugging Face provider. Book registration uses ISBN catalogue lookup directly from the app.

## Architecture

```
iOS App → Cloudflare Workers Proxy → Hugging Face (quote pages)
                    ↓
               Validates:
               - Apple Sign-In JWT
               - App Store-verified subscription status
               - Atomic rate limits (Durable Objects)
```

## Setup

### Prerequisites

- Node.js 18+
- Cloudflare account with Workers enabled
- Wrangler CLI (`npm install -g wrangler`)
- Apple Developer account (for Sign-In with Apple)

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
   Update `wrangler.toml` with the returned namespace IDs. The checked-in
   Durable Object binding and `v1` SQLite migration create the atomic rate-limit
   coordinator on the first deploy; do not remove that migration from later deployments.

2. **Set Secrets:**
   ```bash
   wrangler secret put APPLE_TEAM_ID
   wrangler secret put JWT_SECRET
   wrangler secret put APPLE_BUNDLE_ID
   wrangler secret put APPLE_IAP_KEY_ID
   wrangler secret put APPLE_IAP_ISSUER_ID
   wrangler secret put APPLE_IAP_PRIVATE_KEY
   wrangler secret put HF_API_TOKEN
   ```

   For model-assisted quote extraction, set `HF_MODEL_ID` to an explicitly
   approved provider route, for example
   `Qwen/Qwen2.5-VL-72B-Instruct:hf-inference`. Routing policies such as
   `:preferred`, `:fastest`, and `:cheapest` are rejected by the Worker. Adding
   a provider requires a privacy and retention review before deployment.

3. **Configure Apple Sign-In:**
   - In Apple Developer Portal, enable Sign in with Apple for the app
   - Apple identity tokens use the **bundle ID** as `aud`
   - Set `APPLE_BUNDLE_ID` to `com.acampbell.bookquotes` (Sign in with Apple JWT audience + IAP bundle checks)
   - Set `APPLE_TEAM_ID` to your Apple Developer Team ID (kept for Apple portal alignment; Sign in with Apple verification uses `APPLE_BUNDLE_ID`)

4. **Configure App Store Server API:**
   - In App Store Connect, create an In-App Purchase key under `Users and Access > Integrations > In-App Purchase`
   - Set `APPLE_BUNDLE_ID` to `com.acampbell.bookquotes`
   - Set `APPLE_IAP_KEY_ID` and `APPLE_IAP_ISSUER_ID` from that key
   - Paste the `.p8` contents into `APPLE_IAP_PRIVATE_KEY`
   - App Store Server Notification / API JWS payloads are signature-verified against Apple Root CA - G3 (`nodejs_compat` required)

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

### Staging verification

Run these only against a disposable staging account and Worker. Both commands require an explicit
confirmation flag and never print the supplied session token or request image.

```bash
STAGING_BASE_URL=https://your-staging-worker.example \
STAGING_SESSION_TOKEN=... \
STAGING_CONFIRM_RATE_LIMIT_LOAD=true \
npm run verify:staging-rate-limit

STAGING_BASE_URL=https://your-staging-worker.example \
STAGING_SESSION_TOKEN=... \
STAGING_CONFIRM_ACCOUNT_DELETE=true \
npm run verify:staging-account-deletion
```

The rate-limit check sends 31 concurrent quote requests by default and expects at least one
`429 RATE_LIMIT` response. The account-deletion check permanently deletes the staging account,
then verifies that its old token cannot access usage, subscription sync, or quote extraction.

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

By default, extraction endpoints require a signed-in user with an active subscription/trial record. For temporary beta/TestFlight validation only, the backend can allow signed-in users through the extraction gate with:

```text
ALLOW_AUTHENTICATED_EXTRACTION=true
```

Production ships with this flag **unset/false** so extraction requires an active subscription. This does not remove authentication or rate limits.

Session tokens include a server-side session version. Deleting an account increments that version
before data deletion, invalidating all previously issued session tokens. A later Sign in with Apple
creates a new session version for the same Apple identifier.

#### `POST /api/extract-cover`
Retired. Returns `410 COVER_EXTRACTION_ROUTE_RETIRED` before authentication, request parsing, or
provider forwarding. The app scans ISBN barcodes and uses catalogue metadata instead.

#### `POST /api/extract-quotes-hf`
Extract quotes from a book page through the approved Hugging Face provider route.

**Headers:**
- `Authorization: Bearer <session_token>`
- `Idempotency-Key: <new UUID for one extraction attempt>`

**Body:** BookQuotes quote-extraction request format with prompt and inline image data.

`POST /api/extract-quotes` is retired and returns `410 QUOTE_EXTRACTION_ROUTE_RETIRED`
without parsing or forwarding the image. This prevents legacy page-quote traffic from reaching
Gemini outside the approved provider contract.

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

- **Per user:** 30 requests per minute and 1000 successful extractions per month.
- **Per network:** 120 extraction requests per minute across accounts.
- Limits are coordinated by named SQLite-backed Durable Objects, not Cloudflare KV
  read-modify-write operations. Existing monthly KV counts are read once when a user
  first reaches the coordinator, then all new state is stored atomically in that object.
- An extraction reserves monthly capacity before the image is forwarded. A provider
  success finalizes that reservation exactly once for its `Idempotency-Key`; provider
  failures, invalid requests, and Worker-side errors release it. Every attempt still
  consumes its short per-minute abuse-prevention slot.
- A client disconnect does not change this policy: the Worker charges only when the
  provider call returns success, and releases the reservation for a failed provider call.
  In-progress reservations expire after five minutes to recover from an interrupted Worker.
- Operations logs record only route, decision, and outcome. They do not record prompts,
  images, account identifiers, IP addresses, or idempotency keys.

Before production deployment, run a concurrent staging load test that exceeds each
configured limit and confirm no provider calls occur after a rejected reservation.

## Error Responses

| Code | Status | Description |
|------|--------|-------------|
| `AUTH_REQUIRED` | 401 | Missing or invalid session token |
| `AUTH_INVALID` | 401 | Invalid Apple Sign-In token |
| `SUBSCRIPTION_REQUIRED` | 402 | No active subscription |
| `RATE_LIMIT` | 429 | Rate limit exceeded |
| `IDEMPOTENCY_INVALID` | 400 | Missing or malformed extraction idempotency key |
| `IDEMPOTENCY_IN_PROGRESS` | 409 | The same extraction attempt is still running |
| `IDEMPOTENCY_REPLAY` | 409 | The same extraction attempt was already charged |
| `RATE_LIMIT_UNAVAILABLE` | 503 | Atomic usage coordinator temporarily unavailable |
| `EXTRACTION_ERROR` | 500 | Gemini API error |
| `NOT_FOUND` | 404 | Unknown endpoint |

## Security

- Apple Sign-In tokens are verified against Apple's public keys
- Session tokens are signed with HS256 and expire after 7 days
- Gemini API key is never exposed to clients
- Subscription access is granted from App Store Server API state, not client-declared status
- `ALLOW_AUTHENTICATED_EXTRACTION=true` is a temporary beta-only policy; production leaves it unset so subscription gating stays enforced
- Subscription ownership is bound to a deterministic `appAccountToken`
- App Store notifications trigger server-side reconciliation before entitlements are mutated
- The worker stores the normalized entitlement cache in Cloudflare KV
- CORS headers allow requests from any origin (iOS app)
