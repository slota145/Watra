"""Grafiki esencji legend (scripts/essences.gd) z PixelLab (create_1_direction_object; identyfikatory
w pixellab_src/essences/ids.json). Arkusz pixellab_src/essences/icons.png (4 ikony 64x64, złożone przez
pixelart_workbench join): esencja broni (pomarańczowa), zbroi (niebieska), biżuterii (fioletowa), Serce Kryształu.
Arkusz pixellab_src/essences/altar.png (96x96): Ołtarz Welesa w lochu (pierwsza klatka).
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.clear_background).
Wynik: assets/items/essence_<weapon|armor|jewelry>.png, assets/items/crystal_heart.png, assets/dungeons/veles_altar.png.
Uruchom: python tools/essence_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells, clear_background  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "essences")


def main():
    icons = list(cells(Image.open(os.path.join(SRC, "icons.png")), 4, 4))
    for name, icon in zip(["essence_weapon", "essence_armor", "essence_jewelry", "crystal_heart"], icons):
        icon.save(os.path.join(ROOT, "assets", "items", name + ".png"))
    altar = clear_background(Image.open(os.path.join(SRC, "altar.png")).convert("RGBA").crop((0, 0, 96, 96)))
    box = altar.getbbox()
    # ołtarz stoi na dole klatki
    canvas = Image.new("RGBA", (96, 96))
    piece = altar.crop(box)
    canvas.alpha_composite(piece, ((96 - piece.width) // 2, 96 - piece.height))
    os.makedirs(os.path.join(ROOT, "assets", "dungeons"), exist_ok=True)
    canvas.save(os.path.join(ROOT, "assets", "dungeons", "veles_altar.png"))
    print("esencje: 3 ikony, Serce Kryształu, Ołtarz Welesa")


if __name__ == "__main__":
    main()
