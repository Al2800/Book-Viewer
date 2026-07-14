# 106 - Eliminate false-green UI test skips

Status: open
Area: XCUITest / Release Gate
Priority: high (release blocker 15)

## Problem

The full UI target contains 33 `XCTSkip` branches. Several skip when a required application control, navigation route, fixture, editor, review, or save action is missing. Those conditions conceal regressions by reporting a skip instead of a failure. Only genuine environment constraints, such as unavailable physical camera hardware, may remain skips and must be explicitly reported.

## Acceptance Criteria

- [ ] Replace skips caused by missing application UI, fixtures, navigation, or save actions with failing assertions.
- [ ] Make mocked camera and seeded-data dependencies deterministic so workflow tests do not skip because setup did not arrive.
- [ ] Retain skips only for verified simulator or device limitations, with a clear reason and separate reporting.
- [ ] Run the full UI target with zero false-green skips and investigate every remaining failure.
- [ ] Record the final pass, failure, and genuine-environment skip counts in release evidence.

## Initial Inventory

- `BatchCaptureFlowTests`: 14 skip sites.
- `CoverCaptureFlowTests`: 5 skip sites.
- `QuoteCaptureFlowTests`: 11 skip sites.
- `LibraryManagementTests`: 1 skip site.
- `OnboardingFlowTests`: 2 skip sites.

## Verification

- Run each affected workflow individually after replacing its skips.
- Run the full UI target on phone and iPad simulators.
- Preserve `xcresult` bundles and distinguish product failures from documented simulator limitations.
