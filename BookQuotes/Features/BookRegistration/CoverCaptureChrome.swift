import SwiftUI

struct AppStoreISBNScanPreview: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let lineWidths: [CGFloat] = [0.82, 0.94, 0.76, 0.88, 0.68]
    private let barWidths: [CGFloat] = [3, 7, 4, 9, 3, 5, 8, 4, 6, 3, 9, 5, 3, 7, 4, 8, 3]

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.14, blue: 0.16)

            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.95, green: 0.91, blue: 0.82))
                .overlay {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("THE QUIET MARGIN")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color(red: 0.18, green: 0.20, blue: 0.23))

                        Text("ROWAN VALE")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.65, green: 0.25, blue: 0.18))

                        ForEach(Array(lineWidths.enumerated()), id: \.offset) { _, width in
                            Capsule()
                                .fill(Color.black.opacity(0.25))
                                .frame(maxWidth: 420 * width, minHeight: 4, maxHeight: 4)
                        }

                        Spacer()
                            .frame(height: horizontalSizeClass == .compact ? 0 : 110)

                        HStack(spacing: 3) {
                            ForEach(Array(barWidths.enumerated()), id: \.offset) { _, width in
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: width, height: 72)
                            }
                        }
                        .padding(10)
                        .background(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                        Text("9 780001 234567")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Spacer()
                    }
                    .padding(30)
                }
                .aspectRatio(0.72, contentMode: .fit)
                .frame(maxWidth: 620)
                .padding(.horizontal, 42)
                .rotationEffect(.degrees(-2))
                .shadow(color: .black.opacity(0.35), radius: 26, y: 18)
        }
    }
}

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
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(.black.opacity(0.62), in: Capsule())
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
