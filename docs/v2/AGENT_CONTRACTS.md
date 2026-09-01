# BookQuotes v2 agent contracts

These rules apply to human contributors and AI coding agents working on the v2 programme. They supplement the root `AGENTS.md`.

## 1. Product invariant

The core loop is:

```text
Active book -> Capture -> Review uncertainty -> Persist -> Retrieve
```

A change that adds ceremony to this loop must justify the user value and provide before/after interaction evidence.

## 2. Product hierarchy

- **Reading** is the passage-first home.
- **Capture** is the active-book camera and review workflow.
- **Explore** is grounded retrieval and connection.
- **Studio** is contextual from a passage.
- **Settings** is secondary.

Do not add a primary tab without changing the product specification first.

## 3. Camera ownership

- `AVCaptureSession` is owned only by camera infrastructure.
- SwiftUI views do not start, stop, reconfigure or tear down capture sessions directly.
- All queued session work must be invalidatable when its owner is replaced or dismissed.
- Hardware behaviour requires a physical-device verification note.

## 4. Capture workflow

- One coordinator owns valid workflow transitions.
- Views render state and emit events.
- Do not introduce a new boolean presentation flag when the condition represents a workflow state.
- Recoverable source input must survive until persistence succeeds.

## 5. Extraction

- Extractors return structured candidates and never navigate UI.
- Candidate order is page order.
- Local and cloud extractors conform to the same domain contract.
- Raw confidence is not normal user-facing copy. Confidence changes selection state: automatic, Check or unselected.
- No local model controls automatic selection before benchmark gates pass.
- Evaluation fixtures are immutable evidence. Do not tune against the held-out set.

## 6. Persistence

- Do not use `try? modelContext.save()` in a user-data mutation path.
- Present a recoverable error when persistence fails.
- Delete source files only after the replacement model state is saved.
- Every searchable mutation must update the search index or issue an explicit index mutation.

## 7. Images

- Feature views do not synchronously decode large image blobs repeatedly.
- Use shared image infrastructure with cancellation and stable cache identity.
- A byte count is not a valid content cache key.
- Preserve source provenance independently of display thumbnails.

## 8. UI

- One primary action per workflow state.
- Reading is quiet and editorial.
- Capture is dark and functional.
- Review is neutral and precise.
- Studio may be expressive.
- Do not use decorative gold, glass, 3D motion or nested cards without a functional reason.
- Every user-visible control requires a stable accessibility identifier.
- Dynamic Type, VoiceOver, Reduce Motion and contrast are acceptance criteria, not later polish.

## 9. Navigation

- Navigation destinations are defined centrally for each product shell.
- Do not create a feature-local route that bypasses the canonical Book or Passage destination.
- Adding a book from Capture returns to Capture with that book active.

## 10. Export

- Preview and exported rendering share the same state.
- Escaping is required for YAML, Markdown tables and multiline blockquotes.
- Export failures must be visible.

## 11. File ownership

Prefer semantic files such as:

- `CaptureBookSwitcher.swift`;
- `CaptureResultReview.swift`;
- `SourcePageViewer.swift`;
- `ProvenanceOverlay.swift`;
- `ReadingHome.swift`.

Avoid adding new dumping-ground files named `SupportViews`, `FlowViews` or `OverviewViews`. Existing large files may be decomposed when touched, but decomposition should preserve behaviour and tests.

## 12. Pull-request contract

Every PR description must contain:

1. baseline and dependency;
2. user problem;
3. behavioural change;
4. files or subsystem owned;
5. automated verification;
6. manual or physical-device verification;
7. migration/recovery impact;
8. explicit non-goals.

## 13. Definition of done

A task is not complete when code has been written. It is complete when:

- the intended state is reachable;
- invalid states are prevented or recoverable;
- tests cover the contract;
- documentation reflects any changed invariant;
- the PR can be reviewed without reconstructing product intent from implementation.
