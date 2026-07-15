# 095 - Make AI provider routing and retention claims enforceable

Status: in_progress
Area: Backend / AI Providers / Privacy
Priority: critical (release blocker 7)

## Problem

The Hugging Face model uses `:preferred`, which may route requests to external inference providers with separate policies. The privacy policy nevertheless promises that images are not retained. Gemini may retain prompts for abuse monitoring unless the account has zero-data-retention approval.

## Acceptance Criteria

- [x] Production routing uses an explicitly approved provider or an allowlist with reviewed terms.
- [x] Provider identity is documented and enforced operationally.
- [x] Retention claims do not exceed the contractual guarantees of every active provider.
- [x] Provider changes require a privacy review before deployment.
- [x] A no-remote-processing mode remains available.

## Verification

- [x] Backend tests for provider selection and rejected providers.
- [ ] Deployment configuration review.
- [ ] Recorded evidence of provider retention terms or ZDR approval.

## Implementation Notes

Quote-page extraction defaults to the explicitly routed `hf-inference` provider and rejects
dynamic-routing suffixes such as `:preferred`, `:fastest`, and `:cheapest` before image parsing
or forwarding. The Worker allowlist is the deployment control point; changing it requires a
privacy and retention review. The user-facing policy no longer makes provider-retention claims
outside BookQuotes' control, and remote processing remains an explicit, revocable choice.

This remains open until production deployment is confirmed with a supported `hf-inference` model
route and the applicable provider terms (including Google Gemini's retention configuration) are
recorded by the account owner.

2026-07-15 route retirement follow-up:

- Retired `POST /api/extract-quotes`, the legacy Gemini page-quote endpoint. It now returns
  `410 QUOTE_EXTRACTION_ROUTE_RETIRED` before request parsing, authentication, rate-limit
  reservation, or provider forwarding.
- `POST /api/extract-quotes-hf` is the sole Worker route for quote-page images and continues to
  reject unapproved Hugging Face provider suffixes before reading or forwarding an image.
- Migrated the account-deletion extraction race regression to the approved Hugging Face route so
  that revocation coverage matches the production quote path.
- Full backend verification passed: 36 tests, 0 failures; `npm run typecheck` passed.
- Deployment configuration review and recorded Hugging Face/Gemini retention evidence remain
  required before submission.

2026-07-15 production inspection and deployment-preflight follow-up:

- Read-only Cloudflare inspection found the active production Worker version dated 2026-06-07.
  It has `HF_API_TOKEN` and `HF_MODEL_ID` configured, but still exposes the old deployment shape:
  `ALLOW_AUTHENTICATED_EXTRACTION=true` and no `EXTRACTION_LIMITER` binding.
- `backend/wrangler.toml` now makes the production contract explicit: subscription bypass is
  `false`, quote pages are pinned to `Qwen/Qwen2.5-VL-72B-Instruct:hf-inference`, the bundle ID
  is pinned for Apple Sign-In audience validation, and the atomic limiter binding is present.
- `wrangler deploy --env production --dry-run` verified that the next deployment contains the
  Durable Object, production KV namespace, disabled bypass, approved model route, and bundle ID.
- The production secret inventory is missing `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`, and
  `APPLE_IAP_PRIVATE_KEY`. Provision those App Store Server API credentials before deploying the
  subscription-gated production Worker; do not substitute placeholder values.

2026-07-15 deployment-tooling follow-up:

- Upgraded the Worker deployment toolchain from the obsolete Wrangler 3 line to Wrangler 4,
  including its required Cloudflare Worker type definitions and the compatible Vitest version.
- The current Node 22.12+ runtime satisfies the declared toolchain requirement. A clean
  lockfile install, backend typecheck, and all 39 tests passed; `wrangler deploy --env production
  --dry-run` passed with the expected production bindings, and
  `npm audit --audit-level=moderate` reported zero vulnerabilities.
- This removes a local release-tooling security risk; it does not replace the missing production
  secrets, actual deployment, or provider-retention evidence.
