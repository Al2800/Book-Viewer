# TestFlight AI Bypass Window

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
- No iOS rebuild is required.

## Remaining Release Gate

This window validates remote AI extraction and the surrounding capture/review workflow only. It
does not validate StoreKit product loading, purchase, restore, backend entitlement reconciliation,
or post-purchase AI access. Those checks remain mandatory after App Store Connect activates the
commercial agreement, and the bypass variables must be removed before App Store submission.

## Deployment Verification

- Production Worker version: `bb4eeb81-24eb-489e-8d79-6fa7984e01ea`.
- `GET /health` returned HTTP 200.
- An unauthenticated `POST /api/extract-quotes-hf` returned HTTP 401 `AUTH_REQUIRED`.
- Backend verification passed: 11 test files, 49 tests, and TypeScript type checking.
