#!/usr/bin/env python3
"""Offline architecture and asset checks; not a substitute for xcodebuild/device testing."""
import plistlib
import struct
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
NEEDED = [
    "project.yml", "App/BaraPauseApp.swift", "App/HomeView.swift",
    "App/ScreenTimeController.swift", "App/FocusTimerView.swift",
    "App/QuickSearchView.swift", "App/PreferencesView.swift",
    "Shared/BaraStore.swift", "Widget/BaraPauseWidget.swift",
    "Monitor/ActivityMonitorExtension.swift", "Shield/BaraShieldDataSource.swift",
    "Design/capybara.svg", "Scripts/build_icons.py",
    "Config/BaraPause-Info.plist",
    "Config/BaraPause.entitlements", "Config/Widget.entitlements",
    "Config/Monitor.entitlements", "Config/Shield.entitlements",
    "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",
    "Resources/Assets.xcassets/Capybara.imageset/Capybara-1024.png",
    "Design/BaraPause-4096.png",
]
for name in NEEDED:
    assert (ROOT / name).is_file(), "Missing " + name
    print("FILE_OK", name)

def plist(name):
    with (ROOT / name).open("rb") as f:
        return plistlib.load(f)

app_info = plist("Config/BaraPause-Info.plist")
assert any("barapause" in t.get("CFBundleURLSchemes", [])
           for t in app_info.get("CFBundleURLTypes", []))
assert "group.de.claua.barapause" in plist("Config/BaraPause.entitlements")[
    "com.apple.security.application-groups"]
for name in ("Config/BaraPause.entitlements", "Config/Monitor.entitlements",
             "Config/Shield.entitlements"):
    assert plist(name).get("com.apple.developer.family-controls") is True
for name,point in [
    ("Config/Widget-Info.plist", "com.apple.widgetkit-extension"),
    ("Config/Monitor-Info.plist", "com.apple.deviceactivity.monitor-extension"),
    ("Config/Shield-Info.plist", "com.apple.ManagedSettingsUI.shield-configuration-service"),
]:
    assert plist(name)["NSExtension"]["NSExtensionPointIdentifier"] == point
    print("EXTENSION_OK", name)

ET.parse(ROOT / "Design/capybara.svg")
def size(path):
    raw = path.read_bytes()[:24]
    assert raw[:8] == b"\x89PNG\r\n\x1a\n", "Invalid PNG header: " + str(path)
    return struct.unpack(">II", raw[16:24])
for name, expected in [
    ("Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png", (1024,1024)),
    ("Resources/Assets.xcassets/Capybara.imageset/Capybara-1024.png", (1024,1024)),
    ("Design/BaraPause-4096.png", (4096,4096)),
]:
    got = size(ROOT / name)
    assert got == expected, f"{name}: expected {expected}, got {got}"
    print("PNG_OK", name, got)

swift_files = list(ROOT.glob("App/*.swift")) + list(ROOT.glob("Shared/*.swift"))
swift_files += list(ROOT.glob("Widget/*.swift")) + list(ROOT.glob("Monitor/*.swift"))
swift_files += list(ROOT.glob("Shield/*.swift"))
assert len(swift_files) >= 9
for path in swift_files:
    content = path.read_text(encoding="utf-8")
    assert content.strip() and "import " in content, "Empty Swift file: " + str(path)
assert "requestAuthorization(for: .individual)" in (
    ROOT / "App/ScreenTimeController.swift").read_text()
assert "eventDidReachThreshold" in (
    ROOT / "Monitor/ActivityMonitorExtension.swift").read_text()
assert "ShieldConfiguration(" in (
    ROOT / "Shield/BaraShieldDataSource.swift").read_text()
print(f"STATIC_AUDIT_PASS: {len(swift_files)} Swift source files, 4K asset, 3 extensions")
