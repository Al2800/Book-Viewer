# Release and TestFlight Gate Verification

## Slice

Issue: `book-quote-release-testflight-gate`

Goal: confirm the refactor foundation is behaviour-preserving enough for continued development, record coverage/CRAP guidance, and identify any blockers before a TestFlight push.

## Dependency Status

Closed implementation slices:

- `book-quote-capture-flow-state`
- `book-quote-cover-extraction-orchestration`
- `book-quote-cover-camera-crop-sections`
- `book-quote-book-edit-ui-sections`

Open follow-on issues created from this gate:

- `book-quote-release-build-22`: bump and verify build settings before upload.
- `book-quote-capture-tab-root-modular-followup`: continue reducing `CaptureTabRootView` after characterization.
- `book-quote-book-edit-sections-coverage`: add direct section-wiring coverage for book edit composition.
- `book-quote-cover-crop-review-acceptance`: strengthen direct crop-review simulator coverage.
- `book-quote-library-row-accessibility`: stabilize library row accessibility for edit-flow UI tests.

## Focused Coverage

Command:

```bash
RUN_ID=refactor_gate_20260606 \
DESTINATION='platform=iOS Simulator,name=iPhone 17,OS=26.5' \
ONLY_TESTING='BookQuotesTests/BookEditDraftTests|BookQuotesTests/BookEditSaveDraftTests|BookQuotesTests/CoverMetadataNormalizerTests|BookQuotesTests/CoverExtractionOrchestratorTests|BookQuotesTests/CoverCropGeometryTests|BookQuotesTests/CoverOCRHeuristicsTests|BookQuotesTests/CaptureFlowStateTests' \
./scripts/coverage.sh
```

Result:

- Tests passed: 26 tests, 0 failures.
- Artifacts: `artifacts/coverage/refactor_gate_20260606/`.
- Script exit: non-zero because global thresholds failed on a deliberately focused unit-only run.
- Threshold result: overall `5.0% < 19.0%`, `BookQuotes.app` `4.9% < 9.0%`, `BookQuotesTests.xctest` `7.5% < 85.0%`.

Interpretation:

- The run is valid as a focused characterization signal for the extracted seams.
- It is not valid as a full-suite coverage regression gate because UI tests and broad integration tests were intentionally excluded.
- The threshold mismatch is expected for this focused run and remains documented rather than hidden.

## Coverage Signal

| File | Focused line coverage |
|---|---:|
| `CaptureFlowState.swift` | 100.0% |
| `CoverExtractionOrchestrator.swift` | 100.0% |
| `CoverCropGeometry.swift` | 98.5% |
| `CoverOCRHeuristics.swift` | 94.8% |
| `BookEditSaveDraft.swift` | 87.5% |
| `BookEditOptions.swift` | 85.7% |
| `CoverMetadataNormalizer.swift` | 84.0% |
| `BookEditDraft.swift` | 79.1% |
| `CaptureTabRootView.swift` | 3.4% |
| `BookEditView.swift` | 0.0% |
| `BookEditSections.swift` | 0.0% |
| `CoverCaptureView.swift` | 0.0% |
| `CoverCaptureChrome.swift` | 0.0% |
| `CoverCropReviewView.swift` | 0.0% |

The zero-coverage SwiftUI composition files are still covered by focused simulator acceptance runs recorded in the slice verification docs. They are also the main reason for the follow-on UI coverage issues.

## CRAP Proxy

No local cyclomatic-complexity tool is installed, so this is a proxy, not a true CRAP score. The proxy uses:

- Branch proxy: count of common Swift control-flow and SwiftUI branching tokens, plus one.
- Coverage: xccov line coverage from `artifacts/coverage/refactor_gate_20260606/coverage_report.json`.
- Formula: `branch_proxy^2 * (1 - coverage)^3 + branch_proxy`.

| File | LOC | Coverage | Branch proxy | CRAP proxy |
|---|---:|---:|---:|---:|
| `CaptureTabRootView.swift` | 812 | 3.4% | 52 | 2492.1 |
| `CoverCaptureView.swift` | 443 | 0.0% | 63 | 4032.0 |
| `BookEditView.swift` | 423 | 0.0% | 62 | 3906.0 |
| `BookEditSections.swift` | 272 | 0.0% | 12 | 156.0 |
| `CoverCropReviewView.swift` | 205 | 0.0% | 11 | 132.0 |
| `CoverCaptureChrome.swift` | 154 | 0.0% | 16 | 272.0 |
| `CoverOCRHeuristics.swift` | 92 | 94.8% | 26 | 26.1 |
| `CoverMetadataNormalizer.swift` | 78 | 84.0% | 17 | 18.2 |
| `CoverCropGeometry.swift` | 95 | 98.5% | 6 | 6.0 |
| `CaptureFlowState.swift` | 92 | 100.0% | 30 | 30.0 |
| `CoverExtractionOrchestrator.swift` | 33 | 100.0% | 7 | 7.0 |

Guidance:

- Continue extracting `CaptureTabRootView` next; it is the only current target still above 500 LOC.
- Treat `BookEditView` and `CoverCaptureView` as lower LOC but still high-risk orchestration files; the next slices should add characterization before any further extraction.
- Do not split the high-coverage pure seams unless behaviour expands. They are currently doing their job.
- Add direct UI/section-wiring coverage where simulator acceptance is the only coverage signal.

## Simulator Acceptance Evidence

Latest recorded passing simulator checks from the implementation slices:

- Cover capture photo/test-cover/manual-entry paths: 4 tests, 0 failures.
- Book edit create, all-fields create, validation, cancel, and cover-section paths: 5 tests passed in the broader UI run.
- Book edit seeded existing-book edit entry paths after helper fix: 2 tests, 0 failures.
- Book edit create-then-edit persisted title path: 1 test, 0 failures.

Known note:

- `testEditBook_ModifyTitle_SavesChanges` still logs a non-fatal message when seeded data does not visibly update. `testManualEntry_CreateThenEditBook_UpdatesTitle` is the stronger persisted edit acceptance test and passes.

## TestFlight Readiness

Release configuration observed on 2026-06-06:

- App bundle identifier: `com.acampbell.bookquotes`.
- App marketing version: `1.0`.
- App target build number: `CURRENT_PROJECT_VERSION = 20`.
- Development team: `92XJSN32W4`.
- Signing style: Automatic.
- User-reported latest TestFlight build: build 21.

Gate result:

- Do not upload this branch to the same App Store Connect app as-is.
- The app build number must be bumped above 21 before upload. This is tracked by `book-quote-release-build-22`.

API key/configuration result:

- The iOS app uses `AuthService.proxyBaseURL` and sends authorized requests to the BookQuotes proxy through `GeminiService`.
- No raw `GEMINI_API_KEY` is set in the app code.
- The backend expects `GEMINI_API_KEY` as a Cloudflare Worker secret.

## Neutral Change Log

- Added pure characterization seams for capture flow state, cover extraction fallback, cover metadata normalization, cover crop geometry, cover OCR heuristics, book edit draft loading, and book edit save mapping.
- Extracted cover capture screen chrome and crop review UI from `CoverCaptureView`.
- Extracted book edit form sections from `BookEditView`.
- Updated simulator UI helpers to tap SwiftUI list-row child elements when row identifiers are exposed on child `StaticText`/`Image` elements.
- Preserved current user-visible create, cover-capture, edit, validation, cancel, and save behaviours covered by focused simulator checks.

## Remaining Risk

- `CaptureTabRootView.swift` remains above the sub-500 LOC target.
- SwiftUI composition coverage is still mostly simulator-driven rather than xccov line-driven.
- Direct crop-review sheet behaviour needs a stronger simulator path.
- Release upload remains blocked until the build number is bumped and archive/signing are checked.
