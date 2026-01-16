import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - CaptureSessionTests

@MainActor
final class CaptureSessionTests: SwiftDataTestCase {

    func testAddCaptureUpdatesCounts() throws {
        logger.step(1, "Creating session")
        let session = CaptureSession()

        logger.step(2, "Adding capture")
        let capture = TestFixtures.pageCapture { builder in
            builder.session = session
        }
        session.addCapture(capture)

        logger.step(3, "Validating counts")
        XCTAssertEqual(session.totalPages, 1)
        XCTAssertEqual(session.processedPages, 0)
        XCTAssertEqual(session.failedPages, 0)
        XCTAssertEqual(session.pendingPages, 1)
        XCTAssertEqual(session.captures.first?.orderIndex, 0)

        logger.success("Session counts update")
    }

    func testProcessingFlowCompletesSuccessfully() throws {
        logger.step(1, "Creating session with capture")
        let session = CaptureSession()
        session.addCapture(TestFixtures.pageCapture())

        logger.step(2, "Finishing capture")
        session.finishCapturing()
        XCTAssertEqual(session.status, .readyToProcess)

        logger.step(3, "Processing")
        session.beginProcessing()
        session.recordSuccess()

        logger.step(4, "Validating completion")
        XCTAssertEqual(session.status, .completed)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.progress, 1.0)
        XCTAssertNotNil(session.dateCompleted)

        logger.success("Session completes successfully")
    }

    func testProcessingFlowHandlesFailure() throws {
        logger.step(1, "Creating session with capture")
        let session = CaptureSession()
        session.addCapture(TestFixtures.pageCapture())
        session.finishCapturing()
        session.beginProcessing()

        logger.step(2, "Recording failure")
        session.recordFailure()

        logger.step(3, "Validating failure state")
        XCTAssertEqual(session.status, .partialFailure)
        XCTAssertTrue(session.hasFailures)
        XCTAssertTrue(session.isComplete)

        logger.success("Session failure captured")
    }

    func testCancelSetsCompletion() throws {
        let session = CaptureSession()
        session.cancel()
        XCTAssertEqual(session.status, .cancelled)
        XCTAssertNotNil(session.dateCompleted)
        logger.success("Session cancel sets completed")
    }
}
