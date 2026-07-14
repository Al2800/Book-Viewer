# Release readiness audit - 2026-07-14

## Revision Assessed

- Git revision: `b52c907` (`fix(ui): adapt library and extraction review layouts`).
- The project build number is still `38`; the latest TestFlight build 38 predates this revision.
  A new signed archive and upload, with the build number incremented, are required after the
  remaining release gates pass.

## Local Evidence

- Release iOS build completed successfully with:

  ```bash
  xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes \
    -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
  ```

- Subscription-account linkage and reconciliation tests passed: 9 tests, 0 failures, 0 skips.
  Result bundle: `/tmp/BookQuotes-subscription-reconciliation-final.xcresult`.
- The complete UI release target previously passed on this mainline work: 90 tests, 0 failures,
  0 skips on iPhone 17 and on iPad Air 11-inch. The subscription change above is separately
  compiled and covered by its focused tests.
- Adaptive-layout follow-up passed its focused simulator matrix: Library grid, Library list, and
  compact Extraction Review at Accessibility XXXL on iPhone 17; plus the normal-text,
  side-by-side Extraction Review on iPad Pro 13-inch. The corresponding screenshots were
  visually inspected. This resolves the automated portion of issue `105`.
- The full app-unit command returned success, but Xcode wrote an incomplete result bundle without
  `Info.plist`; do not use that rerun as countable release evidence. Re-run the full app-unit gate
  and retain a readable `.xcresult` before archiving.
- Backend tests and typecheck passed: 36 tests, 0 failures.
- Production Worker dependency audit reported no known vulnerabilities.
- A tracked-file secret-pattern scan found no credential material. The only match is the expected
  private-key format validation in `backend/src/subscription.ts`.

## Submission Blockers

1. Confirm the deployed Worker uses the approved Hugging Face provider route and record the
   Hugging Face and Gemini retention/zero-data-retention evidence. See issue `095`.
2. Run the staging load test for Durable Object extraction limits and the deployed-Worker
   account-deletion check. See issues `102` and `099`.
3. Test the next TestFlight build on physical hardware:
   - Sandbox purchase, intentionally interrupted reconciliation, Restore Purchases, then remote
     extraction as the restored customer.
   - Apple Sign In, Remote AI Processing consent accept/decline/revoke, and a real marked-page
     extraction.
   - Offline multi-page capture with interrupted connectivity, draft resume, and queue recovery.
   - Delete Account, then verify the old session cannot access refresh, subscription sync, or
     extraction endpoints.
   - Captured-image storage/backup behavior and real camera framing.
   These runs close the remaining evidence for issues `007`, `086`, `096`, `097`, `099`, and `101`.
4. Enter and review the App Privacy questionnaire and App Review Notes in App Store Connect using
   `docs/APP_STORE_CONNECT.md`. See issues `093`, `094`, and `086`.
5. Complete the remaining physical-device Accessibility/Dynamic Type/VoiceOver audit in issue
   `105`: VoiceOver order and source-image activation, Reduce Motion, rotation, and iPad
   split-view behavior.

## Residual Risks

- The website's production dependency audit reports two moderate inherited PostCSS advisories
  under Next.js. The available automatic fix proposes a breaking downgrade, so this remains an
  upstream website risk rather than an iOS-binary blocker.
- Existing Swift 6 concurrency and API deprecation warnings remain during Xcode builds. They do
  not fail the current Swift 5-mode build, but should be resolved before a Swift 6 migration.

## Decision

The codebase is simulator-ready and the iPad release gate is green. It is **not ready to submit
to App Review** until the production, physical-device, App Store Connect, and fresh-archive gates
above are completed and recorded.
