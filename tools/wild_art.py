"""Grafiki dzikiej części lasu i drogi: wilk, nora, truchło jelenia, kości, skóra wilka
oraz wóz kupiecki z koniem. Wywoływane z generate_art.py."""
import math
import os

from generate_art import BARK, GRASS, OUT, OUTLINE_DARK, STONE, hexc, line, new, outline, put, rect, shadow_ellipse

WILD = os.path.join(OUT, "wild")
ITEMS = os.path.join(OUT, "items")
VILLAGE = os.path.join(OUT, "village")

FUR = hexc("6b6f7a")
FUR_D = hexc("4a4d57")
FUR_L = hexc("9aa0ad")
BELLY = hexc("c0c4cc")
EYE = hexc("f2d14c")
NOSE = hexc("1a1c2c")
BLOOD = hexc("8e1b2b")
BLOOD_L = hexc("c0392b")
BONE = hexc("e8e0c8")
DIRT = [hexc("3a2a1a"), hexc("5a4030"), hexc("7a5a40"), hexc("9a7a58")]


# ---------------------------------------------------------------- wilk (bokiem, patrzy w prawo, 24x16)
def wolf_frame(kind, f=0):
    """kind: run (f 0-3) / lie / eat (f 0-1) / crouch / bite."""
    img = new(24, 16)
    lie = kind == "lie"
    low = 1 if kind == "crouch" else 0
    bob = 1 if kind == "run" and f in (1, 3) else 0
    body_top = (9 if lie else 6) + low + bob
    shift = 2 if kind == "bite" else 0

    # nogi (dalsze ciemniejsze)
    if kind == "run":
        swing = {0: 0, 1: 2, 2: 0, 3: -2}[f]
        for x, dx, c in ((6, -swing, FUR_D), (16, swing, FUR_D), (7, swing, FUR), (17, -swing, FUR)):
            line(img, x, 12 + bob, x + dx, 15, c)
    elif lie:
        rect(img, 18, 14, 22, 14, FUR)  # przednie łapy wyciągnięte
        rect(img, 4, 14, 8, 14, FUR_D)
    else:
        bend = 1 if kind == "crouch" else 0
        for x, c in ((6, FUR_D), (8, FUR), (15, FUR_D), (17, FUR)):
            rect(img, x + shift, 12 + low, x + shift, 15, c)
            if bend:
                put(img, x + shift + 1, 13, c)

    # ogon
    if lie:
        for x, y in ((3, 13), (2, 12), (1, 12), (2, 13)):
            put(img, x, y, FUR)
    else:
        tail_y = body_top + (1 if kind in ("crouch", "eat") else 0)
        for i, (x, y) in enumerate(((4, 0), (3, -1), (2, -1), (1, 0), (2, 0))):
            put(img, x + shift, tail_y + y, FUR_D if i == 4 else FUR)

    # tułów
    for y in range(body_top, body_top + 6):
        for x in range(4 + shift, 19 + shift):
            t = (y - body_top) / 5
            dx = (x - (11 + shift)) / 7.5
            if dx * dx + ((t - 0.5) * 2) ** 2 * 0.6 > 1.15:
                continue
            c = FUR_L if t < 0.2 else FUR if t < 0.65 else BELLY if t < 0.9 else FUR_D
            put(img, x, y, c)
    rect(img, 6 + shift, body_top, 9 + shift, body_top, FUR_D)  # ciemny pas na grzbiecie

    # głowa
    if kind == "eat":
        hx, hy = 17, 8 + (1 if f else 0)  # łeb przy ziemi
    elif lie:
        hx, hy = 17, 8
    elif kind == "bite":
        hx, hy = 18 + shift - 2, 3 + low
    else:
        hx, hy = 17 + shift, 2 + low + bob
    rect(img, hx, hy + 2, hx + 4, hy + 6, FUR)
    rect(img, hx, hy + 2, hx + 4, hy + 2, FUR_L)
    put(img, hx + 1, hy + 1, FUR_D)  # uszy
    put(img, hx + 1, hy, FUR_D)
    put(img, hx + 3, hy + 1, FUR)
    put(img, hx + 3, hy, FUR)
    # pysk
    if kind == "bite":
        rect(img, hx + 5, hy + 3, hx + 7, hy + 3, FUR)
        rect(img, hx + 5, hy + 6, hx + 7, hy + 6, FUR)
        put(img, hx + 6, hy + 4, BONE)
        put(img, hx + 7, hy + 3, NOSE)
    else:
        rect(img, hx + 5, hy + 4, hx + 6, hy + 5, FUR)
        put(img, hx + 6, hy + 4, NOSE)
        put(img, hx + 5, hy + 6, BELLY)
    put(img, hx + 3, hy + 3, EYE if kind != "lie" else FUR_D)  # leżący mruży oczy
    if kind == "eat":
        put(img, hx + 6, hy + 6, BLOOD_L)
    outline(img, OUTLINE_DARK)
    return img


def make_wolf():
    sheet = new(24 * 4, 16 * 3)
    frames = [("run", 0), ("run", 1), ("run", 2), ("run", 3),
              ("lie", 0), ("eat", 0), ("eat", 1), ("run", 0),
              ("crouch", 0), ("bite", 0), ("crouch", 0), ("bite", 0)]
    for i, (kind, f) in enumerate(frames):
        sheet.paste(wolf_frame(kind, f), ((i % 4) * 24, (i // 4) * 16))
    sheet.save(os.path.join(WILD, "wolf.png"))


# ---------------------------------------------------------------- nora, truchło, kości
def make_den():
    img = new(44, 28)
    for y in range(28):
        for x in range(44):
            d = ((x + 0.5 - 22) / 21) ** 2 + ((y + 0.5 - 17) / 10) ** 2
            if d <= 1:
                v = -(x - 22) * 0.04 - (y - 17) * 0.12
                put(img, x, y, DIRT[3] if v > 0.6 else DIRT[2] if v > -0.3 else DIRT[1])
    for x, y in ((6, 15), (34, 14), (12, 22), (31, 22), (20, 9)):  # kamienie
        rect(img, x, y, x + 3, y + 2, STONE[1])
        rect(img, x, y, x + 3, y, STONE[2])
    for y in range(28):  # otwór nory
        for x in range(44):
            if ((x + 0.5 - 22) / 9) ** 2 + ((y + 0.5 - 18) / 6) ** 2 <= 1:
                put(img, x, y, hexc("120c08") if y > 15 else DIRT[0])
    for x, y, l in ((9, 24, 4), (30, 25, 5)):  # kości przy wejściu
        line(img, x, y, x + l, y - 1, BONE)
        put(img, x, y - 1, BONE)
        put(img, x + l, y - 2, BONE)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 22, 26, 20, 2)
    img.save(os.path.join(WILD, "wolf_den.png"))


def make_carcass():
    img = new(34, 18)
    hide, hide_d = hexc("8a5a34"), hexc("6b4226")
    for y in range(18):
        for x in range(34):
            if ((x + 0.5 - 15) / 11) ** 2 + ((y + 0.5 - 11) / 4.5) ** 2 <= 1:
                put(img, x, y, hide if y < 11 else hide_d)
    for x in range(10, 21, 2):  # odsłonięte żebra
        line(img, x, 8, x + 1, 13, BONE)
        put(img, x + 1, 10, BLOOD)
    rect(img, 11, 10, 19, 11, BLOOD_L)
    rect(img, 26, 8, 30, 12, hide)  # łeb
    put(img, 30, 11, NOSE)
    put(img, 28, 9, NOSE)
    for x0 in (27, 29):  # poroże
        line(img, x0, 7, x0 - 1, 2, BONE)
        put(img, x0 - 2, 4, BONE)
        put(img, x0, 3, BONE)
    for x, y, dx in ((6, 14, -4), (9, 15, -3), (21, 15, 3), (24, 14, 4)):  # nogi
        line(img, x, y, x + dx, y + 2, hide_d)
    for x, y in ((4, 16), (25, 16), (13, 16)):  # krew na ziemi
        rect(img, x, y, x + 3, y, BLOOD)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 16, 16, 15, 2)
    img.save(os.path.join(WILD, "deer_carcass.png"))


def make_bones():
    img = new(16 * 3, 10)
    for i in range(3):
        b = new(16, 10)
        if i == 0:
            line(b, 3, 6, 11, 4, BONE)
            put(b, 2, 5, BONE)
            put(b, 2, 7, BONE)
            put(b, 12, 3, BONE)
            put(b, 12, 5, BONE)
        elif i == 1:  # czaszka
            rect(b, 5, 3, 10, 7, BONE)
            put(b, 6, 5, NOSE)
            put(b, 9, 5, NOSE)
            rect(b, 6, 8, 9, 8, BONE)
        else:
            line(b, 2, 7, 6, 3, BONE)
            line(b, 8, 7, 13, 6, BONE)
        outline(b, OUTLINE_DARK)
        img.paste(b, (i * 16, 0))
    img.save(os.path.join(WILD, "bones.png"))


def make_pelt_icon():
    img = new(16, 16)
    for y in range(2, 15):
        half = 6 - abs(y - 8) // 2
        for x in range(8 - half, 8 + half):
            put(img, x, y, FUR if (x + y) % 4 else FUR_L)
    for x, y in ((2, 4), (13, 4), (2, 12), (13, 12)):  # łapy skóry
        rect(img, x, y, x + 1, y + 1, FUR_D)
    line(img, 8, 2, 8, 14, FUR_D)
    rect(img, 7, 1, 9, 2, FUR_D)
    outline(img, OUTLINE_DARK)
    img.save(os.path.join(ITEMS, "wolf_pelt.png"))


# ---------------------------------------------------------------- wóz kupiecki z koniem (2 klatki)
def wagon_frame(f):
    img = new(60, 32)
    wood, wood_d, wood_l = BARK[2], BARK[1], BARK[3]
    canvas, canvas_d = hexc("e0d0a8"), hexc("b8a47c")
    horse, horse_d = hexc("7a4a28"), hexc("5a3418")
    # koło tylne (dalsze) i przednie
    for cx in (9, 29):
        for y in range(32):
            for x in range(60):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - 25)
                if 3.5 <= d <= 5.2:
                    put(img, x, y, wood_d)
        a = f * math.pi / 4  # szprychy obracają się
        for k in range(4):
            ang = a + k * math.pi / 2
            line(img, cx, 25, round(cx + math.cos(ang) * 4), round(25 + math.sin(ang) * 4), wood)
    # skrzynia wozu
    rect(img, 2, 15, 35, 21, wood)
    rect(img, 2, 15, 35, 15, wood_l)
    rect(img, 2, 21, 35, 21, wood_d)
    for x in range(6, 35, 7):
        rect(img, x, 16, x, 20, wood_d)
    # plandeka z towarem
    for y in range(3, 15):
        for x in range(4, 34):
            if ((x + 0.5 - 19) / 15) ** 2 + ((y + 0.5 - 15) / 12) ** 2 <= 1:
                put(img, x, y, canvas if (x // 5) % 2 else canvas_d)
    rect(img, 5, 14, 33, 14, canvas_d)
    rect(img, 30, 11, 34, 15, hexc("a8743f"))  # skrzynka z tyłu plandeki
    # dyszel
    line(img, 35, 19, 44, 18, wood_d)
    # koń
    leg = 1 if f else -1
    rect(img, 42, 11, 53, 17, horse)
    rect(img, 42, 11, 53, 11, hexc("9a6a40"))
    for x, dx in ((43, leg), (45, -leg), (50, -leg), (52, leg)):
        line(img, x, 18, x + dx, 24, horse_d)
    rect(img, 52, 5, 55, 12, horse)  # szyja
    rect(img, 54, 4, 58, 8, horse)  # łeb
    put(img, 57, 5, NOSE)
    put(img, 55, 3, horse_d)  # ucho
    rect(img, 51, 5, 52, 11, hexc("2a1a10"))  # grzywa
    line(img, 41, 12, 39, 16, hexc("2a1a10"))  # ogon
    rect(img, 47, 10, 49, 11, hexc("b33a3a"))  # uprząż
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 30, 29, 28, 2.5)
    return img


def make_wagon():
    sheet = new(60 * 2, 32)
    for f in range(2):
        sheet.paste(wagon_frame(f), (f * 60, 0))
    sheet.save(os.path.join(VILLAGE, "wagon.png"))


def make_all():
    os.makedirs(WILD, exist_ok=True)
    make_wolf()
    make_den()
    make_carcass()
    make_bones()
    make_pelt_icon()
    make_wagon()
