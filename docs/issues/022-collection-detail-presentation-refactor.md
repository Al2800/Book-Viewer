# Collection Detail Presentation Refactor

Status: `closed`

Priority: medium

## Problem

`CollectionDetailView.swift` was 487 LOC and mixed the collection detail coordinator with reusable presentation and add-quotes sheet support:

- collection header presentation;
- empty state presentation;
- toolbar menu presentation;
- quote list row wiring;
- add-quotes sheet row/chip helpers;
- collection quote sort vocabulary.

This made the detail screen harder to reason about before adding more collection features or fixing collection-specific UI behaviour.

## Acceptance Criteria

- [x] Characterize collection model/relationship behaviour before production edits.
- [x] Attempt focused simulator UI smoke for collection detail before production edits.
- [x] Keep `CollectionDetailView` responsible for sheet state, search text, sorted/filtered quotes, and SwiftData mutations.
- [x] Move presentation-only collection detail UI into a support module.
- [x] Preserve add-quotes sheet behaviour, including book filtering, search, duplicate exclusion, selection, save, and dismiss.
- [x] Preserve collection detail toolbar actions: add quotes, edit collection, delete collection.
- [x] Preserve quote row navigation, remove swipe action, and favorite swipe action.
- [x] Move `CollectionDetailView.swift` materially below 500 LOC.
- [x] Build passes after extraction.
- [x] Focused collection model/relationship tests pass after extraction.
- [x] Document simulator UI smoke result and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/Collections/CollectionDetailSupport.swift`.
- Moved collection quote sort metadata, header/list/empty/toolbar presentation, and add-quotes sheet support into the support module.
- Kept `CollectionDetailView` as the collection-detail coordinator and persistence mutation owner.

## LOC Result

- `CollectionDetailView.swift`: 487 LOC -> 167 LOC.
- `CollectionDetailSupport.swift`: 323 LOC.

## Residual Risk / Next Slice

- The focused collection detail UI smoke failed before and after this slice because the UI test runner timed out waiting for the AX loaded notification.
- A follow-on Collections slice should repair or replace the failing UI route before making visible behaviour changes to collection detail flows.
