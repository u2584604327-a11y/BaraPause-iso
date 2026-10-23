# BaraPause iOS — signed iPhone IPA release checklist

An Android APK is not usable on iOS. The unsigned `.app` ZIP built by GitHub
Actions runs **only on an iOS Simulator**, not on a real iPhone.

## Before building

1. A Mac with Xcode 16 or newer. Run `xcodebuild -version`.
2. Apple Developer membership/team configured in Xcode → Settings → Accounts.
3. Register and configure **five distinct** Bundle IDs for the main App, Widget,
   Device Activity Monitor, Shield Configuration, and Share extension; replace
   the example `de.claua.barapause` identifiers in `project.yml` with your
   own unique IDs if they are not yours.
4. Register the App Group identifier used in
   `Config/*.entitlements` and `Shared/SharedConfig.swift`, and add App Group
   capability to all five app/extension targets.
5. Family Controls development entitlement and approved **distribution**
   entitlement for the main app plus its Screen Time extensions (Monitor and
   Shield). Apply the corresponding signing capabilities to each App ID and
   profile. Apple explicitly reviews Family Controls distribution requests.
6. Device provisioning profiles for your chosen release method, including all
   embedded extensions. TestFlight is a preferable beta distribution channel
   once the necessary approvals are granted.

Never share, commit or paste private keys, signing certificates, P12 passwords,
App Store Connect tokens or provisioning profiles into a public repository.

## Reproducible build from trusted Mac

```bash
brew install xcodegen cairo
python3 -m venv .venv
.venv/bin/pip install cairosvg
.venv/bin/python Scripts/build_icons.py
.venv/bin/python Scripts/static_audit.py
xcodegen generate --spec project.yml
open BaraPause.xcodeproj
```

Check all five targets in Xcode under **Signing & Capabilities**. Select your
team, verify the App Group and Family Controls setup, and test on your own iPhone.

When the device archive can be successfully code signed, choose
**Product → Archive** in Xcode, open **Window → Organizer**, then
**Distribute App**. Choose TestFlight/App Store or registered-device testing
as appropriate. Xcode handles the signing/export options.

Advanced option: Xcode's Organizer can supply an export options plist.
Run `APPLE_TEAM_ID=YOUR_TEAM EXPORT_OPTIONS_PLIST=/path/to/ExportOptions.plist
bash Scripts/archive_signed_ipa.sh` to archive and export with local signing.

## Acceptance gate

- `SIMULATOR_BUILD=PASS` does not imply `DEVICE_INSTALL=PASS`.
- `IPA_EXPORT=PASS` requires Xcode to produce an actual .ipa, including
  correct signatures and provisioning for **every extension**.
- A working Screen Time Shield on a real iPhone additionally needs user-granted
  Screen Time authorization, threshold triggering and lifecycle testing.
- The current repo does **not** contain credentials or guarantee a signed IPA.
