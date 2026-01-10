import Foundation
import UIKit

// MARK: - GeminiService

/// Service for communicating with Gemini API through the BookQuotes proxy.
/// Handles authentication, request formatting, and response parsing.
@MainActor
@Observable
final class GeminiService {

    // MARK: - Configuration

    /// Proxy server base URL
    private let baseURL: URL

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
        baseURL: URL = URL(string: "https://bookquotes-proxy.your-worker.workers.dev")!
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

        // Prepare image data
        guard let imageData = prepareImageData(image) else {
            let error = ExtractionError.invalidImage
            lastError = error
            throw error
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
        let url = baseURL.appendingPathComponent(endpoint)
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

    /// Prepare image data for upload (resize and compress if needed)
    private func prepareImageData(_ image: UIImage) -> Data? {
        // Maximum dimension for Gemini
        let maxDimension: CGFloat = 2048

        var targetImage = image

        // Resize if too large
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            targetImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }

        // Compress to JPEG with good quality
        // Start with high quality and reduce if too large
        var quality: CGFloat = 0.85
        var imageData = targetImage.jpegData(compressionQuality: quality)

        // Reduce quality if over 4MB
        while let data = imageData, data.count > 4_000_000, quality > 0.3 {
            quality -= 0.1
            imageData = targetImage.jpegData(compressionQuality: quality)
        }

        return imageData
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
