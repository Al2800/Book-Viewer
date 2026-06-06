import SwiftUI

// MARK: - Accessibility Manager

/// Centralized accessibility state manager for motion and transparency preferences.
/// Use this to check user preferences before applying animations.
@Observable
final class AccessibilityManager {
    /// Shared singleton instance
    static let shared = AccessibilityManager()

    /// Whether the user prefers reduced motion (Settings > Accessibility > Motion > Reduce Motion)
    var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Whether the user prefers reduced transparency
    var prefersReducedTransparency: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    private init() {
        // Listen for changes to update views reactively
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Trigger re-evaluation of prefersReducedMotion
            // @Observable will handle view updates
            _ = self?.prefersReducedMotion
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.prefersReducedTransparency
        }
    }
}

// MARK: - iOS 26 Liquid Glass Support

extension View {
    /// Apply glass card effect with iOS 26 Liquid Glass.
    /// Falls back to ultraThinMaterial on earlier iOS versions.
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .padding()
    ///     .glassCard()
    /// ```
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg, elevated: Bool = true) -> some View {
        if #available(iOS 26, *) {
            // iOS 26: Use native Liquid Glass effect
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial)
                        .glassEffect()
                        // Some iOS 26 glass backgrounds can render as a rectangular layer behind
                        // the intended rounded shape. Mask it explicitly to the same shape.
                        .mask(RoundedRectangle(cornerRadius: cornerRadius))
                }
                // Without an explicit clip, some iOS 26 glass backgrounds can render as a rectangular
                // layer behind the rounded overlay, which looks like two styles stacked.
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            // Pre-iOS 26: Material-based fallback with similar visual feel
            if elevated {
                self
                    .background {
                        // Avoid rectangular material backgrounds showing behind rounded overlays.
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .elevation(.sm)
            } else {
                // For chrome layered on top of a live camera preview, even a small shadow reads as a dark slab.
                // Use the same shaped material but skip elevation.
                self
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    /// Chrome specifically tuned for camera controls layered on top of a live preview.
    /// Material + elevation can read as a dark slab; keep it light and avoid double-layered shapes.
    @ViewBuilder
    func cameraChrome(cornerRadius: CGFloat = CornerRadius.xl) -> some View {
        if #available(iOS 26, *) {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .overlay {
                            // Subtle highlight to keep controls readable over dark previews.
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        }
                        .mask(RoundedRectangle(cornerRadius: cornerRadius))
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Apply glass button style with iOS 26 Liquid Glass.
    /// Falls back to borderedProminent with accent tint on earlier iOS.
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26, *) {
            // iOS 26: Use native glass button style if available
            self.buttonStyle(.glass)
        } else {
            // Pre-iOS 26: Bordered prominent with accent tint
            self
                .buttonStyle(.borderedProminent)
                .tint(Color.accent.opacity(0.9))
        }
    }

    /// Apply glass toolbar background with iOS 26 Liquid Glass.
    /// Falls back to ultraThinMaterial on earlier iOS versions.
    @ViewBuilder
    func glassToolbar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    /// Apply glass tab bar background with iOS 26 Liquid Glass.
    @ViewBuilder
    func glassTabBar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    /// Apply glass effect to floating elements (FABs, toasts).
    /// More prominent than glassCard with additional shadow.
    @ViewBuilder
    func glassFloating(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        if #available(iOS 26, *) {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thickMaterial)
                        .glassEffect()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .elevation(.lg)
        } else {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thickMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .elevation(.lg)
        }
    }

    /// Apply warm paper card styling with a subtle glassy highlight.
    /// Designed for form sections and content blocks.
    func paperCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.backgroundCard)
                    .overlay {
                        LinearGradient.cardHighlight
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.quoteBorder.opacity(0.7), lineWidth: Stroke.hairline.width)
                    }
            }
            .elevation(.xs)
    }

    /// Apply consistent field styling for inputs.
    func fieldChrome(minHeight: CGFloat? = nil) -> some View {
        self
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
            )
    }
}
