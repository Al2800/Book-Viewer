import Foundation

// MARK: - ISBN Validator

/// Utility for validating ISBN-10 and ISBN-13 codes.
/// ISBN-10: 10 digits with mod-11 checksum
/// ISBN-13: 13 digits starting with 978/979 with mod-10 checksum
enum ISBNValidator {
    // MARK: - Validation Result

    enum ValidationResult: Equatable {
        case valid(normalized: String)
        case invalid(reason: String)

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }

        var normalizedISBN: String? {
            if case .valid(let normalized) = self { return normalized }
            return nil
        }
    }

    // MARK: - Public API

    /// Validate and normalize an ISBN string.
    /// Accepts ISBN-10 or ISBN-13 with or without hyphens/spaces.
    /// - Parameter isbn: The ISBN string to validate
    /// - Returns: ValidationResult indicating validity and normalized form
    static func validate(_ isbn: String) -> ValidationResult {
        // Remove hyphens, spaces, and normalize
        let cleaned = isbn
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        switch cleaned.count {
        case 10:
            return validateISBN10(cleaned)
        case 13:
            return validateISBN13(cleaned)
        default:
            return .invalid(reason: "ISBN must be 10 or 13 characters, got \(cleaned.count)")
        }
    }

    /// Quick check if a string is a valid ISBN
    static func isValid(_ isbn: String) -> Bool {
        validate(isbn).isValid
    }

    /// Convert ISBN-10 to ISBN-13 format
    static func toISBN13(_ isbn10: String) -> String? {
        let cleaned = isbn10
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard cleaned.count == 10 else { return nil }
        guard validateISBN10(cleaned).isValid else { return nil }

        // Take first 9 digits, prepend 978
        let base = "978" + cleaned.prefix(9)
        let checkDigit = calculateISBN13CheckDigit(String(base))
        return base + String(checkDigit)
    }

    /// Convert ISBN-13 to ISBN-10 format (only works for 978-prefixed ISBNs)
    static func toISBN10(_ isbn13: String) -> String? {
        let cleaned = isbn13
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard cleaned.count == 13 else { return nil }
        guard cleaned.hasPrefix("978") else { return nil }
        guard validateISBN13(cleaned).isValid else { return nil }

        // Take digits 4-12, calculate ISBN-10 check digit
        let base = String(cleaned.dropFirst(3).prefix(9))
        let checkDigit = calculateISBN10CheckDigit(base)
        return base + checkDigit
    }

    // MARK: - ISBN-10 Validation

    private static func validateISBN10(_ isbn: String) -> ValidationResult {
        guard isbn.count == 10 else {
            return .invalid(reason: "ISBN-10 must be exactly 10 characters")
        }

        // First 9 must be digits, last can be digit or X
        let chars = Array(isbn)
        for (index, char) in chars.enumerated() {
            if index < 9 {
                guard char.isNumber else {
                    return .invalid(reason: "ISBN-10 first 9 characters must be digits")
                }
            } else {
                guard char.isNumber || char == "X" else {
                    return .invalid(reason: "ISBN-10 check digit must be digit or X")
                }
            }
        }

        // Calculate checksum: sum of (10-i) * digit_i for i=0..9, mod 11 should equal 0
        var sum = 0
        for (index, char) in chars.enumerated() {
            let value: Int
            if char == "X" {
                value = 10
            } else {
                value = Int(String(char))!
            }
            sum += (10 - index) * value
        }

        if sum % 11 == 0 {
            return .valid(normalized: isbn)
        } else {
            return .invalid(reason: "ISBN-10 checksum invalid")
        }
    }

    private static func calculateISBN10CheckDigit(_ base9: String) -> String {
        guard base9.count == 9 else { return "0" }

        var sum = 0
        for (index, char) in base9.enumerated() {
            guard let digit = Int(String(char)) else { continue }
            sum += (10 - index) * digit
        }

        let remainder = sum % 11
        let checkValue = (11 - remainder) % 11

        return checkValue == 10 ? "X" : String(checkValue)
    }

    // MARK: - ISBN-13 Validation

    private static func validateISBN13(_ isbn: String) -> ValidationResult {
        guard isbn.count == 13 else {
            return .invalid(reason: "ISBN-13 must be exactly 13 characters")
        }

        // All must be digits
        guard isbn.allSatisfy({ $0.isNumber }) else {
            return .invalid(reason: "ISBN-13 must contain only digits")
        }

        // Must start with 978 or 979
        guard isbn.hasPrefix("978") || isbn.hasPrefix("979") else {
            return .invalid(reason: "ISBN-13 must start with 978 or 979")
        }

        // Calculate checksum: alternating weights 1,3,1,3... mod 10 should equal 0
        var sum = 0
        for (index, char) in isbn.enumerated() {
            guard let digit = Int(String(char)) else { continue }
            let weight = index % 2 == 0 ? 1 : 3
            sum += digit * weight
        }

        if sum % 10 == 0 {
            return .valid(normalized: isbn)
        } else {
            return .invalid(reason: "ISBN-13 checksum invalid")
        }
    }

    private static func calculateISBN13CheckDigit(_ base12: String) -> Int {
        guard base12.count == 12 else { return 0 }

        var sum = 0
        for (index, char) in base12.enumerated() {
            guard let digit = Int(String(char)) else { continue }
            let weight = index % 2 == 0 ? 1 : 3
            sum += digit * weight
        }

        return (10 - (sum % 10)) % 10
    }
}

// MARK: - Barcode to ISBN Conversion

extension ISBNValidator {
    /// Convert EAN-13 barcode payload to ISBN if applicable.
    /// EAN-13 barcodes with 978/979 prefix are ISBNs.
    static func isbnFromBarcode(_ barcode: String) -> String? {
        let cleaned = barcode
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        // EAN-13 with book prefix
        if cleaned.count == 13 && (cleaned.hasPrefix("978") || cleaned.hasPrefix("979")) {
            return validate(cleaned).normalizedISBN
        }

        // UPC-E expanded to EAN-13 (rare for books)
        if cleaned.count == 8 {
            // UPC-E to EAN-13 expansion would go here
            // Books rarely use UPC-E, so skipping for now
            return nil
        }

        return nil
    }
}

// MARK: - ISBN Formatting

extension ISBNValidator {
    /// Format an ISBN with hyphens for display.
    /// Note: Proper ISBN formatting requires registration group data.
    /// This provides a simple visual grouping.
    static func format(_ isbn: String) -> String {
        let cleaned = isbn
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch cleaned.count {
        case 10:
            // Simple format: X-XXX-XXXXX-X
            let i = cleaned.startIndex
            return "\(cleaned[i])-\(cleaned[cleaned.index(i, offsetBy: 1)..<cleaned.index(i, offsetBy: 4)])-\(cleaned[cleaned.index(i, offsetBy: 4)..<cleaned.index(i, offsetBy: 9)])-\(cleaned[cleaned.index(i, offsetBy: 9)])"

        case 13:
            // Simple format: XXX-X-XXX-XXXXX-X
            let i = cleaned.startIndex
            return "\(cleaned[i..<cleaned.index(i, offsetBy: 3)])-\(cleaned[cleaned.index(i, offsetBy: 3)])-\(cleaned[cleaned.index(i, offsetBy: 4)..<cleaned.index(i, offsetBy: 7)])-\(cleaned[cleaned.index(i, offsetBy: 7)..<cleaned.index(i, offsetBy: 12)])-\(cleaned[cleaned.index(i, offsetBy: 12)])"

        default:
            return isbn
        }
    }
}
