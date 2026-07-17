# Build 45 Session and Purchase Restoration

## Scope

Build 45 keeps the accepted Build 44 camera, subscription, model-assisted extraction, account
deletion, and network-recovery behavior. It addresses the two findings from the final recovery
pass:

- Saved BookQuotes credentials are restored securely during launch and retried after foregrounding
  or network reconnection. Only a definitive expired-session response clears them.
- Restore Purchases first reconciles an active entitlement already visible through StoreKit. It
  requests a full App Store account sync only when no entitlement is available and shows an
  explicit success confirmation when restoration completes.

The dormant legacy offline queue is not part of the current capture workflow. The supported
offline path remains the accepted explicit failure screen with Retry AI, Use On-Device Instead,
and manual-entry recovery.

## Verification

- Focused iPhone 17 / iOS 26.5 restoration tests: 14 passed, 0 failures.
- Complete iPhone 17 unit target: 656 passed, 0 failures, 1 existing optional local-photo fixture
  skip.
- Signed Release archive: succeeded.
- `git diff --check`: passed before commit.

## TestFlight Delivery

- Version: `1.0`.
- Build: `45`.
- Source commit: `8ef5aac` on `main`.
- Signed archive: `artifacts/release/BookQuotes-1.0-45.xcarchive`, arm64.
- TestFlight upload: succeeded on 2026-07-17.
- App Store Connect build ID: `2ebf7662-8840-4d6c-b5b6-dc42281e75db`.
- Processing state: `VALID`.
- Encryption declaration: `usesNonExemptEncryption: false`.
- Internal group: `Test v1`, with access to all builds and one tester.

## Final Device Check

1. Force-close and reopen Build 45. Confirm the BookQuotes account remains signed in and the
   subscription remains active.
2. Select Restore Purchases. Confirm the operation completes with `Purchases Restored` and does
   not force the unnecessary Apple account-sync prompt that failed in Build 44.
