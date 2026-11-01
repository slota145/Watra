"""Rekwizyty wioski satyrów w Wietrznych Turniach (winne święto) z PixelLab: paczki obiektów
create_1_direction_object w pixellab_src/regions/satyr_village/<paczka>/frame_<i>.png (identyfikatory w ids.json):
- houses (128 px): dwie chaty z bali z dachem z trzciny i winoroślą, winiarnia z tłocznią, altana,
- feast (128 px): długi stół biesiadny, tron z beczek, podwyższenie grajków, wielkie ognisko,
- vineyard (64 px): rzędy winorośli, lampiony, girlanda, jabłoń, grusza, płot zagrody, koryto i drobiazgi.
Wielkie ognisko jest animowane (animate_object, klatki w pixellab_src/regions/satyr_village/bonfire/frame_<i>.png).

Każdy obiekt jest zmniejszany jak postacie (hero_sheets.shrink_image), przycinany do sylwetki i zapisywany jako
assets/mountains/satyr/<nazwa>.png; do każdego powstaje scena scenes/props/mountains/satyr/<nazwa>.tscn
(przeszkoda z prostokątem u podstawy albo sama ozdoba; podstawa obiektu w punkcie węzła).
Uruchom: python tools/satyr_village_art.py"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "regions", "satyr_village")
OUT = os.path.join(ROOT, "assets", "mountains", "satyr")
SCENES = os.path.join(ROOT, "scenes", "props", "mountains", "satyr")

# nazwa: (paczka, klatka, skala, podstawa kolizji (szer., wys.) albo None dla ozdoby)
PROPS = {
    "cottage": ("houses", 0, 0.8, (66, 16)),
    "cottage_porch": ("houses", 1, 0.8, (70, 16)),
    "winery": ("houses", 2, 0.85, (78, 18)),
    "arbor": ("houses", 3, 0.8, (64, 10)),
    "banquet": ("feast", 0, 0.9, (76, 20)),
    "throne": ("feast", 1, 0.6, (40, 10)),
    "stage": ("feast", 2, 0.7, None),  # podest leży pod postaciami (warstwa podłóg), grajkowie stoją na nim
    "vine_row": ("vineyard", 0, 0.75, (42, 6)),
    "vine_row_2": ("vineyard", 1, 0.75, (42, 6)),
    "lantern": ("vineyard", 2, 0.75, (6, 4)),
    "garland": ("vineyard", 3, 0.9, None),
    "apple_tree": ("vineyard", 4, 0.85, (10, 6)),
    "pear_tree": ("vineyard", 5, 0.85, (10, 6)),
    "fence": ("vineyard", 6, 0.75, (44, 6)),
    "trough": ("vineyard", 7, 0.6, (30, 6)),
    "grape_basket": ("vineyard", 8, 0.45, None),
    "stomp_tub": ("vineyard", 9, 0.55, (24, 6)),
    "barrel_pile": ("vineyard", 10, 0.6, (30, 8)),
    "keg": ("vineyard", 11, 0.5, (16, 5)),
    "wreath_pole": ("vineyard", 12, 0.7, (6, 4)),
    "amphora": ("vineyard", 13, 0.5, (14, 5)),
    "ladder_basket": ("vineyard", 14, 0.55, None),
    "grape_cart": ("vineyard", 15, 0.6, (30, 8)),
}
## Wielkie ognisko: skala klatek i podstawa kolizji.
BONFIRE_SCALE = 0.7
BONFIRE_BASE = (44, 14)

SOLID = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/prop.gd" id="1_prop"]
[ext_resource type="Texture2D" path="res://assets/mountains/satyr/{name}.png" id="2_tex"]

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

[ext_resource type="Texture2D" path="res://assets/mountains/satyr/{name}.png" id="2_tex"]

[node name="{node}" type="Node2D"]

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
offset = Vector2(0, {offset})
"""

## Ognisko: animowany sprite (scripts/campfire.gd przełącza klatki), poświata i kolizja u podstawy.
BONFIRE = """[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/campfire.gd" id="1_fire"]
[ext_resource type="Texture2D" path="res://assets/mountains/satyr/bonfire.png" id="2_tex"]

[sub_resource type="Gradient" id="Gradient_glow"]
colors = PackedColorArray(1, 0.6, 0.2, 0.4, 1, 0.45, 0.1, 0)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_glow"]
gradient = SubResource("Gradient_glow")
width = 320
height = 220
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(1, 0.5)

[sub_resource type="CanvasItemMaterial" id="CanvasItemMaterial_add"]
blend_mode = 1

[sub_resource type="RectangleShape2D" id="RectangleShape2D_base"]
size = Vector2({w}, {h})

[node name="Bonfire" type="StaticBody2D"]
script = ExtResource("1_fire")

[node name="Glow" type="Sprite2D" parent="."]
material = SubResource("CanvasItemMaterial_add")
position = Vector2(0, -16)
texture = SubResource("GradientTexture2D_glow")

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
offset = Vector2(0, {offset})
hframes = {frames}

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, {cy})
shape = SubResource("RectangleShape2D_base")
"""


def _node(name):
    return "Satyr" + "".join(part.capitalize() for part in name.split("_"))


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
    if base:
        text = SOLID.format(name=name, node=_node(name), offset="%g" % offset, w=base[0], h=base[1], cy="%g" % (-base[1] / 2.0 + 1))
    else:
        text = DECOR.format(name=name, node=_node(name), offset="%g" % offset)
    open(os.path.join(SCENES, name + ".tscn"), "w", encoding="utf-8", newline="\n").write(text)
    return img.size


def bonfire():
    """Klatki ogniska w jednym pasku; wspólny obrys wszystkich klatek (płomienie skaczą różnie wysoko)."""
    folder = os.path.join(SRC, "bonfire")
    names = sorted((f for f in os.listdir(folder) if f.startswith("frame_")), key=lambda f: int(f[6:-4]))
    frames = []
    for f in names:
        src = Image.open(os.path.join(folder, f)).convert("RGBA")
        frames.append(hero_sheets.shrink_image(src, round(src.width * BONFIRE_SCALE), round(src.height * BONFIRE_SCALE)))
    box = [min(img.getbbox()[i] for img in frames) if i < 2 else max(img.getbbox()[i] for img in frames) for i in range(4)]
    cx = frames[0].width / 2.0
    half = int(max(cx - box[0], box[2] - cx) + 0.999)
    left = int(cx) - half
    cells = [img.crop((left, box[1], left + half * 2, box[3])) for img in frames]
    w, h = cells[0].size
    strip = Image.new("RGBA", (w * len(cells), h))
    for i, img in enumerate(cells):
        strip.alpha_composite(img, (i * w, 0))
    strip.save(os.path.join(OUT, "bonfire.png"))
    text = BONFIRE.format(offset="%g" % (-(h / 2.0) + 2), frames=len(cells), w=BONFIRE_BASE[0], h=BONFIRE_BASE[1],
                          cy="%g" % (-BONFIRE_BASE[1] / 2.0 + 1))
    open(os.path.join(SCENES, "bonfire.tscn"), "w", encoding="utf-8", newline="\n").write(text)
    return strip.size


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SCENES, exist_ok=True)
    for name, (pack, index, scale, base) in PROPS.items():
        print(name, build(name, pack, index, scale, base))
    if os.path.isdir(os.path.join(SRC, "bonfire")):
        print("bonfire", bonfire())


if __name__ == "__main__":
    main()
