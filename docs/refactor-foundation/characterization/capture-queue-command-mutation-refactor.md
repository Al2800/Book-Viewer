# Capture Queue Command Mutation Refactor Characterization

Date: 2026-07-01

## Scope

This slice keeps `OnboardingView` as the route shell and focuses on public `CaptureQueueManager` command behaviour.

## Characterized Behaviour

- Removing a queue item after a retryable failure cancels the delayed retry task for that item.
- Retrying a queue item marks the item for retry, updates stats, and processes the next pending item when online.

## Tests Added

- `CaptureQueueManagerTests.testRemoveFromQueueCancelsPendingRetryForItem`
- `CaptureQueueManagerTests.testRetryItemMarksItemForRetryAndProcessesWhenOnline`

## Refactor

Repeated queue command orchestration now goes through `CaptureQueueManager.performQueueMutation(startReason:_:)`, which performs the storage mutation, updates stats, and starts processing only when the command has a start reason that passes `CaptureQueueProcessingStartPolicy`.

## Acceptance Notes

- Public manager APIs are unchanged.
- `OnboardingView.swift` remains at 148 LOC.
- `CaptureQueueManager.swift` remains at 303 LOC.
- Simulator and focused XCTest execution remain blocked by the local Xcode/CoreSimulator environment, not by an app assertion.
