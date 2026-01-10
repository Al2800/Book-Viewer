import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Cover Capture View

/// Camera-based view for capturing book covers or scanning ISBN barcodes.
/// Supports Photo mode for AI-based cover extraction and Barcode mode for ISBN lookup.
struct CoverCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Completion handler with the created book
    var onComplete: ((Book) -> Void)?

    /// Handler when user cancels
    var onCancel: (() -> Void)?

    // MARK: - State

    @State private var cameraService = CameraService()
    @State private var isbnScanner = ISBNScanner()
    @State private var captureMode: CaptureMode = .photo
    @State private var captureState: CaptureState = .previewing
    @State private var capturedImage: UIImage?
    @State private var extractedMetadata: BookMetadata?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                cameraContent

                // Mode-specific overlay
                captureOverlay

                // Processing indicator
                if isProcessing {
                    processingOverlay
                }

                // Capture controls
                controlsOverlay
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(item: $extractedMetadata) { metadata in
                BookEditView(mode: .createFromMetadata(metadata)) { book in
                    onComplete?(book)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupCamera()
            }
            .onDisappear {
                cleanup()
            }
            .onChange(of: captureMode) { _, newMode in
                handleModeChange(newMode)
            }
        }
    }

    // MARK: - Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        if cameraService.isAuthorized {
            CameraPreviewView(cameraService: cameraService)
                .ignoresSafeArea()
        } else {
            CameraPermissionView()
        }
    }

    // MARK: - Capture Overlay

    @ViewBuilder
    private var captureOverlay: some View {
        switch captureMode {
        case .photo:
            photoCaptureOverlay
        case .barcode:
            barcodeScanOverlay
        }
    }

    private var photoCaptureOverlay: some View {
        VStack {
            Spacer()

            // Guide frame
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 250, height: 375) // Book cover aspect ratio
                .overlay {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "book.closed")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Position book cover")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

            Spacer()
        }
    }

    private var barcodeScanOverlay: some View {
        VStack {
            Spacer()

            // Barcode scanner area
            VStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.brand, lineWidth: 3)
                    .frame(width: 280, height: 100)
                    .overlay {
                        // Scan line animation
                        ScanLineView()
                    }

                Text("Align barcode within frame")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(processingMessage)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    private var processingMessage: String {
        switch captureMode {
        case .photo:
            return "Analyzing cover..."
        case .barcode:
            return "Looking up book..."
        }
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack {
            // Mode switcher at top
            Picker("Mode", selection: $captureMode) {
                Label("Photo", systemImage: "camera.fill").tag(CaptureMode.photo)
                Label("Barcode", systemImage: "barcode.viewfinder").tag(CaptureMode.barcode)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)

            Spacer()

            // Capture button (photo mode only)
            if captureMode == .photo && !isProcessing {
                HStack {
                    Spacer()

                    Button {
                        capturePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 72, height: 72)

                            Circle()
                                .stroke(.white.opacity(0.5), lineWidth: 4)
                                .frame(width: 82, height: 82)
                        }
                    }
                    .disabled(!cameraService.isSessionRunning)

                    Spacer()
                }
                .padding(.bottom, Spacing.xl)
            }

            // Manual entry link
            if !isProcessing {
                Button {
                    showManualEntry()
                } label: {
                    Text("Enter manually")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.bottom, Spacing.lg)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                onCancel?()
                dismiss()
            }
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        Task {
            let authorized = await cameraService.requestAuthorization()
            guard authorized else { return }

            do {
                try cameraService.setupSession()
                cameraService.startSession()

                // Set up barcode scanning callback
                setupBarcodeScanning()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func setupBarcodeScanning() {
        isbnScanner.onBarcodeDetected = { isbn in
            guard captureMode == .barcode, !isProcessing else { return }
            handleBarcodeDetected(isbn)
        }
    }

    private func handleModeChange(_ mode: CaptureMode) {
        switch mode {
        case .photo:
            isbnScanner.stopScanning()
        case .barcode:
            if let session = cameraService.captureSession {
                isbnScanner.startScanning(on: session)
            }
        }
    }

    private func cleanup() {
        isbnScanner.stopScanning()
        cameraService.cleanup()
    }

    // MARK: - Capture Actions

    private func capturePhoto() {
        Task {
            isProcessing = true
            HapticManager.medium()

            do {
                let image = try await cameraService.capturePhoto()
                capturedImage = image

                // Process cover (placeholder - would call GeminiService)
                let metadata = await extractCoverMetadata(from: image)
                extractedMetadata = metadata

                isProcessing = false

            } catch {
                isProcessing = false
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    private func handleBarcodeDetected(_ isbn: String) {
        Task {
            isProcessing = true
            HapticManager.success()

            do {
                // Look up ISBN
                let metadata = try await lookupISBN(isbn)
                extractedMetadata = metadata
                isProcessing = false

            } catch {
                isProcessing = false
                errorMessage = "Could not find book: \(error.localizedDescription)"
                showError = true
                HapticManager.error()
            }
        }
    }

    private func showManualEntry() {
        // Create empty metadata to trigger manual entry
        extractedMetadata = BookMetadata(title: "", authors: [])
    }

    // MARK: - Extraction (Placeholders)

    private func extractCoverMetadata(from image: UIImage) async -> BookMetadata {
        // TODO: Replace with actual GeminiService call when available
        // For now, return empty metadata for manual entry
        var metadata = BookMetadata(title: "", authors: [])
        metadata.coverImageData = image.jpegData(compressionQuality: 0.8)
        return metadata
    }

    private func lookupISBN(_ isbn: String) async throws -> BookMetadata {
        let service = ISBNLookupService()
        return try await service.lookup(isbn: isbn)
    }
}

// MARK: - Capture Mode

extension CoverCaptureView {
    enum CaptureMode: String, CaseIterable {
        case photo
        case barcode
    }

    enum CaptureState {
        case previewing
        case processing
        case reviewing
    }
}

// MARK: - Scan Line View

/// Animated scan line for barcode mode
struct ScanLineView: View {
    @State private var offset: CGFloat = -30

    var body: some View {
        Rectangle()
            .fill(Color.brand)
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 30
                }
            }
    }
}

// MARK: - ISBNLookupService Extension

extension ISBNLookupService {
    /// Look up book metadata by ISBN
    func lookup(isbn: String) async throws -> BookMetadata {
        let result = try await lookupBook(isbn: isbn)

        switch result {
        case .googleBooks(let item):
            return BookMetadata(
                title: item.volumeInfo.title,
                authors: item.volumeInfo.authors ?? [],
                subtitle: item.volumeInfo.subtitle,
                isbn: isbn,
                publisher: item.volumeInfo.publisher,
                publishYear: extractYear(from: item.volumeInfo.publishedDate),
                genre: item.volumeInfo.categories?.first,
                pageCount: item.volumeInfo.pageCount,
                coverImageURL: URL(string: item.volumeInfo.imageLinks?.thumbnail ?? "")
            )

        case .openLibrary(let work, let edition):
            return BookMetadata(
                title: edition.title ?? work.title,
                authors: work.authorNames ?? [],
                isbn: isbn,
                publisher: edition.publishers?.first,
                publishYear: extractYear(from: edition.publishDate),
                pageCount: edition.numberOfPages
            )
        }
    }

    private func extractYear(from dateString: String?) -> Int? {
        guard let dateString = dateString else { return nil }
        // Try to extract 4-digit year
        let yearPattern = /\d{4}/
        if let match = dateString.firstMatch(of: yearPattern) {
            return Int(match.output)
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    CoverCaptureView()
        .modelContainer(for: Book.self, inMemory: true)
}
