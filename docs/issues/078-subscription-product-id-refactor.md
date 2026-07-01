# Issue 078: Subscription Product ID Refactor

Status: `closed`

## Context

`SubscriptionService.swift` still owned App Store product identifiers, display names, and product loading identifier order. These values are small but load-bearing: StoreKit loading, monthly/yearly product lookup, paywall defaults, and subscription display all depend on them remaining stable.

Issue 077 moved backend sync response mapping out of `SubscriptionService`. The next subscription seam is product ID metadata.

## Acceptance Criteria

- [x] Characterize monthly and yearly App Store product identifiers.
- [x] Characterize product identifier ordering used for product loading.
- [x] Characterize product display names.
- [x] Move product ID metadata out of `SubscriptionService`.
- [x] Preserve `monthlyProduct`, `yearlyProduct`, and `loadProducts()` behavior.
- [x] Keep all touched production files below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused subscription product tests when the local Xcode runner is healthy.
- [x] Run subscription/paywall simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `SubscriptionProductID`.
- Added `SubscriptionProductIDTests`.
- Updated `SubscriptionService` product lookup and product loading to use `SubscriptionProductID`.
- Repaired stale/colliding Xcode project references exposed by the focused test build:
  `CaptureQueueDependencies.swift`, `CaptureQueueRetryCoordinator.swift`,
  `QuoteSaveDraft.swift`, `QuoteSaveTypes.swift`, and `QuoteSaveResultTests.swift`.

## Verification

- See `docs/refactor-foundation/verification/2026-07-01-subscription-product-id-refactor.md`.
- Reconciled in `docs/refactor-foundation/verification/2026-07-01-book-save-subscription-reconciliation.md`.
- Focused book/save/subscription gate passed: 21 tests, 0 failures.
- Broad unit gate passed: 548 tests, 0 failures.
- Subscription media route smoke passed with monthly/yearly plans and `Start Free Trial` visible.

## Follow-Up

- Further `SubscriptionService` extraction should target one characterized behavior seam at a time: entitlement status selection, subscription error descriptions, or product display helpers.
