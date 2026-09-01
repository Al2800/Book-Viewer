import Foundation
import SwiftData

// MARK: - ActiveReadingSessionStore

/// Manages the currently active book for zero-click capture flow.
@Observable
final class ActiveReadingSessionStore {
    static let shared = ActiveReadingSessionStore()

    private let userDefaults: UserDefaults
    private let activeBookKey = "active_reading_book_id"

    var activeBookID: UUID? {
        didSet {
            if let activeBookID {
                userDefaults.set(activeBookID.uuidString, forKey: activeBookKey)
            } else {
                userDefaults.removeObject(forKey: activeBookKey)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let savedIDString = userDefaults.string(forKey: activeBookKey),
           let uuid = UUID(uuidString: savedIDString) {
            self.activeBookID = uuid
        } else {
            self.activeBookID = nil
        }
    }

    /// Resolves the active book from a collection of available books without side effects.
    /// Priority order:
    /// 1. Book matching persisted `activeBookID`
    /// 2. First book with `.currentlyReading` status (sorted by dateModified desc)
    /// 3. Most recently modified book
    /// 4. nil if no books exist
    func activeBook(from books: [Book]) -> Book? {
        guard !books.isEmpty else { return nil }

        // 1. Persisted match
        if let activeBookID, let matched = books.first(where: { $0.id == activeBookID }) {
            return matched
        }

        // 2. Currently reading
        let currentlyReading = books
            .filter { $0.status == .currentlyReading }
            .sorted { $0.dateModified > $1.dateModified }
        if let firstReading = currentlyReading.first {
            return firstReading
        }

        // 3. Most recently modified
        let sorted = books.sorted { $0.dateModified > $1.dateModified }
        return sorted.first
    }

    /// Resolves and persists the active book from available books.
    @discardableResult
    func resolveActiveBook(from books: [Book], persist: Bool = true) -> Book? {
        guard let resolved = activeBook(from: books) else { return nil }
        if persist && activeBookID != resolved.id {
            setActiveBook(resolved)
        }
        return resolved
    }

    /// Sets the currently active reading book.
    func setActiveBook(_ book: Book?) {
        self.activeBookID = book?.id
    }

    /// Clears active book selection.
    func clearActiveBook() {
        self.activeBookID = nil
    }
}
