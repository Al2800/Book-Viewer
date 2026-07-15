# Release readiness audit - 2026-07-14

## Revision Assessed

- Baseline Git revision: `b52c907` (`fix(ui): adapt library and extraction review layouts`).
- Latest locally verified code revision: `a5ed719` (`fix(tests): clear Debug build diagnostics`).
- The project build number remains `38`; the final local App Store export is version `1.0`, build
  `39`, but it has not been uploaded. The latest TestFlight build 38 predates this revision.

## Local Evidence

- Release iOS build completed successfully after `147a198` with:

  ```bash
  xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes \
    -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
  ```

- Subscription-account linkage and reconciliation tests passed: 9 tests, 0 failures, 0 skips.
  Result bundle: `/tmp/BookQuotes-subscription-reconciliation-final.xcresult`.
- The complete current UI release target passed 101 tests, 0 failures, and 0 skips on both iPhone
  17 Pro and iPad Air 11-inch (M4), iOS 26.5. Result bundles:
  `/tmp/BookQuotes-full-ui-iphone-a5ed719-2026-07-15.xcresult` and
  `/tmp/BookQuotes-full-ui-ipad-a5ed719-2026-07-15.xcresult`.
- The full app-unit gate passed 636 tests, 0 failures, and 1 documented local-photo fixture skip
  on iPhone 17 Pro / iOS 26.5. Result bundle:
  `/tmp/BookQuotes-full-unit-a5ed719-2026-07-15.xcresult`.
- A clean Debug `build-for-testing` completed with zero source or Apple-framework strip warnings.
  The focused warning-regression gate passed 60 unit/integration tests and one UI smoke test.
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
- The explicitly consented remote fallback now sends a Vision text-bounded content crop when at
  least three recognized lines safely remove at least 10 percent of outer camera area while
  retaining generous space for margin marks. Sparse, broad, or failed crops retain the
  document-prepared image. Geometry, crop-rendering, and outbound-request tests passed, and the
  complete on-device extractor suite passed: 29 tests,
  0 failures, and 1 documented local-photo fixture skip. Result bundle:
  `/tmp/BookQuotes-on-device-remote-crop-final-2026-07-15.xcresult`.
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
- Two close, aligned underline strokes now merge into a single `doubleUnderline` marking before
  quote selection, preserving the reader's marking family rather than flattening it to an
  underline. The full mark-family suite passed on iPhone 17 / iOS 26.5: 21 tests passed,
  0 failed, and 1 documented local-only fixture skip. Result bundle:
  `/tmp/BookQuotes-mark-families-2026-07-15.xcresult`.
- A short OCR-readable line beside a marked quote is now retained as that quote's editable
  margin note. The selector excludes wider opposing text columns, and the full on-device suite
  passed with this rule: 22 tests passed, 0 failed, and 1 documented local-only fixture skip on
  iPhone 17 / iOS 26.5. Result bundle:
  `/tmp/BookQuotes-mark-families-margin-note-2026-07-15.xcresult`.
- Adjacent highlighted lines now become one review candidate rather than separate cards. A
  colored highlight also takes precedence over a substantially overlapping neutral-ink run, so
  printed text inside a highlighter stroke cannot produce a duplicate underline candidate. The
  on-device suite passed: 23 tests passed, 0 failed, and 1 documented local-only fixture skip;
  the quote-review UI smoke also passed (1 test, 0 failures, 0 skips). Result bundles:
  `/tmp/BookQuotes-highlight-mark-family-2026-07-15.xcresult` and
  `/tmp/BookQuotes-highlight-review-ui-2026-07-15.xcresult`.
- Candidate confidence now includes OCR, detected-mark, mark-to-text geometry, and passage
  continuity signals. Focused tests prove that distant underlines and loose multi-line passages
  score below close, continuous equivalents without suppressing low-confidence review cards.
  The on-device suite passed: 25 tests passed, 0 failed, and 1 documented local-only fixture
  skip; the quote-review UI smoke also passed (1 test, 0 failures, 0 skips). Result bundles:
  `/tmp/BookQuotes-confidence-mark-family-2026-07-15.xcresult` and
  `/tmp/BookQuotes-confidence-review-ui-2026-07-15.xcresult`.
- Vision OCR now retains both top-left normalized and image-pixel bounding boxes for every
  recognized line. Existing mark geometry continues using pixels, while the normalized rectangle
  remains available to the extraction pipeline. The complete on-device extractor suite passed:
  30 tests, 0 failures, and 1 documented local-photo fixture skip. Result bundle:
  `/tmp/BookQuotes-on-device-normalized-bounds-2026-07-15.xcresult`.
- Quote editor interaction is covered by a native UIKit text editor that retries initial focus
  through sheet presentation and does not overwrite an active edit with stale SwiftUI state.
  The capture, extraction-review, and quote-save regression set passed on 2026-07-15: 20 tests,
  0 failures, 0 skips in 382.707 seconds on iPhone 17. Result bundle:
  `/tmp/bookquotes-capture-regression-2026-07-15.xcresult`.
- The direct quote-editor typing test also passed on iPad Air 11-inch (M4), iOS 26.5: 1 test,
  0 failures, 0 skips in 90.072 seconds. Result bundle:
  `/tmp/bookquotes-quote-editor-ipad-2026-07-15.xcresult`.
- A physical iPhone 17 / iOS 26.5.2 passed quote-editor typing and Save All navigation, plus
  multi-page Process-to-Review and Save Draft-to-Resume (4 UI tests, 0 failures). A focused unit
  test on the same device directly verified that a saved capture file and its directory use
  `completeUntilFirstUserAuthentication` protection, are excluded from backup, and are removed
  by the lifecycle cleanup (1 test, 0 failures). This closes issue `096`; issue `097` still needs
  the manual TestFlight network-loss interruption.
- The physical iPhone also activated the Accessibility XXXL extraction-review source image,
  opened and closed its full-screen viewer, and passed the retained Apple system accessibility
  audit while that viewer was open (1 test, 0 failures). Manual VoiceOver reading order and
  Reduce Motion remain open under issue `105`.
- The Capture mode-selection, quote-camera, and photo-review screens passed the retained Apple
  system audits on iPhone 17 Pro simulator (3 tests, 0 failures). The resulting fixes reflow
  guidance, quality metrics, and actions at large text sizes, expose spoken metric states and
  camera actions, preserve warning copy, and provide an accessible preview zoom action. The
  connected phone locked before this focused physical rerun could start, so it remains simulator
  evidence.
- The full app-unit gate passed again on 2026-07-15 after the remote-image budget change with a
  complete, readable result bundle: 616 tests passed, 0 failed, and 1 skipped in 204.243 seconds
  on iPhone 17 / iOS 26.5. The skip is the
  documented local-only real-book-photo fixture (`testRealBookFixtureExtractsUnderlinedPassageWhenProvided`).
  Result bundle: `/tmp/BookQuotes-app-unit-2026-07-15-post-upload-budget.xcresult`
  (`Info.plist` verified present).
- The full app-unit gate passed again on the current branch after the margin-note, highlighted
  passage, and confidence-scoring fixes: 622 tests passed, 0 failed, and 1 documented local-only
  real-book-photo fixture skip in 197.354 seconds on iPhone 17 / iOS 26.5. Result bundle:
  `/tmp/BookQuotes-app-unit-2026-07-15-current.xcresult`.
- The full app-unit gate passed again on the final current revision after remote-crop, extraction
  metadata, and backend-policy work: 627 tests passed, 0 failed, and 1 documented local-only
  real-book-photo fixture skip in 216.089 seconds on iPhone 17 / iOS 26.5. Result bundle:
  `/tmp/BookQuotes-app-unit-2026-07-15-final.xcresult` (`Info.plist` verified present).
- The unsigned Release build completed successfully after the current extraction changes. The
  two Sign In with Apple error handlers now share a graceful default for newer authorization
  states, eliminating the prior non-exhaustive-switch warnings; the onboarding sign-in UI check
  passed (1 test, 0 failures, 0 skips). Result bundle:
  `/tmp/BookQuotes-sign-in-ui-2026-07-15.xcresult`.
- A signed App Store distribution export preflight completed on 2026-07-15 after Xcode refreshed
  the Sign in with Apple provisioning profile. The resulting local IPA has a valid distribution
  signature, the expected Sign in with Apple entitlement, and `get-task-allow = false`. This
  clears the local archive/export configuration check; it does not upload a build or replace the
  production, TestFlight, or App Store Connect gates. Detailed evidence:
  `docs/refactor-foundation/verification/2026-07-15-signed-release-preflight.md`.
- The signed archive and local export were repeated after issue `107` closed. The generic-iOS
  archive and clean Release simulator build emitted zero production compiler warnings. The final
  IPA remains correctly distribution-signed as version `1.0`, build `39`, with Sign in with Apple
  and `get-task-allow = false`.
- The app supports iOS 17, so the Empty State and Error views now use the iOS 18 symbol bounce
  effect only when available and retain their normal icon transition on earlier supported OS
  versions. The unsigned Release build passed with both prior availability warnings eliminated.
- Backend tests and typecheck passed: 39 tests, 0 failures.
- Production Worker deployment tooling is now on Wrangler 4 / Worker types 5 / Vitest 4, with
  Node 22.12+ compatibility verified. The full backend suite passed and
  `npm audit --audit-level=moderate` reports zero vulnerabilities.
- A tracked-file secret-pattern scan found no credential material. The only match is the expected
  private-key format validation in `backend/src/subscription.ts`.
- The App Store Connect status helper now defaults to the active Mac user's local configuration,
  supports `~/` private-key paths, and permits an explicit `ASC_CONFIG_PATH` override. Its status
  output omits local private-key paths and individual TestFlight tester data, reducing accidental
  credential-location and personal-data exposure in release logs.
- Subscription and explicit authenticated-beta extraction access are now a tested backend policy
  module rather than route-controller logic. The HTTP routes retain the same client-facing denied
  response and remain covered by request-level tests. The complete backend suite passed: 42 tests,
  0 failures; TypeScript typecheck passed.
- The subscription paywall now avoids advertising cloud sync while the v1 CloudKit flag is off and
  avoids promising that a consented remote-AI request is never shared. The dated provider-terms
  record at `docs/AI_PROVIDER_RETENTION.md` distinguishes the pinned Hugging Face route from
  Gemini's account-level Zero Data Retention setting; it does not claim ZDR approval for the
  BookQuotes project.

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
   The local App Store Connect API configuration is currently absent, so its processing and build
   status cannot be verified from this machine until it is restored at
   `~/.appstoreconnect/config.json` or supplied through `ASC_CONFIG_PATH`.
5. Complete the remaining physical-device Accessibility/Dynamic Type/VoiceOver audit in issue
   `105`: VoiceOver order and source-image activation, Reduce Motion, rotation, and iPad
   split-view behavior.

## Residual Risks

- The website's production dependency audit reports two moderate inherited PostCSS advisories
  under Next.js. The available automatic fix proposes a breaking downgrade, so this remains an
  upstream website risk rather than an iOS-binary blocker. A separate high Picomatch advisory is
  limited to the Tailwind 3 development watcher chain; it requires a planned Tailwind 4 migration
  and is not in the deployed production dependency set.
- The tracked production Swift 6 isolation/sendability and current-SDK deprecation warnings were
  removed under issue `107`; its final clean Release build and signed archive emitted no production
  compiler warnings. Test-target diagnostics remain maintenance work but are not present in the
  shipping binary.

## Decision

The codebase is simulator-ready, the iPad simulator gate is green, and the local signed
archive/export gate is green. It is **not ready to submit to App Review** until the production,
physical-device, and App Store Connect gates above are completed and recorded.
