# Onboarding Media Subscription Plan Characterization

Date: 2026-07-01

Issue: `067-onboarding-media-subscription-plan-refactor.md`

## Scope

This slice isolates the deterministic fallback plan data used by the onboarding embedded paywall when StoreKit products are unavailable and the App Store/TestFlight media subscription route is open.

## Characterized Behavior

- Monthly fallback plan:
  - title: `Monthly`
  - price: `$4.99`
  - subtitle: `Flexible access for regular readers`
  - period: `per month`
  - badge: none

- Yearly fallback plan:
  - title: `Yearly`
  - price: `$39.99`
  - subtitle: `Best value for committed readers`
  - period: `per year`
  - badge: `Best Value`

- Display order stays monthly before yearly.

## Non-Goals

- No StoreKit purchase behavior changes.
- No product loading behavior changes.
- No onboarding route changes.
- No visual copy changes.
