"""Grafiki Kryształu Watry (zdarzenie w lochach, scripts/watra_crystal.gd) z PixelLab (create_1_direction_object;
identyfikatory w pixellab_src/crystal/ids.json), złożone przez pixelart_workbench join:
- pixellab_src/crystal/crystal_v2.png (4 klatki 96x96): kryształ, kryształ przygasły (pęknięty), gruz po rozbitym
  krysztale - cała skalna podstawa mieści się w klatce (w pierwszej wersji 64x64 była ucięta na dole),
- pixellab_src/crystal/objects.png (6 klatek 64x64): stąd górnik z kilofem w górze i w uderzeniu.
Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki (herb_art.clear_background), a klatki są przycięte
do zawartości (górnik - obie klatki do wspólnego prostokąta, żeby nie skakał).
Wynik: assets/crystal/<nazwa>.png. Uruchom: python tools/crystal_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells, clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CRYSTALS = ["crystal", "crystal_dim", "rubble"]
BIG = 96


def main():
    out = os.path.join(ROOT, "assets", "crystal")
    os.makedirs(out, exist_ok=True)
    sheet = Image.open(os.path.join(ROOT, "pixellab_src", "crystal", "crystal_v2.png"))
    for i, name in enumerate(CRYSTALS):
        cell = clear_background(sheet.crop((i * BIG, 0, (i + 1) * BIG, BIG)).convert("RGBA"))
        cell.crop(cell.getbbox()).save(os.path.join(out, name + ".png"))
    # górnik: wspólny prostokąt obu klatek
    frames = list(cells(Image.open(os.path.join(ROOT, "pixellab_src", "crystal", "objects.png")), 6, 4))
    boxes = [frames[2].getbbox(), frames[3].getbbox()]
    box = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    for i, name in ((2, "miner_up"), (3, "miner_down")):
        frames[i].crop(box).save(os.path.join(out, name + ".png"))
    print("Kryształ Watry: %d grafik" % (len(CRYSTALS) + 2))


if __name__ == "__main__":
    main()
