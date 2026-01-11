import SwiftUI

// MARK: - Skeleton View

/// A shimmering placeholder view for loading states.
/// Displays an animated gradient that moves across the view to indicate loading.
struct SkeletonView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The corner radius of the skeleton shape
    var cornerRadius: CGFloat = CornerRadius.sm

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.backgroundSecondary)
                .overlay {
                    if !reduceMotion {
                        shimmerGradient(width: geometry.size.width)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    private func shimmerGradient(width: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.3),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: width * 0.6)
        .offset(x: isAnimating ? width : -width * 0.6)
        .mask(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Skeleton Text

/// A skeleton placeholder for text content
struct SkeletonText: View {
    var lineCount: Int = 1
    var lastLineWidth: CGFloat = 0.6

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(0..<lineCount, id: \.self) { index in
                SkeletonView()
                    .frame(height: 14)
                    .frame(maxWidth: index == lineCount - 1 ? .infinity : .infinity)
                    .scaleEffect(
                        x: index == lineCount - 1 ? lastLineWidth : 1.0,
                        y: 1.0,
                        anchor: .leading
                    )
            }
        }
    }
}

// MARK: - Book Card Skeleton

/// Skeleton placeholder for a book cover card
struct BookCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Cover image placeholder
            SkeletonView(cornerRadius: CornerRadius.md)
                .aspectRatio(2/3, contentMode: .fit)

            // Title placeholder
            SkeletonView()
                .frame(height: 14)

            // Author placeholder
            SkeletonView()
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .scaleEffect(x: 0.7, y: 1.0, anchor: .leading)
        }
    }
}

// MARK: - Book List Row Skeleton

/// Skeleton placeholder for a book list row
struct BookListRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Cover thumbnail
            SkeletonView(cornerRadius: CornerRadius.sm)
                .frame(width: 50, height: 75)

            // Text content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonView()
                    .frame(height: 16)
                    .frame(maxWidth: 200)

                SkeletonView()
                    .frame(height: 14)
                    .frame(maxWidth: 150)

                SkeletonView()
                    .frame(height: 12)
                    .frame(maxWidth: 80)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Quote Card Skeleton

/// Skeleton placeholder for a quote card
struct QuoteCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Quote text placeholder (multiple lines)
            SkeletonText(lineCount: 3, lastLineWidth: 0.5)

            // Book info placeholder
            HStack(spacing: Spacing.xs) {
                SkeletonView()
                    .frame(width: 14, height: 14)

                SkeletonView()
                    .frame(height: 12)
                    .frame(maxWidth: 120)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - Search Result Skeleton

/// Skeleton placeholder for search results
struct SearchResultSkeleton: View {
    var resultCount: Int = 3

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<resultCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SkeletonView()
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 0.8, y: 1.0, anchor: .leading)

                    SkeletonView()
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 0.6, y: 1.0, anchor: .leading)
                }
                .padding()

                Divider()
            }
        }
    }
}

// MARK: - Library Grid Skeleton

/// Skeleton placeholder for the library grid view
struct LibraryGridSkeleton: View {
    var columns: Int = 3
    var rows: Int = 2

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: columns),
            spacing: Spacing.lg
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                BookCardSkeleton()
            }
        }
        .padding()
    }
}

// MARK: - Library List Skeleton

/// Skeleton placeholder for the library list view
struct LibraryListSkeleton: View {
    var rowCount: Int = 5

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { _ in
                BookListRowSkeleton()
                    .padding(.horizontal)
                Divider()
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Shows a skeleton placeholder when loading, otherwise shows the content
    /// - Parameters:
    ///   - isLoading: Whether content is still loading
    ///   - skeleton: The skeleton view to show during loading
    @ViewBuilder
    func skeleton<Skeleton: View>(
        isLoading: Bool,
        @ViewBuilder skeleton: () -> Skeleton
    ) -> some View {
        if isLoading {
            skeleton()
        } else {
            self
        }
    }

    /// Applies a redacted/skeleton effect to the view when loading
    func redactedSkeleton(isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(isActive: isLoading)
    }
}

// MARK: - Shimmer Effect Modifier

/// Adds a shimmer effect to any view
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    }
                    .mask(content)
                }
            }
            .onAppear {
                guard isActive && !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Adds a shimmering effect to the view
    func shimmering(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Preview

#Preview("Skeleton Views") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            Text("Book Card Skeleton")
                .font(.headline)
            BookCardSkeleton()
                .frame(width: 120)

            Text("Book List Row Skeleton")
                .font(.headline)
            BookListRowSkeleton()

            Text("Quote Card Skeleton")
                .font(.headline)
            QuoteCardSkeleton()

            Text("Library Grid Skeleton")
                .font(.headline)
            LibraryGridSkeleton()
        }
        .padding()
    }
}

#Preview("Shimmer Effect") {
    VStack(spacing: Spacing.lg) {
        Text("Loading...")
            .font(.title)
            .shimmering()

        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 100)
            .shimmering()
    }
    .padding()
}
