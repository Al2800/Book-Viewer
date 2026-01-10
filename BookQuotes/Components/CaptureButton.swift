import SwiftUI

// MARK: - Capture Button

/// Large capture button for camera interfaces.
/// Shows processing state and animates on press.
struct CaptureButton: View {
    /// Whether capture is in progress
    let isProcessing: Bool

    /// Action to perform on tap
    let action: () async -> Void

    /// Button size
    var size: CGFloat = 72

    /// Ring width
    var ringWidth: CGFloat = 4

    @State private var isPressed = false

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: ringWidth)
                    .frame(width: size, height: size)

                // Inner circle
                Circle()
                    .fill(isProcessing ? Color.white.opacity(0.3) : Color.white)
                    .frame(width: size - ringWidth * 3, height: size - ringWidth * 3)
                    .scaleEffect(isPressed ? 0.85 : 1.0)

                // Processing indicator
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.brand)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isProcessing {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel("Capture")
        .accessibilityHint(isProcessing ? "Processing photo" : "Take photo")
    }
}

// MARK: - Small Capture Button

/// Smaller version of capture button for compact UIs.
struct SmallCaptureButton: View {
    let isProcessing: Bool
    let action: () async -> Void

    var body: some View {
        CaptureButton(
            isProcessing: isProcessing,
            action: action,
            size: 56,
            ringWidth: 3
        )
    }
}

// MARK: - Capture Button with Label

/// Capture button with text label below.
struct LabeledCaptureButton: View {
    let label: String
    let isProcessing: Bool
    let action: () async -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            CaptureButton(
                isProcessing: isProcessing,
                action: action
            )

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Capture Controls Bar

/// Bottom bar with capture button and secondary actions.
struct CaptureControlsBar: View {
    let isProcessing: Bool
    let onCapture: () async -> Void
    let onFlash: (() -> Void)?
    let onFlip: (() -> Void)?

    @State private var flashMode: FlashMode = .auto

    enum FlashMode: CaseIterable {
        case auto, on, off

        var icon: String {
            switch self {
            case .auto: return "bolt.badge.automatic"
            case .on: return "bolt.fill"
            case .off: return "bolt.slash"
            }
        }

        var next: FlashMode {
            switch self {
            case .auto: return .on
            case .on: return .off
            case .off: return .auto
            }
        }
    }

    var body: some View {
        HStack {
            // Flash toggle
            if let onFlash = onFlash {
                Button {
                    flashMode = flashMode.next
                    onFlash()
                } label: {
                    Image(systemName: flashMode.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }

            Spacer()

            // Main capture button
            CaptureButton(
                isProcessing: isProcessing,
                action: onCapture
            )

            Spacer()

            // Camera flip
            if let onFlip = onFlip {
                Button {
                    onFlip()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(.ultraThinMaterial.opacity(0.5))
    }
}

// MARK: - Preview

#Preview("Capture Button") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: Spacing.xl) {
            CaptureButton(isProcessing: false) {
                print("Captured")
            }

            CaptureButton(isProcessing: true) {
                print("Captured")
            }

            SmallCaptureButton(isProcessing: false) {
                print("Captured")
            }

            LabeledCaptureButton(
                label: "Take Photo",
                isProcessing: false
            ) {
                print("Captured")
            }
        }
    }
}

#Preview("Capture Controls Bar") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            CaptureControlsBar(
                isProcessing: false,
                onCapture: { print("Capture") },
                onFlash: { print("Flash") },
                onFlip: { print("Flip") }
            )
        }
    }
}
