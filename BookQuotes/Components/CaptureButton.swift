import SwiftUI

// MARK: - Capture Button

/// Large capture button for camera interfaces.
/// Features Stripe-level polish: ripple effect, haptics, smooth animations.
struct CaptureButton: View {
    /// Whether capture is in progress
    let isProcessing: Bool

    /// Action to perform on tap
    let action: () async -> Void

    /// Button size
    var size: CGFloat = 72

    /// Ring width
    var ringWidth: CGFloat = 4

    // MARK: - State

    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: CGFloat = 0.0
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            triggerCapture()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: size * 1.5, height: size * 1.5)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)

                Circle()
                    .stroke(Color.white, lineWidth: ringWidth)
                    .frame(width: size, height: size)
                    .shadow(color: .white.opacity(0.3), radius: isPressed ? 8 : 4)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(isProcessing ? 0.3 : 0.9)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size - ringWidth * 3, height: size - ringWidth * 3)
                    .scaleEffect(isPressed ? 0.85 : 1.0)

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.brand)
                        .scaleEffect(1.2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isProcessing {
                        withAnimation(.quickSpring) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.smoothSpring) {
                        isPressed = false
                    }
                }
        )
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.8)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.2)) {
                hasAppeared = true
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.captureButton)
        .accessibilityLabel("Capture")
        .accessibilityHint(isProcessing ? "Processing photo" : "Take photo")
    }

    // MARK: - Capture Action

    private func triggerCapture() {
        // A light press acknowledgement is appropriate here. Callers emit success only
        // after AVFoundation or the mock camera has actually returned an image.
        HapticManager.light()

        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.4)) {
                rippleScale = 1.8
                rippleOpacity = 0.6
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                rippleOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                rippleScale = 1.0
            }
        }

        Task { @MainActor in
            await action()
        }
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

    @State private var flashMode: CaptureFlashMode = .auto

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            if let onFlash = onFlash {
                Button {
                    HapticManager.light()
                    withAnimation(.snappy) {
                        flashMode = flashMode.next
                    }
                    onFlash()
                } label: {
                    Image(systemName: flashMode.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(CameraControlButtonStyle())
            } else {
                Spacer()
                    .frame(width: 44)
            }

            Spacer()

            CaptureButton(
                isProcessing: isProcessing,
                action: onCapture
            )

            Spacer()

            if let onFlip = onFlip {
                Button {
                    HapticManager.light()
                    onFlip()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(CameraControlButtonStyle())
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

// MARK: - Shared Camera Chrome

struct CaptureHeaderBar<Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String?
    let subtitleAccessibilityIdentifier: String?
    let onCancel: () -> Void
    let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        subtitleAccessibilityIdentifier: String? = nil,
        onCancel: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleAccessibilityIdentifier = subtitleAccessibilityIdentifier
        self.onCancel = onCancel
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            CameraIconButton(systemImage: "xmark", action: onCancel)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    if let subtitleAccessibilityIdentifier {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier(subtitleAccessibilityIdentifier)
                    } else {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 0)

            trailing
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .cameraChrome(cornerRadius: CornerRadius.xl)
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

extension CaptureHeaderBar where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        subtitleAccessibilityIdentifier: String? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            subtitleAccessibilityIdentifier: subtitleAccessibilityIdentifier,
            onCancel: onCancel
        ) {
            EmptyView()
        }
    }
}

/// Floating camera controls anchored to the bottom of the preview.
struct CaptureControlTray<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
        .background {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct CaptureStatusPill: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let systemImage: String
    let text: String
    var tint: Color = .white

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)

            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.black.opacity(0.55), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

struct CaptureFlashButton: View {
    let flashMode: CaptureFlashMode
    var isAvailable: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard isAvailable else { return }
            HapticManager.light()
            action()
        } label: {
            Image(systemName: flashMode.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.35), in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.4)
        .accessibilityIdentifier("capture_flash_button")
        .accessibilityLabel(flashMode.accessibilityLabel)
        .accessibilityHint(isAvailable ? "Cycles flash between automatic, on, and off" : "Flash is unavailable for this camera")
    }
}

struct CameraIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cancelButton)
    }
}

// MARK: - Camera Control Button Style

private struct CameraControlButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.white.opacity(0.2) : Color.clear)
                    .frame(width: 44, height: 44)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
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
