# Subscription Account Token Refactor Characterization

Date: 2026-07-01

## Scope

This slice covers deterministic StoreKit app-account-token generation. It does not change product loading, purchase, restore, entitlement refresh, backend sync, paywall presentation, or subscription management UI.

## Characterized Behaviour

- The token for `reader-1` remains `bf66392e-c65d-53e4-a467-eef774ead731`.
- Different user IDs produce different tokens.
- Generated UUIDs use version 5 bits and RFC 4122 variant bits, matching the existing algorithm.

## Tests Added

- `SubscriptionAccountTokenTests.testTokenIsStableForUserID`
- `SubscriptionAccountTokenTests.testDifferentUserIDsGetDifferentTokens`
- `SubscriptionAccountTokenTests.testTokenUsesVersionFiveAndRfc4122VariantBits`

## Refactor

`SubscriptionAccountToken` now owns the SHA-256 namespace string, first-16-byte truncation, UUID version-bit setting, and RFC 4122 variant-bit setting.

`SubscriptionService.purchaseOptions()` remains responsible for deciding whether a signed-in user exists and whether to add `.appAccountToken(...)`.

## Acceptance Notes

- `SubscriptionService.swift` is 446 LOC after extraction.
- `SubscriptionAccountToken.swift` is 19 LOC.
- Focused XCTest execution remains blocked by the local Xcode startup failure, not by a test assertion.
