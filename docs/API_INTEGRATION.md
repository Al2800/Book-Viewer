# Remote Quote Extraction Contract

> **Current release contract (2026-07-15):** Book registration is ISBN/manual only. Cover photos
> are not sent to an AI provider. For consented, authenticated subscribers, quote capture calls
> `/api/extract-quotes-hf` first through the BookQuotes Worker and the pinned Hugging Face provider.
> Apple Vision OCR is the fallback. `/api/extract-cover` and `/api/extract-quotes` are retired and
> return `410` before parsing or forwarding images.

The Gemini material below is retained only as historical implementation reference. It does not
describe a reachable production workflow and must not be used for release copy or new features.

# Legacy Gemini Proxy Integration Specification

## Overview

BookQuotes uses Google's Gemini API via the BookQuotes proxy for two core AI capabilities:
1. **Book Cover Analysis**: Extract title, author, and metadata from book cover photos
2. **Quote Extraction**: Identify and transcribe marked/highlighted passages from book page photos

This document specifies the integration architecture, prompts, error handling, and optimization strategies.

---

## Proxy Configuration

### Endpoint

```
Base URL: https://api.bookquotes.app/v1
Model: gemini-1.5-flash (optimized for speed and cost)
Alternative: gemini-1.5-pro (for higher accuracy when needed)
```

### Request Format

```http
POST /v1/ai/extract
Content-Type: application/json
Authorization: Bearer {SESSION_TOKEN}

{
  "contents": [
    {
      "parts": [
        {
          "text": "Your prompt here"
        },
        {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": "base64_encoded_image_data"
          }
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.1,
    "topP": 0.95,
    "maxOutputTokens": 2048,
    "responseMimeType": "application/json"
  },
  "safetySettings": [
    {
      "category": "HARM_CATEGORY_HARASSMENT",
      "threshold": "BLOCK_NONE"
    }
  ]
}
```

---

## GeminiService Implementation

```swift
import Foundation

@MainActor
@Observable
final class GeminiService {
    // MARK: - Configuration

    private let baseURL = "https://api.bookquotes.app/v1"
    private let defaultModel = "gemini-1.5-flash"
    private let proModel = "gemini-1.5-pro"
    private let authProvider: AuthProviding

    // MARK: - State

    var isProcessing = false
    var lastError: GeminiError?

    // MARK: - Errors

    enum GeminiError: LocalizedError {
        case unauthenticated
        case subscriptionRequired
        case usageLimitReached
        case networkError(Error)
        case rateLimited(retryAfter: Int?)
        case invalidResponse
        case parsingError(String)
        case serverError(Int, String?)
        case imageProcessingFailed
        case quotaExceeded

        var errorDescription: String? {
            switch self {
            case .unauthenticated:
                return "Please sign in again to continue."
            case .subscriptionRequired:
                return "Subscription required. Start a trial or update your plan."
            case .usageLimitReached:
                return "Usage limit reached. Please wait or upgrade your plan."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .rateLimited(let retry):
                if let retry = retry {
                    return "Rate limited. Please wait \(retry) seconds."
                }
                return "Rate limited. Please try again later."
            case .invalidResponse:
                return "Invalid response from AI service."
            case .parsingError(let detail):
                return "Failed to parse response: \(detail)"
            case .serverError(let code, let message):
                return "Server error (\(code)): \(message ?? "Unknown")"
            case .imageProcessingFailed:
                return "Failed to process image. Please try a clearer photo."
            case .quotaExceeded:
                return "API quota exceeded. Please try again tomorrow or upgrade your plan."
            }
        }
    }

    // MARK: - Initialization

    init(authProvider: AuthProviding) {
        self.authProvider = authProvider
    }

    // MARK: - Book Cover Processing

    func extractBookMetadata(from imageData: Data) async throws -> BookMetadataResponse {
        let prompt = Self.bookCoverPrompt
        let response = try await sendRequest(
            prompt: prompt,
            imageData: imageData,
            model: defaultModel
        )

        return try parseBookMetadata(from: response)
    }

    // MARK: - Quote Extraction

    func extractQuotes(from imageData: Data) async throws -> QuoteExtractionResponse {
        let prompt = Self.quoteExtractionPrompt
        let response = try await sendRequest(
            prompt: prompt,
            imageData: imageData,
            model: defaultModel
        )

        return try parseQuoteExtraction(from: response)
    }

    // MARK: - Private: Request Handling

    private func sendRequest(
        prompt: String,
        imageData: Data,
        model: String
    ) async throws -> GeminiResponse {
        guard let token = authProvider.sessionToken else {
            throw GeminiError.unauthenticated
        }

        isProcessing = true
        defer { isProcessing = false }

        let url = URL(string: "\(baseURL)/ai/extract")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60 // Longer timeout for image processing

        let base64Image = imageData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topP": 0.95,
                "maxOutputTokens": 4096,
                "responseMimeType": "application/json"
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        // Handle HTTP errors
        try handleHTTPStatus(httpResponse, data: data)

        // Parse response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return geminiResponse
    }

    private func handleHTTPStatus(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200:
            return // Success
        case 400:
            let message = try? extractErrorMessage(from: data)
            throw GeminiError.parsingError(message ?? "Bad request")
        case 403:
            throw GeminiError.invalidAPIKey
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Int($0) }
            throw GeminiError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            let message = try? extractErrorMessage(from: data)
            throw GeminiError.serverError(response.statusCode, message)
        default:
            throw GeminiError.serverError(response.statusCode, nil)
        }
    }

    private func extractErrorMessage(from data: Data) throws -> String? {
        struct ErrorResponse: Codable {
            let error: ErrorDetail?
            struct ErrorDetail: Codable {
                let message: String?
            }
        }
        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
        return errorResponse.error?.message
    }

    // MARK: - Private: Response Parsing

    private func parseBookMetadata(from response: GeminiResponse) throws -> BookMetadataResponse {
        guard let text = response.candidates.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }

        // Clean JSON (remove markdown code blocks if present)
        let cleanedJSON = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.parsingError("Invalid JSON encoding")
        }

        do {
            return try JSONDecoder().decode(BookMetadataResponse.self, from: jsonData)
        } catch {
            throw GeminiError.parsingError("Failed to decode book metadata: \(error.localizedDescription)")
        }
    }

    private func parseQuoteExtraction(from response: GeminiResponse) throws -> QuoteExtractionResponse {
        guard let text = response.candidates.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }

        let cleanedJSON = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.parsingError("Invalid JSON encoding")
        }

        do {
            return try JSONDecoder().decode(QuoteExtractionResponse.self, from: jsonData)
        } catch {
            throw GeminiError.parsingError("Failed to decode quotes: \(error.localizedDescription)")
        }
    }
}

// MARK: - Response Models

struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
    }

    struct Content: Codable {
        let parts: [Part]
        let role: String?
    }

    struct Part: Codable {
        let text: String?
    }
}
```

---

## Prompts

### Book Cover Analysis Prompt

```swift
extension GeminiService {
    static let bookCoverPrompt = """
    Analyze this book cover image and extract bibliographic information.

    Return a JSON object with the following structure:
    {
      "title": "The exact book title as shown on cover",
      "author": "Author name(s) as shown",
      "subtitle": "Subtitle if present, or null",
      "publisher": "Publisher name if visible, or null",
      "isbn": "ISBN-10 or ISBN-13 if visible on cover, or null",
      "pageCount": null,
      "confidence": 0.95
    }

    Rules:
    1. Extract text EXACTLY as printed (preserve capitalization, punctuation)
    2. For multiple authors, separate with " and " or ", "
    3. If title has a colon, text before colon is title, after is subtitle
    4. Only include ISBN if clearly visible (usually on back cover)
    5. confidence should be 0.0-1.0 indicating certainty of extraction
    6. Use null for any field that cannot be determined

    Respond with ONLY the JSON object, no markdown formatting or explanation.
    """
}
```

### Quote Extraction Prompt

```swift
extension GeminiService {
    static let quoteExtractionPrompt = """
    Analyze this book page image to extract marked/highlighted passages.

    The reader has marked passages using one or more methods:
    - Underlines (single or double lines under text)
    - Margin lines (vertical lines in the margin next to paragraphs)
    - Highlights (colored/marked text)
    - Brackets (square or curly brackets around text)
    - Margin notes (handwritten annotations)

    Return a JSON object:
    {
      "quotes": [
        {
          "text": "The exact text that was marked",
          "pageNumber": 42,
          "marginNote": "Any handwritten note near this passage, or null",
          "markingType": "underline",
          "confidence": 0.92
        }
      ],
      "pageNumber": 42,
      "processingNotes": "Optional notes about extraction quality"
    }

    Rules for extraction:
    1. Extract the COMPLETE marked passage - include full sentences
    2. For underlines: extract all underlined text in that section
    3. For margin lines: extract the entire paragraph(s) indicated
    4. For highlights: extract all highlighted text
    5. Preserve original formatting (line breaks where meaningful)
    6. Transcribe handwritten margin notes as accurately as possible
    7. If page number is visible (corners/headers), include it
    8. markingType must be one of: underline, double_underline, margin_line, highlight, bracket, margin_note, mixed
    9. If multiple separate passages are marked, return each as separate quote
    10. confidence should be 0.0-1.0 for each quote's accuracy

    Respond with ONLY the JSON object, no markdown formatting.
    """
}
```

---

## Image Preprocessing

Before sending to Gemini, images should be optimized:

```swift
import UIKit
import CoreImage

extension UIImage {
    /// Prepare image for Gemini API processing
    func preparedForGemini() -> Data? {
        // 1. Resize to optimal dimensions
        let maxDimension: CGFloat = 2048
        let resized = resizedToFit(maxDimension: maxDimension)

        // 2. Convert to JPEG with good quality
        guard let jpegData = resized.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        // 3. Check size (Gemini has limits)
        let maxSize = 4 * 1024 * 1024 // 4MB
        if jpegData.count > maxSize {
            // Re-compress with lower quality
            return resized.jpegData(compressionQuality: 0.6)
        }

        return jpegData
    }

    private func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let ratio = max(size.width, size.height) / maxDimension
        if ratio <= 1 { return self }

        let newSize = CGSize(
            width: size.width / ratio,
            height: size.height / ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Optional: Enhance contrast for better OCR
    func contrastEnhanced() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey) // Slight boost

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
```

---

## Rate Limiting & Retry Logic

```swift
actor RequestQueue {
    private var lastRequestTime: Date?
    private let minInterval: TimeInterval = 0.5 // 500ms between requests

    func waitForSlot() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minInterval {
                try? await Task.sleep(for: .milliseconds(Int((minInterval - elapsed) * 1000)))
            }
        }
        lastRequestTime = Date()
    }
}

extension GeminiService {
    private static let requestQueue = RequestQueue()

    /// Execute request with automatic retry for transient failures
    func executeWithRetry<T>(
        maxAttempts: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            await Self.requestQueue.waitForSlot()

            do {
                return try await operation()
            } catch let error as GeminiError {
                lastError = error

                switch error {
                case .rateLimited(let retryAfter):
                    // Wait for rate limit to clear
                    let waitTime = retryAfter ?? (attempt * 5)
                    try? await Task.sleep(for: .seconds(waitTime))
                    continue

                case .networkError, .serverError:
                    // Exponential backoff for transient errors
                    if attempt < maxAttempts {
                        let backoff = pow(2.0, Double(attempt))
                        try? await Task.sleep(for: .seconds(backoff))
                        continue
                    }

                case .invalidAPIKey, .noAPIKey, .quotaExceeded:
                    // Don't retry auth/quota errors
                    throw error

                default:
                    if attempt < maxAttempts {
                        continue
                    }
                }
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    let backoff = pow(2.0, Double(attempt))
                    try? await Task.sleep(for: .seconds(backoff))
                    continue
                }
            }
        }

        throw lastError ?? GeminiError.invalidResponse
    }
}
```

---

## Usage Examples

### Book Cover Processing Flow

```swift
@MainActor
@Observable
final class BookCoverProcessor {
    private let geminiService: GeminiService

    var isProcessing = false
    var extractedMetadata: BookMetadataResponse?
    var error: GeminiService.GeminiError?

    init(geminiService: GeminiService) {
        self.geminiService = geminiService
    }

    func processBookCover(_ image: UIImage) async {
        isProcessing = true
        error = nil
        extractedMetadata = nil

        defer { isProcessing = false }

        guard let imageData = image.preparedForGemini() else {
            error = .imageProcessingFailed
            return
        }

        do {
            let metadata = try await geminiService.executeWithRetry {
                try await geminiService.extractBookMetadata(from: imageData)
            }
            extractedMetadata = metadata
        } catch let geminiError as GeminiService.GeminiError {
            error = geminiError
        } catch {
            self.error = .networkError(error)
        }
    }
}
```

### Quote Extraction Flow

```swift
@MainActor
@Observable
final class QuoteExtractor {
    private let geminiService: GeminiService

    var isProcessing = false
    var extractedQuotes: [ExtractedQuoteResponse] = []
    var error: GeminiService.GeminiError?

    init(geminiService: GeminiService) {
        self.geminiService = geminiService
    }

    func processPageImage(_ image: UIImage, book: Book) async -> [Quote] {
        isProcessing = true
        error = nil
        extractedQuotes = []

        defer { isProcessing = false }

        guard let imageData = image.preparedForGemini() else {
            error = .imageProcessingFailed
            return []
        }

        do {
            let response = try await geminiService.executeWithRetry {
                try await geminiService.extractQuotes(from: imageData)
            }

            extractedQuotes = response.quotes

            // Convert to Quote models
            return response.quotes.map { extracted in
                let quote = extracted.toQuote(book: book)
                // Store original image for reference
                quote.sourceImageData = imageData
                return quote
            }
        } catch let geminiError as GeminiService.GeminiError {
            error = geminiError
            return []
        } catch {
            self.error = .networkError(error)
            return []
        }
    }
}
```

---

## Cost Estimation

### Gemini 1.5 Flash Pricing (as of early 2025)

| Input | Price |
|-------|-------|
| Text input | $0.075 / 1M tokens |
| Image input | $0.02 / image |
| Text output | $0.30 / 1M tokens |

### Estimated Per-Operation Cost

| Operation | Est. Tokens | Est. Cost |
|-----------|-------------|-----------|
| Book cover analysis | ~500 output | ~$0.02 |
| Quote extraction (single page) | ~1000 output | ~$0.02 |

### Monthly Usage Estimates

| Usage Level | Operations/Month | Est. Cost |
|-------------|------------------|-----------|
| Light (10 books, 50 pages) | 60 | ~$1.20 |
| Medium (30 books, 150 pages) | 180 | ~$3.60 |
| Heavy (100 books, 500 pages) | 600 | ~$12.00 |

Note: Costs are borne by the app via the proxy. Subscription pricing should cover average usage with healthy margin.

---

## Security Considerations

1. **Session Token Storage**: Tokens stored in iOS Keychain, never in UserDefaults
2. **Network Security**: All requests use HTTPS
3. **Data Privacy**: Images are proxied and not retained after processing
4. **Error Messages**: Never expose tokens in error messages or logs
5. **Rate Limiting**: Enforce per-user limits on the proxy + client backoff

---

## Testing Strategy

### Unit Tests

```swift
final class GeminiServiceTests: XCTestCase {
    func testParseValidBookMetadata() throws {
        let json = """
        {
          "title": "Meditations",
          "author": "Marcus Aurelius",
          "subtitle": null,
          "publisher": "Penguin Classics",
          "isbn": null,
          "confidence": 0.95
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(BookMetadataResponse.self, from: data)

        XCTAssertEqual(metadata.title, "Meditations")
        XCTAssertEqual(metadata.author, "Marcus Aurelius")
        XCTAssertNil(metadata.subtitle)
    }

    func testParseQuoteExtraction() throws {
        let json = """
        {
          "quotes": [
            {
              "text": "You have power over your mind.",
              "pageNumber": 42,
              "marginNote": null,
              "markingType": "underline",
              "confidence": 0.92
            }
          ],
          "pageNumber": 42,
          "processingNotes": null
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(QuoteExtractionResponse.self, from: data)

        XCTAssertEqual(response.quotes.count, 1)
        XCTAssertEqual(response.quotes[0].text, "You have power over your mind.")
    }
}
```

### Integration Tests

Test with real images (requires a test session token):

```swift
final class GeminiIntegrationTests: XCTestCase {
    var service: GeminiService!

    override func setUp() {
        // Use test session token from environment
        let token = ProcessInfo.processInfo.environment["BQ_TEST_SESSION_TOKEN"] ?? ""
        let authProvider = TestAuthProvider(token: token)
        service = GeminiService(authProvider: authProvider)
    }

    func testBookCoverExtraction() async throws {
        let testImage = UIImage(named: "test_book_cover")!
        let imageData = testImage.preparedForGemini()!

        let metadata = try await service.extractBookMetadata(from: imageData)

        XCTAssertFalse(metadata.title.isEmpty)
        XCTAssertFalse(metadata.author.isEmpty)
    }
}
```

---

## Alternative: OpenAI Vision API

If switching to OpenAI is preferred:

```swift
final class OpenAIService {
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4o" // or "gpt-4o-mini" for cost savings

    func extractBookMetadata(from imageData: Data) async throws -> BookMetadataResponse {
        // Similar implementation with OpenAI-specific request format
        // Key differences:
        // - Authorization: Bearer {API_KEY} header
        // - Different JSON structure for image input
        // - Slightly different prompt formatting may help
    }
}
```

The prompts remain largely the same; only the API request/response format changes.
