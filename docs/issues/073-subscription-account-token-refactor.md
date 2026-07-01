# Issue 073: Subscription Account Token Refactor

Status: `closed`

## Context

`SubscriptionService.swift` is the largest remaining service file and owns StoreKit product loading, purchase/restore, entitlement refresh, backend sync, system subscription management, product display helpers, errors, and app-account-token generation.

The app-account-token algorithm is deterministic and security-relevant: it hashes the signed-in user ID into the UUID passed to StoreKit purchase options. That behavior should be directly characterized without needing StoreKit products, purchase UI, or a live App Store transaction.

## Acceptance Criteria

- [x] Characterize stable app account token output for a known user ID.
- [x] Characterize that different user IDs produce different tokens.
- [x] Characterize UUID version and RFC 4122 variant bits.
- [x] Move token generation out of `SubscriptionService`.
- [x] Preserve the existing token algorithm and StoreKit purchase option behavior.
- [x] Keep `SubscriptionService.swift` below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused subscription token tests when the local Xcode runner is healthy.
- [x] Run subscription/paywall simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Services/SubscriptionAccountToken.swift`.
- Added `BookQuotesTests/Unit/Services/SubscriptionAccountTokenTests.swift`.
- Updated `SubscriptionService.purchaseOptions()` to use `SubscriptionAccountToken.token(for:)`.
- Removed `CryptoKit` import and SHA/UUID byte manipulation from `SubscriptionService.swift`.

## Verification

- `git diff --check` passed.
- `plutil -lint BookQuotes.xcodeproj/project.pbxproj` passed.
- LOC check:
  - `BookQuotes/Services/SubscriptionService.swift`: 421 LOC.
  - `BookQuotes/Services/SubscriptionAccountToken.swift`: 19 LOC.
  - `BookQuotesTests/Unit/Services/SubscriptionAccountTokenTests.swift`: 27 LOC.
- Focused book/save/subscription gate passed: 21 tests, 0 failures.
- Broad unit gate passed: 548 tests, 0 failures.
- Subscription media route smoke passed with monthly/yearly plans and `Start Free Trial` visible.

See `docs/refactor-foundation/verification/2026-07-01-book-save-subscription-reconciliation.md`.

## Follow-Up

- Issue 077 extracts backend sync response mapping.
- Further `SubscriptionService` extraction should target one characterized behavior seam at a time: entitlement status selection, product ID metadata, or subscription error descriptions.
