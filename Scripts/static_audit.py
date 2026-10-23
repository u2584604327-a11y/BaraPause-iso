#!/usr/bin/env python3
"""Static preflight (not an iPhone or Xcode build verification)."""
import plistlib
import struct
import re
from pathlib import Path
from xml.etree import ElementTree as ET

root=Path(__file__).resolve().parent.parent
source_paths=[
    "App/BaraPauseApp.swift","App/RootView.swift","App/CapyMascot.swift",
    "App/FocusView.swift","App/ScreenTimeController.swift","App/ScreenTimeView.swift",
    "App/QuickSearchView.swift","App/SettingsView.swift",
    "Shared/SharedConfig.swift","Shared/Localization.swift",
    "Monitor/ActivityMonitorExtension.swift","Shield/BaraShieldDataSource.swift",
    "Widget/BaraWidget.swift", "Share/ShareReceiverController.swift",
]
required=source_paths+[
    "project.yml",".github/workflows/ios-simulator.yml",
    "Design/capybara.svg","Scripts/build_icons.py",
    "Config/BaraPause-Info.plist","Config/BaraPause.entitlements",
    "Config/Widget.entitlements","Config/Monitor.entitlements",
    "Config/Shield.entitlements","Config/Share.entitlements","Config/Widget-Info.plist",
    "Config/Monitor-Info.plist","Config/Shield-Info.plist","Config/Share-Info.plist",
    "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",
    "Resources/Assets.xcassets/Capybara.imageset/Capybara-1024.png",
    "Design/BaraPause-4096.png"
]
for path in required:
    assert (root/path).is_file(),f"Missing: {path}"

def plist(path):
    with (root/path).open("rb") as f:
        return plistlib.load(f)

assert any("barapause" in t.get("CFBundleURLSchemes",[])
           for t in plist("Config/BaraPause-Info.plist").get("CFBundleURLTypes",[]))
for name in ["BaraPause","Monitor","Shield"]:
    p=plist(f"Config/{name}.entitlements")
    assert p.get("com.apple.developer.family-controls") is True, name
for name in ["BaraPause","Widget","Monitor","Shield","Share"]:
    p=plist(f"Config/{name}.entitlements")
    assert "group.de.claua.barapause" in p.get("com.apple.security.application-groups",[]), name

for name,point in [
    ("Widget-Info.plist","com.apple.widgetkit-extension"),
    ("Monitor-Info.plist","com.apple.deviceactivity.monitor-extension"),
    ("Shield-Info.plist","com.apple.ManagedSettingsUI.shield-configuration-service"),
    ("Share-Info.plist","com.apple.share-services")
]:
    assert plist(f"Config/{name}")["NSExtension"]["NSExtensionPointIdentifier"]==point

ET.parse(root/"Design/capybara.svg")
for path,expected in [
    ("Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",(1024,1024)),
    ("Resources/Assets.xcassets/Capybara.imageset/Capybara-1024.png",(1024,1024)),
    ("Design/BaraPause-4096.png",(4096,4096))
]:
    b=(root/path).read_bytes()
    assert b[:8]==b"\x89PNG\r\n\x1a\n"
    assert struct.unpack(">II",b[16:24])==expected, path

swift_files=list(root.glob("App/*.swift"))+list(root.glob("Shared/*.swift"))
swift_files+=list(root.glob("Widget/*.swift"))+list(root.glob("Monitor/*.swift"))
swift_files+=list(root.glob("Shield/*.swift"))+list(root.glob("Share/*.swift"))
names={}
for file in swift_files:
    content=file.read_text(encoding="utf-8")
    assert content.strip().startswith(("import ","//")),file
    for name in re.findall(r"(?m)^\s*(?:(?:@MainActor|final|private|public|internal)\s+)*(?:struct|class|enum)\s+(\w+)",content):
        assert name not in names,f"Duplicate Swift type {name}: {names.get(name)} and {file}"
        names[name]=str(file.relative_to(root))
screen=(root/"App/ScreenTimeController.swift").read_text(encoding="utf-8")
assert "requestAuthorization(for: .individual)" in screen
assert "startMonitoring(" in screen
assert "eventDidReachThreshold" in (root/"Monitor/ActivityMonitorExtension.swift").read_text(encoding="utf-8")
assert "ShieldConfiguration(" in (root/"Shield/BaraShieldDataSource.swift").read_text(encoding="utf-8")
assert "@main" in (root/"Widget/BaraWidget.swift").read_text(encoding="utf-8")
assert "@main" in (root/"App/BaraPauseApp.swift").read_text(encoding="utf-8")
print("STATIC_AUDIT_PASS",len(swift_files),"Swift files, 4K vector master, 4 extensions, no duplicate public types")
