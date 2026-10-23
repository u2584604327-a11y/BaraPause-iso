import SwiftUI
import WidgetKit

struct SearchProvider: Identifiable, Hashable {
    let id:String
    let title:String
    let base:String
    let parameter:String

    static let options:[SearchProvider] = [
        .init(id:"google",title:"Google",base:"https://www.google.com/search",parameter:"q"),
        .init(id:"bing",title:"Bing",base:"https://www.bing.com/search",parameter:"q"),
        .init(id:"youtube",title:"YouTube",base:"https://www.youtube.com/results",parameter:"search_query"),
        .init(id:"maps",title:"Apple Maps",base:"https://maps.apple.com/",parameter:"q")
    ]
    func url(query:String)->URL? {
        guard var parts=URLComponents(string:base) else { return nil }
        parts.queryItems=[URLQueryItem(name:parameter,value:query)]
        return parts.url
    }
}
struct QuickSearchView: View {
    @AppStorage("language",store:SharedConfig.defaults) private var lang="system"
    @Environment(\.openURL) private var openURL
    @State private var query=""
    @State private var provider=SearchProvider.options[0]
    @State private var contentLink=""
    @State private var recent:[String]=[]
    @State private var confirmLink=false
    @State private var message=""
    private func tr(_ key:String)->String { TextKey.label(key,lang:lang) }

    var body: some View {
        Form {
            Section(tr("search")) {
                HStack {
                    CapyMascot(animated:true).scaleEffect(0.45).frame(width:75,height:75)
                    Text(tr("search")).font(.headline)
                }
                TextField(tr("quickHint"),text:$query)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search).onSubmit { search() }
                Picker("搜索来源",selection:$provider) {
                    ForEach(SearchProvider.options) { item in
                        Text(item.title).tag(item)
                    }
                }
                Button(tr("openWeb")) { search() }
                    .disabled(query.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                Text("iOS 无法遍历手机所有 App，也不能代替第三方 App 点击私有搜索框；公开网页或关联的 Universal Link 可以交给系统处理。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section(tr("history")) {
                if recent.isEmpty { Text("暂无历史").foregroundStyle(.secondary) }
                ForEach(recent,id:\.self) { item in
                    Button(item) { query=item }
                }
                Button("清空历史",role:.destructive) {
                    recent=[]
                    SharedConfig.defaults.removeObject(forKey:SharedConfig.searchHistoryKey)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            Section(tr("openLink")) {
                TextField("https://…",text:$contentLink,axis:.vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled().keyboardType(.URL)
                Button(tr("open")) { confirmLink=true }
                    .disabled(checkedURL==nil)
                Text("仅支持 HTTPS。关联 App 支持 Universal Links 时可直达内容，否则由浏览器打开。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if !message.isEmpty {
                Section { Text(message).foregroundStyle(.orange) }
            }
        }
        .onAppear {
            recent=SharedConfig.defaults.stringArray(forKey:SharedConfig.searchHistoryKey) ?? []
            if let incoming=SharedConfig.defaults.string(forKey:"sharedIncomingLink"),!incoming.isEmpty {
                contentLink=incoming
                SharedConfig.defaults.removeObject(forKey:"sharedIncomingLink")
                // Deliberately require user confirmation before opening.
                confirmLink=false
            }
        }
        .confirmationDialog("打开外部链接？",isPresented:$confirmLink) {
            if let url=checkedURL {
                Button(tr("open")) { openURL(url) }
            }
        } message: {
            Text(checkedURL?.host ?? "")
        }
    }

    private var checkedURL:URL? {
        let input=contentLink.trimmingCharacters(in:.whitespacesAndNewlines)
        guard input.count<=2048,
              let parts=URLComponents(string:input),
              parts.scheme?.lowercased()=="https",
              let host=parts.host,!host.isEmpty,
              parts.user==nil,parts.password==nil else { return nil }
        return parts.url
    }

    private func search() {
        let word=query.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !word.isEmpty,word.count<=200,
              let url=provider.url(query:word) else { return }
        recent=Array(([word]+recent.filter { $0 != word }).prefix(12))
        SharedConfig.defaults.set(recent,forKey:SharedConfig.searchHistoryKey)
        WidgetCenter.shared.reloadAllTimelines()
        openURL(url)
    }
}
