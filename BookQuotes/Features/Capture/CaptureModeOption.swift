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
            subtitle: "Scan the ISBN barcode",
            systemImage: "barcode.viewfinder",
            accent: .brand,
            accessibilityId: AccessibilityIdentifiers.Capture.modeSelectCover
        ),
        CaptureModeOption(
            kind: .quote,
            title: "Capture Quotes",
            subtitle: "One page at a time",
            systemImage: "text.quote",
            accent: .accent,
            accessibilityId: AccessibilityIdentifiers.Capture.modeSelectQuote
        ),
        CaptureModeOption(
            kind: .batch,
            title: "Batch Mode",
            subtitle: "Several pages, one session",
            systemImage: "square.stack.3d.up.fill",
            accent: .success,
            accessibilityId: AccessibilityIdentifiers.Capture.modeSelectBatch
        )
    ]
}
