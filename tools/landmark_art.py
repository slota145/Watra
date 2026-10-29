"""Chata mędrca i gildia poszukiwaczy przygód (budowy u sołtysa): budynki z ozdobionymi
fasadami i wnętrzami, wyposażenie, ozdoby wokół i postacie. Wywoływane z generate_art.py
(po village_art - korzysta z make_building i rozbudowuje gotowe dachy i podłogi).

Chata mędrca: omszały, fioletowy dach strzecha, księżyc z gwiazdą na szczycie, okrągłe
okienko z niebieskim blaskiem, pęki ziół pod okapem, bluszcz na ścianach, latarenka przy
drzwiach i kamienny stopień; w środku dywan z gwiazdami. Wokół: regały z księgami i pulpit
(w środku), kocioł z bulgoczącym wywarem, luneta, grządka ziół, sowa na żerdzi, kamień runiczny.

Gildia: kamienny budynek z karmazynowym dachem i złotą listwą, dwa proporce na fasadzie,
tarcza z mieczami nad szyldem, skrzynki z kwiatami pod oknami, kamienne schody; w środku
czerwony chodnik. Wokół: tablica ogłoszeń, maszty z łopoczącymi proporcami, pochodnie,
ława, stół z mapą i trofeum (w środku)."""
import math
import os
import random

from PIL import Image

from generate_art import BARK, OUT, OUTLINE_DARK, STONE, hexc, line, new, outline, put, rect, shadow_ellipse
import village_art
from village_art import NPC_DIR, VILLAGE, person, sign_pixels, tunic

PAPER = [hexc("b8a888"), hexc("e8dcc0"), hexc("f8f0dc")]
GOLD = [hexc("8a5a10"), hexc("c8901c"), hexc("f2c94c"), hexc("fff3b0")]
CRIMSON = [hexc("4a1420"), hexc("7a1f2e"), hexc("a82e40"), hexc("d04a5a")]
VIOLET = [hexc("2a1f3a"), hexc("3d2d55"), hexc("54407a"), hexc("6e58a0")]
MOSS = [hexc("3e5a2a"), hexc("56783a"), hexc("6f944a")]
BOOK_COLORS = ["8e2f25", "34496a", "3e4d26", "6a3d8a", "b08a3a", "2f6f73", "7a5230", "a8564a"]

village_art.SIGNS["book"] = sign_pixels(["bbbb.", "bppbb", "bppbb", "bbbb.", "....."],
                                        {"b": "54407a", "p": "f4f0e0"})
village_art.SIGNS["guild"] = sign_pixels(["s...s", ".s.s.", "..y..", ".s.s.", "y...y"],
                                         {"s": "c9d1e0", "y": "e0a020"})


def save(img, name):
    img.save(os.path.join(VILLAGE, name + ".png"))


def shade(img, x, y, k):
    r, g, b, a = img.getpixel((x, y))
    if a:
        img.putpixel((x, y), (min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k)), a))


# ---------------------------------------------------------------- budynki
def sage_hut():
    village_art.make_building("sage_hut", 8, 6, VIOLET, "wood", "book", True)
    roof = Image.open(os.path.join(VILLAGE, "sage_hut_roof.png")).convert("RGBA")
    W, H = roof.size
    rng = random.Random(7)
    roof_h = H - 30
    # mech na strzesze
    for _ in range(160):
        x, y = rng.randrange(2, W - 2), rng.randrange(3, roof_h - 3)
        if roof.getpixel((x, y))[3]:
            put(roof, x, y, MOSS[rng.randrange(3)])
    # księżyc z gwiazdą na szczycie dachu
    cx, cy = W // 2 - 26, 14
    for y in range(-5, 6):
        for x in range(-5, 6):
            if x * x + y * y <= 25 and (x + 2) ** 2 + (y - 1) ** 2 > 14:
                put(roof, cx + x, cy + y, GOLD[2] if x < -1 else GOLD[1])
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        put(roof, cx + 8 + dx, cy - 4 + dy, GOLD[3] if (dx, dy) == (0, 0) else GOLD[2])
    # okrągłe okienko w szczycie z niebieskim blaskiem
    wx, wy = W // 2 + 30, 18
    for y in range(-5, 6):
        for x in range(-5, 6):
            d = math.hypot(x, y)
            if d <= 5.3:
                put(roof, wx + x, wy + y, BARK[0] if d > 4.2 else hexc("7ec8ff") if d < 2 else hexc("4a8ad0"))
    line(roof, wx - 4, wy, wx + 4, wy, BARK[0])
    line(roof, wx, wy - 4, wx, wy + 4, BARK[0])
    # pęki ziół pod okapem
    for i, hx in enumerate(range(10, W - 8, 13)):
        if abs(hx - W // 2) < 16:
            continue
        put(roof, hx, roof_h - 1, BARK[0])
        col = [MOSS[1], hexc("8a6aa8"), hexc("c8a04a")][i % 3]
        for k in range(5):
            rect(roof, hx - 1 + (k % 2), roof_h + k, hx + 1 - (k % 2) + (k > 2), roof_h + k, col)
    # bluszcz na ścianach
    for side_x in (2, W - 4):
        x = side_x
        for y in range(roof_h + 2, H - 2):
            x += rng.choice((-1, 0, 0, 1))
            x = max(1, min(W - 2, x))
            if abs(x - side_x) > 4:
                x = side_x
            put(roof, x, y, MOSS[1])
            if rng.random() < 0.4:
                put(roof, x + rng.choice((-1, 1)), y, MOSS[2])
    # latarenka przy drzwiach i kamienny stopień
    lx = W // 2 + 14
    rect(roof, lx, H - 24, lx + 3, H - 24, BARK[0])
    rect(roof, lx, H - 23, lx + 3, H - 19, hexc("ffd27a"))
    rect(roof, lx + 1, H - 22, lx + 2, H - 20, hexc("fff3c0"))
    rect(roof, W // 2 - 12, H - 3, W // 2 + 11, H - 2, STONE[2])
    rect(roof, W // 2 - 12, H - 3, W // 2 + 11, H - 3, STONE[3])
    roof.save(os.path.join(VILLAGE, "sage_hut_roof.png"))

    floor = Image.open(os.path.join(VILLAGE, "sage_hut_floor.png")).convert("RGBA")
    # okrągły dywan z gwiazdami na środku izby
    cx, cy = W // 2, 62
    for y in range(-14, 15):
        for x in range(-26, 27):
            d = math.hypot(x / 26, y / 14)
            if d <= 1:
                c = VIOLET[1] if d > 0.85 else VIOLET[2] if d > 0.75 else VIOLET[1]
                if d < 0.7 and (x * 7 + y * 13) % 23 == 0:
                    c = GOLD[2]
                put(floor, cx + x, cy + y, c)
    floor.save(os.path.join(VILLAGE, "sage_hut_floor.png"))


def guild():
    village_art.make_building("guild", 12, 7, CRIMSON, "stone", "guild", True)
    roof = Image.open(os.path.join(VILLAGE, "guild_roof.png")).convert("RGBA")
    W, H = roof.size
    roof_h = H - 30
    # złota listwa okapu i kalenicy
    rect(roof, 1, roof_h - 3, W - 2, roof_h - 3, GOLD[1])
    rect(roof, 1, 2, W - 2, 2, GOLD[2])
    # tarcza ze skrzyżowanymi mieczami nad szyldem
    sx, sy = W // 2, roof_h - 18
    for y in range(0, 11):
        half = 6 if y < 6 else 6 - (y - 5)
        rect(roof, sx - half, sy + y, sx + half - 1, sy + y, CRIMSON[2] if y > 0 else GOLD[2])
    rect(roof, sx - 6, sy, sx - 6, sy + 5, GOLD[1])
    rect(roof, sx + 5, sy, sx + 5, sy + 5, GOLD[1])
    line(roof, sx - 4, sy + 2, sx + 3, sy + 8, hexc("dfe4ee"))
    line(roof, sx + 3, sy + 2, sx - 4, sy + 8, hexc("dfe4ee"))
    put(roof, sx - 1, sy + 5, GOLD[3])
    # dwa proporce na fasadzie
    for bx in (24, W - 32):
        rect(roof, bx - 1, roof_h, bx + 8, roof_h, GOLD[1])
        for y in range(roof_h + 1, H - 6):
            for x in range(bx, bx + 8):
                tip = y - (H - 12)
                if tip > 0 and abs(x - (bx + 3.5)) < tip:
                    continue
                put(roof, x, y, CRIMSON[2] if x > bx else CRIMSON[1])
        rect(roof, bx + 2, roof_h + 5, bx + 5, roof_h + 8, GOLD[2])
        put(roof, bx + 3, roof_h + 6, GOLD[3])
    # skrzynki z kwiatami pod oknami
    for wx in (W // 4, W - W // 4):
        if abs(wx - W // 2) < 18:
            continue
        rect(roof, wx - 6, H - 11, wx + 5, H - 9, BARK[1])
        for k, col in enumerate(("e04a5a", "f2c94c", "e8e0ff", "e04a5a", "f2c94c", "8ac8ff")):
            put(roof, wx - 5 + k * 2, H - 12, hexc(col))
            put(roof, wx - 5 + k * 2, H - 13, MOSS[2])
    # kamienne schody
    rect(roof, W // 2 - 13, H - 4, W // 2 + 12, H - 2, STONE[2])
    rect(roof, W // 2 - 13, H - 4, W // 2 + 12, H - 4, STONE[3])
    roof.save(os.path.join(VILLAGE, "guild_roof.png"))

    floor = Image.open(os.path.join(VILLAGE, "guild_floor.png")).convert("RGBA")
    # czerwony chodnik od drzwi i duży dywan w sali
    rect(floor, W // 2 - 8, 70, W // 2 + 7, H - 6, CRIMSON[1])
    rect(floor, W // 2 - 7, 70, W // 2 + 6, H - 6, CRIMSON[2])
    rect(floor, W // 2 - 7, 70, W // 2 - 7, H - 6, GOLD[1])
    rect(floor, W // 2 + 6, 70, W // 2 + 6, H - 6, GOLD[1])
    rect(floor, W // 2 - 30, 44, W // 2 + 29, 69, CRIMSON[1])
    rect(floor, W // 2 - 28, 46, W // 2 + 27, 67, CRIMSON[2])
    for x in range(W // 2 - 28, W // 2 + 28, 6):
        put(floor, x, 46, GOLD[2])
        put(floor, x + 3, 67, GOLD[2])
    floor.save(os.path.join(VILLAGE, "guild_floor.png"))


# ---------------------------------------------------------------- chata mędrca: wyposażenie i ozdoby
def bookshelf(variant):
    img = new(20, 30)
    rng = random.Random(40 + variant)
    rect(img, 0, 0, 19, 29, BARK[1])
    rect(img, 0, 0, 19, 1, BARK[3])
    rect(img, 2, 2, 17, 27, BARK[0])
    for shelf_y in (2, 10, 18):
        x = 2
        while x < 17:
            w = rng.choice((1, 2, 2))
            h = rng.randint(5, 7)
            col = hexc(rng.choice(BOOK_COLORS))
            if rng.random() < 0.12:  # przechylona albo brak
                x += 1
                continue
            rect(img, x, shelf_y + 8 - h, min(16, x + w - 1), shelf_y + 7, col)
            put(img, x, shelf_y + 8 - h + 1, GOLD[2])
            x += w
        rect(img, 1, shelf_y + 8, 18, shelf_y + 8, BARK[2])
    if variant == 1:  # czaszka i świeca na półce
        rect(img, 12, 21, 15, 25, hexc("e8dcc0"))
        put(img, 13, 23, BARK[0])
        put(img, 14, 23, BARK[0])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 10, 29, 9, 1.5)
    save(img, "bookshelf_%d" % variant)


def lectern():
    """Pulpit z otwartą księgą i świecą - 2 klatki (przewracana kartka)."""
    sheet = new(24 * 2, 26)
    for f in range(2):
        img = new(24, 26)
        rect(img, 10, 13, 13, 23, BARK[1])  # noga
        rect(img, 10, 13, 10, 23, BARK[3])
        rect(img, 6, 23, 17, 24, BARK[1])  # podstawa
        for y in range(8, 14):  # skośny blat
            rect(img, 3 + (13 - y) // 3, y, 20 - (13 - y) // 3, y, BARK[2])
        # otwarta księga
        rect(img, 5, 5, 11, 10, PAPER[2])
        rect(img, 12, 5, 18, 10, PAPER[1] if f else PAPER[2])
        rect(img, 11, 5, 12, 10, PAPER[0])
        for ty in (6, 8):
            line(img, 6, ty, 10, ty, hexc("8a7a5a"))
            if not f:
                line(img, 13, ty, 17, ty, hexc("8a7a5a"))
        if f:  # kartka w połowie przewracania
            for y in range(2, 8):
                put(img, 12 + (7 - y) // 2, y, PAPER[2])
        # świeca
        rect(img, 20, 3, 21, 8, hexc("f4f0e0"))
        put(img, 20, 2, hexc("ffd27a"))
        put(img, 20, 1, hexc("fff3c0"))
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 12, 24, 8, 1.5)
        sheet.paste(img, (f * 24, 0))
    save(sheet, "lectern")


def cauldron():
    """Kocioł na trójnogu z bulgoczącym zielonym wywarem - 2 klatki."""
    sheet = new(20 * 2, 20)
    for f in range(2):
        img = new(20, 20)
        rect(img, 4, 10, 15, 16, hexc("2a2c36"))
        rect(img, 3, 9, 16, 10, hexc("3d3f4f"))
        rect(img, 5, 16, 14, 17, hexc("2a2c36"))
        rect(img, 5, 11, 6, 15, hexc("4b4f63"))
        rect(img, 4, 8, 15, 9, hexc("3fd070"))
        rect(img, 6, 8, 9, 8, hexc("9cffb0"))
        for bx, by in ((7, 6 - f), (12, 5 + f), (10, 3 - f)):
            put(img, bx, by, hexc("9cffb0"))
        for x in (6, 10, 14):  # ogień pod kotłem
            put(img, x, 18, hexc("ff8a20"))
            put(img, x + (f * 2 - 1) * 0, 17 + f, hexc("ffd27a"))
        rect(img, 2, 18, 17, 18, BARK[1])
        outline(img, OUTLINE_DARK)
        sheet.paste(img, (f * 20, 0))
    save(sheet, "cauldron")


def telescope():
    img = new(16, 26)
    line(img, 8, 14, 3, 24, BARK[1])  # trójnóg
    line(img, 8, 14, 13, 24, BARK[1])
    line(img, 8, 14, 8, 24, BARK[2])
    for i in range(10):  # tuba skierowana w niebo
        x, y = 3 + i, 14 - i
        rect(img, x, y - 1, x + 1, y + 1, GOLD[1] if i % 4 else GOLD[2])
    rect(img, 12, 3, 14, 5, GOLD[0])
    put(img, 13, 4, hexc("7ec8ff"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 25, 6, 1.2)
    save(img, "telescope")


def herb_garden():
    img = new(36, 16)
    rng = random.Random(9)
    rect(img, 1, 5, 34, 14, BARK[1])
    rect(img, 2, 6, 33, 13, hexc("4a3020"))
    for x in range(4, 33, 4):
        h = rng.randint(3, 6)
        col = [MOSS[1], MOSS[2], hexc("8a6aa8"), hexc("c8a04a")][rng.randrange(4)]
        for k in range(h):
            put(img, x + (k % 2), 11 - k, MOSS[1] if k < h - 1 else col)
            put(img, x - 1 + (k % 2) * 2, 12 - k, MOSS[0])
        put(img, x, 11 - h, col)
    outline(img, OUTLINE_DARK)
    save(img, "herb_garden")


def owl_perch():
    """Sowa na żerdzi - 2 klatki (mrugnięcie)."""
    sheet = new(14 * 2, 28)
    for f in range(2):
        img = new(14, 28)
        rect(img, 6, 10, 7, 27, BARK[1])
        rect(img, 2, 10, 11, 11, BARK[2])
        rect(img, 4, 2, 9, 9, hexc("8a6a44"))
        rect(img, 5, 6, 8, 9, hexc("c8a878"))
        put(img, 4, 1, hexc("6b4a2c"))
        put(img, 9, 1, hexc("6b4a2c"))
        if f == 0:
            put(img, 5, 4, hexc("f2c94c"))
            put(img, 8, 4, hexc("f2c94c"))
        else:
            put(img, 5, 4, hexc("4e3420"))
            put(img, 8, 4, hexc("4e3420"))
        put(img, 6, 5, hexc("e0a020"))
        put(img, 7, 5, hexc("e0a020"))
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 7, 27, 4, 1)
        sheet.paste(img, (f * 14, 0))
    save(sheet, "owl_perch")


def rune_stone():
    img = new(14, 18)
    for y in range(2, 17):
        w = 5 if y > 4 else 3 + (y - 2)
        rect(img, 7 - w, y, 6 + w, y, STONE[2] if y < 8 else STONE[1])
    for x, y in ((6, 6), (6, 7), (7, 8), (6, 9), (5, 10), (8, 10), (6, 11), (6, 12)):
        put(img, x, y, hexc("7ec8ff"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 7, 17, 6, 1.2)
    save(img, "rune_stone")


# ---------------------------------------------------------------- gildia: wyposażenie i ozdoby
def notice_board():
    """Tablica ogłoszeń z daszkiem, przypiętymi kartkami, listami gończymi i lampionem."""
    img = new(40, 36)
    rect(img, 4, 8, 6, 35, BARK[1])  # słupki
    rect(img, 33, 8, 35, 35, BARK[1])
    rect(img, 4, 8, 4, 35, BARK[3])
    for y in range(0, 7):  # daszek
        rect(img, 2 + y // 2, y, 37 - y // 2, y, CRIMSON[1] if y % 2 else CRIMSON[2])
    rect(img, 1, 6, 38, 7, BARK[0])
    rect(img, 6, 10, 33, 28, BARK[2])  # tablica
    rect(img, 6, 10, 33, 10, BARK[3])
    rect(img, 6, 28, 33, 28, BARK[0])
    notes = [(8, 12, 7, 8, PAPER[2]), (17, 11, 6, 7, PAPER[1]), (25, 12, 7, 9, PAPER[2]),
             (9, 21, 6, 6, hexc("f2e0a0")), (18, 19, 8, 8, PAPER[2]), (27, 22, 5, 5, PAPER[1])]
    for x, y, w, h, col in notes:
        rect(img, x, y, x + w - 1, y + h - 1, col)
        for ty in range(y + 2, y + h - 1, 2):
            line(img, x + 1, ty, x + w - 2, ty, hexc("8a7a5a"))
        put(img, x + w // 2, y, hexc("c0392b"))  # pinezka
    # list gończy z czerwoną pieczęcią i portretem goblina
    rect(img, 19, 20, 24, 23, hexc("6aa84f"))
    put(img, 20, 21, BARK[0])
    put(img, 23, 21, BARK[0])
    put(img, 30, 25, hexc("c0392b"))
    rect(img, 15, 29, 24, 31, BARK[1])  # półeczka na pióro i kałamarz
    put(img, 17, 28, hexc("1a1c2c"))
    line(img, 21, 28, 23, 25, PAPER[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 20, 35, 16, 1.5)
    save(img, "notice_board")


def banner_pole():
    """Maszt z karmazynowym proporcem i złotym godłem - 2 klatki (łopotanie)."""
    sheet = new(16 * 2, 40)
    for f in range(2):
        img = new(16, 40)
        rect(img, 2, 2, 3, 39, BARK[1])
        put(img, 2, 1, GOLD[2])
        put(img, 3, 1, GOLD[2])
        for y in range(4, 22):
            wave = int(round(math.sin(y * 0.5 + f * math.pi) * 1.0))
            length = 10 - max(0, y - 17) * 2
            for x in range(4, 4 + length):
                put(img, x, y + (wave if x > 8 else 0), CRIMSON[2] if (x + y) % 7 else CRIMSON[1])
        rect(img, 7, 9, 10, 13, GOLD[2])
        put(img, 8, 10, GOLD[3])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 3, 39, 3, 1)
        sheet.paste(img, (f * 16, 0))
    save(sheet, "banner_pole")


def torch_stand():
    """Pochodnia na żelaznym stojaku - 2 klatki (płomień)."""
    sheet = new(10 * 2, 26)
    for f in range(2):
        img = new(10, 26)
        rect(img, 4, 9, 5, 25, hexc("3d3f4f"))
        rect(img, 2, 25, 7, 25, hexc("3d3f4f"))
        rect(img, 3, 7, 6, 9, hexc("4b4f63"))
        flame = [(4, 6), (5, 6), (3, 5), (4, 5), (5, 5), (6, 5), (4, 4), (5, 4), (4 + f, 3), (4 + f, 2)]
        for i, (x, y) in enumerate(flame):
            put(img, x, y, hexc("ffd27a") if i < 2 else hexc("ff8a20") if i < 8 else hexc("ffcf60"))
        outline(img, OUTLINE_DARK)
        sheet.paste(img, (f * 10, 0))
    save(sheet, "torch_stand")


def map_table():
    img = new(34, 20)
    rect(img, 1, 4, 32, 12, BARK[2])
    rect(img, 1, 4, 32, 4, BARK[3])
    rect(img, 3, 13, 4, 19, BARK[1])
    rect(img, 29, 13, 30, 19, BARK[1])
    rect(img, 5, 5, 28, 11, PAPER[1])  # mapa
    line(img, 7, 9, 13, 7, hexc("3f8f93"))
    line(img, 13, 7, 20, 8, hexc("3f8f93"))
    for x, y in ((10, 6), (22, 9), (17, 10)):
        put(img, x, y, MOSS[0])
    put(img, 24, 6, hexc("c0392b"))
    put(img, 25, 7, hexc("c0392b"))
    rect(img, 27, 2, 30, 4, hexc("dfe4ee"))  # kompas
    put(img, 28, 3, hexc("c0392b"))
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 17, 19, 14, 1.2)
    save(img, "map_table")


def trophy():
    """Trofeum na ścianę: łeb dzika na tarczy."""
    img = new(18, 16)
    rect(img, 2, 1, 15, 13, BARK[2])
    rect(img, 2, 1, 15, 1, BARK[3])
    rect(img, 5, 4, 12, 11, hexc("5a3a28"))
    rect(img, 6, 9, 11, 12, hexc("7a5238"))
    put(img, 7, 6, hexc("e04a30"))
    put(img, 10, 6, hexc("e04a30"))
    put(img, 5, 11, hexc("f2ecd8"))
    put(img, 12, 11, hexc("f2ecd8"))
    put(img, 4, 3, hexc("5a3a28"))
    put(img, 13, 3, hexc("5a3a28"))
    outline(img, OUTLINE_DARK)
    save(img, "trophy")


def bench():
    img = new(30, 12)
    rect(img, 1, 3, 28, 6, BARK[2])
    rect(img, 1, 3, 28, 3, BARK[3])
    rect(img, 3, 7, 4, 11, BARK[1])
    rect(img, 25, 7, 26, 11, BARK[1])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 15, 11, 13, 1)
    save(img, "bench")


# ---------------------------------------------------------------- postacie
NPCS = [
    ("sage", person("e8e8f0", "b8b8c8", tunic("3d2d55", "2a1f3a", "54407a"), pants=hexc("3d2d55"),
                    beard=hexc("f0f0f8"), hood=hexc("54407a"), hood_d=hexc("3d2d55"))),
    ("guild_clerk", person("5c2e1a", "3a1c10", tunic("7a1f2e", "4a1420", "a82e40"), buckle=hexc("f2c94c"))),
    ("adventurer_a", person("c8a060", "a07c40", tunic("7d8192", "5b5e70", "a3a7b5"), pants=village_art.PANTS_BROWN,
                            buckle=hexc("c9d1e0"))),
    ("adventurer_b", person("2a2a2a", "151515", tunic("2f6f73", "1a4446", "3f8f93"), skin=(village_art.SKIN_TAN, village_art.SKIN_TAN_D),
                            hood=hexc("245a5d"), hood_d=hexc("1a4446"))),
]


def make_npcs():
    from generate_art import make_person_sheet
    os.makedirs(NPC_DIR, exist_ok=True)
    for name, palette in NPCS:
        make_person_sheet(palette, work=True).save(os.path.join(NPC_DIR, name + ".png"))


def make_all():
    sage_hut()
    guild()
    bookshelf(0)
    bookshelf(1)
    lectern()
    cauldron()
    telescope()
    herb_garden()
    owl_perch()
    rune_stone()
    notice_board()
    banner_pole()
    torch_stand()
    map_table()
    trophy()
    bench()
    make_npcs()
