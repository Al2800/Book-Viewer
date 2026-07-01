# Tag Row Presentation Refactor

## Characterized Behaviour

- Tag row presentation exposes the tag name unchanged.
- Tag row presentation exposes the quote count as display text.
- Tag row presentation maps valid `colorName` values to `CollectionColor`.
- Unknown tag color names fall back to `.blue`.

## Refactor Decision

`TagRowPresentation` owns deterministic display values. `TagRowViews` owns the SwiftUI menu/chip presentation.

`TagsView` keeps list/search state, create/edit/delete sheet state, delete confirmation state, model-context deletion, and save orchestration.

## Regression Coverage

- `TagRowPresentationTests`

## Acceptance Notes

- This continues the tag refactor by reducing `TagsView` while keeping action side effects in the existing caller.
- The seam is intentionally small: it is useful because future row display changes no longer require editing the whole tag management screen.
