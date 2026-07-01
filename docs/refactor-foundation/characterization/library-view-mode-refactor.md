# Library View Mode Characterization

## Scope

This slice isolates the Library grid/list mode from `LibraryView`.

## Current Behaviour Characterized

- Grid mode is stored as `grid`.
- List mode is stored as `list`.
- Grid mode uses SF Symbol `square.grid.2x2`.
- List mode uses SF Symbol `list.bullet`.
- Grid mode appears in Library summary copy as `Grid View`.
- List mode appears in Library summary copy as `List View`.

## Missing Test Surface Before This Slice

The grid/list mode enum lived inside `LibraryView`, while extracted Library modules consumed it for summary and picker presentation. The behaviour was visible, but there was no focused unit seam for changing stored values or display metadata.

## Refactor Decision

Create `LibraryViewMode` in `Features/Library/` and make it own the stored values and display metadata. `LibraryView`, `LibrarySummaryCard`, `LibraryBooksSection`, and `LibraryViewModeControl` now use that type directly.

## Acceptance Coverage Added

- `LibraryViewModeTests.testGridModePreservesStoredValueAndPresentation`
- `LibraryViewModeTests.testListModePreservesStoredValueAndPresentation`

## Non-Goals

- No change to Library search lifecycle.
- No change to book grid/list rendering.
- No change to `@AppStorage("libraryViewMode")`.
- No change to Library navigation, delete, add/edit sheet, or refresh behaviour.
