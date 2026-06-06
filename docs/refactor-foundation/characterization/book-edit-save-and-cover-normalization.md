# Book Edit Save and Cover Normalization Characterization - 2026-06-06

## Scope

Target files:

- `BookQuotes/Features/BookRegistration/BookEditView.swift`
- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`

This slice covers save-value mapping, cover metadata normalization, and the cover-capture completion path back to the library. UI composition, camera capture mechanics, Vision rectangle detection, crop review layout, API invocation, and persistence error presentation remain later slices.

## Current Behavior

`BookEditView` creates or updates `Book` values from form state:

- Title is trimmed and required.
- Author is trimmed; blank author saves as `Unknown`.
- Empty optional string fields save as `nil`.
- `publishYear` and `pageCount` are parsed with `Int(...)`; invalid or empty values become `nil`.
- Reading status is preserved from the form.
- Create inserts a new `Book`; edit mutates the existing `Book` and updates `dateModified`.
- Cover images are compressed only at save time into thumbnail and full-size JPEG data.

`CoverCaptureView` converts Gemini/OCR/manual cover extraction into `BookMetadata`:

- Gemini author strings split on `&`, ` and `, or comma.
- ISBN values map to `isbn10` or `isbn13` by length.
- Gemini genre becomes a one-item `categories` list.
- If Gemini returns a blank title, OCR title fallback wins when available.
- If Gemini returns no authors, OCR authors backfill when available.
- Final extraction failure still opens manual entry and keeps cover image data.

Cover capture completion now returns to the Library tab after saving, so the new book is visible in the list.

## Public Interface In Scope

New seams:

- `BookEditSaveDraft`: form values in, `Book` creation or mutation out.
- `BookEditCoverImageData`: compressed cover data value object.
- `CoverMetadataNormalizer`: extraction result in, normalized `BookMetadata` out.

The seams intentionally do not expose SwiftUI state, `ModelContext`, `UIImage`, camera services, Vision requests, haptics, alerts, or dismissal.

## Implementation Map

Current owners after this slice:

- `BookEditView` still owns SwiftUI state, persistence calls, haptics, milestone behavior, and dismissal.
- `BookEditSaveDraft` owns save normalization and `Book` field assignment.
- `CoverCaptureView` still owns camera/crop/OCR/API orchestration.
- `CoverMetadataNormalizer` owns pure metadata normalization and fallback mapping.
- `ContentView` owns tab selection after cover-created completion.

Current file size:

- `BookEditView.swift`: 645 LOC. Still above the 500 LOC target.
- `CoverCaptureView.swift`: 906 LOC. Still above the 500 LOC target.
- `BookEditSaveDraft.swift`: 77 LOC.
- `CoverMetadataNormalizer.swift`: 78 LOC.

CRAP guidance:

- This removes save and metadata mapping from the high-CRAP view files and puts them behind pure value seams.
- Remaining high-risk work is in UI composition, camera/Vision orchestration, and capture-tab flow state.

## Target Shape

The target is narrower, deeper modules:

- Views orchestrate state and presentation.
- Value seams own deterministic transformations.
- Acceptance tests cover user-visible behavior through the simulator.
- Unit tests characterize transformations before extraction.

Non-additive check:

- `BookEditView` should no longer duplicate every save field assignment inline.
- `CoverCaptureView` should no longer duplicate cover metadata normalization inline.
- The cover-save acceptance path should verify the saved book appears in the library after completion.

## Acceptance Criteria

- [x] Red/green tests cover creating a `Book` from form values with trimming, optional normalization, status, and cover data.
- [x] Red/green tests cover editing an existing `Book`, blank author fallback, optional clearing, date modification, and cover clearing.
- [x] Red/green tests cover Gemini cover metadata normalization, OCR title fallback, OCR author fallback, and manual fallback.
- [x] `BookEditView` delegates save mapping to `BookEditSaveDraft`.
- [x] `CoverCaptureView` delegates extraction-result mapping to `CoverMetadataNormalizer`.
- [x] Cover capture save returns to the Library tab where the newly saved book is visible.
- [x] Existing manual create and edit simulator acceptance paths still pass.
- [x] New source and test files are below 500 LOC.
- [x] Remaining over-500 LOC files are explicitly carried into later refactor slices.

## Notes From Implementation

- Validation calls `makeSaveDraft(includeCoverData: false)` so title/author checks do not recompress cover images on every render.
- The active `BookMetadata` for cover flows is the service-facing model in `ISBNLookupService.swift`; tests assert `categories` rather than the older `tags` shape.
- The cover-save UI test now queries for a static text whose label contains the generated title, because SwiftUI exposes list-row labels as title plus author.

## Verification Plan

Focused TDD:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditSaveDraftTests

xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverMetadataNormalizerTests
```

Focused guard:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/BookEditDraftTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests \
  -only-testing:BookQuotesTests/CoverMetadataNormalizerTests \
  -only-testing:BookQuotesTests/BookModelTests
```

Simulator acceptance:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateBook_WithRequiredFields \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateThenEditBook_UpdatesTitle \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```
