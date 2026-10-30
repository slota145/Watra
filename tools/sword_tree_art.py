"""Ikony drzewka miecza z PixelLab (create_1_direction_object, 16 ikon 64x64; identyfikator w pixellab_src/sword_tree/ids.json).
Arkusz pixellab_src/sword_tree/icons.png (4x4) złożony przez pixelart_workbench join: pasek podpisu ucięty, ciemne tło
(31, 37, 44) usuwane wypełnianiem od krawędzi każdej klatki. Wynik: assets/skills/<nazwa>.png - umiejętności (także
te z kolejnego etapu drzewka), węzły kluczowe (ks_*) i ikony węzłów pasywnych (node_*).
Uruchom: python tools/sword_tree_art.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAMES = ["flicker", "smoke_burst", "rend", "ground_slam", "riposte", "war_cry", "spectral_blades", "ks_endless_whirl",
         "ks_blade_dance", "ks_smoke_shadow", "ks_blood_frenzy", "node_physical", "node_attack_speed", "node_crit",
         "node_combo", "node_spell"]


def main():
    sheet = Image.open(os.path.join(ROOT, "pixellab_src", "sword_tree", "icons.png"))
    for name, icon in zip(NAMES, cells(sheet, 4, len(NAMES))):
        icon.save(os.path.join(ROOT, "assets", "skills", name + ".png"))
    print("drzewko miecza: %d ikon" % len(NAMES))


if __name__ == "__main__":
    main()
