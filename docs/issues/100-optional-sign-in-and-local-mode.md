# 100 - Allow meaningful local use without account sign-in

Status: in_progress
Area: Onboarding / Authentication / App Review
Priority: critical (release blocker 9)

## Problem

Physical devices cannot skip Sign in with Apple even though manual library management and on-device extraction are local features. This creates App Review risk and unnecessarily blocks privacy-preserving use.

## Acceptance Criteria

- [x] Onboarding offers a clear continue-without-account path on production devices.
- [ ] Library, manual book entry, local OCR, search, export, and settings work signed out.
- [ ] Account and subscription prompts appear only when a remote/account feature is requested.
- [ ] Signing in later preserves the existing local library.
- [ ] Sign-out does not delete local data without explicit confirmation.

## Verification

- Fresh-install UI test on a non-account path.
- Signed-out capture and local extraction tests.
- App Review notes describe which features require an account and why.
