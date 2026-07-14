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

## Verification

- StoreKit tests for signed-out, signed-in, interrupted, restored, and family/shared ownership states.
- Sandbox device purchase and restore test.
