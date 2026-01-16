import Foundation
import UIKit

// MARK: - UI Test Logger

/// Structured logger for UI tests with step tracking and summary.
final class UITestLogger {

    // MARK: - Properties

    private let testName: String
    private let startTime: Date
    private var entries: [LogEntry] = []
    private var currentStepNumber = 0
    private var lastStepTime: Date?
    private let onCheckpoint: ((Int, String) -> Void)?

    // MARK: - Initialization

    init(testName: String, onCheckpoint: ((Int, String) -> Void)? = nil) {
        self.testName = testName
        self.startTime = Date()
        self.onCheckpoint = onCheckpoint
        info("Test started")
        info("Device: \(deviceSummary)")
        info("Locale: \(localeSummary)")
    }

    // MARK: - Logging Methods

    /// Log a numbered step in the test flow.
    func step(_ number: Int, _ message: String) {
        currentStepNumber = number
        let now = Date()
        let delta = now.timeIntervalSince(lastStepTime ?? startTime)
        lastStepTime = now
        log(.step, "STEP \(number): \(message) (+\(String(format: "%.2fs", delta)))")
        onCheckpoint?(number, message)
    }

    /// Log an informational message.
    func info(_ message: String) {
        log(.info, message)
    }

    /// Log a success message.
    func success(_ message: String) {
        log(.success, "✓ \(message)")
    }

    /// Log a warning message.
    func warning(_ message: String) {
        log(.warning, "⚠️ \(message)")
    }

    /// Log an error message.
    func error(_ message: String) {
        log(.error, "✗ \(message)")
    }

    /// Log a debug message (only printed in verbose mode).
    func debug(_ message: String) {
        log(.debug, message, printToConsole: ProcessInfo.processInfo.environment["VERBOSE_UI_TESTS"] != nil)
    }

    // MARK: - Summary

    /// Generate a formatted summary of the test run.
    func summary() -> String {
        let duration = Date().timeIntervalSince(startTime)
        let formattedDuration = String(format: "%.2fs", duration)

        var lines: [String] = []
        lines.append("═══════════════════════════════════════")
        lines.append("Test: \(testName)")
        lines.append("Duration: \(formattedDuration)")
        lines.append("Steps completed: \(currentStepNumber)")
        lines.append("Device: \(deviceSummary)")
        lines.append("Locale: \(localeSummary)")
        lines.append("───────────────────────────────────────")

        for entry in entries {
            lines.append(entry.formatted)
        }

        lines.append("═══════════════════════════════════════")

        return lines.joined(separator: "\n")
    }

    /// Write summary to a file in the temp directory.
    func writeSummaryToFile() {
        let fileManager = FileManager.default
        let logDir = artifactsDirectory.appendingPathComponent("logs", isDirectory: true)

        do {
            try fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)

            let fileName = "\(sanitizedTestName).log"
            let fileURL = logDir.appendingPathComponent(fileName)

            let summaryText = summary()
            try summaryText.write(to: fileURL, atomically: true, encoding: .utf8)

            print("📁 Log written to: \(fileURL.path)")

            let jsonURL = logDir.appendingPathComponent("\(sanitizedTestName).json")
            let jsonData = try JSONEncoder().encode(entries.map { $0.serialized })
            try jsonData.write(to: jsonURL, options: .atomic)
            print("📁 JSON log written to: \(jsonURL.path)")
        } catch {
            print("⚠️ Failed to write log file: \(error)")
        }
    }

    // MARK: - Private Methods

    private func log(_ level: LogLevel, _ message: String, printToConsole: Bool = true) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message
        )
        entries.append(entry)

        if printToConsole {
            print(entry.formatted)
        }
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private var sanitizedTestName: String {
        testName
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    private var deviceSummary: String {
        let device = UIDevice.current
        return "\(device.model) \(device.systemName) \(device.systemVersion)"
    }

    private var localeSummary: String {
        let locale = Locale.current.identifier
        let timeZone = TimeZone.current.identifier
        return "\(locale) (\(timeZone))"
    }

    private var artifactsDirectory: URL {
        if let customPath = ProcessInfo.processInfo.environment["UI_TEST_ARTIFACTS_DIR"] {
            return URL(fileURLWithPath: customPath, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("BookQuotesUITests", isDirectory: true)
    }
}

// MARK: - Log Entry

private struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let message: String

    var formatted: String {
        let timeString = ISO8601DateFormatter().string(from: timestamp)
        return "[\(timeString)] [\(level.rawValue)] \(message)"
    }

    var serialized: SerializedLogEntry {
        SerializedLogEntry(
            timestamp: ISO8601DateFormatter().string(from: timestamp),
            level: level.rawValue,
            message: message
        )
    }
}

private struct SerializedLogEntry: Codable {
    let timestamp: String
    let level: String
    let message: String
}

// MARK: - Log Level

private enum LogLevel: String {
    case step = "STEP"
    case info = "INFO"
    case success = "PASS"
    case warning = "WARN"
    case error = "FAIL"
    case debug = "DEBUG"
}
