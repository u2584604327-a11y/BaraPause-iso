import ManagedSettings
import ManagedSettingsUI
import UIKit

final class BaraShieldDataSource: ShieldConfigurationDataSource {
    private var card: ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1),
            icon: UIImage(systemName:"leaf.fill"),
            title: ShieldConfiguration.Label(
                text:"BaraPause · 休息一下",
                color: UIColor(red:0.28,green:0.42,blue:0.32,alpha:1)
            ),
            subtitle: ShieldConfiguration.Label(
                text:"今日使用时间达到设定限额。现在适合回到专注任务。",
                color: .darkGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text:"知道了",color:.white),
            primaryButtonBackgroundColor: UIColor(red:0.37,green:0.57,blue:0.42,alpha:1)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration { card }
    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration { card }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { card }
    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration { card }
}
