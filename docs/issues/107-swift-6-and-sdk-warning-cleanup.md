# 107 - Remove Swift 6 and current-SDK release warnings

Status: in_progress
Area: Build / Concurrency / Camera
Priority: medium

## Problem

The signed Release archive succeeds in Swift 5.9 mode, but production sources still emit warnings
that become errors in Swift 6 or use APIs already deprecated by the iOS 17 deployment target.
Leaving these warnings in the release log obscures new diagnostics and increases the risk of a
future Xcode upgrade becoming a blocking migration.

## Acceptance Criteria

- [x] `SearchDatabase` initialization does not call actor-isolated methods from a nonisolated
  actor initializer.
- [x] Quote-save result types do not claim unsafe `Sendable` conformance for SwiftData models.
- [ ] Capture queue publisher and retry dependencies use accurate isolation and sendability.
- [ ] Camera capture resolution and orientation use supported iOS 17+ APIs.
- [ ] Unreachable error handlers and deprecated trailing-closure syntax are removed.
- [ ] A clean Release build emits no production warnings that are Swift 6 errors or current-target
  SDK deprecations.

## Verification

- Focused tests for every changed service or workflow.
- Release-configured iOS build after each slice.
- Final signed archive warning review.

## Progress

2026-07-15 SearchDatabase initialization slice:

- Replaced actor-isolated setup calls from all three initializers with a static SQLite factory.
- The database actor now stores one non-optional, fully configured connection.
- A failed open or FTS schema setup closes any partial connection before throwing.
- Added an invalid-path regression that preserves `SearchError.databaseOpenFailed`.
- The focused search stack passed 68 tests, 0 failures, and 0 skips on iPhone 17 / iOS 26.5.
- A Release simulator build completed without any `SearchDatabase.swift` warning.

2026-07-15 quote-save sendability slice:

- Removed `Sendable` from `ExtractedQuote`, `SaveFailure`, and `BatchSaveResult` rather than using
  unchecked conformance for their SwiftData `MarkingDefinition`, `Quote`, and `Book` references.
- These contracts remain owned by the existing `@MainActor` quote-save and review workflow.
- The focused save, draft, review-state, review-processor, and page-capture gate passed 23 tests,
  0 failures, and 0 skips on iPhone 17 / iOS 26.5.
- A Release simulator build completed without any `QuoteSaveTypes.swift` sendability warning.
