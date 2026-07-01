# Issue 080: Tags Casing Contract Conflict

Status: `closed`

## Context

`TagsPresentationTests.testFilteringMatchesCaseInsensitively` currently expects filtered tag names to retain mixed-case input:

```text
["Strategy", "Systems"]
```

The production `Tag` model deliberately normalizes names to lowercase on initialization:

```swift
self.name = name.lowercased().trimmingCharacters(in: .whitespaces)
```

`TagModelTests.testTagNormalizesName` already characterizes that behaviour by expecting `Tag(name: "  Productivity ").name` to become `productivity`.

This is a contract conflict, not a simple filtering failure. The product needs one explicit rule:

- tags are stored and displayed as canonical lowercase labels, or
- tags preserve display casing while using a separate normalized key for identity/search.

## Acceptance Criteria

- Decide the canonical tag casing contract before production edits.
- Keep case-insensitive search filtering.
- Preserve duplicate prevention semantics for tags.
- Preserve tag sorting and existing tag relationship mutation behaviour.
- Do not introduce arbitrary case behaviour that depends on whitespace or input shape.
- Update tests to describe the chosen public behaviour.
- Run focused tags tests:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/TagsPresentationTests
```

- Run nearby tag/model tests:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/TagsPresentationTests \
  -only-testing:BookQuotesTests/TagModelTests \
  -only-testing:BookQuotesTests/TagEditorDraftTests \
  -only-testing:BookQuotesTests/QuoteTagMutationTests
```

## Implementation

- Confirmed the established product contract: tags are stored and displayed as canonical lowercase labels.
- Kept `Tag` and `TagEditorDraft` normalization behaviour unchanged.
- Corrected `TagsPresentationTests.testFilteringMatchesCaseInsensitively` so it verifies case-insensitive matching while preserving canonical lowercase output.

## Verification

Latest broad evidence:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests
```

Result: `TagsPresentationTests.testFilteringMatchesCaseInsensitively` failed because stored tag names are lowercase.

Focused verification after the characterization correction:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/TagsPresentationTests \
  -only-testing:BookQuotesTests/TagModelTests \
  -only-testing:BookQuotesTests/TagEditorDraftTests \
  -only-testing:BookQuotesTests/QuoteTagMutationTests
```

Result: 11 tests executed, 0 failures.

## Follow-Up

- If the chosen product direction is case-preserving display names, add a normalized identity/search field rather than overloading `Tag.name`.
- If the chosen product direction is lowercase canonical labels, correct the presentation characterization to assert lowercase results and keep the filtering behaviour covered.
