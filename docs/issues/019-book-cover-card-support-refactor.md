# Book Cover Card Support Refactor

Status: `closed`

Priority: medium

## Problem

`BookCoverCard.swift` was the largest Swift file remaining in the app at 502 LOC. It mixed two public library presentations, `BookCoverCard` and `BookListRow`, with duplicated support concerns:

- cover image and placeholder rendering;
- quote count badge presentation;
- reading-status badge label, colour, and sizing;
- book context menu item construction;
- grid/list animation and interaction shell.

This made small library UI changes harder to place and left the file just over the sub-500 LOC target.

## Acceptance Criteria

- [x] Characterize the library card/list route before production edits, or record simulator runner limitations.
- [x] Keep public `BookCoverCard` and `BookListRow` APIs unchanged.
- [x] Preserve visible title, author, quote count, status badge, cover placeholder, context menu labels, haptics, accessibility identifiers, and tap behaviour.
- [x] Extract shared support into a focused module that owns real rendering behaviour rather than pass-through wrappers.
- [x] Move `BookCoverCard.swift` below 500 LOC.
- [x] Build passes after extraction.
- [x] Attempt focused library simulator smoke after extraction and record the result.
- [x] Architecture and verification docs record module ownership, test commands, LOC delta, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/Library/BookCoverCardSupport.swift`.
- Kept `BookCoverCard.swift` as the public grid-card and list-row entry point.
- Moved cover artwork, quote count badge, reading-status badge, and context menu items to support views.

## LOC Result

- `BookCoverCard.swift`: 502 LOC -> 304 LOC.
- `BookCoverCardSupport.swift`: 201 LOC.

## Residual Risk / Next Slice

- Focused library UI smoke could not run in this environment because the XCTest UI runner failed before app assertions with `Timed out waiting for AX loaded notification`.
- Visual equivalence is build-verified and structurally constrained, but should be confirmed with a passing simulator/library smoke once the local AX runner is healthy.
