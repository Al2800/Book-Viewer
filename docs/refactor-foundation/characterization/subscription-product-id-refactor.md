# Subscription Product ID Refactor Characterization

Date: 2026-07-01

## Scope

- `BookQuotes/Services/SubscriptionService.swift`
- `BookQuotes/Services/SubscriptionProductID.swift`
- `BookQuotesTests/Unit/Services/SubscriptionProductIDTests.swift`

## Existing Behaviour

- Monthly StoreKit product id is `com.bookquotes.monthly`.
- Yearly StoreKit product id is `com.bookquotes.yearly`.
- Product ids are requested in monthly, yearly order.
- Product display labels are `Monthly` and `Yearly`.

## Characterization Added

- `SubscriptionProductIDTests.testProductIdentifiersMatchAppStoreConnectProducts`
- `SubscriptionProductIDTests.testProductIdentifiersStayInDisplayOrder`
- `SubscriptionProductIDTests.testDisplayNamesMatchPaywallCopy`

## Non-Goals

- No StoreKit product loading strategy changes.
- No pricing, paywall, subscription status, or backend sync changes.
