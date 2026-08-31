import AVFoundation
import CoreImage
import Foundation
import UIKit
import Vision

// MARK: - ISBNScanner

/// Observable service for scanning ISBN barcodes from camera feed or images.
/// Uses Vision framework for barcode detection and validates ISBN payloads.
@MainActor
@Observable
final class ISBNScanner: NSObject {
    // MARK: - Published State

    /// Last detected ISBN (validated)
    private(set) var detectedISBN: String?

    /// Whether a scan is currently in progress
    private(set) var isScanning = false

    /// Confidence score of the last detection (0.0-1.0)
    private(set) var confidence: Float = 0

    /// Last error that occurred
    private(set) var error: ISBNScannerError?

    /// Callback for real-time detections
    var onBarcodeDetected: ((String) -> Void)?

    // MARK: - Configuration

    /// Minimum confidence required for live-camera detections
    var minimumConfidence: Float = 0.8

    /// Frame interval and confirmation policy for the live camera feed
    var scanConfiguration: ScanConfiguration = .default {
        didSet {
            liveScanCoordinator.updateConfiguration(scanConfiguration)
        }
    }

    // MARK: - Real-time Scanning State

    private var videoOutput: AVCaptureVideoDataOutput?
    private weak var activeSession: AVCaptureSession?
    private let videoQueue = DispatchQueue(label: "com.bookquotes.ISBNScanner", qos: .userInitiated)
    nonisolated private let liveScanCoordinator = ISBNLiveScanCoordinator()

    // MARK: - Single Image Scanning

    /// Scan a UIImage for ISBN barcodes
    func scanImage(_ image: UIImage) async throws -> String? {
        guard let ciImage = CIImage(image: image) else {
            throw ISBNScannerError.invalidImage
        }
        return try await scanCIImage(ciImage)
    }

    /// Scan a CIImage for ISBN barcodes
    func scanCIImage(_ image: CIImage) async throws -> String? {
        let wasScanning = isScanning
        isScanning = true
        error = nil
        detectedISBN = nil
        confidence = 0

        defer { isScanning = wasScanning }

        do {
            let result = try await performBarcodeDetection(on: image)
            if let isbn = result {
                detectedISBN = isbn.isbn
                confidence = isbn.confidence
            }
            return result?.isbn
        } catch {
            let scanError = error as? ISBNScannerError ?? .detectionFailed(error.localizedDescription)

            // Still-image callers treat Vision detection failure as no barcode found.
            switch scanError {
            case .invalidImage, .invalidSampleBuffer:
                self.error = scanError
                throw scanError
            case .detectionFailed, .noBarcodesFound:
                return nil
            }
        }
    }

    /// Scan image data for ISBN barcodes
    func scanImageData(_ data: Data) async throws -> String? {
        guard let image = UIImage(data: data) else {
            throw ISBNScannerError.invalidImage
        }
        return try await scanImage(image)
    }

    // MARK: - Real-time Scanning

    /// Scan a sample buffer from camera for ISBN barcodes.
    func scanSampleBuffer(_ sampleBuffer: CMSampleBuffer) async throws -> String? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw ISBNScannerError.invalidSampleBuffer
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return try await scanCIImage(ciImage)
    }

    // MARK: - Real-time Session Scanning

    /// Start scanning barcodes from a live AVCaptureSession.
    func startScanning(on session: AVCaptureSession) {
        guard !isScanning else { return }

        error = nil
        detectedISBN = nil
        confidence = 0
        liveScanCoordinator.updateConfiguration(scanConfiguration)
        liveScanCoordinator.reset()

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)

        session.beginConfiguration()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            liveScanCoordinator.reset()
            error = .detectionFailed("Unable to attach video output for scanning.")
            return
        }

        session.addOutput(output)
        session.commitConfiguration()

        activeSession = session
        videoOutput = output
        isScanning = true
    }

    /// Stop scanning and invalidate every in-flight frame before removing the output.
    func stopScanning() {
        liveScanCoordinator.reset()

        guard let session = activeSession, let output = videoOutput else {
            videoOutput = nil
            activeSession = nil
            isScanning = false
            return
        }

        output.setSampleBufferDelegate(nil, queue: nil)
        session.beginConfiguration()
        session.removeOutput(output)
        session.commitConfiguration()

        videoOutput = nil
        activeSession = nil
        isScanning = false
    }

    /// Process a camera frame for barcode detection without storing observable state.
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
        try await withCheckedThrowingContinuation { continuation in
            let lock = NSLock()
            var hasResumed = false

            func resumeOnce(_ action: () -> Void) {
                lock.lock()
                defer { lock.unlock() }

                guard !hasResumed else { return }
                hasResumed = true
                action()
            }

            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    resumeOnce {
                        continuation.resume(throwing: ISBNScannerError.detectionFailed(error.localizedDescription))
                    }
                    return
                }

                guard let results = request.results as? [VNBarcodeObservation] else {
                    resumeOnce { continuation.resume(returning: nil) }
                    return
                }

                for observation in results {
                    guard Self.isISBNSymbology(observation.symbology),
                          let payload = observation.payloadStringValue,
                          let isbn = ISBNValidator.isbnFromBarcode(payload) else {
                        continue
                    }

                    let result = ScanResult(
                        isbn: isbn,
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox,
                        symbology: observation.symbology
                    )
                    resumeOnce { continuation.resume(returning: result) }
                    return
                }

                resumeOnce { continuation.resume(returning: nil) }
            }

            request.symbologies = [.ean13, .ean8, .upce]

            let handler = VNImageRequestHandler(ciImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                resumeOnce {
                    continuation.resume(throwing: ISBNScannerError.detectionFailed(error.localizedDescription))
                }
            }
        }
    }

    private nonisolated static func isISBNSymbology(_ symbology: VNBarcodeSymbology) -> Bool {
        switch symbology {
        case .ean13, .ean8, .upce:
            return true
        default:
            return false
        }
    }

    // MARK: - State Management

    /// Clear the last detection result and invalidate any frame still completing.
    func clearResult() {
        detectedISBN = nil
        confidence = 0
        error = nil
        liveScanCoordinator.reset()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ISBNScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let coordinator = liveScanCoordinator
        guard let frameToken = coordinator.beginFrame(now: CFAbsoluteTimeGetCurrent()) else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            coordinator.endFrame(frameToken)
            return
        }

        Task {
            defer { coordinator.endFrame(frameToken) }

            guard let result = await detectBarcode(in: pixelBuffer) else { return }

            let requirements = await MainActor.run {
                (minimumConfidence: self.minimumConfidence, hapticFeedback: self.scanConfiguration.hapticFeedback)
            }
            guard result.confidence >= requirements.minimumConfidence else { return }
            guard coordinator.confirm(result.isbn, for: frameToken) else { return }

            await MainActor.run {
                guard isScanning, coordinator.isCurrent(frameToken) else { return }
                detectedISBN = result.isbn
                confidence = result.confidence
                if requirements.hapticFeedback {
                    HapticManager.success()
                }
                onBarcodeDetected?(result.isbn)
            }
        }
    }
}

// MARK: - Scan Result

extension ISBNScanner {
    struct ScanResult: Sendable {
        let isbn: String
        let confidence: Float
        let boundingBox: CGRect
        let symbology: VNBarcodeSymbology

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

@MainActor
protocol ISBNScannerDelegate: AnyObject {
    func scanner(_ scanner: ISBNScanner, didDetect result: ISBNScanner.ScanResult)
    func scanner(_ scanner: ISBNScanner, didFailWith error: ISBNScannerError)
}

// MARK: - Continuous Scanning Support

extension ISBNScanner {
    struct ScanConfiguration: Sendable {
        /// Minimum time between processing frames (to reduce CPU usage)
        let frameInterval: TimeInterval

        /// Number of matching detections required to confirm an ISBN
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

struct ISBNLiveScanFrameToken: Sendable, Equatable {
    let generation: UInt64
}

/// Serializes live-camera ISBN work so Vision is not invoked on every frame.
/// Each reset advances a generation, preventing an old frame from completing into a new scan.
final class ISBNLiveScanCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private var configuration: ISBNScanner.ScanConfiguration
    private var generation: UInt64 = 0
    private var lastProcessedAt: TimeInterval = 0
    private var isBusy = false
    private var candidate: String?
    private var hits = 0
    private var confirmedISBN: String?

    init(configuration: ISBNScanner.ScanConfiguration = .default) {
        self.configuration = configuration
    }

    func updateConfiguration(_ configuration: ISBNScanner.ScanConfiguration) {
        lock.lock()
        self.configuration = configuration
        generation &+= 1
        lastProcessedAt = 0
        isBusy = false
        candidate = nil
        hits = 0
        confirmedISBN = nil
        lock.unlock()
    }

    func reset() {
        lock.lock()
        generation &+= 1
        lastProcessedAt = 0
        isBusy = false
        candidate = nil
        hits = 0
        confirmedISBN = nil
        lock.unlock()
    }

    func beginFrame(now: TimeInterval) -> ISBNLiveScanFrameToken? {
        lock.lock()
        defer { lock.unlock() }

        guard !isBusy, confirmedISBN == nil else { return nil }
        guard lastProcessedAt == 0 || now - lastProcessedAt >= configuration.frameInterval else { return nil }

        isBusy = true
        lastProcessedAt = now
        return ISBNLiveScanFrameToken(generation: generation)
    }

    func endFrame(_ token: ISBNLiveScanFrameToken) {
        lock.lock()
        if token.generation == generation {
            isBusy = false
        }
        lock.unlock()
    }

    func confirm(_ isbn: String, for token: ISBNLiveScanFrameToken) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard token.generation == generation, confirmedISBN == nil else { return false }

        if isbn == candidate {
            hits += 1
        } else {
            candidate = isbn
            hits = 1
        }

        guard hits >= max(configuration.confirmationCount, 1) else { return false }
        confirmedISBN = isbn
        return true
    }

    func isCurrent(_ token: ISBNLiveScanFrameToken) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return token.generation == generation
    }
}
