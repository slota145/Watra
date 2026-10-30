"""Grafiki Leśnego Cmentarza z PixelLab (pixellab_src/cemetery/, pobrane przez pixellab_src/cemetery/fetch.py):
rekwizyty i budowle z paczek kandydatów, podłoże (zwiędła trawa, ziemia grobów), arkusze nieumarłych
i ich sceny. Składanie jak w fields_sheets.
Wynik: assets/cemetery/*.png, scenes/<stworzenie>.tscn.
Uruchom: python tools/cemetery_sheets.py (albo na końcu generate_art.py)"""
import json
import os

from PIL import Image, ImageEnhance

import forest_scenes
import forest_sheets
import region_props
import region_sheets
from alpine_tiles import full_tile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "cemetery")
OUT = os.path.join(ROOT, "assets", "cemetery")

PROPS = {
    "gravestone": ("props", 0, 0.45), "celtic_cross": ("props", 1, 0.6), "wood_cross": ("props", 2, 0.45),
    "open_grave": ("props", 3, 0.55), "grave_mound": ("props", 4, 0.5), "fence": ("props", 5, 0.6),
    "fence_broken": ("props", 6, 0.6), "angel": ("props", 7, 0.8), "sarcophagus": ("props", 8, 0.6),
    "dead_tree": ("props", 9, 1.0), "skulls": ("props", 10, 0.5), "lantern": ("props", 11, 0.7),
    "obelisk": ("props", 12, 0.7), "fallen_stone": ("props", 13, 0.45), "ritual": ("props", 14, 1.0),
    "corpses": ("props", 15, 0.7),
    "mausoleum": ("buildings", 0, 1.1), "barrow": ("buildings", 1, 1.2), "chapel": ("buildings", 2, 1.0),
    "crypt": ("buildings", 3, 0.8),
}


def _std(n):
    return [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.rot(n),
                                   region_sheets.frame(n, "attack", 1), region_sheets.frame(n, "attack", 3)]]


CREATURES = {
    "skeleton": (_std, ["walk", "attack"]),
    "skeleton_archer": (_std, ["walk", "attack"]),
    "skeleton_knight": (_std, ["walk", "attack"]),
    "ghoul": (_std, ["walk", "attack"]),
    "zombie": (_std, ["walk", "attack"]),
    "necromancer": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.frame(n, "summon", 3),
                                                      region_sheets.frame(n, "cast", 3), region_sheets.frame(n, "cast", 5)]],
                    ["walk", "summon", "cast"]),
    "colossal_ghoul": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.frame(n, "smash", 1),
                                                         region_sheets.frame(n, "smash", 3), region_sheets.frame(n, "roar", 3)]],
                       ["walk", "smash", "roar"]),
}

SCENES = {
    "skeleton": ("skeleton", (1.6, 0.9), 12.0),
    "skeleton_archer": ("skeleton_archer", (1.6, 0.9), 12.0),
    "skeleton_knight": ("skeleton_knight", (2.2, 1.2), 16.0),
    "ghoul": ("ghoul", (1.7, 1.0), 11.0),
    "zombie": ("zombie", (1.7, 1.0), 12.0),
    "necromancer": ("necromancer", (2.8, 1.5), 22.0),
    "colossal_ghoul": ("colossal_ghoul", (4.4, 2.2), 30.0),
}
NEW = {
    "skeleton": ("goblin", "Skeleton", "res://scripts/skeleton.gd", {
        "max_health": "140", "damage": "20", "speed": "58.0", "attack_windup": "0.4", "attack_cooldown": "1.0",
        "xp_reward": "95", "gold_min": "7", "gold_max": "13", "aggro_radius": "110.0", "attack_range": "20.0"}),
    "skeleton_archer": ("goblin", "SkeletonArcher", "res://scripts/skeleton_archer.gd", {
        "max_health": "110", "damage": "16", "speed": "54.0", "attack_windup": "0.55", "attack_cooldown": "1.7",
        "xp_reward": "100", "gold_min": "7", "gold_max": "13", "attack_range": "150.0", "aggro_radius": "150.0",
        "arrow_damage": "22"}),
    "skeleton_knight": ("goblin", "SkeletonKnight", "res://scripts/skeleton.gd", {
        "max_health": "420", "damage": "42", "speed": "44.0", "attack_windup": "0.75", "attack_cooldown": "1.8",
        "xp_reward": "260", "gold_min": "15", "gold_max": "28", "aggro_radius": "110.0", "attack_range": "26.0",
        "stone_drop_chance": "0.25", "equipment_drop_chance": "0.12"}),
    "ghoul": ("goblin", "Ghoul", "res://scripts/ghoul.gd", {
        "max_health": "170", "damage": "24", "speed": "80.0", "attack_windup": "0.3", "attack_cooldown": "0.8",
        "xp_reward": "120", "gold_min": "8", "gold_max": "14", "aggro_radius": "120.0", "attack_range": "20.0",
        "pounce_damage": "30"}),
    "zombie": ("goblin", "Zombie", "res://scripts/zombie.gd", {
        "max_health": "320", "damage": "28", "speed": "34.0", "attack_windup": "0.55", "attack_cooldown": "1.2",
        "xp_reward": "130", "gold_min": "8", "gold_max": "14", "aggro_radius": "100.0", "attack_range": "20.0"}),
    "necromancer": ("frog_chief", "Necromancer", "res://scripts/necromancer.gd", {
        "max_health": "1800", "damage": "30", "speed": "52.0", "xp_reward": "1900", "gold_min": "18", "gold_max": "30",
        "aggro_radius": "170.0", "leash_radius": "460.0", "attack_interval": "1.3", "boss_name": '"Mortan, Pan Kości"',
        "legendary_drops": 'PackedStringArray("legend_mortan_staff", "legend_mortan_robe", "legend_mortan_crown", "legend_mortan_phylactery")',
        "bone_damage": "30", "beam_damage": "55", "spike_damage": "45"}),
    "colossal_ghoul": ("frog_chief", "ColossalGhoul", "res://scripts/colossal_ghoul.gd", {
        "max_health": "2000", "damage": "34", "speed": "50.0", "xp_reward": "2000", "gold_min": "18", "gold_max": "30",
        "aggro_radius": "160.0", "leash_radius": "440.0", "attack_interval": "1.4", "boss_name": '"Gnilec, Kolosalny Ghul"',
        "legendary_drops": 'PackedStringArray("legend_gnilec_gauntlets", "legend_gnilec_greaves", "legend_gnilec_axe", "legend_gnilec_maw")',
        "sweep_damage": "50", "slam_damage": "65", "leap_damage": "60", "bile_damage": "40"}),
}


def grounds():
    folder = os.path.join(SRC, "wang")
    out = os.path.join(OUT, "ground")
    for name, (tileset, side, adjust) in {"grass": ("soil", "lower", (0.6, 0.62)), "soil": ("soil", "upper", (0.75, 0.85)),
                                          "path": ("path", "upper", (0.6, 0.7))}.items():
        png = os.path.join(folder, tileset + ".png")
        if not os.path.exists(png):
            continue
        meta = json.load(open(os.path.join(folder, tileset + ".json"), encoding="utf-8"))
        tile = full_tile(Image.open(png).convert("RGBA"), meta, side)
        if tile is None:
            continue
        tile = ImageEnhance.Brightness(ImageEnhance.Color(tile).enhance(adjust[0])).enhance(adjust[1])
        os.makedirs(out, exist_ok=True)
        tile.save(os.path.join(out, name + ".png"))
    # liście: przygaszone liście Prastarego Lasu (jaskrawe plamy rzucały się w oczy w mroku)
    leaves = Image.open(os.path.join(ROOT, "assets", "ancient", "ground", "leaves.png")).convert("RGBA")
    ImageEnhance.Brightness(ImageEnhance.Color(leaves).enhance(0.45)).enhance(0.6).save(os.path.join(out, "leaves.png"))
    # ścieżka: dopóki nie ma zestawu z PixelLab - przygaszona ścieżka Prastarego Lasu
    if not os.path.exists(os.path.join(out, "path.png")):
        tile = Image.open(os.path.join(ROOT, "assets", "ancient", "ground", "path.png")).convert("RGBA")
        ImageEnhance.Brightness(ImageEnhance.Color(tile).enhance(0.45)).enhance(1.0).save(os.path.join(out, "path.png"))
    print("cemetery: podłoże")


def main():
    os.makedirs(OUT, exist_ok=True)
    region_props.SRC = SRC
    region_props.ASSETS = OUT
    for name, (pack, index, scale) in PROPS.items():
        if os.path.exists(os.path.join(SRC, pack, "frame_%d.png" % index)):
            region_props.build(name + ".png", pack, [index], scale)
    grounds()
    layout_path = os.path.join(SRC, "layout.json")
    layout = json.load(open(layout_path)) if os.path.exists(layout_path) else {}
    forest_sheets.SRC = SRC
    forest_sheets.OUT = OUT
    for name, (rows, anims) in CREATURES.items():
        folder = os.path.join(SRC, name, "animations")
        if all(os.path.isdir(os.path.join(folder, a)) for a in anims):
            layout[name] = forest_sheets.build(name, rows(name))
            print("Zapisano %s %s" % (name, layout[name]))
    json.dump(layout, open(layout_path, "w"), indent=1)
    forest_scenes.ASSET_DIR = "cemetery"
    for name, (template, node, script, values) in NEW.items():
        if not os.path.exists(forest_scenes.scene_path(name)):
            forest_scenes.create(name, template, node, script, values)
    for name, (sheet, shadow, height) in SCENES.items():
        if sheet in layout and os.path.exists(forest_scenes.scene_path(name)):
            forest_scenes.wire(name, sheet, 4, 2, shadow, height, "hurt_height", layout)
            print("Podpięto", name)


if __name__ == "__main__":
    main()
