import Foundation

enum SharedConfig {
    static let groupID = "group.de.claua.barapause"
    static var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }
    static var appGroupAvailable: Bool {
        groupDefaults != nil
    }
    // The standard store is used only for basic UI previews. Screen Time
    // monitoring must explicitly reject unavailable App Group access.
    static var defaults: UserDefaults {
        groupDefaults ?? .standard
    }
    static let activityName = "barapause.daily"
    static let thresholdName = "barapause.threshold"
    static let selectionKey = "screenTimeSelection"
    static let limitKey = "dailyLimitMinutes"
    static let focusEndKey = "focusEnd"
    static let widgetTargetKey = "favoriteTarget"
    static let limitReachedKey = "limitReached"
    static let searchHistoryKey = "searchHistory"

    static func focusRemaining(at date: Date = Date()) -> TimeInterval {
        max(0, defaults.double(forKey: focusEndKey) - date.timeIntervalSince1970)
    }
    static func startFocus(minutes: Int) {
        defaults.set(Date().addingTimeInterval(TimeInterval(max(5, min(minutes, 180)) * 60))
            .timeIntervalSince1970, forKey: focusEndKey)
    }
    static func endFocus() {
        defaults.removeObject(forKey: focusEndKey)
    }
}
