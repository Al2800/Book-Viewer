# Quote Detail Text Formatter Refactor Characterization

Date: 2026-06-30

Issue: `docs/issues/031-quote-detail-text-formatter-refactor.md`

## Baseline Behaviour

`QuoteDetailView` used the same text shape for copying and sharing a quote:

- the quote text is wrapped in straight double quotes;
- when the quote has a book, attribution is appended after a blank line as `— {title} by {author}`;
- when the quote has a book and page number, the page suffix is appended as `, p. {page}`;
- when the quote has no book, only the quoted text is returned.

This behavior was duplicated in `copyToClipboard()` and `shareableQuoteText`.

## Characterization Tests

Added `QuoteDetailTextFormatterTests` before the production module existed. The red state was a compile failure because `QuoteDetailTextFormatter` was missing.

The tests characterize:

- quote, book, author, and page output;
- quote-only output when the book is missing;
- book attribution without page suffix when the page is missing.

## Refactor Boundary

`QuoteDetailTextFormatter` owns only the quote-detail copy/share text contract.

`QuoteDetailView` keeps editing state, menu/sheet presentation, persistence, haptics, deletion, source image display, marking picker routing, and navigation.
