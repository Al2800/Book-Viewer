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
}

struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(Color.brand)

            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}
