"""Żaboludzie z rozlewisk: wojownik z oszczepem, plujący jadem, ich wódz, chaty w olbrzymich
namorzynach, stojaki z suszącymi się rybami, rozwieszone sieci, totemy, koksowniki, dłubanki,
gliniane dzbany, tron z muszli oraz łupy (żabi język, ryba). Wywoływane z generate_art.py.

Arkusze żaboludzi mają ten sam układ co goblin (4x2): 0-3 chód (podskoki), 4-5 przysiad
z nadymanym workiem rezonansowym, 6 zamach, 7 cios / splunięcie."""
import math
import os
import random

from generate_art import (BARK, LEAF, OUT, OUTLINE_DARK, OUTLINE_LEAF, STONE, hexc, line, new, outline, put, rect,
                          shaded_blob, shadow_ellipse)

FROGS = os.path.join(OUT, "frogs")
ITEMS = os.path.join(OUT, "items")
EYE = hexc("1a1c2c")


def ellipse(img, cx, cy, rx, ry, color, shade=None):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                put(img, x, y, shade if shade is not None and dy > 0.45 else color)


# ---------------------------------------------------------------- żaboludzie (20x20, bokiem, patrzą w prawo)
def frog_frame(kind, f, pal, weapon):
    img = new(20, 20)
    skin, skin_d, belly, spot = pal
    squat = kind == "squat"
    hop = {0: 0, 1: -1, 2: -2, 3: -1}[f] if kind == "walk" else 0
    base = 19
    # nogi: przysiad (żabie uda) albo krok
    if squat or kind in ("windup", "strike"):
        ellipse(img, 7, base - 3, 4, 2.5, skin_d)
        rect(img, 3, base - 1, 9, base - 1, skin_d)
    else:
        step = {0: 0, 1: 2, 2: 0, 3: -2}[f]
        rect(img, 7 - step, base - 5 + hop, 8 - step, base - 1, skin_d)
        rect(img, 10 + step, base - 5 + hop, 11 + step, base - 1, skin_d)
        rect(img, 6 - step, base - 1, 9 - step, base - 1, skin_d)
        rect(img, 9 + step, base - 1, 12 + step, base - 1, skin_d)
    body_y = (base - 8 if not squat else base - 6) + hop
    ellipse(img, 9, body_y, 5, 4.5, skin, skin_d)
    ellipse(img, 10, body_y + 1, 3, 3, belly)  # jasny brzuch
    rect(img, 5, body_y + 3, 12, body_y + 4, hexc("6b5236"))  # przepaska z trzciny
    for x in range(6, 12, 2):
        put(img, x, body_y + 5, hexc("8a7a4a"))
    # głowa: szeroki pysk i wyłupiaste oczy
    hy = body_y - 6
    ellipse(img, 11, hy + 2, 5, 3.2, skin)
    rect(img, 9, hy + 4, 16, hy + 4, skin_d)  # linia pyska
    for ex in (10, 14):
        ellipse(img, ex, hy - 0.5, 1.6, 1.6, skin)
        put(img, ex, hy - 1, hexc("f2d14c"))
        put(img, ex + 1, hy - 1, EYE)
    for sx, sy in ((7, body_y - 2), (10, body_y - 3), (6, body_y + 1)):
        put(img, sx, sy, spot)
    # worek rezonansowy pod pyskiem (przysiad: rechot)
    if kind == "squat" and f == 1 or kind == "windup" and weapon == "spit":
        ellipse(img, 14, hy + 5, 2.8, 2.4, hexc("e8d8a0"))
    # ręce i broń
    if weapon == "spear":
        wood, tip = BARK[2], hexc("e8e0c8")
        if kind == "windup":
            line(img, 2, hy + 2, 14, hy + 6, wood)
            rect(img, 1, hy + 1, 2, hy + 2, tip)
        elif kind == "strike":
            line(img, 6, body_y, 19, body_y - 1, wood)
            rect(img, 18, body_y - 2, 19, body_y - 1, tip)
        else:
            line(img, 14, hy - 4, 14, base - 2, wood)
            rect(img, 13, hy - 6, 15, hy - 5, tip)
            put(img, 14, hy - 7, tip)
        put(img, 13, body_y, skin_d)
    else:
        put(img, 13, body_y + 1, skin_d)
        if kind == "strike":  # splunięcie: otwarty pysk
            rect(img, 14, hy + 3, 17, hy + 5, hexc("8e2f25"))
            rect(img, 18, hy + 3, 19, hy + 4, hexc("7fdc4a"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 9, 19, 6, 1.2)
    return img


def make_frogmen():
    warrior = (hexc("4f8a3a"), hexc("355f28"), hexc("c8c070"), hexc("2a4a20"))
    spitter = (hexc("2f8a9a"), hexc("1f5e6a"), hexc("9ad0c8"), hexc("f08a2a"))
    for name, pal, weapon in (("frogman", warrior, "spear"), ("frog_spitter", spitter, "spit")):
        frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("squat", 0), ("squat", 1), ("windup", 0), ("strike", 0)]
        sheet = new(20 * 4, 20 * 2)
        for i, (kind, f) in enumerate(frames):
            sheet.paste(frog_frame(kind, f, pal, weapon), ((i % 4) * 20, (i // 4) * 20))
        sheet.save(os.path.join(FROGS, name + ".png"))


# ---------------------------------------------------------------- wódz żaboludzi (52x50)
def chief_frame(kind, f=0):
    img = new(52, 50)
    skin, skin_d, belly = hexc("5a7a2e"), hexc("3e5620"), hexc("d8cc80")
    base = 48
    lift = {"leap": 10}.get(kind, 0)
    waddle = {0: 0, 1: -2, 2: 0, 3: -2}[f] if kind == "walk" else 0
    by = base - 15 - lift + waddle
    # grube żabie nogi
    ellipse(img, 15, base - 6 - lift, 9, 6, skin_d)
    ellipse(img, 33, base - 6 - lift, 9, 6, skin_d)
    rect(img, 6, base - 1 - lift, 22, base - lift, skin_d)
    # wielkie, tłuste cielsko z brzuchem
    ellipse(img, 24, by, 17, 14, skin, skin_d)
    ellipse(img, 27, by + 3, 11, 9, belly)
    for sx, sy in ((14, by - 8), (20, by - 11), (11, by - 2), (30, by - 10)):
        ellipse(img, sx, sy, 1.6, 1.2, hexc("2f4a18"))
    # pas z muszli i sieci
    rect(img, 9, by + 7, 40, by + 8, hexc("6b5236"))
    for x in range(12, 40, 6):
        ellipse(img, x, by + 9, 1.5, 1.2, hexc("e8d8c8"))
    # łeb
    hy = by - 15
    mouth_open = kind in ("tongue_wind", "tongue")
    ellipse(img, 29, hy + 4, 13, 7, skin)
    if mouth_open:
        rect(img, 24, hy + 6, 42, hy + 10, hexc("6e231c"))
        rect(img, 26, hy + 7, 41, hy + 8, hexc("c0392b"))
    else:
        rect(img, 22, hy + 8, 41, hy + 8, skin_d)
    for ex in (23, 34):
        ellipse(img, ex, hy - 1, 3.2, 3.2, skin)
        ellipse(img, ex, hy - 1.5, 1.8, 1.8, hexc("f2d14c"))
        rect(img, ex, hy - 2, ex + 1, hy - 1, EYE)
    # korona z muszli i kości
    for k, x in enumerate(range(21, 38, 4)):
        rect(img, x, hy - 8 - (k % 2) * 2, x + 1, hy - 4, hexc("e8e0c8"))
    rect(img, 20, hy - 5, 38, hy - 4, hexc("e0a020"))
    # ręce: w zamachu na języku - napięte, w skoku - rozłożone
    if kind == "leap":
        line(img, 8, by - 4, 2, by - 12, skin_d)
        line(img, 40, by - 4, 47, by - 12, skin_d)
    else:
        line(img, 10, by, 7, by + 8, skin_d)
        line(img, 40, by, 44, by + 8, skin_d)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 25, base, 18, 2.5)
    return img


def make_chief():
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("tongue_wind", 0), ("tongue", 0), ("leap", 0)]
    sheet = new(52 * 4, 50 * 2)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(chief_frame(kind, f), ((i % 4) * 52, (i // 4) * 50))
    sheet.save(os.path.join(FROGS, "frog_chief.png"))


# ---------------------------------------------------------------- wioska
def make_hut_tree(seed):
    """Chata żaboludzi wbudowana w olbrzymi namorzyn: korzenie w wodzie, pień, chata z trzcinowym
    dachem na pomoście w koronie, drabinka."""
    rng = random.Random(seed)
    W, H = 76, 92
    img = new(W, H)
    base = H - 4
    roots = [hexc("4e3a26"), hexc("6b5236"), hexc("86683e")]
    for k in range(9):  # korzenie palczaste
        foot = 4 + k * 8 + rng.randrange(-2, 3)
        top_y = base - 22
        for i in range(13):
            t = i / 12
            x = round(38 + (foot - 38) * t)
            y = round(top_y + (base - top_y) * t - math.sin(math.pi * t) * 7)
            rect(img, x, y, x + 1, y + 1, roots[k % 2])
    rect(img, 33, base - 50, 43, base - 18, roots[1])  # gruby pień
    rect(img, 33, base - 50, 34, base - 18, roots[2])
    for y in range(base - 48, base - 18, 5):
        put(img, 37, y, roots[0])
    canopy = new(W, H)
    shaded_blob(canopy, [(38, 20, 22), (18, 26, 14), (58, 26, 14), (38, 30, 15)], [hexc("102c22")] + LEAF[1:], rng=rng, speckle=0.2)
    img.alpha_composite(canopy)
    # pomost i chata z trzcinowym dachem
    plank, plank_d, straw, straw_d = hexc("86603a"), hexc("5a3a20"), hexc("c8a45a"), hexc("8a6a2a")
    rect(img, 18, base - 48, 58, base - 45, plank)
    rect(img, 18, base - 45, 58, base - 45, plank_d)
    for x in (20, 56):
        rect(img, x, base - 45, x + 1, base - 30, plank_d)
    rect(img, 24, base - 62, 52, base - 48, hexc("9c7b52"))  # ściany z gliny i trzciny
    for x in range(25, 52, 3):
        rect(img, x, base - 62, x, base - 48, hexc("7a5a38"))
    rect(img, 35, base - 57, 40, base - 48, hexc("2a1a10"))  # wejście
    for y in range(13):  # dach stożkowy
        half = 3 + y * 1.4
        for x in range(int(38 - half), int(38 + half) + 1):
            put(img, x, base - 76 + y, straw if (x + y) % 3 else straw_d)
    rect(img, 37, base - 79, 38, base - 76, straw_d)
    for y in range(base - 44, base - 4, 3):  # drabinka
        rect(img, 46, y, 50, y, plank)
    rect(img, 46, base - 45, 46, base - 4, plank_d)
    rect(img, 50, base - 45, 50, base - 4, plank_d)
    rect(img, 26, base - 60, 29, base - 57, hexc("4e7a8a"))  # wisząca sieć z muszlami
    for _ in range(4):
        x = rng.randrange(20, 56)
        line(img, x, base - 44, x, base - 44 + rng.randrange(4, 10), LEAF[2])
    outline(img, OUTLINE_LEAF)
    for x in range(6, 70):
        if rng.random() < 0.4:
            put(img, x, base + 1, hexc("7aa898"))
    shadow_ellipse(img, 38, base + 1, 30, 3)
    return img


def make_village_props():
    plank, plank_d = hexc("86603a"), hexc("5a3a20")
    # stojak z suszącymi się rybami
    rack = new(32, 28)
    rect(rack, 2, 4, 3, 27, plank_d)
    rect(rack, 28, 4, 29, 27, plank_d)
    rect(rack, 0, 4, 31, 5, plank)
    rect(rack, 0, 13, 31, 14, plank)
    for row, y in enumerate((6, 15)):
        for x in range(5, 28, 5):
            line(rack, x, y, x, y + 1, hexc("8a7a4a"))
            ellipse(rack, x, y + 5, 1.6, 3.2, hexc("a3a7b5") if (x // 5 + row) % 2 else hexc("c89a64"))
            put(rack, x, y + 8, hexc("7d8192"))
    outline(rack, OUTLINE_DARK)
    shadow_ellipse(rack, 16, 27, 14, 1.2)
    rack.save(os.path.join(FROGS, "fish_rack.png"))

    # sieć rozwieszona między dwoma palami
    net = new(36, 30)
    rect(net, 2, 2, 3, 29, plank_d)
    rect(net, 32, 4, 33, 29, plank_d)
    for y in range(5, 24):
        sag = int(3 * math.sin(math.pi * (y - 5) / 18))
        for x in range(4, 32):
            if (x + y) % 4 == 0 or (x - y) % 4 == 0:
                put(net, x, y + sag // 2, hexc("b8a47c"))
    for x in (9, 17, 25):  # pływaki
        ellipse(net, x, 6, 1.4, 1.4, hexc("e67e22"))
    outline(net, OUTLINE_DARK)
    shadow_ellipse(net, 18, 29, 15, 1.2)
    net.save(os.path.join(FROGS, "fish_net.png"))

    # żabi totem
    totem = new(16, 34)
    rect(totem, 6, 10, 9, 33, plank_d)
    ellipse(totem, 8, 7, 6, 5, hexc("4f8a3a"))
    for ex in (5, 11):
        ellipse(totem, ex, 3, 2, 2, hexc("4f8a3a"))
        put(totem, ex, 3, hexc("f2d14c"))
    rect(totem, 4, 9, 12, 9, hexc("2a4a20"))
    for y in (14, 20, 26):
        rect(totem, 5, y, 10, y, hexc("e8e0c8"))
    outline(totem, OUTLINE_DARK)
    shadow_ellipse(totem, 8, 33, 5, 1)
    totem.save(os.path.join(FROGS, "frog_totem.png"))

    # koksownik na palach (2 klatki ognia)
    sheet = new(12 * 2, 24)
    for f in range(2):
        img = new(12, 24)
        line(img, 3, 23, 5, 12, plank_d)
        line(img, 8, 23, 6, 12, plank_d)
        rect(img, 1, 9, 10, 12, STONE[1])
        rect(img, 1, 9, 10, 9, STONE[2])
        flame = [(2, 6), (3, 8), (4, 5), (5, 7), (6, 6), (7, 8), (8, 5)] if f == 0 else [(2, 7), (3, 5), (4, 7), (5, 4), (6, 7), (7, 5), (8, 7)]
        for x, h in flame:
            for k in range(h):
                put(img, x + 1, 8 - k, hexc("fdf2a6") if k < 2 else hexc("7fdc4a") if k < h - 2 else hexc("2f8a3a"))
        outline(img, OUTLINE_DARK)
        sheet.paste(img, (f * 12, 0))
    sheet.save(os.path.join(FROGS, "brazier.png"))

    # dłubanka przy brzegu
    canoe = new(38, 12)
    for x in range(1, 37):
        half = 4 - abs(x - 19) / 6
        for y in range(int(6 - half), int(6 + half) + 1):
            put(canoe, x, y, plank if y < 6 else plank_d)
    rect(canoe, 5, 5, 32, 6, hexc("3a2215"))
    line(canoe, 14, 2, 26, 9, hexc("a07848"))  # wiosło
    outline(canoe, OUTLINE_DARK)
    canoe.save(os.path.join(FROGS, "canoe.png"))

    # gliniane dzbany
    pots = new(20, 14)
    for cx, h in ((5, 9), (12, 11), (16, 7)):
        ellipse(pots, cx, 13 - h / 2, 3.2, h / 2, hexc("a8564a"), hexc("7d3e36"))
        rect(pots, cx - 1, 13 - h, cx + 1, 13 - h, hexc("7d3e36"))
    outline(pots, OUTLINE_DARK)
    pots.save(os.path.join(FROGS, "clay_pots.png"))

    # tron z muszli
    throne = new(44, 40)
    ellipse(throne, 22, 20, 18, 17, hexc("e8d8c8"), hexc("c8b4a0"))
    for k in range(7):
        a = math.pi * (0.15 + 0.7 * k / 6)
        line(throne, 22, 34, round(22 - math.cos(a) * 17), round(34 - math.sin(a) * 30), hexc("b09880"))
    rect(throne, 10, 28, 34, 38, hexc("6b5236"))
    rect(throne, 10, 28, 34, 29, hexc("86683e"))
    ellipse(throne, 22, 31, 7, 2, hexc("4f8a3a"))  # siedzisko z liścia
    outline(throne, OUTLINE_DARK)
    shadow_ellipse(throne, 22, 39, 18, 1.5)
    throne.save(os.path.join(FROGS, "shell_throne.png"))

    # kładka (pomost) - deski wzdłuż, 16x16
    walk = new(16, 16)
    for y in range(16):
        for x in range(16):
            k = y % 4
            put(walk, x, y, plank_d if k == 3 else plank if k else hexc("a07848"))
    for y in (1, 9):
        put(walk, 2, y, plank_d)
        put(walk, 13, y, plank_d)
    walk.save(os.path.join(FROGS, "boardwalk.png"))


def make_items():
    tongue = new(16, 16)
    for i in range(12):
        x = 2 + i
        y = round(10 - math.sin(i / 11 * math.pi) * 5)
        rect(tongue, x, y, x, y + 2, hexc("d9607a"))
        put(tongue, x, y, hexc("f0a0b0"))
    ellipse(tongue, 13, 5, 2.4, 2.2, hexc("c0405a"))
    outline(tongue, OUTLINE_DARK)
    tongue.save(os.path.join(ITEMS, "frog_tongue.png"))

    fish = new(16, 16)
    for x in range(2, 13):
        for y in range(5, 12):
            if ((x - 7) / 5.2) ** 2 + ((y - 8.5) / 3.2) ** 2 <= 1:
                put(fish, x, y, hexc("a3a7b5") if y < 8 else hexc("7d8192"))
    for y in range(5, 12):
        put(fish, 13 + abs(y - 8) // 2, y, hexc("7d8192"))
    put(fish, 4, 7, EYE)
    line(fish, 6, 9, 10, 9, hexc("c9cfdc"))
    outline(fish, OUTLINE_DARK)
    fish.save(os.path.join(ITEMS, "fish.png"))


def make_all():
    os.makedirs(FROGS, exist_ok=True)
    make_frogmen()
    make_chief()
    for i in range(3):
        make_hut_tree(500 + i).save(os.path.join(FROGS, f"hut_tree_{i}.png"))
    make_village_props()
    make_items()
