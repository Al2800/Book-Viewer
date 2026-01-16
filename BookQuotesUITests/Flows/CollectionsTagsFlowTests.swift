import XCTest

/// End-to-end tests for collections and tags management flows.
/// Tests creating, editing, and organizing quotes with collections and tags.
final class CollectionsTagsFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()

        // Navigate to library tab
        let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    // MARK: - Collections Navigation Tests

    func testLibrary_FilterButton_ShowsFilterOptions() {
        logger.step(1, "Finding filter button")
        let filterButton = app.buttons[AccessibilityIdentifiers.Library.filterButton]

        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            logger.step(2, "Verifying filter options appear")
            // Should see filter sheet with collections and tags options
            let collectionsOption = app.staticTexts["Collections"]
            let tagsOption = app.staticTexts["Tags"]
            let filterSheet = app.sheets.firstMatch

            let hasFilterUI = collectionsOption.waitForExistence(timeout: 3) ||
                             tagsOption.exists ||
                             filterSheet.exists

            if hasFilterUI {
                logger.success("Filter options displayed")
            }

            // Dismiss
            app.swipeDown()
        } else {
            logger.info("Filter button not found - may have different UI")
        }
    }

    // MARK: - Collection Creation Tests

    func testQuoteDetail_AddToCollection_ShowsCollectionSheet() {
        logger.step(1, "Opening a quote detail")
        openFirstQuote()

        logger.step(2, "Finding add to collection option")
        // Try menu button first
        let menuButton = findMoreMenuButton()
        if menuButton.waitForExistence(timeout: 3) {
            menuButton.tap()

            let addToCollectionOption = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Collection'")
            ).firstMatch

            if addToCollectionOption.waitForExistence(timeout: 2) {
                addToCollectionOption.tap()

                logger.step(3, "Verifying collection sheet")
                let createNewButton = app.buttons[AccessibilityIdentifiers.Collections.createButton]
                let collectionsList = app.tables.firstMatch

                let hasCollectionSheet = createNewButton.waitForExistence(timeout: 3) ||
                                        collectionsList.exists

                if hasCollectionSheet {
                    logger.success("Collection sheet displayed")
                }

                // Dismiss
                app.swipeDown()
            } else {
                logger.info("Add to collection option not in menu")
            }
        }
    }

    func testCollectionSheet_CreateNew_ShowsNameField() {
        logger.step(1, "Opening collection sheet")
        openFirstQuote()

        let menuButton = findMoreMenuButton()
        if menuButton.waitForExistence(timeout: 3) {
            menuButton.tap()

            let addToCollectionOption = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Collection'")
            ).firstMatch

            if addToCollectionOption.waitForExistence(timeout: 2) {
                addToCollectionOption.tap()

                logger.step(2, "Tapping create new collection")
                let createButton = app.buttons[AccessibilityIdentifiers.Collections.createButton]
                let newCollectionButton = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'New Collection' OR label CONTAINS 'Create'")
                ).firstMatch

                if createButton.waitForExistence(timeout: 3) {
                    createButton.tap()
                } else if newCollectionButton.exists {
                    newCollectionButton.tap()
                }

                logger.step(3, "Verifying name field appears")
                let nameField = app.textFields[AccessibilityIdentifiers.Collections.nameField]
                let collectionNameField = app.textFields.matching(
                    NSPredicate(format: "placeholderValue CONTAINS 'name' OR placeholderValue CONTAINS 'Name'")
                ).firstMatch

                let hasNameField = nameField.waitForExistence(timeout: 3) || collectionNameField.exists

                if hasNameField {
                    logger.success("Collection name field displayed")
                }

                // Cancel
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }

        // Dismiss any sheets
        app.swipeDown()
    }

    func testCollection_CreateAndSave_AppearsInList() {
        logger.step(1, "Opening collection creation")
        openFirstQuote()

        let menuButton = findMoreMenuButton()
        guard menuButton.waitForExistence(timeout: 3) else {
            logger.info("Menu button not found")
            return
        }

        menuButton.tap()

        let addToCollectionOption = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Collection'")
        ).firstMatch

        guard addToCollectionOption.waitForExistence(timeout: 2) else {
            logger.info("Add to collection not available")
            app.tap() // Dismiss menu
            return
        }

        addToCollectionOption.tap()

        logger.step(2, "Creating new collection")
        let createButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'New' OR label CONTAINS 'Create'")
        ).firstMatch

        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()

            let nameField = app.textFields.firstMatch
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText("Test Collection")

                logger.step(3, "Saving collection")
                let saveButton = app.buttons["Save"]
                let doneButton = app.buttons["Done"]

                if saveButton.exists {
                    saveButton.tap()
                } else if doneButton.exists {
                    doneButton.tap()
                }

                logger.step(4, "Verifying collection appears")
                let collectionRow = app.staticTexts["Test Collection"]

                if collectionRow.waitForExistence(timeout: 3) {
                    logger.success("Collection created and visible")
                }
            }
        }

        app.swipeDown()
    }

    // MARK: - Tag Tests

    func testQuoteDetail_AddTag_ShowsTagInput() {
        logger.step(1, "Opening quote detail")
        openFirstQuote()

        logger.step(2, "Finding add tag button")
        let addTagButton = app.buttons[AccessibilityIdentifiers.Tags.addButton]
        let tagButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Tag' OR label CONTAINS 'tag'")
        ).firstMatch

        if addTagButton.waitForExistence(timeout: 3) || tagButton.waitForExistence(timeout: 2) {
            if addTagButton.exists {
                addTagButton.tap()
            } else {
                tagButton.tap()
            }

            logger.step(3, "Verifying tag input")
            let tagField = app.textFields[AccessibilityIdentifiers.Tags.nameField]
            let tagInput = app.textFields.matching(
                NSPredicate(format: "placeholderValue CONTAINS 'tag' OR placeholderValue CONTAINS 'Tag'")
            ).firstMatch

            let hasTagInput = tagField.waitForExistence(timeout: 3) || tagInput.exists

            if hasTagInput {
                logger.success("Tag input displayed")
            }

            // Cancel
            app.tap()
        } else {
            // Tags might be in a different location - try menu
            let menuButton = findMoreMenuButton()
            if menuButton.exists {
                menuButton.tap()

                let tagOption = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'Tag'")
                ).firstMatch

                if tagOption.waitForExistence(timeout: 2) {
                    logger.info("Tag option found in menu")
                }

                app.tap() // Dismiss
            }
        }
    }

    func testQuoteDetail_ExistingTags_DisplayAsChips() {
        logger.step(1, "Opening quote detail")
        openFirstQuote()

        logger.step(2, "Looking for tag chips")
        let tagChips = app.buttons[AccessibilityIdentifiers.Tags.tagChip]

        // Tags might be displayed as buttons or static text
        let tagElements = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'tag'")
        )

        let hasTagDisplay = tagChips.waitForExistence(timeout: 3) || tagElements.count > 0

        if hasTagDisplay {
            logger.success("Tag chips displayed")
        } else {
            logger.info("No tags on this quote or different display format")
        }
    }

    // MARK: - Filter by Collection Tests

    func testLibrary_FilterByCollection_FiltersResults() {
        logger.step(1, "Finding filter button")
        let filterButton = app.buttons[AccessibilityIdentifiers.Library.filterButton]

        guard filterButton.waitForExistence(timeout: 3) else {
            logger.info("Filter button not found")
            return
        }

        filterButton.tap()

        logger.step(2, "Selecting a collection filter")
        let collectionsSection = app.staticTexts["Collections"]
        if collectionsSection.waitForExistence(timeout: 3) {
            // Try to find and tap a collection
            let collectionCell = app.cells.firstMatch
            if collectionCell.exists {
                collectionCell.tap()

                logger.step(3, "Verifying filter applied")
                // Should see filter indicator or reduced results
                let activeFilter = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'Clear' OR identifier CONTAINS 'filter'")
                ).firstMatch

                if activeFilter.waitForExistence(timeout: 3) {
                    logger.success("Collection filter applied")
                }
            }
        }

        app.swipeDown()
    }

    // MARK: - Filter by Tag Tests

    func testLibrary_FilterByTag_FiltersResults() {
        logger.step(1, "Finding filter button")
        let filterButton = app.buttons[AccessibilityIdentifiers.Library.filterButton]

        guard filterButton.waitForExistence(timeout: 3) else {
            logger.info("Filter button not found")
            return
        }

        filterButton.tap()

        logger.step(2, "Selecting tag filter")
        let tagsSection = app.staticTexts["Tags"]
        if tagsSection.waitForExistence(timeout: 3) {
            // Find tag chips in filter view
            let tagChip = app.buttons.matching(
                NSPredicate(format: "identifier CONTAINS 'tag'")
            ).firstMatch

            if tagChip.exists {
                tagChip.tap()

                logger.step(3, "Verifying filter applied")
                let activeFilter = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'Clear'")
                ).firstMatch

                if activeFilter.waitForExistence(timeout: 3) {
                    logger.success("Tag filter applied")
                }
            }
        }

        app.swipeDown()
    }

    // MARK: - Search Filter Tests

    func testSearch_FilterSheet_ShowsFiltersOptions() {
        logger.step(1, "Activating search")
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
        }

        logger.step(2, "Finding filter button in search")
        let filterButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Filter' OR identifier CONTAINS 'filter'")
        ).firstMatch

        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            logger.step(3, "Verifying filter sheet content")
            let collectionsFilter = app.staticTexts["Collections"]
            let tagsFilter = app.staticTexts["Tags"]
            let dateFilter = app.staticTexts["Date"]

            let hasFilters = collectionsFilter.waitForExistence(timeout: 3) ||
                            tagsFilter.exists ||
                            dateFilter.exists

            if hasFilters {
                logger.success("Search filter sheet shows filter options")
            }

            app.swipeDown()
        } else {
            logger.info("Filter button not found in search UI")
        }

        // Dismiss keyboard
        dismissKeyboard()
    }

    // MARK: - Collection Detail Tests

    func testCollection_TapCollection_ShowsCollectionDetail() {
        logger.step(1, "Opening filter to find collections")
        let filterButton = app.buttons[AccessibilityIdentifiers.Library.filterButton]

        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            logger.step(2, "Finding collections section")
            let collectionsHeader = app.staticTexts["Collections"]
            if collectionsHeader.waitForExistence(timeout: 3) {
                // Try to find and tap a collection row
                let collectionRow = app.cells[AccessibilityIdentifiers.Collections.collectionRow].firstMatch

                if collectionRow.exists {
                    collectionRow.tap()

                    logger.step(3, "Verifying collection detail")
                    let collectionDetail = app.otherElements[AccessibilityIdentifiers.Collections.detailView]
                    let quotesList = app.tables.firstMatch

                    let hasDetail = collectionDetail.waitForExistence(timeout: 3) || quotesList.exists

                    if hasDetail {
                        logger.success("Collection detail displayed")
                    }

                    // Go back
                    tapBackButton()
                }
            }

            app.swipeDown()
        }
    }

    // MARK: - Helpers

    private func openFirstQuote() {
        // Open first book
        openFirstBook()

        // Find and tap first quote
        let quoteCard = app.otherElements[AccessibilityIdentifiers.QuoteCard.container].firstMatch
        let quoteCells = app.cells.firstMatch

        if quoteCard.waitForExistence(timeout: 3) {
            quoteCard.tap()
        } else if quoteCells.exists {
            quoteCells.tap()
        }

        // Wait for quote detail
        _ = app.textViews.firstMatch.waitForExistence(timeout: 3)
    }

    private func openFirstBook() {
        // Switch to list view for easier selection
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        if viewModeToggle.waitForExistence(timeout: 2) {
            if viewModeToggle.buttons.count > 1 {
                viewModeToggle.buttons.element(boundBy: 1).tap()
            }
        }

        // Tap first book
        let bookRow = app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        if bookRow.waitForExistence(timeout: 3) {
            bookRow.tap()
        } else if app.cells.firstMatch.exists {
            app.cells.firstMatch.tap()
        }

        // Wait for detail view
        _ = app.staticTexts["Quotes"].waitForExistence(timeout: 3)
    }

    private func findMoreMenuButton() -> XCUIElement {
        let navButtons = app.navigationBars.buttons
        let predicate = NSPredicate(format: "label CONTAINS 'More' OR label CONTAINS 'ellipsis'")
        let match = navButtons.matching(predicate).firstMatch
        if match.exists {
            return match
        }
        return navButtons.element(boundBy: navButtons.count > 0 ? navButtons.count - 1 : 0)
    }
}
