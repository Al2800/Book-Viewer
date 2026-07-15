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

struct CoverCaptureHeader: View {
    let onCancel: () -> Void

    var body: some View {
        CaptureHeaderBar(
            title: "Add Book",
            subtitle: "Scan the ISBN barcode",
            onCancel: onCancel
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
}

struct CoverCaptureBottomControls: View {
    let isProcessing: Bool
    let showsTestISBNButton: Bool
    let onUseTestISBN: () -> Void
    let onManualEntry: () -> Void

    var body: some View {
        CaptureControlTray {
            statusPill
                .frame(maxWidth: .infinity, alignment: .center)

            if !isProcessing {
                if showsTestISBNButton {
                    Button("Use Test ISBN") {
                        onUseTestISBN()
                    }
                    .buttonStyle(.primaryCompact)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testCoverButton)
                }

                Button {
                    onManualEntry()
                } label: {
                    Text("Enter book details manually")
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

    private var statusPill: CaptureStatusPill {
        if isProcessing {
            return CaptureStatusPill(systemImage: "viewfinder", text: "Looking up ISBN...")
        }

        return CaptureStatusPill(
            systemImage: "barcode.viewfinder",
            text: "Hold the barcode steady inside the scanner"
        )
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
