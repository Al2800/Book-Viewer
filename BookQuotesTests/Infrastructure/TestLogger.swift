import Foundation
import os.log

// MARK: - TestLogger

/// Thread-safe test logger with structured output.
final class TestLogger {

    // MARK: - Log Levels

    enum Level: String, Sendable {
        case trace = "TRACE"
        case debug = "DEBUG"
        case info = "INFO"
        case step = "STEP"
        case warning = "WARN"
        case error = "ERROR"
        case success = "PASS"
        case failure = "FAIL"

        var emoji: String {
            switch self {
            case .trace: return "⚪️"
            case .debug: return "🔵"
            case .info: return "🟢"
            case .step: return "👉"
            case .warning: return "🟡"
            case .error: return "🔴"
            case .success: return "✅"
            case .failure: return "❌"
            }
        }

        var display: String {
            "\(emoji) \(rawValue)"
        }
    }

    // MARK: - Log Entry

    struct LogEntry: Sendable, Codable {
        let timestamp: Date
        let level: String
        let testName: String
        let message: String
        let file: String
        let line: Int
        let context: [String: String]

        var formatted: String {
            let time = Self.formatter.string(from: timestamp)
            let filename = file.split(separator: "/").last.map(String.init) ?? file
            let location = "\(filename):\(line)"
            let contextStr = context.isEmpty ? "" : " \(context)"
            return "[\(time)] [\(level)] [\(testName)] \(message)\(contextStr) (\(location))"
        }

        private static let formatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
    }

    // MARK: - Properties

    private let testName: String
    private let logFileURL: URL?
    private let osLog: OSLog
    private let entries: LockedState<[LogEntry]>

    // MARK: - Initialization

    init(testName: String, writeToFile: Bool = true) {
        self.testName = testName
        self.osLog = OSLog(subsystem: "com.bookquotes.tests", category: testName)
        self.entries = LockedState([])

        if writeToFile {
            let logsDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("BookQuotesTestLogs", isDirectory: true)
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

            let timestamp = Int(Date().timeIntervalSince1970)
            let sanitizedName = testName.replacingOccurrences(of: " ", with: "_")
            self.logFileURL = logsDir.appendingPathComponent("\(sanitizedName)_\(timestamp).log")
        } else {
            self.logFileURL = nil
        }
    }

    // MARK: - Logging Methods

    func trace(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.trace, message, context: context, file: file, line: line)
    }

    func debug(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.debug, message, context: context, file: file, line: line)
    }

    func info(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.info, message, context: context, file: file, line: line)
    }

    func step(
        _ stepNumber: Int,
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.step, "Step \(stepNumber): \(message)", context: context, file: file, line: line)
    }

    func warning(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.warning, message, context: context, file: file, line: line)
    }

    func error(
        _ message: String,
        error: Error? = nil,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        var ctx = context
        if let error = error {
            ctx["error"] = String(describing: error)
        }
        log(.error, message, context: ctx, file: file, line: line)
    }

    func success(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.success, message, context: context, file: file, line: line)
    }

    func failure(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        line: Int = #line
    ) {
        log(.failure, message, context: context, file: file, line: line)
    }

    // MARK: - Core Logging

    private func log(
        _ level: Level,
        _ message: String,
        context: [String: String],
        file: String,
        line: Int
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level.display,
            testName: testName,
            message: message,
            file: file,
            line: line,
            context: context
        )

        // Store entry
        entries.withLock { $0.append(entry) }

        // Console output via os_log
        os_log("%{public}@", log: osLog, type: osLogType(for: level), entry.formatted)

        // File output
        appendToFile(entry)
    }

    private func osLogType(for level: Level) -> OSLogType {
        switch level {
        case .trace, .debug: return .debug
        case .info, .step, .success: return .info
        case .warning: return .default
        case .error, .failure: return .error
        }
    }

    private func appendToFile(_ entry: LogEntry) {
        guard let url = logFileURL else { return }
        let line = entry.formatted + "\n"

        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: url)
        }
    }

    // MARK: - Summary

    /// Generate a summary of the test run
    func summary() -> String {
        let allEntries = entries.withLock { $0 }
        let errorCount = allEntries.filter {
            $0.level.contains("ERROR") || $0.level.contains("FAIL")
        }.count
        let stepCount = allEntries.filter { $0.level.contains("STEP") }.count
        let totalCount = allEntries.count

        return """
        ══════════════════════════════════════════════════════════
        TEST: \(testName)
        TOTAL LOGS: \(totalCount)
        STEPS: \(stepCount)
        ERRORS: \(errorCount)
        LOG FILE: \(logFileURL?.path ?? "none")
        ══════════════════════════════════════════════════════════
        """
    }

    /// Export all entries as JSON for CI analysis
    func exportJSON() -> Data? {
        let allEntries = entries.withLock { $0 }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(allEntries)
    }

    /// Get all log entries
    func allEntries() -> [LogEntry] {
        entries.withLock { $0 }
    }

    /// Get the log file URL if file logging is enabled
    var logFile: URL? { logFileURL }
}

// MARK: - LockedState

/// Wrapper for mutable state with lock-based synchronization.
/// Use this when you need shared mutable state in tests.
final class LockedState<T> {
    private var value: T
    private let lock = NSLock()

    init(_ value: T) {
        self.value = value
    }

    /// Execute a closure with exclusive access to the value
    func withLock<R>(_ body: (inout T) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }

    /// Read the current value (snapshot)
    var current: T {
        withLock { $0 }
    }
}
