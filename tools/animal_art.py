"""Zwierzyna łowna: jeleń, sarna, dzik i zając (bokiem, patrzą w prawo) oraz łupy -
skóry, mięso i poroże. Wywoływane z generate_art.py.

Arkusz zwierzęcia: 4 kolumny x 2 wiersze klatek -
wiersz 0: bieg (0-3), wiersz 1: pasienie (łeb przy ziemi, 2 klatki), czujność (łeb w górze), stanie."""
import math
import os

from generate_art import OUT, OUTLINE_DARK, hexc, line, new, outline, put, rect, shadow_ellipse

WILD = os.path.join(OUT, "wild")
ITEMS = os.path.join(OUT, "items")

EYE = hexc("1a1c2c")
HOOF = hexc("2a1e16")
WHITE = hexc("ece4d4")


def ellipse(img, cx, cy, rx, ry, color, top=None, bottom=None):
    """Wypełniona elipsa; opcjonalnie jaśniejszy wierzch / ciemniejszy spód."""
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                c = color
                if top is not None and dy < -0.45:
                    c = top
                if bottom is not None and dy > 0.5:
                    c = bottom
                put(img, x, y, c)


def legs(img, xs, top, ground, color, far_color, phase, swing, thick=1):
    """Cztery nogi: (tylna dalsza, tylna bliższa, przednia dalsza, przednia bliższa)."""
    for i, x in enumerate(xs):
        far = i % 2 == 0
        s = swing * math.sin(phase + (0 if i < 2 else math.pi) + (math.pi if far else 0))
        knee_x = x + s * 0.4
        foot_x = x + s
        c = far_color if far else color
        line(img, round(x), top, round(knee_x), (top + ground) // 2, c)
        line(img, round(knee_x), (top + ground) // 2, round(foot_x), ground - 1, c)
        if thick > 1:
            line(img, round(x) + 1, top, round(knee_x) + 1, (top + ground) // 2, c)
        put(img, round(foot_x), ground, HOOF)
        if thick > 1:
            put(img, round(foot_x) + 1, ground, HOOF)


def sheet_from(frames, w, h, name):
    sheet = new(w * 4, h * 2)
    for i, img in enumerate(frames):
        sheet.paste(img, ((i % 4) * w, (i // 4) * h))
    sheet.save(os.path.join(WILD, name + ".png"))


def pose_params(i):
    """Numer klatki -> (faza biegu, podskok, łeb: 'run'/'graze'/'alert'/'stand')."""
    if i < 4:
        return i * math.pi / 2, (1 if i in (1, 3) else 0), "run"
    return 0.0, 0, ["graze", "graze2", "alert", "stand"][i - 4]


# ---------------------------------------------------------------- jeleń i sarna
def cervid(i, big):
    W, H = (30, 36) if big else (24, 22)
    img = new(W, H)
    phase, bob, head = pose_params(i)
    coat = hexc("8a5a34") if big else hexc("a8743f")
    coat_d = hexc("6b4226") if big else hexc("86592e")
    coat_l = hexc("a8743f") if big else hexc("c4905a")
    ground = H - 2
    body_y = (H - 13 if big else H - 10) - bob
    body_x = W // 2 - 2
    rx, ry = (8, 4.2) if big else (6.5, 3.4)
    leg_top = int(body_y + ry - 1)
    xs = [body_x - rx + 2, body_x - rx + 3, body_x + rx - 3, body_x + rx - 2]
    legs(img, xs, leg_top, ground, coat_d, hexc("4e2f1b"), phase, 2.5 if head == "run" else 0.0)
    ellipse(img, body_x, body_y, rx, ry, coat, top=coat_d, bottom=coat_l)
    # ogon / biała plama na zadzie (sarna ma "lusterko")
    if big:
        rect(img, body_x - rx - 1, body_y - 2, body_x - rx, body_y, coat_d)
    else:
        ellipse(img, body_x - rx + 1, body_y - 0.5, 1.8, 2.2, WHITE)
    # szyja i łeb
    nx = int(body_x + rx - 2)
    if head in ("graze", "graze2"):
        hx, hy = nx + 4, ground - 3 + (1 if head == "graze2" else 0)
    elif head == "alert":
        hx, hy = nx + 3, body_y - (11 if big else 8)
    else:
        hx, hy = nx + 4, body_y - (8 if big else 6)
    for k in range(3):
        line(img, nx - 1 + k, body_y - 1, hx - 1 + k, hy + 1, coat if k else coat_d)
    ellipse(img, hx + 1, hy, 2.6 if big else 2.2, 1.9 if big else 1.6, coat)
    rect(img, hx + 3, hy, hx + 4, hy + 1, coat_l)  # pysk
    put(img, hx + 4, hy, EYE)  # nos
    put(img, hx + 1, hy - 1, EYE)  # oko
    put(img, hx - 1, hy - 2, coat_d)  # ucho
    put(img, hx - 2, hy - 3, coat_d)
    if big:  # poroże: dwie tyki odchylone do tyłu, odnogi skierowane do przodu (dalsza ciemniejsza)
        top = hy - 2
        for shift, a in ((4, hexc("b0a080")), (0, hexc("e8dcc0"))):
            bx = hx - 1 + shift
            line(img, bx, top, bx - 3, top - 5, a)
            line(img, bx - 3, top - 5, bx - 4, top - 10, a)
            line(img, bx - 1, top - 2, bx + 2, top - 3, a)  # oczniak
            line(img, bx - 3, top - 6, bx, top - 8, a)
            line(img, bx - 4, top - 10, bx - 6, top - 12, a)  # korona
            line(img, bx - 4, top - 10, bx - 2, top - 12, a)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, body_x, ground + 0.5, rx + 2, 1.5)
    return img


# ---------------------------------------------------------------- dzik
def boar(i):
    W, H = 24, 18
    img = new(W, H)
    phase, bob, head = pose_params(i)
    hair, hair_d, hair_l = hexc("4e3a2c"), hexc("33251c"), hexc("6b5442")
    ground = H - 2
    body_x, body_y = 11, H - 8 - bob
    xs = [body_x - 5, body_x - 4, body_x + 4, body_x + 5]
    legs(img, xs, body_y + 3, ground, hair_d, hexc("241a12"), phase, 2.0 if head == "run" else 0.0)
    ellipse(img, body_x, body_y, 7.5, 4.2, hair, top=hair_d, bottom=hair_l)
    for x in range(body_x - 5, body_x + 6, 2):  # szczecina na grzbiecie
        put(img, x, int(body_y - 4.6), hair_d)
        put(img, x + 1, int(body_y - 5.2), hair_d)
    line(img, body_x - 8, body_y - 1, body_x - 9, body_y + 1, hair_d)  # ogonek
    # łeb nisko, klinem w przód
    dy = 3 if head in ("graze", "graze2") else -1 if head == "alert" else 1
    hx, hy = body_x + 7, body_y + dy
    for k in range(5):
        rect(img, hx + k, hy - 2 + k // 2, hx + k, hy + 2, hair if k < 3 else hair_l)
    rect(img, hx + 5, hy, hx + 6, hy + 2, hexc("8a6a5a"))  # ryj
    put(img, hx + 6, hy + 1 + (1 if head == "graze2" else 0), EYE)
    put(img, hx + 2, hy - 1, EYE)
    put(img, hx + 4, hy + 2, WHITE)  # szabla
    put(img, hx + 4, hy + 1, WHITE)
    put(img, hx, hy - 3, hair_d)  # ucho
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, body_x, ground + 0.5, 9, 1.5)
    return img


# ---------------------------------------------------------------- zając
def hare(i):
    W, H = 16, 14
    img = new(W, H)
    phase, bob, head = pose_params(i)
    fur, fur_d, fur_l = hexc("9a7a58"), hexc("7a5a40"), hexc("c4a882")
    ground = H - 2
    hop = [0, 2, 3, 1][i] if i < 4 else 0
    body_x, body_y = 7, ground - 3 - hop
    stretch = 1.0 if i in (1, 2) else 0.0
    ellipse(img, body_x, body_y, 4 + stretch, 2.6, fur, top=fur_d, bottom=fur_l)
    # łapy: tylne długie, przednie krótkie
    if i < 4 and hop > 0:
        line(img, body_x - 3, body_y + 2, body_x - 5, body_y + 3, fur_d)
        line(img, body_x + 3, body_y + 2, body_x + 5, body_y + 3, fur_d)
    else:
        rect(img, body_x - 4, ground - 1, body_x - 1, ground, fur_d)
        put(img, body_x + 3, ground, fur_d)
    ellipse(img, body_x - 4.5, body_y - 0.5, 1.2, 1.2, WHITE)  # biały ogonek
    hx, hy = body_x + 4, body_y - (1 if head in ("graze", "graze2") else 3)
    if head in ("graze", "graze2"):
        hy = body_y + 1
    ellipse(img, hx, hy, 2.0, 1.7, fur)
    put(img, hx + 1, hy - 1, EYE)
    put(img, hx + 2, hy + (1 if head == "graze2" else 0), hexc("c08080"))
    # długie uszy
    lean = 2 if i < 4 else 0
    line(img, hx - 1, hy - 1, hx - 2 - lean, hy - 5, fur_d)
    line(img, hx, hy - 1, hx - 1 - lean, hy - 5, fur)
    outline(img, OUTLINE_DARK)
    shadow_ellipse(img, body_x, ground + 0.6, 5, 1.0)
    return img


# ---------------------------------------------------------------- łupy
def make_items():
    def hide(name, base, dark, light, spots=None):
        img = new(16, 16)
        for y in range(2, 15):
            half = 6 - abs(y - 8) // 2
            for x in range(8 - half, 8 + half):
                put(img, x, y, base if (x + y) % 5 else light)
        for x, y in ((2, 4), (13, 4), (2, 12), (13, 12)):
            rect(img, x, y, x + 1, y + 1, dark)
        line(img, 8, 3, 8, 13, dark)
        if spots:
            for x, y in spots:
                put(img, x, y, WHITE)
        outline(img, OUTLINE_DARK)
        img.save(os.path.join(ITEMS, name + ".png"))

    hide("deer_hide", hexc("8a5a34"), hexc("6b4226"), hexc("a8743f"))
    hide("roe_hide", hexc("a8743f"), hexc("86592e"), hexc("c4905a"), spots=[(5, 6), (10, 7), (6, 10), (11, 11)])
    hide("boar_hide", hexc("4e3a2c"), hexc("33251c"), hexc("6b5442"))

    pelt = new(16, 16)  # skórka zająca - mała i puszysta
    ellipse(pelt, 8, 9, 5, 4, hexc("9a7a58"), top=hexc("c4a882"))
    line(pelt, 5, 5, 4, 1, hexc("7a5a40"))
    line(pelt, 7, 5, 7, 1, hexc("7a5a40"))
    outline(pelt, OUTLINE_DARK)
    pelt.save(os.path.join(ITEMS, "hare_pelt.png"))

    meat = new(16, 16)  # udziec
    ellipse(meat, 7, 8, 5, 4, hexc("c0392b"), top=hexc("d9604e"), bottom=hexc("8e1b2b"))
    ellipse(meat, 6, 7, 2, 1.5, hexc("e8a090"))
    rect(meat, 11, 10, 14, 11, WHITE)  # kość
    rect(meat, 13, 9, 14, 12, WHITE)
    outline(meat, OUTLINE_DARK)
    meat.save(os.path.join(ITEMS, "meat.png"))

    antlers = new(16, 16)
    a, a_d = hexc("e0d0b0"), hexc("b0a080")
    for side in (-1, 1):
        cx = 8 + side * 2
        line(antlers, cx, 14, cx + side * 3, 4, a)
        line(antlers, cx + side * 3, 4, cx + side * 5, 1, a)
        line(antlers, cx + side, 10, cx + side * 5, 8, a_d)
        line(antlers, cx + side * 2, 6, cx + side * 6, 5, a_d)
    rect(antlers, 6, 13, 10, 14, hexc("8a5a34"))
    outline(antlers, OUTLINE_DARK)
    antlers.save(os.path.join(ITEMS, "antlers.png"))


def make_all():
    os.makedirs(WILD, exist_ok=True)
    sheet_from([cervid(i, True) for i in range(8)], 30, 36, "deer")
    sheet_from([cervid(i, False) for i in range(8)], 24, 22, "roe")
    sheet_from([boar(i) for i in range(8)], 24, 18, "boar")
    sheet_from([hare(i) for i in range(8)], 16, 14, "hare")
    make_items()
