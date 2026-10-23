import SwiftUI
import FamilyControls

struct ProfilesView:View {
    @ObservedObject var controller:ScreenTimeController
    @AppStorage("language",store:SharedConfig.defaults) private var lang="system"
    private func tr(_ zh:String,_ en:String,_ ja:String?=nil)->String {
        let l=lang=="system" ? (Locale.preferredLanguages.first ?? "en").lowercased() : lang.lowercased()
        if l.hasPrefix("ja") {return ja ?? en}
        if l.hasPrefix("en") {return en}
        return zh
    }
    @State private var slots:[BaraPreset]=[]
    @State private var title=""
    @State private var clone=true
    @State private var pending:UUID?
    @State private var showConfirm=false
    @State private var feedback=""
    @State private var renameText:[UUID:String]=[:]

    private func refresh() {
        slots=ProfileLibrary.all()
        renameText=Dictionary(uniqueKeysWithValues:slots.map { ($0.id,$0.name) })
    }

    var body:some View {
        Form {
            Section {
                Text(tr("每次只有一个档位生效。切换时自动保存当前选择；若原来已开启监控，系统会重新建立新档位的规则。","Only one preset is active. Switching saves your current selection and re-registers monitoring."))
                    .font(.footnote).foregroundStyle(.secondary)
                Text(tr("匿名 App Tokens 只保留在此设备的 App Group 中，不会进入导出的 JSON 文件。","Anonymous Screen Time tokens stay on this device; exported JSON never includes them."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section(tr("创建存档 · 最多 8 个","New preset · up to 8")) {
                TextField(tr("名称，例如：考研 / 日常 / 休息","Name: Study / Daily / Break"),text:$title)
                    .textInputAutocapitalization(.never)
                Toggle(tr("复制当前规则","Duplicate current rules"),isOn:$clone)
                Button(tr("保存为新档","Create preset")) {
                    _ = controller.storeActiveProfile()
                    if ProfileLibrary.create(name:title,duplicate:clone) {
                        title=""; feedback="已创建新档";refresh()
                    } else {feedback="请填写名称，且最多创建 8 个档位"}
                }.disabled(slots.count>=ProfileLibrary.maxProfiles || title.trimmingCharacters(in:.whitespaces).isEmpty)
            }
            Section(tr("已保存的配置","Saved presets")) {
                ForEach(slots) { slot in
                    VStack(alignment:.leading,spacing:9) {
                        HStack {
                            Image(systemName:slot.id == ProfileLibrary.activeID() ?
                                  "checkmark.circle.fill":"circle")
                                .foregroundStyle(.green)
                            Text(slot.name).font(.headline)
                            Spacer()
                            Text("\(slot.dailyMinutes) 分钟").font(.caption).foregroundStyle(.secondary)
                        }
                        TextField(tr("重命名","Rename"),text:Binding(
                            get: { renameText[slot.id] ?? slot.name },
                            set: { renameText[slot.id] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        HStack {
                            Button(tr("保存名称","Save name")) {
                                if ProfileLibrary.rename(slot.id,to:renameText[slot.id] ?? "") {
                                    feedback="名称已保存";refresh()
                                } else {feedback="名称不合法"}
                            }.buttonStyle(.bordered)
                            if slot.id != ProfileLibrary.activeID() {
                                Button(tr("启用","Activate")) { pending=slot.id;showConfirm=true }
                                    .buttonStyle(.borderedProminent)
                                Button(tr("删除","Delete"),role:.destructive) {
                                    if ProfileLibrary.delete(slot.id) {refresh()}
                                }.buttonStyle(.bordered)
                            } else {
                                Text(tr("当前生效","Active now")).font(.caption).foregroundStyle(.green)
                            }
                        }
                    }.padding(.vertical,5)
                }
            }
            if !feedback.isEmpty {
                Section {Text(feedback).font(.footnote)}
            }
        }
        .navigationTitle(tr("多存档 · 快速切换","Presets · quick switch"))
        .onAppear { refresh() }
        .confirmationDialog(tr("切换当前系统监控规则？","Switch active Screen Time rules?"),isPresented:$showConfirm) {
            Button(tr("确认切换","Confirm switch")) {
                if let id=pending {
                    controller.switchProfile(to:id)
                    if let message=controller.errorMessage {feedback=message}
                    else { feedback="存档已切换" }
                    refresh()
                }
                pending=nil
            }
            Button(tr("取消","Cancel"),role:.cancel) {pending=nil}
        } message: {
            Text(tr("如果旧档已开启 Screen Time，切换将重新注册新档的监控阈值。新档没有选择 App 时会停止系统限制。","Switching re-registers Screen Time monitoring. A blank preset stops the old limits."))
        }
    }
}
