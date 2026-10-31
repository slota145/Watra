"""Arkusze stworzeń Goblińskiego Lasu z PixelLab (pixellab_src/forest/<nazwa>/ - rozpakowane
paczki z pixellab_src/forest/fetch.py). Klatki są zmniejszane jak postacie gracza (hero_sheets:
ta sama skala i powrót do oryginalnej palety), żeby wszystko miało tę samą gęstość pikseli.

Układ klatek jak w dotychczasowych skryptach:
- goblin (i łucznik, osiłek): 4x2 - 0-3 chód, 4-5 siedzenie, 6 zamach, 7 cios,
- wódz goblinów: 4x2 - 0-3 chód, 4 spoczynek, 5 zamach, 6 uderzenie, 7 szarża,
- wilk / warg: 4x3 - 0-3 bieg, 4 leżenie, 5-6 jedzenie, 8 przyczajenie, 9 skok,
- wilk alfa: 4x2 - 0-3 bieg, 4 spoczynek, 5 przyczajenie, 6 skok, 7 rozszarpanie,
- zwierzyna: 4x2 - 0-3 bieg, 4-5 pasienie, 6 czujność, 7 stanie.

Wynik: assets/forest/<nazwa>.png i pixellab_src/forest/layout.json (komórka i przesunięcie sprite'a).
Uruchom: python tools/forest_sheets.py"""
import json
import os

from PIL import Image, ImageEnhance

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "forest")
OUT = os.path.join(ROOT, "assets", "forest")
SCALE = hero_sheets.SCALE
DIR = "south-east"
## PixelLab narysował stan "Siedzi" goblina na całe płótno, tak wysoko jak stojącego (38 vs 36 px) - siedzący
## wychodził większy niż po wstaniu. Sylwetkę siedzenia zmniejszamy, zostawiając ją opartą o ziemię.
SIT_SCALE = 0.75
## Stworzenia mniejsze niż wychodzą z PixelLab (mnożnik do SCALE): wilki i wargi zlewały się w stadzie w jedną
## plamę, były większe od goblinów. Wilk Alfa zostaje duży - ma się wyróżniać.
SIZE = {"wolf": 0.78, "warg": 0.8}
## Sarna jest u PixelLab drobna (płótno 56 px) - po zmniejszeniu piksele zlewały się w rozmazaną plamę, więc zostaje 1:1.
SIZE["roe"] = 1.0 / SCALE


def _open(path):
    return Image.open(os.path.join(SRC, path)).convert("RGBA")


def rot(name, state=""):
    return os.path.join(name, state, "rotations", DIR + ".png")


def frame(name, anim, i, state=""):
    return os.path.join(name, state, "animations", anim, DIR, "frame_%03d.png" % i)


def anim(name, anim_name, count=4):
    return [frame(name, anim_name, i) for i in range(count)]


def build(name, rows, out_name=None):
    """rows: lista rzędów ścieżek do klatek. Płótna PixelLab są wyśrodkowane na postaci,
    więc stopy liczymy z obrotu (przesuniętego o różnicę płócien) - jak w hero_sheets."""
    reference = _open(rot(name))
    ref_bottom = reference.getbbox()[3]
    placed = []
    for r, paths in enumerate(rows):
        for c, path in enumerate(paths):
            img = _open(path)
            if "Siedzi" in path:
                img = _sitting(img)
            feet = ref_bottom + (img.height - reference.height) / 2.0
            placed.append((r, c, img, feet))
    left = right = up = down = 0.0
    for _r, _c, img, feet in placed:
        box = img.getbbox()
        cx = img.width / 2.0
        left, right = max(left, cx - box[0]), max(right, box[2] - cx)
        up, down = max(up, feet - box[1]), max(down, box[3] - feet)
    half = int(max(left, right)) + 2
    cell_w = half * 2
    feet_y = int(up) + 2
    cell_h = feet_y + int(down) + 2
    # komórki muszą się dzielić przez skalę bez reszty - zaokrąglamy w górę do wielokrotności 4
    cell_w += -cell_w % 4
    cell_h += -cell_h % 4
    columns = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cell_w * columns, cell_h * len(rows)))
    for r, c, img, feet in placed:
        sheet.alpha_composite(img, (int(c * cell_w + half - img.width / 2.0), int(r * cell_h + feet_y - feet)))
    scale = SCALE * SIZE.get(out_name or name, 1.0)
    small = shrink(sheet, cell_w, cell_h, scale)
    os.makedirs(OUT, exist_ok=True)
    small.save(os.path.join(OUT, (out_name or name) + ".png"))
    w, h = round(cell_w * scale), round(cell_h * scale)
    return {"cell": [w, h], "offset_y": -(round(feet_y * scale) - h / 2.0)}


def _sitting(img):
    """Sylwetka siedzącego goblina zmniejszona do SIT_SCALE, wyśrodkowana i oparta o ten sam dół co oryginał."""
    box = img.getbbox()
    figure = img.crop(box)
    small = hero_sheets.shrink_image(figure, round(figure.width * SIT_SCALE), round(figure.height * SIT_SCALE))
    out = Image.new("RGBA", img.size)
    out.alpha_composite(small, (round((box[0] + box[2]) / 2.0 - small.width / 2.0), box[3] - small.height))
    return out


def shrink(sheet, cell_w, cell_h, scale=SCALE):
    """Zmniejszenie komórka po komórce (hero_sheets._shrink działa na kwadratowych komórkach)."""
    cols, rows = sheet.width // cell_w, sheet.height // cell_h
    out_w, out_h = round(cell_w * scale), round(cell_h * scale)
    out = Image.new("RGBA", (out_w * cols, out_h * rows))
    for r in range(rows):
        for c in range(cols):
            cell = sheet.crop((c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h))
            if cell.getbbox() is None:
                continue
            out.alpha_composite(hero_sheets.shrink_image(cell, out_w, out_h), (c * out_w, r * out_h))
    return out


def creatures():
    layout = {}
    g = "goblin"
    if os.path.exists(os.path.join(SRC, g, "animations")):
        sit = rot(g, "Siedzi") if os.path.exists(os.path.join(SRC, rot(g, "Siedzi"))) else rot(g)
        layout[g] = build(g, [anim(g, "walk"), [sit, sit, frame(g, "attack", 1), frame(g, "attack", 3)]])
    for name, attack in (("goblin_archer", "shoot"), ("goblin_brute", "smash")):
        if os.path.exists(os.path.join(SRC, name, "animations", attack)):
            layout[name] = build(name, [anim(name, "walk"), [rot(name), rot(name), frame(name, attack, 1), frame(name, attack, 3)]])
    c = "goblin_chief"
    if os.path.exists(os.path.join(SRC, c, "animations", "slam")):
        layout[c] = build(c, [anim(c, "walk"), [rot(c), frame(c, "slam", 1), frame(c, "slam", 3), frame(c, "walk", 1)]])
    for w in ("wolf", "warg"):
        if os.path.exists(os.path.join(SRC, w, "animations", "leap")):
            layout[w] = build(w, [anim(w, "run"), [frame(w, "lie", 3), frame(w, "eat", 1), frame(w, "eat", 2), rot(w)],
                                  [frame(w, "leap", 0), frame(w, "leap", 2), rot(w), rot(w)]])
    a = "alpha_wolf"
    if os.path.exists(os.path.join(SRC, a, "animations", "cleave")):
        layout[a] = build(a, [anim(a, "run"), [rot(a), frame(a, "pounce", 0), frame(a, "pounce", 2), frame(a, "cleave", 3)]])
    for beast in ("deer", "roe", "boar", "hare"):
        folder = os.path.join(SRC, beast, "animations")
        if os.path.exists(os.path.join(folder, "run")) and os.path.exists(os.path.join(folder, "eat")):
            layout[beast] = build(beast, [anim(beast, "run"), [frame(beast, "eat", 1), frame(beast, "eat", 2), rot(beast), rot(beast)]])
    return layout


## Przejścia Wang Goblińskiego Lasu w assets/tiles.png za zestawami Prastarego Lasu
## (world.gd: FOREST_WANG_ROW). Wszystkie zestawy mają ten sam dolny teren (łąka), więc kafelek
## o masce 0 każdego zestawu to wariant czystej trawy. Kafelek o masce narożników mask
## (NW<<3 | NE<<2 | SW<<1 | SE, bit = górny teren) leży w kolumnie mask % 4, rzędzie row + 4 * zestaw + mask / 4.
WANG_SETS = ["dark", "road", "flowers"]
FOREST_WANG_ROW = 23


def paste_wang(sheet, folder, name, row):
    """Zestaw Wang z PixelLab (<folder>/<nazwa>.png + .json) do atlasu od rzędu `row` (przygaszony jak łąka lasu)."""
    wang = ImageEnhance.Color(ImageEnhance.Brightness(Image.open(os.path.join(folder, name + ".png")).convert("RGBA")).enhance(0.84)).enhance(0.66)
    meta = json.load(open(os.path.join(folder, name + ".json")))
    for tile in meta["tileset_data"]["tiles"]:
        c = tile["corners"]
        mask = sum(bit for corner, bit in (("NW", 8), ("NE", 4), ("SW", 2), ("SE", 1)) if c[corner] == "upper")
        box = tile["bounding_box"]
        crop = wang.crop((box["x"], box["y"], box["x"] + box["width"], box["y"] + box["height"]))
        sheet.paste(crop, ((mask % 4) * 16, (row + mask // 4) * 16))


def tiles():
    path = os.path.join(ROOT, "assets", "tiles.png")
    old = Image.open(path).convert("RGBA")
    # dalsze rzędy (przejścia rozlewisk i gór z region_sheets.py) zostają
    end = (FOREST_WANG_ROW + 4 * len(WANG_SETS)) * 16
    sheet = Image.new("RGBA", (old.width, max(end, old.height)))
    sheet.paste(old.crop((0, 0, old.width, min(old.height, FOREST_WANG_ROW * 16))), (0, 0))
    if old.height > end:
        sheet.paste(old.crop((0, end, old.width, old.height)), (0, end))
    for n, name in enumerate(WANG_SETS):
        # PixelLab daje bardzo jaskrawą łąkę - przygaszamy ją do tonu reszty krainy
        wang = ImageEnhance.Color(ImageEnhance.Brightness(_open(os.path.join("wang", name + ".png"))).enhance(0.84)).enhance(0.66)
        meta = json.load(open(os.path.join(SRC, "wang", name + ".json")))
        for tile in meta["tileset_data"]["tiles"]:
            c = tile["corners"]
            mask = sum(bit for corner, bit in (("NW", 8), ("NE", 4), ("SW", 2), ("SE", 1)) if c[corner] == "upper")
            box = tile["bounding_box"]
            crop = wang.crop((box["x"], box["y"], box["x"] + box["width"], box["y"] + box["height"]))
            sheet.paste(crop, ((mask % 4) * 16, (FOREST_WANG_ROW + n * 4 + mask // 4) * 16))
    sheet.save(path)


def main():
    if os.path.exists(os.path.join(SRC, "wang", WANG_SETS[-1] + ".json")):
        tiles()
    layout = creatures()
    path = os.path.join(SRC, "layout.json")
    old = json.load(open(path)) if os.path.exists(path) else {}
    old.update(layout)
    json.dump(old, open(path, "w"), indent=1)
    for name, data in layout.items():
        print("Zapisano %s %s" % (name, data))


if __name__ == "__main__":
    main()
