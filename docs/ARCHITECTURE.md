# Architecture Guide

This document explains the architectural patterns, conventions, and organization of the BookQuotes iOS app. Understanding these patterns will help you navigate the codebase and contribute effectively.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [The Model-View Pattern](#the-model-view-pattern)
4. [State Management with @Observable](#state-management-with-observable)
5. [Dependency Injection](#dependency-injection)
6. [Navigation System](#navigation-system)
7. [Service Layer](#service-layer)
8. [Concurrency Patterns](#concurrency-patterns)
9. [Error Handling](#error-handling)

---

## Overview

BookQuotes follows a **Model-View (MV)** architecture pattern optimized for SwiftUI and SwiftData. This is a deliberate simplification of MVVM—we avoid separate ViewModel classes because SwiftUI views are already lightweight value types, and SwiftData models with `@Observable` provide reactive state management directly.

### Key Principles

1. **Views are cheap** — SwiftUI views are structs. Don't fight the framework by adding abstraction layers.
2. **Services own logic** — Business logic lives in service classes, not views.
3. **Models are reactive** — SwiftData models with `@Observable` drive UI updates automatically.
4. **Environment is your friend** — Use SwiftUI's environment for dependency injection.

---

## Project Structure

```
BookQuotes/
├── App/                      # Application lifecycle and tab structure
│   ├── BookQuotesApp.swift   # @main entry point, container setup
│   ├── ContentView.swift     # Root TabView
│   ├── Tab.swift             # Tab enum definitions
│   ├── LibraryTab.swift      # Library tab navigation stack
│   ├── CaptureTab.swift      # Capture tab navigation
│   ├── SettingsTab.swift     # Settings tab navigation
│   └── RouterPath.swift      # Programmatic navigation helper
│
├── Models/                   # SwiftData @Model classes
│   ├── Book.swift            # Book entity with quotes relationship
│   ├── Quote.swift           # Quote entity linked to Book
│   ├── Collection.swift      # Quote organization
│   ├── Tag.swift             # Quote tagging
│   ├── MarkingDefinition.swift  # User annotation vocabulary
│   ├── CaptureSession.swift  # Batch capture session
│   ├── PageCapture.swift     # Individual captured page
│   └── CaptureQueueItem.swift # Offline queue item
│
├── Services/                 # Business logic and external integrations
│   ├── GeminiService.swift   # AI extraction via proxy
│   ├── SearchService.swift   # FTS5 search orchestration
│   ├── SearchDatabase.swift  # SQLite FTS5 implementation
│   ├── CameraService.swift   # AVFoundation camera
│   ├── CaptureQueueManager.swift  # Offline queue processing
│   ├── BatchProcessingService.swift # Parallel page extraction
│   └── ...                   # Other services
│
├── Features/                 # Feature modules (screens + supporting views)
│   ├── Library/              # Book/quote browsing
│   ├── Capture/              # Camera and capture flows
│   ├── BookRegistration/     # Cover capture, ISBN, editing
│   ├── QuoteCapture/         # Quote extraction and review
│   ├── Collections/          # Collection management
│   ├── Tags/                 # Tag management
│   ├── Export/               # Export functionality
│   ├── Onboarding/           # First-run experience
│   ├── Auth/                 # Sign-in flows
│   └── Subscription/         # Premium features
│
├── Components/               # Reusable UI components
│   ├── DesignSystem.swift    # Colors, typography, spacing tokens
│   ├── QuoteCardView.swift   # Quote display card
│   ├── BookCoverCard.swift   # Book cover thumbnail
│   ├── ErrorView.swift       # Error display states
│   ├── LoadingView.swift     # Loading indicators
│   └── ...                   # Other shared components
│
├── Utilities/                # Helpers and extensions
│   ├── HapticManager.swift   # Tactile feedback
│   ├── ImagePreprocessor.swift # Image preparation
│   ├── AccessibilityIdentifiers.swift # UI test identifiers
│   └── ...                   # Other utilities
│
└── Resources/                # Assets, localization
    └── Assets.xcassets/      # Images, colors
```

### Where to Add New Code

| You want to add... | Put it in... |
|-------------------|--------------|
| New data type to persist | `Models/` as a `@Model` class |
| Business logic / API calls | `Services/` as an `actor` or `@Observable` class |
| New screen in existing feature | `Features/<FeatureName>/` |
| Capture-tab flow transition logic | `Features/Capture/CaptureFlowState.swift` |
| Cover metadata extraction fallback logic | `Features/BookRegistration/CoverExtractionOrchestrator.swift` |
| Cover crop sizing, zoom, offset, or crop-rect logic | `Features/BookRegistration/CoverCropGeometry.swift` |
| Cover capture screen chrome sections | `Features/BookRegistration/CoverCaptureChrome.swift` |
| Cover OCR title/author text heuristics | `Features/BookRegistration/CoverOCRHeuristics.swift` |
| Book edit form UI sections | `Features/BookRegistration/BookEditSections.swift` |
| Entirely new feature | Create `Features/<NewFeature>/` folder |
| Shared UI component | `Components/` |
| Helper function or extension | `Utilities/` |

---

### Book Registration Seams

`Features/BookRegistration/` keeps `BookEditView.Mode` as the caller-facing interface for create, edit, and metadata-confirmation flows. Internally, form loading goes through:

- `BookEditSource`: create, edit existing book, or metadata source.
- `BookEditDraft`: value object for title, author, optional metadata strings, status, and cover image data.
- `BookEditOptions`: genre option list and display labels.
- `BookEditSaveDraft`: value object for form-to-`Book` create/update mapping.
- `BookEditCoverImageData`: compressed thumbnail/full cover image data passed into save mapping.
- `BookEditSections`: SwiftUI-only form sections for cover, details, metadata, reading status, and notes.
- `CoverMetadataNormalizer`: pure mapper from Gemini/OCR/manual extraction results into `BookMetadata`.
- `CoverExtractionOrchestrator`: async decision seam for Gemini success/failure, OCR fallback, and manual fallback.
- `CoverCaptureChrome`: cover-capture top mode switcher, barcode overlay, processing overlay, and bottom controls.
- `CoverCropGeometry`: pure crop viewport, scale, offset clamp, and image crop-rect calculations.
- `CoverCropReviewView`: crop-review sheet UI for move/zoom/use/retake.
- `CoverOCRHeuristics`: pure Vision text-line sanitizing and title/author guessing.

This keeps source-to-form mapping, save mapping, form section composition, and cover metadata normalization testable without exposing SwiftUI state, `ModelContext`, haptics, dismissal, API calls, camera services, Vision requests, or photo picker behavior. Further refactor slices should apply the same pattern to cover/image picking.

New cover extraction behavior should be characterized in `CoverExtractionOrchestratorTests` first. `CoverCaptureView` should keep the concrete image, Vision OCR, API service, loading/error, and sheet presentation concerns while delegating deterministic extraction decisions to the orchestrator.

New cover crop math should be characterized in `CoverCropGeometryTests` before touching `CoverCropReviewView`. New OCR title/author heuristics should be characterized in `CoverOCRHeuristicsTests`. Cover screen chrome changes should keep `CoverCaptureFlowTests` green because their observable behavior is user navigation and controls, not the internal SwiftUI section layout.

New book edit UI should be added to the relevant section in `BookEditSections.swift` unless it owns mode, persistence, photo loading, validation, save/update, dismissal, or milestone behavior. Those orchestration concerns remain in `BookEditView.swift`. Simulator coverage for this area should include manual create, validation, cancel, cover section visibility, and create-then-edit persisted title behavior.

### Capture Feature Seams

`Features/Capture/` keeps `CaptureTabRootView` as the SwiftUI shell for permission gating, coaching presentation, haptics, selected `Book` storage, and branch rendering. Deterministic flow decisions go through:

- `CaptureFlowState`: value type for current capture mode, quote/batch flow identity refreshes, and commands that tell the view when to clear selected-book state.

New capture-tab navigation behavior should be added to `CaptureFlowState` first with characterization tests. `CaptureTabRootView` should then delegate to the flow state and keep only UI orchestration that depends on SwiftUI, callbacks, or concrete `Book` objects.

---

## The Model-View Pattern

We use a simplified architecture that leverages SwiftUI and SwiftData's built-in capabilities:

```
┌─────────────────────────────────────────────────────────────┐
│                          View                               │
│  - Renders UI from model state                              │
│  - Calls service methods for actions                        │
│  - Reads from @Environment for dependencies                 │
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │ observes                           │ calls
         ▼                                    ▼
┌─────────────────────┐            ┌─────────────────────────┐
│   @Model (SwiftData)│            │   Service (@Observable) │
│  - Persisted state  │            │  - Business logic       │
│  - Relationships    │            │  - API calls            │
│  - Computed props   │            │  - State management     │
└─────────────────────┘            └─────────────────────────┘
```

### Example: Book Detail Screen

```swift
struct BookDetailView: View {
    // The model we're displaying
    let book: Book

    // Environment for persistence
    @Environment(\.modelContext) private var modelContext

    // Environment for navigation
    @Environment(RouterPath.self) private var router

    // Local UI state (not persisted)
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            // Display book properties directly
            Text(book.title)
            Text("by \(book.author)")

            // Display related quotes
            ForEach(book.quotes) { quote in
                NavigationLink(value: quote) {
                    QuoteCardView(quote: quote)
                }
            }
        }
    }

    private func deleteBook() {
        modelContext.delete(book)
        try? modelContext.save()
        router.pop() // Navigate back
    }
}
```

### Why Not MVVM?

Traditional MVVM adds a ViewModel layer between View and Model. In SwiftUI with SwiftData, this often creates unnecessary complexity:

1. **SwiftUI views are value types** — They're rebuilt frequently and cheaply. No need to separate "view logic."
2. **SwiftData models are @Observable** — They automatically notify views of changes.
3. **Services handle business logic** — Complex operations belong in services, not ViewModels.

We do use `@Observable` service classes when we need stateful business logic (like `SearchService`), but these aren't ViewModels—they're shared services injected via environment.

---

## State Management with @Observable

SwiftData models and service classes use the `@Observable` macro for reactive updates.

### Model State (Persisted)

```swift
@Model
final class Book {
    var title: String
    var author: String
    var status: ReadingStatus

    // Relationships
    @Relationship(deleteRule: .cascade)
    var quotes: [Quote] = []

    // Computed properties work too
    var quoteCount: Int { quotes.count }
}
```

When any property changes, views observing that model automatically update.

### Service State (In-Memory)

```swift
@MainActor
@Observable
final class SearchService {
    private(set) var results: SearchResults = .empty
    private(set) var isSearching = false
    private(set) var lastError: SearchError?

    func search(_ query: String, scope: SearchScope) {
        isSearching = true
        // ... perform search
        results = searchResults
        isSearching = false
    }
}
```

Views can observe service properties directly:

```swift
struct SearchResultsView: View {
    let searchService: SearchService

    var body: some View {
        if searchService.isSearching {
            ProgressView("Searching...")
        } else {
            ForEach(searchService.results.quotes) { ... }
        }
    }
}
```

### Local View State

Use `@State` for UI-only state that doesn't need persistence:

```swift
@State private var isExpanded = false
@State private var selectedTab = 0
@State private var showSheet = false
```

---

## Dependency Injection

We use SwiftUI's environment system for dependency injection.

### App-Level Services

Services are created at app launch and injected into the view hierarchy:

```swift
// BookQuotesApp.swift
@main
struct BookQuotesApp: App {
    @State private var authService = AuthService()
    @State private var geminiService: GeminiService
    @State private var networkMonitor = NetworkMonitor.shared

    init() {
        let auth = AuthService()
        _authService = State(initialValue: auth)
        _geminiService = State(initialValue: GeminiService(authService: auth))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(geminiService)
                .environment(networkMonitor)
                .modelContainer(container)
        }
    }
}
```

### Consuming Services in Views

```swift
struct QuoteCaptureView: View {
    @Environment(GeminiService.self) private var geminiService
    @Environment(\.modelContext) private var modelContext

    func extractQuotes(from image: UIImage) async {
        let result = try await geminiService.extractQuotes(from: image)
        // Use modelContext to save...
    }
}
```

### Custom Environment Keys

For optional services or non-Observable types:

```swift
// Define the key
private struct SearchServiceKey: EnvironmentKey {
    static let defaultValue: SearchService? = nil
}

// Extend EnvironmentValues
extension EnvironmentValues {
    var searchService: SearchService? {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }
}

// View modifier for convenience
extension View {
    func searchService(_ service: SearchService) -> some View {
        environment(\.searchService, service)
    }
}
```

---

## Navigation System

BookQuotes uses a combination of `NavigationStack` and programmatic navigation.

### Tab-Based Structure

Each major section has its own `NavigationStack`:

```swift
// ContentView.swift
struct ContentView: View {
    @State private var selectedTab = Tab.library

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryTab()
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(Tab.library)

            CaptureTab()
                .tabItem { Label("Capture", systemImage: "camera") }
                .tag(Tab.capture)

            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
    }
}
```

### Navigation Within Tabs

Each tab manages its own `NavigationStack`:

```swift
struct LibraryTab: View {
    @State private var router = RouterPath()

    var body: some View {
        NavigationStack(path: $router.path) {
            LibraryView()
                .navigationDestination(for: Book.self) { book in
                    BookDetailView(book: book)
                }
                .navigationDestination(for: Quote.self) { quote in
                    QuoteDetailView(quote: quote)
                }
        }
        .environment(router)
    }
}
```

### Programmatic Navigation

The `RouterPath` helper enables navigation from anywhere:

```swift
@Observable
final class RouterPath {
    var path = NavigationPath()

    func navigate(to destination: any Hashable) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
```

Usage in views:

```swift
struct QuoteCardView: View {
    let quote: Quote
    @Environment(RouterPath.self) private var router

    var body: some View {
        Button {
            router.navigate(to: quote)
        } label: {
            // Quote card content
        }
    }
}
```

### Modal Presentation

Use `@State` booleans with `.sheet()` or `.fullScreenCover()`:

```swift
@State private var showExportSheet = false

var body: some View {
    Button("Export") { showExportSheet = true }
        .sheet(isPresented: $showExportSheet) {
            ExportView(quotes: book.quotes)
        }
}
```

---

## Service Layer

Services encapsulate business logic and external integrations. They're typically `actor` (for thread safety) or `@Observable` classes (for reactive state).

### Service Types

| Type | When to Use | Example |
|------|-------------|---------|
| `actor` | Concurrent operations, no UI state | `BatchProcessingService`, `SearchDatabase` |
| `@Observable class` | Reactive state for UI binding | `SearchService`, `GeminiService` |
| `struct` | Stateless utilities | `ImagePreprocessor` |
| Singleton | App-wide shared state | `NetworkMonitor.shared` |

### Example: GeminiService

```swift
@MainActor
@Observable
final class GeminiService {
    // Observable state for UI
    private(set) var isProcessing = false
    private(set) var lastError: ExtractionError?

    // Dependencies
    private let authService: AuthService
    private let session: URLSession

    init(authService: AuthService) {
        self.authService = authService
        // Configure session...
    }

    // Business method
    func extractQuotes(from image: UIImage, markings: [MarkingDefinition]) async throws -> QuoteExtractionResult {
        isProcessing = true
        defer { isProcessing = false }

        guard let token = authService.getSessionToken() else {
            throw ExtractionError.authenticationRequired
        }

        // Prepare and send request...
        return try QuoteExtractionResult.parse(from: response)
    }
}
```

### Actor Example: BatchProcessingService

```swift
actor BatchProcessingService {
    private var isCancelled = false

    func processSession(_ session: CaptureSession) async throws -> BatchResult {
        isCancelled = false

        return await withTaskGroup(of: PageResult.self) { group in
            for capture in session.captures {
                group.addTask {
                    await self.processCapture(capture)
                }
            }
            // Collect results...
        }
    }

    func cancel() {
        isCancelled = true
    }
}
```

---

## Concurrency Patterns

BookQuotes uses Swift's structured concurrency throughout.

### MainActor for UI-Bound Services

Services that update UI state run on `@MainActor`:

```swift
@MainActor
@Observable
final class SearchService {
    // All property updates happen on main thread
    private(set) var results: SearchResults = .empty
}
```

### Actors for Thread-Safe State

Services with concurrent operations use `actor`:

```swift
actor SearchDatabase {
    private var db: OpaquePointer?

    func search(query: String) throws -> SearchResults {
        // SQLite operations are serialized
    }
}
```

### Task Groups for Parallelism

Batch operations use `withTaskGroup`:

```swift
func processBatch(_ captures: [PageCapture]) async -> [Result] {
    await withTaskGroup(of: Result.self) { group in
        for capture in captures.prefix(maxConcurrent) {
            group.addTask {
                await self.processOne(capture)
            }
        }

        var results: [Result] = []
        for await result in group {
            results.append(result)
        }
        return results
    }
}
```

### Task Cancellation

Long-running operations check for cancellation:

```swift
func search(_ query: String) {
    currentTask?.cancel()

    currentTask = Task {
        try? await Task.sleep(for: .milliseconds(150)) // Debounce
        guard !Task.isCancelled else { return }

        // Perform search...
    }
}
```

---

## Error Handling

Errors are typed per-domain and provide user-friendly messages.

### Domain-Specific Error Types

```swift
enum ExtractionError: LocalizedError {
    case authenticationRequired
    case subscriptionRequired
    case rateLimited
    case invalidImage
    case networkError(Error)
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Please sign in to extract quotes."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        // ...
        }
    }
}
```

### Error Display in Views

```swift
struct QuoteCaptureView: View {
    @State private var error: ExtractionError?

    var body: some View {
        ZStack {
            // Main content...

            if let error {
                ErrorView(error: error, style: .overlay) {
                    // Retry action
                    self.error = nil
                    await retryExtraction()
                }
            }
        }
    }
}
```

### Result Types for Complex Operations

```swift
struct BatchResult {
    let pageResults: [PageProcessingResult]
    let totalProcessingTime: TimeInterval

    var successCount: Int {
        pageResults.filter { $0.success }.count
    }

    var isFullSuccess: Bool {
        pageResults.allSatisfy { $0.success }
    }
}
```

---

## Next Steps

- [SERVICES.md](SERVICES.md) — Deep dive into each service
- [CAPTURE_FLOW.md](CAPTURE_FLOW.md) — End-to-end capture system
- [SEARCH_SYSTEM.md](SEARCH_SYSTEM.md) — FTS5 search architecture
- [TESTING.md](TESTING.md) — Testing strategy and patterns
