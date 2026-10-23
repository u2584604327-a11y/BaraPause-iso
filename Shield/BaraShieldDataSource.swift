import ManagedSettings
import ManagedSettingsUI
import UIKit

final class BaraShieldDataSource: ShieldConfigurationDataSource {
    private var card: ShieldConfiguration {
        let locale=SharedConfig.defaults.string(forKey:"language") ?? "system"
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1),
            icon: ArtworkStore.loadImage() ?? UIImage(systemName:"leaf.fill"),
            title: ShieldConfiguration.Label(
                text:TextKey.label("shieldTitle",lang:locale),
                color: UIColor(red:0.28,green:0.42,blue:0.32,alpha:1)
            ),
            subtitle: ShieldConfiguration.Label(
                text:TextKey.label("shieldSubtitle",lang:locale),
                color: .darkGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text:TextKey.label("shieldAction",lang:locale),color:.white),
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
