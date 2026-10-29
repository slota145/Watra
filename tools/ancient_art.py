"""Prastary Las - kraina nad Goblińskim Lasem. Kafelki leśnego runa (dopisywane do tiles.png),
ogromne drzewa, prastare drzewa z twarzą (budzą drzewce), drzewce, Leszy i jego kamienny krąg
oplątany pnączami, świecące grzyby, pnie i paprocie; leże pająków (sieci, kokony, owinięte ofiary,
jaja), pająki, pajęczaki i Królowa Pająków; siedlisko bestii (drzewa z pazurami, rozorana ziemia,
złamane drzewa, czaszki na palach, krew), niedźwiedź-bestia, wilkołak i Bies. Do tego ikony łupów.
Wywoływane z generate_art.py.

Arkusze postaci mają układ jak goblin (4x2): 0-3 chód, 4-5 spoczynek, 6 zamach, 7 cios."""
import math
import os
import random

from generate_art import (BARK, LEAF, OUT, OUTLINE_DARK, OUTLINE_LEAF, hexc, line, new, outline, put, rect,
                          shaded_blob, shadow_ellipse)

ANCIENT = os.path.join(OUT, "ancient")
ITEMS = os.path.join(OUT, "items")
OLD_BARK = [hexc("2a1e16"), hexc("3e2e22"), hexc("564232"), hexc("705a44"), hexc("8a7458")]
DEEP_LEAF = [hexc("12301c"), hexc("1a4428"), hexc("245a32"), hexc("33703e"), hexc("48884a")]
MOSS = [hexc("2f5a24"), hexc("4a7a30"), hexc("6a9a3e"), hexc("8ab44e")]
GLOW = [hexc("1e5a6a"), hexc("2fa0b0"), hexc("6ae8f0"), hexc("d0fcff")]
STONE = [hexc("3a3c46"), hexc("565a66"), hexc("747a86"), hexc("969ca8")]
EYE_GREEN = hexc("b8ff6a")
EYE_RED = hexc("ff3a2a")
SILK = [hexc("a8a8b0"), hexc("d0d0d8"), hexc("f0f0f6")]
SPIDER = [hexc("16141c"), hexc("26222e"), hexc("3a3446"), hexc("8e2f25")]
BLOOD = [hexc("4a0e0e"), hexc("7a1414")]


def ellipse(img, cx, cy, rx, ry, color, shade=None):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                put(img, x, y, shade if shade is not None and dy > 0.45 else color)


def save(img, name, folder=ANCIENT):
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name + ".png"))


# ---------------------------------------------------------------- kafelki (rząd 7)
def _tile(rng, palette, weights, specks):
    img = new(16, 16)
    for y in range(16):
        for x in range(16):
            r = rng.random()
            acc = 0.0
            c = palette[-1]
            for col, wt in zip(palette, weights):
                acc += wt
                if r < acc:
                    c = col
                    break
            img.putpixel((x, y), c)
    for col, n in specks:
        for _ in range(n):
            put(img, rng.randrange(16), rng.randrange(16), col)
    return img


def ground_tiles(rng):
    """4 kafelki: ciemna trawa lasu, opadłe liście, mech, ziemia z korzeniami."""
    dark = _tile(rng, [hexc("1e3a1e"), hexc("284a26"), hexc("32582c")], [0.3, 0.45, 0.25], [(hexc("40683a"), 10)])
    leaves = _tile(rng, [hexc("3a3a1e"), hexc("4a4426"), hexc("2e3a1e")], [0.35, 0.35, 0.3],
                   [(hexc("8a5a2a"), 10), (hexc("a8742e"), 6), (hexc("6a3a1e"), 6)])
    moss = _tile(rng, [MOSS[0], MOSS[1], MOSS[2]], [0.3, 0.45, 0.25], [(MOSS[3], 8)])
    roots = _tile(rng, [hexc("2e2618"), hexc("3a3020"), hexc("28361e")], [0.35, 0.35, 0.3], [])
    for _ in range(2):
        x, y = rng.randrange(0, 8), rng.randrange(2, 14)
        for k in range(rng.randint(5, 10)):
            put(roots, x + k, y + int(math.sin(k * 0.8) * 1.5), OLD_BARK[2])
    return [dark, leaves, moss, roots]


# ---------------------------------------------------------------- drzewa i las
def giant_tree(variant):
    """Ogromne drzewo (112x140): szeroki pień z korzeniami i wielopiętrowa, ciemna korona."""
    rng = random.Random(400 + variant)
    W, H = 112, 140
    img = new(W, H)
    # korzenie i pień
    for y in range(70, H - 2):
        t = (y - 70) / (H - 72)
        half = int(9 + t * t * 18)
        for x in range(W // 2 - half, W // 2 + half):
            c = OLD_BARK[2] if (x + y // 3) % 7 else OLD_BARK[1]
            if x < W // 2 - half + 3:
                c = OLD_BARK[3]
            elif x > W // 2 + half - 4:
                c = OLD_BARK[0]
            put(img, x, y, c)
    for k in range(4):  # mech na pniu
        x0, y0 = W // 2 - 6 + k * 3, 90 + k * 9
        for d in range(6):
            put(img, x0 + d % 3, y0 + d, MOSS[1 + d % 2])
    # korona z kilku nachodzących na siebie kul
    circles = [(W // 2, 46, 40), (W // 2 - 26, 58, 26), (W // 2 + 27, 56, 26), (W // 2 - 10, 26, 28), (W // 2 + 14, 30, 26)]
    canopy = new(W, H)
    shaded_blob(canopy, circles, DEEP_LEAF, rng=rng, speckle=0.18)
    img.alpha_composite(canopy)
    for _ in range(60):  # pojedyncze jaśniejsze liście
        x, y = rng.randrange(10, W - 10), rng.randrange(6, 88)
        if img.getpixel((x, y))[3] and rng.random() < 0.5:
            put(img, x, y, DEEP_LEAF[4])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, W // 2, H - 2, 30, 4)
    return img


def ancient_tree(state):
    """Prastare drzewo z twarzą w korze (80x104): 0 - uśpione, 1 - przebudzone (świecące oczy i paszcza)."""
    rng = random.Random(420)
    W, H = 80, 104
    img = new(W, H)
    for y in range(44, H - 2):
        t = (y - 44) / (H - 46)
        half = int(13 + t * t * 14 + math.sin(y * 0.3) * 1.5)
        for x in range(W // 2 - half, W // 2 + half):
            c = OLD_BARK[2] if (x * 2 + y) % 9 else OLD_BARK[1]
            if x < W // 2 - half + 3:
                c = OLD_BARK[3]
            elif x > W // 2 + half - 4:
                c = OLD_BARK[0]
            put(img, x, y, c)
    # twarz w korze
    fy = 64
    for ex in (W // 2 - 8, W // 2 + 5):
        ellipse(img, ex, fy, 3.2, 2.2, OLD_BARK[0])
        if state == 1:
            ellipse(img, ex, fy, 2, 1.2, EYE_GREEN)
    ellipse(img, W // 2, fy + 12, 6, 4, OLD_BARK[0])
    if state == 1:
        ellipse(img, W // 2, fy + 12, 4, 2.5, hexc("4ac040"))
    line(img, W // 2 - 12, fy - 5, W // 2 - 4, fy - 3, OLD_BARK[0])  # brwi
    line(img, W // 2 + 12, fy - 5, W // 2 + 2, fy - 3, OLD_BARK[0])
    # pokręcone gałęzie i rzadka, stara korona z mchem
    for (x0, y0, x1, y1) in ((W // 2 - 6, 50, 8, 22), (W // 2 + 6, 48, W - 8, 18), (W // 2, 46, W // 2 + 4, 6)):
        line(img, x0, y0, x1, y1, OLD_BARK[1])
        line(img, x0 + 1, y0, x1 + 1, y1, OLD_BARK[2])
    canopy = new(W, H)
    shaded_blob(canopy, [(18, 22, 16), (W - 18, 18, 16), (W // 2 + 2, 12, 15)], DEEP_LEAF, rng=rng, speckle=0.2)
    img.alpha_composite(canopy)
    for k in range(10):  # brody mchu
        x = rng.randrange(8, W - 8)
        y = rng.randrange(26, 36)
        for d in range(rng.randint(4, 10)):
            put(img, x, y + d, MOSS[1 + d % 2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, W // 2, H - 2, 24, 3)
    return img


def ancient_stump():
    """Rozbite prastare drzewo: poszarpany pień z drzazgami i zgasłą twarzą."""
    img = new(64, 40)
    for y in range(8, 38):
        half = 14 + (y - 8) // 3
        for x in range(32 - half, 32 + half):
            put(img, x, y, OLD_BARK[2] if (x + y) % 6 else OLD_BARK[1])
    for x in range(32 - 14, 32 + 14, 3):
        for d in range(random.Random(x).randint(2, 8)):
            put(img, x, 8 - d, OLD_BARK[3])
    ellipse(img, 26, 24, 2.5, 1.6, OLD_BARK[0])
    ellipse(img, 37, 24, 2.5, 1.6, OLD_BARK[0])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 32, 38, 22, 2)
    return img


def glow_shroom():
    """Kępa świecących grzybów (2 klatki 24x18): przygaszone i rozświetlone."""
    sheet = new(24 * 2, 18)
    for f in range(2):
        img = new(24, 18)
        for cx, cy, r in ((7, 9, 4.5), (15, 7, 5.5), (19, 12, 3.2), (11, 13, 3)):
            rect(img, cx - 1, cy, cx, cy + int(r) + 3, hexc("c8d8d0") if f else hexc("8aa0a0"))
            for y in range(int(cy - r), cy + 1):
                for x in range(int(cx - r), int(cx + r) + 1):
                    d = math.hypot((x - cx) / r, (y - cy) / (r * 0.8))
                    if d <= 1:
                        c = GLOW[2] if f and d < 0.6 else GLOW[1] if f else GLOW[0] if d > 0.6 else GLOW[1]
                        put(img, x, y, c)
            put(img, cx - 1, int(cy - r / 2), GLOW[3] if f else GLOW[2])
            put(img, cx + 1, int(cy - r / 3), GLOW[3] if f else GLOW[1])
        outline(img, OUTLINE_DARK)
        sheet.paste(img, (f * 24, 0))
    return sheet


def menhir(variant):
    """Kamień kręgu (20x38) oplątany pnączami, z runą (2 klatki: runa ciemna / świecąca)."""
    rng = random.Random(440 + variant)
    sheet = new(20 * 2, 38)
    for f in range(2):
        img = new(20, 38)
        for y in range(3, 36):
            half = 6 + (y > 10) + (y > 28) - (y < 6)
            for x in range(10 - half, 10 + half):
                put(img, x, y, STONE[2] if x < 9 else STONE[1])
        rect(img, 5, 3, 13, 4, STONE[3])
        rune = [(9, 12), (9, 13), (9, 14), (8, 15), (10, 15), (9, 16), (9, 17), (8, 18), (10, 18)]
        for x, y in rune:
            put(img, x, y, EYE_GREEN if f else STONE[0])
        x = 4 + variant
        for y in range(36, 4, -1):  # pnącze wspinające się po kamieniu
            x += rng.choice((-1, 0, 1))
            x = max(3, min(16, x))
            put(img, x, y, MOSS[1])
            if rng.random() < 0.3:
                put(img, x + rng.choice((-1, 1)), y, MOSS[3])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 10, 37, 7, 1.2)
        sheet.paste(img, (f * 20, 0))
    return sheet


def altar_stump():
    """Ołtarz Leszego: omszały pień z darami - jagody, poroże, świece z żywicy."""
    img = new(44, 30)
    for y in range(8, 28):
        half = 14 + (y - 8) // 4
        for x in range(22 - half, 22 + half):
            put(img, x, y, OLD_BARK[2] if y > 10 else OLD_BARK[3])
    for x in range(10, 34):
        put(img, x, 8, MOSS[2])
        if x % 3 == 0:
            put(img, x, 9, MOSS[1])
    for x, y in ((14, 6), (16, 5), (18, 6)):  # jagody
        put(img, x, y, hexc("c0392b"))
    line(img, 24, 7, 30, 2, hexc("d8ccb0"))  # poroże
    line(img, 27, 4, 29, 0, hexc("d8ccb0"))
    for cx in (11, 33):  # świece z żywicy
        rect(img, cx, 3, cx + 1, 7, hexc("e0a030"))
        put(img, cx, 2, hexc("fff3b0"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 22, 28, 18, 2)
    return img


def fallen_log():
    img = new(70, 22)
    for y in range(4, 18):
        for x in range(4, 64):
            c = OLD_BARK[2] if y > 6 else OLD_BARK[3]
            if y > 15:
                c = OLD_BARK[1]
            put(img, x, y, c)
    ellipse(img, 63, 11, 5, 7, OLD_BARK[3])
    ellipse(img, 63, 11, 3, 5, hexc("8a6a44"))
    for x in range(8, 58, 3):
        put(img, x, 4, MOSS[2])
        if x % 6 == 0:
            put(img, x, 5, MOSS[1])
    for x, y in ((20, 8), (40, 10)):
        put(img, x, y, hexc("c8b060"))
        put(img, x + 1, y, hexc("e8d080"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 35, 20, 30, 2)
    return img


def forest_decor():
    """8 klatek (16x16): paproć x2, bluszcz, opadłe liście, grzybek, omszały kamień, korzeń, jagody."""
    sheet = new(16 * 8, 16)
    rng = random.Random(9)
    for f in range(8):
        img = new(16, 16)
        if f < 2:
            for k in range(5):
                a = math.pi * (0.15 + k / 4 * 0.7)
                for d in range(6 + f):
                    put(img, int(8 + math.cos(a) * d * (1 if k % 2 else -1)), int(14 - math.sin(a) * d), DEEP_LEAF[3 - (d > 4)])
        elif f == 2:
            for k in range(8):
                put(img, 4 + k, 10 + int(math.sin(k) * 2), DEEP_LEAF[3])
                put(img, 4 + k, 9 + int(math.sin(k) * 2), DEEP_LEAF[4] if k % 2 else DEEP_LEAF[2])
        elif f == 3:
            for _ in range(6):
                put(img, rng.randrange(3, 13), rng.randrange(8, 14), rng.choice([hexc("8a5a2a"), hexc("a8742e"), hexc("6a3a1e")]))
        elif f == 4:
            rect(img, 7, 10, 8, 14, hexc("e8e0d0"))
            ellipse(img, 7.5, 9, 3.5, 2, hexc("c0392b"))
            put(img, 6, 8, hexc("ffffff"))
        elif f == 5:
            ellipse(img, 8, 11, 5, 3, STONE[2], STONE[1])
            for x in range(4, 12):
                put(img, x, 8 + (x % 2), MOSS[2])
        elif f == 6:
            line(img, 2, 12, 13, 10, OLD_BARK[2])
            line(img, 2, 13, 13, 11, OLD_BARK[1])
        else:
            for x, y in ((6, 10), (8, 9), (9, 11), (7, 12)):
                put(img, x, y, hexc("3a3a8a"))
            put(img, 8, 7, DEEP_LEAF[3])
        sheet.paste(img, (f * 16, 0))
    return sheet


# ---------------------------------------------------------------- leże pająków
def web(size, seed):
    """Pajęczyna (płasko na ziemi albo między drzewami): szprychy i spirala."""
    rng = random.Random(seed)
    img = new(size, size)
    c = size / 2
    spokes = 9
    for k in range(spokes):
        a = math.tau * k / spokes + rng.uniform(-0.1, 0.1)
        for d in range(int(c)):
            put(img, int(c + math.cos(a) * d), int(c + math.sin(a) * d), (*SILK[2][:3], 150))
    for ring in range(4, int(c), max(3, int(c) // 6)):
        for k in range(spokes * 6):
            a = math.tau * k / (spokes * 6)
            r = ring * (0.92 + 0.08 * math.sin(k * 1.7))
            put(img, int(c + math.cos(a) * r), int(c + math.sin(a) * r), (*SILK[1][:3], 120))
    return img


def cocoon():
    """Kokon (2 klatki 18x26): cały i rozerwany."""
    sheet = new(18 * 2, 26)
    for f in range(2):
        img = new(18, 26)
        if f == 0:
            ellipse(img, 9, 13, 6, 10, SILK[1], SILK[0])
            for y in range(4, 23, 3):
                line(img, 4, y, 14, y + 2, SILK[0])
            line(img, 9, 0, 9, 3, SILK[2])
        else:
            for x, y, r in ((5, 20, 4), (13, 21, 4)):
                ellipse(img, x, y, r, 3, SILK[0])
            for k in range(6):
                line(img, 9, 22, 3 + k * 2, 12 + (k % 3) * 2, SILK[1])
            ellipse(img, 9, 21, 3, 2, hexc("3a6a2a"))  # resztki jaja
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 9, 25, 6, 1)
        sheet.paste(img, (f * 18, 0))
    return sheet


def wrapped_victim():
    """Ofiara owinięta w sieć (goblin) - tylko stopy i ręka wystają."""
    img = new(32, 14)
    ellipse(img, 16, 8, 13, 5, SILK[1], SILK[0])
    for x in range(5, 28, 3):
        line(img, x, 4, x + 2, 12, SILK[0])
    rect(img, 2, 7, 4, 9, hexc("6aa84f"))  # goblińskie stopy
    rect(img, 27, 5, 29, 6, hexc("6aa84f"))
    outline(img, OUTLINE_DARK)
    return img


def egg_sac():
    img = new(26, 16)
    for cx, cy in ((7, 10), (13, 9), (19, 10), (10, 6), (16, 6)):
        ellipse(img, cx, cy, 3.4, 3, hexc("d8d0b0"), hexc("a89870"))
        put(img, cx - 1, cy - 1, hexc("f8f0d8"))
    for x in range(3, 23, 4):
        line(img, x, 2, x + 3, 14, (*SILK[2][:3], 160))
    outline(img, OUTLINE_DARK)
    return img


# ---------------------------------------------------------------- siedlisko bestii
def claw_tree():
    """Pień z głębokimi śladami pazurów i oderwaną korą."""
    img = new(30, 52)
    for y in range(6, 50):
        for x in range(9, 21):
            put(img, x, y, OLD_BARK[2] if x > 10 else OLD_BARK[3])
    for k in range(3):  # trzy rysy pazurów, po dwóch stronach
        for i in range(14):
            put(img, 11 + k * 3 + i // 7, 18 + i, hexc("c8a878"))
            put(img, 11 + k * 3 + i // 7, 32 + i // 2, hexc("c8a878"))
    for x, y in ((9, 10), (10, 9), (20, 14)):  # odłamki kory
        put(img, x, y, OLD_BARK[0])
    rect(img, 9, 2, 20, 6, OLD_BARK[1])
    for x in range(9, 21, 2):
        put(img, x, 1, OLD_BARK[3])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 15, 50, 9, 1.5)
    return img


def broken_tree():
    """Złamane drzewo: poszarpany pień i leżący obok wierzchołek z suchymi liśćmi."""
    img = new(56, 40)
    for y in range(12, 38):
        for x in range(8, 18):
            put(img, x, y, OLD_BARK[2] if x > 9 else OLD_BARK[3])
    for x in range(8, 18, 2):
        for d in range(random.Random(x).randint(2, 7)):
            put(img, x, 12 - d, hexc("c8a878"))
    line(img, 20, 34, 52, 22, OLD_BARK[2])
    line(img, 20, 35, 52, 23, OLD_BARK[1])
    for cx, cy in ((44, 20), (50, 24), (38, 24)):
        ellipse(img, cx, cy, 6, 4, hexc("6a5a2a"), hexc("4a3e1e"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 28, 38, 20, 2)
    return img


def scratches():
    """Rozorana pazurami ziemia (płasko na ziemi)."""
    img = new(32, 20)
    for k in range(4):
        for i in range(22):
            x = 4 + i + k
            y = 2 + k * 4 + i // 4
            put(img, x, y, (40, 28, 18, 210))
            put(img, x, y + 1, (90, 70, 46, 160))
    return img


def blood():
    img = new(22, 12)
    ellipse(img, 10, 6, 8, 4, (*BLOOD[0][:3], 200))
    ellipse(img, 9, 5, 5, 2.5, (*BLOOD[1][:3], 200))
    for x, y in ((19, 4), (2, 9), (17, 10)):
        put(img, x, y, (*BLOOD[1][:3], 220))
    return img


def skull_totem():
    """Czaszka jelenia z porożem na palu - znak granicy siedliska bestii."""
    img = new(26, 44)
    rect(img, 12, 14, 13, 43, OLD_BARK[2])
    ellipse(img, 12.5, 12, 4, 5, hexc("e8dcc0"))
    put(img, 11, 11, hexc("1a1210"))
    put(img, 14, 11, hexc("1a1210"))
    for side in (-1, 1):
        x, y = 12 + side * 3, 8
        for k in range(8):
            x += side
            y -= 1 if k % 2 else 0
            put(img, x, y, hexc("d8ccb0"))
            if k in (3, 6):
                put(img, x, y - 2, hexc("d8ccb0"))
                put(img, x, y - 1, hexc("d8ccb0"))
    for k in range(3):  # wiszące pióra i rzemienie
        line(img, 10 + k * 2, 18, 10 + k * 2, 22 + k, hexc("6a4a2a"))
        put(img, 10 + k * 2, 23 + k, hexc("c0392b") if k == 1 else hexc("f0ece0"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 12, 43, 5, 1)
    return img


# ---------------------------------------------------------------- stworzenia
def treant_frame(kind, f):
    """Drzewiec (32x42): chodzący pień z gałęziami-ramionami, twarzą i mchem."""
    img = new(32, 42)
    base = 41
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if kind == "walk" else 0
    for lx, ph in ((11, step), (19, -step)):  # nogi-korzenie
        rect(img, lx + ph // 2, base - 9, lx + 3 + ph // 2, base - 1, OLD_BARK[1])
        rect(img, lx - 2 + ph // 2, base - 1, lx + 5 + ph // 2, base - 1, OLD_BARK[0])
    for y in range(base - 30, base - 8):
        for x in range(9, 24):
            put(img, x, y, OLD_BARK[2] if (x + y // 2) % 5 else OLD_BARK[1])
        put(img, 9, y, OLD_BARK[3])
    ellipse(img, 13, base - 22, 1.6, 1.3, EYE_GREEN)
    ellipse(img, 19, base - 22, 1.6, 1.3, EYE_GREEN)
    rect(img, 13, base - 16, 19, base - 15, OLD_BARK[0])
    canopy = new(32, 42)
    shaded_blob(canopy, [(16, 8, 9), (8, 11, 6), (24, 11, 6)], DEEP_LEAF, rng=random.Random(f))
    img.alpha_composite(canopy)
    if kind == "windup":
        line(img, 9, base - 26, 2, base - 38, OLD_BARK[2])
        line(img, 23, base - 26, 30, base - 38, OLD_BARK[2])
    elif kind == "strike":
        line(img, 23, base - 24, 31, base - 14, OLD_BARK[2])
        line(img, 23, base - 22, 31, base - 12, OLD_BARK[1])
    else:
        line(img, 9, base - 26, 4, base - 14, OLD_BARK[2])
        line(img, 23, base - 26, 28, base - 14, OLD_BARK[2])
    for k in range(4):
        put(img, 10 + k * 4, base - 9 - k % 2, MOSS[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 16, 41, 10, 1.6)
    return img


def leshy_frame(kind, f=0):
    """Leszy (52x70): wysoki, chudy duch lasu - ciało z kory, broda z mchu, poroże, laska z korzenia."""
    img = new(52, 70)
    base = 68
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if kind == "walk" else 0
    for lx, ph in ((21, step), (28, -step)):
        rect(img, lx + ph // 2, base - 16, lx + 2 + ph // 2, base - 1, OLD_BARK[1])
    for y in range(base - 44, base - 14):  # długie, chude ciało
        half = 5 + (y - (base - 44)) // 8
        for x in range(26 - half, 26 + half):
            put(img, x, y, OLD_BARK[2] if (x + y) % 4 else OLD_BARK[3])
    for y in range(base - 40, base - 18):  # broda z mchu
        for x in range(22, 31):
            if (x + y) % 3 and y < base - 18 - abs(x - 26):
                put(img, x, y, MOSS[1 + (x + y) % 2])
    hy = base - 50
    ellipse(img, 26, hy, 6, 7, OLD_BARK[3])
    ellipse(img, 23, hy - 1, 1.4, 1.4, EYE_GREEN)
    ellipse(img, 29, hy - 1, 1.4, 1.4, EYE_GREEN)
    for side in (-1, 1):  # rozłożyste poroże
        x, y = 26 + side * 4, hy - 6
        for k in range(14):
            x += side
            y -= 1 if k % 2 == 0 else 0
            put(img, x, y, hexc("c8b890"))
            if k in (4, 8, 12):
                line(img, x, y, x + side * 2, y - 5, hexc("c8b890"))
    if kind == "summon":
        line(img, 20, base - 40, 8, base - 56, OLD_BARK[2])
        line(img, 32, base - 40, 44, base - 56, OLD_BARK[2])
        for x, y in ((6, base - 58), (46, base - 58), (5, base - 61)):
            put(img, x, y, EYE_GREEN)
    elif kind in ("roots", "leaves"):
        line(img, 32, base - 38, 48, base - 30 if kind == "roots" else base - 46, OLD_BARK[2])
        line(img, 20, base - 38, 12, base - 26, OLD_BARK[2])
        if kind == "leaves":
            for k in range(8):
                put(img, 44 + k % 4, base - 50 + k * 2, hexc("c8a040") if k % 2 else DEEP_LEAF[4])
    else:
        line(img, 33, base - 38, 40, base - 22, OLD_BARK[2])  # laska z korzenia
        line(img, 40, base - 50, 40, base - 1, OLD_BARK[1])
        ellipse(img, 40, base - 52, 2.5, 2.5, EYE_GREEN)
        line(img, 19, base - 38, 14, base - 24, OLD_BARK[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 26, 68, 12, 2)
    return img


def spider_frame(kind, f, pal, size=24, h=18):
    """Pająk bokiem (24x18): okrągły odwłok, osiem nóg, czerwone znaczenia, kły."""
    img = new(size, h)
    s = size / 24
    base = h - 1
    step = f % 2 if kind == "walk" else 0
    lift = -2 if kind == "windup" else 0
    ellipse(img, 8 * s, base - 8 * s + lift, 6 * s, 5 * s, pal[1], pal[0])
    put(img, int(8 * s), int(base - 10 * s + lift), pal[3])
    put(img, int(7 * s), int(base - 9 * s + lift), pal[3])
    ellipse(img, 15 * s, base - 7 * s + lift, 3.5 * s, 3 * s, pal[2], pal[1])
    for k in range(4):  # nogi
        x0 = 11 * s + k * 2 * s
        y0 = base - 7 * s + lift
        knee = (x0 + (k - 1.5) * 3 * s, y0 - 5 * s + (step if k % 2 else -step))
        line(img, int(x0), int(y0), int(knee[0]), int(knee[1]), pal[0])
        line(img, int(knee[0]), int(knee[1]), int(knee[0] + (k - 1.5) * 2 * s), int(base), pal[0])
    put(img, int(17 * s), int(base - 8 * s + lift), EYE_RED)
    if kind in ("windup", "strike"):
        line(img, int(18 * s), int(base - 6 * s + lift), int(20 * s + (2 if kind == "strike" else 0)), int(base - 4 * s), hexc("d8d0c0"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 12 * s, h - 1, 9 * s, 1)
    return img


def make_spiders():
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("idle", 1), ("windup", 0), ("strike", 0)]
    for name, pal, size, h in (("spider", SPIDER, 24, 18),
                               ("web_spider", [hexc("1e1a2e"), hexc("3a3456"), hexc("5a5280"), hexc("e0e0f0")], 24, 18),
                               ("spiderling", SPIDER, 12, 10)):
        sheet = new(size * 4, h * 2)
        for i, (kind, f) in enumerate(frames):
            sheet.paste(spider_frame(kind, f, pal, size, h), ((i % 4) * size, (i // 4) * h))
        save(sheet, name)


def queen_frame(kind, f=0):
    """Królowa Pająków (76x58): olbrzymi, nabrzmiały odwłok z czerwoną klepsydrą i koroną kolców."""
    img = new(76, 58)
    base = 56
    lift = {"leap": 10}.get(kind, 0)
    step = f % 2 if kind == "walk" else 0
    ellipse(img, 26, base - 22 - lift, 20, 16, SPIDER[1], SPIDER[0])
    for y in range(base - 30 - lift, base - 14 - lift):  # klepsydra
        w = abs(y - (base - 22 - lift)) // 2 + 1
        rect(img, 26 - w, y, 25 + w, y, SPIDER[3])
    ellipse(img, 50, base - 20 - lift, 10, 8, SPIDER[2], SPIDER[1])
    for k in range(5):  # korona kolców
        line(img, 46 + k * 2, base - 27 - lift, 45 + k * 3, base - 34 - lift - (k % 2) * 2, hexc("d8d0c0"))
    for ex, ey in ((55, base - 22), (57, base - 20), (53, base - 20), (56, base - 24)):
        put(img, ex, ey - lift, EYE_RED)
    for k in range(4):  # osiem grubych nóg
        x0 = 36 + k * 5
        y0 = base - 18 - lift
        kx = x0 + (k - 1.5) * 9
        ky = y0 - 16 + (step * 2 if k % 2 else -step * 2)
        for dx in (0, 1):
            line(img, x0 + dx, y0, int(kx) + dx, int(ky), SPIDER[0])
            line(img, int(kx) + dx, int(ky), int(kx + (k - 1.5) * 6) + dx, base - (0 if kind != "leap" else lift), SPIDER[0])
    if kind in ("spray", "summon"):
        for i in range(10):
            put(img, 60 + i * 1, base - 18 - (i % 3), SILK[2])
    if kind == "summon":
        for x in range(10, 40, 6):
            ellipse(img, x, base - 4, 2, 1.6, hexc("d8d0b0"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 36, 56, 26, 2.5)
    return img


def bear_frame(kind, f=0):
    """Niedźwiedź-bestia (50x42): czarne, zjeżone futro, blizny, świecące oczy, ogromne łapy."""
    img = new(50, 42)
    fur, fur_d, fur_l = hexc("2a2220"), hexc("1a1412"), hexc("4a3c34")
    base = 41
    step = {0: 0, 1: 3, 2: 0, 3: -3}[f] if kind == "walk" else 0
    rear = kind in ("windup", "roar")
    if rear:  # staje na tylnych łapach
        ellipse(img, 22, base - 18, 10, 16, fur, fur_d)
        ellipse(img, 24, base - 34, 7, 6, fur)
        line(img, 14, base - 26, 6, base - 36, fur_d)
        line(img, 30, base - 26, 40, base - 36, fur_d)
        put(img, 27, base - 35, EYE_RED)
        rect(img, 28, base - 31, 31, base - 30, hexc("e8e0d0"))
    else:
        for lx, ph in ((12, step), (17, -step), (31, step), (36, -step)):
            rect(img, lx + ph // 2, base - 10, lx + 3 + ph // 2, base - 1, fur_d)
        ellipse(img, 24, base - 16, 16, 10, fur, fur_d)
        for x in range(12, 36, 3):  # zjeżony grzbiet
            put(img, x, base - 27, fur_l)
        ellipse(img, 40, base - 18, 7, 6, fur)
        put(img, 42, base - 20, EYE_RED)
        put(img, 46, base - 16, hexc("1a1210"))
        line(img, 18, base - 20, 24, base - 12, fur_l)  # blizna
        if kind == "strike":
            line(img, 36, base - 12, 48, base - 4, fur_d)
            for k in range(3):
                put(img, 48, base - 5 + k, hexc("e8e0d0"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 25, 41, 16, 2)
    return img


def werewolf_frame(kind, f=0):
    """Wilkołak (36x44): wyprostowany, szary, z długimi pazurami i żółtymi oczami."""
    img = new(36, 44)
    fur, fur_d, fur_l = hexc("5a5a62"), hexc("3a3a42"), hexc("8a8a94")
    base = 43
    step = {0: 0, 1: 2, 2: 0, 3: -2}[f] if kind == "walk" else 0
    for lx, ph in ((13, step), (20, -step)):  # wygięte tylne łapy
        line(img, lx + ph // 2, base - 14, lx + 2 + ph // 2, base - 7, fur_d)
        line(img, lx + 2 + ph // 2, base - 7, lx + ph // 2, base - 1, fur_d)
    ellipse(img, 17, base - 22, 8, 10, fur, fur_d)
    ellipse(img, 18, base - 20, 4, 6, fur_l)
    hy = base - 34
    ellipse(img, 20, hy, 5, 4, fur)
    rect(img, 23, hy + 1, 28, hy + 3, fur)  # pysk
    put(img, 21, hy - 1, hexc("f2d14c"))
    put(img, 13, hy - 5, fur)  # uszy
    put(img, 16, hy - 6, fur)
    rect(img, 24, hy + 3, 27, hy + 3, hexc("e8e0d0"))
    if kind == "windup":
        line(img, 11, base - 26, 4, base - 36, fur_d)
        line(img, 24, base - 26, 31, base - 36, fur_d)
    elif kind == "strike":
        line(img, 24, base - 24, 35, base - 22, fur_d)
        for k in range(3):
            put(img, 35, base - 24 + k, hexc("e8e0d0"))
    else:
        line(img, 11, base - 26, 9, base - 14, fur_d)
        line(img, 24, base - 26, 26, base - 14, fur_d)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 17, 43, 9, 1.5)
    return img


def bies_frame(kind, f=0):
    """Bies (60x66): czarny demon puszczy - kozie rogi, czerwone ślepia, długie szpony, dym u stóp."""
    img = new(60, 66)
    skin, skin_d, ember = hexc("1e1416"), hexc("120a0c"), hexc("ff4a1e")
    base = 64
    step = {0: 0, 1: 3, 2: 0, 3: -3}[f] if kind == "walk" else 0
    for lx, ph in ((23, step), (32, -step)):  # kozie nogi z kopytami
        line(img, lx + ph // 2, base - 20, lx + 3 + ph // 2, base - 10, skin_d)
        line(img, lx + 3 + ph // 2, base - 10, lx + ph // 2, base - 2, skin_d)
        rect(img, lx - 1 + ph // 2, base - 2, lx + 2 + ph // 2, base - 1, hexc("3a2a20"))
    ellipse(img, 28, base - 32, 12, 15, skin, skin_d)
    for k in range(5):  # żarzące się pęknięcia na piersi
        put(img, 24 + k * 2, base - 34 + (k % 2) * 3, ember)
    hy = base - 50
    ellipse(img, 29, hy, 7, 7, skin)
    put(img, 26, hy - 1, EYE_RED)
    put(img, 32, hy - 1, EYE_RED)
    rect(img, 26, hy + 3, 32, hy + 4, ember if kind in ("roar", "windup") else skin_d)
    for side in (-1, 1):  # zakręcone kozie rogi
        x, y = 29 + side * 5, hy - 5
        for k in range(12):
            x += side if k < 7 else 0
            y -= 1 if k < 7 else -1
            put(img, x, y, hexc("8a7a5a"))
            put(img, x, y + 1, hexc("5a4a3a"))
    if kind == "windup":
        line(img, 17, base - 38, 6, base - 54, skin_d)
        line(img, 39, base - 38, 50, base - 54, skin_d)
    elif kind == "strike":
        line(img, 39, base - 36, 58, base - 28, skin_d)
        for k in range(4):
            put(img, 58, base - 31 + k, hexc("e8e0d0"))
    elif kind == "roar":
        line(img, 17, base - 36, 5, base - 30, skin_d)
        line(img, 39, base - 36, 53, base - 30, skin_d)
    else:
        line(img, 17, base - 38, 12, base - 20, skin_d)
        line(img, 39, base - 38, 44, base - 20, skin_d)
        for k in range(3):
            put(img, 11 + k, base - 19, hexc("e8e0d0"))
            put(img, 44 + k, base - 19, hexc("e8e0d0"))
    rng = random.Random(f)
    for _ in range(14):  # dym u stóp
        x, y = rng.randrange(12, 46), rng.randrange(base - 8, base)
        if not img.getpixel((x, y))[3]:
            put(img, x, y, (60, 50, 56, 160))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 29, 64, 16, 2.5)
    return img


def make_sheet(fn, frames, w, h, name):
    sheet = new(w * 4, h * 2)
    for i, (kind, f) in enumerate(frames):
        sheet.paste(fn(kind, f), ((i % 4) * w, (i // 4) * h))
    save(sheet, name)


# ---------------------------------------------------------------- łupy
def items():
    bark = new(16, 16)
    for y in range(3, 14):
        for x in range(4, 13):
            put(bark, x, y, OLD_BARK[2] if (x + y) % 3 else OLD_BARK[3])
    for y in (5, 9, 12):
        line(bark, 5, y, 11, y + 1, OLD_BARK[0])
    put(bark, 8, 7, EYE_GREEN)
    outline(bark, OUTLINE_DARK)
    save(bark, "ancient_bark", ITEMS)

    silk = new(16, 16)
    ellipse(silk, 8, 9, 5, 4, SILK[1], SILK[0])
    for k in range(5):
        line(silk, 3 + k * 2, 6, 5 + k * 2, 13, SILK[2])
    outline(silk, OUTLINE_DARK)
    save(silk, "spider_silk", ITEMS)

    venom = new(16, 16)
    ellipse(venom, 8, 9, 4, 5, hexc("3a8a2a"), hexc("1e5a1a"))
    put(venom, 7, 7, hexc("b8ff6a"))
    line(venom, 8, 3, 8, 5, SPIDER[2])
    outline(venom, OUTLINE_DARK)
    save(venom, "spider_venom", ITEMS)

    fang = new(16, 16)
    for y in range(2, 15):
        w = max(0, (15 - y) // 3)
        rect(fang, 7 - w // 2, y, 8 + w // 2, y, hexc("f0e8d0") if y < 11 else hexc("c8b890"))
    put(fang, 7, 14, BLOOD[1])
    outline(fang, OUTLINE_DARK)
    save(fang, "beast_fang", ITEMS)
    legendary_items()


def _band(img, cy, palette, rx=1.0):
    """Obręcz pierścienia (dolna połowa ikony), jaśniejsza u góry z lewej."""
    for y in range(16):
        for x in range(16):
            d = math.hypot((x + 0.5 - 8) / rx, (y + 0.5 - cy) / 0.85)
            if 3.4 <= d <= 5.6:
                put(img, x, y, palette[2] if (x - 8) + (y - cy) < -2 else palette[1] if d < 4.6 else palette[0])


def _hoop(img, palette):
    """Kółko kolczyka u góry ikony."""
    for t in range(9):
        a = math.pi * (0.15 + t / 8 * 1.3)
        put(img, int(round(8 + math.cos(a) * 3)), int(round(3.5 - math.sin(a) * 3)), palette[2])
    rect(img, 8, 4, 8, 6, palette[1])


def legendary_items():
    from drowned_art import GOLD, SILVER, glow
    legend = hexc("ffa040")

    # Obręcz Leszego: pierścień z poskręcanego korzenia z zielonym kamieniem i listkami
    ring = new(16, 16)
    _band(ring, 10, [OLD_BARK[1], OLD_BARK[3], OLD_BARK[4]])
    ellipse(ring, 8, 4, 2.6, 2.4, hexc("3aa040"), hexc("1e6a2a"))
    put(ring, 7, 3, EYE_GREEN)
    for x, y in ((4, 4), (12, 4), (3, 6)):
        put(ring, x, y, MOSS[2])
        put(ring, x + 1, y - 1, MOSS[3])
    outline(ring, OUTLINE_DARK)
    glow(ring, legend)
    save(ring, "ring_leshy", ITEMS)

    # Żołądź Leszego: złote kółko z żołędziem obrośniętym cierniami
    ear = new(16, 16)
    _hoop(ear, GOLD)
    ellipse(ear, 8, 11, 3.2, 3.6, hexc("a87a3a"), hexc("7a5426"))
    rect(ear, 5, 7, 11, 8, OLD_BARK[2])
    for x in (5, 7, 9, 11):
        put(ear, x, 6, OLD_BARK[3])
    for x, y in ((3, 10), (13, 11), (4, 13), (12, 8)):
        put(ear, x, y, MOSS[1])
    put(ear, 7, 10, hexc("e0b870"))
    outline(ear, OUTLINE_DARK)
    glow(ear, legend)
    save(ear, "earring_leshy", ITEMS)

    # Pierścień Królowej: czarna obręcz z czerwoną klepsydrą, oplątana jedwabiem
    ring = new(16, 16)
    _band(ring, 10, [SPIDER[0], SPIDER[1], SPIDER[2]])
    ellipse(ring, 8, 4, 3, 2.6, SPIDER[1])
    for y, w in ((2, 2), (3, 1), (4, 0), (5, 1), (6, 2)):
        rect(ring, 8 - w, y, 8 + w, y, SPIDER[3] if w else hexc("ff5040"))
    for k in range(4):
        put(ring, 3 + k * 3, 9 + k % 2, SILK[2])
    outline(ring, OUTLINE_DARK)
    glow(ring, legend)
    save(ring, "ring_queen", ITEMS)

    # Jedwabny Kokon: srebrne kółko z małym kokonem, z którego wystają nóżki
    ear = new(16, 16)
    _hoop(ear, SILVER)
    ellipse(ear, 8, 11, 3, 4, SILK[1], SILK[0])
    for y in (9, 11, 13):
        line(ear, 6, y, 10, y + 1, SILK[2])
    for x, y in ((4, 9), (12, 9), (4, 13), (12, 13)):
        put(ear, x, y, SPIDER[1])
    put(ear, 8, 10, EYE_GREEN)
    outline(ear, OUTLINE_DARK)
    glow(ear, legend)
    save(ear, "earring_queen", ITEMS)

    # Róg Biesa: obręcz z czarnego rogu z żarzącym się, czerwonym okiem
    ring = new(16, 16)
    _band(ring, 10, [hexc("140e10"), hexc("2a2024"), hexc("4a3a3e")])
    ellipse(ring, 8, 4, 2.6, 2.6, hexc("3a0e0e"))
    put(ring, 8, 4, EYE_RED)
    put(ring, 7, 4, hexc("ff8a50"))
    for x, y in ((4, 2), (3, 1), (12, 2), (13, 1)):  # małe rogi po bokach oka
        put(ring, x, y, hexc("d8d0c0"))
    outline(ring, OUTLINE_DARK)
    glow(ring, legend)
    save(ring, "ring_bies", ITEMS)

    # Szpon Biesa: złote kółko z zakrzywionym, czarnym szponem i kroplą krwi
    ear = new(16, 16)
    _hoop(ear, GOLD)
    for i in range(8):
        x = 8 + int(round(math.sin(i / 7 * 1.6) * 3))
        rect(ear, x - (1 if i < 4 else 0), 7 + i, x, 7 + i, hexc("2a2024") if i < 6 else hexc("4a3a3e"))
    put(ear, 11, 15, BLOOD[1])
    put(ear, 7, 8, hexc("6a5a5e"))
    outline(ear, OUTLINE_DARK)
    glow(ear, legend)
    save(ear, "earring_bies", ITEMS)

    # przedmioty przyzwania
    twig = new(16, 16)  # Gałąź Leszego: sękata gałązka z listkami i świecącą runą
    line(twig, 3, 14, 12, 3, OLD_BARK[2])
    line(twig, 4, 14, 13, 4, OLD_BARK[1])
    line(twig, 8, 9, 5, 5, OLD_BARK[3])
    for x, y in ((4, 4), (5, 3), (12, 2), (13, 2), (11, 6)):
        put(twig, x, y, MOSS[2])
    put(twig, 9, 8, EYE_GREEN)
    outline(twig, OUTLINE_DARK)
    glow(twig, hexc("b060ff"), 120)
    save(twig, "summon_leshy", ITEMS)

    egg = new(16, 16)  # Jajo Królowej: wielkie, oplecione jedwabiem jajo z czerwoną plamką
    ellipse(egg, 8, 9, 5, 6, hexc("e8e0c8"), hexc("b8b098"))
    for y in (5, 8, 11, 13):
        line(egg, 3, y, 13, y + 1, SILK[2])
    put(egg, 9, 9, SPIDER[3])
    put(egg, 9, 10, SPIDER[3])
    outline(egg, OUTLINE_DARK)
    glow(egg, hexc("b060ff"), 120)
    save(egg, "summon_spider_queen", ITEMS)

    skull = new(16, 16)  # Czaszka Biesa: rogata czaszka z czerwonymi oczodołami
    ellipse(skull, 8, 9, 4.5, 4, hexc("e0d8c0"), hexc("b0a890"))
    rect(skull, 6, 12, 10, 13, hexc("c8c0a8"))
    put(skull, 6, 9, EYE_RED)
    put(skull, 10, 9, EYE_RED)
    for i in range(4):
        put(skull, 3 - i // 2, 6 - i, hexc("3a2c26"))
        put(skull, 13 + i // 2, 6 - i, hexc("3a2c26"))
    outline(skull, OUTLINE_DARK)
    glow(skull, hexc("b060ff"), 120)
    save(skull, "summon_bies", ITEMS)


def make_all():
    os.makedirs(ANCIENT, exist_ok=True)
    for v in range(3):
        save(giant_tree(v), "giant_tree_%d" % v)
        save(menhir(v), "menhir_%d" % v)
    sheet = new(80 * 2, 104)
    for s in range(2):
        sheet.paste(ancient_tree(s), (s * 80, 0))
    save(sheet, "ancient_tree")
    save(ancient_stump(), "ancient_stump")
    save(glow_shroom(), "glow_shroom")
    save(altar_stump(), "altar_stump")
    save(fallen_log(), "fallen_log")
    save(forest_decor(), "decor")
    save(web(56, 1), "web_big")
    save(web(32, 2), "web_small")
    save(web(120, 3), "web_huge")
    save(cocoon(), "cocoon")
    save(wrapped_victim(), "wrapped_victim")
    save(egg_sac(), "egg_sac")
    save(claw_tree(), "claw_tree")
    save(broken_tree(), "broken_tree")
    save(scratches(), "scratches")
    save(blood(), "blood")
    save(skull_totem(), "skull_totem")
    frames = [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("idle", 1), ("windup", 0), ("strike", 0)]
    make_sheet(treant_frame, frames, 32, 42, "treant")
    make_sheet(leshy_frame, [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("summon", 0), ("roots", 0), ("leaves", 0)], 52, 70, "leshy")
    make_spiders()
    make_sheet(queen_frame, [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("spray", 0), ("summon", 0), ("leap", 0)], 76, 58, "spider_queen")
    make_sheet(bear_frame, [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("roar", 0), ("windup", 0), ("strike", 0)], 50, 42, "beast_bear")
    make_sheet(werewolf_frame, frames, 36, 44, "beast_werewolf")
    make_sheet(bies_frame, [("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3), ("idle", 0), ("roar", 0), ("windup", 0), ("strike", 0)], 60, 66, "bies")
    items()
