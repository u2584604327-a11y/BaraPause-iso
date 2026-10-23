import SwiftUI

struct SearchProvider: Identifiable, Hashable {
    let id: String
    let title: String
    let base: String
    let parameter: String

    static let options: [SearchProvider] = [
        .init(id: "google", title: "Google", base: "https://www.google.com/search", parameter: "q"),
        .init(id: "bing", title: "Bing", base: "https://www.bing.com/search", parameter: "q"),
        .init(id: "youtube", title: "YouTube", base: "https://www.youtube.com/results", parameter: "search_query"),
        .init(id: "maps", title: "Apple Maps", base: "https://maps.apple.com/", parameter: "q")
    ]
    func url(query: String) -> URL? {
        guard var url = URLComponents(string: base) else { return nil }
        url.queryItems = [URLQueryItem(name: parameter, value: query)]
        return url.url
    }
}

struct QuickSearchView: View {
    @Environment(\.openURL) private var openURL
    @State private var query = ""
    @State private var provider = SearchProvider.options[0]
    @State private var customLink = ""
    @State private var message = ""
    @State private var recent = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

    var body: some View {
        Form {
            Section {
                HStack {
                    MascotView(size: 70)
                    Text(BaraStrings.text("quick")).font(.headline)
                }
                TextField(BaraStrings.text("searchHint"), text: $query)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { search() }
                Picker("Search provider", selection: $provider) {
                    ForEach(SearchProvider.options) { option in
                        Text(option.title).tag(option)
                    }
                }
                Button(BaraStrings.text("open")) { search() }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Text("iOS cannot list all installed apps or access private in-app search boxes.")
                    .font(.footnote)
            }
            Section("Recent local searches") {
                if recent.isEmpty { Text("No recent searches").foregroundStyle(.secondary) }
                ForEach(recent, id: \.self) { item in
                    Button(item) { query = item }
                }
                Button("Clear recent searches", role: .destructive) {
                    recent = []
                    UserDefaults.standard.removeObject(forKey: "recentSearches")
                }
            }
            Section("Open a content link") {
                TextField("https://…", text: $customLink)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Open HTTPS link") {
                    let trimmed = customLink.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = URL(string: trimmed), url.scheme == "https",
                          let host = url.host, !host.isEmpty, url.user == nil,
                          trimmed.count <= 2048 else {
                        message = "Only valid HTTPS links are accepted."
                        return
                    }
                    openURL(url)
                }
            }
            if !message.isEmpty { Section { Text(message).foregroundStyle(.orange) } }
        }
        .navigationTitle(BaraStrings.text("quick"))
    }
    private func search() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let url = provider.url(query: text) else { return }
        recent = Array(([text] + recent.filter { $0 != text }).prefix(12))
        UserDefaults.standard.set(recent, forKey: "recentSearches")
        openURL(url)
    }
}
