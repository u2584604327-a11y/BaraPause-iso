import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit
import WidgetKit

struct BaraBackup: Codable {
    let format: String
    let version: Int
    let dailyMinutes: Int
    let appearance: String
    let language: String
    let reminderStyle: String
}

struct BaraBackupFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var content: Data
    init(content: Data) { self.content = content }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count <= 1_048_576 else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content)
    }
}

struct PreferencesView: View {
    @EnvironmentObject private var controller: ScreenTimeController
    @State private var appearance = BaraStore.appearance
    @State private var language = BaraStore.language
    @State private var motion = BaraStore.reminderStyle
    @State private var exporting = false
    @State private var importing = false
    @State private var feedback = ""
    @State private var backup = BaraBackupFile(content: Data())
    @State private var photo: PhotosPickerItem?
    @State private var mascotImage: UIImage?

    var body: some View {
        Form {
            Section(BaraStrings.text("look")) {
                Picker(BaraStrings.text("look"), selection: $appearance) {
                    Text("Follow system").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("Eye comfort").tag("eye")
                }
                .onChange(of: appearance) { _, v in
                    BaraStore.appearance = v
                    NotificationCenter.default.post(name: .baraAppearanceChanged, object: nil)
                }
                Picker(BaraStrings.text("language"), selection: $language) {
                    Text("System").tag("system")
                    Text("简体中文").tag("zh-Hans")
                    Text("繁體中文").tag("zh-Hant")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                }
                .onChange(of: language) { _, v in BaraStore.language = v }
                Picker(BaraStrings.text("motion"), selection: $motion) {
                    Text("Still").tag("still")
                    Text("Breathe").tag("breathe")
                    Text("Bounce").tag("bounce")
                }
                .onChange(of: motion) { _, v in BaraStore.reminderStyle = v }
            }
            Section("Custom capybara image (inside this app)") {
                PhotosPicker(selection: $photo, matching: .images) {
                    Label("Choose photo", systemImage: "photo")
                }
                if let mascotImage {
                    Image(uiImage: mascotImage).resizable().scaledToFit().frame(maxHeight: 155)
                }
                Button("Restore mascot") {
                    mascotImage = nil
                    if let url = selectedPhotoURL { try? FileManager.default.removeItem(at: url) }
                }
                Text("iOS Screen Time shields cannot display arbitrary continuously animated overlays.")
                    .font(.footnote)
            }
            Section(BaraStrings.text("backup")) {
                Button(BaraStrings.text("export")) {
                    let data = BaraBackup(format: "barapause-ios-settings", version: 1,
                                          dailyMinutes: BaraStore.dailyLimitMinutes,
                                          appearance: appearance, language: language,
                                          reminderStyle: motion)
                    backup = BaraBackupFile(content: (try? JSONEncoder().encode(data)) ?? Data())
                    exporting = true
                }
                Button(BaraStrings.text("import")) { importing = true }
                Text("Screen Time app selections, personal usage data and opaque tokens are excluded.")
                    .font(.caption)
            }
            if !feedback.isEmpty { Section { Text(feedback).font(.footnote) } }
        }
        .navigationTitle(BaraStrings.text("settings"))
        .onAppear {
            if let url = selectedPhotoURL { mascotImage = UIImage(contentsOfFile: url.path) }
        }
        .onChange(of: photo) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   data.count <= 8_000_000, let image = UIImage(data: data) {
                    if let url = selectedPhotoURL, let jpeg = image.jpegData(compressionQuality: 0.80) {
                        try? jpeg.write(to: url, options: .atomic)
                    }
                    mascotImage = image
                } else if item != nil {
                    feedback = "Could not load image (8 MB maximum)."
                }
            }
        }
        .fileExporter(isPresented: $exporting, document: backup,
                      contentType: .json, defaultFilename: "BaraPause-iOS-settings") { result in
            if case .failure(let error) = result { feedback = error.localizedDescription }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                guard url.startAccessingSecurityScopedResource() else {
                    feedback = "Could not access selected file."; return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                guard data.count <= 1_048_576 else { feedback = "File too large"; return }
                let model = try JSONDecoder().decode(BaraBackup.self, from: data)
                guard model.format == "barapause-ios-settings", model.version == 1,
                      (1...240).contains(model.dailyMinutes),
                      ["system","light","dark","eye"].contains(model.appearance),
                      ["system","zh-Hans","zh-Hant","en","ja"].contains(model.language),
                      ["still","breathe","bounce"].contains(model.reminderStyle) else {
                    feedback = "Unsupported settings file."; return
                }
                BaraStore.dailyLimitMinutes = model.dailyMinutes
                BaraStore.appearance = model.appearance
                BaraStore.language = model.language
                BaraStore.reminderStyle = model.reminderStyle
                controller.dailyMinutes = model.dailyMinutes
                appearance = model.appearance
                language = model.language
                motion = model.reminderStyle
                NotificationCenter.default.post(name: .baraAppearanceChanged, object: nil)
                WidgetCenter.shared.reloadAllTimelines()
                feedback = "Settings imported; re-authorize app choices if needed."
            } catch { feedback = "Import failed: \(error.localizedDescription)" }
        }
    }

    private var selectedPhotoURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaraStore.group)?
            .appendingPathComponent("custom-mascot.jpg")
    }
}
