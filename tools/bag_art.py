"""Ikony toreb z łupu (scripts/bags.gd) z PixelLab (create_1_direction_object, 64 px).
Arkusz pixellab_src/bags/sheet.png (złożony przez pixelart_workbench join, z paskiem podpisu u góry): Mieszek,
Skórzana sakwa, Torba wędrowca, Plecak łowcy, Plecak wyprawowy, Legendarny tobół.
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.clear_background).
Wynik: assets/items/bag_*.png.
Uruchom: python tools/bag_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL = 64
NAMES = ["bag_purse", "bag_satchel", "bag_wanderer", "bag_hunter", "bag_expedition", "bag_legendary"]


def main():
    sheet = Image.open(os.path.join(ROOT, "pixellab_src", "bags", "sheet.png")).convert("RGBA")
    top = sheet.height - CELL
    for i, name in enumerate(NAMES):
        icon = clear_background(sheet.crop((i * CELL, top, (i + 1) * CELL, top + CELL)))
        icon.save(os.path.join(ROOT, "assets", "items", name + ".png"))
    print("torby: %d ikon" % len(NAMES))


if __name__ == "__main__":
    main()
