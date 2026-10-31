"""Ikony run do warsztatu kowala (scripts/item_craft.gd) z PixelLab (create_1_direction_object; identyfikator
w pixellab_src/runes/ids.json). Arkusz pixellab_src/runes/runes.png (4 ikony 64x64, złożone przez pixelart_workbench join):
Runa Zmiany (pierwsza), Runa Pieczęci (druga); dwie ostatnie to warianty zapasowe.
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.cells).
Wynik: assets/items/rune_chaos.png, assets/items/rune_seal.png.
Uruchom: python tools/rune_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    icons = list(cells(Image.open(os.path.join(ROOT, "pixellab_src", "runes", "runes.png")), 4, 4))
    icons[0].save(os.path.join(ROOT, "assets", "items", "rune_chaos.png"))
    icons[1].save(os.path.join(ROOT, "assets", "items", "rune_seal.png"))
    print("runy: Zmiany, Pieczęci")


if __name__ == "__main__":
    main()
