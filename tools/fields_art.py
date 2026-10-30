"""Grafiki Pól Zbożowych rysowane w Pythonie: pas zboża (bezszwowy w poziomie - rząd zboża w grze to jeden
Sprite2D z powtarzaną teksturą, kołysany shaderem), kopczyk ziemi nad podkopującym się czerwiem i kopczyk z wylotem nory (jak po krecie),
oraz zaorana ziemia (bezszwowa tekstura 64x64 - skośne bruzdy schodzą się na wszystkich krawędziach).
Wynik: assets/fields/grain.png (3 warianty jeden pod drugim: dojrzałe, jaśniejsze, zielonkawe),
assets/fields/mound.png, assets/fields/hole.png, assets/fields/ground/soil.png.
Uruchom: python tools/fields_art.py (albo na końcu generate_art.py)"""
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "fields")
W, H = 64, 30

VARIANTS = [
    # łodyga ciemna / jasna, kłos ciemny / jasny / błysk
    ((150, 112, 44), (196, 156, 66), (176, 128, 46), (222, 178, 82), (246, 214, 128)),
    ((164, 124, 50), (210, 170, 76), (190, 142, 54), (232, 192, 96), (250, 224, 146)),
    ((120, 120, 46), (160, 156, 62), (150, 140, 56), (190, 176, 78), (220, 206, 118)),
]


def put(img, x, y, color):
    if 0 <= y < img.height:
        img.putpixel((x % img.width, y), color + (255,))


def grain(variant, rng):
    stem_d, stem_l, head_d, head_l, shine = variant
    img = Image.new("RGBA", (W, H))
    # gęsto: kilka warstw źdźbeł, tylne ciemniejsze
    for layer in range(3):
        for i in range(34):
            x = rng.randrange(W)
            top = rng.randrange(1, 9) + layer * 2
            lean = rng.choice([-1, 0, 0, 1])
            dark = layer == 0
            for y in range(top + 5, H):
                xx = x + (lean if y < top + 10 else 0)
                put(img, xx, y, stem_d if dark or y > H - 6 else stem_l)
            # kłos: 5-6 px, ziarna na przemian po bokach
            for k in range(6):
                y = top + k
                xx = x + (lean if k < 3 else 0)
                put(img, xx, y, head_d if dark else (shine if k == 1 else head_l))
                if k % 2 == 0 and k < 5:
                    put(img, xx - 1, y + 1, head_d)
                else:
                    put(img, xx + 1, y + 1, head_d if dark else head_l)
            # wąsy kłosa
            put(img, x + lean, top - 1, head_l)
            if rng.random() < 0.5:
                put(img, x + lean - 1, top - 2, head_d)
    # cień u podstawy
    for x in range(W):
        for y in range(H - 3, H):
            r, g, b, a = img.getpixel((x, y))
            if a:
                img.putpixel((x, y), (int(r * 0.7), int(g * 0.68), int(b * 0.6), 255))
    return img


# zaorana ziemia: paleta z dawnej tekstury PixelLab (grzbiet skiby jasny, bruzda ciemna)
SOIL = [(42, 26, 16), (62, 39, 22), (82, 51, 28), (114, 72, 38), (144, 95, 51)]
SOIL_CLOD = (166, 122, 73)
SOIL_WEED = (123, 116, 47)
SOIL_SIZE = 64
FURROW = 16  # okres bruzd wzdłuż u = x + 2y (dzieli 64, więc tekstura się zawija); w pionie co 8 px


def molehill(w, h, opening, seed):
    """Kopczyk świeżej ziemi jak po krecie: kopuła z grudek (jaśniejsza od góry-lewej, ciemniejsza u dołu),
    poszarpany brzeg z osypanymi grudkami dookoła; `opening` - ciemny otwór na szczycie (wylot nory czerwia)."""
    rng = random.Random(seed)
    img = Image.new("RGBA", (w, h))
    cx, cy = (w - 1) / 2, h * 0.6
    rx, ry = w / 2 - 2.5, h * 0.6 - 1.5
    soil = SOIL + [SOIL_CLOD]
    for y in range(h):
        for x in range(w):
            dx, dy = (x - cx) / rx, (y - cy) / ry
            edge = 1.0 + 0.16 * ((x * 7 + y * 13) % 5 - 2) / 2
            d = dx * dx + dy * dy
            if d > edge:
                continue
            height = 1.0 - d  # wyżej w środku
            light = height * 1.3 - dx * 0.45 - dy * 0.5 + rng.uniform(-0.22, 0.22)
            level = max(1, min(5, int(1.2 + light * 3.4)))
            if dy > 0.55 and d > 0.55:  # cień u dołu kopuły
                level = min(level, 1)
            img.putpixel((x, y), soil[level] + (255,))
    # ciemny obrys dolnej połowy (kopczyk odcina się od ziemi i trawy)
    px = img.load()
    rim = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and y > cy - 1:
                if any(0 <= x + ex < w and 0 <= y + ey < h and px[x + ex, y + ey][3] for ex, ey in ((0, -1), (1, 0), (-1, 0))):
                    rim.append((x, y))
    for x, y in rim:
        px[x, y] = (30, 19, 12, 255)
    # grudki osypane wokół kopczyka
    for i in range(18):
        a = rng.uniform(0, 6.283)
        import math
        r = rng.uniform(1.0, 1.35)
        x, y = int(cx + math.cos(a) * rx * r), int(cy + math.sin(a) * ry * r)
        if 0 <= x < w - 1 and 0 <= y < h - 1:
            img.putpixel((x, y), soil[rng.choice((3, 4, 5))] + (255,))
            img.putpixel((x, y + 1), soil[1] + (255,))
    if opening:
        ox, oy = cx, cy - ry * 0.25
        for y in range(h):
            for x in range(w):
                dx, dy = (x - ox) / 4.2, (y - oy) / 2.2
                if dx * dx + dy * dy <= 1.0:
                    img.putpixel((x, y), (24, 15, 10, 255) if dy > -0.5 else SOIL[1] + (255,))
    return img


def mound():
    """Kopczyk nad czerwiem, który ryje pod ziemią."""
    return molehill(24, 15, False, 3)


def hole():
    """Kopczyk z wylotem nory - z niego wynurza się czerw."""
    return molehill(30, 17, True, 7)


def soil(rng):
    """Skiby wznoszące się w prawo (nachylenie 1:2): w każdej bruździe od góry grzbiet w słońcu, stok, środek,
    cień i dno bruzdy. Lekkie falowanie (okresowe w x i y), rozrzucony szum, grudy i źdźbła chwastów."""
    import math
    img = Image.new("RGB", (SOIL_SIZE, SOIL_SIZE))
    # profil skiby: indeks palety dla pozycji w okresie (0 = szczyt grzbietu)
    profile = [4, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 0, 0, 1, 3]
    for y in range(SOIL_SIZE):
        for x in range(SOIL_SIZE):
            wobble = math.sin(2 * math.pi * x / SOIL_SIZE * 2) * 1.2 + math.sin(2 * math.pi * y / SOIL_SIZE * 3 + 1.0) * 0.8
            u = (x + 2 * y + wobble) % FURROW
            level = profile[int(u)]
            r = rng.random()
            if r < 0.14:
                level = max(0, level - 1)
            elif r < 0.24:
                level = min(4, level + 1)
            img.putpixel((x, y), SOIL[level])
    # grudy na grzbietach i źdźbła chwastów
    for i in range(46):
        x, y = rng.randrange(SOIL_SIZE), rng.randrange(SOIL_SIZE)
        img.putpixel((x, y), SOIL_CLOD if i % 5 else SOIL_WEED)
        if i % 5 and rng.random() < 0.5:
            img.putpixel(((x + 1) % SOIL_SIZE, y), SOIL[3])
    return img.convert("RGBA")


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(11)
    sheet = Image.new("RGBA", (W, H * len(VARIANTS)))
    for i, v in enumerate(VARIANTS):
        sheet.alpha_composite(grain(v, rng), (0, i * H))
    sheet.save(os.path.join(OUT, "grain.png"))
    mound().save(os.path.join(OUT, "mound.png"))
    hole().save(os.path.join(OUT, "hole.png"))
    os.makedirs(os.path.join(OUT, "ground"), exist_ok=True)
    soil(random.Random(5)).save(os.path.join(OUT, "ground", "soil.png"))
    print("fields: grain, mound, hole, soil")


if __name__ == "__main__":
    main()
