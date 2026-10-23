import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import WidgetKit

struct LocalBackup: Codable {
    let schema: String
    let language: String
    let theme: String
    let limitMinutes: Int
}

struct LocalBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var backup: LocalBackup
    init(_ backup: LocalBackup) { self.backup = backup }
    init(configuration: ReadConfiguration) throws {
        guard let data=configuration.file.regularFileContents, data.count<=1_048_576
        else { throw CocoaError(.fileReadCorruptFile) }
        backup=try JSONDecoder().decode(LocalBackup.self,from:data)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents:try JSONEncoder().encode(backup))
    }
}

struct SettingsView: View {
    @AppStorage("language",store:SharedConfig.defaults) private var lang="system"
    @AppStorage("theme",store:SharedConfig.defaults) private var theme="system"
    @AppStorage(SharedConfig.limitKey,store:SharedConfig.defaults) private var limitMinutes=20
    @State private var showExport=false
    @State private var showImport=false
    @State private var exportDocument:LocalBackupDocument?
    @State private var message=""
    @State private var photo:PhotosPickerItem?
    @State private var preview:UIImage?

    private func tr(_ key:String)->String { TextKey.label(key,lang:lang) }

    var body: some View {
        Form {
            Section(tr("language")) {
                Picker(tr("language"),selection:$lang) {
                    Text("跟随系统 / System").tag("system")
                    Text("简体中文").tag("zh-Hans")
                    Text("繁體中文").tag("zh-Hant")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                }
            }
            Section(tr("theme")) {
                Picker(tr("theme"),selection:$theme) {
                    Text(tr("system")).tag("system")
                    Text(tr("light")).tag("light")
                    Text(tr("dark")).tag("dark")
                    Text(tr("eye")).tag("eye")
                }
            }
            Section("水豚自定义形象") {
                PhotosPicker(selection:$photo,matching:.images) {
                    Label("选择本地照片",systemImage:"photo.on.rectangle")
                }
                .onChange(of:photo) { _,value in
                    Task {
                        if let raw=try? await value?.loadTransferable(type:Data.self),
                           raw.count<8_000_000, let img=UIImage(data:raw) {
                            await MainActor.run { preview=img }
                        }
                    }
                }
                if let preview {
                    Image(uiImage:preview).resizable().scaledToFit()
                        .frame(maxHeight:160)
                        .clipShape(RoundedRectangle(cornerRadius:18))
                } else {
                    CapyMascot(animated:false).frame(height:150)
                }
                Text("预览图片仅在当前界面展示；iOS 系统限制页不会允许任意动态图覆盖。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("本地设置备份") {
                Button(tr("backup")) {
                    exportDocument=LocalBackupDocument(LocalBackup(
                        schema:"barapause-ios-settings/1",language:lang,
                        theme:theme,limitMinutes:limitMinutes))
                    showExport=true
                }
                Button(tr("restore")) { showImport=true }
                Text("不备份匿名 App Tokens、使用历史、图片或 Screen Time 授权；导入后不会自动打开系统监控。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("隐私") {
                Label(tr("privacy"),systemImage:"lock.shield")
                Text("所有规则和关键词均保存在设备上，不需要云端账号。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if !message.isEmpty {
                Section { Text(message).foregroundStyle(.orange) }
            }
        }
        .fileExporter(isPresented:$showExport,document:exportDocument,
                      contentType:.json,defaultFilename:"BaraPause-settings") { outcome in
            if case .failure(let error)=outcome { message=error.localizedDescription }
        }
        .fileImporter(isPresented:$showImport,allowedContentTypes:[.json]) { outcome in
            do {
                let url=try outcome.get()
                let granted=url.startAccessingSecurityScopedResource()
                defer { if granted { url.stopAccessingSecurityScopedResource() } }
                let raw=try Data(contentsOf:url)
                guard raw.count<=1_048_576 else { throw CocoaError(.fileReadTooLarge) }
                let input=try JSONDecoder().decode(LocalBackup.self,from:raw)
                guard input.schema=="barapause-ios-settings/1",
                      ["system","zh-Hans","zh-Hant","en","ja"].contains(input.language),
                      ["system","light","dark","eye"].contains(input.theme),
                      (1...240).contains(input.limitMinutes)
                else { throw CocoaError(.fileReadCorruptFile) }
                lang=input.language;theme=input.theme;limitMinutes=input.limitMinutes
                message=""
            } catch {
                message=tr("importError")+": "+error.localizedDescription
            }
        }
    }
}
