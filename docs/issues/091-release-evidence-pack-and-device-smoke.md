# 091 - Release evidence pack and device smoke

Status: in_progress
Area: Release / TestFlight / App Store Connect
Priority: high

## Problem

After extraction, backend, website, and quote detail readiness slices are green, the project needs a concise release evidence pack before another App Store submission push.

The evidence must cover both local verification and real-device TestFlight behaviour because subscription, camera, extraction, account deletion, and model-assisted quote capture cannot be proven fully by simulator tests alone.

## Acceptance Criteria

- [x] Xcode build passes from a clean pulled main.
- [x] Focused app unit tests pass for extraction, capture queue, account/subscription-facing settings, and quote detail.
- [x] Backend unit tests and typecheck pass.
- [x] Website build and production audit pass or documented risk is accepted.
- [x] Simulator smoke covers Library/Search, capture review route, settings/account deletion presentation, and quote detail edit path where available.
- [ ] TestFlight/device smoke covers subscription gate, sign-in, model-assisted extraction, offline/manual fallback, queue processing, and delete account after Worker deploy.
- [x] App Store privacy/account deletion/subscription notes are recorded for the submission checklist.

## Characterization Plan

- Treat simulator checks as necessary but not sufficient.
- Record exact commands, build number, Worker deployment state, and manual device results in `docs/refactor-foundation/verification/`.

## Related Issues

- `086-capture-ship-readiness.md`
- `087-quote-extraction-pipeline-deepening.md`
- `088-backend-entitlement-account-complexity-refactor.md`
- `089-website-dependency-privacy-readiness.md`
- `090-quote-detail-view-final-slice.md`

## Progress

2026-07-13:

- Added release verification note at `docs/refactor-foundation/verification/submission-checkpoint-2026-07-13.md`.
- Simulator UI smoke passed Library, Search, and Quote Capture extraction review.
- Simulator UI smoke failed Settings before assertions because the test launch could not find the Settings tab.
- Device/TestFlight smoke remains required for subscription-gated model extraction and account deletion.

2026-07-14:

- The complete UI target passed on both iPhone 17 and iPad Air 11-inch simulators: 90 tests,
  0 failures, and 0 skips on each form factor.
- A release-configured physical-device build completed successfully without code signing.
- Current release status and remaining production/device gates are recorded in
  `docs/refactor-foundation/verification/2026-07-14-release-readiness-audit.md`.
