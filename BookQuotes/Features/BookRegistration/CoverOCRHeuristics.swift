import CoreGraphics
import Foundation

/// Pure heuristics used by the OCR cover fallback to derive title/author from Vision text lines.
struct CoverOCRHeuristics {

    static func sanitizeLine(_ line: String) -> String {
        var s = line
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Drop common UI/irrelevant strings if they leak into the crop.
        let lowered = s.lowercased()
        if lowered.contains("cancel") ||
            lowered.contains("add book") ||
            lowered.contains("add new book") ||
            lowered.contains("confirm book") {
            return ""
        }

        // Drop barcode/ISBN-heavy lines.
        let digitCount = s.filter { $0.isNumber }.count
        if digitCount >= max(5, s.count / 3) {
            return ""
        }

        // Remove leading "BY " patterns.
        if lowered.hasPrefix("by ") {
            s = String(s.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return s
    }

    static func guessTitleAndAuthor(from lines: [(text: String, box: CGRect)]) -> (title: String, author: String) {
        guard !lines.isEmpty else { return ("", "") }

        // Prefer text near the top for title.
        let topLines = lines.filter { $0.box.midY > 0.55 }.map(\.text)
        let allLines = lines.map(\.text)
        let titleSource = topLines.isEmpty ? allLines : topLines

        let title = buildTitle(from: titleSource)
        let author = findAuthor(in: lines) ?? ""
        return (title, author)
    }

    private static func buildTitle(from lines: [String]) -> String {
        var parts: [String] = []
        var total = 0
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard t.count >= 3 else { continue }
            if t.lowercased().contains("isbn") { continue }
            parts.append(t)
            total += t.count
            if parts.count >= 3 || total >= 40 {
                break
            }
        }
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func findAuthor(in lines: [(text: String, box: CGRect)]) -> String? {
        for item in lines {
            let lowered = item.text.lowercased()
            if lowered.hasPrefix("by ") {
                return String(item.text.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let range = lowered.range(of: " by ") {
                let author = item.text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if author.count >= 3 { return author }
            }
        }

        let bottomCandidates = lines
            .filter { $0.box.midY < 0.45 }
            .sorted { $0.box.midY < $1.box.midY }
            .map(\.text)
            .filter { $0.count >= 5 && $0.count <= 40 }
            .filter { !$0.lowercased().contains("isbn") }

        for text in bottomCandidates {
            let words = text.split(separator: " ")
            if (2...5).contains(words.count) {
                return text
            }
        }
        return bottomCandidates.first
    }
}
