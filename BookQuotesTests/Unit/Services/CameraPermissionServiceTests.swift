import XCTest

@testable import BookQuotes

// MARK: - CameraPermissionServiceTests

final class CameraPermissionServiceTests: XCTestCase {

    func testPermissionStatusDescriptions() {
        XCTAssertEqual(CameraPermissionService.PermissionStatus.notDetermined.description, "Camera permission not yet requested")
        XCTAssertEqual(CameraPermissionService.PermissionStatus.authorized.description, "Camera access authorized")
        XCTAssertEqual(CameraPermissionService.PermissionStatus.denied.description, "Camera access denied by user")
        XCTAssertEqual(CameraPermissionService.PermissionStatus.restricted.description, "Camera access restricted by system")
    }

    func testPermissionStatusIcons() {
        XCTAssertEqual(CameraPermissionService.PermissionStatus.notDetermined.icon, "questionmark.circle")
        XCTAssertEqual(CameraPermissionService.PermissionStatus.authorized.icon, "checkmark.circle.fill")
        XCTAssertEqual(CameraPermissionService.PermissionStatus.denied.icon, "xmark.circle.fill")
        XCTAssertEqual(CameraPermissionService.PermissionStatus.restricted.icon, "lock.circle.fill")
    }
}
