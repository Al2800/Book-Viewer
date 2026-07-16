# 101 - Prevent subscription purchase before account linkage is ready

Status: in_progress
Area: StoreKit / Account / Paywall
Priority: high (release blocker 10)

## Problem

Settings exposes plan purchase while signed out. A customer can complete StoreKit payment but remain blocked from model-assisted extraction until sign-in and backend reconciliation succeeds.

## Acceptance Criteria

- [x] Purchase initiation requires a valid account session and app-account token linkage.
- [x] The reason for sign-in is explained before StoreKit UI appears.
- [x] Purchase completion waits for or clearly reports backend entitlement reconciliation.
- [x] Interrupted reconciliation is recoverable through Restore Purchases.
- [x] No paid user is shown as unsubscribed solely because linkage is delayed.

## Resolution

- A verified StoreKit purchase is retained as an active local entitlement while the
  backend sync runs, so a temporary linkage delay does not turn a paid customer
  into a free customer in the app UI.
- The paywall now distinguishes successful App Store payment from delayed backend
  verification, keeps the purchase screen open, and directs the customer to
  Restore Purchases to retry reconciliation.
- Restore Purchases performs a fresh StoreKit sync and backend reconciliation;
  it only dismisses the paywall after an active entitlement is available.

## Remaining Release Verification

- Run a signed-in Sandbox purchase on a physical device, temporarily interrupt
  the network during reconciliation, then use Restore Purchases after restoring
  connectivity. Confirm the account is enabled server-side and remote extraction
  succeeds.

## 2026-07-16 TestFlight Blocker

Build 41 correctly requests `com.bookquotes.monthly` and `com.bookquotes.yearly`, and App Store
Connect confirms both products have prices plus UK/US availability. StoreKit nevertheless returns
an empty product array because the account's commerce setup is incomplete:

- Paid Apps Agreement: `Pending User Info`
- Bank account: not added
- U.S. tax questionnaire: `Missing Tax Info`

Apple TN3186 identifies an active Paid Apps Agreement and complete banking/tax information as
requirements for sandbox/TestFlight product availability. The Account Holder must complete those
items in App Store Connect Business, wait up to one hour for propagation, then retry Build 41.
No app binary change is required for this blocker.

## Verification

- StoreKit tests for signed-out, signed-in, interrupted, restored, and family/shared ownership states.
- Sandbox device purchase and restore test.
