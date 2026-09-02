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
                onSwitchBook: onChooseBook,
                onComplete: { session in
                    capturedSession = session
                },
                onCancel: onCancel
            )
            .sheet(item: $capturedSession) { session in
                ExtractionReviewView(
                    session: session,
                    book: book,
                    onComplete: {
                        capturedSession = nil
                        onComplete(session)
                    }
                )
                .presentationDetents([.large])
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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.62))
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white.opacity(0.22), lineWidth: Stroke.hairline.width)
                                    }
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close capture")
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cancelButton)

                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient.foilAccent.opacity(0.15))
                        .frame(width: 88, height: 88)

                    Image(systemName: "book.closed")
                        .font(.largeTitle.weight(.light))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(Color.gildedAccent)
                }

                VStack(spacing: Spacing.sm) {
                    Text("No Book Selected")
                        .font(.serifTitleLarge)
                        .foregroundStyle(.white)

                    Text("Please choose an active book or scan a new one to start capturing quotes.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                if let onChooseBook {
                    Button {
                        HapticManager.selection()
                        onChooseBook()
                    } label: {
                        Text("Select Active Book")
                            .font(.uiLabel)
                            .foregroundStyle(Color.darkLinen)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(LinearGradient.foilAccent)
                            .clipShape(Capsule())
                            .shadow(color: Color.gildedAccent.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }

                Spacer()
            }
            .padding()
        }
        .accessibilityLabel(title)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

enum QuietCaptureMode {
    case singlePage
    case batch
}

struct CaptureModeMenuButton: View {
    let currentMode: QuietCaptureMode
    var draftCount: Int = 0
    var onSelectSingle: () -> Void = {}
    var onSelectBatch: () -> Void = {}
    var onShowDrafts: (() -> Void)? = nil

    var body: some View {
        Menu {
            Button {
                HapticManager.selection()
                onSelectSingle()
            } label: {
                Label("Single Page", systemImage: currentMode == .singlePage ? "checkmark" : "doc")
            }
            .disabled(currentMode == .singlePage)

            Button {
                HapticManager.selection()
                onSelectBatch()
            } label: {
                Label("Batch Mode", systemImage: currentMode == .batch ? "checkmark" : "square.stack.3d.up")
            }
            .disabled(currentMode == .batch)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.modeSelectBatch)

            if let onShowDrafts, draftCount > 0 {
                Divider()

                Button {
                    HapticManager.light()
                    onShowDrafts()
                } label: {
                    Label("Saved Drafts (\(draftCount))", systemImage: "tray.full")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.savedDraftsButton)
            }
        } label: {
            Image(systemName: "camera.badge.ellipsis")
                .font(.uiLabel)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.62))
                        .overlay {
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.35))
                        }
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: Stroke.hairline.width)
                        }
                )
                .shadow(color: Color.black.opacity(0.3), radius: 6, y: 3)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.modeMenu)
        .accessibilityLabel(currentMode == .batch ? "Capture mode, Batch Mode" : "Capture mode, Single Page")
        .accessibilityHint(currentMode == .batch ? "Choose Single Page" : "Choose Batch Mode or open saved drafts")
    }
}
