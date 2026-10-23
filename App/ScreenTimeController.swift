import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
final class ScreenTimeController: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var authorized = false
    @Published var errorMessage: String?
    @Published var monitoring = false
    @Published var needsRecovery = false
    @Published var limitMinutes = 20

    private let center = DeviceActivityCenter()
    private let activity = DeviceActivityName(SharedConfig.activityName)

    init() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        let stored = SharedConfig.defaults.integer(forKey: SharedConfig.limitKey)
        limitMinutes = stored > 0 ? min(stored,240) : 20
        if let active=ProfileLibrary.current().selectionData,
           let decoded=try? JSONDecoder().decode(FamilyActivitySelection.self,from:active) {
            selection = decoded
        } else if let data=SharedConfig.defaults.data(forKey:SharedConfig.selectionKey),
                  let decoded=try? JSONDecoder().decode(FamilyActivitySelection.self,from:data) {
            selection=decoded
        }
        let activeProfile=ProfileLibrary.current()
        limitMinutes=max(1,min(240,activeProfile.dailyMinutes))
        refreshStatus()
    }

    func refreshStatus() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        let scheduled = center.activities.contains(activity)
        monitoring = authorized && scheduled
        needsRecovery = SharedConfig.defaults.bool(forKey:"monitorEnabled") && (!scheduled || !authorized)
    }

    func restoreMonitoringIfRequested() {
        guard needsRecovery else { return }
        // User action only. No silent recovery when authorization was revoked.
        enableDailyLimit()
    }

    func storeActiveProfile() -> Bool {
        ProfileLibrary.saveCurrent(selection:selection,minutes:limitMinutes)
    }

    func switchProfile(to id:UUID) {
        errorMessage=nil
        guard let next=ProfileLibrary.named(id),id != ProfileLibrary.activeID() else {return}
        guard storeActiveProfile() else {
            errorMessage="无法保存当前存档，切换已取消。"
            return
        }
        let wasRunning=monitoring
        if wasRunning { disableDailyLimit() }
        let old=ProfileLibrary.current()
        selection=ProfileLibrary.decodedSelection(next)
        limitMinutes=next.dailyMinutes
        guard ProfileLibrary.activate(id) else {
            selection=ProfileLibrary.decodedSelection(old)
            limitMinutes=old.dailyMinutes
            if wasRunning { enableDailyLimit() }
            errorMessage="无法切换存档，已恢复旧规则。"
            return
        }
        if let language=next.language,
           ["system","zh-Hans","zh-Hant","en","ja"].contains(language) {
            SharedConfig.defaults.set(language,forKey:"language")
        }
        if let theme=next.theme,
           ["system","light","dark","eye"].contains(theme) {
            SharedConfig.defaults.set(theme,forKey:"theme")
        }
        SharedConfig.defaults.set(next.selectionData,forKey:SharedConfig.selectionKey)
        SharedConfig.defaults.set(next.dailyMinutes,forKey:SharedConfig.limitKey)
        if wasRunning && (!selection.applicationTokens.isEmpty ||
                !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty) {
            enableDailyLimit()
            if !monitoring {
                errorMessage="新存档已切换，但系统监控未启动，请检查授权和规则。"
                needsRecovery=true
            }
        } else if wasRunning {
            errorMessage="已切换到无受限 App 的存档，系统监控已停止。"
        }
    }

    func requestAccess() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = AuthorizationCenter.shared.authorizationStatus == .approved
            if !authorized { errorMessage = "Screen Time access not granted." }
            refreshStatus()
        } catch {
            authorized = false
            errorMessage = error.localizedDescription
        }
    }

    func enableDailyLimit() {
        errorMessage = nil
        guard SharedConfig.appGroupAvailable else {
            errorMessage = "App Group 未配置或不可用，无法安全启动 Screen Time 扩展。"
            return
        }
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            errorMessage = "Authorize Screen Time first."
            return
        }
        guard !selection.applicationTokens.isEmpty ||
              !selection.categoryTokens.isEmpty ||
              !selection.webDomainTokens.isEmpty else {
            errorMessage = "Choose at least one app, category or website."
            return
        }
        let apps = Array(selection.applicationTokens)
        let categories = Array(selection.categoryTokens)
        let websites = Array(selection.webDomainTokens)
        // Events are bounded to keep within DeviceActivity scheduling limits.
        guard apps.count + categories.count + websites.count <= 12 else {
            errorMessage = "每次最多选择 12 项 App、网站或类别；请缩小范围。"
            return
        }
        let minutes = max(1, min(limitMinutes, 240))
        do {
            let encoded = try JSONEncoder().encode(selection)
            let appTokens = try JSONEncoder().encode(apps)
            let categoryTokens = try JSONEncoder().encode(categories)
            let webTokens = try JSONEncoder().encode(websites)
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0,minute: 0),
                intervalEnd: DateComponents(hour: 23,minute: 59),
                repeats: true)
            var events: [DeviceActivityEvent.Name:DeviceActivityEvent] = [:]
            let threshold = DateComponents(minute:minutes)
            for (i, token) in apps.enumerated() {
                events[DeviceActivityEvent.Name("app.\(i)")] =
                    DeviceActivityEvent(applications:[token],threshold:threshold)
            }
            for (i, token) in categories.enumerated() {
                events[DeviceActivityEvent.Name("category.\(i)")] =
                    DeviceActivityEvent(categories:[token],threshold:threshold)
            }
            for (i, token) in websites.enumerated() {
                events[DeviceActivityEvent.Name("web.\(i)")] =
                    DeviceActivityEvent(webDomains:[token],threshold:threshold)
            }
            // Store event-index mappings before monitoring. Do not persist anonymous tokens in export.
            SharedConfig.defaults.set(encoded,forKey:SharedConfig.selectionKey)
            SharedConfig.defaults.set(appTokens,forKey:"eventAppTokens")
            SharedConfig.defaults.set(categoryTokens,forKey:"eventCategoryTokens")
            SharedConfig.defaults.set(webTokens,forKey:"eventWebTokens")
            SharedConfig.defaults.set(minutes,forKey:SharedConfig.limitKey)
            SharedConfig.defaults.set(false,forKey:SharedConfig.limitReachedKey)
            // Remember the user-requested state even if registration fails.
            // On the next foreground opening, offer an explicit recovery button.
            SharedConfig.defaults.set(true,forKey:"monitorEnabled")
            center.stopMonitoring([activity])
            ManagedSettingsStore().clearAllSettings()
            try center.startMonitoring(activity,during:schedule,events:events)
            monitoring = true
            needsRecovery=false
            SharedConfig.defaults.set(true,forKey:"monitorEnabled")
            _ = storeActiveProfile()
        } catch {
            errorMessage = error.localizedDescription
            monitoring = false
            SharedConfig.defaults.set(true,forKey:"monitorEnabled")
            needsRecovery=true
        }
    }

    func disableDailyLimit() {
        center.stopMonitoring([activity])
        ManagedSettingsStore().clearAllSettings()
        SharedConfig.defaults.set(false,forKey: SharedConfig.limitReachedKey)
        SharedConfig.defaults.set(false,forKey:"monitorEnabled")
        monitoring = false
        needsRecovery=false
    }
}
