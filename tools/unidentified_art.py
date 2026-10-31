"""Ikony przedmiotów niezidentyfikowanych (scripts/unidentified.gd) z PixelLab (create_1_direction_object, 64 px).
Arkusz pixellab_src/unidentified/sheet.png (złożony przez pixelart_workbench join, z paskiem podpisu u góry):
broń, zbroja i biżuteria zawinięte w płótno z woskową pieczęcią.
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.clear_background).
Wynik: assets/items/unid_weapon.png, unid_armor.png, unid_jewelry.png.
Uruchom: python tools/unidentified_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL = 64
NAMES = ["unid_weapon", "unid_armor", "unid_jewelry"]


def main():
    sheet = Image.open(os.path.join(ROOT, "pixellab_src", "unidentified", "sheet.png")).convert("RGBA")
    top = sheet.height - CELL
    for i, name in enumerate(NAMES):
        icon = clear_background(sheet.crop((i * CELL, top, (i + 1) * CELL, top + CELL)))
        icon.save(os.path.join(ROOT, "assets", "items", name + ".png"))
    print("przedmioty niezidentyfikowane: %d ikony" % len(NAMES))


if __name__ == "__main__":
    main()
