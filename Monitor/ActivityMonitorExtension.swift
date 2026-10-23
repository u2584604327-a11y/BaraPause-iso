import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Invoked by the OS after an actual usage threshold is reached.
final class ActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("barapause"))
    private let tracked = DeviceActivityName("barapause.daily")
    private let thresholdName = DeviceActivityEvent.Name("barapause.limit")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity == tracked else { return }
        clearShields()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard activity == tracked, event == thresholdName else { return }
        guard let data = BaraStore.selectionData,
              let selected = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        store.shield.applications = selected.applicationTokens.isEmpty ? nil : selected.applicationTokens
        store.shield.applicationCategories = selected.categoryTokens.isEmpty
            ? nil : .specific(selected.categoryTokens)
        store.shield.webDomains = selected.webDomainTokens.isEmpty ? nil : selected.webDomainTokens
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == tracked else { return }
        clearShields()
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
