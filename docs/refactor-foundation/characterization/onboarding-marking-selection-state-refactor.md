# Onboarding Marking Selection State Characterization

Date: 2026-07-01

Issue: `070-onboarding-marking-selection-state-refactor.md`

## Scope

This slice isolates the marking setup selector's deterministic selected-style state from SwiftUI presentation.

## Characterized Behavior

- Default selection includes:
  - underline,
  - highlight.

- Default selection excludes:
  - margin line.

- Toggling a selected style removes it without disturbing the other default selection.

- Toggling an unselected style adds it without disturbing the default selections.

## Non-Goals

- No persistence of onboarding marking preferences.
- No marking type copy/icon changes.
- No onboarding route changes.
- No visual layout changes.
