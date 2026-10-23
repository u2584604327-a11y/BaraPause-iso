import Foundation
import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
final class ScreenTimeController: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    @Published var dailyMinutes = BaraStore.dailyLimitMinutes
    @Published var monitoring = false
    @Published var statusMessage = ""
    @Published var authorized = false

    private let center = DeviceActivityCenter()
    private let activity = DeviceActivityName("barapause.daily")
    private let event = DeviceActivityEvent.Name("barapause.limit")
    private let shield = ManagedSettingsStore(named: ManagedSettingsStore.Name("barapause"))

    init() {
        if let data = BaraStore.selectionData,
           let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        }
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        monitoring = UserDefaults.standard.bool(forKey: "screenTimeRunning")
    }

    var selectedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    func saveSelection() {
        BaraStore.selectionData = try? PropertyListEncoder().encode(selection)
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = AuthorizationCenter.shared.authorizationStatus == .approved
            statusMessage = authorized ? "Screen Time authorized" : "Authorization was not granted"
        } catch {
            authorized = false
            statusMessage = "Authorization failed: \(error.localizedDescription)"
        }
    }

    func start() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        guard authorized else {
            statusMessage = "Authorize Screen Time first."
            return
        }
        guard selectedCount > 0 else {
            statusMessage = "Choose one or more apps, categories or websites."
            return
        }
        saveSelection()
        BaraStore.dailyLimitMinutes = dailyMinutes

        // Inclusive enough for normal daily use; Apple's DeviceActivity owns enforcement timing.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let limit = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: dailyMinutes),
            includesPastActivity: true
        )
        do {
            center.stopMonitoring([activity])
            shield.shield.applications = nil
            shield.shield.applicationCategories = nil
            shield.shield.webDomains = nil
            try center.startMonitoring(activity, during: schedule, events: [event: limit])
            monitoring = true
            UserDefaults.standard.set(true, forKey: "screenTimeRunning")
            statusMessage = "Monitoring request accepted. Check on a real iPhone."
        } catch {
            monitoring = false
            UserDefaults.standard.set(false, forKey: "screenTimeRunning")
            statusMessage = "Failed to start: \(error.localizedDescription)"
        }
    }

    func stop() {
        center.stopMonitoring([activity])
        shield.shield.applications = nil
        shield.shield.applicationCategories = nil
        shield.shield.webDomains = nil
        monitoring = false
        UserDefaults.standard.set(false, forKey: "screenTimeRunning")
        statusMessage = "Monitoring stopped; shields cleared."
    }
}
