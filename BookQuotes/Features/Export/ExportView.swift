import SwiftUI
import SwiftData

struct ExportView: View {
    let book: Book?

    @Query(sort: [SortDescriptor(\Quote.captureDate, order: .reverse)])
    private var quotes: [Quote]

    @State private var selectedFormat: ExportFormat = .markdown
    @State private var options = ExportOptions()
    @State private var isExporting = false
    @State private var resultMessage: String?
    @State private var resultFileURL: URL?
    @State private var resultFilename: String?
    @State private var showAlert = false
    @State private var showShareSheet = false
    @State private var showFileExporter = false
    @State private var showExportActions = false

    private let exportService = ExportService()

    init(book: Book? = nil) {
        self.book = book
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    SectionCard(title: "Format") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Picker("Export Format", selection: $selectedFormat) {
                                ForEach(ExportFormat.allCases) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                            .fieldChrome()
                            .accessibilityIdentifier(AccessibilityIdentifiers.Export.formatPicker)

                            Text(formatDescription)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    SectionCard(title: "Options") {
                        ExportOptionsView(options: $options)
                    }

                    SectionCard(title: "Preview") {
                        ExportPreviewView(
                            quotes: exportQuotes,
                            format: selectedFormat,
                            options: options
                        )
                    }

                    if let fileURL = resultFileURL, let filename = resultFilename {
                        SectionCard(title: "Result") {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Your export is ready. Use Save to Files to choose a destination or share it with another app.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let resultMessage {
                                    Text(resultMessage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                VStack(spacing: Spacing.sm) {
                                    Button {
                                        Task { await prepareFileExporter() }
                                    } label: {
                                        Label("Save to Files", systemImage: "folder")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .glassButton()

                                    Button {
                                        Task { await prepareShareSheet() }
                                    } label: {
                                        Label("Share \(filename)", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.secondary)
                                }

                                Text("Saved temporarily at:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(fileURL.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Export \(exportQuotes.count) Quotes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        Task { await performExport() }
                    }
                    .disabled(isExporting || exportQuotes.isEmpty)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Export.exportButton)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay {
                if exportQuotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Quotes", systemImage: "quote.opening")
                    } description: {
                        Text("Add quotes before exporting.")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = resultFileURL {
                FileShareSheet(activityItems: [fileURL])
            }
        }
        .sheet(isPresented: $showFileExporter) {
            if let fileURL = resultFileURL {
                FileExportSheet(urls: [fileURL])
            }
        }
        .confirmationDialog("Export Ready", isPresented: $showExportActions, titleVisibility: .visible) {
            Button("Save to Files") {
                Task { await prepareFileExporter() }
            }
            Button("Share") {
                Task { await prepareShareSheet() }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Choose where to save or share your export.")
        }
        .alert("Export", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private var formatDescription: String {
        switch selectedFormat {
        case .markdown:
            return "Great for notes apps and Markdown editors."
        case .plainText:
            return "Simple text format for universal sharing."
        case .json:
            return "Structured export for automation or backups."
        case .notion:
            return "Send quotes to a connected Notion database."
        case .obsidian:
            return "Markdown bundle optimized for Obsidian vaults."
        }
    }

    private var exportQuotes: [Quote] {
        guard let book = book else { return quotes }
        return quotes.filter { $0.book?.id == book.id }
    }

    private func performExport() async {
        await performExport(showActions: true, onFileReady: nil)
    }

    private func performExport(
        showActions: Bool,
        onFileReady: (() -> Void)?
    ) async {
        guard !isExporting else { return }

        isExporting = true
        defer { isExporting = false }

        do {
            let result = try await exportService.export(
                quotes: exportQuotes,
                format: selectedFormat,
                options: options
            )

            handleResult(result, showActions: showActions, onFileReady: onFileReady)
        } catch {
            resultFileURL = nil
            resultFilename = nil
            resultMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func handleResult(
        _ result: ExportResult,
        showActions: Bool,
        onFileReady: (() -> Void)?
    ) {
        switch result {
        case let .file(url, filename):
            resultFileURL = url
            resultFilename = filename
            resultMessage = "Exported \(filename)."
            if showActions {
                showExportActions = true
            } else {
                onFileReady?()
            }
        case let .apiSuccess(message):
            resultFileURL = nil
            resultFilename = nil
            resultMessage = message
            showAlert = true
        case let .apiError(message):
            resultFileURL = nil
            resultFilename = nil
            resultMessage = message
            showAlert = true
        }
    }

    private func prepareFileExporter() async {
        let available = ensureExportFileAvailable()
        if available {
            showFileExporter = true
            return
        }

        await performExport(showActions: false) {
            showFileExporter = true
        }
    }

    private func prepareShareSheet() async {
        let available = ensureExportFileAvailable()
        if available {
            showShareSheet = true
            return
        }

        await performExport(showActions: false) {
            showShareSheet = true
        }
    }

    private func ensureExportFileAvailable() -> Bool {
        guard let url = resultFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

// MARK: - File Share Sheet

/// Share sheet for exported files using UIActivityViewController.
struct FileShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - File Export Sheet

/// Presents the iOS Files export picker for one or more URLs.
struct FileExportSheet: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: urls)
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
