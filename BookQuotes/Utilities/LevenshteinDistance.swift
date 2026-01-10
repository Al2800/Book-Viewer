import Foundation

// MARK: - Levenshtein Distance

/// Calculate the Levenshtein edit distance between two strings.
/// This is the minimum number of single-character edits (insertions,
/// deletions, substitutions) required to transform one string into another.
///
/// Uses optimized O(n) space dynamic programming algorithm.
///
/// - Parameters:
///   - s1: First string
///   - s2: Second string
/// - Returns: Edit distance (0 = identical strings)
func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    // Handle empty string edge cases
    guard !s1.isEmpty else { return s2.count }
    guard !s2.isEmpty else { return s1.count }

    // Convert to arrays for O(1) indexing
    let a = Array(s1)
    let b = Array(s2)

    // Optimize by making the shorter string the column
    if a.count > b.count {
        return levenshteinDistance(s2, s1)
    }

    // Use single array with O(min(m,n)) space
    var dp = Array(0...a.count)

    for j in 1...b.count {
        var prev = dp[0]
        dp[0] = j

        for i in 1...a.count {
            let temp = dp[i]
            if a[i - 1] == b[j - 1] {
                // Characters match - no edit needed
                dp[i] = prev
            } else {
                // Min of: substitution, deletion, insertion
                dp[i] = min(prev, dp[i], dp[i - 1]) + 1
            }
            prev = temp
        }
    }

    return dp[a.count]
}

/// Calculate normalized similarity between two strings based on Levenshtein distance.
/// Returns a value between 0.0 (completely different) and 1.0 (identical).
///
/// - Parameters:
///   - s1: First string
///   - s2: Second string
/// - Returns: Similarity score (0.0 to 1.0)
func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
    let distance = levenshteinDistance(s1, s2)
    let maxLength = max(s1.count, s2.count)
    guard maxLength > 0 else { return 1.0 }
    return 1.0 - (Double(distance) / Double(maxLength))
}

/// Calculate Levenshtein distance with case-insensitive comparison.
///
/// - Parameters:
///   - s1: First string
///   - s2: Second string
/// - Returns: Edit distance ignoring case
func levenshteinDistanceCaseInsensitive(_ s1: String, _ s2: String) -> Int {
    levenshteinDistance(s1.lowercased(), s2.lowercased())
}

/// Calculate similarity with case-insensitive comparison.
///
/// - Parameters:
///   - s1: First string
///   - s2: Second string
/// - Returns: Similarity score (0.0 to 1.0) ignoring case
func levenshteinSimilarityCaseInsensitive(_ s1: String, _ s2: String) -> Double {
    levenshteinSimilarity(s1.lowercased(), s2.lowercased())
}

// MARK: - String Extension

extension String {
    /// Calculate Levenshtein distance to another string.
    func levenshteinDistance(to other: String) -> Int {
        BookQuotes.levenshteinDistance(self, other)
    }

    /// Calculate similarity to another string (0.0 to 1.0).
    func levenshteinSimilarity(to other: String) -> Double {
        BookQuotes.levenshteinSimilarity(self, other)
    }

    /// Check if this string is similar to another within a threshold.
    /// - Parameters:
    ///   - other: String to compare against
    ///   - threshold: Minimum similarity score (default 0.85)
    /// - Returns: true if similarity >= threshold
    func isSimilar(to other: String, threshold: Double = 0.85) -> Bool {
        levenshteinSimilarity(to: other) >= threshold
    }
}
