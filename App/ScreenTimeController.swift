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
    private let eventName = DeviceActivityEvent.Name(SharedConfig.thresholdName)

    init() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        limitMinutes = max(1, SharedConfig.defaults.integer(forKey: SharedConfig.limitKey))
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
        let minutes = max(1, min(limitMinutes, 240))
        do {
            let data = try JSONEncoder().encode(selection)
            SharedConfig.defaults.set(data,forKey: SharedConfig.selectionKey)
            SharedConfig.defaults.set(minutes,forKey: SharedConfig.limitKey)
            SharedConfig.defaults.set(false,forKey: SharedConfig.limitReachedKey)
            // Prevent stale shield from an earlier interval or set of selections.
            ManagedSettingsStore().clearAllSettings()
            center.stopMonitoring([activity])
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour:0, minute:0),
                intervalEnd: DateComponents(hour:23,minute:59),
                repeats: true
            )
            let event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(minute: minutes)
            )
            try center.startMonitoring(activity,during:schedule,events:[eventName:event])
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
