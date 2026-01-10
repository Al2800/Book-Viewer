import XCTest

@testable import BookQuotes

// MARK: - LevenshteinDistanceTests

/// Unit tests for Levenshtein distance algorithm.
final class LevenshteinDistanceTests: XCTestCase {

    // MARK: - Properties

    var logger: TestLogger!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        logger = TestLogger(testName: name)
    }

    override func tearDown() {
        print(logger.summary())
        super.tearDown()
    }

    // MARK: - Basic Distance Tests

    func testLevenshtein_IdenticalStrings_ReturnsZero() {
        XCTAssertEqual(levenshteinDistance("hello", "hello"), 0)
        XCTAssertEqual(levenshteinDistance("", ""), 0)
        XCTAssertEqual(levenshteinDistance("test", "test"), 0)
        XCTAssertEqual(levenshteinDistance("a", "a"), 0)
        XCTAssertEqual(levenshteinDistance("longer string here", "longer string here"), 0)

        logger.success("Identical strings return distance 0")
    }

    func testLevenshtein_OneCharDifference_ReturnsOne() {
        // Substitution
        XCTAssertEqual(levenshteinDistance("cat", "bat"), 1)
        XCTAssertEqual(levenshteinDistance("dog", "fog"), 1)

        // Insertion
        XCTAssertEqual(levenshteinDistance("cat", "cats"), 1)
        XCTAssertEqual(levenshteinDistance("a", "ab"), 1)

        // Deletion
        XCTAssertEqual(levenshteinDistance("cats", "cat"), 1)
        XCTAssertEqual(levenshteinDistance("ab", "a"), 1)

        logger.success("Single edit distance = 1")
    }

    func testLevenshtein_MultipleEdits_ReturnsCorrectDistance() {
        // Classic examples
        XCTAssertEqual(levenshteinDistance("kitten", "sitting"), 3)
        XCTAssertEqual(levenshteinDistance("saturday", "sunday"), 3)

        // Two substitutions
        XCTAssertEqual(levenshteinDistance("book", "back"), 2)

        // Mix of operations
        XCTAssertEqual(levenshteinDistance("abc", "xyz"), 3)
        XCTAssertEqual(levenshteinDistance("intention", "execution"), 5)

        logger.success("Multiple edits calculated correctly")
    }

    func testLevenshtein_EmptyString_ReturnsOtherLength() {
        XCTAssertEqual(levenshteinDistance("", "hello"), 5)
        XCTAssertEqual(levenshteinDistance("hello", ""), 5)
        XCTAssertEqual(levenshteinDistance("", "a"), 1)
        XCTAssertEqual(levenshteinDistance("a", ""), 1)
        XCTAssertEqual(levenshteinDistance("", "ab"), 2)

        logger.success("Empty string distance = other string length")
    }

    func testLevenshtein_CommonTypos_CatchesWithinThreshold() {
        // Common typos should have distance <= 2
        XCTAssertLessThanOrEqual(levenshteinDistance("hapiness", "happiness"), 2)
        XCTAssertLessThanOrEqual(levenshteinDistance("recieve", "receive"), 2)
        XCTAssertLessThanOrEqual(levenshteinDistance("occurence", "occurrence"), 2)
        XCTAssertLessThanOrEqual(levenshteinDistance("seperate", "separate"), 2)
        XCTAssertLessThanOrEqual(levenshteinDistance("accomodate", "accommodate"), 2)
        XCTAssertLessThanOrEqual(levenshteinDistance("definately", "definitely"), 2)

        logger.success("Common typos within threshold")
    }

    func testLevenshtein_CaseSensitive() {
        XCTAssertEqual(levenshteinDistance("Hello", "hello"), 1)
        XCTAssertEqual(levenshteinDistance("HELLO", "hello"), 5)
        XCTAssertEqual(levenshteinDistance("Test", "test"), 1)
        XCTAssertEqual(levenshteinDistance("ABC", "abc"), 3)

        logger.success("Case sensitivity works correctly")
    }

    // MARK: - Similarity Tests

    func testSimilarity_IdenticalStrings_ReturnsOne() {
        XCTAssertEqual(levenshteinSimilarity("hello", "hello"), 1.0)
        XCTAssertEqual(levenshteinSimilarity("test", "test"), 1.0)
        XCTAssertEqual(levenshteinSimilarity("", ""), 1.0)

        logger.success("Identical strings return similarity 1.0")
    }

    func testSimilarity_CompletelyDifferent_ReturnsZero() {
        XCTAssertEqual(levenshteinSimilarity("abc", "xyz"), 0.0)
        XCTAssertEqual(levenshteinSimilarity("a", "b"), 0.0)

        logger.success("Completely different strings return similarity 0.0")
    }

    func testSimilarity_PartialMatch_ReturnsFraction() {
        // "cat" vs "cats" - 1 edit in 4 chars = 0.75 similarity
        let catsSimilarity = levenshteinSimilarity("cat", "cats")
        XCTAssertEqual(catsSimilarity, 0.75, accuracy: 0.01)

        // "hello" vs "hallo" - 1 edit in 5 chars = 0.8 similarity
        let halloSimilarity = levenshteinSimilarity("hello", "hallo")
        XCTAssertEqual(halloSimilarity, 0.8, accuracy: 0.01)

        logger.success("Partial matches return correct fraction")
    }

    func testSimilarity_OneEmpty_ReturnsZero() {
        XCTAssertEqual(levenshteinSimilarity("", "hello"), 0.0)
        XCTAssertEqual(levenshteinSimilarity("hello", ""), 0.0)

        logger.success("Empty vs non-empty returns similarity 0.0")
    }

    // MARK: - Case Insensitive Tests

    func testCaseInsensitive_IgnoresCase() {
        XCTAssertEqual(levenshteinDistanceCaseInsensitive("Hello", "hello"), 0)
        XCTAssertEqual(levenshteinDistanceCaseInsensitive("HELLO", "hello"), 0)
        XCTAssertEqual(levenshteinDistanceCaseInsensitive("HeLLo", "hEllO"), 0)

        logger.success("Case insensitive distance ignores case")
    }

    func testCaseInsensitiveSimilarity_IgnoresCase() {
        XCTAssertEqual(levenshteinSimilarityCaseInsensitive("Hello", "hello"), 1.0)
        XCTAssertEqual(levenshteinSimilarityCaseInsensitive("TEST", "test"), 1.0)

        logger.success("Case insensitive similarity ignores case")
    }

    // MARK: - String Extension Tests

    func testStringExtension_Distance() {
        XCTAssertEqual("hello".levenshteinDistance(to: "hallo"), 1)
        XCTAssertEqual("cat".levenshteinDistance(to: "cats"), 1)

        logger.success("String extension distance works")
    }

    func testStringExtension_Similarity() {
        XCTAssertEqual("hello".levenshteinSimilarity(to: "hello"), 1.0)
        XCTAssertEqual("cat".levenshteinSimilarity(to: "cats"), 0.75, accuracy: 0.01)

        logger.success("String extension similarity works")
    }

    func testStringExtension_IsSimilar() {
        // Default threshold 0.85
        XCTAssertTrue("happiness".isSimilar(to: "happiness"))
        XCTAssertFalse("cat".isSimilar(to: "elephant"))

        // Custom threshold
        XCTAssertTrue("cat".isSimilar(to: "cats", threshold: 0.70))
        XCTAssertFalse("cat".isSimilar(to: "cats", threshold: 0.80))

        logger.success("String extension isSimilar works")
    }

    // MARK: - Unicode Tests

    func testLevenshtein_Unicode_HandlesCorrectly() {
        // Japanese characters
        XCTAssertEqual(levenshteinDistance("日本", "日本"), 0)
        XCTAssertEqual(levenshteinDistance("日本", "日本語"), 1)

        // Emoji
        XCTAssertEqual(levenshteinDistance("hello", "hello"), 0)
        XCTAssertEqual(levenshteinDistance("a", "b"), 1)

        // Accented characters
        XCTAssertEqual(levenshteinDistance("cafe", "café"), 1)
        XCTAssertEqual(levenshteinDistance("resume", "résumé"), 2)

        logger.success("Unicode characters handled correctly")
    }

    // MARK: - Symmetry Tests

    func testLevenshtein_IsSymmetric() {
        XCTAssertEqual(levenshteinDistance("abc", "def"), levenshteinDistance("def", "abc"))
        XCTAssertEqual(levenshteinDistance("kitten", "sitting"), levenshteinDistance("sitting", "kitten"))
        XCTAssertEqual(levenshteinDistance("", "hello"), levenshteinDistance("hello", ""))

        logger.success("Levenshtein distance is symmetric")
    }

    // MARK: - Performance Tests

    func testLevenshtein_LongStrings_CompletesQuickly() {
        let string1 = String(repeating: "a", count: 100)
        let string2 = String(repeating: "b", count: 100)

        let start = CFAbsoluteTimeGetCurrent()
        _ = levenshteinDistance(string1, string2)
        let duration = CFAbsoluteTimeGetCurrent() - start

        XCTAssertLessThan(duration, 0.1, "Should complete in < 100ms")
        logger.info("Long string comparison took \(String(format: "%.2f", duration * 1000))ms")

        logger.success("Long string comparison completes quickly")
    }

    func testLevenshtein_MediumStrings_Performance() {
        let iterations = 100
        var totalDuration: Double = 0

        for _ in 0..<iterations {
            let s1 = "The quick brown fox jumps over the lazy dog"
            let s2 = "The quick brown cat jumps over the lazy dog"

            let start = CFAbsoluteTimeGetCurrent()
            _ = levenshteinDistance(s1, s2)
            totalDuration += CFAbsoluteTimeGetCurrent() - start
        }

        let avgMs = (totalDuration / Double(iterations)) * 1000
        XCTAssertLessThan(avgMs, 1.0, "Average should be < 1ms")
        logger.info("Average medium string comparison: \(String(format: "%.3f", avgMs))ms")

        logger.success("Medium string performance acceptable")
    }

    // MARK: - Edge Cases

    func testLevenshtein_SingleCharacterStrings() {
        XCTAssertEqual(levenshteinDistance("a", "a"), 0)
        XCTAssertEqual(levenshteinDistance("a", "b"), 1)
        XCTAssertEqual(levenshteinDistance("a", ""), 1)
        XCTAssertEqual(levenshteinDistance("", "a"), 1)

        logger.success("Single character strings handled")
    }

    func testLevenshtein_RepeatingCharacters() {
        XCTAssertEqual(levenshteinDistance("aaaa", "aaaa"), 0)
        XCTAssertEqual(levenshteinDistance("aaaa", "aaa"), 1)
        XCTAssertEqual(levenshteinDistance("aaaa", "aaaaa"), 1)
        XCTAssertEqual(levenshteinDistance("aaaa", "bbbb"), 4)

        logger.success("Repeating character strings handled")
    }

    func testLevenshtein_SpecialCharacters() {
        XCTAssertEqual(levenshteinDistance("hello!", "hello?"), 1)
        XCTAssertEqual(levenshteinDistance("test@email.com", "test@email.org"), 3)
        XCTAssertEqual(levenshteinDistance("$100", "$200"), 1)

        logger.success("Special characters handled")
    }
}
