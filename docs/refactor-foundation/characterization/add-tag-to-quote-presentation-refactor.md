# Add Tag To Quote Presentation Refactor

## Characterized Behaviour

- A quote's current tags are excluded from available addable tags.
- Available tag order follows the `allTags` ordering supplied to the presentation module.
- When a quote has no current tags, all tags remain available.

## Refactor Decision

`AddTagToQuotePresentation` is a focused presentation seam for deterministic add-to-quote availability filtering.

`AddTagToQuoteSheet` keeps SwiftUI and persistence orchestration:

- current tag chips;
- available tag section rendering;
- create-tag sheet presentation;
- `QuoteTagMutation` add/remove calls;
- model-context save;
- dismissal.

This avoids growing `TagsView.swift` while keeping relationship mutation and presentation filtering in separate, testable modules.

## Regression Coverage

- `AddTagToQuotePresentationTests` covers exclusion, order preservation, and the empty-current-tags case.
