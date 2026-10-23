import SwiftUI
import FamilyControls
import UIKit

struct ScreenTimeView: View {
    @StateObject private var controller=ScreenTimeController()
    @State private var showPicker=false
    @State private var showRepairConfirmation=false
    @State private var showStopConfirmation=false
    @State private var didCopy=false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("language",store:SharedConfig.defaults) private var lang="system"

    private func tr(_ key:String)->String { TextKey.label(key,lang:lang) }
    private var selectedCount:Int {
        controller.selection.applicationTokens.count +
        controller.selection.categoryTokens.count +
        controller.selection.webDomainTokens.count
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(tr("permission")) {
                    Label(controller.authorized ? tr("approved") : tr("awaiting"),
                          systemImage:controller.authorized ? "checkmark.shield.fill" : "lock.shield")
                }
                Button(tr("authorize")) {
                    Task { await controller.requestAccess() }
                }
                Text(tr("familyNotice")).font(.footnote).foregroundStyle(.secondary)
            }

            Section("持续监控 · 系统状态") {
                Label(controller.monitoring ? "系统已登记" : "当前未确认正常运行",
                      systemImage:controller.monitoring ? "checkmark.shield.fill" : "exclamationmark.shield")
                    .foregroundStyle(controller.monitoring ? .green : .orange)
                Text(controller.systemStatus)
                    .font(.subheadline)
                if controller.limitReached {
                    Label("今天已有目标达到限额",systemImage:"hand.raised.fill")
                        .foregroundStyle(.orange)
                }
                LabeledContent("最近回调") {
                    Text(controller.lastEvent).font(.footnote)
                        .multilineTextAlignment(.trailing)
                }
                if let date=controller.lastEventDate {
                    Text("事件时间：\(date.formatted(date:.abbreviated,time:.standard))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("刷新真实监控状态") { controller.refreshStatus() }
                if controller.pendingLimitChange && controller.monitoring {
                    Text("本地限额已修改，但系统仍按旧限额运行。点击「开启每日限额」重新登记才会生效。")
                        .font(.caption).foregroundStyle(.orange)
                }
                if controller.recoveryNeeded {
                    Button("重新登记系统监控") {
                        showRepairConfirmation=true
                    }.tint(.orange)
                    Text("系统会继续计入今天此前的使用时间；如果已超限，重新登记可能立即触发 Shield。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button(didCopy ? "诊断已复制" : "复制无敏感信息的诊断") {
                    let report = """
                    BaraPause iOS Monitor
                    authorized=\(controller.authorized)
                    registered=\(controller.monitoring)
                    needs_repair=\(controller.recoveryNeeded)
                    selected_count=\(selectedCount)
                    status=\(controller.systemStatus)
                    last_event=\(controller.lastEvent)
                    """
                    UIPasteboard.general.string=report
                    didCopy=true
                }
            }

            Section {
                Button {
                    showPicker=true
                } label: {
                    Label(tr("choose"),systemImage:"apps.iphone")
                }.disabled(!controller.authorized)
                Text("\(tr("selected"))：\(selectedCount)")
                    .foregroundStyle(.secondary)
                Stepper(value:$controller.limitMinutes,in:1...240,step:1) {
                    Text("\(controller.limitMinutes) \(tr("minutes"))")
                }
                Button(tr("enable")) { controller.enableDailyLimit() }
                    .disabled(!controller.authorized || selectedCount==0)
                Button(tr("disable"),role:.destructive) {
                    showStopConfirmation=true
                }
            } header: {
                Text(tr("shield"))
            } footer: {
                Text("由 iOS 在每日周期内累计选定的 App/类别/网站使用情况。关闭 BaraPause 界面不等于停止系统登记；授权撤销或系统限制会影响运行。")
            }

            if let error=controller.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .familyActivityPicker(isPresented:$showPicker,selection:$controller.selection)
        .alert("重新登记监控？",isPresented:$showRepairConfirmation) {
            Button("取消",role:.cancel) {}
            Button("确认重新登记") { controller.enableDailyLimit() }
        } message: {
            Text("将重新建立系统监控，包含今天此前的使用时间。若已超过限额，可能立即显示系统限制页。")
        }
        .confirmationDialog("关闭所有 BaraPause 的 Screen Time 限制？",
                            isPresented:$showStopConfirmation) {
            Button("停止监控并解除限制",role:.destructive) {
                controller.disableDailyLimit()
            }
            Button("取消",role:.cancel) {}
        }
        .onAppear { controller.refreshStatus() }
        .onChange(of:scenePhase) { _,value in
            if value == .active { controller.refreshStatus() }
        }
    }
}
