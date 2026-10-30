"""Grafiki Pól Zbożowych z PixelLab (pixellab_src/fields/, pobrane przez pixellab_src/fields/fetch.py):
rekwizyty i budynki z paczek kandydatów, drobiazgi, arkusze koboldów i czerwi, tekstura ścierniska i sceny
stworzeń (zaorana ziemia - fields_art.py). Składanie jak w region_sheets / region_props / region_scenes.
Wynik: assets/fields/*.png, scenes/<stworzenie>.tscn.
Uruchom: python tools/fields_sheets.py (albo na końcu generate_art.py)"""
import json
import os

from PIL import Image, ImageEnhance

import forest_scenes
import forest_sheets
import region_props
import region_sheets
from alpine_tiles import full_tile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "fields")
OUT = os.path.join(ROOT, "assets", "fields")

# plik -> (paczka, klatka, skala)
PROPS = {
    "haystack": ("props", 0, 0.75), "hay_bale": ("props", 1, 0.45), "scarecrow": ("props", 2, 0.7),
    "well": ("props", 3, 0.7), "cart": ("props", 4, 0.75), "stook": ("props", 5, 0.5), "trough": ("props", 6, 0.55),
    "plough": ("props", 7, 0.55), "sacks": ("props", 8, 0.5), "fence": ("props", 9, 0.55), "wall": ("props", 10, 0.7),
    "wall_end": ("props", 11, 0.7), "rubble": ("props", 12, 0.55), "totem": ("props", 13, 0.7),
    "bomb_crate": ("props", 14, 0.5), "powder_barrel": ("props", 15, 0.42),
    "farmhouse": ("buildings", 0, 0.9), "barn": ("buildings", 1, 0.95), "windmill": ("buildings", 2, 1.0),
    "kobold_tent": ("buildings", 3, 0.7),
}
DECOR_CELL = 24

# stworzenia: rzędy klatek (ścieżki względem SRC) i wymagane animacje
CREATURES = {
    "kobold": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.rot(n),
                                                 region_sheets.frame(n, "attack", 1), region_sheets.frame(n, "attack", 3)]],
               ["walk", "attack"]),
    "kobold_slinger": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.rot(n),
                                                         region_sheets.frame(n, "attack", 2), region_sheets.frame(n, "attack", 4)]],
                       ["walk", "attack"]),
    "kobold_bomber": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.rot(n),
                                                        region_sheets.frame(n, "attack", 2), region_sheets.frame(n, "attack", 4)]],
                      ["walk", "attack"]),
    "kobold_bombardier": (lambda n: [region_sheets.walk(n), [region_sheets.rot(n), region_sheets.frame(n, "throw", 2),
                                                            region_sheets.frame(n, "throw", 4), region_sheets.frame(n, "jump", 4)]],
                          ["walk", "throw", "jump"]),
}

# scena: (arkusz, cień, wysokość tułowia)
SCENES = {
    "kobold": ("kobold", (1.5, 0.9), 9.0),
    "kobold_slinger": ("kobold_slinger", (1.5, 0.9), 9.0),
    "kobold_bomber": ("kobold_bomber", (1.5, 0.9), 9.0),
    "kobold_bombardier": ("kobold_bombardier", (3.2, 1.7), 20.0),
    "field_worm": ("field_worm", (1.8, 1.0), 14.0),
    "giant_worm": ("giant_worm", (4.6, 2.2), 34.0),
}
# nowe sceny: (wzór, węzeł, skrypt, właściwości)
NEW = {
    "kobold": ("goblin", "Kobold", "res://scripts/kobold.gd", {
        "max_health": "70", "damage": "13", "speed": "70.0", "attack_windup": "0.3", "attack_cooldown": "0.8",
        "xp_reward": "14", "gold_min": "4", "gold_max": "9", "aggro_radius": "100.0", "attack_range": "20.0"}),
    "kobold_slinger": ("goblin", "KoboldSlinger", "res://scripts/kobold_slinger.gd", {
        "max_health": "55", "damage": "10", "speed": "64.0", "attack_windup": "0.5", "attack_cooldown": "1.6",
        "xp_reward": "15", "gold_min": "4", "gold_max": "9", "attack_range": "130.0", "aggro_radius": "130.0",
        "stone_damage": "12"}),
    "kobold_bomber": ("goblin", "KoboldBomber", "res://scripts/kobold_bomber.gd", {
        "max_health": "60", "damage": "10", "speed": "60.0", "attack_windup": "0.6", "attack_cooldown": "2.4",
        "xp_reward": "17", "gold_min": "5", "gold_max": "10", "attack_range": "140.0", "aggro_radius": "130.0",
        "bomb_damage": "20"}),
    "field_worm": ("goblin", "FieldWorm", "res://scripts/field_worm.gd", {
        "max_health": "130", "damage": "14", "speed": "85.0", "attack_windup": "0.3", "attack_cooldown": "0.9",
        "xp_reward": "22", "gold_min": "4", "gold_max": "10", "aggro_radius": "110.0", "attack_range": "22.0",
        "leash_radius": "320.0", "erupt_damage": "20"}),
    "kobold_bombardier": ("frog_chief", "KoboldBombardier", "res://scripts/kobold_bombardier.gd", {
        "max_health": "1000", "damage": "20", "speed": "60.0", "xp_reward": "260", "gold_min": "10", "gold_max": "20",
        "aggro_radius": "150.0", "leash_radius": "420.0", "attack_interval": "1.4", "boss_name": '"Bombardier Kaszlak"',
        "legendary_drops": 'PackedStringArray("legend_kaszlak_gloves", "legend_kaszlak_boots", "legend_kaszlak_cord", "legend_kaszlak_staff")',
        "bomb_damage": "28", "barrel_damage": "55"}),
    "giant_worm": ("frog_chief", "GiantWorm", "res://scripts/giant_worm.gd", {
        "max_health": "1200", "damage": "22", "speed": "60.0", "xp_reward": "280", "gold_min": "10", "gold_max": "20",
        "aggro_radius": "150.0", "leash_radius": "420.0", "attack_interval": "1.5", "boss_name": '"Pożeracz Pól"',
        "legendary_drops": 'PackedStringArray("legend_devourer_helm", "legend_devourer_chest", "legend_devourer_bow", "legend_devourer_amulet")',
        "erupt_damage": "50", "slam_damage": "45", "acid_damage": "24", "quake_damage": "32"}),
}


def props():
    os.makedirs(OUT, exist_ok=True)
    region_props.SRC = SRC
    region_props.ASSETS = OUT
    for name, (pack, index, scale) in PROPS.items():
        if os.path.exists(os.path.join(SRC, pack, "frame_%d.png" % index)):
            region_props.build(name + ".png", pack, [index], scale)
    if os.path.exists(os.path.join(SRC, "small", "frame_15.png")):
        region_props.decor("decor.png", "small", list(range(16)), DECOR_CELL)
    print("fields: rekwizyty")


def grounds():
    # zaorana ziemia rysowana jest w fields_art.py (tekstura z PixelLab nie zawijała się w poziomie)
    for name, (tileset, adjust) in {"stubble": ("stubble", (0.85, 0.9))}.items():
        png = os.path.join(SRC, "wang", tileset + ".png")
        if not os.path.exists(png):
            continue
        meta = json.load(open(os.path.join(SRC, "wang", tileset + ".json"), encoding="utf-8"))
        tile = full_tile(Image.open(png).convert("RGBA"), meta, "upper")
        if tile is None:
            continue
        tile = ImageEnhance.Brightness(ImageEnhance.Color(tile).enhance(adjust[0])).enhance(adjust[1])
        os.makedirs(os.path.join(OUT, "ground"), exist_ok=True)
        tile.save(os.path.join(OUT, "ground", name + ".png"))
    print("fields: podłoże")


def worms(layout):
    region_sheets.SRC = SRC
    for name, scale in (("field_worm", 0.55), ("giant_worm", 0.8)):
        frames = {}
        anims = os.path.join(SRC, name, "animations")
        if not os.path.isdir(anims):
            continue
        for folder in os.listdir(anims):
            sub = os.path.join(anims, folder, "unknown")
            imgs = [Image.open(os.path.join(sub, f)).convert("RGBA") for f in sorted(os.listdir(sub))]
            lower = folder.lower()
            key = "sink" if "sink" in lower else "attack" if ("slam" in lower or "lunge" in lower or "rears" in lower) else "sway"
            frames[key] = imgs
        if len(frames) < 3:
            continue
        sw, at, sk = frames["sway"], frames["attack"], frames["sink"]
        cells = sw[:4] + [sk[-1], sk[len(sk) // 2], at[1], at[-2]]
        w, h = region_sheets.object_sheet(cells, os.path.join(OUT, name + ".png"), scale=scale)
        layout[name] = {"cell": [w, h], "offset_y": -(h / 2.0) + 6}
        print(name, w, h)


def creatures(layout):
    forest_sheets.SRC = SRC
    forest_sheets.OUT = OUT
    for name, (rows, anims) in CREATURES.items():
        folder = os.path.join(SRC, name, "animations")
        if not all(os.path.isdir(os.path.join(folder, a)) for a in anims):
            continue
        layout[name] = forest_sheets.build(name, rows(name))
        print("Zapisano %s %s" % (name, layout[name]))


def scenes(layout):
    forest_scenes.ASSET_DIR = "fields"
    for name, (template, node, script, values) in NEW.items():
        if not os.path.exists(forest_scenes.scene_path(name)):
            forest_scenes.create(name, template, node, script, values)
    for name, (sheet, shadow, height) in SCENES.items():
        if sheet in layout and os.path.exists(forest_scenes.scene_path(name)):
            forest_scenes.wire(name, sheet, 4, 2, shadow, height, "hurt_height", layout)
            print("Podpięto", name)


def main():
    props()
    grounds()
    layout_path = os.path.join(SRC, "layout.json")
    layout = json.load(open(layout_path)) if os.path.exists(layout_path) else {}
    creatures(layout)
    worms(layout)
    json.dump(layout, open(layout_path, "w"), indent=1)
    scenes(layout)


if __name__ == "__main__":
    main()
