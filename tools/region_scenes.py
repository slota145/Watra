"""Podpina arkusze stworzeń Rozlewisk, Wietrznych Turni i wioski satyrów (assets/regions/, z tools/region_sheets.py)
do scen - tymi samymi funkcjami co forest_scenes.py - i tworzy sceny satyrów na wzór goblina.
Uruchom po region_sheets.py: python tools/region_scenes.py"""
import json
import os

import forest_scenes

ROOT = forest_scenes.ROOT
LAYOUT = os.path.join(ROOT, "pixellab_src", "regions", "layout.json")

# scena: (arkusz, hframes, vframes, skala cienia, wysokość tułowia, właściwość wysokości)
SCENES = {
    "frogman": ("frogman", 4, 2, (1.6, 1.0), 9.0, "hurt_height"),
    "frog_spitter": ("frog_spitter", 4, 2, (1.6, 1.0), 9.0, "hurt_height"),
    "frog_chief": ("frog_chief", 4, 2, (3.6, 1.9), 24.0, "hurt_height"),
    "drowner": ("drowner", 4, 2, (1.7, 1.0), 12.0, "hurt_height"),
    "rusalka": ("rusalka", 4, 2, (1.7, 1.0), 15.0, "hurt_height"),
    "wodnik": ("wodnik", 4, 2, (3.6, 1.9), 26.0, "hurt_height"),
    "birdman": ("birdman", 4, 2, (1.7, 1.0), 12.0, "hurt_height"),
    "birdman_thrower": ("birdman_thrower", 4, 2, (1.7, 1.0), 12.0, "hurt_height"),
    "birdman_shaman": ("birdman_shaman", 4, 2, (1.7, 1.0), 12.0, "hurt_height"),
    "satyr": ("satyr", 4, 2, (1.7, 1.0), 12.0, "hurt_height"),
    "satyr_piper": ("satyr_piper", 4, 2, (1.7, 1.0), 12.0, "hurt_height"),
    "satyr_brute": ("satyr_brute", 4, 2, (2.6, 1.4), 17.0, "hurt_height"),
    "goat": ("goat", 4, 2, (2.2, 1.1), 11.0, "body_offset"),
    "storm_eagle": ("storm_eagle", 4, 3, (4.0, 1.8), 30.0, "hurt_height"),
    "wisp": ("wisp", 4, 2, (1.0, 0.6), None, None),
}

# nowe sceny: (wzór, nazwa węzła, skrypt, właściwości)
NEW = {
    "satyr": ("goblin", "Satyr", "res://scripts/satyr.gd", {
        "max_health": "300", "damage": "32", "speed": "74.0", "attack_windup": "0.35", "attack_cooldown": "0.9",
        "xp_reward": "140", "gold_min": "10", "gold_max": "20", "aggro_radius": "110.0"}),
    "satyr_piper": ("goblin", "SatyrPiper", "res://scripts/satyr_piper.gd", {
        "max_health": "200", "damage": "20", "speed": "60.0", "attack_windup": "0.5", "attack_cooldown": "1.5",
        "xp_reward": "150", "gold_min": "10", "gold_max": "20", "attack_range": "120.0", "aggro_radius": "130.0",
        "note_damage": "28"}),
    "satyr_brute": ("goblin", "SatyrBrute", "res://scripts/satyr_brute.gd", {
        "max_health": "750", "damage": "60", "speed": "56.0", "attack_windup": "0.7", "attack_cooldown": "2.2",
        "xp_reward": "300", "gold_min": "20", "gold_max": "40", "attack_range": "22.0", "aggro_radius": "120.0"}),
}


def main():
    forest_scenes.ASSET_DIR = "regions"
    layout = json.load(open(LAYOUT)) if os.path.exists(LAYOUT) else {}
    for name, (template, node, script, props) in NEW.items():
        if not os.path.exists(forest_scenes.scene_path(name)):
            forest_scenes.create(name, template, node, script, props)
    for name, (sheet, hframes, vframes, shadow, height, prop) in SCENES.items():
        if sheet in layout:
            forest_scenes.wire(name, sheet, hframes, vframes, shadow, height, prop, layout)
            print("Podpięto", name)


if __name__ == "__main__":
    main()
