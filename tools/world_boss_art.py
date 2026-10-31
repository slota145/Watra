"""Arkusze world bossów (scripts/world_boss.gd) z PixelLab (create_1_direction_object 160 px + animate_object v3).
Źródła w pixellab_src/world_bosses/ (złożone przez pixelart_workbench join, z paskiem podpisu u góry):
- zmij.png - Żmij Gorynycz, 8 klatek machania skrzydłami (4x2),
- wij.png - Wij, 9 klatek unoszenia powiek (5x2, ostatnia komórka pusta).
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.clear_background).
Wynik: assets/world_bosses/zmij.png (8 klatek w rzędzie), assets/world_bosses/wij.png (9 klatek w rzędzie).
Uruchom: python tools/world_boss_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL = 160
SHEETS = {"zmij": (4, 8), "wij": (5, 9)}


def main():
    for name, (columns, count) in SHEETS.items():
        sheet = Image.open(os.path.join(ROOT, "pixellab_src", "world_bosses", name + ".png")).convert("RGBA")
        top = sheet.height - 2 * CELL
        out = Image.new("RGBA", (CELL * count, CELL))
        for i in range(count):
            x, y = (i % columns) * CELL, top + (i // columns) * CELL
            out.alpha_composite(clear_background(sheet.crop((x, y, x + CELL, y + CELL))), (i * CELL, 0))
        out.save(os.path.join(ROOT, "assets", "world_bosses", name + ".png"))
        print("%s: %d klatek" % (name, count))


if __name__ == "__main__":
    main()
