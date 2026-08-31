import SwiftUI

// MARK: - Canvas Transform

struct StudioCanvasTransform: Equatable, Sendable {
    var scale: CGFloat
    var normalizedOffset: CGSize

    static let identity = StudioCanvasTransform(scale: 1.0, normalizedOffset: .zero)

    func pointOffset(in cardSize: CGSize) -> CGSize {
        CGSize(
            width: normalizedOffset.width * cardSize.width,
            height: normalizedOffset.height * cardSize.height
        )
    }

    static func normalized(
        scale: CGFloat,
        pointOffset: CGSize,
        cardSize: CGSize
    ) -> StudioCanvasTransform {
        guard cardSize.width > 0, cardSize.height > 0 else {
            return StudioCanvasTransform(scale: scale, normalizedOffset: .zero)
        }

        return StudioCanvasTransform(
            scale: scale,
            normalizedOffset: CGSize(
                width: pointOffset.width / cardSize.width,
                height: pointOffset.height / cardSize.height
            )
        )
    }
}

// MARK: - QuoteCanvasView

/// Interactive canvas for viewing, scaling, and manipulating a quote card with gestures.
/// The transform is stored in normalized card coordinates so export can reproduce the preview.
struct QuoteCanvasView: View {
    let quote: Quote
    let theme: StudioTheme
    let aspectRatio: StudioAspectRatio
    @Binding var transform: StudioCanvasTransform

    @State private var magnificationStartScale: CGFloat?
    @State private var dragStartOffset: CGSize?
    @State private var showAlignmentGuides = false

    init(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio,
        transform: Binding<StudioCanvasTransform> = .constant(.identity)
    ) {
        self.quote = quote
        self.theme = theme
        self.aspectRatio = aspectRatio
        self._transform = transform
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - Spacing.lg * 2, 200)
            let availableHeight = max(geometry.size.height - Spacing.lg * 2, 200)
            let targetRatio = aspectRatio.ratioValue

            let cardDimensions: CGSize = {
                if availableWidth / availableHeight > targetRatio {
                    let height = min(availableHeight, 520)
                    let width = height * targetRatio
                    return CGSize(width: width, height: height)
                } else {
                    let width = min(availableWidth, 360)
                    let height = width / targetRatio
                    return CGSize(width: width, height: height)
                }
            }()

            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.backgroundSecondary.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.xl)
                            .stroke(Color.quoteBorder.opacity(0.4), lineWidth: 1)
                    }

                if showAlignmentGuides {
                    alignmentGuides
                        .transition(.opacity)
                }

                QuoteCanvasCard(
                    quote: quote,
                    theme: theme,
                    aspectRatio: aspectRatio
                )
                .frame(width: cardDimensions.width, height: cardDimensions.height)
                .scaleEffect(transform.scale)
                .offset(transform.pointOffset(in: cardDimensions))
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                showAlignmentGuides = true
                                if magnificationStartScale == nil {
                                    magnificationStartScale = transform.scale
                                }
                                let start = magnificationStartScale ?? transform.scale
                                transform.scale = min(max(start * value, 0.75), 2.2)
                            }
                            .onEnded { value in
                                let start = magnificationStartScale ?? transform.scale
                                transform.scale = min(max(start * value, 0.85), 2.0)
                                magnificationStartScale = nil
                                showAlignmentGuides = false
                            },
                        DragGesture()
                            .onChanged { value in
                                showAlignmentGuides = true
                                if dragStartOffset == nil {
                                    dragStartOffset = transform.normalizedOffset
                                }

                                let start = dragStartOffset ?? transform.normalizedOffset
                                transform.normalizedOffset = CGSize(
                                    width: start.width + value.translation.width / cardDimensions.width,
                                    height: start.height + value.translation.height / cardDimensions.height
                                )
                            }
                            .onEnded { value in
                                let start = dragStartOffset ?? transform.normalizedOffset
                                var pointOffset = CGSize(
                                    width: (start.width * cardDimensions.width) + value.translation.width,
                                    height: (start.height * cardDimensions.height) + value.translation.height
                                )

                                let maxPanX = geometry.size.width * 0.35
                                let maxPanY = geometry.size.height * 0.35
                                pointOffset.width = min(max(pointOffset.width, -maxPanX), maxPanX)
                                pointOffset.height = min(max(pointOffset.height, -maxPanY), maxPanY)

                                transform = .normalized(
                                    scale: transform.scale,
                                    pointOffset: pointOffset,
                                    cardSize: cardDimensions
                                )
                                dragStartOffset = nil
                                showAlignmentGuides = false
                            }
                    )
                )
                .elevation(.lg)

                VStack {
                    HStack {
                        Text(aspectRatio.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 3)
                            .background(Color.backgroundPrimary.opacity(0.85))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)

                        Spacer()

                        if transform != .identity {
                            Button {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    transform = .identity
                                    magnificationStartScale = nil
                                    dragStartOffset = nil
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.gildedAccent)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 3)
                                .background(Color.backgroundPrimary.opacity(0.9))
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                            }
                        }
                    }
                    .padding(Spacing.md)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }

    private var alignmentGuides: some View {
        ZStack {
            Rectangle()
                .fill(Color.gildedAccent.opacity(0.4))
                .frame(height: 1)

            Rectangle()
                .fill(Color.gildedAccent.opacity(0.4))
                .frame(width: 1)
        }
        .allowsHitTesting(false)
    }
}
