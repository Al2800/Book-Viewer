import SwiftUI

struct ExportView: View {
    let quotes: [Quote]

    @State private var selectedFormat: ExportFormat = .markdown
    @State private var options = ExportOptions()
    @State private var isExporting = false
    @State private var resultMessage: String?
    @State private var resultFileURL: URL?
    @State private var resultFilename: String?
    @State private var showAlert = false

    private let exportService = ExportService()

    var body: some View {
        NavigationStack {
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
                    quotes: quotes,
                    format: selectedFormat,
                    options: options
                )

                if let fileURL = resultFileURL, let filename = resultFilename {
                    Section("Result") {
                        ShareLink(item: fileURL) {
                            Label("Share \(filename)", systemImage: "square.and.arrow.up")
                        }
                        .font(.subheadline)
                        Text("Saved to: \(fileURL.lastPathComponent)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Export \(quotes.count) Quotes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        Task { await performExport() }
                    }
                    .disabled(isExporting || quotes.isEmpty)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Export.exportButton)
                }
            }
            .overlay {
                if quotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Quotes", systemImage: "quote.opening")
                    } description: {
                        Text("Add quotes before exporting.")
                    }
                }
            }
        }
        .alert("Export", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private func performExport() async {
        guard !isExporting else { return }

        isExporting = true
        defer { isExporting = false }

        do {
            let result = try await exportService.export(
                quotes: quotes,
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
            showAlert = true
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
