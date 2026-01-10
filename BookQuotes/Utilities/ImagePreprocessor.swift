import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

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
        // 1. Normalize orientation
        let normalizedImage = normalizeOrientation(image)

        // 2. Resize if needed
        let resizedImage = resize(normalizedImage, maxDimension: config.maxDimension)

        // 3. Apply contrast enhancement if enabled
        let finalImage: UIImage
        if config.enhanceContrast {
            finalImage = enhanceContrast(resizedImage, amount: config.contrastAmount) ?? resizedImage
        } else {
            finalImage = resizedImage
        }

        // 4. Compress to JPEG
        guard let jpegData = finalImage.jpegData(compressionQuality: config.compressionQuality) else {
            throw PreprocessorError.compressionFailed
        }

        // 5. Calculate metrics
        let originalEstimatedSize = image.size.width * image.size.height * 4 // RGBA
        let compressionRatio = Double(jpegData.count) / originalEstimatedSize

        return Result(
            data: jpegData,
            originalSize: image.size,
            processedSize: finalImage.size,
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

    /// Normalize image orientation to .up
    private static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    /// Resize image to fit within max dimension while preserving aspect ratio
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size preserving aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Resize using high-quality interpolation
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Apply light contrast enhancement using Core Image
    private static func enhanceContrast(_ image: UIImage, amount: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let context = CIContext()

        // Apply color controls filter
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = Float(1.0 + amount)
        filter.brightness = Float(amount * 0.05) // Slight brightness boost

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
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
