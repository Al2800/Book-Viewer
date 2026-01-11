import SwiftUI
import SwiftData

/// Capture tab - camera interface for book covers and pages
struct CaptureTab: View {
    var body: some View {
        CaptureTabRootView()
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundStyle(color)
                    .frame(width: 50)

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

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .elevation(.sm)
        }
        .buttonStyle(.plain)
    }
}

// Note: CoverCaptureView and QuoteCaptureView are defined in their respective
// feature modules (BookRegistration and Capture folders)

#Preview {
    CaptureTab()
}
