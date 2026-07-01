import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

// MARK: - Image Quality Analyzer

/// Analyzes captured images for quality before API submission.
/// Checks blur, brightness, and text detectability to catch problems early.
actor ImageQualityAnalyzer {

    // MARK: - Properties

    private let context: CIContext
    private let configuration: Configuration

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }

    // MARK: - Public Analysis API

    /// Analyze an image for quality issues
    /// - Parameter image: The UIImage to analyze
    /// - Returns: Quality result with scores and issues
    func analyze(image: UIImage) async throws -> QualityResult {
        guard let ciImage = CIImage(image: image) else {
            throw QualityAnalysisError.invalidImage
        }

        return try await analyze(ciImage: ciImage)
    }

    /// Analyze a CIImage for quality issues
    /// - Parameter ciImage: The CIImage to analyze
    /// - Returns: Quality result with scores and issues
    func analyze(ciImage: CIImage) async throws -> QualityResult {
        // Run analyses concurrently
        async let blurResult = analyzeBlur(ciImage)
        async let brightnessResult = analyzeBrightness(ciImage)
        async let textResult = analyzeTextConfidence(ciImage)

        let blur = try await blurResult
        let brightness = try await brightnessResult
        let text = try await textResult

        return combineResults(blur: blur, brightness: brightness, text: text)
    }

    /// Quick check if image is likely acceptable (faster, less detailed)
    func quickCheck(image: UIImage) async -> Bool {
        guard let ciImage = CIImage(image: image) else {
            return false
        }

        // Just check blur and brightness for quick assessment
        let blur = (try? await analyzeBlur(ciImage)) ?? 0
        let brightness = (try? await analyzeBrightness(ciImage)) ?? 0.5

        let blurOK = blur >= configuration.minBlurScore
        let brightnessOK = brightness >= configuration.minBrightness
            && brightness <= configuration.maxBrightness

        return blurOK && brightnessOK
    }

    // MARK: - Blur Analysis

    /// Analyze image sharpness using Laplacian variance method
    private func analyzeBlur(_ image: CIImage) async throws -> Double {
        // Apply Laplacian filter (edge detection)
        // Higher variance in the result = sharper image
        let laplacianKernel: [CGFloat] = [
            0, 1, 0,
            1, -4, 1,
            0, 1, 0
        ]

        let weightsVector = CIVector(values: laplacianKernel, count: 9)

        guard let laplacianImage = image.applyingFilter(
            "CIConvolution3X3",
            parameters: [
                kCIInputWeightsKey: weightsVector,
                kCIInputBiasKey: 0.5  // Shift to avoid negative values
            ]
        ).cropped(to: image.extent) as CIImage? else {
            throw QualityAnalysisError.filterApplicationFailed
        }

        // Calculate variance of the Laplacian image
        // We sample the image to calculate statistics
        let variance = try calculateVariance(of: laplacianImage)

        return variance
    }

    /// Calculate variance of pixel values in an image
    private func calculateVariance(of image: CIImage) throws -> Double {
        // Downsample for faster processing
        let scale = min(1.0, 512.0 / max(image.extent.width, image.extent.height))
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Get pixel data
        let extent = scaledImage.extent
        guard extent.width > 0, extent.height > 0 else {
            throw QualityAnalysisError.invalidImage
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        context.render(
            scaledImage,
            toBitmap: &pixelData,
            rowBytes: width * 4,
            bounds: extent,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        // Calculate mean
        var sum: Double = 0
        let pixelCount = width * height

        for i in stride(from: 0, to: pixelData.count, by: 4) {
            // Use luminance (weighted grayscale)
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            sum += luminance
        }

        let mean = sum / Double(pixelCount)

        // Calculate variance
        var varianceSum: Double = 0
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            let diff = luminance - mean
            varianceSum += diff * diff
        }

        return varianceSum / Double(pixelCount)
    }

    // MARK: - Brightness Analysis

    /// Analyze image brightness using average luminance
    private func analyzeBrightness(_ image: CIImage) async throws -> Double {
        // Use CIAreaAverage to get the average color
        let averageFilter = CIFilter.areaAverage()
        averageFilter.inputImage = image
        averageFilter.extent = image.extent

        guard let outputImage = averageFilter.outputImage else {
            throw QualityAnalysisError.filterApplicationFailed
        }

        // Render 1x1 pixel result
        var pixel = [UInt8](repeating: 0, count: 4)

        context.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        // Calculate luminance from RGB
        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0

        // Standard luminance formula
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b

        return luminance
    }

    // MARK: - Text Detection Analysis

    /// Analyze text detectability using Vision framework
    private func analyzeTextConfidence(_ image: CIImage) async throws -> (confidence: Double, count: Int) {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: QualityAnalysisError.visionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: (confidence: 0, count: 0))
                    return
                }

                // Calculate average confidence across all text regions
                if observations.isEmpty {
                    continuation.resume(returning: (confidence: 0, count: 0))
                    return
                }

                let confidences = observations.compactMap { observation -> Float? in
                    observation.topCandidates(1).first?.confidence
                }

                let avgConfidence = confidences.isEmpty
                    ? 0.0
                    : Double(confidences.reduce(0, +)) / Double(confidences.count)

                continuation.resume(returning: (confidence: avgConfidence, count: observations.count))
            }

            // Use fast recognition for quick analysis
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false

            // Create CGImage from CIImage for Vision
            guard let cgImage = context.createCGImage(image, from: image.extent) else {
                continuation.resume(throwing: QualityAnalysisError.imageConversionFailed)
                return
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: QualityAnalysisError.visionFailed(error))
            }
        }
    }

    // MARK: - Result Combination

    /// Combine individual analysis results into overall quality result
    private func combineResults(
        blur: Double,
        brightness: Double,
        text: (confidence: Double, count: Int)
    ) -> QualityResult {
        var issues: [QualityIssue] = []

        // Check blur
        let blurOK = blur >= configuration.minBlurScore
        if !blurOK {
            issues.append(.tooBlurry(advice: "Hold the camera steady and ensure good focus"))
        }

        // Check brightness
        let tooDark = brightness < configuration.minBrightness
        let tooBright = brightness > configuration.maxBrightness
        let brightnessOK = !tooDark && !tooBright

        if tooDark {
            issues.append(.tooDark(advice: "Move to a brighter area or turn on a light"))
        } else if tooBright {
            issues.append(.tooBright(advice: "Avoid direct light on the page or reduce flash"))
        }

        // Check text detection
        let noText = text.count < configuration.minTextRegions
        let lowConfidence = text.confidence < configuration.minTextConfidence && text.count > 0
        let textOK = !noText && !lowConfidence

        if noText {
            issues.append(.noTextDetected(advice: "Ensure the book page is visible in frame"))
        } else if lowConfidence {
            issues.append(.lowTextConfidence(advice: "Hold camera parallel to page and ensure good lighting"))
        }

        // Calculate overall score (weighted)
        // Normalize blur score to 0-1 range (assume 500 is excellent)
        let normalizedBlur = min(1.0, blur / 500.0)

        // Brightness score is already 0-1, penalize deviation from 0.5
        let brightnessPenalty = abs(brightness - 0.5) * 2
        let normalizedBrightness = 1.0 - brightnessPenalty

        // Text confidence is already 0-1
        let textScore = text.count > 0 ? text.confidence : 0.0

        // Weighted combination
        let overallScore = (normalizedBlur * 0.3 + normalizedBrightness * 0.3 + textScore * 0.4)

        let isAcceptable = blurOK && brightnessOK && textOK

        return QualityResult(
            overallScore: overallScore,
            blurScore: blur,
            brightnessScore: brightness,
            textConfidence: text.confidence,
            textRegionCount: text.count,
            issues: issues,
            isAcceptable: isAcceptable
        )
    }
}
