import Foundation

protocol BookISBNMetadataLookup {
    func lookup(isbn: String) async throws -> BookMetadata
}

extension ISBNLookupService: BookISBNMetadataLookup {}

enum BookISBNScanLookupResult {
    case found(BookMetadata)
    case failed(Error)
}

struct BookISBNScanLookup {
    private let lookupMetadata: (String) async throws -> BookMetadata

    init(lookupMetadata: @escaping (String) async throws -> BookMetadata) {
        self.lookupMetadata = lookupMetadata
    }

    init(service: any BookISBNMetadataLookup = ISBNLookupService()) {
        self.lookupMetadata = { isbn in
            try await service.lookup(isbn: isbn)
        }
    }

    func lookup(isbn: String) async -> BookISBNScanLookupResult {
        do {
            return .found(try await lookupMetadata(isbn))
        } catch {
            return .failed(error)
        }
    }
}
