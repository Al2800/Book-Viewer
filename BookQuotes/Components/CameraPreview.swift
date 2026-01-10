import AVFoundation
import SwiftUI

// MARK: - Camera Preview

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer.
/// Displays the live camera feed from a CameraService.
struct CameraPreview: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Configure preview layer from camera service
        if uiView.previewLayer == nil {
            if let layer = cameraService.createPreviewLayer() {
                uiView.previewLayer = layer
            }
        }
    }
}

// MARK: - Camera Preview UIView

/// UIView subclass that hosts the AVCaptureVideoPreviewLayer.
final class CameraPreviewUIView: UIView {
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
    }
}

// MARK: - Camera Preview with Focus

/// Camera preview with tap-to-focus capability.
struct CameraPreviewWithFocus: View {
    let cameraService: CameraService

    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false

    var body: some View {
        GeometryReader { geometry in
            CameraPreview(cameraService: cameraService)
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
                        FocusIndicator()
                            .position(point)
                    }
                }
        }
    }
}

// MARK: - Focus Indicator

/// Visual indicator for tap-to-focus location.
private struct FocusIndicator: View {
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

#Preview("Camera Preview") {
    // Note: Preview won't show actual camera feed
    ZStack {
        Color.black
        Text("Camera Preview")
            .foregroundStyle(.white)
    }
    .ignoresSafeArea()
}
