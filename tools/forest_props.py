"""Rekwizyty Goblińskiego Lasu z paczek obiektów PixelLab (pixellab_src/forest/<paczka>/frame_<i>.png,
pobrane przez pixellab_src/forest/fetch.py packs). Każdy wybrany obiekt jest zmniejszany jak postacie
(hero_sheets.shrink_image - ta sama gęstość pikseli), przycinany do sylwetki i zapisywany jako
assets/forest/props/<nazwa>.png. Do każdego powstaje scena scenes/props/forest/<nazwa>.tscn:
przeszkoda (StaticBody2D z prostokątem u podstawy) albo sama ozdoba (Node2D) - podstawa obiektu
leży w punkcie węzła, więc sortowanie po y działa jak u postaci.
Uruchom: python tools/forest_props.py"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "forest")
OUT = os.path.join(ROOT, "assets", "forest", "props")
SCENES = os.path.join(ROOT, "scenes", "props", "forest")

# nazwa: (paczka, klatka, skala, podstawa kolizji (szer., wys.) albo None dla ozdoby)
PROPS = {
    "tent": ("camp", 0, 0.75, (30, 8)),
    "hide_tent": ("camp", 1, 0.75, (34, 9)),
    "weapon_rack": ("camp", 2, 0.6, (26, 5)),
    "cage": ("camp", 3, 0.6, (24, 8)),
    "hide_rack": ("camp", 4, 0.6, (26, 5)),
    "loot": ("camp", 5, 0.55, (22, 6)),
    "banner": ("camp", 6, 0.6, (6, 4)),
    "shields": ("camp", 7, 0.5, (20, 6)),
    "pots": ("camp", 8, 0.45, (18, 5)),
    "bedroll": ("camp", 9, 0.5, None),
    "log_seat": ("camp", 10, 0.55, (26, 5)),
    "skull_totem": ("camp", 11, 0.65, (8, 5)),
    "bone_pile": ("camp", 12, 0.5, None),
    "barrel": ("camp", 13, 0.45, (12, 5)),
    "cauldron": ("camp", 14, 0.55, (22, 6)),
    "palisade": ("camp", 15, 0.6, (32, 6)),
    # duże namioty obozu (paczka 128 px) - dawne z paczki 64 px były ledwie większe od goblina
    "goblin_tent_0": ("camp_tents", 0, 0.62, (58, 10)),
    "goblin_tent_1": ("camp_tents", 1, 0.62, (58, 10)),
    "goblin_tent_2": ("camp_tents", 2, 0.62, (58, 10)),
    "goblin_tent_3": ("camp_tents", 3, 0.62, (52, 10)),
    "wolf_den": ("wolves", 0, 0.75, (40, 10)),
    "carcass": ("wolves", 1, 0.6, None),
    "ribcage": ("wolves", 2, 0.6, (24, 6)),
    "bones": ("wolves", 3, 0.5, None),
    "dead_tree": ("wolves", 5, 0.8, (10, 6)),
    "hollow_log": ("wolves", 6, 0.6, (34, 8)),
    "flat_rock": ("wolves", 7, 0.6, (34, 10)),
    "skull_pole": ("wolves", 8, 0.55, (6, 4)),
    "antlers": ("wolves", 9, 0.5, None),
    "thorns": ("wolves", 10, 0.55, (26, 6)),
    "boulders": ("wolves", 11, 0.6, (32, 10)),
    "dead_stump": ("wolves", 12, 0.6, (16, 6)),
    "bone_throne": ("wolves", 13, 0.75, (30, 10)),
    "wolf_totem": ("wolves", 14, 0.6, (8, 5)),
    "skull_bones": ("wolves", 15, 0.45, None),
    # wioska satyrów (Wietrzne Turnie)
    "satyr_tent": ("satyr", 0, 0.75, (32, 8)),
    "satyr_hut": ("satyr", 1, 0.75, (34, 9)),
    "satyr_barrels": ("satyr", 2, 0.55, (22, 6)),
    "satyr_amphoras": ("satyr", 3, 0.5, (20, 5)),
    "satyr_vines": ("satyr", 4, 0.65, (30, 5)),
    "satyr_press": ("satyr", 5, 0.6, (26, 7)),
    "satyr_maypole": ("satyr", 6, 0.85, (8, 5)),
    "satyr_totem": ("satyr", 7, 0.7, (8, 5)),
    "satyr_stone": ("satyr", 8, 0.6, (14, 6)),
    "satyr_arch": ("satyr", 9, 0.85, None),
    "satyr_bench": ("satyr", 10, 0.5, (24, 5)),
    "satyr_drums": ("satyr", 11, 0.5, (16, 5)),
    "satyr_feast": ("satyr", 12, 0.55, None),
    "satyr_firepit": ("satyr", 13, 0.6, None),
    "satyr_statue": ("satyr", 14, 0.7, (12, 6)),
    "satyr_hay": ("satyr", 15, 0.55, (22, 6)),
}

SOLID = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/prop.gd" id="1_prop"]
[ext_resource type="Texture2D" path="res://assets/forest/props/{name}.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_base"]
size = Vector2({w}, {h})

[node name="{node}" type="StaticBody2D"]
script = ExtResource("1_prop")

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
offset = Vector2(0, {offset})

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, {cy})
shape = SubResource("RectangleShape2D_base")
"""

DECOR = """[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/forest/props/{name}.png" id="2_tex"]

[node name="{node}" type="Node2D"]

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
offset = Vector2(0, {offset})
"""


def build(name, pack, index, scale, base):
    src = Image.open(os.path.join(SRC, pack, "frame_%d.png" % index)).convert("RGBA")
    small = hero_sheets.shrink_image(src, round(src.width * scale), round(src.height * scale))
    box = small.getbbox()
    # poziomo symetrycznie względem środka płótna (obiekty PixelLab stoją pośrodku)
    cx = small.width / 2.0
    half = int(max(cx - box[0], box[2] - cx) + 0.999)
    left = int(cx) - half
    img = small.crop((left, box[1], left + half * 2, box[3]))
    img.save(os.path.join(OUT, name + ".png"))
    # podstawa obiektu 2 piksele nad dolną krawędzią (cień, trawa wokół podstawy)
    offset = -(img.height / 2.0) + 2
    node = "".join(part.capitalize() for part in name.split("_"))
    if base:
        text = SOLID.format(name=name, node=node, offset="%g" % offset, w=base[0], h=base[1], cy="%g" % (-base[1] / 2.0 + 1))
    else:
        text = DECOR.format(name=name, node=node, offset="%g" % offset)
    open(os.path.join(SCENES, name + ".tscn"), "w", encoding="utf-8", newline="\n").write(text)
    return img.size


## Warianty istniejących scen przeszkód (tree_oak, tree_pine, bush, boulder, stump): każda klatka
## trafia na wspólne płótno sceny z podstawą przy dolnej krawędzi, więc jedno przesunięcie
## sprite'a pasuje do wszystkich wariantów. scena: (płótno (szer., wys.), skala, [(paczka, klatka)])
VARIANTS = {
    "oak": ((64, 64), 0.75, [("trees", 0), ("trees", 1), ("trees", 2), ("trees2", 4), ("trees2", 5), ("trees2", 7),
                             ("trees", 3), ("trees2", 6)]),
    "pine": ((48, 64), 0.75, [("trees2", 0), ("trees2", 1), ("trees2", 3), ("trees2", 10), ("trees2", 8)]),
    "bush": ((36, 30), 0.45, [("trees2", 12), ("trees2", 15), ("trees2", 11)]),
    "rock": ((24, 20), 0.75, [("small", 2), ("small", 3), ("small", 62)]),
    "stump": ((24, 20), 0.75, [("small", 12), ("small", 35)]),
}
## Drobne ozdoby runa (bez kolizji) w jednym pasku klatek 24x24: kwiaty, grzyby, trawy, paprocie, gałązki, liście.
DECO = [4, 5, 6, 19, 24, 33, 40, 7, 8, 26, 34, 43, 48, 58, 9, 10, 13, 16, 31, 46, 47, 11, 17, 29, 53, 15, 21, 44, 45, 25, 50]
DECO_CELL = 24
## Klatki z liśćmi (kępka, liść dębu, rozsypane liście) - PixelLab rysował je na całą klatkę, więc po
## zmniejszeniu wychodziły wielkie jak grzyby; dostają połowę klatki.
DECO_LEAVES = {25: 0.5, 26: 0.45, 27: 0.5}


def _variant(pack, index, scale, canvas):
    src = Image.open(os.path.join(SRC, pack, "frame_%d.png" % index)).convert("RGBA")
    small = hero_sheets.shrink_image(src, round(src.width * scale), round(src.height * scale))
    # paczki 80x80 mają czasem okruchy sąsiedniej klatki przy górnej krawędzi - bierzemy największą bryłę
    box = _main_box(small)
    img = small.crop(box)
    out = Image.new("RGBA", canvas)
    out.alpha_composite(img, (max(0, (canvas[0] - img.width) // 2), max(0, canvas[1] - 1 - img.height)))
    return out


def _main_box(img):
    """Obrys bez pustych wierszy oddzielających okruchy od obiektu (szukamy przerwy od góry)."""
    box = img.getbbox()
    alpha = img.getchannel("A")
    top = box[1]
    for y in range(box[1], box[3]):
        row = alpha.crop((0, y, img.width, y + 1)).getbbox()
        if row is None:
            top = y + 1
        elif y - top > 6:
            break
    return (box[0], top, box[2], box[3])


def variants():
    out_dir = os.path.join(ROOT, "assets", "forest", "trees")
    os.makedirs(out_dir, exist_ok=True)
    for kind, (canvas, scale, frames) in VARIANTS.items():
        for i, (pack, index) in enumerate(frames):
            _variant(pack, index, scale, canvas).save(os.path.join(out_dir, "%s_%d.png" % (kind, i)))
        print(kind, len(frames))
    strip = Image.new("RGBA", (DECO_CELL * len(DECO), DECO_CELL))
    for i, index in enumerate(DECO):
        src = Image.open(os.path.join(SRC, "small", "frame_%d.png" % index)).convert("RGBA")
        size = round(DECO_CELL * DECO_LEAVES.get(i, 1.0))
        small = hero_sheets.shrink_image(src, size, size)
        strip.alpha_composite(small, (i * DECO_CELL + (DECO_CELL - size) // 2, DECO_CELL - size))
    strip.save(os.path.join(ROOT, "assets", "forest", "deco.png"))
    print("deco", len(DECO))


def campfire():
    """Ognisko: 4 klatki płomieni (animacja obiektu z PixelLab) w pasku dla scenes/props/campfire.tscn."""
    anims = os.path.join(SRC, "campfire", "animations")
    if not os.path.isdir(anims):
        return
    folder = os.path.join(anims, os.listdir(anims)[0], "unknown")
    frames = [Image.open(os.path.join(folder, f)).convert("RGBA") for f in sorted(os.listdir(folder))]
    size = round(frames[0].width * 0.75)
    strip = Image.new("RGBA", (size * len(frames), size))
    for i, img in enumerate(frames):
        strip.alpha_composite(hero_sheets.shrink_image(img, size, size), (i * size, 0))
    strip.save(os.path.join(OUT, "campfire.png"))
    print("campfire", strip.size)


def main():
    campfire()
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SCENES, exist_ok=True)
    for name, (pack, index, scale, base) in PROPS.items():
        if os.path.exists(os.path.join(SRC, pack, "frame_%d.png" % index)):
            print(name, build(name, pack, index, scale, base))
    variants()


if __name__ == "__main__":
    main()
