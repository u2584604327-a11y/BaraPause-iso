import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
final class ScreenTimeController: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var authorized = false
    @Published var errorMessage: String?
    @Published var monitoring = false
    @Published var limitMinutes = 20

    private let center = DeviceActivityCenter()
    private let activity = DeviceActivityName(SharedConfig.activityName)

    init() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        let stored = SharedConfig.defaults.integer(forKey: SharedConfig.limitKey)
        limitMinutes = stored > 0 ? min(stored,240) : 20
        if let data = SharedConfig.defaults.data(forKey: SharedConfig.selectionKey),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        }
        monitoring = SharedConfig.defaults.bool(forKey: "monitorEnabled")
    }

    func requestAccess() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = AuthorizationCenter.shared.authorizationStatus == .approved
            if !authorized { errorMessage = "Screen Time access not granted." }
        } catch {
            authorized = false
            errorMessage = error.localizedDescription
        }
    }

    func enableDailyLimit() {
        errorMessage = nil
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
            center.stopMonitoring([activity])
            ManagedSettingsStore().clearAllSettings()
            try center.startMonitoring(activity,during:schedule,events:events)
            monitoring = true
            SharedConfig.defaults.set(true,forKey:"monitorEnabled")
        } catch {
            errorMessage = error.localizedDescription
            monitoring = false
            SharedConfig.defaults.set(false,forKey:"monitorEnabled")
        }
    }

    func disableDailyLimit() {
        center.stopMonitoring([activity])
        ManagedSettingsStore().clearAllSettings()
        SharedConfig.defaults.set(false,forKey: SharedConfig.limitReachedKey)
        SharedConfig.defaults.set(false,forKey:"monitorEnabled")
        monitoring = false
    }
}
