#!/usr/bin/env python3
"""Generate original, sharp PNG assets from a hand-authored, resolution-independent SVG."""
import json
from pathlib import Path
from xml.etree import ElementTree as ET

try:
    import cairosvg
except ImportError as exc:
    raise SystemExit("Install CairoSVG: python3 -m pip install cairosvg") from exc

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Design" / "capybara.svg"
CATALOG = ROOT / "Resources" / "Assets.xcassets"
ET.parse(SOURCE)

def png(path: Path, px: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(url=str(SOURCE), write_to=str(path), output_width=px, output_height=px)
    print(f"{path.relative_to(ROOT)} {path.stat().st_size} bytes")

def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

icon = CATALOG / "AppIcon.appiconset"
png(icon / "AppIcon-1024.png", 1024)
write_json(icon / "Contents.json", {
    "images": [{"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1}
})
mascot = CATALOG / "Capybara.imageset"
png(mascot / "Capybara-1024.png", 1024)
write_json(mascot / "Contents.json", {
    "images": [{"filename": "Capybara-1024.png", "idiom": "universal"}],
    "info": {"author": "xcode", "version": 1}
})
png(ROOT / "Design" / "BaraPause-4096.png", 4096)
print("Done: vector source + 1024 app assets + native 4K master")
