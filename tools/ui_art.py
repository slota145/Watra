"""Ikony przycisków interfejsu (16x16): ekwipunek, postać, umiejętności, mapa i pomoc.
Wywoływane z generate_art.py."""
import math
import os

from generate_art import BARK, OUTLINE_DARK, hexc, line, new, outline, put, rect

UI = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "ui")

GOLD = hexc("f2c94c")
GOLD_D = hexc("c8962c")


def icon_bag():
    img = new(16, 16)
    sack, sack_d, sack_l = hexc("a8743f"), hexc("7a5230"), hexc("c89a64")
    for y in range(5, 15):
        half = min(6, 3 + (y - 5))
        rect(img, 8 - half, y, 7 + half, y, sack if y < 12 else sack_d)
    rect(img, 6, 2, 9, 5, sack)  # zawiązana góra
    rect(img, 5, 5, 10, 5, BARK[1])  # sznurek
    put(img, 4, 7, sack_l)
    put(img, 3, 9, sack_l)
    rect(img, 7, 9, 8, 11, GOLD)  # klamra
    outline(img, OUTLINE_DARK)
    return img


def icon_character():
    img = new(16, 16)
    skin, hair, tunic, tunic_d = hexc("f4c29a"), hexc("8a4b2a"), hexc("3b7dd8"), hexc("2a5aa8")
    for y in range(10, 16):  # ramiona
        half = 3 + (y - 10)
        rect(img, 8 - half, y, 7 + half, y, tunic if y < 14 else tunic_d)
    for y in range(2, 10):  # głowa
        for x in range(4, 12):
            if math.hypot(x + 0.5 - 8, y + 0.5 - 6) <= 3.8:
                put(img, x, y, skin)
    rect(img, 5, 2, 10, 4, hair)
    put(img, 4, 4, hair)
    put(img, 11, 4, hair)
    put(img, 6, 6, OUTLINE_DARK)
    put(img, 9, 6, OUTLINE_DARK)
    outline(img, OUTLINE_DARK)
    return img


def icon_skills():
    img = new(16, 16)
    cover, cover_d, page = hexc("4e2a68"), hexc("3a1e50"), hexc("f0e8d8")
    rect(img, 1, 6, 14, 14, cover_d)  # otwarta księga
    rect(img, 2, 6, 7, 12, page)
    rect(img, 8, 6, 13, 12, page)
    line(img, 7, 6, 7, 13, cover)
    rect(img, 1, 13, 14, 14, cover)
    for x in (3, 9):
        rect(img, x, 8, x + 3, 8, hexc("b8ac90"))
        rect(img, x, 10, x + 2, 10, hexc("b8ac90"))
    # magiczna gwiazdka nad księgą
    for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
        put(img, 8 + dx, 3 + dy, hexc("9ad8ff"))
    put(img, 8, 3, hexc("ffffff"))
    put(img, 5, 2, hexc("9ad8ff"))
    put(img, 11, 2, hexc("9ad8ff"))
    outline(img, OUTLINE_DARK)
    return img


def icon_map():
    img = new(16, 16)
    paper, paper_d = hexc("e0d0a8"), hexc("b8a47c")
    rect(img, 2, 3, 13, 12, paper)
    for x in (2, 6, 10):  # zagięcia mapy
        rect(img, x + 3, 3, x + 3, 12, paper_d)
    line(img, 3, 10, 6, 6, hexc("8a6a44"))  # ścieżka
    line(img, 6, 6, 10, 8, hexc("8a6a44"))
    line(img, 10, 5, 12, 7, hexc("c0392b"))  # czerwony krzyżyk
    line(img, 12, 5, 10, 7, hexc("c0392b"))
    rect(img, 3, 4, 4, 5, hexc("4a8236"))  # las
    outline(img, OUTLINE_DARK)
    return img


def icon_help():
    img = new(16, 16)
    for y in range(16):
        for x in range(16):
            d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
            if d <= 6.5:
                put(img, x, y, hexc("2f6fb8") if d > 5.5 else hexc("3b86d8"))
    question = [".XXX.", "X...X", "....X", "..XX.", "..X..", ".....", "..X.."]
    for y, row in enumerate(question):
        for x, ch in enumerate(row):
            if ch == "X":
                put(img, 6 + x, 4 + y, hexc("ffffff"))
    outline(img, OUTLINE_DARK)
    return img


def icon_journal():
    img = new(16, 16)
    paper, paper_d = hexc("e8d8b0"), hexc("c0a878")
    rect(img, 3, 2, 12, 14, paper)  # zwój
    rect(img, 2, 1, 13, 2, paper_d)
    rect(img, 2, 14, 13, 15, paper_d)
    for y in (5, 7, 9, 11):
        rect(img, 5, y, 10 - (y % 3), y, hexc("8a7a5a"))
    put(img, 5, 4, hexc("c0392b"))  # czerwony inicjał
    line(img, 13, 3, 9, 11, hexc("f4f7fb"))  # gęsie pióro
    line(img, 14, 3, 10, 11, hexc("c9d1e0"))
    put(img, 9, 12, OUTLINE_DARK)
    outline(img, OUTLINE_DARK)
    return img


def icon_track(active):
    """Oko - śledzenie zadania (jasne = śledzone)."""
    img = new(12, 10)
    white = hexc("f4f7fb") if active else hexc("8a8e9a")
    iris = GOLD if active else hexc("5b5e70")
    for y in range(10):
        for x in range(12):
            if ((x + 0.5 - 6) / 5.5) ** 2 + ((y + 0.5 - 5) / 3.2) ** 2 <= 1:
                put(img, x, y, white)
    rect(img, 5, 3, 7, 6, iris)
    put(img, 6, 4, OUTLINE_DARK)
    outline(img, OUTLINE_DARK)
    return img


def icon_trash():
    """Kosz w plecaku - upuszczony na nim przedmiot znika."""
    img = new(14, 14)
    metal, metal_d, metal_l = hexc("8a8e9a"), hexc("5b5e70"), hexc("b8bcc8")
    rect(img, 5, 1, 8, 2, metal_d)  # uchwyt pokrywy
    rect(img, 2, 3, 11, 4, metal)  # pokrywa
    rect(img, 2, 3, 11, 3, metal_l)
    for y in range(5, 13):  # kubeł lekko zwężający się ku dołowi
        inset = 3 if y > 10 else 2
        rect(img, inset + 1, y, 12 - inset - 1, y, metal if y < 12 else metal_d)
    for x in (5, 7, 9):  # żłobienia
        line(img, x - 1 if x == 5 else x, 6, x - 1 if x == 5 else x, 11, metal_d)
    outline(img, OUTLINE_DARK)
    return img


def icon_sort():
    """Sortowanie plecaka: trzy paski od najdłuższego i strzałka w dół."""
    img = new(14, 14)
    bar = hexc("e8d8b0")
    for i, width in enumerate((8, 6, 4)):
        rect(img, 1, 2 + i * 4, width, 3 + i * 4, bar)
    line(img, 11, 2, 11, 11, GOLD)
    for d in range(3):
        rect(img, 11 - d, 11 - d, 11 + d, 11 - d, GOLD)
    outline(img, OUTLINE_DARK)
    return img


def make_all():
    os.makedirs(UI, exist_ok=True)
    for name, make in (("bag", icon_bag), ("character", icon_character), ("skills", icon_skills),
                       ("map", icon_map), ("help", icon_help), ("journal", icon_journal),
                       ("trash", icon_trash), ("sort", icon_sort)):
        make().save(os.path.join(UI, name + ".png"))
    icon_track(True).save(os.path.join(UI, "track_on.png"))
    icon_track(False).save(os.path.join(UI, "track_off.png"))
