# Capture Queue Manager Test Surface Refactor Characterization

Date: 2026-07-01

## Scope

- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTestDoubles.swift`

## Existing Behaviour

- `CaptureQueueManager` falls back to `QueueStats(isProcessing:)` when a queue stats read fails.
- Public stats publication should still emit processing state so UI subscribers can reflect active work.
- Manager tests use fake queue storage, fake item processing, and fake network connectivity to characterize actor orchestration without live Gemini extraction or SwiftData storage.

## Characterization Added

- `CaptureQueueManagerTests.testStatsPublisherUsesProcessingFallbackWhenStatsReadFails`

## Non-Goals

- No production queue manager changes.
- No onboarding production changes.
- No extraction, retry timing, network transition, or queue persistence behavior changes.
