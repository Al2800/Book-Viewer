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
  suffixes. The Worker also normalizes each successful provider reply to the app's bounded
  quote-review schema before marking it billable; malformed output returns `502` and releases the
  extraction reservation. The backend suite passed: 39 tests, 0 failures; TypeScript typecheck
  passed.
- Remote quote extraction now limits its prepared JPEG to 4 MB, below the Worker's 4.5 MB decoded
  image limit, by adapting compression and dimensions only when the normal 2048 px image would
  exceed the budget. Focused iOS tests cover both a high-entropy image and the actual outbound
  request payload.
- Removed the unreferenced `BatchProcessingService` and unused `QuoteSaveService.saveFromSession`
  placeholder. They represented an obsolete batch path that either always failed authentication or
  returned an empty save result; the live flow remains `BatchCaptureFlowView` to
  `ExtractionReviewView` to the direct quote-save path. Focused draft/save/review tests passed on
  2026-07-15 after the removal: 12 tests passed, 0 failures, 0 skips on iPhone 17 / iOS 26.5.
  Result bundle: `/tmp/BookQuotes-batch-path-removal-2026-07-15.xcresult`. An additional
  `BatchCaptureFlowTests` run was interrupted after Xcode stalled while installing and launching
  the simulator test runner, before any test started; it is not counted as passing evidence.
- Quote-page extraction now runs on-device OCR first. Remote AI processing is an optional,
  consent-controlled recovery path only when on-device OCR finds no candidate or errors; a normal
  local result never uploads the page. Extraction Review no longer blocks local processing on the
  remote-consent sheet. The focused extractor suite passed on 2026-07-15: 19 tests passed,
  0 failed, 1 documented local-only-fixture skip on iPhone 17 / iOS 26.5. The quote-capture UI
  regression also passed: 1 test, 0 failures, 0 skips. Result bundles:
  `/tmp/BookQuotes-local-first-extraction-2026-07-15.xcresult` and
  `/tmp/BookQuotes-local-first-review-ui-2026-07-15.xcresult`.
- The on-device detector now recognizes a hooked vertical mark as a bracket, suppresses its hook
  fragments as duplicate underlines, and selects the entire adjacent paragraph. The full
  on-device extractor suite passed after the change: 20 tests passed, 0 failed, 1 documented
  local-only fixture skip on iPhone 17 / iOS 26.5. Result bundle:
  `/tmp/BookQuotes-bracket-extraction-2026-07-15.xcresult`.
- Quote editor interaction is covered by a native UIKit text editor that retries initial focus
  through sheet presentation and does not overwrite an active edit with stale SwiftUI state.
  The capture, extraction-review, and quote-save regression set passed on 2026-07-15: 20 tests,
  0 failures, 0 skips in 382.707 seconds on iPhone 17. Result bundle:
  `/tmp/bookquotes-capture-regression-2026-07-15.xcresult`.
- The direct quote-editor typing test also passed on iPad Air 11-inch (M4), iOS 26.5: 1 test,
  0 failures, 0 skips in 90.072 seconds. Result bundle:
  `/tmp/bookquotes-quote-editor-ipad-2026-07-15.xcresult`.
- The full app-unit gate passed again on 2026-07-15 after the remote-image budget change with a
  complete, readable result bundle: 616 tests passed, 0 failed, and 1 skipped in 204.243 seconds
  on iPhone 17 / iOS 26.5. The skip is the
  documented local-only real-book-photo fixture (`testRealBookFixtureExtractsUnderlinedPassageWhenProvided`).
  Result bundle: `/tmp/BookQuotes-app-unit-2026-07-15-post-upload-budget.xcresult`
  (`Info.plist` verified present).
- Backend tests and typecheck passed: 39 tests, 0 failures.
- Production Worker deployment tooling is now on Wrangler 4 / Worker types 5 / Vitest 4, with
  Node 22.12+ compatibility verified. The full backend suite passed and
  `npm audit --audit-level=moderate` reports zero vulnerabilities.
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
  upstream website risk rather than an iOS-binary blocker. A separate high Picomatch advisory is
  limited to the Tailwind 3 development watcher chain; it requires a planned Tailwind 4 migration
  and is not in the deployed production dependency set.
- Existing Swift 6 concurrency and API deprecation warnings remain during Xcode builds. They do
  not fail the current Swift 5-mode build, but should be resolved before a Swift 6 migration.

## Decision

The codebase is simulator-ready and the iPad release gate is green. It is **not ready to submit
to App Review** until the production, physical-device, App Store Connect, and fresh-archive gates
above are completed and recorded.
