# Capture Tab Root Modular Follow-Up

Status: `closed`

Priority: high

## Problem

`CaptureTabRootView.swift` is 812 LOC. It mixes permission gating, first-capture coaching, selected-book state, capture mode routing, mode-selection presentation, book-selection presentation, and capture-flow wrappers.

The previous slice introduced `CaptureFlowState`; this slice should continue from that seam without changing current build 22 behaviour.

## Acceptance Criteria

- [x] Current mode-selection, book-selection, cover-capture, quote-capture, and batch-capture transitions are characterized before production edits.
- [x] At least one focused unit seam or simulator acceptance test is added or strengthened before extraction.
- [x] Extracted modules own real UI behaviour and accessibility contracts, not single-line pass-through wrappers.
- [x] `CaptureTabRootView.swift` moves materially toward sub-500 LOC.
- [x] Selected-book clearing, quote/batch identity refresh, cover completion, coaching, and permission behaviour are preserved.
- [x] Simulator acceptance covers the capture paths touched by the refactor.
- [x] Verification docs record tests, LOC delta, and neutral behaviour notes.

## Initial Target

Extract cohesive start/book-selection presentation and flow wrapper modules while keeping orchestration state in `CaptureTabRootView`.

## Outcome

Closed on 2026-06-06.

- `CaptureTabRootView.swift` reduced from 812 LOC to 174 LOC.
- Added `CaptureModeOption`, `CaptureModeSelectionView`, `BookSelectionForCaptureView`, and `CaptureFlowViews`.
- Added characterization for capture mode ordering and accessibility identifiers.
- Selected simulator acceptance passed for capture landing, quote capture entry, batch entry, and cover capture test navigation.

See:

- `docs/refactor-foundation/characterization/capture-tab-root-modular-followup.md`
- `docs/refactor-foundation/verification/2026-06-06-capture-tab-root-modular-followup.md`
