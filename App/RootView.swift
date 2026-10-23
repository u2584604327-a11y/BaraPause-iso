import SwiftUI

struct RootView: View {
    @AppStorage("language",store: SharedConfig.defaults) private var lang = "system"
    @AppStorage("theme",store: SharedConfig.defaults) private var theme = "system"
    @AppStorage("lastSelectedTab",store:SharedConfig.defaults) private var tab = 0

    private func tr(_ key:String)->String { TextKey.label(key,lang: lang) }
    private var background: Color {
        theme == "eye" ? Color(red: 0.97,green: 0.94,blue: 0.86) : Color(.systemGroupedBackground)
    }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        CapyMascot().frame(height: 183)
                        Text("BaraPause")
                            .font(.largeTitle.bold())
                        Text(tr("local")).foregroundStyle(.secondary)
                        Button { tab = 1 } label: {
                            Label(tr("focus"),systemImage: "timer")
                                .frame(maxWidth:.infinity).padding(8)
                        }.buttonStyle(.borderedProminent)
                        Button { tab = 2 } label: {
                            Label(tr("apps"),systemImage: "hourglass")
                                .frame(maxWidth:.infinity).padding(8)
                        }.buttonStyle(.bordered)
                        Button { tab = 3 } label: {
                            Label(tr("search"),systemImage: "magnifyingglass")
                                .frame(maxWidth:.infinity).padding(8)
                        }.buttonStyle(.bordered)
                        HStack {
                            Image(systemName: "lock.shield")
                            Text(tr("shieldNote"))
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                    .padding(20)
                }
                .navigationTitle("BaraPause")
                .background(background)
            }
            .tabItem { Label(tr("home"),systemImage: "house.fill") }.tag(0)
            NavigationStack { FocusView().navigationTitle(tr("focus")) }
                .tabItem { Label(tr("focus"),systemImage: "timer") }.tag(1)
            NavigationStack { ScreenTimeView().navigationTitle(tr("apps")) }
                .tabItem { Label(tr("apps"),systemImage: "hourglass") }.tag(2)
            NavigationStack { QuickSearchView().navigationTitle(tr("search")) }
                .tabItem { Label(tr("search"),systemImage: "magnifyingglass") }.tag(3)
            NavigationStack { SettingsView().navigationTitle(tr("settings")) }
                .tabItem { Label(tr("settings"),systemImage: "gearshape") }.tag(4)
        }
        .onOpenURL { url in
            guard url.scheme == "barapause" else { return }
            switch url.host {
            case "search": tab = 3
            case "focus": tab = 1
            case "apps": tab = 2
            default: tab = 0
            }
        }
    }
}
