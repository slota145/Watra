"""Ikony kamieni szlachetnych (scripts/gems.gd) z PixelLab (create_1_direction_object; identyfikatory
w pixellab_src/gems/ids.json). Arkusze pixellab_src/gems/gems_1.png i gems_2.png (po 16 ikon 64x64, 8 kolumn,
złożone przez pixelart_workbench join): rubin, szafir, szmaragd, potem topaz, ametyst, onyks - każdy w 5 szlifach
(okruch, odłamek, kamień, szlifowany, królewski); na końcu surowy klejnot (zadanie jubilera) i puste gniazdo.
Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki (herb_art.cells).
Wynik: assets/items/gems/<rodzaj>_<szlif 1-5>.png, assets/items/rough_gem.png, assets/ui/socket.png.
Uruchom: python tools/gem_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = [("gems_1.png", ["ruby", "sapphire", "emerald"], "rough_gem"), ("gems_2.png", ["topaz", "amethyst", "onyx"], "socket")]


def main():
    out = os.path.join(ROOT, "assets", "items", "gems")
    os.makedirs(out, exist_ok=True)
    for sheet, kinds, extra in SHEETS:
        icons = list(cells(Image.open(os.path.join(ROOT, "pixellab_src", "gems", sheet)), 8, 16))
        for k, kind in enumerate(kinds):
            for cut in range(5):
                icons[k * 5 + cut].save(os.path.join(out, "%s_%d.png" % (kind, cut + 1)))
        target = ("items", "rough_gem.png") if extra == "rough_gem" else ("ui", "socket.png")
        icons[15].save(os.path.join(ROOT, "assets", *target))
    print("kamienie szlachetne: 30 ikon, surowy klejnot, gniazdo")


if __name__ == "__main__":
    main()
