"""Grafiki losowych wydarzeń w świecie (scripts/world_events.gd, scripts/event_site.gd) z PixelLab
(create_1_direction_object, 64 px). Arkusz pixellab_src/events/sheet.png (złożony przez pixelart_workbench join,
z paskiem podpisu u góry): trzy odmiany meteorytu, spadający meteoryt, Znak Zwycięstwa.
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.clear_background).
Wynik: assets/events/meteor_0..2.png, assets/events/meteor_fall.png, assets/items/victory_mark.png.
Uruchom: python tools/event_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL = 64
HEADER = 18


def main():
    sheet = Image.open(os.path.join(ROOT, "pixellab_src", "events", "sheet.png")).convert("RGBA")
    top = sheet.height - CELL if sheet.height > CELL else 0
    frames = [clear_background(sheet.crop((i * CELL, top, (i + 1) * CELL, top + CELL))) for i in range(5)]
    out = os.path.join(ROOT, "assets", "events")
    os.makedirs(out, exist_ok=True)
    for i in range(3):
        frames[i].save(os.path.join(out, "meteor_%d.png" % i))
    frames[3].save(os.path.join(out, "meteor_fall.png"))
    frames[4].save(os.path.join(ROOT, "assets", "items", "victory_mark.png"))
    print("wydarzenia: 3 meteoryty, spadający meteoryt, Znak Zwycięstwa")


if __name__ == "__main__":
    main()
