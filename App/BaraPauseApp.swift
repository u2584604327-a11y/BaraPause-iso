import SwiftUI

@main
struct BaraPauseApp: App {
    @AppStorage("language", store: SharedConfig.defaults) private var lang = "system"
    @AppStorage("theme", store: SharedConfig.defaults) private var theme = "system"

    var colorScheme: ColorScheme? {
        switch theme {
        case "light", "eye": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorScheme)
                .tint(Color(red: 0.29, green: 0.47, blue: 0.37))
        }
    }
}
