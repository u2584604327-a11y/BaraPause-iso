# BaraPause for iOS 🦫🌱

**A gentle pause for mindless scrolling — now being developed for iPhone.**

BaraPause for iOS is the native SwiftUI companion to the [BaraPause Android app](https://github.com/u2584604327-a11y/sbara). It is designed to help you notice how long you spend in selected apps and make an intentional choice about when to take a break.

Instead of reproducing Android's cross-app overlays, the iOS edition uses Apple's **Screen Time** frameworks and a customizable system **Shield**.

## Planned and implemented in the development source

- **Screen Time controls:** use `FamilyControls` to select apps, categories, and websites and `DeviceActivity` to monitor configured usage thresholds.
- **System reminders:** apply `ManagedSettings` Shields when a selected usage threshold is reached, subject to Apple authorization and real-device support.
- **A capybara companion:** a SwiftUI mascot with in-app animation, plus customizable static Shield artwork.
- **Focus sessions:** start a temporary timer with adjustable durations.
- **Up to eight local profiles:** save different choices, time limits, languages, and appearance settings for study and daily routines.
- **Home-screen widgets:** shortcuts to focus and search, built with WidgetKit.
- **Quick search and links:** web search, HTTPS links, and an iOS share extension for saving links to review.
- **Local settings and language options:** JSON export/import for portable basic preferences, light/dark/eye-comfort themes, and support for Chinese, English, and Japanese.

Screen Time selections use Apple-managed anonymous tokens. These cannot be treated as a portable list of installed apps and are deliberately excluded from exported settings.

## Current status: iOS Simulator build available

**A real Xcode-based Simulator build has succeeded.** The project includes the main app and its Widget, Device Activity Monitor, Shield, and Share extensions.

- [Current iOS development branch](https://github.com/u2584604327-a11y/BaraPause-iso/tree/feature/ios-v1_2-simulator-package-signing)
- [Verified iOS Simulator build](https://github.com/u2584604327-a11y/BaraPause-iso/actions/runs/39890663055)
- [Signed IPA build instructions](https://github.com/u2584604327-a11y/BaraPause-iso/blob/feature/ios-v1_2-simulator-package-signing/docs/BUILD_SIGNED_IPA.md)

**There is no verified, signed IPA for physical iPhones yet.** An unsigned Simulator `.app` cannot be installed on a real iPhone. Physical-device distribution requires an Apple Developer signing setup, App Groups, and the appropriate **Family Controls entitlements**. Screen Time behavior, persistence, and profile switching still need real-device acceptance testing.

> The default `main` branch is an entry point for project information and workflows. Current application source is maintained in the development branches linked above.

## Build the iOS project

On a Mac with Xcode 16+, Python 3, XcodeGen, and CairoSVG:

```bash
python3 Scripts/build_icons.py
xcodegen generate --spec project.yml
open BaraPause.xcodeproj
```

Run these commands from the **iOS development branch**, not the minimal `main` branch. Before attempting an iPhone archive, configure your own Apple Developer Team, signing identities, App Group, and Screen Time capabilities for the main app and relevant extensions.

## Privacy and platform limitations

BaraPause is designed around local configuration and system-managed Screen Time controls. iOS does not permit third-party apps to place unrestricted floating reminders over other apps, enumerate every installed app without authorization, or navigate arbitrary private search interfaces.

**Your time, your choice — with a little help from a capybara.**
