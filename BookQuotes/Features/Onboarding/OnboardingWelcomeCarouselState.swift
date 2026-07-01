import Foundation

enum OnboardingWelcomeCarouselAction: Equatable {
    case showNextPage
    case complete
}

struct OnboardingWelcomeCarouselState: Equatable {
    var currentPage: Int
    let pageCount: Int

    init(
        currentPage: Int = 0,
        pageCount: Int
    ) {
        self.currentPage = currentPage
        self.pageCount = max(pageCount, 1)
    }

    var isLastPage: Bool {
        currentPage >= pageCount - 1
    }

    var showsSkipButton: Bool {
        !isLastPage
    }

    var primaryButtonTitle: String {
        isLastPage ? "Get Started" : "Continue"
    }

    mutating func advance() -> OnboardingWelcomeCarouselAction {
        guard !isLastPage else {
            return .complete
        }

        currentPage += 1
        return .showNextPage
    }
}
