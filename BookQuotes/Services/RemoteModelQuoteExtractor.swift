import Foundation
import UIKit

struct RemoteModelQuoteExtractor: QuoteExtracting {
    private let authService: AuthService
    private let baseURL: URL
    private let session: URLSession

    init(
        authService: AuthService,
        baseURL: URL = AuthService.proxyBaseURL,
        session: URLSession = .shared
    ) {
        self.authService = authService
        self.baseURL = baseURL
        self.session = session
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        let token = await MainActor.run { authService.getSessionToken() }
        guard let token else { throw ExtractionError.authenticationRequired }

        let imageData = try await Task.detached(priority: .userInitiated) {
            try ImagePreprocessor.processForQuoteExtraction(image).data
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
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            try handleHTTPResponse(httpResponse, data: data)
        }

        let proxyResponse = try JSONDecoder().decode(RemoteModelQuoteResponse.self, from: data)
        guard let text = proxyResponse.candidates.first?.content.parts.first?.text else {
            throw ExtractionError.parsingError("No model-assisted extraction content")
        }

        return try QuoteExtractionResult.parse(from: text)
    }

    private func handleHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200:
            return
        case 401:
            throw ExtractionError.authenticationRequired
        case 402:
            throw ExtractionError.subscriptionRequired
        case 429:
            throw ExtractionError.rateLimited
        default:
            if let error = try? JSONDecoder().decode(RemoteModelErrorResponse.self, from: data) {
                throw ExtractionError.parsingError("\(error.code): \(error.error)")
            }
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

private struct RemoteModelErrorResponse: Decodable {
    let error: String
    let code: String
}
