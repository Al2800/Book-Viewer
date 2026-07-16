import Foundation

/// The type of marking used to highlight a passage in a book.
enum MarkingType: String, Codable, CaseIterable, Identifiable {
    case underline = "underline"
    case doubleUnderline = "double_underline"
    case marginLine = "margin_line"
    case highlight = "highlight"
    case marginNote = "margin_note"
    case bracket = "bracket"
    case mixed = "mixed"

    var id: String { rawValue }

    /// Concrete styles a reader can intentionally configure. `mixed` is an
    /// extraction result, not a marking style someone can choose.
    static let configurableCases: [MarkingType] = [
        .underline,
        .doubleUnderline,
        .marginLine,
        .highlight,
        .marginNote,
        .bracket
    ]

    var displayName: String {
        switch self {
        case .underline: return "Underline"
        case .doubleUnderline: return "Double Underline"
        case .marginLine: return "Margin Line"
        case .highlight: return "Highlight"
        case .marginNote: return "Margin Note"
        case .bracket: return "Bracket"
        case .mixed: return "Mixed Markings"
        }
    }

    var description: String {
        switch self {
        case .underline: return "Single line under text"
        case .doubleUnderline: return "Double line under text"
        case .marginLine: return "Vertical line in margin"
        case .highlight: return "Highlighted/colored text"
        case .marginNote: return "Handwritten note in margin"
        case .bracket: return "Bracketed passage"
        case .mixed: return "Multiple marking styles"
        }
    }

    var systemImage: String {
        switch self {
        case .underline: return "underline"
        case .doubleUnderline: return "underline"
        case .marginLine: return "sidebar.leading"
        case .highlight: return "highlighter"
        case .marginNote: return "note.text"
        case .bracket: return "chevron.left.forwardslash.chevron.right"
        case .mixed: return "checklist"
        }
    }
}
