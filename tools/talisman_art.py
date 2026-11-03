"""Ikony talizmanów (scripts/talismans.gd) rysowane w kodzie, bez PixelLab.
Każdy kształt ma rozmiar obrazka pasujący do kratek siatki talizmanów: kratka to 32x32 piksele rysunku, powiększone
2x (jak inne ikony przedmiotów 64x64). Kształty:
- small (1x1) - okrągły krążek z wyrytym znakiem i rzemieniem,
- long (1x2) - podłużny kieł z runami,
- wide (2x1) - szeroka tabliczka z dwoma znakami,
- large (2x2) - wielka tarcza ze słońcem i czterema znakami wokół.
Rzadkości: magic - kość z niebieskimi runami, rare - bursztyn ze złotą oprawą i ognistymi runami.
Wynik: assets/items/talismans/<kształt>_<rzadkość>.png.
Uruchom: python tools/talisman_art.py"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "items", "talismans")
CELL = 32
SCALE = 2

PALETTES = {
    "magic": {"light": (236, 226, 200), "mid": (205, 190, 158), "dark": (150, 132, 104), "outline": (52, 40, 34),
              "rune": (110, 170, 255), "glow": (190, 225, 255), "cord": (120, 78, 46), "rim": None},
    "rare": {"light": (255, 196, 92), "mid": (226, 140, 40), "dark": (160, 82, 22), "outline": (58, 30, 14),
             "rune": (255, 236, 150), "glow": (255, 255, 220), "cord": (110, 70, 40), "rim": (250, 214, 110)},
}


def shade(img, pal):
    """Cieniowanie bryły: jaśniej u góry z lewej, ciemniej na dole z prawej; obrys z przezroczystych sąsiadów."""
    w, h = img.size
    px = img.load()
    mask = [[px[x, y][3] > 0 for y in range(h)] for x in range(w)]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    po = out.load()
    for x in range(w):
        for y in range(h):
            if not mask[x][y]:
                continue
            edge = any(not (0 <= x + dx < w and 0 <= y + dy < h and mask[x + dx][y + dy])
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                po[x, y] = pal["outline"] + (255,)
                continue
            # odległość od lewego górnego brzegu bryły (światło z góry z lewej)
            lit = not (0 <= x - 2 < w and 0 <= y - 2 < h and mask[x - 2][y - 2])
            dark = not (0 <= x + 2 < w and 0 <= y + 2 < h and mask[x + 2][y + 2])
            if lit:
                po[x, y] = pal["light"] + (255,)
            elif dark:
                po[x, y] = pal["dark"] + (255,)
            else:
                po[x, y] = pal["mid"] + (255,)
    return out


def body(size, draw_fn):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(img))
    return img


def rune(draw, points, pal):
    """Wyryty znak: kreski w kolorze run z jaśniejszym środkiem."""
    for a, b in points:
        draw.line([a, b], fill=pal["rune"] + (255,), width=1)
    for a, b in points:
        mx, my = (a[0] + b[0]) // 2, (a[1] + b[1]) // 2
        draw.point((mx, my), fill=pal["glow"] + (255,))


def cord(draw, x, y0, y1, pal):
    draw.line([(x, y0), (x, y1)], fill=pal["cord"] + (255,), width=1)
    draw.line([(x + 1, y0), (x + 1, y1)], fill=tuple(int(c * 0.7) for c in pal["cord"]) + (255,), width=1)


def rim(img, pal):
    """Złota oprawa rzadkich talizmanów: pierścień jasnych pikseli tuż pod obrysem."""
    if pal["rim"] is None:
        return img
    w, h = img.size
    px = img.load()
    outline = pal["outline"] + (255,)
    marks = []
    for x in range(1, w - 1):
        for y in range(1, h - 1):
            if px[x, y][3] and px[x, y] != outline:
                if any(px[x + dx, y + dy] == outline for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    marks.append((x, y))
    for x, y in marks:
        px[x, y] = pal["rim"] + (255,)
    return img


def small(pal):
    img = body((CELL, CELL), lambda d: d.ellipse([3, 5, 28, 30], fill=(255, 255, 255, 255)))
    img = rim(shade(img, pal), pal)
    d = ImageDraw.Draw(img)
    cord(d, 15, 1, 5, pal)
    d.ellipse([13, 0, 18, 4], outline=pal["cord"] + (255,))
    # znak Peruna (sześciopromienny kwiat w kole) uproszczony do trzech kresek
    c = (15, 17)
    pts = []
    for k in range(3):
        a = math.pi * k / 3
        dx, dy = round(math.cos(a) * 8), round(math.sin(a) * 8)
        pts.append(((c[0] - dx, c[1] - dy), (c[0] + dx, c[1] + dy)))
    rune(d, pts, pal)
    return img


def long(pal):
    def shape(d):
        d.polygon([(6, 8), (26, 8), (25, 30), (21, 48), (16, 61), (11, 48), (7, 30)], fill=(255, 255, 255, 255))
        d.rectangle([5, 5, 27, 11], fill=(255, 255, 255, 255))
    img = rim(shade(body((CELL, CELL * 2), shape), pal), pal)
    d = ImageDraw.Draw(img)
    cord(d, 15, 0, 6, pal)
    # runy jedna pod drugą
    rune(d, [((12, 15), (20, 23)), ((20, 15), (12, 23))], pal)
    rune(d, [((16, 27), (16, 37)), ((12, 31), (16, 27)), ((20, 31), (16, 27))], pal)
    rune(d, [((13, 41), (19, 41)), ((16, 41), (16, 50))], pal)
    return img


def wide(pal):
    def shape(d):
        d.rounded_rectangle([3, 9, 60, 26], radius=6, fill=(255, 255, 255, 255))
    img = rim(shade(body((CELL * 2, CELL), shape), pal), pal)
    d = ImageDraw.Draw(img)
    cord(d, 10, 2, 9, pal)
    cord(d, 52, 2, 9, pal)
    d.line([(10, 2), (52, 2)], fill=pal["cord"] + (255,))
    # trzy znaki: romb (znak zasianego pola), strzała Peruna i gwiazda
    rune(d, [((15, 12), (20, 17)), ((20, 17), (15, 22)), ((15, 22), (10, 17)), ((10, 17), (15, 12)),
             ((15, 17), (15, 17))], pal)
    rune(d, [((31, 13), (31, 22)), ((28, 16), (31, 13)), ((34, 16), (31, 13))], pal)
    rune(d, [((44, 13), (50, 22)), ((50, 13), (44, 22)), ((47, 12), (47, 23))], pal)
    return img


def large(pal):
    def shape(d):
        d.ellipse([4, 8, 59, 62], fill=(255, 255, 255, 255))
    img = rim(shade(body((CELL * 2, CELL * 2), shape), pal), pal)
    d = ImageDraw.Draw(img)
    cord(d, 31, 0, 8, pal)
    d.ellipse([28, 0, 35, 5], outline=pal["cord"] + (255,))
    c = (31, 35)
    # słońce: krąg i dwanaście prostych promieni
    pts = []
    for k in range(12):
        a = math.tau * k / 12
        x0, y0 = c[0] + round(math.cos(a) * 8), c[1] + round(math.sin(a) * 8)
        x1, y1 = c[0] + round(math.cos(a) * (15 if k % 2 == 0 else 12)), c[1] + round(math.sin(a) * (15 if k % 2 == 0 else 12))
        pts.append(((x0, y0), (x1, y1)))
    rune(d, pts, pal)
    d.ellipse([c[0] - 6, c[1] - 6, c[0] + 6, c[1] + 6], outline=pal["rune"] + (255,))
    d.ellipse([c[0] - 2, c[1] - 2, c[0] + 2, c[1] + 2], fill=pal["glow"] + (255,))
    # cztery małe znaki przy brzegu
    for k in range(4):
        a = math.tau * k / 4 + math.pi / 4
        x, y = c[0] + round(math.cos(a) * 21), c[1] + round(math.sin(a) * 21)
        rune(d, [((x - 2, y), (x + 2, y)), ((x, y - 2), (x, y + 2))], pal)
    return img


SHAPES = {"small": small, "long": long, "wide": wide, "large": large}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SHAPES.items():
        for quality, pal in PALETTES.items():
            img = fn(pal)
            img = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
            path = os.path.join(OUT, f"{name}_{quality}.png")
            img.save(path)
            print(path, img.size)


if __name__ == "__main__":
    main()
