# Architecture Guide

This document explains the architectural patterns, conventions, and organization of the BookQuotes iOS app. Understanding these patterns will help you navigate the codebase and contribute effectively.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [The Model-View Pattern](#the-model-view-pattern)
4. [State Management with @Observable](#state-management-with-observable)
5. [Dependency Injection](#dependency-injection)
6. [Navigation System](#navigation-system)
7. [Service Layer](#service-layer)
8. [Concurrency Patterns](#concurrency-patterns)
9. [Error Handling](#error-handling)

---

## Overview

BookQuotes follows a **Model-View (MV)** architecture pattern optimized for SwiftUI and SwiftData. This is a deliberate simplification of MVVM—we avoid separate ViewModel classes because SwiftUI views are already lightweight value types, and SwiftData models with `@Observable` provide reactive state management directly.

### Key Principles

1. **Views are cheap** — SwiftUI views are structs. Don't fight the framework by adding abstraction layers.
2. **Services own logic** — Business logic lives in service classes, not views.
3. **Models are reactive** — SwiftData models with `@Observable` drive UI updates automatically.
4. **Environment is your friend** — Use SwiftUI's environment for dependency injection.

---

## Project Structure

```
BookQuotes/
├── App/                      # Application lifecycle and tab structure
│   ├── BookQuotesApp.swift   # @main entry point, container setup
│   ├── ContentView.swift     # Root TabView
│   ├── Tab.swift             # Tab enum definitions
│   ├── LibraryTab.swift      # Library tab navigation stack
│   ├── CaptureTab.swift      # Capture tab navigation
│   ├── SettingsTab.swift     # Settings tab navigation
│   └── RouterPath.swift      # Programmatic navigation helper
│
├── Models/                   # SwiftData @Model classes
│   ├── Book.swift            # Book entity with quotes relationship
│   ├── Quote.swift           # Quote entity linked to Book
│   ├── Collection.swift      # Quote organization
│   ├── Tag.swift             # Quote tagging
│   ├── MarkingDefinition.swift  # User annotation vocabulary
│   ├── CaptureSession.swift  # Batch capture session
│   ├── PageCapture.swift     # Individual captured page
│   └── CaptureQueueItem.swift # Offline queue item
│
├── Services/                 # Business logic and external integrations
│   ├── GeminiService.swift   # AI extraction via proxy
│   ├── SearchService.swift   # FTS5 search orchestration
│   ├── SearchDatabase.swift  # SQLite FTS5 implementation
│   ├── SQLiteStatement.swift # SQLite statement lifecycle adapter
│   ├── SearchFTSQueryBuilder.swift # FTS query normalization
│   ├── CameraService.swift   # AVFoundation camera
│   ├── CaptureQueueManager.swift  # Offline queue processing
│   ├── BatchProcessingService.swift # Parallel page extraction
│   └── ...                   # Other services
│
├── Features/                 # Feature modules (screens + supporting views)
│   ├── Library/              # Book/quote browsing
│   ├── Capture/              # Camera and capture flows
│   ├── BookRegistration/     # Cover capture, ISBN, editing
│   ├── QuoteCapture/         # Quote extraction and review
│   ├── Collections/          # Collection management
│   ├── Tags/                 # Tag management
│   ├── Export/               # Export functionality
│   ├── Onboarding/           # First-run experience
│   ├── Auth/                 # Sign-in flows
│   └── Subscription/         # Premium features
│
├── Components/               # Reusable UI components
│   ├── DesignSystem.swift    # Colors, typography, spacing tokens
│   ├── QuoteCardView.swift   # Quote display card
│   ├── BookCoverCard.swift   # Book cover thumbnail
│   ├── ErrorView.swift       # Error display states
│   ├── LoadingView.swift     # Loading indicators
│   └── ...                   # Other shared components
│
├── Utilities/                # Helpers and extensions
│   ├── HapticManager.swift   # Tactile feedback
│   ├── ImagePreprocessor.swift # Image preparation
│   ├── AccessibilityIdentifiers.swift # UI test identifiers
│   └── ...                   # Other utilities
│
└── Resources/                # Assets, localization
    └── Assets.xcassets/      # Images, colors
```

### Where to Add New Code

| You want to add... | Put it in... |
|-------------------|--------------|
| New data type to persist | `Models/` as a `@Model` class |
| Business logic / API calls | `Services/` as an `actor` or `@Observable` class |
| New screen in existing feature | `Features/<FeatureName>/` |
| Library overview cards, empty state, or reusable Library rows | `Features/Library/LibraryOverviewViews.swift` |
| Library top-level search/empty/library content mode selection | `Features/Library/LibraryContentMode.swift` |
| Library grid/list stored values, icons, and summary labels | `Features/Library/LibraryViewMode.swift` |
| Library search result orchestration | `Features/Library/SearchResultsView.swift` |
| Library search result section visibility, animation delay, and did-you-mean eligibility policy | `Features/Library/SearchResultsPresentation.swift` |
| Library search empty/error/no-results presentation | `Features/Library/SearchResultsStateViews.swift` |
| Library search result rows | `Features/Library/BookSearchResultRow.swift` and `Features/Library/QuoteSearchResultRow.swift` |
| Library book card/list row entry points | `Features/Library/BookCoverCard.swift` |
| Library book cover artwork, status badges, quote badge, and card context menu support | `Features/Library/BookCoverCardSupport.swift` |
| Library Books section, grid/list rendering, and view-mode segmented control | `Features/Library/LibraryBooksSectionViews.swift` |
| Library search service setup and suggestion-history side effects | `Features/Library/LibrarySearchServices.swift` |
| Library search-result navigation lookup | `Features/Library/LibraryNavigationLookup.swift` |
| Book detail quote filtering, sorting, unique page count, and available marking filters | `Features/Library/BookDetailQuotePresentation.swift` |
| Quote detail copy/share text | `Features/Library/QuoteDetailTextFormatter.swift` |
| Quote detail edit-save field mutation | `Features/Library/QuoteDetailEditDraft.swift` |
| Quote detail edit-load field mapping | `Features/Library/QuoteDetailEditFields.swift` |
| Quote detail deletion prompt copy | `Features/Library/QuoteDeletionPrompt.swift` |
| Shared Library and Book Detail deletion prompt copy | `Features/Library/BookDeletionPrompt.swift` |
| Quote/tag relationship add-remove mutation | `Features/Tags/QuoteTagMutation.swift` |
| Tag browsing total-use and search filtering calculations | `Features/Tags/TagsPresentation.swift` |
| Tag editor name/color normalization and save-field mapping | `Features/Tags/TagEditorDraft.swift` |
| Tag editor mode title/action copy and editor sheet UI | `Features/Tags/TagEditorModePresentation.swift` and `Features/Tags/TagEditorSheet.swift` |
| Add-to-quote available-tag filtering | `Features/Tags/AddTagToQuotePresentation.swift` |
| Tag deletion prompt copy and pluralization | `Features/Tags/TagDeletionPrompt.swift` |
| Tag row display values and row menu/chip presentation | `Features/Tags/TagRowPresentation.swift` and `Features/Tags/TagRowViews.swift` |
| Collection detail coordination, sheet state, filtering, sorting, and SwiftData mutations | `Features/Collections/CollectionDetailView.swift` |
| Collection detail header/list/toolbar/empty-state and add-quotes sheet presentation | `Features/Collections/CollectionDetailSupport.swift` |
| Search database SQL schema and query text | `Services/SearchDatabaseSQL.swift` |
| SQLite FTS query construction | `Services/SearchFTSQueryBuilder.swift` |
| SQLite statement lifecycle/binding helpers | `Services/SQLiteStatement.swift` |
| Capture-tab flow transition logic | `Features/Capture/CaptureFlowState.swift` |
| Capture-tab mode metadata and accessibility contracts | `Features/Capture/CaptureModeOption.swift` |
| Capture-tab landing UI | `Features/Capture/CaptureModeSelectionView.swift` |
| Capture-tab existing-book picker | `Features/Capture/BookSelectionForCaptureView.swift` |
| Capture-tab quote, batch, and cover flow wrappers | `Features/Capture/CaptureFlowViews.swift` |
| Quote-capture image preparation and quality analysis | `Features/Capture/QuoteCaptureImageProcessor.swift` |
| Quote-capture confirmed-image session/page persistence | `Features/Capture/QuoteCaptureSessionStore.swift` |
| Capture control flash mode cycle and SF Symbol contract | `Components/CaptureFlashMode.swift` |
| Extraction-review pending capture processing transaction | `Features/QuoteCapture/ExtractionReviewProcessor.swift` |
| Camera session lifecycle, authorization state mutation, preview, capture, switching, focus, and cleanup | `Services/CameraService.swift` |
| Camera authorization decision and permission-status policy | `Services/CameraAuthorizationPolicy.swift` |
| Camera errors and upload image compression | `Services/CameraServiceSupport.swift` |
| Camera preview-size validation and cropping fallback | `Services/CameraPreviewSizeStore.swift` |
| Extraction-review editable quote state and page counts | `Features/QuoteCapture/ExtractionReviewQuoteState.swift` |
| Extracted quote to validated `Quote` mapping | `Services/QuoteSaveDraft.swift` |
| Quote-save input, batch result, failure, and error value contracts | `Services/QuoteSaveTypes.swift` |
| Extraction-review manual quote sheet or summary UI | `Features/QuoteCapture/ExtractionReviewSupplementaryViews.swift` |
| Extraction-review processing/no-quotes/failure/selection states | `Features/QuoteCapture/ExtractionReviewStatusViews.swift` |
| Page quote editor selected-page layout and quote section | `Features/QuoteCapture/PageQuoteEditor.swift` |
| Page quote editor quote-list title and deletion behavior | `Features/QuoteCapture/PageQuoteEditorList.swift` |
| Page quote editor full-image viewer and thumbnail navigation | `Features/QuoteCapture/PageQuoteEditorSupportViews.swift` |
| Cover metadata extraction fallback logic | `Features/BookRegistration/CoverExtractionOrchestrator.swift` |
| Cover crop sizing, zoom, offset, or crop-rect logic | `Features/BookRegistration/CoverCropGeometry.swift` |
| Cover capture screen chrome sections | `Features/BookRegistration/CoverCaptureChrome.swift` |
| Cover capture metadata extraction, OCR fallback, orientation normalization, and ISBN lookup support | `Features/BookRegistration/CoverCaptureMetadataSupport.swift` |
| Cover OCR title/author text heuristics | `Features/BookRegistration/CoverOCRHeuristics.swift` |
| Book edit form UI sections | `Features/BookRegistration/BookEditSections.swift` |
| ISBN confirmation edited metadata to `Book` mapping | `Features/BookRegistration/BookISBNConfirmationDraft.swift` |
| ISBN confirmation title/author field validity | `Features/BookRegistration/BookISBNConfirmationValidation.swift` |
| ISBN scan-result metadata lookup | `Features/BookRegistration/BookISBNScanLookup.swift` |
| ISBN scan-result loading/error/found presentation | `Features/BookRegistration/BookISBNScanResultView.swift` |
| Onboarding flow step coordination | `Features/Onboarding/OnboardingView.swift` |
| Onboarding deterministic route policy | `Features/Onboarding/OnboardingFlowPolicy.swift` |
| Onboarding step state type, mutable session state, fixed step advances, signed-in user capture, and completion progress | `Features/Onboarding/OnboardingSessionState.swift` |
| Onboarding auth skip policy | `Features/Onboarding/OnboardingAuthSkipPolicy.swift` |
| Onboarding sign-in description copy for subscription/cloud/local release configurations | `Features/Onboarding/OnboardingSignInCopyPolicy.swift` |
| Onboarding completion flags | `Features/Onboarding/OnboardingCompletionStore.swift` |
| Onboarding completion state and persistence sequence | `Features/Onboarding/OnboardingCompletionAction.swift` |
| Onboarding step screen presentation | `Features/Onboarding/OnboardingStepViews.swift` |
| Onboarding welcome carousel state, skip visibility, button title, and next/complete action | `Features/Onboarding/OnboardingWelcomeCarouselState.swift` |
| Onboarding welcome carousel content | `Features/Onboarding/OnboardingWelcomeViews.swift` |
| Onboarding marking setup controls | `Features/Onboarding/OnboardingMarkingViews.swift` |
| Onboarding marking setup selected-style state and toggling | `Features/Onboarding/OnboardingMarkingSelectionState.swift` |
| Onboarding embedded paywall product loading, selection, purchase action, errors, and continuation | `Features/Onboarding/OnboardingPaywallViews.swift` |
| Onboarding fallback media subscription plan copy and option-card presentation | `Features/Onboarding/OnboardingMediaSubscriptionPlan.swift` |
| StoreKit app account token generation | `Services/SubscriptionAccountToken.swift` |
| Backend subscription sync response mapping | `Services/SubscriptionSyncState.swift` |
| StoreKit subscription product identifiers and display labels | `Services/SubscriptionProductID.swift` |
| Capture queue lifecycle, network observation, processing orchestration, retry trigger scheduling, and public command coordination | `Services/CaptureQueueManager.swift` |
| Capture queue current-value stats publication | `Services/CaptureQueueStatsReporter.swift` |
| Capture queue connectivity seam and live network monitor adapter conformance | `Services/CaptureQueueNetworkMonitoring.swift` |
| Capture queue restored-connection transition decision | `Services/CaptureQueueNetworkTransition.swift` |
| Capture queue network observation loop and polling adapter | `Services/CaptureQueueNetworkObserver.swift` |
| Capture queue image storage, SwiftData mutations, stats reads, and next-pending-item lookup | `Services/CaptureQueueStore.swift` |
| Capture queue item extraction transaction and processing outcome retry request | `Services/CaptureQueueProcessing.swift` |
| Capture queue manager storage and item-processing dependency seams | `Services/CaptureQueueDependencies.swift` |
| Capture queue auto-processing preference lookup | `Services/CaptureQueueProcessingPreferences.swift` |
| Capture queue retry task storage, replacement, and cancellation | `Services/CaptureQueueRetryScheduler.swift` |
| Capture queue delayed retry task orchestration and controlled sleep injection | `Services/CaptureQueueRetryCoordinator.swift` |
| Capture queue retry policy, processing start policy, fetch-descriptor, and stats helper logic | `Services/CaptureQueueSupport.swift` |
| Capture queue stats and errors | `Services/CaptureQueueTypes.swift` |
| Capture queue shared instance setup | `Services/CaptureQueueShared.swift` |
| Entirely new feature | Create `Features/<NewFeature>/` folder |
| Shared UI component | `Components/` |
| Helper function or extension | `Utilities/` |

---

### Book Registration Seams

`Features/BookRegistration/` keeps `BookEditView.Mode` as the caller-facing interface for create, edit, and metadata-confirmation flows. Internally, form loading goes through:

- `BookEditSource`: create, edit existing book, or metadata source.
- `BookEditDraft`: value object for title, author, optional metadata strings, status, and cover image data.
- `BookEditOptions`: genre option list and display labels.
- `BookEditSaveDraft`: value object for form-to-`Book` create/update mapping.
- `BookEditCoverImageData`: compressed thumbnail/full cover image data passed into save mapping.
- `BookISBNConfirmationDraft`: adapter from edited ISBN confirmation fields plus lookup metadata into the shared `BookEditSaveDraft` save path.
- `BookISBNConfirmationValidation`: pure title/author validity rules for ISBN confirmation.
- `BookISBNScanLookup`: injectable async ISBN scan-result metadata lookup and success/failure result mapping.
- `BookISBNScanResultView`: SwiftUI-only loading, found metadata, retry, cancel, and error presentation for `BookISBNConfirmationSheet.FromScanResult`.
- `BookEditSections`: SwiftUI-only form sections for cover, details, metadata, reading status, and notes.
- `CoverCaptureChrome`: ISBN scanner header, barcode overlay, processing overlay, and manual-entry controls.
- `CoverCaptureMetadataSupport`: ISBN catalogue lookup helper used by the live registration flow.
- `CoverCropGeometry`: pure crop viewport, scale, offset clamp, and image crop-rect calculations.
- `CoverCropReviewView`: crop-review sheet UI for move/zoom/use/retake.
- `CoverOCRHeuristics`: pure Vision text-line sanitizing and title/author guessing.

This keeps source-to-form mapping, save mapping, form section composition, and ISBN lookup testable without exposing SwiftUI state, `ModelContext`, haptics, dismissal, API calls, or camera services.

`CoverCaptureView` should keep camera setup, ISBN scanner lifecycle, loading/error state, and edit-sheet presentation while delegating catalogue lookup to `CoverCaptureMetadataSupport`. Cover screen chrome changes should keep `CoverCaptureFlowTests` green because their observable behavior is user navigation and controls, not the internal SwiftUI section layout. Retired cover-photo extraction helpers remain only for compatibility tests and must not be reconnected to production navigation.

New book edit UI should be added to the relevant section in `BookEditSections.swift` unless it owns mode, persistence, photo loading, validation, save/update, dismissal, or milestone behavior. Those orchestration concerns remain in `BookEditView.swift`. New ISBN confirmation save behavior should be characterized in `BookISBNConfirmationDraftTests` and reuse `BookEditSaveDraft` where possible. New ISBN confirmation field-validation behavior should be characterized in `BookISBNConfirmationValidationTests` before changing `BookISBNConfirmationValidation` or `BookISBNConfirmationSheet.validateAndSave()`. New ISBN scan-result metadata lookup behavior should be characterized in `BookISBNScanLookupTests`; scan-result loading/error presentation belongs in `BookISBNScanResultView`. Simulator coverage for this area should include manual create, validation, cancel, cover section visibility, ISBN scan result loading/error, and create-then-edit persisted title behavior.

### Capture Feature Seams

`Features/Capture/` keeps `CaptureTabRootView` as the SwiftUI shell for permission gating, coaching presentation, haptics, selected `Book` storage, and branch rendering. Deterministic flow decisions go through:

- `CaptureFlowState`: value type for current capture mode, quote/batch flow identity refreshes, and commands that tell the view when to clear selected-book state.
- `CaptureModeOption`: value type for capture mode ordering, display metadata, colour, icon, and accessibility identifiers.
- `CaptureModeSelectionView`: landing UI for choosing cover, quote, or batch capture.
- `BookSelectionForCaptureView`: existing-book picker used before quote or batch capture, including the empty-library path into cover capture.
- `CaptureFlowViews`: wrappers for quote, batch, cover, and missing-book fallback branches.
- `QuoteCaptureImageProcessor`: captured-image crop-policy application, document preparation, quality-analysis ordering, and non-fatal quality-analysis failure handling.
- `QuoteCaptureSessionStore`: confirmed quote image processing, capture-file storage, thumbnail creation, session/page insertion, ready-to-process transition, and UI-test seeded extraction state.
- `CaptureFlashMode`: deterministic flash control cycle and SF Symbol metadata used by `CaptureControlsBar`.

New capture-tab navigation behavior should be added to `CaptureFlowState` first with characterization tests. `CaptureTabRootView` should then delegate to the flow state and keep only UI orchestration that depends on SwiftUI, callbacks, or concrete `Book` objects.

`QuoteCaptureView` should keep camera setup, preview state, capture actions, quality-analysis UI state, review presentation, extraction-review presentation, callbacks, haptics, and user-visible errors. Captured-image preparation and quality-analysis sequencing belongs in `QuoteCaptureImageProcessor` and should be characterized with `QuoteCaptureImageProcessorTests`. Confirmed-image persistence belongs in `QuoteCaptureSessionStore` and should be characterized with `QuoteCaptureSessionStoreTests`.

New capture-control flash metadata should be characterized in `CaptureFlashModeTests` before changing `CaptureControlsBar`. Hardware flash behaviour should not be added to `CaptureFlashMode`; add a camera-service adapter seam first if the app starts controlling actual torch/flash state.

### Quote Capture Seams

`Features/QuoteCapture/` keeps `ExtractionReviewView` as the orchestration shell for selected-page state, quote-state loading, saving quotes, milestone side effects, alerts, haptics, and dismissal. Review processing and deterministic review state go through:

- `ExtractionReviewProcessor`: pending capture processing transaction, including enabled marking prompt fetch, image decode, extractor calls, capture/session success or failure mutation, model saves, and refresh callback.
- `ExtractionReviewQuoteState`: value type for editable quote loading, quote counts by page, page-specific replacement, and partial-save failure filtering.
- `QuoteSaveDraft`: value type for deterministic `ExtractedQuote` to validated `Quote` mapping before persistence.
- `QuoteSaveTypes`: `ExtractedQuote`, batch save result summaries, save failure error-message mapping, and quote-save user-facing errors.
- `ExtractionReviewSupplementaryViews`: manual quote sheet, review summary, and previews.
- `PageQuoteEditor`: selected-page editor shell, page image section, quote section, empty state, and add/delete callback wiring.
- `PageQuoteEditorList`: quote count title and delete-by-identity behavior.
- `PageQuoteEditorSupportViews`: full-screen image viewer, page thumbnail list, and thumbnail cell presentation.
- `BatchCapturePageStore`: captured-page crop/preprocess/thumbnail/disk/SwiftData persistence.
- `BatchCaptureLifecycleState`: value type for batch capture in-progress state, finish/cancel decisions, status text, and offline queue confirmation decisions.
- `BatchCaptureSupplementaryViews`: thumbnail strip item, capture detail sheet, offline queue confirmation sheet, deprecated offline toast, and previews.

New extraction-review processing behavior should be characterized in `ExtractionReviewProcessorTests` before touching `ExtractionReviewProcessor` or its caller. New extraction-review quote mapping or page-replacement behavior should be characterized in `ExtractionReviewQuoteStateTests` before touching `ExtractionReviewView`. New page quote editor list behavior should be characterized in `PageQuoteEditorListTests` before changing delete/count behavior. Simulator coverage for the review screen is currently tracked by `docs/issues/006-extraction-review-simulator-route-repair.md`.

Extraction review status presentation belongs in `ExtractionReviewStatusViews`. Page image viewer and thumbnail navigation presentation belong in `PageQuoteEditorSupportViews`. Selected-page state, quote loading, save confirmation, milestone celebration, haptics, and dismissal orchestration remain in `ExtractionReviewView` unless a deeper seam is characterized first. `QuoteSaveService` owns quote persistence, duplicate checks, book timestamp mutation, context saves, and haptics; deterministic quote construction belongs in `QuoteSaveDraft`, and quote-save input/result/error value contracts belong in `QuoteSaveTypes`.

New batch capture lifecycle decisions should be characterized in `BatchCaptureLifecycleStateTests` before touching `BatchCaptureView`. New captured-page persistence behavior should be characterized in `BatchCapturePageStoreTests` before touching `BatchCapturePageStore`. `BatchCaptureView` should keep concrete camera setup, capture execution, haptics, milestones, and callbacks. Thumbnail/detail/offline confirmation presentation belongs in `BatchCaptureSupplementaryViews` unless it starts owning capture or persistence decisions.

### Library Feature Seams

`App/LibraryTab.swift` keeps the tab-level shell and `LibraryView` orchestration for SwiftData book queries, search service setup, suggestions, navigation, add/edit sheets, delete confirmation, and refresh. Reusable Library presentation lives in `Features/Library/`.

- `LibraryOverviewViews`: Library summary card, section card, empty state, control/action/info rows, and shared overview visual helpers.
- `LibraryViewMode`: grid/list stored values, SF Symbol names, and summary labels.
- `LibrarySearchServices`: paired search/suggestions setup, suggestion loading/clearing, accepted/submitted search history, and refresh reindex trigger.
- `LibraryNavigationLookup`: SwiftData lookup for search-result book and quote identifiers before navigation.
- `SearchResultsView`: FTS-backed search orchestration, search task state, and result navigation callbacks.
- `SearchResultsStateViews`: search empty state, no-results state, and error state presentation.
- `LibraryBooksSectionViews`: Books section composition, grid/list rendering, and view-mode segmented control.
- `BookDetailQuotePresentation`: Book Detail quote filtering, sort order contract, unique page count, and available marking filters.
- `QuoteDetailTextFormatter`: Quote Detail copy/share text contract.
- `QuoteDetailEditDraft`: Quote Detail edit-save field mutation for text, margin note, page number, and modified date.
- `QuoteDetailEditFields`: Quote Detail edit-load mapping from live quote values into editable strings.
- `QuoteDeletionPrompt`: Quote Detail destructive deletion title, action title, and message copy.
- `BookDeletionPrompt`: shared destructive book-deletion title, action title, and quote-count message copy.
- `BookCoverCard`: caller-facing grid card and list row presentation for books.
- `BookCoverCardSupport`: shared cover artwork, quote count badge, reading-status badge, and card/list context menu items.
- `BookDetailView` / `QuoteDetailView`: detail screens reached from Library and Search.

New Library overview UI should be added to `LibraryOverviewViews` unless it owns search lifecycle, navigation, persistence, or sheet presentation. Library grid/list storage, labels, and icons should be characterized in `LibraryViewModeTests` before changing `LibraryViewMode` or view-mode controls. Search service setup and suggestion-history side effects belong in `LibrarySearchServices`. New Book Detail quote filtering/sorting/count behavior should be characterized in `BookDetailQuotePresentationTests` before changing `BookDetailQuotePresentation` or `BookDetailView`. New Quote Detail copy/share text behavior should be characterized in `QuoteDetailTextFormatterTests` before changing `QuoteDetailTextFormatter` or `QuoteDetailView`. New Quote Detail edit-load field behavior should be characterized in `QuoteDetailEditFieldsTests`; new edit-save field behavior should be characterized in `QuoteDetailEditDraftTests` before changing `QuoteDetailView`. New Quote Detail deletion prompt copy should be characterized in `QuoteDeletionPromptTests`; actual quote delete persistence, haptics, dismissal, and dialog state remain in `QuoteDetailView`. New search state presentation should go in `SearchResultsStateViews`; result-cell presentation should stay in the row modules. New search behaviour should be characterized through `SearchFlowTests` or a focused search seam before changing `LibrarySearchServices`, `SearchResultsView`, `SearchDatabase`, or `SearchFTSQueryBuilder`.

New shared book-deletion copy should be characterized in `BookDeletionPromptTests`. Actual delete persistence, haptics, routing, dismissal, and dialog state remain in the owning SwiftUI view until a broader deletion-action seam is characterized.

### Collections Feature Seams

`Features/Collections/CollectionDetailView.swift` keeps collection-detail coordination: sheet state, search text, quote filtering/sorting, delete confirmation, and SwiftData mutations for remove, favorite, and delete actions.

- `CollectionDetailSupport`: collection quote sort metadata, detail header/list/empty/toolbar presentation, add-quotes sheet presentation, quote-selection row, and book-filter chips.
- `CollectionsView`: top-level collections listing and navigation.
- `AddToCollectionSheet`: quote-detail driven add-to-collection flow.

New collection detail UI should land in `CollectionDetailSupport` unless it owns persistence, navigation state, or sheet presentation state. Behaviour changes should first repair or replace the currently failing collection detail UI smoke, then characterize add/remove/favorite/delete and add-quotes flows.

### Tags Feature Seams

`Features/Tags/TagsView.swift` keeps tag list presentation, search text, tag create/edit sheet state, delete confirmation, model-context saves, and the quote tag-management sheet.

- `QuoteTagMutation`: deterministic `Quote` / `Tag` relationship mutation for add/remove operations and quote modified-date updates.
- `TagsPresentation`: deterministic tag browsing total-use and search filtering calculations.
- `TagEditorDraft`: deterministic tag editor name normalization, save eligibility, new-tag creation, and existing-tag field mutation.
- `TagEditorModePresentation`: deterministic create/edit title and confirmation action copy.
- `TagEditorSheet`: create/edit tag form presentation plus SwiftData insertion/update.
- `AddTagToQuotePresentation`: deterministic filtering of tags not already attached to a quote.
- `TagDeletionPrompt`: deterministic tag deletion dialog copy and quote-count pluralization.
- `TagRowPresentation`: deterministic tag row display name, quote-count text, and color fallback.
- `TagRowViews`: tag row menu/chip presentation with edit/delete callbacks.
- `AddTagToQuoteSheet`: current/available tag section presentation, create-tag sheet routing, save calls, and dismissal.

New quote-tag relationship behaviour should be characterized in `QuoteTagMutationTests` before changing `QuoteTagMutation` or `AddTagToQuoteSheet`. New tag browsing calculation behaviour should be characterized in `TagsPresentationTests` before changing `TagsPresentation` or `TagsView`. New tag editor mode title/action copy should be characterized in `TagEditorModePresentationTests`; new tag editor save-field behaviour should be characterized in `TagEditorDraftTests` before changing `TagEditorDraft` or `TagEditorSheet.save()`. New add-to-quote availability behaviour should be characterized in `AddTagToQuotePresentationTests` before changing `AddTagToQuotePresentation` or `AddTagToQuoteSheet.availableTags`. New tag deletion prompt copy should be characterized in `TagDeletionPromptTests` before changing `TagDeletionPrompt` or the `TagsView` confirmation dialog. New tag row display behavior should be characterized in `TagRowPresentationTests` before changing `TagRowPresentation` or `TagRowViews`.

### Onboarding Feature Seams

`Features/Onboarding/OnboardingView.swift` keeps step coordination, auth/subscription service injection, legal sheet presentation, completion side effects, and the top-level background.

- `OnboardingFlowPolicy`: deterministic initial-step and post-sign-in routing decisions.
- `OnboardingAuthSkipPolicy`: simulator/UI-test auth skip decisions.
- `OnboardingSignInCopyPolicy`: deterministic sign-in description copy for subscription, cloud-sync, and local-library release configurations.
- `OnboardingCompletionStore`: first-run completion and first-capture coaching flag persistence.
- `OnboardingCompletionAction`: deterministic completion sequence that marks session completion progress and persists onboarding/coaching flags.
- `OnboardingSessionState`: onboarding step state type, mutable step, fixed welcome/subscription/marking step advances, signed-in user, and completion progress state.
- `OnboardingStepViews`: sign-in, subscription, marking setup, completion, and welcome carousel screen composition with callback-based actions.
- `OnboardingWelcomeCarouselState`: deterministic welcome-carousel page state, skip visibility, primary button title, and next/complete action.
- `OnboardingWelcomeViews`: welcome page metadata and carousel page presentation.
- `OnboardingMarkingViews`: marking template selector and marking option controls.
- `OnboardingMarkingSelectionState`: default selected marking styles and toggle behavior for the marking setup selector.
- `OnboardingPaywallViews`: embedded paywall presentation, StoreKit product loading, product selection, purchase action, and paywall error presentation.
- `OnboardingMediaSubscriptionPlan`: fallback media subscription plan copy, display order, selected-card presentation, and media plan pricing display.

New onboarding presentation should land in the matching view module. Initial and post-sign-in route decisions should be characterized in `OnboardingFlowPolicyTests`; fixed step advance behavior should be characterized in `OnboardingSessionStateTests` before changing `OnboardingView`. Welcome carousel page-state behavior should be characterized in `OnboardingWelcomeCarouselStateTests`. Sign-in release-configuration copy should be characterized in `OnboardingSignInCopyPolicyTests`. Marking setup default selection and toggle behavior should be characterized in `OnboardingMarkingSelectionStateTests`. Completion persistence should be characterized in `OnboardingCompletionStoreTests`; completion state plus persistence sequencing should be characterized in `OnboardingCompletionActionTests`. Fallback media subscription copy and order should be characterized in `OnboardingMediaSubscriptionPlanTests` before changing the App Store/TestFlight media plan route. Full screen sequence behavior should still be checked through `OnboardingFlowTests` when the simulator runner is healthy. Avoid adding new onboarding root helpers unless they concentrate behavior that cannot live in the existing route, session, completion, paywall, or step-view seams.

### Subscription Seams

`Services/SubscriptionService.swift` keeps StoreKit product loading, purchase/restore orchestration, entitlement refresh, backend sync, system subscription management, and purchase-option composition.

- `SubscriptionAccountToken`: deterministic StoreKit app account token generation from a signed-in user ID.
- `SubscriptionSyncState`: backend sync response decoding into app subscription status, expiry, and product id.
- `SubscriptionProductID`: monthly/yearly StoreKit product IDs, raw-value loading order, and display labels.
- `OnboardingMediaSubscriptionPlan`: fallback product-facing media plan copy used when StoreKit products are unavailable in the App Store/TestFlight media subscription route.

New app-account-token behavior should be characterized in `SubscriptionAccountTokenTests` before changing the hash namespace, UUID version bits, or variant bits. Backend sync mapping changes should be characterized in `SubscriptionSyncStateTests` before changing status fallback, expiry parsing, or product id retention. Product ID changes should be characterized in `SubscriptionProductIDTests` before changing StoreKit identifiers, loading order, or labels. Further `SubscriptionService` extraction should be driven by characterized behavior seams such as entitlement selection or subscription error descriptions.

### Capture Queue Seams

`Services/CaptureQueueManager.swift` keeps the actor-owned queue lifecycle: network observation, processing orchestration, retry task scheduling, and public queue commands.

- `CaptureQueueTypes`: queue stats and queue error descriptions.
- `CaptureQueueStatsReporter`: current-value queue stats publication for app/UI subscribers.
- `CaptureQueueShared`: app-wide shared queue manager initialization.
- `CaptureQueueStore`: image storage, SwiftData queue mutations, cleanup, stats reads, and next-pending-item lookup.
- `CaptureQueueProcessing`: queued item extraction transaction, including image load, enabled marking prompt fetch, model extraction, quote insertion, completion mutation, failure mutation, processing outcome reporting, and retry request derivation.
- `CaptureQueueDependencies`: manager-facing storage and item-processing interfaces used for actor orchestration tests; `CaptureQueueStore` and `CaptureQueueItemProcessor` are the live adapters.
- `CaptureQueueProcessingPreferences`: persisted auto-processing setting lookup and defaulting behavior for `autoProcessQueue`.
- `CaptureQueueRetryCoordinator`: delayed retry task creation, controlled sleep injection for tests, retry task replacement, single-item retry cancellation, and cancel-all behavior.
- `CaptureQueueNetworkMonitoring`: narrow connectivity seam used by the queue manager; `NetworkMonitor` is the live adapter.
- `CaptureQueueNetworkTransition`: pure restored-connection decision for whether queue processing should start.
- `CaptureQueueNetworkObserver`: async restored-connection observation loop plus the live one-second polling adapter. Tests should use a scripted poller rather than sleeping.
- `CaptureQueueSupport`: standard retry policy, retry-delay selection, processing start policy for automatic/manual queue triggers, queue item fetch descriptor helpers, pending-item fetch limit, and stats aggregation from queue items.

Further queue storage changes should be characterized in `CaptureQueueStoreTests`. Queue item state and descriptor behavior belongs in `CaptureQueueItemTests`; queue stats, queue errors, retry policy, and start-trigger policy belong in `CaptureQueueSupportTests`. Queue processing outcome retry request behavior belongs in `CaptureQueueProcessingTests`. Queue manager orchestration behaviour should use fake `CaptureQueueStoring` and `CaptureQueueItemProcessing` adapters in `CaptureQueueManagerTests`; retry orchestration tests can inject a short `CaptureQueueRetryPolicy` while app code keeps `.standard`. Public queue command behaviour, such as remove/retry/cancel side effects, should be characterized through `CaptureQueueManagerTests` before changing the manager command path. Delayed retry task creation, sleep control, replacement, and cancellation belong in `CaptureQueueRetryCoordinatorTests`. Queue start trigger changes should be characterized in `CaptureQueueSupportTests` before changing `CaptureQueueManager`. Further queue processing transaction changes should stay in `CaptureQueueProcessing` and be characterized before changing the live model extraction path. Further network restoration changes should use the `CaptureQueueNetworkMonitoring`, `CaptureQueueNetworkTransition`, and `CaptureQueueNetworkObserver` seams before changing timing or scheduling behavior.

`CaptureQueueManagerTestDoubles.swift` owns reusable fake network, storage, processor, and wait helpers for manager-level queue orchestration tests.

### Testing Notes and Refactor Inputs

Live testing notes are part of the refactor foundation. Before changing a feature module, check `docs/issues/` for open notes in that area and fold them into characterization.

Each note should map to a module seam:

- Quote extraction notes usually map to `QuoteExtractionPromptBuilder`, `GeminiService`, `ExtractionReviewView`, and the simulator route tracked by issue 006.
- Cover metadata notes usually map to `CoverExtractionOrchestrator`, `CoverMetadataNormalizer`, and `CoverOCRHeuristics`.
- Cover camera/crop notes usually map to `CoverCaptureView`, `CoverCropReviewView`, and `CoverCropGeometry`.
- Capture navigation notes usually map to `CaptureFlowState` and `CaptureFlowViews`.
- Batch capture notes usually map to `BatchCaptureLifecycleState`, `BatchCapturePageStore`, `BatchCaptureView`, and `BatchCaptureSupplementaryViews`.

The refactor order should prioritize notes that reveal both user-visible bugs and missing characterization seams. If the note cannot be reproduced locally, keep it open with the missing evidence required to close the loop.

---

## The Model-View Pattern

We use a simplified architecture that leverages SwiftUI and SwiftData's built-in capabilities:

```
┌─────────────────────────────────────────────────────────────┐
│                          View                               │
│  - Renders UI from model state                              │
│  - Calls service methods for actions                        │
│  - Reads from @Environment for dependencies                 │
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │ observes                           │ calls
         ▼                                    ▼
┌─────────────────────┐            ┌─────────────────────────┐
│   @Model (SwiftData)│            │   Service (@Observable) │
│  - Persisted state  │            │  - Business logic       │
│  - Relationships    │            │  - API calls            │
│  - Computed props   │            │  - State management     │
└─────────────────────┘            └─────────────────────────┘
```

### Example: Book Detail Screen

```swift
struct BookDetailView: View {
    // The model we're displaying
    let book: Book

    // Environment for persistence
    @Environment(\.modelContext) private var modelContext

    // Environment for navigation
    @Environment(RouterPath.self) private var router

    // Local UI state (not persisted)
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            // Display book properties directly
            Text(book.title)
            Text("by \(book.author)")

            // Display related quotes
            ForEach(book.quotes) { quote in
                NavigationLink(value: quote) {
                    QuoteCardView(quote: quote)
                }
            }
        }
    }

    private func deleteBook() {
        modelContext.delete(book)
        try? modelContext.save()
        router.pop() // Navigate back
    }
}
```

### Why Not MVVM?

Traditional MVVM adds a ViewModel layer between View and Model. In SwiftUI with SwiftData, this often creates unnecessary complexity:

1. **SwiftUI views are value types** — They're rebuilt frequently and cheaply. No need to separate "view logic."
2. **SwiftData models are @Observable** — They automatically notify views of changes.
3. **Services handle business logic** — Complex operations belong in services, not ViewModels.

We do use `@Observable` service classes when we need stateful business logic (like `SearchService`), but these aren't ViewModels—they're shared services injected via environment.

---

## State Management with @Observable

SwiftData models and service classes use the `@Observable` macro for reactive updates.

### Model State (Persisted)

```swift
@Model
final class Book {
    var title: String
    var author: String
    var status: ReadingStatus

    // Relationships
    @Relationship(deleteRule: .cascade)
    var quotes: [Quote] = []

    // Computed properties work too
    var quoteCount: Int { quotes.count }
}
```

When any property changes, views observing that model automatically update.

### Service State (In-Memory)

```swift
@MainActor
@Observable
final class SearchService {
    private(set) var results: SearchResults = .empty
    private(set) var isSearching = false
    private(set) var lastError: SearchError?

    func search(_ query: String, scope: SearchScope) {
        isSearching = true
        // ... perform search
        results = searchResults
        isSearching = false
    }
}
```

Views can observe service properties directly:

```swift
struct SearchResultsView: View {
    let searchService: SearchService

    var body: some View {
        if searchService.isSearching {
            ProgressView("Searching...")
        } else {
            ForEach(searchService.results.quotes) { ... }
        }
    }
}
```

### Local View State

Use `@State` for UI-only state that doesn't need persistence:

```swift
@State private var isExpanded = false
@State private var selectedTab = 0
@State private var showSheet = false
```

---

## Dependency Injection

We use SwiftUI's environment system for dependency injection.

### App-Level Services

Services are created at app launch and injected into the view hierarchy:

```swift
// BookQuotesApp.swift
@main
struct BookQuotesApp: App {
    @State private var authService = AuthService()
    @State private var geminiService: GeminiService
    @State private var networkMonitor = NetworkMonitor.shared

    init() {
        let auth = AuthService()
        _authService = State(initialValue: auth)
        _geminiService = State(initialValue: GeminiService(authService: auth))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(geminiService)
                .environment(networkMonitor)
                .modelContainer(container)
        }
    }
}
```

### Consuming Services in Views

```swift
struct QuoteCaptureView: View {
    @Environment(GeminiService.self) private var geminiService
    @Environment(\.modelContext) private var modelContext

    func extractQuotes(from image: UIImage) async {
        let result = try await geminiService.extractQuotes(from: image)
        // Use modelContext to save...
    }
}
```

### Custom Environment Keys

For optional services or non-Observable types:

```swift
// Define the key
private struct SearchServiceKey: EnvironmentKey {
    static let defaultValue: SearchService? = nil
}

// Extend EnvironmentValues
extension EnvironmentValues {
    var searchService: SearchService? {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }
}

// View modifier for convenience
extension View {
    func searchService(_ service: SearchService) -> some View {
        environment(\.searchService, service)
    }
}
```

---

## Navigation System

BookQuotes uses a combination of `NavigationStack` and programmatic navigation.

### Tab-Based Structure

Each major section has its own `NavigationStack`:

```swift
// ContentView.swift
struct ContentView: View {
    @State private var selectedTab = Tab.library

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryTab()
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(Tab.library)

            CaptureTab()
                .tabItem { Label("Capture", systemImage: "camera") }
                .tag(Tab.capture)

            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
    }
}
```

### Navigation Within Tabs

Each tab manages its own `NavigationStack`:

```swift
struct LibraryTab: View {
    @State private var router = RouterPath()

    var body: some View {
        NavigationStack(path: $router.path) {
            LibraryView()
                .navigationDestination(for: Book.self) { book in
                    BookDetailView(book: book)
                }
                .navigationDestination(for: Quote.self) { quote in
                    QuoteDetailView(quote: quote)
                }
        }
        .environment(router)
    }
}
```

### Programmatic Navigation

The `RouterPath` helper enables navigation from anywhere:

```swift
@Observable
final class RouterPath {
    var path = NavigationPath()

    func navigate(to destination: any Hashable) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
```

Usage in views:

```swift
struct QuoteCardView: View {
    let quote: Quote
    @Environment(RouterPath.self) private var router

    var body: some View {
        Button {
            router.navigate(to: quote)
        } label: {
            // Quote card content
        }
    }
}
```

### Modal Presentation

Use `@State` booleans with `.sheet()` or `.fullScreenCover()`:

```swift
@State private var showExportSheet = false

var body: some View {
    Button("Export") { showExportSheet = true }
        .sheet(isPresented: $showExportSheet) {
            ExportView(quotes: book.quotes)
        }
}
```

---

## Service Layer

Services encapsulate business logic and external integrations. They're typically `actor` (for thread safety) or `@Observable` classes (for reactive state).

### Service Types

| Type | When to Use | Example |
|------|-------------|---------|
| `actor` | Concurrent operations, no UI state | `BatchProcessingService`, `SearchDatabase` |
| `@Observable class` | Reactive state for UI binding | `SearchService`, `GeminiService` |
| `struct` | Stateless utilities | `ImagePreprocessor` |
| Singleton | App-wide shared state | `NetworkMonitor.shared` |

### Example: GeminiService

```swift
@MainActor
@Observable
final class GeminiService {
    // Observable state for UI
    private(set) var isProcessing = false
    private(set) var lastError: ExtractionError?

    // Dependencies
    private let authService: AuthService
    private let session: URLSession

    init(authService: AuthService) {
        self.authService = authService
        // Configure session...
    }

    // Business method
    func extractQuotes(from image: UIImage, markings: [MarkingDefinition]) async throws -> QuoteExtractionResult {
        isProcessing = true
        defer { isProcessing = false }

        guard let token = authService.getSessionToken() else {
            throw ExtractionError.authenticationRequired
        }

        // Prepare and send request...
        return try QuoteExtractionResult.parse(from: response)
    }
}
```

### Actor Example: BatchProcessingService

```swift
actor BatchProcessingService {
    private var isCancelled = false

    func processSession(_ session: CaptureSession) async throws -> BatchResult {
        isCancelled = false

        return await withTaskGroup(of: PageResult.self) { group in
            for capture in session.captures {
                group.addTask {
                    await self.processCapture(capture)
                }
            }
            // Collect results...
        }
    }

    func cancel() {
        isCancelled = true
    }
}
```

---

## Concurrency Patterns

BookQuotes uses Swift's structured concurrency throughout.

### MainActor for UI-Bound Services

Services that update UI state run on `@MainActor`:

```swift
@MainActor
@Observable
final class SearchService {
    // All property updates happen on main thread
    private(set) var results: SearchResults = .empty
}
```

### Actors for Thread-Safe State

Services with concurrent operations use `actor`:

```swift
actor SearchDatabase {
    private var db: OpaquePointer?

    func search(query: String) throws -> SearchResults {
        // SQLite operations are serialized
    }
}
```

### Task Groups for Parallelism

Batch operations use `withTaskGroup`:

```swift
func processBatch(_ captures: [PageCapture]) async -> [Result] {
    await withTaskGroup(of: Result.self) { group in
        for capture in captures.prefix(maxConcurrent) {
            group.addTask {
                await self.processOne(capture)
            }
        }

        var results: [Result] = []
        for await result in group {
            results.append(result)
        }
        return results
    }
}
```

### Task Cancellation

Long-running operations check for cancellation:

```swift
func search(_ query: String) {
    currentTask?.cancel()

    currentTask = Task {
        try? await Task.sleep(for: .milliseconds(150)) // Debounce
        guard !Task.isCancelled else { return }

        // Perform search...
    }
}
```

---

## Error Handling

Errors are typed per-domain and provide user-friendly messages.

### Domain-Specific Error Types

```swift
enum ExtractionError: LocalizedError {
    case authenticationRequired
    case subscriptionRequired
    case rateLimited
    case invalidImage
    case networkError(Error)
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Please sign in to extract quotes."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        // ...
        }
    }
}
```

### Error Display in Views

```swift
struct QuoteCaptureView: View {
    @State private var error: ExtractionError?

    var body: some View {
        ZStack {
            // Main content...

            if let error {
                ErrorView(error: error, style: .overlay) {
                    // Retry action
                    self.error = nil
                    await retryExtraction()
                }
            }
        }
    }
}
```

### Result Types for Complex Operations

```swift
struct BatchResult {
    let pageResults: [PageProcessingResult]
    let totalProcessingTime: TimeInterval

    var successCount: Int {
        pageResults.filter { $0.success }.count
    }

    var isFullSuccess: Bool {
        pageResults.allSatisfy { $0.success }
    }
}
```

---

## Next Steps

- [SERVICES.md](SERVICES.md) — Deep dive into each service
- [CAPTURE_FLOW.md](CAPTURE_FLOW.md) — End-to-end capture system
- [SEARCH_SYSTEM.md](SEARCH_SYSTEM.md) — FTS5 search architecture
- [TESTING.md](TESTING.md) — Testing strategy and patterns
