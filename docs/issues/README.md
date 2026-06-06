# Local Issues

This folder tracks local markdown issues for the refactor programme.

## Status Values

- `open`
- `in_progress`
- `closed`

## Current Issues

- `001-capture-tab-root-modular-followup.md` - closed
- `002-extraction-review-view-modular-refactor.md` - closed
- `003-batch-capture-view-lifecycle-refactor.md` - closed
- `004-design-system-modular-refactor.md` - closed
- `005-settings-tab-modular-refactor.md` - closed
- `006-extraction-review-simulator-route-repair.md` - closed
- `007-testflight-build-22-quote-extraction-empty-results.md` - in_progress
- `008-cover-metadata-noisy-title-author-extraction.md` - closed
- `009-cover-capture-white-screen-after-use-photo.md` - closed
- `010-testing-note-intake-and-refactor-mapping.md` - open
- `011-settings-legal-sheet-activation.md` - closed

## Refactor Rules

- Characterize current behaviour before production edits.
- Use red-green-refactor where practical.
- Keep simulator acceptance in the loop for user-visible capture, review, and settings flows.
- Move large files toward sub-500 LOC without creating shallow pass-through modules.
- Record verification in `docs/refactor-foundation/verification/`.

## Testing Note Intake

Every user testing note should be captured before or alongside implementation work.

- Attach the note to an existing issue when it is the same symptom or same module seam.
- Create a new local markdown issue when it is a distinct symptom, missing test seam, or new refactor pressure.
- Record the product symptom, suspected module/seam, characterization plan, refactor impact, acceptance criteria, and verification route.
- Before starting a refactor slice, check open issues in that area and include relevant bugs in the characterization tests.
- Do not treat live bugs as isolated text or prompt tweaks only; identify the code path and the missing test seam.
- If a note cannot be reproduced locally, keep the issue open and mark the needed evidence, such as TestFlight screenshots, proxy logs, or the failing image.

## Refactor Area Map

- Capture tab/root: `001`, `006`, quote-capture navigation notes.
- Extraction review: `002`, `006`, `007`.
- Batch capture: `003`, multi-page capture notes.
- Book registration/cover capture/book edit: `008`, `009`.
- Design system/settings: `004`, `005`, visual consistency notes, settings behaviour notes.
- Settings legal/export presentation: `011`.
