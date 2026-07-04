import SwiftUI
import SwiftData

/// Storage and backup management
struct StorageBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var quotes: [Quote]

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
        .navigationTitle("Storage & Backup")
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
            Text("This will remove cached images from completed captures and exports. Your quotes and book covers will not be affected.")
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
            Text("Backup")
                .sectionHeaderStyle()

            Button {
                showExportOptions = true
            } label: {
                Label("Export All Data", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .glassButton()

            Text("Export your entire library as a backup file that can be restored later.")
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
                Text("Clear cached images to free up storage space. Original images in your library will not be affected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var estimatedImageStorage: String {
        let imageCount = books.filter { $0.coverThumbnailData != nil }.count +
                         quotes.filter { $0.sourceImageData != nil }.count
        let estimatedMB = Double(imageCount) * 0.05
        if estimatedMB < 1 {
            return "< 1 MB"
        }
        return String(format: "%.1f MB", estimatedMB)
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

        let activeImagePaths = Set(
            (try? modelContext.fetch(FetchDescriptor<CaptureQueueItem>()))?
                .filter { $0.status == .pending || $0.status == .processing }
                .map { $0.imagePath } ?? []
        )

        for case let fileURL as URL in enumerator {
            if activeImagePaths.contains(fileURL.lastPathComponent) {
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

        for case let fileURL as URL in enumerator {
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

        try? fileManager.removeItem(at: capturesDir)

        return bytesCleared
    }
}
