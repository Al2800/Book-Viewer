# Services Guide

This document provides a comprehensive overview of all services in BookQuotes—what they do, how they work together, and when to use each one.

---

## Table of Contents

1. [Service Architecture Overview](#service-architecture-overview)
2. [AI Services](#ai-services)
   - [GeminiService](#geminiservice)
   - [QuoteExtractionPromptBuilder](#quoteextractionpromptbuilder)
3. [Capture Services](#capture-services)
   - [CameraService](#cameraservice)
   - [ImageQualityAnalyzer](#imagequalityanalyzer)
   - [BatchProcessingService](#batchprocessingservice)
   - [CaptureQueueManager](#capturequeuemanager)
4. [Search Services](#search-services)
   - [SearchService](#searchservice)
   - [SearchDatabase](#searchdatabase)
   - [SearchSuggestionsService](#searchsuggestionsservice)
5. [Data Services](#data-services)
   - [QuoteSaveService](#quotesaveservice)
   - [DuplicateDetector](#duplicatedetector)
   - [ExportService](#exportservice)
6. [Book Registration Services](#book-registration-services)
   - [ISBNScanner](#isbnscanner)
   - [ISBNLookupService](#isbnlookupservice)
7. [Infrastructure Services](#infrastructure-services)
   - [AuthService](#authservice)
   - [KeychainService](#keychainservice)
   - [NetworkMonitor](#networkmonitor)
   - [SubscriptionService](#subscriptionservice)

---

## Service Architecture Overview

Services in BookQuotes are organized by responsibility:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        User Interface                                │
└─────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
        ┌───────────────────┐   ┌───────────────────────┐
        │  Feature Services │   │  Infrastructure       │
        │  ─────────────────│   │  ────────────────────│
        │  • GeminiService  │   │  • AuthService       │
        │  • SearchService  │   │  • NetworkMonitor    │
        │  • CameraService  │   │  • KeychainService   │
        │  • ExportService  │   │  • SubscriptionService│
        └─────────┬─────────┘   └───────────┬───────────┘
                  │                         │
                  └───────────┬─────────────┘
                              ▼
              ┌───────────────────────────────┐
              │       Data Layer              │
              │  ──────────────────────────── │
              │  • SwiftData ModelContext     │
              │  • SearchDatabase (SQLite)    │
              │  • FileManager (images)       │
              └───────────────────────────────┘
```

### Service Initialization

Services are created at app launch in `BookQuotesApp.swift`:

```swift
init() {
    // Create services with their dependencies
    let auth = AuthService()
    let gemini = GeminiService(authService: auth)

    _authService = State(initialValue: auth)
    _geminiService = State(initialValue: gemini)
    _networkMonitor = State(initialValue: NetworkMonitor.shared)

    // Initialize singleton queue manager
    CaptureQueueManager.initialize(
        modelContainer: container,
        geminiService: gemini,
        networkMonitor: NetworkMonitor.shared
    )
}
```

---

## AI Services

### GeminiService

**Purpose**: Communicates with the Gemini AI API through the BookQuotes proxy server for quote extraction and book metadata recognition.

**File**: `Services/GeminiService.swift`

**Type**: `@MainActor @Observable class`

#### How It Works

The service proxies requests through a Cloudflare Worker to:
1. Add authentication (user's session token)
2. Attach the subscription API key
3. Handle rate limiting and error responses

```
┌─────────┐    ┌───────────────────┐    ┌─────────────┐
│  App    │───▶│  Proxy (Worker)   │───▶│  Gemini API │
└─────────┘    └───────────────────┘    └─────────────┘
     │                 │
     │                 └─── Validates subscription
     └─── Sends: image + prompt + session token
```

#### Key Methods

```swift
/// Extract quotes from a book page image
func extractQuotes(from image: UIImage, markings: [MarkingDefinition]) async throws -> QuoteExtractionResult

/// Extract book metadata from cover image
func extractCoverMetadata(from image: UIImage) async throws -> BookMetadataResult
```

#### Observable State

```swift
/// UI can show loading indicator
var isProcessing: Bool { get }

/// UI can display errors
var lastError: ExtractionError? { get }
```

#### Usage Example

```swift
struct QuoteCaptureView: View {
    @Environment(GeminiService.self) private var geminiService

    func processImage(_ image: UIImage) async {
        do {
            let markings = fetchMarkingDefinitions()
            let result = try await geminiService.extractQuotes(from: image, markings: markings)

            for quote in result.quotes {
                // Save quotes to SwiftData...
            }
        } catch {
            // Handle error...
        }
    }
}
```

#### Error Handling

The service throws typed `ExtractionError`:

| Error | Meaning | User Action |
|-------|---------|-------------|
| `.authenticationRequired` | No valid session token | Sign in again |
| `.subscriptionRequired` | Free tier exceeded | Upgrade or wait |
| `.rateLimited` | Too many requests | Wait and retry |
| `.invalidImage` | Image couldn't be processed | Retake photo |
| `.networkError(_)` | Connection failed | Check network |
| `.parsingError(_)` | AI response malformed | Retry |

---

### QuoteExtractionPromptBuilder

**Purpose**: Constructs optimized prompts for the Gemini API based on user's marking definitions.

**File**: `Services/QuoteExtractionPromptBuilder.swift`

**Type**: `enum` with static methods (stateless)

#### How It Works

The prompt builder creates structured instructions that:
1. Describe what marking types to look for
2. Request JSON-formatted responses
3. Include confidence scoring instructions

```swift
static func buildPrompt(markings: [MarkingDefinition]) -> String {
    // Generates a detailed prompt like:
    """
    You are analyzing a photograph of a book page.
    Look for these marking types:
    - Underline: single line under text (importance: high)
    - Highlight: colored marker highlighting (importance: high)
    - Margin line: vertical line next to paragraph (importance: medium)

    For each marked passage, extract:
    1. The exact text that was marked
    2. The type of marking
    3. Your confidence (0.0-1.0)
    4. Any margin notes nearby

    Return JSON in this format: { "quotes": [...], "pageNumber": ... }
    """
}
```

---

## Capture Services

### CameraService

**Purpose**: Manages AVFoundation camera session for photo capture.

**File**: `Services/CameraService.swift`

**Type**: `@Observable class`

#### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    CameraService                         │
├─────────────────────────────────────────────────────────┤
│  AVCaptureSession                                        │
│  ├── AVCaptureDeviceInput (back camera)                 │
│  ├── AVCapturePhotoOutput (still photos)                │
│  └── AVCaptureVideoPreviewLayer (live preview)          │
└─────────────────────────────────────────────────────────┘
```

#### Key Methods

```swift
/// Start the camera session
func startSession()

/// Stop the camera session
func stopSession()

/// Capture a photo
func capturePhoto() async throws -> UIImage

/// Toggle flash mode
func toggleFlash()
```

#### Observable State

```swift
var isSessionRunning: Bool
var flashMode: AVCaptureDevice.FlashMode
var capturedImage: UIImage?
```

---

### ImageQualityAnalyzer

**Purpose**: Analyzes image quality before API submission to prevent failed extractions.

**File**: `Services/ImageQualityAnalyzer.swift`

**Type**: `struct` with static methods

#### How It Works

The analyzer performs three checks:

1. **Blur Detection**: Uses Laplacian variance to detect motion blur
2. **Brightness Analysis**: Checks histogram distribution for over/under exposure
3. **Text Confidence**: Uses Vision framework to detect readable text

```swift
struct QualityAssessment {
    let overallScore: Double      // 0.0-1.0
    let isAcceptable: Bool        // score >= 0.6
    let issues: [QualityIssue]    // Problems found

    enum QualityIssue {
        case tooBlurry
        case tooDark
        case tooBright
        case lowTextConfidence
        case poorAngle
    }
}
```

#### Usage

```swift
let assessment = ImageQualityAnalyzer.analyze(image)

if assessment.isAcceptable {
    // Proceed with extraction
} else {
    // Show feedback: "Hold steadier" / "Improve lighting"
    showQualityWarning(assessment.issues)
}
```

---

### BatchProcessingService

**Purpose**: Processes multiple captured pages in parallel with rate limiting and progress tracking.

**File**: `Services/BatchProcessingService.swift`

**Type**: `actor`

#### How It Works

```
User captures 10 pages
         │
         ▼
┌────────────────────────────────────────────────────┐
│            BatchProcessingService                   │
├────────────────────────────────────────────────────┤
│  Concurrency: 3 parallel requests                  │
│  Rate limiting: 500ms between requests             │
│  Progress callback: (completed, total) → UI        │
└────────────────────────────────────────────────────┘
         │
         ├── Page 1 → GeminiService → Results
         ├── Page 2 → GeminiService → Results
         ├── Page 3 → GeminiService → Results
         │   ... (rate limited) ...
         └── Page 10 → GeminiService → Results
         │
         ▼
   BatchResult (all extracted quotes)
```

#### Configuration

```swift
struct Configuration {
    var maxConcurrent: Int = 3          // Parallel requests
    var requestDelay: TimeInterval = 0.5 // Between requests
    var pageTimeout: TimeInterval = 30   // Per-page timeout
    var stopOnFirstFailure: Bool = false

    static let conservative = Configuration(maxConcurrent: 2, requestDelay: 1.0)
    static let aggressive = Configuration(maxConcurrent: 5, requestDelay: 0.2)
}
```

#### Progress Tracking

```swift
struct BatchProgress: Sendable {
    let total: Int
    var completed: Int
    var failed: Int
    var currentlyProcessing: Set<UUID>

    var percentComplete: Double
    var isComplete: Bool
}

// Usage with progress callback
let service = BatchProcessingService()
let result = try await service.processSession(session, markings: markings) { progress in
    // Update UI: "Processing 3/10..."
    updateProgressBar(progress.percentComplete)
}
```

---

### CaptureQueueManager

**Purpose**: Manages offline capture queue—stores images locally and processes them when network is available.

**File**: `Services/CaptureQueueManager.swift`

**Type**: `actor` (singleton: `CaptureQueueManager.shared`)

#### How It Works

```
┌────────────────────────────────────────────────────────────────┐
│                     CaptureQueueManager                         │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│   User captures photo (offline)                                 │
│            │                                                    │
│            ▼                                                    │
│   ┌─────────────────┐                                          │
│   │ CaptureQueueItem│ (saved to SwiftData + file system)       │
│   │ status: pending │                                          │
│   └─────────────────┘                                          │
│            │                                                    │
│            │ ← NetworkMonitor detects connection               │
│            ▼                                                    │
│   ┌─────────────────┐                                          │
│   │ status: processing │ → GeminiService.extractQuotes()       │
│   └─────────────────┘                                          │
│            │                                                    │
│            ├── Success → status: completed, quotes saved       │
│            └── Failure → status: failed, schedule retry        │
│                                                                 │
│   Retry schedule: 5s → 30s → 120s (exponential backoff)        │
└────────────────────────────────────────────────────────────────┘
```

#### Key Methods

```swift
/// Add a captured image to the queue
func addToQueue(image: UIImage, book: Book, priority: Int = 0) async throws -> CaptureQueueItem

/// Manually retry a failed item
func retryItem(itemId: UUID) async throws

/// Remove an item from the queue
func removeFromQueue(itemId: UUID) async throws

/// Get current queue statistics
var stats: QueueStats { get }
```

#### Queue Statistics

```swift
struct QueueStats: Equatable, Sendable {
    var pendingCount: Int       // Waiting to process
    var processingCount: Int    // Currently processing
    var failedCount: Int        // Failed (can retry)
    var completedCount: Int     // Successfully processed
    var isProcessing: Bool      // Queue actively running

    var statusDescription: String  // "Processing 2 of 5"
}
```

---

## Search Services

### SearchService

**Purpose**: Provides debounced full-text search with reactive state for UI binding.

**File**: `Services/SearchService.swift`

**Type**: `@MainActor @Observable class`

#### How It Works

```
User types "ato"
    │
    │ ← 150ms debounce
    ▼
SearchService.search("ato", scope: .all)
    │
    ▼
SearchDatabase (SQLite FTS5)
    │
    ├── quotes_fts: "ato*" → matches "atomic", "atom"
    └── books_fts: "ato*" → matches "Atomic Habits"
    │
    ▼
SearchResults (quotes: [...], books: [...])
    │
    ▼
UI automatically updates (via @Observable)
```

#### Key Methods

```swift
/// Debounced search (call on every keystroke)
func search(_ query: String, scope: SearchScope = .all)

/// Immediate search (for programmatic use)
func searchImmediate(_ query: String, scope: SearchScope) async

/// Index management
func indexQuote(_ quote: Quote, book: Book) async
func indexBook(_ book: Book) async
func rebuildIndex(books: [Book]) async
```

#### Observable State

```swift
var results: SearchResults { get }   // Current results
var isSearching: Bool { get }        // Loading state
var lastError: SearchError? { get }  // Error state
```

See [SEARCH_SYSTEM.md](SEARCH_SYSTEM.md) for detailed search architecture.

---

### SearchDatabase

**Purpose**: Low-level SQLite FTS5 database operations for full-text search.

**File**: `Services/SearchDatabase.swift`

**Type**: `actor`

#### Schema

```sql
-- Quotes full-text index
CREATE VIRTUAL TABLE quotes_fts USING fts5(
    quote_id UNINDEXED,
    book_id UNINDEXED,
    text,
    margin_note,
    book_title,
    book_author,
    tokenize='porter unicode61'
);

-- Books full-text index
CREATE VIRTUAL TABLE books_fts USING fts5(
    book_id UNINDEXED,
    title,
    author,
    subtitle,
    tokenize='porter unicode61'
);
```

#### Key Features

- **Porter Stemming**: "running" matches "run", "runs", "runner"
- **Prefix Matching**: Instant-as-you-type with "term*" queries
- **BM25 Ranking**: Results ordered by relevance
- **Snippet Generation**: `<mark>` tags around matches

---

### SearchSuggestionsService

**Purpose**: Provides search suggestions, history, and "did you mean" corrections.

**File**: `Services/SearchSuggestionsService.swift`

**Type**: `@Observable class`

#### Features

1. **Recent Searches**: Stored locally, shown when search field is empty
2. **Autocomplete**: Book titles, authors, popular terms as you type
3. **Did You Mean**: Levenshtein distance for typo correction

```swift
// Get suggestions for partial input
let suggestions = await suggestionsService.getSuggestions(for: "atom")
// Returns: [.bookTitle("Atomic Habits"), .author("James Clear"), ...]

// Get typo correction
let correction = await suggestionsService.didYouMean("atmoic")
// Returns: "atomic"
```

---

## Data Services

### QuoteSaveService

**Purpose**: Saves extracted quotes to SwiftData with proper relationships and index updates.

**File**: `Services/QuoteSaveService.swift`

**Type**: `actor`

#### What It Does

1. Creates `Quote` model instances from extraction results
2. Links quotes to their parent `Book`
3. Updates the search index
4. Handles duplicate detection warnings

```swift
func saveQuotes(_ extracted: [ExtractedQuote], to book: Book, in context: ModelContext) async throws -> [Quote] {
    var savedQuotes: [Quote] = []

    for data in extracted {
        let quote = Quote(text: data.text, book: book)
        quote.pageNumber = data.pageNumber
        quote.markingType = data.markingType
        quote.confidence = data.confidence
        quote.marginNote = data.marginNote

        context.insert(quote)
        savedQuotes.append(quote)

        // Update search index
        await searchService?.indexQuote(quote, book: book)
    }

    try context.save()
    return savedQuotes
}
```

---

### DuplicateDetector

**Purpose**: Detects potential duplicate quotes before saving.

**File**: `Services/DuplicateDetector.swift`

**Type**: `actor`

#### How It Works

Uses text similarity (Levenshtein distance + word overlap) to find duplicates:

```swift
struct DuplicateCheck {
    let isDuplicate: Bool
    let similarity: Double       // 0.0-1.0
    let existingQuote: Quote?    // The potential duplicate

    var shouldWarn: Bool { similarity > 0.8 }
}

// Usage
let check = await duplicateDetector.check(newText, against: book.quotes)
if check.shouldWarn {
    showDuplicateWarning(existing: check.existingQuote!)
}
```

---

### ExportService

**Purpose**: Exports quotes to various formats (Markdown, JSON, plain text, Obsidian, Notion).

**File**: `Services/ExportService.swift`

**Type**: `actor`

#### Supported Formats

| Format | Output | Use Case |
|--------|--------|----------|
| Markdown | `.md` file with headers, quotes | General sharing |
| Plain Text | `.txt` clean text | Copy-paste |
| JSON | Structured data | API integration |
| Obsidian | Markdown + YAML frontmatter | Obsidian vault |
| Notion | API call | Notion database |

```swift
// Export to Markdown
let markdown = try await exportService.export(quotes, format: .markdown, options: options)

// Export to Obsidian with frontmatter
let obsidian = try await exportService.export(quotes, format: .obsidian, options: .init(
    includeMetadata: true,
    groupByBook: true
))
```

---

## Book Registration Services

### ISBNScanner

**Purpose**: Scans ISBN barcodes using Vision framework.

**File**: `Services/ISBNScanner.swift`

**Type**: `actor`

#### How It Works

Uses `VNDetectBarcodesRequest` to find EAN-13/EAN-8 barcodes:

```swift
func scan(from image: UIImage) async throws -> String? {
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.ean13, .ean8]

    let handler = VNImageRequestHandler(cgImage: cgImage)
    try handler.perform([request])

    return request.results?.first?.payloadStringValue
}
```

---

### ISBNLookupService

**Purpose**: Looks up book metadata from ISBN via Google Books and OpenLibrary APIs.

**File**: `Services/ISBNLookupService.swift`

**Type**: `actor`

#### Lookup Strategy

```
ISBN → Google Books API
           │
           ├── Found → Return metadata
           │
           └── Not found → OpenLibrary API
                              │
                              ├── Found → Return metadata
                              │
                              └── Not found → Return nil
```

```swift
struct BookLookupResult {
    let title: String
    let author: String
    let subtitle: String?
    let publisher: String?
    let publishedDate: String?
    let coverImageURL: URL?
    let isbn: String
    let source: LookupSource // .googleBooks or .openLibrary
}
```

---

## Infrastructure Services

### AuthService

**Purpose**: Manages Apple Sign-In and session tokens.

**File**: `Services/AuthService.swift`

**Type**: `@Observable class`

#### Authentication Flow

```
1. User taps "Sign in with Apple"
           │
           ▼
2. ASAuthorizationController presents UI
           │
           ▼
3. Apple returns user identifier + identity token
           │
           ▼
4. AuthService stores credentials in Keychain
           │
           ▼
5. Session token used for proxy API calls
```

#### Key Methods

```swift
/// Start sign-in flow
func signInWithApple() async throws

/// Check if user is authenticated
var isAuthenticated: Bool { get }

/// Get current session token for API calls
func getSessionToken() -> String?

/// Sign out and clear credentials
func signOut()
```

---

### KeychainService

**Purpose**: Secure storage for sensitive data (tokens, credentials).

**File**: `Services/KeychainService.swift`

**Type**: `actor`

#### Usage

```swift
// Store a value
try await KeychainService.shared.set("token123", forKey: "sessionToken")

// Retrieve a value
let token = try await KeychainService.shared.get("sessionToken")

// Delete a value
try await KeychainService.shared.delete("sessionToken")
```

---

### NetworkMonitor

**Purpose**: Monitors network connectivity using `NWPathMonitor`.

**File**: `Services/NetworkMonitor.swift`

**Type**: `@Observable class` (singleton: `NetworkMonitor.shared`)

#### Observable State

```swift
var isConnected: Bool { get }
var connectionType: ConnectionType { get } // .wifi, .cellular, .none
```

#### Integration with Queue

The `CaptureQueueManager` observes network changes:

```swift
// When connection restored
if !wasConnected && networkMonitor.isConnected {
    await queueManager.startProcessing()
}
```

---

### SubscriptionService

**Purpose**: Manages StoreKit 2 subscriptions and premium feature access.

**File**: `Services/SubscriptionService.swift`

**Type**: `@Observable class`

#### Subscription Tiers

| Tier | Features | Limit |
|------|----------|-------|
| Free | Basic extraction | 10/month |
| Premium | Unlimited extraction, batch mode, export | Unlimited |

#### Key Methods

```swift
/// Current subscription status
var subscriptionStatus: SubscriptionStatus { get }

/// Check if user can perform an extraction
var canExtract: Bool { get }

/// Purchase a subscription
func purchase(_ product: Product) async throws

/// Restore previous purchases
func restorePurchases() async throws
```

---

## Next Steps

- [CAPTURE_FLOW.md](CAPTURE_FLOW.md) — How capture services work together
- [SEARCH_SYSTEM.md](SEARCH_SYSTEM.md) — Deep dive into FTS5 search
- [TESTING.md](TESTING.md) — How to test services
