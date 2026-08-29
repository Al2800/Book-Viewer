import AVFoundation
import SwiftUI

// MARK: - Camera Preview View

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer.
/// Displays the live camera feed from a CameraService.
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    var framingProfile: CameraFramingProfile = .quotePage

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.cameraService = cameraService
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Configure preview layer from camera service
        if uiView.previewLayer == nil {
            if let layer = cameraService.createPreviewLayer(framingProfile: framingProfile) {
                uiView.previewLayer = layer
            }
        } else {
            uiView.previewLayer?.videoGravity = framingProfile.previewVideoGravity
        }
    }

    /// UIView subclass that hosts the AVCaptureVideoPreviewLayer.
    final class CameraPreviewUIView: UIView {
        weak var cameraService: CameraService?

        var previewLayer: AVCaptureVideoPreviewLayer? {
            didSet {
                oldValue?.removeFromSuperlayer()
                if let layer = previewLayer {
                    layer.frame = bounds
                    self.layer.insertSublayer(layer, at: 0)
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
            if bounds.width > 0, bounds.height > 0 {
                CameraCaptureConfiguration.applyPortraitRotation(
                    to: previewLayer?.connection
                )
                cameraService?.updatePreviewSize(bounds.size)
            }
        }
    }
}

// MARK: - Live AR Mark Framing Overlay

/// Renders glowing amber highlight bounding boxes over detected passages in the live camera feed.
struct LiveARMarkOverlay: View {
    let boundingBoxes: [CGRect]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ForEach(Array(boundingBoxes.enumerated()), id: \.offset) { _, normBox in
                let rect = VisionBoundingBoxTransformer.scaleNormalizedRect(normBox, to: size)
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(Color.gildedAccent.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.gildedAccent.opacity(0.85),
                                        Color.goldFoil.opacity(0.65)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.gildedAccent.opacity(0.5), radius: 4)
                    .frame(width: max(rect.width, 24), height: max(rect.height, 12))
                    .position(x: rect.midX, y: rect.midY)
                    .animation(.easeInOut(duration: 0.15), value: normBox)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Camera Preview with Focus

/// Camera preview with tap-to-focus capability and live AR mark framing overlay.
struct CameraPreviewViewWithFocus: View {
    let cameraService: CameraService
    var framingProfile: CameraFramingProfile = .quotePage

    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView(cameraService: cameraService, framingProfile: framingProfile)

                // Live AR mark framing overlay
                LiveARMarkOverlay(boundingBoxes: cameraService.detectedBoundingBoxes)
            }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let point = value.location
                            // Convert to normalized coordinates (0-1)
                            let normalizedPoint = CGPoint(
                                x: point.x / geometry.size.width,
                                y: point.y / geometry.size.height
                            )

                            cameraService.focus(at: normalizedPoint)

                            // Show focus indicator
                            focusPoint = point
                            withAnimation(.easeIn(duration: 0.1)) {
                                showFocusIndicator = true
                            }

                            // Hide after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showFocusIndicator = false
                                }
                            }

                            HapticManager.light()
                        }
                )
                .overlay {
                    if showFocusIndicator, let point = focusPoint {
                        FocusIndicatorView()
                            .position(point)
                    }
                }
        }
    }
}

// MARK: - Focus Indicator

/// Visual indicator for tap-to-focus location.
private struct FocusIndicatorView: View {
    @State private var scale: CGFloat = 1.2

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 70, height: 70)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - Preview

#Preview("Camera Preview View") {
    // Note: Preview won't show actual camera feed
    ZStack {
        Color.black
        Text("Camera Preview")
            .foregroundStyle(.white)
    }
    .ignoresSafeArea()
}
