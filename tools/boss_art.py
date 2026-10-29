"""Bossowie: Wódz goblinów (z ogromną maczugą) i Wilk Alfa, oraz wystrój ich leży
(kościany tron, totemy z czaszkami). Rysowani w pełnej rozdzielczości, bez skalowania,
żeby pasowali pikselami do reszty gry. Wywoływane z generate_art.py."""
import math
import os
import random

from generate_art import BARK, OUTLINE_DARK, STONE, hexc, line, new, outline, put, rect, shadow_ellipse

BOSS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "bosses")

BONE = hexc("e8e0c8")
BONE_D = hexc("b8ac90")
FEATHER = hexc("c0392b")
FEATHER_D = hexc("8e1b2b")
GOLD = hexc("f2c94c")


def ellipse(img, cx, cy, rx, ry, color_fn):
    """Wypełnia elipsę; color_fn(nx, ny) dostaje znormalizowane współrzędne (-1..1)."""
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if nx * nx + ny * ny <= 1.0:
                c = color_fn(nx, ny)
                if c is not None:
                    put(img, x, y, c)


def shade(light, mid, dark):
    """Cieniowanie ze światłem z lewej góry."""
    return lambda nx, ny: light if (nx + ny) < -0.6 else mid if (nx + ny) < 0.5 else dark


# ---------------------------------------------------------------- Wódz goblinów (48x48, patrzy w prawo)
SKIN = (hexc("8cc26a"), hexc("6aa84f"), hexc("4a7a35"))
FUR = (hexc("8a6a48"), hexc("6b4e32"), hexc("4a3420"))
LEATHER = (hexc("7a5230"), hexc("5a3a20"))


def club(img, hx, hy, ex, ey):
    """Maczuga z kolcami: rękojeść od dłoni (hx, hy) do głowicy (ex, ey)."""
    line(img, hx, hy, ex, ey, BARK[1])
    line(img, hx + 1, hy, ex + 1, ey, BARK[2])
    ellipse(img, ex, ey, 5.5, 5.5, shade(BARK[3], BARK[2], BARK[1]))
    for a in range(0, 360, 60):
        r = math.radians(a)
        put(img, round(ex + math.cos(r) * 6.5), round(ey + math.sin(r) * 6.5), STONE[3])


def chief_frame(kind, f=0):
    img = new(48, 48)
    bob = 1 if kind == "walk" and f in (1, 3) else 0
    lean = 3 if kind == "charge" else 0
    crouch = 2 if kind == "slam" else 0
    oy = bob + crouch

    # nogi
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if kind == "walk" else (3 if kind == "charge" else 0)
    for x, dx in ((15, -step), (25, step)):
        rect(img, x + dx, 37 + oy, x + dx + 4, 44, SKIN[2])
        rect(img, x + dx - 1, 44, x + dx + 5, 46, LEATHER[1])

    # futrzana peleryna za plecami
    ellipse(img, 13 + lean, 27 + oy, 7, 12, shade(*FUR))
    for y in range(17, 40, 3):
        put(img, 6 + lean + (y % 2), y + oy, FUR[1])

    # tułów
    ellipse(img, 22 + lean, 29 + oy, 11, 10, shade(*SKIN))
    ellipse(img, 24 + lean, 32 + oy, 6, 5, lambda nx, ny: SKIN[0] if ny < 0 else None)
    line(img, 13 + lean, 21 + oy, 31 + lean, 37 + oy, LEATHER[1])  # pas przez pierś
    line(img, 14 + lean, 21 + oy, 32 + lean, 37 + oy, LEATHER[0])
    rect(img, 12 + lean, 36 + oy, 33 + lean, 38 + oy, LEATHER[1])  # pas
    for x in (17, 23, 29):  # czaszki przy pasie
        rect(img, x + lean, 36 + oy, x + 2 + lean, 38 + oy, BONE)
        put(img, x + 1 + lean, 37 + oy, OUTLINE_DARK)

    # głowa z długimi uszami
    hx, hy = 25 + lean, 14 + oy
    for side in (-1, 1):
        for i in range(9):
            put(img, hx + side * (8 + i), hy - 1 - i // 3, SKIN[1])
            put(img, hx + side * (8 + i), hy - i // 3, SKIN[2])
    ellipse(img, hx, hy, 9, 8, shade(*SKIN))
    rect(img, hx - 6, hy - 3, hx + 6, hy - 2, SKIN[2])  # zmarszczone brwi
    for ex in (hx - 4, hx + 3):
        rect(img, ex, hy - 1, ex + 1, hy, hexc("ffde5a"))
    rect(img, hx - 5, hy + 4, hx + 5, hy + 5, OUTLINE_DARK)  # paszcza
    for tx in (hx - 4, hx + 4):  # kły
        rect(img, tx, hy + 2, tx, hy + 4, BONE)
    # korona z kości i czerwonych piór
    for i, x in enumerate(range(hx - 7, hx + 8, 3)):
        h = 5 if i % 2 else 3
        rect(img, x, hy - 8 - h, x + 1, hy - 7, BONE if i % 2 else BONE_D)
    for x, h in ((hx - 9, 7), (hx + 8, 8), (hx - 1, 10)):
        line(img, x, hy - 7, x - 2, hy - 7 - h, FEATHER)
        line(img, x + 1, hy - 7, x - 1, hy - 7 - h, FEATHER_D)

    # ręka z maczugą
    if kind in ("walk", "idle"):
        rect(img, 31 + lean, 25 + oy, 34 + lean, 31 + oy, SKIN[1])
        club(img, 34, 31 + oy, 41, 39)
    elif kind == "windup":  # maczuga wysoko w górze
        rect(img, 29, 9, 32, 22, SKIN[1])
        club(img, 31, 10, 37, 4)
    elif kind == "slam":  # uderzenie o ziemię
        rect(img, 31, 27 + oy, 35, 33 + oy, SKIN[1])
        club(img, 35, 33 + oy, 41, 40)
        for x, y in ((35, 46), (46, 45), (38, 47), (44, 47)):
            put(img, x, y, hexc("9a7a58"))
    else:  # charge - maczuga wysunięta przed siebie
        rect(img, 33, 25, 37, 29, SKIN[1])
        club(img, 37, 27, 42, 23)

    outline(img, OUTLINE_DARK)
    return img


def make_chief():
    sheet = new(48 * 4, 48 * 2)
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("windup", 0), ("slam", 0), ("charge", 0)]
    for i, (kind, f) in enumerate(frames):
        sheet.paste(chief_frame(kind, f), ((i % 4) * 48, (i // 4) * 48))
    sheet.save(os.path.join(BOSS, "goblin_chief.png"))


# ---------------------------------------------------------------- Wilk Alfa (56x36, patrzy w prawo)
A_FUR = (hexc("5a5e6a"), hexc("3a3d46"), hexc("26282f"))
A_MANE = (hexc("8a8e9a"), hexc("6a6e7a"), hexc("4a4e5a"))
RED_EYE = hexc("ff3030")
RED_GLOW = (255, 120, 110, 160)


def alpha_frame(kind, f=0):
    img = new(56, 36)
    rng = random.Random(7)
    bob = 1 if kind == "run" and f in (1, 3) else 0
    crouch = 3 if kind == "crouch" else 0
    leap = kind == "leap"
    oy = bob + crouch - (2 if leap else 0)

    # nogi
    if kind == "run":
        sw = {0: 0, 1: 4, 2: 0, 3: -4}[f]
        legs = ((14, -sw), (19, sw), (38, sw), (42, -sw))
    elif leap:
        legs = ((10, -6), (15, -5), (42, 6), (46, 5))
    else:
        legs = ((14, 0), (19, 0), (38, 0), (42, 0))
    for i, (x, dx) in enumerate(legs):
        c = A_FUR[2] if i % 2 == 0 else A_FUR[1]
        top = 22 + oy
        bottom = 34 if not leap else 30
        if kind == "cleave" and i == 3:  # uniesiona łapa z pazurami
            line(img, x, top, x + 7, top - 4, c)
            line(img, x + 1, top, x + 8, top - 4, c)
            for k in range(3):
                put(img, x + 9, top - 6 + k * 2, BONE)
            continue
        for w in range(3):
            line(img, x + w, top, x + dx + w, bottom - (crouch // 2), c)
        rect(img, x + dx, bottom - (crouch // 2), x + dx + 3, bottom - (crouch // 2), A_FUR[2])

    # ogon
    for t in range(14):
        a = math.pi * (0.9 + t * 0.03)
        x = round(11 + math.cos(a) * t * 0.8)
        y = round(17 + oy - t * 0.45 + (3 if crouch else 0))
        for w in range(3 - t // 6):
            put(img, x, y + w, A_FUR[1] if w else A_FUR[0])

    # tułów
    ellipse(img, 27, 19 + oy, 17, 8, lambda nx, ny: A_FUR[0] if ny < -0.45 else A_FUR[1] if ny < 0.55 else A_MANE[2])
    for x0, y0 in ((20, 17), (24, 19), (28, 16)):  # blizny
        line(img, x0, y0 + oy, x0 + 4, y0 - 2 + oy, A_MANE[1])

    # grzywa wokół karku
    hx = 46 if kind != "cleave" else 48
    ellipse(img, 37, 14 + oy, 8, 10, lambda nx, ny: A_MANE[0] if nx + ny < -0.5 else A_MANE[1] if nx + ny < 0.6 else A_MANE[2])
    for i in range(10):  # postrzępiony brzeg
        a = math.pi * (0.6 + i * 0.14)
        put(img, round(37 + math.cos(a) * 9.5), round(14 + oy + math.sin(a) * 10.5), A_MANE[1])

    # głowa
    hy = 12 + oy + (4 if crouch else 0) + (2 if kind == "cleave" else 0)
    ellipse(img, hx, hy, 6, 5, shade(*A_FUR))
    for ex in (hx - 3, hx + 1):  # uszy
        line(img, ex, hy - 4, ex + 1, hy - 8, A_FUR[1])
        line(img, ex + 1, hy - 4, ex + 2, hy - 8, A_FUR[0])
    if kind == "cleave":  # otwarta paszcza z kłami
        rect(img, hx + 4, hy - 1, hx + 9, hy, A_FUR[1])
        rect(img, hx + 4, hy + 3, hx + 9, hy + 4, A_FUR[1])
        rect(img, hx + 5, hy + 1, hx + 9, hy + 2, hexc("5a1010"))
        for tx in (hx + 5, hx + 7, hx + 9):
            put(img, tx, hy + 1, BONE)
            put(img, tx, hy + 2 if tx == hx + 7 else hy + 1, BONE)
        put(img, hx + 9, hy - 1, OUTLINE_DARK)
    else:
        rect(img, hx + 4, hy, hx + 9, hy + 3, A_FUR[1])
        rect(img, hx + 4, hy, hx + 9, hy, A_FUR[0])
        put(img, hx + 9, hy, OUTLINE_DARK)
        put(img, hx + 7, hy + 3, BONE)  # wystający kieł
    rect(img, hx + 1, hy - 2, hx + 2, hy - 1, RED_EYE)

    outline(img, OUTLINE_DARK)
    # czerwona poświata oczu nad obrysem
    for dx, dy in ((0, -3), (3, -2), (-1, -2), (3, -1)):
        x, y = hx + 1 + dx, hy + dy
        if 0 <= x < 56 and 0 <= y < 36 and img.getpixel((x, y))[3] == 0:
            img.putpixel((x, y), RED_GLOW)
    return img


def make_alpha():
    sheet = new(56 * 4, 36 * 2)
    frames = [("run", 0), ("run", 1), ("run", 2), ("run", 3), ("idle", 0), ("crouch", 0), ("leap", 0), ("cleave", 0)]
    for i, (kind, f) in enumerate(frames):
        sheet.paste(alpha_frame(kind, f), ((i % 4) * 56, (i // 4) * 36))
    sheet.save(os.path.join(BOSS, "alpha_wolf.png"))


# ---------------------------------------------------------------- wystrój leży
def make_lair_props():
    throne = new(36, 40)
    rect(throne, 6, 8, 29, 36, BARK[1])  # oparcie
    rect(throne, 6, 8, 29, 9, BARK[2])
    rect(throne, 3, 24, 32, 36, BARK[2])  # siedzisko
    rect(throne, 3, 24, 32, 25, BARK[3])
    for x in (4, 11, 18, 25):  # czaszki na oparciu i nogach
        rect(throne, x + 2, 2 + (x % 3), x + 6, 6 + (x % 3), BONE)
        put(throne, x + 3, 4 + (x % 3), OUTLINE_DARK)
        put(throne, x + 5, 4 + (x % 3), OUTLINE_DARK)
    for x in (3, 30):
        rect(throne, x, 30, x + 2, 39, BONE_D)
    rect(throne, 12, 26, 23, 31, FEATHER_D)  # futro na siedzisku
    outline(throne, OUTLINE_DARK)
    shadow_ellipse(throne, 18, 38, 16, 2)
    throne.save(os.path.join(BOSS, "bone_throne.png"))

    totem = new(14, 32)
    rect(totem, 6, 10, 7, 30, BARK[2])
    rect(totem, 3, 3, 10, 9, BONE)  # czaszka na palu
    put(totem, 5, 6, OUTLINE_DARK)
    put(totem, 8, 6, OUTLINE_DARK)
    rect(totem, 5, 9, 8, 10, BONE_D)
    line(totem, 2, 12, 0, 18, FEATHER)
    line(totem, 11, 12, 13, 17, FEATHER)
    outline(totem, OUTLINE_DARK)
    totem.save(os.path.join(BOSS, "skull_totem.png"))


def make_all():
    os.makedirs(BOSS, exist_ok=True)
    make_chief()
    make_alpha()
    make_lair_props()
