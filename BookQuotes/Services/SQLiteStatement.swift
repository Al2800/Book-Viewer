import Foundation
import SQLite3

/// Small adapter for SQLite statement lifecycle and typed column access.
final class SQLiteStatement {
    private let statement: OpaquePointer?

    init(database: OpaquePointer?, sql: String, errorMessage: String) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(errorMessage)
        }
        self.statement = statement
    }

    deinit {
        sqlite3_finalize(statement)
    }

    func bind(_ text: String, at index: Int32) {
        sqlite3_bind_text(statement, index, text, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
    }

    func bind(_ value: Int32, at index: Int32) {
        sqlite3_bind_int(statement, index, value)
    }

    func step() -> Int32 {
        sqlite3_step(statement)
    }

    func text(at index: Int32) -> String? {
        guard let pointer = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: pointer)
    }

    func double(at index: Int32) -> Double {
        sqlite3_column_double(statement, index)
    }

    func int(at index: Int32) -> Int {
        Int(sqlite3_column_int(statement, index))
    }
}
