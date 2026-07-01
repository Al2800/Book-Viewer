# Onboarding Welcome Carousel State Characterization

Date: 2026-07-01

Issue: `069-onboarding-welcome-carousel-state-refactor.md`

## Scope

This slice isolates deterministic welcome carousel state from SwiftUI presentation.

## Characterized Behavior

- First page:
  - skip button is visible,
  - primary button title is `Continue`.

- Advancing before the last page:
  - returns `.showNextPage`,
  - increments the current page.

- Last page:
  - skip button is hidden,
  - primary button title is `Get Started`,
  - advancing returns `.complete`,
  - current page stays unchanged.

## Non-Goals

- No welcome page copy changes.
- No page order changes.
- No onboarding route changes.
- No animation behavior changes beyond delegating state decisions.
