# Test Coverage Matrix

Purpose: single source of truth for current coverage, gaps, and target coverage for BookQuotes.

## Current Test Suites

Unit (XCTest)
- Models: `BookQuotesTests/Unit/Models/BookModelTests.swift`, `BookQuotesTests/Unit/Models/QuoteModelTests.swift`
- Services: `BookQuotesTests/Unit/Services/GeminiServiceTests.swift`, `BookQuotesTests/Unit/Services/SearchDatabaseTests.swift`,
  `BookQuotesTests/Unit/Services/SearchServiceTests.swift`, `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`,
  `BookQuotesTests/Unit/Services/KeychainServiceTests.swift`
- Utilities: `BookQuotesTests/Unit/Utilities/LevenshteinDistanceTests.swift`

Integration (XCTest)
- `BookQuotesTests/Integration/CaptureToSearchFlowTests.swift`
- `BookQuotesTests/Integration/OfflineQueueFlowTests.swift`

Performance
- `BookQuotesTests/Performance/SearchPerformanceTests.swift`
- `BookQuotesTests/Performance/MemoryPerformanceTests.swift`

UI/E2E (XCUITest)
- `BookQuotesUITests/Flows/OnboardingFlowTests.swift`
- `BookQuotesUITests/Flows/BookRegistrationFlowTests.swift`
- `BookQuotesUITests/Flows/LibraryManagementTests.swift`
- `BookQuotesUITests/Flows/QuoteCaptureFlowTests.swift`
- `BookQuotesUITests/Flows/SearchFlowTests.swift`

Notes
- UI tests use test-image buttons for capture flows rather than mock camera flags.
- There is structured UI logging via `BookQuotesUITests/Infrastructure/UITestLogger.swift`, but no dedicated CLI E2E scripts.

## Coverage Matrix

Legend: Full = comprehensive; Partial = some tests; None = no tests observed.

| Area | Scope | Current Coverage | Gaps (examples) | Target Coverage |
| --- | --- | --- | --- | --- |
| Models | `Book`, `Quote` | Partial | Coverage exists for basic init/relationships; no tests for `Collection`, `Tag`, `User`, `MarkingDefinition`, `CaptureSession`, `PageCapture`, `SearchFilters`, `SearchScope`, `QuoteCorrection`, `ValidationError` | 90%+ branch for all model logic |
| Models | `Collection`, `Tag`, `MarkingDefinition` | None | Relationship behaviors, uniqueness rules, system defaults, persistence | 90%+ branch |
| Models | `CaptureSession`, `PageCapture`, `CaptureQueueItem` | None | Data integrity, lifecycle flags, persistence | 90%+ branch |
| Models | `SearchResults`, `SearchFilters`, `SearchScope` | None | Filtering logic, ordering, serialization | 90%+ branch |
| Services | `GeminiService`, `QuoteExtractionResult`, `QuoteExtractionPromptBuilder` | Partial | Parsing tested, but prompt building and error pathways not fully covered | 85%+ branch |
| Services | `SearchDatabase`, `SearchService`, `SearchSuggestionsService` | Partial | SearchDatabase/SearchService tests exist; suggestions untested; pagination and ranking edge cases | 85%+ branch |
| Services | `CaptureQueueManager`, `BatchProcessingService` | Partial | Queue manager tests exist; batch processing untested | 85%+ branch |
| Services | `ImageQualityAnalyzer`, `ImagePreprocessor` | None | Blur/brightness metrics and preprocess pipeline | 85%+ branch |
| Services | `ISBNScanner`, `ISBNLookupService`, `ISBNValidator`, `OpenLibraryTypes`, `GoogleBooksTypes` | None | Barcode parsing, lookup error handling, ISBN validation edge cases | 85%+ branch |
| Services | `CameraService`, `CameraPermissionService` | None | Permission state transitions, capture state machine | 85%+ branch |
| Services | `ExportService`, `ExportOptions`, Exporters (Markdown/JSON/PlainText/Notion/Obsidian) | None | Format correctness, field coverage, metadata, errors | 85%+ branch |
| Services | `AuthService`, `KeychainService`, `SubscriptionService`, `NetworkMonitor` | Partial | Keychain tests exist; auth/subscription/network untested | 85%+ branch |
| Services | `DuplicateDetector`, `QuoteSaveService` | None | Duplicate detection heuristics, save error handling | 85%+ branch |
| Features | Onboarding, Capture, QuoteCapture, Library, BookRegistration, Export, Settings, Tags, Collections, Subscription | None (unit) / Partial (UI) | UI tests exercise some flows but use mock camera; no feature-level unit tests or view model tests | 70%+ UI coverage with real inputs; unit coverage for any view models |
| Components | Reusable UI components in `BookQuotes/Components` | None | Rendering and behavior tests absent | 60%+ snapshot/logic coverage where applicable |
| Utilities | `LevenshteinDistance` | Partial | Tests exist; add more boundaries and performance checks | 90%+ branch |
| Utilities | `AccessibilityIdentifiers`, `UITestConfiguration`, `MockCameraImages` | None | Test configuration behaviors and identifier stability | 80%+ branch |

## Critical Risk Areas (Untested)

- Image pipeline: `ImageQualityAnalyzer`, `ImagePreprocessor`, capture flows (affects capture UX and extraction quality).
- Export pipeline: `ExportService` and exporter formatters (risk of broken exports and data loss).
- ISBN scanning/lookup: `ISBNScanner`, `ISBNLookupService` (core book registration flow).
- Duplicate detection: `DuplicateDetector` (data quality).
- Subscription/Auth/Network behaviors (app access and entitlement states).

## Scope Exclusions (Requires Rationale)

- Visual-only components with no logic may be tested via UI snapshots or excluded with documented rationale.
- Third-party SDK behaviors (e.g., OS-level camera permission prompts) may be validated via integration tests rather than unit tests.

## Target Coverage Goals

- Models: 90%+ branch coverage across all model logic.
- Services: 85%+ branch coverage across all core services.
- Utilities: 90%+ branch coverage for all helpers.
- UI/E2E: end-to-end coverage for core user journeys without mock flags; artifacts and logs required.
