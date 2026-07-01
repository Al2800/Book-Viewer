# Issue 070: Onboarding Marking Selection State Refactor

Status: `closed`

## Context

`OnboardingMarkingViews.swift` stored selected marking styles directly in the SwiftUI view and performed selection toggling inline.

That selection behavior is deterministic and should be characterized before further marking setup changes.

## Acceptance Criteria

- [x] Characterize default selected marking styles.
- [x] Characterize toggling a selected style off.
- [x] Characterize toggling an unselected style on.
- [x] Move marking selection state out of `OnboardingMarkingViews.swift`.
- [x] Preserve default underline/highlight selection.
- [x] Preserve haptic feedback from the selector tap.
- [x] Keep `OnboardingMarkingViews.swift` below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused onboarding tests when the local Xcode runner is healthy.
- [x] Run simulator onboarding smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Features/Onboarding/OnboardingMarkingSelectionState.swift`.
- Added `BookQuotesTests/Unit/Utilities/OnboardingMarkingSelectionStateTests.swift`.
- `MarkingTemplateSelector` now delegates selected-style checks and toggling to `OnboardingMarkingSelectionState`.

## Residual Risk / Next Slice

- The selector currently keeps selections local to onboarding presentation. Persisting preferred marking styles should be handled as a separate product issue with explicit acceptance criteria.
- Visual selector behavior still needs simulator smoke once CoreSimulatorService is available.

## Verification

- Focused onboarding/capture queue characterization gate on 2026-07-01:
  - 84 tests executed.
  - 0 failures.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual onboarding reset simulator smoke:
  - App launched with `--uitesting --reset-onboarding --skip-auth`.
  - Screenshot showed the onboarding welcome screen.
