import CoreGraphics

struct CoverCropGeometry {

    static func viewportSize(
        for availableSize: CGSize,
        horizontalInset: CGFloat = Spacing.xl * 2,
        maxWidth: CGFloat = 340,
        reservedHeight: CGFloat = 140,
        minimumHeight: CGFloat = 220
    ) -> CGSize {
        let availableWidth = max(0, availableSize.width - horizontalInset)
        let maximumViewportWidth = max(0, min(availableWidth, maxWidth))
        let height = maximumViewportWidth * 1.5
        let constrainedHeight = min(height, max(minimumHeight, availableSize.height - reservedHeight))
        let width = constrainedHeight / 1.5
        return CGSize(width: width, height: constrainedHeight)
    }

    static func baseScale(imageSize: CGSize, viewport: CGSize) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0 else { return 1.0 }
        return max(viewport.width / imageSize.width, viewport.height / imageSize.height)
    }

    static func displayedImageSize(
        imageSize: CGSize,
        viewport: CGSize,
        zoomScale: CGFloat
    ) -> CGSize {
        let totalScale = baseScale(imageSize: imageSize, viewport: viewport) * zoomScale
        return CGSize(
            width: imageSize.width * totalScale,
            height: imageSize.height * totalScale
        )
    }

    static func clampedOffset(
        _ proposedOffset: CGSize,
        imageSize: CGSize,
        viewport: CGSize,
        zoomScale: CGFloat
    ) -> CGSize {
        let displayedSize = displayedImageSize(
            imageSize: imageSize,
            viewport: viewport,
            zoomScale: zoomScale
        )
        let maxX = max(0, (displayedSize.width - viewport.width) / 2)
        let maxY = max(0, (displayedSize.height - viewport.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        )
    }

    static func cropRectInPoints(
        imageSize: CGSize,
        viewport: CGSize,
        zoomScale: CGFloat,
        offset: CGSize
    ) -> CGRect? {
        let displayedSize = displayedImageSize(
            imageSize: imageSize,
            viewport: viewport,
            zoomScale: zoomScale
        )
        let totalScale = displayedSize.width / imageSize.width
        guard totalScale > 0 else { return nil }

        let clamped = clampedOffset(
            offset,
            imageSize: imageSize,
            viewport: viewport,
            zoomScale: zoomScale
        )
        let displayedOrigin = CGPoint(
            x: (viewport.width - displayedSize.width) / 2 + clamped.width,
            y: (viewport.height - displayedSize.height) / 2 + clamped.height
        )

        let cropRect = CGRect(
            x: (0 - displayedOrigin.x) / totalScale,
            y: (0 - displayedOrigin.y) / totalScale,
            width: viewport.width / totalScale,
            height: viewport.height / totalScale
        )
        .intersection(CGRect(origin: .zero, size: imageSize))

        guard !cropRect.isNull, !cropRect.isEmpty else {
            return nil
        }

        return cropRect
    }
}
