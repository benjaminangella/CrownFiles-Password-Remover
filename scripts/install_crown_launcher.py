"""Install CrownFiles' actual brand logo into generated Android launcher resources.

Source PNG was obtained from the owner's CrownFiles website at
https://crownfiles.arosoftlabs.com/branding/crownfiles-original.png
and downscaled without modifying its design. Encoded image assets are text
so they can be retained in the code repository and reproduced by CI.
"""
from pathlib import Path
import base64

for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
    source = Path(f"assets/android/ic_launcher_{density}.b64")
    target = Path(f"android/app/src/main/res/mipmap-{density}/ic_launcher.png")
    target.parent.mkdir(parents=True, exist_ok=True)
    data = base64.b64decode(source.read_text(encoding="ascii").strip(), validate=True)
    if not data.startswith(bytes.fromhex("89504e470d0a1a0a")):
        raise ValueError(f"Not a PNG: {source}")
    target.write_bytes(data)
    print(f"{density}: {len(data)} bytes")
