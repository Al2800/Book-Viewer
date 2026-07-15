# Capture Flow Guide

This document explains the end-to-end capture system in BookQuotes—from photographing a book page to having quotes saved in your library.

---

## Table of Contents

1. [Overview](#overview)
2. [Capture Modes](#capture-modes)
3. [Single Quote Capture](#single-quote-capture)
4. [Batch Capture](#batch-capture)
5. [Cover Capture](#cover-capture)
6. [Offline Queue](#offline-queue)
7. [Quality Assessment](#quality-assessment)
8. [Extraction Review](#extraction-review)
9. [Error Recovery](#error-recovery)

---

## Overview

The capture system is designed around three principles:

1. **Fast capture, thoughtful review** — Users can quickly snap photos; AI does the heavy lifting; users verify results.
2. **Works offline** — Photos are queued locally and processed when connectivity returns.
3. **Quality gates** — Pre-upload analysis prevents failed extractions.

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      CaptureTabRootView                          │
│  ─────────────────────────────────────────────────────────────── │
│                                                                   │
│   ┌───────────────┐    ┌───────────────┐    ┌───────────────┐   │
│   │  Add New Book │    │ Capture Quotes│    │  Batch Mode   │   │
│   │  (ISBN scan)  │    │(Single page)  │    │(Multi-page)   │   │
│   └───────┬───────┘    └───────┬───────┘    └───────┬───────┘   │
│           │                    │                    │            │
│           ▼                    ▼                    ▼            │
│    CoverCaptureView      QuoteCaptureView     BatchCaptureView  │
│           │                    │                    │            │
│           ▼                    ▼                    ▼            │
│   Catalog Metadata        AI Extraction        Batch Processing │
│           │                    │                    │            │
│           ▼                    ▼                    ▼            │
│       BookEditView       QuoteDetailView     ExtractionReviewView│
│           │                    │                    │            │
│           └────────────────────┴────────────────────┘            │
│                               │                                   │
│                               ▼                                   │
│                          Library                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Capture Modes

BookQuotes offers three capture modes, accessible from the Capture tab:

### Mode Selection (`CaptureModeSelectionView`)

```swift
CaptureModeSelectionView(
    onSelectCoverCapture: { /* → Cover flow */ },
    onSelectQuoteCapture: { /* → Book selection → Quote capture */ },
    onSelectBatchCapture: { /* → Book selection → Batch capture */ }
)
```

| Mode | Use Case | Flow |
|------|----------|------|
| **Add New Book** | Register a new book | ISBN barcode → catalogue metadata → Edit → Save |
| **Capture Quotes** | Extract from one page | Select book → Photo → AI extraction → Review |
| **Batch Mode** | Extract from many pages | Select book → Multiple photos → Process all → Review all |

In UI tests, book registration exposes a `Use Test ISBN` affordance. It injects deterministic
catalogue metadata and opens `BookEditView` directly. Production registration scans a real ISBN
barcode, with manual entry available when a barcode or catalogue result is unavailable.

### Flow State (`CaptureFlowState`)

`CaptureTabRootView` owns SwiftUI concerns: permission gating, first-capture coaching, haptics, selected `Book` storage, and branch rendering. Deterministic mode changes live in `CaptureFlowState`.

`CaptureFlowState` handles:

- mode selection: `selection` to cover, book selection, or batch book selection;
- book-selection transitions into quote or batch capture;
- fresh quote and batch flow IDs so SwiftUI does not reuse stale capture child state;
- completion/cancellation transitions back to selection;
- selected-book clearing commands for quote and batch completion/cancellation.

When adding or changing capture-tab navigation, characterize the transition in `CaptureFlowStateTests` first, then delegate from `CaptureTabRootView`.

---

## Single Quote Capture

The simplest flow: capture one page, extract quotes, save.

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. SELECT BOOK                                                   │
│    BookSelectionForCaptureView                                   │
│    ├── Shows book grid (sorted by recent activity)              │
│    └── "Add New Book" option at top                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. CAPTURE PAGE                                                  │
│    QuoteCaptureView                                              │
│    ├── Live camera preview                                      │
│    ├── Quality overlay (blur/brightness feedback)               │
│    ├── Shutter button                                           │
│    └── Flash toggle                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. QUALITY CHECK                                                 │
│    ImageQualityAnalyzer                                          │
│    ├── Blur detection                                           │
│    ├── Brightness check                                         │
│    └── Text confidence                                          │
│                                                                   │
│    If issues: "Hold steadier" / "Improve lighting"              │
│    User can retake or proceed anyway                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. AI EXTRACTION                                                 │
│    GeminiService.extractQuotes()                                 │
│    ├── Image preprocessed (resize, compress)                    │
│    ├── Prompt built from user's marking definitions             │
│    ├── Request sent to proxy → Gemini API                       │
│    └── Response parsed into ExtractedQuote objects              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. REVIEW & EDIT                                                 │
│    PageQuoteEditor                                               │
│    ├── Shows extracted quotes with confidence badges            │
│    ├── User can edit text, fix errors                           │
│    ├── Delete false positives                                   │
│    └── Add page number if detected                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. SAVE                                                          │
│    QuoteSaveService                                              │
│    ├── Create Quote models                                      │
│    ├── Link to Book                                             │
│    ├── Check for duplicates                                     │
│    ├── Update search index                                      │
│    └── Show confirmation                                        │
└─────────────────────────────────────────────────────────────────┘
```

### Code Path

```swift
// QuoteCaptureView.swift
struct QuoteCaptureView: View {
    let book: Book
    let onComplete: () -> Void

    @Environment(GeminiService.self) private var geminiService
    @State private var capturedImage: UIImage?
    @State private var extractedQuotes: [ExtractedQuote] = []

    func captureAndProcess() async {
        // 1. Capture photo
        let image = try await cameraService.capturePhoto()

        // 2. Quality check
        let quality = ImageQualityAnalyzer.analyze(image)
        if !quality.isAcceptable {
            showQualityWarning(quality.issues)
            return
        }

        // 3. Extract quotes
        let markings = fetchMarkingDefinitions()
        let result = try await geminiService.extractQuotes(from: image, markings: markings)

        // 4. Show for review
        extractedQuotes = result.quotes
        showReviewSheet = true
    }
}
```

---

## Batch Capture

Optimized for capturing many pages quickly—photos are collected first, then processed together.

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. CAPTURE MULTIPLE PAGES                                        │
│    BatchCaptureView                                              │
│    ├── Live camera with capture button                          │
│    ├── Thumbnail strip showing captured pages                   │
│    ├── Counter: "5 of 20 max"                                   │
│    ├── Individual retake/delete                                 │
│    └── "Process All" button when ready                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Creates CaptureSession with PageCapture items
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. BATCH PROCESSING                                              │
│    BatchProcessingService                                        │
│    ├── Process up to 3 pages in parallel                        │
│    ├── Rate limiting (500ms between requests)                   │
│    ├── Progress updates: "Processing 3/10..."                   │
│    └── Collect all results                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. EXTRACTION REVIEW                                             │
│    ExtractionReviewView                                          │
│    ├── Page-by-page navigation                                  │
│    ├── Side-by-side: original image + extracted quotes          │
│    ├── Edit/delete individual quotes                            │
│    ├── Retry failed pages                                       │
│    └── Summary: "42 quotes from 10 pages"                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. BULK SAVE                                                     │
│    ├── All approved quotes saved                                │
│    ├── Search index updated                                     │
│    └── Return to capture selection                              │
└─────────────────────────────────────────────────────────────────┘
```

### CaptureSession Model

```swift
@Model
final class CaptureSession {
    var id: UUID
    var book: Book?
    var captures: [PageCapture] = []
    var status: SessionStatus
    var createdAt: Date

    // Progress tracking
    var totalPages: Int
    var processedPages: Int
    var failedPages: Int

    var isComplete: Bool {
        processedPages + failedPages == totalPages
    }
}

@Model
final class PageCapture {
    var id: UUID
    var session: CaptureSession?
    var status: CaptureStatus  // pending, processing, completed, failed
    var imagePath: String?     // File system path
    var thumbnailData: Data?
    var extractedQuotesJSON: Data?  // Serialized results
    var pageNumber: Int?
    var errorMessage: String?
}
```

### Processing Service

```swift
actor BatchProcessingService {
    func processSession(_ session: CaptureSession, markings: [MarkingDefinition], onProgress: ((BatchProgress) -> Void)?) async throws -> BatchResult {
        // Process with concurrency control
        await withTaskGroup(of: PageProcessingResult.self) { group in
            var activeCount = 0

            for capture in session.captures {
                // Wait if at max concurrency
                while activeCount >= configuration.maxConcurrent {
                    if let result = await group.next() {
                        activeCount -= 1
                        // Update progress...
                    }
                }

                group.addTask {
                    await self.processCapture(capture, markings: markings)
                }
                activeCount += 1

                // Rate limiting
                try? await Task.sleep(for: .milliseconds(500))
            }

            // Collect remaining results
            for await result in group {
                // Handle result...
            }
        }
    }
}
```

---

## ISBN Book Registration

The current production flow scans an ISBN barcode, looks up catalogue metadata, then opens the
editable book form. Manual entry is the fallback. Cover-photo AI, photo/ISBN mode switching, crop
review, and Gemini cover extraction shown in the historical diagram below are retired and are not
reachable from the app.

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. CAPTURE COVER                                                 │
│    CoverCaptureView                                              │
│    ├── Live camera preview                                      │
│    ├── Mode switcher: Photo / ISBN Scan                         │
│    └── Capture button                                           │
└─────────────────────────────────────────────────────────────────┘
              │                              │
              │ Photo mode                   │ ISBN mode
              ▼                              ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│ 2a. AI EXTRACTION        │    │ 2b. BARCODE SCAN         │
│     GeminiService        │    │     ISBNScanner          │
│     .extractCoverMetadata│    │     + ISBNLookupService  │
└──────────────────────────┘    └──────────────────────────┘
              │                              │
              └──────────────┬───────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. CONFIRM/EDIT METADATA                                         │
│    BookISBNConfirmationSheet (if ISBN)                           │
│    OR BookEditView (if photo)                                    │
│    ├── Title, author, subtitle                                  │
│    ├── Cover image preview                                      │
│    └── Save or adjust                                           │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SAVE BOOK                                                     │
│    ├── Create Book model                                        │
│    ├── Store cover image                                        │
│    ├── Update search index                                      │
│    └── Navigate to book detail or quote capture                 │
└─────────────────────────────────────────────────────────────────┘
```

### Registration Options

| Method | Accuracy | Speed | Best For |
|--------|----------|-------|----------|
| ISBN Scan | ~99% (database lookup) | Fast | Books with visible barcode |
| Manual entry | User supplied | Variable | Books without a usable barcode or catalogue result |

### Retired Photo Metadata Extraction

`CoverCaptureView` owns camera services, captured image state, crop-review sheet presentation, loading/error state, image data creation, and concrete service wiring. Screen chrome sections live in `CoverCaptureChrome`, crop-review presentation lives in `CoverCropReviewView`, pure crop math lives in `CoverCropGeometry`, OCR text-line heuristics live in `CoverOCRHeuristics`, and the deterministic photo metadata decision path lives in `CoverExtractionOrchestrator`.

`CoverExtractionOrchestrator` handles:

- Gemini success with usable title and author: normalize the Gemini result and skip OCR.
- Gemini success with a blank title or missing authors: run OCR and let `CoverMetadataNormalizer` use OCR fallback values.
- Gemini failure with an OCR title: use the OCR metadata directly.
- Gemini failure with no OCR title: return manual fallback metadata while preserving cover image data.

When changing extraction fallback behavior, characterize it in `CoverExtractionOrchestratorTests` first, then keep the simulator cover flow green through `CoverCaptureFlowTests`.

These helpers remain as legacy compatibility seams only and must not be reconnected to production
navigation. Current registration changes should keep `CoverCaptureFlowTests`,
`BookISBNScanLookupTests`, and the ISBN confirmation tests green.

---

## Offline Queue

When the device is offline, captures are queued locally and processed automatically when connectivity returns.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Offline Capture Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User captures photo                                             │
│         │                                                         │
│         │ NetworkMonitor.isConnected = false                     │
│         ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                  CaptureQueueManager                         │ │
│  │                                                               │ │
│  │  1. Save image to disk (Documents/queue_images/)             │ │
│  │  2. Create CaptureQueueItem (SwiftData)                      │ │
│  │     - status: .pending                                       │ │
│  │     - imagePath: local file path                             │ │
│  │     - thumbnailData: compressed preview                      │ │
│  │  3. Show confirmation: "Saved for later"                     │ │
│  │                                                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
│         │                                                         │
│         │ Later: NetworkMonitor.isConnected = true               │
│         ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Automatic Processing                                        │ │
│  │                                                               │ │
│  │  1. Fetch pending items (sorted by priority, then date)      │ │
│  │  2. For each item:                                           │ │
│  │     a. Mark status: .processing                              │ │
│  │     b. Load image from disk                                  │ │
│  │     c. Call GeminiService.extractQuotes()                    │ │
│  │     d. On success: save quotes, mark .completed              │ │
│  │     e. On failure: mark .failed, schedule retry              │ │
│  │  3. Clean up: delete processed image files                   │ │
│  │                                                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  Retry Schedule (exponential backoff):                           │
│  • 1st retry: 5 seconds                                          │
│  • 2nd retry: 30 seconds                                         │
│  • 3rd retry: 120 seconds                                        │
│  • Max retries: 3                                                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### CaptureQueueItem Model

```swift
@Model
final class CaptureQueueItem {
    var id: UUID
    var book: Book?
    var imagePath: String?
    var thumbnailData: Data?
    var status: QueueStatus  // pending, processing, completed, failed, cancelled
    var createdAt: Date
    var processedAt: Date?
    var priority: Int        // Higher = processed first
    var retryCount: Int
    var errorMessage: String?

    var canRetry: Bool {
        status == .failed && retryCount < 3
    }
}
```

### Queue UI

The Settings tab shows queue status:

```swift
Section("Offline Queue") {
    if stats.hasActiveItems {
        HStack {
            Text(stats.statusDescription)
            Spacer()
            if stats.isProcessing {
                ProgressView()
            }
        }

        if stats.failedCount > 0 {
            Button("Retry Failed") {
                await queueManager.retryAll()
            }
        }
    } else {
        Text("No pending captures")
            .foregroundStyle(.secondary)
    }
}
```

---

## Quality Assessment

Before sending images to the API, we check for common issues.

### Checks Performed

```swift
struct QualityAssessment {
    let overallScore: Double      // 0.0 to 1.0
    let blurScore: Double         // Laplacian variance
    let brightnessScore: Double   // Histogram analysis
    let textConfidence: Double    // Vision text detection
    let issues: [QualityIssue]

    var isAcceptable: Bool { overallScore >= 0.6 }
}

enum QualityIssue: String {
    case tooBlurry = "Hold the camera steadier"
    case tooDark = "Move to better lighting"
    case tooBright = "Reduce glare or direct light"
    case lowTextConfidence = "Make sure text is visible"
    case poorAngle = "Hold camera more directly above page"
}
```

### Live Feedback

`QualityOverlayView` shows real-time feedback:

```swift
struct QualityOverlayView: View {
    let assessment: QualityAssessment

    var body: some View {
        VStack {
            if !assessment.isAcceptable {
                ForEach(assessment.issues, id: \.self) { issue in
                    Label(issue.rawValue, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.warning)
                }
            }

            // Quality meter
            QualityMeter(score: assessment.overallScore)
        }
    }
}
```

---

## Extraction Review

After AI extraction, users review and correct results.

### ExtractionReviewView

For batch captures, provides page-by-page review:

```swift
struct ExtractionReviewView: View {
    let session: CaptureSession
    let book: Book

    @State private var currentPageIndex = 0
    @State private var approvedQuotes: [Quote] = []

    var body: some View {
        VStack {
            // Page navigation
            PageIndicator(current: currentPageIndex + 1, total: session.captures.count)

            HStack {
                // Original image
                if let image = currentCapture.loadFullImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }

                // Extracted quotes
                List {
                    ForEach(currentCapture.extractedQuotes) { quote in
                        QuoteReviewRow(
                            quote: quote,
                            onEdit: { editQuote(quote) },
                            onDelete: { deleteQuote(quote) }
                        )
                    }
                }
            }

            // Navigation
            HStack {
                Button("Previous") { currentPageIndex -= 1 }
                Spacer()
                Button("Next") { currentPageIndex += 1 }
            }
        }
    }
}
```

### Confidence Display

Quotes show AI confidence level:

```swift
struct ConfidenceIndicator: View {
    let confidence: Double

    var color: Color {
        switch confidence {
        case 0.9...: return .success
        case 0.7..<0.9: return .warning
        default: return .error
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(Int(confidence * 100))%")
                .font(.caption)
        }
    }
}
```

---

## Error Recovery

When things go wrong, the system provides recovery options.

### Error Types

| Error | Cause | Recovery |
|-------|-------|----------|
| Network failure | No connection | Queue offline, retry later |
| Rate limited | Too many requests | Wait, then retry |
| Authentication expired | Session timeout | Re-authenticate |
| Extraction failed | AI couldn't parse | Retake photo |
| Low confidence | Poor image quality | Retake or edit manually |

### Retry Strategies

```swift
// Automatic retry (queue items)
private let retryDelays: [TimeInterval] = [5, 30, 120]

func scheduleRetry(for itemId: UUID, retryCount: Int) async {
    let delay = retryDelays[min(retryCount, retryDelays.count - 1)]
    try? await Task.sleep(for: .seconds(delay))
    await processItem(itemId)
}

// Manual retry (batch processing)
Button("Retry Failed Pages") {
    await batchService.retryFailed(from: result, markings: markings)
}
```

---

## Summary

The capture system is built for resilience:

1. **Quality gates** prevent wasted API calls
2. **Offline queue** ensures no work is lost
3. **Batch mode** optimizes for high-volume capture
4. **Review flow** lets users correct AI mistakes
5. **Automatic retries** handle transient failures

See also:
- [SERVICES.md](SERVICES.md) — Service layer documentation
- [API_INTEGRATION.md](API_INTEGRATION.md) — Gemini API details
