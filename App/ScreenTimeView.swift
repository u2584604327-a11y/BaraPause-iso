import SwiftUI
import FamilyControls

struct ScreenTimeView: View {
    @StateObject private var controller = ScreenTimeController()
    @State private var showPicker = false
    @AppStorage("language",store:SharedConfig.defaults) private var lang="system"

    private func tr(_ key:String)->String { TextKey.label(key,lang:lang) }
    private var selectedCount: Int {
        controller.selection.applicationTokens.count +
        controller.selection.categoryTokens.count +
        controller.selection.webDomainTokens.count
    }

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    ProfilesView(controller:controller)
                } label: {
                    Label("多存档 · 快速切换",systemImage:"square.stack.3d.up")
                }
                Text("只运行当前存档的一套 Screen Time 规则。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                LabeledContent(tr("permission")) {
                    Label(controller.authorized ? tr("approved") : tr("awaiting"),
                          systemImage: controller.authorized ? "checkmark.shield.fill" : "lock.shield")
                }
                if controller.needsRecovery {
                    Label("系统监控计划中断或不存在",systemImage:"exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Button("手动恢复系统监控") { controller.restoreMonitoringIfRequested() }
                }
                Button(tr("authorize")) {
                    Task { await controller.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
                Text(tr("familyNotice")).font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button {
                    showPicker = true
                } label: {
                    Label(tr("choose"),systemImage: "apps.iphone")
                }
                .disabled(!controller.authorized)
                Text("\(tr("selected"))：\(selectedCount)")
                    .foregroundStyle(.secondary)
                Stepper(value:$controller.limitMinutes,in:1...240,step:1) {
                    Text("\(controller.limitMinutes) \(tr("minutes"))")
                }
                Button(tr("enable")) { controller.enableDailyLimit() }
                    .disabled(!controller.authorized || selectedCount==0)
                Button(tr("disable"),role:.destructive) { controller.disableDailyLimit() }
            } header: {
                Text(tr("shield"))
            } footer: {
                Text(tr("shieldNote"))
            }
            if let error = controller.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }
            if controller.monitoring {
                Section {
                    Label(tr("saved"),systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .familyActivityPicker(isPresented:$showPicker,selection:$controller.selection)
        .onAppear { controller.refreshStatus() }
    }
}
