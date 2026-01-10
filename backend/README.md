# BookQuotes Backend Proxy

Cloudflare Workers serverless proxy for BookQuotes iOS app. Handles authentication, subscription validation, rate limiting, and proxies requests to the Gemini API.

## Architecture

```
iOS App → Cloudflare Workers Proxy → Gemini API
              ↓
         Validates:
         - Apple Sign-In JWT
         - Subscription status (KV)
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
   ```

3. **Configure Apple Sign-In:**
   - In Apple Developer Portal, create a Services ID for Sign in with Apple
   - Configure your app's bundle ID as the audience
   - Set `APPLE_TEAM_ID` to your app's bundle ID or team ID

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
- All subscription status is stored in Cloudflare KV
- CORS headers allow requests from any origin (iOS app)
