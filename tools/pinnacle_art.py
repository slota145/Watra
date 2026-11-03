"""Grafiki bossów szczytowych Mapy Nawii (scripts/pinnacles.gd) z PixelLab.
Źródła w pixellab_src/pinnacles/:
- <bóg>.png (weles, marzanna, czarnobog, horde - Władca Hordy) - arkusz z pixelart_workbench join (pasek podpisu u góry, 18 klatek 160 px
  w 6 kolumnach): klatki 0-8 to spoczynek, 9-17 atak (create_1_direction_object 160 px + 2x animate_object v3),
- icons/<nazwa>.png - ikony 64 px (podglądy kandydatów z get_object, już przezroczyste): fragmenty kluczy i serca
  bogów (assets/items/pinnacle_<...>.png) oraz legendy (assets/items/legends/<legenda>.png),
- props/horde_statue.png - posąg Władcy Hordy w Ostoi (assets/village/horde_statue.png).
Ciemne tło arkuszy znika wypełnianiem od krawędzi klatki (herb_art.clear_background).
Wynik: assets/pinnacles/<bóg>.png - 18 klatek w rzędzie.
Uruchom: python tools/pinnacle_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "pinnacles")
CELL = 160
COLUMNS = 6
FRAMES = 18
GODS = ["weles", "marzanna", "czarnobog", "horde"]


def sheets():
    os.makedirs(os.path.join(ROOT, "assets", "pinnacles"), exist_ok=True)
    for god in GODS:
        sheet = Image.open(os.path.join(SRC, god + ".png")).convert("RGBA")
        top = sheet.height - 3 * CELL
        out = Image.new("RGBA", (CELL * FRAMES, CELL))
        for i in range(FRAMES):
            x, y = (i % COLUMNS) * CELL, top + (i // COLUMNS) * CELL
            out.alpha_composite(clear_background(sheet.crop((x, y, x + CELL, y + CELL))), (i * CELL, 0))
        out.save(os.path.join(ROOT, "assets", "pinnacles", god + ".png"))
        print("%s: %d klatek" % (god, FRAMES))


def icons():
    folder = os.path.join(SRC, "icons")
    for name in sorted(os.listdir(folder)):
        icon = Image.open(os.path.join(folder, name)).convert("RGBA")
        if name.startswith("legend_"):
            target = os.path.join(ROOT, "assets", "items", "legends", name)
        else:
            target = os.path.join(ROOT, "assets", "items", "pinnacle_" + name)
        icon.save(target)
        print("ikona:", os.path.relpath(target, ROOT))


def props():
    src = os.path.join(SRC, "props", "horde_statue.png")
    Image.open(src).convert("RGBA").save(os.path.join(ROOT, "assets", "village", "horde_statue.png"))
    print("posąg: assets/village/horde_statue.png")


if __name__ == "__main__":
    sheets()
    icons()
    props()
