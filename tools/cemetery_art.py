"""Grafiki Leśnego Cmentarza rysowane w Pythonie:
- kuty płot jako zestaw kafelków (autotile): 16 kafelków na wszystkie połączenia z sąsiadami (maska: 1 - północ,
  2 - wschód, 4 - południe, 8 - zachód). Odcinki wschód-zachód to pręty z grotami między dwiema poprzeczkami
  na niskiej kamiennej podmurówce, odcinki północ-południe widać z boku (wąski pas słupków z grotami). Tam, gdzie
  płot skręca, rozwidla się albo kończy (furtka), stoi kamienny słupek z daszkiem. Kafelek ma 16x32 px:
  dolne 16 px to komórka na ziemi, płot wyrasta nad nią.
- znicz: czerwone szkło z płomykiem, 2 klatki migotania.
Wynik: assets/cemetery/iron_fence.png (16 kafelków w rzędzie, w kolejności maski), assets/cemetery/candle.png.
Uruchom: python tools/cemetery_art.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "cemetery")

T = 16
CELL_H = 32
GROUND = 24  # środek komórki na płótnie (y)
HEIGHT = 13  # wysokość płotu nad ziemią
IRON = (34, 32, 38)
IRON_LIGHT = (78, 76, 86)
IRON_DARK = (18, 17, 21)
STONE = [(92, 90, 96), (110, 108, 114), (132, 130, 136), (70, 68, 74)]
OUTLINE = (14, 13, 16)


def put(img, x, y, color):
    if 0 <= x < T and 0 <= y < CELL_H:
        img.putpixel((x, y), color + (255,))


def bar_segment(img, x0, x1):
    """Odcinek wschód-zachód od x0 do x1 (włącznie): podmurówka, poprzeczki i pręty z grotami co 3 px."""
    top = GROUND - HEIGHT
    for x in range(x0, x1 + 1):
        # podmurówka 3 px (wierzch jaśniejszy, lico ciemniejsze)
        put(img, x, GROUND - 2, STONE[2])
        put(img, x, GROUND - 1, STONE[0] if x % 4 else STONE[3])
        put(img, x, GROUND, STONE[3])
        put(img, x, GROUND + 1, OUTLINE)
        # poprzeczki
        put(img, x, top + 3, IRON)
        put(img, x, top + 2, IRON_LIGHT)
        put(img, x, GROUND - 4, IRON)
        if x % 3 == 1:
            for y in range(top + 1, GROUND - 2):
                put(img, x, y, IRON_LIGHT if y < top + 4 else IRON)
            put(img, x, top, IRON_LIGHT)  # grot
            put(img, x - 1, top + 1, IRON_DARK)
            put(img, x + 1, top + 1, IRON_DARK)
            put(img, x, top - 1, IRON_DARK)


def side_segment(img, y0, y1):
    """Odcinek północ-południe widziany z boku: dla każdego rzędu ziemi od y0 do y1 słupek wysokości płotu
    (cienki pas), co 3 rzędy grot ponad górną poprzeczką, u dołu podmurówka."""
    for gy in range(y0, y1 + 1):
        py = GROUND - 8 + gy  # rząd ziemi gy (0..15) na płótnie
        for x in (7, 8):
            put(img, x, py + 1, STONE[0] if x == 7 else STONE[3])
        put(img, 9, py + 1, OUTLINE)
        put(img, 6, py + 1, OUTLINE)
        for y in range(py - HEIGHT + 2, py):
            put(img, 7, y, IRON_LIGHT if y == py - HEIGHT + 4 else IRON)
            put(img, 8, y, IRON_DARK)
        if gy % 3 == 0:
            put(img, 7, py - HEIGHT + 1, IRON_LIGHT)
            put(img, 7, py - HEIGHT, IRON_DARK)


def pillar(img):
    """Kamienny słupek z daszkiem na środku komórki (narożnik, rozwidlenie, koniec przy furtce)."""
    x0, x1 = 5, 10
    top = GROUND - HEIGHT - 3
    for y in range(top + 2, GROUND + 1):
        for x in range(x0, x1 + 1):
            c = STONE[2] if x == x0 + 1 else STONE[3] if x == x1 else STONE[1] if (x + y) % 5 else STONE[0]
            put(img, x, y, c)
    for x in range(x0 - 1, x1 + 2):  # daszek
        put(img, x, top + 1, STONE[2])
        put(img, x, top + 2, STONE[3])
        put(img, x, top, OUTLINE)
    for x in range(x0 + 1, x1):
        put(img, x, top - 1, STONE[1])
        put(img, x, top - 2, OUTLINE)
    put(img, x0 + 2, top - 1, STONE[2])
    for y in range(top + 1, GROUND + 2):
        put(img, x0 - 1, y, OUTLINE)
        put(img, x1 + 1, y, OUTLINE)
    for x in range(x0 - 1, x1 + 2):
        put(img, x, GROUND + 1, OUTLINE)


def fence_tile(mask):
    img = Image.new("RGBA", (T, CELL_H))
    n, e, s, w = mask & 1, mask & 2, mask & 4, mask & 8
    straight = mask in (2 | 8, 1 | 4)
    # najpierw to, co z tyłu (północ), potem poziomo, na końcu południe - żeby bliższe zasłaniało dalsze
    if n:
        side_segment(img, 0, 7)
    if w:
        bar_segment(img, 0, 8 if straight else 5)
    if e:
        bar_segment(img, 7 if straight else 10, 15)
    if s:
        side_segment(img, 8, 15)
    if not straight:
        pillar(img)
    return img


def candle(frame):
    """Znicz 7x10: czerwone szkło z jaśniejszym odblaskiem, złoty daszek, płomyk (dwie wysokości)."""
    img = Image.new("RGBA", (7, 10))
    glass = [(150, 28, 30), (196, 48, 40), (228, 92, 64)]
    for y in range(4, 10):
        for x in range(1, 6):
            c = glass[1]
            if x == 1:
                c = glass[0]
            elif x == 2 and y < 8:
                c = glass[2]
            img.putpixel((x, y), c + (255,))
    for x in range(1, 6):
        img.putpixel((x, 3), (196, 160, 72, 255))
        img.putpixel((x, 9), (110, 20, 22, 255))
    img.putpixel((3, 2), (255, 220, 120, 255))
    img.putpixel((3, 1), (255, 170, 60, 255) if frame == 0 else (255, 240, 170, 255))
    if frame == 1:
        img.putpixel((3, 0), (255, 150, 50, 255))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet = Image.new("RGBA", (T * 16, CELL_H))
    for mask in range(16):
        sheet.alpha_composite(fence_tile(mask), (mask * T, 0))
    sheet.save(os.path.join(OUT, "iron_fence.png"))
    candles = Image.new("RGBA", (14, 10))
    for f in range(2):
        candles.alpha_composite(candle(f), (f * 7, 0))
    candles.save(os.path.join(OUT, "candle.png"))
    print("cemetery: iron_fence, candle")


if __name__ == "__main__":
    main()
