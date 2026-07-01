import Foundation

struct CaptureQueueProcessingPreferences {
    static let autoProcessQueueKey = "autoProcessQueue"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isAutoProcessEnabled: Bool {
        if userDefaults.object(forKey: Self.autoProcessQueueKey) == nil {
            return true
        }

        return userDefaults.bool(forKey: Self.autoProcessQueueKey)
    }
}
