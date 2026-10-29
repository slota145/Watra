"""Wietrzne Turnie - górska kraina na wschód od rozlewisk. Kafelki (alpejska trawa, skała,
piarg - dopisywane do tiles.png przez make_tiles), skarpy płaskowyżów (ściany, krawędzie, rampy), ruda
żelaza, martwe drzewa (żerdzie orłów), drobne ozdoby, kozy górskie, orły (lot i siedzenie),
ptakoludzie (wojownik, miotacz oszczepów, szaman burzy), ich wódz - Gromoskrzydły, burzowy
orzeł - oraz wioska: chaty na palach, gniazda na skalnych iglicach, żerdzie z piórami,
totemy orła, gniazda z jajami, kości kóz, kopczyki kamieni, dzwonki wietrzne, piorunochrony
z kryształem burzy i wielkie gniazdo wodza. Do tego ikony łupów (ruda, skóra kozy, pióro).
Wywoływane z generate_art.py.

Arkusze postaci mają układ jak goblin (4x2): 0-3 chód, 4-5 spoczynek, 6 zamach, 7 cios."""
import math
import os
import random

from generate_art import (BARK, OUT, OUTLINE_DARK, STONE, hexc, line, new, outline, put, rect, shaded_blob,
                          shadow_ellipse)

MOUNT = os.path.join(OUT, "mountains")
ITEMS = os.path.join(OUT, "items")
EYE = hexc("1a1c2c")

ALPINE = [hexc("4a6a3a"), hexc("5f7f44"), hexc("748f4e"), hexc("8aa35c"), hexc("a4b86e")]
ROCK = [hexc("3a3a44"), hexc("55565f"), hexc("6e6f78"), hexc("8a8b92"), hexc("a8a9ae")]
GRAVEL = [hexc("6a6258"), hexc("847b6e"), hexc("9c9384"), hexc("b4ab9a")]
FEATHER = [hexc("4a3020"), hexc("6b4a2c"), hexc("8a6440"), hexc("c8a878"), hexc("f0e8d8")]
STORM = [hexc("1d3a8a"), hexc("3f7fe0"), hexc("8ac8ff"), hexc("e8f6ff")]
IRON = [hexc("6e3018"), hexc("a04a20"), hexc("c8702e"), hexc("4a4e58")]


def ellipse(img, cx, cy, rx, ry, color, shade=None):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                put(img, x, y, shade if shade is not None and dy > 0.45 else color)


def save(img, name, folder=MOUNT):
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name + ".png"))


# ---------------------------------------------------------------- kafelki (rzędy 5 i 6 w tiles.png)
def _noise_tile(rng, palette, weights, specks=None):
    img = new(16, 16)
    for y in range(16):
        for x in range(16):
            r = rng.random()
            acc = 0.0
            c = palette[-1]
            for col, w in zip(palette, weights):
                acc += w
                if r < acc:
                    c = col
                    break
            img.putpixel((x, y), c)
    for col, n in (specks or []):
        for _ in range(n):
            put(img, rng.randrange(16), rng.randrange(16), col)
    return img


def alpine_tile(rng, stones):
    img = _noise_tile(rng, [ALPINE[1], ALPINE[2], ALPINE[3]], [0.25, 0.5, 0.25])
    for _ in range(5):
        x, y = rng.randrange(1, 15), rng.randrange(2, 15)
        put(img, x, y, ALPINE[0])
        put(img, x, y - 1, ALPINE[4])
    for _ in range(stones):
        x, y = rng.randrange(1, 14), rng.randrange(1, 14)
        rect(img, x, y, x + 1, y, ROCK[3])
        put(img, x, y + 1, ROCK[1])
    return img


def rock_tile(rng, light):
    pal = ROCK[2:] if light else ROCK[1:4]
    img = _noise_tile(rng, pal, [0.3, 0.45, 0.25])
    for _ in range(3):  # pęknięcia
        x, y = rng.randrange(0, 14), rng.randrange(0, 14)
        for k in range(rng.randint(2, 5)):
            put(img, x + k, y + (k + rng.randint(0, 1)) // 2, ROCK[0])
    return img


def gravel_tile(rng):
    img = _noise_tile(rng, GRAVEL[:3], [0.3, 0.45, 0.25], [(GRAVEL[3], 14), (ROCK[0], 8)])
    return img


def ground_tiles(rng):
    """8 kafelków: alpejska trawa x2 (gładka, z kamykami), skała x2, piarg x2, jasna skała, płowa trawa płaskowyżów."""
    return [alpine_tile(rng, 0), alpine_tile(rng, 3), rock_tile(rng, False), rock_tile(rng, False),
            gravel_tile(rng), gravel_tile(rng), rock_tile(rng, True), highland_tile(rng)]


def highland_tile(rng):
    """Sucha, płowa trawa wysokogórska na płaskowyżach - od razu widać, co leży wyżej."""
    dry = [hexc("7a7a42"), hexc("948e50"), hexc("aaa262"), hexc("c0b878")]
    img = _noise_tile(rng, dry[:3], [0.25, 0.5, 0.25])
    for _ in range(6):
        x, y = rng.randrange(1, 15), rng.randrange(2, 15)
        put(img, x, y, dry[0])
        put(img, x, y - 1, dry[3])
    for _ in range(2):
        x, y = rng.randrange(1, 14), rng.randrange(1, 14)
        put(img, x, y, ROCK[3])
    return img


# ---------------------------------------------------------------- skarpy
def cliff_wall(variant):
    """Ściana płaskowyżu od południa (16x32) - kafelkuje się w poziomie bez szwów: warstwy skały
    zależą tylko od wysokości, u góry jasna krawędź, u dołu cień. Warianty różnią się rysami."""
    rng = random.Random(70 + variant)
    img = new(16, 32)
    bands = [ROCK[3], ROCK[2], ROCK[2], ROCK[1], ROCK[2], ROCK[3], ROCK[2], ROCK[1], ROCK[1], ROCK[0]]
    for y in range(32):
        for x in range(16):
            if y < 2:
                c = ROCK[4] if y == 0 else ROCK[3]
            else:
                c = bands[min((y - 2) // 3, len(bands) - 1)]
                if rng.random() < 0.06:
                    c = ROCK[0] if y > 16 else ROCK[3]
            img.putpixel((x, y), c)
    for _ in range(2 + variant):  # pionowe rysy
        x = rng.randrange(1, 15)
        for y in range(rng.randint(3, 8), rng.randint(16, 28)):
            put(img, x, y, ROCK[0])
            if rng.random() < 0.3:
                x = max(0, min(15, x + rng.choice((-1, 1))))
    if variant == 1:  # wystający głaz
        rect(img, 4, 14, 8, 16, ROCK[3])
        rect(img, 4, 17, 8, 17, ROCK[0])
    if variant == 2:  # kępka trawy w szczelinie
        rect(img, 9, 11, 11, 11, ALPINE[2])
        put(img, 10, 10, ALPINE[3])
    for x in range(16):  # nierówne dno - cień przechodzący w osypisko
        for y in range(29 + rng.randint(0, 2), 32):
            img.putpixel((x, y), (0, 0, 0, 0))
    return img


def wall_end(side):
    """Zaokrąglony koniec ściany (5x32) - ciemniejszy brzeg tam, gdzie ściana się kończy."""
    img = new(5, 32)
    for y in range(2, 30):
        for x in range(5):
            edge = x if side == "right" else 4 - x  # 0 przy ścianie, 4 na zewnątrz
            if edge >= 4 - (y < 6):
                continue
            img.putpixel((x, y), ROCK[1] if edge < 2 else ROCK[0])
    return img


def rim(side):
    """Krawędź płaskowyżu z boku albo z tyłu: pas skały bez trawy, kafelkuje się bez szwów."""
    if side == "back":
        img = new(16, 6)
        for y in range(6):
            for x in range(16):
                img.putpixel((x, y), [ROCK[0], ROCK[1], ROCK[2], ROCK[3], ROCK[3], ROCK[2]][y])
        return img
    img = new(6, 16)
    for y in range(16):
        for x in range(6):
            edge = x if side == "right" else 5 - x  # 5 = zewnętrzny brzeg
            img.putpixel((x, y), [ROCK[2], ROCK[3], ROCK[3], ROCK[2], ROCK[1], ROCK[0]][edge])
    return img


def ramp():
    """Żwirowa rampa (48x32) prowadząca na płaskowyż: stopnie z kamieni między skalnymi brzegami."""
    rng = random.Random(77)
    img = new(48, 32)
    for y in range(32):
        for x in range(48):
            c = GRAVEL[1] if rng.random() < 0.6 else GRAVEL[2]
            if y % 6 == 5:
                c = GRAVEL[0]
            if rng.random() < 0.05:
                c = ROCK[3]
            img.putpixel((x, y), c)
    for y in range(32):  # skalne brzegi rampy
        for x in range(4):
            img.putpixel((x, y), [ROCK[0], ROCK[1], ROCK[2], ROCK[3]][x])
            img.putpixel((47 - x, y), [ROCK[0], ROCK[1], ROCK[2], ROCK[3]][x])
    for x in range(48):
        put(img, x, 0, ROCK[3])
    return img


def peak(variant):
    """Wysoki szczyt (88x96): skalna piramida oświetlona z lewej, z granią, żlebami
    i śnieżną czapą; u podstawy piarg. Stawiany gęsto na grani wokół wioski ptakoludzi."""
    rng = random.Random(200 + variant)
    W, H = 88, 96
    img = new(W, H)
    top_x = W // 2 + rng.randint(-10, 10)
    top_y = 4 + rng.randint(0, 10)
    base = H - 6
    snow = [hexc("c8d4e0"), hexc("e8eef4"), hexc("ffffff")]
    for y in range(top_y, base + 1):
        t = (y - top_y) / (base - top_y)
        left = top_x - int(t * (top_x - 2) + math.sin(y * 0.3 + variant) * 2)
        right = top_x + int(t * (W - 3 - top_x) + math.sin(y * 0.25 + variant * 2) * 2)
        for x in range(max(0, left), min(W, right + 1)):
            lit = x < top_x + (y - top_y) * 0.12  # grań schodzi lekko w prawo: lewa strona w świetle
            c = ROCK[3] if lit else ROCK[1]
            if rng.random() < 0.07:
                c = ROCK[2]
            # śnieżna czapa i śnieg w żlebach
            snow_line = 0.32 + 0.05 * math.sin(x * 0.4 + variant)
            if t < snow_line:
                c = snow[2] if lit else snow[0]
            elif t < snow_line + 0.14 and rng.random() < 0.35 * (1 - (t - snow_line) / 0.14):
                c = snow[1] if lit else snow[0]
            put(img, x, y, c)
    for k in range(4):  # żleby - ukośne ciemne smugi
        x0 = top_x + rng.randint(-14, 14)
        y0 = top_y + rng.randint(14, 30)
        for i in range(rng.randint(14, 30)):
            x = x0 + (i // 3) * (1 if x0 > top_x else -1)
            y = y0 + i
            if 0 <= x < W and y <= base and img.getpixel((x, y))[3]:
                put(img, x, y, ROCK[0] if y > top_y + 28 else snow[0])
    for x in range(W):  # piarg u podstawy
        for y in range(base - 3, base + 1):
            if img.getpixel((x, y))[3] and rng.random() < 0.5:
                put(img, x, y, GRAVEL[rng.randrange(3)])
    outline(img, OUTLINE_DARK)
    return img


# ---------------------------------------------------------------- ruda żelaza, drzewa, ozdoby
def iron_ore(variant):
    rng = random.Random(90 + variant)
    img = new(26, 22)
    circles = [(13, 13, 9), (7 + variant, 15, 6), (19 - variant, 15, 6)]
    shaded_blob(img, circles, [ROCK[0], ROCK[1], ROCK[2], ROCK[3]], rng=rng)
    for _ in range(6 + variant):  # rdzawe żyły i metaliczne grudki
        x, y = rng.randrange(5, 21), rng.randrange(7, 19)
        if img.getpixel((x, y))[3]:
            put(img, x, y, IRON[1])
            put(img, x + 1, y, IRON[2])
            put(img, x, y + 1, IRON[0])
    for _ in range(3):
        x, y = rng.randrange(6, 20), rng.randrange(8, 17)
        if img.getpixel((x, y))[3]:
            put(img, x, y, hexc("c8ccd8"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 13, 21, 11, 1.6)
    return img


def dead_tree(variant):
    """Martwe, pokręcone drzewo z gołymi gałęziami - orły na nim przysiadają."""
    rng = random.Random(110 + variant)
    img = new(32, 46)
    wood = [hexc("3e2e22"), hexc("5a4636"), hexc("7a6450")]
    for y in range(14, 45):
        sway = int(math.sin(y * 0.25 + variant) * 1.5)
        rect(img, 14 + sway, y, 17 + sway, y, wood[1])
        put(img, 14 + sway, y, wood[2])
    for (x0, y0, x1, y1) in [(16, 18, 4, 9), (16, 24, 28, 14), (15, 30, 6, 24), (17, 14, 22, 4), (16, 16, 12, 2)]:
        line(img, x0, y0, x1 + rng.randint(-1, 1), y1, wood[1])
        line(img, x0, y0 + 1, x1 + rng.randint(-1, 1), y1 + 1, wood[0])
    rect(img, 10, 44, 21, 45, wood[0])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 16, 45, 9, 1.5)
    return img


def mountain_decor():
    """8 klatek drobnych ozdób (16x16): szarotka, goryczka, kamyki x2, kępa trawy x2, mech, czaszka kozy."""
    sheet = new(16 * 8, 16)
    rng = random.Random(5)
    for f in range(8):
        img = new(16, 16)
        if f == 0:  # szarotka
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1), (-1, -1), (1, 1)):
                put(img, 8 + dx, 9 + dy, hexc("f0f0e8"))
            put(img, 8, 9, hexc("e0c040"))
            line(img, 8, 11, 8, 14, ALPINE[1])
        elif f == 1:  # goryczka
            for x in (6, 9):
                rect(img, x, 8, x + 1, 10, hexc("3a5ad0"))
                put(img, x, 7, hexc("6a8af0"))
                line(img, x, 11, x, 14, ALPINE[1])
        elif f in (2, 3):
            for _ in range(3 + f):
                x, y = rng.randrange(3, 12), rng.randrange(8, 14)
                rect(img, x, y, x + 1, y, ROCK[3])
                put(img, x, y + 1, ROCK[1])
        elif f in (4, 5):
            for k in range(5):
                x = 5 + k + (f - 4)
                line(img, x, 14, x + rng.randint(-1, 1), 8 + rng.randint(0, 2), ALPINE[3] if k % 2 else ALPINE[2])
        elif f == 6:
            ellipse(img, 8, 12, 5, 2.5, hexc("5f7f44"))
            ellipse(img, 7, 11, 2, 1, hexc("8aa35c"))
        else:  # czaszka kozy z rogami
            ellipse(img, 8, 11, 3, 2.5, hexc("e8dcc0"))
            put(img, 7, 11, EYE)
            put(img, 9, 11, EYE)
            line(img, 5, 9, 3, 6, hexc("b8a888"))
            line(img, 11, 9, 13, 6, hexc("b8a888"))
        sheet.paste(img, (f * 16, 0))
    return sheet


# ---------------------------------------------------------------- koza górska (24x22, bokiem)
def goat_frame(kind, f):
    img = new(24, 22)
    fur, fur_d, fur_l = hexc("e8e4d8"), hexc("b8b2a2"), hexc("ffffff")
    horn = hexc("6a5a48")
    base = 21
    run = kind == "run"
    graze = kind == "graze"
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if run else 0
    lift = {0: 0, 1: -1, 2: -2, 3: -1}[f] if run else 0
    by = base - 9 + lift
    for lx, ph in ((7, step), (9, -step), (15, -step), (17, step)):
        rect(img, lx + ph // 2, by + 4, lx + ph // 2, base - 1, fur_d)
        put(img, lx + ph // 2, base - 1, hexc("3a3028"))
    ellipse(img, 12, by + 1, 7, 4, fur, fur_d)
    ellipse(img, 11, by - 1, 5, 2, fur_l)
    # szyja i głowa (pasąca się - nisko)
    hx, hy = (19, by + 4) if graze else (19, by - 4)
    line(img, 16, by - 1, hx - 1, hy + 1, fur)
    line(img, 17, by - 1, hx, hy + 1, fur)
    ellipse(img, hx + 1, hy, 2.6, 2, fur)
    put(img, hx + 3, hy + 1, fur_d)
    put(img, hx + 1, hy - 1, EYE)
    # bródka i zakrzywione rogi
    put(img, hx + 2, hy + 2, fur_d)
    put(img, hx + 2, hy + 3, fur_d)
    curl = 1 if kind == "alert" else 0
    line(img, hx, hy - 2, hx - 3, hy - 5 - curl, horn)
    line(img, hx - 3, hy - 5 - curl, hx - 5, hy - 3, horn)
    put(img, 5, by - 1, fur_l)  # ogonek
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 12, 21, 8, 1.4)
    return img


def make_goat():
    frames = [("run", 0), ("run", 1), ("run", 2), ("run", 3), ("graze", 0), ("graze", 1), ("alert", 0), ("idle", 0)]
    sheet = new(24 * 4, 22 * 2)
    for i, (kind, f) in enumerate(frames):
        img = goat_frame(kind, f)
        if kind == "graze" and f == 1:
            img = img.transpose(0) if False else img
        sheet.paste(img, ((i % 4) * 24, (i // 4) * 22))
    save(sheet, "goat")


# ---------------------------------------------------------------- orzeł (lot 4 klatki 30x20, siedzenie 2 klatki 16x18)
def eagle_fly(f):
    img = new(30, 20)
    body, body_d, head = FEATHER[1], FEATHER[0], hexc("f0ece0")
    wing = {0: -7, 1: -2, 2: 4, 3: -2}[f]
    for side in (-1, 1):
        for i in range(12):
            x = 15 + side * (3 + i)
            y = 10 + int(wing * (i / 11.0)) - (1 if i > 8 else 0)
            rect(img, min(x, x + side), y, max(x, x + side), y + 2 - (i > 9), body if i < 9 else body_d)
            if i > 8:
                put(img, x + side, y + 2, body_d)
    ellipse(img, 15, 11, 3, 5, body, body_d)
    ellipse(img, 15, 6, 2.2, 2.2, head)
    put(img, 15, 4, hexc("e0a020"))
    rect(img, 14, 15, 16, 17, head)  # biały ogon
    outline(img, OUTLINE_DARK)
    return img


def eagle_perch(f):
    img = new(16, 18)
    body, body_d, head = FEATHER[1], FEATHER[0], hexc("f0ece0")
    ellipse(img, 8, 10, 4, 5.5, body, body_d)
    line(img, 5, 7, 4, 14, body_d)
    ellipse(img, 9 + (1 if f else 0), 4, 2.6, 2.4, head)
    put(img, 11 + (1 if f else 0), 4, hexc("e0a020"))
    put(img, 12 + (1 if f else 0), 5, hexc("e0a020"))
    put(img, 9 + (1 if f else 0), 3, EYE)
    rect(img, 6, 15, 7, 16, hexc("e0a020"))
    rect(img, 9, 15, 10, 16, hexc("e0a020"))
    rect(img, 7, 15, 9, 16, head)
    outline(img, OUTLINE_DARK)
    return img


def make_eagle():
    fly = new(30 * 4, 20)
    for f in range(4):
        fly.paste(eagle_fly(f), (f * 30, 0))
    save(fly, "eagle_fly")
    perch = new(16 * 2, 18)
    for f in range(2):
        perch.paste(eagle_perch(f), (f * 16, 0))
    save(perch, "eagle_perch")


# ---------------------------------------------------------------- ptakoludzie (22x26, bokiem, patrzą w prawo)
BIRD_PALETTES = {
    "birdman": (hexc("7a5a3a"), hexc("54402a"), hexc("d8c8a8"), hexc("c0392b")),
    "birdman_thrower": (hexc("5a6a7a"), hexc("3e4a58"), hexc("d0d8e0"), hexc("2f8a9a")),
    "birdman_shaman": (hexc("3d3466"), hexc("2a2248"), hexc("c8c0e8"), hexc("8ac8ff")),
}


def bird_frame(kind, f, name):
    img = new(22, 26)
    feather, feather_d, chest, accent = BIRD_PALETTES[name]
    base = 25
    hop = {0: 0, 1: -1, 2: 0, 3: -1}[f] if kind == "walk" else 0
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if kind == "walk" else 0
    # chude, ptasie nogi ze szponami
    for lx, ph in ((8, step), (12, -step)):
        line(img, lx + ph // 2, base - 7 + hop, lx + ph // 2, base - 1, hexc("e0a020"))
        rect(img, lx - 1 + ph // 2, base - 1, lx + 2 + ph // 2, base - 1, hexc("c08010"))
    by = base - 12 + hop
    ellipse(img, 10, by, 5, 6, feather, feather_d)
    ellipse(img, 12, by + 1, 2.5, 4, chest)
    # skrzydła-ramiona: złożone, rozłożone w zamachu
    if kind in ("windup", "strike"):
        for i in range(9):
            put(img, 6 - i // 2, by - 4 - i, feather_d)
            put(img, 7 - i // 2, by - 4 - i, feather)
            put(img, 5 - i // 2, by - 3 - i, accent if i > 6 else feather_d)
    else:
        ellipse(img, 7, by + 1, 2.5, 5, feather_d)
        for i in range(3):
            put(img, 5 + i, by + 6 + (i % 2), accent)
    # głowa z hakowatym dziobem i grzebieniem piór
    hy = by - 9
    ellipse(img, 12, hy + 2, 3.6, 3.2, feather)
    put(img, 13, hy + 1, hexc("f2d14c"))
    put(img, 14, hy + 1, EYE)
    rect(img, 15, hy + 2, 17, hy + 2, hexc("e0a020"))
    put(img, 17, hy + 3, hexc("c08010"))
    for k in range(4):
        put(img, 9 - k, hy - 1 + k // 2, accent if k % 2 else feather_d)
        put(img, 9 - k, hy - 2 + k // 2, accent)
    # broń
    if name == "birdman":  # oszczep z kamiennym grotem
        wood, tip = BARK[2], ROCK[3]
        if kind == "windup":
            line(img, 2, hy, 15, by + 2, wood)
            rect(img, 1, hy - 1, 2, hy, tip)
        elif kind == "strike":
            line(img, 7, by - 1, 21, by - 2, wood)
            rect(img, 20, by - 3, 21, by - 1, tip)
        else:
            line(img, 16, hy - 4, 16, base - 3, wood)
            rect(img, 15, hy - 6, 17, hy - 5, tip)
    elif name == "birdman_thrower":  # kołczan i oszczepy do rzucania
        line(img, 5, by - 6, 4, by + 4, BARK[1])
        for k in range(3):
            put(img, 4 + k, by - 7 - k, FEATHER[4])
        if kind == "windup":
            line(img, 3, hy - 3, 16, hy + 2, wood := BARK[2])
            put(img, 16, hy + 2, ROCK[4])
        elif kind == "strike":
            line(img, 12, by - 2, 21, by - 6, BARK[2])
            put(img, 21, by - 6, ROCK[4])
    else:  # szaman: laska z kryształem burzy
        line(img, 17, hy - 5, 17, base - 2, BARK[1])
        glow = STORM[3] if kind in ("windup", "strike") else STORM[2]
        rect(img, 16, hy - 8, 18, hy - 6, glow)
        put(img, 17, hy - 9, STORM[3])
        if kind == "strike":
            for k in range(4):
                put(img, 18 + k % 2, hy - 10 - k, STORM[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 10, 25, 6, 1.3)
    return img


def make_birdmen():
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("idle", 1), ("windup", 0), ("strike", 0)]
    for name in BIRD_PALETTES:
        sheet = new(22 * 4, 26 * 2)
        for i, (kind, f) in enumerate(frames):
            img = bird_frame(kind, f, name)
            if kind == "idle" and f == 1:  # strzepnięcie piór - lekko w górę
                shifted = new(22, 26)
                shifted.paste(img, (0, -1))
                img = shifted
            sheet.paste(img, ((i % 4) * 22, (i // 4) * 26))
        save(sheet, name)


# ---------------------------------------------------------------- Gromoskrzydły (64x56)
def eagle_boss_frame(kind, f=0):
    img = new(64, 56)
    body, body_d, body_l = hexc("3a3a5a"), hexc("26263e"), hexc("5a5a82")
    head = hexc("e8eef8")
    base = 54
    hover = {0: 0, 1: -2, 2: -3, 3: -1}[f] if kind == "fly" else 0
    by = base - 22 + hover
    wings_up = kind in ("fly", "charge", "screech")
    flap = {0: -10, 1: -4, 2: 6, 3: -4}[f] if kind == "fly" else (-14 if kind == "charge" else -8 if kind == "screech" else 0)
    # skrzydła
    for side in (-1, 1):
        for i in range(24):
            x = 32 + side * (5 + i)
            if wings_up:
                y = by - 4 + int(flap * (i / 23.0))
            elif kind == "dive":
                y = by - 2 - i // 3
                x = 32 + side * (5 + i // 2)
            else:
                y = by + 2 + i // 5
                x = 32 + side * (5 + i // 2)
            height = 6 if i < 16 else 4
            col = body if i < 14 else body_d
            rect(img, min(x, x + side), y, max(x, x + side), y + height, col)
            if i % 4 == 0:
                put(img, x, y + height, STORM[1])
            if i > 18:
                put(img, x + side, y + height + 1, body_d)
    # tułów i ogon
    ellipse(img, 32, by + 4, 8, 11, body, body_d)
    ellipse(img, 33, by + 4, 4, 7, body_l)
    for k in range(5):
        rect(img, 28 + k * 2, by + 14, 29 + k * 2, by + 19, head if k % 2 else STORM[2])
    # szpony
    for tx in (28, 35):
        rect(img, tx, by + 14, tx + 1, base - 2 - max(hover, 0), hexc("e0a020"))
        rect(img, tx - 1, base - 2, tx + 3, base - 1, hexc("c08010"))
    # biała głowa z hakowatym dziobem i burzowymi oczami
    hy = by - 10
    ellipse(img, 33, hy, 6, 5.5, head)
    rect(img, 38, hy, 42, hy + 1, hexc("e0a020"))
    rect(img, 41, hy + 2, 42, hy + 3, hexc("c08010"))
    put(img, 35, hy - 1, STORM[3])
    put(img, 36, hy - 1, STORM[1])
    if kind == "screech":
        rect(img, 38, hy + 2, 41, hy + 2, hexc("6e231c"))
    # pióropusz z wyładowaniami
    for k in range(5):
        put(img, 27 - k, hy - 3 - k % 2, STORM[2 if k % 2 else 1])
    if kind in ("charge", "screech", "fly"):
        rng = random.Random(f + {"charge": 10, "screech": 20, "fly": 30}[kind])
        for _ in range(6 if kind == "charge" else 3):
            x, y = rng.randrange(6, 58), rng.randrange(by - 18, by + 12)
            for k in range(4):
                put(img, x + rng.randint(-1, 1), y + k, STORM[3] if k % 2 else STORM[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 32, base, 18, 2.5)
    return img


def make_eagle_boss():
    frames = [("fly", 0), ("fly", 1), ("fly", 2), ("fly", 3), ("idle", 0), ("charge", 0), ("dive", 0), ("screech", 0)]
    sheet = new(64 * 4, 56 * 2)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(eagle_boss_frame(kind, f), ((i % 4) * 64, (i // 4) * 56))
    save(sheet, "storm_eagle")


# ---------------------------------------------------------------- wioska ptakoludzi
def stilt_hut(variant):
    """Chata na wysokich palach: ściany z plecionych gałęzi, dach z piór, drabina, wiszące pióra."""
    rng = random.Random(130 + variant)
    img = new(52, 70)
    wood = [hexc("3e2e22"), hexc("5a4636"), hexc("7a6450")]
    for px in (12, 24 + variant * 2, 38):  # pale
        rect(img, px, 38, px + 2, 68, wood[1])
        put(img, px, 38, wood[2])
    line(img, 13, 66, 39, 44, wood[0])  # ukośne stężenia
    line(img, 13, 44, 39, 66, wood[0])
    rect(img, 6, 36, 46, 39, wood[2])  # pomost
    rect(img, 6, 39, 46, 39, wood[0])
    for y in range(18, 36):  # pleciona ściana
        for x in range(10, 43):
            weave = (x + (y // 3) * 2) % 6 < 3
            img.putpixel((x, y), wood[2] if weave else wood[1])
    rect(img, 23, 26, 29, 35, hexc("1a1210"))  # wejście
    for y in range(0, 20):  # dach z piór
        half = 6 + y
        for x in range(26 - half, 26 + half + 1):
            if 0 <= x < 52:
                row = y // 3
                c = FEATHER[2] if (x + row) % 4 else FEATHER[1]
                if y > 15 and (x % 3 == 0):
                    c = FEATHER[3]
                img.putpixel((x, y + 2), c)
    for k in range(4):  # pióra na sznurkach
        x = 10 + k * 10 + rng.randint(-2, 2)
        line(img, x, 22, x, 26, wood[0])
        rect(img, x - 1, 27, x, 31, [FEATHER[4], hexc("c0392b"), STORM[1], FEATHER[3]][k])
    for y in range(40, 68, 3):  # drabina
        rect(img, 30, y, 34, y, wood[2])
    line(img, 30, 39, 30, 68, wood[1])
    line(img, 34, 39, 34, 68, wood[1])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 26, 68, 20, 2)
    return img


def rock_pillar_nest(variant):
    """Skalna iglica z gniazdem i jajami na szczycie."""
    rng = random.Random(150 + variant)
    img = new(40, 76)
    for y in range(22, 74):
        w = 8 + (y - 22) // 6 + int(math.sin(y * 0.4 + variant) * 1.5)
        for x in range(20 - w, 20 + w):
            c = ROCK[2] if x < 20 - w // 3 else ROCK[1] if x < 20 + w // 3 else ROCK[0]
            if rng.random() < 0.06:
                c = ROCK[3]
            put(img, x, y, c)
    for y in range(12, 24):  # gniazdo z gałęzi
        w = 15 - abs(y - 18)
        for x in range(20 - w, 20 + w):
            put(img, x, y, BARK[1] if (x + y) % 3 else BARK[2])
    for ex in (15, 20, 25):  # jaja
        ellipse(img, ex, 13, 2.2, 2.6, hexc("e8e0d0"))
        put(img, ex - 1, 12, hexc("ffffff"))
        put(img, ex + 1, 14, hexc("a89880"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 20, 74, 16, 2)
    return img


def perch_pole():
    """Żerdź z poprzeczkami i powiewającymi piórami (2 klatki)."""
    sheet = new(20 * 2, 48)
    for f in range(2):
        img = new(20, 48)
        rect(img, 9, 4, 10, 47, BARK[1])
        for y in (10, 22):
            rect(img, 3, y, 16, y + 1, BARK[2])
            for k, x in enumerate((4, 8, 12, 15)):
                sway = (1 if (f + k) % 2 else -1)
                line(img, x, y + 2, x + sway, y + 6, [FEATHER[4], hexc("c0392b"), STORM[1], FEATHER[3]][k])
        rect(img, 8, 2, 11, 4, FEATHER[4])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 10, 47, 5, 1)
        sheet.paste(img, (f * 20, 0))
    return sheet


def eagle_totem():
    """Rzeźbiony totem z rozpostartymi skrzydłami orła."""
    img = new(36, 50)
    wood = [hexc("4a3020"), hexc("6b4a2c"), hexc("8a6440")]
    rect(img, 15, 14, 21, 49, wood[1])
    rect(img, 15, 14, 16, 49, wood[2])
    for y in (24, 34, 42):  # rzeźbione twarze
        rect(img, 16, y, 20, y + 1, wood[0])
        put(img, 17, y - 2, hexc("f2d14c"))
        put(img, 19, y - 2, hexc("f2d14c"))
    for side in (-1, 1):  # skrzydła
        for i in range(14):
            x = 18 + side * (4 + i)
            rect(img, min(x, x + side), 10 + i // 3, max(x, x + side), 15 - i // 4, wood[2] if i % 3 else STORM[1])
    ellipse(img, 18, 8, 4, 4, hexc("e8e0d0"))
    rect(img, 21, 8, 24, 9, hexc("e0a020"))
    put(img, 19, 7, EYE)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 18, 49, 8, 1.4)
    return img


def egg_nest():
    img = new(26, 14)
    for y in range(4, 13):
        w = 12 - abs(y - 8)
        rect(img, 13 - w, y, 12 + w, y, BARK[1] if y % 2 else BARK[2])
    for ex in (8, 13, 18):
        ellipse(img, ex, 6, 2.4, 2.8, hexc("dcd4c0"))
        put(img, ex - 1, 5, hexc("ffffff"))
        put(img, ex + 1, 7, hexc("8ac8ff"))
    outline(img, OUTLINE_DARK)
    return img


def bone_pile():
    img = new(26, 14)
    bone = hexc("e8dcc0")
    for (x0, y0, x1, y1) in ((3, 12, 14, 9), (8, 12, 21, 11), (12, 8, 23, 12)):
        line(img, x0, y0, x1, y1, bone)
    ellipse(img, 9, 7, 3.4, 2.8, bone)
    put(img, 8, 7, EYE)
    put(img, 10, 7, EYE)
    line(img, 6, 5, 3, 1, hexc("b8a888"))
    line(img, 12, 5, 15, 1, hexc("b8a888"))
    outline(img, OUTLINE_DARK)
    return img


def cairn():
    img = new(16, 22)
    y = 20
    for k, w in enumerate((6, 5, 4, 3, 2)):
        rect(img, 8 - w, y - 3, 7 + w, y, ROCK[3] if k % 2 else ROCK[2])
        rect(img, 8 - w, y, 7 + w, y, ROCK[1])
        y -= 4
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 21, 6, 1.2)
    return img


def wind_chime():
    """Dzwonek wietrzny z kości i piór (2 klatki - kołysanie)."""
    sheet = new(18 * 2, 36)
    for f in range(2):
        img = new(18, 36)
        rect(img, 8, 6, 9, 35, BARK[1])
        rect(img, 2, 6, 15, 7, BARK[2])
        for k, x in enumerate((3, 7, 11, 14)):
            sway = 1 if (f + k) % 2 else 0
            line(img, x, 8, x + sway, 13, hexc("8a7a5a"))
            rect(img, x + sway, 14, x + sway, 17, hexc("e8dcc0") if k % 2 else FEATHER[4])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 9, 35, 4, 1)
        sheet.paste(img, (f * 18, 0))
    return sheet


def storm_rod():
    """Piorunochron: skała z żelaznym prętem i kryształem burzy, po którym przeskakują iskry (2 klatki)."""
    sheet = new(18 * 2, 44)
    for f in range(2):
        img = new(18, 44)
        for y in range(30, 43):
            w = 6 - (42 - y) // 4
            rect(img, 9 - w, y, 8 + w, y, ROCK[2] if y < 36 else ROCK[1])
        rect(img, 8, 10, 9, 30, IRON[3])
        for y in range(2, 11):
            w = 3 - abs(y - 6) // 2
            rect(img, 9 - w, y, 8 + w, y, STORM[2] if y % 2 else STORM[1])
        put(img, 8, 4, STORM[3])
        rng = random.Random(f)
        for _ in range(4):
            x, y = rng.randrange(2, 16), rng.randrange(1, 14)
            put(img, x, y, STORM[3])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 9, 43, 7, 1.2)
        sheet.paste(img, (f * 18, 0))
    return sheet


def aerie():
    """Olbrzymie gniazdo wodza (płasko na ziemi, 112x52): pierścień z gałęzi, kości i pióra."""
    rng = random.Random(170)
    img = new(112, 52)
    for y in range(52):
        for x in range(112):
            d = math.hypot((x - 56) / 54, (y - 26) / 24)
            if d > 1:
                continue
            if d > 0.62:
                c = BARK[1] if (x * 3 + y * 5) % 7 else BARK[2]
                if rng.random() < 0.08:
                    c = BARK[0]
            else:
                c = hexc("8a7a5a") if rng.random() < 0.7 else hexc("a89878")
            img.putpixel((x, y), c)
    for _ in range(24):  # pióra i kości
        x, y = rng.randrange(20, 92), rng.randrange(8, 44)
        if math.hypot((x - 56) / 54, (y - 26) / 24) < 0.9:
            line(img, x, y, x + rng.randint(-3, 3), y + rng.randint(1, 3), rng.choice([FEATHER[4], hexc("e8dcc0"), STORM[1]]))
    outline(img, OUTLINE_DARK)
    return img


# ---------------------------------------------------------------- łupy
def item_icons():
    ore = new(16, 16)
    shaded = [ROCK[0], ROCK[1], ROCK[2], ROCK[3]]
    shaded_blob(ore, [(8, 9, 6), (5, 10, 4)], shaded, rng=random.Random(3))
    for x, y in ((6, 7), (9, 9), (7, 11), (10, 6)):
        put(ore, x, y, IRON[2])
        put(ore, x + 1, y, IRON[1])
    put(ore, 8, 8, hexc("d8dce8"))
    outline(ore, OUTLINE_DARK)
    save(ore, "iron_ore", ITEMS)

    hide = new(16, 16)
    for y in range(3, 14):
        w = 6 - abs(y - 8) // 2
        rect(hide, 8 - w, y, 7 + w, y, hexc("e8e4d8"))
    for x, y in ((3, 3), (12, 3), (3, 13), (12, 13)):
        put(hide, x, y, hexc("e8e4d8"))
    rect(hide, 6, 6, 9, 9, hexc("d0c8b4"))
    outline(hide, OUTLINE_DARK)
    save(hide, "goat_hide", ITEMS)

    feather = new(16, 16)
    line(feather, 3, 14, 12, 2, hexc("8a7a5a"))
    for i in range(9):
        x, y = 4 + i, 12 - int(i * 1.2)
        put(feather, x - 1, y - 1, FEATHER[2])
        put(feather, x - 2, y, FEATHER[1])
        put(feather, x + 1, y + 1, STORM[1] if i > 5 else FEATHER[3])
    outline(feather, OUTLINE_DARK)
    save(feather, "storm_feather", ITEMS)


def make_all():
    os.makedirs(MOUNT, exist_ok=True)
    for v in range(3):
        save(cliff_wall(v), "wall_%d" % v)
        save(iron_ore(v), "iron_ore_%d" % v)
    save(wall_end("left"), "wall_end_l")
    save(wall_end("right"), "wall_end_r")
    save(rim("left"), "rim_l")
    save(rim("right"), "rim_r")
    save(rim("back"), "rim_back")
    save(ramp(), "ramp")
    for v in range(3):
        save(peak(v), "peak_%d" % v)
    for v in range(2):
        save(dead_tree(v), "dead_tree_%d" % v)
        save(stilt_hut(v), "stilt_hut_%d" % v)
        save(rock_pillar_nest(v), "pillar_nest_%d" % v)
    save(mountain_decor(), "decor")
    make_goat()
    make_eagle()
    make_birdmen()
    make_eagle_boss()
    save(perch_pole(), "perch_pole")
    save(eagle_totem(), "eagle_totem")
    save(egg_nest(), "egg_nest")
    save(bone_pile(), "bone_pile")
    save(cairn(), "cairn")
    save(wind_chime(), "wind_chime")
    save(storm_rod(), "storm_rod")
    save(aerie(), "aerie")
    item_icons()
