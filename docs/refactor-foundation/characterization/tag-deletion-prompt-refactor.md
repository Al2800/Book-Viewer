# Tag Deletion Prompt Refactor

## Characterized Behaviour

- Tag deletion title remains `Delete Tag?`.
- Destructive action title remains `Delete Tag`.
- Warning copy uses `quote` for one linked quote and `quotes` otherwise.

## Refactor Decision

`TagDeletionPrompt` owns deletion prompt copy and pluralization.

`TagsView` keeps:

- selected-tag state;
- confirmation dialog presentation;
- SwiftData model deletion;
- model-context save;
- selected-tag clearing.

This keeps user-facing copy characterized while avoiding a shallow deletion-action seam for persistence behavior that is still simple and view-owned.

## Regression Coverage

- `TagDeletionPromptTests` covers title/action copy plus singular and plural warning messages.
