# BookQuotes v2 delivery plan

## 1. Delivery strategy

The reset is delivered as a sequence of mergeable pull requests. Each PR should be understandable and reversible in isolation. Product structure changes and extraction research remain in the same repository, but are separated by feature boundaries and verification gates.

## 2. Baseline

At the start of this programme:

- the existing App Store version remains live;
- TestFlight Build 51 is the engineering baseline;
- camera, Batch, ISBN and UI correctness hardening from PRs #6 to #8 is incorporated;
- the new product shell is not yet the default.

## 3. Phase A: contracts and safe entry

### PR A1: product and architecture contracts

Add the v2 specification, architecture boundaries, agent contracts, ADR and delivery plan. No runtime behaviour changes.

Acceptance:

- product thesis and non-goals are explicit;
- Reading, Capture and Explore responsibilities are defined;
- local/cloud extraction policy is documented;
- agent invariants are reviewable in the repository.

### PR A2: feature-flagged product shell

Add a default-off shell with three primary destinations:

- Reading, initially backed by the existing Library surface;
- Capture, backed by the hardened capture implementation;
- Explore, initially providing grounded passage search and revisit.

Studio leaves the primary tab bar in the v2 shell but remains accessible from passage detail. Settings remains accessible as a secondary destination.

Acceptance:

- existing shell remains unchanged when the flag is off;
- launch argument enables v2 deterministically;
- existing data appears in both shells;
- no model migration is required.

### PR A3: design-system reduction

Create named semantic roles for Reading, Capture, Review and Studio. Remove new v2 code's dependency on decorative legacy styles where those styles conflict with information hierarchy.

Acceptance:

- typography, colour, control hierarchy and motion rules have previews;
- accessible contrast and Dynamic Type are verified;
- no broad legacy visual rewrite is included.

## 4. Phase B: Reading

### PR B1: Reading data adapter

Add tested derivation for:

- active book;
- recent passages;
- deterministic revisit;
- books with passage counts;
- empty-state decisions.

### PR B2: Reading home

Implement passage-first hierarchy:

1. search;
2. continue reading;
3. recent passages;
4. revisit;
5. books.

### PR B3: passage-first book detail

Lead with captured passages and search within the book. Move publication metadata into a secondary details surface.

### PR B4: passage detail

Create the canonical passage surface with source provenance, notes, related actions and contextual Studio entry.

## 5. Phase C: Capture 2.0

### PR C1: capture coordinator

Introduce the explicit state machine without changing the user-visible workflow. Add transition tests.

### PR C2: camera shell

Implement active-book context, Change, flash, shutter and Batch in one coherent camera surface.

### PR C3: contextual book switcher

Unify existing books, search, ISBN scanning and manual addition. Completion returns to Capture with the new book active.

### PR C4: quality gate

Allow clearly usable images to proceed without mandatory image-review ceremony. Keep Retake and Use Anyway for poor images.

### PR C5: inline passage review

Implement frozen source page, linked overlays, selected candidates, Check state and Save N.

### PR C6: Batch integration

Use the same camera and review language for Batch, including safe drafts and immediate page persistence.

## 6. Phase D: Explore and retrieval

### PR D1: mutation-driven indexing

Replace count-based rebuild triggers with explicit searchable mutations.

### PR D2: Explore search

Search passage text, books, authors, notes and tags. All results navigate to grounded source material.

### PR D3: revisit

Add deterministic, useful resurfacing without streaks or engagement manipulation.

### PR D4: topics

Expose topics only after quality and editability are sufficient.

## 7. Phase E: on-device extraction

### PR E1: benchmark schema and harness

Define labelled-page fixtures, expected passages and passage-level metrics.

### PR E2: Vision OCR baseline

Measure OCR accuracy and latency on representative devices.

### PR E3: OCR-anchored underline detector

Classify marking evidence around recognised text lines using deterministic computer vision and heuristics.

### PR E4: additional marks

Add highlighter, margin line and bracket handling independently.

### PR E5: confidence calibration

Map scores to automatic, Check and hidden bands using held-out fixtures.

### PR E6: TestFlight shadow mode

Compare local output with cloud output and user corrections without altering the visible result.

### PR E7: local suggestions

Allow local candidates to appear without controlling automatic selection.

### PR E8: local-first rollout

Proceed only if passage precision, recall, latency, false-positive and Batch stability gates pass.

## 8. Phase F: connections

### PR F1: semantic passage index

Index saved passages, not entire books, with source links.

### PR F2: related passages

Show grounded similarities with transparent source passages.

### PR F3: Ask Your Reading

Answer only from the user's saved corpus and cite passages. State when evidence is insufficient.

### PR F4: themes and different perspectives

Support editable themes and evidence-backed comparisons.

## 9. Cross-cutting work

The following run throughout the programme:

- visible persistence errors;
- shared source-image pipeline;
- accessibility identifiers;
- screenshot references;
- feature-folder documentation;
- architecture checks;
- privacy-safe analytics;
- TestFlight release evidence.

## 10. Merge gates

No PR is ready merely because it compiles. It must include:

- affected user journey;
- acceptance criteria;
- automated tests where possible;
- physical-device checks where hardware behaviour is involved;
- migration and recovery consequences;
- screenshots for material UI changes.

The v2 flag becomes the default only after Reading, Capture and Explore meet the release gates in `PRODUCT_SPEC.md`.
