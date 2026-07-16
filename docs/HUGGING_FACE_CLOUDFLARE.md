# Hugging Face and Cloudflare Quote Extraction

This runbook describes how BookQuotes uses Hugging Face model inference through the Cloudflare Worker proxy.

## Architecture

```text
iPhone app
-> api.bookquotes.uk Cloudflare Worker
-> Hugging Face router
-> Qwen/Qwen2.5-VL-72B-Instruct
-> Cloudflare Worker
-> iPhone quote review
```

The iOS app never stores a Hugging Face token. It sends authenticated requests to the existing BookQuotes proxy. The Worker reads `HF_API_TOKEN` from Cloudflare secrets and calls Hugging Face.

## Runtime Flow

1. The user captures a quote page in the iOS app.
2. `ExtractionReviewView` processes pending page captures through `ModelAssistedQuoteExtractor`.
3. `ModelAssistedQuoteExtractor` calls `RemoteModelQuoteExtractor` first. Model-assisted extraction is the primary path for quote capture because OCR-only selection misses real-page lines and margin/bracket spans.
4. A valid remote response is authoritative, including an empty quote list. If the remote model
   fails, the review screen keeps that failure visible and offers Retry AI, an explicit on-device
   attempt, or manual entry; it does not silently replace the result with OCR.
5. `RemoteModelQuoteExtractor` sends the same Gemini-shaped request body to:

```text
POST https://api.bookquotes.uk/api/extract-quotes-hf
```

6. The Cloudflare Worker validates:

- app session token;
- beta/subscription access policy;
- request size and image format;
- rate limits.

7. The Worker converts the request into Hugging Face router chat-completions format and calls:

```text
POST https://router.huggingface.co/v1/chat/completions
```

8. Hugging Face routes the request to the selected provider/model using the configured model id.
9. The Worker normalizes the model response back into the existing Gemini-compatible response envelope.
10. The iOS app parses the response into `QuoteExtractionResult` and shows editable quote cards.

## Backend Configuration

Cloudflare Worker secrets:

```bash
cd backend
npx wrangler secret put HF_API_TOKEN --env production
```

Optional Worker variable:

```text
HF_MODEL_ID
```

If `HF_MODEL_ID` is not set, the backend defaults to:

```text
Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai
```

The explicit provider suffix prevents Hugging Face's router from dynamically selecting a different
processor for page images. Provider changes require a privacy and retention review before deployment.

## Billing

Model inference is billed through Hugging Face because requests authenticate with `HF_API_TOKEN` and use Hugging Face routed inference.

Cloudflare can still bill normal proxy usage:

- Worker request invocations;
- Worker CPU time;
- KV reads/writes for auth, subscription, usage, and rate limiting.

This implementation does not call Cloudflare Workers AI, so it should not create Workers AI model-inference charges.

## Deployment Process

1. Confirm Hugging Face CLI auth:

```bash
hf auth whoami
```

2. Confirm Cloudflare Wrangler auth:

```bash
cd backend
npx wrangler whoami
```

3. Set or rotate the Hugging Face token in Cloudflare:

```bash
tr -d "\n" < ~/.cache/huggingface/token | npx wrangler secret put HF_API_TOKEN --env production
```

4. Run backend tests:

```bash
npx vitest run
npm run typecheck
```

5. Deploy the Worker:

```bash
npx wrangler deploy --env production
```

6. Check production health:

```bash
curl https://api.bookquotes.uk/health
```

Expected response:

```json
{"status":"ok","version":"1.0.0"}
```

## TestFlight Process

1. Run the focused iOS release gate.
2. Bump `CURRENT_PROJECT_VERSION`.
3. Archive the iOS app.
4. Upload to App Store Connect.
5. Verify build processing and encryption status using:

```bash
BUILD_NUMBER=<build> node scripts/appstoreconnect_status.js --set-encryption-false
```

6. In TestFlight, test:

- clear underlined passage;
- faint pencil underline;
- vertical margin-line marked paragraph;
- multiple marked passages on the same page;
- difficult page curvature or partial OCR line breaks.

## Current Production State

Last verified production Worker deploy:

```text
Version ID: 68c35e56-9836-42f4-aa0f-0a79439d6290
Route: api.bookquotes.uk/*
HF_API_TOKEN: configured as a Cloudflare production secret
HF_MODEL_ID: configured as Qwen/Qwen2.5-VL-72B-Instruct:preferred
```
