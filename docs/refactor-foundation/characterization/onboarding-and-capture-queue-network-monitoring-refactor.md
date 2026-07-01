# Onboarding and Capture Queue Network Monitoring Characterization

Date: 2026-06-30

## Characterized Behaviour

- Onboarding explicit step advancement moves to the target step without clearing the signed-in user.
- Queue manager startup starts the injected network monitor.
- When the injected network monitor is offline, queue manager startup remains idle and does not mark stats as processing.

## Red State

The new queue manager characterization was written against an injected network monitor seam before production support existed. The first run was blocked by the existing red Library navigation lookup test, so that compile blocker was resolved before rerunning the onboarding/queue suite.

## Refactor

Added `CaptureQueueNetworkMonitoring` as a small connectivity seam. `NetworkMonitor` is the live adapter, and tests can inject a deterministic monitor.

## Non-Goals

- No changes to auto-processing policy.
- No changes to retry delays or retry scheduling.
- No changes to the queue processing transaction.
