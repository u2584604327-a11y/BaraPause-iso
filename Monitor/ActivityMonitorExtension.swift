import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

final class ActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    private func clearShields() {
        store.clearAllSettings()
        SharedConfig.defaults.removeObject(forKey:"reachedCategories")
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
              SharedConfig.defaults.bool(forKey:"monitorEnabled") else { return }
        let parts=event.rawValue.split(separator:".",omittingEmptySubsequences:false)
        guard parts.count==2,let index=Int(parts[1]),index >= 0 else { return }
        let decoder=JSONDecoder()
        switch parts[0] {
        case "app":
            guard let data=SharedConfig.defaults.data(forKey:"eventAppTokens"),
                  let tokens=try? decoder.decode([ApplicationToken].self,from:data),
                  tokens.indices.contains(index) else { return }
            var shielded=store.shield.applications ?? Set<ApplicationToken>()
            shielded.insert(tokens[index])
            store.shield.applications=shielded
        case "category":
            guard let data=SharedConfig.defaults.data(forKey:"eventCategoryTokens"),
                  let tokens=try? decoder.decode([ActivityCategoryToken].self,from:data),
                  tokens.indices.contains(index) else { return }
            // Apply only the reached category; tracking this separately from apps.
            var reached=SharedConfig.defaults.array(forKey:"reachedCategories") as? [Int] ?? []
            if !reached.contains(index) { reached.append(index) }
            SharedConfig.defaults.set(reached,forKey:"reachedCategories")
            store.shield.applicationCategories = .specific(
                Set(reached.filter { tokens.indices.contains($0) }.map { tokens[$0] }))
        case "web":
            guard let data=SharedConfig.defaults.data(forKey:"eventWebTokens"),
                  let tokens=try? decoder.decode([WebDomainToken].self,from:data),
                  tokens.indices.contains(index) else { return }
            var shielded=store.shield.webDomains ?? Set<WebDomainToken>()
            shielded.insert(tokens[index])
            store.shield.webDomains=shielded
        default:
            return
        }
        SharedConfig.defaults.set(true,forKey:SharedConfig.limitReachedKey)
    }
}
