import SwiftUI

// MARK: - Milestone Type

/// Different types of milestone celebrations with their visual styling
enum MilestoneType {
    case pageCapture(count: Int)
    case firstBook
    case quoteCount(count: Int)
    case custom(message: String, icon: String)

    var message: String {
        switch self {
        case .pageCapture(let count):
            return "\(count) pages captured!"
        case .firstBook:
            return "First book added!"
        case .quoteCount(let count):
            return "\(count) quotes saved!"
        case .custom(let message, _):
            return message
        }
    }

    var systemImage: String {
        switch self {
        case .pageCapture:
            return "party.popper.fill"
        case .firstBook:
            return "book.fill"
        case .quoteCount:
            return "quote.opening"
        case .custom(_, let icon):
            return icon
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .pageCapture:
            return [.yellow, .orange]
        case .firstBook:
            return [.green, .mint]
        case .quoteCount:
            return [.purple, .pink]
        case .custom:
            return [.blue, .cyan]
        }
    }
}

// MARK: - Milestone Celebration

/// Full-screen celebration overlay for milestones
/// Displays an animated icon with a celebratory message
struct MilestoneCelebration: View {
    let type: MilestoneType

    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Convenience initializer for simple message-only celebrations
    init(message: String) {
        self.type = .custom(message: message, icon: "party.popper.fill")
    }

    /// Full initializer with milestone type
    init(type: MilestoneType) {
        self.type = type
    }

    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                // Celebration icon
                Image(systemName: type.systemImage)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: type.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconScale)
                    .symbolEffect(.bounce, options: .speed(0.5), isActive: !reduceMotion)

                // Message
                Text(type.message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
            }
            .padding(Spacing.xxl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .onAppear {
            guard !reduceMotion else {
                iconScale = 1.0
                textOpacity = 1.0
                return
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Milestone Manager

/// Tracks and triggers milestone celebrations
@MainActor
final class MilestoneManager: ObservableObject {
    @Published var showMilestone = false
    @Published var currentMilestone: MilestoneType?

    private var dismissTask: Task<Void, Never>?

    /// Quote count milestones
    static let quoteMilestones = [10, 50, 100, 250, 500, 1000]

    /// Page capture milestones
    static let pageMilestones = [5, 10, 20, 50, 100]

    /// Check and trigger a milestone celebration for quote count
    func checkQuoteMilestone(totalQuotes: Int) {
        guard Self.quoteMilestones.contains(totalQuotes) else { return }
        trigger(.quoteCount(count: totalQuotes))
    }

    /// Check and trigger a milestone celebration for page captures
    func checkPageMilestone(pageCount: Int) {
        guard Self.pageMilestones.contains(pageCount) else { return }
        trigger(.pageCapture(count: pageCount))
    }

    /// Trigger first book milestone
    func triggerFirstBook() {
        trigger(.firstBook)
    }

    /// Trigger a custom milestone
    func trigger(_ type: MilestoneType) {
        HapticManager.success()
        currentMilestone = type

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showMilestone = true
        }

        // Auto-dismiss after 2 seconds
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                showMilestone = false
            }
        }
    }

    /// Manually dismiss the milestone
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            showMilestone = false
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds milestone celebration overlay capability to a view
    func milestoneCelebration(manager: MilestoneManager) -> some View {
        self.overlay {
            if manager.showMilestone, let milestone = manager.currentMilestone {
                MilestoneCelebration(type: milestone)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .onTapGesture {
                        manager.dismiss()
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: manager.showMilestone)
    }
}

// MARK: - Preview

#Preview("Page Capture Milestone") {
    ZStack {
        Color.gray.ignoresSafeArea()
        MilestoneCelebration(type: .pageCapture(count: 10))
    }
}

#Preview("First Book Milestone") {
    ZStack {
        Color.gray.ignoresSafeArea()
        MilestoneCelebration(type: .firstBook)
    }
}

#Preview("Quote Count Milestone") {
    ZStack {
        Color.gray.ignoresSafeArea()
        MilestoneCelebration(type: .quoteCount(count: 100))
    }
}

#Preview("Legacy Message") {
    ZStack {
        Color.gray.ignoresSafeArea()
        MilestoneCelebration(message: "Custom celebration!")
    }
}
