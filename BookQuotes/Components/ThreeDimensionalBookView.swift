import SwiftUI

// MARK: - Procedural Hardcover Jacket Theme

/// Classic procedural clothbound jacket themes for books without scanned cover art.
/// Inspired by Penguin Clothbound Classics, Everyman's Library, and Library of America.
enum ClothboundJacketTheme: CaseIterable {
    case oxfordNavy
    case forestGreen
    case burgundyWine
    case terracotta
    case charcoalLinen

    static func forBook(_ book: Book) -> ClothboundJacketTheme {
        // Stable deterministic hash of title and author across app launches
        let key = "\(book.title.trimmingCharacters(in: .whitespacesAndNewlines))|\(book.author.trimmingCharacters(in: .whitespacesAndNewlines))"
        var hash: UInt64 = 5381
        for byte in key.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        let themes = ClothboundJacketTheme.allCases
        return themes[Int(hash % UInt64(themes.count))]
    }

    var baseColor: Color {
        switch self {
        case .oxfordNavy:
            return Color(red: 0.11, green: 0.16, blue: 0.24)
        case .forestGreen:
            return Color(red: 0.11, green: 0.22, blue: 0.16)
        case .burgundyWine:
            return Color(red: 0.24, green: 0.11, blue: 0.14)
        case .terracotta:
            return Color(red: 0.28, green: 0.16, blue: 0.11)
        case .charcoalLinen:
            return Color(red: 0.14, green: 0.14, blue: 0.15)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .oxfordNavy:
            return Color(red: 0.16, green: 0.23, blue: 0.33)
        case .forestGreen:
            return Color(red: 0.16, green: 0.30, blue: 0.22)
        case .burgundyWine:
            return Color(red: 0.33, green: 0.16, blue: 0.20)
        case .terracotta:
            return Color(red: 0.36, green: 0.22, blue: 0.16)
        case .charcoalLinen:
            return Color(red: 0.20, green: 0.20, blue: 0.22)
        }
    }

    var foilGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.85, blue: 0.55),
                Color(red: 0.83, green: 0.69, blue: 0.22),
                Color(red: 0.77, green: 0.63, blue: 0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var foilBorderColor: Color {
        Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.75)
    }
}

// MARK: - Procedural Clothbound Cover View

/// Renders a luxury clothbound book cover with embossed foil stamping and geometric border rules.
struct ProceduralClothboundCoverView: View {
    let title: String
    let author: String
    let theme: ClothboundJacketTheme

    var body: some View {
        ZStack {
            // Textured cloth background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.secondaryColor, theme.baseColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Tactile linen weave pattern overlay
            LinenWeaveTexture()
                .opacity(0.18)

            // Embossed decorative foil frame
            RoundedRectangle(cornerRadius: CornerRadius.xs)
                .strokeBorder(theme.foilBorderColor, lineWidth: 1)
                .padding(6)

            RoundedRectangle(cornerRadius: CornerRadius.xs)
                .strokeBorder(theme.foilBorderColor.opacity(0.4), lineWidth: 0.5)
                .padding(9)

            // Cover Typography
            VStack(spacing: Spacing.xs) {
                // Top ornament
                Text("✦")
                    .font(.system(size: 8))
                    .foregroundStyle(theme.foilGradient)
                    .padding(.top, Spacing.xs)

                Spacer(minLength: 2)

                // Book Title
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(theme.foilGradient)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, Spacing.xs)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, y: 1)

                // Author
                Text(author.uppercased())
                    .font(.system(size: 7.5, weight: .semibold, design: .serif))
                    .tracking(1.0)
                    .foregroundStyle(theme.foilGradient.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.top, 2)

                Spacer(minLength: 2)

                // Bottom ornament
                Text("❖")
                    .font(.system(size: 7))
                    .foregroundStyle(theme.foilGradient.opacity(0.7))
                    .padding(.bottom, Spacing.xs)
            }
            .padding(Spacing.xxs)
        }
    }
}

// MARK: - Linen Weave Texture Shape

/// Procedural linen weave lines for tactile cloth realism.
struct LinenWeaveTexture: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 3
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white, lineWidth: 0.3)
        }
    }
}

// MARK: - ThreeDimensionalBookView

/// A realistic 3D Hardcover Book rendered with perspective projection,
/// spine hinge groove, fore-edge page block, top page edge, and surface light sheen.
enum ThreeDimensionalBookPresentation {
    case shelf
    case card
    case hero
}

struct ThreeDimensionalBookView: View {
    let book: Book
    var width: CGFloat = 100
    var height: CGFloat = 150
    var pageBlockThickness: CGFloat = 14
    var isInteractive: Bool = true
    var showQuoteBadge: Bool = true
    var presentation: ThreeDimensionalBookPresentation = .shelf

    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var coverWidth: CGFloat { width }
    private var coverHeight: CGFloat { height }

    private var restAngle: Double {
        switch presentation {
        case .shelf: return -10
        case .card: return -6
        case .hero: return -8
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if presentation != .card {
                BookCastShadow(width: width, thickness: pageBlockThickness)
                    .offset(x: 2, y: presentation == .shelf ? 2 : 6)
            }

            ZStack(alignment: .leading) {
                PageBlockForeEdge(height: coverHeight, thickness: pageBlockThickness)
                    .offset(x: coverWidth - 2)

                if presentation != .card {
                    PageBlockTopEdge(width: coverWidth, thickness: pageBlockThickness)
                        .offset(y: -3)
                }

                frontCoverBoard
                    .frame(width: coverWidth, height: coverHeight)
            }
            .rotation3DEffect(
                reduceMotion ? .zero : .degrees(isPressed ? restAngle + 4 : restAngle),
                axis: (x: 0.04, y: 1.0, z: -0.01),
                anchor: .leading,
                perspective: 0.35
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .frame(
            width: presentation == .card ? width : width + pageBlockThickness + 6,
            height: presentation == .card ? height : height + (presentation == .shelf ? 4 : 10)
        )
        .clipped(antialiased: presentation == .card)
        .modifier(InteractivePressModifier(isEnabled: isInteractive && !reduceMotion, isPressed: $isPressed))
        .accessibilityIdentifier(presentation == .hero ? AccessibilityIdentifiers.BookDetail.coverImage : "")
    }

    // MARK: - Front Cover Board

    private var frontCoverBoard: some View {
        ZStack(alignment: .leading) {
            // Cover Artwork (Actual image or Procedural Clothbound)
            if let coverData = book.coverThumbnailData ?? book.coverFullData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: coverWidth, height: coverHeight)
                    .clipped()
            } else {
                ProceduralClothboundCoverView(
                    title: book.title,
                    author: book.author,
                    theme: ClothboundJacketTheme.forBook(book)
                )
            }

            // Hardcover outer board edge highlight & bevel
            RoundedRectangle(cornerRadius: CornerRadius.xs)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.05),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Surface Lighting Sheen (Angle reflection)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.clear,
                    Color.black.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Spine Hinge Groove (The physical French groove indent)
            SpineHingeGroove()

            // Gold foil quote counter badge
            if showQuoteBadge && book.hasQuotes {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 7))
                            Text("\(book.quoteCount)")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Color.black.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(LinearGradient.foilAccent)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
                        .padding(5)
                    }
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
    }
}

// MARK: - Spine Hinge Groove

/// Realistic vertical indentation and shadow where the book board hinges.
struct SpineHingeGroove: View {
    var body: some View {
        HStack(spacing: 0) {
            // Spine rounded edge
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.white.opacity(0.15),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 5)

            Spacer()
                .frame(width: 4)

            // Hinge crease groove
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.45),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 3)

            Spacer()
        }
    }
}

// MARK: - Page Block Fore-Edge (Side Pages)

/// Side paper block showing cream paper thickness, layer lines, and edge shadow.
struct PageBlockForeEdge: View {
    let height: CGFloat
    let thickness: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            // Base warm paper block
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.94, blue: 0.89),
                            Color(red: 0.88, green: 0.85, blue: 0.78),
                            Color(red: 0.78, green: 0.74, blue: 0.67)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: thickness, height: height - 4)

            // Fine page striation lines
            VStack(spacing: 1.5) {
                ForEach(0..<Int(height / 3), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.04))
                        .frame(height: 0.5)
                }
            }
            .frame(width: thickness, height: height - 4)

            // Inner gutter shadow
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.35), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4, height: height - 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 1))
    }
}

// MARK: - Page Block Top Edge (Top Pages)

/// Top angled paper edge visible from the shelf perspective.
struct PageBlockTopEdge: View {
    let width: CGFloat
    let thickness: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.90, blue: 0.84),
                        Color(red: 0.82, green: 0.79, blue: 0.72)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width - 6, height: 4)
            .offset(x: 4)
    }
}

// MARK: - Book Cast Shadow

/// Deep ambient occlusion and contact shadow cast by the 3D book onto the wooden ledge.
struct BookCastShadow: View {
    let width: CGFloat
    let thickness: CGFloat

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.45),
                        Color.black.opacity(0.25),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: width * 0.55
                )
            )
            .frame(width: width + thickness + 12, height: 18)
            .blur(radius: 4)
    }
}

private struct InteractivePressModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var isPressed: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        } else {
            content
        }
    }
}
