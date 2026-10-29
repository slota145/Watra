"""Ikony umiejętności dodatkowych (16x16): szarża, półksiężyc, strzała tropiąca, szybka salwa,
łańcuch błyskawic i fala piorunów. Wywoływane z generate_art.py."""
import math
import os

from generate_art import BARK, OUT, STONE, hexc, line, new, put, rect

SKILLS = os.path.join(OUT, "skills")
STEEL = STONE[3]
GOLD = hexc("e0a020")
BOLT = hexc("bfe8ff")
BOLT_CORE = hexc("ffffff")


# kwadratowa ramka w kolorze broni - jak przy dotychczasowych ikonach (item_art.skill_frame)
FRAMES = {"melee": ("3a2a2a", "c0392b"), "bow": ("2a3a2a", "6aa84f"), "spell": ("3a2a1a", "e67e22")}


def background(weapon):
    bg, border = FRAMES[weapon]
    img = new(16, 16)
    rect(img, 0, 0, 15, 15, hexc(border))
    rect(img, 1, 1, 14, 14, hexc(bg))
    return img


def lunge():
    img = background("melee")
    for k, y in enumerate((5, 8, 11)):  # smugi pędu
        rect(img, 1, y, 4 + k, y, hexc("9fc4ff"))
    line(img, 4, 12, 13, 3, STEEL)
    line(img, 5, 12, 14, 3, hexc("e8f0ff"))
    rect(img, 4, 11, 6, 13, GOLD)  # jelec
    line(img, 2, 14, 4, 12, BARK[2])
    return img


def crescent():
    img = background("melee")
    for a in range(0, 300, 6):  # szeroki łuk cięcia
        t = math.radians(a - 60)
        for r in (5.5, 6.5):
            put(img, round(7.5 + math.cos(t) * r), round(7.5 + math.sin(t) * r), hexc("f4f7fb") if r < 6 else hexc("ffd0a0"))
    line(img, 6, 9, 11, 4, STEEL)
    rect(img, 5, 9, 7, 10, GOLD)
    return img


def seeker():
    img = background("bow")
    pts = [(2, 12), (3, 9), (5, 6), (8, 5), (11, 6), (12, 9), (11, 11)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):  # tor strzały zawracający po łuku
        line(img, x0, y0, x1, y1, hexc("c8f080"))
    rect(img, 9, 11, 11, 13, STEEL)  # grot
    put(img, 9, 13, STEEL)
    put(img, 2, 13, hexc("f2f2e6"))  # lotki
    put(img, 1, 12, hexc("f2f2e6"))
    return img


def rapid_volley():
    img = background("bow")
    for y in (4, 8, 12):
        line(img, 2, y, 12, y, BARK[3])
        rect(img, 12, y - 1, 14, y + 1, STEEL)
        put(img, 15, y, STEEL)
        put(img, 2, y - 1, hexc("f2f2e6"))
        put(img, 2, y + 1, hexc("f2f2e6"))
    return img


def chain_lightning():
    img = background("spell")
    nodes = [(3, 12), (7, 4), (10, 11), (13, 5)]
    for (x0, y0), (x1, y1) in zip(nodes, nodes[1:]):
        mx, my = (x0 + x1) // 2 + 1, (y0 + y1) // 2
        line(img, x0, y0, mx, my, BOLT)
        line(img, mx, my, x1, y1, BOLT)
    for x, y in nodes:
        rect(img, x - 1, y - 1, x, y, BOLT_CORE)
    return img


def thunder_wave():
    img = background("spell")
    for a in (-35, -12, 12, 35):  # pioruny rozchodzące się stożkiem
        t = math.radians(a)
        x0, y0 = 2, 8
        x1, y1 = round(2 + math.cos(t) * 12), round(8 + math.sin(t) * 12)
        mx, my = (x0 + x1) // 2, (y0 + y1) // 2 + (1 if a > 0 else -1)
        line(img, x0, y0, mx, my, BOLT)
        line(img, mx, my, x1, y1, BOLT)
    rect(img, 1, 7, 3, 9, BOLT_CORE)
    return img


def make_all():
    os.makedirs(SKILLS, exist_ok=True)
    for name, fn in (("lunge", lunge), ("crescent", crescent), ("seeker", seeker), ("rapid_volley", rapid_volley),
                     ("chain_lightning", chain_lightning), ("thunder_wave", thunder_wave)):
        fn().save(os.path.join(SKILLS, name + ".png"))
