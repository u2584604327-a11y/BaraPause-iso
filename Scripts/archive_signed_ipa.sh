#!/usr/bin/env bash
# Run only on a trusted macOS machine with a configured Apple developer identity.
# No signing secrets are consumed through source code or GitHub Actions.
set -euo pipefail

if [[ -z "${APPLE_TEAM_ID:-}" ]]; then
  echo "Set APPLE_TEAM_ID to your registered Apple Developer Team ID." >&2
  exit 2
fi
if [[ -z "${EXPORT_OPTIONS_PLIST:-}" || ! -f "${EXPORT_OPTIONS_PLIST:-}" ]]; then
  echo "Set EXPORT_OPTIONS_PLIST to an Xcode-generated export options plist." >&2
  exit 2
fi
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Xcode signing and IPA export require macOS." >&2
  exit 2
fi

command -v xcodebuild >/dev/null
command -v xcodegen >/dev/null
if [[ ! -d "BaraPause.xcodeproj" ]]; then
  xcodegen generate --spec project.yml
fi

mkdir -p artifacts
xcodebuild -project BaraPause.xcodeproj -scheme BaraPause \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/artifacts/BaraPause.xcarchive" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Automatic archive

xcodebuild -exportArchive \
  -archivePath "$PWD/artifacts/BaraPause.xcarchive" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -exportPath "$PWD/artifacts/export"

if ! find artifacts/export -maxdepth 1 -name '*.ipa' | grep -q .; then
  echo "No signed IPA exported. Review Family Controls capabilities and provisioning." >&2
  exit 3
fi
echo "SIGNED_IPA_EXPORT=PASS (verify entitlement and install on registered iPhone)"
