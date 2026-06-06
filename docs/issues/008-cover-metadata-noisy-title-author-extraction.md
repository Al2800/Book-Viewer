# 008 - Cover Metadata Pulls Praise Copy Into Title

Status: closed
Area: Book registration
Priority: high

## Problem

Build 22 cover/title capture can include review quotes, bestseller badges, or other front-cover copy in the extracted title instead of isolating the book title and author.

## Characterization

- Gemini cover extraction prompt currently asks for the exact title but does not explicitly reject praise, blurbs, badges, awards, or endorsement text.
- OCR fallback only runs when Gemini leaves title or author blank.
- OCR title heuristics currently build titles from top cover lines and can include praise/bestseller text before the actual title.

## Acceptance Criteria

- Cover prompt tells the model to ignore praise quotes, reviews, bestseller badges, awards, endorsements, and marketing blurbs.
- OCR fallback filters common praise and bestseller lines before title guessing.
- Tests characterize noisy front-cover text and preserve the expected title/author.
- Existing clean-cover extraction behaviour is unchanged.

## Verification

- Run targeted cover prompt and OCR heuristic tests.
- Run existing cover extraction orchestrator tests.
- Re-test with at least one real noisy front cover before release.

## Progress

2026-06-06:

- Added cover prompt characterization for rejecting praise, bestseller, and marketing copy as metadata.
- Added OCR heuristic characterization for a noisy front cover with praise and bestseller lines above the real title.
- Updated Gemini cover prompt and OCR fallback filtering.
- Added normalizer characterization for Gemini returning noisy multiline title text.
- Added normalizer characterization for Gemini returning only marketing copy while OCR has the real title.
- Updated `CoverMetadataNormalizer` to strip noisy Gemini title lines and fall back to OCR when Gemini title output is only marketing copy.
- Reused `CoverOCRHeuristics` marketing-line rules for Gemini title cleanup so OCR and Gemini fallback share one local rule set.
- Verified cover prompt, normalizer, OCR heuristic, and extraction orchestrator tests.
- Verified mocked cover capture simulator handoff into book edit.

## Verification Results

- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverMetadataNormalizerTests`
  - Red before implementation: noisy Gemini title tests failed.
  - Green after implementation: 7 tests passed.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests -only-testing:BookQuotesTests/CoverMetadataNormalizerTests -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests -only-testing:BookQuotesTests/CoverOCRHeuristicsTests`
  - Passed: 22 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit`
  - Passed: 1 UI test.

## Residual Risk

- No real failing noisy cover image is checked into the repo. Before release, repeat this path with at least one real noisy cover in the simulator or TestFlight to validate model output against the deterministic normalizer behavior.
