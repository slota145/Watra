"""Arkusze i sceny Hydry i Gryfa z PixelLab (obiekty 1-kierunkowe z animacjami w pixellab_src/bosses/,
pobrane przez pixellab_src/bosses/fetch.py). Składanie jak u Gromoskrzydłego (region_sheets.object_sheet).
Układ 4x2:
- Hydra: 0-3 kołysanie głów, 4 spoczynek, 5 zamach (głowy w tył), 6 kąsanie, 7 ryk,
- Gryf: 0-3 machanie skrzydłami, 4 szybowanie, 5 krzyk, 6 pikowanie, 7 szpony.
Uruchom: python tools/boss_sheets.py (albo na końcu generate_art.py)"""
import json
import os

from PIL import Image

import forest_scenes
import forest_sheets
import region_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "bosses")
OUT = os.path.join(ROOT, "assets", "bosses")

# obiekt: (skala, {klucz: słowa w nazwie folderu animacji}, klatki: [(klucz, indeks)] - "rot" to obrót)
OBJECTS = {
    "hydra": (0.85, {"sway": ["sway"], "bite": ["lunge", "bite", "rear"], "roar": ["roar"]},
              [("sway", 0), ("sway", 1), ("sway", 2), ("sway", 3), ("rot", 0), ("bite", 1), ("bite", -2), ("roar", -2)]),
    "gryf": (0.8, {"flap": ["flap"], "dive": ["dive", "fold"], "screech": ["screech", "rearing"]},
             [("flap", 0), ("flap", 1), ("flap", 2), ("flap", 3), ("rot", 0), ("screech", 2), ("dive", 2), ("dive", 3)]),
}
SCENES = {"hydra": ((5.0, 2.4), 40.0), "gryf": ((3.0, 1.4), 26.0), "satyr_king": ((2.8, 1.5), 22.0)}
# postacie (Faun-Król): układ 4x2 - 0-3 chód, 4 spoczynek, 5 zamach, 6 szarża, 7 tupnięcie
CREATURES = {
    "satyr_king": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.frame(n, "charge", 1),
                                                     region_sheets.frame(n, "charge", 3), region_sheets.frame(n, "stomp", 3)]],
                   ["walk", "charge", "stomp"]),
}
NEW = {
    "hydra": ("frog_chief", "Hydra", "res://scripts/hydra.gd", {
        "max_health": "2400", "damage": "40", "speed": "0.0", "xp_reward": "3000", "gold_min": "30", "gold_max": "50",
        "gold_coins": "14", "aggro_radius": "190.0", "leash_radius": "520.0", "attack_interval": "1.2",
        "boss_name": '"Hydra z Bagien"', "legendary_drops": 'PackedStringArray("legend_hydra_fang", "legend_hydra_scales", '
        '"legend_hydra_bow", "legend_hydra_crown", "legend_hydra_gloves", "legend_hydra_boots")',
        "legendary_drop_chance": "0.03",
        "bite_damage": "60", "venom_damage": "40", "wave_damage": "55", "breath_damage": "45"}),
    "satyr_king": ("frog_chief", "SatyrKing", "res://scripts/satyr_king.gd", {
        "max_health": "3000", "damage": "40", "speed": "62.0", "xp_reward": "2200", "gold_min": "20", "gold_max": "34",
        "aggro_radius": "170.0", "leash_radius": "460.0", "attack_interval": "1.3", "boss_name": '"Faun-Król, Władca Satyrów"',
        "legendary_drops": 'PackedStringArray("legend_faun_flute", "legend_faun_horns", "legend_faun_hooves", "legend_faun_scepter")',
        "charge_damage": "55", "vine_damage": "30", "stomp_damage": "45"}),
    "gryf": ("frog_chief", "Gryf", "res://scripts/gryf.gd", {
        "max_health": "2200", "damage": "40", "speed": "95.0", "xp_reward": "2700", "gold_min": "28", "gold_max": "46",
        "gold_coins": "14", "aggro_radius": "170.0", "leash_radius": "560.0", "attack_interval": "1.3",
        "boss_name": '"Gryf, Władca Wzgórza"', "legendary_drops": 'PackedStringArray("legend_gryf_blade", "legend_gryf_talons", '
        '"legend_gryf_tome", "legend_gryf_wings", "legend_gryf_crest", "legend_gryf_heart")',
        "legendary_drop_chance": "0.03",
        "dive_damage": "60", "gust_damage": "40", "feather_damage": "30", "slam_damage": "65", "tornado_damage": "25"}),
}


def _frames(name, keys):
    anims = os.path.join(SRC, name, "animations")
    found = {}
    for folder in sorted(os.listdir(anims)) if os.path.isdir(anims) else []:
        sub = os.path.join(anims, folder, "unknown")
        lower = folder.lower()
        for key, words in keys.items():
            if key not in found and any(word in lower for word in words):
                found[key] = [Image.open(os.path.join(sub, f)).convert("RGBA") for f in sorted(os.listdir(sub))]
    rot = os.path.join(SRC, name, "rotations", "unknown.png")
    if os.path.exists(rot):
        found["rot"] = [Image.open(rot).convert("RGBA")]
    return found


def main():
    os.makedirs(OUT, exist_ok=True)
    layout_path = os.path.join(SRC, "layout.json")
    layout = json.load(open(layout_path)) if os.path.exists(layout_path) else {}
    for name, (scale, keys, order) in OBJECTS.items():
        found = _frames(name, keys)
        if not all(k in found for k, _ in order):
            print("  %s: brakuje animacji" % name)
            continue
        cells = [found[k][i] for k, i in order]
        w, h = region_sheets.object_sheet(cells, os.path.join(OUT, name + ".png"), scale=scale)
        layout[name] = {"cell": [w, h], "offset_y": -(h / 2.0) + 6}
        print(name, w, h)
    forest_sheets.SRC = SRC
    forest_sheets.OUT = OUT
    for name, (rows, anims) in CREATURES.items():
        folder = os.path.join(SRC, name, "animations")
        if all(os.path.isdir(os.path.join(folder, a)) for a in anims):
            layout[name] = forest_sheets.build(name, rows(name))
            print("Zapisano %s %s" % (name, layout[name]))
    json.dump(layout, open(layout_path, "w"), indent=1)
    forest_scenes.ASSET_DIR = "bosses"
    for name, (template, node, script, values) in NEW.items():
        if not os.path.exists(forest_scenes.scene_path(name)):
            forest_scenes.create(name, template, node, script, values)
    for name, (shadow, height) in SCENES.items():
        if name in layout:
            forest_scenes.wire(name, name, 4, 2, shadow, height, "hurt_height", layout)
            print("Podpięto", name)


if __name__ == "__main__":
    main()
