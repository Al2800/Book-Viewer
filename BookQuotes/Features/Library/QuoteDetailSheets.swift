import SwiftUI
import UIKit

struct QuoteSourceImageSheet: View {
    let imageData: Data?
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            if let imageData,
               let uiImage = UIImage(data: imageData) {
                ScrollView {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                .navigationTitle("Source Image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done", action: onDone)
                    }
                }
            }
        }
    }
}

struct QuoteMarkingPickerSheet: View {
    @Binding var markingType: MarkingType
    let onCancel: () -> Void
    let onSelect: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(MarkingType.allCases, id: \.self) { type in
                    Button {
                        markingType = type
                        onSelect()
                    } label: {
                        HStack {
                            MarkingTypeBadge(markingType: type)
                            Spacer()
                            if markingType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.brand)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Select Marking Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

/// Share sheet for quotes using UIActivityViewController.
/// Items typically contain a rendered share-card image plus the plain text.
struct QuoteShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Quote Share Card

/// Typographic paper card rendered to an image for sharing quotes.
/// Always renders in light mode so the shared card reads as warm paper.
struct QuoteShareCard: View {
    let text: String
    let bookTitle: String?
    let author: String?
    let pageNumber: Int?

    static let cardWidth: CGFloat = 360

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundStyle(Color.accent)

            Text(text)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let bookTitle {
                    Text(bookTitle)
                        .font(.bookTitleSmall)
                        .foregroundStyle(Color.textPrimary)
                }

                if let author {
                    Text(attributionLine(author: author))
                        .font(.attributionSmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Rectangle()
                .fill(Color.quoteBorder)
                .frame(height: 1)

            Text("Collected with BookQuotes")
                .font(.system(.caption2, design: .serif))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.xl)
        .frame(width: Self.cardWidth, alignment: .leading)
        .background(Color.quoteBackground)
    }

    private func attributionLine(author: String) -> String {
        if let pageNumber {
            return "\(author) · p. \(pageNumber)"
        }
        return author
    }
}

/// Renders a quote share card to a UIImage for the share sheet.
@MainActor
enum QuoteShareImageRenderer {
    static func render(quote: Quote) -> UIImage? {
        let card = QuoteShareCard(
            text: quote.text,
            bookTitle: quote.book?.title,
            author: quote.book?.author,
            pageNumber: quote.pageNumber
        )
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: QuoteShareCard.cardWidth, height: nil)
        return renderer.uiImage
    }
}

#Preview("Quote Share Card") {
    QuoteShareCard(
        text: "Every action you take is a vote for the type of person you wish to become.",
        bookTitle: "Atomic Habits",
        author: "James Clear",
        pageNumber: 38
    )
}
