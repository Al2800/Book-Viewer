import SwiftUI
import UIKit

struct CoverCropReviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewportSize: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxZoomScale: CGFloat = 4.0

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                cropViewport
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: Spacing.sm) {
                    Text("Adjust Cover Crop")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text("Move and zoom the photo until the full cover sits inside the frame.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.xl)

                HStack(spacing: Spacing.lg) {
                    Button {
                        onRetake()
                        dismiss()
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.CoverCrop.retakeButton)

                    Button {
                        onUse(croppedImage())
                        dismiss()
                    } label: {
                        Label("Use Crop", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .glassButton()
                    .accessibilityIdentifier(AccessibilityIdentifiers.CoverCrop.useCropButton)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .padding(.top, Spacing.lg)
            .background(Color.backgroundPrimary)
            .navigationTitle("Cover")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onRetake()
                        dismiss()
                    }
                }
            }
        }
    }

    private var cropViewport: some View {
        GeometryReader { geometry in
            let size = cropViewportSize(for: geometry.size)

            ZStack {
                Color.black

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: displayedImageSize(in: size).width, height: displayedImageSize(in: size).height)
                        .offset(clampedOffset(in: size))
                }
                .frame(width: size.width, height: size.height)
                .clipped()
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.35), radius: 16, y: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let proposedScale = max(1.0, min(lastZoomScale * value, maxZoomScale))
                            zoomScale = proposedScale
                            imageOffset = clampedOffset(in: size)
                        }
                        .onEnded { _ in
                            zoomScale = max(1.0, min(zoomScale, maxZoomScale))
                            lastZoomScale = zoomScale
                            imageOffset = clampedOffset(in: size)
                            lastOffset = imageOffset
                        },
                    DragGesture()
                        .onChanged { value in
                            let proposedOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            imageOffset = clampedOffset(proposedOffset, in: size)
                        }
                        .onEnded { _ in
                            imageOffset = clampedOffset(imageOffset, in: size)
                            lastOffset = imageOffset
                        }
                )
            )
            .onAppear {
                viewportSize = size
                imageOffset = clampedOffset(in: size)
                lastOffset = imageOffset
            }
            .onChange(of: geometry.size) { _, _ in
                viewportSize = size
                imageOffset = clampedOffset(in: size)
                lastOffset = imageOffset
            }
        }
    }

    private func cropViewportSize(for availableSize: CGSize) -> CGSize {
        CoverCropGeometry.viewportSize(for: availableSize)
    }

    private func displayedImageSize(in viewport: CGSize) -> CGSize {
        CoverCropGeometry.displayedImageSize(
            imageSize: normalizedImage.size,
            viewport: viewport,
            zoomScale: zoomScale
        )
    }

    private func clampedOffset(in viewport: CGSize) -> CGSize {
        clampedOffset(imageOffset, in: viewport)
    }

    private func clampedOffset(_ proposedOffset: CGSize, in viewport: CGSize) -> CGSize {
        CoverCropGeometry.clampedOffset(
            proposedOffset,
            imageSize: normalizedImage.size,
            viewport: viewport,
            zoomScale: zoomScale
        )
    }

    private var normalizedImage: UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    private func croppedImage() -> UIImage {
        let normalized = normalizedImage
        guard let cgImage = normalized.cgImage,
              viewportSize.width > 0,
              viewportSize.height > 0,
              let cropRectInPoints = CoverCropGeometry.cropRectInPoints(
                imageSize: normalized.size,
                viewport: viewportSize,
                zoomScale: zoomScale,
                offset: imageOffset
              ) else {
            return normalized
        }

        let pixelScaleX = CGFloat(cgImage.width) / normalized.size.width
        let pixelScaleY = CGFloat(cgImage.height) / normalized.size.height
        let cropRectInPixels = CGRect(
            x: cropRectInPoints.minX * pixelScaleX,
            y: cropRectInPoints.minY * pixelScaleY,
            width: cropRectInPoints.width * pixelScaleX,
            height: cropRectInPoints.height * pixelScaleY
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard let cropped = cgImage.cropping(to: cropRectInPixels) else {
            return normalized
        }

        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }
}
