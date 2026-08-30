import SwiftUI

// MARK: - QuoteCanvasView

/// Interactive canvas for viewing, scaling, and manipulating a quote card with gestures.
/// Strictly enforces viewport aspect ratio fitting and prevents canvas overflow.
struct QuoteCanvasView: View {
    let quote: Quote
    let theme: StudioTheme
    let aspectRatio: StudioAspectRatio

    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    @State private var showAlignmentGuides: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - Spacing.lg * 2, 200)
            let availableHeight = max(geometry.size.height - Spacing.lg * 2, 200)
            let targetRatio = aspectRatio.ratioValue // e.g. 9/16 = 0.5625, 1/1 = 1.0, 4/5 = 0.8

            // Compute fitted card dimensions that never overflow available canvas area
            let cardDimensions: CGSize = {
                if availableWidth / availableHeight > targetRatio {
                    // Height constrained
                    let height = min(availableHeight, 520)
                    let width = height * targetRatio
                    return CGSize(width: width, height: height)
                } else {
                    // Width constrained
                    let width = min(availableWidth, 360)
                    let height = width / targetRatio
                    return CGSize(width: width, height: height)
                }
            }()

            ZStack {
                // Subtle canvas background texture
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.backgroundSecondary.opacity(0.4))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.xl)
                            .stroke(Color.quoteBorder.opacity(0.4), lineWidth: 1)
                    }

                // Interactive Alignment Guides
                if showAlignmentGuides {
                    alignmentGuides(size: geometry.size)
                        .transition(.opacity)
                }

                // Renderable Card strictly fitted to computed dimensions
                QuoteCanvasCard(
                    quote: quote,
                    theme: theme,
                    aspectRatio: aspectRatio
                )
                .frame(width: cardDimensions.width, height: cardDimensions.height)
                .scaleEffect(currentScale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                showAlignmentGuides = true
                                currentScale = min(max(finalScale * value, 0.75), 2.2)
                            }
                            .onEnded { value in
                                showAlignmentGuides = false
                                finalScale = min(max(finalScale * value, 0.85), 2.0)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
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
                                let maxPanX = geometry.size.width * 0.35
                                let maxPanY = geometry.size.height * 0.35

                                var newX = finalOffset.width + value.translation.width
                                var newY = finalOffset.height + value.translation.height

                                // Snap back if dragged out of canvas view
                                if abs(newX) > maxPanX || abs(newY) > maxPanY {
                                    newX = min(max(newX, -maxPanX), maxPanX)
                                    newY = min(max(newY, -maxPanY), maxPanY)
                                }

                                finalOffset = CGSize(width: newX, height: newY)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    offset = finalOffset
                                }
                            }
                    )
                )
                .elevation(.lg)

                // Canvas Controls Overlay (Reset button & aspect ratio indicator)
                VStack {
                    HStack {
                        // Aspect ratio badge
                        Text(aspectRatio.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 3)
                            .background(Color.backgroundPrimary.opacity(0.85))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)

                        Spacer()

                        // Reset Transform Button (appears if zoomed or panned)
                        if currentScale != 1.0 || offset != .zero {
                            Button {
                                HapticManager.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentScale = 1.0
                                    finalScale = 1.0
                                    offset = .zero
                                    finalOffset = .zero
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

    // MARK: - Alignment Guides Overlay

    private func alignmentGuides(size: CGSize) -> some View {
        ZStack {
            // Horizontal Center Guide
            Rectangle()
                .fill(Color.gildedAccent.opacity(0.4))
                .frame(height: 1)

            // Vertical Center Guide
            Rectangle()
                .fill(Color.gildedAccent.opacity(0.4))
                .frame(width: 1)
        }
        .allowsHitTesting(false)
    }
}
