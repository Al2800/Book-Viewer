import SwiftUI

// MARK: - Page Quote Editor

/// Editor view for quotes extracted from a single page.
/// Shows the source image with a list of editable quotes below.
struct PageQuoteEditor: View {
    let page: PageCapture
    @Binding var quotes: [EditableQuote]
    let onAddManualQuote: () -> Void

    @State private var showingFullImage = false
    @State private var imageScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Source image section
            imageSection

            Divider()

            // Quotes list section
            quotesSection
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        ZStack {
            Color.black

            if let image = page.loadFullImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                imageScale = scale
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    imageScale = max(1.0, min(imageScale, 3.0))
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            imageScale = imageScale > 1.5 ? 1.0 : 2.0
                        }
                    }
            } else if let thumbnail = page.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            } else {
                ContentUnavailableView(
                    "Image Not Found",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("The source image could not be loaded")
                )
            }

            // Zoom indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if imageScale > 1.0 {
                        Text("\(Int(imageScale * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                }
                .padding(Spacing.sm)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        )
        .padding(Spacing.sm)
        .paperCard(cornerRadius: CornerRadius.lg)
        .onTapGesture {
            showingFullImage = true
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            FullImageViewer(page: page)
        }
    }

    // MARK: - Quotes Section

    private var quotesSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("\(quotes.count) Quote\(quotes.count == 1 ? "" : "s")", systemImage: "text.quote")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button {
                    onAddManualQuote()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.brand)
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)

            // Quote list
            if quotes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach($quotes) { $quote in
                            QuoteEditRow(
                                quote: $quote,
                                onDelete: {
                                    deleteQuote(quote)
                                }
                            )
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .paperCard(cornerRadius: CornerRadius.lg)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "text.badge.xmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)

            Text("No Quotes Found")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text("The AI didn't find any marked passages on this page. You can add quotes manually.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                onAddManualQuote()
            } label: {
                Label("Add Quote Manually", systemImage: "plus")
            }
            .glassButton()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func deleteQuote(_ quote: EditableQuote) {
        withAnimation(.snappy) {
            quotes.removeAll { $0.id == quote.id }
        }
        HapticManager.light()
    }
}

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
            GeometryReader { geometry in
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

/// Vertical list of page thumbnails for navigation.
struct PageListView: View {
    let session: CaptureSession
    @Binding var selection: PageCapture?
    let quoteCounts: [UUID: Int]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(session.captures.sorted(by: { $0.orderIndex < $1.orderIndex })) { page in
                    PageThumbnailCell(
                        page: page,
                        quoteCount: quoteCounts[page.id] ?? 0,
                        isSelected: selection?.id == page.id
                    )
                    .onTapGesture {
                        withAnimation(.snappy) {
                            selection = page
                        }
                    }
                }
            }
            .padding(Spacing.sm)
        }
        .frame(width: 118)
        .paperCard(cornerRadius: CornerRadius.lg)
    }
}

// MARK: - Page Thumbnail Cell

/// Individual thumbnail cell showing page preview and quote count.
struct PageThumbnailCell: View {
    let page: PageCapture
    let quoteCount: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Thumbnail
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

                // Status overlay
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

            // Quote count
            Text("\(quoteCount)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(quoteCount > 0 ? Color.textPrimary : Color.textTertiary)

            // Page number if detected
            if let pageNum = page.detectedPageNumber {
                Text("p.\(pageNum)")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
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

// MARK: - Preview

#Preview("Page Quote Editor") {
    PageQuoteEditor(
        page: {
            let page = PageCapture(imagePath: "test.jpg")
            page.detectedPageNumber = 42
            return page
        }(),
        quotes: .constant([
            EditableQuote(
                pageId: UUID(),
                text: "The only way to do great work is to love what you do.",
                markingType: "underline",
                confidence: 0.95,
                pageNumber: 42
            ),
            EditableQuote(
                pageId: UUID(),
                text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
                markingType: "highlight",
                confidence: 0.82,
                pageNumber: 42,
                marginNote: "Churchill?"
            )
        ]),
        onAddManualQuote: {}
    )
}
