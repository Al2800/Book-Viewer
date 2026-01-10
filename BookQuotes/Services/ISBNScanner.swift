import Foundation
import Vision
import UIKit
import CoreImage

// MARK: - ISBNScanner

/// Observable service for scanning ISBN barcodes from camera feed or images.
/// Uses Vision framework for near-100% accuracy barcode detection.
@MainActor
@Observable
final class ISBNScanner {
    // MARK: - Published State

    /// Last detected ISBN (validated)
    private(set) var detectedISBN: String?

    /// Whether a scan is currently in progress
    private(set) var isScanning = false

    /// Confidence score of the last detection (0.0-1.0)
    private(set) var confidence: Float = 0

    /// Last error that occurred
    private(set) var error: ISBNScannerError?

    // MARK: - Configuration

    /// Minimum confidence required for detection
    var minimumConfidence: Float = 0.8

    // MARK: - Initialization

    init() {}

    // MARK: - Single Image Scanning

    /// Scan a UIImage for ISBN barcodes
    /// - Parameter image: The image to scan
    /// - Returns: The detected ISBN, or nil if none found
    func scanImage(_ image: UIImage) async throws -> String? {
        guard let ciImage = CIImage(image: image) else {
            throw ISBNScannerError.invalidImage
        }
        return try await scanCIImage(ciImage)
    }

    /// Scan a CIImage for ISBN barcodes
    /// - Parameter image: The image to scan
    /// - Returns: The detected ISBN, or nil if none found
    func scanCIImage(_ image: CIImage) async throws -> String? {
        isScanning = true
        error = nil
        detectedISBN = nil
        confidence = 0

        defer { isScanning = false }

        do {
            let result = try await performBarcodeDetection(on: image)
            if let isbn = result {
                detectedISBN = isbn.isbn
                confidence = isbn.confidence
            }
            return result?.isbn
        } catch {
            self.error = error as? ISBNScannerError ?? .detectionFailed(error.localizedDescription)
            throw self.error!
        }
    }

    /// Scan image data for ISBN barcodes
    /// - Parameter data: Image data (JPEG, PNG, etc.)
    /// - Returns: The detected ISBN, or nil if none found
    func scanImageData(_ data: Data) async throws -> String? {
        guard let image = UIImage(data: data) else {
            throw ISBNScannerError.invalidImage
        }
        return try await scanImage(image)
    }

    // MARK: - Real-time Scanning

    /// Scan a sample buffer from camera for ISBN barcodes.
    /// Designed for real-time scanning during camera preview.
    /// - Parameter sampleBuffer: CMSampleBuffer from camera
    /// - Returns: The detected ISBN, or nil if none found
    func scanSampleBuffer(_ sampleBuffer: CMSampleBuffer) async throws -> String? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw ISBNScannerError.invalidSampleBuffer
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return try await scanCIImage(ciImage)
    }

    /// Process a camera frame for barcode detection.
    /// Returns immediately without storing state - use for continuous scanning.
    nonisolated func detectBarcode(in pixelBuffer: CVPixelBuffer) async -> ScanResult? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        do {
            return try await performBarcodeDetection(on: ciImage)
        } catch {
            return nil
        }
    }

    // MARK: - Vision Detection

    private nonisolated func performBarcodeDetection(on image: CIImage) async throws -> ScanResult? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ISBNScannerError.detectionFailed(error.localizedDescription))
                    return
                }

                guard let results = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Find first valid ISBN barcode
                for observation in results {
                    // Check symbology
                    guard Self.isISBNSymbology(observation.symbology) else {
                        continue
                    }

                    // Check payload
                    guard let payload = observation.payloadStringValue else {
                        continue
                    }

                    // Validate as ISBN
                    if let isbn = ISBNValidator.isbnFromBarcode(payload) {
                        let result = ScanResult(
                            isbn: isbn,
                            confidence: observation.confidence,
                            boundingBox: observation.boundingBox,
                            symbology: observation.symbology
                        )
                        continuation.resume(returning: result)
                        return
                    }
                }

                continuation.resume(returning: nil)
            }

            // Configure request for book barcodes
            request.symbologies = [.ean13, .ean8, .upce]

            let handler = VNImageRequestHandler(ciImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ISBNScannerError.detectionFailed(error.localizedDescription))
            }
        }
    }

    private static func isISBNSymbology(_ symbology: VNBarcodeSymbology) -> Bool {
        switch symbology {
        case .ean13, .ean8, .upce:
            return true
        default:
            return false
        }
    }

    // MARK: - State Management

    /// Clear the last detection result
    func clearResult() {
        detectedISBN = nil
        confidence = 0
        error = nil
    }
}

// MARK: - Scan Result

extension ISBNScanner {
    /// Result of a successful barcode scan
    struct ScanResult: Sendable {
        /// The validated ISBN
        let isbn: String

        /// Detection confidence (0.0-1.0)
        let confidence: Float

        /// Bounding box in normalized image coordinates
        let boundingBox: CGRect

        /// The barcode symbology detected
        let symbology: VNBarcodeSymbology

        /// Formatted ISBN for display
        var formattedISBN: String {
            ISBNValidator.format(isbn)
        }
    }
}

// MARK: - Scanner Errors

enum ISBNScannerError: LocalizedError {
    case invalidImage
    case invalidSampleBuffer
    case detectionFailed(String)
    case noBarcodesFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .invalidSampleBuffer:
            return "Invalid camera sample buffer"
        case .detectionFailed(let message):
            return "Barcode detection failed: \(message)"
        case .noBarcodesFound:
            return "No ISBN barcodes found in image"
        }
    }
}

// MARK: - Real-time Scanner Delegate

/// Protocol for receiving real-time scan results
@MainActor
protocol ISBNScannerDelegate: AnyObject {
    /// Called when an ISBN barcode is detected
    func scanner(_ scanner: ISBNScanner, didDetect result: ISBNScanner.ScanResult)

    /// Called when scanning fails
    func scanner(_ scanner: ISBNScanner, didFailWith error: ISBNScannerError)
}

// MARK: - Continuous Scanning Support

extension ISBNScanner {
    /// Configuration for continuous scanning mode
    struct ScanConfiguration: Sendable {
        /// Minimum time between processing frames (to reduce CPU usage)
        let frameInterval: TimeInterval

        /// Number of consecutive detections required to confirm ISBN
        let confirmationCount: Int

        /// Whether to play haptic feedback on detection
        let hapticFeedback: Bool

        static let `default` = ScanConfiguration(
            frameInterval: 0.1,
            confirmationCount: 2,
            hapticFeedback: true
        )

        static let fast = ScanConfiguration(
            frameInterval: 0.05,
            confirmationCount: 1,
            hapticFeedback: true
        )
    }
}
