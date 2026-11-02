"""Rekwizyty lochów Watry z paczek kandydatów PixelLab (create_1_direction_object, 64 px, top-down).
Surowe klatki leżą w pixellab_src/dungeons/<paczka>/frame_<i>.png (pobiera je pixellab_src/dungeons/fetch.py).
Narzędzie przycina każdą klatkę do zawartości, nakładkom na podłogę zmniejsza krycie (wtapiają się w kafelki)
i zapisuje wynik do assets/dungeons/<klimat>/<nazwa>.png. Chodnik (runner) rysuje samo - pionowy pas,
który gra powtarza wzdłuż komnaty.
Uruchom: python tools/dungeon_props.py"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "dungeons")

# klimat -> nazwa -> (paczka, klatka, krycie); z klatki zostaje najszersza ciągła grupa kolumn (main_part)
PROPS = {
    "catacombs": {
        # nakładki na podłogę
        "crack": ("catacombs_small", 0, 0.55),
        "puddle": ("catacombs_small", 1, 0.6),
        "rubble": ("catacombs_small", 2, 0.9),
        "hole": ("catacombs_small", 3, 0.7),
        "slab": ("catacombs_small", 4, 0.9),
        "grate": ("catacombs_small", 5, 0.9),
        "blood": ("catacombs_small", 6, 0.6),
        # na licu ściany
        "sconce": ("catacombs_small", 8, 1.0),
        "niche": ("catacombs_small", 9, 1.0),
        "banner": ("catacombs_small", 10, 1.0),
        "wall_crack": ("catacombs_small", 11, 1.0),
        # drobiazgi
        "candles": ("catacombs_small", 12, 1.0),
        "skull_pile": ("catacombs_small", 13, 1.0),
        "coffin_lid": ("catacombs_small", 14, 1.0),
        "urn": ("catacombs_small", 15, 1.0),
        # duże, z kolizją
        "pillar_0": ("catacombs_tall", 0, 1.0),
        "pillar_1": ("catacombs_tall", 1, 1.0),
        "pillar_2": ("catacombs_tall", 3, 1.0),
        "broken_0": ("catacombs_tall", 4, 1.0),
        "broken_1": ("catacombs_tall", 5, 1.0),
        "broken_2": ("catacombs_tall", 6, 1.0),
        "brazier": ("catacombs_tall", 7, 1.0),
        "brazier_iron": ("catacombs_tall", 8, 1.0),
        "brazier_cold": ("catacombs_tall", 9, 1.0),
        "statue_0": ("catacombs_tall", 10, 1.0),
        "statue_1": ("catacombs_tall", 11, 1.0),
        "statue_2": ("catacombs_tall", 12, 1.0),
        "sarcophagus_0": ("catacombs_tall", 13, 1.0),
        "sarcophagus_1": ("catacombs_tall", 14, 1.0),
        "coffin": ("catacombs_tall", 15, 1.0),
        # meble pod ściany
        "shelf": ("catacombs_furniture", 0, 1.0),
        "coffins_upright": ("catacombs_furniture", 1, 1.0),
        "candelabra": ("catacombs_furniture", 2, 1.0),
        "ossuary_shelf": ("catacombs_furniture", 3, 1.0),
        "table": ("catacombs_furniture", 4, 1.0),
        "cage": ("catacombs_furniture", 5, 1.0),
        "crates": ("catacombs_furniture", 6, 1.0),
        "upright_sarc": ("catacombs_furniture", 7, 1.0),
        "weapon_rack": ("catacombs_furniture", 8, 1.0),
        "chains": ("catacombs_furniture", 9, 1.0),
        "web": ("catacombs_furniture", 10, 1.0),
        "font": ("catacombs_furniture", 11, 1.0),
        "bench": ("catacombs_furniture", 12, 1.0),
        "shrouds": ("catacombs_furniture", 13, 1.0),
        "runestone": ("catacombs_furniture", 14, 1.0),
        "cart": ("catacombs_furniture", 15, 1.0),
    },
}


def main_part(img):
    """Najszersza ciągła grupa kolumn z treścią (przerwy do 6 px się nie liczą) - odcina okruchy sąsiednich
    kandydatów z paczki."""
    alpha = img.getchannel("A")
    filled = [any(alpha.getpixel((x, y)) for y in range(img.height)) for x in range(img.width)]
    for x in range(img.width):
        if not filled[x] and any(filled[max(0, x - 6):x]) and any(filled[x + 1:x + 7]):
            filled[x] = True
    best, start = (0, 0), None
    for x, on in enumerate(filled + [False]):
        if on and start is None:
            start = x
        elif not on and start is not None:
            if x - start > best[1] - best[0]:
                best = (start, x)
            start = None
    img = img.crop((best[0], 0, best[1], img.height))
    return img.crop(img.getbbox())


def runner():
    """Wytarty, ciemnoczerwony chodnik ze złotawym szlakiem: 28x64, bezszwowy w pionie."""
    img = Image.new("RGBA", (28, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 27, 63), fill=(74, 22, 24, 230))
    d.line((0, 0, 0, 63), fill=(40, 12, 14, 230))
    d.line((27, 0, 27, 63), fill=(40, 12, 14, 230))
    for x in (2, 25):
        d.line((x, 0, x, 63), fill=(150, 112, 52, 230))
    for y in range(0, 64, 16):
        # romb pośrodku co 16 px
        d.polygon([(14, y + 3), (19, y + 8), (14, y + 13), (9, y + 8)], outline=(132, 96, 46, 230))
        d.point((14, y + 8), fill=(160, 120, 60, 230))
    # przetarcia
    for x, y in ((6, 9), (20, 27), (11, 44), (17, 58), (5, 37)):
        d.point((x, y), fill=(98, 44, 40, 230))
        d.point((x + 1, y), fill=(98, 44, 40, 230))
    return img


def main():
    for climate, props in PROPS.items():
        out = os.path.join(ROOT, "assets", "dungeons", climate)
        os.makedirs(out, exist_ok=True)
        for name, (pack, frame, alpha) in props.items():
            img = Image.open(os.path.join(SRC, pack, "frame_%d.png" % frame)).convert("RGBA")
            img = main_part(img)
            if alpha < 1.0:
                a = img.getchannel("A").point(lambda v: int(v * alpha))
                img.putalpha(a)
            img.save(os.path.join(out, name + ".png"))
        runner().save(os.path.join(out, "runner.png"))
        print("%s: %d rekwizytów" % (climate, len(props) + 1))


if __name__ == "__main__":
    main()
