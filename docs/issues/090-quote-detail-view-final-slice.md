# 090 - Quote Detail View final orchestration slice

Status: closed
Area: Library / Quote detail
Priority: medium

## Problem

`QuoteDetailView.swift` is currently the only production app Swift file above the 500 LOC guide. It has already been deepened through formatter, edit draft, edit fields, and deletion prompt modules, but the July feature/refactor stream pushed it back to 551 LOC.

This is not automatically a blocker if the file remains cohesive, but it is the clearest remaining app-side size target before feature work resumes.

## Acceptance Criteria

- [x] Characterization confirms quote display, copy/share text, edit/save/correction recording, delete confirmation, and navigation behaviour before production edits.
- [x] One cohesive slice is extracted from `QuoteDetailView.swift` into a deeper module that owns real behaviour.
- [x] `QuoteDetailView.swift` moves below 500 LOC.
- [x] Existing quote detail unit tests and nearby Library tests pass.
- [x] Simulator build passes; UI smoke is attempted where the runner is available.

## Characterization Plan

- Re-run focused quote detail tests first.
- Prefer extracting deterministic state/action policy over tiny presentational wrappers.
- Avoid changing edit-screen behaviour unless a characterization test is red first.

## Related Issues

- `015-library-tab-modular-refactor.md`
- `044-quote-detail-edit-draft-refactor.md`
- `050-quote-detail-edit-fields-refactor.md`

## Progress

2026-07-13:

- Added `QuoteDetailSections.swift` for the Quote Detail organize, source-image, and book sections.
- Kept `QuoteDetailView` responsible for state, toolbar, sheets, model-context persistence, and actions.
- Reduced `QuoteDetailView.swift` from 551 LOC to 448 LOC.
- Simulator build passed.
- Focused Quote Detail/nearby Library tests passed: 19 tests, 0 failures.
