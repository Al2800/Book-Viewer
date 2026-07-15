import Foundation
import UIKit

struct AIProcessingConsentStore {
    static let consentVersionKey = "ai_processing_consent_version"
    static let currentVersion = "2026-07"
    static let shared = AIProcessingConsentStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCurrentConsent: Bool {
        defaults.string(forKey: Self.consentVersionKey) == Self.currentVersion
    }

    func grant() {
        defaults.set(Self.currentVersion, forKey: Self.consentVersionKey)
    }

    func revoke() {
        defaults.removeObject(forKey: Self.consentVersionKey)
    }
}

protocol RemoteQuoteImageCropping: Sendable {
    func crop(_ image: UIImage) async -> UIImage
}

/// Produces a smaller, still-contextual image for explicitly enabled remote extraction.
/// It leaves the document-prepared capture untouched unless Vision can safely remove enough
/// outer camera area while retaining generous space for margin marks.
struct VisionRemoteQuoteImageCropper: RemoteQuoteImageCropping {
    private let textRecognizer: any PageTextRecognizing

    init(textRecognizer: any PageTextRecognizing = VisionPageTextRecognizer()) {
        self.textRecognizer = textRecognizer
    }

    func crop(_ image: UIImage) async -> UIImage {
        guard let textLines = try? await textRecognizer.recognizeText(in: image),
              let cropRect = RemoteQuoteImageCropGeometry.contentCropRect(
                  imageSize: imagePixelSize(image),
                  textLines: textLines
              ) else {
            return image
        }

        return (try? ImagePreprocessor.crop(image, toPixelRect: cropRect)) ?? image
    }

    private func imagePixelSize(_ image: UIImage) -> CGSize {
        if let cgImage = image.cgImage {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }
        return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }
}

enum RemoteQuoteImageCropGeometry {
    private static let minimumReduction: CGFloat = 0.10

    static func contentCropRect(
        imageSize: CGSize,
        textLines: [RecognizedTextLine]
    ) -> CGRect? {
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let imageBounds = CGRect(origin: .zero, size: imageSize)
        let textRects = textLines
            .filter { $0.confidence >= 0.2 }
            .map { $0.boundingBox.intersection(imageBounds) }
            .filter { !$0.isNull && !$0.isEmpty }

        // A few recognized lines are needed to safely preserve a multi-passage page.
        guard textRects.count >= 3 else { return nil }

        let textBounds = textRects.dropFirst().reduce(textRects[0]) { partial, rect in
            partial.union(rect)
        }
        let horizontalPadding = max(imageSize.width * 0.20, 64)
        let verticalPadding = max(imageSize.height * 0.10, 64)
        let cropRect = textBounds
            .insetBy(dx: -horizontalPadding, dy: -verticalPadding)
            .integral
            .intersection(imageBounds)

        guard !cropRect.isNull, !cropRect.isEmpty else { return nil }

        let cropArea = cropRect.width * cropRect.height
        let imageArea = imageBounds.width * imageBounds.height
        guard cropArea <= imageArea * (1 - minimumReduction) else { return nil }

        return cropRect
    }
}

struct RemoteModelQuoteExtractor: QuoteExtracting {
    private static let maximumResponseBytes = 256 * 1024
    private let authService: AuthService
    private let baseURL: URL
    private let session: URLSession
    private let consentStore: AIProcessingConsentStore
    private let imageCropper: any RemoteQuoteImageCropping

    init(
        authService: AuthService,
        baseURL: URL = AuthService.proxyBaseURL,
        session: URLSession = .shared,
        consentStore: AIProcessingConsentStore = .shared,
        imageCropper: any RemoteQuoteImageCropping = VisionRemoteQuoteImageCropper()
    ) {
        self.authService = authService
        self.baseURL = baseURL
        self.session = session
        self.consentStore = consentStore
        self.imageCropper = imageCropper
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        guard consentStore.hasCurrentConsent else {
            throw ExtractionError.thirdPartyAIConsentRequired
        }

        let token = await MainActor.run { authService.getSessionToken() }
        guard let token else { throw ExtractionError.authenticationRequired }

        let imageForUpload = await imageCropper.crop(image)
        let imageData = try await Task.detached(priority: .userInitiated) {
            try ImagePreprocessor.processForQuoteExtraction(imageForUpload).data
        }.value

        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markingPrompts: markings)
        let body = RemoteModelQuoteRequest(
            contents: [
                .init(parts: [
                    .text(prompt),
                    .image(mimeType: "image/jpeg", data: imageData.base64EncodedString())
                ])
            ],
            generationConfig: .json
        )

        var request = URLRequest(url: baseURL.appendingPathComponent("api/extract-quotes-hf"))
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard data.count <= Self.maximumResponseBytes else {
            throw ExtractionError.parsingError("Remote response exceeds the size limit")
        }
        if let httpResponse = response as? HTTPURLResponse {
            await MainActor.run {
                authService.applyRefreshedSessionToken(from: httpResponse)
            }
            try handleHTTPResponse(httpResponse)
        }

        let proxyResponse = try JSONDecoder().decode(RemoteModelQuoteResponse.self, from: data)
        guard let text = proxyResponse.candidates.first?.content.parts.first?.text else {
            throw ExtractionError.parsingError("No model-assisted extraction content")
        }

        return try QuoteExtractionResult.parse(from: text)
            .resolvingCustomMarkings(from: markings)
            .withExtractionSource(.modelAssisted)
    }

    private func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200:
            return
        case 401:
            throw ExtractionError.authenticationRequired
        case 402:
            throw ExtractionError.subscriptionRequired
        case 429:
            throw ExtractionError.rateLimited
        case 413:
            throw ExtractionError.invalidImage
        default:
            throw ExtractionError.networkError(URLError(.badServerResponse))
        }
    }
}

private struct RemoteModelQuoteRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String?
        let inlineData: InlineData?

        static func text(_ text: String) -> Part {
            Part(text: text, inlineData: nil)
        }

        static func image(mimeType: String, data: String) -> Part {
            Part(text: nil, inlineData: InlineData(mimeType: mimeType, data: data))
        }
    }

    struct InlineData: Encodable {
        let mimeType: String
        let data: String
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
        let maxOutputTokens: Int
        let responseMimeType: String

        static let json = GenerationConfig(
            temperature: 0.1,
            maxOutputTokens: 4096,
            responseMimeType: "application/json"
        )
    }
}

private struct RemoteModelQuoteResponse: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content
    }

    struct Content: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let text: String
    }
}
