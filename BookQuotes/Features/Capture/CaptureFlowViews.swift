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
    var hidesHeaderBar: Bool = false
    var hidesTabBar: Bool = true
    let onComplete: () -> Void
    let onCancel: () -> Void
    var onChooseBook: (() -> Void)? = nil

    var body: some View {
        if let book {
            QuoteCaptureView(
                book: book,
                hidesHeaderBar: hidesHeaderBar,
                hidesTabBar: hidesTabBar,
                onComplete: onComplete,
                onCancel: onCancel
            )
        } else {
            MissingSelectedBookView(
                title: "Capture Quotes",
                onChooseBook: onChooseBook,
                onCancel: onCancel
            )
        }
    }
}

/// Batch capture flow wrapper - delegates to BatchCaptureView then ExtractionReviewView.
struct BatchCaptureFlowView: View {
    let book: Book?
    let initialSession: CaptureSession?
    var hidesHeaderBar: Bool = false
    var hidesTabBar: Bool = true
    let onComplete: (CaptureSession) -> Void
    let onCancel: () -> Void
    var onChooseBook: (() -> Void)? = nil

    @State private var capturedSession: CaptureSession?

    init(
        book: Book?,
        initialSession: CaptureSession? = nil,
        hidesHeaderBar: Bool = false,
        hidesTabBar: Bool = true,
        onComplete: @escaping (CaptureSession) -> Void,
        onCancel: @escaping () -> Void,
        onChooseBook: (() -> Void)? = nil
    ) {
        self.book = book
        self.initialSession = initialSession
        self.hidesHeaderBar = hidesHeaderBar
        self.hidesTabBar = hidesTabBar
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onChooseBook = onChooseBook
    }

    var body: some View {
        if let book {
            BatchCaptureView(
                book: book,
                session: initialSession,
                hidesHeaderBar: hidesHeaderBar,
                hidesTabBar: hidesTabBar,
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
                onChooseBook: onChooseBook,
                onCancel: onCancel
            )
        }
    }
}

private struct MissingSelectedBookView: View {
    let title: String
    var onChooseBook: (() -> Void)? = nil
    let onCancel: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Book Selected", systemImage: "book.closed")
        } description: {
            Text("Please choose an active book or scan a new one to start capturing quotes.")
        } actions: {
            if let onChooseBook {
                Button {
                    HapticManager.selection()
                    onChooseBook()
                } label: {
                    Text("Select Active Book")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.brand)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", action: onCancel)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cancelButton)
            }
        }
    }
}
