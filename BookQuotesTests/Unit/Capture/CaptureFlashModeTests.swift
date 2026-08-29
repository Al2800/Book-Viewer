import AVFoundation
import XCTest

@testable import BookQuotes

final class CaptureFlashModeTests: XCTestCase {

    func testCyclesAutoOnOffBackToAuto() {
        XCTAssertEqual(CaptureFlashMode.auto.next, .on)
        XCTAssertEqual(CaptureFlashMode.on.next, .off)
        XCTAssertEqual(CaptureFlashMode.off.next, .auto)
    }

    func testUsesExistingSystemImages() {
        XCTAssertEqual(CaptureFlashMode.auto.icon, "bolt.badge.automatic")
        XCTAssertEqual(CaptureFlashMode.on.icon, "bolt.fill")
        XCTAssertEqual(CaptureFlashMode.off.icon, "bolt.slash")
    }

    func testAccessibilityLabelsDescribeEachMode() {
        XCTAssertEqual(CaptureFlashMode.auto.accessibilityLabel, "Flash automatic")
        XCTAssertEqual(CaptureFlashMode.on.accessibilityLabel, "Flash on")
        XCTAssertEqual(CaptureFlashMode.off.accessibilityLabel, "Flash off")
    }

    func testMapsToAVFoundationFlashModes() {
        XCTAssertEqual(CaptureFlashMode.auto.avFoundationMode, .auto)
        XCTAssertEqual(CaptureFlashMode.on.avFoundationMode, .on)
        XCTAssertEqual(CaptureFlashMode.off.avFoundationMode, .off)
    }
}
