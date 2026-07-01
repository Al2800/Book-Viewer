# Issue 069: Onboarding Welcome Carousel State Refactor

Status: `closed`

## Context

`OnboardingStepViews.swift` still owned welcome carousel state decisions inline: skip visibility, primary button title, next-page advancement, and completion behavior.

Those decisions are deterministic and should be characterized outside the SwiftUI view before further onboarding step refactors.

## Acceptance Criteria

- [x] Characterize first-page skip visibility and primary button title.
- [x] Characterize advance behavior before the last page.
- [x] Characterize last-page skip visibility, button title, completion action, and page stability.
- [x] Move welcome carousel page-state decisions out of `OnboardingStepViews.swift`.
- [x] Preserve the welcome carousel page order and visible button copy.
- [x] Keep `OnboardingStepViews.swift` below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused onboarding tests when the local Xcode runner is healthy.
- [x] Run simulator onboarding welcome-carousel smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Features/Onboarding/OnboardingWelcomeCarouselState.swift`.
- Added `BookQuotesTests/Unit/Utilities/OnboardingWelcomeCarouselStateTests.swift`.
- `OnboardingWelcomeCarouselView` now delegates skip visibility, primary button title, and next/complete behavior to `OnboardingWelcomeCarouselState`.

## Residual Risk / Next Slice

- Full swipe/tap behavior still needs simulator verification once CoreSimulatorService is available.
- Further welcome-page content changes should stay in `WelcomePage` and be characterized separately.

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
