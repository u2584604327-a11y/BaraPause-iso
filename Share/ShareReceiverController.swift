import UIKit
import UniformTypeIdentifiers
import Foundation

/// Minimal user-driven share target. It saves a URL for review in BaraPause,
/// but never launches it directly from the extension.
final class ShareReceiverController: UIViewController {
    private let message=UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let title=UILabel()
        title.text="BaraPause · 收藏内容链接"
        title.textAlignment = .center
        title.font=UIFont.preferredFont(forTextStyle:.title2)
        message.text="仅保存 HTTPS 链接；下次打开 BaraPause 时确认跳转。"
        message.numberOfLines=0
        message.textAlignment = .center
        message.textColor = .secondaryLabel
        let save=UIButton(type:.system)
        save.setTitle("保存到 BaraPause",for:.normal)
        save.titleLabel?.font=UIFont.preferredFont(forTextStyle:.headline)
        save.addTarget(self,action:#selector(saveLink),for:.touchUpInside)
        let close=UIButton(type:.system)
        close.setTitle("取消",for:.normal)
        close.addTarget(self,action:#selector(closeSheet),for:.touchUpInside)
        let stack=UIStackView(arrangedSubviews:[title,message,save,close])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:24),
            stack.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-24),
            stack.centerYAnchor.constraint(equalTo:view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    @objc private func saveLink() {
        let providers=(extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        guard let provider=providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) ||
            $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        }) else {
            message.text="未检测到可处理的网页链接。"
            return
        }
        let type=provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            ? UTType.url.identifier : UTType.plainText.identifier
        provider.loadItem(forTypeIdentifier:type,options:nil) { [weak self] item,_ in
            let raw=(item as? URL)?.absoluteString ??
                (item as? NSString).map(String.init) ?? ""
            DispatchQueue.main.async {
                guard let self=self else { return }
                guard let link=Self.extractHTTPS(raw) else {
                    self.message.text="分享内容不包含合法 HTTPS 链接。"
                    return
                }
                guard let defaults=UserDefaults(suiteName:SharedConfig.groupID) else {
                    self.message.text="App Group 不可用，链接未保存。"
                    return
                }
                defaults.set(link,forKey:"sharedIncomingLink")
                self.extensionContext?.completeRequest(returningItems:[],completionHandler:nil)
            }
        }
    }

    static func extractHTTPS(_ text:String)->String? {
        guard text.count<=10_000 else { return nil }
        for candidate in text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }) {
            let raw=String(candidate).trimmingCharacters(in:CharacterSet(charactersIn:"()[]<>，。,;"))
            guard raw.count<=2048,
                  let c=URLComponents(string:raw),
                  c.scheme?.lowercased()=="https",let host=c.host,!host.isEmpty,
                  c.user==nil,c.password==nil,c.url != nil else { continue }
            return raw
        }
        return nil
    }
    @objc private func closeSheet() {
        extensionContext?.completeRequest(returningItems:[],completionHandler:nil)
    }
}
