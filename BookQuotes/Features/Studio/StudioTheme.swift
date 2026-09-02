import SwiftUI

// MARK: - StudioTheme

/// Visual themes available for quote cards in the Studio.
enum StudioTheme: String, CaseIterable, Identifiable {
    case darkLinen = "dark_linen"
    case warmVellum = "warm_vellum"
    case monochrome = "monochrome"
    case editorialNewsprint = "editorial_newsprint"
    case gilded = "gilded"
    case terracotta = "terracotta"
    case midnightNavy = "midnight_navy"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .darkLinen: return "Dark Linen"
        case .warmVellum: return "Warm Vellum"
        case .monochrome: return "Monochrome"
        case .editorialNewsprint: return "Newsprint"
        case .gilded: return "Gilded"
        case .terracotta: return "Terracotta"
        case .midnightNavy: return "Midnight Navy"
        }
    }

    var cardBackground: Color {
        switch self {
        case .darkLinen:
            return Color(red: 0.08, green: 0.08, blue: 0.09)
        case .warmVellum:
            return Color(red: 0.98, green: 0.97, blue: 0.94)
        case .monochrome:
            return Color(red: 0.92, green: 0.92, blue: 0.91)
        case .editorialNewsprint:
            return Color(red: 0.94, green: 0.93, blue: 0.89)
        case .gilded:
            return Color(red: 0.10, green: 0.09, blue: 0.08)
        case .terracotta:
            return Color(red: 0.22, green: 0.12, blue: 0.09)
        case .midnightNavy:
            return Color(red: 0.07, green: 0.10, blue: 0.16)
        }
    }

    var textColor: Color {
        switch self {
        case .darkLinen:
            return Color(red: 0.96, green: 0.96, blue: 0.96)
        case .warmVellum:
            return Color(red: 0.12, green: 0.10, blue: 0.08)
        case .monochrome:
            return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .editorialNewsprint:
            return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .gilded:
            return Color(red: 0.98, green: 0.95, blue: 0.86)
        case .terracotta:
            return Color(red: 0.97, green: 0.93, blue: 0.89)
        case .midnightNavy:
            return Color(red: 0.95, green: 0.96, blue: 0.98)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .darkLinen:
            return Color(red: 0.78, green: 0.78, blue: 0.80)
        case .warmVellum:
            return Color(red: 0.38, green: 0.33, blue: 0.28)
        case .monochrome:
            return Color(red: 0.35, green: 0.35, blue: 0.35)
        case .editorialNewsprint:
            return Color(red: 0.35, green: 0.35, blue: 0.35)
        case .gilded:
            return Color(red: 0.85, green: 0.73, blue: 0.45)
        case .terracotta:
            return Color(red: 0.82, green: 0.70, blue: 0.62)
        case .midnightNavy:
            return Color(red: 0.72, green: 0.78, blue: 0.88)
        }
    }

    var accentColor: Color {
        switch self {
        case .darkLinen:
            return Color.gildedAccent
        case .warmVellum:
            return Color(red: 0.68, green: 0.44, blue: 0.18)
        case .monochrome:
            return Color(red: 0.20, green: 0.20, blue: 0.20)
        case .editorialNewsprint:
            return Color(red: 0.22, green: 0.22, blue: 0.22)
        case .gilded:
            return Color(red: 0.92, green: 0.78, blue: 0.32)
        case .terracotta:
            return Color(red: 0.90, green: 0.58, blue: 0.42)
        case .midnightNavy:
            return Color(red: 0.55, green: 0.75, blue: 0.98)
        }
    }

    var borderColor: Color {
        switch self {
        case .darkLinen:
            return Color.gildedAccent.opacity(0.35)
        case .warmVellum:
            return Color(red: 0.82, green: 0.78, blue: 0.72)
        case .monochrome:
            return Color.black.opacity(0.20)
        case .editorialNewsprint:
            return Color.black.opacity(0.18)
        case .gilded:
            return Color.gildedAccent.opacity(0.45)
        case .terracotta:
            return Color(red: 0.85, green: 0.50, blue: 0.35).opacity(0.35)
        case .midnightNavy:
            return Color(red: 0.45, green: 0.65, blue: 0.95).opacity(0.35)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .darkLinen, .gilded, .terracotta, .midnightNavy:
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
