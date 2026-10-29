"""Ikony legendarnych pierścieni i kolczyków (16x16): złota, zdobiona obręcz, duży szlachetny kamień
i pomarańczowa poświata - żeby od razu było widać, że to coś wyjątkowego.
Wywoływane z generate_art.py."""
import math
import os

from generate_art import OUT, OUTLINE_DARK, hexc, line, new, outline, put, rect

ITEMS = os.path.join(OUT, "items")
GOLD = [hexc("8a5a10"), hexc("c8901c"), hexc("f2c94c"), hexc("fff3b0")]
SILVER = [hexc("5b5e70"), hexc("a3a7b5"), hexc("dfe4ee"), hexc("ffffff")]


def glow(img, color):
    """Miękka poświata wokół pierścienia (pod obrysem)."""
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, y - 8.5)
            if 6.0 < d < 7.8 and img.getpixel((x, y))[3] == 0:
                put(img, x, y, (*color[:3], int(150 * (7.8 - d) / 1.8)))


def band(img, metal):
    for y in range(16):
        for x in range(16):
            d = math.hypot((x + 0.5 - 8) / 1.0, (y + 0.5 - 10) / 0.85)
            if 3.4 <= d <= 5.6:
                light = (x - 8) + (y - 10) < -2
                put(img, x, y, metal[3] if light and d > 4.8 else metal[2] if light else metal[1] if d < 4.6 else metal[0])


def gem(img, cx, cy, colors, size=2):
    for y in range(cy - size, cy + size + 1):
        for x in range(cx - size, cx + size + 1):
            if abs(x - cx) + abs(y - cy) <= size:
                put(img, x, y, colors[1])
    put(img, cx - 1, cy - 1, colors[2])
    put(img, cx, cy - size, colors[2])
    put(img, cx + size, cy, colors[0])
    put(img, cx, cy + size, colors[0])


def gruzlog():
    """Sygnet Gruzłoga: ciężka złota obręcz z rubinem i kłami po bokach."""
    img = new(16, 16)
    band(img, GOLD)
    rect(img, 5, 2, 10, 6, GOLD[1])  # oprawa
    gem(img, 8, 4, [hexc("6e1010"), hexc("d02828"), hexc("ff9a8a")])
    for x, y in ((4, 3), (3, 2), (11, 3), (12, 2)):  # kły
        put(img, x, y, hexc("f2f2e6"))
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ff8a20"))
    return img


def alpha():
    """Kieł Alfy: srebrna obręcz, wilczy kieł i lodowo-błękitny kamień."""
    img = new(16, 16)
    band(img, SILVER)
    rect(img, 5, 3, 10, 6, SILVER[1])
    gem(img, 8, 4, [hexc("1d4a8a"), hexc("5aa8ff"), hexc("d0f0ff")])
    for k in range(4):  # kieł zwisający z oprawy
        rect(img, 11 + (k > 1), 5 + k, 11 + (k > 1), 5 + k, hexc("f2f2e6"))
    rect(img, 4, 4, 4, 5, GOLD[2])
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ffa040"))
    return img


def bulgor():
    """Oko Przypływu: złota obręcz z falą, morski kamień i muszelki."""
    img = new(16, 16)
    band(img, GOLD)
    for x in range(4, 13):  # fala wyryta w obręczy
        put(img, x, 13 + int(math.sin(x * 1.3) > 0), hexc("3fb8b0"))
    rect(img, 5, 2, 10, 6, GOLD[1])
    gem(img, 8, 4, [hexc("0f5a58"), hexc("2fc8b8"), hexc("c0fff4")])
    put(img, 3, 4, hexc("f4e4d0"))
    put(img, 12, 4, hexc("f4e4d0"))
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ff9a30"))
    return img


def hook(img, metal):
    """Złote kółko kolczyka u góry."""
    for t in range(9):
        a = math.pi * (0.15 + t / 8 * 1.3)
        put(img, int(round(8 + math.cos(a) * 3)), int(round(3.5 - math.sin(a) * 3)), metal[2])
    rect(img, 8, 4, 8, 6, metal[1])


def earring_gruzlog():
    """Kolczyk Gruzłoga: ciężki złoty kieł z rubinową oprawą."""
    img = new(16, 16)
    hook(img, GOLD)
    rect(img, 6, 6, 10, 8, GOLD[1])
    rect(img, 6, 6, 10, 6, GOLD[2])
    gem(img, 8, 7, [hexc("6e1010"), hexc("d02828"), hexc("ff9a8a")], 1)
    for y in range(9, 15):  # kieł
        w = max(0, (15 - y) // 2)
        rect(img, 8 - w // 2, y, 8 + (w + 1) // 2, y, hexc("f2ecd8") if y < 13 else hexc("d8ccb0"))
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ff8a20"))
    return img


def earring_alpha():
    """Pazur Szarokła: srebrny kolczyk z trzema wilczymi pazurami."""
    img = new(16, 16)
    hook(img, SILVER)
    rect(img, 6, 6, 10, 7, SILVER[2])
    put(img, 8, 6, hexc("5aa8ff"))
    for k, x0 in enumerate((5, 8, 11)):  # trzy zakrzywione pazury
        for i in range(6):
            x = x0 + (1 if i > 3 else 0) * (1 if k == 2 else -1 if k == 0 else 0)
            put(img, x, 8 + i, hexc("eeeef4") if i < 4 else hexc("b8b8c4"))
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ffa040"))
    return img


def earring_bulgor():
    """Łza Bulgora: złoty kolczyk z wielką, morską kroplą."""
    img = new(16, 16)
    hook(img, GOLD)
    rect(img, 7, 6, 9, 7, GOLD[1])
    for y in range(8, 15):  # kropla
        w = min(y - 8, 3) if y < 12 else 14 - y + 1
        rect(img, 8 - w, y, 8 + w, y, hexc("2fc8b8"))
    rect(img, 6, 10, 7, 11, hexc("c0fff4"))
    put(img, 9, 13, hexc("0f5a58"))
    put(img, 10, 12, hexc("0f5a58"))
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ff9a30"))
    return img


STORM = [hexc("1d3a8a"), hexc("3f7fe0"), hexc("8ac8ff"), hexc("e8f6ff")]


def ring_storm():
    """Pierścień Gromu: stalowa obręcz z błyskawicą i burzowym kryształem."""
    img = new(16, 16)
    band(img, SILVER)
    rect(img, 5, 2, 10, 6, hexc("3a3a5a"))
    gem(img, 8, 4, [STORM[0], STORM[1], STORM[3]])
    for x, y in ((3, 1), (4, 2), (3, 3), (4, 4)):  # błyskawice po bokach
        put(img, x, y, STORM[2])
        put(img, 15 - x, y, STORM[2])
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ffa040"))
    return img


def earring_storm():
    """Lotka Burzy: pióro orła na złotym kółku, z iskrzącą końcówką."""
    img = new(16, 16)
    hook(img, GOLD)
    line(img, 8, 6, 8, 15, hexc("8a7a5a"))
    for y in range(7, 15):
        w = 2 if y < 13 else 1
        rect(img, 8 - w, y, 7, y, hexc("f0ece0") if y < 10 else hexc("6b4a2c"))
        rect(img, 9, y, 8 + w, y, hexc("d8d0c0") if y < 10 else hexc("4a3020"))
    put(img, 6, 14, STORM[2])
    put(img, 10, 13, STORM[3])
    put(img, 8, 15, STORM[2])
    outline(img, OUTLINE_DARK)
    glow(img, hexc("ff9a30"))
    return img


def make_all():
    os.makedirs(ITEMS, exist_ok=True)
    gruzlog().save(os.path.join(ITEMS, "ring_gruzlog.png"))
    alpha().save(os.path.join(ITEMS, "ring_alpha.png"))
    bulgor().save(os.path.join(ITEMS, "ring_bulgor.png"))
    earring_gruzlog().save(os.path.join(ITEMS, "earring_gruzlog.png"))
    earring_alpha().save(os.path.join(ITEMS, "earring_alpha.png"))
    earring_bulgor().save(os.path.join(ITEMS, "earring_bulgor.png"))
    ring_storm().save(os.path.join(ITEMS, "ring_storm.png"))
    earring_storm().save(os.path.join(ITEMS, "earring_storm.png"))
