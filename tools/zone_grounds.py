"""Podłoże Rozlewisk i Prastarego Lasu z zestawów Wang PixelLab (tryb pro, 64 px) - jak Gobliński Las
(forest_ground.py): z każdego zestawu bierzemy pełny kafelek terenu, czyli bezszwową teksturę 64x64, którą
SoftGround kładzie w przestrzeni świata. Rozlewiska: łańcuch od trawy lasu (woda rzeki, płycizna rozlewiska,
błoto); Prastary Las: łańcuch od ściółki (mech, liście, ścieżka). Kolory przygaszone pod resztę gry.
Wynik: assets/swamp/ground/<teren>.png i assets/ancient/ground/<teren>.png.
Uruchom: python tools/zone_grounds.py (albo na końcu generate_art.py)"""
import json
import os

from PIL import Image, ImageEnhance

from alpine_tiles import full_tile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# kraina: (folder źródeł, folder wyniku, {teren: (zestaw, strona)}, {teren: (nasycenie, jasność)})
ZONES = {
    "swamp": ("swamp_ground", os.path.join("swamp", "ground"),
              {"water": ("water", "upper"), "shallow": ("shallow", "upper"), "mud": ("mud", "upper")},
              {"water": (0.62, 0.78), "shallow": (0.9, 1.1), "mud": (0.9, 0.95)}),
    "ancient": ("ancient_ground", os.path.join("ancient", "ground"),
                {"soil": ("moss", "lower"), "moss": ("moss", "upper"), "leaves": ("leaves", "upper"),
                 "path": ("path", "upper")},
                {"soil": (0.95, 0.9), "moss": (0.62, 0.66), "leaves": (0.5, 0.62), "path": (0.95, 0.95)}),
}


CONTRAST = {}


def calm_water():
    """Woda rzeki jak na referencji: jednolity błękit z ledwie widocznymi smugami nurtu i rzadkimi, krótkimi
    poziomymi kreskami zmarszczek (zawijane - 64x64 bez szwów). Głębię przy brzegu daje cień skarpy.
    Woda z PixelLab miała ostry, powtarzalny wzór. Błyski i falowanie dokłada shader."""
    import random
    img = Image.new("RGBA", (64, 64))
    base, dim = (54, 110, 168), (49, 103, 160)
    rng = random.Random(7)
    for y in range(64):
        for x in range(64):
            img.putpixel((x, y), base + (255,))
    # ledwie widoczne, dłuższe smugi nurtu
    for i in range(10):
        x, y = rng.randrange(64), rng.randrange(64)
        for k in range(rng.randrange(8, 16)):
            img.putpixel(((x + k) % 64, y), dim + (255,))
    light, faint = (118, 170, 212, 255), (84, 138, 188, 255)
    for i in range(16):
        x, y = rng.randrange(64), rng.randrange(64)
        length = rng.choice([3, 4, 5, 6])
        for k in range(length):
            img.putpixel(((x + k) % 64, y), light if 0 < k < length - 1 else faint)
        # druga, krótsza kreska tuż pod (zmarszczka)
        if rng.random() < 0.5:
            for k in range(max(2, length - 3)):
                img.putpixel(((x + 2 + k) % 64, (y + 2) % 64), faint)
    img.save(os.path.join(ROOT, "assets", "swamp", "ground", "water.png"))


def main():
    for zone, (src, out, terrains, adjust) in ZONES.items():
        src_dir = os.path.join(ROOT, "pixellab_src", src)
        out_dir = os.path.join(ROOT, "assets", out)
        os.makedirs(out_dir, exist_ok=True)
        for terrain, (tileset, side) in terrains.items():
            png = os.path.join(src_dir, tileset + ".png")
            if not os.path.exists(png):
                continue
            meta = json.load(open(os.path.join(src_dir, tileset + ".json"), encoding="utf-8"))
            tile = full_tile(Image.open(png).convert("RGBA"), meta, side)
            if tile is None:
                print("  %s/%s: brak pełnego kafelka" % (zone, terrain))
                continue
            saturation, brightness = adjust.get(terrain, (1.0, 1.0))
            tile = ImageEnhance.Brightness(ImageEnhance.Color(tile).enhance(saturation)).enhance(brightness)
            if terrain in CONTRAST:
                tile = ImageEnhance.Contrast(tile).enhance(CONTRAST[terrain])
            tile.save(os.path.join(out_dir, terrain + ".png"))
        print(zone, sorted(f for f in os.listdir(out_dir) if f.endswith(".png")))
    calm_water()


if __name__ == "__main__":
    main()
