import SwiftUI

// MARK: - StudioTheme

/// Visual themes available for quote cards in the Studio.
enum StudioTheme: String, CaseIterable, Identifiable {
    case darkLinen = "dark_linen"
    case warmVellum = "warm_vellum"
    case monochrome = "monochrome"
    case editorialNewsprint = "editorial_newsprint"
    case gilded = "gilded"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .darkLinen: return "Dark Linen"
        case .warmVellum: return "Warm Vellum"
        case .monochrome: return "Monochrome"
        case .editorialNewsprint: return "Newsprint"
        case .gilded: return "Gilded"
        }
    }

    var cardBackground: Color {
        switch self {
        case .darkLinen:
            return Color.darkLinen
        case .warmVellum:
            return Color.warmVellum
        case .monochrome:
            return Color.editorialMonochrome
        case .editorialNewsprint:
            return Color(red: 0.94, green: 0.93, blue: 0.89)
        case .gilded:
            return Color(red: 0.12, green: 0.11, blue: 0.10)
        }
    }

    var textColor: Color {
        switch self {
        case .darkLinen:
            return Color.white.opacity(0.95)
        case .warmVellum:
            return Color(red: 0.15, green: 0.13, blue: 0.10)
        case .monochrome:
            return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .editorialNewsprint:
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .gilded:
            return Color(red: 0.96, green: 0.92, blue: 0.80)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .darkLinen:
            return Color.white.opacity(0.70)
        case .warmVellum:
            return Color(red: 0.45, green: 0.40, blue: 0.35)
        case .monochrome:
            return Color.black.opacity(0.60)
        case .editorialNewsprint:
            return Color(red: 0.40, green: 0.40, blue: 0.40)
        case .gilded:
            return Color(red: 0.77, green: 0.63, blue: 0.35)
        }
    }

    var accentColor: Color {
        switch self {
        case .darkLinen:
            return Color.gildedAccent
        case .warmVellum:
            return Color(red: 0.70, green: 0.48, blue: 0.22)
        case .monochrome:
            return Color.black.opacity(0.75)
        case .editorialNewsprint:
            return Color(red: 0.20, green: 0.20, blue: 0.20)
        case .gilded:
            return Color.gildedAccent
        }
    }

    var borderColor: Color {
        switch self {
        case .darkLinen:
            return Color.gildedAccent.opacity(0.3)
        case .warmVellum:
            return Color.quoteBorder.opacity(0.8)
        case .monochrome:
            return Color.quoteBorder.opacity(0.5)
        case .editorialNewsprint:
            return Color.black.opacity(0.15)
        case .gilded:
            return Color.gildedAccent.opacity(0.4)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .darkLinen, .gilded:
            return .dark
        case .warmVellum, .monochrome, .editorialNewsprint:
            return .light
        }
    }
}

// MARK: - StudioAspectRatio

/// Aspect ratio presets for social export formats.
enum StudioAspectRatio: String, CaseIterable, Identifiable {
    case story = "9:16"
    case square = "1:1"
    case portrait = "4:5"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .story: return "Story (9:16)"
        case .square: return "Square (1:1)"
        case .portrait: return "Card (4:5)"
        }
    }

    var ratioValue: CGFloat {
        switch self {
        case .story: return 9.0 / 16.0
        case .square: return 1.0
        case .portrait: return 4.0 / 5.0
        }
    }

    var targetSize: CGSize {
        switch self {
        case .story: return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        case .portrait: return CGSize(width: 1080, height: 1350)
        }
    }
}
