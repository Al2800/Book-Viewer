# Capture Queue Network Observer Refactor Characterization

Date: 2026-06-30

## Behaviour Characterized

The queue should start processing when:

- network observation has started,
- the previous connectivity state was offline,
- a later poll observes the network online,
- automatic queue processing is enabled.

The characterization uses a scripted poller so the test does not sleep or depend on `NWPathMonitor`.

## Test Added

- `BookQuotesTests/Unit/Services/CaptureQueueNetworkObserverTests.swift`

The test starts with a mutable network monitor offline. The first scripted poll flips connectivity online, the observer evaluates the already-characterized `CaptureQueueNetworkTransition`, and the test asserts that processing starts exactly once.

## Refactor Shape

- `CaptureQueueNetworkObserver` owns the async observation loop.
- `CaptureQueueNetworkPoller` is the live adapter that waits one second between polls.
- Tests use `ScriptedCaptureQueueNetworkPoller` to drive the same interface without real time.

## Acceptance Criteria Covered

- Network monitoring begins when observation runs.
- Offline-to-online transition starts processing when auto-processing is enabled.
- The observation loop is deterministic under test.
- `CaptureQueueManager` no longer contains the polling loop.
