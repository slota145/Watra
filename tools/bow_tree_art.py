"""Grafiki drzewka łuku z PixelLab (create_1_direction_object; identyfikatory w pixellab_src/bow_tree/ids.json).
- pixellab_src/bow_tree/icons.png (4x4 ikon 64x64, złożone przez pixelart_workbench join): umiejętności, węzły
  kluczowe (ks_*), ikony węzłów pasywnych (node_*) i dwie legendy z lochów. Część ikon PixelLab podpisał na dolnej
  ramce - pasek ramki (wiersze 57-62) bierzemy wtedy z czystej ikony 0. Wynik: assets/skills/<nazwa>.png
  i assets/items/legends/<legenda>.png.
- pixellab_src/bow_tree/objects.png (5 klatek 64x64): balista, sokół w locie, otwarte i zatrzaśnięte sidła (bełt nieużywany)
  - przycięte do zawartości w assets/bow/<nazwa>.png.
Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki (herb_art.cells).
Uruchom: python tools/bow_tree_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "bow_tree")
ICONS = ["power_shot", "arrow_rain", "vault", "snare", "falcon", "venom_arrows", "wind_arrow", "ballista",
         "ks_falcon_eye", "ks_hail", "ks_shadow_hunter", "ks_running_fire", "node_pierce", "node_range",
         "legend_swarog_bow", "legend_engineer_gloves"]
## Ikony z podpisem na dolnej ramce.
CAPTIONED = range(8, 16)
OBJECTS = ["ballista", "falcon", "snare_open", "snare_closed"]


def main():
    icons = list(cells(Image.open(os.path.join(SRC, "icons.png")), 4, len(ICONS)))
    band = icons[0].crop((6, 57, 58, 63))
    os.makedirs(os.path.join(ROOT, "assets", "items", "legends"), exist_ok=True)
    for i, (name, icon) in enumerate(zip(ICONS, icons)):
        if i in CAPTIONED:
            icon.paste(band, (6, 57))
        folder = ("items", "legends") if name.startswith("legend_") else ("skills",)
        icon.save(os.path.join(ROOT, "assets", *folder, name + ".png"))
    os.makedirs(os.path.join(ROOT, "assets", "bow"), exist_ok=True)
    for name, sprite in zip(OBJECTS, cells(Image.open(os.path.join(SRC, "objects.png")), 5, len(OBJECTS))):
        sprite.crop(sprite.getbbox()).save(os.path.join(ROOT, "assets", "bow", name + ".png"))
    print("drzewko łuku: %d ikon, %d obiektów" % (len(ICONS), len(OBJECTS)))


if __name__ == "__main__":
    main()
