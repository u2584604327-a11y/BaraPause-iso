import SwiftUI

@main
struct BaraPauseApp: App {
    @StateObject private var screenTime = ScreenTimeController()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(screenTime)
        }
    }
}
