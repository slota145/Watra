"""Grafiki zielarstwa z PixelLab (create_1_direction_object, 64x64; identyfikatory w pixellab_src/herbs/ids.json).
Arkusze złożone przez pixelart_workbench join (pasek podpisu ucięty, ciemne tło (31, 37, 44) bez przezroczystości):
- pixellab_src/herbs/icons.png: 4x3 ikony - 6 ziół (pęczki) i 6 mikstur zielarki,
- pixellab_src/herbs/plants.png: 6x1 rośliny rosnące w świecie.
Tło usuwamy wypełnianiem od krawędzi każdej klatki. Wynik: assets/items/herb_<zioło>.png, assets/items/elixir_<zioło>.png
(ikony 64x64) i assets/herbs/<zioło>.png (rośliny 64x64; gra zmniejsza je do ok. 22 px wysokości).
Uruchom: python tools/herb_art.py"""
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "herbs")
KINDS = ["wort", "chamomile", "calamus", "arnica", "fern", "datura"]
BACKGROUND = (31, 37, 44)
CELL = 64


def clear_background(cell):
    """Przezroczyste tło: wypełnienie od krawędzi po pikselach w kolorze tła (z małą tolerancją)."""
    px = cell.load()
    w, h = cell.size
    seen = set()
    queue = deque((x, y) for x in range(w) for y in (0, h - 1))
    queue.extend((x, y) for y in range(h) for x in (0, w - 1))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if a == 0 or (abs(r - BACKGROUND[0]) + abs(g - BACKGROUND[1]) + abs(b - BACKGROUND[2]) <= 6):
            px[x, y] = (0, 0, 0, 0)
            queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return cell


def cells(sheet, columns, count):
    for i in range(count):
        x, y = (i % columns) * CELL, (i // columns) * CELL
        yield clear_background(sheet.crop((x, y, x + CELL, y + CELL)).convert("RGBA"))


def main():
    icons = list(cells(Image.open(os.path.join(SRC, "icons.png")), 4, 12))
    plants = list(cells(Image.open(os.path.join(SRC, "plants.png")), 6, 6))
    os.makedirs(os.path.join(ROOT, "assets", "herbs"), exist_ok=True)
    for i, kind in enumerate(KINDS):
        icons[i].save(os.path.join(ROOT, "assets", "items", "herb_%s.png" % kind))
        icons[6 + i].save(os.path.join(ROOT, "assets", "items", "elixir_%s.png" % kind))
        plant = plants[i]
        box = plant.getbbox()
        # roślina stoi na dole klatki - kotwica u podstawy
        canvas = Image.new("RGBA", (CELL, CELL))
        piece = plant.crop(box)
        canvas.alpha_composite(piece, ((CELL - piece.width) // 2, CELL - piece.height))
        canvas.save(os.path.join(ROOT, "assets", "herbs", "%s.png" % kind))
    print("zielarstwo: %d ziół, %d mikstur, %d roślin" % (len(KINDS), len(KINDS), len(KINDS)))


if __name__ == "__main__":
    main()
