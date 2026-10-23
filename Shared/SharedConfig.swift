import Foundation

enum SharedConfig {
    static let groupID = "group.de.claua.barapause"
    static var groupDefaults: UserDefaults? { UserDefaults(suiteName: groupID) }
    static var appGroupAvailable: Bool {
        groupDefaults != nil &&
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:groupID) != nil
    }

    // Local preview features may use standard defaults; Screen Time never may.
    static var defaults: UserDefaults { groupDefaults ?? .standard }

    static let legacyActivityName = "barapause.daily"
    static let activityPrefix = "barapause.daily."
    static let selectionKey = "screenTimeSelection"
    static let limitKey = "dailyLimitMinutes"
    static let appliedLimitKey = "registeredLimitMinutes"
    static let focusEndKey = "focusEnd"
    static let limitReachedKey = "limitReached"
    static let searchHistoryKey = "searchHistory"
    static let activeActivityKey = "activeActivityName"
    static let monitorEnabledKey = "monitorEnabled"
    static let generationKey = "monitorGeneration"
    static let lastEventKey = "lastMonitorEvent"
    static let lastEventAtKey = "lastMonitorEventAt"

    static var activeActivityName: String {
        defaults.string(forKey: activeActivityKey) ?? ""
    }
    static func ownsActivity(_ raw: String) -> Bool {
        raw == legacyActivityName || raw.hasPrefix(activityPrefix)
    }
    static func isActiveActivity(_ raw: String) -> Bool {
        defaults.bool(forKey: monitorEnabledKey) &&
        !activeActivityName.isEmpty &&
        raw == activeActivityName
    }
    static func recordMonitorEvent(_ value: String, at date: Date = Date()) {
        guard let shared=groupDefaults else { return }
        shared.set(String(value.prefix(120)), forKey: lastEventKey)
        shared.set(date.timeIntervalSince1970, forKey: lastEventAtKey)
    }
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
