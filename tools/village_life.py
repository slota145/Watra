"""Życie osady z PixelLab: rekwizyty stref (obóz uchodźców, rynek, zagroda, kąciki pracy - paczki
pixellab_src/village/<camp_big|camp_small|fences>/frame_<i>.png), arkusze świń (pixellab_src/village/animals/<świnia>/
- postacie z PixelLab pobrane przez fetch.py animals) i nutki grajka.

Świnia: arkusz 8 kolumn x 3 rzędy (Livestock): chód (4), rycie (klatki 1-4 animacji eat), kładzenie się
(klatki 1-8 animacji sleep - ostatnia leży); skala i komórki jak zwierzyna lasu (forest_sheets.build).
Uruchom: python tools/village_life.py (albo na końcu generate_art.py)"""
import os

from PIL import Image

import forest_sheets
import village_props

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "village")
OUT = os.path.join(ROOT, "assets", "village")

# nazwa: (paczka, klatka, docelowy dłuższy bok w świecie)
PROPS = {
    "refugee_tent_0": ("camp_big", 0, 46), "refugee_tent_1": ("camp_big", 1, 46), "lean_to": ("camp_big", 2, 40),
    "covered_wagon": ("camp_big", 3, 54), "handcart": ("camp_big", 4, 34),
    "stall_veg": ("camp_big", 5, 46), "stall_bread": ("camp_big", 6, 46), "stall_goods": ("camp_big", 7, 46),
    "trough": ("camp_big", 10, 28), "mud": ("camp_big", 11, 40), "pig_shelter": ("camp_big", 12, 38),
    "water_trough": ("camp_big", 13, 26), "hay_pile": ("camp_big", 14, 28),
    "bedroll": ("camp_small", 0, 18), "bedroll_open": ("camp_small", 1, 22), "cook_pot": ("camp_small", 2, 24),
    "bundle": ("camp_small", 3, 12), "quench_barrel": ("camp_small", 4, 16), "grindstone": ("camp_small", 5, 20),
    "chop_block": ("camp_small", 6, 18), "firewood": ("camp_small", 7, 22), "coal_sack": ("camp_small", 8, 14),
    "grain_sacks": ("camp_small", 9, 20), "apple_crate": ("camp_small", 10, 16), "cabbage_crate": ("camp_small", 11, 16),
    "camp_stool": ("camp_small", 12, 10), "laundry_basket": ("camp_small", 14, 14), "wash_tub": ("camp_small", 15, 18),
    "pen_fence_h": ("fences", 2, 28), "pen_fence_v": ("fences", 0, 24), "pen_post": ("fences", 4, 12),
    "sleeping_cat": ("fences", 6, 14), "resting_dog": ("fences", 7, 20), "slops_bucket": ("fences", 9, 12),
    "pig_sign": ("fences", 11, 20), "turnips": ("fences", 12, 14), "pitchfork": ("fences", 13, 22),
    "water_bucket": ("fences", 15, 12),
    # budowle z menu sołtysa (z zewnątrz) i ich otoczenie
    "jeweler_hut": ("b_jeweler", 0, 100), "gem_bench": ("props_jeweler", 0, 26), "gem_wheel": ("props_jeweler", 1, 22),
    "gem_case": ("props_jeweler", 2, 22), "crystal_crate": ("props_jeweler", 3, 18),
    "infirmary": ("b_infirmary", 1, 112), "chapel": ("b_chapel", 2, 112), "bathhouse": ("b_bathhouse", 1, 104),
    "cottage_0": ("b_cottage", 0, 64), "cottage_1": ("b_cottage", 2, 64),
    "cot_wounded_0": ("props3", 0, 30), "cot_wounded_1": ("props3", 1, 30), "cot_empty": ("props3", 2, 30),
    "herb_rack": ("props3", 3, 30), "mortar_table": ("props3", 4, 24), "candle_stand": ("props3", 5, 22),
    "offering_box": ("props3", 6, 14), "bath_tub": ("props3", 7, 28), "towel_rack": ("props3", 8, 26),
    "bunting": ("props3", 9, 48), "garland": ("props3", 10, 48), "exotic_crate": ("props3", 11, 20),
    "carpets": ("props3", 12, 22), "altar": ("props3", 13, 26), "pillow_bench": ("props3", 14, 30),
    "kindling": ("props3", 15, 16),
    # kuźnia pod wiatą i ogródki
    "forge_furnace": ("forge_garden", 1, 30), "bellows": ("forge_garden", 2, 18), "weapon_crate": ("forge_garden", 3, 18),
    "tilled_bed": ("forge_garden", 4, 58), "tilled_sprouts": ("forge_garden", 5, 58), "tilled_plot": ("forge_garden", 6, 58),
    "watering_can": ("forge_garden", 7, 12), "garden_hoe": ("forge_garden", 8, 18), "clothesline": ("forge_garden", 9, 34),
    "laundry": ("forge_garden", 10, 14), "ingots": ("forge_garden", 11, 14), "tool_table": ("forge_garden", 12, 22),
    "charcoal": ("forge_garden", 13, 16), "soil_barrow": ("forge_garden", 14, 22), "cabbage_row": ("forge_garden", 15, 26),
}
# ikony 64x64 (assets/items/<nazwa>.png) z paczki icons3
ICONS = ["guard_horn", "meal_stew", "meal_roast", "meal_broth", "bless_wisdom", "bless_might", "rested",
         "greater_health_potion", "greater_mana_potion", "reforge", "bestiary", "tax_pouch"]
PIGS = ["pig_pink", "pig_spotted"]


def props():
    for name, (pack, frame, size) in PROPS.items():
        path = os.path.join(SRC, pack, "frame_%d.png" % frame)
        if os.path.exists(path):
            village_props.build(name, [Image.open(path).convert("RGBA")], size / village_props.GROWTH)


def pigs():
    forest_sheets.SRC = os.path.join(SRC, "animals")
    forest_sheets.OUT = OUT
    fs = forest_sheets
    for pig in PIGS:
        if not os.path.isdir(os.path.join(fs.SRC, pig, "animations", "sleep")):
            continue
        layout = fs.build(pig, [fs.anim(pig, "walk"), [fs.frame(pig, "eat", i) for i in range(1, 5)],
                                [fs.frame(pig, "sleep", i) for i in range(1, 9)]])
        print(pig, layout)


def notes():
    """Dwie nutki 7x9 px (ósemka i dwie połączone) z obrysem - Npc._note."""
    shapes = [
        ["...##..", "...#.#.", "...#..#", "...#...", "...#...", ".###...", "####...", "####...", ".##...."],
        ["..#####", "..#...#", "..#...#", "..#...#", "..#...#", ".##..##", "###.###", "###.###", ".#...#."],
    ]
    sheet = Image.new("RGBA", (9 * len(shapes), 11))
    px = sheet.load()
    for k, rows in enumerate(shapes):
        cells = {(x, y) for y, row in enumerate(rows) for x, ch in enumerate(row) if ch == "#"}
        for x, y in cells:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (k * 9 + 1 + x + dx, 1 + y + dy)
                    if (x + dx, y + dy) not in cells and px[q][3] == 0:
                        px[q] = (26, 28, 43, 255)
        for x, y in cells:
            px[k * 9 + 1 + x, 1 + y] = (255, 255, 255, 255)
    sheet.save(os.path.join(OUT, "note.png"))


# słupy wiaty kuźni na gotowej grafice 115x115 (lewy, przedni, prawy): (x0, y0, x1, y1), dół = podstawa słupa
FORGE_POSTS = {"forge_post_l": (3, 52, 18, 91), "forge_post_m": (51, 70, 66, 115), "forge_post_r": (99, 53, 113, 91)}


def forge_shed():
    """Wiata kuźni (dach na słupach) z PixelLab bez pieca i kowadła, które narysował pod dachem - gra stawia
    pod nią własny piec, kowadło i beczkę (kowal chodzi między nimi). Wycinamy wszystko pod krawędzią dachu
    w kolumnach między przednim a tylnym słupem."""
    import colorsys
    path = os.path.join(SRC, "forge_roof", "frame_2.png")
    if not os.path.exists(path):
        return
    img = Image.open(path).convert("RGBA")
    px = img.load()
    for x in range(71, 107):
        end = None
        for y in range(30, 90):
            r, g, b, a = px[x, y]
            if a and (lambda h, s, v: h < 0.13 and s > 0.45 and v > 0.3)(*colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)):
                end = y
        if end is not None:
            for y in range(end + 2, 112):
                px[x, y] = (0, 0, 0, 0)
    village_props.build("forge_shed", [img], 116 / village_props.GROWTH)
    # słupy osobno (każdy sortowany wg własnej podstawy - nie zasłania tego, co stoi przed nim), dach bez nich
    roof = Image.open(os.path.join(OUT, "forge_shed.png")).convert("RGBA")
    for name, box in FORGE_POSTS.items():
        roof.crop(box).save(os.path.join(OUT, name + ".png"))
        roof.paste(Image.new("RGBA", (box[2] - box[0], box[3] - box[1])), box[:2])
    roof.save(os.path.join(OUT, "forge_shed.png"))


def carried():
    """Niesione przez kowala: rozżarzony pręt (z pieca) i gotowe ostrze (po hartowaniu) - małe, z obrysem."""
    bar = Image.new("RGBA", (14, 5))
    for x in range(1, 13):
        heat = x / 12.0
        bar.putpixel((x, 1), (40, 20, 10, 255))
        bar.putpixel((x, 3), (40, 20, 10, 255))
        bar.putpixel((x, 2), (255, int(120 + 120 * heat), int(40 * heat), 255) if x > 4 else (90, 80, 75, 255))
    bar.putpixel((0, 2), (40, 20, 10, 255))
    bar.putpixel((13, 2), (40, 20, 10, 255))
    bar.save(os.path.join(OUT, "hot_bar.png"))
    blade = Image.new("RGBA", (16, 5))
    for x in range(16):
        for y in range(5):
            edge = y in (0, 4) or x in (0, 15)
            if x < 4:
                color = (40, 25, 15, 255) if edge else (110, 70, 40, 255)
            elif x == 4:
                color = (60, 55, 50, 255) if y in (0, 4) else (150, 140, 120, 255)
            else:
                if y in (0, 4) and x > 13:
                    continue
                color = (40, 40, 48, 255) if edge else ((215, 220, 230, 255) if y == 1 else (165, 170, 182, 255))
            blade.putpixel((x, y), color)
    blade.save(os.path.join(OUT, "blade.png"))


def icons():
    for i, name in enumerate(ICONS):
        path = os.path.join(SRC, "icons3", "frame_%d.png" % i)
        if os.path.exists(path):
            Image.open(path).convert("RGBA").save(os.path.join(ROOT, "assets", "items", name + ".png"))


def main():
    props()
    forge_shed()
    carried()
    icons()
    pigs()
    notes()


if __name__ == "__main__":
    main()
