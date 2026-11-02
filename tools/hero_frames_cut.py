"""Klatki animacji postaci gracza z PixelLab, złożone przez `pixelart_workbench join ... --as sheet --columns <n>`
(rząd na kierunek).

Sieć kontenera nie pobiera plików z PixelLab, ale `join` zapisuje arkusz lokalnie (katalog tool-results sesji):
pasek podpisu u góry, rzędy klatek na ciemnym tle (31, 37, 44). Ten skrypt ucina pasek, usuwa tło
wypełnianiem od krawędzi każdej klatki i zapisuje klatki jako pixellab_src/heroes/<postać>/<animacja>_<kierunek>_<i>.png
(stare klatki tej animacji i kierunku są usuwane). Potem uruchom python tools/hero_sheets.py.

Uruchom: python tools/hero_frames_cut.py <arkusz.png> <postać> <animacja> <kierunki po przecinku, rząd po rzędzie>
[rozmiar klatki, domyślnie 80]. Rząd innej animacji: animacja:kierunek (np. shoot:north)."""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKGROUND = (31, 37, 44)


def clear(cell):
    """Tło -> przezroczystość: wypełnianie od krawędzi po pikselach dokładnie w kolorze tła."""
    px = cell.load()
    w, h = cell.size
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    seen = set()
    while stack:
        p = stack.pop()
        if p in seen:
            continue
        seen.add(p)
        if px[p][:3] != BACKGROUND:
            continue
        px[p] = (0, 0, 0, 0)
        x, y = p
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= n[0] < w and 0 <= n[1] < h and n not in seen:
                stack.append(n)
    return cell


def main():
    path, hero, anim, directions = sys.argv[1:5]
    directions = directions.split(",")
    size = int(sys.argv[5]) if len(sys.argv) > 5 else 80
    sheet = Image.open(path).convert("RGBA")
    top = sheet.height - size * len(directions)  # pasek podpisu nad klatkami
    count = sheet.width // size
    folder = os.path.join(ROOT, "pixellab_src", "heroes", hero)
    for row, entry in enumerate(directions):
        row_anim, direction = entry.split(":") if ":" in entry else (anim, entry)
        for old in glob.glob(os.path.join(folder, "%s_%s_*.png" % (row_anim, direction))):
            os.remove(old)
        y = top + row * size
        for i in range(count):
            cell = clear(sheet.crop((i * size, y, (i + 1) * size, y + size)))
            cell.save(os.path.join(folder, "%s_%s_%d.png" % (row_anim, direction, i)))
        print("%s %s %s: %d klatek" % (hero, row_anim, direction, count))


if __name__ == "__main__":
    main()
