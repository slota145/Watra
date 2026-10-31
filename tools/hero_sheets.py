"""Arkusze postaci gracza z PixelLab (pixellab_src/heroes/<postać>/) i dane chwytu broni.

Każda postać ma 5 kierunków (south, south-east, east, north-east, north - pozostałe gra
odbija w poziomie) i animacje: idle (obrót postaci), walk, slash (zamach), cast (czar),
shoot (łuk) - po 4 klatki. Arkusz: kolumny = klatki, wiersze = animacja * 5 + kierunek.

Chwyt broni: PixelLab przerysował klatki spoczynku i chodu z postacią trzymającą znacznik -
pręt z różowym (#FF00FF) końcem w dłoni i błękitnym (#00FFFF) czubkiem (pliki mk_*.png).
Z położenia obu kolorów liczymy punkt chwytu i kąt broni dla każdej klatki - w grze
broń z ekwipunku jest wtedy trzymana w dłoni i kołysze się razem z ręką.

Wynik: assets/heroes/<postać>.png i scripts/hero_rig.gd (stałe dla gry).
Uruchom: python tools/hero_sheets.py"""
import colorsys
import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "heroes")
OUT = os.path.join(ROOT, "assets", "heroes")

HEROES = [("wojciech", "Wojciech"), ("bogdan", "Bogdan"), ("mira", "Mira"), ("jaga", "Jaga")]
DIRS = ["south", "south-east", "east", "north-east", "north"]
ANIMS = ["idle", "walk", "slash", "cast", "shoot"]
FRAMES = 4
CELL = 72
FEET_Y = 62  # stopy w komórce (od góry), przed zmniejszeniem
## Postać z PixelLab jest za duża przy reszcie świata - zmniejszamy ją do ok. 30 px wzrostu
## (trochę więcej niż dawna, 24-pikselowa postać). Wynikowa komórka i stopy:
SCALE = 0.75
## Znaczniki, którym nie da się ufać: Mira trzyma znacznik za plecami i w chodzie bokiem przekłada go przez ciało.
## STEADY_WALK - w chodzie broń zostaje w dłoni z pozy spoczynku (kołysze się z sylwetką); IDLE_GRIP_FROM - spoczynek
## w danym kierunku bierze chwyt z innego kierunku.
STEADY_WALK = {"mira": ("east", "south-east")}
IDLE_GRIP_FROM = {"mira": {"south-east": "east"}}
OUT_CELL = round(CELL * SCALE)
OUT_FEET_Y = round(FEET_Y * SCALE)


def _open(path):
    return Image.open(path).convert("RGBA")


def _bottom(img):
    return img.getbbox()[3]


def _frames(hero, anim, direction):
    folder = os.path.join(SRC, hero)
    if anim == "idle":
        path = os.path.join(folder, "rot_%s.png" % direction)
        return [path] * FRAMES if os.path.exists(path) else []
    paths = [os.path.join(folder, "%s_%s_%d.png" % (anim, direction, i)) for i in range(FRAMES)]
    return paths if all(os.path.exists(p) for p in paths) else []


def _hsv(r, g, b):
    h, sat, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    return h * 360.0, sat, v


def _is_magenta(r, g, b):
    h, sat, v = _hsv(r, g, b)
    return 280.0 <= h <= 335.0 and sat > 0.3 and v > 0.35


def _is_cyan(r, g, b):
    # błękitny czubek bywa bardzo blady - wystarczy wyraźnie błękitny odcień
    h, sat, v = _hsv(r, g, b)
    return 170.0 <= h <= 196.0 and sat > 0.15 and v > 0.72


def _is_rod(r, g, b):
    return min(r, g, b) > 165 or _is_magenta(r, g, b) or _is_cyan(r, g, b)


def _largest_group(points):
    """Największa zwarta grupa pikseli (odrzuca pojedyncze błyski w kolorze znacznika na stroju)."""
    left = set(points)
    best = []
    while left:
        start = left.pop()
        group, stack = [start], [start]
        while stack:
            x, y = stack.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in left:
                        left.remove(n)
                        group.append(n)
                        stack.append(n)
        if len(group) > len(best):
            best = group
    return best


def _marker(img):
    """(x, y chwytu, x, y czubka) znacznika albo None. Czubek to środek błękitnych pikseli;
    chwyt - środek różowych, a gdy różowy koniec schował się w pięści, najdalszy od czubka
    punkt pręta (idziemy od czubka po jasnych pikselach pręta)."""
    px = img.load()
    mag, cyan = [], []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            if _is_magenta(r, g, b):
                mag.append((x, y))
            elif _is_cyan(r, g, b):
                cyan.append((x, y))
    cyan = _largest_group(cyan)
    mag = _largest_group(mag)
    if len(cyan) < 2:
        return None
    cx = sum(p[0] for p in cyan) / len(cyan)
    cy = sum(p[1] for p in cyan) / len(cyan)
    if len(mag) >= 2:
        return sum(p[0] for p in mag) / len(mag), sum(p[1] for p in mag) / len(mag), cx, cy
    seen = set(cyan)
    stack = list(cyan)
    while stack:
        x, y = stack.pop()
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                n = (x + dx, y + dy)
                if n in seen or not (0 <= n[0] < img.width and 0 <= n[1] < img.height):
                    continue
                r, g, b, a = px[n]
                if a >= 128 and _is_rod(r, g, b):
                    seen.add(n)
                    stack.append(n)
    far = max(seen, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
    if (far[0] - cx) ** 2 + (far[1] - cy) ** 2 < 16:
        return None
    return far[0], far[1], cx, cy


def build(hero):
    folder = os.path.join(SRC, hero)
    sheet = Image.new("RGBA", (CELL * FRAMES, CELL * len(ANIMS) * len(DIRS)))
    grips = {}
    tops = {}  # (animacja, kierunek, klatka) -> czubek głowy względem stóp (kołysanie przy chodzie)
    for a, anim in enumerate(ANIMS):
        grips[anim] = []
        for d, direction in enumerate(DIRS):
            rot = _open(os.path.join(folder, "rot_%s.png" % direction))
            dir_grips = []
            for f, path in enumerate(_frames(hero, anim, direction)):
                img = _open(path)
                # płótna PixelLab są wyśrodkowane na postaci: stopy z obrotu, przesunięte o różnicę płócien
                feet = _bottom(rot) + (img.height - rot.height) / 2.0
                x0 = CELL / 2.0 - img.width / 2.0
                y0 = FEET_Y - feet
                sheet.alpha_composite(img, (int(f * CELL + x0), int((a * len(DIRS) + d) * CELL + y0)))
                tops[(anim, d, f)] = img.getbbox()[1] + y0 - FEET_Y
                # znacznik chwytu (tylko spoczynek i chód)
                mk_name = "mk_idle_%s.png" % direction if anim == "idle" else "mk_%s_%s_%d.png" % (anim, direction, f)
                mk_path = os.path.join(folder, mk_name)
                grip = None
                if os.path.exists(mk_path):
                    mk = _open(mk_path)
                    found = _marker(mk)
                    if found:
                        mx, my, cx, cy = found
                        # znacznik może mieć inne płótno niż czysta klatka - też wyśrodkowane
                        ox = (mk.width - img.width) / 2.0
                        oy = (mk.height - img.height) / 2.0
                        gx = mx - ox + x0 - CELL / 2.0
                        gy = my - oy + y0 - FEET_Y
                        angle = math.atan2(cy - my, cx - mx)
                        # bokiem broń ma celować przed postać - PixelLab bywa, że rysuje znacznik
                        # trzymany za plecami (Mira); odbijamy wtedy kąt i dłoń w poziomie względem
                        # środka sylwetki, żeby rękojeść była w przedniej dłoni
                        if direction in ("east", "south-east") and math.cos(angle) < 0:
                            angle = math.atan2(math.sin(angle), -math.cos(angle))
                            box = img.getbbox()
                            body_x = (box[0] + box[2]) / 2.0 + x0 - CELL / 2.0
                            gx = 2.0 * body_x - gx
                        grip = [round(gx * SCALE, 1), round(gy * SCALE, 1), round(angle, 3)]
                dir_grips.append(grip)
            # brakujące klatki biorą chwyt z poprzedniej (albo z najbliższej znalezionej)
            known = [g for g in dir_grips if g]
            for i, g in enumerate(dir_grips):
                if g is None and known:
                    dir_grips[i] = dir_grips[i - 1] if i > 0 and dir_grips[i - 1] else known[0]
            # pojedyncza klatka z bronią obróconą w drugą stronę (np. Bogdan idący na północ) - kąt jak w pozostałych
            if len(known) >= 3:
                for i, g in enumerate(dir_grips):
                    others = [o[2] for j, o in enumerate(dir_grips) if j != i]
                    near = [a for a in others if abs(math.remainder(a - g[2], math.tau)) < math.pi / 3]
                    if not near:
                        dir_grips[i] = [g[0], g[1], sorted(others)[len(others) // 2]]
            grips[anim].append(dir_grips if known else [])
    # spoczynek bez znacznika bierze chwyt z pierwszej klatki chodu (i odwrotnie)
    for d in range(len(DIRS)):
        if not grips["idle"][d] and grips["walk"][d]:
            grips["idle"][d] = [grips["walk"][d][0]] * FRAMES
        elif not grips["walk"][d] and grips["idle"][d]:
            grips["walk"][d] = list(grips["idle"][d])
    for d, direction in enumerate(DIRS):
        source = IDLE_GRIP_FROM.get(hero, {}).get(direction)
        if source:
            grips["idle"][d] = list(grips["idle"][DIRS.index(source)])
        if direction in STEADY_WALK.get(hero, ()) and grips["idle"][d]:
            # chwyt spoczynku, który unosi się i opada razem z sylwetką
            hold = grips["idle"][d][0]
            grips["walk"][d] = [[hold[0], round(hold[1] + (tops[("walk", d, f)] - tops[("idle", d, 0)]) * SCALE, 1), hold[2]]
                                for f in range(FRAMES)]
    os.makedirs(OUT, exist_ok=True)
    _shrink(sheet).save(os.path.join(OUT, hero + ".png"))
    return grips


def _shrink(sheet):
    """Zmniejsza arkusz komórka po komórce tak, żeby został pixel artem: skalowanie z mieszaniem
    na kanale alfa (bez ciemnych obwódek), twardy próg przezroczystości i powrót do oryginalnej
    palety kolorów komórki - piksele zostają ostre, bez rozmytych półtonów."""
    cols, rows = sheet.width // CELL, sheet.height // CELL
    out = Image.new("RGBA", (OUT_CELL * cols, OUT_CELL * rows))
    for r in range(rows):
        for c in range(cols):
            cell = sheet.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
            if cell.getbbox() is None:
                continue
            small = shrink_image(cell, OUT_CELL, OUT_CELL)
            out.alpha_composite(small, (c * OUT_CELL, r * OUT_CELL))
    return out


def shrink_image(cell, out_w, out_h):
    """Zmniejsza jeden obrazek pixel artu do out_w x out_h: skalowanie z mieszaniem na kanale
    alfa, twardy próg przezroczystości i powrót do oryginalnej palety kolorów."""
    cell_px = cell.load()
    palette = list({cell_px[x, y][:3] for y in range(cell.height) for x in range(cell.width) if cell_px[x, y][3] >= 128})
    small = cell.convert("RGBa").resize((out_w, out_h), Image.LANCZOS).convert("RGBA")
    px = small.load()
    cache = {}
    for y in range(out_h):
        for x in range(out_w):
            red, green, blue, alpha = px[x, y]
            if alpha < 110 or not palette:
                px[x, y] = (0, 0, 0, 0)
                continue
            key = (red, green, blue)
            if key not in cache:
                cache[key] = min(palette, key=lambda p: (p[0] - red) ** 2 + (p[1] - green) ** 2 + (p[2] - blue) ** 2)
            px[x, y] = cache[key] + (255,)
    return small


def _gd(value):
    if value is None:
        return "[]"
    if isinstance(value, list):
        return "[" + ", ".join(_gd(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{" + ", ".join('"%s": %s' % (k, _gd(v)) for k, v in value.items()) + "}"
    return repr(value)


def main():
    grips = {}
    heroes = [(h, n) for h, n in HEROES if os.path.exists(os.path.join(SRC, h, "rot_south.png"))]
    for hero, _name in heroes:
        grips[hero] = build(hero)
        print("Zapisano", hero)
    lines = [
        "class_name HeroRig",
        "## Wygenerowane przez tools/hero_sheets.py - nie edytować ręcznie.",
        "## Postacie gracza z PixelLab: arkusz assets/heroes/<postać>.png (kolumny = klatki,",
        "## wiersze = animacja * DIRS + kierunek) i chwyt broni w dłoni dla każdej klatki:",
        "## [x, y, kąt] w pikselach od stóp postaci (kierunki zachodnie = odbicie lustrzane).",
        "",
        "const HEROES := %s" % _gd([h for h, _n in heroes]),
        "const NAMES := %s" % _gd({h: n for h, n in heroes}),
        "const DIRS := %d" % len(DIRS),
        "const ANIMS := %s" % _gd(ANIMS),
        "const FRAMES := %d" % FRAMES,
        "const CELL := %d" % OUT_CELL,
        "const FEET_Y := %d" % OUT_FEET_Y,
        "const GRIPS := {",
    ]
    for hero, data in grips.items():
        lines.append('\t"%s": %s,' % (hero, _gd(data)))
    lines += [
        "}",
        "",
        "",
        "static func sheet(hero: String) -> Texture2D:",
        '\treturn load("res://assets/heroes/%s.png" % hero)',
        "",
        "",
        "static func frame_index(anim: String, dir: int, frame: int) -> int:",
        "\treturn (ANIMS.find(anim) * DIRS + dir) * FRAMES + frame",
        "",
        "",
        "## Chwyt [x, y, kąt] dla klatki (pusta tablica - brak danych, np. podczas ataku).",
        "static func grip(hero: String, anim: String, dir: int, frame: int) -> Array:",
        "\tvar per_dir: Array = GRIPS.get(hero, {}).get(anim, [])",
        "\tif dir >= per_dir.size() or per_dir[dir].is_empty():",
        "\t\treturn []",
        "\treturn per_dir[dir][mini(frame, per_dir[dir].size() - 1)]",
        "",
    ]
    with open(os.path.join(ROOT, "scripts", "hero_rig.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("Zapisano scripts/hero_rig.gd")


if __name__ == "__main__":
    main()
