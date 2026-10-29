"""Ikony przedmiotów przyzwania bossów (16x16), wytwarzanych w oknie rzemiosła:
- summon_chief.png - Krwawy Totem: kościany totem z czaszką i pulsującym sercem goblina,
- summon_alpha.png - Wilczy Róg: róg owinięty szarym futrem, z kłem na rzemieniu,
- summon_frog_chief.png - Muszla Bulgora: spiralna muszla z zielonym, bagiennym blaskiem.
Każda ma magiczną, fioletową poświatę przyzwania. Wywoływane z generate_art.py."""
import math
import os

from generate_art import OUT, OUTLINE_DARK, hexc, line, new, outline, put, rect

ITEMS = os.path.join(OUT, "items")
BONE = [hexc("7a6a52"), hexc("b8a888"), hexc("e8dcc0")]
MAGIC = hexc("b060ff")


def glow(img, color, strength=120):
    for y in range(16):
        for x in range(16):
            if img.getpixel((x, y))[3] != 0:
                continue
            near = any(0 <= x + dx < 16 and 0 <= y + dy < 16 and img.getpixel((x + dx, y + dy))[3] == 255
                       for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if near:
                put(img, x, y, (*color[:3], strength))


def chief():
    """Krwawy Totem: palik z czaszką na szczycie i sercem przywiązanym pośrodku."""
    img = new(16, 16)
    rect(img, 7, 6, 8, 15, BONE[1])  # palik
    rect(img, 7, 6, 7, 15, BONE[2])
    # czaszka
    rect(img, 5, 1, 10, 5, BONE[2])
    rect(img, 6, 6, 9, 6, BONE[1])
    put(img, 6, 3, hexc("200a0a"))
    put(img, 9, 3, hexc("200a0a"))
    put(img, 6, 3, hexc("ff3020"))
    put(img, 9, 3, hexc("ff3020"))
    put(img, 7, 5, hexc("5a4a3a"))
    put(img, 8, 5, hexc("5a4a3a"))
    # serce
    for x, y in ((6, 9), (7, 9), (9, 9), (10, 9), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10),
                 (6, 11), (7, 11), (8, 11), (9, 11), (7, 12), (8, 12)):
        put(img, x, y, hexc("b01818"))
    put(img, 6, 10, hexc("ff6050"))
    put(img, 7, 9, hexc("e83030"))
    rect(img, 5, 13, 10, 13, hexc("6a4a2a"))  # rzemień
    outline(img, OUTLINE_DARK)
    glow(img, MAGIC)
    return img


def alpha():
    """Wilczy Róg: zakrzywiony róg z futrem przy ustniku i kłem na rzemieniu."""
    img = new(16, 16)
    for i in range(11):
        t = i / 10.0
        cx = 3 + i
        cy = 11 - int(5 * math.sin(t * math.pi * 0.9))
        r = 2.4 - t * 1.6
        for y in range(16):
            for x in range(16):
                if math.hypot(x - cx, y - cy) <= r:
                    put(img, x, y, BONE[2] if y < cy else BONE[1])
    put(img, 13, 5, BONE[0])
    for x, y in ((2, 10), (3, 9), (2, 11), (3, 12), (4, 12), (4, 9), (2, 12), (5, 12)):  # futro
        put(img, x, y, hexc("8a8a94"))
    put(img, 3, 10, hexc("c8c8d0"))
    rect(img, 7, 12, 7, 13, hexc("6a4a2a"))
    put(img, 7, 14, hexc("f2f2e6"))
    put(img, 8, 14, hexc("f2f2e6"))
    put(img, 8, 15, hexc("f2f2e6"))
    outline(img, OUTLINE_DARK)
    glow(img, MAGIC)
    return img


def frog_chief():
    """Muszla Bulgora: spiralna muszla z zielonym blaskiem w środku."""
    img = new(16, 16)
    shell = [hexc("9a6a4a"), hexc("d8a878"), hexc("f4dcc0")]
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, (y - 8.5) * 1.15)
            if d <= 6.2:
                a = math.atan2(y - 8.5, x - 7.5)
                band = (d * 1.2 + a * 1.1) % 3
                put(img, x, y, shell[int(band)])
    for y in range(6, 12):  # otwór muszli z bagiennym blaskiem
        for x in range(9, 14):
            if math.hypot(x - 11, y - 9) <= 2.2:
                put(img, x, y, hexc("3fd070") if math.hypot(x - 11.5, y - 8.5) < 1.2 else hexc("1a6a3a"))
    put(img, 3, 3, shell[2])
    put(img, 2, 2, shell[1])
    outline(img, OUTLINE_DARK)
    glow(img, MAGIC)
    return img


def storm_eagle():
    """Burzowy Wabik: pęk piór burzy związany rzemieniem, z iskrzącym kryształem."""
    img = new(16, 16)
    for k, (x0, y0) in enumerate(((4, 14), (7, 15), (10, 14))):
        x1, y1 = x0 + (k - 1) * 3, 2 + abs(k - 1) * 2
        line(img, x0, y0, x1, y1, hexc("8a7a5a"))
        for i in range(8):
            x, y = x0 + (x1 - x0) * i // 8, y0 + (y1 - y0) * i // 8
            put(img, x - 1, y, hexc("f0ece0") if i > 4 else hexc("6b4a2c"))
            put(img, x + 1, y, hexc("8ac8ff") if i > 5 else hexc("4a3020"))
    rect(img, 5, 11, 10, 12, hexc("6a4a2a"))
    rect(img, 7, 9, 8, 10, hexc("3f7fe0"))
    put(img, 7, 9, hexc("e8f6ff"))
    outline(img, OUTLINE_DARK)
    glow(img, MAGIC)
    return img


def make_all():
    os.makedirs(ITEMS, exist_ok=True)
    chief().save(os.path.join(ITEMS, "summon_chief.png"))
    alpha().save(os.path.join(ITEMS, "summon_alpha.png"))
    frog_chief().save(os.path.join(ITEMS, "summon_frog_chief.png"))
    storm_eagle().save(os.path.join(ITEMS, "summon_storm_eagle.png"))
