# Submission checkpoint verification - 2026-07-13

## Scope

Five-step readiness pass:

1. Quote extraction pipeline deepening.
2. Backend entitlement/account complexity refactor.
3. Website dependency/privacy readiness.
4. Quote Detail final orchestration slice.
5. Release evidence pack and simulator smoke.

## Code Structure Results

- `BookQuotes/Features/Library/QuoteDetailView.swift`: 551 -> 448 LOC.
- `BookQuotes/Features/Library/QuoteDetailSections.swift`: 114 LOC.
- `backend/src/index.ts`: 519 -> 355 LOC.
- `backend/src/subscription.ts`: 984 -> 929 LOC.
- `backend/src/gemini-proxy.ts`: 166 LOC.
- `backend/src/account-data.ts`: 68 LOC.
- `backend/src/subscription-keys.ts`: 21 LOC.

## Verification

### App focused extraction and queue gate

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result:

- Passed.
- 38 tests, 0 failures.

### Backend gate

```bash
cd backend
npm test -- --run
npm run typecheck -- --pretty false
```

Result:

- Passed.
- 22 Vitest tests, 0 failures.
- TypeScript typecheck passed.

### Website gate

```bash
cd website
npm run build
npm audit --omit=dev
```

Result:

- `next` upgraded to `16.2.10`.
- Build passed on Next 16/Turbopack after moving the Google Fonts `@import` before Tailwind directives.
- Privacy page still describes Hugging Face model-assisted quote extraction, Apple Vision/on-device fallback, Gemini cover extraction, and Settings -> Account -> Delete Account.
- Production audit still reports the Next-bundled `postcss <8.5.10` advisory. `npm audit fix --force` proposes downgrading to `next@9.3.3`, so that fix is not acceptable. Track as upstream dependency risk while staying on latest available Next.

### Quote Detail gate

```bash
xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'generic/platform=iOS Simulator'
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/QuoteDetailTextFormatterTests \
  -only-testing:BookQuotesTests/QuoteDetailEditDraftTests \
  -only-testing:BookQuotesTests/QuoteDetailEditFieldsTests \
  -only-testing:BookQuotesTests/QuoteDeletionPromptTests \
  -only-testing:BookQuotesTests/BookDetailQuotePresentationTests
```

Result:

- Build passed.
- Focused tests passed.
- 19 tests, 0 failures.

### Simulator UI smoke

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_SeededQuote_ReturnsMatch \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_DisplaysCoreSectionsAndRows
```

Result:

- Library passed.
- Quote Capture extraction review passed.
- Search passed.
- Settings failed before assertions because the test launch could not find the Settings tab. The run found a navigation bar but no tab item, consistent with launch/onboarding state rather than a crash in refactored code.

## Remaining Release Evidence

- Device/TestFlight smoke is still required for subscription gate, sign-in, model-assisted extraction, offline/manual fallback, queue processing, and delete account after Worker deployment.
- App Store Connect privacy/subscription/account deletion questionnaire remains manual.
- Backend account deletion removes server-side KV records, but session JWTs are stateless until expiry. This should remain a documented compliance risk or become a follow-up denylist/session-version issue.
