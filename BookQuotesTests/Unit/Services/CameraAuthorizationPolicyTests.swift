import AVFoundation
import XCTest

@testable import BookQuotes

final class CameraAuthorizationPolicyTests: XCTestCase {
    func testAuthorizedStatusAllowsCameraWithoutPrompting() {
        let decision = CameraAuthorizationPolicy.decision(for: .authorized)

        XCTAssertEqual(decision, .authorized)
        XCTAssertTrue(decision.isAuthorized)
        XCTAssertFalse(decision.shouldRequestAccess)
    }

    func testNotDeterminedStatusRequestsAccess() {
        let decision = CameraAuthorizationPolicy.decision(for: .notDetermined)

        XCTAssertEqual(decision, .needsRequest)
        XCTAssertFalse(decision.isAuthorized)
        XCTAssertTrue(decision.shouldRequestAccess)
    }

    func testDeniedAndRestrictedStatusesDenyCameraWithoutPrompting() {
        for status in [AVAuthorizationStatus.denied, .restricted] {
            let decision = CameraAuthorizationPolicy.decision(for: status)

            XCTAssertEqual(decision, .denied)
            XCTAssertFalse(decision.isAuthorized)
            XCTAssertFalse(decision.shouldRequestAccess)
        }
    }

    func testPermissionStatusMappingPreservesDeniedAndRestrictedDistinction() {
        XCTAssertEqual(CameraAuthorizationPolicy.permissionStatus(for: .authorized), .authorized)
        XCTAssertEqual(CameraAuthorizationPolicy.permissionStatus(for: .notDetermined), .notDetermined)
        XCTAssertEqual(CameraAuthorizationPolicy.permissionStatus(for: .denied), .denied)
        XCTAssertEqual(CameraAuthorizationPolicy.permissionStatus(for: .restricted), .restricted)
    }
}
