import SwiftUI
import SwiftData

/// Capture tab - ISBN scanning and marked-page capture
struct CaptureTab: View {
    var onBookCreated: ((Book) -> Void)?
    var onQuotesSaved: ((Book) -> Void)?

    var body: some View {
        CaptureTabRootView(
            onBookCreated: onBookCreated,
            onQuotesSaved: onQuotesSaved
        )
    }
}

/// Navigation destinations for capture flow
enum CaptureDestination: Hashable {
    case cover
    case quotes
    case batch
}

/// Main capture menu
struct CaptureMenuView: View {
    @Environment(RouterPath.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                CaptureOptionCard(
                    title: "New Book",
                    description: "Photograph a book cover to add it to your library",
                    systemImage: "book.closed",
                    color: .brand
                ) {
                    router.navigate(to: CaptureDestination.cover)
                }

                CaptureOptionCard(
                    title: "Capture Quotes",
                    description: "Photograph pages with underlined or highlighted passages",
                    systemImage: "text.quote",
                    color: .accent
                ) {
                    router.navigate(to: CaptureDestination.quotes)
                }

                CaptureOptionCard(
                    title: "Batch Mode",
                    description: "Capture multiple pages quickly, process later",
                    systemImage: "square.stack.3d.up",
                    color: .success
                ) {
                    router.navigate(to: CaptureDestination.batch)
                }
            }
            .padding()
        }
        .navigationTitle("Capture")
    }
}

/// Card for capture option
struct CaptureOptionCard: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let accessibilityId: String?
    let action: () -> Void

    init(
        title: String,
        description: String,
        systemImage: String,
        color: Color,
        accessibilityId: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.color = color
        self.accessibilityId = accessibilityId
        self.action = action
    }

    var body: some View {
        if let accessibilityId {
            cardButton
                .accessibilityIdentifier(accessibilityId)
        } else {
            cardButton
        }
    }

    private var cardButton: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: CornerRadius.lg)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
    }
}

// Note: CoverCaptureView and QuoteCaptureView are defined in their respective
// feature modules (BookRegistration and Capture folders)

#Preview {
    CaptureTab()
}
