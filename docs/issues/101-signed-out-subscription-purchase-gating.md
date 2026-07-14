# 101 - Prevent subscription purchase before account linkage is ready

Status: in_progress
Area: StoreKit / Account / Paywall
Priority: high (release blocker 10)

## Problem

Settings exposes plan purchase while signed out. A customer can complete StoreKit payment but remain blocked from model-assisted extraction until sign-in and backend reconciliation succeeds.

## Acceptance Criteria

- [x] Purchase initiation requires a valid account session and app-account token linkage.
- [x] The reason for sign-in is explained before StoreKit UI appears.
- [ ] Purchase completion waits for or clearly reports backend entitlement reconciliation.
- [ ] Interrupted reconciliation is recoverable through Restore Purchases.
- [ ] No paid user is shown as unsubscribed solely because linkage is delayed.

## Verification

- StoreKit tests for signed-out, signed-in, interrupted, restored, and family/shared ownership states.
- Sandbox device purchase and restore test.
