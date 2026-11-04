"""Ikony kroku 5 wspólnego drzewka (docs/plan_drzewek.md): nowe umiejętności, węzły kluczowe i węzły znaczące strony
zręczności i siły. Paczka 16 ikon 64x64 z PixelLab (create_1_direction_object, id w pixellab_src/shared_tree/ids.json),
złożona przez pixelart_workbench join w arkusz 4x4: pixellab_src/shared_tree/icons_step5.png (pasek podpisu ucięty).
Ciemne tło (31, 37, 44) znika wypełnianiem od krawędzi klatki (herb_art.cells). Wynik: assets/skills/<nazwa>.png.
Zastępuje tymczasowe przebarwienia strony siły (dawne tools/strength_icons.py).
Druga paczka (icons_step5_int.png, strona inteligencji): nowe umiejętności i węzły inteligencji, puste miejsca stref
i przywołań (Błędne Ogniki, Wataha) na zapas.
Uruchom: python tools/tree_step5_icons.py"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = {"icons_step5.png": ["viper_arrow", "split_arrow", "caltrops", "ks_shadow_stalker",
         "ks_battle_frenzy", "node_row_shot", "node_silent_steps", "node_running_breath",
         "wolf_fang", "bull_roar", "bear_leap", "ks_last_bastion",
         "node_whirl_pull", "node_loud_voice", "node_full_strength", "node_wounded_wrath"],
          "icons_step5_int.png": ["fire_wall", "ice_armor", "ks_elem_master", "node_mana_flow",
                                  "node_full_mind", "thrown_knives", "node_momentum", "node_open_wounds",
                                  "thunder_arrow", "node_lightness", "enchanted_blade", "ks_iron_will",
                                  "wisps", "node_loyal_wisps", "wolf_pack", "node_pack_leader"]}


def main():
    total = 0
    for sheet, icons in SHEETS.items():
        src = os.path.join(ROOT, "pixellab_src", "shared_tree", sheet)
        for name, icon in zip(icons, cells(Image.open(src), 4, len(icons))):
            icon.save(os.path.join(ROOT, "assets", "skills", name + ".png"))
        total += len(icons)
    print("ikony kroku 5: %d" % total)


if __name__ == "__main__":
    main()
