"""Grafiki Kryształu Watry (zdarzenie w lochach, scripts/watra_crystal.gd) z PixelLab (create_1_direction_object;
identyfikator w pixellab_src/crystal/ids.json). Arkusz pixellab_src/crystal/objects.png (6 klatek 64x64, złożone
przez pixelart_workbench join): kryształ, kryształ przygasły (pęknięty), górnik z kilofem w górze, górnik w uderzeniu,
odłamek, gruz po rozbitym krysztale. Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki
(herb_art.cells), a klatki są przycięte do zawartości (górnik - obie klatki do wspólnego prostokąta, żeby nie skakał).
Wynik: assets/crystal/<nazwa>.png. Uruchom: python tools/crystal_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAMES = ["crystal", "crystal_dim", "miner_up", "miner_down", "shard", "rubble"]


def main():
    frames = list(cells(Image.open(os.path.join(ROOT, "pixellab_src", "crystal", "objects.png")), 6, 6))
    out = os.path.join(ROOT, "assets", "crystal")
    os.makedirs(out, exist_ok=True)
    for i, name in enumerate(NAMES):
        if name.startswith("miner"):
            continue
        frames[i].crop(frames[i].getbbox()).save(os.path.join(out, name + ".png"))
    # górnik: wspólny prostokąt obu klatek
    boxes = [frames[2].getbbox(), frames[3].getbbox()]
    box = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    for i in (2, 3):
        frames[i].crop(box).save(os.path.join(out, NAMES[i] + ".png"))
    print("Kryształ Watry: %d grafik" % len(NAMES))


if __name__ == "__main__":
    main()
