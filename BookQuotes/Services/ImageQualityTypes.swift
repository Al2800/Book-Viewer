import UIKit

extension ImageQualityAnalyzer {
    struct Configuration {
        /// Minimum blur score (Laplacian variance) to be considered acceptable
        var minBlurScore: Double = 100

        /// Acceptable brightness range (0.0-1.0)
        var minBrightness: Double = 0.2
        var maxBrightness: Double = 0.8

        /// Minimum text confidence to be considered acceptable
        var minTextConfidence: Double = 0.6

        /// Minimum number of text regions expected
        var minTextRegions: Int = 1

        static let `default` = Configuration()

        /// More lenient thresholds for low-quality cameras
        static let lenient = Configuration(
            minBlurScore: 50,
            minBrightness: 0.15,
            maxBrightness: 0.85,
            minTextConfidence: 0.4,
            minTextRegions: 1
        )

        /// Stricter thresholds for best results
        static let strict = Configuration(
            minBlurScore: 150,
            minBrightness: 0.25,
            maxBrightness: 0.75,
            minTextConfidence: 0.7,
            minTextRegions: 2
        )
    }

    struct QualityResult: Sendable {
        /// Overall quality score (0.0-1.0), weighted combination
        let overallScore: Double

        /// Blur score - higher means sharper image
        let blurScore: Double

        /// Brightness score - 0.5 is ideal, <0.2 too dark, >0.8 too bright
        let brightnessScore: Double

        /// Average confidence from text detection
        let textConfidence: Double

        /// Number of text regions detected
        let textRegionCount: Int

        /// List of identified quality issues
        let issues: [QualityIssue]

        /// Whether image meets minimum quality thresholds
        let isAcceptable: Bool

        /// Human-readable summary
        var summary: String {
            if isAcceptable {
                return "Image quality is acceptable"
            } else if issues.isEmpty {
                return "Image quality could not be determined"
            } else {
                return issues.map { $0.description }.joined(separator: "; ")
            }
        }
    }

    enum QualityIssue: Sendable, Equatable {
        case tooBlurry(advice: String)
        case tooDark(advice: String)
        case tooBright(advice: String)
        case noTextDetected(advice: String)
        case lowTextConfidence(advice: String)

        var description: String {
            switch self {
            case .tooBlurry(let advice):
                return "Image is blurry. \(advice)"
            case .tooDark(let advice):
                return "Image is too dark. \(advice)"
            case .tooBright(let advice):
                return "Image is too bright. \(advice)"
            case .noTextDetected(let advice):
                return "No text detected. \(advice)"
            case .lowTextConfidence(let advice):
                return "Text is hard to read. \(advice)"
            }
        }

        var icon: String {
            switch self {
            case .tooBlurry: return "camera.metering.unknown"
            case .tooDark: return "sun.min"
            case .tooBright: return "sun.max"
            case .noTextDetected: return "text.magnifyingglass"
            case .lowTextConfidence: return "text.badge.xmark"
            }
        }

        var advice: String {
            switch self {
            case .tooBlurry(let advice),
                 .tooDark(let advice),
                 .tooBright(let advice),
                 .noTextDetected(let advice),
                 .lowTextConfidence(let advice):
                return advice
            }
        }
    }
}

enum QualityAnalysisError: LocalizedError {
    case invalidImage
    case filterApplicationFailed
    case imageConversionFailed
    case visionFailed(Error)
    case analysisTimeout

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid or corrupted image data"
        case .filterApplicationFailed:
            return "Failed to apply image analysis filter"
        case .imageConversionFailed:
            return "Failed to convert image for analysis"
        case .visionFailed(let error):
            return "Vision analysis failed: \(error.localizedDescription)"
        case .analysisTimeout:
            return "Image analysis timed out"
        }
    }
}

extension UIImage {
    /// Analyze image quality for API submission
    func analyzeQuality(
        configuration: ImageQualityAnalyzer.Configuration = .default
    ) async throws -> ImageQualityAnalyzer.QualityResult {
        let analyzer = ImageQualityAnalyzer(configuration: configuration)
        return try await analyzer.analyze(image: self)
    }

    /// Quick check if image quality is acceptable
    func isQualityAcceptable() async -> Bool {
        let analyzer = ImageQualityAnalyzer()
        return await analyzer.quickCheck(image: self)
    }
}
