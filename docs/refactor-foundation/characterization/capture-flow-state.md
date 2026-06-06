# Capture Flow State Characterization

## Scope

`CaptureTabRootView.swift` currently owns capture-tab flow transitions inline alongside permission gating, UI composition, selected-book state, and capture flow identity resets.

This slice extracts only the deterministic flow-state decisions. The view should continue to own SwiftUI rendering, haptics, selected `Book` object storage, and the `onBookCreated` callback.

## Current Transition Map

| Current mode | User/system event | Resulting mode | Extra state change |
| --- | --- | --- | --- |
| `selection` | Add New Book | `coverCapture` | none |
| `selection` | Capture Quotes | `bookSelection` | none |
| `selection` | Batch Mode | `bookSelectionForBatch` | none |
| `bookSelection` | Select book | `quoteCapture` | `selectedBook = book`, new `quoteCaptureFlowID` |
| `bookSelection` | Add new book | `coverCapture` | none |
| `bookSelection` | Cancel | `selection` | none |
| `bookSelectionForBatch` | Select book | `batchCapture` | `selectedBook = book`, new `batchCaptureFlowID` |
| `bookSelectionForBatch` | Add new book | `coverCapture` | none |
| `bookSelectionForBatch` | Cancel | `selection` | none |
| `coverCapture` | Complete | `selection` | call `onBookCreated(book)` |
| `coverCapture` | Cancel | `selection` | none |
| `quoteCapture` | Complete | `selection` | `selectedBook = nil` |
| `quoteCapture` | Cancel | `selection` | `selectedBook = nil` |
| `batchCapture` | Complete | `selection` | `selectedBook = nil` |
| `batchCapture` | Cancel | `selection` | `selectedBook = nil` |

## Risk Points

- SwiftUI may preserve child capture state when returning to quote or batch capture. The current implementation forces a fresh flow ID when a book is selected.
- Quote and batch completion must clear `selectedBook`; cover completion currently does not.
- Adding a new book from either book-selection mode reuses the same cover-capture flow path as selecting Add New Book from the initial selection screen.
- UI tests bypass the camera permission gate, so this seam must not alter permission/coaching logic.

## Desired Seam

`CaptureFlowState` should own:

- current flow mode;
- quote and batch flow identity resets;
- transition decisions for capture-tab events;
- commands that tell the view when to clear selected book state.

`CaptureTabRootView` should own:

- the selected `Book` object;
- haptics;
- `onBookCreated`;
- permission and coaching presentation;
- SwiftUI branch rendering.
