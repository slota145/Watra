"""Arkusze i grafiki z PixelLab (pixellab_src/...) dla gry.

PixelLab zwraca każdą klatkę osobno: obroty postaci na płótnie wielkości postaci (np. 80x80),
animacje na większym płótnie z miejscem na ruch (np. 112x112). Postać zawsze stoi pośrodku
płótna, więc poziomo wyrównujemy środki płócien, a pionowo - stopy (dół sylwetki pierwszej
klatki danej animacji). Dzięki temu postać nie podskakuje między animacjami.

Potwory dostają standardowy układ 4x2 jak gobliny: 0-3 chód, 4-5 spoczynek, 6 zamach, 7 cios
(bossowie mają w 5-7 swoje pozy ataków). Leszy ma pełne animacje ataków (5 rzędów).

Uruchamiane na końcu generate_art.py (nadpisuje grafiki Prastarego Lasu z ancient_art.py),
albo osobno: python tools/pixellab_sheets.py"""
import json
import os

from PIL import Image, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src")
ANCIENT = os.path.join(ROOT, "assets", "ancient")
LAYOUT = {}  # nazwa arkusza -> wymiary komórki i przesunięcie sprite'a (do scen)


def _open(path):
    return Image.open(os.path.join(SRC, path)).convert("RGBA")


def _bottom(img):
    return img.getbbox()[3]


def sheet(name, rows, out, margin=2):
    """rows: lista rzędów; rząd to lista klatek, klatka to (plik, plik_odniesienia_stóp).
    Zwraca rozmiar komórki i y stóp w komórce."""
    placed = []  # (rząd, kolumna, obraz, x środka, y stóp na obrazie)
    for r, frames in enumerate(rows):
        for c, (path, ref) in enumerate(frames):
            img = _open(path)
            ref_img = _open(ref)
            # płótna są wyśrodkowane na postaci - stopy z odniesienia przesuwamy o różnicę płócien
            placed.append((r, c, img, img.width / 2.0, _bottom(ref_img) + (img.height - ref_img.height) / 2.0))
    # komórka: największy zasięg treści wokół punktu (środek, stopy)
    left = right = up = down = 0
    for _, _, img, cx, fy in placed:
        box = img.getbbox()
        left = max(left, cx - box[0])
        right = max(right, box[2] - cx)
        up = max(up, fy - box[1])
        down = max(down, box[3] - fy)
    half = int(max(left, right)) + margin
    width = half * 2
    feet = int(up) + margin
    height = feet + int(down) + margin
    height += height % 2
    columns = max(len(r) for r in rows)
    out_img = Image.new("RGBA", (width * columns, height * len(rows)), (0, 0, 0, 0))
    for r, c, img, cx, fy in placed:
        out_img.alpha_composite(img, (int(c * width + half - cx), int(r * height + feet - fy)))
    out_img.save(out)
    LAYOUT[name] = {"cell": [width, height], "offset_y": -(feet - height / 2.0)}
    print("Zapisano %s %s komórka %dx%d stopy %d" % (name, out_img.size, width, height, feet))


def same(path):
    return (path, path)


def anim(folder, name, count, ref=None):
    """Klatki animacji wyrównane do stóp pierwszej klatki (albo `ref`)."""
    files = ["%s/%s_%d.png" % (folder, name, i) for i in range(count)]
    return [(f, ref or files[0]) for f in files]


def leshy():
    rows = [
        anim("leshy", "walk", 4),
        anim("leshy", "summon", 5)[1:],
        anim("leshy", "roots", 5)[1:],
        anim("leshy", "leaves", 5)[1:],
        [same("leshy/leshy_south-east.png")],
    ]
    # animacje v3 (summon/roots/leaves) zaczynają się od klatki = obrót - stopy jak w klatce 0
    rows[1] = [(f, "leshy/summon_0.png") for f, _ in rows[1]]
    rows[2] = [(f, "leshy/roots_0.png") for f, _ in rows[2]]
    rows[3] = [(f, "leshy/leaves_0.png") for f, _ in rows[3]]
    sheet("leshy", rows, os.path.join(ANCIENT, "leshy_pl.png"))


def creature(name, walk, idle, windup, strike, extra=None, mirror=False):
    """Arkusz 4x2: chód (4), spoczynek (2), zamach, cios. `extra` zastępuje klatki 5-7.
    `mirror` odbija każdą klatkę w poziomie - gra zakłada, że potwór na rysunku patrzy w prawo
    (Goblin/Boss odbijają go przy ruchu w lewo), a niektóre obroty z PixelLab patrzą w lewo."""
    row2 = [idle, idle, windup, strike]
    if extra:
        row2 = [idle] + extra
    path = os.path.join(ANCIENT, name + "_pl.png")
    sheet(name, [walk, row2], path)
    if mirror:
        img = Image.open(path)
        cell_w, cell_h = img.width // 4, img.height // 2
        out = Image.new("RGBA", img.size)
        for i in range(8):
            box = ((i % 4) * cell_w, (i // 4) * cell_h, (i % 4 + 1) * cell_w, (i // 4 + 1) * cell_h)
            out.paste(img.crop(box).transpose(Image.Transpose.FLIP_LEFT_RIGHT), box[:2])
        out.save(path)


def creatures():
    a = "ancient/"

    def walk(name):
        return anim(a + name, "walk", 4)

    def pose(name, frame):
        return (a + name + "/" + frame + ".png", a + name + "/rot.png")

    def rot(name):
        return same(a + name + "/rot.png")

    creature("treant", walk("treant"), rot("treant"), pose("treant", "smash_1"), pose("treant", "smash_3"))
    creature("spider", walk("spider"), rot("spider"), pose("spider", "attack_1"), pose("spider", "attack_3"))
    creature("web_spider", walk("web_spider"), rot("web_spider"), pose("web_spider", "attack_1"),
             pose("web_spider", "attack_3"))
    creature("spiderling", walk("spiderling"), rot("spiderling"), pose("spiderling", "walk_1"),
             pose("spiderling", "walk_3"))
    # mini-bossowie i bossowie: 5-7 to ich pozy ataków (forest_beast.gd, bies.gd, spider_queen.gd)
    creature("beast_bear", walk("bear"), rot("bear"), None, None,
             extra=[pose("bear", "slam_1"), pose("bear", "slam_1"), pose("bear", "slam_3")])
    creature("beast_werewolf", walk("werewolf"), rot("werewolf"), None, None,
             extra=[pose("werewolf", "frenzy_0"), pose("werewolf", "frenzy_1"), pose("werewolf", "frenzy_3")])
    creature("bies", walk("bies"), rot("bies"), None, None,
             extra=[pose("bies", "roar_2"), pose("bies", "slash_1"), pose("bies", "slash_3")])
    # królowa na obrotach z PixelLab patrzy w lewo - odbita, żeby nie stała do gracza tyłem
    creature("spider_queen", walk("queen"), rot("queen"), None, None,
             extra=[pose("queen", "spray_3"), pose("queen", "summon_2"), pose("queen", "leap_2")], mirror=True)


def glow_shroom():
    """Dwie klatki: przygaszone grzyby i te same rozjarzone (jaśniejsze, turkusowe)."""
    dim = _open("ancient/small/frame_0.png")
    box = dim.getbbox()
    dim = dim.crop(box)
    lit = ImageEnhance.Brightness(dim).enhance(1.9)
    r, g, b, alpha = lit.split()
    lit = Image.merge("RGBA", (r.point(lambda v: int(v * 0.7)), g, b.point(lambda v: min(255, int(v * 1.15))), alpha))
    out = Image.new("RGBA", (dim.width * 2, dim.height))
    out.alpha_composite(dim, (0, 0))
    out.alpha_composite(lit, (dim.width, 0))
    out.save(os.path.join(ANCIENT, "glow_shroom.png"))


def soften_base(img, frac=0.3):
    """Podstawa ogromnych drzew (wysepka mchu z ciemnym obrysem) wygląda jak naklejka - usuwamy
    ciemny obrys przy dolnej krawędzi i rozpraszamy brzeg w szachownicę, żeby wtopił się w runo."""
    px = img.load()
    box = img.getbbox()
    top = int(box[3] - (box[3] - box[1]) * frac)

    def edge(x, y):
        return any(not (0 <= x + dx < img.width and 0 <= y + dy < img.height) or px[x + dx, y + dy][3] == 0
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))

    for _ in range(2):
        dark = [(x, y) for y in range(top, img.height) for x in range(img.width)
                if px[x, y][3] and sum(px[x, y][:3]) < 150 and edge(x, y)]
        for x, y in dark:
            px[x, y] = (0, 0, 0, 0)
    rim = [(x, y) for y in range(top, img.height) for x in range(img.width) if px[x, y][3] and edge(x, y)]
    for x, y in rim:
        if (x + y) % 2 == 0:
            px[x, y] = (0, 0, 0, 0)
        else:
            r, g, b, _a = px[x, y]
            px[x, y] = (r, g, b, 150)
    return img


BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
## Ile pikseli od dołu grafiki leży jej podstawa (np. pień drzewa, a nie koniec korzeni) -
## trafia do scripts/prop_sinks.gd, żeby gra ustalała kolejność rysowania od podstawy.
SINKS = {}


def trunk_base(img):
    """(x środka pnia, y początku korzeni, y podstawy) na przyciętej grafice drzewa: pień to
    najwęższe miejsce w dolnej części, korzenie zaczynają się tam, gdzie sylwetka znów się rozszerza."""
    px = img.load()
    widths = [sum(1 for x in range(img.width) if px[x, y][3]) for y in range(img.height)]
    lo, hi = int(img.height * 0.45), int(img.height * 0.92)
    trunk = min(range(lo, hi), key=lambda y: widths[y])
    roots = next((y for y in range(trunk, img.height) if widths[y] > widths[trunk] * 1.6), int(img.height * 0.9))
    xs = [x for x in range(img.width) if px[x, trunk][3]]
    cx = sum(xs) / max(len(xs), 1)
    return cx, roots, int(roots + 0.4 * (img.height - roots))


def fade_roots(img):
    """Korzenie i wysepka mchu u stóp drzewa stopniowo (w ditheringu) znikają ku krawędziom,
    zamiast urywać się prostą linią - drzewo wtapia się w runo. Zwraca y podstawy."""
    px = img.load()
    cx, roots, base = trunk_base(img)
    xs = [x for y in range(roots, img.height) for x in range(img.width) if px[x, y][3]]
    rx = max(cx - min(xs), max(xs) - cx, 1)
    ry = max(img.height - roots, 1)
    for y in range(roots, img.height):
        for x in range(img.width):
            if not px[x, y][3]:
                continue
            d = (((x - cx) / rx) ** 2 + ((y - roots) / ry) ** 2) ** 0.5
            fade = min(max((d - 0.55) / 0.45, 0.0), 1.0)
            if BAYER[y % 4][x % 4] / 16.0 < fade:
                px[x, y] = (0, 0, 0, 0)
    return base


def trimmed(src, out, keep_light=False, soft_base=False, sink=None, scale=1.0):
    """Pojedyncza grafika przycięta do treści (dół = podstawa obiektu).
    `scale` zmniejsza wynik (próbkowanie najbliższym pikselem, bez rozmycia)."""
    img = _open(src)
    if keep_light:  # pajęczyna na ziemi: tylko jasne nitki, bez ciemnego tła
        px = img.load()
        for y in range(img.height):
            for x in range(img.width):
                cr, cg, cb, ca = px[x, y]
                if ca and (cr + cg + cb) / 3 < 150:
                    px[x, y] = (0, 0, 0, 0)
    if soft_base:
        soften_base(img)
    img = img.crop(img.getbbox())
    if scale != 1.0:
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.Resampling.NEAREST)
    if soft_base:
        base = fade_roots(img)
        img = img.crop((0, 0, img.width, img.getbbox()[3]))
        SINKS[out[:-4]] = img.height - base
    elif sink == "trunk":
        SINKS[out[:-4]] = img.height - trunk_base(img)[2]
    elif sink is not None:
        SINKS[out[:-4]] = int(img.height * sink)
    img.save(os.path.join(ANCIENT, out))
    return img


def pair(first, second, out, soft_base=False, scale=1.0):
    """Dwie klatki obok siebie (np. drzewo uśpione / przebudzone), wyrównane do dołu.
    `scale` zmniejsza wynik (próbkowanie najbliższym pikselem, bez rozmycia)."""
    a, b = _open(first), _open(second)
    if soft_base:
        soften_base(a)
        soften_base(b)
    sink = 0
    if soft_base:
        a, b = a.crop(a.getbbox()), b.crop(b.getbbox())
        sink = a.height - fade_roots(a)
        fade_roots(b)
    box_a, box_b = a.getbbox(), b.getbbox()
    w = max(box_a[2] - box_a[0], box_b[2] - box_b[0])
    h = max(box_a[3] - box_a[1], box_b[3] - box_b[1])
    out_img = Image.new("RGBA", (w * 2, h))
    for i, (img, box) in enumerate(((a, box_a), (b, box_b))):
        crop = img.crop(box)
        out_img.alpha_composite(crop, (i * w + (w - crop.width) // 2, h - crop.height))
    if scale != 1.0:
        cell_w, cell_h = round(w * scale), round(h * scale)
        out_img = out_img.resize((cell_w * 2, cell_h), Image.Resampling.NEAREST)
    out_img.save(os.path.join(ANCIENT, out))
    if sink:
        SINKS[out[:-4]] = sink


def strip(sources, out):
    """Jednakowe klatki obok siebie (np. drobne detale runa) - bez przycinania."""
    imgs = [_open(s) for s in sources]
    w, h = imgs[0].size
    out_img = Image.new("RGBA", (w * len(imgs), h))
    for i, img in enumerate(imgs):
        out_img.alpha_composite(img, (i * w, 0))
    out_img.save(os.path.join(ANCIENT, out))


# indeksy z paczek PixelLab (pixellab_src/ancient/<paczka>/frame_<i>.png)
PROPS = {"menhir_0": 0, "menhir_1": 1, "menhir_2": 2, "altar_stump": 3, "fallen_log": 4, "claw_tree": 5,
         "broken_tree": 6, "skull_totem": 7, "wrapped_victim": 10, "egg_sac": 11, "ancient_stump": 12,
         "bone_pile": 13, "mossy_rock": 14, "rotten_stump": 15}
## Zmniejszenie niektórych obiektów (owinięta ofiara była ponad 2 razy dłuższa niż wzrost postaci).
PROP_SCALE = {"wrapped_victim": 0.5}
DECOR = [2, 3, 4, 5, 6, 7, 8, 9, 13, 14, 15, 18, 20, 31, 32, 34, 37, 38, 44, 47, 48, 51, 57, 60, 63]
REMAINS = [22, 23, 24, 26, 40, 41]  # czaszka, miecz, dzban, kości, latarnia, plecak - ślady poszukiwaczy


def props():
    a = "ancient"
    for i in range(3):
        trimmed("%s/trees/frame_%d.png" % (a, i), "giant_tree_%d.png" % i, soft_base=True)
    face = "%s/trees/frame_3.png" % a
    awake = "%s/trees/awake.png" % a
    pair(face, awake if os.path.exists(os.path.join(SRC, awake)) else face, "ancient_tree.png", soft_base=True)
    for name, i in PROPS.items():
        trimmed("%s/props/frame_%d.png" % (a, i), name + ".png", sink="trunk" if name in ("claw_tree", "broken_tree") else 0.12,
                scale=PROP_SCALE.get(name, 1.0))
    for i in range(3):
        lit = "%s/props/menhir_%d_lit.png" % (a, i)
        base = "%s/props/frame_%d.png" % (a, i)
        pair(base, lit if os.path.exists(os.path.join(SRC, lit)) else base, "menhir_%d.png" % i)
    # kokon z uwięzionym człowiekiem - zmniejszony, żeby człowiek w środku miał mniej więcej wzrost postaci
    pair("%s/props/frame_8.png" % a, "%s/props/frame_9.png" % a, "cocoon.png", scale=0.6)
    trimmed("%s/webs/frame_0.png" % a, "web_huge.png", sink=0.15)
    trimmed("%s/webs/frame_1.png" % a, "web_big.png", keep_light=True)
    trimmed("%s/webs/frame_2.png" % a, "web_tangle.png", keep_light=True)
    trimmed("%s/small/frame_10.png" % a, "web_small.png")
    trimmed("%s/small/frame_11.png" % a, "blood.png")
    trimmed("%s/small/frame_12.png" % a, "scratches.png")
    strip(["%s/small/frame_%d.png" % (a, i) for i in DECOR], "decor.png")
    strip(["%s/small/frame_%d.png" % (a, i) for i in REMAINS], "remains.png")
    glow_shroom()
    # drzewa do ścinania w Prastarym Lesie: duże (płótno 80), wszystkie stopą w tym samym miejscu
    for name, i in (("stump", 5), ("thorn_bush", 14)):
        trimmed("%s/forest_trees/frame_%d.png" % (a, i), "tree_" + name + ".png")
    sinks = []
    for kind, indices in TREES.items():
        for n, i in enumerate(indices):
            img = _clean_specks(_open("%s/big_trees/frame_%d.png" % (a, i)))
            crop = img.crop(img.getbbox())
            sinks.append(crop.height - trunk_base(crop)[2])
            out = Image.new("RGBA", (TREE_CANVAS, TREE_CANVAS))
            out.alpha_composite(crop, ((TREE_CANVAS - crop.width) // 2, TREE_CANVAS - crop.height))
            out.save(os.path.join(ANCIENT, "tree_%s_%d.png" % (kind, n)))
    # drzewa do ścinania losują grafikę w grze, więc dostają wspólne (średnie) zagłębienie
    SINKS["tree"] = round(sum(sinks) / len(sinks))
    write_sinks()


def write_sinks():
    lines = ["class_name PropSinks",
             "## Wygenerowane przez tools/pixellab_sheets.py - nie edytować ręcznie.",
             "## Ile pikseli od dołu grafiki leży podstawa obiektu (pień, a nie koniec korzeni). O tyle",
             "## grafika schodzi poniżej punktu, według którego gra ustala, co jest bliżej kamery.",
             "", "const SINKS := {"]
    lines += ['\t"%s": %d,' % (name, value) for name, value in sorted(SINKS.items())]
    lines += ["}", "", "",
              "static func of(texture: Texture2D) -> int:",
              "\treturn SINKS.get(texture.resource_path.get_file().get_basename(), 0)", ""]
    with open(os.path.join(ROOT, "scripts", "prop_sinks.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


# duże drzewa z paczki big_trees: liściaste (dęby, buki, lipy, brzoza, wierzba, jarzębina, martwe) i iglaste
TREES = {"oak": [0, 1, 2, 3, 7, 8, 9, 10, 11, 12, 13, 14, 15], "pine": [4, 5, 6]}
TREE_CANVAS = 80


def _clean_specks(img, min_size=16):
    """Usuwa drobne, oderwane grupki pikseli (śmieci z generowania wokół drzew)."""
    px = img.load()
    seen = set()
    for y in range(img.height):
        for x in range(img.width):
            if (x, y) in seen or px[x, y][3] == 0:
                continue
            group, stack = [], [(x, y)]
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                group.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < img.width and 0 <= ny < img.height and (nx, ny) not in seen and px[nx, ny][3]:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if len(group) < min_size:
                for gx, gy in group:
                    px[gx, gy] = (0, 0, 0, 0)
    return img


TILE_ROWS = 4  # ściółka, liście, mech, korzenie - po 4 warianty (rzędy 7-10)
## Zestawy przejść Wang (rzędy 11+, po 4 rzędy na zestaw): ściółka -> mech / liście / ścieżka.
## Kafelek leży w kolumnie mask % 4 i rzędzie mask / 4, gdzie mask = NW<<3 | NE<<2 | SW<<1 | SE
## (bit = narożnik pokryty górnym terenem) - AncientForest liczy maskę tak samo.
WANG_SETS = ["moss", "leaves", "path"]
WANG_ROW = 7 + TILE_ROWS
WANG_BRIGHTNESS = 0.62


def tiles():
    """Kafelki runa Prastarego Lasu w tiles.png: warianty z tiles_pro i zestawy przejść Wang."""
    sheet_path = os.path.join(ROOT, "assets", "tiles.png")
    old = Image.open(sheet_path).convert("RGBA")
    # rzędy za zestawami Prastarego Lasu (np. przejścia Goblińskiego Lasu z forest_sheets.py) zostają
    end = (WANG_ROW + 4 * len(WANG_SETS)) * 16
    sheet_img = Image.new("RGBA", (old.width, max(end, old.height)))
    sheet_img.paste(old.crop((0, 0, old.width, 7 * 16)), (0, 0))
    if old.height > end:
        sheet_img.paste(old.crop((0, end, old.width, old.height)), (0, end))
    for i in range(TILE_ROWS * 4):
        sheet_img.paste(_open("ancient/tiles/tile_%d.png" % i), ((i % 4) * 16, (7 + i // 4) * 16))
    for n, name in enumerate(WANG_SETS):
        # zestawy Wang wychodzą jaśniejsze i żywsze niż reszta runa - przygaszamy je do mroku puszczy
        wang = ImageEnhance.Color(ImageEnhance.Brightness(_open("ancient/wang/%s.png" % name)).enhance(WANG_BRIGHTNESS)).enhance(0.8)
        meta = json.load(open(os.path.join(SRC, "ancient", "wang", name + ".json")))
        for tile in meta["tileset_data"]["tiles"]:
            c = tile["corners"]
            mask = sum(bit for corner, bit in (("NW", 8), ("NE", 4), ("SW", 2), ("SE", 1)) if c[corner] == "upper")
            box = tile["bounding_box"]
            crop = wang.crop((box["x"], box["y"], box["x"] + box["width"], box["y"] + box["height"]))
            sheet_img.paste(crop, ((mask % 4) * 16, (WANG_ROW + n * 4 + mask // 4) * 16))
    sheet_img.save(sheet_path)


def main():
    leshy()
    creatures()
    props()
    tiles()
    json.dump(LAYOUT, open(os.path.join(SRC, "layout.json"), "w"), indent=1)
    print("Grafiki z PixelLab gotowe")


if __name__ == "__main__":
    main()
