"""Ikona encyklopedii na pasku ikon (prawy dolny róg ekranu) z PixelLab (create_1_direction_object; identyfikator
w pixellab_src/codex/ids.json). Arkusz pixellab_src/codex/icons.png (4 propozycje 64x64, złożone przez
pixelart_workbench join) - wybrana jest trzecia: otwarta księga z rysunkiem potwora i miecza.
Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki (herb_art.cells). Wynik: assets/ui/codex.png.
Uruchom: python tools/codex_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHOSEN = 2


def main():
    icons = list(cells(Image.open(os.path.join(ROOT, "pixellab_src", "codex", "icons.png")), 4, 4))
    icons[CHOSEN].save(os.path.join(ROOT, "assets", "ui", "codex.png"))
    print("encyklopedia: ikona")


if __name__ == "__main__":
    main()
