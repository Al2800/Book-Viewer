# Capture Tab Root Modular Follow-Up Characterization

Date: 2026-06-06

Issue: `docs/issues/001-capture-tab-root-modular-followup.md`

## Baseline Behaviour

This slice keeps `CaptureTabRootView` as the capture shell and moves concrete presentation into deeper capture modules. The baseline user-visible behaviours are:

- Capture tab opens on the three mode choices in this order: cover, quote, batch.
- Mode accessibility identifiers remain stable:
  - `capture_mode_select_cover`
  - `capture_mode_select_quote`
  - `capture_mode_select_batch`
- Quote capture requires a selected existing book before opening the quote camera.
- Batch capture requires a selected existing book before opening batch mode.
- Cover capture opens without an existing book and completion routes to book edit.
- Existing UI-test affordances remain present for mock-camera flows.

## Characterization Added

`CaptureFlowStateTests.testCaptureModeOptionsPreserveOrderAndAccessibilityContracts` captures the mode-option contract before and after extraction.

The selected simulator acceptance set exercises:

- Capture landing content.
- Quote capture book-selection path to test image capture affordance.
- Batch capture entry from the capture tab.
- Cover capture test-cover button navigation to book edit.

## Extracted Modules

- `CaptureModeOption.swift`: mode metadata, ordering, colour, icon, and accessibility contract.
- `CaptureModeSelectionView.swift`: capture landing presentation.
- `BookSelectionForCaptureView.swift`: existing-book selection and empty-library route into cover capture.
- `CaptureFlowViews.swift`: quote, batch, and cover flow wrappers.

## Non-Goals

- No change to extraction model, camera service, OCR, persistence, or navigation destinations.
- No new capture mode.
- No change to TestFlight build 22 observable behaviour.
