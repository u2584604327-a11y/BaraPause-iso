import Foundation
import UIKit
import ManagedSettings
import ManagedSettingsUI

/// System-owned Screen Time shield; no always-on overlay or continuous third-party animation.
final class BaraShieldDataSource: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeShield()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeShield()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeShield()
    }

    private func makeShield() -> ShieldConfiguration {
        let green = UIColor(red: 0.31, green: 0.52, blue: 0.34, alpha: 1)
        let cocoa = UIColor(red: 0.33, green: 0.24, blue: 0.20, alpha: 1)
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(red: 0.99, green: 0.95, blue: 0.87, alpha: 1),
            icon: UIImage(systemName: "leaf.circle.fill"),
            title: .init(text: "BaraPause · 休息一下", color: cocoa),
            subtitle: .init(text: "今天给这个 App 的使用时间已经到了。回去做一件更重要的事吧。", color: cocoa),
            primaryButtonLabel: .init(text: "知道了", color: .white),
            primaryButtonBackgroundColor: green,
            secondaryButtonLabel: nil
        )
    }
}
