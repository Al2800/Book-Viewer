# Issue 077: Subscription Sync State Refactor

Status: `closed`

## Context

`SubscriptionService.swift` remains one of the largest service files. Issue 073 moved StoreKit app-account-token generation into a focused module and left backend sync response mapping as the next characterized subscription seam.

The backend sync path maps the `/api/subscription/sync` response into app subscription state: normalized `SubscriptionStatus`, optional expiry date, and product id fallback. That mapping is product-critical because it controls signed-in subscription access after StoreKit/backend reconciliation.

## Acceptance Criteria

- [x] Characterize backend sync response mapping before production edits.
- [x] Preserve backend request construction and networking inside `SubscriptionService`.
- [x] Preserve AuthService subscription-state update behavior.
- [x] Preserve unknown backend status fallback to `.none`.
- [x] Preserve ISO8601 expiry parsing and nil-on-invalid-date behavior.
- [x] Preserve product id retention for backend-provided `productId`.
- [x] Move sync response mapping out of `SubscriptionService`.
- [x] Keep all touched production files below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused subscription sync tests when the local Xcode runner is healthy.
- [x] Run subscription/paywall simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `SubscriptionSyncResponse`.
- Added `SubscriptionSyncState`.
- Added `SubscriptionSyncStateTests`.
- Updated `SubscriptionService.refreshSubscriptionWithServer(transaction:)` to decode `SubscriptionSyncResponse` and apply `SubscriptionSyncState`.

## Verification

- See `docs/refactor-foundation/verification/2026-07-01-subscription-sync-state-refactor.md`.
- Reconciled in `docs/refactor-foundation/verification/2026-07-01-book-save-subscription-reconciliation.md`.
- Focused book/save/subscription gate passed: 21 tests, 0 failures.
- Broad unit gate passed: 548 tests, 0 failures.
- Subscription media route smoke passed with monthly/yearly plans and `Start Free Trial` visible.

## Follow-Up

- Issue 078 extracts product ID metadata.
- Further `SubscriptionService` extraction should target one characterized behavior seam at a time: entitlement status selection, subscription error descriptions, or product display helpers.
