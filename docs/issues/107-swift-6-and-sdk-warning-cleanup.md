# 107 - Remove Swift 6 and current-SDK release warnings

Status: closed
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
- [x] Capture queue publisher and retry dependencies use accurate isolation and sendability.
- [x] Camera capture resolution and orientation use supported iOS 17+ APIs.
- [x] Unreachable error handlers and deprecated trailing-closure syntax are removed.
- [x] A clean Release build emits no production warnings that are Swift 6 errors or current-target
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

2026-07-15 capture-queue isolation slice:

- Replaced ineffective `nonisolated(unsafe)` annotations with a Sendable reporter dependency and
  an explicitly `nonisolated` publisher surface.
- Protected synchronous current-stats reads with a lock while keeping Combine delivery outside
  the lock to avoid subscriber reentrancy deadlocks.
- Typed the production retry delay as a stored `CaptureQueueRetrySleep` closure, preserving the
  existing backoff behavior while satisfying its `@Sendable` contract.
- The complete `CaptureQueue*` gate passed 61 tests, 0 failures, and 0 skips on iPhone 17 / iOS
  26.5.
- A Release simulator build completed without any queue isolation or retry sendability warning.

2026-07-15 compiler-diagnostic slice:

- Removed an impossible outer startup-recovery `catch` while retaining the real rotated-store and
  in-memory rescue failure handling.
- Removed the impossible quote-save `catch`; the nonthrowing batch result continues to drive full,
  partial, and failed save presentation.
- Labeled the tag-chip removal closure explicitly, avoiding deprecated backward closure matching.
- The focused save/review unit tests plus save-to-book and add-tag UI workflows passed 14 tests,
  0 failures, and 0 skips on iPhone 17 / iOS 26.5.
- A clean Release simulator build completed without the startup, extraction-review, or tag-call
  diagnostics removed in this slice.

2026-07-15 camera SDK slice:

- Replaced deprecated high-resolution flags with the largest `maxPhotoDimensions` advertised by
  the active camera format and uses that same value for each photo request.
- Reconfigures the maximum dimensions after switching cameras.
- Replaced fixed `videoOrientation` writes with a supported 90-degree `videoRotationAngle` check.
- Replaced weak mutable captures in detached session start/stop tasks with stable strong captures;
  the service remains alive until the requested AVFoundation transition completes.
- The focused camera and image-processing gate passed 27 tests, 0 failures, and 0 skips on iPhone
  17 Pro / iOS 26.5.
- Quote, cover, and batch camera UI smoke tests passed 3 tests, 0 failures, and 0 skips.
- A clean Release simulator build completed without camera deprecation or session-capture warnings.

2026-07-15 cover Vision isolation slice:

- Constructed and executed each Vision request and request handler on the same worker queue, so
  non-Sendable framework objects no longer cross concurrency boundaries.
- Reworked the synthetic-cover integration test to call the shipping OCR fallback instead of a
  duplicate test implementation.
- The production OCR, normalization, and heuristic gate passed 25 tests, 0 failures, and 0 skips
  on iPhone 17 Pro / iOS 26.5.
- A Release simulator build completed without the cover OCR or rectangle-detection warnings.

2026-07-15 final production warning gate:

- Removed three unused locals from the UI-test camera image renderer without changing its output.
- Quote and batch mock-camera UI smoke tests passed 2 tests, 0 failures, and 0 skips.
- A clean Release simulator build completed successfully with zero production compiler warnings.
- The final generic-iOS archive completed with zero compiler warnings and exported a signed App
  Store IPA as version 1.0, build 39.
- The exported app retains bundle ID `com.acampbell.bookquotes`, Sign in with Apple, the expected
  distribution signature, and `get-task-allow = false`.
