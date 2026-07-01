import SwiftUI

extension BookISBNConfirmationSheet {
    /// Create a confirmation sheet directly from an ISBN scan result.
    /// Performs the lookup automatically and shows loading state.
    struct FromScanResult: View {
        let isbn: String
        let onConfirm: (Book) -> Void
        let onCancel: () -> Void
        private let lookup: BookISBNScanLookup

        @State private var metadata: BookMetadata?
        @State private var isLoading = true
        @State private var error: Error?

        init(
            isbn: String,
            lookup: BookISBNScanLookup = BookISBNScanLookup(),
            onConfirm: @escaping (Book) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.isbn = isbn
            self.lookup = lookup
            self.onConfirm = onConfirm
            self.onCancel = onCancel
        }

        var body: some View {
            Group {
                if isLoading {
                    loadingView
                } else if let metadata = metadata {
                    BookISBNConfirmationSheet(
                        metadata: metadata,
                        onConfirm: onConfirm,
                        onCancel: onCancel
                    )
                } else {
                    errorView
                }
            }
            .task {
                await lookupISBN()
            }
        }

        private var loadingView: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Looking up book...")
                    .font(.headline)
                Text(ISBNValidator.format(isbn))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var errorView: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Book Not Found")
                    .font(.headline)

                Text(error?.localizedDescription ?? "Unable to find book information for this ISBN.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)

                    Button("Try Again") {
                        Task {
                            await lookupISBN()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private func lookupISBN() async {
            isLoading = true
            error = nil

            switch await lookup.lookup(isbn: isbn) {
            case .found(let metadata):
                self.metadata = metadata
            case .failed(let error):
                self.error = error
            }

            isLoading = false
        }
    }
}
