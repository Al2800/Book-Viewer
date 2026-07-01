# Subscription Sync State Refactor Characterization

Date: 2026-07-01

## Scope

- `BookQuotes/Services/SubscriptionService.swift`
- `BookQuotes/Services/SubscriptionSyncState.swift`
- `BookQuotesTests/Unit/Services/SubscriptionSyncStateTests.swift`

## Existing Behaviour

- Backend sync responses include:
  - `status`
  - `rawStatus`
  - `expiresAt`
  - `productId`
- `status` is normalized into `SubscriptionStatus`, falling back to `.none`.
- `expiresAt` is parsed with `ISO8601DateFormatter`, falling back to `nil`.
- `productId` is retained for purchased-product fallback.

## Characterization Added

- `SubscriptionSyncStateTests.testMapsActiveResponseWithExpirationAndProductID`
- `SubscriptionSyncStateTests.testMapsCancelledBackendStatus`
- `SubscriptionSyncStateTests.testUnknownStatusFallsBackToNone`

## Non-Goals

- No StoreKit entitlement-selection changes.
- No backend request body or endpoint changes.
- No AuthService persistence changes.
- No paywall UI changes.
