"""Arkusze mieszkańców osady z PixelLab (pixellab_src/village/npcs/<nazwa>/ - rozpakowane paczki
z pixellab_src/village/fetch.py npcs). Mieszkańcy mają rozmiar postaci gracza: te same płótna,
ta sama skala i powrót do oryginalnej palety (hero_sheets.shrink_image).

Układ jak w dawnych arkuszach (Npc): 4 kolumny x 4 rzędy - chód w dół, w górę, w bok (w prawo,
w lewo odbicie) i praca (klatki 0-2: zamach, uderzenie, powrót). Kto nie ma animacji pracy,
ma w tym rzędzie spoczynek z boku.
Wynik: assets/npc/<nazwa>.png. Uruchom: python tools/npc_sheets.py"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "village", "npcs")
OUT = os.path.join(ROOT, "assets", "npc")
CELL = hero_sheets.CELL
FEET_Y = hero_sheets.FEET_Y
ROWS = [("walk", "south"), ("walk", "north"), ("walk", "east"), ("work", "east")]
## Npc w rzędzie pracy pokazuje klatkę 2 przy zamachu i 1 przy uderzeniu, a animacja z PixelLab
## zaczyna od uniesionych rąk (0-1) i kończy uderzeniem (2-3) - przestawiamy klatki.
WORK_ORDER = [2, 3, 0, 1]


def _frames(name, anim, direction):
    folder = os.path.join(SRC, name, "animations", anim, direction)
    if not os.path.isdir(folder):
        return []
    return [Image.open(os.path.join(folder, f)).convert("RGBA") for f in sorted(os.listdir(folder)) if f.endswith(".png")]


def build(name):
    rotations = os.path.join(SRC, name, "rotations")
    sheet = Image.new("RGBA", (CELL * 4, CELL * len(ROWS)))
    for row, (anim, direction) in enumerate(ROWS):
        reference = Image.open(os.path.join(rotations, direction + ".png")).convert("RGBA")
        frames = _frames(name, anim, direction) or [reference] * 4
        # płótna PixelLab są wyśrodkowane na postaci - stopy z obrotu przesuwamy o różnicę płócien
        ref_bottom = reference.getbbox()[3]
        for col in range(4):
            index = WORK_ORDER[col] if anim == "work" else col
            img = frames[index % len(frames)]
            feet = ref_bottom + (img.height - reference.height) / 2.0
            sheet.alpha_composite(img, (int(col * CELL + CELL / 2 - img.width / 2), int(row * CELL + FEET_Y - feet)))
    out_cell = hero_sheets.OUT_CELL
    small = Image.new("RGBA", (out_cell * 4, out_cell * len(ROWS)))
    for row in range(len(ROWS)):
        for col in range(4):
            cell = sheet.crop((col * CELL, row * CELL, (col + 1) * CELL, (row + 1) * CELL))
            if cell.getbbox():
                small.alpha_composite(hero_sheets.shrink_image(cell, out_cell, out_cell), (col * out_cell, row * out_cell))
    small.save(os.path.join(OUT, name + ".png"))


def main():
    if not os.path.isdir(SRC):
        return
    for name in sorted(os.listdir(SRC)):
        if os.path.isdir(os.path.join(SRC, name, "rotations")):
            build(name)
            print("Mieszkaniec", name)


if __name__ == "__main__":
    main()
