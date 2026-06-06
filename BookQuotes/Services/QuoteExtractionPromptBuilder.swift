import Foundation

// MARK: - Quote Extraction Prompt Builder

/// Builds dynamic prompts for Gemini API quote extraction.
/// Incorporates user's custom marking vocabulary for personalized extraction.
enum QuoteExtractionPromptBuilder {

    // MARK: - Prompt Generation

    /// Concurrency-safe snapshot of a marking definition used for prompt building.
    ///
    /// Avoid passing SwiftData model objects (e.g. `MarkingDefinition`) across concurrency domains.
    struct MarkingPrompt: Sendable {
        let name: String
        let visualDescription: String
        let meaning: String
        let isEnabled: Bool

        init(
            name: String,
            visualDescription: String,
            meaning: String,
            isEnabled: Bool = true
        ) {
            self.name = name
            self.visualDescription = visualDescription
            self.meaning = meaning
            self.isEnabled = isEnabled
        }

        init(_ definition: MarkingDefinition) {
            self.init(
                name: definition.name,
                visualDescription: definition.visualDescription,
                meaning: definition.meaning,
                isEnabled: definition.isEnabled
            )
        }
    }

    /// Build a quote extraction prompt with user's marking definitions
    /// - Parameter markings: User's enabled marking definitions
    /// - Returns: Complete prompt string for Gemini API
    static func buildPrompt(markings: [MarkingDefinition]) -> String {
        buildPrompt(markingPrompts: markings.map(MarkingPrompt.init))
    }

    /// Build a quote extraction prompt with marking definitions snapshots.
    static func buildPrompt(markingPrompts: [MarkingPrompt]) -> String {
        let enabledMarkings = markingPrompts.filter { $0.isEnabled }

        // Build marking descriptions
        let markingDescriptions = enabledMarkings.map { marking in
            """
            - **\(marking.name)**: \(marking.visualDescription)
              Meaning: \(marking.meaning)
            """
        }.joined(separator: "\n")

        // Build marking type enum for JSON schema
        let markingTypes = enabledMarkings.map {
            "\"\(normalizeMarkingType($0.name))\""
        }.joined(separator: " | ")

        // Default marking types if user has none enabled
        let effectiveMarkingTypes = markingTypes.isEmpty
            ? "\"underline\" | \"highlight\" | \"margin_note\" | \"bracket\" | \"circle\""
            : markingTypes

        return """
        Analyze this book page image to extract marked/highlighted passages.

        The reader uses the following marking system:

        \(markingDescriptions.isEmpty ? defaultMarkingDescriptions : markingDescriptions)

        Return a JSON object with this exact structure:
        {
          "quotes": [
            {
              "text": "The exact text that was marked",
              "pageNumber": 42,
              "marginNote": "Any handwritten note near this passage, or null",
              "markingType": \(effectiveMarkingTypes),
              "confidence": 0.92
            }
          ],
          "pageNumber": 42,
          "processingNotes": "Optional notes about extraction quality"
        }

        Rules:
        1. Extract COMPLETE marked passages - include full sentences when the marking extends across partial text
        2. For **Margin Line** (vertical line in the margin): capture ALL text aligned with the line, starting where the line begins and stopping exactly where the line ends. If the line spans multiple sentences/paragraphs, include the full span.
        3. Match marking type to the user's vocabulary above
        4. If multiple marking types are present on the same passage, use the primary/most prominent one
        5. Preserve original punctuation and formatting where meaningful
        6. Transcribe handwritten margin notes accurately - include spelling as written
        7. Page number: only read a page number if it appears as a standalone number in the page margin/footer/header (top-left, top-right, bottom-left, bottom-right). Never infer from body text (e.g., dates, references, "Falcon 9", chapter numbers). If you are not confident the number is a page number, set pageNumber to null (both at the page level and per-quote).
        8. Each separate marked passage should be its own quote object
        9. Set confidence (0.0-1.0) based on extraction accuracy:
           - 0.9+ : Clear text, unambiguous marking
           - 0.7-0.9 : Minor uncertainty about boundaries or exact text
           - 0.5-0.7 : Significant uncertainty, text may be partially obscured
           - <0.5 : Low confidence, marking unclear or text hard to read
        10. If a passage appears intentionally marked but boundaries are uncertain, return best-effort marked text with lower confidence rather than dropping it.
        11. Do not return an empty quotes array when readable marked text is visible. Only return an empty quotes array when no marked/readable text is visible at all.

        Respond with ONLY valid JSON. No markdown formatting, no code blocks, no explanatory text.
        """
    }

    /// Build a simplified prompt for quick extraction (fewer instructions)
    static func buildQuickPrompt(markings: [MarkingDefinition]) -> String {
        buildQuickPrompt(markingPrompts: markings.map(MarkingPrompt.init))
    }

    /// Build a simplified prompt for quick extraction (fewer instructions) using marking snapshots.
    static func buildQuickPrompt(markingPrompts: [MarkingPrompt]) -> String {
        let enabledMarkings = markingPrompts.filter { $0.isEnabled }
        let markingNames = enabledMarkings.map { $0.name }.joined(separator: ", ")

        return """
        Extract marked text from this book page.

        Look for: \(markingNames.isEmpty ? "underlines, highlights, margin notes" : markingNames)

        Return JSON:
        {"quotes":[{"text":"marked text","markingType":"type","confidence":0.9}],"pageNumber":null}

        Page number rule: only set pageNumber if a standalone number appears in the page margin/header/footer (top-left, top-right, bottom-left, bottom-right). Never infer from body text.
        If readable marked text is visible but the boundaries are uncertain, return best-effort text with lower confidence.
        Do not return an empty quotes array unless no marked/readable text is visible.

        JSON only, no markdown.
        """
    }

    // MARK: - Helpers

    /// Normalize marking name to snake_case for JSON
    private static func normalizeMarkingType(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    /// Default marking descriptions when user has none
    private static var defaultMarkingDescriptions: String {
        """
        - **Underline**: Single line drawn under text - Important passage
        - **Highlight**: Text colored with highlighter - Key passage to remember
        - **Margin Line**: Vertical line in margin - Capture all text aligned with the line, from where it starts to where it ends
        - **Bracket**: Brackets around text - Discrete section of interest
        - **Circle**: Circle around word/phrase - Key term or concept
        - **Margin Note**: Handwritten text in margin - Personal thought
        """
    }
}

// MARK: - Cover Metadata Extraction Prompt

extension QuoteExtractionPromptBuilder {
    /// Build prompt for book cover metadata extraction
    static func buildCoverExtractionPrompt() -> String {
        """
        Analyze this book cover image and extract metadata.

        Return a JSON object with these fields:
        {
          "title": "The exact book title as printed",
          "author": "Author name(s), comma-separated if multiple",
          "subtitle": "Subtitle if present, or null",
          "publisher": "Publisher name if visible, or null",
          "publishYear": 2023 or null,
          "genre": "Best guess at genre category",
          "isbn": "ISBN if visible on cover, or null",
          "confidence": 0.95
        }

        Rules:
        1. Extract the EXACT title as printed on the cover
        2. For multiple authors, use comma separation: "Author One, Author Two"
        3. Genre should be a single category: Fiction, Non-Fiction, Biography, Science, History, Self-Help, Business, Philosophy, etc.
        4. confidence is 0.0-1.0 for overall extraction accuracy
        5. Only include ISBN if clearly visible (usually on back cover)
        6. Ignore praise quotes, reviews, bestseller badges, award text, endorsement copy, and marketing blurbs.
        7. Do not include praise, publication names, review quotes, bestseller text, awards, or marketing copy in the title, subtitle, or author fields.

        Respond with ONLY valid JSON. No markdown, no code blocks.
        """
    }
}
