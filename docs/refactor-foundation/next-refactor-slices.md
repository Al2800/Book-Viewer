# Next Refactor Slices

Selected while build 22 is under TestFlight review.

## Refactor Rules

- Characterize current behaviour before production edits.
- Prefer red-green-refactor where practical.
- Keep simulator acceptance in the loop for user-visible capture and edit flows.
- Move large files toward sub-500 LOC without creating shallow pass-through modules.
- Use a module only when it improves locality or leverage.
- Log neutral behaviour notes in `docs/refactor-foundation/verification/`.

## Slice 1: Capture Tab Root Modular Follow-Up

Issue: `book-quote-capture-tab-root-modular-followup`

Why first:

- `CaptureTabRootView.swift` is still 812 LOC.
- It owns routing, permission gating, selected-book state, coaching presentation, mode selection UI, book-selection UI, and capture-flow wrappers.
- The existing `CaptureFlowState` seam gives us a stable characterization base.

Target:

- Deepen the capture-tab module by moving start-screen and book-selection presentation into focused modules while keeping flow orchestration in `CaptureTabRootView`.
- Preserve selected-book clearing, quote/batch identity refresh, cover completion, coaching, and permission behaviour.

Acceptance criteria:

1. Characterize visible mode-selection, book-selection, quote, batch, and cover transitions before edits.
2. Add or strengthen at least one simulator acceptance path touched by the extraction.
3. Extract modules that own real UI behaviour and accessibility contracts, not single-line pass-through wrappers.
4. Reduce `CaptureTabRootView.swift` materially toward sub-500 LOC.
5. Record simulator and focused-test verification.

## Slice 2: Cover Crop Review Acceptance

Issue: `book-quote-cover-crop-review-acceptance`

Why second:

- Cover capture is working in build 22 and should be protected before deeper image/camera refactors.
- Pure crop geometry tests exist, but the crop-review sheet path still needs a simulator-level contract.

Target:

- Characterize crop-review presentation and completion wiring through UI acceptance.
- Decide whether remaining crop-detection helper behaviour is live or dead, then document the result.

Acceptance criteria:

1. Characterize crop-review presentation before production edits.
2. Add simulator acceptance for review visibility, retake/use-cover controls, and completion navigation.
3. Keep geometry math assertions in `CoverCropGeometryTests`.
4. Avoid broad visual snapshot assertions.
5. Record focused verification and any dead-code decision.

## Slice 3: Book Edit Sections Coverage

Issue: `book-quote-book-edit-sections-coverage`

Why third:

- `BookEditView.swift` is now under 500 LOC, but its section composition has weak direct coverage.
- Future product work will likely touch cover, metadata, reading status, and save validation.

Target:

- Strengthen behavioural coverage for section wiring without snapshot brittleness.
- Keep the view split stable and prevent regressions in create/edit/create-from-metadata flows.

Acceptance criteria:

1. Characterize section behaviours worth testing before adding tests.
2. Verify cover, details, metadata, reading status, notes, and save enablement through stable accessibility identifiers or a small testable seam.
3. Keep `BookEditView.swift` and `BookEditSections.swift` below 500 LOC.
4. Refresh focused coverage/CRAP proxy after tests.
5. Record simulator and coverage results.

## Deferred Candidates

These are important, but should follow once the three slices above have stabilized the capture/edit foundation:

- `ExtractionReviewView.swift` orchestration: 784 LOC and likely needs characterization around pending pages, review progression, save/retry, and error states.
- `BatchCaptureView.swift` capture lifecycle: 754 LOC and performance-sensitive; refactor only with simulator/device smoke coverage.
- `DesignSystem.swift` split: 1534 LOC, but high churn risk because it touches the whole UI. Tackle after behaviour-critical capture/edit seams are safer.
- `SettingsTab.swift` split: 1287 LOC, lower priority because it is less central to the current capture/book workflow.
