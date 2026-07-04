import SwiftUI

/// Empty state for library with entrance animation.
struct EmptyLibraryView: View {
    var onAddBook: (() -> Void)?

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                LibrarySummaryCard(bookCount: 0, quoteCount: 0, viewMode: .grid)

                LibrarySectionCard(title: "Library") {
                    emptyIntroRow

                    Button {
                        HapticManager.light()
                        onAddBook?()
                    } label: {
                        LibraryActionRow(
                            icon: "camera.viewfinder",
                            title: "Add Your First Book",
                            subtitle: "Scan a cover or ISBN barcode"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.emptyState)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }

    private var emptyIntroRow: some View {
        HStack(spacing: Spacing.md) {
            LibraryIconCircle(systemImage: "books.vertical", size: 44, font: .headline.weight(.semibold))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("No Books Yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("Add your first book to start building a searchable quote library.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }
}

struct LibrarySectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .sectionHeaderStyle()

            VStack(spacing: Spacing.sm) {
                content
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

struct LibrarySummaryCard: View {
    let bookCount: Int
    let quoteCount: Int
    let viewMode: LibraryViewMode

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.sm) {
                summaryPills
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                summaryPills
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .paperCard()
    }

    @ViewBuilder
    private var summaryPills: some View {
        LibrarySummaryPill(
            systemImage: "books.vertical",
            text: "\(bookCount) \(bookCount == 1 ? "Book" : "Books")"
        )
        LibrarySummaryPill(
            systemImage: "text.quote",
            text: "\(quoteCount) \(quoteCount == 1 ? "Quote" : "Quotes")"
        )
        LibrarySummaryPill(
            systemImage: viewMode.systemImageName,
            text: viewMode.summaryText
        )
    }
}

struct LibraryControlRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            LibraryIconCircle(systemImage: icon)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer(minLength: 0)

            trailing
        }
    }
}

struct LibraryActionRow: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: Spacing.md) {
            LibraryIconCircle(systemImage: icon, foreground: Color.accent)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .contentShape(Rectangle())
    }
}

private struct LibrarySummaryPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.backgroundSecondary)
        )
        .overlay {
            Capsule()
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        }
    }
}

private struct LibraryIconCircle: View {
    let systemImage: String
    var size: CGFloat = 36
    var font: Font = .subheadline.weight(.semibold)
    var foreground: Color = .textPrimary

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.backgroundSecondary)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }

            Image(systemName: systemImage)
                .font(font)
                .foregroundStyle(foreground)
        }
    }
}
