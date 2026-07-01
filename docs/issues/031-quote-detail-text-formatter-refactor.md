# Issue 031: Quote Detail Text Formatter Refactor

Status: closed

## Problem

`QuoteDetailView` duplicated the copy/share quote-attribution string construction. The behaviour was small, but it was a user-visible contract and lived inside an already-large detail screen.

The detail view should keep UI state, editing, menus, sheets, persistence, haptics, and dismissal. The quote detail text used for copy/share should have a focused test seam.

## Acceptance Criteria

- Characterize the existing quote detail copy/share text before production edits.
- Preserve the quote detail text format:
  - quote text wrapped in straight double quotes;
  - optional book attribution on a blank line with `— {title} by {author}`;
  - optional page suffix `, p. {page}` only when a book and page exist;
  - no attribution when the quote has no book.
- Use the same formatter for copy and share actions.
- Keep all touched files under 500 LOC.
- Run focused formatter tests, nearby Library/model characterization, simulator build, and a quote-detail UI smoke attempt.

## Result

- Added `QuoteDetailTextFormatter`.
- Added `QuoteDetailTextFormatterTests`.
- Updated `QuoteDetailView` to use the formatter for copy and share.
- Reduced `QuoteDetailView.swift` from 449 LOC to 435 LOC.
