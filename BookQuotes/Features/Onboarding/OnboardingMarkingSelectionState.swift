import Foundation

struct OnboardingMarkingSelectionState: Equatable {
    private(set) var selectedStyles: Set<MarkingType>

    init(selectedStyles: Set<MarkingType> = [.underline, .highlight]) {
        self.selectedStyles = selectedStyles
    }

    func isSelected(_ type: MarkingType) -> Bool {
        selectedStyles.contains(type)
    }

    mutating func toggle(_ type: MarkingType) {
        if selectedStyles.contains(type) {
            selectedStyles.remove(type)
        } else {
            selectedStyles.insert(type)
        }
    }
}
