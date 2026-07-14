import SwiftUI

// MARK: - Full Image Viewer

/// Full-screen image viewer with zoom and pan.
struct FullImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let page: PageCapture

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let image = page.loadFullImage() {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = max(1.0, min(value, 5.0))
                                        }
                                        .onEnded { _ in
                                            if scale < 1.0 {
                                                withAnimation(.spring()) {
                                                    scale = 1.0
                                                    offset = .zero
                                                }
                                            }
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1.0 {
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring()) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2.5
                                    }
                                }
                            }
                    } else {
                        ContentUnavailableView(
                            "Image Not Found",
                            systemImage: "photo.badge.exclamationmark"
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                ToolbarItem(placement: .principal) {
                    if let pageNum = page.detectedPageNumber {
                        Text("Page \(pageNum)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if scale > 1.0 {
                        Button {
                            withAnimation(.spring()) {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Page List View

enum PageListLayout {
    case horizontal
    case vertical
}

/// A compact page selector that changes direction with the available review layout.
struct PageListView: View {
    let session: CaptureSession
    @Binding var selection: PageCapture?
    let quoteCounts: [UUID: Int]
    let layout: PageListLayout

    var body: some View {
        Group {
            switch layout {
            case .horizontal:
                ScrollView(.horizontal) {
                    LazyHStack(spacing: Spacing.sm) {
                        pageButtons
                    }
                    .padding(Spacing.sm)
                }
                .frame(height: 154)
            case .vertical:
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        pageButtons
                    }
                    .padding(Spacing.sm)
                }
                .frame(width: 118)
            }
        }
        .paperCard(cornerRadius: CornerRadius.lg)
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionPageSelector)
    }

    @ViewBuilder
    private var pageButtons: some View {
        ForEach(session.captures.sorted(by: { $0.orderIndex < $1.orderIndex })) { page in
            Button {
                withAnimation(.snappy) {
                    selection = page
                }
            } label: {
                PageThumbnailCell(
                    page: page,
                    quoteCount: quoteCounts[page.id] ?? 0,
                    isSelected: selection?.id == page.id
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(pageAccessibilityLabel(for: page))
            .accessibilityValue(selection?.id == page.id ? "Selected" : "Not selected")
            .accessibilityHint("Select this page for quote review")
        }
    }

    private func pageAccessibilityLabel(for page: PageCapture) -> String {
        let pageLabel = page.detectedPageNumber.map { "Page \($0)" } ?? "Captured page"
        let quoteCount = quoteCounts[page.id] ?? 0
        return "\(pageLabel), \(quoteCount) quote\(quoteCount == 1 ? "" : "s")"
    }
}

// MARK: - Page Thumbnail Cell

/// Individual thumbnail cell showing page preview and quote count.
struct PageThumbnailCell: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let page: PageCapture
    let quoteCount: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                if let thumbnail = page.loadThumbnail() {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.backgroundTertiary)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.textTertiary)
                        }
                }

                VStack {
                    Spacer()
                    HStack {
                        statusBadge
                        Spacer()
                    }
                }
                .padding(4)
            }
            .frame(width: 86, height: 112)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.backgroundCard)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(LinearGradient.brandAccent)
                            : AnyShapeStyle(Color.quoteBorder.opacity(0.5)),
                        lineWidth: isSelected ? Stroke.medium.width : Stroke.hairline.width
                    )
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0), radius: 6, y: 2)

            if !dynamicTypeSize.isAccessibilitySize {
                Text("\(quoteCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(quoteCount > 0 ? Color.textPrimary : Color.textTertiary)

                if let pageNum = page.detectedPageNumber {
                    Text("p.\(pageNum)")
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .opacity(isSelected ? 1.0 : 0.8)
    }

    private var statusBadge: some View {
        Group {
            switch page.status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.success)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.error)
            case .processing:
                ProgressView()
                    .scaleEffect(0.6)
            case .pending:
                EmptyView()
            }
        }
        .font(.caption)
        .padding(2)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
}
