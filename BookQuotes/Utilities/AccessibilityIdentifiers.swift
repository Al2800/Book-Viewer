import Foundation

// MARK: - Accessibility Identifiers

/// Centralized accessibility identifiers for UI automation testing.
///
/// Usage in views:
/// ```swift
/// someView
///     .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCell)
/// ```
///
/// Usage in UI tests:
/// ```swift
/// app.buttons[AccessibilityIdentifiers.Capture.captureButton].tap()
/// ```
enum AccessibilityIdentifiers {

    // MARK: - Library

    enum Library {
        /// Grid cell displaying a book cover
        static let bookCoverCard = "library_book_cover_card"

        /// List row displaying a book
        static let bookListRow = "library_book_list_row"

        /// Empty state view when library has no books
        static let emptyState = "library_empty_state"

        /// Add book button in library
        static let addBookButton = "library_add_book_button"

        /// Filter toggle for library view
        static let filterButton = "library_filter_button"

        /// Sort menu for library view
        static let sortMenu = "library_sort_menu"

        /// View mode toggle (grid/list)
        static let viewModeToggle = "library_view_mode_toggle"

        /// Dismisses an active library search and returns to the library root
        static let dismissSearchButton = "library_dismiss_search_button"

        /// Organize section row linking to Collections
        static let collectionsRow = "library_collections_row"

        /// Organize section row linking to Tags
        static let tagsRow = "library_tags_row"
    }

    // MARK: - Search

    enum Search {
        /// Main search text field
        static let searchField = "search_field"

        /// Search scope picker (all/books/quotes)
        static let scopePicker = "search_scope_picker"

        /// Book search result row
        static let bookResultRow = "search_book_result_row"

        /// Quote search result row
        static let quoteResultRow = "search_quote_result_row"

        /// No results empty state
        static let noResultsView = "search_no_results"

        /// Searching progress indicator
        static let searchingIndicator = "search_searching"

        /// Did-you-mean suggestion banner
        static let didYouMeanBanner = "search_did_you_mean_banner"
    }

    // MARK: - Quote Card

    enum QuoteCard {
        /// Quote card container
        static let container = "quote_card_container"

        /// Quote text display
        static let quoteText = "quote_card_text"

        /// Margin note display
        static let marginNote = "quote_card_margin_note"

        /// Favorite indicator heart
        static let favoriteIndicator = "quote_card_favorite"

        /// Marking type badge
        static let markingBadge = "quote_card_marking_badge"

        /// Page number label
        static let pageNumber = "quote_card_page_number"

        /// Confidence indicator
        static let confidenceIndicator = "quote_card_confidence"
    }

    // MARK: - Quote Detail

    enum QuoteDetail {
        /// Text editor for editing quote
        static let textEditor = "quote_detail_text_editor"

        /// Page number text field
        static let pageField = "quote_detail_page_field"

        /// Margin note text field
        static let marginNoteField = "quote_detail_margin_note_field"

        /// Edit button / menu
        static let editButton = "quote_detail_edit_button"

        /// Done button (save edits)
        static let doneButton = "quote_detail_done_button"

        /// Cancel button (discard edits)
        static let cancelButton = "quote_detail_cancel_button"

        /// Delete button
        static let deleteButton = "quote_detail_delete_button"

        /// Favorite toggle button
        static let favoriteButton = "quote_detail_favorite_button"

        /// Copy to clipboard button
        static let copyButton = "quote_detail_copy_button"

        /// Share button
        static let shareButton = "quote_detail_share_button"

        /// View source image button
        static let sourceImageButton = "quote_detail_source_image_button"

        /// Marking type picker button
        static let markingPickerButton = "quote_detail_marking_picker"
    }

    // MARK: - Book Edit

    enum BookEdit {
        /// Title field on the add/edit book form
        static let titleField = "book_edit_title_field"

        /// Author field on the add/edit book form
        static let authorField = "book_edit_author_field"

        /// Subtitle field on the add/edit book form
        static let subtitleField = "book_edit_subtitle_field"

        /// ISBN field on the add/edit book form
        static let isbnField = "book_edit_isbn_field"

        /// Publisher field on the add/edit book form
        static let publisherField = "book_edit_publisher_field"

        /// Cancel button on the add/edit book form
        static let cancelButton = "book_edit_cancel_button"

        /// Save/Add button on the add/edit book form
        static let saveButton = "book_edit_save_button"

        /// Scrollable content in the add/edit book form
        static let formScrollView = "book_edit_form_scroll_view"

        /// Keyboard toolbar action that removes focus from the active book field
        static let keyboardDoneButton = "book_edit_keyboard_done_button"
    }

    // MARK: - Capture

    enum Capture {
        /// Main capture/shutter button
        static let captureButton = "capture_button"

        /// Camera preview view
        static let cameraPreview = "capture_camera_preview"

        /// Quality overlay toggle
        static let qualityToggle = "capture_quality_toggle"

        /// Cancel capture button
        static let cancelButton = "capture_cancel_button"

        /// Camera permission prompt
        static let permissionPrompt = "capture_permission_prompt"

        /// Open settings button (for camera permission)
        static let openSettingsButton = "capture_open_settings_button"

        /// UI test-only button for injecting a test capture image
        static let testImageButton = "capture_test_image_button"

        /// UI test-only button for injecting a test cover image
        static let testCoverButton = "capture_test_cover_button"

        /// Manual metadata entry action shown in cover capture.
        static let manualEntryButton = "capture_manual_entry_button"

        /// Barcode scanner framing guide shown in cover capture.
        static let barcodeScanFrame = "capture_barcode_scan_frame"

        /// Barcode scanner instruction shown in cover capture.
        static let barcodeInstruction = "capture_barcode_instruction"

        /// Capture mode selection: cover
        static let modeSelectCover = "capture_mode_select_cover"

        /// Capture mode selection: quote
        static let modeSelectQuote = "capture_mode_select_quote"

        /// Capture mode selection: batch
        static let modeSelectBatch = "capture_mode_select_batch"

        /// Book card in capture book selection grid
        static let bookSelectionCard = "capture_book_selection_card"

        /// Mode picker (photo/barcode)
        static let modePicker = "capture_mode_picker"

        /// Page counter in batch capture
        static let pageCounter = "capture_page_counter"

        /// Done button in batch capture
        static let doneButton = "capture_done_button"

        /// Thumbnail strip in batch capture
        static let thumbnailStrip = "capture_thumbnail_strip"

        /// Individual page thumbnail in batch capture
        static let thumbnail = "capture_thumbnail"

        /// Process button in the batch completion confirmation
        static let processBatchButton = "capture_process_batch_button"

        /// Save draft button in the batch completion confirmation
        static let saveDraftButton = "capture_save_draft_button"

        /// Remove page button in the batch capture detail sheet
        static let removePageButton = "capture_remove_page_button"

        // MARK: Extraction Review (Quote Capture)

        /// Edit button (pencil) on an extracted quote row during extraction review.
        static let extractionQuoteEditButton = "capture_extraction_quote_edit_button"

        /// Text editor inside the "Edit Quote" sheet during extraction review.
        static let extractionQuoteTextEditor = "capture_extraction_quote_text_editor"

        /// Margin note field inside the "Edit Quote" sheet during extraction review.
        static let extractionQuoteMarginNoteField = "capture_extraction_quote_margin_note_field"

        /// Per-candidate provenance shown during extraction review.
        static let extractionQuoteSourceLabel = "capture_extraction_quote_source_label"

        /// On-device fallback status shown for a processed page.
        static let extractionFallbackNotice = "capture_extraction_fallback_notice"

        /// Page selector shown during extraction review.
        static let extractionPageSelector = "capture_extraction_page_selector"

        /// Main vertical scroll view for compact extraction review layouts.
        static let extractionReviewScrollView = "capture_extraction_review_scroll_view"

        /// Source page image shown during extraction review.
        static let extractionPageImage = "capture_extraction_page_image"
    }

    // MARK: - Collections

    enum Collections {
        /// Add to collection button
        static let addButton = "collections_add_button"

        /// Collection list row
        static let collectionRow = "collections_row"

        /// Create collection button
        static let createButton = "collections_create_button"

        /// Collection name field
        static let nameField = "collections_name_field"

        /// Collection detail view
        static let detailView = "collections_detail_view"

        /// Empty state view
        static let emptyState = "collections_empty_state"
    }

    // MARK: - Tags

    enum Tags {
        /// Add tag button
        static let addButton = "tags_add_button"

        /// Tag chip/pill view
        static let tagChip = "tags_chip"

        /// Tag name field
        static let nameField = "tags_name_field"

        /// Tags list view
        static let listView = "tags_list_view"

        /// Empty state view
        static let emptyState = "tags_empty_state"
    }

    // MARK: - Image Review

    enum ImageReview {
        /// Captured image preview
        static let imagePreview = "image_review_preview"

        /// Retake photo button
        static let retakeButton = "image_review_retake_button"

        /// Use/confirm photo button
        static let usePhotoButton = "image_review_use_photo_button"

        /// Quality indicator bar
        static let qualityBar = "image_review_quality_bar"

        /// Cancel/dismiss button
        static let cancelButton = "image_review_cancel_button"
    }

    // MARK: - Cover Crop Review

    enum CoverCrop {
        /// Retake cover crop button
        static let retakeButton = "cover_crop_retake_button"

        /// Accept cropped cover button
        static let useCropButton = "cover_crop_use_button"
    }

    // MARK: - Export

    enum Export {
        /// Export button in toolbar
        static let exportButton = "export_button"

        /// Format picker
        static let formatPicker = "export_format_picker"

        /// Preview section
        static let previewSection = "export_preview"

        /// Preview text content
        static let previewText = "export_preview_text"

        /// Share link button
        static let shareButton = "export_share_button"

        /// Include book info toggle
        static let includeBookInfoToggle = "export_include_book_info"

        /// Include page numbers toggle
        static let includePageNumbersToggle = "export_include_page_numbers"
    }

    // MARK: - Book Detail

    enum BookDetail {
        /// Book title text
        static let bookTitle = "book_detail_title"

        /// Author text
        static let bookAuthor = "book_detail_author"

        /// Cover image
        static let coverImage = "book_detail_cover_image"

        /// Quote count label
        static let quoteCount = "book_detail_quote_count"

        /// Capture quotes button
        static let captureQuotesButton = "book_detail_capture_button"

        /// Edit book button
        static let editButton = "book_detail_edit_button"

        /// Delete book button
        static let deleteButton = "book_detail_delete_button"

        /// Reading status picker in the book editor.
        static let statusPicker = "book_detail_status_picker"
    }

    // MARK: - Onboarding

    enum Onboarding {
        /// Continue/next button
        static let continueButton = "onboarding_continue_button"

        /// Skip button
        static let skipButton = "onboarding_skip_button"

        /// Sign in button
        static let signInButton = "onboarding_sign_in_button"

        /// Page indicator dots
        static let pageIndicator = "onboarding_page_indicator"
    }

    // MARK: - Settings

    enum Settings {
        /// Account section
        static let accountSection = "settings_account_section"

        /// Sign out button
        static let signOutButton = "settings_sign_out_button"

        /// Delete account button
        static let deleteAccountButton = "settings_delete_account_button"

        /// Sign in button
        static let signInButton = "settings_sign_in_button"

        /// Subscription status view
        static let subscriptionStatus = "settings_subscription_status"

        /// Restore purchases button
        static let restorePurchasesButton = "settings_restore_purchases"

        /// Manage subscription button
        static let manageSubscriptionButton = "settings_manage_subscription"

        /// Marking definitions navigation row
        static let markingDefinitionsRow = "settings_marking_definitions_row"

        /// Account navigation row
        static let accountRow = "settings_account_row"

        /// Storage and export navigation row
        static let storageAndExportRow = "settings_storage_and_export_row"

        /// About navigation row
        static let aboutRow = "settings_about_row"

        /// Remote AI processing settings destination.
        static let remoteAIProcessingRow = "settings_remote_ai_processing_row"

        /// Consent toggle for remote AI processing.
        static let remoteAIProcessingToggle = "settings_remote_ai_processing_toggle"

        /// Export quotes row button
        static let exportQuotesButton = "settings_export_quotes_button"

        /// Privacy policy row button
        static let privacyPolicyButton = "settings_privacy_policy_button"

        /// Terms of service row button
        static let termsOfServiceButton = "settings_terms_of_service_button"
    }

    // MARK: - Marking Definitions

    enum MarkingDefinitions {
        /// Root list view
        static let listView = "marking_definitions_list_view"

        /// Add custom marking button
        static let addButton = "marking_definitions_add_button"

        /// A single marking row/card
        static let markingRow = "marking_definitions_row"
    }

    // MARK: - Marking Definition Editor

    enum MarkingEditor {
        static let nameField = "marking_editor_name_field"
        static let visualDescriptionField = "marking_editor_visual_description_field"
        static let meaningField = "marking_editor_meaning_field"
        static let saveButton = "marking_editor_save_button"
        static let cancelButton = "marking_editor_cancel_button"
        static let keyboardActionButton = "marking_editor_keyboard_action_button"
    }

    // MARK: - Tabs

    enum Tabs {
        /// Library tab bar item
        static let libraryTab = "tab_library"

        /// Capture tab bar item
        static let captureTab = "tab_capture"

        /// Settings tab bar item
        static let settingsTab = "tab_settings"
    }

    // MARK: - Common

    enum Common {
        /// Loading/progress indicator
        static let loadingIndicator = "loading_indicator"

        /// Error view
        static let errorView = "error_view"

        /// Retry button
        static let retryButton = "retry_button"

        /// Dismiss button
        static let dismissButton = "dismiss_button"

        /// Overflow/more menu button (ellipsis)
        static let moreMenuButton = "more_menu_button"

        /// UI test seed completion marker
        static let uiTestSeeded = "ui_test_seeded"

        /// UI test visible book count marker
        static let uiTestBookCount = "ui_test_book_count"
    }
}
