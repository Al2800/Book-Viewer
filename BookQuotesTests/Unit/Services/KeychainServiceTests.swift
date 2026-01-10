import XCTest

@testable import BookQuotes

// MARK: - KeychainServiceTests

/// Unit tests for KeychainService secure token storage.
/// Note: These tests use real Keychain operations and require a device/simulator.
final class KeychainServiceTests: XCTestCase {

    // MARK: - Properties

    var keychainService: KeychainService!
    var logger: TestLogger!

    /// Unique test account for generic storage tests
    private let testAccount = "com.bookquotes.test.account"

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        logger = TestLogger(testName: name)
        keychainService = KeychainService()
        logger.info("KeychainService initialized for testing")
    }

    override func tearDown() {
        // Clean up all test keychain items
        cleanupTestData()
        print(logger.summary())
        super.tearDown()
    }

    private func cleanupTestData() {
        // Delete all token types
        try? keychainService.deleteAllTokens()

        // Delete test account used for generic storage tests
        try? keychainService.delete(account: testAccount)

        logger.info("Cleaned up test keychain items")
    }

    // MARK: - Token Save Tests

    func testSaveToken_ValidToken_Succeeds() throws {
        logger.step(1, "Saving a valid session token")
        let testToken = "test-api-key-12345"

        try keychainService.saveToken(testToken, type: .session)

        logger.step(2, "Verifying token was saved")
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, testToken)
        logger.success("Session token saved and retrieved successfully")
    }

    func testSaveToken_AllTypes_Succeeds() throws {
        logger.step(1, "Saving all token types")

        try keychainService.saveToken("session-token", type: .session)
        try keychainService.saveToken("refresh-token", type: .refresh)
        try keychainService.saveToken("apple-identity-token", type: .appleIdentity)

        logger.step(2, "Verifying each type retrieved correctly")
        XCTAssertEqual(try keychainService.getToken(type: .session), "session-token")
        XCTAssertEqual(try keychainService.getToken(type: .refresh), "refresh-token")
        XCTAssertEqual(try keychainService.getToken(type: .appleIdentity), "apple-identity-token")

        logger.success("All token types work correctly")
    }

    func testSaveToken_OverwritesExisting() throws {
        logger.step(1, "Saving initial token")
        try keychainService.saveToken("first-token", type: .session)

        logger.step(2, "Saving new token (should overwrite)")
        try keychainService.saveToken("second-token", type: .session)

        logger.step(3, "Verifying new token retrieved")
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, "second-token")
        logger.success("Token overwrite works correctly")
    }

    func testSaveToken_DefaultsToSession() throws {
        logger.step(1, "Saving token with default type")
        try keychainService.saveToken("default-type-token")

        logger.step(2, "Retrieving with explicit session type")
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, "default-type-token")
        logger.success("Default token type is session")
    }

    // MARK: - Token Retrieve Tests

    func testGetToken_NoToken_ThrowsItemNotFound() throws {
        logger.step(1, "Retrieving token when none exists")

        XCTAssertThrowsError(try keychainService.getToken(type: .session)) { error in
            guard let keychainError = error as? KeychainService.KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            XCTAssertEqual(keychainError, .itemNotFound)
        }

        logger.success("Throws itemNotFound when no token exists")
    }

    func testGetToken_AfterSave_ReturnsToken() throws {
        let testToken = "retrieve-test-token"
        try keychainService.saveToken(testToken, type: .refresh)

        let retrieved = try keychainService.getToken(type: .refresh)

        XCTAssertEqual(retrieved, testToken)
        logger.success("Token retrieved after save")
    }

    func testGetToken_WrongType_ThrowsItemNotFound() throws {
        logger.step(1, "Saving session token")
        try keychainService.saveToken("session-only", type: .session)

        logger.step(2, "Trying to retrieve as refresh token")
        XCTAssertThrowsError(try keychainService.getToken(type: .refresh)) { error in
            guard let keychainError = error as? KeychainService.KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            XCTAssertEqual(keychainError, .itemNotFound)
        }

        logger.success("Wrong token type throws itemNotFound")
    }

    // MARK: - Token Delete Tests

    func testDeleteToken_ExistingToken_Removes() throws {
        logger.step(1, "Saving a token")
        try keychainService.saveToken("to-be-deleted", type: .session)

        logger.step(2, "Deleting the token")
        try keychainService.deleteToken(type: .session)

        logger.step(3, "Verifying token is gone")
        XCTAssertFalse(keychainService.hasToken(type: .session))

        logger.success("Token deleted successfully")
    }

    func testDeleteToken_NoToken_NoError() throws {
        // Should not throw even if no token exists
        XCTAssertNoThrow(try keychainService.deleteToken(type: .session))

        logger.success("Delete on empty keychain succeeds silently")
    }

    func testDeleteToken_OnlyDeletesSpecifiedType() throws {
        logger.step(1, "Saving multiple token types")
        try keychainService.saveToken("session-token", type: .session)
        try keychainService.saveToken("refresh-token", type: .refresh)

        logger.step(2, "Deleting only session token")
        try keychainService.deleteToken(type: .session)

        logger.step(3, "Verifying refresh token still exists")
        XCTAssertFalse(keychainService.hasToken(type: .session))
        XCTAssertTrue(keychainService.hasToken(type: .refresh))

        logger.success("Delete only affects specified type")
    }

    // MARK: - Convenience Method Tests

    func testHasToken_WithToken_ReturnsTrue() throws {
        try keychainService.saveToken("valid-token", type: .session)

        let hasToken = keychainService.hasToken(type: .session)

        XCTAssertTrue(hasToken)
        logger.success("hasToken returns true when token exists")
    }

    func testHasToken_NoToken_ReturnsFalse() {
        let hasToken = keychainService.hasToken(type: .session)

        XCTAssertFalse(hasToken)
        logger.success("hasToken returns false when no token")
    }

    func testHasToken_DefaultsToSession() throws {
        try keychainService.saveToken("session-token", type: .session)

        let hasToken = keychainService.hasToken()

        XCTAssertTrue(hasToken)
        logger.success("hasToken defaults to session type")
    }

    func testTokenOrNil_WithToken_ReturnsToken() throws {
        try keychainService.saveToken("my-token", type: .session)

        let token = keychainService.tokenOrNil(type: .session)

        XCTAssertEqual(token, "my-token")
        logger.success("tokenOrNil returns token when exists")
    }

    func testTokenOrNil_NoToken_ReturnsNil() {
        let token = keychainService.tokenOrNil(type: .session)

        XCTAssertNil(token)
        logger.success("tokenOrNil returns nil when no token")
    }

    func testDeleteAllTokens_RemovesAll() throws {
        logger.step(1, "Saving all token types")
        try keychainService.saveToken("session", type: .session)
        try keychainService.saveToken("refresh", type: .refresh)
        try keychainService.saveToken("apple", type: .appleIdentity)

        logger.step(2, "Deleting all tokens")
        try keychainService.deleteAllTokens()

        logger.step(3, "Verifying all are gone")
        XCTAssertFalse(keychainService.hasToken(type: .session))
        XCTAssertFalse(keychainService.hasToken(type: .refresh))
        XCTAssertFalse(keychainService.hasToken(type: .appleIdentity))

        logger.success("deleteAllTokens removes all token types")
    }

    // MARK: - Special Character Tests

    func testToken_SpecialCharacters_Handled() throws {
        let specialToken = "key-with-special-chars!@#$%^&*()_+-=[]{}|;':,./<>?\"`~"

        try keychainService.saveToken(specialToken, type: .session)
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, specialToken)
        logger.success("Special characters handled correctly")
    }

    func testToken_UnicodeCharacters_Handled() throws {
        let unicodeToken = "token-日本語-émojis-🔐🔑-ñoño"

        try keychainService.saveToken(unicodeToken, type: .session)
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, unicodeToken)
        logger.success("Unicode characters handled correctly")
    }

    func testToken_LongToken_Handled() throws {
        let longToken = String(repeating: "a", count: 2000)

        try keychainService.saveToken(longToken, type: .session)
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, longToken)
        XCTAssertEqual(retrieved.count, 2000)
        logger.success("Long token handled correctly")
    }

    func testToken_EmptyString_Handled() throws {
        // Empty string should be saved and retrieved correctly
        // (though not recommended for real use)
        try keychainService.saveToken("", type: .session)
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, "")
        logger.success("Empty string token handled")
    }

    func testToken_WhitespaceOnly_Handled() throws {
        let whitespaceToken = "   \n\t   "

        try keychainService.saveToken(whitespaceToken, type: .session)
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, whitespaceToken)
        logger.success("Whitespace-only token handled")
    }

    // MARK: - Generic Codable Storage Tests

    func testGenericStorage_SimpleCodable_Succeeds() throws {
        struct UserPrefs: Codable, Equatable {
            let darkMode: Bool
            let fontSize: Int
        }

        logger.step(1, "Saving Codable struct")
        let prefs = UserPrefs(darkMode: true, fontSize: 14)
        try keychainService.save(prefs, account: testAccount)

        logger.step(2, "Retrieving Codable struct")
        let retrieved: UserPrefs = try keychainService.get(account: testAccount)

        XCTAssertEqual(retrieved, prefs)
        logger.success("Generic Codable storage works")
    }

    func testGenericStorage_ComplexCodable_Succeeds() throws {
        struct ComplexData: Codable, Equatable {
            let id: UUID
            let name: String
            let tags: [String]
            let metadata: [String: Int]
            let date: Date
        }

        logger.step(1, "Saving complex Codable struct")
        let data = ComplexData(
            id: UUID(),
            name: "Test Item",
            tags: ["a", "b", "c"],
            metadata: ["count": 42, "version": 1],
            date: Date()
        )
        try keychainService.save(data, account: testAccount)

        logger.step(2, "Retrieving complex struct")
        let retrieved: ComplexData = try keychainService.get(account: testAccount)

        XCTAssertEqual(retrieved.id, data.id)
        XCTAssertEqual(retrieved.name, data.name)
        XCTAssertEqual(retrieved.tags, data.tags)
        XCTAssertEqual(retrieved.metadata, data.metadata)

        logger.success("Complex Codable storage works")
    }

    func testGenericStorage_NoData_ThrowsItemNotFound() throws {
        struct TestStruct: Codable {
            let value: Int
        }

        XCTAssertThrowsError(try keychainService.get(account: testAccount) as TestStruct) { error in
            guard let keychainError = error as? KeychainService.KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            XCTAssertEqual(keychainError, .itemNotFound)
        }

        logger.success("Generic get throws itemNotFound when empty")
    }

    func testGenericStorage_Overwrite_Succeeds() throws {
        struct Version: Codable, Equatable {
            let number: Int
        }

        logger.step(1, "Saving initial version")
        try keychainService.save(Version(number: 1), account: testAccount)

        logger.step(2, "Saving new version (overwrite)")
        try keychainService.save(Version(number: 2), account: testAccount)

        logger.step(3, "Verifying new version retrieved")
        let retrieved: Version = try keychainService.get(account: testAccount)
        XCTAssertEqual(retrieved.number, 2)

        logger.success("Generic storage overwrite works")
    }

    func testGenericStorage_Delete_Removes() throws {
        struct TestData: Codable {
            let value: String
        }

        logger.step(1, "Saving data")
        try keychainService.save(TestData(value: "test"), account: testAccount)

        logger.step(2, "Deleting data")
        try keychainService.delete(account: testAccount)

        logger.step(3, "Verifying data is gone")
        XCTAssertThrowsError(try keychainService.get(account: testAccount) as TestData)

        logger.success("Generic storage delete works")
    }

    func testGenericStorage_DeleteNonExistent_NoError() throws {
        XCTAssertNoThrow(try keychainService.delete(account: "nonexistent-account"))

        logger.success("Delete nonexistent account succeeds silently")
    }

    // MARK: - Error Type Tests

    func testKeychainError_LocalizedDescriptions() {
        // Verify all error types have descriptions
        let errors: [KeychainService.KeychainError] = [
            .saveFailed(0),
            .readFailed(0),
            .deleteFailed(0),
            .dataEncodingFailed,
            .dataDecodingFailed,
            .itemNotFound,
            .unexpectedData
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }

        logger.success("All error types have descriptions")
    }

    func testKeychainError_Equatable() {
        XCTAssertEqual(KeychainService.KeychainError.itemNotFound, .itemNotFound)
        XCTAssertEqual(KeychainService.KeychainError.saveFailed(100), .saveFailed(100))
        XCTAssertNotEqual(KeychainService.KeychainError.saveFailed(100), .saveFailed(200))

        logger.success("KeychainError equatable works")
    }

    // MARK: - Security Tests

    func testToken_NotInUserDefaults() throws {
        let secretToken = "secret-key-12345"
        try keychainService.saveToken(secretToken, type: .session)

        // Verify token is NOT stored in UserDefaults (insecure)
        let userDefaultsValue = UserDefaults.standard.string(forKey: "session")
        XCTAssertNil(userDefaultsValue)

        // Check other common keys
        XCTAssertNil(UserDefaults.standard.string(forKey: "apiKey"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "token"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "accessToken"))

        logger.success("Token not stored in UserDefaults")
    }

    // MARK: - TokenType Tests

    func testTokenType_RawValues() {
        XCTAssertEqual(KeychainService.TokenType.session.rawValue, "session")
        XCTAssertEqual(KeychainService.TokenType.refresh.rawValue, "refresh")
        XCTAssertEqual(KeychainService.TokenType.appleIdentity.rawValue, "apple_identity")

        logger.success("TokenType raw values are correct")
    }

    // MARK: - Shared Instance Tests

    func testSharedInstance_IsSingleton() {
        let instance1 = KeychainService.shared
        let instance2 = KeychainService.shared

        XCTAssertTrue(instance1 === instance2)

        logger.success("Shared instance is singleton")
    }

    func testSharedInstance_SharesState() throws {
        // Save via shared instance
        try KeychainService.shared.saveToken("shared-token", type: .session)

        // Retrieve via our test instance (same underlying keychain)
        let retrieved = try keychainService.getToken(type: .session)

        XCTAssertEqual(retrieved, "shared-token")

        // Clean up
        try KeychainService.shared.deleteToken(type: .session)

        logger.success("Shared instance shares keychain state")
    }
}

// MARK: - KeychainError Equatable

extension KeychainService.KeychainError: Equatable {
    public static func == (lhs: KeychainService.KeychainError, rhs: KeychainService.KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.saveFailed(let s1), .saveFailed(let s2)):
            return s1 == s2
        case (.readFailed(let s1), .readFailed(let s2)):
            return s1 == s2
        case (.deleteFailed(let s1), .deleteFailed(let s2)):
            return s1 == s2
        case (.dataEncodingFailed, .dataEncodingFailed),
             (.dataDecodingFailed, .dataDecodingFailed),
             (.itemNotFound, .itemNotFound),
             (.unexpectedData, .unexpectedData):
            return true
        default:
            return false
        }
    }
}
