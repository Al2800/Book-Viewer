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

/// Renders glowing amber highlight bounding boxes over detected text regions in the live camera feed.
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

/// Camera preview with tap-to-focus capability and live text framing overlay.
struct CameraPreviewViewWithFocus: View {
    let cameraService: CameraService
    var framingProfile: CameraFramingProfile = .quotePage

    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false

    var body: some View {
        GeometryReader { _ in
            ZStack {
                CameraPreviewView(cameraService: cameraService, framingProfile: framingProfile)

                LiveARMarkOverlay(boundingBoxes: cameraService.detectedBoundingBoxes)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let point = value.location
                        cameraService.focus(atPreviewPoint: point)

                        focusPoint = point
                        withAnimation(.easeIn(duration: 0.1)) {
                            showFocusIndicator = true
                        }

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

// MARK: - Scene Phase

extension View {
    /// Stops the camera when the app backgrounds and restarts it on return.
    func cameraSessionHandlesScenePhase(_ cameraService: CameraService) -> some View {
        modifier(CameraSessionScenePhaseModifier(cameraService: cameraService))
    }
}

private struct CameraSessionScenePhaseModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let cameraService: CameraService

    func body(content: Content) -> some View {
        content.onChange(of: scenePhase) { _, phase in
            cameraService.handleScenePhase(phase)
        }
    }
}

// MARK: - Preview

#Preview("Camera Preview View") {
    ZStack {
        Color.black
        Text("Camera Preview")
            .foregroundStyle(.white)
    }
    .ignoresSafeArea()
}
