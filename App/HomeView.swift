import SwiftUI
import FamilyControls

enum BaraTheme {
    static let cream = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let leaf = Color(red: 0.44, green: 0.63, blue: 0.43)
    static let cocoa = Color(red: 0.34, green: 0.24, blue: 0.19)
    static func scheme(_ mode: String) -> ColorScheme? {
        switch mode {
        case "light", "eye": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

struct BaraPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(BaraTheme.cream.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(BaraTheme.cocoa)
    }
}

struct MascotView: View {
    var size: CGFloat = 84
    @State private var animate = false
    var body: some View {
        Image("Capybara").resizable().scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(animate ? 1.035 : 0.97)
            .rotationEffect(.degrees(animate ? 2 : -2))
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = BaraStore.reminderStyle != "still" }
            .onDisappear { animate = false }
            .accessibilityLabel("BaraPause capybara")
    }
}

struct HomeView: View {
    @EnvironmentObject private var screenTime: ScreenTimeController
    @State private var tab = 0
    @State private var showPicker = false
    @State private var appearance = BaraStore.appearance
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { dashboard }
                .tabItem { Label(BaraStrings.text("home"), systemImage: "house.fill") }.tag(0)
            NavigationStack { FocusTimerView() }
                .tabItem { Label(BaraStrings.text("focus"), systemImage: "timer") }.tag(1)
            NavigationStack { screenTimePage }
                .tabItem { Label(BaraStrings.text("limits"), systemImage: "hourglass") }.tag(2)
            NavigationStack { QuickSearchView() }
                .tabItem { Label(BaraStrings.text("quick"), systemImage: "magnifyingglass") }.tag(3)
            NavigationStack { PreferencesView() }
                .tabItem { Label(BaraStrings.text("settings"), systemImage: "gearshape") }.tag(4)
        }
        .tint(BaraTheme.leaf)
        .preferredColorScheme(BaraTheme.scheme(appearance))
        .onOpenURL { url in
            guard url.scheme == "barapause" else { return }
            switch url.host {
            case "search": tab = 3
            case "focus": tab = 1
            case "limits": tab = 2
            default: tab = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .baraAppearanceChanged)) { _ in
            appearance = BaraStore.appearance
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 16) {
                BaraPanel {
                    HStack(spacing: 15) {
                        MascotView(size: 110)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BaraPause").font(.system(size: 29, weight: .bold, design: .rounded))
                            Text("🍃  " + BaraStrings.text("focus")).font(.subheadline)
                            Text(BaraStrings.text("limitations")).font(.caption)
                        }
                    }
                }
                BaraPanel {
                    Label(BaraStrings.text("status"), systemImage: "shield.lefthalf.filled")
                        .font(.headline)
                    Text(BaraStrings.text(screenTime.monitoring ? "active" : "inactive"))
                    Text(BaraStrings.text("shield")).font(.footnote)
                    Button(BaraStrings.text("limits")) { tab = 2 }
                        .buttonStyle(.borderedProminent).tint(BaraTheme.leaf)
                }
                HStack {
                    Button { tab = 1 } label: {
                        Label(BaraStrings.text("focus"), systemImage: "timer")
                            .frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.bordered)
                    Button { tab = 3 } label: {
                        Label(BaraStrings.text("quick"), systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.bordered)
                }
                BaraPanel {
                    Label(BaraStrings.text("widget"), systemImage: "square.grid.2x2.fill")
                    Text("长按 iPhone 主屏幕 → 编辑 → 添加小组件 → BaraPause")
                        .font(.footnote)
                }
            }.padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("BaraPause")
    }

    private var screenTimePage: some View {
        Form {
            Section {
                Text(BaraStrings.text("shield")).font(.footnote)
                HStack {
                    Image(systemName: "shield.checkered").foregroundStyle(BaraTheme.leaf)
                    Text(screenTime.authorized ? "Screen Time authorized" : "Authorization required")
                }
                Button(BaraStrings.text("authorize")) {
                    Task { await screenTime.requestAuthorization() }
                }
                Button(BaraStrings.text("choose")) { showPicker = true }
                Text("App/category/domain groups: \(screenTime.selectedCount)").font(.footnote)
                Stepper("\(BaraStrings.text("daily")): \(screenTime.dailyMinutes) \(BaraStrings.text("minutes"))",
                        value: $screenTime.dailyMinutes, in: 1...240)
            }
            Section {
                Button(BaraStrings.text("saveRule")) { screenTime.start() }
                    .disabled(!screenTime.authorized || screenTime.selectedCount == 0)
                Button(BaraStrings.text("stopRule"), role: .destructive) { screenTime.stop() }
                if !screenTime.statusMessage.isEmpty {
                    Text(screenTime.statusMessage).font(.footnote)
                }
            }
        }
        .navigationTitle(BaraStrings.text("limits"))
        .familyActivityPicker(isPresented: $showPicker, selection: $screenTime.selection)
        .onChange(of: showPicker) { _, showing in
            if !showing { screenTime.saveSelection() }
        }
    }
}

extension Notification.Name {
    static let baraAppearanceChanged = Notification.Name("barapause.appearanceChanged")
}
