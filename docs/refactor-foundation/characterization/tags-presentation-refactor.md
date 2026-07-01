# Characterization: Tags Presentation Refactor

Date: 2026-07-01

## Scope

This slice characterizes tag browsing presentation calculations that were still embedded in `TagsView`.

It does not change tag creation, editing, deletion, quote/tag relationship mutation, SwiftData saves, or sheet state.

## Characterized Behaviour

`TagsPresentationTests` pins:

- total uses sums all tag quote counts.
- empty search text returns every tag.
- search text filters tag names case-insensitively.

## Refactor Rule

`TagsPresentation` owns deterministic tag browsing calculations.

`TagsView` remains the SwiftUI shell for navigation, search field state, sheets, delete confirmation, model-context saves, and tag row actions.

`QuoteTagMutation` remains the relationship mutation seam for adding/removing tags on a quote.

## Current Verification Blocker

The focused tests could not be run in this session because Xcode failed before project compilation due local simulator/cache service errors. See the matching verification note for command output summary and follow-up commands.
