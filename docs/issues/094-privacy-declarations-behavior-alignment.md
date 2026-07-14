# 094 - Align privacy declarations with retained account, usage, and image data

Status: open
Area: Privacy / App Store Connect / Website
Priority: critical (release blocker 6)

## Problem

The published policy says captured images exist only in memory and that usage-pattern data is not collected. The app writes page captures to Documents, and the backend stores account-linked extraction counts and timestamps. The privacy manifest currently declares no collected data types.

## Acceptance Criteria

- [ ] Website and in-app privacy text accurately describe local image persistence and deletion.
- [ ] Account identifiers, purchase state, extraction usage, and retention periods are documented.
- [ ] Google Books and Open Library metadata requests are disclosed where required.
- [ ] Privacy manifest and App Store Connect answers are reconciled with actual behavior.
- [ ] Data deletion and retention claims are testable and internally consistent.

## Verification

- Privacy data-flow inventory covering app, Worker, and third parties.
- App Store Connect questionnaire checklist review.
- Legal-copy snapshot tests or content assertions where practical.

## Dependencies

- Complete `093`, `095`, `096`, `097`, and `099` before final wording.

