# 093 - Obtain explicit consent before third-party AI image sharing

Status: in_progress
Area: Privacy / Onboarding / Capture
Priority: critical (release blocker 5)

## Problem

Camera permission and sign-in copy mention AI processing but do not obtain explicit permission before page or cover images are sent to third-party AI services. This does not satisfy the current App Review requirement for clear third-party AI disclosure and explicit permission.

## Acceptance Criteria

- [x] A dedicated consent screen identifies the categories of third parties and the data sent.
- [x] Consent is affirmative, versioned, locally persisted, and revocable from Settings.
- [x] Remote cover and quote extraction cannot run until consent is granted.
- [x] Declining consent leaves manual and on-device workflows usable.
- [ ] Consent copy and App Store privacy answers use the same terminology.

## Verification

- [x] Unit tests for consent state and remote-extraction gating.
- [x] UI tests for accept, decline, and revoke flows.
- Manual review against App Review Guidelines 5.1.1 and 5.1.2.

## Dependencies

- Complete `096` and `097` first so the disclosure describes final image behavior.
