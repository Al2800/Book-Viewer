# Testing Guide

This document covers the testing strategy, patterns, and practices used in BookQuotes. It explains how to write tests, run them, and maintain test quality.

---

## Table of Contents

1. [Overview](#overview)
2. [Test Organization](#test-organization)
3. [Running Tests](#running-tests)
4. [Unit Tests](#unit-tests)
5. [Integration Tests](#integration-tests)
6. [UI Tests](#ui-tests)
7. [Performance Tests](#performance-tests)
8. [Test Infrastructure](#test-infrastructure)
9. [Writing New Tests](#writing-new-tests)
10. [Test Data](#test-data)
11. [Coverage Reporting](#coverage-reporting)
12. [Continuous Integration](#continuous-integration)

---

## Overview

BookQuotes uses a three-tier testing pyramid:

```
        ┌─────────────────┐
        │    UI Tests     │  ← End-to-end flows
        │   (10 tests)    │
        └────────┬────────┘
                 │
       ┌─────────┴─────────┐
       │ Integration Tests │  ← Service interactions
       │    (15 tests)     │
       └─────────┬─────────┘
                 │
    ┌────────────┴────────────┐
    │       Unit Tests        │  ← Individual components
    │      (50+ tests)        │
    └─────────────────────────┘
```

### Testing Principles

1. **Test behavior, not implementation** — Tests should verify what the code does, not how.
2. **Isolation** — Each test runs independently with fresh state.
3. **Readability** — Tests serve as documentation; make them clear.
4. **Fast feedback** — Unit tests should run in milliseconds.

### Policy: "No Mocks / No Fakes"

This repo prefers *integration-first* tests: real implementations, real frameworks, and real persistence where possible.

Definitions used in this repo:

- **Mock**: a test double primarily used to assert how something was called (method/args/call count).
- **Fake**: a replacement implementation that behaves "like" the real thing but is not the real stack (for example, an in-memory network client that is not URLSession).
- **Stub**: a simple return-value replacement (often with fixed canned responses).
- **Hermetic server**: a local HTTP server spun up during tests so production code still uses URLSession, but no external network is required.
- **Recorded fixture**: a captured request/response pair stored in-repo and replayed deterministically.

Default rule:

- Prefer **real** SwiftData, Vision, URLSession, and app flows.
- Avoid mocks/fakes/stubs for core behaviors unless the dependency is fundamentally non-deterministic or external.

Decision table (what to do in practice):

| Dependency / Layer | Preferred test approach | Allowed exceptions |
|---|---|---|
| SwiftData models + queries | Real `ModelContainer` using in-memory/temporary store, real fetch descriptors | None (this is already deterministic) |
| Search database (FTS5) | Real sqlite DB in a temp location, real queries | None |
| Vision OCR / rectangle detection | Real Vision requests over a small fixture image set | If Vision output varies across iOS minors, apply tolerant comparison rules (documented) |
| Networking (Gemini proxy, ISBN lookups) | URLSession to a hermetic local server + recorded fixtures | For truly external-only behavior, allow "smoke" tests that are opt-in and never run in CI |
| CloudKit | Excluded from automated tests; use SwiftData without iCloud in tests | Manual QA checklist and/or dedicated non-CI test plan if needed |
| Camera / Photos | UI tests using simulator camera/photos flows with deterministic media inputs | If simulator APIs are unstable, use checkpoint screenshots + logs and keep tests best-effort |
| Time/randomness/concurrency | Prefer deterministic clocks and bounded timeouts; avoid `sleep` | Allow injection of `Clock`/scheduler only at seams where it meaningfully reduces flake |

What this policy is *not*:

- It does **not** require 100% code coverage at the expense of test quality.
- It does **not** forbid all indirection. It forbids test doubles that hide real behavior.

---

## Test Organization

```
BookQuotesTests/
├── Infrastructure/           # Test helpers and base classes
│   ├── SwiftDataTestCase.swift   # Base for model tests
│   ├── FTS5TestCase.swift        # Base for search tests
│   ├── TestFixtures.swift        # Shared test data
│   └── TestLogger.swift          # Structured test output
│
├── Unit/                     # Unit tests
│   ├── Models/
│   │   ├── BookModelTests.swift
│   │   └── QuoteModelTests.swift
│   └── Services/
│       ├── SearchServiceTests.swift
│       ├── SearchDatabaseTests.swift
│       └── CaptureQueueManagerTests.swift
│
├── Integration/              # Integration tests
│   ├── CaptureToSearchFlowTests.swift
│   └── OfflineQueueFlowTests.swift
│
└── Performance/              # Performance tests
    ├── SearchPerformanceTests.swift
    └── MemoryPerformanceTests.swift

BookQuotesUITests/
├── Infrastructure/           # UI test helpers
│   ├── BaseUITestCase.swift      # Base for all UI tests
│   ├── UITestLogger.swift        # Test logging
│   └── ScreenshotCapture.swift   # Failure screenshots
│
└── Flows/                    # UI flow tests
    ├── OnboardingFlowTests.swift
    ├── BookRegistrationFlowTests.swift
    ├── QuoteCaptureFlowTests.swift
    ├── SearchFlowTests.swift
    └── LibraryManagementTests.swift
```

---

## Running Tests

### From Xcode

```
⌘ + U           Run all tests
⌘ + Shift + U   Run last test again
```

Or use the Test Navigator (⌘ + 6) to run individual tests.

### From Command Line

```bash
# Run all tests
xcodebuild test \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:BookQuotesTests/SearchDatabaseTests

# Run with verbose logging
xcodebuild test ... | xcpretty
```

### E2E Scripts

```bash
# Run integration + unit tests with artifacts
./scripts/e2e_integration.sh

# Run UI test plan with artifacts and screenshots
./scripts/e2e_ui.sh

# Run both suites in order
./scripts/e2e_full.sh

# Run only integration tests
./scripts/e2e_full.sh --integration

# Run only UI tests
./scripts/e2e_full.sh --ui
```

#### Environment Variables

All scripts accept environment variables for customization:

| Variable | Default | Description |
|----------|---------|-------------|
| `SCHEME` | `BookQuotes` | Xcode scheme to test |
| `DESTINATION` | `platform=iOS Simulator,name=iPhone 15` | Simulator destination |
| `ARTIFACTS_DIR` | `artifacts/` | Output directory for artifacts |
| `ONLY_TESTING` | (empty) | Specific test target (e.g., `BookQuotesTests/SearchDatabaseTests`) |
| `RETRY_COUNT` | `0` (integration), `1` (UI) | Number of retry attempts for flaky tests |
| `TIMEOUT` | `600` | Test timeout in seconds (UI only) |
| `TEST_PLAN` | `FullRegressionPlan` | Test plan name (UI only) |
| `SIMULATOR_NAME` | `iPhone 15` | Simulator name for setup |

Example with custom settings:

```bash
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro" RETRY_COUNT=2 ARTIFACTS_DIR=./ci-artifacts ./scripts/e2e_full.sh
```

### App Store Media (Screenshots + Previews)

Use the App Store media runner to capture iPhone screenshots and preview videos via UI tests:

```bash
# Screenshots + previews (default)
./scripts/appstore_media.sh

# Screenshots only
./scripts/appstore_media.sh --screenshots

# Previews only
./scripts/appstore_media.sh --previews
```

Customize devices and output locations:

```bash
# `SCREENSHOT_DESTINATIONS` is '|' separated (xcodebuild destinations).
SCREENSHOT_DESTINATIONS="platform=iOS Simulator,OS=latest,name=iPhone 17 Pro Max|platform=iOS Simulator,OS=latest,name=iPad Pro 13-inch (M5)" \
PREVIEW_DESTINATION="platform=iOS Simulator,OS=latest,name=iPhone 17 Pro Max" \
ARTIFACTS_DIR=./artifacts/app-store \
./scripts/appstore_media.sh
```

Preview pacing can be tuned by setting `APP_STORE_PREVIEW_STEP_DELAY` (seconds) when running previews.
Retries can be controlled with `MAX_UI_TEST_RETRIES` (default: `2`).

#### Artifacts Produced

Integration tests (`artifacts/integration-tests/`):
- `integration-tests-{timestamp}.xcresult` — Xcode result bundle
- `integration-tests-{timestamp}.log` — Console output log
- `coverage-{timestamp}.txt` — Human-readable coverage summary
- `coverage-{timestamp}.json` — Machine-readable coverage data

UI tests (`artifacts/ui-tests/`):
- `ui-tests-{timestamp}.xcresult` — Xcode result bundle
- `ui-tests-{timestamp}.log` — Console output log
- `screenshots/` — Test screenshots directory
- `results-{timestamp}.json` — Extracted test results

App Store media (`artifacts/app-store/<RUN_ID>/`):
- `screenshots/<device_slug>/screenshots/01_library_grid.png` (and `02_...` through `08_...`) for upload
- `screenshots/<device_slug>/screenshots_attemptN.xcresult` and `screenshots_attemptN.log` for debugging
- `screenshots/<device_slug>/attachments_attemptN/manifest.json` mapping attachment names to files
- `screenshots/<device_slug>/reports/simctl-diagnose.txt` and `reports/simulator-logs.logarchive` on failure

### UI Tests with Logging

```bash
# Run UI tests with log output
WRITE_UI_TEST_LOGS=1 xcodebuild test \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotesUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### Upload To App Store Connect

1. Generate screenshots:
   ```bash
   ./scripts/appstore_media.sh --screenshots
   ```
2. Locate PNGs:
   - iPhone: `artifacts/app-store/<RUN_ID>/screenshots/iPhone_17_Pro_Max/screenshots/*.png`
   - iPad: `artifacts/app-store/<RUN_ID>/screenshots/iPad_Pro_13-inch_M5/screenshots/*.png`
3. Upload in App Store Connect:
   - App Store Connect -> Your app -> App Store -> iOS App -> App Previews and Screenshots
   - Select the correct device size group (6.9" iPhone, 13" iPad)
   - Upload the `01_...` through `08_...` PNGs in order
4. If you hit tooling flake:
   - Re-run with a new `RUN_ID` and increase retries: `MAX_UI_TEST_RETRIES=3 ./scripts/appstore_media.sh --screenshots`
   - Inspect failure diagnostics under `.../reports/` for the failing device destination.

### CI Notes

- Fail the build on any non-zero exit from `scripts/e2e_integration.sh` or `scripts/e2e_ui.sh`.
- Publish `artifacts/**` as CI artifacts for coverage, logs, screenshots, and xcresult bundles.
- If running UI tests in CI, set `UI_TEST_ARTIFACTS_DIR` to a writable workspace path.

### Troubleshooting

#### Simulator Boot / CoreSimulator Issues

Common symptoms:
1. `xcrun simctl list devices available` hangs forever.
2. `xcodebuild test` fails during launch with `NSMachErrorDomain Code=-308` (ipc/mig server died).
3. UI tests fail to start with `Timed out while loading Accessibility`.

Practical fixes (best-effort, in increasing order of disruption):
1. Ensure your destination exists: `xcrun simctl list devices available | rg "iPhone|iPad"`.
2. Reboot the specific simulator:
```bash
xcrun simctl shutdown <UDID>
xcrun simctl boot <UDID>
xcrun simctl bootstatus <UDID> -b
```
3. Restart Simulator + CoreSimulator services (this will terminate running sims):
```bash
killall -9 Simulator || true
killall -9 com.apple.CoreSimulator.CoreSimulatorService || true
```
4. If you intentionally want a clean device state (destructive): `xcrun simctl erase <UDID>`

#### xcodebuild Test Flakiness

If UI tests are intermittently failing on CI or locally:
1. Prefer scripts that capture xcresult + logs and apply retries: `scripts/e2e_ui.sh` and `scripts/appstore_media.sh`.
2. Make sure UI tests do not accidentally run in unit/integration CI jobs. Use `-skip-testing:BookQuotesUITests` in CI.
3. When debugging, always write an xcresult bundle:
```bash
xcodebuild test ... -resultBundlePath artifacts/xcresults/run.xcresult
```

#### Coverage Missing / xccov Parsing

Coverage can be missing or empty when:
1. Tests were run without `-enableCodeCoverage YES`.
2. You ran a scheme that does not have coverage enabled in Xcode.
3. The failing run never produced a result bundle.

Debug commands:
```bash
xcrun xccov view --report artifacts/xcresults/run.xcresult
xcrun xccov view --report --json artifacts/xcresults/run.xcresult > /tmp/coverage_report.json
```

#### Inspecting xcresult Bundles

Useful commands:
```bash
# GUI explorer
open artifacts/**/**.xcresult

# Raw JSON (can be large)
xcrun xcresulttool get --path artifacts/**/**.xcresult --format json > /tmp/xcresult.json

# Export screenshot attachments
xcrun xcresulttool export attachments --path artifacts/**/**.xcresult --output-path /tmp/xcresult_attachments
```

#### Missing Screenshots / Logs

For UI test scripts:
1. Ensure `WRITE_UI_TEST_LOGS=1` is set (writes `UITestLogger` summaries).
2. Ensure `CAPTURE_UI_TEST_CHECKPOINTS=1` is set if you want per-step checkpoint screenshots.

## Coverage Reporting

Code coverage should be generated from Xcode test runs with coverage enabled.

```bash
# Generate coverage artifacts (summary + JSON + LCOV + HTML)
./scripts/coverage.sh BookQuotes

# Override destination or output folder as needed
DESTINATION='platform=iOS Simulator,name=iPhone 15 Pro' RESULT_DIR='artifacts/coverage' ./scripts/coverage.sh
```

Artifacts produced by the script:
- `artifacts/coverage/summary.txt` (human-readable summary)
- `artifacts/coverage/coverage.json` (machine-readable detail)
- `artifacts/coverage/coverage.lcov` (LCOV)
- `artifacts/coverage/coverage.html` (HTML summary)

Thresholds are configured in `scripts/coverage_thresholds.json`. Override with:

```bash
THRESHOLDS=path/to/thresholds.json ./scripts/coverage.sh
```

## Unit Tests

Unit tests verify individual components in isolation.

### SwiftData Model Tests

Inherit from `SwiftDataTestCase` for in-memory model testing:

```swift
final class BookModelTests: SwiftDataTestCase {

    func testBookCreation() async throws {
        logger.step(1, "Creating a book")
        let book = Book(title: "Atomic Habits", author: "James Clear")

        logger.step(2, "Inserting book")
        try insertBook(book)

        logger.step(3, "Verifying book was saved")
        try assertBookCount(1)

        let fetched = try fetchAllBooks().first
        XCTAssertEqual(fetched?.title, "Atomic Habits")
    }

    func testBookQuoteRelationship() async throws {
        logger.step(1, "Creating book with quotes")
        let book = TestFixtures.atomicHabits

        let quote1 = Quote(text: "Quote 1", book: book)
        let quote2 = Quote(text: "Quote 2", book: book)

        logger.step(2, "Saving book and quotes")
        try insertBook(book)

        logger.step(3, "Verifying relationship")
        XCTAssertEqual(book.quotes.count, 2)
        XCTAssertEqual(book.quoteCount, 2)
    }

    func testCascadeDelete() async throws {
        // When a book is deleted, its quotes should be deleted too
        let book = TestFixtures.atomicHabits
        let quote = Quote(text: "Test", book: book)
        try insertBook(book)

        try assertQuoteCount(1)

        modelContext.delete(book)
        try modelContext.save()

        try assertBookCount(0)
        try assertQuoteCount(0)  // Cascade delete worked
    }
}
```

### Service Tests

Test services with real implementations and deterministic fixtures:

```swift
final class SearchServiceTests: XCTestCase {

    var searchService: SearchService!
    var tempDBPath: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Use temp directory for test database
        tempDBPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")

        let database = try SearchDatabase(path: tempDBPath)
        searchService = SearchService(database: database)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDBPath)
        try await super.tearDown()
    }

    func testDebouncing() async throws {
        // Rapid searches should only execute last one
        searchService.search("a")
        searchService.search("at")
        searchService.search("ato")
        searchService.search("atom")

        // Wait for debounce
        try await Task.sleep(for: .milliseconds(200))

        // Only final search should have run
        XCTAssertFalse(searchService.isSearching)
    }

    func testCancellation() async throws {
        searchService.search("test")
        searchService.cancelSearch()

        XCTAssertFalse(searchService.isSearching)
        XCTAssertEqual(searchService.results, .empty)
    }
}
```

### FTS5 Tests

Inherit from `FTS5TestCase` for search database testing:

```swift
final class SearchDatabaseTests: FTS5TestCase {

    func testBasicSearch() async throws {
        // Index test data
        try await indexTestQuotes()

        // Search
        let results = try await searchDB.search(query: "atomic", scope: .all)

        XCTAssertGreaterThan(results.quotes.count, 0)
        XCTAssertTrue(results.quotes.first?.snippet.contains("<mark>"))
    }

    func testPrefixMatching() async throws {
        try await indexTestQuotes()

        // "ato" should match "atomic"
        let results = try await searchDB.search(query: "ato", scope: .all)

        XCTAssertGreaterThan(results.quotes.count, 0)
    }

    func testPorterStemming() async throws {
        // Index quote with "running"
        let book = Book(title: "Test", author: "Test")
        let quote = Quote(text: "I was running fast", book: book)
        try await searchDB.indexQuote(quote, book: book)

        // "run" should match "running"
        let results = try await searchDB.search(query: "run", scope: .quotes)

        XCTAssertEqual(results.quotes.count, 1)
    }
}
```

---

## Integration Tests

Integration tests verify that multiple components work together correctly.

### Hermetic Network + Recorded Fixtures

Integration tests must be able to run offline and in CI without secrets.

Rules:

- Do not call external services (Gemini proxy, ISBN providers) from default test runs.
- Prefer URLSession hitting a *local* hermetic HTTP server started by the test process.
- Use recorded fixtures (checked into the repo) for request/response playback.

Fixture format (recommended):

- Location: `BookQuotesTests/Fixtures/Network/<service>/<case>.json`
- One file per interaction so diffs stay small.
- Store both request matcher and response payload.

Example (shape only):

```json
{
  "request": { "method": "POST", "path": "/v1/extract", "headers": { "content-type": "application/json" } },
  "response": { "status": 200, "headers": { "content-type": "application/json" }, "body": { "quotes": [] } }
}
```

Redaction rules:

- Never store API keys, auth headers, or user-identifying content.
- If a payload includes text extracted from personal photos, replace it with synthetic text in the fixture.

Strictness:

- Unknown requests should fail fast with a clear diff (method/path/body).
- Fixture updates must be explicit (no silent rewrites during a test run).

### Vision and Camera Strategy

Vision and camera behavior is best validated with "golden" integration tests and a small fixture set:

- Store fixture images in the test bundle (asset catalog or bundled resources).
- Run real Vision requests (`VNRecognizeTextRequest`, rectangle detection) over fixtures.
- Compare output using tolerant rules (case folding, whitespace normalization) if iOS minors vary.

For camera/PhotosUI:

- Prefer UI tests using deterministic media inputs (seeded library assets, known photos).
- Keep these tests best-effort, but require high-signal artifacts on failure (logs + checkpoint screenshots).

### CloudKit and Concurrency Rules

CloudKit is excluded from automated tests by default because it is non-deterministic and environment-dependent.

Rules:

- Tests should use SwiftData without iCloud, and avoid code paths that require CloudKit availability.
- For async behaviors, prefer predicate-based waits over fixed sleeps.
- Use bounded timeouts and log each wait step so failures are diagnosable from artifacts alone.

### Capture-to-Search Flow

```swift
final class CaptureToSearchFlowTests: SwiftDataTestCase {

    var searchService: SearchService!

    override func setUp() async throws {
        try await super.setUp()
        searchService = try SearchService()
    }

    func testNewQuoteAppearsInSearch() async throws {
        logger.step(1, "Creating a book and quote")
        let book = Book(title: "Meditations", author: "Marcus Aurelius")
        let quote = Quote(
            text: "You have power over your mind",
            book: book
        )
        try insertBook(book)

        logger.step(2, "Indexing for search")
        await searchService.indexQuote(quote, book: book)

        logger.step(3, "Searching for the quote")
        await searchService.searchImmediate("power mind", scope: .all)

        logger.step(4, "Verifying quote appears in results")
        XCTAssertEqual(searchService.results.quotes.count, 1)
        XCTAssertEqual(searchService.results.quotes.first?.quoteId, quote.id)
    }

    func testDeletedQuoteRemovedFromSearch() async throws {
        // Setup
        let book = TestFixtures.atomicHabits
        let quote = Quote(text: "Test quote for deletion", book: book)
        try insertBook(book)
        await searchService.indexQuote(quote, book: book)

        // Verify it's searchable
        await searchService.searchImmediate("deletion", scope: .quotes)
        XCTAssertEqual(searchService.results.quotes.count, 1)

        // Delete quote
        modelContext.delete(quote)
        try modelContext.save()
        await searchService.removeQuoteFromIndex(id: quote.id)

        // Verify it's gone from search
        await searchService.searchImmediate("deletion", scope: .quotes)
        XCTAssertEqual(searchService.results.quotes.count, 0)
    }
}
```

### Offline Queue Flow

```swift
final class OfflineQueueFlowTests: SwiftDataTestCase {

    func testQueueProcessingWhenOnline() async throws {
        let authService = AuthService()
        let geminiService = GeminiService(authService: authService)
        let queueManager = CaptureQueueManager(
            modelContainer: modelContainer,
            geminiService: geminiService,
            networkMonitor: NetworkMonitor()
        )

        logger.step(1, "Adding item while offline")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let testImage = TestFixtures.TestImages.bookPage
        let item = try await queueManager.addToQueue(image: testImage, book: book)

        XCTAssertEqual(item.status, .pending)

        logger.step(2, "Simulating network connection")
        // Use network state changes via NetworkMonitor in integration tests

        logger.step(3, "Starting queue processing")
        await queueManager.start()

        // Wait for processing
        try await Task.sleep(for: .seconds(2))

        logger.step(4, "Verifying item was processed")
        let stats = await queueManager.stats
        XCTAssertEqual(stats.completedCount, 1)
    }
}
```

---

## UI Tests

UI tests verify complete user flows through the actual app interface.

### Base Test Case

All UI tests inherit from `BaseUITestCase`:

```swift
final class BookRegistrationFlowTests: BaseUITestCase {

    func testAddBookManually() {
        logger.step(1, "Navigating to Capture tab")
        navigateToTab("Capture")

        logger.step(2, "Tapping Add New Book")
        app.buttons["Add New Book"].tap()

        logger.step(3, "Entering book details")
        let titleField = app.textFields["Book Title"]
        assertExists(titleField)
        titleField.tap()
        titleField.typeText("Test Book")

        let authorField = app.textFields["Author"]
        authorField.tap()
        authorField.typeText("Test Author")

        logger.step(4, "Saving book")
        app.buttons["Save"].tap()

        logger.step(5, "Verifying book in library")
        navigateToTab("Library")
        assertTextExists("Test Book")
    }
}
```

### Accessibility Identifiers

UI tests use accessibility identifiers for reliable element selection:

```swift
// In view code
Button("Add Book") { ... }
    .accessibilityIdentifier(AccessibilityIdentifiers.Library.addBookButton)

// In test code
let addButton = app.buttons[AccessibilityIdentifiers.Library.addBookButton]
addButton.tap()
```

Identifiers are defined centrally:

```swift
// AccessibilityIdentifiers.swift
enum AccessibilityIdentifiers {
    enum Library {
        static let addBookButton = "library_add_book_button"
        static let viewModeToggle = "library_view_mode_toggle"
        static let emptyState = "library_empty_state"
    }

    enum Search {
        static let searchField = "search_field"
        static let noResultsView = "search_no_results"
        static let didYouMeanBanner = "search_did_you_mean_banner"
    }
    // ...
}
```

### Test Data Seeding

UI tests use seeded data for consistent state:

```swift
// In test setup
override var additionalLaunchArguments: [String] {
    ["--uitesting", "--seed-test-data"]
}

// In app
if ProcessInfo.processInfo.arguments.contains("--seed-test-data") {
    UITestDataSeeder(modelContext: context).seedTestData()
}
```

---

## Performance Tests

Performance tests measure critical operations.

### Search Performance

```swift
final class SearchPerformanceTests: XCTestCase {

    func testSearchPerformanceWith10000Quotes() throws {
        let database = try setupLargeDatabase(quoteCount: 10_000)
        let service = SearchService(database: database)

        measure {
            let expectation = expectation(description: "Search complete")

            Task {
                await service.searchImmediate("atomic habits", scope: .all)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }

        // Baseline: < 50ms average
    }

    func testIndexingPerformance() throws {
        let database = try SearchDatabase(path: tempPath)

        let books = (0..<100).map { i in
            Book(title: "Book \(i)", author: "Author \(i)")
        }

        measure {
            for book in books {
                try? database.indexBook(book)
            }
        }

        // Baseline: < 100ms for 100 books
    }
}
```

### Memory Tests

```swift
final class MemoryPerformanceTests: XCTestCase {

    func testMemoryUsageDuringBatchProcessing() throws {
        let session = createLargeCaptureSession(pageCount: 20)

        measureMetrics([XCTMemoryMetric()], automaticallyStartMeasuring: false) {
            startMeasuring()

            let expectation = expectation(description: "Processing complete")
            Task {
                let service = BatchProcessingService()
                _ = try await service.processSession(session, markings: [])
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 60)
            stopMeasuring()
        }
    }
}
```

---

## Test Infrastructure

### SwiftDataTestCase

Base class providing in-memory SwiftData:

```swift
@MainActor
class SwiftDataTestCase: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var logger: TestLogger!

    override func setUp() async throws {
        // Create in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = modelContainer.mainContext

        logger = TestLogger(testName: name)
    }

    // Helper methods
    func insertBook(_ book: Book) throws { ... }
    func assertBookCount(_ expected: Int) throws { ... }
    func fetchAllQuotes() throws -> [Quote] { ... }
}
```

### TestLogger

Structured logging for test debugging:

```swift
class TestLogger {
    func step(_ number: Int, _ description: String) {
        print("[\(testName)] Step \(number): \(description)")
    }

    func info(_ message: String, context: [String: String] = [:]) {
        print("[\(testName)] ℹ️ \(message) \(formatContext(context))")
    }

    func success(_ message: String) {
        print("[\(testName)] ✅ \(message)")
    }

    func error(_ message: String, error: Error? = nil) {
        print("[\(testName)] ❌ \(message): \(error?.localizedDescription ?? "")")
    }

    func summary() -> String {
        // Returns formatted summary of all logged events
    }
}
```

### TestFixtures

Shared test data:

```swift
enum TestFixtures {
    static var atomicHabits: Book {
        let book = Book(title: "Atomic Habits", author: "James Clear")
        book.subtitle = "An Easy & Proven Way to Build Good Habits"
        return book
    }

    static var sampleQuote: Quote {
        Quote(
            text: "You do not rise to the level of your goals...",
            book: atomicHabits
        )
    }

    static var testPageImage: UIImage {
        UIImage(named: "test_page", in: .test, with: nil)!
    }
}
```

---

## Writing New Tests

### Test Naming Convention

```swift
func test<What>_<Condition>_<Expected>() {
    // Example: testSearch_WhenQueryEmpty_ReturnsNoResults
}

// Or simpler:
func test<Behavior>() {
    // Example: testEmptyQueryReturnsNoResults
}
```

### Test Structure (Arrange-Act-Assert)

```swift
func testQuoteSavingUpdatesSearchIndex() async throws {
    // Arrange
    let book = TestFixtures.atomicHabits
    let quote = Quote(text: "Test quote", book: book)
    try insertBook(book)

    // Act
    await searchService.indexQuote(quote, book: book)
    await searchService.searchImmediate("Test", scope: .quotes)

    // Assert
    XCTAssertEqual(searchService.results.quotes.count, 1)
}
```

### Testing Async Code

```swift
func testAsyncOperation() async throws {
    // Use async/await directly
    let result = try await someAsyncOperation()
    XCTAssertNotNil(result)
}

func testWithExpectation() {
    let expectation = expectation(description: "Callback called")

    someOperationWithCallback { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5.0)
}
```

---

## Test Data

### UI Test Seeding

The `UITestDataSeeder` creates consistent test data:

```swift
class UITestDataSeeder {
    func seedTestDataIfNeeded() async throws {
        // Check if already seeded
        guard needsSeeding() else { return }

        // Create books
        let book1 = Book(title: "Atomic Habits", author: "James Clear")
        let book2 = Book(title: "Meditations", author: "Marcus Aurelius")

        // Create quotes
        let quote1 = Quote(text: "You do not rise...", book: book1)
        let quote2 = Quote(text: "You have power...", book: book2)

        // Insert all
        modelContext.insert(book1)
        modelContext.insert(book2)
        try modelContext.save()

        // Rebuild search index
        await searchService.rebuildIndex(books: [book1, book2])
    }
}
```

### Test Configuration

```swift
enum UITestConfiguration {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    static var shouldSeedData: Bool {
        ProcessInfo.processInfo.arguments.contains("--seed-test-data")
    }
}
```

---

## Continuous Integration

CI uploads high-signal debugging artifacts (xcresult bundles, coverage reports, and logs) on every run.
Artifact retention is currently set to **14 days** (see `.github/workflows/ios-unit-integration-tests.yml`).

UI tests run in a separate best-effort workflow (manual trigger + nightly schedule): `.github/workflows/ios-ui-tests.yml`.

### GitHub Actions Workflow

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project BookQuotes.xcodeproj \
            -scheme BookQuotes \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:BookQuotesTests \
            | xcpretty

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project BookQuotes.xcodeproj \
            -scheme BookQuotesUITests \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            | xcpretty
```

### Test Coverage

Generate coverage reports:

```bash
xcodebuild test \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# View in Xcode: Product → Build for → Testing
# Then: Product → Test
# Coverage visible in Report Navigator
```

---

## Troubleshooting

### Common Failures

#### "Simulator not found"
```bash
# List available simulators
xcrun simctl list devices available

# Use a different destination
DESTINATION="platform=iOS Simulator,name=iPhone 16" ./scripts/e2e_full.sh
```

#### "Tests timed out"
```bash
# Increase timeout (in seconds)
TIMEOUT=900 ./scripts/e2e_ui.sh

# Run with retries
RETRY_COUNT=2 ./scripts/e2e_integration.sh
```

#### "Camera permission denied" (UI tests)
UI tests run with the `--uitesting` launch argument which enables test image injection buttons. If camera-related tests fail:
1. Check that `AccessibilityIdentifiers.Capture.testImageButton` is visible
2. Verify the test uses the test image button, not the actual camera
3. Reset simulator state: `xcrun simctl erase <UDID>`

#### "SwiftData migration failed"
Clear the simulator data:
```bash
xcrun simctl shutdown all
xcrun simctl erase all
```

#### "FTS5 database locked"
Multiple processes may be accessing the search database:
```bash
# Kill Xcode and simulators
pkill -9 Simulator
pkill -9 Xcode

# Clean test databases
rm -rf /tmp/BookQuotesTests*
```

#### Flaky UI tests
UI tests can be flaky due to timing issues. Solutions:
1. Use `RETRY_COUNT=1` or higher
2. Add explicit waits in tests using `waitForExistence(timeout:)`
3. Check for race conditions in test setup

### Debugging Test Failures

#### View xcresult bundle
```bash
# Open in Xcode
open artifacts/ui-tests/ui-tests-*.xcresult

# Extract test summary as JSON
xcrun xcresulttool get --path <result-bundle> --format json
```

#### Enable verbose logging
```bash
# Integration tests
xcodebuild test ... 2>&1 | tee verbose.log

# UI tests with checkpoint screenshots
CAPTURE_UI_TEST_CHECKPOINTS=1 WRITE_UI_TEST_LOGS=1 ./scripts/e2e_ui.sh
```

#### Check simulator logs
```bash
# Stream logs from booted simulator
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.yourapp.BookQuotes"'
```

### CI-Specific Notes

#### GitHub Actions
- Use `macos-14` or later runners
- Set Xcode version explicitly: `sudo xcode-select -s /Applications/Xcode_16.0.app`
- Artifacts should be uploaded using `actions/upload-artifact@v4`

#### Xcode Cloud
- Use test plans for organized test execution
- Enable "Collect code coverage" in the test plan
- Screenshots are automatically collected on failure

#### Local CI Simulation
```bash
# Simulate CI environment
env -i HOME="$HOME" PATH="$PATH" ./scripts/e2e_full.sh
```

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — Code organization
- [SERVICES.md](SERVICES.md) — Services being tested
- [TEST_COVERAGE_MATRIX.md](TEST_COVERAGE_MATRIX.md) — Coverage requirements and current status
