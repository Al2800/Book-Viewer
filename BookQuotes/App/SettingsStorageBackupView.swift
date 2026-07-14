import SwiftUI
import SwiftData

/// Storage and backup management
struct StorageBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var quotes: [Quote]
    @Query private var pageCaptures: [PageCapture]
    @Query private var queueItems: [CaptureQueueItem]

    @State private var showExportOptions = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var exportFilename: String?
    @State private var showExportResult = false
    @State private var exportError: String?

    @State private var showClearCacheConfirmation = false
    @State private var isClearingCache = false
    @State private var cacheCleared = false
    @State private var bytesCleared: Int64 = 0

    private let exportService = ExportService()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                storageCard
                backupCard
                cacheCard
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Storage & Export")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundPrimary)
        .confirmationDialog("Export Options", isPresented: $showExportOptions) {
            Button("Export as JSON") {
                Task { await exportAsJSON() }
            }
            Button("Export as Markdown") {
                Task { await exportAsMarkdown() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Clear Image Cache?",
            isPresented: $showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Cache", role: .destructive) {
                Task { await clearImageCache() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove unused capture images and temporary exports. Pending captures, drafts, quotes, and book covers will not be affected.")
        }
        .alert("Export", isPresented: $showExportResult) {
            if let url = exportURL {
                ShareLink(item: url) {
                    Text("Share")
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let error = exportError {
                Text(error)
            } else if let filename = exportFilename {
                Text("Successfully exported \(filename)")
            }
        }
        .overlay {
            if isExporting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("Exporting...")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
            }
        }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Storage Usage")
                .sectionHeaderStyle()

            SettingsInfoRow(label: "Books", value: "\(books.count)")
            SettingsInfoRow(label: "Quotes", value: "\(quotes.count)")
            SettingsInfoRow(label: "Images", value: estimatedImageStorage)
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Export")
                .sectionHeaderStyle()

            Button {
                showExportOptions = true
            } label: {
                Label("Export Quotes", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .glassButton()

            Text("Share your saved quotes and their book details as JSON or Markdown.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Data Management")
                .sectionHeaderStyle()

            Button(role: .destructive) {
                showClearCacheConfirmation = true
            } label: {
                HStack {
                    Label("Clear Image Cache", systemImage: "trash")
                    if isClearingCache {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .buttonStyle(.secondary)
            .disabled(isClearingCache)

            if cacheCleared {
                Label(
                    "Cleared \(ByteCountFormatter.string(fromByteCount: bytesCleared, countStyle: .file))",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(Color.success)
            } else {
                Text("Clear unused capture images and temporary exports to free up storage space.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var estimatedImageStorage: String {
        let embeddedBytes = books.reduce(0) {
            $0 + ($1.coverThumbnailData?.count ?? 0) + ($1.coverFullData?.count ?? 0)
        } + quotes.reduce(0) {
            $0 + ($1.sourceImageData?.count ?? 0)
        } + pageCaptures.reduce(0) {
            $0 + ($1.thumbnailData?.count ?? 0)
        } + queueItems.reduce(0) {
            $0 + ($1.thumbnailData?.count ?? 0)
        }

        let fileBytes = pageCaptures.compactMap(\.imageURL).reduce(0) {
            $0 + fileSize(at: $1)
        } + queueItems.reduce(0) {
            $0 + fileSize(at: $1.fullImagePath)
        }

        return ByteCountFormatter.string(
            fromByteCount: Int64(embeddedBytes) + fileBytes,
            countStyle: .file
        )
    }

    private func exportAsJSON() async {
        await performExport(format: .json)
    }

    private func exportAsMarkdown() async {
        await performExport(format: .markdown)
    }

    private func performExport(format: ExportFormat) async {
        guard !quotes.isEmpty else {
            exportError = "No quotes to export."
            showExportResult = true
            return
        }

        isExporting = true
        defer { isExporting = false }

        exportURL = nil
        exportFilename = nil
        exportError = nil

        do {
            let options = ExportOptions(
                includeMetadata: true,
                groupByBook: true,
                includePageNumbers: true,
                includeMarginNotes: true
            )

            let result = try await exportService.export(
                quotes: quotes,
                format: format,
                options: options
            )

            switch result {
            case let .file(url, filename):
                exportURL = url
                exportFilename = filename
                HapticManager.success()
            case let .apiSuccess(message):
                exportFilename = message
                HapticManager.success()
            case let .apiError(message):
                exportError = message
                HapticManager.error()
            }
        } catch {
            exportError = error.localizedDescription
            HapticManager.error()
        }

        showExportResult = true
    }

    private func clearImageCache() async {
        isClearingCache = true
        cacheCleared = false
        bytesCleared = 0

        defer { isClearingCache = false }

        var totalBytesCleared: Int64 = 0
        let fileManager = FileManager.default

        totalBytesCleared += clearQueueCache(fileManager: fileManager)
        totalBytesCleared += clearExportCache(fileManager: fileManager)
        totalBytesCleared += clearCapturesDirectory(fileManager: fileManager)

        bytesCleared = totalBytesCleared
        cacheCleared = true
        HapticManager.success()
    }

    private func clearQueueCache(fileManager: FileManager) -> Int64 {
        var bytesCleared: Int64 = 0
        let queueDirectory = CaptureQueueItem.queueDirectory

        guard let enumerator = fileManager.enumerator(
            at: queueDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        let referencedImagePaths = Set(queueItems.filter { !$0.imagePath.isEmpty }.map { $0.imagePath })

        for case let fileURL as URL in enumerator {
            if referencedImagePaths.contains(fileURL.lastPathComponent) {
                continue
            }

            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                do {
                    try fileManager.removeItem(at: fileURL)
                    bytesCleared += Int64(size)
                } catch {
                    // Continue clearing other files.
                }
            }
        }

        return bytesCleared
    }

    private func clearExportCache(fileManager: FileManager) -> Int64 {
        var bytesCleared: Int64 = 0

        guard let exportDir = try? ExportFileWriter.exportDirectory() else { return 0 }

        guard let enumerator = fileManager.enumerator(
            at: exportDir,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        let referencedImagePaths = Set(pageCaptures.compactMap(\.imageURL).map(\.standardizedFileURL.path))

        for case let fileURL as URL in enumerator {
            if referencedImagePaths.contains(fileURL.standardizedFileURL.path) {
                continue
            }

            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                bytesCleared += Int64(size)
            }
        }

        try? fileManager.removeItem(at: exportDir)

        return bytesCleared
    }

    private func clearCapturesDirectory(fileManager: FileManager) -> Int64 {
        var bytesCleared: Int64 = 0

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        let capturesDir = documentsURL.appendingPathComponent("captures", isDirectory: true)

        guard fileManager.fileExists(atPath: capturesDir.path) else { return 0 }

        guard let enumerator = fileManager.enumerator(
            at: capturesDir,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                bytesCleared += Int64(size)
            }
        }

        return bytesCleared
    }

    private func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else {
            return 0
        }
        return Int64(size)
    }
}
