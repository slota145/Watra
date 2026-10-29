"""Grafiki osady Ostoja: mieszkańcy, budynki (podłoga + dach z fasadą), palisada,
meble, przedmioty noszone przez tragarzy i mikstury. Wywoływane z generate_art.py."""
import math
import os
import random

from generate_art import (BARK, CLEAR, EYE, GRASS, OUT, OUTLINE_DARK, STONE, hexc, line, make_person_sheet,
                          new, outline, put, rect, shadow_ellipse)

VILLAGE = os.path.join(OUT, "village")
NPC_DIR = os.path.join(OUT, "npc")
ITEMS = os.path.join(OUT, "items")

SKIN = hexc("f4c29a")
SKIN_D = hexc("d08f6a")
SKIN_TAN = hexc("d9a67a")
SKIN_TAN_D = hexc("b07a52")
PANTS = hexc("4a4e6d")
PANTS_BROWN = hexc("5a4632")
BOOTS = hexc("4a2f1d")
BELT = hexc("6b3e1f")

FLOOR = [hexc("5e4128"), hexc("7e5636"), hexc("9c7048"), hexc("b0845a")]
WOOD_WALL = [hexc("3a2215"), hexc("5a3a20"), hexc("7a5230"), hexc("96683e"), hexc("b08050")]
STONE_WALL = [hexc("2c2e3a"), STONE[0], STONE[1], STONE[2], STONE[3]]
DOOR = hexc("2a1a10")
WINDOW = hexc("f2c94c")
WINDOW_L = hexc("fff3b0")


def tunic(base, dark, light):
    return {"tunic": hexc(base), "tunic_d": hexc(dark), "tunic_l": hexc(light)}


def person(hair, hair_d, clothes, skin=(SKIN, SKIN_D), pants=PANTS, **extra):
    p = {"skin": skin[0], "skin_d": skin[1], "hair": hexc(hair), "hair_d": hexc(hair_d),
         "belt": BELT, "buckle": hexc("a87a48"), "pants": pants, "boots": BOOTS}
    p.update(clothes)
    p.update(extra)
    return p


# (nazwa pliku, paleta, czy ma wiersz pracy)
NPCS = [
    ("villager_brown", person("3a2a1a", "241a10", tunic("8a6d4a", "6b5236", "a8875e")), False),
    ("villager_green", person("c8a060", "a07c40", tunic("6a8a4a", "4f6b36", "86a85e")), False),
    ("villager_red", person("5c2e1a", "3a1c10", tunic("a8564a", "7d3e36", "c4705e"), skin=(SKIN_TAN, SKIN_TAN_D)), False),
    ("worker_gray", person("6b4226", "4e2f1b", tunic("7a7a8a", "5b5b6b", "9696a6"), pants=PANTS_BROWN), False),
    ("worker_ochre", person("2a2a2a", "151515", tunic("b08a3a", "8a6a2a", "c8a45a"), skin=(SKIN_TAN, SKIN_TAN_D)), False),
    ("smith", person("2a2a2a", "151515", tunic("6b4226", "4e2f1b", "8a5a34"), skin=(SKIN_TAN, SKIN_TAN_D),
                     apron=hexc("3d3f4f"), beard=hexc("2a2a2a"), tool="hammer"), True),
    ("hunter", person("5c2e1a", "3a1c10", tunic("4a5e35", "36452a", "62784a"), pants=PANTS_BROWN,
                      hood=hexc("3e5030"), hood_d=hexc("2c3a22"), tool="knife"), True),
    ("builder", person("8a4b2a", "5c2e1a", tunic("8a5a34", "6b4226", "a8743f"), pants=PANTS_BROWN, tool="hammer"), True),
    ("merchant", person("9a9a9a", "707070", tunic("6a3d8a", "4e2a68", "8a5aa8"), beard=hexc("b0b0b0"),
                        buckle=hexc("f2c94c")), False),
    ("barkeep", person("8a4b2a", "5c2e1a", tunic("a8743f", "86592e", "c4905a"), apron=hexc("e8e0d0")), False),
    ("storekeeper", person("6b6b6b", "4a4a4a", tunic("5a6a3a", "45522c", "72844a"), pants=PANTS_BROWN,
                           apron=hexc("8a6a44"), beard=hexc("6b6b6b"), helmet=hexc("6b4a2c"), helmet_d=hexc("4e3420")), False),
    ("guard", person("3a2a1a", "241a10", tunic("7d8192", "5b5e70", "a3a7b5"), helmet=hexc("5b5e70"),
                     helmet_d=hexc("3d3f4f"), buckle=hexc("c9d1e0")), False),
]


def make_npcs():
    os.makedirs(NPC_DIR, exist_ok=True)
    for name, palette, _work in NPCS:
        # każdy ma wiersz pracy (pracownicy z narzędziem, reszta bez - i tak go nie używa)
        make_person_sheet(palette, work=True).save(os.path.join(NPC_DIR, name + ".png"))


# ---------------------------------------------------------------- budynki
def wall_pattern(img, x0, y0, x1, y1, style, rng):
    """Ściana z poziomych bali (drewno) albo cegieł (kamień)."""
    pal = WOOD_WALL if style == "wood" else STONE_WALL
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if style == "wood":
                k = (y - y0) % 5
                c = pal[3] if k == 0 else pal[1] if k == 4 else pal[2]
                if rng.random() < 0.05:
                    c = pal[1]
            else:
                row = (y - y0) // 4
                k = (y - y0) % 4
                brick_edge = (x - x0 + (row % 2) * 4) % 8 == 0
                c = pal[1] if k == 3 or brick_edge else pal[3] if k == 0 else pal[2]
                if rng.random() < 0.06 and not brick_edge:
                    c = pal[4]
            put(img, x, y, c)


# Rozmiary podłóg w pikselach dla budynków z dachami z PixelLab (tools/village_buildings.py ustawia je
# na wymiary grafiki dachu); pozostałe budynki mają rozmiar w kafelkach * 16.
SIZE_OVERRIDE = {}


def make_building(name, w, h, roof, style, sign, chimney, rooms=False):
    rng = random.Random(sum(map(ord, name)))
    W, H = SIZE_OVERRIDE.get(name, (w * 16, h * 16))
    door_l, door_r = W // 2 - 10, W // 2 + 9
    wall = WOOD_WALL if style == "wood" else STONE_WALL

    # --- wnętrze (podłoga + ściany widoczne od środka)
    fl = new(W, H)
    for y in range(H):
        board = y // 5
        offset = (board * 11) % 24
        for x in range(W):
            if y % 5 == 4:
                c = FLOOR[0]
            elif (x + offset) % 24 == 0:
                c = FLOOR[1]
            else:
                r = rng.random()
                c = FLOOR[3] if r < 0.04 else FLOOR[1] if r < 0.1 else FLOOR[2]
            fl.putpixel((x, y), c)
    wall_pattern(fl, 0, 0, W - 1, 27, style, rng)
    rect(fl, 0, 0, W - 1, 3, wall[0])  # wierzch tylnej ściany
    for y in range(28, 31):  # cień pod ścianą
        for x in range(W):
            r, g, b, a = fl.getpixel((x, y))
            fl.putpixel((x, y), (int(r * 0.7), int(g * 0.7), int(b * 0.7), a))
    rect(fl, 0, 0, 3, H - 1, wall[1])
    rect(fl, W - 4, 0, W - 1, H - 1, wall[1])
    rect(fl, 3, 4, 3, H - 1, wall[2])
    rect(fl, W - 4, 4, W - 4, H - 1, wall[0])
    rect(fl, 0, H - 5, W - 1, H - 1, wall[1])
    rect(fl, 0, H - 5, W - 1, H - 5, wall[2])
    rect(fl, door_l, H - 5, door_r, H - 1, FLOOR[1])  # próg
    if rooms:
        draw_rooms(fl, W, H, wall, rng)

    # --- z zewnątrz: dach + fasada
    ex = new(W, H)
    facade = 30
    roof_h = H - facade
    for y in range(roof_h):
        row = y // 5
        t = y / max(1, roof_h - 1)
        base = roof[2] if t < 0.25 else roof[1] if t < 0.8 else roof[0]
        for x in range(W):
            seam = (x + (row % 2) * 4) % 8 == 0
            c = roof[0] if (y % 5 == 4 or seam) else base
            if not seam and y % 5 == 0 and t < 0.8:
                c = roof[3] if t < 0.25 else roof[2]
            ex.putpixel((x, y), c)
    rect(ex, 0, 0, W - 1, 1, roof[3])  # kalenica
    rect(ex, 0, roof_h - 2, W - 1, roof_h - 1, roof[0])  # okap
    wall_pattern(ex, 0, roof_h, W - 1, H - 1, style, rng)
    for y in range(roof_h, roof_h + 2):  # cień okapu
        for x in range(W):
            r, g, b, a = ex.getpixel((x, y))
            ex.putpixel((x, y), (int(r * 0.6), int(g * 0.6), int(b * 0.6), a))
    # drzwi
    rect(ex, door_l + 1, H - 22, door_r - 1, H - 1, DOOR)
    rect(ex, door_l, H - 23, door_r, H - 23, wall[0])
    rect(ex, door_l, H - 22, door_l, H - 1, wall[0])
    rect(ex, door_r, H - 22, door_r, H - 1, wall[0])
    # okna z ciepłym światłem
    for wx in (W // 4, W - W // 4):
        if abs(wx - W // 2) < 18:
            continue
        rect(ex, wx - 5, H - 21, wx + 4, H - 12, wall[0])
        rect(ex, wx - 4, H - 20, wx + 3, H - 13, WINDOW)
        rect(ex, wx - 4, H - 20, wx - 3, H - 19, WINDOW_L)
        rect(ex, wx, H - 20, wx, H - 13, wall[0])
        rect(ex, wx - 4, H - 17, wx + 3, H - 17, wall[0])
    # komin
    if chimney:
        cx = int(W * 0.75)
        rect(ex, cx, 2, cx + 7, 12, STONE[1])
        rect(ex, cx, 2, cx + 7, 3, STONE[2])
        rect(ex, cx + 1, 2, cx + 6, 2, hexc("1a1c2c"))
    # szyld nad drzwiami
    sx, sy = W // 2 - 7, roof_h - 6
    rect(ex, sx, sy, sx + 13, sy + 8, hexc("c89a64"))
    rect(ex, sx, sy, sx + 13, sy, hexc("e0b880"))
    for (px, py), col in SIGNS[sign]:
        put(ex, sx + 4 + px, sy + 2 + py, hexc(col))
    # obrys
    for x in range(W):
        put(ex, x, 0, OUTLINE_DARK)
        put(ex, x, H - 1, OUTLINE_DARK)
    for y in range(H):
        put(ex, 0, y, OUTLINE_DARK)
        put(ex, W - 1, y, OUTLINE_DARK)

    fl.save(os.path.join(VILLAGE, f"{name}_floor.png"))
    ex.save(os.path.join(VILLAGE, f"{name}_roof.png"))


def sign_pixels(rows, colors):
    out = []
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in colors:
                out.append(((x, y), colors[ch]))
    return out


# Pokoje gościnne w karczmie: ściana działowa z dwojgiem drzwi i ściana między pokojami.
# Te same liczby (piksele od lewego górnego rogu) ma Settlement.TAVERN_ROOM_WALLS.
# Liczby dotyczą karczmy 192x112 - przy innym rozmiarze podłogi skalujemy je proporcjonalnie (tak samo gra).
ROOM_X = 136
ROOM_SPLIT_Y = 64
ROOM_DOORS = ((40, 58), (84, 102))
ROOM_BASE = (192, 112)


def draw_rooms(fl, W, H, wall, rng):
    sx, sy = W / ROOM_BASE[0], H / ROOM_BASE[1]
    room_x, split_y = round(ROOM_X * sx), round(ROOM_SPLIT_Y * sy)
    doors = [(round(a * sy), round(b * sy)) for a, b in ROOM_DOORS]
    # podłoga pokoi - ciemniejsze deski
    for y in range(31, H - 5):
        for x in range(room_x + 4, W - 4):
            r, g, b, a = fl.getpixel((x, y))
            fl.putpixel((x, y), (int(r * 0.85), int(g * 0.82), int(b * 0.8), a))
    # ściana działowa (widok z góry) z otworami na drzwi
    for y in range(26, H - 5):
        if any(d0 <= y < d1 for d0, d1 in doors):
            continue
        rect(fl, room_x, y, room_x + 3, y, wall[2])
        put(fl, room_x, y, wall[3])
        put(fl, room_x + 3, y, wall[0])
    for d0, d1 in doors:  # futryny
        rect(fl, room_x, d0 - 1, room_x + 3, d0 - 1, wall[0])
        rect(fl, room_x, d1, room_x + 3, d1, wall[0])
    # ściana między pokojami: wierzch + fasada z bali
    wall_pattern(fl, room_x + 4, split_y + 3, W - 5, split_y + 12, "wood", rng)
    rect(fl, room_x + 4, split_y, W - 5, split_y + 2, wall[0])
    for x in range(room_x + 4, W - 4):  # cień pod ścianą
        for y in range(split_y + 13, split_y + 15):
            r, g, b, a = fl.getpixel((x, y))
            fl.putpixel((x, y), (int(r * 0.7), int(g * 0.7), int(b * 0.7), a))


SIGNS = {
    "mug": sign_pixels(["wwww.", "yyyyy", "yyy.y", "yyyyy", "yyy.."], {"w": "f4f7fb", "y": "e0a020"}),
    "crate": sign_pixels(["bbbbb", "b.b.b", "bbbbb", "b.b.b", "bbbbb"], {"b": "6b4226"}),
    "anvil": sign_pixels([".....", "sssss", ".sss.", "..s..", ".sss."], {"s": "3d3f4f"}),
    "bow": sign_pixels([".b...", "b.s..", "b..s.", "b.s..", ".b..."], {"b": "6b4226", "s": "e8e0d0"}),
    "crown": sign_pixels(["y.y.y", "yyyyy", "yrryy", "yyyyy", "....."], {"y": "e0a020", "r": "c0392b"}),
    "sword": sign_pixels(["....s", "...s.", "y.s..", ".y...", "b.y.."], {"s": "c9d1e0", "y": "e0a020", "b": "6b4226"}),
    "potion": sign_pixels(["..c..", ".ggg.", "grrrg", "grrrg", ".ggg."], {"c": "6b4226", "g": "a3a7b5", "r": "c0392b"}),
}

BUILDINGS = [
    # nazwa, szer., wys. (kafelki), dach, ściany, szyld, komin
    ("tavern", 12, 7, [hexc("6e231c"), hexc("8e2f25"), hexc("a83e30"), hexc("c4553f")], "wood", "mug", True, True),
    ("warehouse", 8, 6, [hexc("4e3420"), hexc("6b4a2c"), hexc("86603a"), hexc("a07848")], "wood", "crate", False),
    ("smithy", 7, 6, [hexc("2c2e3a"), hexc("3d4050"), hexc("4b4f63"), hexc("646a82")], "stone", "anvil", True),
    ("shop", 8, 6, [hexc("1a4446"), hexc("245a5d"), hexc("2f6f73"), hexc("3f8f93")], "wood", "potion", False),
    ("chief_house", 8, 6, [hexc("2a3a52"), hexc("34496a"), hexc("43608a"), hexc("5a7aa8")], "wood", "crown", True),
    ("lodge", 8, 6, [hexc("2e3a1c"), hexc("3e4d26"), hexc("4f6230"), hexc("67803e")], "wood", "bow", True),
    ("barracks", 12, 7, [hexc("3a2a20"), hexc("54402e"), hexc("6e5640"), hexc("8a7054")], "stone", "sword", False),
]


# ---------------------------------------------------------------- palisada i rekwizyty
def make_palisade():
    img = new(16, 30)
    for i, x0 in enumerate((0, 5, 11)):
        w = 5 if i < 2 else 5
        top = 4 + (i % 2) * 2
        for x in range(x0, min(16, x0 + w)):
            peak = abs(x - (x0 + w // 2))
            for y in range(top + peak, 28):
                c = BARK[3] if x == x0 else BARK[1] if x == x0 + w - 1 else BARK[2]
                put(img, x, y, c)
        put(img, x0 + 2, 14, BARK[0])
    rect(img, 0, 18, 15, 19, hexc("8a7a4a"))  # wiązanie liną
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 8, 28, 8, 2)
    img.save(os.path.join(VILLAGE, "palisade.png"))

    broken = new(16, 30)
    for x0, top in ((0, 16), (5, 21), (11, 13)):
        for x in range(x0, x0 + 5):
            for y in range(top + (x % 2), 28):
                put(broken, x, y, BARK[2] if x != x0 else BARK[3])
    put(broken, 7, 20, hexc("e0c090"))  # świeże drzazgi
    put(broken, 12, 12, hexc("e0c090"))
    outline(broken, OUTLINE_DARK)
    shadow_ellipse(broken, 8, 28, 8, 2)
    broken.save(os.path.join(VILLAGE, "palisade_broken.png"))


def save(img, name, shadow=None):
    if shadow:
        shadow_ellipse(img, *shadow)
    img.save(os.path.join(VILLAGE, name + ".png"))


def make_props():
    plank_c = [hexc("a8743f"), hexc("c89a64"), hexc("86592e")]

    # deska noszona przez tragarzy
    plank = new(24, 6)
    rect(plank, 1, 1, 22, 4, plank_c[0])
    rect(plank, 1, 1, 22, 1, plank_c[1])
    rect(plank, 1, 4, 22, 4, plank_c[2])
    outline(plank, OUTLINE_DARK)
    save(plank, "plank")

    # stos desek - 4 klatki (1-4 deski)
    pile = new(26 * 4, 16)
    for n in range(1, 5):
        img = new(26, 16)
        for k in range(n):
            y = 12 - k * 3
            rect(img, 1 + (k % 2), y, 23 + (k % 2), y + 2, plank_c[0])
            rect(img, 1 + (k % 2), y, 23 + (k % 2), y, plank_c[1])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 13, 15, 12, 1.5)
        pile.paste(img, ((n - 1) * 26, 0))
    pile.save(os.path.join(VILLAGE, "plank_pile.png"))

    # beczka
    barrel = new(12, 15)
    rect(barrel, 1, 2, 10, 13, BARK[2])
    rect(barrel, 2, 1, 9, 1, BARK[2])
    rect(barrel, 2, 14, 9, 14, BARK[1])
    rect(barrel, 1, 2, 2, 13, BARK[3])
    rect(barrel, 9, 2, 10, 13, BARK[1])
    rect(barrel, 1, 4, 10, 4, STONE[1])
    rect(barrel, 1, 11, 10, 11, STONE[1])
    rect(barrel, 3, 1, 8, 2, hexc("c89a64"))
    outline(barrel, OUTLINE_DARK)
    save(barrel, "barrel")

    # skrzynia
    crate = new(14, 14)
    rect(crate, 0, 0, 13, 13, plank_c[0])
    rect(crate, 0, 0, 13, 1, plank_c[1])
    rect(crate, 0, 0, 1, 13, plank_c[2])
    rect(crate, 12, 0, 13, 13, plank_c[2])
    rect(crate, 0, 12, 13, 13, plank_c[2])
    line(crate, 2, 2, 11, 11, plank_c[2])
    outline(crate, OUTLINE_DARK)
    save(crate, "crate")

    # stół
    table = new(26, 16)
    rect(table, 1, 1, 24, 8, plank_c[0])
    rect(table, 1, 1, 24, 1, plank_c[1])
    rect(table, 1, 8, 24, 9, plank_c[2])
    rect(table, 3, 10, 4, 14, BARK[1])
    rect(table, 21, 10, 22, 14, BARK[1])
    put(table, 7, 4, hexc("e0a020"))  # kufel
    put(table, 7, 3, hexc("f4f7fb"))
    put(table, 16, 5, hexc("c9d1e0"))
    outline(table, OUTLINE_DARK)
    save(table, "table")

    # stołek
    stool = new(10, 10)
    rect(stool, 1, 1, 8, 4, plank_c[0])
    rect(stool, 1, 1, 8, 1, plank_c[1])
    rect(stool, 2, 5, 2, 8, BARK[1])
    rect(stool, 7, 5, 7, 8, BARK[1])
    outline(stool, OUTLINE_DARK)
    save(stool, "stool")

    # lada
    counter = new(50, 20)
    rect(counter, 0, 0, 49, 7, plank_c[1])
    rect(counter, 0, 0, 49, 0, hexc("e0b880"))
    rect(counter, 0, 8, 49, 19, plank_c[2])
    for x in range(0, 50, 8):
        rect(counter, x, 8, x, 19, BARK[1])
    outline(counter, OUTLINE_DARK)
    save(counter, "counter")

    # półka z miksturami
    shelf = new(32, 26)
    rect(shelf, 0, 0, 31, 25, BARK[1])
    for y in (7, 15, 23):
        rect(shelf, 0, y, 31, y + 1, plank_c[0])
    rng = random.Random(5)
    for y in (2, 10, 18):
        for x in range(2, 30, 4):
            if rng.random() < 0.8:
                col = rng.choice(["c0392b", "3b6fd8", "6aa84f", "e0a020"])
                rect(shelf, x, y + 1, x + 1, y + 4, hexc(col))
                put(shelf, x, y, hexc("a3a7b5"))
    outline(shelf, OUTLINE_DARK)
    save(shelf, "shelf")

    # palenisko kowala
    forge = new(26, 26)
    rect(forge, 1, 6, 24, 24, STONE[1])
    rect(forge, 1, 6, 24, 7, STONE[2])
    for y in range(9, 24, 4):
        for x in range(1, 25, 6):
            put(forge, x + (y // 4 % 2) * 3, y, STONE[0])
    rect(forge, 5, 2, 20, 9, STONE[0])
    rect(forge, 7, 4, 18, 9, hexc("c0392b"))
    rect(forge, 9, 5, 16, 8, hexc("e67e22"))
    rect(forge, 11, 6, 14, 8, hexc("fdf2a6"))
    outline(forge, OUTLINE_DARK)
    save(forge, "forge")

    # kowadło
    anvil = new(18, 12)
    rect(anvil, 1, 1, 15, 3, STONE[1])
    rect(anvil, 1, 1, 15, 1, STONE[3])
    rect(anvil, 15, 2, 17, 2, STONE[1])
    rect(anvil, 5, 4, 11, 7, STONE[0])
    rect(anvil, 3, 8, 13, 10, BARK[1])  # pieniek
    rect(anvil, 9, 0, 13, 0, hexc("e67e22"))  # rozgrzane żelazo
    outline(anvil, OUTLINE_DARK)
    save(anvil, "anvil")

    # stojak na broń
    rack = new(22, 24)
    rect(rack, 1, 6, 20, 7, BARK[2])
    rect(rack, 1, 18, 20, 19, BARK[2])
    rect(rack, 2, 4, 3, 22, BARK[1])
    rect(rack, 18, 4, 19, 22, BARK[1])
    for x in (6, 10, 14):
        rect(rack, x, 1, x, 17, hexc("c9d1e0"))
        put(rack, x, 0, hexc("f4f7fb"))
        rect(rack, x - 1, 14, x + 1, 14, hexc("f2c94c"))
        rect(rack, x, 15, x, 18, BARK[2])
    outline(rack, OUTLINE_DARK)
    save(rack, "weapon_rack")

    # rama do suszenia skór
    hide = new(24, 28)
    rect(hide, 1, 2, 2, 26, BARK[2])
    rect(hide, 21, 2, 22, 26, BARK[2])
    rect(hide, 0, 3, 23, 4, BARK[3])
    pelt = [hexc("8a5a34"), hexc("a8743f"), hexc("6b4226")]
    for y in range(6, 22):
        half = 7 - abs(y - 13) // 3
        for x in range(12 - half, 12 + half):
            put(hide, x, y, pelt[0] if (x + y) % 5 else pelt[2])
    rect(hide, 8, 8, 10, 10, pelt[1])
    outline(hide, OUTLINE_DARK)
    save(hide, "hide_rack")

    # skóra rozłożona na ziemi (do oprawiania)
    pelt_img = new(20, 12)
    for y in range(1, 11):
        half = 8 - abs(y - 6)
        for x in range(10 - half, 10 + half):
            put(pelt_img, x, y, pelt[1] if (x * y) % 7 else pelt[0])
    outline(pelt_img, OUTLINE_DARK)
    save(pelt_img, "pelt")

    # studnia
    well = new(26, 28)
    rect(well, 2, 14, 23, 25, STONE[1])
    rect(well, 2, 14, 23, 15, STONE[2])
    rect(well, 5, 16, 20, 19, hexc("1a2a3a"))
    rect(well, 3, 2, 4, 15, BARK[2])
    rect(well, 21, 2, 22, 15, BARK[2])
    rect(well, 1, 1, 24, 3, hexc("8e2f25"))
    line(well, 12, 4, 12, 15, hexc("c8a46e"))
    rect(well, 11, 12, 13, 14, BARK[1])
    outline(well, OUTLINE_DARK)
    save(well, "well")


def make_potions():
    os.makedirs(ITEMS, exist_ok=True)
    for name, liquid, liquid_d in (("health_potion", "d63a3a", "8e1b2b"), ("mana_potion", "3b6fd8", "23458e")):
        img = new(12, 14)
        rect(img, 4, 0, 7, 1, BARK[2])  # korek
        rect(img, 4, 2, 7, 4, hexc("c9d1e0"))
        rect(img, 2, 5, 9, 12, hexc("c9d1e0"))
        rect(img, 3, 6, 8, 12, hexc(liquid))
        rect(img, 3, 10, 8, 12, hexc(liquid_d))
        put(img, 4, 7, hexc("ffffff"))
        put(img, 4, 8, hexc("f4f7fb"))
        outline(img, OUTLINE_DARK)
        img.save(os.path.join(ITEMS, name + ".png"))


def make_wood_art():
    """Ikona drewna i stos kłód przy magazynie (4 wielkości)."""
    bark, bark_d, ring, ring_d = BARK[2], BARK[1], hexc("d8b07a"), hexc("b08050")

    def log_end(img, cx, cy, r=3):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                d = math.hypot(x - cx, y - cy)
                if d <= r + 0.3:
                    put(img, x, y, bark_d if d > r - 0.7 else ring_d if d > r - 1.7 else ring)
        put(img, cx, cy, ring_d)

    icon = new(16, 16)
    for y in range(6, 12):
        for x in range(2, 13):
            put(icon, x, y, bark if 7 <= y <= 10 else bark_d)
    for x in (4, 8, 11):
        put(icon, x, 8, bark_d)
    log_end(icon, 12, 9, 3)
    outline(icon, OUTLINE_DARK)
    icon.save(os.path.join(OUT, "items", "wood.png"))

    # stos: 1 - 3 kłody, 2 - 6, 3 - 10, 4 - 15 (piramida)
    rows_for = {1: [2, 1], 2: [3, 2, 1], 3: [4, 3, 2, 1], 4: [5, 4, 3, 2, 1]}
    sheet = new(36 * 4, 30)
    for stage in range(1, 5):
        img = new(36, 30)
        rows = rows_for[stage]
        for r, count in enumerate(rows):
            y = 26 - r * 6
            x0 = 18 - count * 3
            for i in range(count):
                log_end(img, x0 + i * 6 + 3, y, 3)
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 18, 28, 16, 2)
        sheet.paste(img, ((stage - 1) * 36, 0))
    sheet.save(os.path.join(VILLAGE, "wood_pile.png"))


def make_all():
    os.makedirs(VILLAGE, exist_ok=True)
    make_wood_art()
    make_npcs()
    for b in BUILDINGS:
        make_building(*b)
    make_palisade()
    make_props()
    make_potions()
