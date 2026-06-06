import SwiftUI

struct CaptureModeOption: Identifiable, Equatable {
    enum Kind: Equatable {
        case cover
        case quote
        case batch
    }

    enum Accent: Equatable {
        case brand
        case accent
        case success

        var color: Color {
            switch self {
            case .brand:
                return .brand
            case .accent:
                return .accent
            case .success:
                return .success
            }
        }
    }

    let kind: Kind
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Accent
    let accessibilityId: String

    var id: Kind { kind }

    static let all: [CaptureModeOption] = [
        CaptureModeOption(
            kind: .cover,
            title: "Add New Book",
            subtitle: "Photograph a cover and create a library entry",
            systemImage: "book.closed.fill",
            accent: .brand,
            accessibilityId: AccessibilityIdentifiers.Capture.modeSelectCover
        ),
        CaptureModeOption(
            kind: .quote,
            title: "Capture Quotes",
            subtitle: "Scan a marked page and review one passage at a time",
            systemImage: "text.quote",
            accent: .accent,
            accessibilityId: AccessibilityIdentifiers.Capture.modeSelectQuote
        ),
        CaptureModeOption(
            kind: .batch,
            title: "Batch Mode",
            subtitle: "Capture several pages first and process the session together",
            systemImage: "square.stack.3d.up.fill",
            accent: .success,
            accessibilityId: AccessibilityIdentifiers.Capture.modeSelectBatch
        )
    ]
}
