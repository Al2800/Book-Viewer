import SwiftUI

// MARK: - First Capture Coaching View

/// Guided tutorial for first-time users to ensure successful first capture.
/// This is a critical UX pinch point - failure here leads to abandonment.
struct FirstCaptureCoachingView: View {
    @AppStorage("hasCompletedCaptureCoaching") private var hasCompleted = false
    @Binding var isPresented: Bool

    @State private var currentStep = 0

    private let steps = CoachingStep.allSteps

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            headerSection

            // Step content
            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepContent(step)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smoothSpring, value: currentStep)

            // Navigation footer
            navigationSection
        }
        .background(Color.backgroundPrimary)
        .interactiveDismissDisabled()
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: Spacing.lg) {
            // Close button (disabled until complete)
            HStack {
                Spacer()
                if currentStep == steps.count - 1 {
                    Button {
                        completeCoaching()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .frame(height: 30)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            // Progress indicator
            progressDots
        }
    }

    @ViewBuilder
    private var progressDots: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.brand : Color.backgroundSecondary)
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.smoothSpring, value: currentStep)
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private func stepContent(_ step: CoachingStep) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: step.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Color.brand)
            }

            // Text content
            VStack(spacing: Spacing.md) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)

                Text(step.description)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Spacing.xl)

            // Pro tip
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accent)

                Text(step.tip)
                    .font(.subheadline)
                    .foregroundStyle(Color.accent)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.accent.opacity(0.1))
            .clipShape(Capsule())

            Spacer()
        }
    }

    // MARK: - Navigation Section

    @ViewBuilder
    private var navigationSection: some View {
        VStack(spacing: Spacing.md) {
            // Step counter
            Text("Step \(currentStep + 1) of \(steps.count)")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)

            // Navigation buttons
            HStack(spacing: Spacing.lg) {
                // Back button
                Button {
                    withAnimation(.smoothSpring) {
                        currentStep = max(0, currentStep - 1)
                    }
                    HapticManager.impact(.light)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(currentStep > 0 ? Color.brand : Color.textTertiary)
                    .frame(width: 100)
                }
                .disabled(currentStep == 0)

                Spacer()

                // Next/Complete button
                Button {
                    if currentStep < steps.count - 1 {
                        withAnimation(.smoothSpring) {
                            currentStep += 1
                        }
                        HapticManager.impact(.light)
                    } else {
                        completeCoaching()
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(currentStep < steps.count - 1 ? "Next" : "Start Capturing")
                        if currentStep < steps.count - 1 {
                            Image(systemName: "chevron.right")
                        } else {
                            Image(systemName: "camera")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.brand)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
        .padding(.vertical, Spacing.xl)
        .background(Color.backgroundPrimary)
    }

    // MARK: - Actions

    private func completeCoaching() {
        hasCompleted = true
        HapticManager.notification(.success)
        isPresented = false
    }
}

// MARK: - Coaching Step Model

/// Individual step in the capture coaching tutorial
struct CoachingStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let tip: String

    /// All coaching steps in order
    static let allSteps: [CoachingStep] = [
        CoachingStep(
            icon: "sun.max.fill",
            title: "Good Lighting",
            description: "Find a well-lit area. Natural light works best. Avoid shadows falling across the page.",
            tip: "Near a window during daytime is ideal"
        ),
        CoachingStep(
            icon: "rectangle.portrait",
            title: "Position the Page",
            description: "Hold your phone parallel to the page. Fill the frame with the text area—margins can be cropped.",
            tip: "Keep the page flat, not curved"
        ),
        CoachingStep(
            icon: "hand.raised.fill",
            title: "Hold Steady",
            description: "Keep your phone still when capturing. You'll feel haptic feedback when the photo is taken.",
            tip: "Rest your elbows on a table for stability"
        ),
        CoachingStep(
            icon: "highlighter",
            title: "Check Your Markings",
            description: "Make sure your underlines, highlights, and margin notes are clearly visible. The AI will look for these.",
            tip: "Darker markings extract more reliably"
        )
    ]
}

// MARK: - Coaching Manager

/// Manages coaching state and re-triggering
@Observable
final class CaptureCoachingManager {
    @AppStorage("hasCompletedCaptureCoaching") var hasCompleted = false

    /// Reset coaching to show tutorial again
    func resetCoaching() {
        hasCompleted = false
    }

    /// Whether to show coaching
    var shouldShowCoaching: Bool {
        !hasCompleted
    }
}

// MARK: - Settings Integration Row

/// Row for settings screen to reset/show coaching
struct CaptureCoachingSettingsRow: View {
    @State private var manager = CaptureCoachingManager()
    @State private var showCoaching = false

    var body: some View {
        Button {
            showCoaching = true
        } label: {
            HStack {
                Label("Capture Tips", systemImage: "lightbulb")
                Spacer()
                if manager.hasCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                }
            }
        }
        .sheet(isPresented: $showCoaching) {
            FirstCaptureCoachingView(isPresented: $showCoaching)
                .presentationDetents([.large])
        }
    }
}

// MARK: - Preview

#Preview("Coaching View") {
    FirstCaptureCoachingView(isPresented: .constant(true))
}

#Preview("Settings Row") {
    List {
        CaptureCoachingSettingsRow()
    }
}
