import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

final class ActivityMonitorExtension: DeviceActivityMonitor {
    private let store=ManagedSettingsStore()

    private func resetShield(for activity:DeviceActivityName,kind:String) {
        // Ignore stale callbacks from an earlier rules generation.
        guard SharedConfig.isActiveActivity(activity.rawValue) else { return }
        store.clearAllSettings()
        SharedConfig.defaults.removeObject(forKey:"reachedCategories")
        SharedConfig.defaults.set(false,forKey:SharedConfig.limitReachedKey)
        SharedConfig.recordMonitorEvent(kind)
    }

    override func intervalDidStart(for activity:DeviceActivityName) {
        super.intervalDidStart(for:activity)
        resetShield(for:activity,kind:"新周期开始，解除上日限制")
    }

    override func intervalDidEnd(for activity:DeviceActivityName) {
        super.intervalDidEnd(for:activity)
        resetShield(for:activity,kind:"今日监控周期结束")
    }

    override func eventDidReachThreshold(_ event:DeviceActivityEvent.Name,
                                         activity:DeviceActivityName) {
        super.eventDidReachThreshold(event,activity:activity)
        guard SharedConfig.isActiveActivity(activity.rawValue) else { return }
        let parts=event.rawValue.split(separator:".",omittingEmptySubsequences:false)
        guard parts.count==2,let index=Int(parts[1]),index>=0 else { return }
        let decoder=JSONDecoder()
        switch parts[0] {
        case "app":
            guard let raw=SharedConfig.defaults.data(forKey:"eventAppTokens"),
                  let tokens=try? decoder.decode([ApplicationToken].self,from:raw),
                  tokens.indices.contains(index) else { return }
            var already=store.shield.applications ?? Set<ApplicationToken>()
            already.insert(tokens[index])
            store.shield.applications=already
        case "category":
            guard let raw=SharedConfig.defaults.data(forKey:"eventCategoryTokens"),
                  let tokens=try? decoder.decode([ActivityCategoryToken].self,from:raw),
                  tokens.indices.contains(index) else { return }
            var reached=SharedConfig.defaults.array(forKey:"reachedCategories") as? [Int] ?? []
            if !reached.contains(index) { reached.append(index) }
            SharedConfig.defaults.set(reached,forKey:"reachedCategories")
            store.shield.applicationCategories = .specific(
                Set(reached.filter { tokens.indices.contains($0) }.map { tokens[$0] }))
        case "web":
            guard let raw=SharedConfig.defaults.data(forKey:"eventWebTokens"),
                  let tokens=try? decoder.decode([WebDomainToken].self,from:raw),
                  tokens.indices.contains(index) else { return }
            var already=store.shield.webDomains ?? Set<WebDomainToken>()
            already.insert(tokens[index])
            store.shield.webDomains=already
        default:
            return
        }
        SharedConfig.defaults.set(true,forKey:SharedConfig.limitReachedKey)
        SharedConfig.recordMonitorEvent("使用阈值达到：\(parts[0]) #\(index+1)")
    }
}
