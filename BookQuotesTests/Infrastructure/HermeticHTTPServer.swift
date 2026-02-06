import Foundation
import Dispatch
import Darwin
import XCTest

/// A tiny in-process HTTP/1.1 server intended for integration tests.
///
/// Goals:
/// - Runs offline on localhost with an ephemeral port.
/// - Deterministic routing (method + path).
/// - Captures a request log for assertions and debugging.
///
/// Non-goals:
/// - Full HTTP spec compliance.
/// - Streaming bodies / chunked transfer encoding.
final class HermeticHTTPServer {

    struct Request: Sendable {
        let method: String
        let path: String
        let query: String?
        let headers: [String: String]
        let body: Data
    }

    struct Response: Sendable {
        let statusCode: Int
        let headers: [String: String]
        let body: Data

        static func json(_ statusCode: Int = 200, _ json: Data) -> Response {
            Response(
                statusCode: statusCode,
                headers: ["Content-Type": "application/json"],
                body: json
            )
        }

        static func text(_ statusCode: Int = 200, _ text: String) -> Response {
            Response(
                statusCode: statusCode,
                headers: ["Content-Type": "text/plain; charset=utf-8"],
                body: Data(text.utf8)
            )
        }
    }

    typealias Handler = @Sendable (Request) -> Response

    private struct RouteKey: Hashable {
        let method: String
        let path: String
    }

    private let routes = LockedState<[RouteKey: Handler]>([:])
    private let requestsLog = LockedState<[Request]>([])
    private let unexpectedRequestMessages = LockedState<[String]>([])
    private let structuredLogLines = LockedState<[String]>([])

    private let redactHeaderNames: Set<String>
    private let failOnUnknownRequests: Bool
    private let queue = DispatchQueue(label: "HermeticHTTPServer.queue")
    private let queueKey = DispatchSpecificKey<Bool>()

    private var listenFD: Int32 = -1
    private var listenSource: DispatchSourceRead?
    private let clients = LockedState<[Int32: ClientHandler]>([:])
    private(set) var port: UInt16?

    init(
        redactHeaderNames: Set<String> = ["authorization", "cookie"],
        failOnUnknownRequests: Bool = true
    ) {
        self.redactHeaderNames = Set(redactHeaderNames.map { $0.lowercased() })
        self.failOnUnknownRequests = failOnUnknownRequests
        self.queue.setSpecific(key: queueKey, value: true)
    }

    var baseURL: URL {
        guard let port else {
            return URL(string: "http://127.0.0.1:0")!
        }
        return URL(string: "http://127.0.0.1:\(port)")!
    }

    func route(method: String, path: String, handler: @escaping Handler) {
        let key = RouteKey(method: method.uppercased(), path: Self.normalizePath(path))
        routes.withLock { $0[key] = handler }
    }

    func allRequests() -> [Request] {
        requestsLog.current
    }

    func allUnexpectedRequestMessages() -> [String] {
        unexpectedRequestMessages.current
    }

    /// Structured logs, one JSON object per line, suitable for saving as a CI artifact.
    func allStructuredLogLines() -> [String] {
        structuredLogLines.current
    }

    func resetRequests() {
        requestsLog.withLock { $0.removeAll(keepingCapacity: true) }
    }

    func resetUnexpectedRequests() {
        unexpectedRequestMessages.withLock { $0.removeAll(keepingCapacity: true) }
    }

    func resetStructuredLogs() {
        structuredLogLines.withLock { $0.removeAll(keepingCapacity: true) }
    }

    func start() async throws {
        if listenSource != nil { return }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    cont.resume(throwing: NSError(domain: "HermeticHTTPServer", code: 1))
                    return
                }

                do {
                    try self.startLocked()
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        let stopLocked = { [self] in
            self.listenSource?.cancel()
            self.listenSource = nil

            if self.listenFD >= 0 {
                Darwin.close(self.listenFD)
                self.listenFD = -1
            }

            self.clients.withLock { clients in
                for (_, c) in clients {
                    c.stop()
                }
                clients.removeAll()
            }

            self.port = nil
        }

        if DispatchQueue.getSpecific(key: queueKey) == true {
            stopLocked()
        } else {
            queue.sync(execute: stopLocked)
        }
    }

    // MARK: - Internals

    private func startLocked() throws {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw POSIXError(.EBADF)
        }

        var yes: Int32 = 1
        _ = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))

        // Non-blocking accept loop.
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(0).bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            let err = errno
            Darwin.close(fd)
            throw POSIXError(POSIXError.Code(rawValue: err) ?? .EINVAL)
        }

        guard listen(fd, 128) == 0 else {
            let err = errno
            Darwin.close(fd)
            throw POSIXError(POSIXError.Code(rawValue: err) ?? .EINVAL)
        }

        // Resolve ephemeral port.
        var bound = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &bound) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(fd, $0, &len)
            }
        }
        guard nameResult == 0 else {
            let err = errno
            Darwin.close(fd)
            throw POSIXError(POSIXError.Code(rawValue: err) ?? .EINVAL)
        }

        listenFD = fd
        port = UInt16(bigEndian: bound.sin_port)

        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        listenSource = source
        source.setEventHandler { [weak self] in
            self?.acceptLoop()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.listenFD >= 0 {
                Darwin.close(self.listenFD)
                self.listenFD = -1
            }
        }
        source.resume()
    }

    private func acceptLoop() {
        while true {
            var addr = sockaddr()
            var len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
            let clientFD = accept(listenFD, &addr, &len)
            if clientFD < 0 {
                if errno == EWOULDBLOCK || errno == EAGAIN {
                    return
                }
                return
            }

            let flags = fcntl(clientFD, F_GETFL, 0)
            _ = fcntl(clientFD, F_SETFL, flags | O_NONBLOCK)

            let client = ClientHandler(fd: clientFD, queue: queue) { [weak self] request in
                guard let self else {
                    return Response.text(503, "server stopped")
                }
                self.requestsLog.withLock { $0.append(self.redact(request: request)) }
                return self.dispatch(request)
            } onClose: { [weak self] fd in
                self?.clients.withLock { $0.removeValue(forKey: fd) }
            }

            clients.withLock { $0[clientFD] = client }
            client.start()
        }
    }

    private func dispatch(_ request: Request) -> Response {
        let key = RouteKey(method: request.method.uppercased(), path: Self.normalizePath(request.path))
        let handler = routes.withLock { $0[key] }
        let started = CFAbsoluteTimeGetCurrent()

        let response: Response
        let matchedRoute: Bool

        if let handler {
            matchedRoute = true
            response = handler(request)
        } else {
            matchedRoute = false

            let message = unexpectedRequestDiagnostic(for: request)
            unexpectedRequestMessages.withLock { $0.append(message) }

            if failOnUnknownRequests {
                XCTFail(message)
            }

            // 500 is intentional: this is a test-time contract violation, not a real 404.
            response = Response.text(500, message)
        }

        let durationMs = Int(((CFAbsoluteTimeGetCurrent() - started) * 1000.0).rounded())
        let redactedRequest = redact(request: request)
        let redactedResponseHeaders = redact(headers: response.headers)

        structuredLogLines.withLock { logs in
            logs.append(
                Self.formatStructuredLogLine(
                    request: redactedRequest,
                    responseStatus: response.statusCode,
                    responseHeaders: redactedResponseHeaders,
                    responseBodyBytes: response.body.count,
                    matchedRoute: matchedRoute,
                    durationMs: durationMs
                )
            )
        }

        return response
    }

    private func redact(request: Request) -> Request {
        let headers = redact(headers: request.headers)
        return Request(
            method: request.method,
            path: request.path,
            query: request.query,
            headers: headers,
            body: request.body
        )
    }

    private func redact(headers: [String: String]) -> [String: String] {
        var redacted = headers
        for (k, _) in redacted {
            if redactHeaderNames.contains(k.lowercased()) {
                redacted[k] = "<redacted>"
            }
        }
        return redacted
    }

    private func unexpectedRequestDiagnostic(for request: Request) -> String {
        let redacted = redact(request: request)

        let querySuffix: String
        if let q = redacted.query, !q.isEmpty {
            querySuffix = "?\(q)"
        } else {
            querySuffix = ""
        }

        let knownRoutes: [String] = routes.withLock { dict in
            dict.keys
                .map { "\($0.method) \($0.path)" }
                .sorted()
        }

        var lines: [String] = []
        lines.append("Unexpected request: \(redacted.method) \(redacted.path)\(querySuffix)")
        lines.append("Known routes (\(knownRoutes.count)):")
        if knownRoutes.isEmpty {
            lines.append("  <none>")
        } else {
            for route in knownRoutes {
                lines.append("  - \(route)")
            }
        }

        let headerPairs = redacted.headers.sorted { $0.key.lowercased() < $1.key.lowercased() }
        lines.append("Headers (\(headerPairs.count)):")
        if headerPairs.isEmpty {
            lines.append("  <none>")
        } else {
            for (k, v) in headerPairs {
                lines.append("  - \(k): \(v)")
            }
        }

        if redacted.body.isEmpty {
            lines.append("Body: <empty>")
        } else if let utf8 = String(data: redacted.body, encoding: .utf8) {
            // If it's JSON, try to pretty print for better diffs.
            if
                let obj = try? JSONSerialization.jsonObject(with: redacted.body),
                let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
                let prettyString = String(data: pretty, encoding: .utf8)
            {
                lines.append("Body (json, \(redacted.body.count) bytes):")
                lines.append(prettyString)
            } else {
                lines.append("Body (utf8, \(redacted.body.count) bytes):")
                lines.append(utf8)
            }
        } else {
            lines.append("Body (base64, \(redacted.body.count) bytes):")
            lines.append(redacted.body.base64EncodedString())
        }

        return lines.joined(separator: "\n")
    }

    private static func normalizePath(_ path: String) -> String {
        if path.isEmpty { return "/" }
        return path.hasPrefix("/") ? path : "/" + path
    }

    private static func formatStructuredLogLine(
        request: Request,
        responseStatus: Int,
        responseHeaders: [String: String],
        responseBodyBytes: Int,
        matchedRoute: Bool,
        durationMs: Int
    ) -> String {
        // Keep values small and stable; avoid copying the full request/response bodies into logs.
        var obj: [String: Any] = [
            "type": "hermetic_http",
            "method": request.method.uppercased(),
            "path": request.path,
            "query": request.query ?? "",
            "matched_route": matchedRoute,
            "status": responseStatus,
            "duration_ms": durationMs,
            "request_body_bytes": request.body.count,
            "response_body_bytes": responseBodyBytes,
            "request_headers": request.headers,
            "response_headers": responseHeaders
        ]

        if let keys = jsonTopLevelKeys(from: request.body) {
            obj["request_json_keys"] = keys
        }

        // Response keys are sometimes useful, but only attempt if the content-type is JSON.
        // (We do not have the response body in this method, just size; keys are omitted intentionally.)

        let data = (try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func jsonTopLevelKeys(from data: Data) -> [String]? {
        guard !data.isEmpty else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let dict = obj as? [String: Any] {
            return dict.keys.sorted()
        }
        return nil
    }
}

private final class ClientHandler {
    private let fd: Int32
    private let queue: DispatchQueue
    private let onRequest: (HermeticHTTPServer.Request) -> HermeticHTTPServer.Response
    private let onClose: (Int32) -> Void

    private var buffer = Data()
    private var source: DispatchSourceRead?

    init(
        fd: Int32,
        queue: DispatchQueue,
        onRequest: @escaping (HermeticHTTPServer.Request) -> HermeticHTTPServer.Response,
        onClose: @escaping (Int32) -> Void
    ) {
        self.fd = fd
        self.queue = queue
        self.onRequest = onRequest
        self.onClose = onClose
    }

    func start() {
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        self.source = source
        source.setEventHandler { [weak self] in
            self?.readAvailable()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            Darwin.close(self.fd)
            self.onClose(self.fd)
        }
        source.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    private func readAvailable() {
        var tmp = [UInt8](repeating: 0, count: 16 * 1024)
        while true {
            let n = read(fd, &tmp, tmp.count)
            if n > 0 {
                buffer.append(contentsOf: tmp[0..<n])
                if let request = tryParseRequest(from: buffer) {
                    let response = onRequest(request)
                    sendAndClose(response)
                    return
                }
                continue
            }

            if n == 0 {
                sendAndClose(HermeticHTTPServer.Response.text(400, "incomplete request"))
                return
            }

            // n < 0
            if errno == EWOULDBLOCK || errno == EAGAIN {
                return
            }
            sendAndClose(HermeticHTTPServer.Response.text(500, "read error: \(errno)"))
            return
        }
    }

    private func sendAndClose(_ response: HermeticHTTPServer.Response) {
        let data = Self.serialize(response: response)
        data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return }
            var remaining = raw.count
            var offset = 0
            while remaining > 0 {
                let written = write(fd, base.advanced(by: offset), remaining)
                if written > 0 {
                    remaining -= written
                    offset += written
                    continue
                }
                if written < 0 && (errno == EWOULDBLOCK || errno == EAGAIN) {
                    // Best-effort: if the socket is blocked, bail and close.
                    break
                }
                break
            }
        }
        stop()
    }

    private func tryParseRequest(from data: Data) -> HermeticHTTPServer.Request? {
        guard let headerEndRange = data.range(of: Data("\r\n\r\n".utf8)) else {
            return nil
        }

        let headerData = data[..<headerEndRange.lowerBound]
        guard let headerText = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        var lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first, !requestLine.isEmpty else { return nil }
        lines.removeFirst()

        let parts = requestLine.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0])
        let rawTarget = String(parts[1])
        let targetParts = rawTarget.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let path = String(targetParts.first ?? "/")
        let query = targetParts.count > 1 ? String(targetParts[1]) : nil

        var headers: [String: String] = [:]
        for line in lines {
            if line.isEmpty { continue }
            if let idx = line.firstIndex(of: ":") {
                let name = line[..<idx].trimmingCharacters(in: .whitespaces)
                let value = line[line.index(after: idx)...].trimmingCharacters(in: .whitespaces)
                headers[name] = value
            }
        }

        let bodyStart = headerEndRange.upperBound
        let contentLength = Int(headers["Content-Length"] ?? "") ?? 0
        let totalLength = bodyStart + contentLength
        guard data.count >= totalLength else { return nil }

        let body = contentLength > 0 ? data[bodyStart..<totalLength] : Data()

        return HermeticHTTPServer.Request(
            method: method,
            path: path,
            query: query,
            headers: headers,
            body: Data(body)
        )
    }

    private static func serialize(response: HermeticHTTPServer.Response) -> Data {
        var headers = response.headers
        headers["Content-Length"] = "\(response.body.count)"
        headers["Connection"] = "close"
        if headers["Content-Type"] == nil {
            headers["Content-Type"] = "application/octet-stream"
        }

        let reason = reasonPhrase(for: response.statusCode)
        var head = "HTTP/1.1 \(response.statusCode) \(reason)\r\n"
        for (k, v) in headers {
            head += "\(k): \(v)\r\n"
        }
        head += "\r\n"

        var data = Data(head.utf8)
        data.append(response.body)
        return data
    }

    private static func reasonPhrase(for statusCode: Int) -> String {
        switch statusCode {
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 409: return "Conflict"
        case 429: return "Too Many Requests"
        case 500: return "Internal Server Error"
        case 503: return "Service Unavailable"
        default: return "HTTP"
        }
    }
}
