# Book Edit UI Sections Characterization

## Scope

`BookEditView.swift` currently owns:

- navigation title and toolbar actions;
- cover image selection, camera sheet presentation, and selected photo loading;
- details fields for title, author, subtitle;
- metadata fields for ISBN, publisher, year, page count, and genre;
- reading status picker and notes field;
- validation triggers for title and author;
- initial draft loading from create/edit/metadata modes;
- save/update behavior through `ModelContext`;
- first-book milestone presentation.

This slice targets the UI section composition only. It should not change draft loading, save mapping, model insertion/update, milestone timing, photo loading, or `BookEditView.Mode`.

## Current Behaviour

| Area | Current behaviour |
| --- | --- |
| Mode title | `.create` shows `Add Book`; `.edit` shows `Edit Book`; `.createFromMetadata` shows `Confirm Book`. |
| Cover section | Shows a 140x210 cover placeholder or image. Allows library selection, optional camera, and remove when an image exists. |
| Details section | Title is required; author is optional but shakes when blank; subtitle is optional. |
| Metadata section | ISBN, publisher, year, pages, and genre are optional. Year/pages use number pads. |
| Status section | Segmented picker over all `ReadingStatus` cases. |
| Notes section | Multi-line optional text field. |
| Save button | Disabled while title is blank; create/metadata label is `Add Book`, edit label is `Save`. |
| Cancel button | Dismisses without saving. |
| Save create | Inserts a new `Book`, triggers first-book milestone when appropriate, calls `onSave`, then dismisses. |
| Save edit | Applies form fields to the existing `Book`, saves, calls `onSave`, then dismisses. |

## Desired Seams

- `BookEditSections`: focused SwiftUI section views for cover, details, metadata, status, and notes.
- `BookEditView`: owns mode, model context, validation, photo loading, draft loading, save/update, dismissal, and milestone behavior.
- Existing `BookEditDraft`, `BookEditSaveDraft`, and `BookEditOptions` remain the behavior seams for data loading and saving.

## Acceptance Notes

- Characterization tests should remain green before and after extraction.
- Simulator acceptance should cover manual create, create with all fields, empty-title validation, cancel, edit/save, and cover UI presence.
- `BookEditView.swift` should move under 500 LOC.
- Extracted section files should stay under 500 LOC and should not contain persistence logic.

## Extraction Outcome

- Added `BookEditSections.swift` for cover, details, metadata, reading-status, and notes UI sections.
- Kept `BookEditView.swift` responsible for mode, `ModelContext`, validation triggers, photo loading, save/update, dismissal, first-book milestone, and toolbar actions.
- `BookEditView.swift` reduced from 645 LOC to 423 LOC.
- `BookEditSections.swift` is 272 LOC.
- Updated `BookRegistrationFlowTests.openFirstBook()` to tap the exposed row `StaticText`/`Image` children. The simulator hierarchy showed `library_book_list_row` is exposed on child elements, not as an XCUI cell/button.

## Verification Summary

- `BookEditDraftTests` and `BookEditSaveDraftTests`: 4 tests, 0 failures before extraction.
- `BookEditDraftTests` and `BookEditSaveDraftTests`: 4 tests, 0 failures after extraction.
- Book registration simulator create/cancel/validation/cover paths: 5 passing tests.
- Existing-book edit simulator paths: 2 passing tests after row-targeting helper fix.
- Create-then-edit persisted title simulator path: 1 passing test.
