"""Ikony przedmiotów do założenia (16x16), bronie trzymane w ręku i pociski.
Wywoływane z generate_art.py."""
import math
import os

from generate_art import BARK, OUTLINE_DARK, STONE, hexc, line, new, outline, put, rect

ITEMS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "items")
WEAPONS = os.path.join(os.path.dirname(ITEMS), "weapons")
PROJECTILES = os.path.join(os.path.dirname(ITEMS), "projectiles")

GOLD = hexc("f2c94c")
GOLD_D = hexc("c8962c")
LEATHER = [hexc("4e2f1b"), hexc("6b4226"), hexc("8a5a34"), hexc("a8743f")]
IRON = [hexc("5b5e70"), hexc("8b93a8"), hexc("c9d1e0"), hexc("f4f7fb")]
RUST = [hexc("5a4a40"), hexc("7a6a5a"), hexc("9a8a78"), hexc("a0522d")]
COPPER = [hexc("8a4a20"), hexc("c87533"), hexc("e8a060")]
SILVER = [hexc("8b93a8"), hexc("c9d1e0"), hexc("ffffff")]


def save(img, folder, name):
    os.makedirs(folder, exist_ok=True)
    outline(img, OUTLINE_DARK)
    img.save(os.path.join(folder, name + ".png"))


# ---------------------------------------------------------------- ikony
def icon_sword(blade):
    img = new(16, 16)
    for i in range(10):  # ostrze po przekątnej
        put(img, 5 + i, 10 - i, blade[2])
        put(img, 6 + i, 10 - i, blade[1])
        put(img, 5 + i, 9 - i, blade[3] if i % 3 else blade[2])
    if blade is RUST:
        for x, y in ((8, 7), (11, 4), (9, 5)):
            put(img, x, y, RUST[3])
    line(img, 2, 9, 7, 14, GOLD_D)  # jelec
    line(img, 3, 9, 7, 13, GOLD)
    line(img, 1, 14, 3, 12, LEATHER[2])  # rękojeść
    put(img, 1, 15, GOLD)
    return img


def icon_axe():
    img = new(16, 16)
    line(img, 2, 14, 11, 5, LEATHER[2])
    line(img, 3, 14, 12, 5, LEATHER[1])
    for y in range(1, 10):  # ostrze
        w = 4 - abs(y - 5) // 2
        rect(img, 10, y, 10 + w, y, IRON[1])
        put(img, 10 + w, y, IRON[3])
    rect(img, 8, 3, 10, 7, IRON[0])
    return img


def icon_bow():
    img = new(16, 16)
    for t in range(15):
        a = -1.2 + t * 2.4 / 14
        x = int(4 + math.cos(a) * 8)
        y = int(8 + math.sin(a) * 7)
        put(img, x, y, LEATHER[2])
        put(img, x + 1, y, LEATHER[3])
    line(img, 6, 1, 6, 14, hexc("e8e0d0"))
    rect(img, 11, 7, 12, 9, LEATHER[0])
    return img


def icon_book():
    img = new(16, 16)
    rect(img, 2, 2, 13, 14, hexc("4e2a68"))
    rect(img, 3, 2, 13, 13, hexc("6a3d8a"))
    rect(img, 12, 3, 13, 14, hexc("f0e8d8"))  # kartki
    rect(img, 2, 2, 3, 14, hexc("3a1e50"))
    for x, y in ((7, 5), (8, 6), (6, 7), (9, 7), (7, 8), (8, 9), (7, 10)):
        put(img, x, y, GOLD)
    put(img, 7, 7, hexc("9ad8ff"))
    put(img, 8, 8, hexc("9ad8ff"))
    return img


def icon_helmet(pal, nose):
    img = new(16, 16)
    for y in range(3, 13):
        for x in range(2, 14):
            if math.hypot(x - 7.5, (y - 9) * 1.15) <= 6.2 and y <= 11:
                put(img, x, y, pal[2] if x < 7 else pal[1])
    rect(img, 2, 11, 13, 12, pal[0])
    put(img, 5, 5, pal[3])
    if nose:
        rect(img, 7, 9, 8, 13, pal[1])
        rect(img, 4, 9, 6, 10, hexc("1a1c2c"))
        rect(img, 9, 9, 11, 10, hexc("1a1c2c"))
    return img


def icon_chest(pal, mail):
    img = new(16, 16)
    rect(img, 4, 3, 11, 14, pal[2])
    rect(img, 1, 3, 4, 8, pal[1])
    rect(img, 11, 3, 14, 8, pal[1])
    rect(img, 6, 2, 9, 4, (0, 0, 0, 0))
    rect(img, 4, 13, 11, 14, pal[0])
    if mail:
        for y in range(5, 13):
            for x in range(4, 12):
                if (x + y) % 2 == 0:
                    put(img, x, y, pal[1])
    else:
        line(img, 7, 5, 7, 12, pal[0])
        rect(img, 4, 10, 11, 10, pal[0])
        put(img, 7, 10, GOLD)
    return img


def icon_gloves():
    img = new(16, 16)
    rect(img, 4, 6, 10, 13, LEATHER[2])
    for i, x in enumerate((4, 6, 8)):
        rect(img, x, 2 + (i % 2), x + 1, 6, LEATHER[2])
    rect(img, 10, 6, 12, 9, LEATHER[2])  # kciuk
    rect(img, 4, 12, 10, 13, LEATHER[0])
    rect(img, 4, 6, 4, 11, LEATHER[3])
    return img


def icon_boots():
    img = new(16, 16)
    rect(img, 4, 2, 9, 11, LEATHER[2])
    rect(img, 4, 10, 13, 13, LEATHER[2])
    rect(img, 4, 13, 13, 14, LEATHER[0])
    rect(img, 4, 2, 9, 3, LEATHER[3])
    rect(img, 4, 2, 4, 12, LEATHER[3])
    return img


def icon_ring(metal, gem):
    img = new(16, 16)
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, y - 9)
            if 3.0 <= d <= 5.2:
                put(img, x, y, metal[1] if y > 8 else metal[2])
    if gem:
        rect(img, 6, 2, 9, 5, hexc(gem))
        put(img, 6, 2, hexc("ffffff"))
    return img


def icon_earring(metal, drop):
    img = new(16, 16)
    for t in range(8):
        a = math.pi * (0.2 + t / 7 * 1.2)
        put(img, int(8 + math.cos(a) * 3), int(4 - math.sin(a) * 3), metal[1])
    line(img, 8, 5, 8, 8, metal[1])
    if drop == "fang":
        for y in range(9, 15):
            w = max(0, (14 - y) // 2)
            rect(img, 7, y, 7 + w, y, hexc("f0e8d8"))
    else:
        rect(img, 6, 9, 10, 13, hexc(drop))
        put(img, 7, 10, hexc("ffffff"))
    return img


def icon_necklace():
    img = new(16, 16)
    for t in range(20):
        a = math.pi * t / 19
        put(img, round(7.5 + math.cos(a) * 5.5), round(1 + math.sin(a) * 5.5), GOLD_D if t % 2 else GOLD)
    for y in range(7, 15):  # bursztynowa zawieszka w kształcie kropli
        w = min(y - 7, 3) if y < 12 else 14 - y + 1
        rect(img, 8 - w, y, 7 + w, y, hexc("e0901a"))
    rect(img, 6, 10, 7, 11, hexc("f8c060"))
    return img


# ---------------------------------------------------------------- bronie w ręku (skierowane w prawo, rękojeść z lewej)
def held_sword(blade):
    img = new(18, 9)
    rect(img, 1, 4, 4, 4, BARK[2])
    put(img, 1, 4, GOLD)
    rect(img, 5, 1, 5, 7, GOLD)
    rect(img, 6, 3, 15, 5, blade[2])
    rect(img, 6, 3, 15, 3, blade[3])
    rect(img, 6, 5, 15, 5, blade[1])
    put(img, 16, 4, blade[2])
    if blade is RUST:
        for x in (8, 11, 14):
            put(img, x, 4, RUST[3])
    return img


def held_axe():
    img = new(20, 13)
    rect(img, 1, 6, 15, 7, BARK[2])
    rect(img, 1, 6, 15, 6, BARK[3])
    for x in range(13, 19):
        h = 5 - abs(x - 16)
        rect(img, x, 6 - h - 1, x, 7 + h + 1, IRON[1])
    rect(img, 18, 1, 18, 12, IRON[3])
    return img


def held_bow():
    img = new(9, 20)
    for y in range(1, 19):
        x = int(1 + math.sin((y - 1) / 17 * math.pi) * 5)
        put(img, x, y, BARK[2])
        put(img, x + 1, y, BARK[3])
    line(img, 1, 1, 1, 18, hexc("e8e0d0"))
    rect(img, 6, 9, 7, 10, LEATHER[0])
    return img


def held_book():
    img = new(12, 10)
    rect(img, 1, 1, 10, 8, hexc("f0e8d8"))
    rect(img, 5, 1, 6, 8, hexc("c8b898"))
    rect(img, 0, 8, 11, 9, hexc("6a3d8a"))
    for x in (2, 3, 8, 9):
        put(img, x, 3, hexc("8a7a9a"))
        put(img, x, 5, hexc("8a7a9a"))
    put(img, 3, 4, hexc("9ad8ff"))
    put(img, 8, 4, hexc("9ad8ff"))
    return img


def make_projectiles():
    os.makedirs(PROJECTILES, exist_ok=True)
    arrow = new(14, 5)
    rect(arrow, 2, 2, 11, 2, BARK[3])
    rect(arrow, 11, 1, 12, 3, IRON[2])
    put(arrow, 13, 2, IRON[3])
    for x in (1, 2, 3):
        put(arrow, x, 1, hexc("e8e0d0"))
        put(arrow, x, 3, hexc("e8e0d0"))
    outline(arrow, OUTLINE_DARK)
    arrow.save(os.path.join(PROJECTILES, "arrow.png"))

    orb = new(9, 9)
    for y in range(9):
        for x in range(9):
            d = math.hypot(x - 4, y - 4)
            if d <= 4.2:
                c = hexc("ffffff") if d < 1.5 else hexc("b8e8ff") if d < 2.6 else hexc("7a5cff") if d < 3.6 else hexc("4a2ab0", 200)
                put(orb, x, y, c)
    orb.save(os.path.join(PROJECTILES, "magic_missile.png"))


# ---------------------------------------------------------------- umiejętności
SKILLS = os.path.join(os.path.dirname(ITEMS), "skills")


def skill_frame(bg, border):
    """Kwadratowa ramka ikony umiejętności."""
    img = new(16, 16)
    rect(img, 0, 0, 15, 15, hexc(border))
    rect(img, 1, 1, 14, 14, hexc(bg))
    return img


def skill_whirlwind():
    img = skill_frame("3a2a2a", "c0392b")
    for k in range(3):  # trzy wirujące ostrza
        a0 = k * math.tau / 3
        for t in range(12):
            a = a0 + t * 0.15
            r = 1.5 + t * 0.4
            put(img, round(7.5 + math.cos(a) * r), round(7.5 + math.sin(a) * r), IRON[3] if t > 6 else IRON[2])
    rect(img, 7, 7, 8, 8, GOLD)
    return img


def skill_multishot():
    img = skill_frame("2a3a2a", "6aa84f")
    for dy in (-4, 0, 4):
        line(img, 2, 8 + dy // 2, 12, 8 + dy, BARK[3])
        put(img, 13, 8 + dy, IRON[3])
        put(img, 2, 7 + dy // 2, hexc("e8e0d0"))
    return img


def skill_fireball():
    img = skill_frame("3a1e14", "e67e22")
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 9, y - 7)
            if d < 4.5:
                put(img, x, y, hexc("fdf2a6") if d < 1.8 else hexc("f5b041") if d < 3.2 else hexc("e67e22"))
    for i in range(5):  # ogon płomienia
        put(img, 4 - i // 2, 10 + i // 2, hexc("c0392b"))
        put(img, 5 - i // 2, 10 + i // 2, hexc("e67e22"))
    return img


def skill_regen(liquid, liquid_d, border):
    img = skill_frame("1e2230", border)
    if liquid == "heart":
        for y, row in enumerate([".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]):
            for x, ch in enumerate(row):
                if ch == "X":
                    put(img, 2 + x, 4 + y, hexc("d63a3a") if y < 3 else hexc("8e1b2b"))
    else:
        for y in range(3, 12):
            w = min(y - 3, 3) if y < 9 else 11 - y + 1
            rect(img, 5 - w, y, 5 + w, y, hexc(liquid))
        put(img, 4, 7, hexc("ffffff"))
    rect(img, 10, 5, 10, 11, hexc("f4f7fb"))  # plus
    rect(img, 8, 8, 12, 8, hexc("f4f7fb"))
    return img


def make_skill_art():
    os.makedirs(SKILLS, exist_ok=True)
    for name, img in (
        ("whirlwind", skill_whirlwind()),
        ("multishot", skill_multishot()),
        ("fireball", skill_fireball()),
        ("health_regen", skill_regen("heart", None, "d63a3a")),
        ("mana_regen", skill_regen("3b6fd8", None, "3b6fd8")),
    ):
        img.save(os.path.join(SKILLS, name + ".png"))

    fireball = new(11, 11)
    for y in range(11):
        for x in range(11):
            d = math.hypot(x - 5, y - 5)
            if d <= 5.2:
                c = hexc("fff7d0") if d < 1.6 else hexc("fdd25a") if d < 2.8 else hexc("f08a24") if d < 4.0 else hexc("c0392b", 220)
                put(fireball, x, y, c)
    fireball.save(os.path.join(PROJECTILES, "fireball.png"))

    # miękki krąg wybuchu (skalowany w grze do promienia)
    boom = new(64, 64)
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5) / 32.0
            if d <= 1.0:
                a = int(255 * (1.0 - d) ** 0.6)
                c = (255, 230, 150) if d < 0.35 else (255, 150, 50) if d < 0.7 else (200, 60, 30)
                boom.putpixel((x, y), (*c, a))
    boom.save(os.path.join(PROJECTILES, "explosion.png"))


# ---------------------------------------------------------------- umiejętności
SKILLS = os.path.join(os.path.dirname(ITEMS), "skills")


def skill_frame(bg, border):
    """Kwadratowa ramka ikony umiejętności."""
    img = new(16, 16)
    rect(img, 0, 0, 15, 15, hexc(border))
    rect(img, 1, 1, 14, 14, hexc(bg))
    return img


def skill_whirlwind():
    img = skill_frame("3a2a2a", "c0392b")
    for k in range(3):  # trzy wirujące ostrza
        a0 = k * math.tau / 3
        for t in range(12):
            a = a0 + t * 0.15
            r = 1.5 + t * 0.4
            put(img, round(7.5 + math.cos(a) * r), round(7.5 + math.sin(a) * r), IRON[3] if t > 6 else IRON[2])
    rect(img, 7, 7, 8, 8, GOLD)
    return img


def skill_multishot():
    img = skill_frame("2a3a2a", "6aa84f")
    for dy in (-4, 0, 4):
        line(img, 2, 8 + dy // 2, 12, 8 + dy, BARK[3])
        put(img, 13, 8 + dy, IRON[3])
        put(img, 2, 7 + dy // 2, hexc("e8e0d0"))
    return img


def skill_fireball():
    img = skill_frame("3a1e14", "e67e22")
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 9, y - 7)
            if d < 4.5:
                put(img, x, y, hexc("fdf2a6") if d < 1.8 else hexc("f5b041") if d < 3.2 else hexc("e67e22"))
    for i in range(5):  # ogon płomienia
        put(img, 4 - i // 2, 10 + i // 2, hexc("c0392b"))
        put(img, 5 - i // 2, 10 + i // 2, hexc("e67e22"))
    return img


def skill_regen(liquid, liquid_d, border):
    img = skill_frame("1e2230", border)
    if liquid == "heart":
        for y, row in enumerate([".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]):
            for x, ch in enumerate(row):
                if ch == "X":
                    put(img, 2 + x, 4 + y, hexc("d63a3a") if y < 3 else hexc("8e1b2b"))
    else:
        for y in range(3, 12):
            w = min(y - 3, 3) if y < 9 else 11 - y + 1
            rect(img, 5 - w, y, 5 + w, y, hexc(liquid))
        put(img, 4, 7, hexc("ffffff"))
    rect(img, 10, 5, 10, 11, hexc("f4f7fb"))  # plus
    rect(img, 8, 8, 12, 8, hexc("f4f7fb"))
    return img


def make_skill_art():
    os.makedirs(SKILLS, exist_ok=True)
    for name, img in (
        ("whirlwind", skill_whirlwind()),
        ("multishot", skill_multishot()),
        ("fireball", skill_fireball()),
        ("health_regen", skill_regen("heart", None, "d63a3a")),
        ("mana_regen", skill_regen("3b6fd8", None, "3b6fd8")),
    ):
        img.save(os.path.join(SKILLS, name + ".png"))

    fireball = new(11, 11)
    for y in range(11):
        for x in range(11):
            d = math.hypot(x - 5, y - 5)
            if d <= 5.2:
                c = hexc("fff7d0") if d < 1.6 else hexc("fdd25a") if d < 2.8 else hexc("f08a24") if d < 4.0 else hexc("c0392b", 220)
                put(fireball, x, y, c)
    fireball.save(os.path.join(PROJECTILES, "fireball.png"))

    # miękki krąg wybuchu (skalowany w grze do promienia)
    boom = new(64, 64)
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5) / 32.0
            if d <= 1.0:
                a = int(255 * (1.0 - d) ** 0.6)
                c = (255, 230, 150) if d < 0.35 else (255, 150, 50) if d < 0.7 else (200, 60, 30)
                boom.putpixel((x, y), (*c, a))
    boom.save(os.path.join(PROJECTILES, "explosion.png"))


# ---------------------------------------------------------------- kamienie zaklinające
# (ciemny, średni, jasny, blask) dla zwykłych i doskonałych
STONE_COLORS = {
    "weapon": {"normal": ("4a0c14", "7a1a26", "a8303c", "d65060"), "perfect": ("9e1e2e", "e03a4a", "ff7a80", "ffd0d0")},
    "armor": {"normal": ("0e2350", "1c3c7a", "2e5aa8", "5a86d0"), "perfect": ("1e4ab0", "3a7af0", "7ab0ff", "d8ecff")},
    "jewelry": {"normal": ("2a1240", "48236a", "6a3a94", "9468c0"), "perfect": ("6a2aa8", "a35ae0", "d08cff", "f2dcff")},
}


def stone_icon(category, perfect):
    pal = [hexc(c) for c in STONE_COLORS[category]["perfect" if perfect else "normal"]]
    img = new(16, 16)
    shape = set()
    for y in range(16):
        for x in range(16):
            if perfect:
                # fasolka: szeroka elipsa z wcięciem u góry
                inside = ((x + 0.5 - 8) / 6.3) ** 2 + ((y + 0.5 - 8.5) / 4.4) ** 2 <= 1
                notch = math.hypot(x + 0.5 - 8.5, y + 0.5 - 2.6) < 2.4
                if inside and not notch:
                    shape.add((x, y))
            else:
                # jajko: węższe u góry
                dy = (y + 0.5 - 8.8) / 5.2
                rx = 3.9 * (1.0 + 0.18 * dy)
                if abs(dy) <= 1 and abs(x + 0.5 - 8) <= rx * math.sqrt(max(0.0, 1 - dy * dy)):
                    shape.add((x, y))
    xs = [p[0] for p in shape]
    ys = [p[1] for p in shape]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    for x, y in shape:
        # światło z lewej góry
        v = -(x - cx) * 0.18 - (y - cy) * 0.22
        c = pal[2] if v > 0.6 else pal[1] if v > -0.5 else pal[0]
        img.putpixel((x, y), c)
    hx, hy = int(cx - 2), int(cy - 2)
    put(img, hx, hy, pal[3])
    put(img, hx + 1, hy, pal[3] if perfect else pal[2])
    put(img, hx, hy + 1, pal[2])
    if perfect:
        put(img, hx + 4, hy + 3, pal[3])
    outline(img, OUTLINE_DARK)

    # magiczna aura - słabsza przy zwykłych, mocniejsza i szersza przy doskonałych
    glow = pal[2]
    reach = 2.3 if perfect else 1.5
    strength = 190 if perfect else 70
    solid = {(x, y) for y in range(16) for x in range(16) if img.getpixel((x, y))[3] > 0}
    for y in range(16):
        for x in range(16):
            if (x, y) in solid:
                continue
            d = min(math.hypot(x - sx, y - sy) for sx, sy in solid)
            if d <= reach:
                a = int(strength * (1 - (d - 1) / reach))
                img.putpixel((x, y), (glow[0], glow[1], glow[2], max(0, min(255, a))))
    if perfect:  # iskierki
        for x, y in ((1, 2), (14, 3), (2, 13), (13, 14)):
            if (x, y) not in solid:
                img.putpixel((x, y), (*pal[3][:3], 220))
    return img


def make_stone_icons():
    for category in STONE_COLORS:
        stone_icon(category, False).save(os.path.join(ITEMS, f"{category}_stone.png"))
        stone_icon(category, True).save(os.path.join(ITEMS, f"{category}_stone_perfect.png"))


# ---------------------------------------------------------------- kamienie zaklinające
# (ciemny, średni, jasny, blask) dla zwykłych i doskonałych
STONE_COLORS = {
    "weapon": {"normal": ("4a0c14", "7a1a26", "a8303c", "d65060"), "perfect": ("9e1e2e", "e03a4a", "ff7a80", "ffd0d0")},
    "armor": {"normal": ("0e2350", "1c3c7a", "2e5aa8", "5a86d0"), "perfect": ("1e4ab0", "3a7af0", "7ab0ff", "d8ecff")},
    "jewelry": {"normal": ("2a1240", "48236a", "6a3a94", "9468c0"), "perfect": ("6a2aa8", "a35ae0", "d08cff", "f2dcff")},
}


def stone_icon(category, perfect):
    pal = [hexc(c) for c in STONE_COLORS[category]["perfect" if perfect else "normal"]]
    img = new(16, 16)
    shape = set()
    for y in range(16):
        for x in range(16):
            if perfect:
                # fasolka: szeroka elipsa z wcięciem u góry
                inside = ((x + 0.5 - 8) / 6.3) ** 2 + ((y + 0.5 - 8.5) / 4.4) ** 2 <= 1
                notch = math.hypot(x + 0.5 - 8.5, y + 0.5 - 2.6) < 2.4
                if inside and not notch:
                    shape.add((x, y))
            else:
                # jajko: węższe u góry
                dy = (y + 0.5 - 8.8) / 5.2
                rx = 3.9 * (1.0 + 0.18 * dy)
                if abs(dy) <= 1 and abs(x + 0.5 - 8) <= rx * math.sqrt(max(0.0, 1 - dy * dy)):
                    shape.add((x, y))
    xs = [p[0] for p in shape]
    ys = [p[1] for p in shape]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    for x, y in shape:
        # światło z lewej góry
        v = -(x - cx) * 0.18 - (y - cy) * 0.22
        c = pal[2] if v > 0.6 else pal[1] if v > -0.5 else pal[0]
        img.putpixel((x, y), c)
    hx, hy = int(cx - 2), int(cy - 2)
    put(img, hx, hy, pal[3])
    put(img, hx + 1, hy, pal[3] if perfect else pal[2])
    put(img, hx, hy + 1, pal[2])
    if perfect:
        put(img, hx + 4, hy + 3, pal[3])
    outline(img, OUTLINE_DARK)

    # magiczna aura - słabsza przy zwykłych, mocniejsza i szersza przy doskonałych
    glow = pal[2]
    reach = 2.3 if perfect else 1.5
    strength = 190 if perfect else 70
    solid = {(x, y) for y in range(16) for x in range(16) if img.getpixel((x, y))[3] > 0}
    for y in range(16):
        for x in range(16):
            if (x, y) in solid:
                continue
            d = min(math.hypot(x - sx, y - sy) for sx, sy in solid)
            if d <= reach:
                a = int(strength * (1 - (d - 1) / reach))
                img.putpixel((x, y), (glow[0], glow[1], glow[2], max(0, min(255, a))))
    if perfect:  # iskierki
        for x, y in ((1, 2), (14, 3), (2, 13), (13, 14)):
            if (x, y) not in solid:
                img.putpixel((x, y), (*pal[3][:3], 220))
    return img


def make_stone_icons():
    for category in STONE_COLORS:
        stone_icon(category, False).save(os.path.join(ITEMS, f"{category}_stone.png"))
        stone_icon(category, True).save(os.path.join(ITEMS, f"{category}_stone_perfect.png"))


ICONS = {
    "rusty_sword": lambda: icon_sword(RUST),
    "iron_sword": lambda: icon_sword(IRON),
    "war_axe": icon_axe,
    "short_bow": icon_bow,
    "spellbook": icon_book,
    "leather_cap": lambda: icon_helmet(LEATHER, False),
    "iron_helmet": lambda: icon_helmet(IRON, True),
    "leather_armor": lambda: icon_chest(LEATHER, False),
    "chainmail": lambda: icon_chest(IRON, True),
    "leather_gloves": icon_gloves,
    "leather_boots": icon_boots,
    "copper_ring": lambda: icon_ring(COPPER, None),
    "ring_of_strength": lambda: icon_ring(SILVER, "c0392b"),
    "silver_earring": lambda: icon_earring(SILVER, "3b6fd8"),
    "fang_earring": lambda: icon_earring(COPPER, "fang"),
    "amber_necklace": icon_necklace,
}

HELD = {
    "rusty_sword": lambda: held_sword(RUST),
    "iron_sword": lambda: held_sword(IRON),
    "war_axe": held_axe,
    "short_bow": held_bow,
    "spellbook": held_book,
}


def make_all():
    for name, make in ICONS.items():
        save(make(), ITEMS, name)
    for name, make in HELD.items():
        save(make(), WEAPONS, name)
    make_projectiles()
    make_skill_art()
    make_stone_icons()
    make_stone_icons()
    make_skill_art()
