"""Rozbudowa osady: głazy i kamień, kilof, stosy kamieni przy magazynie, plac budowy
koszar, kukły treningowe, daszek nad kowadłem, stajnia z koniem, wóz z towarem,
meble pokoi w karczmie i nowi mieszkańcy (sołtys, żołnierze). Wywoływane z generate_art.py."""
import math
import os
import random

from generate_art import (BARK, OUT, OUTLINE_DARK, STONE, hexc, line, make_person_sheet, new, outline, put, rect,
                          shaded_blob, shadow_ellipse)
from village_art import NPC_DIR, PANTS, PANTS_BROWN, SKIN_TAN, SKIN_TAN_D, VILLAGE, person, tunic

ITEMS = os.path.join(OUT, "items")
WEAPONS = os.path.join(OUT, "weapons")

PLANK = [hexc("a8743f"), hexc("c89a64"), hexc("86592e")]
STRAW = [hexc("8a6a2a"), hexc("c8a45a"), hexc("e0c47a")]
CANVAS = [hexc("8a7a5a"), hexc("b8a47c"), hexc("e0d0a8")]
ROCK = [hexc("3d3f4f"), hexc("5b5e70"), hexc("7d8192"), hexc("a3a7b5"), hexc("c9cfdc")]
HORSE = [hexc("4a2c16"), hexc("7a4a28"), hexc("9a6a40")]
MANE = hexc("2a1a10")


def save(img, name, folder=VILLAGE):
    img.save(os.path.join(folder, name + ".png"))


# ---------------------------------------------------------------- głazy i kamień
def make_boulders():
    shapes = [
        [(13, 12, 8.5), (8, 14, 6), (18, 14, 6)],
        [(12, 13, 7.5), (17, 11, 6), (7, 15, 5)],
        [(13, 11, 7), (8, 14, 6.5), (19, 15, 5.5), (14, 15, 6)],
    ]
    for i, circles in enumerate(shapes):
        rng = random.Random(40 + i)
        img = new(26, 22)
        body = new(26, 22)
        shaded_blob(body, circles, ROCK[:4], rng=rng, speckle=0.12)
        img.alpha_composite(body)
        # pęknięcia i mech
        crack = [(9 + i, 8), (10 + i, 9), (10 + i, 10), (11 + i, 11)]
        for x, y in crack:
            if img.getpixel((x, y))[3]:
                put(img, x, y, ROCK[0])
        for _ in range(5):
            x, y = rng.randint(6, 18), rng.randint(4, 8)
            if img.getpixel((x, y))[3]:
                put(img, x, y, hexc("4b8f3f") if rng.random() < 0.6 else hexc("2f6b34"))
        for y in range(16, 22):  # spód w cieniu
            for x in range(26):
                if img.getpixel((x, y))[3] and y >= 17:
                    put(img, x, y, ROCK[1])
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 13, 20.5, 11, 2)
        img.save(os.path.join(OUT, f"boulder_{i}.png"))

    # gruz po rozbitym głazie
    rng = random.Random(9)
    rubble = new(22, 10)
    for cx, cy, r in ((6, 6, 2.5), (11, 5, 3), (16, 6, 2.5), (9, 8, 1.8), (14, 8, 1.8), (19, 8, 1.4), (3, 8, 1.3)):
        for y in range(10):
            for x in range(22):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d <= r:
                    put(rubble, x, y, ROCK[3] if y < cy - r / 3 else ROCK[2] if rng.random() < 0.8 else ROCK[1])
    outline(rubble, OUTLINE_DARK)
    rubble.save(os.path.join(OUT, "rubble.png"))


def stone_chunk(img, cx, cy, r, rng):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            d = math.hypot((x + 0.5 - cx) * 0.95, (y + 0.5 - cy) * 1.1)
            if d <= r:
                light = (x - cx) + (y - cy) < -r * 0.4
                c = ROCK[3] if light else ROCK[1] if y > cy + r * 0.4 else ROCK[2]
                if rng.random() < 0.08:
                    c = ROCK[1]
                put(img, x, y, c)


def make_stone_art():
    rng = random.Random(3)
    icon = new(16, 16)
    stone_chunk(icon, 6, 10, 4.2, rng)
    stone_chunk(icon, 11, 11, 3.4, rng)
    stone_chunk(icon, 9, 6, 3.0, rng)
    outline(icon, OUTLINE_DARK)
    save(icon, "stone", ITEMS)

    # stos kamieni przy magazynie: 4 wielkości (piramida z łupanych bloków)
    rows_for = {1: [2, 1], 2: [3, 2, 1], 3: [4, 3, 2, 1], 4: [5, 4, 3, 2, 1]}
    sheet = new(36 * 4, 30)
    for stage in range(1, 5):
        img = new(36, 30)
        rng = random.Random(stage)
        for r, count in enumerate(rows_for[stage]):
            y = 25 - r * 5
            x0 = 18 - count * 3
            for i in range(count):
                stone_chunk(img, x0 + i * 6 + 3 + rng.uniform(-0.4, 0.4), y, 3.2, rng)
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 18, 28, 16, 2)
        sheet.paste(img, ((stage - 1) * 36, 0))
    save(sheet, "stone_pile")


def make_pickaxe():
    img = new(20, 13)
    rect(img, 0, 6, 15, 7, BARK[2])  # trzonek
    rect(img, 0, 6, 15, 6, BARK[3])
    rect(img, 1, 6, 2, 7, BARK[1])
    # żelazny grot zakrzywiony w obie strony
    for y, x in ((0, 18), (1, 17), (2, 17), (3, 16), (4, 16), (5, 16), (6, 16), (7, 16), (8, 16), (9, 16),
                 (10, 17), (11, 17), (12, 18)):
        rect(img, x, y, x + 1, y, STONE[2])
        put(img, x, y, STONE[3])
    rect(img, 15, 5, 17, 8, STONE[1])
    outline(img, OUTLINE_DARK)
    save(img, "pickaxe", WEAPONS)


# ---------------------------------------------------------------- wyposażenie osady
def make_dummy():
    """Kukła treningowa: pal, poprzeczka, słomiany tułów i worek zamiast głowy."""
    img = new(20, 30)
    rect(img, 9, 12, 10, 29, BARK[1])
    rect(img, 2, 12, 17, 13, BARK[2])
    rect(img, 2, 12, 17, 12, BARK[3])
    for y in range(11, 24):
        for x in range(5, 15):
            if abs(x - 9.5) <= 4.5 - max(0, y - 20) * 0.8:
                put(img, x, y, STRAW[1] if (x + y) % 4 else STRAW[0])
    rect(img, 5, 16, 14, 16, BARK[1])  # sznur
    for y in range(3, 11):
        for x in range(6, 14):
            if math.hypot(x + 0.5 - 10, y + 0.5 - 7) <= 4:
                put(img, x, y, CANVAS[1] if y > 4 else CANVAS[2])
    put(img, 8, 6, BARK[0])
    put(img, 11, 6, BARK[0])
    line(img, 8, 8, 11, 9, hexc("8e2f25"))  # namalowana gęba
    rect(img, 13, 18, 14, 19, STRAW[2])  # wystająca słoma
    put(img, 5, 21, STRAW[2])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 10, 28.5, 7, 1.5)
    save(img, "dummy")


def make_awning():
    """Daszek nad kowadłem: dach z gontów na czterech słupach (środek przezroczysty)."""
    W, H = 56, 52
    img = new(W, H)
    for x in (3, W - 5):
        rect(img, x, 14, x + 1, H - 3, BARK[1])  # tylne słupy (krótsze, wyżej)
    for x in (1, W - 3):
        rect(img, x, 18, x + 1, H - 1, BARK[2])
        put(img, x, 18, BARK[3])
    roof = [hexc("2c2e3a"), hexc("3d4050"), hexc("4b4f63"), hexc("646a82")]
    for y in range(0, 20):
        for x in range(W):
            seam = (x + (y // 4 % 2) * 3) % 6 == 0
            c = roof[0] if y % 4 == 3 or seam else roof[2] if y < 6 else roof[1]
            put(img, x, y, c)
    rect(img, 0, 0, W - 1, 1, roof[3])
    rect(img, 0, 18, W - 1, 19, roof[0])
    outline(img, OUTLINE_DARK)
    save(img, "awning")


def make_hearth():
    """Kowalskie palenisko na zewnątrz z miechem (2 klatki żaru)."""
    sheet = new(28 * 2, 26)
    for f in range(2):
        img = new(28, 26)
        rect(img, 2, 8, 25, 24, STONE[1])
        rect(img, 2, 8, 25, 9, STONE[2])
        for y in range(11, 24, 4):
            for x in range(2, 26, 6):
                put(img, x + (y // 4 % 2) * 3, y, STONE[0])
        rect(img, 5, 4, 22, 10, STONE[0])
        rect(img, 7, 5, 20, 9, hexc("c0392b"))
        rect(img, 9, 5 - f, 18, 8, hexc("e67e22"))
        rect(img, 11 + f, 6 - f, 16, 8, hexc("fdf2a6"))
        # miech z boku
        rect(img, 23, 13, 27, 17, BARK[2] if f == 0 else BARK[3])
        line(img, 22, 15, 20, 12, BARK[1])
        outline(img, OUTLINE_DARK)
        sheet.paste(img, (f * 28, 0))
    save(sheet, "hearth")


def make_stable():
    """Otwarta stajnia z sianem w środku."""
    W, H = 64, 50
    img = new(W, H)
    # tylna ściana z desek
    for y in range(14, H - 2):
        for x in range(2, W - 2):
            k = (x - 2) % 6
            put(img, x, y, PLANK[2] if k == 0 else PLANK[0])
    rect(img, 2, H - 4, W - 3, H - 2, BARK[1])
    # siano w środku i przegroda
    for y in range(32, H - 4):
        for x in range(6, 28):
            if (x * 3 + y) % 5:
                put(img, x, y, STRAW[1] if (x + y) % 3 else STRAW[2])
    rect(img, 31, 22, 32, H - 3, BARK[1])
    rect(img, 34, 34, W - 6, 36, BARK[2])  # żłób
    rect(img, 35, 33, W - 7, 33, STRAW[2])
    # słupy i dach
    for x in (1, 31, W - 3):
        rect(img, x, 12, x + 1, H - 1, BARK[2])
    roof = [hexc("4e3420"), hexc("6b4a2c"), hexc("86603a"), hexc("a07848")]
    for y in range(0, 16):
        for x in range(W):
            seam = (x + (y // 4 % 2) * 3) % 6 == 0
            put(img, x, y, roof[0] if y % 4 == 3 or seam else roof[2] if y < 5 else roof[1])
    rect(img, 0, 0, W - 1, 1, roof[3])
    rect(img, 0, 14, W - 1, 15, roof[0])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, W // 2, H - 1.5, W // 2 - 2, 1.5)
    save(img, "stable")


def make_horse():
    """Koń przy żłobie, z boku: 2 klatki - łeb uniesiony / opuszczony do jedzenia."""
    sheet = new(34 * 2, 26)
    for f in range(2):
        img = new(34, 26)
        rect(img, 6, 9, 22, 16, HORSE[1])
        rect(img, 6, 9, 22, 9, HORSE[2])
        rect(img, 6, 15, 22, 16, HORSE[0])
        for x in (7, 10, 18, 21):
            rect(img, x, 17, x + 1, 24, HORSE[0])
            put(img, x, 24, MANE)
            put(img, x + 1, 24, MANE)
        line(img, 5, 10, 2, 15 + f, MANE)  # ogon
        line(img, 4, 10, 2, 16 - f, MANE)
        if f == 0:  # łeb w górze
            rect(img, 21, 3, 24, 11, HORSE[1])
            rect(img, 23, 1, 28, 6, HORSE[1])
            put(img, 27, 2, hexc("1a1c2c"))
            put(img, 24, 0, HORSE[0])
            rect(img, 20, 3, 21, 10, MANE)
        else:  # łeb opuszczony - je
            rect(img, 21, 9, 25, 14, HORSE[1])
            rect(img, 24, 13, 29, 18, HORSE[1])
            put(img, 27, 15, hexc("1a1c2c"))
            rect(img, 20, 8, 22, 12, MANE)
        rect(img, 12, 9, 15, 10, hexc("b33a3a"))  # derka
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 15, 24.5, 12, 1.5)
        sheet.paste(img, (f * 34, 0))
    save(sheet, "horse")


def make_cart():
    """Wóz bez konia, z odkrytą skrzynią pełną towaru do rozładunku."""
    img = new(48, 32)
    wood, wood_d, wood_l = BARK[2], BARK[1], BARK[3]
    for cx in (10, 34):
        for y in range(32):
            for x in range(48):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - 25)
                if 3.5 <= d <= 5.2:
                    put(img, x, y, wood_d)
        for k in range(4):
            ang = k * math.pi / 2 + 0.4
            line(img, cx, 25, round(cx + math.cos(ang) * 4), round(25 + math.sin(ang) * 4), wood)
    rect(img, 2, 14, 41, 21, wood)
    rect(img, 2, 14, 41, 14, wood_l)
    rect(img, 2, 21, 41, 21, wood_d)
    for x in range(8, 41, 8):
        rect(img, x, 15, x, 20, wood_d)
    line(img, 41, 18, 47, 22, wood_d)  # dyszel opuszczony na ziemię
    # towar: skrzynie, beczka i worki
    rect(img, 4, 6, 13, 13, PLANK[0])
    rect(img, 4, 6, 13, 6, PLANK[1])
    line(img, 5, 7, 12, 12, PLANK[2])
    rect(img, 15, 4, 21, 13, BARK[2])
    rect(img, 15, 6, 21, 6, STONE[1])
    rect(img, 15, 11, 21, 11, STONE[1])
    for cx, cy in ((26, 10), (32, 11), (37, 10)):
        for y in range(cy - 4, cy + 4):
            for x in range(cx - 3, cx + 4):
                if ((x - cx) / 3.5) ** 2 + ((y - cy) / 4) ** 2 <= 1:
                    put(img, x, y, CANVAS[1] if x < cx else CANVAS[0])
        put(img, cx, cy - 4, BARK[1])
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, 22, 29, 21, 2.5)
    save(img, "cart")


def make_small_props():
    # worek (noszony przez tragarza)
    sack = new(12, 13)
    for y in range(2, 13):
        for x in range(12):
            if ((x + 0.5 - 6) / 5.5) ** 2 + ((y + 0.5 - 8) / 5) ** 2 <= 1:
                put(sack, x, y, CANVAS[2] if x < 5 else CANVAS[1])
    rect(sack, 5, 0, 7, 2, CANVAS[1])
    rect(sack, 4, 2, 8, 2, BARK[1])
    outline(sack, OUTLINE_DARK)
    save(sack, "sack")

    # kufel piwa
    mug = new(8, 8)
    rect(mug, 1, 1, 5, 7, hexc("c9a46a"))
    rect(mug, 1, 1, 5, 2, hexc("f4f7fb"))
    rect(mug, 6, 3, 6, 5, hexc("8a6a44"))
    rect(mug, 1, 3, 5, 3, hexc("e0a020"))
    outline(mug, OUTLINE_DARK)
    save(mug, "mug")

    # łóżko (widok z góry, wezgłowie u góry)
    bed = new(18, 30)
    rect(bed, 0, 0, 17, 29, BARK[2])
    rect(bed, 0, 0, 17, 3, BARK[3])
    rect(bed, 2, 4, 15, 27, hexc("e8e0d0"))
    rect(bed, 3, 5, 14, 9, hexc("f4f7fb"))  # poduszka
    rect(bed, 2, 12, 15, 27, hexc("8e2f25"))  # pled
    rect(bed, 2, 12, 15, 13, hexc("c4553f"))
    for y in range(16, 27, 4):
        rect(bed, 2, y, 15, y, hexc("6e231c"))
    outline(bed, OUTLINE_DARK)
    save(bed, "bed")

    # kufer
    chest = new(16, 13)
    rect(chest, 0, 2, 15, 12, BARK[2])
    rect(chest, 0, 0, 15, 4, BARK[3])
    rect(chest, 0, 4, 15, 4, BARK[1])
    rect(chest, 2, 0, 3, 12, STONE[1])
    rect(chest, 12, 0, 13, 12, STONE[1])
    rect(chest, 7, 4, 8, 6, hexc("e0a020"))
    outline(chest, OUTLINE_DARK)
    save(chest, "chest")

    # wiązka broni (noszona do koszar)
    arms = new(22, 12)
    for i, y in enumerate((2, 5, 8)):
        line(arms, 1, y + 2, 18, y - 1, STONE[3] if i != 1 else STONE[2])
        rect(arms, 16, y - 2, 17, y + 1, hexc("e0a020"))
        line(arms, 18, y - 1, 21, y - 2, BARK[2])
    rect(arms, 7, 2, 8, 10, BARK[1])  # rzemień
    outline(arms, OUTLINE_DARK)
    save(arms, "arms_bundle")

    # kolczuga złożona w kostkę (noszona do koszar)
    mail = new(14, 12)
    for y in range(1, 11):
        for x in range(1, 13):
            put(mail, x, y, STONE[2] if (x + y) % 2 else STONE[1])
    rect(mail, 1, 1, 12, 1, STONE[3])
    rect(mail, 5, 1, 8, 3, hexc("8a5a34"))
    outline(mail, OUTLINE_DARK)
    save(mail, "mail_bundle")

    # tarcza (dekoracja przy koszarach)
    shield = new(14, 16)
    for y in range(16):
        for x in range(14):
            if abs(x + 0.5 - 7) <= 6.5 - max(0, y - 8) * 0.8:
                put(shield, x, y, hexc("8e2f25") if x < 7 else hexc("a83e30"))
    rect(shield, 6, 0, 7, 14, hexc("e0a020"))
    rect(shield, 1, 5, 12, 6, hexc("e0a020"))
    outline(shield, OUTLINE_DARK)
    save(shield, "shield")

    # bela siana
    hay = new(22, 16)
    rect(hay, 1, 3, 20, 14, STRAW[1])
    rect(hay, 1, 3, 20, 5, STRAW[2])
    for x in range(2, 20, 3):
        rect(hay, x, 6, x, 13, STRAW[0])
    rect(hay, 6, 3, 6, 14, BARK[1])
    rect(hay, 15, 3, 15, 14, BARK[1])
    outline(hay, OUTLINE_DARK)
    shadow_ellipse(hay, 11, 15, 10, 1.2)
    save(hay, "hay")

    # grządka z warzywami
    rng = random.Random(21)
    garden = new(40, 22)
    rect(garden, 0, 2, 39, 21, hexc("5a3a20"))
    for row in range(3):
        y = 5 + row * 6
        rect(garden, 1, y + 2, 38, y + 3, hexc("3a2215"))
        for x in range(3, 38, 5):
            c = rng.choice(["4b8f3f", "6fb04a", "4b8f3f"])
            rect(garden, x, y - 1, x + 2, y + 1, hexc(c))
            if rng.random() < 0.35:
                put(garden, x + 1, y + 1, hexc(rng.choice(["e67e22", "c0392b", "f2c94c"])))
    for x in range(0, 40, 6):  # płotek z przodu
        rect(garden, x, 18, x + 1, 21, BARK[2])
    rect(garden, 0, 19, 39, 19, BARK[3])
    outline(garden, OUTLINE_DARK)
    save(garden, "garden")

    # sztandar osady
    banner = new(14, 34)
    rect(banner, 6, 0, 7, 33, BARK[1])
    rect(banner, 1, 2, 12, 2, BARK[2])
    for y in range(3, 20):
        for x in range(2, 12):
            if y < 17 or abs(x - 6.5) > (y - 16):
                put(banner, x, y, hexc("2f5f8a") if (y // 3) % 3 else hexc("e0a020"))
    outline(banner, OUTLINE_DARK)
    shadow_ellipse(banner, 7, 33, 3, 1)
    save(banner, "banner")


# ---------------------------------------------------------------- plac budowy koszar
def make_construction(w_tiles=12, h_tiles=7, name="construction"):
    """Plac budowy (domyślnie koszar, 12x7 kafelków) w 4 etapach: fundament, szkielet,
    ściany z rusztowaniem, więźba dachu. Punkt zaczepienia - lewy dolny róg."""
    W, H = w_tiles * 16, h_tiles * 16
    sheet = new(W * 4, H)
    for stage in range(4):
        rng = random.Random(stage)
        img = new(W, H)
        # wydeptana ziemia
        for y in range(28, H):
            for x in range(W):
                r = rng.random()
                put(img, x, y, hexc("8a6a44") if r < 0.85 else hexc("6b4e30") if r < 0.97 else hexc("a8865a"))
        # fundament z kamieni
        for x in range(4, W - 4, 6):
            for y in (H - 10, 30):
                rect(img, x, y, x + 4, y + 4, ROCK[2])
                put(img, x, y, ROCK[3])
        for y in range(30, H - 6, 6):
            for x in (4, W - 9):
                rect(img, x, y, x + 4, y + 4, ROCK[2])
                put(img, x, y, ROCK[3])
        if stage >= 1:  # słupy szkieletu
            for x in range(4, W - 2, 30):
                rect(img, x, 8, x + 3, H - 6, PLANK[0])
                rect(img, x, 8, x, H - 6, PLANK[1])
            rect(img, 4, 8, W - 5, 11, PLANK[2])
            rect(img, 4, H - 40, W - 5, H - 38, PLANK[2])
        if stage >= 2:  # dolne ściany z bali + rusztowanie
            for y in range(H - 38, H - 6):
                for x in range(4, W - 4):
                    k = (y - (H - 38)) % 5
                    put(img, x, y, PLANK[1] if k == 0 else PLANK[2] if k == 4 else PLANK[0])
            rect(img, W // 2 - 10, H - 30, W // 2 + 9, H - 6, hexc("2a1a10"))  # otwór na drzwi
            for x in range(20, W - 20, 70):
                line(img, x, H - 2, x + 12, 20, BARK[2])
                line(img, x + 24, H - 2, x + 12, 20, BARK[2])
            rect(img, 10, 40, W - 10, 41, BARK[3])  # pomost
        if stage >= 3:  # więźba dachu
            for x in range(4, W - 2, 12):
                line(img, x, 10, x + 6, 0, BARK[3])
                line(img, x + 12, 10, x + 6, 0, BARK[3])
            rect(img, 4, 0, W - 5, 1, BARK[3])
        outline(img, OUTLINE_DARK)
        sheet.paste(img, (stage * W, 0))
    save(sheet, name)


# ---------------------------------------------------------------- chatka myśliwych
def make_lodge_props():
    # stelaż do oprawiania zwierzyny: pusty / z zawieszoną tuszą
    sheet = new(28 * 2, 34)
    for f in range(2):
        img = new(28, 34)
        rect(img, 2, 4, 3, 33, BARK[2])
        rect(img, 24, 4, 25, 33, BARK[2])
        rect(img, 0, 3, 27, 5, BARK[3])
        rect(img, 0, 5, 27, 5, BARK[1])
        if f == 1:
            line(img, 13, 6, 13, 9, hexc("8a7a4a"))  # sznur
            for y in range(9, 30):  # tusza głową w dół
                half = 4 if y < 24 else 3 - (y - 24) // 2
                for x in range(13 - half, 14 + half):
                    put(img, x, y, hexc("8a5a34") if (x + y) % 5 else hexc("6b4226"))
            rect(img, 11, 9, 11, 12, hexc("6b4226"))  # tylne nogi
            rect(img, 15, 9, 15, 12, hexc("6b4226"))
            rect(img, 12, 16, 14, 22, hexc("c0392b"))  # oprawiane
        else:
            rect(img, 12, 6, 14, 7, STONE[2])  # haki
        outline(img, OUTLINE_DARK)
        shadow_ellipse(img, 14, 33, 12, 1.2)
        sheet.paste(img, (f * 28, 0))
    save(sheet, "butcher_rack")

    # tarcza łucznicza na stojaku
    target = new(20, 26)
    line(target, 4, 25, 8, 12, BARK[1])
    line(target, 15, 25, 11, 12, BARK[1])
    for y in range(1, 17):
        for x in range(1, 19):
            d = math.hypot((x + 0.5 - 10) / 8.5, (y + 0.5 - 9) / 8)
            if d <= 1.0:
                c = STRAW[1] if d > 0.82 else hexc("e8e0d0") if d > 0.62 else hexc("2f5f8a") if d > 0.42 else hexc("c0392b") if d > 0.2 else hexc("f2c94c")
                put(target, x, y, c)
    outline(target, OUTLINE_DARK)
    shadow_ellipse(target, 10, 25, 7, 1.2)
    save(target, "archery_target")

    # wędzarnia: mała kamienna budka z kominem i wiszącym mięsem w otwartym boku
    smoke = new(26, 32)
    rect(smoke, 2, 10, 23, 30, STONE[1])
    for y in range(12, 30, 4):
        for x in range(2, 24, 6):
            put(smoke, x + (y // 4 % 2) * 3, y, STONE[0])
    rect(smoke, 7, 16, 18, 29, hexc("1a1210"))
    for x in (9, 12, 15):
        rect(smoke, x, 17, x + 1, 22, hexc("8e2f25"))
        put(smoke, x, 17, hexc("c0392b"))
    rect(smoke, 0, 6, 25, 10, hexc("4e3420"))
    rect(smoke, 0, 6, 25, 6, hexc("6b4a2c"))
    rect(smoke, 17, 0, 21, 6, STONE[2])
    rect(smoke, 17, 0, 21, 0, STONE[3])
    outline(smoke, OUTLINE_DARK)
    shadow_ellipse(smoke, 13, 31, 12, 1.2)
    save(smoke, "smokehouse")

    # kołczan ze strzałami na stole
    quiver = new(10, 16)
    rect(quiver, 2, 5, 7, 15, BARK[2])
    rect(quiver, 2, 5, 7, 6, BARK[3])
    for x in (3, 5, 6):
        rect(quiver, x, 0, x, 5, BARK[3])
        put(quiver, x, 0, hexc("e8e0d0"))
    outline(quiver, OUTLINE_DARK)
    save(quiver, "quiver")


# ---------------------------------------------------------------- mieszkańcy
NPCS = [
    ("chief", person("9a9a9a", "707070", tunic("2f5f8a", "22466a", "4a7aa8"), beard=hexc("c0c0c0"),
                     buckle=hexc("f2c94c"), helmet=hexc("8e2f25"), helmet_d=hexc("6e231c"))),
    ("soldier_a", person("3a2a1a", "241a10", tunic("8a8e9e", "676b7b", "b0b4c4"), helmet=hexc("7d8192"),
                         helmet_d=hexc("3d3f4f"), belt=hexc("8e2f25"), buckle=hexc("c9d1e0"), tool="sword")),
    ("soldier_b", person("c8a060", "a07c40", tunic("8a8e9e", "676b7b", "b0b4c4"), skin=(SKIN_TAN, SKIN_TAN_D),
                         helmet=hexc("7d8192"), helmet_d=hexc("3d3f4f"), belt=hexc("8e2f25"), buckle=hexc("c9d1e0"),
                         pants=PANTS_BROWN, tool="sword")),
    ("soldier_c", person("5c2e1a", "3a1c10", tunic("6b4226", "4e2f1b", "8a5a34"), helmet=hexc("7d8192"),
                         helmet_d=hexc("3d3f4f"), belt=hexc("3a2215"), buckle=hexc("c9d1e0"), pants=PANTS, tool="sword")),
    ("hunter_b", person("8a4b2a", "5c2e1a", tunic("5e6b3a", "47522c", "76864a"), pants=PANTS_BROWN,
                        hood=hexc("4a5530"), hood_d=hexc("363e22"), tool="knife")),
    ("hunter_c", person("2a2a2a", "151515", tunic("6b4a2c", "4e3420", "86603a"), skin=(SKIN_TAN, SKIN_TAN_D),
                        pants=PANTS_BROWN, hood=hexc("5a3a20"), hood_d=hexc("3a2215"), beard=hexc("2a2a2a"), tool="knife")),
    ("hunter_d", person("c8a060", "a07c40", tunic("3e5a4a", "2c4236", "52725e"), pants=PANTS,
                        hood=hexc("2f4a3a"), hood_d=hexc("20342a"), tool="knife")),
    ("sergeant", person("2a2a2a", "151515", tunic("a83e30", "7d2626", "c4553f"), beard=hexc("2a2a2a"),
                        helmet=hexc("a3a7b5"), helmet_d=hexc("5b5e70"), buckle=hexc("f2c94c"), tool="sword")),
]


def make_npcs():
    for name, palette in NPCS:
        make_person_sheet(palette, work=True).save(os.path.join(NPC_DIR, name + ".png"))


def make_bag_icons():
    leather, leather_d, leather_l = hexc("8a5a34"), hexc("6b4226"), hexc("a8743f")
    pouch = new(16, 16)  # sakwa z klapą i rzemieniem
    rect(pouch, 3, 6, 12, 14, leather)
    rect(pouch, 3, 13, 12, 14, leather_d)
    rect(pouch, 2, 5, 13, 9, leather_l)
    rect(pouch, 2, 9, 13, 9, leather_d)
    rect(pouch, 7, 8, 8, 10, hexc("e0a020"))
    line(pouch, 3, 5, 6, 1, BARK[1])
    line(pouch, 12, 5, 9, 1, BARK[1])
    outline(pouch, OUTLINE_DARK)
    save(pouch, "pouch", ITEMS)

    pack = new(16, 16)  # plecak z kieszenią i zwiniętym kocem na górze
    rect(pack, 3, 4, 12, 15, leather)
    rect(pack, 3, 4, 12, 5, leather_l)
    rect(pack, 5, 9, 10, 14, leather_d)
    rect(pack, 5, 9, 10, 9, leather_l)
    rect(pack, 7, 10, 8, 11, hexc("e0a020"))
    rect(pack, 2, 1, 13, 3, hexc("5a6a3a"))  # koc
    rect(pack, 2, 1, 13, 1, hexc("72844a"))
    rect(pack, 4, 1, 4, 3, BARK[1])
    rect(pack, 11, 1, 11, 3, BARK[1])
    outline(pack, OUTLINE_DARK)
    save(pack, "backpack", ITEMS)


def make_all():
    os.makedirs(VILLAGE, exist_ok=True)
    make_bag_icons()
    os.makedirs(WEAPONS, exist_ok=True)
    make_boulders()
    make_stone_art()
    make_pickaxe()
    make_dummy()
    make_awning()
    make_hearth()
    make_stable()
    make_horse()
    make_cart()
    make_small_props()
    make_construction()
    make_construction(8, 6, "construction_lodge")
    make_construction(8, 6, "construction_sage")
    make_construction(12, 7, "construction_guild")
    make_lodge_props()
    make_npcs()
