# 094 - Align privacy declarations with retained account, usage, and image data

Status: in_progress
Area: Privacy / App Store Connect / Website
Priority: critical (release blocker 6)

## Problem

The published policy says captured images exist only in memory and that usage-pattern data is not collected. The app writes page captures to Documents, and the backend stores account-linked extraction counts and timestamps. The privacy manifest currently declares no collected data types.

## Acceptance Criteria

- [x] Website and in-app privacy text accurately describe local image persistence and deletion.
- [x] Account identifiers, purchase state, extraction usage, and retention periods are documented.
- [x] Google Books and Open Library metadata requests are disclosed where required.
- [x] Privacy manifest is reconciled with actual behavior; the matching App Store Connect answers are recorded for manual entry.
- [x] Data deletion and retention claims are testable and internally consistent.

## Verification

- Privacy data-flow inventory covering app, Worker, and third parties.
- App Store Connect questionnaire checklist review.
- Legal-copy snapshot tests or content assertions where practical.

## Progress

2026-07-14:

- Added the app privacy-manifest declarations for identity, email address, purchase history,
  account-linked usage data, remote-processing images, and remote-processing text. Each is
  marked as linked to the user only for app functionality, never tracking.
- Added matching Google Books and Open Library catalogue-lookup disclosures to the website and
  in-app Privacy Policy.
- Added the App Store Connect answer map in `docs/APP_STORE_CONNECT.md`; entering and reviewing
  those answers in App Store Connect remains a manual release step.
- Verified the local lifecycle claims with 35 iOS `PageCaptureTests` and `QuoteModelTests` passes
  on iPhone 17 (iOS 26.5), and the server-side deletion/usage claims with 8 backend
  account-revocation and atomic-rate-limit test passes plus a TypeScript typecheck.

2026-07-15 paywall-copy follow-up:

- Replaced the stale "Sync Everywhere" sales claim while CloudKit remains disabled in this v1
  release.
- Replaced the unsupported "never shared" privacy claim with accurate local-first, explicit
  remote-AI-consent wording. Provider retention evidence is recorded in
  `docs/AI_PROVIDER_RETENTION.md`.

## Dependencies

- Complete `093`, `095`, `096`, `097`, and `099` before final wording.
