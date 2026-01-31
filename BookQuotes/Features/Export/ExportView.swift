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
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                Form {
                    Section("Format") {
                        Picker("Export Format", selection: $selectedFormat) {
                            ForEach(ExportFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.inline)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Export.formatPicker)
                    }

                    ExportOptionsView(options: $options)

                    ExportPreviewView(
                        quotes: exportQuotes,
                        format: selectedFormat,
                        options: options
                    )

                    if let fileURL = resultFileURL, let filename = resultFilename {
                        Section("Result") {
                            Text("Your export is ready. Use Save to Files to choose a destination or share it with another app.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let resultMessage {
                                Text(resultMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                showFileExporter = true
                            } label: {
                                Label("Save to Files", systemImage: "folder")
                            }
                            .font(.subheadline)

                            Button {
                                showShareSheet = true
                            } label: {
                                Label("Share \(filename)", systemImage: "square.and.arrow.up")
                            }
                            .font(.subheadline)

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
                .scrollContentBackground(.hidden)
                .background(Color.backgroundPrimary)
            }
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
                showFileExporter = true
            }
            Button("Share") {
                showShareSheet = true
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

    private var exportQuotes: [Quote] {
        guard let book = book else { return quotes }
        return quotes.filter { $0.book?.id == book.id }
    }

    private func performExport() async {
        guard !isExporting else { return }

        isExporting = true
        defer { isExporting = false }

        do {
            let result = try await exportService.export(
                quotes: exportQuotes,
                format: selectedFormat,
                options: options
            )

            handleResult(result)
        } catch {
            resultFileURL = nil
            resultFilename = nil
            resultMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func handleResult(_ result: ExportResult) {
        switch result {
        case let .file(url, filename):
            resultFileURL = url
            resultFilename = filename
            resultMessage = "Exported \(filename)."
            showExportActions = true
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
