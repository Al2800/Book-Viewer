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
            return "books.vertical.fill"
        case .firstBook:
            return "book.fill"
        case .quoteCount:
            return "quote.opening"
        case .custom(_, let icon):
            return icon
        }
    }
}

// MARK: - Milestone Celebration

/// Quiet milestone acknowledgment.
/// A small paper card with an accent icon and serif message,
/// in keeping with the calm book aesthetic.
struct MilestoneCelebration: View {
    let type: MilestoneType

    /// Convenience initializer for simple message-only acknowledgments
    init(message: String) {
        self.type = .custom(message: message, icon: "bookmark.fill")
    }

    /// Full initializer with milestone type
    init(type: MilestoneType) {
        self.type = type
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: type.systemImage)
                .font(.system(size: 32))
                .foregroundStyle(Color.accent)

            Text(type.message)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.quoteBorder, lineWidth: 1)
        )
        .elevation(.lg)
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

        withAnimation(.easeOut(duration: 0.25)) {
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
    /// Adds milestone acknowledgment overlay capability to a view
    func milestoneCelebration(manager: MilestoneManager) -> some View {
        self.overlay {
            if manager.showMilestone, let milestone = manager.currentMilestone {
                MilestoneCelebration(type: milestone)
                    .transition(.opacity)
                    .onTapGesture {
                        manager.dismiss()
                    }
            }
        }
        .animation(.easeOut(duration: 0.25), value: manager.showMilestone)
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
