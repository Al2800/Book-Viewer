import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

// MARK: - GeminiService

private enum GeminiImagePrepError: Error {
    case failed
}

/// Service for communicating with Gemini API through the BookQuotes proxy.
/// Handles authentication, request formatting, and response parsing.
@MainActor
@Observable
final class GeminiService {

    // MARK: - Configuration

    /// Proxy server base URL
    private let baseURL: URL

    /// Default proxy URL
    nonisolated private static let defaultBaseURL: URL = AuthService.proxyBaseURL

    /// Auth service for session tokens
    private let authService: AuthService

    /// URL session for requests
    private let session: URLSession

    // MARK: - State

    /// Whether a request is in progress
    private(set) var isProcessing = false

    /// Last error encountered
    private(set) var lastError: ExtractionError?

    // MARK: - Initialization

    init(
        authService: AuthService,
        baseURL: URL = GeminiService.defaultBaseURL
    ) {
        self.authService = authService
        self.baseURL = baseURL

        // Configure URL session with reasonable timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60  // 60 seconds for AI processing
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    // MARK: - Quote Extraction

    /// Extract quotes from a book page image
    /// - Parameters:
    ///   - image: The book page image
    ///   - markings: User's marking definitions for customized extraction
    /// - Returns: Extraction result with quotes
    func extractQuotes(
        from image: UIImage,
        markings: [MarkingDefinition] = []
    ) async throws -> QuoteExtractionResult {
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        // Build the prompt
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markings: markings)

        // Make the request
        let response = try await makeRequest(
            endpoint: "/api/extract-quotes",
            image: image,
            prompt: prompt
        )

        // Parse the response
        return try QuoteExtractionResult.parse(from: response)
    }

    /// Quick extraction with simplified prompt (faster but less detailed)
    func quickExtractQuotes(
        from image: UIImage,
        markings: [MarkingDefinition] = []
    ) async throws -> QuoteExtractionResult {
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        let prompt = QuoteExtractionPromptBuilder.buildQuickPrompt(markings: markings)

        let response = try await makeRequest(
            endpoint: "/api/extract-quotes",
            image: image,
            prompt: prompt
        )

        return try QuoteExtractionResult.parse(from: response)
    }

    // MARK: - Cover Extraction

    /// Extract book metadata from cover image
    /// - Parameter image: The book cover image
    /// - Returns: Book metadata result
    func extractCoverMetadata(from image: UIImage) async throws -> BookMetadataResult {
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        let prompt = QuoteExtractionPromptBuilder.buildCoverExtractionPrompt()

        let response = try await makeRequest(
            endpoint: "/api/extract-cover",
            image: image,
            prompt: prompt
        )

        return try BookMetadataResult.parse(from: response)
    }

    // MARK: - Private Methods

    /// Make a request to the proxy server
    private func makeRequest(
        endpoint: String,
        image: UIImage,
        prompt: String
    ) async throws -> String {
        // Get auth token
        guard let token = authService.getSessionToken() else {
            let error = ExtractionError.authenticationRequired
            lastError = error
            throw error
        }

        // Prepare image data (can be expensive; keep it off the MainActor).
        let imageData: Data
        do {
            imageData = try await prepareImageData(image)
        } catch {
            let extractionError = (error as? ExtractionError) ?? ExtractionError.invalidImage
            lastError = extractionError
            throw extractionError
        }

        // Build request body
        let requestBody = GeminiRequestBody(
            contents: [
                GeminiContent(parts: [
                    GeminiPart(text: prompt),
                    GeminiPart(inlineData: GeminiInlineData(
                        mimeType: "image/jpeg",
                        data: imageData.base64EncodedString()
                    ))
                ])
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.1,
                maxOutputTokens: 4096,
                responseMimeType: "application/json"
            )
        )

        // Create URL request
        let sanitizedEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(sanitizedEndpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            let extractionError = ExtractionError.networkError(error)
            lastError = extractionError
            throw extractionError
        }

        // Make request
        do {
            let (data, response) = try await session.data(for: request)

            // Handle HTTP errors
            if let httpResponse = response as? HTTPURLResponse {
                try handleHTTPResponse(httpResponse, data: data)
            }

            // Parse Gemini response
            return try parseGeminiResponse(data)

        } catch let error as ExtractionError {
            lastError = error
            throw error
        } catch {
            let extractionError = ExtractionError.networkError(error)
            lastError = extractionError
            throw extractionError
        }
    }

    /// Prepare image data for upload (resize and compress if needed).
    ///
    /// Important: this work can take hundreds of ms on device for large photos.
    /// It must not run on the MainActor or it will appear as a "freeze" after capture.
    private func prepareImageData(_ image: UIImage) async throws -> Data {
        do {
            return try await Task.detached(priority: .userInitiated) {
                try Self.prepareImageDataThreadSafe(image)
            }.value
        } catch {
            throw ExtractionError.invalidImage
        }
    }

    nonisolated private static func prepareImageDataThreadSafe(_ image: UIImage) throws -> Data {
        let maxDimension: CGFloat = 2048
        let maxBytes = 4_000_000

        guard let cgImage = image.cgImage else { throw GeminiImagePrepError.failed }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let scale = min(1.0, maxDimension / max(width, height))

        let resizedCGImage: CGImage
        if scale < 1.0 {
            let targetWidth = max(1, Int((width * scale).rounded(.down)))
            let targetHeight = max(1, Int((height * scale).rounded(.down)))

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            guard let context = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { throw GeminiImagePrepError.failed }

            context.interpolationQuality = .high
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            guard let output = context.makeImage() else { throw GeminiImagePrepError.failed }
            resizedCGImage = output
        } else {
            resizedCGImage = cgImage
        }

        var quality: CGFloat = 0.85
        while true {
            let encoded = try encodeJPEG(resizedCGImage, quality: quality)
            if encoded.count <= maxBytes || quality <= 0.3 {
                return encoded
            }
            quality -= 0.1
        }
    }

    nonisolated private static func encodeJPEG(_ image: CGImage, quality: CGFloat) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { throw GeminiImagePrepError.failed }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw GeminiImagePrepError.failed }

        return data as Data
    }

    /// Handle HTTP response status codes
    private func handleHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200:
            return  // Success

        case 401:
            throw ExtractionError.authenticationRequired

        case 402:
            throw ExtractionError.subscriptionRequired

        case 429:
            throw ExtractionError.rateLimited

        default:
            // Try to parse error message from response
            if let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data) {
                throw ExtractionError.networkError(ProxyError(
                    code: errorResponse.code,
                    message: errorResponse.error
                ))
            }
            throw ExtractionError.networkError(URLError(.badServerResponse))
        }
    }

    /// Parse the Gemini API response from proxy
    private func parseGeminiResponse(_ data: Data) throws -> String {
        let response: GeminiResponse

        do {
            response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw ExtractionError.parsingError("Failed to decode response: \(error.localizedDescription)")
        }

        // Extract text content from response
        guard let candidate = response.candidates?.first,
              let part = candidate.content?.parts?.first,
              let text = part.text else {

            // Check for blocked content
            if let reason = response.promptFeedback?.blockReason {
                throw ExtractionError.parsingError("Content blocked: \(reason)")
            }

            throw ExtractionError.parsingError("No content in response")
        }

        return text
    }
}

// MARK: - Request Types

/// Gemini API request body
private struct GeminiRequestBody: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
}

private struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable {
    var text: String?
    var inlineData: GeminiInlineData?

    init(text: String) {
        self.text = text
    }

    init(inlineData: GeminiInlineData) {
        self.inlineData = inlineData
    }
}

private struct GeminiInlineData: Encodable {
    let mimeType: String
    let data: String
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
    let responseMimeType: String
}

// MARK: - Response Types

/// Gemini API response
private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: PromptFeedback?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiResponseContent?
    let finishReason: String?
}

private struct GeminiResponseContent: Decodable {
    let parts: [GeminiResponsePart]?
}

private struct GeminiResponsePart: Decodable {
    let text: String?
}

private struct PromptFeedback: Decodable {
    let blockReason: String?
}

// MARK: - Error Types

/// Error response from proxy server
private struct ProxyErrorResponse: Decodable {
    let error: String
    let code: String
    let details: String?
}

/// Custom error for proxy responses
private struct ProxyError: LocalizedError {
    let code: String
    let message: String

    var errorDescription: String? {
        "\(code): \(message)"
    }
}
