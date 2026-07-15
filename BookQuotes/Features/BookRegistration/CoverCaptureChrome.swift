import SwiftUI

struct CoverBarcodeScanOverlay: View {
    var body: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.brand, lineWidth: 3)
                .frame(width: 280, height: 100)
                .overlay {
                    CoverScanLineView()
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.barcodeScanFrame)

            Text("Align barcode within frame")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.top, Spacing.md)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.barcodeInstruction)

            Spacer()
        }
    }
}

struct CoverProcessingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }
}

struct CoverCaptureModeSwitcher: View {
    @Binding var captureMode: CoverCaptureView.CaptureMode
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            CaptureHeaderBar(
                title: "Add Book",
                subtitle: captureMode == .photo ? "Scan cover or ISBN" : "Scan the ISBN barcode",
                onCancel: onCancel
            )

            Picker("Mode", selection: $captureMode) {
                Label("Photo", systemImage: "camera.fill").tag(CoverCaptureView.CaptureMode.photo)
                Label("Barcode", systemImage: "barcode.viewfinder").tag(CoverCaptureView.CaptureMode.barcode)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.modePicker)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .cameraChrome(cornerRadius: CornerRadius.xl)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
}

struct CoverCaptureBottomControls: View {
    let captureMode: CoverCaptureView.CaptureMode
    let isProcessing: Bool
    let isCapturing: Bool
    let isSessionRunning: Bool
    let showsTestCoverButton: Bool
    let onCapturePhoto: () -> Void
    let onUseTestCover: () -> Void
    let onManualEntry: () -> Void

    var body: some View {
        CaptureControlTray {
            if let statusPill {
                statusPill
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if captureMode == .photo && !isProcessing {
                CaptureButton(isProcessing: isProcessing || isCapturing) {
                    onCapturePhoto()
                }
                .disabled(!isSessionRunning || isCapturing)

                if showsTestCoverButton {
                    Button("Use Test Cover") {
                        onUseTestCover()
                    }
                    .buttonStyle(.primaryCompact)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testCoverButton)
                }
            }

            if !isProcessing {
                Button {
                    onManualEntry()
                } label: {
                    Text(captureMode == .photo ? "Enter details manually" : "Enter ISBN manually")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .glassButton()
                .contentShape(Rectangle())
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.manualEntryButton)
            }
        }
    }

    private var statusPill: CaptureStatusPill? {
        if isProcessing {
            let text = captureMode == .photo ? "Reading cover..." : "Looking up ISBN..."
            return CaptureStatusPill(systemImage: "viewfinder", text: text)
        }

        switch captureMode {
        case .photo:
            return nil
        case .barcode:
            return CaptureStatusPill(
                systemImage: "barcode.viewfinder",
                text: "Hold the barcode steady inside the scanner"
            )
        }
    }
}

private struct CoverScanLineView: View {
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
