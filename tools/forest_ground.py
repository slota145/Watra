"""Podłoże Goblińskiego Lasu z zestawów Wang PixelLab (tryb pro, 64 px, pixellab_src/forest_ground/<zestaw>.png
+ .json z pixellab_src/forest_ground/fetch.py) - jak góry (alpine_tiles.py): z każdego zestawu bierzemy pełny
kafelek jednego terenu, czyli bezszwową teksturę 64x64, którą gra kładzie w przestrzeni świata zamiast kafelków
16 px z atlasu, a przejścia rysuje shader (scripts/soft_ground.gd). Wszystkie zestawy mają tę samą trawę
(łańcuch przez lower_base_tile_id). Wynik: assets/forest/ground/<teren>.png - nazwy jak tereny atlasu
(grass, dark, road, flowers, cobble), bo las podmienia nimi właśnie te tereny.
Uruchom: python tools/forest_ground.py (albo na końcu generate_art.py)"""
import json
import os

from PIL import Image, ImageEnhance

from alpine_tiles import full_tile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "forest_ground")
OUT = os.path.join(ROOT, "assets", "forest", "ground")

# zestaw: (teren dolny albo None, teren górny)
SETS = {
    "path": ("grass", "road"),
    "dark": (None, "dark"),
    "flowers": (None, "flowers"),
    "cobble": (None, "cobble"),
}
# korekta kolorów pod referencję: (nasycenie, jasność) - PixelLab dał neonową trawę, bladszą od niej łąkę,
# prawie czarną ciemną trawę i pomarańczową ścieżkę; łąka ma mieć odcień trawy, żeby płaty się nie odcinały
ADJUST = {"grass": (0.7, 0.93), "dark": (0.75, 1.6), "road": (0.75, 1.12)}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (lower, upper) in SETS.items():
        png = os.path.join(SRC, name + ".png")
        if not os.path.exists(png):
            continue
        sheet = Image.open(png).convert("RGBA")
        meta = json.load(open(os.path.join(SRC, name + ".json"), encoding="utf-8"))
        for kind, side in ((lower, "lower"), (upper, "upper")):
            if kind is None:
                continue
            tile = full_tile(sheet, meta, side)
            if tile is None:
                print("  %s: brak pełnego kafelka (%s)" % (name, side))
                continue
            saturation, brightness = ADJUST.get(kind, (1.0, 1.0))
            tile = ImageEnhance.Brightness(ImageEnhance.Color(tile).enhance(saturation)).enhance(brightness)
            tile.save(os.path.join(OUT, kind + ".png"))
    _flowers_on_grass()
    print("podłoże lasu:", sorted(os.listdir(OUT)))


def _flowers_on_grass():
    """Kwietna łąka: same kwiatki z zestawu łąki położone na teksturze trawy - tło łąki wyszło jaśniejsze
    od trawy i jej płaty wyglądały jak rozmyte plamy (jak w górach: alpine_tiles._flowers_on_meadow)."""
    grass_path = os.path.join(OUT, "grass.png")
    png = os.path.join(SRC, "flowers.png")
    if not os.path.exists(grass_path) or not os.path.exists(png):
        return
    import colorsys
    flowers = full_tile(Image.open(png).convert("RGBA"), json.load(open(os.path.join(SRC, "flowers.json"), encoding="utf-8")), "upper")
    out = Image.open(grass_path).convert("RGBA")
    for y in range(flowers.height):
        for x in range(flowers.width):
            r, g, b, _a = flowers.getpixel((x, y))
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            # kwiatek: nie-zielony odcień albo prawie biały
            if not (0.17 < h < 0.45) and s > 0.25 or s < 0.18 and v > 0.8:
                out.putpixel((x, y), (r, g, b, 255))
    out.save(os.path.join(OUT, "flowers.png"))


if __name__ == "__main__":
    main()
