# BookQuotes v2 architecture

## 1. Decision context

BookQuotes already contains the engineering required for the product reset:

- camera and image-processing infrastructure;
- single and batch capture;
- local and remote extraction abstractions;
- SwiftData models for books, passages and source material;
- search infrastructure;
- export and Studio rendering;
- TestFlight and UI-test support.

V2 remains in the same repository so the product surfaces and extraction pipeline share one source of truth, one data model and one verification system. Creating a second application repository would duplicate the most failure-prone contracts and slow feedback between extraction quality and capture UX.

This is not permission to keep adding unrelated behaviour to shared files. The repository must move toward explicit ownership boundaries.

## 2. Target product boundaries

```text
App
  App shell
  Navigation
  Feature flags

Features
  Reading
  Capture
  Studio
  Book
  Passage
  Settings

Domain
  Books
  Passages
  Capture
  Extraction
  Search
  Connections

Infrastructure
  Camera
  Persistence
  Source images
  Search index
  Networking
  Analytics
  Export
```

These are ownership boundaries first. They do not require an immediate conversion into separate Swift packages. Package boundaries should follow stable dependency seams rather than precede them.

## 3. Core workflow contract

```text
Active book
  -> capture page
  -> produce passage candidates
  -> expose uncertainty
  -> persist selected passages and source provenance
  -> index searchable mutations
  -> retrieve or connect later
```

A view may render a workflow state and emit events. It must not independently coordinate camera lifecycle, file storage, extraction policy and persistence.

## 4. Capture state

The current implementation contains several related booleans and presentation flags. The target is one explicit state owned by a coordinator.

```swift
enum CaptureState: Equatable {
    case permissionRequired
    case preparing(bookID: UUID, mode: CaptureMode)
    case ready(bookID: UUID, mode: CaptureMode)
    case capturing(bookID: UUID, mode: CaptureMode)
    case analysing(pageID: UUID)
    case review(pageID: UUID, candidates: [PassageCandidate])
    case saving(pageID: UUID)
    case saved(count: Int)
    case interrupted
    case failed(CaptureFailure)
}
```

The coordinator owns valid transitions. Views must not infer a route from combinations of `selectedBook`, `selectedDraft`, camera booleans and sheet booleans.

## 5. Extraction contract

All extractors return the same structured candidate type.

```swift
struct PassageCandidate: Identifiable, Sendable {
    let id: UUID
    let text: String
    let pageNumber: Int?
    let sourceBounds: CGRect?
    let marking: MarkingType?
    let confidence: Double
    let source: ExtractionSource
}
```

Extraction policy sits above individual extractors. It decides whether to:

- accept high-confidence local candidates;
- ask the user to check an ambiguous candidate;
- invoke the cloud fallback;
- merge candidates;
- return no result.

Extractors do not navigate UI or persist user data. Candidate order remains page order.

## 6. Local and cloud inference

The existing cloud path remains the production comparator while local extraction develops. The intended progression is:

1. local benchmark only;
2. TestFlight shadow mode;
3. local suggestions;
4. calibrated local auto-selection;
5. local-first with cloud fallback;
6. optional fully offline mode.

No local detector controls automatic selection until passage-level precision, recall, latency and false-positive gates are met on the evaluation corpus.

## 7. Data evolution

The current `Quote` model may retain its internal name during the initial reset. User-facing language should use **Passage**. Renaming a SwiftData model is not required to improve the product and introduces migration risk.

The longer-term model should avoid duplicating one page image for each extracted passage.

```text
Book
  -> SourcePage
       -> image reference
       -> OCR text
       -> page number
       -> passages
            -> text
            -> source bounds
            -> marking
            -> notes
```

Any migration to `SourcePage` requires:

- a tested schema migration;
- compatibility with existing App Store data;
- lazy or resumable file migration where practical;
- recovery behaviour when a source file is missing;
- no deletion of legacy source data until the new model is persisted.

## 8. Search ownership

Search must become mutation-driven. Editing a title, author, passage, note or tag must update the index directly. Counts are not a sufficient invalidation signal.

The domain mutation that succeeds in persistence is responsible for issuing the corresponding search-index mutation. Views do not rebuild the index opportunistically.

## 9. Persistence contract

User-data operations must not use `try? modelContext.save()`.

Required sequence:

1. retain recoverable input;
2. perform the model mutation;
3. persist;
4. update dependent indexes;
5. only then remove superseded source files;
6. present a recoverable error on failure.

## 10. Images

SwiftUI feature views should not repeatedly decode large image blobs synchronously. A shared source-image pipeline should own:

- content-addressed cache keys or explicit revisions;
- cancellation;
- thumbnail generation;
- memory limits;
- background decoding;
- missing-file recovery.

## 11. Feature flags

The first implementation step introduces a default-off v2 product shell. Requirements:

- existing TestFlight navigation remains the default;
- v2 can be enabled by launch argument and persisted internal setting;
- the same underlying models and services are used;
- tests can exercise both shells deterministically;
- the flag is removed only after the v2 release gates pass.

## 12. Verification boundaries

Each subsystem should have a focused verification layer:

- domain state and policies: unit tests;
- persistence and indexing: integration tests;
- capture and review journeys: UI tests;
- camera, flash and interruption: physical-device smoke tests;
- local extraction: fixed evaluation corpus;
- architecture: source-level checks;
- visual hierarchy: reference screenshots and accessibility audits.

## 13. Dependency direction

Desired direction:

```text
Views -> feature coordinators -> domain services -> infrastructure
```

Infrastructure must not import feature UI. Domain services must not present SwiftUI screens. Shared design components must not become workflow owners.
