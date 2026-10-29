"""Grafiki rozlewisk: kafelki wody i błota, most z poręczami, pałki wodne, namorzyny
na palczastych korzeniach, lilie wodne, trzcina, drogowskaz, ikona kapliczki na mapę
oraz dzikie życie przy wodzie: kaczki, żuraw, ważki i ryby.
Wywoływane z generate_art.py (kafelki trafiają do tiles.png przez make_tiles)."""
import math
import os
import random

from generate_art import (BARK, LEAF, OUT, OUTLINE_DARK, OUTLINE_LEAF, STONE, hexc, line, new, outline, put, rect,
                          shaded_blob, shadow_ellipse)

UI = os.path.join(OUT, "ui")
SWAMP = os.path.join(OUT, "swamp")

DEEP = [hexc("1d3a5c"), hexc("24476e"), hexc("2c5684"), hexc("4a7aa8")]
SHALLOW = [hexc("2f5a52"), hexc("3a6a5e"), hexc("4a7c6a"), hexc("7aa898")]
MUD = [hexc("3a2c1c"), hexc("4a3a26"), hexc("5a4a32"), hexc("6e5c40")]
PLANK = [hexc("6b4a2c"), hexc("86603a"), hexc("a07848"), hexc("4e3420")]


# ---------------------------------------------------------------- kafelki
def water_tiles(rng):
    tiles = []
    for v in range(2):  # głęboka woda rzeki: ciemna, z jasnymi zmarszczkami
        img = new(16, 16)
        for y in range(16):
            for x in range(16):
                r = rng.random()
                img.putpixel((x, y), DEEP[1] if r < 0.55 else DEEP[0] if r < 0.8 else DEEP[2])
        for _ in range(2 + v):
            x, y = rng.randrange(1, 12), rng.randrange(2, 15)
            rect(img, x, y, x + rng.randrange(2, 4), y, DEEP[3])
        tiles.append(img)
    for v in range(2):  # płycizna: mętna, zielonkawa, prześwitujące dno
        img = new(16, 16)
        for y in range(16):
            for x in range(16):
                r = rng.random()
                img.putpixel((x, y), SHALLOW[1] if r < 0.6 else SHALLOW[0] if r < 0.82 else SHALLOW[2])
        for _ in range(3):
            put(img, rng.randrange(16), rng.randrange(16), MUD[2])
        for _ in range(1 + v):
            x, y = rng.randrange(1, 13), rng.randrange(1, 15)
            rect(img, x, y, x + 2, y, SHALLOW[3])
        tiles.append(img)
    return tiles


def mud_tiles(rng):
    tiles = []
    for v in range(2):  # błoto
        img = new(16, 16)
        for y in range(16):
            for x in range(16):
                r = rng.random()
                img.putpixel((x, y), MUD[1] if r < 0.55 else MUD[2] if r < 0.85 else MUD[0])
        for _ in range(2):  # kałuże
            x, y = rng.randrange(1, 12), rng.randrange(1, 14)
            rect(img, x, y, x + 2, y + 1, SHALLOW[1])
            put(img, x, y, SHALLOW[3])
        tiles.append(img)
    for v in range(2):  # podmokły brzeg: trawa przetarta błotem
        img = new(16, 16)
        green = [hexc("3e7330"), hexc("4a8236"), hexc("2f5a28")]
        for y in range(16):
            for x in range(16):
                r = rng.random()
                img.putpixel((x, y), MUD[2] if r < 0.35 - v * 0.1 else green[0] if r < 0.7 else green[1] if r < 0.9 else green[2])
        tiles.append(img)
    return tiles


# ---------------------------------------------------------------- most
def make_bridge():
    # pokład: deski w poprzek drogi (pionowe)
    deck = new(16, 16)
    for x in range(16):
        k = x % 4
        for y in range(16):
            put(deck, x, y, PLANK[3] if k == 3 else PLANK[1] if k == 1 else PLANK[2])
    for x in range(1, 16, 4):
        put(deck, x, 3, PLANK[3])
        put(deck, x, 12, PLANK[3])
    deck.save(os.path.join(SWAMP, "bridge_deck.png"))
    # poręcz: słupek i dwie żerdzie (kafelek 16 szer.)
    rail = new(16, 18)
    rect(rail, 1, 2, 3, 17, PLANK[0])
    rect(rail, 1, 2, 3, 2, PLANK[2])
    rect(rail, 0, 4, 15, 5, PLANK[1])
    rect(rail, 0, 4, 15, 4, PLANK[2])
    rect(rail, 0, 10, 15, 11, PLANK[1])
    outline(rail, OUTLINE_DARK)
    rail.save(os.path.join(SWAMP, "bridge_rail.png"))
    # pal mostu wystający z wody
    post = new(8, 14)
    rect(post, 2, 0, 5, 13, PLANK[0])
    rect(post, 2, 0, 5, 1, PLANK[2])
    rect(post, 1, 11, 6, 13, SHALLOW[3])  # fala przy palu
    outline(post, OUTLINE_DARK)
    post.save(os.path.join(SWAMP, "bridge_post.png"))


# ---------------------------------------------------------------- roślinność
def make_cattails():
    sheet = new(16 * 3, 26)
    for v in range(3):
        rng = random.Random(10 + v)
        img = new(16, 26)
        for k in range(4 + v):
            x = rng.randrange(2, 14)
            top = rng.randrange(3, 10)
            line(img, x, 25, x + rng.choice([-1, 0, 1]), top, hexc("4b8f3f") if k % 2 else hexc("2f6b34"))
            rect(img, x, top - 1, x + 1, top + 4, hexc("6b4226"))  # kolba
            put(img, x, top - 1, hexc("8a5a34"))
            put(img, x, top - 2, hexc("c8a46e"))
        for k in range(3):  # liście
            x = rng.randrange(1, 15)
            line(img, x, 25, x + rng.choice([-3, 3]), rng.randrange(8, 16), hexc("6fb04a"))
        outline(img, OUTLINE_LEAF)
        sheet.paste(img, (v * 16, 0))
    sheet.save(os.path.join(SWAMP, "cattails.png"))


def make_reeds():
    sheet = new(14 * 2, 14)
    for v in range(2):
        rng = random.Random(30 + v)
        img = new(14, 14)
        for k in range(6):
            x = rng.randrange(1, 13)
            line(img, x, 13, x + rng.choice([-2, -1, 1, 2]), rng.randrange(1, 7), hexc("86a85e") if k % 2 else hexc("62784a"))
        outline(img, OUTLINE_LEAF)
        sheet.paste(img, (v * 14, 0))
    sheet.save(os.path.join(SWAMP, "reeds.png"))


def make_lilies():
    sheet = new(14 * 3, 9)
    for v in range(3):
        img = new(14, 9)
        for cx, cy, r in ((5, 5, 3.5), (10, 4, 2.6)):
            for y in range(9):
                for x in range(14):
                    d = math.hypot(x + 0.5 - cx, (y + 0.5 - cy) * 1.4)
                    if d <= r and not (abs(x + 0.5 - cx - r * 0.5) < 0.8 and y < cy):
                        put(img, x, y, hexc("4b8f3f") if d < r - 1 else hexc("2f6b34"))
        if v == 1:  # kwiat
            rect(img, 4, 3, 6, 4, hexc("f4f7fb"))
            put(img, 5, 3, hexc("f2c94c"))
        if v == 2:
            put(img, 10, 3, hexc("e8a0c0"))
            put(img, 9, 3, hexc("f4c4d8"))
        sheet.paste(img, (v * 14, 0))
    sheet.save(os.path.join(SWAMP, "lilies.png"))


def mangrove(seed):
    """Drzewo rzeczne: gęsta korona na krótkim pniu, który rozchodzi się w łukowate korzenie w wodzie."""
    rng = random.Random(seed)
    W, H = 44, 50
    img = new(W, H)
    root_c = [hexc("4e3a26"), hexc("6b5236"), hexc("86683e")]
    base = H - 4
    # korzenie palczaste - łuki od pnia do wody
    for k in range(7):
        foot = 4 + k * 6 + rng.randrange(-1, 2)
        top_y = base - 15 + rng.randrange(-2, 2)
        steps = 10
        for i in range(steps + 1):
            t = i / steps
            x = round(22 + (foot - 22) * t)
            y = round(top_y + (base - top_y) * t - math.sin(math.pi * t) * 5)
            put(img, x, y, root_c[1] if k % 2 else root_c[0])
            put(img, x, y + 1, root_c[0])
    rect(img, 20, base - 22, 24, base - 12, root_c[1])  # pień
    rect(img, 20, base - 22, 20, base - 12, root_c[2])
    canopy = new(W, H)
    shaded_blob(canopy, [(22, 14, 13), (12, 18, 9), (32, 18, 9), (22, 22, 9)], [hexc("102c22")] + LEAF[1:], rng=rng, speckle=0.2)
    img.alpha_composite(canopy)
    for _ in range(4):  # zwisające pnącza
        x = rng.randrange(10, 34)
        line(img, x, 22, x, 22 + rng.randrange(4, 9), LEAF[2])
    outline(img, OUTLINE_LEAF)
    for x in range(4, 42):  # rozbryzg wody wokół korzeni
        if rng.random() < 0.4:
            put(img, x, base + 1, hexc("7aa898"))
    shadow_ellipse(img, 22, base + 1, 18, 2.5)
    return img


# ---------------------------------------------------------------- drogowskaz i ikona kapliczki
def make_signpost():
    img = new(26, 30)
    rect(img, 11, 6, 13, 29, BARK[1])
    rect(img, 11, 6, 11, 29, BARK[2])
    for y, flip in ((6, False), (14, True)):  # dwie strzałki
        rect(img, 2, y, 23, y + 5, BARK[3])
        rect(img, 2, y, 23, y, hexc("c89a64"))
        tip = 24 if not flip else 1
        for k in range(3):
            put(img, tip + (k if not flip else -k), y + 2, BARK[3])
            put(img, tip + (k if not flip else -k), y + 3, BARK[3])
        for x in range(5, 21, 3):
            put(img, x, y + 3, BARK[1])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 12, 29, 6, 1.2)
    img.save(os.path.join(SWAMP, "signpost.png"))


def make_shrine_icon():
    """Ikona kapliczki na mapę: kamienny obelisk z błękitnym kryształem i poświatą (11x15)."""
    img = new(13, 17)
    glow = hexc("5fd3ff")
    for y in range(17):
        for x in range(13):
            d = math.hypot(x + 0.5 - 6.5, (y + 0.5 - 5) * 0.9)
            if 4.5 < d < 6.2:
                put(img, x, y, (95, 211, 255, 70))
    rect(img, 3, 13, 9, 15, STONE[1])  # podstawa
    rect(img, 3, 13, 9, 13, STONE[3])
    rect(img, 4, 7, 8, 12, STONE[2])  # kolumna
    rect(img, 4, 7, 4, 12, STONE[3])
    for y, half in ((2, 0), (3, 1), (4, 2), (5, 2), (6, 1)):  # kryształ
        rect(img, 6 - half, y, 6 + half, y, glow)
    put(img, 5, 4, hexc("e8fbff"))
    outline(img, OUTLINE_DARK)
    img.save(os.path.join(UI, "shrine_icon.png"))


# ---------------------------------------------------------------- życie przy wodzie
def duck_frame(kind, f, drake):
    """Kaczka bokiem, patrzy w prawo (16x12): pływanie (kołysze się) albo lot (skrzydła góra/dół)."""
    img = new(16, 12)
    body, body_d = (hexc("a8a49a"), hexc("7a766c")) if drake else (hexc("8a6a44"), hexc("6b4e30"))
    head = hexc("2f7a3a") if drake else hexc("7a5a38")
    beak = hexc("e0b020") if drake else hexc("c8862a")
    if kind == "swim":
        bob = f
        for y in range(6, 11):
            for x in range(2, 13):
                if ((x - 7) / 5.5) ** 2 + ((y - 8.5 - bob * 0.5) / 2.5) ** 2 <= 1:
                    put(img, x, y, body if y < 9 else body_d)
        rect(img, 1, 6 + bob, 3, 7 + bob, body_d)  # ogon
        if drake:
            rect(img, 9, 6 + bob, 11, 7 + bob, hexc("5a3a2a"))  # brązowa pierś
        rect(img, 10, 2 + bob, 13, 6 + bob, head)  # głowa
        if drake:
            rect(img, 10, 6 + bob, 13, 6 + bob, hexc("f4f7fb"))  # biała obroża
        rect(img, 14, 4 + bob, 15, 5 + bob, beak)
        put(img, 12, 3 + bob, hexc("1a1c2c"))
        rect(img, 5, 7 + bob, 8, 7 + bob, hexc("3b5fa8") if drake else hexc("3b5fa8"))  # lusterko
        for x in range(1, 15):  # linia wody
            put(img, x, 10, hexc("7aa898"))
    else:
        up = f == 0
        rect(img, 3, 5, 11, 7, body)
        rect(img, 3, 7, 11, 7, body_d)
        rect(img, 11, 4, 13, 6, head)
        rect(img, 14, 5, 15, 5, beak)
        rect(img, 0, 5, 2, 6, body_d)
        if up:  # skrzydła w górze
            for k in range(4):
                rect(img, 5 + k, 1 + k, 6 + k, 4, body_d)
        else:  # skrzydła w dole
            for k in range(4):
                rect(img, 5 + k, 8, 6 + k, 8 + (3 - k), body_d)
    outline(img, OUTLINE_DARK)
    return img


def make_ducks():
    for drake in (True, False):
        sheet = new(16 * 4, 12)
        for i, (kind, f) in enumerate((("swim", 0), ("swim", 1), ("fly", 0), ("fly", 1))):
            sheet.paste(duck_frame(kind, f, drake), (i * 16, 0))
        sheet.save(os.path.join(SWAMP, "duck_drake.png" if drake else "duck_hen.png"))


def crane_frame(kind, f):
    """Żuraw bokiem, patrzy w prawo (26x34): stoi / kroczy / dziobie / leci."""
    img = new(26, 34)
    gray, gray_d, gray_l = hexc("8e939e"), hexc("6a6f7a"), hexc("b4b9c2")
    black, red = hexc("2a2a2e"), hexc("c0392b")
    leg = hexc("3a3a3a")
    if kind in ("stand", "walk", "peck"):
        lx = (1 if f else -1) if kind == "walk" else 0
        line(img, 11 - lx, 24, 11 - lx, 33, leg)  # długie nogi
        line(img, 14 + lx, 24, 14 + lx, 33, leg)
        for y in range(15, 25):  # tułów
            for x in range(5, 20):
                if ((x - 12.5) / 7.5) ** 2 + ((y - 20) / 4.5) ** 2 <= 1:
                    put(img, x, y, gray if y < 22 else gray_d)
        rect(img, 2, 18, 7, 22, black)  # "kuper" z czarnych lotek
        put(img, 2, 22, black)
        if kind == "peck":  # szyja w dół, dziób w wodzie
            line(img, 18, 17, 22, 26, gray_l)
            line(img, 19, 17, 23, 26, gray_l)
            rect(img, 21, 26, 24, 28, black)
            line(img, 24, 28, 25, 32, hexc("6b6b6b"))
        else:  # szyja wyprostowana
            rect(img, 17, 5, 18, 16, gray_l)
            rect(img, 16, 5, 16, 12, black)
            rect(img, 16, 2, 20, 5, black)  # głowa
            rect(img, 17, 2, 18, 2, red)  # czerwona czapeczka
            put(img, 19, 4, hexc("f4f7fb"))
            line(img, 21, 4, 25, 5, hexc("6b6b6b"))  # dziób
    else:  # lot - szyja wyciągnięta w przód, nogi w tył
        up = f == 0
        rect(img, 6, 16, 17, 19, gray)
        rect(img, 17, 16, 22, 17, gray_l)
        rect(img, 22, 15, 24, 17, black)
        put(img, 22, 15, red)
        line(img, 25, 16, 25, 16, hexc("6b6b6b"))
        line(img, 0, 18, 6, 18, leg)
        for k in range(6):
            if up:
                rect(img, 8 + k, 9 + k, 9 + k, 16, gray_d if k < 3 else gray)
            else:
                rect(img, 8 + k, 19, 9 + k, 25 - k, gray_d if k < 3 else gray)
        rect(img, 8, 10 if up else 22, 10, 12 if up else 24, black)
    outline(img, OUTLINE_DARK)
    return img


def make_crane():
    frames = [("stand", 0), ("walk", 0), ("walk", 1), ("peck", 0), ("fly", 0), ("fly", 1)]
    sheet = new(26 * len(frames), 34)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(crane_frame(kind, f), (i * 26, 0))
    sheet.save(os.path.join(SWAMP, "crane.png"))


def make_dragonfly():
    sheet = new(10 * 2, 7)
    for f in range(2):
        img = new(10, 7)
        rect(img, 1, 3, 8, 3, hexc("3b6fd8"))  # odwłok
        rect(img, 6, 2, 8, 4, hexc("2a5aa8"))
        put(img, 9, 3, hexc("1a1c2c"))
        wing = (200, 230, 255, 170)
        if f == 0:
            rect(img, 4, 0, 7, 1, wing)
            rect(img, 4, 5, 7, 6, wing)
        else:
            rect(img, 3, 1, 8, 1, wing)
            rect(img, 3, 5, 8, 5, wing)
        sheet.paste(img, (f * 10, 0))
    sheet.save(os.path.join(SWAMP, "dragonfly.png"))


def make_fish():
    img = new(10, 5)
    for x in range(1, 8):
        for y in range(1, 4):
            if ((x - 4) / 3.5) ** 2 + ((y - 2) / 1.6) ** 2 <= 1:
                put(img, x, y, hexc("a3a7b5") if y < 2 else hexc("7d8192"))
    rect(img, 8, 0, 9, 4, hexc("7d8192"))  # ogon
    put(img, 2, 2, hexc("1a1c2c"))
    outline(img, OUTLINE_DARK)
    img.save(os.path.join(SWAMP, "fish.png"))


def make_all():
    os.makedirs(SWAMP, exist_ok=True)
    os.makedirs(UI, exist_ok=True)
    make_bridge()
    make_cattails()
    make_reeds()
    make_lilies()
    for i in range(3):
        mangrove(300 + i).save(os.path.join(SWAMP, f"mangrove_{i}.png"))
    make_signpost()
    make_shrine_icon()
    make_ducks()
    make_crane()
    make_dragonfly()
    make_fish()
