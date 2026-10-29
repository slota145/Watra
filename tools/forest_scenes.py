"""Podpina arkusze stworzeń Goblińskiego Lasu (assets/forest/, z tools/forest_sheets.py) do scen:
tekstura, przesunięcie sprite'a (stopy w środku węzła), siatka klatek, cień i wysokość tułowia.
Tworzy też sceny nowych przeciwników (goblin łucznik, goblin osiłek, warg) na wzór istniejących.
Uruchom po forest_sheets.py: python tools/forest_scenes.py"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUT = os.path.join(ROOT, "pixellab_src", "forest", "layout.json")
## Folder arkuszy w assets/ (region_scenes.py używa tych samych funkcji dla assets/regions).
ASSET_DIR = "forest"

# scena: (arkusz, hframes, vframes, skala cienia, wysokość tułowia, właściwość wysokości albo None)
SCENES = {
    "goblin": ("goblin", 4, 2, (1.6, 1.0), 11.0, "hurt_height"),
    "goblin_archer": ("goblin_archer", 4, 2, (1.6, 1.0), 11.0, "hurt_height"),
    "goblin_brute": ("goblin_brute", 4, 2, (2.6, 1.4), 18.0, "hurt_height"),
    "goblin_chief": ("goblin_chief", 4, 2, (3.4, 1.8), None, None),
    "wolf": ("wolf", 4, 3, (1.9, 1.0), 7.0, "hurt_height"),
    "warg": ("warg", 4, 3, (2.7, 1.3), 11.0, "hurt_height"),
    "alpha_wolf": ("alpha_wolf", 4, 2, (4.0, 1.9), None, None),
    "deer": ("deer", 4, 2, (2.6, 1.3), 16.0, "body_offset"),
    "roe": ("roe", 4, 2, (2.2, 1.1), 12.0, "body_offset"),
    "boar": ("boar", 4, 2, (2.4, 1.2), 7.0, "body_offset"),
    "hare": ("hare", 4, 2, (1.2, 0.7), 5.0, "body_offset"),
}

# nowe sceny: (wzór, nazwa węzła, skrypt albo None, nadpisane właściwości)
NEW = {
    "goblin_archer": ("goblin", "GoblinArcher", "res://scripts/goblin_archer.gd", {
        "max_health": "30", "damage": "6", "attack_windup": "0.5", "attack_cooldown": "1.6", "xp_reward": "14",
        "attack_range": "110.0", "aggro_radius": "120.0"}),
    "goblin_brute": ("goblin", "GoblinBrute", "res://scripts/goblin_brute.gd", {
        "max_health": "160", "damage": "22", "speed": "38.0", "attack_windup": "0.8", "attack_cooldown": "1.6",
        "xp_reward": "40", "attack_range": "24.0"}),
    "warg": ("wolf", "Warg", None, {
        "max_health": "190", "damage": "22", "speed": "70.0", "xp_reward": "45", "pelt_drop_chance": "0.8"}),
}


def scene_path(name):
    return os.path.join(ROOT, "scenes", name + ".tscn")


def create(name, template, node, script, props):
    s = open(scene_path(template), encoding="utf-8").read()
    s = re.sub(r'\[node name="[^"]+" type="CharacterBody2D"\]', '[node name="%s" type="CharacterBody2D"]' % node, s, count=1)
    if script:
        s = re.sub(r'(\[ext_resource type="Script" path=")[^"]+(")', r"\g<1>%s\g<2>" % script, s, count=1)
    head, body = s.split('[node name="Shadow"', 1)
    for key, value in props.items():
        if re.search(r"^%s = .*$" % key, head, flags=re.M):
            head = re.sub(r"^%s = .*$" % key, "%s = %s" % (key, value), head, flags=re.M)
        else:
            head = head.rstrip("\n") + "\n%s = %s\n\n" % (key, value)
    open(scene_path(name), "w", encoding="utf-8", newline="\n").write(head + '[node name="Shadow"' + body)


def wire(name, sheet, hframes, vframes, shadow, height, height_prop, layout):
    s = open(scene_path(name), encoding="utf-8").read()
    s = re.sub(r'path="res://assets/[^"]*" id="2_sheet"', 'path="res://assets/%s/%s.png" id="2_sheet"' % (ASSET_DIR, sheet), s)
    offset = layout[sheet]["offset_y"]
    s = re.sub(r'(texture = ExtResource\("2_sheet"\)\n)offset = Vector2\([^)]*\)', lambda m: m.group(1) + "offset = Vector2(0, %g)" % offset, s)
    s = re.sub(r"(texture = ExtResource\(\"2_sheet\"\)\noffset = [^\n]*\n)(scale = [^\n]*\n)?", r"\1", s)
    s = re.sub(r"hframes = \d+\nvframes = \d+", "hframes = %d\nvframes = %d" % (hframes, vframes), s)
    s = re.sub(r'(\[node name="Shadow"[^\[]*?)(scale = Vector2\([^)]*\)\n)?(texture = ExtResource\("3_shadow"\))',
               lambda m: m.group(1) + "scale = Vector2(%g, %g)\n" % shadow + m.group(3), s, flags=re.S)
    if height_prop:
        head, body = s.split('[node name="Shadow"', 1)
        value = "Vector2(0, -%g)" % height if height_prop == "body_offset" else "%g" % height
        if re.search(r"^%s = .*$" % height_prop, head, flags=re.M):
            head = re.sub(r"^%s = .*$" % height_prop, "%s = %s" % (height_prop, value), head, flags=re.M)
        else:
            head = head.rstrip("\n") + "\n%s = %s\n\n" % (height_prop, value)
        s = head + '[node name="Shadow"' + body
    open(scene_path(name), "w", encoding="utf-8", newline="\n").write(s)


def main():
    layout = json.load(open(LAYOUT))
    for name, (template, node, script, props) in NEW.items():
        if not os.path.exists(scene_path(name)):
            create(name, template, node, script, props)
    for name, (sheet, hframes, vframes, shadow, height, prop) in SCENES.items():
        if sheet in layout:
            wire(name, sheet, hframes, vframes, shadow, height, prop, layout)
            print("Podpięto", name)


if __name__ == "__main__":
    main()
