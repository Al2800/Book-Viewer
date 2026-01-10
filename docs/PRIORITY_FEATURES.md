# Priority Features Technical Specification

## Overview

This document provides detailed technical specifications for the 5 highest-priority features identified through careful analysis. Each feature is designed to be implementable within the existing SwiftUI + SwiftData + Gemini tech stack.

---

## Feature 1: Pre-Upload Image Quality Assessment

### Purpose
Prevent failed extractions by analyzing image quality locally before sending to Gemini. Guide users to capture better images when quality is insufficient.

### Technical Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Camera Capture │ ──▶ │ Quality Analyzer │ ──▶ │ Decision Gate   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                         │
                        ┌────────────────────────────────┼────────────────────────────────┐
                        ▼                                ▼                                ▼
                 ┌─────────────┐                 ┌──────────────┐                 ┌──────────────┐
                 │  Pass       │                 │  Warn        │                 │  Fail        │
                 │  → Process  │                 │  → Suggest   │                 │  → Retake    │
                 └─────────────┘                 └──────────────┘                 └──────────────┘
```

### Implementation

#### ImageQualityAnalyzer Service

```swift
import Vision
import CoreImage
import UIKit

/// Analyzes captured images for quality issues before API submission
@MainActor
@Observable
final class ImageQualityAnalyzer {

    // MARK: - Quality Thresholds

    private enum Threshold {
        static let minimumBlurScore: Double = 80        // Laplacian variance
        static let warningBlurScore: Double = 120       // Below this = warning
        static let minimumBrightness: Double = 0.15     // 0-1 scale
        static let maximumBrightness: Double = 0.85     // Avoid overexposure
        static let minimumTextConfidence: Float = 0.4   // Vision text detection
        static let minimumTextBlocks: Int = 3           // At least some text detected
    }

    // MARK: - Assessment Result

    struct Assessment {
        let blurScore: Double
        let brightnessScore: Double
        let textConfidence: Float
        let textBlockCount: Int
        let overallQuality: Quality
        let issues: [QualityIssue]

        enum Quality: Comparable {
            case excellent  // All checks pass with margin
            case acceptable // All checks pass
            case marginal   // Some warnings, may work
            case poor       // Likely to fail, recommend retake
        }

        var canProceed: Bool {
            overallQuality >= .marginal
        }

        var shouldWarn: Bool {
            overallQuality == .marginal || !issues.isEmpty
        }
    }

    enum QualityIssue {
        case tooBlurry
        case tooDark
        case tooBright
        case insufficientText
        case extremeAngle

        var message: String {
            switch self {
            case .tooBlurry:
                return "Image appears blurry—hold your phone steadier"
            case .tooDark:
                return "Image is too dark—try better lighting"
            case .tooBright:
                return "Image is overexposed—avoid direct light on page"
            case .insufficientText:
                return "Can't detect much text—ensure the page is fully visible"
            case .extremeAngle:
                return "Page appears tilted—try to capture straight-on"
            }
        }

        var icon: String {
            switch self {
            case .tooBlurry: return "camera.metering.center.weighted"
            case .tooDark: return "sun.min"
            case .tooBright: return "sun.max.fill"
            case .insufficientText: return "text.magnifyingglass"
            case .extremeAngle: return "skew"
            }
        }
    }

    // MARK: - Analysis Methods

    /// Perform comprehensive quality assessment
    func analyze(_ image: UIImage) async -> Assessment {
        async let blurResult = analyzeBlur(image)
        async let brightnessResult = analyzeBrightness(image)
        async let textResult = analyzeTextPresence(image)

        let blur = await blurResult
        let brightness = await brightnessResult
        let (textConfidence, textCount) = await textResult

        var issues: [QualityIssue] = []

        // Check blur
        if blur < Threshold.minimumBlurScore {
            issues.append(.tooBlurry)
        }

        // Check brightness
        if brightness < Threshold.minimumBrightness {
            issues.append(.tooDark)
        } else if brightness > Threshold.maximumBrightness {
            issues.append(.tooBright)
        }

        // Check text detection
        if textConfidence < Threshold.minimumTextConfidence || textCount < Threshold.minimumTextBlocks {
            issues.append(.insufficientText)
        }

        // Determine overall quality
        let quality: Assessment.Quality
        if issues.contains(.tooBlurry) || issues.contains(.insufficientText) {
            quality = .poor
        } else if issues.count > 0 {
            quality = .marginal
        } else if blur > Threshold.warningBlurScore && textConfidence > 0.7 {
            quality = .excellent
        } else {
            quality = .acceptable
        }

        return Assessment(
            blurScore: blur,
            brightnessScore: brightness,
            textConfidence: textConfidence,
            textBlockCount: textCount,
            overallQuality: quality,
            issues: issues
        )
    }

    // MARK: - Blur Detection (Laplacian Variance)

    /// Higher score = sharper image
    private func analyzeBlur(_ image: UIImage) async -> Double {
        guard let cgImage = image.cgImage else { return 0 }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])

        // Convert to grayscale
        guard let grayscaleFilter = CIFilter(name: "CIColorControls") else { return 0 }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0, forKey: kCIInputSaturationKey)

        guard let grayscale = grayscaleFilter.outputImage else { return 0 }

        // Apply Laplacian edge detection
        let laplacianKernel: [CGFloat] = [
            0,  1, 0,
            1, -4, 1,
            0,  1, 0
        ]

        guard let convolutionFilter = CIFilter(name: "CIConvolution3X3") else { return 0 }
        convolutionFilter.setValue(grayscale, forKey: kCIInputImageKey)
        convolutionFilter.setValue(CIVector(values: laplacianKernel, count: 9), forKey: "inputWeights")

        guard let laplacian = convolutionFilter.outputImage else { return 0 }

        // Calculate variance of the Laplacian
        // Higher variance = more edges = sharper image
        let extent = laplacian.extent
        var bitmap = [UInt8](repeating: 0, count: Int(extent.width * extent.height))

        context.render(
            laplacian,
            toBitmap: &bitmap,
            rowBytes: Int(extent.width),
            bounds: extent,
            format: .L8,
            colorSpace: CGColorSpaceCreateDeviceGray()
        )

        // Calculate variance
        let mean = bitmap.reduce(0) { $0 + Double($1) } / Double(bitmap.count)
        let variance = bitmap.reduce(0) { $0 + pow(Double($1) - mean, 2) } / Double(bitmap.count)

        return variance
    }

    // MARK: - Brightness Analysis

    /// Returns 0-1 where 0.5 is ideal
    private func analyzeBrightness(_ image: UIImage) async -> Double {
        guard let cgImage = image.cgImage else { return 0.5 }

        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        // Use CIAreaAverage to get mean color
        guard let averageFilter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        averageFilter.setValue(ciImage, forKey: kCIInputImageKey)
        averageFilter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = averageFilter.outputImage else { return 0.5 }

        let context = CIContext()
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        // Calculate luminance: 0.299*R + 0.587*G + 0.114*B
        let luminance = (0.299 * Double(pixel[0]) + 0.587 * Double(pixel[1]) + 0.114 * Double(pixel[2])) / 255.0

        return luminance
    }

    // MARK: - Text Presence Detection

    /// Returns (confidence, block count)
    private func analyzeTextPresence(_ image: UIImage) async -> (Float, Int) {
        guard let cgImage = image.cgImage else { return (0, 0) }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: (0, 0))
                    return
                }

                let confidences = observations.compactMap { $0.topCandidates(1).first?.confidence }
                let averageConfidence = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Float(confidences.count)

                continuation.resume(returning: (averageConfidence, observations.count))
            }

            request.recognitionLevel = .fast // Speed over accuracy for quality check
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
```

#### Quality Assessment UI

```swift
struct ImageQualitySheet: View {
    let image: UIImage
    let assessment: ImageQualityAnalyzer.Assessment
    let onRetake: () -> Void
    let onProceed: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

            // Quality indicator
            qualityIndicator

            // Issues list
            if !assessment.issues.isEmpty {
                issuesList
            }

            // Actions
            actionButtons
        }
        .padding(Spacing.xl)
    }

    private var qualityIndicator: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(qualityColor)
                .frame(width: 12, height: 12)

            Text(qualityLabel)
                .font(.headline)
        }
    }

    private var qualityColor: Color {
        switch assessment.overallQuality {
        case .excellent: return .green
        case .acceptable: return .green
        case .marginal: return .yellow
        case .poor: return .red
        }
    }

    private var qualityLabel: String {
        switch assessment.overallQuality {
        case .excellent: return "Excellent quality"
        case .acceptable: return "Good quality"
        case .marginal: return "May have issues"
        case .poor: return "Poor quality—retake recommended"
        }
    }

    private var issuesList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(assessment.issues, id: \.message) { issue in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: issue.icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    Text(issue.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            Button("Retake") {
                onRetake()
            }
            .buttonStyle(.bordered)

            Button(assessment.overallQuality == .poor ? "Try Anyway" : "Continue") {
                onProceed()
            }
            .buttonStyle(.borderedProminent)
            .tint(assessment.overallQuality == .poor ? .orange : .accent)
        }
    }
}
```

#### Integration with Capture Flow

```swift
struct QuoteCaptureView: View {
    @State private var capturedImage: UIImage?
    @State private var assessment: ImageQualityAnalyzer.Assessment?
    @State private var showQualitySheet = false
    @State private var isAnalyzing = false

    private let qualityAnalyzer = ImageQualityAnalyzer()

    func handleCapture(_ image: UIImage) {
        capturedImage = image
        isAnalyzing = true

        Task {
            let result = await qualityAnalyzer.analyze(image)
            assessment = result
            isAnalyzing = false

            if result.shouldWarn || result.overallQuality == .poor {
                showQualitySheet = true
            } else {
                // Quality is good, proceed directly
                proceedToProcessing(image)
            }
        }
    }

    func proceedToProcessing(_ image: UIImage) {
        // Send to Gemini for extraction
    }
}
```

### Performance Considerations

- **Blur analysis**: ~50-100ms on modern devices
- **Brightness analysis**: ~10ms
- **Text detection**: ~100-200ms with `.fast` recognition level
- **Total**: ~200-300ms, acceptable for post-capture flow

### Testing Strategy

```swift
final class ImageQualityAnalyzerTests: XCTestCase {
    let analyzer = ImageQualityAnalyzer()

    func testBlurryImageDetected() async {
        let blurryImage = UIImage(named: "test_blurry_page")!
        let assessment = await analyzer.analyze(blurryImage)

        XCTAssertTrue(assessment.issues.contains(.tooBlurry))
        XCTAssertEqual(assessment.overallQuality, .poor)
    }

    func testDarkImageDetected() async {
        let darkImage = UIImage(named: "test_dark_page")!
        let assessment = await analyzer.analyze(darkImage)

        XCTAssertTrue(assessment.issues.contains(.tooDark))
    }

    func testGoodImagePasses() async {
        let goodImage = UIImage(named: "test_good_page")!
        let assessment = await analyzer.analyze(goodImage)

        XCTAssertTrue(assessment.issues.isEmpty)
        XCTAssertGreaterThanOrEqual(assessment.overallQuality, .acceptable)
    }
}
```

---

## Feature 2: Multi-Page Batch Capture Mode

### Purpose
Allow users to capture multiple pages in sequence before processing, matching how people actually read and annotate books.

### Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Capture Session                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐         │
│  │ Pg 1 │  │ Pg 2 │  │ Pg 3 │  │ Pg 4 │  │ + Add│         │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘         │
├─────────────────────────────────────────────────────────────┤
│  [Cancel Session]              [Process 4 Pages]            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Batch Processing Queue                     │
├─────────────────────────────────────────────────────────────┤
│  Page 1: ✓ Complete    │  Page 3: ◐ Processing              │
│  Page 2: ✓ Complete    │  Page 4: ○ Pending                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Batch Review                             │
├─────────────────────────────────────────────────────────────┤
│  12 quotes extracted from 4 pages                           │
│  [Review & Save All]  [Review Individually]                 │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

#### CaptureSession Model

```swift
import SwiftUI
import Observation

@MainActor
@Observable
final class CaptureSession {
    // MARK: - Types

    struct CapturedPage: Identifiable {
        let id = UUID()
        let image: UIImage
        let thumbnail: UIImage
        let captureDate: Date
        var qualityAssessment: ImageQualityAnalyzer.Assessment?
        var processingStatus: ProcessingStatus = .pending
        var extractedQuotes: [ExtractedQuoteResponse] = []
        var error: Error?
    }

    enum ProcessingStatus: Equatable {
        case pending
        case processing
        case completed
        case failed
    }

    enum SessionState {
        case inactive
        case capturing
        case processing
        case reviewing
    }

    // MARK: - State

    private(set) var pages: [CapturedPage] = []
    private(set) var state: SessionState = .inactive
    private(set) var processingProgress: Double = 0

    var pageCount: Int { pages.count }
    var canProcess: Bool { !pages.isEmpty && state == .capturing }
    var completedCount: Int { pages.filter { $0.processingStatus == .completed }.count }
    var totalExtractedQuotes: Int { pages.flatMap { $0.extractedQuotes }.count }

    // MARK: - Dependencies

    private let qualityAnalyzer = ImageQualityAnalyzer()
    private let geminiService: GeminiService
    private let book: Book

    init(book: Book, geminiService: GeminiService) {
        self.book = book
        self.geminiService = geminiService
    }

    // MARK: - Session Management

    func startSession() {
        pages = []
        state = .capturing
        processingProgress = 0
    }

    func endSession() {
        pages = []
        state = .inactive
    }

    // MARK: - Capture Management

    func addCapture(_ image: UIImage) async {
        guard state == .capturing else { return }

        // Generate thumbnail
        let thumbnail = image.resizedToFit(maxDimension: 150)

        // Create page entry
        var page = CapturedPage(
            image: image,
            thumbnail: thumbnail,
            captureDate: Date()
        )

        // Analyze quality in background
        let assessment = await qualityAnalyzer.analyze(image)
        page.qualityAssessment = assessment

        pages.append(page)

        // Haptic feedback
        HapticManager.impact(.light)
    }

    func removePage(at index: Int) {
        guard pages.indices.contains(index) else { return }
        pages.remove(at: index)
    }

    func removePage(_ page: CapturedPage) {
        pages.removeAll { $0.id == page.id }
    }

    // MARK: - Batch Processing

    func processAllPages() async {
        guard canProcess else { return }

        state = .processing
        processingProgress = 0

        let totalPages = Double(pages.count)

        for (index, _) in pages.enumerated() {
            pages[index].processingStatus = .processing

            do {
                // Prepare image
                guard let imageData = pages[index].image.preparedForGemini() else {
                    throw GeminiService.GeminiError.imageProcessingFailed
                }

                // Extract quotes
                let response = try await geminiService.extractQuotes(from: imageData)

                pages[index].extractedQuotes = response.quotes
                pages[index].processingStatus = .completed

            } catch {
                pages[index].error = error
                pages[index].processingStatus = .failed
            }

            // Update progress
            processingProgress = Double(index + 1) / totalPages

            // Rate limiting delay between requests
            if index < pages.count - 1 {
                try? await Task.sleep(for: .milliseconds(500))
            }
        }

        state = .reviewing
    }

    // MARK: - Results

    func getAllExtractedQuotes() -> [(page: CapturedPage, quotes: [ExtractedQuoteResponse])] {
        pages.filter { $0.processingStatus == .completed }
            .map { ($0, $0.extractedQuotes) }
    }

    func saveAllQuotes(to context: ModelContext) -> [Quote] {
        var savedQuotes: [Quote] = []

        for page in pages where page.processingStatus == .completed {
            for extracted in page.extractedQuotes {
                let quote = extracted.toQuote(book: book)
                quote.sourceImageData = page.image.preparedForGemini()
                context.insert(quote)
                savedQuotes.append(quote)
            }
        }

        return savedQuotes
    }
}
```

#### Batch Capture UI

```swift
struct BatchCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var session: CaptureSession
    @State private var showCamera = true
    @State private var showProcessingSheet = false

    let book: Book
    let geminiService: GeminiService

    init(book: Book, geminiService: GeminiService) {
        self.book = book
        self.geminiService = geminiService
        self._session = State(initialValue: CaptureSession(book: book, geminiService: geminiService))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera
                if showCamera {
                    CameraView(onCapture: handleCapture)
                }

                // Overlay UI
                VStack {
                    Spacer()

                    // Thumbnail strip
                    if !session.pages.isEmpty {
                        thumbnailStrip
                    }

                    // Actions
                    bottomBar
                }
            }
            .navigationTitle("Batch Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        session.endSession()
                        dismiss()
                    }
                }
            }
            .onAppear {
                session.startSession()
            }
            .sheet(isPresented: $showProcessingSheet) {
                BatchProcessingSheet(session: session, book: book)
            }
        }
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(session.pages.enumerated()), id: \.element.id) { index, page in
                    ThumbnailView(
                        page: page,
                        index: index + 1,
                        onDelete: { session.removePage(at: index) }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .frame(height: 80)
        .background(.ultraThinMaterial)
    }

    private var bottomBar: some View {
        HStack {
            // Page count
            Text("\(session.pageCount) page\(session.pageCount == 1 ? "" : "s")")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            // Process button
            Button {
                showProcessingSheet = true
                Task {
                    await session.processAllPages()
                }
            } label: {
                Label("Process All", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!session.canProcess)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func handleCapture(_ image: UIImage) {
        Task {
            await session.addCapture(image)
        }
    }
}

struct ThumbnailView: View {
    let page: CaptureSession.CapturedPage
    let index: Int
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: page.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    // Quality indicator
                    if let assessment = page.qualityAssessment,
                       assessment.overallQuality == .poor {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.orange, lineWidth: 2)
                    }
                }

            // Page number badge
            Text("\(index)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(4)
                .background(.black.opacity(0.6))
                .clipShape(Circle())
                .offset(x: 4, y: -4)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white, .red)
            }
            .offset(x: 8, y: -8)
        }
    }
}
```

#### Batch Processing Sheet

```swift
struct BatchProcessingSheet: View {
    @Bindable var session: CaptureSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: Book

    var body: some View {
        NavigationStack {
            Group {
                switch session.state {
                case .processing:
                    processingView
                case .reviewing:
                    reviewView
                default:
                    EmptyView()
                }
            }
            .navigationTitle(session.state == .processing ? "Processing" : "Review")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var processingView: some View {
        VStack(spacing: Spacing.xl) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: session.processingProgress)
                    .stroke(.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: session.processingProgress)

                VStack {
                    Text("\(session.completedCount)/\(session.pageCount)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("pages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Status list
            List {
                ForEach(Array(session.pages.enumerated()), id: \.element.id) { index, page in
                    HStack {
                        Text("Page \(index + 1)")
                        Spacer()
                        statusIcon(for: page.processingStatus)
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }

    private var reviewView: some View {
        VStack(spacing: Spacing.lg) {
            // Summary
            VStack(spacing: Spacing.sm) {
                Text("\(session.totalExtractedQuotes)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.accent)

                Text("quotes extracted from \(session.completedCount) pages")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.xl)

            // Quote preview list
            List {
                ForEach(session.getAllExtractedQuotes(), id: \.page.id) { page, quotes in
                    Section("Page \(pageIndex(page) + 1)") {
                        ForEach(quotes, id: \.text) { quote in
                            Text(quote.text)
                                .font(.caption)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)

            // Actions
            HStack(spacing: Spacing.md) {
                Button("Discard All") {
                    session.endSession()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save All Quotes") {
                    let _ = session.saveAllQuotes(to: modelContext)
                    HapticManager.notification(.success)
                    session.endSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func statusIcon(for status: CaptureSession.ProcessingStatus) -> some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            case .processing:
                ProgressView()
                    .scaleEffect(0.8)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private func pageIndex(_ page: CaptureSession.CapturedPage) -> Int {
        session.pages.firstIndex { $0.id == page.id } ?? 0
    }
}
```

### Concurrency Considerations

```swift
extension CaptureSession {
    /// Process pages with controlled concurrency
    func processAllPagesParallel(maxConcurrent: Int = 2) async {
        state = .processing

        await withTaskGroup(of: (Int, Result<[ExtractedQuoteResponse], Error>).self) { group in
            var activeTasks = 0
            var nextIndex = 0

            // Seed initial tasks
            while activeTasks < maxConcurrent && nextIndex < pages.count {
                let index = nextIndex
                group.addTask {
                    await self.processPage(at: index)
                    return (index, .success(self.pages[index].extractedQuotes))
                }
                activeTasks += 1
                nextIndex += 1
            }

            // Process results and add new tasks
            for await (index, result) in group {
                activeTasks -= 1
                processingProgress = Double(index + 1) / Double(pages.count)

                // Add next task if available
                if nextIndex < pages.count {
                    let idx = nextIndex
                    group.addTask {
                        await self.processPage(at: idx)
                        return (idx, .success(self.pages[idx].extractedQuotes))
                    }
                    activeTasks += 1
                    nextIndex += 1
                }
            }
        }

        state = .reviewing
    }

    private func processPage(at index: Int) async {
        pages[index].processingStatus = .processing

        do {
            guard let imageData = pages[index].image.preparedForGemini() else {
                throw GeminiService.GeminiError.imageProcessingFailed
            }

            let response = try await geminiService.extractQuotes(from: imageData)
            pages[index].extractedQuotes = response.quotes
            pages[index].processingStatus = .completed
        } catch {
            pages[index].error = error
            pages[index].processingStatus = .failed
        }
    }
}
```

---

## Feature 3: ISBN Barcode Scanning

### Purpose
Provide a reliable, accurate alternative to cover photo recognition for book identification using ISBN barcodes.

### Technical Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Camera + Scan  │ ──▶ │ Vision Barcode   │ ──▶ │ ISBN Extracted  │
└─────────────────┘     │ Detection        │     └─────────────────┘
                        └──────────────────┘              │
                                                          ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │ Google Books API │ ◀── │ API Lookup      │
                        │ (or OpenLibrary) │     └─────────────────┘
                        └──────────────────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │ Verified Book    │
                        │ Metadata         │
                        └──────────────────┘
```

### Implementation

#### ISBN Scanner Service

```swift
import Vision
import AVFoundation

@MainActor
@Observable
final class ISBNScanner {
    // MARK: - State

    private(set) var isScanning = false
    private(set) var detectedISBN: String?
    private(set) var lookupResult: BookLookupResult?
    private(set) var error: ISBNError?

    enum ISBNError: LocalizedError {
        case noBarcode
        case invalidISBN
        case lookupFailed(Error)
        case bookNotFound

        var errorDescription: String? {
            switch self {
            case .noBarcode: return "No barcode detected"
            case .invalidISBN: return "Invalid ISBN format"
            case .lookupFailed(let error): return "Lookup failed: \(error.localizedDescription)"
            case .bookNotFound: return "Book not found in database"
            }
        }
    }

    struct BookLookupResult {
        let isbn: String
        let title: String
        let authors: [String]
        let publisher: String?
        let publishedDate: String?
        let pageCount: Int?
        let description: String?
        let coverImageURL: URL?
        let source: LookupSource

        enum LookupSource {
            case googleBooks
            case openLibrary
        }

        var authorString: String {
            authors.joined(separator: ", ")
        }

        func toBook() -> Book {
            let book = Book(title: title, author: authorString)
            book.isbn = isbn
            book.publisher = publisher
            book.pageCount = pageCount
            return book
        }
    }

    // MARK: - Barcode Detection

    /// Scan image for ISBN barcode
    func scanForISBN(_ image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                guard let results = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Look for EAN-13 (ISBN-13) or EAN-8
                for result in results {
                    if result.symbology == .ean13 || result.symbology == .ean8 {
                        if let payload = result.payloadStringValue,
                           self.isValidISBN(payload) {
                            continuation.resume(returning: payload)
                            return
                        }
                    }
                }

                continuation.resume(returning: nil)
            }

            request.symbologies = [.ean13, .ean8]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Validate ISBN checksum
    private func isValidISBN(_ code: String) -> Bool {
        // ISBN-13 validation
        if code.count == 13 {
            let digits = code.compactMap { Int(String($0)) }
            guard digits.count == 13 else { return false }

            var sum = 0
            for (index, digit) in digits.enumerated() {
                sum += digit * (index % 2 == 0 ? 1 : 3)
            }
            return sum % 10 == 0
        }

        // ISBN-10 validation
        if code.count == 10 {
            var sum = 0
            for (index, char) in code.enumerated() {
                let value: Int
                if char == "X" && index == 9 {
                    value = 10
                } else if let digit = Int(String(char)) {
                    value = digit
                } else {
                    return false
                }
                sum += value * (10 - index)
            }
            return sum % 11 == 0
        }

        return false
    }

    // MARK: - Book Lookup

    /// Look up book metadata from ISBN
    func lookupISBN(_ isbn: String) async throws -> BookLookupResult {
        isScanning = true
        defer { isScanning = false }

        // Try Google Books first
        if let result = try? await lookupGoogleBooks(isbn) {
            return result
        }

        // Fallback to OpenLibrary
        if let result = try? await lookupOpenLibrary(isbn) {
            return result
        }

        throw ISBNError.bookNotFound
    }

    // MARK: - Google Books API

    private func lookupGoogleBooks(_ isbn: String) async throws -> BookLookupResult {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        guard let url = URL(string: urlString) else {
            throw ISBNError.lookupFailed(URLError(.badURL))
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ISBNError.lookupFailed(URLError(.badServerResponse))
        }

        let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        guard let item = decoded.items?.first,
              let volumeInfo = item.volumeInfo else {
            throw ISBNError.bookNotFound
        }

        return BookLookupResult(
            isbn: isbn,
            title: volumeInfo.title,
            authors: volumeInfo.authors ?? ["Unknown Author"],
            publisher: volumeInfo.publisher,
            publishedDate: volumeInfo.publishedDate,
            pageCount: volumeInfo.pageCount,
            description: volumeInfo.description,
            coverImageURL: volumeInfo.imageLinks?.thumbnail.flatMap { URL(string: $0.replacingOccurrences(of: "http://", with: "https://")) },
            source: .googleBooks
        )
    }

    // MARK: - OpenLibrary API

    private func lookupOpenLibrary(_ isbn: String) async throws -> BookLookupResult {
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data"
        guard let url = URL(string: urlString) else {
            throw ISBNError.lookupFailed(URLError(.badURL))
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ISBNError.lookupFailed(URLError(.badServerResponse))
        }

        let decoded = try JSONDecoder().decode([String: OpenLibraryBook].self, from: data)

        guard let book = decoded["ISBN:\(isbn)"] else {
            throw ISBNError.bookNotFound
        }

        return BookLookupResult(
            isbn: isbn,
            title: book.title,
            authors: book.authors?.map { $0.name } ?? ["Unknown Author"],
            publisher: book.publishers?.first?.name,
            publishedDate: book.publishDate,
            pageCount: book.numberOfPages,
            description: nil,
            coverImageURL: book.cover?.large.flatMap { URL(string: $0) },
            source: .openLibrary
        )
    }
}

// MARK: - API Response Models

struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?

    struct GoogleBookItem: Codable {
        let volumeInfo: VolumeInfo?
    }

    struct VolumeInfo: Codable {
        let title: String
        let authors: [String]?
        let publisher: String?
        let publishedDate: String?
        let pageCount: Int?
        let description: String?
        let imageLinks: ImageLinks?
    }

    struct ImageLinks: Codable {
        let thumbnail: String?
        let smallThumbnail: String?
    }
}

struct OpenLibraryBook: Codable {
    let title: String
    let authors: [Author]?
    let publishers: [Publisher]?
    let publishDate: String?
    let numberOfPages: Int?
    let cover: Cover?

    struct Author: Codable {
        let name: String
    }

    struct Publisher: Codable {
        let name: String
    }

    struct Cover: Codable {
        let small: String?
        let medium: String?
        let large: String?
    }

    enum CodingKeys: String, CodingKey {
        case title, authors, publishers, cover
        case publishDate = "publish_date"
        case numberOfPages = "number_of_pages"
    }
}
```

#### Real-Time Barcode Scanner View

```swift
import SwiftUI
import AVFoundation
import Vision

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onISBNDetected: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.onISBNDetected = onISBNDetected
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

class BarcodeScannerViewController: UIViewController {
    var onISBNDetected: ((String) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var detectionOverlay: CAShapeLayer?

    private var lastDetectedISBN: String?
    private var detectionCount = 0
    private let requiredDetections = 3 // Require 3 consistent detections

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "barcode.scanner"))
        session.addOutput(output)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        self.captureSession = session
        self.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func setupOverlay() {
        // Add scanning guide overlay
        let overlay = CAShapeLayer()
        overlay.strokeColor = UIColor.systemBlue.cgColor
        overlay.fillColor = UIColor.clear.cgColor
        overlay.lineWidth = 3

        let guideRect = CGRect(
            x: view.bounds.width * 0.1,
            y: view.bounds.height * 0.35,
            width: view.bounds.width * 0.8,
            height: view.bounds.height * 0.15
        )
        overlay.path = UIBezierPath(roundedRect: guideRect, cornerRadius: 8).cgPath

        view.layer.addSublayer(overlay)
        detectionOverlay = overlay
    }

    private func handleDetection(_ isbn: String) {
        if isbn == lastDetectedISBN {
            detectionCount += 1
        } else {
            lastDetectedISBN = isbn
            detectionCount = 1
        }

        if detectionCount >= requiredDetections {
            // Confirmed detection
            DispatchQueue.main.async { [weak self] in
                self?.captureSession?.stopRunning()

                // Visual feedback
                self?.detectionOverlay?.strokeColor = UIColor.systemGreen.cgColor

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                self?.onISBNDetected?(isbn)
            }
        }
    }
}

extension BarcodeScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let results = request.results as? [VNBarcodeObservation] else { return }

            for result in results {
                if result.symbology == .ean13,
                   let payload = result.payloadStringValue,
                   payload.hasPrefix("978") || payload.hasPrefix("979") { // ISBN prefixes
                    self?.handleDetection(payload)
                    return
                }
            }
        }

        request.symbologies = [.ean13]

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
```

#### ISBN Capture Flow UI

```swift
struct BookRegistrationView: View {
    @State private var captureMode: CaptureMode = .cover
    @State private var scannedISBN: String?
    @State private var lookupResult: ISBNScanner.BookLookupResult?
    @State private var isLookingUp = false
    @State private var showConfirmation = false

    private let scanner = ISBNScanner()

    enum CaptureMode {
        case cover
        case barcode
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode picker
                Picker("Capture Mode", selection: $captureMode) {
                    Label("Scan Cover", systemImage: "book.closed").tag(CaptureMode.cover)
                    Label("Scan Barcode", systemImage: "barcode.viewfinder").tag(CaptureMode.barcode)
                }
                .pickerStyle(.segmented)
                .padding()

                // Scanner view
                Group {
                    switch captureMode {
                    case .cover:
                        CoverCaptureView()
                    case .barcode:
                        BarcodeScannerView(onISBNDetected: handleISBNDetected)
                            .overlay {
                                if isLookingUp {
                                    Color.black.opacity(0.5)
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                    }
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showConfirmation) {
                if let result = lookupResult {
                    BookConfirmationSheet(result: result)
                }
            }
        }
    }

    private func handleISBNDetected(_ isbn: String) {
        scannedISBN = isbn
        isLookingUp = true

        Task {
            do {
                let result = try await scanner.lookupISBN(isbn)
                lookupResult = result
                showConfirmation = true
            } catch {
                // Show error
            }
            isLookingUp = false
        }
    }
}

struct BookConfirmationSheet: View {
    let result: ISBNScanner.BookLookupResult
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var author: String
    @State private var coverImage: UIImage?

    init(result: ISBNScanner.BookLookupResult) {
        self.result = result
        self._title = State(initialValue: result.title)
        self._author = State(initialValue: result.authorString)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Cover preview
                Section {
                    HStack {
                        Spacer()
                        AsyncImage(url: result.coverImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(.secondary.opacity(0.2))
                        }
                        .frame(width: 120, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                // Editable fields
                Section("Book Details") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                }

                // Read-only metadata
                Section("From Database") {
                    if let publisher = result.publisher {
                        LabeledContent("Publisher", value: publisher)
                    }
                    if let pages = result.pageCount {
                        LabeledContent("Pages", value: "\(pages)")
                    }
                    LabeledContent("ISBN", value: result.isbn)
                    LabeledContent("Source", value: result.source == .googleBooks ? "Google Books" : "OpenLibrary")
                }
            }
            .navigationTitle("Confirm Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Book") {
                        saveBook()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveBook() {
        let book = Book(title: title, author: author)
        book.isbn = result.isbn
        book.publisher = result.publisher
        book.pageCount = result.pageCount

        // Download cover image
        if let url = result.coverImageURL {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    book.coverThumbnailData = data
                }
            }
        }

        modelContext.insert(book)
    }
}
```

---

## Feature 4: Duplicate Quote Detection

### Purpose
Prevent library clutter by detecting and warning about duplicate or near-duplicate quotes before saving.

### Implementation

#### DuplicateDetector Service

```swift
import Foundation

/// Detects duplicate or near-duplicate quotes using fuzzy string matching
@MainActor
final class DuplicateDetector {

    // MARK: - Configuration

    struct Config {
        /// Minimum similarity ratio to consider a duplicate (0.0 - 1.0)
        var similarityThreshold: Double = 0.85

        /// Only check quotes from the same book
        var sameBookOnly: Bool = true

        /// Maximum quotes to check (for performance)
        var maxComparisons: Int = 1000
    }

    var config = Config()

    // MARK: - Detection Result

    struct DuplicateMatch {
        let existingQuote: Quote
        let similarity: Double

        var percentMatch: Int {
            Int(similarity * 100)
        }
    }

    // MARK: - Detection Methods

    /// Find quotes similar to the new text
    func findDuplicates(
        of newText: String,
        in existingQuotes: [Quote]
    ) -> [DuplicateMatch] {
        let normalizedNew = normalize(newText)

        var matches: [DuplicateMatch] = []

        let quotesToCheck = Array(existingQuotes.prefix(config.maxComparisons))

        for quote in quotesToCheck {
            let normalizedExisting = normalize(quote.text)
            let similarity = calculateSimilarity(normalizedNew, normalizedExisting)

            if similarity >= config.similarityThreshold {
                matches.append(DuplicateMatch(
                    existingQuote: quote,
                    similarity: similarity
                ))
            }
        }

        return matches.sorted { $0.similarity > $1.similarity }
    }

    /// Quick check if any duplicate exists
    func hasDuplicate(
        of newText: String,
        in existingQuotes: [Quote]
    ) -> Bool {
        let normalizedNew = normalize(newText)

        for quote in existingQuotes.prefix(config.maxComparisons) {
            let normalizedExisting = normalize(quote.text)
            let similarity = calculateSimilarity(normalizedNew, normalizedExisting)

            if similarity >= config.similarityThreshold {
                return true
            }
        }

        return false
    }

    // MARK: - Text Normalization

    /// Normalize text for comparison (lowercase, remove punctuation, collapse whitespace)
    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Similarity Calculation

    /// Calculate Levenshtein similarity (1.0 = identical, 0.0 = completely different)
    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    /// Levenshtein edit distance using Wagner-Fischer algorithm
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        let m = s1Array.count
        let n = s2Array.count

        // Edge cases
        if m == 0 { return n }
        if n == 0 { return m }

        // Use two rows instead of full matrix (space optimization)
        var previousRow = Array(0...n)
        var currentRow = [Int](repeating: 0, count: n + 1)

        for i in 1...m {
            currentRow[0] = i

            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1

                currentRow[j] = min(
                    previousRow[j] + 1,      // deletion
                    currentRow[j - 1] + 1,   // insertion
                    previousRow[j - 1] + cost // substitution
                )
            }

            swap(&previousRow, &currentRow)
        }

        return previousRow[n]
    }
}
```

#### Duplicate Detection UI Integration

```swift
struct QuoteReviewView: View {
    let extractedQuote: ExtractedQuoteResponse
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editedText: String
    @State private var duplicateMatches: [DuplicateDetector.DuplicateMatch] = []
    @State private var showDuplicateWarning = false
    @State private var isChecking = false

    @Query private var existingQuotes: [Quote]

    private let duplicateDetector = DuplicateDetector()

    init(extractedQuote: ExtractedQuoteResponse, book: Book) {
        self.extractedQuote = extractedQuote
        self.book = book
        self._editedText = State(initialValue: extractedQuote.text)

        // Query quotes for this book
        let bookID = book.id
        self._existingQuotes = Query(
            filter: #Predicate<Quote> { $0.book?.id == bookID },
            sort: \.captureDate
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $editedText)
                        .frame(minHeight: 150)
                }

                if let pageNumber = extractedQuote.pageNumber {
                    Section {
                        LabeledContent("Page", value: "\(pageNumber)")
                    }
                }
            }
            .navigationTitle("Review Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        checkForDuplicatesAndSave()
                    }
                }
            }
            .alert("Similar Quote Found", isPresented: $showDuplicateWarning) {
                Button("Save Anyway") { saveQuote() }
                Button("View Existing") { /* Navigate to existing quote */ }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let match = duplicateMatches.first {
                    Text("This quote is \(match.percentMatch)% similar to one you've already saved:\n\n\"\(match.existingQuote.text.prefix(100))...\"")
                }
            }
        }
    }

    private func checkForDuplicatesAndSave() {
        isChecking = true

        // Run duplicate detection
        duplicateMatches = duplicateDetector.findDuplicates(
            of: editedText,
            in: existingQuotes
        )

        isChecking = false

        if duplicateMatches.isEmpty {
            saveQuote()
        } else {
            showDuplicateWarning = true
        }
    }

    private func saveQuote() {
        let quote = Quote(text: editedText, book: book)
        quote.pageNumber = extractedQuote.pageNumber
        quote.marginNote = extractedQuote.marginNote

        modelContext.insert(quote)
        HapticManager.notification(.success)
        dismiss()
    }
}
```

#### Batch Duplicate Detection

```swift
extension DuplicateDetector {
    /// Check multiple quotes at once (for batch import)
    func findAllDuplicates(
        newQuotes: [String],
        existingQuotes: [Quote]
    ) -> [Int: [DuplicateMatch]] {
        var results: [Int: [DuplicateMatch]] = [:]

        for (index, newText) in newQuotes.enumerated() {
            let matches = findDuplicates(of: newText, in: existingQuotes)
            if !matches.isEmpty {
                results[index] = matches
            }
        }

        return results
    }
}
```

---

## Feature 5: Confidence Scoring with Correction Feedback

### Purpose
Display AI confidence levels to build trust and collect user corrections to enable future improvements.

### Implementation

#### Enhanced Quote Extraction Response

```swift
struct ExtractedQuoteResponse: Codable {
    let text: String
    let pageNumber: Int?
    let marginNote: String?
    let markingType: String
    let confidence: Double  // 0.0 - 1.0

    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.9...: return .high
        case 0.75..<0.9: return .medium
        case 0.5..<0.75: return .low
        default: return .veryLow
        }
    }

    enum ConfidenceLevel {
        case high, medium, low, veryLow

        var color: Color {
            switch self {
            case .high: return .green
            case .medium: return .yellow
            case .low: return .orange
            case .veryLow: return .red
            }
        }

        var label: String {
            switch self {
            case .high: return "High confidence"
            case .medium: return "Medium confidence"
            case .low: return "Low confidence"
            case .veryLow: return "Review carefully"
            }
        }

        var icon: String {
            switch self {
            case .high: return "checkmark.circle.fill"
            case .medium: return "circle.fill"
            case .low: return "exclamationmark.circle.fill"
            case .veryLow: return "xmark.circle.fill"
            }
        }
    }
}
```

#### Correction Tracking Model

```swift
@Model
final class QuoteCorrection {
    var id: UUID

    /// Original text from AI extraction
    var originalText: String

    /// User-corrected text
    var correctedText: String

    /// Type of correction
    var correctionType: CorrectionType

    /// AI confidence at extraction time
    var originalConfidence: Double

    /// Marking type the quote was extracted from
    var markingType: String

    /// Image quality metrics at capture time
    var blurScore: Double?
    var brightnessScore: Double?

    /// When the correction was made
    var timestamp: Date

    /// Associated quote (if still exists)
    var quote: Quote?

    init(
        original: String,
        corrected: String,
        confidence: Double,
        markingType: String
    ) {
        self.id = UUID()
        self.originalText = original
        self.correctedText = corrected
        self.originalConfidence = confidence
        self.markingType = markingType
        self.correctionType = Self.classifyCorrection(original: original, corrected: corrected)
        self.timestamp = Date()
    }

    enum CorrectionType: String, Codable {
        case minorTypo       // 1-2 character changes
        case wordCorrection  // Word-level fixes
        case majorEdit       // Significant changes
        case deletion        // User deleted quote entirely
    }

    static func classifyCorrection(original: String, corrected: String) -> CorrectionType {
        let distance = levenshteinDistance(original, corrected)
        let ratio = Double(distance) / Double(max(original.count, corrected.count))

        switch ratio {
        case 0..<0.05: return .minorTypo
        case 0.05..<0.2: return .wordCorrection
        default: return .majorEdit
        }
    }
}
```

#### Confidence Display UI

```swift
struct ConfidenceIndicator: View {
    let confidence: Double
    let showLabel: Bool

    init(confidence: Double, showLabel: Bool = false) {
        self.confidence = confidence
        self.showLabel = showLabel
    }

    private var level: ExtractedQuoteResponse.ConfidenceLevel {
        switch confidence {
        case 0.9...: return .high
        case 0.75..<0.9: return .medium
        case 0.5..<0.75: return .low
        default: return .veryLow
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption2)
                .foregroundStyle(level.color)

            if showLabel {
                Text(level.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

#### Quote Review with Correction Tracking

```swift
struct QuoteReviewWithConfidence: View {
    let extracted: ExtractedQuoteResponse
    let book: Book
    let imageQuality: ImageQualityAnalyzer.Assessment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editedText: String
    @State private var hasBeenEdited = false

    init(extracted: ExtractedQuoteResponse, book: Book, imageQuality: ImageQualityAnalyzer.Assessment? = nil) {
        self.extracted = extracted
        self.book = book
        self.imageQuality = imageQuality
        self._editedText = State(initialValue: extracted.text)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Confidence section
                Section {
                    HStack {
                        Text("AI Confidence")
                        Spacer()
                        ConfidenceIndicator(confidence: extracted.confidence, showLabel: true)
                    }

                    if extracted.confidenceLevel == .low || extracted.confidenceLevel == .veryLow {
                        Text("This extraction may contain errors. Please review carefully.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Editable quote text
                Section("Quote Text") {
                    TextEditor(text: $editedText)
                        .frame(minHeight: 150)
                        .onChange(of: editedText) { _, newValue in
                            hasBeenEdited = (newValue != extracted.text)
                        }

                    if hasBeenEdited {
                        Label("You've made corrections", systemImage: "pencil")
                            .font(.caption)
                            .foregroundStyle(.accent)
                    }
                }

                // Metadata
                Section("Details") {
                    if let page = extracted.pageNumber {
                        LabeledContent("Page", value: "\(page)")
                    }
                    LabeledContent("Marking Type", value: extracted.markingType.capitalized)
                }
            }
            .navigationTitle("Review Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWithCorrection() }
                }
            }
        }
    }

    private func saveWithCorrection() {
        // Create quote
        let quote = Quote(text: editedText, book: book)
        quote.pageNumber = extracted.pageNumber
        quote.marginNote = extracted.marginNote
        modelContext.insert(quote)

        // Track correction if edited
        if hasBeenEdited {
            let correction = QuoteCorrection(
                original: extracted.text,
                corrected: editedText,
                confidence: extracted.confidence,
                markingType: extracted.markingType
            )
            correction.blurScore = imageQuality?.blurScore
            correction.brightnessScore = imageQuality?.brightnessScore
            correction.quote = quote
            modelContext.insert(correction)
        }

        HapticManager.notification(.success)
        dismiss()
    }
}
```

#### Correction Analytics

```swift
@MainActor
@Observable
final class CorrectionAnalytics {

    struct AnalysisReport {
        let totalCorrections: Int
        let correctionsByType: [QuoteCorrection.CorrectionType: Int]
        let correctionsByMarkingType: [String: Int]
        let averageOriginalConfidence: Double
        let lowConfidenceAccuracy: Double // % of low-confidence that needed correction
        let highConfidenceAccuracy: Double // % of high-confidence that needed correction

        var summary: String {
            """
            Total corrections: \(totalCorrections)
            High confidence accuracy: \(Int(highConfidenceAccuracy * 100))%
            Low confidence accuracy: \(Int(lowConfidenceAccuracy * 100))%
            Most corrected marking type: \(correctionsByMarkingType.max(by: { $0.value < $1.value })?.key ?? "N/A")
            """
        }
    }

    func analyze(corrections: [QuoteCorrection], allQuotes: [Quote]) -> AnalysisReport {
        let byType = Dictionary(grouping: corrections, by: { $0.correctionType })
            .mapValues { $0.count }

        let byMarking = Dictionary(grouping: corrections, by: { $0.markingType })
            .mapValues { $0.count }

        let avgConfidence = corrections.isEmpty ? 0 :
            corrections.map(\.originalConfidence).reduce(0, +) / Double(corrections.count)

        // Calculate accuracy rates
        let highConfidenceQuotes = allQuotes.filter {
            // Would need to track original confidence on Quote model
            true
        }

        return AnalysisReport(
            totalCorrections: corrections.count,
            correctionsByType: byType,
            correctionsByMarkingType: byMarking,
            averageOriginalConfidence: avgConfidence,
            lowConfidenceAccuracy: 0.7, // Placeholder - calculate from real data
            highConfidenceAccuracy: 0.95
        )
    }
}
```

---

## Implementation Priority & Timeline

| Feature | Priority | Estimated Effort | Dependencies |
|---------|----------|------------------|--------------|
| Image Quality Assessment | P0 | 2-3 days | Vision framework |
| Multi-Page Batch Capture | P0 | 3-4 days | Existing capture flow |
| ISBN Barcode Scanning | P1 | 2 days | Vision, Google Books API |
| Duplicate Detection | P1 | 1 day | None |
| Confidence Scoring | P2 | 2 days | Gemini prompt update |

### Recommended Implementation Order

1. **Image Quality Assessment** - Foundation for all captures
2. **Batch Capture Mode** - Major UX improvement
3. **Duplicate Detection** - Simple, high value
4. **ISBN Scanning** - Alternative capture path
5. **Confidence Scoring** - Polish and trust-building

---

## Testing Requirements

### Unit Tests
- Blur detection accuracy with known images
- ISBN validation (valid/invalid checksums)
- Levenshtein distance correctness
- Confidence level thresholds

### Integration Tests
- Quality assessment → capture flow
- Barcode detection → API lookup → book creation
- Batch capture → batch processing → review

### UI Tests
- Quality warning dismissal
- Batch capture session flow
- Duplicate warning interaction

### Performance Tests
- Quality analysis < 300ms
- Duplicate detection < 100ms for 1000 quotes
- Batch processing throughput
