# Release readiness audit - 2026-07-14

## Revision Assessed

- Baseline Git revision: `b52c907` (`fix(ui): adapt library and extraction review layouts`).
- Latest locally verified code revision: `147a198` (`fix(capture): stabilize quote editor focus`).
- The project build number is still `38`; the latest TestFlight build 38 predates this revision.
  A new signed archive and upload, with the build number incremented, are required after the
  remaining release gates pass.

## Local Evidence

- Release iOS build completed successfully after `147a198` with:

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
- Custom marking identities now survive on-device or model-assisted extraction, cached review,
  queued processing, and quote saving. The focused regression gate passed on 2026-07-15 in
  49.802 seconds, and the unsigned Release build completed successfully after the change.
- The legacy Gemini quote-page endpoint now returns `410` before parsing or forwarding an image;
  quote pages can only use the approved Hugging Face route, which rejects dynamic provider
  suffixes. The backend suite passed: 36 tests, 0 failures; TypeScript typecheck passed.
- Quote editor interaction is covered by a native UIKit text editor that retries initial focus
  through sheet presentation and does not overwrite an active edit with stale SwiftUI state.
  The capture, extraction-review, and quote-save regression set passed on 2026-07-15: 20 tests,
  0 failures, 0 skips in 382.707 seconds on iPhone 17. Result bundle:
  `/tmp/bookquotes-capture-regression-2026-07-15.xcresult`.
- The direct quote-editor typing test also passed on iPad Air 11-inch (M4), iOS 26.5: 1 test,
  0 failures, 0 skips in 90.072 seconds. Result bundle:
  `/tmp/bookquotes-quote-editor-ipad-2026-07-15.xcresult`.
- The full app-unit gate passed on 2026-07-15 with a complete, readable result bundle:
  615 tests passed, 0 failed, and 1 skipped in 242.649 seconds on iPhone 17. The skip is the
  documented local-only real-book-photo fixture (`testRealBookFixtureExtractsUnderlinedPassageWhenProvided`).
  Result bundle: `/tmp/BookQuotes-app-unit-2026-07-15.xcresult` (`Info.plist` verified present).
- Backend tests and typecheck passed: 36 tests, 0 failures.
- Production Worker dependency audit reported no known vulnerabilities.
- A tracked-file secret-pattern scan found no credential material. The only match is the expected
  private-key format validation in `backend/src/subscription.ts`.

## Submission Blockers

1. Provision the three missing App Store Server API secrets (`APPLE_IAP_KEY_ID`,
   `APPLE_IAP_ISSUER_ID`, and `APPLE_IAP_PRIVATE_KEY`), then deploy the preflight-verified
   Worker. The currently deployed June Worker has `ALLOW_AUTHENTICATED_EXTRACTION=true` and no
   atomic limiter binding; it is not the release configuration. After deployment, confirm the
   pinned `hf-inference` route and record Hugging Face/Gemini retention evidence. See issue `095`.
2. Run the guarded staging checks with a disposable account: `npm run verify:staging-rate-limit`
   for Durable Object extraction limits, then `npm run verify:staging-account-deletion` for
   deployed-Worker session revocation. See issues `102` and `099`.
3. Test the next TestFlight build on physical hardware:
   - Sandbox purchase, intentionally interrupted reconciliation, Restore Purchases, then remote
     extraction as the restored customer.
   - Apple Sign In, Remote AI Processing consent accept/decline/revoke, and a real marked-page
     extraction.
   - Offline multi-page capture with interrupted connectivity, draft resume, and queue recovery.
   - Delete Account, then verify the old session cannot access refresh, subscription sync, or
     extraction endpoints.
   - Captured-image storage/backup behavior and real camera framing.
   - Quote-edit typing and saving on both iPhone and iPad.
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
