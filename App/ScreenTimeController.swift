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
    @Published var recoveryNeeded = false
    @Published var pendingLimitChange = false
    @Published var systemStatus = "尚未检查"
    @Published var lastEvent = "暂无系统回调"
    @Published var lastEventDate: Date?
    @Published var limitReached = false
    @Published var limitMinutes = 20

    private let center = DeviceActivityCenter()

    init() {
        let stored=SharedConfig.defaults.integer(forKey:SharedConfig.limitKey)
        limitMinutes=stored > 0 ? min(stored,240) : 20
        if let data=SharedConfig.defaults.data(forKey:SharedConfig.selectionKey),
           let decoded=try? JSONDecoder().decode(FamilyActivitySelection.self,from:data) {
            selection=decoded
        }
        refreshStatus()
    }

    /// DeviceActivityCenter is the source of truth. A local flag alone is not proof.
    func refreshStatus() {
        authorized=AuthorizationCenter.shared.authorizationStatus == .approved
        guard SharedConfig.appGroupAvailable else {
            monitoring=false
            recoveryNeeded=false
            systemStatus="App Group 不可用：不能读取可靠的扩展状态"
            return
        }
        let state=SharedConfig.defaults
        let requested=state.bool(forKey:SharedConfig.monitorEnabledKey)
        pendingLimitChange = requested && state.integer(forKey:SharedConfig.appliedLimitKey) != state.integer(forKey:SharedConfig.limitKey)
        let active=SharedConfig.activeActivityName
        let registered = !active.isEmpty && center.activities.contains {
            $0.rawValue == active
        }
        let stale = center.activities.contains { SharedConfig.ownsActivity($0.rawValue) }
        monitoring = requested && registered && authorized
        recoveryNeeded = requested && (!registered || !authorized)
        if !authorized {
            systemStatus = "Screen Time 授权未通过，限制可能已失效"
        } else if monitoring {
            systemStatus = "系统已登记周期性监控（不需要常驻打开 App）"
        } else if recoveryNeeded {
            systemStatus = "本地标记已启用，但系统无有效监控：请重新登记"
        } else if stale {
            systemStatus = "存在旧版监控登记；重新开启时会清理旧任务"
        } else {
            systemStatus = "监控未启用"
        }
        lastEvent = state.string(forKey:SharedConfig.lastEventKey) ?? "暂无系统回调"
        let stamp=state.double(forKey:SharedConfig.lastEventAtKey)
        lastEventDate=stamp>0 ? Date(timeIntervalSince1970:stamp) : nil
        limitReached=state.bool(forKey:SharedConfig.limitReachedKey)
    }

    func requestAccess() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for:.individual)
            refreshStatus()
            if !authorized { errorMessage="Screen Time 授权未通过" }
            else { errorMessage=nil }
        } catch {
            refreshStatus()
            errorMessage=error.localizedDescription
        }
    }

    func enableDailyLimit() {
        errorMessage=nil
        guard SharedConfig.appGroupAvailable, let shared=SharedConfig.groupDefaults else {
            errorMessage="App Group 不可用，无法启动系统监控"
            refreshStatus()
            return
        }
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            errorMessage="请先授予 Screen Time 权限"
            refreshStatus()
            return
        }
        let apps=Array(selection.applicationTokens)
        let categories=Array(selection.categoryTokens)
        let websites=Array(selection.webDomainTokens)
        let count=apps.count+categories.count+websites.count
        guard count>0 && count<=12 else {
            errorMessage="请选择 1 至 12 项 App、类别或网站"
            return
        }
        let minutes=max(1,min(limitMinutes,240))
        do {
            let selectionData=try JSONEncoder().encode(selection)
            let appsData=try JSONEncoder().encode(apps)
            let categoriesData=try JSONEncoder().encode(categories)
            let websitesData=try JSONEncoder().encode(websites)
            let oldNumber=shared.integer(forKey:SharedConfig.generationKey)
            let generation=oldNumber >= 1_000_000 ? 1 : oldNumber+1
            let nextName=SharedConfig.activityPrefix+"\(generation)"
            let threshold=DateComponents(minute:minutes)
            var events:[DeviceActivityEvent.Name:DeviceActivityEvent]=[:]
            for (i,token) in apps.enumerated() {
                events[DeviceActivityEvent.Name("app.\(i)")] =
                    DeviceActivityEvent(applications:[token],threshold:threshold,includesPastActivity:true)
            }
            for (i,token) in categories.enumerated() {
                events[DeviceActivityEvent.Name("category.\(i)")] =
                    DeviceActivityEvent(categories:[token],threshold:threshold,includesPastActivity:true)
            }
            for (i,token) in websites.enumerated() {
                events[DeviceActivityEvent.Name("web.\(i)")] =
                    DeviceActivityEvent(webDomains:[token],threshold:threshold,includesPastActivity:true)
            }
            let schedule=DeviceActivitySchedule(
                intervalStart:DateComponents(hour:0,minute:0),
                intervalEnd:DateComponents(hour:23,minute:59),
                repeats:true)
            // 1. Stop old activity before writing the new token mapping.
            //    Its interval-end callback must not clear a newly applied Shield.
            shared.set(false,forKey:SharedConfig.monitorEnabledKey)
            let old=center.activities.filter { SharedConfig.ownsActivity($0.rawValue) }
            if !old.isEmpty { center.stopMonitoring(old) }
            ManagedSettingsStore().clearAllSettings()

            // The daily event includes activity from earlier in this interval.
            // 2. Prepare the next activity ID and token mapping.
            //    The system may invoke callbacks synchronously during startMonitoring().
            shared.set(selectionData,forKey:SharedConfig.selectionKey)
            shared.set(appsData,forKey:"eventAppTokens")
            shared.set(categoriesData,forKey:"eventCategoryTokens")
            shared.set(websitesData,forKey:"eventWebTokens")
            shared.set(minutes,forKey:SharedConfig.limitKey)
            shared.set(generation,forKey:SharedConfig.generationKey)
            shared.set(nextName,forKey:SharedConfig.activeActivityKey)
            shared.removeObject(forKey:"reachedCategories")
            shared.set(false,forKey:SharedConfig.limitReachedKey)
            shared.set(true,forKey:SharedConfig.monitorEnabledKey)

            // 3. Register with Apple. A failed call never leaves a fake "running" state.
            let activity=DeviceActivityName(nextName)
            do {
                try center.startMonitoring(activity,during:schedule,events:events)
                shared.set(minutes,forKey:SharedConfig.appliedLimitKey)
                SharedConfig.recordMonitorEvent("登记成功：每日独立阈值监控")
            } catch {
                shared.set(false,forKey:SharedConfig.monitorEnabledKey)
                shared.removeObject(forKey:SharedConfig.activeActivityKey)
                center.stopMonitoring([activity])
                ManagedSettingsStore().clearAllSettings()
                SharedConfig.recordMonitorEvent("监控登记失败：请检查授权与系统配置")
                throw error
            }
            refreshStatus()
            if !monitoring {
                errorMessage="已请求系统登记，但没有查询到活动。请查看诊断后重试。"
            }
        } catch {
            errorMessage=error.localizedDescription
            refreshStatus()
        }
    }

    func disableDailyLimit() {
        guard SharedConfig.appGroupAvailable, let shared=SharedConfig.groupDefaults else {
            errorMessage="App Group 不可用：不能确认停用状态"
            refreshStatus()
            return
        }
        // Disable first so callbacks from a task being stopped cannot re-shield.
        shared.set(false,forKey:SharedConfig.monitorEnabledKey)
        shared.removeObject(forKey:SharedConfig.activeActivityKey)
        let tasks=center.activities.filter { SharedConfig.ownsActivity($0.rawValue) }
        if !tasks.isEmpty { center.stopMonitoring(tasks) }
        ManagedSettingsStore().clearAllSettings()
        shared.removeObject(forKey:"reachedCategories")
        shared.set(false,forKey:SharedConfig.limitReachedKey)
        SharedConfig.recordMonitorEvent("用户已停用监控")
        refreshStatus()
    }
}
