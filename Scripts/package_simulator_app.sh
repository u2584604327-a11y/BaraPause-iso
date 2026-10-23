#!/usr/bin/env bash
set -euo pipefail

app="DerivedData/Build/Products/Debug-iphonesimulator/BaraPause.app"
output="artifacts"
if [[ ! -d "$app" ]]; then
  echo "ERROR: Compiled simulator BaraPause.app not found at $app" >&2
  exit 2
fi
if [[ ! -f "$app/Info.plist" || ! -x "$app/BaraPause" ]]; then
  echo "ERROR: Compiled .app has no valid Info.plist or executable" >&2
  exit 2
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")"
if [[ "$bundle_id" != "de.claua.barapause" ]]; then
  echo "ERROR: Unexpected bundle identifier: $bundle_id" >&2
  exit 2
fi

count=0
for extension in "$app"/PlugIns/*.appex; do
  if [[ -d "$extension" ]]; then
    count=$((count+1))
  fi
done
if [[ $count -ne 4 ]]; then
  echo "ERROR: Expected Widget, Monitor, Shield and Share extensions; found $count" >&2
  exit 2
fi

mkdir -p "$output"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app" "$output/BaraPause-iOS-Simulator.app.zip"
shasum -a 256 "$output/BaraPause-iOS-Simulator.app.zip" > "$output/SHA256SUMS.txt"
cat > "$output/README.txt" <<'EOF'
BaraPause iOS Simulator bundle
=============================
This ZIP contains a genuine Xcode-compiled, UNSIGNED iOS SIMULATOR .app.
It cannot be installed on a physical iPhone and is NOT an IPA.
To run, extract on macOS, launch iOS Simulator in Xcode, then:
    xcrun simctl install booted BaraPause.app
    xcrun simctl launch booted de.claua.barapause

For a REAL iPhone IPA, configure Apple Developer signing, App Groups and
Family Controls entitlements for the app and its Screen Time extensions.
See docs/BUILD_SIGNED_IPA.md. Keep signing credentials out of this repo.
EOF
test -s "$output/BaraPause-iOS-Simulator.app.zip"
echo "SIMULATOR_BUNDLE=PASS"
echo "BUNDLE_ID=$bundle_id"
echo "EMBEDDED_EXTENSIONS=$count"
cat "$output/SHA256SUMS.txt"
