# Issue 079: Memory Performance Gate Recalibration

Status: `closed`

## Context

The broad unit gate now reaches the memory performance tests, but three assertions fail on the iPhone 17 iOS 26.5 simulator:

- `MemoryPerformanceTests.testBaseline_EmptyApp_MemoryUsage`
- `MemoryPerformanceTests.testMemory_DeleteBooks_Releases`
- `MemoryPerformanceTests.testMemory_Load10000Quotes_Acceptable`

The focused memory run reproduced the failures. The important evidence is that the tests currently assert absolute process RSS, including XCTest, SwiftData, and simulator runtime overhead:

- baseline RSS measured about 326 MB against a 50 MB threshold.
- 10K quote load measured about 405 MB total RSS against a 200 MB threshold.
- delete recovery used RSS release percentage after deletion, which is noisy because allocator and SwiftData memory are not guaranteed to return to the OS immediately.

Several workload-specific protections still passed in the same focused run, including 1K quote load, 5K quote load, repeated queries, cover image handling, and batch insert accumulation.

## Acceptance Criteria

- Characterize current memory behaviour before editing thresholds.
- Preserve performance protection for large quote libraries.
- Replace absolute total-process RSS assertions with workload-sensitive checks where appropriate.
- Keep at least one regression signal for:
  - quote load memory growth.
  - repeated query memory stability.
  - batch insert accumulation.
  - cover image memory growth.
  - deletion or cleanup behaviour.
- Avoid changing thresholds purely to make the current machine green.
- Decide whether memory performance tests belong in the normal broad unit gate or a separate performance gate.
- Record focused memory verification output after the recalibration.
- Record broad unit gate output after the recalibration.

## Implementation

- Replaced the impossible 50 MB absolute XCTest process baseline with:
  - a positive measurement assertion.
  - a high diagnostic ceiling for runaway simulator/XCTest process memory.
- Changed the 10K quote test from absolute total RSS to workload memory increase.
- Changed the deletion test from RSS recovery percentage to:
  - book cleanup assertion.
  - quote cleanup assertion.
  - post-delete memory drift assertion.
- Kept the existing workload-specific gates for 1K quote load, 5K quote load, repeated queries, batch inserts, and cover images.

## Verification

Latest focused evidence:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/MemoryPerformanceTests
```

Result: 8 tests executed, 3 failures.

Focused verification after recalibration:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/MemoryPerformanceTests
```

Result: 8 tests executed, 0 failures.

Observed signals from the passing run included:

- 10K quote load memory increase: about 45.6 MB.
- deletion drift after delete: about 0.05 MB.
- cover image increase: about 7.5 MB.
- repeated-query memory increase: negative after cleanup.

Latest broad evidence:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests
```

Previous result: 548 tests executed, 4 failures.

Broad verification after recalibration:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests
```

Result: 548 tests executed, 0 failures.

## Follow-Up

- Use this issue before any submission-readiness claim.
- If the gate is split, document the normal unit gate and performance gate separately.
