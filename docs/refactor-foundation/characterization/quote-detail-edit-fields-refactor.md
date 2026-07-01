# Characterization: Quote Detail Edit Fields Refactor

Date: 2026-07-01

## Scope

This slice characterizes how a live `Quote` is loaded into editable Quote Detail form fields.

It complements `QuoteDetailEditDraft`, which owns applying edited fields back onto a `Quote`.

## Characterized Behaviour

`QuoteDetailEditFieldsTests` pins:

- quote text is copied to editable text.
- existing margin note is copied to editable margin note.
- missing margin note becomes an empty string.
- existing page number becomes its string representation.
- missing page number becomes an empty string.

## Refactor Rule

`QuoteDetailEditFields` owns only quote-to-edit-field loading.

`QuoteDetailEditDraft` owns edit-field-to-quote saving.

`QuoteDetailView` remains the SwiftUI coordinator for edit mode state, haptics, animation, focus, persistence saves, sheets, and dismissal.

## Current Verification Blocker

The focused tests could not be run in this session because Xcode failed before project compilation due local simulator/cache service errors. See the matching verification note for command output summary and follow-up commands.
