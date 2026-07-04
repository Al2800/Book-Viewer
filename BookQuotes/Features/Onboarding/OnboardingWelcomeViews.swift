import SwiftUI

enum WelcomePage: Int, CaseIterable, Identifiable {
    case capture
    case organize
    case discover

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .capture: return "camera.viewfinder"
        case .organize: return "books.vertical"
        case .discover: return "sparkles"
        }
    }

    var title: String {
        switch self {
        case .capture: return "Capture Quotes Instantly"
        case .organize: return "Build Your Library"
        case .discover: return "Rediscover Wisdom"
        }
    }

    var description: String {
        switch self {
        case .capture:
            return "Point your camera at any marked page. Our AI extracts underlines, highlights, and margin notes automatically."
        case .organize:
            return "Organize quotes by book, topic, or custom collections. Your library stays available on this device, with exports ready whenever you want a backup."
        case .discover:
            return "Search your entire library instantly. Surface forgotten insights and share your favorite passages."
        }
    }

    /// Frontispiece epigraph shown above each welcome page.
    var epigraph: String {
        switch self {
        case .capture:
            return "Some books are to be tasted, others to be swallowed, and some few to be chewed and digested."
        case .organize:
            return "A room without books is like a body without a soul."
        case .discover:
            return "The real voyage of discovery consists not in seeking new landscapes, but in having new eyes."
        }
    }

    var epigraphAttribution: String {
        switch self {
        case .capture: return "Francis Bacon"
        case .organize: return "Cicero"
        case .discover: return "Marcel Proust"
        }
    }
}

struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Frontispiece epigraph
            VStack(spacing: Spacing.md) {
                Text("\u{201C}\(page.epigraph)\u{201D}")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("— \(page.epigraphAttribution)")
                    .font(.attribution)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: page.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.brand)

                Text(page.title)
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}
