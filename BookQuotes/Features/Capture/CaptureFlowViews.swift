import SwiftUI

/// Cover capture flow wrapper - delegates to CoverCaptureView.
struct CoverCaptureFlowView: View {
    let onComplete: (Book) -> Void
    let onCancel: () -> Void

    var body: some View {
        CoverCaptureView(
            onComplete: onComplete,
            onCancel: onCancel
        )
    }
}

/// Quote capture flow wrapper - delegates to actual QuoteCaptureView.
struct QuoteCaptureFlowView: View {
    let book: Book?
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        if let book {
            QuoteCaptureView(
                book: book,
                onComplete: onComplete,
                onCancel: onCancel
            )
        } else {
            MissingSelectedBookView(
                title: "Capture Quotes",
                onCancel: onCancel
            )
        }
    }
}

/// Batch capture flow wrapper - delegates to BatchCaptureView then ExtractionReviewView.
struct BatchCaptureFlowView: View {
    let book: Book?
    let initialSession: CaptureSession?
    let onComplete: (CaptureSession) -> Void
    let onCancel: () -> Void

    @State private var capturedSession: CaptureSession?

    init(
        book: Book?,
        initialSession: CaptureSession? = nil,
        onComplete: @escaping (CaptureSession) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.book = book
        self.initialSession = initialSession
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        if let book {
            BatchCaptureView(
                book: book,
                session: initialSession,
                onComplete: { session in
                    capturedSession = session
                },
                onCancel: onCancel
            )
            .fullScreenCover(item: $capturedSession) { session in
                ExtractionReviewView(
                    session: session,
                    book: book,
                    onComplete: {
                        capturedSession = nil
                        onComplete(session)
                    }
                )
            }
        } else {
            MissingSelectedBookView(
                title: "Batch Capture",
                onCancel: onCancel
            )
        }
    }
}

private struct MissingSelectedBookView: View {
    let title: String
    let onCancel: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Book Selected", systemImage: "book.closed")
        } description: {
            Text("Please select a book first")
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
        }
    }
}
