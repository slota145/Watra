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
}
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


def main():
    props()
    pigs()
    notes()


if __name__ == "__main__":
    main()
