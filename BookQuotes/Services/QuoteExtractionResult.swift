import Foundation

// MARK: - Quote Extraction Result

/// Parsed response from a quote extraction provider or the on-device fallback.
struct QuoteExtractionResult: Codable, Sendable {
    /// Extracted quotes from the page
    let quotes: [ExtractedQuoteData]

    /// Detected page number (if visible)
    let pageNumber: Int?

    /// Optional notes about the extraction process
    let processingNotes: String?

    /// Why on-device extraction was used after a remote attempt, if applicable.
    let fallbackReason: ExtractionFallbackReason?

    init(
        quotes: [ExtractedQuoteData],
        pageNumber: Int?,
        processingNotes: String?,
        fallbackReason: ExtractionFallbackReason? = nil
    ) {
        self.quotes = quotes
        self.pageNumber = pageNumber
        self.processingNotes = processingNotes
        self.fallbackReason = fallbackReason
    }

    /// Whether extraction was successful
    var isSuccessful: Bool {
        !quotes.isEmpty
    }

    /// Total number of quotes extracted
    var quoteCount: Int {
        quotes.count
    }

    /// Average confidence across all quotes
    var averageConfidence: Double {
        guard !quotes.isEmpty else { return 0 }
        let total = quotes.compactMap { $0.confidence }.reduce(0, +)
        let count = quotes.filter { $0.confidence != nil }.count
        return count > 0 ? total / Double(count) : 0
    }

    /// High confidence quotes only (>= 0.7)
    var highConfidenceQuotes: [ExtractedQuoteData] {
        quotes.filter { ($0.confidence ?? 0) >= 0.7 }
    }
}

// MARK: - Extracted Quote Data

enum QuoteExtractionSource: String, Codable, Sendable {
    case onDevice = "on_device"
    case modelAssisted = "model_assisted"
    case manual
    case unknown
}

extension QuoteExtractionSource {
    var reviewLabel: String {
        switch self {
        case .onDevice:
            return "On-device"
        case .modelAssisted:
            return "Model-assisted"
        case .manual:
            return "Manual"
        case .unknown:
            return "Source unavailable"
        }
    }

    var reviewSymbol: String {
        switch self {
        case .onDevice:
            return "iphone"
        case .modelAssisted:
            return "sparkles"
        case .manual:
            return "pencil"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

enum ExtractionFallbackReason: String, Codable, Sendable, Equatable {
    case remoteProcessingDisabled
    case remoteAuthenticationRequired
    case remoteSubscriptionRequired
    case remoteRateLimited
    case remoteUnavailable
    case remoteReturnedNoQuotes

    var reviewMessage: String {
        switch self {
        case .remoteProcessingDisabled:
            return "On-device extraction was used because remote processing is off."
        case .remoteAuthenticationRequired:
            return "On-device extraction was used because remote processing needs sign-in."
        case .remoteSubscriptionRequired:
            return "On-device extraction was used because remote processing needs a subscription."
        case .remoteRateLimited:
            return "On-device extraction was used while remote processing is temporarily limited."
        case .remoteUnavailable:
            return "On-device extraction was used because remote processing was unavailable."
        case .remoteReturnedNoQuotes:
            return "On-device extraction was used because remote processing found no marked text."
        }
    }

    static func from(_ error: Error) -> ExtractionFallbackReason {
        guard let extractionError = error as? ExtractionError else {
            return .remoteUnavailable
        }

        switch extractionError {
        case .thirdPartyAIConsentRequired:
            return .remoteProcessingDisabled
        case .authenticationRequired:
            return .remoteAuthenticationRequired
        case .subscriptionRequired:
            return .remoteSubscriptionRequired
        case .rateLimited:
            return .remoteRateLimited
        case .invalidImage, .networkError, .parsingError, .noQuotesFound:
            return .remoteUnavailable
        }
    }
}

/// Individual quote data from extraction response
struct ExtractedQuoteData: Codable, Sendable, Identifiable {
    let id: UUID = UUID()

    /// The extracted text content
    let text: String

    /// Page number for this specific quote (may differ from page-level)
    let pageNumber: Int?

    /// Transcribed margin note if present
    let marginNote: String?

    /// Type of marking detected
    let markingType: String

    /// AI confidence in this extraction (0.0-1.0)
    let confidence: Double?

    /// Where this quote candidate came from before review.
    let extractionSource: QuoteExtractionSource

    /// Local marking-definition identity resolved by the app, never supplied by a model response.
    let customMarkingDefinitionID: UUID?

    /// Reader-facing custom marking name captured with the result for review display.
    let customMarkingDisplayName: String?

    init(
        text: String,
        pageNumber: Int?,
        marginNote: String?,
        markingType: String,
        confidence: Double?,
        extractionSource: QuoteExtractionSource = .unknown,
        customMarkingDefinitionID: UUID? = nil,
        customMarkingDisplayName: String? = nil
    ) {
        self.text = text
        self.pageNumber = pageNumber
        self.marginNote = marginNote
        self.markingType = markingType
        self.confidence = confidence
        self.extractionSource = extractionSource
        self.customMarkingDefinitionID = customMarkingDefinitionID
        self.customMarkingDisplayName = customMarkingDisplayName
    }

    /// Convert to ExtractedQuote for saving
    func toExtractedQuote(customMarkingDefinition: MarkingDefinition? = nil) -> ExtractedQuote {
        ExtractedQuote(
            text: text,
            markingType: parseMarkingType(),
            confidence: confidence,
            pageNumber: pageNumber,
            marginNote: marginNote,
            customMarkingDefinition: customMarkingDefinition
        )
    }

    /// Parse marking type string to MarkingType enum
    private func parseMarkingType() -> MarkingType {
        let normalized = markingType.lowercased().replacingOccurrences(of: "_", with: " ")

        switch normalized {
        case "underline", "single underline":
            return .underline
        case "double underline":
            return .doubleUnderline
        case "highlight", "highlighted":
            return .highlight
        case "margin line", "vertical line", "sidebar":
            return .marginLine
        case "bracket", "brackets", "braces":
            return .bracket
        case "margin note", "note", "annotation":
            return .marginNote
        case "mixed":
            return .mixed
        default:
            // Map unrecognized types to closest match
            if normalized.contains("underline") {
                return .underline
            } else if normalized.contains("highlight") {
                return .highlight
            } else if normalized.contains("margin") && normalized.contains("note") {
                return .marginNote
            } else if normalized.contains("margin") {
                return .marginLine
            } else if normalized.contains("bracket") {
                return .bracket
            }
            return .mixed  // Default to mixed for unrecognized types
        }
    }

    private enum CodingKeys: String, CodingKey {
        case text
        case pageNumber
        case marginNote
        case markingType
        case confidence
        case extractionSource
        case customMarkingDefinitionID
        case customMarkingDisplayName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        pageNumber = try container.decodeIfPresent(Int.self, forKey: .pageNumber)
        marginNote = try container.decodeIfPresent(String.self, forKey: .marginNote)
        markingType = try container.decode(String.self, forKey: .markingType)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        extractionSource = try container.decodeIfPresent(QuoteExtractionSource.self, forKey: .extractionSource) ?? .unknown
        customMarkingDefinitionID = try container.decodeIfPresent(UUID.self, forKey: .customMarkingDefinitionID)
        customMarkingDisplayName = try container.decodeIfPresent(String.self, forKey: .customMarkingDisplayName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(pageNumber, forKey: .pageNumber)
        try container.encodeIfPresent(marginNote, forKey: .marginNote)
        try container.encode(markingType, forKey: .markingType)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encode(extractionSource, forKey: .extractionSource)
        try container.encodeIfPresent(customMarkingDefinitionID, forKey: .customMarkingDefinitionID)
        try container.encodeIfPresent(customMarkingDisplayName, forKey: .customMarkingDisplayName)
    }
}

// MARK: - Book Metadata Result

/// Legacy parsed response retained for compatibility with retired cover-extraction tests.
struct BookMetadataResult: Codable, Sendable {
    /// Extracted title
    let title: String

    /// Author name(s)
    let author: String

    /// Subtitle if present
    let subtitle: String?

    /// Publisher name
    let publisher: String?

    /// Publication year
    let publishYear: Int?

    /// Genre category
    let genre: String?

    /// ISBN if visible
    let isbn: String?

    /// Extraction confidence
    let confidence: Double

    /// Convert to Book model
    func toBook() -> Book {
        let book = Book(title: title, author: author)
        book.subtitle = subtitle
        book.publisher = publisher
        book.publishYear = publishYear
        book.genre = genre
        book.isbn = isbn
        return book
    }
}

// MARK: - Extraction Error

/// Errors that can occur during extraction
enum ExtractionError: LocalizedError {
    case invalidImage
    case networkError(Error)
    case parsingError(String)
    case noQuotesFound
    case rateLimited
    case subscriptionRequired
    case authenticationRequired
    case thirdPartyAIConsentRequired

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed"
        case .networkError:
            return "The extraction service could not be reached"
        case .parsingError:
            return "The extraction result could not be read"
        case .noQuotesFound:
            return "No marked passages were found in the image"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .subscriptionRequired:
            return "A subscription is required to continue"
        case .authenticationRequired:
            return "Please sign in to continue"
        case .thirdPartyAIConsentRequired:
            return "Remote AI processing is disabled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidImage:
            return "Try capturing a clearer image with better lighting"
        case .networkError:
            return "Try again, or continue with on-device extraction"
        case .parsingError:
            return "Try again, or review the image and add the quote manually"
        case .noQuotesFound:
            return "Make sure your markings are clearly visible in the image"
        case .rateLimited:
            return "Wait 30 seconds before trying again"
        case .subscriptionRequired:
            return "Subscribe to continue extracting quotes"
        case .authenticationRequired:
            return "Sign in with your Apple ID to continue"
        case .thirdPartyAIConsentRequired:
            return "Enable Remote AI Processing in Settings, or continue with on-device extraction"
        }
    }
}

// MARK: - JSON Parsing Extensions

extension QuoteExtractionResult {
    func withExtractionSource(_ source: QuoteExtractionSource) -> QuoteExtractionResult {
        QuoteExtractionResult(
            quotes: quotes.map { quote in
                ExtractedQuoteData(
                    text: quote.text,
                    pageNumber: quote.pageNumber,
                    marginNote: quote.marginNote,
                    markingType: quote.markingType,
                    confidence: quote.confidence,
                    extractionSource: source,
                    customMarkingDefinitionID: quote.customMarkingDefinitionID,
                    customMarkingDisplayName: quote.customMarkingDisplayName
                )
            },
            pageNumber: pageNumber,
            processingNotes: processingNotes,
            fallbackReason: fallbackReason
        )
    }

    func withFallbackReason(_ reason: ExtractionFallbackReason) -> QuoteExtractionResult {
        QuoteExtractionResult(
            quotes: quotes,
            pageNumber: pageNumber,
            processingNotes: processingNotes,
            fallbackReason: reason
        )
    }

    /// Associates model output with an enabled local definition after validation.
    func resolvingCustomMarkings(
        from markings: [QuoteExtractionPromptBuilder.MarkingPrompt]
    ) -> QuoteExtractionResult {
        QuoteExtractionResult(
            quotes: quotes.map { quote in
                guard let marking = markings.customMarking(forModelMarkingType: quote.markingType),
                      let definitionID = marking.definitionID else {
                    return quote
                }

                return ExtractedQuoteData(
                    text: quote.text,
                    pageNumber: quote.pageNumber,
                    marginNote: quote.marginNote,
                    markingType: quote.markingType,
                    confidence: quote.confidence,
                    extractionSource: quote.extractionSource,
                    customMarkingDefinitionID: definitionID,
                    customMarkingDisplayName: marking.name
                )
            },
            pageNumber: pageNumber,
            processingNotes: processingNotes,
            fallbackReason: fallbackReason
        )
    }

    /// Parse from JSON string response
    static func parse(from jsonString: String) throws -> QuoteExtractionResult {
        guard jsonString.lengthOfBytes(using: .utf8) <= QuoteExtractionOutputValidator.maximumResponseBytes else {
            throw ExtractionError.parsingError("Response exceeds the extraction size limit")
        }

        // Clean up common JSON issues
        var cleaned = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code block if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw ExtractionError.parsingError("Invalid UTF-8 string")
        }

        do {
            let rawResult = try JSONDecoder().decode(RawQuoteExtractionResult.self, from: data)
            guard rawResult.quotes.count <= QuoteExtractionOutputValidator.maximumCandidateCount else {
                throw ExtractionError.parsingError("Response contains too many quote candidates")
            }

            let quotes = rawResult.quotes.compactMap(QuoteExtractionOutputValidator.quote(from:))
            if !rawResult.quotes.isEmpty && quotes.isEmpty {
                throw ExtractionError.parsingError("Response contains no valid quote candidates")
            }

            return QuoteExtractionResult(
                quotes: quotes,
                pageNumber: QuoteExtractionOutputValidator.pageNumber(rawResult.pageNumber),
                processingNotes: QuoteExtractionOutputValidator.optionalText(
                    rawResult.processingNotes,
                    maximumLength: QuoteExtractionOutputValidator.maximumProcessingNotesLength
                )
            )
        } catch {
            if let extractionError = error as? ExtractionError {
                throw extractionError
            }
            throw ExtractionError.parsingError(error.localizedDescription)
        }
    }
}

extension BookMetadataResult {
    /// Parse from JSON string response
    static func parse(from jsonString: String) throws -> BookMetadataResult {
        guard jsonString.lengthOfBytes(using: .utf8) <= QuoteExtractionOutputValidator.maximumResponseBytes else {
            throw ExtractionError.parsingError("Response exceeds the extraction size limit")
        }

        var cleaned = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code block if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw ExtractionError.parsingError("Invalid UTF-8 string")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(BookMetadataResult.self, from: data)
        } catch {
            throw ExtractionError.parsingError(error.localizedDescription)
        }
    }
}

private struct RawQuoteExtractionResult: Decodable {
    let quotes: [RawExtractedQuoteData]
    let pageNumber: Int?
    let processingNotes: String?
}

private struct RawExtractedQuoteData: Decodable {
    let text: String?
    let pageNumber: Int?
    let marginNote: String?
    let markingType: String?
    let confidence: Double?
}

private enum QuoteExtractionOutputValidator {
    static let maximumResponseBytes = 128 * 1024
    static let maximumCandidateCount = 30
    static let maximumQuoteLength = 2_000
    static let maximumMarginNoteLength = 500
    static let maximumMarkingTypeLength = 64
    static let maximumProcessingNotesLength = 500
    static let maximumPageNumber = 10_000

    static func quote(from raw: RawExtractedQuoteData) -> ExtractedQuoteData? {
        guard let text = requiredText(raw.text, maximumLength: maximumQuoteLength) else {
            return nil
        }

        return ExtractedQuoteData(
            text: text,
            pageNumber: pageNumber(raw.pageNumber),
            marginNote: optionalText(raw.marginNote, maximumLength: maximumMarginNoteLength),
            markingType: markingType(raw.markingType),
            confidence: confidence(raw.confidence)
        )
    }

    static func pageNumber(_ value: Int?) -> Int? {
        guard let value, (1...maximumPageNumber).contains(value) else {
            return nil
        }
        return value
    }

    static func confidence(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
            return nil
        }
        return min(max(value, 0), 1)
    }

    static func optionalText(_ value: String?, maximumLength: Int) -> String? {
        guard let value else { return nil }
        return normalizedText(value, maximumLength: maximumLength)
    }

    private static func requiredText(_ value: String?, maximumLength: Int) -> String? {
        guard let value else { return nil }
        return normalizedText(value, maximumLength: maximumLength)
    }

    private static func normalizedText(_ value: String, maximumLength: Int) -> String? {
        let withoutControls = value.components(separatedBy: .controlCharacters).joined(separator: " ")
        let normalized = withoutControls
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        guard !normalized.isEmpty, normalized.count <= maximumLength else {
            return nil
        }
        return normalized
    }

    private static func markingType(_ value: String?) -> String {
        guard let value else { return "mixed" }

        var result = ""
        var needsSeparator = false
        for scalar in value.lowercased().unicodeScalars {
            switch scalar.value {
            case 97...122, 48...57:
                if needsSeparator && !result.isEmpty {
                    result.append("_")
                }
                result.unicodeScalars.append(scalar)
                needsSeparator = false
            default:
                needsSeparator = !result.isEmpty
            }
        }

        let normalized = String(result.prefix(maximumMarkingTypeLength))
        return normalized.isEmpty ? "mixed" : normalized
    }
}
