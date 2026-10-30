"""Generuje grafiki pixel art dla gry (kafelki, drzewa, dekoracje, postać).

Uruchom:  python tools/generate_art.py
Wynik trafia do katalogu assets/.
"""
import math
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets")


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


CLEAR = (0, 0, 0, 0)

# --- Paleta ---
GRASS = [hexc("2f5a28"), hexc("3e7330"), hexc("4a8236"), hexc("5a9a42"), hexc("6aab4c")]
LEAF = [hexc("173a22"), hexc("1f4d2a"), hexc("2f6b34"), hexc("4b8f3f"), hexc("6fb04a")]
PINE = [hexc("102c22"), hexc("17402d"), hexc("215a3a"), hexc("2f7547"), hexc("4a9455")]
BARK = [hexc("3a2215"), hexc("4e2f1b"), hexc("6b4226"), hexc("8a5a34")]
STONE = [hexc("3d3f4f"), hexc("5b5e70"), hexc("7d8192"), hexc("a3a7b5")]
OUTLINE_LEAF = hexc("0e2416")
OUTLINE_DARK = hexc("1a1c2c")
SHADOW = (10, 20, 10, 80)


def new(w, h):
    return Image.new("RGBA", (w, h), CLEAR)


def put(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def rect(img, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(img, x, y, c)


def outline(img, color):
    """Dodaje 1px obrys wokół nieprzezroczystych pikseli."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and src.getpixel((nx, ny))[3] > 200:
                    img.putpixel((x, y), color)
                    break


def shadow_ellipse(img, cx, cy, rx, ry):
    """Cień rysowany tylko na pustych pikselach."""
    for y in range(img.height):
        for x in range(img.width):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1 and img.getpixel((x, y))[3] == 0:
                img.putpixel((x, y), SHADOW)


def shaded_blob(img, circles, palette, light=(-0.6, -0.8), rng=None, speckle=0.12):
    """Wypełnia sumę okręgów, cieniując względem kierunku światła."""
    rng = rng or random.Random(1)
    xs = [c[0] for c in circles]
    ys = [c[1] for c in circles]
    cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
    for y in range(img.height):
        for x in range(img.width):
            best = None
            for (ox, oy, r) in circles:
                d = math.hypot(x + 0.5 - ox, y + 0.5 - oy)
                if d <= r:
                    # lokalna normalna względem okręgu + globalna
                    nx, ny = (x + 0.5 - ox) / r, (y + 0.5 - oy) / r
                    v = -(nx * light[0] + ny * light[1]) * 0.6
                    gx, gy = (x - cx) / 14, (y - cy) / 14
                    v += -(gx * light[0] + gy * light[1]) * 0.5
                    best = v if best is None else max(best, v)
            if best is None:
                continue
            best += rng.uniform(-speckle, speckle)
            n = len(palette)
            idx = int((best + 1) / 2 * n)
            idx = max(1, min(n - 1, idx))
            img.putpixel((x, y), palette[idx])


# ---------------------------------------------------------------- kafelki
def grass_tile(rng, variant):
    img = new(16, 16)
    for y in range(16):
        for x in range(16):
            r = rng.random()
            c = GRASS[2]
            if r < 0.18:
                c = GRASS[1]
            elif r < 0.30:
                c = GRASS[3]
            if variant == "dark" and r < 0.3:
                c = GRASS[1] if r < 0.26 else GRASS[0]
            img.putpixel((x, y), c)
    blades = {"plain": 3, "blades": 7, "dark": 4, "flowers": 3, "light": 5}[variant]
    for _ in range(blades):
        x, y = rng.randrange(1, 15), rng.randrange(2, 15)
        put(img, x, y, GRASS[0])
        put(img, x, y - 1, GRASS[4] if variant != "dark" else GRASS[2])
        if rng.random() < 0.5:
            put(img, x + 1, y - 1, GRASS[3])
    if variant == "light":
        for _ in range(14):
            put(img, rng.randrange(16), rng.randrange(16), GRASS[3])
    if variant == "flowers":
        cols = [hexc("f2f2e6"), hexc("f2c94c"), hexc("e57373")]
        for _ in range(3):
            x, y = rng.randrange(1, 15), rng.randrange(1, 15)
            c = rng.choice(cols)
            put(img, x, y, c)
            put(img, x + 1, y + 1, GRASS[0])
    return img


def make_tiles():
    rng = random.Random(42)
    variants = ["plain", "plain", "blades", "light", "flowers", "dark", "dark", "blades"]
    sheet = new(16 * 4, 16 * 8)
    for i, v in enumerate(variants):
        sheet.paste(grass_tile(rng, v), ((i % 4) * 16, (i // 4) * 16))
    # trzeci rząd: ubita ziemia i wydeptana trawa (osada)
    for i, mix in enumerate((1.0, 1.0, 0.55, 0.2)):
        sheet.paste(dirt_tile(rng, mix), (i * 16, 32))
    # czwarty rząd: głęboka woda (rzeka) i płycizna (rozlewisko), piąty: błoto i podmokły brzeg
    import swamp_art
    for i, tile in enumerate(swamp_art.water_tiles(rng) + swamp_art.mud_tiles(rng)):
        sheet.paste(tile, ((i % 4) * 16, 48 + (i // 4) * 16))
    # szósty i siódmy rząd: góry (alpejska trawa, skała, piarg, jasna skała)
    import mountain_art
    for i, tile in enumerate(mountain_art.ground_tiles(rng)):
        sheet.paste(tile, ((i % 4) * 16, 80 + (i // 4) * 16))
    # ósmy rząd: Prastary Las (ciemna trawa, opadłe liście, mech, ziemia z korzeniami)
    import ancient_art
    for i, tile in enumerate(ancient_art.ground_tiles(rng)):
        sheet.paste(tile, (i * 16, 112))
    sheet.save(os.path.join(OUT, "tiles.png"))


def dirt_tile(rng, dirt_amount):
    """dirt_amount: 1.0 = sama ziemia, mniej = trawa przetarta ziemią."""
    dirt = [hexc("6e5234"), hexc("8a6a44"), hexc("9c7b52"), hexc("b08c60")]
    img = new(16, 16)
    for y in range(16):
        for x in range(16):
            if rng.random() < dirt_amount:
                r = rng.random()
                c = dirt[1] if r < 0.6 else dirt[2] if r < 0.85 else dirt[0]
            else:
                c = GRASS[2] if rng.random() < 0.7 else GRASS[3]
            img.putpixel((x, y), c)
    for _ in range(3 if dirt_amount > 0.5 else 1):  # kamyczki
        x, y = rng.randrange(1, 15), rng.randrange(1, 15)
        put(img, x, y, dirt[3])
        put(img, x, y + 1, dirt[0])
    return img


# ---------------------------------------------------------------- drzewa
def make_oak(seed):
    rng = random.Random(seed)
    img = new(32, 40)
    # pień
    rect(img, 13, 24, 18, 35, BARK[2])
    rect(img, 13, 24, 13, 35, BARK[3])
    rect(img, 17, 24, 18, 35, BARK[1])
    rect(img, 12, 34, 19, 35, BARK[1])
    put(img, 15, 29, BARK[0])
    put(img, 16, 31, BARK[0])
    circles = [(16, 13, 11), (9, 17, 7), (23, 17, 7), (16, 21, 7), (11, 9, 6), (21, 9, 6)]
    circles = [(x + rng.uniform(-1, 1), y + rng.uniform(-1, 1), r) for x, y, r in circles]
    canopy = new(32, 40)
    shaded_blob(canopy, circles, LEAF, rng=rng, speckle=0.18)
    img.alpha_composite(canopy)
    # kilka jasnych listków
    for _ in range(10):
        x, y = rng.randrange(6, 20), rng.randrange(4, 14)
        if img.getpixel((x, y))[3]:
            put(img, x, y, LEAF[4])
    outline(img, OUTLINE_LEAF)
    shadow_ellipse(img, 16, 36, 11, 3.5)
    return img


def make_pine(seed):
    rng = random.Random(seed)
    img = new(24, 44)
    rect(img, 10, 32, 13, 39, BARK[2])
    rect(img, 12, 32, 13, 39, BARK[1])
    layers = [(4, 16, 2), (10, 22, 5), (16, 28, 8), (22, 34, 11)]  # (góra, dół, połowa szerokości)
    for top, bottom, half in layers:
        for y in range(top, bottom + 1):
            t = (y - top) / max(1, bottom - top)
            w = int(1 + t * half)
            for x in range(12 - w, 12 + w):
                v = -((x - 12) / (half + 1)) * 0.7 - (t - 0.5) * 0.6 + rng.uniform(-0.2, 0.2)
                idx = max(1, min(4, int((v + 1) / 2 * 5)))
                img.putpixel((x, y), PINE[idx])
    outline(img, OUTLINE_LEAF)
    shadow_ellipse(img, 12, 40, 8, 3)
    return img


def make_rock():
    rng = random.Random(7)
    img = new(16, 16)
    canopy = new(16, 16)
    shaded_blob(canopy, [(8, 9, 5.5), (6, 10, 4), (10.5, 10, 4)], STONE, rng=rng, speckle=0.1)
    img.alpha_composite(canopy)
    put(img, 6, 7, STONE[3])
    put(img, 7, 7, STONE[3])
    for y in range(11, 16):
        for x in range(16):
            if img.getpixel((x, y))[3] and y >= 13:
                put(img, x, y, STONE[1])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 14.5, 7, 2)
    return img


def make_bush():
    rng = random.Random(11)
    img = new(16, 16)
    canopy = new(16, 16)
    shaded_blob(canopy, [(8, 8, 5.5), (4.5, 10, 4), (11.5, 10, 4)], LEAF, rng=rng, speckle=0.2)
    img.alpha_composite(canopy)
    for x, y in ((5, 8), (9, 6), (11, 9)):
        put(img, x, y, hexc("d94f4f"))  # jagody
    outline(img, OUTLINE_LEAF)
    shadow_ellipse(img, 8, 14.5, 7, 2)
    return img


def make_stump():
    img = new(16, 16)
    rect(img, 4, 7, 11, 13, BARK[2])
    rect(img, 4, 7, 4, 13, BARK[3])
    rect(img, 10, 7, 11, 13, BARK[1])
    rect(img, 3, 12, 12, 13, BARK[1])
    rect(img, 5, 5, 10, 7, hexc("c89a64"))
    rect(img, 6, 6, 9, 6, hexc("a87a48"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 14.5, 7, 2)
    return img


# ---------------------------------------------------------------- dekoracje (bez kolizji)
def make_deco():
    sheet = new(16 * 8, 16)
    rng = random.Random(3)

    def flowers(col, center):
        img = new(16, 16)
        for _ in range(3):
            x, y = rng.randrange(3, 12), rng.randrange(5, 12)
            put(img, x, y + 1, GRASS[0])
            put(img, x, y + 2, GRASS[0])
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                put(img, x + dx, y + dy, col)
            put(img, x, y, center)
        return img

    def tuft():
        img = new(16, 16)
        for x in range(4, 12):
            h = rng.randrange(3, 7)
            for y in range(13 - h, 13):
                put(img, x, y, GRASS[3] if y < 13 - h + 2 else GRASS[1])
        outline(img, GRASS[0])
        return img

    def mushroom():
        img = new(16, 16)
        rect(img, 7, 9, 8, 12, hexc("efe6d2"))
        rect(img, 4, 6, 11, 8, hexc("c0392b"))
        rect(img, 5, 5, 10, 5, hexc("c0392b"))
        put(img, 6, 6, hexc("ffffff"))
        put(img, 9, 7, hexc("ffffff"))
        outline(img, OUTLINE_DARK)
        return img

    def pebbles():
        img = new(16, 16)
        for x, y in ((4, 10), (9, 8), (11, 12), (6, 13)):
            rect(img, x, y, x + 1, y, STONE[2])
            put(img, x, y + 1, STONE[1])
            put(img, x + 1, y + 1, STONE[1])
        return img

    def fern():
        img = new(16, 16)
        for ang in (-1.0, -0.4, 0.4, 1.0):
            for t in range(7):
                x = 8 + math.sin(ang) * t
                y = 13 - math.cos(ang) * t * 0.9
                put(img, int(x), int(y), LEAF[3] if t > 3 else LEAF[2])
                if t % 2 == 0:
                    put(img, int(x) + 1, int(y), LEAF[2])
        outline(img, LEAF[0])
        return img

    items = [
        flowers(hexc("f2f2e6"), hexc("f2c94c")),
        flowers(hexc("e57373"), hexc("f2c94c")),
        flowers(hexc("7fa8e0"), hexc("f2f2e6")),
        tuft(),
        mushroom(),
        pebbles(),
        fern(),
        tuft(),
    ]
    for i, it in enumerate(items):
        sheet.paste(it, (i * 16, 0))
    sheet.save(os.path.join(OUT, "deco.png"))


# ---------------------------------------------------------------- postać gracza
SKIN = hexc("f4c29a")
SKIN_D = hexc("d08f6a")
HAIR = hexc("8a4b2a")
HAIR_D = hexc("5c2e1a")
TUNIC = hexc("3b7dd8")
TUNIC_D = hexc("2a5aa8")
TUNIC_L = hexc("5d9cf0")
BELT = hexc("6b3e1f")
BUCKLE = hexc("f2c94c")
PANTS = hexc("4a4e6d")
BOOTS = hexc("4a2f1d")
EYE = hexc("1a1c2c")
CAPE = hexc("b33a3a")
CAPE_D = hexc("7d2626")


HERO = {
    "skin": SKIN, "skin_d": SKIN_D, "hair": HAIR, "hair_d": HAIR_D,
    "tunic": TUNIC, "tunic_d": TUNIC_D, "tunic_l": TUNIC_L, "belt": BELT, "buckle": BUCKLE,
    "pants": PANTS, "boots": BOOTS, "cape": CAPE, "cape_d": CAPE_D,
}

# pozycja dłoni w klatkach pracy: 0 - zamach w górę, 1 - uderzenie, 2 - pół drogi, 3 - uderzenie
WORK_HANDS = {0: (11, 6), 1: (12, 15), 2: (12, 10), 3: (12, 15)}


def line(img, x0, y0, x1, y1, c):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        put(img, round(x0 + (x1 - x0) * i / steps), round(y0 + (y1 - y0) * i / steps), c)


def draw_tool(img, tool, frame, hx, hy):
    metal, metal_l, wood = STONE[2], STONE[3], BARK[2]
    if tool == "hammer":
        if frame == 0:
            line(img, hx, hy - 1, hx, hy - 3, wood)
            rect(img, hx - 1, hy - 5, hx + 1, hy - 4, metal)
            put(img, hx - 1, hy - 5, metal_l)
        elif frame == 2:
            line(img, hx + 1, hy - 1, hx + 2, hy - 2, wood)
            rect(img, hx + 2, hy - 4, hx + 3, hy - 3, metal)
        else:
            line(img, hx + 1, hy, hx + 2, hy, wood)
            rect(img, hx + 3, hy - 1, hx + 3, hy + 1, metal)
    elif tool == "sword":
        blade, hilt = STONE[3], hexc("e0a020")
        if frame == 0:  # zamach - ostrze w górze
            put(img, hx, hy + 1, hilt)
            line(img, hx, hy - 1, hx - 1, hy - 6, blade)
        else:  # cios - ostrze wysunięte przed siebie
            put(img, hx + 1, hy, hilt)
            line(img, hx + 2, hy, hx + 3, hy, blade)
    elif tool == "knife":
        if frame == 0:
            line(img, hx, hy - 1, hx, hy - 2, metal_l)
        else:
            line(img, hx + 1, hy, hx + 2, hy, metal_l)


def person_frame(direction, frame, p=None):
    """direction: 'down' | 'up' | 'side' (patrzy w prawo) | 'work' (z boku, z narzędziem);
    frame 0..3. p - paleta i dodatki postaci (domyślnie bohater)."""
    p = p or HERO
    img = new(16, 24)
    work = direction == "work"
    work_frame = frame
    if work:
        direction, frame = "side", 0
    bob = 1 if frame in (1, 3) else 0
    o = bob  # przesunięcie tułowia w dół przy kroku

    # --- nogi
    if direction in ("down", "up"):
        lift_l = 2 if frame == 1 else 0
        lift_r = 2 if frame == 3 else 0
        rect(img, 5, 18, 7, 21 - lift_l, p["pants"])
        rect(img, 8, 18, 10, 21 - lift_r, p["pants"])
        rect(img, 5, 21 - lift_l, 7, 22 - lift_l, p["boots"])
        rect(img, 8, 21 - lift_r, 10, 22 - lift_r, p["boots"])
    else:
        step = {0: 0, 1: 2, 2: 0, 3: -2}[frame]
        # tylna noga (ciemniejsza)
        rect(img, 7 - step, 18, 8 - step, 21, p["pants"])
        rect(img, 7 - step, 21, 9 - step, 22, p["boots"])
        rect(img, 7 + step, 18, 8 + step, 21, p["pants"])
        rect(img, 7 + step, 21, 9 + step, 22, p["boots"])

    # --- peleryna (widoczna od tyłu i z boku)
    if p.get("cape"):
        if direction == "up":
            rect(img, 4, 11 + o, 11, 19 + o, p["cape"])
            rect(img, 4, 18 + o, 11, 19 + o, p["cape_d"])
        elif direction == "side":
            rect(img, 3, 11 + o, 5, 18 + o, p["cape"])
            rect(img, 3, 17 + o, 5, 18 + o, p["cape_d"])

    # --- tułów
    if direction == "side":
        rect(img, 5, 11 + o, 10, 18 + o, p["tunic"])
        rect(img, 5, 17 + o, 10, 18 + o, p["tunic_d"])
        rect(img, 5, 16 + o, 10, 16 + o, p["belt"])
    elif direction == "down":
        rect(img, 4, 11 + o, 11, 18 + o, p["tunic"])
        rect(img, 4, 11 + o, 4, 18 + o, p["tunic_d"])
        rect(img, 11, 11 + o, 11, 18 + o, p["tunic_d"])
        rect(img, 7, 11 + o, 8, 13 + o, p["tunic_l"])
        rect(img, 4, 16 + o, 11, 16 + o, p["belt"])
        rect(img, 7, 16 + o, 8, 16 + o, p["buckle"])
    elif p.get("cape"):  # up - tułów częściowo zakryty peleryną
        rect(img, 4, 11 + o, 11, 12 + o, p["tunic"])
    else:
        rect(img, 4, 11 + o, 11, 18 + o, p["tunic"])
        rect(img, 4, 17 + o, 11, 18 + o, p["tunic_d"])
        rect(img, 4, 16 + o, 11, 16 + o, p["belt"])

    if p.get("apron"):
        if direction == "down":
            rect(img, 5, 12 + o, 10, 18 + o, p["apron"])
        elif direction == "side":
            rect(img, 9, 12 + o, 10, 18 + o, p["apron"])

    # --- ręce
    swing = {0: 0, 1: 1, 2: 0, 3: -1}[frame]
    if work:
        hx, hy = WORK_HANDS[work_frame]
        line(img, 8, 12, hx, hy, p["tunic_d"])
        line(img, 7, 12, hx - 1, hy, p["tunic_d"])
        put(img, hx, hy, p["skin"])
        draw_tool(img, p.get("tool"), work_frame, hx, hy)
    elif direction in ("down", "up"):
        rect(img, 2, 12 + o + swing, 3, 16 + o + swing, p["tunic_d"])
        rect(img, 12, 12 + o - swing, 13, 16 + o - swing, p["tunic_d"])
        rect(img, 2, 17 + o + swing, 3, 17 + o + swing, p["skin"])
        rect(img, 12, 17 + o - swing, 13, 17 + o - swing, p["skin"])
    else:
        sx = 7 + swing * 2
        rect(img, sx, 12 + o, sx + 1, 16 + o, p["tunic_d"])
        rect(img, sx, 17 + o, sx + 1, 17 + o, p["skin"])

    # --- głowa
    if direction == "side":
        rect(img, 5, 3 + o, 11, 10 + o, p["skin"])
        rect(img, 5, 2 + o, 11, 5 + o, p["hair"])
        rect(img, 4, 3 + o, 7, 9 + o, p["hair"])
        rect(img, 4, 8 + o, 6, 9 + o, p["hair_d"])
        put(img, 9, 7 + o, EYE)
        put(img, 11, 9 + o, p["skin_d"])
        put(img, 12, 7 + o, p["skin"])  # nos
    else:
        rect(img, 4, 3 + o, 11, 10 + o, p["skin"])
        rect(img, 4, 10 + o, 11, 10 + o, p["skin_d"])
        if direction == "down":
            rect(img, 4, 2 + o, 11, 5 + o, p["hair"])
            rect(img, 4, 6 + o, 4, 8 + o, p["hair"])
            rect(img, 11, 6 + o, 11, 8 + o, p["hair"])
            rect(img, 5, 5 + o, 6, 5 + o, p["hair_d"])
            put(img, 6, 7 + o, EYE)
            put(img, 9, 7 + o, EYE)
            put(img, 5, 9 + o, hexc("e8a3a3"))
            put(img, 10, 9 + o, hexc("e8a3a3"))
        else:
            rect(img, 4, 2 + o, 11, 9 + o, p["hair"])
            rect(img, 5, 7 + o, 10, 9 + o, p["hair_d"])
        # zaokrąglenie czubka głowy
        img.putpixel((4, 2 + o), CLEAR)
        img.putpixel((11, 2 + o), CLEAR)

    # --- dodatki na głowie
    if p.get("beard"):
        if direction == "down":
            rect(img, 5, 9 + o, 10, 11 + o, p["beard"])
            put(img, 5, 9 + o, p["skin"])
            put(img, 10, 9 + o, p["skin"])
        elif direction == "side":
            rect(img, 9, 9 + o, 11, 11 + o, p["beard"])
    if p.get("hood"):
        hood, hood_d = p["hood"], p["hood_d"]
        if direction == "down":
            rect(img, 3, 1 + o, 12, 4 + o, hood)
            rect(img, 3, 5 + o, 4, 11 + o, hood_d)
            rect(img, 11, 5 + o, 12, 11 + o, hood_d)
        elif direction == "up":
            rect(img, 3, 1 + o, 12, 11 + o, hood)
            rect(img, 5, 8 + o, 10, 11 + o, hood_d)
        else:
            rect(img, 4, 1 + o, 11, 4 + o, hood)
            rect(img, 3, 3 + o, 7, 11 + o, hood_d)
    if p.get("helmet"):
        helmet, helmet_d = p["helmet"], p["helmet_d"]
        bottom = 8 if direction == "up" else 4
        rect(img, 4, 1 + o, 11, bottom + o, helmet)
        rect(img, 4, bottom + 1 + o, 11, bottom + 1 + o, helmet_d)
        put(img, 6, 2 + o, STONE[3])

    outline(img, OUTLINE_DARK)
    return img


def make_person_sheet(p, work=False):
    """Arkusz 4x3 (dół, góra, bok) albo 4x4 z wierszem pracy."""
    rows = ("down", "up", "side", "work") if work else ("down", "up", "side")
    sheet = new(16 * 4, 24 * len(rows))
    for row, d in enumerate(rows):
        for f in range(4):
            sheet.paste(person_frame(d, f, p), (f * 16, row * 24))
    return sheet


def make_player():
    make_person_sheet(HERO).save(os.path.join(OUT, "player.png"))


def make_shadow():
    img = new(12, 5)
    shadow_ellipse(img, 6, 2.5, 6, 2.5)
    for y in range(img.height):
        for x in range(img.width):
            if img.getpixel((x, y))[3]:
                img.putpixel((x, y), (0, 0, 0, 90))
    img.save(os.path.join(OUT, "shadow.png"))


# ---------------------------------------------------------------- gobliny
GOB = hexc("6aa84f")
GOB_D = hexc("4a7a35")
GOB_L = hexc("8cc26a")
RAG = hexc("7a5230")
RAG_D = hexc("5a3a20")
GEYE = hexc("f2d14c")


def goblin_frame(kind, f):
    """kind: 'walk' | 'sit' | 'windup' | 'strike'. Goblin patrzy w prawo."""
    img = new(16, 16)
    o = 0
    if kind == "walk":
        o = 1 if f in (1, 3) else 0
    elif kind == "sit":
        o = 3 + (1 if f == 1 else 0)

    # nogi (chodzenie / stanie)
    if kind != "sit":
        step = {0: 0, 1: -1, 2: 0, 3: 1}[f] if kind == "walk" else 0
        rect(img, 6 + step, 13, 7 + step, 15, GOB_D)
        rect(img, 9 - step, 13, 10 - step, 15, GOB_D)

    # tułów w łachmanach
    rect(img, 5, 9 + o, 10, min(13 + o, 14), RAG)
    rect(img, 5, min(13 + o, 14), 10, min(13 + o, 14), RAG_D)
    rect(img, 5, 11 + o, 10, 11 + o, RAG_D)

    if kind == "sit":  # skrzyżowane nogi
        rect(img, 4, 14, 11, 15, GOB_D)
        rect(img, 6, 14, 9, 14, GOB)

    # głowa + długie uszy
    rect(img, 4, 2 + o, 11, 8 + o, GOB)
    rect(img, 4, 8 + o, 11, 8 + o, GOB_D)
    rect(img, 5, 2 + o, 9, 2 + o, GOB_L)
    for x, y in ((12, 5), (13, 4), (14, 3), (3, 5), (2, 4), (1, 3)):
        put(img, x, y + o, GOB)
    put(img, 12, 4 + o, GOB_L)
    put(img, 3, 4 + o, GOB_L)
    put(img, 8, 5 + o, GEYE)
    put(img, 10, 5 + o, GEYE)
    put(img, 11, 6 + o, GOB_D)
    rect(img, 8, 7 + o, 10, 7 + o, OUTLINE_DARK)
    put(img, 9, 7 + o, hexc("f2f2e6"))

    # ręka z maczugą
    if kind in ("walk", "sit"):
        put(img, 11, 11 + o, GOB)
        rect(img, 12, 7 + o, 12, 11 + o, BARK[2])
        rect(img, 12, 4 + o, 13, 7 + o, BARK[3])
        put(img, 13, 6 + o, BARK[1])
    elif kind == "windup":
        rect(img, 10, 4, 11, 5, GOB)
        rect(img, 9, 1, 10, 3, BARK[2])
        rect(img, 6, 0, 9, 1, BARK[3])
    else:  # strike - maczuga z przodu
        put(img, 11, 10, GOB)
        rect(img, 12, 10, 12, 10, BARK[2])
        rect(img, 13, 9, 15, 11, BARK[3])
        put(img, 14, 11, BARK[1])

    outline(img, OUTLINE_DARK)
    return img


def make_goblin():
    sheet = new(16 * 4, 16 * 2)
    for f in range(4):
        sheet.paste(goblin_frame("walk", f), (f * 16, 0))
    for i, (kind, f) in enumerate((("sit", 0), ("sit", 1), ("windup", 0), ("strike", 0))):
        sheet.paste(goblin_frame(kind, f), (i * 16, 16))
    sheet.save(os.path.join(OUT, "goblin.png"))


# ---------------------------------------------------------------- obozowisko
def make_campfire():
    sheet = new(16 * 4, 16)
    flame_cols = [hexc("c0392b"), hexc("e67e22"), hexc("f5b041"), hexc("fdf2a6")]
    heights = [[3, 6, 8, 7, 5, 3], [4, 7, 6, 8, 4, 2], [2, 5, 8, 6, 6, 4], [3, 8, 7, 5, 7, 3]]
    for f in range(4):
        img = new(16, 16)
        # kamienie
        for x, y in ((2, 13), (4, 14), (7, 15), (10, 14), (12, 13), (3, 11), (12, 11)):
            rect(img, x, y, x + 1, y, STONE[2])
            put(img, x, y - 1, STONE[3])
        # polana
        rect(img, 4, 12, 11, 13, BARK[2])
        rect(img, 5, 11, 10, 11, BARK[3])
        put(img, 6, 12, BARK[0])
        put(img, 9, 12, BARK[0])
        # płomienie
        for i, h in enumerate(heights[f]):
            x = 5 + i
            for k in range(h):
                y = 11 - k
                t = k / max(1, h - 1)
                c = flame_cols[0] if t > 0.85 else flame_cols[1] if t > 0.5 else flame_cols[2]
                if 1 <= i <= 4 and k < h - 3:
                    c = flame_cols[3] if k < 2 else flame_cols[2]
                put(img, x, y, c)
        sheet.paste(img, (f * 16, 0))
    sheet.save(os.path.join(OUT, "campfire.png"))


def make_tent():
    img = new(32, 28)
    canvas, canvas_d, hole = hexc("c8a46e"), hexc("a9844f"), hexc("3a2a1a")
    for y in range(3, 26):
        t = (y - 3) / 22
        half = int(1 + t * 12.5)
        for x in range(16 - half, 16 + half):
            img.putpixel((x, y), canvas if x < 16 else canvas_d)
    for y in range(12, 26):
        half = int((y - 12) / 13 * 4.5)
        for x in range(16 - half, 16 + half):
            img.putpixel((x, y), hole)
    for y in range(6, 24, 4):  # łaty / szwy
        put(img, 9 + y // 4, y, canvas_d)
    rect(img, 16, 0, 16, 3, BARK[2])
    rect(img, 15, 0, 15, 0, hexc("b33a3a"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 16, 26, 14, 2)
    return img


# ---------------------------------------------------------------- broń i efekty
def make_sword():
    img = new(18, 9)
    rect(img, 1, 4, 4, 4, BARK[2])  # rękojeść
    put(img, 1, 4, hexc("f2c94c"))
    rect(img, 5, 1, 5, 7, hexc("f2c94c"))  # jelec
    rect(img, 6, 3, 15, 5, hexc("c9d1e0"))
    rect(img, 6, 3, 15, 3, hexc("f4f7fb"))
    rect(img, 6, 5, 15, 5, hexc("8b93a8"))
    put(img, 16, 4, hexc("c9d1e0"))
    outline(img, OUTLINE_DARK)
    img.save(os.path.join(OUT, "sword.png"))


def make_slash():
    """4 klatki cięcia po półksiężycu skierowanego w prawo (środek w 32,32)."""
    size, cx, cy, r_out = 64, 32, 32, 29
    frames = [(-80, 0, 1.0, 6), (-80, 80, 1.0, 8), (-80, 80, 0.65, 6), (0, 80, 0.35, 4)]
    sheet = new(size * 4, size)
    for i, (a0, a1, alpha, max_t) in enumerate(frames):
        img = new(size, size)
        for y in range(size):
            for x in range(size):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                r = math.hypot(dx, dy)
                ang = math.degrees(math.atan2(dy, dx))
                if not (a0 <= ang <= a1):
                    continue
                thick = 1 + max_t * (1 - abs(ang) / 80) ** 0.8
                if r_out - thick <= r <= r_out:
                    edge = r > r_out - 2
                    c = (255, 255, 255) if edge else (175, 220, 255)
                    img.putpixel((x, y), (*c, int(255 * alpha * (1 if edge else 0.8))))
        sheet.paste(img, (i * size, 0))
    sheet.save(os.path.join(OUT, "slash.png"))


def make_shrine():
    img = new(16, 24)
    rect(img, 2, 19, 13, 21, STONE[1])
    rect(img, 2, 19, 13, 19, STONE[2])
    rect(img, 5, 5, 10, 18, STONE[2])
    rect(img, 5, 5, 5, 18, STONE[3])
    rect(img, 10, 5, 10, 18, STONE[1])
    rect(img, 6, 3, 9, 4, STONE[2])
    rect(img, 7, 2, 8, 2, STONE[3])
    rune = hexc("5fd3ff")
    for x, y in ((7, 8), (8, 8), (7, 9), (7, 10), (8, 10), (8, 11), (7, 12), (8, 12), (7, 13)):
        put(img, x, y, rune)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 22, 7, 2)
    img.save(os.path.join(OUT, "shrine.png"))


# ---------------------------------------------------------------- przedmioty
def make_items():
    items_dir = os.path.join(OUT, "items")
    os.makedirs(items_dir, exist_ok=True)

    coin = new(10, 10)
    for y in range(10):
        for x in range(10):
            d = math.hypot(x + 0.5 - 5, y + 0.5 - 5)
            if d <= 4:
                coin.putpixel((x, y), hexc("c8962c") if d > 3 else hexc("f2c94c"))
    rect(coin, 4, 3, 4, 6, hexc("c8962c"))
    put(coin, 3, 3, hexc("fff3b0"))
    put(coin, 3, 4, hexc("fff3b0"))
    outline(coin, OUTLINE_DARK)
    coin.save(os.path.join(items_dir, "coin.png"))

    heart = new(14, 14)
    shape = [
        "..XXX...XXX...",
        ".XXXXX.XXXXX..",
        ".XXXXXXXXXXX..",
        ".XXXXXXXXXXX..",
        "..XXXXXXXXX...",
        "...XXXXXXX....",
        "....XXXXX.....",
        ".....XXX......",
        "......X.......",
    ]
    for y, row in enumerate(shape):
        for x, ch in enumerate(row):
            if ch == "X":
                heart.putpixel((x + 1, y + 2), hexc("8e1b2b") if x > 7 or y > 5 else hexc("b8283c"))
    for x, y in ((3, 3), (4, 3), (3, 4)):
        put(heart, x, y, hexc("e8606e"))
    for x, y in ((6, 5), (7, 6), (7, 7), (8, 8), (9, 5), (10, 4)):  # zielone żyłki
        put(heart, x, y, GOB)
    outline(heart, OUTLINE_DARK)
    heart.save(os.path.join(items_dir, "goblin_heart.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    import village_art  # osada: budynki, mieszkańcy, meble
    import item_art  # przedmioty do założenia, bronie i pociski
    import wild_art  # wilki, nory, wóz kupiecki
    import boss_art  # wódz goblinów, wilk alfa, wystrój leży
    import ui_art  # ikony przycisków interfejsu
    import settlement_art  # głazy, kamień, koszary, stajnia, kukły i inne rozbudowy osady
    import animal_art  # zwierzyna łowna: jeleń, sarna, dzik, zając i ich skóry
    import swamp_art  # rozlewiska: most, pałki wodne, namorzyny, lilie, drogowskaz, ikona kapliczki
    import frog_art  # żaboludzie, ich wódz i wioska w namorzynach
    import skill_art  # ikony umiejętności dodatkowych (Shift+LPM i dodatkowe ciosy)
    import legendary_art  # legendarne pierścienie z bossów
    import summon_art  # przedmioty przyzwania bossów (rzemiosło)
    import landmark_art  # chata mędrca i gildia poszukiwaczy przygód
    import mountain_art  # Wietrzne Turnie: skarpy, ruda, kozy, orły, ptakoludzie i ich wioska
    import drowned_art  # Topielcze Uroczysko w rozlewiskach: utopce, ogniki, topielice, Wodnik
    import ancient_art  # Prastary Las: drzewce i Leszy, pająki i ich Królowa, bestie i Bies
    village_art.make_all()
    item_art.make_all()
    wild_art.make_all()
    boss_art.make_all()
    ui_art.make_all()
    settlement_art.make_all()
    animal_art.make_all()
    swamp_art.make_all()
    frog_art.make_all()
    skill_art.make_all()
    legendary_art.make_all()
    summon_art.make_all()
    landmark_art.make_all()
    mountain_art.make_all()
    drowned_art.make_all()
    ancient_art.make_all()
    make_items()
    make_goblin()
    make_campfire()
    make_tent().save(os.path.join(OUT, "tent.png"))
    make_sword()
    make_slash()
    make_shrine()
    make_tiles()
    for i in range(3):
        make_oak(100 + i).save(os.path.join(OUT, f"tree_oak_{i}.png"))
    make_pine(200).save(os.path.join(OUT, "tree_pine.png"))
    make_rock().save(os.path.join(OUT, "rock.png"))
    make_bush().save(os.path.join(OUT, "bush.png"))
    make_stump().save(os.path.join(OUT, "stump.png"))
    make_deco()
    make_player()
    make_shadow()
    import pixellab_sheets  # grafiki z PixelLab (pixellab_src/) zastępują wersje Prastarego Lasu
    pixellab_sheets.main()
    import forest_sheets  # Gobliński Las z PixelLab: stworzenia i przejścia runa (rzędy za Prastarym Lasem)
    forest_sheets.main()
    import forest_props  # rekwizyty obozów i siedlisk, drzewa, krzewy, kamienie, ozdoby runa
    forest_props.main()
    import village_buildings  # budynki osady z PixelLab (dachy) i dopasowane do nich podłogi
    village_buildings.main()
    import village_props  # rekwizyty, ozdoby, palisada, stajnia i koń osady z PixelLab
    village_props.main()
    import village_life  # strefy osady (obóz uchodźców, rynek, zagroda), świnie i nutki z PixelLab
    village_life.main()
    import npc_sheets  # mieszkańcy osady z PixelLab (wielkości postaci gracza)
    npc_sheets.main()
    import region_sheets  # Rozlewiska, Wietrzne Turnie i satyrowie z PixelLab: stworzenia i przejścia runa
    region_sheets.main()
    import region_props  # rekwizyty rozlewisk i gór (podmieniane w miejscu dawnych grafik)
    region_props.main()
    import alpine_tiles  # podłoże i klify gór z zestawów Wang PixelLab 64 px (po region_props - nadpisuje klify)
    alpine_tiles.main()
    import forest_ground  # podłoże Goblińskiego Lasu z zestawów Wang PixelLab 64 px
    forest_ground.main()
    import zone_grounds  # podłoże Rozlewisk i Prastarego Lasu z zestawów Wang PixelLab 64 px
    zone_grounds.main()
    import swamp_v2  # rośliny brzegów, most i kładki Rozlewisk z PixelLab
    swamp_v2.main()
    import ancient_v2  # olbrzymie i wysokie drzewa oraz rekwizyty Prastarego Lasu z PixelLab
    ancient_v2.main()
    import menu_art  # tło menu ze świtem, tablica logo i kursor z PixelLab
    menu_art.main()
    import pixellab_items  # ikony przedmiotów 64 px, broń w ręku, ikony umiejętności i interfejsu z PixelLab (nadpisują)
    pixellab_items.build()
    import fields_art  # Pola Zbożowe: pasy zboża, kopce i nory czerwi
    fields_art.main()
    import fields_sheets  # Pola Zbożowe z PixelLab: rekwizyty, podłoże, koboldy, czerwie i ich sceny (na końcu - zmienia SRC modułów)
    fields_sheets.main()
    import cemetery_sheets  # Leśny Cmentarz z PixelLab: rekwizyty, podłoże, nieumarli i ich sceny
    cemetery_sheets.main()
    import boss_sheets  # Hydra i Gryf z PixelLab (obiekty z animacjami) i ich sceny
    boss_sheets.main()
    print("Zapisano grafiki do", OUT)


if __name__ == "__main__":
    main()
