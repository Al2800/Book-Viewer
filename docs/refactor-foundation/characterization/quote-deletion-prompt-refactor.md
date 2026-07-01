# Quote Deletion Prompt Refactor

## Characterized Behaviour

- Quote Detail destructive dialog title remains `Delete Quote?`.
- Quote Detail destructive action title remains `Delete`.
- Quote Detail dialog message remains `This action cannot be undone.`

## Refactor Decision

The extraction is deliberately narrow. `QuoteDeletionPrompt` owns stable user-facing copy only.

`QuoteDetailView` keeps the mutable and side-effecting behaviour: confirmation presentation state, quote deletion, context save, warning haptic, and dismissal.

## Regression Coverage

- `QuoteDeletionPromptTests`

## Acceptance Notes

- This mirrors the existing `BookDeletionPrompt` and `TagDeletionPrompt` seams.
- It reduces inline prompt copy in `QuoteDetailView` without changing deletion behaviour.
