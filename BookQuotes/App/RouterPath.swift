import SwiftUI

/// Observable navigation path manager for programmatic navigation
@Observable
final class RouterPath {
    var path = NavigationPath()

    // MARK: - Navigation Actions

    /// Navigate to any hashable destination
    func navigate(to destination: any Hashable) {
        path.append(destination)
    }

    /// Go back one level
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Pop multiple levels
    func pop(count: Int) {
        let toRemove = min(count, path.count)
        path.removeLast(toRemove)
    }

    /// Return to root of navigation stack
    func popToRoot() {
        path = NavigationPath()
    }

    /// Check if we're at root level
    var isAtRoot: Bool {
        path.isEmpty
    }
}
