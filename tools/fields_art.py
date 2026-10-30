"""Grafiki Pól Zbożowych rysowane w Pythonie: pas zboża (bezszwowy w poziomie - rząd zboża w grze to jeden
Sprite2D z powtarzaną teksturą, kołysany shaderem), kopiec ziemi nad podkopującym się czerwiem i dziura po nim.
Wynik: assets/fields/grain.png (3 warianty jeden pod drugim: dojrzałe, jaśniejsze, zielonkawe),
assets/fields/mound.png, assets/fields/hole.png.
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


def mound():
    img = Image.new("RGBA", (24, 12))
    for y in range(12):
        for x in range(24):
            dx, dy = (x - 11.5) / 11.5, (y - 8) / 6.5
            if dx * dx + dy * dy <= 1.0 and y < 12:
                shade = 0.75 + 0.35 * (1 - (y / 11))
                n = random.Random(x * 31 + y * 7).random()
                base = (112, 78, 48) if n > 0.25 else (88, 60, 38)
                img.putpixel((x, y), tuple(min(255, int(c * shade)) for c in base) + (255,))
    for x, y in ((6, 6), (15, 5), (10, 3), (18, 8)):
        img.putpixel((x, y), (140, 132, 120, 255))
    return img


def hole():
    img = Image.new("RGBA", (28, 14))
    for y in range(14):
        for x in range(28):
            dx, dy = (x - 13.5) / 13.5, (y - 7) / 6.5
            d = dx * dx + dy * dy
            if d <= 1.0:
                if d < 0.45:
                    img.putpixel((x, y), (30, 20, 14, 255))
                else:
                    img.putpixel((x, y), (98, 68, 42, 255) if (x + y) % 3 else (120, 86, 54, 255))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(11)
    sheet = Image.new("RGBA", (W, H * len(VARIANTS)))
    for i, v in enumerate(VARIANTS):
        sheet.alpha_composite(grain(v, rng), (0, i * H))
    sheet.save(os.path.join(OUT, "grain.png"))
    mound().save(os.path.join(OUT, "mound.png"))
    hole().save(os.path.join(OUT, "hole.png"))
    print("fields: grain, mound, hole")


if __name__ == "__main__":
    main()
