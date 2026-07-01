# Tag Editor Sheet Refactor

## Characterized Behaviour

- Create mode uses `New Tag` as the navigation title.
- Create mode uses `Create` as the confirmation action title.
- Edit mode uses `Edit Tag` as the navigation title.
- Edit mode uses `Save` as the confirmation action title.

## Refactor Decision

`TagEditorModePresentation` owns deterministic mode copy. `TagEditorSheet` owns the SwiftUI form and the concrete insert/update/save/dismiss flow.

`TagEditorDraft` continues to own tag name normalization, save eligibility, new-tag creation, and edited-field application.

## Regression Coverage

- `TagEditorModePresentationTests`
- Existing `TagEditorDraftTests`

## Acceptance Notes

- This reduces `TagsView` without moving persistence side effects into a shallow helper.
- The sheet remains the correct module for model-context insertion/update and dismissal.
