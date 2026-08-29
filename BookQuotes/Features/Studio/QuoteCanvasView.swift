import SwiftUI

// MARK: - QuoteCanvasView

/// Interactive canvas for viewing and manipulating a quote card with gestures.
struct QuoteCanvasView: View {
    let quote: Quote
    let theme: StudioTheme
    let aspectRatio: StudioAspectRatio

    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    @State private var showAlignmentGuides = false

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = min(geometry.size.width - Spacing.xl * 2, 400)
            let cardHeight = cardWidth / aspectRatio.ratioValue

            ZStack {
                // Background subtle grid / canvas container
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.backgroundSecondary.opacity(0.3))
                    .overlay {
                        if showAlignmentGuides {
                            alignmentGuides(size: geometry.size)
                        }
                    }

                // Renderable Card
                QuoteCanvasCard(
                    quote: quote,
                    theme: theme,
                    aspectRatio: aspectRatio
                )
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(currentScale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                showAlignmentGuides = true
                                currentScale = finalScale * value
                            }
                            .onEnded { value in
                                showAlignmentGuides = false
                                finalScale = min(max(finalScale * value, 0.7), 2.0)
                                withAnimation(.spring()) {
                                    currentScale = finalScale
                                }
                            },
                        DragGesture()
                            .onChanged { value in
                                showAlignmentGuides = true
                                offset = CGSize(
                                    width: finalOffset.width + value.translation.width,
                                    height: finalOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                showAlignmentGuides = false
                                finalOffset = CGSize(
                                    width: finalOffset.width + value.translation.width,
                                    height: finalOffset.height + value.translation.height
                                )
                                // Snap back if too far
                                if abs(finalOffset.width) > geometry.size.width * 0.4 ||
                                    abs(finalOffset.height) > geometry.size.height * 0.4 {
                                    withAnimation(.spring()) {
                                        offset = .zero
                                        finalOffset = .zero
                                    }
                                }
                            }
                    )
                )
                .elevation(.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Alignment Guides Overlay

    private func alignmentGuides(size: CGSize) -> some View {
        ZStack {
            // Horizontal Center
            Rectangle()
                .fill(Color.gildedAccent.opacity(0.4))
                .frame(height: 1)

            // Vertical Center
            Rectangle()
                .fill(Color.gildedAccent.opacity(0.4))
                .frame(width: 1)
        }
    }
}
