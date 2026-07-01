# Characterization: Tag Editor Draft Refactor

Date: 2026-07-01

## Scope

This slice characterizes deterministic tag editor save-field behaviour.

It does not change SwiftData insertion/update orchestration, model-context saves, dismissal, sheet state, tag deletion, or quote/tag relationship mutation.

## Characterized Behaviour

`TagEditorDraftTests` pins:

- entered names trim leading/trailing whitespace.
- entered names are lowercased.
- blank names cannot be saved.
- new tags are created with normalized name and selected color.
- existing tags are updated with normalized name and selected color.

## Refactor Rule

`TagEditorDraft` owns deterministic tag editor field normalization, save eligibility, create mapping, and edit mutation.

`TagEditorSheet` remains the SwiftUI shell for text/color state, presentation, SwiftData insertion/update orchestration, model-context saves, and dismissal.

`QuoteTagMutation` remains the relationship mutation seam for adding/removing tags on a quote.

## Current Verification Blocker

The focused tests could not be run in this session because Xcode failed before project compilation due local simulator/cache service errors. See the matching verification note for command output summary and follow-up commands.
