#!/usr/bin/env python3
"""Importeert Gemini-oefenafbeeldingen (twee standen naast elkaar) voor de app.

Gebruik:  python3 tools/import_art.py <map-of-zip-met-afbeeldingen>
Per `<slug>.png|jpg` komen er twee bestanden in SportApp/Resources/ExerciseArt:
  art-<slug>_0.jpg (beginstand) en art-<slug>_1.jpg (eindstand).
Beide helften worden met dezelfde uitsnede bijgesneden (witte rand weg), vierkant
gemaakt en verkleind. Bestaan er nog geen afbeeldingen voor een oefening, dan
toont de app de rechtenvrije foto.
"""
import sys, os, re, zipfile, tempfile, glob
from PIL import Image, ImageChops

OUT = os.path.join(os.path.dirname(__file__), "..", "SportApp", "Resources", "ExerciseArt")
SIZE = 640

def bbox_nonwhite(im):
    bg = Image.new("RGB", im.size, (255, 255, 255))
    diff = ImageChops.difference(im, bg).convert("L").point(lambda p: 255 if p > 24 else 0)
    return diff.getbbox()

def process(path):
    slug = re.sub(r"[^a-z0-9]+", "-", os.path.splitext(os.path.basename(path))[0].lower()).strip("-")
    im = Image.open(path).convert("RGB")
    w, h = im.size
    halves = [im.crop((0, 0, w // 2, h)), im.crop((w // 2, 0, w, h))]
    boxes = [bbox_nonwhite(x) for x in halves]
    boxes = [b for b in boxes if b]
    if not boxes:
        print("LEEG:", path); return
    # Zelfde uitsnede voor beide standen, zodat ze goed op elkaar aansluiten.
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    cw, ch = x1 - x0, y1 - y0
    side = int(max(cw, ch) * 1.08)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    for i, half in enumerate(halves):
        canvas = Image.new("RGB", (side, side), (255, 255, 255))
        canvas.paste(half, (side // 2 - cx, side // 2 - cy))
        canvas = canvas.resize((SIZE, SIZE), Image.LANCZOS)
        canvas.save(os.path.join(OUT, f"art-{slug}_{i}.jpg"), quality=82, optimize=True)
    print("ok:", slug)

def main(src):
    os.makedirs(OUT, exist_ok=True)
    tmp = None
    if src.lower().endswith(".zip"):
        tmp = tempfile.mkdtemp()
        zipfile.ZipFile(src).extractall(tmp)
        src = tmp
    files = [f for ext in ("png", "jpg", "jpeg") for f in glob.glob(os.path.join(src, "**", f"*.{ext}"), recursive=True)]
    for f in sorted(files):
        if os.path.basename(f).startswith("."): continue
        process(f)
    print(len(files), "afbeeldingen verwerkt")

if __name__ == "__main__":
    if len(sys.argv) != 2: sys.exit(__doc__)
    main(sys.argv[1])
