import SwiftUI

// MARK: - Haptic Feedback

enum HapticManager {
    /// Key for the haptic feedback enabled preference
    private static let hapticFeedbackEnabledKey = "hapticFeedbackEnabled"

    /// Whether haptic feedback is enabled (defaults to true)
    static var isEnabled: Bool {
        // Default to true if not set (maintains existing behavior for current users)
        if UserDefaults.standard.object(forKey: hapticFeedbackEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: hapticFeedbackEnabledKey)
    }

    /// Trigger impact feedback with specified style
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger notification feedback with specified type
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Common Haptics

    /// Success haptic for capture completion
    static func captureSuccess() {
        notification(.success)
    }

    /// Light impact for subtle interactions
    static func light() {
        impact(.light)
    }

    /// Medium impact for emphasis
    static func medium() {
        impact(.medium)
    }

    /// Success notification feedback
    static func success() {
        notification(.success)
    }

    /// Warning notification feedback
    static func warning() {
        notification(.warning)
    }

    /// Light impact for quote added
    static func quoteAdded() {
        impact(.light)
    }

    /// Medium impact for favorite toggle
    static func favoriteToggled() {
        impact(.medium)
    }

    /// Error haptic for failures
    static func error() {
        notification(.error)
    }

    /// Selection changed haptic for pickers, toggles
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
