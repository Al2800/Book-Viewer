# 010 - Testing Note Intake and Refactor Mapping

Status: open
Area: Refactor foundation
Priority: high

## Problem

User testing notes can expose product bugs, model/proxy behaviour, simulator gaps, or architecture friction. If they remain only in chat, the refactor programme can miss the actual behaviour that needs preserving or improving.

## Characterization

- Recent TestFlight notes for build 22 were captured as issues 007, 008, and 009.
- Those notes also pointed at existing refactor seams:
  - Quote extraction prompt/proxy behaviour: `GeminiService`, `QuoteExtractionPromptBuilder`, `ExtractionReviewView`, issue 006.
  - Cover metadata noise: `CoverExtractionOrchestrator`, `CoverMetadataNormalizer`, `CoverOCRHeuristics`.
  - Cover capture white screen: `CoverCaptureView`, crop review presentation state, simulator cover flow tests.
- The current issue README has refactor rules but no explicit intake rule for live testing notes.

## Acceptance Criteria

- Every future user testing note is either attached to an existing issue or captured as a new local markdown issue.
- Each captured note includes:
  - product symptom
  - suspected module/seam
  - characterization test or simulator reproduction plan
  - refactor impact
  - acceptance criteria
  - verification route
- Refactor slices must check open bug notes in their area before extracting modules.
- Bugs are not treated as prompt/text tweaks only; the suspected code path and missing test seam are identified.
- If the issue cannot be reproduced locally, it is marked as needing external evidence such as TestFlight screenshots, proxy logs, or the failing image.

## Refactor Mapping

- Capture tab/root: issues 001 and 006, plus any quote-capture navigation note.
- Extraction review: issues 002, 006, and 007.
- Batch capture: issue 003 and any multi-page capture note.
- Book registration/cover capture/book edit: issues 008 and 009.
- Design system/settings: issues 004 and 005, plus any visual consistency or settings behaviour note.

## Verification

- The issue README contains the intake rule.
- New issue notes link back to obvious refactor areas instead of standing alone.
