import Foundation
import UIKit
import XCTest

@testable import BookQuotes

final class HermeticHTTPServerIntegrationTests: XCTestCase {

    func testServer_RoutesAndLogsRequests_WithHeaderRedaction() async throws {
        let server = HermeticHTTPServer(redactHeaderNames: ["authorization"])
        server.route(method: "GET", path: "/hello") { req in
            XCTAssertEqual(req.method.uppercased(), "GET")
            XCTAssertEqual(req.path, "/hello")
            return .text(200, "world")
        }

        try await server.start()
        defer { server.stop() }

        var request = URLRequest(url: server.baseURL.appendingPathComponent("hello"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("Bearer secret-token", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), "world")

        let requests = server.allRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].path, "/hello")
        XCTAssertEqual(requests[0].headers["Authorization"], "<redacted>")
    }

    func testServer_UnknownRequest_ReturnsDiagnosticBody_AndRecords() async throws {
        let server = HermeticHTTPServer(failOnUnknownRequests: false)
        server.route(method: "GET", path: "/hello") { _ in
            return .text(200, "world")
        }

        try await server.start()
        defer { server.stop() }

        var request = URLRequest(url: server.baseURL.appendingPathComponent("nope"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 500)

        let body = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(body.contains("Unexpected request: GET /nope"))
        XCTAssertTrue(body.contains("Known routes"))
        XCTAssertTrue(body.contains("GET /hello"))

        let messages = server.allUnexpectedRequestMessages()
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].contains("Unexpected request: GET /nope"))
    }

    func testServer_ParsesRequestBody() async throws {
        let server = HermeticHTTPServer()
        server.route(method: "POST", path: "/echo") { req in
            return .text(200, String(data: req.body, encoding: .utf8) ?? "")
        }

        try await server.start()
        defer { server.stop() }

        var request = URLRequest(url: server.baseURL.appendingPathComponent("echo"))
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("ping".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), "ping")
    }

    func testGeminiService_CoverMetadata_UsesHermeticFixture() async throws {
        let server = HermeticHTTPServer(redactHeaderNames: ["authorization"])
        server.route(method: "POST", path: "/api/extract-cover") { _ in
            // NOTE: GeminiService expects the proxy to return Gemini's "text" field containing a JSON string.
            let coverJSONText =
                #"{"title":"The Letters of Private Wheeler","author":"B.H. Liddell Hart","subtitle":null,"publisher":null,"publishYear":null,"genre":null,"isbn":null,"confidence":0.92}"#

            let responseBody =
                #"{"candidates":[{"content":{"parts":[{"text":\#(String(reflecting: coverJSONText))}]}}]}"#

            return .json(200, Data(responseBody.utf8))
        }

        try await server.start()
        defer { server.stop() }

        // Use a real KeychainService instance but with a non-sensitive, test-only token.
        let keychain = KeychainService()
        keychain.setSessionToken("test-session-token")

        let auth = await MainActor.run { AuthService(keychainService: keychain) }
        defer { Task { await auth.signOut() } }

        let gemini = await MainActor.run { GeminiService(authService: auth, baseURL: server.baseURL) }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }

        let result = try await gemini.extractCoverMetadata(from: image)
        XCTAssertEqual(result.title, "The Letters of Private Wheeler")
        XCTAssertEqual(result.author, "B.H. Liddell Hart")
        XCTAssertEqual(result.confidence, 0.92, accuracy: 0.0001)

        let requests = server.allRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].path, "/api/extract-cover")
        XCTAssertEqual(requests[0].headers["Authorization"], "<redacted>")

        // Sanity check key pieces of the JSON request body without asserting the full prompt.
        let bodyObj = try JSONSerialization.jsonObject(with: requests[0].body) as? [String: Any]
        XCTAssertNotNil(bodyObj?["contents"])
        let generationConfig = bodyObj?["generationConfig"] as? [String: Any]
        XCTAssertEqual(generationConfig?["responseMimeType"] as? String, "application/json")
    }
}
