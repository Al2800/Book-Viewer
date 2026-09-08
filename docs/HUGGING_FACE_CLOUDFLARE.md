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

Production deployment metadata rechecked on 2026-09-08:

```text
Version ID: ae5a598e-98e8-47c9-b48a-23d652aa697d (deployed 2026-07-17)
Route: api.bookquotes.uk/*
HF_API_TOKEN: configured as a Cloudflare production secret (value not readable)
HF_MODEL_ID: Qwen/Qwen2.5-VL-72B-Instruct:featherless-ai
```

Incident `book-quote-cbjb`: a subscribed Build 61 tester reports failed-page processing. `/health` returned HTTP 200 and Hugging Face's model/provider mapping listed Featherless as live; neither is an end-to-end extraction check. A direct synthetic text-only inference using the existing **local cached** Hugging Face token returned HTTP 401, `OAuth token signature verification failed`. This does not establish that the deployed secret has the same value or that the tester's subscription was rejected. The initial bounded production log observation saw no requests. A subsequent sanitized observation captured three user extraction retries: each returned HTTP 402 with an explicit `huggingface_provider_error` status 402. Usage and subscription sync returned 200. The provider error establishes that these extraction attempts passed the app-side gate and reached upstream; it does not identify the precise billing reason or prove exhausted credits.

### CLI/account follow-up — 2026-09-08

`hf` was absent from PATH. `uv tool run --from huggingface_hub hf auth whoami` ran the official CLI, automatically refreshed the expired local OAuth access token and confirmed account `AlCampbell`. No production secret was changed. The SDK account response reports personal PRO, `canPay: true`, `billingMode: prepaid`, and no organisations. Neither this response nor the available CLI/SDK commands reports the remaining dollar balance; the user's stated monthly $2 allowance was not independently measured.

With that refreshed local credential, official SDK requests on Qwen2.5-VL-72B/Featherless succeeded for synthetic text and a generated blank image (`{"quotes":[]}`). A request to the same OpenAI-compatible router endpoint/model suffix used by production also returned HTTP 200 using standard Hugging Face SDK headers. An earlier Python-urllib probe returned a Featherless Cloudflare 403/1010 HTML page; it was not a billing rejection, and SDK/header-compatible probes subsequently succeeded. No user photographs were used.

These successes show that inference is available to the checked account, not that production is repaired or that its opaque secret belongs to the same account. Investigate production credential/billing context and any transient provider rejection rather than asking the tester to buy another app subscription or assuming more credits are required. Do not expose tokens, bypass subscriptions, switch providers or copy a rotating CLI OAuth credential into production as a permanent service secret.
