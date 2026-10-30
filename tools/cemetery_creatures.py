"""Arkusze ptaków i zjaw Leśnego Cmentarza z PixelLab (pixellab_src/cemetery/<nazwa>/frame_0..7.png - klatki animacji
obiektów PixelLab z przezroczystym tłem): kruk w locie widziany z góry (głową w prawo, 8 klatek machania), kruk
na ziemi (bokiem, 8 klatek dziobania i rozglądania się) i duch (8 klatek unoszenia się). Klatki zmniejszamy jak
postacie (hero_sheets.shrink_image) i przycinamy do wspólnej sylwetki wszystkich klatek - położenie na płótnie
zostaje, więc stworzenie nie skacze między klatkami.
Wynik: assets/cemetery/crow_fly.png, crow_perch.png, ghost.png (klatki w jednym rzędzie, kwadratowe komórki).
Uruchom: python tools/cemetery_creatures.py"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "cemetery")
OUT = os.path.join(ROOT, "assets", "cemetery")

# nazwa: rozmiar komórki w grze (px)
SHEETS = {"crow_fly": 22, "crow_perch": 18, "ghost": 34}


def build(name, cell):
    frames = [Image.open(os.path.join(SRC, name, "frame_%d.png" % i)).convert("RGBA") for i in range(8)]
    small = [hero_sheets.shrink_image(f, cell, cell) for f in frames]
    sheet = Image.new("RGBA", (cell * len(small), cell))
    for k, img in enumerate(small):
        sheet.alpha_composite(img, (k * cell, 0))
    sheet.save(os.path.join(OUT, name + ".png"))
    print(name, sheet.size)


def main():
    for name, cell in SHEETS.items():
        build(name, cell)


if __name__ == "__main__":
    main()
