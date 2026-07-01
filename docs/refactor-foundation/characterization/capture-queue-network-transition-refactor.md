# Capture Queue Network Transition Refactor Characterization

Date: 2026-06-30

## Characterized Behaviour

- A transition from disconnected to connected starts queue processing only when auto-processing is enabled.
- A transition from disconnected to connected does not start processing when auto-processing is disabled.
- A connection that remains online does not re-trigger processing through the transition rule.
- A transition from connected to disconnected does not start processing.

## Red State

`BookQuotesTests/CaptureQueueNetworkTransitionTests` failed because `CaptureQueueNetworkTransition` was missing.

## Refactor

Added `CaptureQueueNetworkTransition` as a pure transition-decision module. `CaptureQueueManager` now asks this module before starting processing from the polling loop.

## Non-Goals

- No changes to polling interval.
- No changes to retry scheduling.
- No changes to queue processing transaction.
- No changes to auto-processing preference defaults.
