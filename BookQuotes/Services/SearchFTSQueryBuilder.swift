import Foundation

extension SearchDatabase {
    /// Builds an FTS5 query with prefix matching for instant search.
    func buildFTSQuery(_ input: String) -> String {
        let terms = input
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !terms.isEmpty, let last = terms.last else {
            return ""
        }

        // Add prefix operator to last term for instant-as-you-type search.
        if terms.count == 1 {
            return "\(last)*"
        }

        let allButLast = terms.dropLast().joined(separator: " ")
        return "\(allButLast) \(last)*"
    }
}
