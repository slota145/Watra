"""Grafiki widoku ekwipunku (scripts/ui/inventory_window.gd) z PixelLab (create_1_direction_object; identyfikatory
w pixellab_src/ui/paperdoll/ids.json):
- pixellab_src/ui/paperdoll/icons.png (16 zarysów 64x64, 8 kolumn): zarysy przedmiotów w pustych miejscach na postaci
  -> assets/ui/slot_<rodzaj>.png (hełm, broń, napierśnik, rękawice, buty, pas, pierścień, kolczyk, naszyjnik);
- pixellab_src/ui/paperdoll/silhouette.png (2 sylwetki 128x128): sylwetka wojownika za miejscami
  -> assets/ui/paperdoll.png (pierwsza, przycięta).
Tło arkusza znika: w zarysach w całej klatce, w sylwetce - wypełnianiem od krawędzi (kolor z rogu klatki).
Uruchom: python tools/paperdoll_art.py"""
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "ui", "paperdoll")
UI = os.path.join(ROOT, "assets", "ui")
SLOTS = ["helmet", "weapon", "chest", "gloves", "boots", "belt", "ring", "earring", "necklace"]


def clear(cell, tolerance=10):
    """Przezroczyste tło: wypełnienie od krawędzi po pikselach w kolorze rogu klatki."""
    px = cell.load()
    w, h = cell.size
    bg = px[0, 0][:3]
    seen = set()
    queue = deque((x, y) for x in range(w) for y in (0, h - 1))
    queue.extend((x, y) for y in range(h) for x in (0, w - 1))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if a == 0 or abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) <= tolerance:
            px[x, y] = (0, 0, 0, 0)
            queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return cell


def key(cell, tolerance=14):
    """Zarysy to jasne linie: tło znika w całej klatce (także w zamkniętych polach, np. w środku pierścienia)."""
    px = cell.load()
    bg = px[0, 0][:3]
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = px[x, y]
            if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) <= tolerance:
                px[x, y] = (0, 0, 0, 0)
    return cell


def main():
    icons = Image.open(os.path.join(SRC, "icons.png")).convert("RGBA")
    for i, slot in enumerate(SLOTS):
        x, y = (i % 8) * 64, (i // 8) * 64
        clear(key(icons.crop((x, y, x + 64, y + 64)))).save(os.path.join(UI, "slot_%s.png" % slot))
    figure = clear(Image.open(os.path.join(SRC, "silhouette.png")).convert("RGBA").crop((0, 0, 128, 128)))
    figure.crop(figure.getbbox()).save(os.path.join(UI, "paperdoll.png"))
    print("ekwipunek: %d zarysów, sylwetka" % len(SLOTS))


if __name__ == "__main__":
    main()
