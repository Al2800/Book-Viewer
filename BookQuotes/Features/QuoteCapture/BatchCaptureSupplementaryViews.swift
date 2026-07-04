import SwiftUI
import SwiftData

// MARK: - Thumbnail View

/// Small thumbnail showing a captured page.
/// Features entrance animation and tap feedback.
struct ThumbnailView: View {
    let capture: PageCapture

    @State private var hasAppeared = false
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let thumbnail = capture.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.backgroundSecondary
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    statusBadge
                }
            }
            .padding(Spacing.xxs)
        }
        .frame(width: 50, height: 65)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.white.opacity(isPressed ? 0.6 : 0.3), lineWidth: isPressed ? 2 : 1)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .brightness(isPressed ? 0.1 : 0)
        .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.7)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                hasAppeared = true
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.quickSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }

    @ViewBuilder
    private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay {
                Image(systemName: capture.status.icon)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private var statusColor: Color {
        switch capture.status {
        case .pending: return .brand
        case .processing: return .warning
        case .completed: return .success
        case .failed: return .error
        }
    }
}

// MARK: - Capture Detail Sheet

/// Detail sheet for viewing/removing a specific capture.
struct CaptureDetailSheet: View {
    let capture: PageCapture
    let session: CaptureSession
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if let image = capture.loadFullImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                } else {
                    ContentUnavailableView {
                        Label("Image Not Found", systemImage: "photo")
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    LabeledContent("Page", value: "\(capture.orderIndex + 1) of \(session.totalPages)")
                    LabeledContent("Status", value: capture.status.rawValue.capitalized)
                    if let quality = capture.qualityScore {
                        LabeledContent("Quality", value: "\(Int(quality * 100))%")
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Label("Remove Page", systemImage: "trash")
                }
                .buttonStyle(.destructive)
            }
            .padding(Spacing.lg)
            .navigationTitle("Page \(capture.orderIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Offline Queue Confirmation Sheet

/// Full confirmation sheet shown when captures are queued for offline processing.
struct OfflineQueueConfirmationSheet: View {
    let queuedCount: Int
    let bookTitle: String
    let onDismiss: () -> Void

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "arrow.down.circle.fill")
                    .batchQueueConfirmationSymbolEffect(isActive: hasAppeared && !reduceMotion)
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .opacity(hasAppeared ? 1 : 0)

            VStack(spacing: Spacing.sm) {
                Text("Saved for Later")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)

                Text("\(queuedCount) page\(queuedCount == 1 ? "" : "s") from \"\(bookTitle)\"")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            VStack(spacing: Spacing.md) {
                InfoRow(
                    icon: "wifi.slash",
                    text: "You're currently offline"
                )

                InfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Pages will process automatically when connected"
                )

                InfoRow(
                    icon: "bell.badge",
                    text: "You'll be notified when quotes are ready"
                )
            }
            .padding(Spacing.lg)
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            Spacer()

            Button {
                HapticManager.light()
                onDismiss()
            } label: {
                Text("Got it")
            }
            .buttonStyle(.primary)
            .opacity(hasAppeared ? 1 : 0)
        }
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }

            withAnimation(.smoothSpring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func batchQueueConfirmationSymbolEffect(isActive: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self
                .font(.system(size: 50))
                .foregroundStyle(Color.brand)
                .symbolEffect(.bounce, options: .nonRepeating, isActive: isActive)
        } else {
            self
                .font(.system(size: 50))
                .foregroundStyle(Color.brand)
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Offline Queue Toast

/// Deprecated notification kept for backwards compatibility.
struct OfflineQueueToast: View {
    let count: Int

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundStyle(Color.brand)
                .symbolEffect(.pulse, options: .repeating.speed(0.5), isActive: !reduceMotion)

            VStack(alignment: .leading, spacing: 2) {
                Text("Saved Offline")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("\(count) page\(count == 1 ? "" : "s") will process when connected")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.lg, colorScheme: colorScheme)
        .padding(.top, Spacing.xl)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : -20)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }

            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Batch Capture") {
    Group {
        if let container = ModelContainer.preview {
            BatchCaptureView(
                book: Book(title: "Test Book", author: "Author"),
                onComplete: { _ in },
                onCancel: {}
            )
            .modelContainer(container)
            .environment(NetworkMonitor())
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Offline Confirmation") {
    OfflineQueueConfirmationSheet(
        queuedCount: 5,
        bookTitle: "Thinking, Fast and Slow"
    ) {
        print("Dismissed")
    }
}

#Preview("Offline Toast (Deprecated)") {
    OfflineQueueToast(count: 5)
        .padding()
}
