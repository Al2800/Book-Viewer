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

2026-07-15 local release gate follow-up:

- The complete app unit target passed on iPhone 17 / iOS 26.5: 632 tests passed, 0 failures,
  and 1 documented optional local-photo fixture skip. Result bundle:
  `/tmp/BookQuotes-full-unit-after-release-hardening-2026-07-15.xcresult`.
- An unsigned Release archive for generic iOS devices completed successfully. It contains an
  arm64 `com.acampbell.bookquotes` application at version `1.0` build `38`, plus its privacy
  manifest and dSYM. This proves the local Release build, not signing, upload, or App Store
  acceptance; those remaining gates stay open.
- The complete iPhone 17 UI target passed 101 tests, 0 failures, and 0 skips after the
  library-navigation and test-isolation regression repair. Result bundle:
  `/tmp/BookQuotes-full-ui-isolated-2026-07-15.xcresult`.
- The current regular-width extraction-review regression passed on iPad Air 11-inch (M4), iOS
  26.5: 1 test, 0 failures, and 0 skips. Result bundle:
  `/tmp/BookQuotes-extraction-review-ipad-current-layout-2026-07-15.xcresult`.
- The signed App Store distribution preflight passed after Xcode refreshed the automatic
  provisioning profile with `-allowProvisioningUpdates`. The local IPA has the distribution
  signature, Sign in with Apple entitlement, and `get-task-allow = false`. Its automatically
  managed build value is `39`; it was exported locally, not uploaded. The retained command,
  export profile, and remaining external gates are in
  `docs/refactor-foundation/verification/2026-07-15-signed-release-preflight.md`.
- A physical iPhone 17 / iOS 26.5.2 passed quote-editor keyboard typing and Save All navigation
  (2 tests, 0 failures), plus multi-page Process-to-Review and Save Draft-to-Resume workflows
  (2 tests, 0 failures). These are local development-build checks with deterministic fixtures;
  production subscription, remote AI, network-loss, and account-deletion TestFlight checks remain.

2026-07-15 build 40 direction recovery:

- Build 40 is release-stopped after device feedback: cover-photo recognition was the wrong book
  registration path, OCR had regressed into the primary quote path, the live camera appeared still,
  and subscription activation did not provide a usable route to remote AI.
- Commit `75b460d` restores consented remote AI as the first quote extractor with Apple Vision OCR
  fallback, makes ISBN scanning the default and only camera-based book registration route, waits
  for an actually configured camera session before constructing the preview, and guides sign-in,
  plan loading, retry, restore, and consent activation.
- Focused iPhone 17 simulator verification passed 61 unit tests with 1 hardware-only skip and 9
  user-flow tests with no failures. Backend verification passed 48 tests and TypeScript typecheck.
- Production Worker version `cc9350c2-d3a8-4a47-b291-a0fb8312b787` is deployed with the paid gate
  enabled. Live smoke returned `200` for health, `410 COVER_EXTRACTION_ROUTE_RETIRED` for the cover
  route before image parsing, and `401 AUTH_REQUIRED` for unauthenticated Hugging Face extraction.
- A signed development build compiled, installed, launched, and remained running on the connected
  iPhone 17. The reader confirmed moving live previews in both ISBN registration and quote capture,
  clearing the physical camera gate for replacement Build 41.
- Build 41 was archived from GitHub commit `b35d6fb`, exported with an App Store distribution
  signature, validated by Apple with no errors, and uploaded under delivery ID
  `a756cb97-8e92-4205-8a09-66a40a3d3088`.
- Apple processing completed with `VALID`, `APP_STORE_ELIGIBLE`, and
  `usesNonExemptEncryption: false`. The remaining open acceptance is the Build 41 TestFlight smoke
  for subscription purchase/restore, authenticated remote extraction, network loss and recovery,
  queued processing, and account deletion.
- Build 41 StoreKit returned no products despite correct product IDs, prices, UK/US availability,
  bundle ID, and In-App Purchase capability. App Store Connect Business inspection identified the
  external blocker: the Paid Apps Agreement is `Pending User Info`, no bank account is configured,
  and the U.S. tax questionnaire is missing. Subscription and remote-AI TestFlight acceptance must
  resume after the Account Holder completes those items and Apple's sandbox data propagates.
- On 2026-07-17, live App Store Connect Business inspection confirmed the Paid Apps Agreement,
  GBP bank account, both submitted US tax forms, and compliance are all `Active`. The external
  commerce blocker is cleared; subscription purchase, restore, entitlement reconciliation, and
  post-purchase remote-AI access remain pending physical-device TestFlight acceptance.
- After Apple propagation, Build 43 loaded the subscription options on the physical device,
  localized the storefront price from USD to GBP, and completed a trial signup. Product loading,
  localization, and trial purchase are accepted. Post-purchase remote-AI access, entitlement
  persistence, network-loss recovery, and Restore Purchases remain open.
