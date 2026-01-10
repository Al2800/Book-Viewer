# Book Quote Scanner - Implementation Plan

## Project Overview

**App Name:** BookQuotes (working title)
**Platform:** iOS 17+ (SwiftUI)
**Purpose:** Digitize and organize quotes from physical books through photo capture and AI-powered text extraction

### Core Value Proposition
Transform the manual process of transcribing underlined passages, margin notes, and highlighted paragraphs from physical books into a seamless photo-to-digital workflow, building a personal library of memorable quotes.

---

## Feature Set

### Phase 1: Foundation (MVP)

#### 1.1 Book Registration
- Capture photo of book cover
- AI extracts: Title, Author, Subtitle, Publisher, ISBN (if visible), Page count (if visible)
- **ISBN Barcode Scanning**: Alternative to cover photo with near-100% accuracy
  - Vision framework barcode detection (EAN-13)
  - Google Books / OpenLibrary API lookup for verified metadata
  - Automatic cover image download from database
  - Fallback when cover recognition fails
- Manual editing/correction of extracted metadata
- Cover image storage and display
- Book status: Currently Reading, Finished, Want to Read

#### 1.2 Quote Capture
- Camera interface optimized for book pages
- **Pre-Upload Image Quality Assessment**: Prevent failed extractions
  - Vision framework blur detection (Laplacian variance)
  - Brightness/exposure analysis
  - Text presence confidence check
  - Actionable feedback: "Image appears blurry—hold steadier"
  - Prevents wasted API calls and user frustration
- **Multi-Page Batch Capture Mode**: Match real reading behavior
  - Capture 5-20 pages in sequence before processing
  - Thumbnail strip with page management
  - Batch processing with progress indicator
  - Review all extracted quotes together
  - Parallel processing with rate limiting
- **Custom marking definitions**: Users define their own annotation vocabulary
  - System defaults: Underline, double underline, margin line, highlight, bracket, margin note
  - User-created: Wavy underline, asterisk, question mark, etc.
  - Each marking has: name, visual description, semantic meaning
  - AI prompt dynamically built from user's marking vocabulary
- AI processes image and extracts:
  - The marked/underlined text verbatim
  - Page number (if visible)
  - Any handwritten margin notes (transcribed)
  - Marking type matched to user's definitions
- **Quote editing**: Full edit capability after extraction to correct LLM errors
- **Confidence scoring**: Display AI confidence per quote for transparency
- Assign quotes to specific books

#### 1.3 Offline Capture Queue
- **Capture anywhere**: Queue images when offline
- **Batch processing**: Automatically process queue when connectivity returns
- **Review flow**: User reviews extracted content before saving
- **Retry logic**: Failed extractions retry with exponential backoff

#### 1.4 Library View
- Grid/list view of all books with covers
- Filter by: Status, Author, Date Added
- Search books by title/author
- Book detail view showing all captured quotes

#### 1.5 Quote Display
- Individual quote cards with elegant typography
- Quote metadata: Page number, capture date, chapter (if available)
- Associated margin notes displayed separately
- **Confidence indicator**: Visual cue for AI extraction reliability

#### 1.6 Data Quality
- **Duplicate Quote Detection**: Prevent library clutter
  - Fuzzy string matching (Levenshtein distance)
  - Configurable similarity threshold (default 85%)
  - Non-blocking warning with options: Save Anyway, View Existing, Discard
  - Works within same book or across entire library
- **Correction Feedback Loop**: Enable continuous improvement
  - Track user corrections to AI extractions
  - Log original text, corrected text, confidence, marking type
  - Analyze patterns to identify problematic conditions
  - Build trust through transparency

### Phase 2: Enhanced Experience

#### 2.1 Collections & Tags
- Create custom collections (e.g., "Philosophy", "Productivity", "Favorites")
- Tag quotes with custom labels
- Smart collections based on criteria

#### 2.2 Export & Sharing
- **Export formats**:
  - **Markdown**: Standard blockquotes with attribution
  - **Plain text**: Simple readable format
  - **JSON**: Structured data for programmatic use
  - **Notion**: Callouts, tables, Notion-flavored markdown
  - **Obsidian**: YAML frontmatter, wikilinks, callouts, tags
- Share individual quotes with attribution
- Export entire book's quotes
- Social sharing with styled quote cards
- **Local backup**: Full JSON export to Files app

#### 2.3 Search & Discovery
- Full-text search across all quotes
- Search by author, book, tag, collection
- "Random quote" feature for rediscovery
- Reading insights/statistics

### Phase 3: Advanced Features

#### 3.1 Cloud Sync
- iCloud sync across devices
- Backup and restore functionality
- Optional account-based sync

#### 3.2 Enhanced AI Features
- Chapter/section detection
- Theme/topic categorization
- Similar quote suggestions
- Quote sentiment analysis

#### 3.3 Widgets & Integrations
- Home screen widgets (Quote of the day)
- Shortcuts integration
- Export to Notion/Obsidian/other apps

---

## Technical Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI (iOS 17+, targeting iOS 26 Liquid Glass) |
| Architecture | MV (Model-View) pattern per SwiftUI skills |
| State Management | `@Observable`, `@State`, `@Environment` |
| Persistence | SwiftData |
| Networking | async/await with URLSession |
| AI Processing | Google Gemini API via BookQuotes proxy (gemini-1.5-flash) |
| Image Processing | Vision framework + Gemini |
| Camera | AVFoundation / PhotosUI |

### Project Structure

```
BookQuotes/
├── App/
│   ├── BookQuotesApp.swift
│   ├── AppTab.swift
│   └── AppRouter.swift
├── Models/
│   ├── Book.swift
│   ├── Quote.swift
│   ├── Collection.swift
│   └── Tag.swift
├── Services/
│   ├── GeminiService.swift
│   ├── BookCoverProcessor.swift
│   ├── QuoteExtractor.swift
│   ├── ImageProcessor.swift
│   ├── PersistenceController.swift
│   ├── ImageQualityAnalyzer.swift    // NEW: Pre-upload quality checks
│   ├── ISBNScanner.swift             // NEW: Barcode detection + API lookup
│   ├── DuplicateDetector.swift       // NEW: Fuzzy string matching
│   ├── CaptureSession.swift          // NEW: Batch capture management
│   └── CorrectionAnalytics.swift     // NEW: Feedback tracking
├── Features/
│   ├── Library/
│   │   ├── LibraryView.swift
│   │   ├── BookGridItem.swift
│   │   └── LibrarySearchView.swift
│   ├── BookDetail/
│   │   ├── BookDetailView.swift
│   │   ├── QuoteListView.swift
│   │   └── BookEditView.swift
│   ├── Capture/
│   │   ├── CaptureView.swift
│   │   ├── CoverCaptureView.swift
│   │   ├── QuoteCaptureView.swift
│   │   ├── CameraOverlay.swift
│   │   ├── ImageReviewView.swift
│   │   ├── ImageQualitySheet.swift       // NEW: Quality warning UI
│   │   ├── BatchCaptureView.swift        // NEW: Multi-page capture
│   │   ├── BatchProcessingSheet.swift    // NEW: Batch progress/review
│   │   ├── BarcodeScannerView.swift      // NEW: ISBN scanning
│   │   └── BookConfirmationSheet.swift   // NEW: ISBN lookup results
│   ├── QuoteDetail/
│   │   ├── QuoteDetailView.swift
│   │   ├── QuoteCardView.swift
│   │   └── QuoteEditView.swift
│   ├── Collections/
│   │   ├── CollectionsView.swift
│   │   └── CollectionDetailView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── APIKeyView.swift
├── Components/
│   ├── BookCoverView.swift
│   ├── QuoteCard.swift
│   ├── LoadingOverlay.swift
│   ├── EmptyStateView.swift
│   └── AsyncButton.swift
├── Utilities/
│   ├── ImageUtilities.swift
│   ├── DateFormatters.swift
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

---

## Data Models

### Book

```swift
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var subtitle: String?
    var publisher: String?
    var isbn: String?
    var pageCount: Int?
    var coverImageData: Data?
    var status: ReadingStatus
    var dateAdded: Date
    var dateStarted: Date?
    var dateFinished: Date?

    @Relationship(deleteRule: .cascade, inverse: \Quote.book)
    var quotes: [Quote]

    init(title: String, author: String) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.status = .wantToRead
        self.dateAdded = Date()
        self.quotes = []
    }
}

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead = "Want to Read"
    case currentlyReading = "Currently Reading"
    case finished = "Finished"
}
```

### Quote

```swift
@Model
final class Quote {
    var id: UUID
    var text: String
    var pageNumber: Int?
    var chapter: String?
    var marginNote: String?
    var captureDate: Date
    var sourceImageData: Data?
    var markingType: MarkingType

    var book: Book?

    @Relationship(inverse: \Tag.quotes)
    var tags: [Tag]

    @Relationship(inverse: \Collection.quotes)
    var collections: [Collection]

    init(text: String, book: Book) {
        self.id = UUID()
        self.text = text
        self.captureDate = Date()
        self.markingType = .underline
        self.book = book
        self.tags = []
        self.collections = []
    }
}

enum MarkingType: String, Codable, CaseIterable {
    case underline = "Underline"
    case marginLine = "Margin Line"
    case highlight = "Highlight"
    case marginNote = "Margin Note"
    case mixed = "Mixed"
}
```

### Collection & Tag

```swift
@Model
final class Collection {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var dateCreated: Date

    var quotes: [Quote]

    init(name: String, icon: String = "folder", color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.dateCreated = Date()
        self.quotes = []
    }
}

@Model
final class Tag {
    var id: UUID
    var name: String

    var quotes: [Quote]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.quotes = []
    }
}
```

---

## App Navigation Architecture

Following the SwiftUI UI Patterns skill guidance:

### AppTab Enum

```swift
@MainActor
enum AppTab: Identifiable, Hashable, CaseIterable {
    case library
    case capture
    case collections
    case settings

    var id: String {
        switch self {
        case .library: return "library"
        case .capture: return "capture"
        case .collections: return "collections"
        case .settings: return "settings"
        }
    }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .library: LibraryView()
        case .capture: CaptureView()
        case .collections: CollectionsView()
        case .settings: SettingsView()
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .library:
            Label("Library", systemImage: "books.vertical")
        case .capture:
            Label("Capture", systemImage: "camera")
        case .collections:
            Label("Collections", systemImage: "folder")
        case .settings:
            Label("Settings", systemImage: "gear")
        }
    }
}
```

### Route Enum

```swift
enum Route: Hashable {
    case bookDetail(bookID: UUID)
    case quoteDetail(quoteID: UUID)
    case collectionDetail(collectionID: UUID)
    case addBook
    case editBook(bookID: UUID)
    case editQuote(quoteID: UUID)
}
```

### Sheet Destinations

```swift
enum SheetDestination: Identifiable, Hashable {
    case coverCapture
    case quoteCapture(bookID: UUID)
    case imageReview(image: UIImage, mode: CaptureMode)
    case exportQuotes(bookID: UUID)
    case shareQuote(quoteID: UUID)
    case createCollection
    case addTag

    var id: String {
        switch self {
        case .coverCapture, .quoteCapture, .imageReview:
            return "capture"
        case .exportQuotes, .shareQuote:
            return "export"
        case .createCollection, .addTag:
            return "organize"
        }
    }
}

enum CaptureMode {
    case bookCover
    case quotePage
}
```

---

## Gemini Proxy Integration

### Service Architecture

```swift
@MainActor
@Observable
final class GeminiService {
    private let baseURL = "https://api.bookquotes.app/v1" // Proxy endpoint
    private let model = "gemini-1.5-flash"
    private let authProvider: AuthProviding

    enum GeminiError: Error {
        case unauthenticated
        case subscriptionRequired
        case usageLimitReached
        case networkError(Error)
        case parsingError
        case rateLimited
        case invalidResponse
    }

    init(authProvider: AuthProviding) {
        self.authProvider = authProvider
    }

    func extractBookMetadata(from imageData: Data) async throws -> BookMetadata
    func extractQuotes(from imageData: Data) async throws -> [ExtractedQuote]
}
```

### Book Cover Extraction Prompt

```
Analyze this book cover image and extract the following information in JSON format:

{
  "title": "The book title",
  "author": "Author name(s)",
  "subtitle": "Subtitle if present, or null",
  "publisher": "Publisher name if visible, or null",
  "isbn": "ISBN if visible, or null"
}

If any field is not clearly visible or determinable, use null.
Respond ONLY with the JSON object, no additional text.
```

### Quote Extraction Prompt

```
Analyze this book page image. The reader has marked certain passages using underlines, margin lines, highlights, or margin notes.

Extract ALL marked/highlighted content and return as JSON:

{
  "quotes": [
    {
      "text": "The exact text that was underlined or marked",
      "pageNumber": 123 or null if not visible,
      "marginNote": "Any handwritten note near this passage, or null",
      "markingType": "underline" | "marginLine" | "highlight" | "marginNote"
    }
  ]
}

Rules:
1. Extract the EXACT text that is underlined, highlighted, or indicated by margin lines
2. For margin lines (vertical lines in the margin), extract the entire paragraph they indicate
3. Transcribe any handwritten margin notes as accurately as possible
4. If page number is visible in corners, include it
5. Maintain original formatting including line breaks where meaningful
6. If multiple separate passages are marked, return each as a separate quote

Respond ONLY with the JSON object, no additional text.
```

### Response Models

```swift
struct BookMetadata: Codable {
    let title: String
    let author: String
    let subtitle: String?
    let publisher: String?
    let isbn: String?
}

struct ExtractedQuote: Codable {
    let text: String
    let pageNumber: Int?
    let marginNote: String?
    let markingType: String
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String
    }
}
```

---

## UI/UX Design Guidelines

### Design Principles

1. **Visual Elegance**: Quotes are literature - present them beautifully
2. **Minimal Friction**: Photo → Extracted Quote should feel magical
3. **Scannable Library**: Quick visual browsing of books and quotes
4. **Readable Typography**: Large, comfortable reading experience

### Color Palette

```swift
extension Color {
    static let brandPrimary = Color("BrandPrimary")     // Deep literary blue
    static let brandSecondary = Color("BrandSecondary") // Warm paper cream
    static let accentGold = Color("AccentGold")         // Highlight accent
    static let textPrimary = Color("TextPrimary")       // Rich black
    static let textSecondary = Color("TextSecondary")   // Soft gray
    static let cardBackground = Color("CardBackground") // Subtle warmth
}
```

### Typography

```swift
extension Font {
    static let quoteDisplay = Font.custom("Georgia", size: 20)
        .weight(.regular)
    static let quoteAttribution = Font.custom("Georgia", size: 14)
        .italic()
    static let bookTitle = Font.system(.title2, design: .serif)
        .weight(.semibold)
    static let authorName = Font.system(.subheadline, design: .serif)
}
```

### Key UI Components

#### Quote Card (Visually Stunning)

```swift
struct QuoteCardView: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Opening quotation mark
            Text("\u{201C}")
                .font(.system(size: 48, design: .serif))
                .foregroundStyle(.secondary.opacity(0.3))

            // Quote text
            Text(quote.text)
                .font(.quoteDisplay)
                .lineSpacing(6)
                .foregroundStyle(.textPrimary)

            // Attribution
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let book = quote.book {
                        Text(book.title)
                            .font(.quoteAttribution)
                            .fontWeight(.medium)
                        Text("by \(book.author)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let page = quote.pageNumber {
                    Text("p. \(page)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
```

### iOS 26 Liquid Glass Integration

For iOS 26+, apply Liquid Glass treatment to key surfaces:

```swift
// Quote card with Liquid Glass
if #available(iOS 26, *) {
    quoteContent
        .padding(24)
        .glassEffect(.regular.tint(.blue.opacity(0.1)), in: .rect(cornerRadius: 16))
} else {
    quoteContent
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
}
```

---

## Camera & Image Processing

### Camera Configuration

```swift
@MainActor
@Observable
final class CameraManager {
    private let captureSession = AVCaptureSession()

    var capturedImage: UIImage?
    var isCapturing = false

    func configureSession() {
        captureSession.sessionPreset = .photo
        // Configure for document capture:
        // - High resolution
        // - Auto-focus on center
        // - Stable exposure
    }

    func capturePhoto() async throws -> UIImage {
        // Capture with document-optimized settings
    }
}
```

### Image Preprocessing

Before sending to Gemini:

```swift
extension UIImage {
    func preparedForOCR() -> UIImage {
        // 1. Resize to max 2048px on longest edge (Gemini limit consideration)
        // 2. Convert to JPEG with 0.8 quality
        // 3. Optional: Increase contrast slightly
        // 4. Optional: Deskew if tilted
        return processedImage
    }
}
```

---

## Implementation Phases

### Phase 1: MVP (Weeks 1-4)

#### Week 1: Project Setup & Core Data
- [ ] Create Xcode project with SwiftUI lifecycle
- [ ] Set up SwiftData models (Book, Quote)
- [ ] Implement PersistenceController
- [ ] Create app navigation skeleton (TabView, NavigationStack)
- [ ] Implement RouterPath and sheet destinations

#### Week 2: Backend & Gemini Integration
- [ ] Implement Apple Sign-In + session management
- [ ] Implement StoreKit 2 subscription flow
- [ ] Set up proxy endpoint for Gemini requests
- [ ] Implement GeminiService using the proxy
- [ ] Create BookCoverProcessor + QuoteExtractor
- [ ] Error handling, retry logic, and quota messaging

#### Week 3: Capture Flow
- [ ] Camera interface with AVFoundation
- [ ] Cover capture flow with preview/confirm
- [ ] Quote capture flow with preview/confirm
- [ ] Image preprocessing utilities
- [ ] Loading states and progress indicators

#### Week 4: Library & Display
- [ ] LibraryView with book grid
- [ ] BookDetailView with quotes list
- [ ] QuoteDetailView with elegant card
- [ ] Basic search functionality
- [ ] Empty states and onboarding

### Phase 2: Enhanced Experience (Weeks 5-7)

#### Week 5: Collections & Tags
- [ ] Collection model and CRUD
- [ ] Tag model and CRUD
- [ ] Collection assignment UI
- [ ] Tag assignment UI
- [ ] Filter by collection/tag

#### Week 6: Export & Sharing
- [ ] Plain text export
- [ ] Markdown export
- [ ] Quote card image generation
- [ ] Share sheet integration
- [ ] PDF export (book's quotes)

#### Week 7: Polish & Performance
- [ ] Image caching strategy
- [ ] Lazy loading optimization
- [ ] Haptic feedback
- [ ] Accessibility audit
- [ ] Error messaging improvements

### Phase 3: Advanced (Weeks 8-10)

#### Week 8: Cloud Sync
- [ ] iCloud container setup
- [ ] CloudKit sync for SwiftData
- [ ] Conflict resolution strategy
- [ ] Sync status indicators

#### Week 9: Widgets & Shortcuts
- [ ] Quote of the day widget (small, medium)
- [ ] Random quote widget
- [ ] Shortcuts integration (capture, search)

#### Week 10: Final Polish
- [ ] iOS 26 Liquid Glass adoption
- [ ] Performance profiling
- [ ] TestFlight beta
- [ ] App Store assets

---

## Authentication & Subscription Management

### Secure Token Storage

```swift
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.bookquotes.auth"

    func saveSessionToken(_ token: String) throws {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    func getSessionToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
}
```

### User Onboarding for Subscription

1. First launch shows value proposition
2. Sign in with Apple
3. Start free trial or pick a plan (StoreKit 2)
4. Backend issues session token
5. Success → proceed to app

---

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Gemini response parsing
- Image preprocessing logic
- Date formatters
- Search filtering

### Integration Tests
- SwiftData CRUD operations
- Gemini API integration (with test images)
- Image capture pipeline

### UI Tests
- Navigation flows
- Capture flow completion
- Search functionality
- Export functionality

### Manual Testing Checklist
- [ ] Book cover recognition accuracy
- [ ] Quote extraction accuracy with various marking styles
- [ ] Handwritten note transcription quality
- [ ] Performance with large libraries (100+ books, 1000+ quotes)
- [ ] Offline behavior
- [ ] Low-light camera capture
- [ ] Various book/page sizes

---

## Performance Considerations

### Image Handling
- Store thumbnails separately from full images
- Lazy load images in lists
- Use `@Query` with fetch limits for large datasets
- Clear unused image cache periodically

### Network
- Debounce search queries (250ms)
- Queue image processing requests
- Implement request timeout (30s)
- Cache Gemini responses temporarily

### Memory
- Use `LazyVStack` / `LazyVGrid` for lists
- Release camera session when not in use
- Monitor memory with Instruments

---

## Open Questions / Decisions Needed

1. **Offline Mode**: Should users be able to capture images offline and process later when connected?

2. **Multiple Languages**: Should we support quote extraction from non-English books?

3. **Handwriting Style**: How accurate should margin note transcription be? Accept inaccuracy or require confirmation?

4. **Subscription Model**: Decision = subscription with app-managed Gemini key (no BYOK)

5. **Book Metadata Enrichment**: Should we supplement cover recognition with book database APIs (Google Books, OpenLibrary)?

6. **Quote Deduplication**: How to handle accidentally capturing the same quote twice?

---

## Files to Create First

When starting implementation, create these files in order:

1. `BookQuotesApp.swift` - App entry point
2. `Models/Book.swift` - Core data model
3. `Models/Quote.swift` - Core data model
4. `Services/PersistenceController.swift` - SwiftData setup
5. `App/AppTab.swift` - Tab definitions
6. `App/AppRouter.swift` - Navigation router
7. `Features/Library/LibraryView.swift` - Main library screen
8. `Services/GeminiService.swift` - Proxy integration
9. `Services/AuthService.swift` - Apple Sign-In + session management
10. `Features/Settings/SettingsView.swift` - Subscription/account settings

---

## Summary

This plan outlines a SwiftUI-native iOS app that transforms physical book annotations into a digital quote library. The architecture follows modern SwiftUI patterns (MV, `@Observable`, `NavigationStack` routing) and integrates Gemini AI for intelligent text extraction.

Key differentiators:
- **Focus on marked passages**: Not generic OCR, but specifically extracting reader-highlighted content
- **Beautiful presentation**: Quotes are literature - display them elegantly
- **Privacy-first**: Proxy with minimal retention, local-first storage
- **Progressive complexity**: MVP is usable, later phases add power features

Ready to begin implementation when you are.
