import Foundation

// MARK: - Quote Extraction Result

/// Parsed response from Gemini API quote extraction.
struct QuoteExtractionResult: Codable, Sendable {
    /// Extracted quotes from the page
    let quotes: [ExtractedQuoteData]

    /// Detected page number (if visible)
    let pageNumber: Int?

    /// Optional notes about the extraction process
    let processingNotes: String?

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

    init(
        text: String,
        pageNumber: Int?,
        marginNote: String?,
        markingType: String,
        confidence: Double?,
        extractionSource: QuoteExtractionSource = .unknown
    ) {
        self.text = text
        self.pageNumber = pageNumber
        self.marginNote = marginNote
        self.markingType = markingType
        self.confidence = confidence
        self.extractionSource = extractionSource
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        pageNumber = try container.decodeIfPresent(Int.self, forKey: .pageNumber)
        marginNote = try container.decodeIfPresent(String.self, forKey: .marginNote)
        markingType = try container.decode(String.self, forKey: .markingType)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        extractionSource = try container.decodeIfPresent(QuoteExtractionSource.self, forKey: .extractionSource) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(pageNumber, forKey: .pageNumber)
        try container.encodeIfPresent(marginNote, forKey: .marginNote)
        try container.encode(markingType, forKey: .markingType)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encode(extractionSource, forKey: .extractionSource)
    }
}

// MARK: - Book Metadata Result

/// Parsed response from Gemini API cover extraction
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
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let details):
            return "Failed to parse response: \(details)"
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
            return "Check your internet connection and try again"
        case .parsingError:
            return "Try capturing the image again"
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
                    extractionSource: source
                )
            },
            pageNumber: pageNumber,
            processingNotes: processingNotes
        )
    }

    /// Parse from JSON string response
    static func parse(from jsonString: String) throws -> QuoteExtractionResult {
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
            let decoder = JSONDecoder()
            return try decoder.decode(QuoteExtractionResult.self, from: data)
        } catch {
            throw ExtractionError.parsingError(error.localizedDescription)
        }
    }
}

extension BookMetadataResult {
    /// Parse from JSON string response
    static func parse(from jsonString: String) throws -> BookMetadataResult {
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
