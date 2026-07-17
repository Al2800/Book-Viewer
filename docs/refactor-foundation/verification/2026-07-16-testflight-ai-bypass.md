# TestFlight AI Bypass Window (Closed)

Status: closed on 2026-07-17 after paid-subscription acceptance.

## Purpose

Build 41 cannot currently obtain subscription products while App Store Connect banking and the
Paid Apps Agreement finish processing. This temporary backend-only window allows authenticated
TestFlight users to test the remote AI workflow independently from StoreKit availability.

## Controls

- The bypass still requires a valid signed-in session.
- Existing per-user and per-network extraction limits remain enforced.
- Production enables `ALLOW_AUTHENTICATED_EXTRACTION=true` only alongside
  `AUTHENTICATED_EXTRACTION_BYPASS_UNTIL=2026-07-19T00:00:00Z`.
- Missing, invalid, or elapsed expiry values fail closed and require a verified subscription.
- Build 42 recognizes TestFlight's sandbox receipt and allows a signed-in tester to grant the
  required remote-processing consent during the same window. App Store receipts are not eligible.

## Remaining Release Gate

This window validates remote AI extraction and the surrounding capture/review workflow only. It
does not validate StoreKit product loading, purchase, restore, backend entitlement reconciliation,
or post-purchase AI access. Those checks remain mandatory after App Store Connect activates the
commercial agreement, and the bypass variables must be removed before App Store submission.

On 2026-07-17, live App Store Connect Business inspection confirmed the Paid Apps Agreement, bank
account, tax forms, and compliance are all `Active`. The remaining gate is therefore the StoreKit
and post-purchase TestFlight acceptance run after sandbox propagation, followed by removal of the
temporary bypass.

## Closure

The physical-device acceptance pass successfully loaded the subscription products, completed the
paid subscription, unlocked remote AI through the reconciled entitlement, and opened Apple's
subscription-management flow. Delete Account and subsequent sign-in also passed; local books
remained on device as designed because account deletion removes server identity and entitlement
state, not the local library.

The bypass variables were removed from `backend/wrangler.toml` and production Worker version
`ae5a598e-98e8-47c9-b48a-23d652aa697d` was deployed. Its reported production bindings omit both
`ALLOW_AUTHENTICATED_EXTRACTION` and `AUTHENTICATED_EXTRACTION_BYPASS_UNTIL`. The post-deployment
health check returned HTTP 200, and unauthenticated extraction returned HTTP 401 `AUTH_REQUIRED`.
Backend verification passed 11 test files, 50 tests, and TypeScript type checking.

After deployment, the subscribed tester completed another remote-AI extraction using the same
Build 44 binary. This accepts the genuine subscription path with the bypass absent and confirms
that no replacement app build was required for the bypass removal itself. A subsequent recovery
pass accepted network-loss and Retry AI behavior, but exposed separate launch-session restoration
and Restore Purchases UX failures that are corrected in Build 45.

## Deployment Verification

- Production Worker version: `bb4eeb81-24eb-489e-8d79-6fa7984e01ea`.
- `GET /health` returned HTTP 200.
- An unauthenticated `POST /api/extract-quotes-hf` returned HTTP 401 `AUTH_REQUIRED`.
- Backend verification passed: 11 test files, 49 tests, and TypeScript type checking.
- Build 42 focused iOS tests passed for consent persistence, TestFlight receipt and expiry
  enforcement, remote-model-first extraction, and on-device OCR fallback.
- The first signed Build 42 archive predated the Build 41 extraction feedback corrections and was
  deleted before the corrected replacement archive was created.
- Xcode's App Store Connect account session was restored on 2026-07-16.
- The post-feedback Build 42 archive from commit `0dab41e` uploaded successfully, completed Apple
  processing, and is assigned to the internal `Test v1` group without a compliance warning.
