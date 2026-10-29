"""Podłoże Wietrznych Turni z zestawów Wang PixelLab (tryb pro, 64 px, pixellab_src/alpine/<zestaw>.png
+ .json z pixellab_src/alpine/fetch.py). Z każdego zestawu bierzemy pełny kafelek (wszystkie narożniki
jednego terenu) - to bezszwowa tekstura 64x64, którą gra kładzie w przestrzeni świata, a przejścia między
terenami rysuje shader (scripts/soft_ground.gd). Wynik: assets/mountains/ground/<teren>.png.
Uruchom: python tools/alpine_tiles.py"""
import json
import os

from PIL import Image, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "alpine")
OUT = os.path.join(ROOT, "assets", "mountains", "ground")

# zestaw: (teren dolny albo None, teren górny, jasność)
SETS = {
    "path": ("meadow", "path", 1.0),
    "rock": (None, "rock", 1.0),
    "scree": (None, "scree", 1.0),
    "dark": (None, "dark", 1.45),
    "flowers": (None, "flowers", 0.88),
    "snow": (None, "snow", 1.0),
}
MOUNTAINS = os.path.join(ROOT, "assets", "mountains")
# rzędy prostej ściany (kafelek z górnymi narożnikami płaskowyżu i dolnymi ściany, 64x128 po złożeniu):
# kępki nawisu, ciało ściany (32 px = jeden poziom w grze) i podstawa z kępkami trawy u dołu
LIP_ROWS = (30, 46)
WALL_ROWS = (72, 104)
FOOT_ROWS = (104, 120)
GRASS_FROM = 119


def full_tile(sheet, meta, side):
    for tile in meta["tileset_data"]["tiles"]:
        if all(v == side for v in tile["corners"].values()):
            box = tile["bounding_box"]
            return sheet.crop((box["x"], box["y"], box["x"] + box["width"], box["y"] + box["height"]))
    return None


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (lower, upper, brightness) in SETS.items():
        png = os.path.join(SRC, name + ".png")
        if not os.path.exists(png):
            continue
        sheet = Image.open(png).convert("RGBA")
        meta = json.load(open(os.path.join(SRC, name + ".json"), encoding="utf-8"))
        for kind, side in ((lower, "lower"), (upper, "upper")):
            if kind is None:
                continue
            tile = full_tile(sheet, meta, side)
            if tile is None:
                print("  %s: brak pełnego kafelka (%s)" % (name, side))
                continue
            if brightness != 1.0:
                tile = ImageEnhance.Brightness(tile).enhance(brightness)
            tile.save(os.path.join(OUT, kind + ".png"))
    _flowers_on_meadow()
    print("podłoże gór:", sorted(os.listdir(OUT)))
    cliffs()


def _flowers_on_meadow():
    """Kwietna łąka: same kwiatki z zestawu łąki (jej trawa wyszła bladomiętowa) położone na teksturze hali."""
    meadow_path = os.path.join(OUT, "meadow.png")
    png = os.path.join(SRC, "flowers.png")
    if not os.path.exists(meadow_path) or not os.path.exists(png):
        return
    import colorsys
    sheet = Image.open(png).convert("RGBA")
    flowers = full_tile(sheet, json.load(open(os.path.join(SRC, "flowers.json"), encoding="utf-8")), "upper")
    out = Image.open(meadow_path).convert("RGBA")
    for y in range(64):
        for x in range(64):
            r, g, b, _a = flowers.getpixel((x, y))
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            # kwiatek: nie-zielony odcień albo prawie biały
            if not (0.17 < h < 0.45) and s > 0.25 or s < 0.18 and v > 0.8:
                out.putpixel((x, y), (r, g, b, 255))
    out.save(os.path.join(OUT, "flowers.png"))


def _band(column, rows, width=256):
    """Pas o szerokości `width` z wierszy `rows` kolumny ściany (wzór powtarza się co 64 px)."""
    piece = column.crop((0, rows[0], column.width, rows[1]))
    band = Image.new("RGBA", (width, piece.height))
    for x in range(0, width, piece.width):
        band.paste(piece, (x, 0))
    return band


def cliffs():
    """Klify gór w stylu zestawu z pełnymi ścianami (pixellab_src/alpine/cliff.png): prosta ściana z dwóch
    kafelków (płaskowyż -> ściana -> hala) cięta na nawis z kępkami trawy, pas ściany i podstawę.
    Nadpisuje grafiki z region_props.cliffs(), więc kod gry się nie zmienia."""
    png = os.path.join(SRC, "cliff.png")
    if not os.path.exists(png):
        return
    import region_props  # najpierw dawne klify ze źródeł (zakończenia, rampa, nawisy skały i żwiru) - przybarwiamy je od nowa
    region_props.cliffs()
    sheet = Image.open(png).convert("RGBA")
    meta = json.load(open(os.path.join(SRC, "cliff.json"), encoding="utf-8"))
    boxes = {}
    for tile in meta["tileset_data"]["tiles"]:
        c = tile["corners"]
        boxes[(c["NW"], c["NE"], c["SW"], c["SE"])] = tile["bounding_box"]

    def crop(key):
        b = boxes[key]
        return sheet.crop((b["x"], b["y"], b["x"] + b["width"], b["y"] + b["height"]))

    column = Image.new("RGBA", (64, 128))
    column.paste(crop(("upper", "upper", "transition", "transition")), (0, 0))
    column.paste(crop(("transition", "transition", "lower", "lower")), (0, 64))
    _band(column, WALL_ROWS).save(os.path.join(MOUNTAINS, "cliff_strip.png"))
    # podstawa: dół ściany z kępkami trawy; wiersze samej trawy przezroczyste (pod spodem jest hala)
    foot = _band(column, FOOT_ROWS)
    for y in range(GRASS_FROM - FOOT_ROWS[0], foot.height):
        for x in range(foot.width):
            foot.putpixel((x, y), (0, 0, 0, 0))
    foot.save(os.path.join(MOUNTAINS, "cliff_foot.png"))
    # nawis trawy: kępki nad ścianą, cień pod nimi zostaje (rysowany na ścianie)
    lip = _band(column, LIP_ROWS)
    lip.save(os.path.join(MOUNTAINS, "cliff_lip_grass.png"))
    lip.rotate(-90, expand=True).save(os.path.join(MOUNTAINS, "cliff_lip_grass_side.png"))
    # zakończenia ścian ze starej, szarej skały - przybarwione na brąz nowej ściany
    path = os.path.join(MOUNTAINS, "cliff_end.png")
    if os.path.exists(path):
        _warm(Image.open(path).convert("RGBA")).save(path)
    _stairs()
    print("klify gór (styl zestawu z pełnymi ścianami)")


def _stairs():
    """Rampa: kamienne schody 48x32, które gra kładzie na pas ściany (boki zasłaniają skały końców ścian, górę
    nawis podłoża). Stopnie z palety skalnej ściany: jasny wierzch, ciemna podstopnica, spoiny między płytami,
    nierówne końce i trochę mchu - dawna wnęka z PixelLab wyglądała na wklejoną."""
    import random
    rng = random.Random(7)
    strip = Image.open(os.path.join(MOUNTAINS, "cliff_strip.png")).convert("RGB")
    pixels = list(strip.getdata())
    stone = sorted({p for p in pixels if p[0] >= p[1] + 6 and p[1] >= p[2]}, key=sum)
    moss = [p for p in pixels if p[1] > p[0] + 25]

    def tone(t):  # 0 - najciemniejszy kamień ściany, 1 - najjaśniejszy
        return stone[min(len(stone) - 1, max(0, int(t * (len(stone) - 1))))] + (255,)

    out = Image.new("RGBA", (48, 32))
    step = 4
    for k in range(32 // step):
        top = k * step
        a = 5 + rng.choice((0, 0, 1))
        b = 43 - rng.choice((0, 0, 1))
        # płyty stopnia: każda z lekko inną jasnością, spoina między nimi
        joints = {}
        x = a
        shade = rng.uniform(-0.06, 0.06)
        while x < b:
            joints[x] = shade
            x += 1
            if rng.random() < 0.09 and x < b - 5:
                shade = rng.uniform(-0.06, 0.06)
                joints[x] = None
                x += 1
        for r in range(step):
            for x in range(a, b):
                t = (0.95, 0.72, 0.42, 0.1)[r] + rng.uniform(-0.05, 0.05)
                if joints.get(x) is None and r < 3:
                    t = 0.3
                else:
                    t += joints[x] or 0.0
                if x in (a, b - 1):
                    t -= 0.15
                out.putpixel((x, top + r), tone(t))
        for _ in range(rng.randint(0, 2)):  # mech przy końcach stopni
            x = rng.choice((a + rng.randint(0, 3), b - 1 - rng.randint(0, 3)))
            out.putpixel((x, top + 1), rng.choice(moss) + (255,))
    out.save(os.path.join(MOUNTAINS, "ramp.png"))


def _warm(image):
    """Szara skała -> ciepła, brązowoszara jak nowa ściana."""
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0 or g > r + 25:  # mech i trawę zostawiamy
                continue
            v = (r + g + b) / 3
            px[x, y] = (min(255, int(v * 1.12 + 6)), int(v * 0.96), int(v * 0.8), a)
    return out


if __name__ == "__main__":
    main()
