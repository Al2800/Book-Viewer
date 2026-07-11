import SwiftUI
import SwiftData

// MARK: - Capture Tab Root View

/// Main orchestrator for the capture tab.
/// Handles permission checking and mode switching between cover and quote capture.
struct CaptureTabRootView: View {
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureFlow = CaptureFlowState()
    @State private var selectedBook: Book?
    var onBookCreated: ((Book) -> Void)?
    var onQuotesSaved: ((Book) -> Void)?
    @State private var showCoaching = false
    @AppStorage("hasCompletedCaptureCoaching") private var hasCompletedCoaching = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            // UI tests: bypass the camera permission gate so App Store media capture is deterministic.
            if UITestConfiguration.isUITesting || cameraPermission.isAuthorized {
                authorizedContent
            } else {
                CameraPermissionView()
            }
        }
        .environment(cameraPermission)
        .onAppear {
            cameraPermission.checkStatus()
            if UITestConfiguration.isUITesting {
                hasCompletedCoaching = true
                showCoaching = false
                return
            }
            // Show coaching for first-time users
            if cameraPermission.isAuthorized && !hasCompletedCoaching {
                showCoaching = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cameraPermission.onAppBecameActive()
            }
        }
        .onChange(of: cameraPermission.isAuthorized) { _, isAuthorized in
            // Show coaching after permission granted
            if isAuthorized && !hasCompletedCoaching {
                showCoaching = true
            }
        }
        .sheet(isPresented: $showCoaching) {
            FirstCaptureCoachingView(isPresented: $showCoaching)
                .presentationDetents([.large])
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Authorized Content

    @ViewBuilder
    private var authorizedContent: some View {
        NavigationStack {
            captureContent
        }
    }

    @ViewBuilder
    private var captureContent: some View {
        switch captureFlow.mode {
        case .selection:
            CaptureModeSelectionView(
                onSelectCoverCapture: {
                    HapticManager.light()
                    handleCaptureFlowEvent(.selectCoverCapture)
                },
                onSelectQuoteCapture: {
                    HapticManager.light()
                    handleCaptureFlowEvent(.selectQuoteCapture)
                },
                onSelectBatchCapture: {
                    HapticManager.light()
                    handleCaptureFlowEvent(.selectBatchCapture)
                }
            )

        case .bookSelection:
            BookSelectionForCaptureView(
                onSelectBook: { book in
                    HapticManager.medium()
                    selectedBook = book
                    handleCaptureFlowEvent(.selectBookForQuoteCapture)
                },
                onAddNewBook: {
                    handleCaptureFlowEvent(.addNewBook)
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelBookSelection)
                }
            )

        case .bookSelectionForBatch:
            BookSelectionForCaptureView(
                onSelectBook: { book in
                    HapticManager.medium()
                    selectedBook = book
                    handleCaptureFlowEvent(.selectBookForBatchCapture)
                },
                onAddNewBook: {
                    handleCaptureFlowEvent(.addNewBook)
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelBookSelection)
                }
            )

        case .coverCapture:
            CoverCaptureFlowView(
                onComplete: { book in
                    handleCaptureFlowEvent(.completeCoverCapture)
                    onBookCreated?(book)
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelCoverCapture)
                }
            )

        case .quoteCapture:
            QuoteCaptureFlowView(
                book: selectedBook,
                onComplete: {
                    let completedBook = selectedBook
                    handleCaptureFlowEvent(.completeQuoteCapture)
                    if let completedBook {
                        onQuotesSaved?(completedBook)
                    }
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelQuoteCapture)
                }
            )
            .id(captureFlow.quoteCaptureFlowID)

        case .batchCapture:
            BatchCaptureFlowView(
                book: selectedBook,
                onComplete: { _ in
                    let completedBook = selectedBook
                    handleCaptureFlowEvent(.completeBatchCapture)
                    if let completedBook {
                        onQuotesSaved?(completedBook)
                    }
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelBatchCapture)
                }
            )
            .id(captureFlow.batchCaptureFlowID)
        }
    }

    private func handleCaptureFlowEvent(_ event: CaptureFlowState.Event) {
        let command = captureFlow.handle(event)
        if command.clearsSelectedBook {
            selectedBook = nil
        }
    }
}

// MARK: - Preview

#Preview("Capture Tab Root") {
    Group {
        if let container = ModelContainer.preview {
            CaptureTabRootView()
                .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
