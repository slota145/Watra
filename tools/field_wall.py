"""Murek z polnych kamieni jako zestaw kafelków (autotile) dla Pól Zbożowych: 16 kafelków na wszystkie połączenia
z sąsiadami (maska: 1 - północ, 2 - wschód, 4 - południe, 8 - zachód), więc murek biegnie ciągłą linią wzdłuż
miedz w każdym kierunku, z narożnikami, rozwidleniami i zakończeniami.

Widok z góry z ukosa: podstawa murka (8 px szerokości) leży na środku kafelka, wierzch jest uniesiony o WALL_H px,
a od południa widać ciemniejsze lico z rzędami kamieni. Kafelek ma 16x(16+TOP) px - dolne 16 px to komórka na ziemi,
górne TOP px to miejsce na wierzch murka wystający nad komórkę. Kamienie wierzchu i lica rysujemy z położenia
w świecie modulo 16 px, a spoiny wypadają na krawędziach kafelka - sąsiednie kafelki łączą się bez szwu.
Wynik: assets/fields/stone_wall.png (16 kafelków w rzędzie, w kolejności maski).
Uruchom: python tools/field_wall.py"""
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "fields")

T = 16
WALL_H = 6
TOP = 8
CELL_H = T + TOP
HALF = 4  # połowa szerokości podstawy murka
GROUND_Y = TOP + T // 2  # środek komórki na płótnie

OUTLINE = (30, 22, 16)
TOP_STONES = [(150, 136, 118), (138, 122, 104), (160, 148, 128), (128, 114, 98), (146, 128, 104)]
TOP_LIGHT = (184, 172, 152)
FACE_STONES = [(96, 82, 68), (88, 72, 60), (104, 90, 74), (80, 66, 54)]
FACE_DARK = (62, 50, 40)
JOINT = (52, 42, 34)
MOSS = [(92, 110, 52), (110, 128, 60)]


def footprint(mask):
    """Podstawa murka w komórce (współrzędne ziemi 0..15, ramiona wychodzą poza komórkę do sąsiadów)."""
    def inside(x, y):
        c = T // 2
        if c - HALF <= x < c + HALF and c - HALF <= y < c + HALF:
            return True
        if mask & 1 and c - HALF <= x < c + HALF and y < c:
            return True
        if mask & 4 and c - HALF <= x < c + HALF and y >= c:
            return True
        if mask & 8 and c - HALF <= y < c + HALF and x < c:
            return True
        if mask & 2 and c - HALF <= y < c + HALF and x >= c:
            return True
        return False
    return inside


def stone_field(spacing, seed):
    """Środki kamieni na poszarpanej siatce zawiniętej co 16 px (wzór powtarza się bez szwu co kafelek)."""
    rnd = random.Random(seed)
    sx, sy = spacing
    centers = []
    for j in range(T // sy):
        for i in range(T // sx):
            centers.append((i * sx + rnd.uniform(0.5, sx - 0.5), j * sy + rnd.uniform(0.5, sy - 0.5), rnd.random()))
    return centers


TOP_FIELD = stone_field((4, 4), 11)
FACE_FIELD = stone_field((4, 4), 23)


def stone_color(gx, gy, palette, seed):
    """Polny kamień pod pikselem: najbliższy środek (odległość na torusie 16x16, dla lica spłaszczona w pionie);
    spoina tam, gdzie dwa najbliższe środki są prawie tak samo blisko. Jeden kolor na kamień, rozjaśniony od
    góry-lewej i przyciemniony od dołu-prawej - kamienie wyglądają na obłe. Zwraca kolor, czy spoina, mech."""
    field = TOP_FIELD if seed == 1 else FACE_FIELD
    squash = 1.0 if seed == 1 else 1.4
    x, y = gx % T, gy % T
    best = second = 99.0
    pick = None
    for cx, cy, r in field:
        dx = (x + 0.5 - cx + T / 2) % T - T / 2
        dy = ((y + 0.5 - cy + T / 2) % T - T / 2) * squash
        d = (dx * dx + dy * dy) ** 0.5
        if d < best:
            second, best, pick = best, d, (r, dx, dy)
        elif d < second:
            second = d
    joint = second - best < 1.1
    r, dx, dy = pick
    base = palette[int(r * len(palette) * 7) % len(palette)]
    light = -(dx + dy) / 3.0  # >0 od góry-lewej
    factor = 1.0 + max(-0.25, min(0.2, light * 0.12))
    color = tuple(max(0, min(255, int(c * factor))) for c in base)
    return color, joint, r < 0.12


def tile(mask):
    img = Image.new("RGBA", (T, CELL_H))
    base = footprint(mask)
    # na płótnie: piksel (x, py) - ziemia na y = py - TOP; wierzch to podstawa przesunięta o WALL_H w górę
    top = lambda x, py: base(x, py - TOP + WALL_H)
    ground = lambda x, py: base(x, py - TOP)
    for py in range(CELL_H):
        for x in range(T):
            if top(x, py):
                gy = py - TOP + WALL_H  # wierzch "leży" nad tym punktem ziemi
                color, joint, mossy = stone_color(x, gy, TOP_STONES, 1)
                if joint:
                    color = JOINT
                elif mossy:
                    color = MOSS[(x + gy) % 2]
                img.putpixel((x, py), color + (255,))
            elif ground(x, py):
                # lico od południa: rzędy kamieni, u dołu ciemniej (cień przy ziemi)
                depth = 0
                while depth < WALL_H and not top(x, py - depth - 1):
                    depth += 1
                color, joint, _mossy = stone_color(x, py, FACE_STONES, 2)
                if joint:
                    color = JOINT
                if depth == 0:
                    color = FACE_DARK
                img.putpixel((x, py), color + (255,))
    # obrys: przezroczyste piksele przy murku dostają ciemny kontur (tylko w obrębie kafelka - na krawędziach
    # połączonych z sąsiadem konturu nie ma, bo tam murek przechodzi dalej)
    px = img.load()
    edge = []
    for py in range(CELL_H):
        for x in range(T):
            if px[x, py][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, py + dy
                if 0 <= nx < T and 0 <= ny < CELL_H and px[nx, ny][3] and px[nx, ny][:3] != OUTLINE:
                    edge.append((x, py))
                    break
    for x, py in edge:
        px[x, py] = OUTLINE + (255,)
    # wierzch od góry jaśniejszy (światło z północy), krawędź wierzchu nad licem ciemniejsza
    for py in range(1, CELL_H):
        for x in range(T):
            if px[x, py][3] and px[x, py][:3] != OUTLINE and top(x, py) and not top(x, py - 1) and px[x, py - 1][:3] == OUTLINE:
                px[x, py] = TOP_LIGHT + (255,)
            if top(x, py - 1) and not top(x, py) and ground(x, py):
                px[x, py] = OUTLINE + (255,)
    return img


def main():
    sheet = Image.new("RGBA", (T * 16, CELL_H))
    for mask in range(16):
        sheet.alpha_composite(tile(mask), (mask * T, 0))
    os.makedirs(OUT, exist_ok=True)
    sheet.save(os.path.join(OUT, "stone_wall.png"))
    print("stone_wall.png", sheet.size)


if __name__ == "__main__":
    main()
