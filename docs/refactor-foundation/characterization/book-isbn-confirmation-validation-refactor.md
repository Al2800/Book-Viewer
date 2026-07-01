# Book ISBN Confirmation Validation Refactor

## Characterized Behaviour

- Title is valid when it contains non-whitespace text.
- Author is valid when it contains non-whitespace text.
- Overall validity requires both title and author to be valid.

## Refactor Decision

`BookISBNConfirmationValidation` owns deterministic ISBN confirmation field validity.

`BookISBNConfirmationSheet` keeps:

- editable field state;
- invalid-field shake triggers;
- error haptic;
- save orchestration;
- model-context insertion;
- callbacks and dismissal;
- cover loading.

This keeps validation behavior directly testable without extracting UI-specific animation or persistence concerns.

## Regression Coverage

- `BookISBNConfirmationValidationTests` covers valid fields, blank title, and blank author.
