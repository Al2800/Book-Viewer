# Collection Detail Presentation Characterization

Date: 2026-06-30

Issue: `docs/issues/022-collection-detail-presentation-refactor.md`

## Baseline Behaviour

This slice preserves collection detail behaviour while extracting presentation-only code.

Collection detail behaviours retained:

- The screen title uses the collection name.
- The collection detail accessibility identifier remains `AccessibilityIdentifiers.Collections.detailView`.
- Empty collections show the "No Quotes Yet" state with an Add Quotes action.
- Non-empty collections show collection metadata followed by quote rows.
- Quote rows navigate to quote detail through the existing `NavigationLink(value:)` route.
- Trailing swipe removes a quote from the collection and saves the model context.
- Leading swipe toggles favourite status and saves the model context.
- Search filters by quote text, book title, and margin note.
- Sort order supports date added, book title, and page number.
- Toolbar actions open add-quotes, edit, and delete flows.
- Deleting the collection deletes only the collection, not books or quotes.

Add-quotes sheet behaviours retained:

- Existing collection quotes are excluded.
- Book filter chips filter available quotes.
- Search filters by quote text and book title.
- Selecting rows updates the Add count.
- Adding selected quotes appends missing quotes, updates `dateModified`, saves, and dismisses.

## Characterization Used

Focused model/relationship baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CollectionModelTests \
  -only-testing:BookQuotesTests/CollectionTagRelationshipIntegrationTests
```

Result before edits:

- Passed.
- Runtime: `38.387` seconds.

Focused collection detail UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/CollectionsTagsFlowTests/testCollection_TapCollection_ShowsCollectionDetail
```

Result before edits:

- Failed before production edits.
- Failure: `BookQuotesUITests-Runner ... Timed out waiting for AX loaded notification`.

## Extracted Module

- `CollectionDetailSupport.swift`: collection quote sort metadata, quote list/header/empty/toolbar presentation, add-quotes sheet, add-quotes selection row, book filter chip, and local unique-array helper.

## Non-Goals

- No change to collection deletion semantics.
- No change to add/edit sheet routing.
- No change to quote search or sort semantics.
- No change to tests to make this pass.
