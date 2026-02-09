import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers

// MARK: - Image Preprocessor

/// Prepares captured images for Gemini API requests
/// Handles orientation normalization, resizing, and JPEG compression
enum ImagePreprocessor {

    // MARK: - Configuration

    struct Config {
        /// Maximum dimension (width or height) for output image
        var maxDimension: CGFloat = 2048

        /// JPEG compression quality (0.0 - 1.0)
        var compressionQuality: CGFloat = 0.80

        /// Whether to apply light contrast enhancement
        var enhanceContrast: Bool = false

        /// Contrast enhancement amount (0.0 - 1.0)
        var contrastAmount: CGFloat = 0.1

        /// Target dimensions for thumbnails
        var thumbnailDimension: CGFloat = 400

        static let `default` = Config()
        static let highQuality = Config(maxDimension: 2048, compressionQuality: 0.85)
        static let thumbnail = Config(maxDimension: 400, compressionQuality: 0.75)
        static let coverImage = Config(maxDimension: 1200, compressionQuality: 0.80)
    }

    // MARK: - Result

    struct Result {
        /// Processed JPEG data
        let data: Data

        /// Original image dimensions
        let originalSize: CGSize

        /// Processed image dimensions
        let processedSize: CGSize

        /// Compression ratio (processed size / original estimated size)
        let compressionRatio: Double

        /// Whether contrast enhancement was applied
        let contrastEnhanced: Bool
    }

    // MARK: - Processing

    /// Process an image for API submission
    /// - Parameters:
    ///   - image: Source UIImage
    ///   - config: Processing configuration
    /// - Returns: Processed result with JPEG data and metadata
    static func process(_ image: UIImage, config: Config = .default) throws -> Result {
        // This code is used in capture flows and may run off the main actor.
        // Avoid UIKit image rendering APIs (UIGraphics...) and do all work via CoreImage/CoreGraphics.

        let originalSize = image.size

        guard let oriented = makeOrientedCIImage(from: image) else {
            throw PreprocessorError.invalidImage
        }

        let resized = resize(oriented, maxDimension: config.maxDimension)
        let finalCI: CIImage
        if config.enhanceContrast {
            finalCI = enhanceContrast(resized, amount: config.contrastAmount) ?? resized
        } else {
            finalCI = resized
        }

        let (jpegData, renderedSize) = try renderJPEG(finalCI, compressionQuality: config.compressionQuality)

        // Calculate metrics
        let originalEstimatedSize = max(1, originalSize.width * originalSize.height * 4) // RGBA
        let compressionRatio = Double(jpegData.count) / Double(originalEstimatedSize)

        return Result(
            data: jpegData,
            originalSize: originalSize,
            processedSize: renderedSize,
            compressionRatio: compressionRatio,
            contrastEnhanced: config.enhanceContrast
        )
    }

    /// Create a thumbnail for display
    static func createThumbnail(_ image: UIImage, config: Config = .thumbnail) throws -> Data {
        let result = try process(image, config: config)
        return result.data
    }

    /// Process for book cover (medium quality, good for display)
    static func processForCover(_ image: UIImage) throws -> Result {
        try process(image, config: .coverImage)
    }

    /// Process for quote extraction (high quality for OCR)
    static func processForQuoteExtraction(_ image: UIImage) throws -> Result {
        try process(image, config: .highQuality)
    }

    // MARK: - Private Helpers

    private static func makeOrientedCIImage(from image: UIImage) -> CIImage? {
        if let cgImage = image.cgImage {
            let base = CIImage(cgImage: cgImage)
            return base.oriented(cgImagePropertyOrientation(from: image.imageOrientation))
        }

        if let ciImage = image.ciImage {
            return ciImage.oriented(cgImagePropertyOrientation(from: image.imageOrientation))
        }

        return nil
    }

    /// Resize image to fit within max dimension while preserving aspect ratio.
    /// Uses Lanczos scaling for quality.
    private static func resize(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let size = image.extent.size
        guard size.width > 0, size.height > 0 else { return image }

        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return image }

        let scale = maxDimension / currentMax

        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = Float(scale)
        filter.aspectRatio = 1.0
        return filter.outputImage ?? image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    /// Apply light contrast enhancement using Core Image.
    private static func enhanceContrast(_ image: CIImage, amount: CGFloat) -> CIImage? {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = Float(1.0 + amount)
        filter.brightness = Float(amount * 0.05) // slight brightness boost
        return filter.outputImage
    }

    private static func renderJPEG(_ image: CIImage, compressionQuality: CGFloat) throws -> (data: Data, size: CGSize) {
        let extent = image.extent.integral
        guard extent.width > 0, extent.height > 0 else {
            throw PreprocessorError.invalidImage
        }

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(image, from: extent) else {
            throw PreprocessorError.processingFailed("Failed to render processed image")
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PreprocessorError.compressionFailed
        }

        let options: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ] as CFDictionary

        CGImageDestinationAddImage(destination, cgImage, options)
        guard CGImageDestinationFinalize(destination) else {
            throw PreprocessorError.compressionFailed
        }

        let renderedSize = CGSize(width: cgImage.width, height: cgImage.height)
        return (outputData as Data, renderedSize)
    }

    private static func cgImagePropertyOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - Errors

enum PreprocessorError: LocalizedError {
    case compressionFailed
    case invalidImage
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image to JPEG"
        case .invalidImage:
            return "Invalid or corrupted image data"
        case .processingFailed(let reason):
            return "Image processing failed: \(reason)"
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// Convenience method to preprocess for API
    func preprocessed(config: ImagePreprocessor.Config = .default) throws -> Data {
        try ImagePreprocessor.process(self, config: config).data
    }

    /// Create a thumbnail
    func thumbnail(maxDimension: CGFloat = 400) throws -> Data {
        let config = ImagePreprocessor.Config(maxDimension: maxDimension, compressionQuality: 0.75)
        return try ImagePreprocessor.process(self, config: config).data
    }
}
