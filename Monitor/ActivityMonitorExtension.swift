import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

final class ActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    private func clearShields() {
        store.clearAllSettings()
        SharedConfig.defaults.set(false,forKey: SharedConfig.limitReachedKey)
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for:activity)
        guard activity.rawValue == SharedConfig.activityName else { return }
        clearShields()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for:activity)
        guard activity.rawValue == SharedConfig.activityName else { return }
        clearShields()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event,activity:activity)
        guard activity.rawValue == SharedConfig.activityName,
              event.rawValue == SharedConfig.thresholdName,
              SharedConfig.defaults.bool(forKey:"monitorEnabled"),
              let data = SharedConfig.defaults.data(forKey: SharedConfig.selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self,from:data)
        else { return }
        // Only the explicitly selected targets are shielded. Empty selection never
        // means all apps because we refuse to begin monitoring with zero selections.
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
        SharedConfig.defaults.set(true,forKey: SharedConfig.limitReachedKey)
    }
}
