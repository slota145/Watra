"""Topielcze Uroczysko - zamglony, martwy las nad czarną wodą w lewym dolnym rogu rozlewisk.
Martwe, poczerniałe drzewa z brodami mchu, zatopione krzyże, spróchniałe pnie, przewrócone
garnki, pod którymi Wodnik trzyma dusze topielców, zbutwiała łódź. Potwory: utopiec (z klatkami
zanurzenia i wynurzania), błędny ognik, topielica (rusałka) i ich pan - Wodnik w czerwonej
czapce, z fajką i brodą z wodorostów. Łupy: wodorosty, perła topieli, komplet legend Wodnika
i jego fajka (przedmiot przyzwania). Wywoływane z generate_art.py.

Arkusze postaci mają układ jak goblin (4x2): 0-3 chód, 4-5 spoczynek, 6 zamach, 7 cios;
utopiec ma zamiast spoczynku 4 - zanurzony (tylko głowa i fale), 5 - wynurzanie."""
import math
import os
import random

from generate_art import BARK, OUT, OUTLINE_DARK, hexc, line, new, outline, put, rect, shadow_ellipse

DROWNED = os.path.join(OUT, "drowned")
ITEMS = os.path.join(OUT, "items")
EYE_GLOW = hexc("b8ff6a")
SKIN = [hexc("3e5a4a"), hexc("5a7a62"), hexc("7a9a7e"), hexc("a8c0a0")]
WEED = [hexc("1e3a22"), hexc("2f5a30"), hexc("4a7a3a")]
DEAD_WOOD = [hexc("1e1a18"), hexc("2e2824"), hexc("443a32"), hexc("5e5246")]
WATER = [hexc("1a3a4a"), hexc("2f5f7a"), hexc("6ab0d0"), hexc("c8f0ff")]
GOLD = [hexc("8a5a10"), hexc("c8901c"), hexc("f2c94c"), hexc("fff3b0")]
SILVER = [hexc("5b5e70"), hexc("a3a7b5"), hexc("dfe4ee"), hexc("ffffff")]


def ellipse(img, cx, cy, rx, ry, color, shade=None):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                put(img, x, y, shade if shade is not None and dy > 0.45 else color)


def save(img, name, folder=DROWNED):
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name + ".png"))


def ripples(img, cx, cy, r):
    for a in range(0, 360, 12):
        x = cx + math.cos(math.radians(a)) * r
        y = cy + math.sin(math.radians(a)) * r * 0.4
        put(img, int(x), int(y), WATER[2] if a % 24 else WATER[3])


# ---------------------------------------------------------------- uroczysko
def drowned_tree(variant):
    """Martwe, poczerniałe drzewo z brodami mchu zwisającymi z gałęzi."""
    rng = random.Random(300 + variant)
    img = new(40, 56)
    for y in range(18, 55):
        sway = int(math.sin(y * 0.2 + variant * 2) * 2)
        w = 3 if y < 44 else 4 + (y - 44) // 3
        rect(img, 19 + sway - w // 2, y, 20 + sway + w // 2, y, DEAD_WOOD[1])
        put(img, 19 + sway - w // 2, y, DEAD_WOOD[3])
    branches = [(20, 22, 4, 12), (20, 26, 36, 14), (19, 32, 6, 24), (21, 18, 28, 4), (20, 20, 13, 3)]
    for (x0, y0, x1, y1) in branches:
        line(img, x0, y0, x1 + rng.randint(-1, 1), y1, DEAD_WOOD[2])
        line(img, x0, y0 + 1, x1, y1 + 1, DEAD_WOOD[0])
        for k in range(3):  # zwisający mech
            mx = x0 + (x1 - x0) * (k + 1) // 4
            my = y0 + (y1 - y0) * (k + 1) // 4 + 1
            for d in range(rng.randint(3, 7)):
                put(img, mx + (d % 2 if k % 2 else 0), my + d, WEED[1] if d % 3 else WEED[2])
    rect(img, 13, 54, 27, 55, DEAD_WOOD[0])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 20, 55, 11, 1.5)
    return img


def sunken_cross():
    img = new(16, 26)
    rect(img, 7, 3, 9, 24, DEAD_WOOD[2])
    rect(img, 2, 8, 14, 10, DEAD_WOOD[2])
    rect(img, 7, 3, 7, 24, DEAD_WOOD[3])
    for x, y in ((3, 11), (4, 12), (12, 11), (9, 15), (9, 16), (8, 20)):
        put(img, x, y, WEED[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 25, 5, 1)
    return img


def rotten_stump():
    img = new(22, 16)
    rect(img, 4, 5, 17, 14, DEAD_WOOD[1])
    rect(img, 4, 5, 17, 6, DEAD_WOOD[3])
    rect(img, 6, 6, 15, 6, DEAD_WOOD[0])
    for x in (2, 3, 18, 19):
        put(img, x, 14, DEAD_WOOD[1])
    for x, y in ((6, 8), (12, 10), (15, 7)):
        put(img, x, y, WEED[2])
        put(img, x + 1, y, hexc("c8b060"))  # grzyby
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 11, 15, 9, 1)
    return img


def soul_jars():
    """Przewrócone garnki - Wodnik trzyma pod nimi dusze topielców; z jednego wydobywa się bąbel."""
    img = new(30, 18)
    clay = [hexc("6e3a24"), hexc("8a4e30"), hexc("a8683e")]
    for cx, cy in ((7, 12), (16, 13), (24, 11)):
        ellipse(img, cx, cy, 5, 4, clay[1], clay[0])
        rect(img, cx - 3, cy - 5, cx + 2, cy - 4, clay[2])
        put(img, cx - 2, cy - 1, clay[2])
    for x, y in ((17, 6), (18, 4), (16, 3)):
        put(img, x, y, hexc("c8f0ff"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 15, 17, 13, 1)
    return img


def sunken_boat():
    img = new(44, 20)
    for y in range(6, 16):
        half = 20 - max(0, y - 10) * 2
        rect(img, 22 - half, y, 21 + half, y, DEAD_WOOD[2] if y < 9 else DEAD_WOOD[1])
    rect(img, 6, 8, 37, 9, DEAD_WOOD[0])
    for x in (10, 22, 32):
        rect(img, x, 6, x + 1, 12, DEAD_WOOD[3])
    rect(img, 26, 12, 34, 15, (0, 0, 0, 0))  # dziura w burcie
    line(img, 30, 3, 40, 12, DEAD_WOOD[3])  # wiosło
    for x, y in ((8, 14), (15, 15), (36, 13)):
        put(img, x, y, WEED[2])
    outline(img, OUTLINE_DARK)
    return img


# ---------------------------------------------------------------- utopiec (20x26)
def drowner_frame(kind, f):
    img = new(20, 26)
    base = 25
    if kind == "submerged":  # tylko czubek głowy, oczy i kręgi na wodzie
        ellipse(img, 10, base - 3, 4, 2, SKIN[1])
        put(img, 8, base - 4, EYE_GLOW)
        put(img, 12, base - 4, EYE_GLOW)
        for k in range(4):
            put(img, 6 + k * 2, base - 5, WEED[1])
        ripples(img, 10, base - 2, 7 + f)
        return img
    rise = {"emerge": 8}.get(kind, 0)
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if kind == "walk" else 0
    hunch = 1 if kind in ("walk", "idle") else 0
    by = base - 11
    if kind != "emerge":
        for lx, ph in ((8, step), (12, -step)):
            rect(img, lx + ph // 2, by + 5, lx + 1 + ph // 2, base - 1, SKIN[0])
    ellipse(img, 10, by + rise, 5, 6, SKIN[1], SKIN[0])
    ellipse(img, 11, by + 1 + rise, 2.5, 3.5, SKIN[2])
    rect(img, 5, by + 4 + rise, 15, by + 5 + rise, WEED[0])  # przepaska z wodorostów
    for x in range(6, 15, 2):
        put(img, x, by + 6 + rise, WEED[1])
    hy = by - 8 + hunch + rise
    ellipse(img, 11, hy + 2, 4, 3.6, SKIN[1])
    put(img, 12, hy + 1, EYE_GLOW)
    put(img, 14, hy + 1, EYE_GLOW)
    rect(img, 12, hy + 4, 14, hy + 4, hexc("1a1210"))
    for k in range(5):  # wodorosty zamiast włosów
        put(img, 8 + k, hy - 1, WEED[1 + k % 2])
        put(img, 7 + k // 2, hy + k, WEED[0])
    # długie ręce ze szponami
    if kind == "windup":
        line(img, 6, by - 2 + rise, 3, by - 9 + rise, SKIN[1])
        line(img, 14, by - 2 + rise, 17, by - 9 + rise, SKIN[1])
    elif kind == "strike":
        line(img, 14, by + rise, 19, by - 1 + rise, SKIN[1])
        line(img, 13, by + 2 + rise, 19, by + 2 + rise, SKIN[1])
        put(img, 19, by - 2 + rise, SKIN[3])
    else:
        line(img, 6, by - 1 + rise, 5, by + 7 + rise, SKIN[1])
        line(img, 15, by - 1 + rise, 16, by + 7 + rise, SKIN[1])
    if kind == "emerge":
        for y in range(base - 6, base):  # dolna część jeszcze pod wodą
            for x in range(3, 18):
                if img.getpixel((x, y))[3]:
                    put(img, x, y, WATER[1])
        ripples(img, 10, base - 4, 8)
    outline(img, OUTLINE_DARK)
    if kind != "emerge":
        shadow_ellipse(img, 10, 25, 6, 1.2)
    return img


def make_drowner():
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("submerged", 0), ("emerge", 0), ("windup", 0), ("strike", 0)]
    sheet = new(20 * 4, 26 * 2)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(drowner_frame(kind, f), ((i % 4) * 20, (i // 4) * 26))
    save(sheet, "drowner")


# ---------------------------------------------------------------- błędny ognik (14x14, 8 klatek pulsowania)
def make_wisp():
    sheet = new(14 * 4, 14 * 2)
    for i in range(8):
        img = new(14, 14)
        r = 4.5 + math.sin(i / 8 * math.tau) * 1.2
        for y in range(14):
            for x in range(14):
                d = math.hypot(x + 0.5 - 7, y + 0.5 - 7)
                if d < r:
                    t = d / r
                    c = (int(200 + 55 * (1 - t)), 255, int(140 + 100 * (1 - t)), 255)
                    put(img, x, y, c)
                elif d < r + 2.2:
                    put(img, x, y, (120, 255, 140, int(120 * (1 - (d - r) / 2.2))))
        put(img, 6, 5, (255, 255, 255, 255))
        sheet.paste(img, ((i % 4) * 14, (i // 4) * 14))
    save(sheet, "wisp")


# ---------------------------------------------------------------- topielica (22x30)
def rusalka_frame(kind, f):
    img = new(22, 30)
    skin = [hexc("b8c8c0"), hexc("d8e4dc")]
    dress = [hexc("8a9a9a"), hexc("c8d4d0"), hexc("eef4f0")]
    hair = [hexc("1e4a30"), hexc("2f6a40"), hexc("4a8a50")]
    base = 29
    float_y = {0: 0, 1: -1, 2: -2, 3: -1}[f] if kind in ("walk", "idle") else -1
    # długa, postrzępiona suknia (bez stóp - unosi się)
    for y in range(base - 14 + float_y, base - 1 + float_y):
        half = 3 + (y - (base - 14 + float_y)) // 3
        rect(img, 11 - half, y, 10 + half, y, dress[1] if y % 3 else dress[0])
    for x in range(5, 17, 2):
        put(img, x, base - 1 + float_y, dress[0])
    rect(img, 8, base - 16 + float_y, 13, base - 14 + float_y, dress[2])
    hy = base - 21 + float_y
    ellipse(img, 11, hy + 2, 3.4, 3.4, skin[1])
    put(img, 10, hy + 2, hexc("1a3a4a"))
    put(img, 12, hy + 2, hexc("1a3a4a"))
    for k in range(9):  # długie zielone włosy do pasa
        put(img, 7 - (k > 5), hy + k, hair[1])
        put(img, 15 + (k > 5), hy + k, hair[1])
        put(img, 8, hy + k, hair[0])
        put(img, 14, hy + k, hair[0])
    rect(img, 8, hy - 1, 14, hy, hair[2])
    put(img, 10, hy - 2, hexc("e8e0ff"))  # wianek
    put(img, 12, hy - 2, hexc("f2c94c"))
    if kind in ("windup", "strike"):  # uniesione ręce - śpiew / czar
        line(img, 8, hy + 6, 4, hy - 1, skin[0])
        line(img, 14, hy + 6, 18, hy - 1, skin[0])
        if kind == "strike":
            for x, y in ((3, hy - 3), (19, hy - 3), (2, hy - 5)):
                put(img, x, y, WATER[3])
    else:
        line(img, 8, hy + 6, 7, hy + 11, skin[0])
        line(img, 14, hy + 6, 15, hy + 11, skin[0])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 11, 29, 5, 1.1)
    return img


def make_rusalka():
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("idle", 2), ("windup", 0), ("strike", 0)]
    sheet = new(22 * 4, 30 * 2)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(rusalka_frame(kind, f), ((i % 4) * 22, (i // 4) * 30))
    save(sheet, "rusalka")


# ---------------------------------------------------------------- Wodnik (60x58)
def wodnik_frame(kind, f=0):
    img = new(60, 58)
    skin = [hexc("2e5a46"), hexc("4a7a5e"), hexc("6a9a78")]
    coat = [hexc("1e2a3a"), hexc("2f405a"), hexc("44587a")]
    cap = [hexc("7a1414"), hexc("b02020"), hexc("e04a3a")]
    base = 56
    waddle = {0: 0, 1: -1, 2: 0, 3: -1}[f] if kind == "walk" else 0
    step = {0: 0, 1: 3, 2: 0, 3: -3}[f] if kind == "walk" else 0
    by = base - 20 + waddle
    for lx, ph in ((22, step), (32, -step)):  # krótkie nogi z płetwami
        rect(img, lx + ph // 2, by + 10, lx + 4 + ph // 2, base - 2, coat[0])
        rect(img, lx - 2 + ph // 2, base - 2, lx + 6 + ph // 2, base - 1, skin[0])
    ellipse(img, 29, by, 14, 13, coat[1], coat[0])  # pękaty surdut
    for y in range(by - 10, by + 12, 4):
        put(img, 29, y, GOLD[2])
    for k in range(6):  # ociekająca woda z surduta
        put(img, 17 + k * 5, by + 12 + (k % 2), WATER[2])
    hy = by - 17
    ellipse(img, 30, hy + 4, 9, 8, skin[1])
    ellipse(img, 33, hy + 5, 3, 2, skin[2])  # nos
    for ex in (27, 34):
        rect(img, ex, hy + 2, ex + 1, hy + 3, EYE_GLOW)
    # broda z wodorostów do pasa
    for k in range(13):
        x = 22 + k + (1 if k % 3 == 0 else 0)
        length = 8 + (6 - abs(k - 6)) * 2
        for d in range(length):
            put(img, x, hy + 9 + d, WEED[1 + (k + d // 3) % 2])
    # czerwona czapka z ociekającym czubkiem
    for y in range(hy - 9, hy - 1):
        half = 9 - (hy - 2 - y) // 2
        rect(img, 30 - half, y, 29 + half, y, cap[1])
    rect(img, 21, hy - 2, 39, hy - 1, cap[0])
    rect(img, 23, hy - 8, 26, hy - 7, cap[2])
    put(img, 36, hy - 10, cap[1])
    put(img, 38, hy - 11, cap[1])
    put(img, 39, hy - 9, WATER[3])
    # fajka
    if kind not in ("summon", "whirl"):
        line(img, 36, hy + 8, 44, hy + 6, DEAD_WOOD[3])
        rect(img, 43, hy + 3, 45, hy + 6, DEAD_WOOD[2])
        put(img, 44, hy + 1, hexc("c8d0d8"))
        put(img, 45, hy - 1, hexc("a8b0b8"))
    # ręce
    if kind == "summon":
        line(img, 17, by - 2, 9, by - 16, skin[1])
        line(img, 41, by - 2, 49, by - 16, skin[1])
        for x, y in ((8, by - 18), (50, by - 18), (7, by - 20)):
            put(img, x, y, WATER[3])
    elif kind == "whirl":
        line(img, 17, by, 5, by - 2, skin[1])
        line(img, 41, by, 54, by + 2, skin[1])
        ripples(img, 29, base - 3, 24)
    elif kind == "slam":
        line(img, 40, by, 54, by + 8, skin[1])
        rect(img, 52, by + 6, 57, by + 10, WATER[2])
    else:
        line(img, 17, by - 2, 13, by + 8, skin[1])
        line(img, 41, by - 2, 45, by + 8, skin[1])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 29, base, 17, 2.5)
    return img


def make_wodnik():
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("summon", 0), ("whirl", 0), ("slam", 0)]
    sheet = new(60 * 4, 58 * 2)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(wodnik_frame(kind, f), ((i % 4) * 60, (i // 4) * 58))
    save(sheet, "wodnik")


# ---------------------------------------------------------------- przedmioty
def glow(img, color, strength=150):
    for y in range(16):
        for x in range(16):
            if img.getpixel((x, y))[3]:
                continue
            if any(0 <= x + dx < 16 and 0 <= y + dy < 16 and img.getpixel((x + dx, y + dy))[3] == 255
                   for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                put(img, x, y, (*color[:3], strength))


def items():
    algae = new(16, 16)
    for k in range(5):
        x = 4 + k * 2
        for y in range(3, 14):
            put(algae, x + int(math.sin(y * 0.7 + k) * 1.2), y, WEED[1 + (y + k) % 2])
    outline(algae, OUTLINE_DARK)
    save(algae, "drowned_algae", ITEMS)

    pearl = new(16, 16)
    ellipse(pearl, 8, 9, 5, 5, hexc("c8d8e0"), hexc("8aa0b0"))
    ellipse(pearl, 7, 7, 2, 2, hexc("ffffff"))
    put(pearl, 10, 11, hexc("b8ff6a"))  # zielonkawy blask duszy
    outline(pearl, OUTLINE_DARK)
    save(pearl, "drowned_pearl", ITEMS)

    # Pierścień Topieli: ciemne srebro z wirem i zielonym okiem
    ring = new(16, 16)
    for y in range(16):
        for x in range(16):
            d = math.hypot((x + 0.5 - 8) / 1.0, (y + 0.5 - 10) / 0.85)
            if 3.4 <= d <= 5.6:
                put(ring, x, y, SILVER[2] if (x - 8) + (y - 10) < -2 else SILVER[1] if d < 4.6 else SILVER[0])
    rect(ring, 5, 2, 10, 6, WATER[0])
    for a in range(0, 360, 30):  # wir w oprawie
        r = 1 + a / 180
        put(ring, int(8 + math.cos(math.radians(a)) * r), int(4 + math.sin(math.radians(a)) * r * 0.8), WATER[2])
    put(ring, 8, 4, EYE_GLOW)
    outline(ring, OUTLINE_DARK)
    glow(ring, hexc("ff9a30"))
    save(ring, "ring_wodnik", ITEMS)

    # Perła Wodnika: złote kółko z wielką, mętną perłą
    ear = new(16, 16)
    for t in range(9):
        a = math.pi * (0.15 + t / 8 * 1.3)
        put(ear, int(round(8 + math.cos(a) * 3)), int(round(3.5 - math.sin(a) * 3)), GOLD[2])
    rect(ear, 8, 4, 8, 6, GOLD[1])
    ellipse(ear, 8, 11, 4, 4, hexc("c8d8e0"), hexc("8aa0b0"))
    put(ear, 7, 9, hexc("ffffff"))
    put(ear, 10, 12, EYE_GLOW)
    for k in range(3):  # wodorosty owinięte wokół
        put(ear, 5 + k * 3, 8 + k % 2, WEED[2])
    outline(ear, OUTLINE_DARK)
    glow(ear, hexc("ffa040"))
    save(ear, "earring_wodnik", ITEMS)

    # Fajka Wodnika - przedmiot przyzwania
    pipe = new(16, 16)
    line(pipe, 2, 11, 10, 9, DEAD_WOOD[3])
    line(pipe, 2, 12, 10, 10, DEAD_WOOD[1])
    rect(pipe, 10, 6, 13, 11, DEAD_WOOD[2])
    rect(pipe, 10, 6, 13, 6, DEAD_WOOD[3])
    for x, y in ((11, 4), (12, 2), (11, 1), (13, 3)):
        put(pipe, x, y, WATER[2])
    for x, y in ((4, 13), (6, 14), (8, 13)):
        put(pipe, x, y, WEED[2])
    outline(pipe, OUTLINE_DARK)
    glow(pipe, hexc("b060ff"), 120)
    save(pipe, "summon_wodnik", ITEMS)


def make_all():
    os.makedirs(DROWNED, exist_ok=True)
    for v in range(2):
        save(drowned_tree(v), "drowned_tree_%d" % v)
    save(sunken_cross(), "sunken_cross")
    save(rotten_stump(), "rotten_stump")
    save(soul_jars(), "soul_jars")
    save(sunken_boat(), "sunken_boat")
    make_drowner()
    make_wisp()
    make_rusalka()
    make_wodnik()
    items()
