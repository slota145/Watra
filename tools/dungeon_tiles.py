"""Kafelki lochów Watry z zestawów Wang PixelLab (tryb pro, 64 px, ściany pełnej wysokości - transition_size 1.0,
25 kafelków w arkuszu 4x8). Surowe arkusze leżą w pixellab_src/dungeons/<klimat>.png (identyfikatory w ids.json;
pobrane przez pixelart_workbench join, bo kontener nie ma dostępu do api.pixellab.ai - pasek podpisu ucięty).
Układ kafelków jest taki sam jak w zestawie klifów gór (pixellab_src/alpine/cliff.json) - z niego pochodzi
tablica narożników w scripts/dungeon.gd. Narzędzie kopiuje arkusze do assets/dungeons/ i wypisuje średnie kolory
podłogi i ściany (do minimapy).
Uruchom: python tools/dungeon_tiles.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "dungeons")
OUT = os.path.join(ROOT, "assets", "dungeons")
CLIMATES = ["catacombs", "mine", "flooded", "roots"]
# pełny kafelek podłogi (wszystkie narożniki "lower") i wierzchu ściany ("upper") w siatce 4x8
FLOOR = (2, 2)
WALL = (0, 6)


def average(img, cell):
    tile = img.crop((cell[0] * 64, cell[1] * 64, cell[0] * 64 + 64, cell[1] * 64 + 64)).convert("RGB")
    pixels = list(tile.getdata())
    return tuple(sum(p[i] for p in pixels) // len(pixels) for i in range(3))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in CLIMATES:
        img = Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")
        assert img.size == (256, 512), img.size
        img.save(os.path.join(OUT, name + ".png"))
        print("%s: podłoga #%02x%02x%02x, ściana #%02x%02x%02x" % ((name,) + average(img, FLOOR) + average(img, WALL)))


if __name__ == "__main__":
    main()
