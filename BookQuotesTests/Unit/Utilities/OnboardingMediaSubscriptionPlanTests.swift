import XCTest

@testable import BookQuotes

final class OnboardingMediaSubscriptionPlanTests: XCTestCase {
    func testMonthlyPlanCopy() {
        let plan = MediaSubscriptionPlan.monthly

        XCTAssertEqual(plan.title, "Monthly")
        XCTAssertEqual(plan.price, "$4.99")
        XCTAssertEqual(plan.subtitle, "Flexible access for regular readers")
        XCTAssertEqual(plan.period, "per month")
        XCTAssertNil(plan.badge)
    }

    func testYearlyPlanCopy() {
        let plan = MediaSubscriptionPlan.yearly

        XCTAssertEqual(plan.title, "Yearly")
        XCTAssertEqual(plan.price, "$39.99")
        XCTAssertEqual(plan.subtitle, "Best value for committed readers")
        XCTAssertEqual(plan.period, "per year")
        XCTAssertEqual(plan.badge, "Best Value")
    }

    func testPlanOrderKeepsMonthlyBeforeYearly() {
        XCTAssertEqual(MediaSubscriptionPlan.allCases, [.monthly, .yearly])
    }
}
