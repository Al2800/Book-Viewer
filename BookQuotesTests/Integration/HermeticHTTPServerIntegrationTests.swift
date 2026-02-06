import Foundation
import XCTest

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
}
