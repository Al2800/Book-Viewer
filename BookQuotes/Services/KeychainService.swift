import Foundation
import Security

// MARK: - KeychainService

/// Secure storage service for authentication tokens using iOS Keychain.
/// Provides persistent, encrypted storage across app launches.
final class KeychainService: Sendable {

    // MARK: - Types

    /// Keychain storage errors
    enum KeychainError: LocalizedError, Equatable, Sendable {
        case saveFailed(OSStatus)
        case readFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataEncodingFailed
        case dataDecodingFailed
        case itemNotFound
        case unexpectedData

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Failed to save to Keychain (status: \(status))"
            case .readFailed(let status):
                return "Failed to read from Keychain (status: \(status))"
            case .deleteFailed(let status):
                return "Failed to delete from Keychain (status: \(status))"
            case .dataEncodingFailed:
                return "Failed to encode data for Keychain storage"
            case .dataDecodingFailed:
                return "Failed to decode data from Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unexpectedData:
                return "Unexpected data format in Keychain"
            }
        }
    }

    /// Token types that can be stored
    enum TokenType: String, Sendable {
        case session = "session"
        case refresh = "refresh"
        case appleIdentity = "apple_identity"
    }

    // MARK: - Constants

    private let service = "com.bookquotes.auth"

    // MARK: - Singleton

    /// Shared instance for app-wide use
    static let shared = KeychainService()

    // MARK: - Initialization

    init() {}

    // MARK: - Token Storage

    /// Save a token securely to the Keychain.
    /// - Parameters:
    ///   - token: The token string to store
    ///   - type: The type of token (session, refresh, etc.)
    /// - Throws: KeychainError if storage fails
    func saveToken(_ token: String, type: TokenType = .session) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.dataEncodingFailed
        }

        // Build the query for the keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: type.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve a token from the Keychain.
    /// - Parameter type: The type of token to retrieve
    /// - Returns: The stored token string
    /// - Throws: KeychainError if retrieval fails or item doesn't exist
    func getToken(type: TokenType = .session) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: type.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            guard let token = String(data: data, encoding: .utf8) else {
                throw KeychainError.dataDecodingFailed
            }
            return token

        case errSecItemNotFound:
            throw KeychainError.itemNotFound

        default:
            throw KeychainError.readFailed(status)
        }
    }

    /// Delete a token from the Keychain.
    /// - Parameter type: The type of token to delete
    /// - Throws: KeychainError if deletion fails (except item not found, which succeeds silently)
    func deleteToken(type: TokenType = .session) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: type.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Success or item not found are both acceptable
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    // MARK: - Convenience Methods

    /// Check if a token exists in the Keychain.
    /// - Parameter type: The type of token to check
    /// - Returns: true if the token exists
    func hasToken(type: TokenType = .session) -> Bool {
        do {
            _ = try getToken(type: type)
            return true
        } catch {
            return false
        }
    }

    /// Get the session token if it exists, nil otherwise.
    /// - Parameter type: The type of token to retrieve
    /// - Returns: The token string or nil if not found
    func tokenOrNil(type: TokenType = .session) -> String? {
        try? getToken(type: type)
    }

    /// Delete all stored tokens (logout/cleanup).
    /// - Throws: KeychainError if any deletion fails
    func deleteAllTokens() throws {
        for tokenType in [TokenType.session, .refresh, .appleIdentity] {
            try deleteToken(type: tokenType)
        }
    }

    // MARK: - Generic Data Storage

    /// Save arbitrary Codable data to the Keychain.
    /// - Parameters:
    ///   - data: The Codable object to store
    ///   - account: Unique account identifier for this data
    /// - Throws: KeychainError if storage fails
    func save<T: Codable>(_ data: T, account: String) throws {
        let encoder = JSONEncoder()
        guard let encodedData = try? encoder.encode(data) else {
            throw KeychainError.dataEncodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: encodedData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve Codable data from the Keychain.
    /// - Parameter account: The account identifier used when saving
    /// - Returns: The decoded object
    /// - Throws: KeychainError if retrieval or decoding fails
    func get<T: Codable>(account: String) throws -> T {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            let decoder = JSONDecoder()
            guard let decoded = try? decoder.decode(T.self, from: data) else {
                throw KeychainError.dataDecodingFailed
            }
            return decoded

        case errSecItemNotFound:
            throw KeychainError.itemNotFound

        default:
            throw KeychainError.readFailed(status)
        }
    }

    /// Delete data from the Keychain by account.
    /// - Parameter account: The account identifier
    /// - Throws: KeychainError if deletion fails
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    // MARK: - String Convenience

    func getString(forKey key: String) -> String? {
        try? get(account: key)
    }

    func setString(_ value: String, forKey key: String) {
        try? save(value, account: key)
    }

    func delete(forKey key: String) {
        try? delete(account: key)
    }
}
