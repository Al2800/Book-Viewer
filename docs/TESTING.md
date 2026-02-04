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
SCREENSHOT_DESTINATIONS="platform=iOS Simulator,name=iPhone 15 Pro Max|platform=iOS Simulator,name=iPhone 15 Pro" \
PREVIEW_DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro Max" \
ARTIFACTS_DIR=./artifacts/app-store \
./scripts/appstore_media.sh
```

Preview pacing can be tuned by setting `APP_STORE_PREVIEW_STEP_DELAY` (seconds) when running previews.

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

### UI Tests with Logging

```bash
# Run UI tests with log output
WRITE_UI_TEST_LOGS=1 xcodebuild test \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotesUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### App Store Media (Screenshots + Previews)

The app includes an automated UI test flow for App Store screenshots and app preview videos.
It uses deterministic UI test data plus `simctl recordVideo` for preview capture.

```bash
# Run automated App Store media capture
./scripts/appstore_media.sh

# Override simulators and preview duration
SIMULATORS="iPhone 15 Pro Max,iPhone 15 Pro" PREVIEW_DURATION=15 ./scripts/appstore_media.sh
```

Artifacts are stored in `artifacts/app-store/<simulator>/`:
- `screenshots/` (PNG files)
- `app_preview_<seconds>s.mp4`

To capture checkpoint screenshots and write artifacts to a deterministic directory:

```bash
UI_TEST_ARTIFACTS_DIR=artifacts/ui-tests \
CAPTURE_UI_TEST_CHECKPOINTS=1 \
WRITE_UI_TEST_LOGS=1 \
xcodebuild test \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotesUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Artifacts produced:
- `artifacts/ui-tests/logs/<TestName>.log` (human-readable summary)
- `artifacts/ui-tests/logs/<TestName>.json` (machine-readable entries)
- `artifacts/ui-tests/screenshots/<TestName>_step_N.png` (checkpoint screenshots)
- `artifacts/ui-tests/screenshots/<TestName>_FAILURE.png` (failure screenshot)

### CI Notes

- Fail the build on any non-zero exit from `scripts/e2e_integration.sh` or `scripts/e2e_ui.sh`.
- Publish `artifacts/**` as CI artifacts for coverage, logs, screenshots, and xcresult bundles.
- If running UI tests in CI, set `UI_TEST_ARTIFACTS_DIR` to a writable workspace path.

### Troubleshooting

- UI tests fail to launch simulator: verify `DESTINATION` matches an installed device.
- Coverage report missing: ensure tests were run with `-enableCodeCoverage YES` or via `scripts/coverage.sh`.
- Missing screenshots/logs: confirm `WRITE_UI_TEST_LOGS=1` and `CAPTURE_UI_TEST_CHECKPOINTS=1` are set.

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
