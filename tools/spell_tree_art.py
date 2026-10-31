"""Grafiki drzewka księgi magii z PixelLab (create_1_direction_object; identyfikatory w pixellab_src/spell_tree/ids.json).
- pixellab_src/spell_tree/icons.png (4x4 ikon 64x64, złożone przez pixelart_workbench join): umiejętności, węzły
  kluczowe (ks_*), ikony węzłów pasywnych (node_*) i dwie legendy z lochów. Wynik: assets/skills/<nazwa>.png
  i assets/items/legends/<legenda>.png.
- pixellab_src/spell_tree/objects.png (4 klatki 64x64): Kamień Runiczny, Włócznia Marzanny (grot w prawo), Spadająca
  Gwiazda, Kula Piorunów - przycięte do zawartości w assets/spell/<nazwa>.png.
Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki (herb_art.cells).
Uruchom: python tools/spell_tree_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "spell_tree")
ICONS = ["frost_lance", "blizzard", "storm_call", "ball_lightning", "meteor", "blink", "mana_shield", "rune_stone",
         "ks_harmony", "ks_blood_sacrifice", "ks_full_power", "ks_echo_runes", "node_spell_power", "node_cast_speed",
         "legend_marzanna_book", "legend_perun_crown"]
OBJECTS = ["rune_stone", "frost_lance", "meteor", "ball_lightning"]


def main():
    os.makedirs(os.path.join(ROOT, "assets", "items", "legends"), exist_ok=True)
    for name, icon in zip(ICONS, cells(Image.open(os.path.join(SRC, "icons.png")), 4, len(ICONS))):
        folder = ("items", "legends") if name.startswith("legend_") else ("skills",)
        icon.save(os.path.join(ROOT, "assets", *folder, name + ".png"))
    os.makedirs(os.path.join(ROOT, "assets", "spell"), exist_ok=True)
    for name, sprite in zip(OBJECTS, cells(Image.open(os.path.join(SRC, "objects.png")), 4, len(OBJECTS))):
        sprite.crop(sprite.getbbox()).save(os.path.join(ROOT, "assets", "spell", name + ".png"))
    print("drzewko księgi: %d ikon, %d obiektów" % (len(ICONS), len(OBJECTS)))


if __name__ == "__main__":
    main()
