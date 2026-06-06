# Book Edit Draft Loading Characterization - 2026-06-06

## Scope

Target file: `BookQuotes/Features/BookRegistration/BookEditView.swift`

This slice covers only form draft/loading and genre display mapping. Save orchestration, persistence failure behavior, photo picker loading, and presentation composition remain in later slices.

## Current Behavior

`BookEditView` supports three entry points:

- `.create`: starts with empty text fields and `ReadingStatus.wantToRead`.
- `.edit(Book)`: pre-fills all editable fields from the existing `Book`, including optional subtitle, ISBN, publisher, publish year, genre, page count, notes, reading status, and cover image data.
- `.createFromMetadata(BookMetadata)`: pre-fills title, formatted authors, subtitle, best ISBN, publisher, publish year, first category/genre, page count, and cover image data. Reading status remains `wantToRead`.

Title is required. Author is optional in the form and is nudged visually when blank, but save behavior normalizes blank author to `Unknown`.

## Public Interface In Scope

Current external callers know `BookEditView.Mode`:

- `BookEditView(mode: .create)`
- `BookEditView(mode: .edit(book))`
- `BookEditView(mode: .createFromMetadata(metadata))`

The new module seam should let callers/tests ask one focused question:

> Given a book edit source, what draft values should the form display?

The seam should not expose SwiftUI state, `ModelContext`, `dismiss`, haptics, milestone behavior, or photo picker internals.

## Implementation Map

Current owners in `BookEditView.swift`:

- `loadInitialValues()` owns source-to-field mapping.
- `BookGenre.displayName` owns edit-form genre labels.
- The view owns `UIImage(data:)` conversion for stored cover data.

Current file size:

- Before slice: `BookEditView.swift`: 711 LOC, above the 500 LOC target.
- After slice: `BookEditView.swift`: 659 LOC. Still above target; next slices must extract save orchestration and UI composition.
- New seams: `BookEditDraft.swift` 88 LOC, `BookEditOptions.swift` 57 LOC.

CRAP guidance from the prior report:

- `BookEditView.swift`: highest file-level CRAP proxy.
- `BookEditView.loadInitialValues()`: high-risk uncovered function.
- `BookGenre.displayName`: high-risk uncovered mapping.

## Target Shape

Introduce a focused module:

- `BookEditSource`: create, edit existing book, or metadata source.
- `BookEditDraft`: value type containing form field strings, status, and optional cover image data.
- `BookEditOptions`: genre choices and labels.

Expected depth:

- Small interface: source in, draft values out.
- High locality: edit prefill rules and display labels no longer live inside SwiftUI presentation.

Non-additive check:

- `BookEditView.loadInitialValues()` should call the new draft module and stop duplicating source-to-field mapping.
- `BookGenre` should move out of `BookEditView.swift`.

## Acceptance Criteria

- [x] Red/green tests cover `.create`, `.edit(Book)`, and `.createFromMetadata(BookMetadata)` draft loading through the new public interface.
- [x] Tests cover at least one genre display label through `BookEditOptions`.
- [x] Existing UI entry points keep the same `BookEditView.Mode` call sites.
- [x] `BookEditView` no longer directly maps `Book`/`BookMetadata` fields into every form state property.
- [x] New source and test files are below 500 LOC.
- [x] `BookEditView.swift` is reduced, with remaining over-500 LOC work explicitly left for the save and UI-composition slices.
- [x] Focused unit tests pass.
- [x] Existing book registration simulator acceptance paths pass after the refactor.

## Notes From Implementation

- `BookEditView.Mode` remains the stable caller-facing interface.
- `BookEditSource` is the internal seam between existing entry points and draft values.
- `BookEditDraft` owns form defaults and edit/metadata prefill behavior.
- `BookEditOptions` owns genre choices and display labels.
- The UI-test-only cover button now injects deterministic cover metadata so simulator acceptance verifies the cover-to-edit path without depending on crop UI, OCR, network calls, or API keys.

## Verification Plan

Focused TDD:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditDraftTests
```

Focused guard:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditDraftTests -only-testing:BookQuotesTests/BookModelTests
```

Simulator acceptance:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateBook_WithRequiredFields \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateThenEditBook_UpdatesTitle \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit
```
