# 100 - Allow meaningful local use without account sign-in

Status: closed
Area: Onboarding / Authentication / App Review
Priority: critical (release blocker 9)

## Problem

Physical devices cannot skip Sign in with Apple even though manual library management and on-device extraction are local features. This creates App Review risk and unnecessarily blocks privacy-preserving use.

## Acceptance Criteria

- [x] Onboarding offers a clear continue-without-account path on production devices.
- [x] Library, manual book entry, local OCR, search, export, and settings work signed out.
- [x] Account and subscription prompts appear only when a remote/account feature is requested.
- [x] Signing in later preserves the existing local library.
- [x] Sign-out does not delete local data without explicit confirmation.

## Verification

- Fresh-install UI test on a non-account path.
- Signed-out capture and local extraction tests.
- App Review notes describe which features require an account and why.

## Progress

- The signed-out account screen now describes the account as optional and scopes it to remote AI
  processing and subscriptions; it no longer presents sign-in as a prerequisite for the app.
- The onboarding UI tests start from a cleared authentication state and verify the local-only
  path reaches the library, Settings/export, and manual book entry.
- The extraction pipeline test verifies that a remote authentication requirement falls back to
  on-device OCR with the correct provenance. Existing local search and export integration tests
  cover the same SwiftData-owned library without an account dependency.
- `AuthService` owns only the account session and Keychain credentials; it never accesses the
  local SwiftData library. The sign-out confirmation explicitly says local data remains on-device.
- App Review instructions are recorded in `docs/APP_STORE_CONNECT.md`.
- Verified on iPhone 17 (iOS 26.5): all 13 `OnboardingFlowTests` passed, including the new
  signed-out Settings/export and manual-entry workflows. The signed-out remote-auth fallback
  test also passed in `OnDeviceQuoteExtractorTests`.
