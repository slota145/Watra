"""Grafiki przeróbki Prastarego Lasu z PixelLab (pixellab_src/ancient_v2/): olbrzymie drzewa (pojedyncze obiekty
256 px), wysokie drzewa (paczka "tall") i rekwizyty (paczka "props": pień ze śladami pazurów w całości, głazy,
korzenie, paprocie...). Przycięte do sylwetki i zmniejszone jak reszta (hero_sheets.shrink_image).
Wynik: assets/ancient/v2_<nazwa>.png. Uruchom: python tools/ancient_v2.py (albo na końcu generate_art.py)"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "ancient_v2")
OUT = os.path.join(ROOT, "assets", "ancient")

# nazwa: (plik albo (paczka, klatka), wysokość w świecie) - olbrzymy ~6 postaci, wysokie ~3,5 postaci
SPRITES = {
    "v2_colossal_0": ("colossal_0.png", 230), "v2_colossal_1": ("colossal_1.png", 240),
    "v2_colossal_2": ("colossal_2.png", 225),
    "v2_tall_0": (("tall", 0), 130), "v2_tall_1": (("tall", 1), 120), "v2_tall_2": (("tall", 2), 125),
    "v2_tall_3": (("tall", 3), 120),
    "v2_claw_tree": (("props", 0), 62), "v2_claw_stump": (("props", 1), 40),
    "v2_boulder": (("props", 2), 34), "v2_mossy_rocks": (("props", 3), 32), "v2_roots": (("props", 4), 36),
    "v2_fallen_trunk": (("props", 5), 30), "v2_mushroom_ring": (("props", 6), 30), "v2_ferns": (("props", 7), 26),
    "v2_stump": (("props", 8), 24), "v2_hollow_log": (("props", 10), 28), "v2_shrine": (("props", 13), 32),
    "v2_dead_sapling": (("props", 14), 40), "v2_tall_grass": (("props", 15), 22),
}


def _load(source):
    path = os.path.join(SRC, source) if isinstance(source, str) else os.path.join(SRC, source[0], "frame_%d.png" % source[1])
    return Image.open(path).convert("RGBA") if os.path.exists(path) else None


def main():
    for name, (source, height) in SPRITES.items():
        img = _load(source)
        if img is None:
            continue
        img = img.crop(img.getbbox())
        scale = min(1.0, height / img.height)
        if scale < 1.0:
            img = hero_sheets.shrink_image(img, max(1, round(img.width * scale)), max(1, round(img.height * scale)))
        img.save(os.path.join(OUT, name + ".png"))
        print(name, img.size)


if __name__ == "__main__":
    main()
