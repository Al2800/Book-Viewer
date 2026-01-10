# Offline Queue & Export Integrations

## Offline Capture Queue

### Problem
Users may want to capture quotes while reading in locations without internet (airplane, cabin, park). The app should allow capture and queue for processing when connectivity returns.

### Solution
Implement an offline-first capture queue that stores images locally and processes them when online.

---

## Offline Queue Model

```swift
@Model
final class CaptureQueueItem {
    @Attribute(.unique) var id: UUID

    /// Type of capture
    var captureType: CaptureType

    /// Image data (stored locally)
    @Attribute(.externalStorage)
    var imageData: Data

    /// Associated book (for quote captures)
    var book: Book?

    /// Processing status
    var status: QueueStatus

    /// When the capture was taken
    var captureDate: Date

    /// Number of processing attempts
    var attemptCount: Int

    /// Last error message if failed
    var lastError: String?

    /// When processing was last attempted
    var lastAttemptDate: Date?

    /// Result: extracted book metadata (for cover captures)
    var extractedBookMetadata: Data? // JSON encoded BookMetadataResponse

    /// Result: extracted quotes (for page captures)
    var extractedQuotes: Data? // JSON encoded [ExtractedQuoteResponse]

    init(captureType: CaptureType, imageData: Data, book: Book? = nil) {
        self.id = UUID()
        self.captureType = captureType
        self.imageData = imageData
        self.book = book
        self.status = .pending
        self.captureDate = Date()
        self.attemptCount = 0
    }
}

enum CaptureType: String, Codable {
    case bookCover
    case quotePage
}

enum QueueStatus: String, Codable {
    case pending        // Waiting to be processed
    case processing     // Currently being processed
    case completed      // Successfully processed, awaiting user review
    case failed         // Failed after max attempts
    case reviewed       // User has reviewed and saved/discarded
}
```

---

## Queue Manager

```swift
import Network

@MainActor
@Observable
final class CaptureQueueManager {
    private let modelContext: ModelContext
    private let geminiService: GeminiService
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isOnline = false
    private(set) var isProcessing = false
    private(set) var pendingCount = 0

    private let maxAttempts = 3
    private var processingTask: Task<Void, Never>?

    init(modelContext: ModelContext, geminiService: GeminiService) {
        self.modelContext = modelContext
        self.geminiService = geminiService
        setupNetworkMonitoring()
        updatePendingCount()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = !(self?.isOnline ?? false)
                self?.isOnline = path.status == .satisfied

                // Auto-process queue when coming online
                if wasOffline && path.status == .satisfied {
                    self?.processQueue()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - Queue Operations

    /// Add a new capture to the queue
    func enqueue(captureType: CaptureType, imageData: Data, book: Book? = nil) {
        let item = CaptureQueueItem(
            captureType: captureType,
            imageData: imageData,
            book: book
        )
        modelContext.insert(item)
        updatePendingCount()

        // Try to process immediately if online
        if isOnline {
            processQueue()
        }
    }

    /// Get all pending items for display
    func getPendingItems() -> [CaptureQueueItem] {
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate { $0.status == .pending || $0.status == .failed },
            sortBy: [SortDescriptor(\.captureDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get items ready for review
    func getCompletedItems() -> [CaptureQueueItem] {
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate { $0.status == .completed },
            sortBy: [SortDescriptor(\.captureDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Process the queue
    func processQueue() {
        guard isOnline, !isProcessing else { return }

        processingTask?.cancel()
        processingTask = Task {
            await processQueueAsync()
        }
    }

    private func processQueueAsync() async {
        isProcessing = true
        defer {
            isProcessing = false
            updatePendingCount()
        }

        let pendingItems = getPendingItems().filter {
            $0.status == .pending || ($0.status == .failed && $0.attemptCount < maxAttempts)
        }

        for item in pendingItems {
            guard !Task.isCancelled else { break }

            item.status = .processing
            item.attemptCount += 1
            item.lastAttemptDate = Date()

            do {
                switch item.captureType {
                case .bookCover:
                    let metadata = try await geminiService.extractBookMetadata(from: item.imageData)
                    item.extractedBookMetadata = try JSONEncoder().encode(metadata)
                    item.status = .completed

                case .quotePage:
                    let response = try await geminiService.extractQuotes(from: item.imageData)
                    item.extractedQuotes = try JSONEncoder().encode(response)
                    item.status = .completed
                }

                item.lastError = nil

            } catch {
                item.lastError = error.localizedDescription

                if item.attemptCount >= maxAttempts {
                    item.status = .failed
                } else {
                    item.status = .pending // Retry later
                }
            }

            // Small delay between items to avoid rate limiting
            try? await Task.sleep(for: .milliseconds(500))
        }
    }

    /// Mark item as reviewed (user accepted or discarded)
    func markReviewed(_ item: CaptureQueueItem) {
        item.status = .reviewed
        updatePendingCount()
    }

    /// Delete a queue item
    func delete(_ item: CaptureQueueItem) {
        modelContext.delete(item)
        updatePendingCount()
    }

    /// Retry a failed item
    func retry(_ item: CaptureQueueItem) {
        item.status = .pending
        item.attemptCount = 0
        item.lastError = nil
        processQueue()
    }

    private func updatePendingCount() {
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate { $0.status == .pending || $0.status == .processing }
        )
        pendingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
```

---

## Queue UI

### Queue Status Badge

```swift
struct QueueStatusBadge: View {
    @Environment(CaptureQueueManager.self) private var queueManager

    var body: some View {
        if queueManager.pendingCount > 0 {
            HStack(spacing: 4) {
                if queueManager.isProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if !queueManager.isOnline {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                }

                Text("\(queueManager.pendingCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(queueManager.isOnline ? .accent : .secondary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
}
```

### Queue Review View

```swift
struct QueueReviewView: View {
    @Environment(CaptureQueueManager.self) private var queueManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                if !queueManager.isOnline {
                    offlineBanner
                }

                Section("Ready for Review") {
                    ForEach(queueManager.getCompletedItems()) { item in
                        QueueItemRow(item: item, onAccept: { acceptItem(item) })
                    }
                }

                Section("Pending") {
                    ForEach(queueManager.getPendingItems()) { item in
                        PendingItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Capture Queue")
            .toolbar {
                if queueManager.isOnline && queueManager.pendingCount > 0 {
                    Button("Process All") {
                        queueManager.processQueue()
                    }
                }
            }
        }
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("You're offline. Captures will process when connected.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .listRowBackground(Color.secondary.opacity(0.1))
    }

    private func acceptItem(_ item: CaptureQueueItem) {
        // Convert extracted data to models and save
        switch item.captureType {
        case .bookCover:
            if let data = item.extractedBookMetadata,
               let metadata = try? JSONDecoder().decode(BookMetadataResponse.self, from: data) {
                let book = metadata.toBook()
                book.coverThumbnailData = item.imageData
                modelContext.insert(book)
            }

        case .quotePage:
            if let data = item.extractedQuotes,
               let response = try? JSONDecoder().decode(QuoteExtractionResponse.self, from: data),
               let book = item.book {
                for extracted in response.quotes {
                    let quote = extracted.toQuote(book: book)
                    quote.sourceImageData = item.imageData
                    modelContext.insert(quote)
                }
            }
        }

        queueManager.markReviewed(item)
    }
}
```

---

## Export Integrations

### Export Service

```swift
@MainActor
@Observable
final class ExportService {
    enum ExportFormat: String, CaseIterable, Identifiable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case json = "JSON"
        case notion = "Notion"
        case obsidian = "Obsidian"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .markdown, .obsidian: return "md"
            case .plainText: return "txt"
            case .json: return "json"
            case .notion: return "md" // Notion uses markdown
            }
        }

        var icon: String {
            switch self {
            case .markdown: return "doc.text"
            case .plainText: return "doc.plaintext"
            case .json: return "curlybraces"
            case .notion: return "n.square"
            case .obsidian: return "diamond"
            }
        }
    }

    // MARK: - Export Book Quotes

    func exportBook(_ book: Book, format: ExportFormat) -> String {
        switch format {
        case .markdown:
            return exportBookMarkdown(book)
        case .plainText:
            return exportBookPlainText(book)
        case .json:
            return exportBookJSON(book)
        case .notion:
            return exportBookNotion(book)
        case .obsidian:
            return exportBookObsidian(book)
        }
    }

    // MARK: - Markdown Export

    private func exportBookMarkdown(_ book: Book) -> String {
        var output = "# \(book.title)\n\n"
        output += "**Author:** \(book.author)\n"

        if let subtitle = book.subtitle {
            output += "**Subtitle:** \(subtitle)\n"
        }

        output += "**Status:** \(book.status.displayName)\n"
        output += "**Quotes:** \(book.quoteCount)\n\n"
        output += "---\n\n"

        for quote in book.quotes.sorted(by: { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }) {
            output += "> \(quote.text)\n\n"

            if let page = quote.pageNumber {
                output += "*Page \(page)*"
            }

            if let note = quote.marginNote {
                output += " | *Note: \(note)*"
            }

            output += "\n\n"
        }

        return output
    }

    // MARK: - Plain Text Export

    private func exportBookPlainText(_ book: Book) -> String {
        var output = "\(book.title)\n"
        output += "by \(book.author)\n"
        output += String(repeating: "=", count: 40) + "\n\n"

        for quote in book.quotes.sorted(by: { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }) {
            output += "\"\(quote.text)\"\n"

            if let page = quote.pageNumber {
                output += "— Page \(page)"
            }

            if let note = quote.marginNote {
                output += "\nNote: \(note)"
            }

            output += "\n\n"
        }

        return output
    }

    // MARK: - JSON Export

    private func exportBookJSON(_ book: Book) -> String {
        struct ExportBook: Codable {
            let title: String
            let author: String
            let subtitle: String?
            let status: String
            let quotes: [ExportQuote]
        }

        struct ExportQuote: Codable {
            let text: String
            let pageNumber: Int?
            let marginNote: String?
            let markingType: String
            let captureDate: Date
        }

        let exportBook = ExportBook(
            title: book.title,
            author: book.author,
            subtitle: book.subtitle,
            status: book.status.rawValue,
            quotes: book.quotes.map { quote in
                ExportQuote(
                    text: quote.text,
                    pageNumber: quote.pageNumber,
                    marginNote: quote.marginNote,
                    markingType: quote.markingDisplayName,
                    captureDate: quote.captureDate
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(exportBook),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json
    }

    // MARK: - Notion Export

    /// Formats for Notion's markdown flavor with callouts and databases
    private func exportBookNotion(_ book: Book) -> String {
        var output = "# \(book.title)\n\n"

        // Notion properties block
        output += """
        | Property | Value |
        |----------|-------|
        | Author | \(book.author) |
        | Status | \(book.status.displayName) |
        | Quotes | \(book.quoteCount) |

        """

        output += "\n---\n\n"
        output += "## Quotes\n\n"

        for quote in book.quotes.sorted(by: { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }) {
            // Notion callout format
            output += "> 💬 \(quote.text)\n"

            var metadata: [String] = []
            if let page = quote.pageNumber {
                metadata.append("Page \(page)")
            }
            metadata.append(quote.markingDisplayName)

            output += "> \n"
            output += "> *\(metadata.joined(separator: " • "))*\n\n"

            if let note = quote.marginNote {
                output += "📝 **My note:** \(note)\n\n"
            }
        }

        return output
    }

    // MARK: - Obsidian Export

    /// Formats for Obsidian with YAML frontmatter, wikilinks, and tags
    private func exportBookObsidian(_ book: Book) -> String {
        var output = """
        ---
        title: "\(book.title)"
        author: "\(book.author)"
        status: \(book.status.rawValue)
        quotes: \(book.quoteCount)
        tags: [book, quotes]
        ---

        # \(book.title)

        **Author:** [[\(book.author)]]

        """

        if let subtitle = book.subtitle {
            output += "**Subtitle:** \(subtitle)\n"
        }

        output += "\n## Quotes\n\n"

        for (index, quote) in book.quotes.sorted(by: { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }).enumerated() {
            output += "### Quote \(index + 1)\n\n"
            output += "> [!quote]\n"
            output += "> \(quote.text)\n\n"

            var metadata: [String] = []
            if let page = quote.pageNumber {
                metadata.append("p. \(page)")
            }
            metadata.append("#\(quote.markingDisplayName.lowercased().replacingOccurrences(of: " ", with: "-"))")

            output += "*\(metadata.joined(separator: " • "))*\n\n"

            if let note = quote.marginNote {
                output += "> [!note] My Note\n"
                output += "> \(note)\n\n"
            }
        }

        // Backlinks section
        output += "\n---\n"
        output += "## Related\n"
        output += "- [[\(book.author)]]\n"

        return output
    }

    // MARK: - Share/Save

    func shareExport(_ content: String, filename: String, format: ExportFormat) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(filename).\(format.fileExtension)")

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    func saveToFiles(_ content: String, filename: String, format: ExportFormat) async -> Bool {
        guard let url = shareExport(content, filename: filename, format: format) else {
            return false
        }

        // Use document picker to save
        // Implementation depends on UIKit integration
        return true
    }
}
```

---

## Export UI

### Export Sheet

```swift
struct ExportSheet: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportService.ExportFormat = .markdown
    @State private var exportContent: String = ""
    @State private var showShareSheet = false

    private let exportService = ExportService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Format picker
                formatPicker
                    .padding()

                Divider()

                // Preview
                ScrollView {
                    Text(exportContent)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(.backgroundSecondary)
            }
            .navigationTitle("Export Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        showShareSheet = true
                    }
                }
            }
            .onAppear {
                updatePreview()
            }
            .onChange(of: selectedFormat) { _, _ in
                updatePreview()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportService.shareExport(
                    exportContent,
                    filename: sanitizeFilename(book.title),
                    format: selectedFormat
                ) {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var formatPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(ExportService.ExportFormat.allCases) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        Label(format.rawValue, systemImage: format.icon)
                            .font(.subheadline)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedFormat == format ? .accent : .backgroundSecondary)
                            .foregroundStyle(selectedFormat == format ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func updatePreview() {
        exportContent = exportService.exportBook(book, format: selectedFormat)
    }

    private func sanitizeFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// UIKit ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

---

## Local Storage

All data is stored locally by default using SwiftData. The export formats above allow users to:
1. **Keep a local backup** - Export to Files app
2. **Sync to cloud notes** - Notion, Obsidian via their sync
3. **Share** - Send markdown/text to any app

### Automatic Local Backup

```swift
@MainActor
final class BackupService {
    private let fileManager = FileManager.default

    var backupDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backups = documents.appendingPathComponent("Backups", isDirectory: true)

        if !fileManager.fileExists(atPath: backups.path) {
            try? fileManager.createDirectory(at: backups, withIntermediateDirectories: true)
        }

        return backups
    }

    /// Create a full JSON backup of all data
    func createBackup(books: [Book]) -> URL? {
        let exportService = ExportService()

        var allData: [[String: Any]] = []

        for book in books {
            let json = exportService.exportBook(book, format: .json)
            if let data = json.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                allData.append(dict)
            }
        }

        let backup: [String: Any] = [
            "version": 1,
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "bookCount": books.count,
            "books": allData
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: backup, options: .prettyPrinted) else {
            return nil
        }

        let filename = "BookQuotes_Backup_\(Date().formatted(.iso8601.year().month().day())).json"
        let fileURL = backupDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    /// List available backups
    func listBackups() -> [URL] {
        let contents = try? fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        return (contents ?? [])
            .filter { $0.pathExtension == "json" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return date1 > date2
            }
    }
}
```

---

## Summary

| Feature | Implementation |
|---------|---------------|
| **Offline Capture** | Queue items stored locally, process when online |
| **Batch Processing** | Sequential with rate limiting, retry on failure |
| **Network Awareness** | NWPathMonitor triggers auto-processing |
| **Export: Markdown** | Standard markdown with blockquotes |
| **Export: Plain Text** | Simple readable format |
| **Export: JSON** | Structured data for programmatic use |
| **Export: Notion** | Callouts, tables, Notion-flavored markdown |
| **Export: Obsidian** | YAML frontmatter, wikilinks, callouts, tags |
| **Local Backup** | Full JSON export to Documents/Backups |
