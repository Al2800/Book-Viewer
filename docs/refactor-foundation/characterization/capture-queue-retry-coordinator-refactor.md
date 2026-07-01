# Capture Queue Retry Coordinator Characterization

Date: 2026-07-01

Issue: `066-capture-queue-retry-coordinator-refactor.md`

## Scope

This slice isolates delayed retry task mechanics from `CaptureQueueManager`.

The manager still owns queue behavior:

- whether processing can start,
- whether the item remains retryable,
- which item is reprocessed,
- stats updates around processing.

The coordinator owns retry mechanics:

- applying the configured retry delay,
- storing the pending task,
- replacing an existing task for the same item,
- cancelling one pending retry or all pending retries.

## Characterized Behavior

- `testScheduleRetryRunsRetryAfterConfiguredDelayWhenStillRetryable`
  - schedules a retry,
  - records the configured delay passed to the sleeper,
  - confirms the retry action runs when `shouldRetry` returns true.

- `testCancelRetryPreventsScheduledRetryFromRunning`
  - schedules a retry behind a controlled sleep gate,
  - waits until the scheduled task is parked,
  - cancels the item retry,
  - releases the sleeper,
  - confirms the retry action never runs.

## Non-Goals

- No change to queue storage.
- No change to extraction processing.
- No change to network restoration behavior.
- No UI behavior change.
