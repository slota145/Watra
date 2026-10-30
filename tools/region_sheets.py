"""Arkusze stworzeń Rozlewisk, Wietrznych Turni i wioski satyrów z PixelLab (pixellab_src/regions/<nazwa>/,
pobrane przez pixellab_src/regions/fetch.py). Składanie i zmniejszanie jak w forest_sheets.build.

Układ 4x2 (0-3 chód, 4-5 spoczynek, 6 zamach, 7 cios), z wyjątkami bossów:
- wódz żab: 4 spoczynek, 5 nabieranie powietrza, 6 język, 7 skok,
- Wodnik: 4 spoczynek, 5 wezwanie, 6 wir, 7 fala,
- utopiec: 4 zanurzony (sam czubek głowy), 5 wynurzanie,
- satyr: 4-5 taniec (gdy "siedzi" przy ognisku).
Wynik: assets/regions/<nazwa>.png i pixellab_src/regions/layout.json.
Uruchom: python tools/region_sheets.py"""
import json
import os

from PIL import Image

import forest_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "regions")
OUT = os.path.join(ROOT, "assets", "regions")


def rot(name):
    return forest_sheets.rot(name)


def frame(name, anim, i):
    return forest_sheets.frame(name, anim, i)


def walk(name):
    return forest_sheets.anim(name, "walk")


def submerged(name):
    """Utopiec pod wodą: z obrotu zostaje tylko czubek głowy z oczami, przesunięty na poziom wody."""
    img = Image.open(os.path.join(SRC, rot(name))).convert("RGBA")
    box = img.getbbox()
    head = img.crop((0, box[1], img.width, box[1] + round((box[3] - box[1]) * 0.22)))
    out = Image.new("RGBA", img.size)
    out.alpha_composite(head, (0, box[3] - head.height))
    path = os.path.join(SRC, name, "submerged.png")
    out.save(path)
    return os.path.join(name, "submerged.png")


# nazwa: funkcja zwracająca rzędy klatek (ścieżki względem SRC); wymagane animacje
CREATURES = {
    "frogman": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "frog_spitter": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "frog_chief": (lambda n: [walk(n), [rot(n), frame(n, "inflate", 2), frame(n, "tongue", 2), frame(n, "jump", 2)]],
                   ["walk", "inflate", "tongue", "jump"]),
    "drowner": (lambda n: [walk(n), [submerged(n), frame(n, "emerge", 1), frame(n, "attack", 1), frame(n, "attack", 3)]],
                ["walk", "emerge", "attack"]),
    "rusalka": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "wodnik": (lambda n: [walk(n), [rot(n), frame(n, "summon", 2), frame(n, "whirl", 2), frame(n, "wave", 2)]],
               ["walk", "summon", "whirl", "wave"]),
    "birdman": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "birdman_thrower": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "birdman_shaman": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "satyr": (lambda n: [walk(n), [frame(n, "dance", 1), frame(n, "dance", 3), frame(n, "attack", 1), frame(n, "attack", 3)]],
              ["walk", "dance", "attack"]),
    "satyr_piper": (lambda n: [walk(n), [frame(n, "dance", 1), frame(n, "dance", 3), frame(n, "attack", 1), frame(n, "attack", 3)]],
                    ["walk", "dance", "attack"]),
    "satyr_brute": (lambda n: [walk(n), [rot(n), rot(n), frame(n, "attack", 1), frame(n, "attack", 3)]], ["walk", "attack"]),
    "goat": (lambda n: [forest_sheets.anim(n, "run"), [frame(n, "eat", 1), frame(n, "eat", 2), rot(n), rot(n)]], ["run", "eat"]),
}


## Przejścia Wang Rozlewisk, Wietrznych Turni (i bruk placu osady) w assets/tiles.png za zestawami Goblińskiego Lasu
## (world.gd: SWAMP_WANG_ROW, ALPINE_WANG_ROW): nazwa zestawu -> pierwszy rząd.
WANG_ROWS = {"swamp_mud": 35, "swamp_shallow": 39, "swamp_deep": 43, "alpine_rock": 47, "alpine_gravel": 51,
             "cobble": 55}  # bruk placu w osadzie (world.COBBLE_WANG_ROW)


def tiles():
    folder = os.path.join(SRC, "wang")
    if not all(os.path.exists(os.path.join(folder, n + ".json")) for n in WANG_ROWS):
        return
    path = os.path.join(ROOT, "assets", "tiles.png")
    old = Image.open(path).convert("RGBA")
    end = (max(WANG_ROWS.values()) + 4) * 16
    sheet = Image.new("RGBA", (old.width, max(end, old.height)))
    sheet.paste(old.crop((0, 0, old.width, min(old.height, 35 * 16))), (0, 0))
    for name, row in WANG_ROWS.items():
        forest_sheets.paste_wang(sheet, folder, name, row)
    sheet.save(path)
    print("Kafelki rozlewisk i gór", sheet.size)


def _anim_frames(folder, prefix):
    """Klatki animacji obiektu PixelLab (folder animacji nazywa się od opisu - szukamy po początku)."""
    anims = os.path.join(SRC, folder, "animations")
    for name in sorted(os.listdir(anims)) if os.path.isdir(anims) else []:
        if name.startswith(prefix):
            sub = os.path.join(anims, name, "unknown")
            return [Image.open(os.path.join(sub, f)).convert("RGBA") for f in sorted(os.listdir(sub))]
    return []


def object_sheet(cells, out_path, columns=4, scale=0.75):
    """Arkusz z klatek obiektu (wszystkie na tym samym płótnie): zmniejszenie jak postacie i przycięcie
    do wspólnej sylwetki - położenie na płótnie zostaje (stworzenie nie skacze między klatkami)."""
    import hero_sheets
    # animacje bywają na większym płótnie niż obrót - wyrównujemy wszystkie do wspólnego, środkami
    canvas = max(max(c.width, c.height) for c in cells)
    padded = []
    for c in cells:
        p = Image.new("RGBA", (canvas, canvas))
        p.alpha_composite(c, ((canvas - c.width) // 2, (canvas - c.height) // 2))
        padded.append(p)
    cells = padded
    size = round(canvas * scale)
    small = [hero_sheets.shrink_image(c, size, size) for c in cells]
    box = None
    for img in small:
        b = img.getbbox()
        box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    # poziomo symetrycznie względem środka płótna (odbicie flip_h nie przesuwa stworzenia)
    half = max(size / 2 - box[0], box[2] - size / 2)
    left = int(size / 2 - half)
    box = (left, box[1], int(size / 2 + half + 0.999), box[3])
    w, h = box[2] - box[0], box[3] - box[1]
    rows = (len(small) + columns - 1) // columns
    sheet = Image.new("RGBA", (w * columns, h * rows))
    for k, img in enumerate(small):
        sheet.alpha_composite(img.crop(box), ((k % columns) * w, (k // columns) * h))
    sheet.save(out_path)
    return w, h


def objects(layout):
    # Gromoskrzydły (układ 4x3): 0-7 pełne uderzenie skrzydeł (skrzydła w górze, w dół pod tułów i z powrotem),
    # 8 spoczynek, 9 ładowanie burzy, 10 nurkowanie, 11 wrzask. Dawna animacja "flapping" prawie nie ruszała
    # skrzydłami, więc lot bierze klatki "powerful_full_wingbeat" (8 klatek).
    fly, dive, screech = (_anim_frames("storm_eagle_obj", p) for p in ("powerful_full_wingbeat", "folds", "spreads"))
    if fly and dive and screech:
        rot = Image.open(os.path.join(SRC, "storm_eagle_obj", "rotations", "unknown.png")).convert("RGBA")
        w, h = object_sheet(fly + [rot, screech[1], dive[2], screech[3]], os.path.join(OUT, "storm_eagle.png"))
        layout["storm_eagle"] = {"cell": [w, h], "offset_y": -(h / 2.0) + 4}
        print("storm_eagle", w, h)
    # orzeł krążący nad turniami: 4 klatki lotu (spoczynek na żerdzi zostaje dawny)
    eagle = _anim_frames("eagle_obj", "flapping")
    if eagle:
        print("eagle", object_sheet(eagle, os.path.join(ROOT, "assets", "mountains", "eagle_fly.png")))
    # ognik: 8 migoczących płomyków z paczki kandydatów
    folder = os.path.join(SRC, "wisp_pack")
    if os.path.exists(os.path.join(folder, "frame_59.png")):
        cells = [Image.open(os.path.join(folder, "frame_%d.png" % i)).convert("RGBA") for i in (0, 5, 6, 14, 24, 30, 45, 59)]
        w, h = object_sheet(cells, os.path.join(OUT, "wisp.png"), scale=0.5)
        layout["wisp"] = {"cell": [w, h], "offset_y": -16}
        print("wisp", w, h)


def main():
    tiles()
    forest_sheets.SRC = SRC
    forest_sheets.OUT = OUT
    layout_path = os.path.join(SRC, "layout.json")
    layout = json.load(open(layout_path)) if os.path.exists(layout_path) else {}
    for name, (rows, anims) in CREATURES.items():
        folder = os.path.join(SRC, name, "animations")
        if not all(os.path.isdir(os.path.join(folder, a)) for a in anims):
            continue
        layout[name] = forest_sheets.build(name, rows(name))
        print("Zapisano %s %s" % (name, layout[name]))
    objects(layout)
    json.dump(layout, open(layout_path, "w"), indent=1)


if __name__ == "__main__":
    main()
