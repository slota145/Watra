"""Rekwizyty lochów Watry z paczek kandydatów PixelLab (create_1_direction_object, 64 px, top-down).
Surowe klatki leżą w pixellab_src/dungeons/<paczka>/frame_<i>.png (pobiera je pixellab_src/dungeons/fetch.py).
Narzędzie przycina każdą klatkę do zawartości, nakładkom na podłogę zmniejsza krycie (wtapiają się w kafelki)
i zapisuje wynik do assets/dungeons/<klimat>/<nazwa>.png. Pasy, które gra powtarza wzdłuż komnaty, rysuje samo
(bezszwowe w pionie): chodnik Katakumb (runner), tory i kładkę z desek Kopalni (rails, walkway),
mokrą kładkę i płytkie rozlewiska Zatopionych podziemi (planks, pool, pool_small).
Gdy pobieranie z PixelLab jest zablokowane, klatki paczki to podglądy kandydatów z get_object (64x64, przezroczyste).
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
    "mine": {
        # nakładki na podłogę
        "crack": ("mine_small", 0, 0.55),
        "ore_bits": ("mine_small", 1, 0.95),
        "rubble": ("mine_small", 2, 0.9),
        "puddle": ("mine_small", 3, 0.6),
        "powder": ("mine_small", 4, 0.7),
        "pick": ("mine_small", 5, 1.0),
        "planks": ("mine_small", 6, 0.95),
        "hatch": ("mine_small", 7, 0.95),
        # na licu ściany
        "lantern": ("mine_small", 8, 1.0),
        "vein": ("mine_small", 9, 1.0),
        "banner": ("mine_small", 10, 1.0),
        "scrawl": ("mine_small", 11, 0.85),
        # drobiazgi
        "nuggets": ("mine_small", 12, 1.0),
        "bucket": ("mine_small", 13, 1.0),
        "picks": ("mine_small", 14, 1.0),
        "skull_stick": ("mine_small", 15, 1.0),
        # duże, z kolizją
        "support": ("mine_tall", 0, 1.0),
        "pillar": ("mine_tall", 1, 1.0),
        "broken_beams": ("mine_tall", 2, 1.0),
        "cart": ("mine_tall", 3, 1.0),
        "cart_tipped": ("mine_tall", 4, 1.0),
        "boulders": ("mine_tall", 5, 1.0),
        "forge": ("mine_tall", 6, 1.0),
        "anvil": ("mine_tall", 7, 1.0),
        "powder_stack": ("mine_tall", 8, 1.0),
        "lift": ("mine_tall", 9, 1.0),
        "windlass": ("mine_tall", 10, 1.0),
        "crystal": ("mine_tall", 11, 1.0),
        "campfire": ("mine_tall", 12, 1.0),
        "throne": ("mine_tall", 13, 1.0),
        "treasure": ("mine_tall", 14, 1.0),
        "ore_heap": ("mine_tall", 15, 1.0),
        # meble pod ściany
        "powder_barrels": ("mine_furniture", 0, 1.0),
        "bomb_crate": ("mine_furniture", 1, 1.0),
        "weapon_rack": ("mine_furniture", 2, 1.0),
        "tool_rack": ("mine_furniture", 3, 1.0),
        "bedroll": ("mine_furniture", 4, 1.0),
        "ore_sacks": ("mine_furniture", 5, 1.0),
        "bellows": ("mine_furniture", 6, 1.0),
        "trough": ("mine_furniture", 7, 1.0),
        "ingot_shelf": ("mine_furniture", 8, 1.0),
        "ladder": ("mine_furniture", 9, 1.0),
        "totem": ("mine_furniture", 10, 1.0),
        "banner_pole": ("mine_furniture", 11, 1.0),
        "lumber": ("mine_furniture", 12, 1.0),
        "chain_post": ("mine_furniture", 13, 1.0),
        "rope": ("mine_furniture", 14, 1.0),
        "warning_sign": ("mine_furniture", 15, 1.0),
    },
    "flooded": {
        # nakładki na podłogę
        "crack": ("flooded_small", 0, 0.55),
        "puddle": ("flooded_small", 1, 0.7),
        "lilies": ("flooded_small", 2, 0.95),
        "algae": ("flooded_small", 3, 0.7),
        "mud": ("flooded_small", 4, 0.6),
        "fish_bones": ("flooded_small", 5, 0.9),
        "mosaic": ("flooded_small", 6, 0.7),
        "grate": ("flooded_small", 7, 0.9),
        # na licu ściany
        "sconce": ("flooded_small", 8, 1.0),
        "moss_drape": ("flooded_small", 9, 1.0),
        "wave_plaque": ("flooded_small", 10, 1.0),
        "net": ("flooded_small", 11, 1.0),
        # drobiazgi
        "shells": ("flooded_small", 12, 1.0),
        "wreath": ("flooded_small", 13, 1.0),
        "jug": ("flooded_small", 14, 1.0),
        "candles": ("flooded_small", 15, 1.0),
        # duże, z kolizją
        "pillar": ("flooded_tall", 0, 1.0),
        "pillar_stump": ("flooded_tall", 1, 1.0),
        "pillar_fallen": ("flooded_tall", 2, 1.0),
        "statue": ("flooded_tall", 3, 1.0),
        "altar": ("flooded_tall", 4, 1.0),
        "basin": ("flooded_tall", 5, 1.0),
        "wreck": ("flooded_tall", 6, 1.0),
        "rowboat": ("flooded_tall", 7, 1.0),
        "mast": ("flooded_tall", 8, 1.0),
        "nest": ("flooded_tall", 9, 1.0),
        "treasure": ("flooded_tall", 10, 1.0),
        "mushrooms": ("flooded_tall", 11, 1.0),
        "totem": ("flooded_tall", 12, 1.0),
        "drying_rack": ("flooded_tall", 13, 1.0),
        "spring": ("flooded_tall", 14, 1.0),
        "throne": ("flooded_tall", 15, 1.0),
        # meble pod ściany
        "amphorae": ("flooded_furniture", 0, 1.0),
        "shelf": ("flooded_furniture", 1, 1.0),
        "oars": ("flooded_furniture", 2, 1.0),
        "anchor": ("flooded_furniture", 3, 1.0),
        "barrels": ("flooded_furniture", 4, 1.0),
        "crates": ("flooded_furniture", 5, 1.0),
        "bench": ("flooded_furniture", 6, 1.0),
        "roots": ("flooded_furniture", 7, 1.0),
        "reeds": ("flooded_furniture", 8, 1.0),
        "shrine": ("flooded_furniture", 9, 1.0),
        "fish_baskets": ("flooded_furniture", 10, 1.0),
        "mirror_pool": ("flooded_furniture", 11, 1.0),
        "birch": ("flooded_furniture", 12, 1.0),
        "wisp_post": ("flooded_furniture", 13, 1.0),
        "stakes": ("flooded_furniture", 14, 1.0),
        "driftwood": ("flooded_furniture", 15, 1.0),
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


def rails():
    """Tory kopalniane: dwie żelazne szyny na drewnianych podkładach co 16 px, 40x64, bezszwowe w pionie."""
    img = Image.new("RGBA", (40, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for y in range(4, 64, 16):
        # podkład z cieniem i słojami
        d.rectangle((1, y, 38, y + 6), fill=(92, 62, 38, 240))
        d.line((1, y + 6, 38, y + 6), fill=(52, 34, 22, 240))
        d.line((1, y, 38, y), fill=(122, 86, 54, 240))
        d.point((8, y + 3), fill=(66, 44, 28, 240))
        d.point((27, y + 2), fill=(66, 44, 28, 240))
    for x in (8, 29):
        d.rectangle((x, 0, x + 3, 63), fill=(70, 66, 64, 250))
        d.line((x + 1, 0, x + 1, 63), fill=(150, 144, 136, 250))
        d.line((x + 3, 0, x + 3, 63), fill=(40, 36, 36, 250))
        for y in range(4, 64, 16):
            # gwoździe przy szynach
            d.point((x - 1, y + 3), fill=(30, 28, 28, 250))
            d.point((x + 4, y + 3), fill=(30, 28, 28, 250))
    return img


def walkway():
    """Kładka z poprzecznych desek, 36x64, bezszwowa w pionie."""
    img = Image.new("RGBA", (36, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    tones = [(104, 72, 44), (96, 66, 40), (112, 80, 48), (100, 70, 42)]
    for i, y in enumerate(range(0, 64, 8)):
        c = tones[i % len(tones)]
        d.rectangle((0, y, 35, y + 6), fill=c + (235,))
        d.line((0, y, 35, y), fill=(136, 100, 62, 235))
        d.line((0, y + 7, 35, y + 7), fill=(40, 26, 16, 235))
        for x in (3, 32):
            d.point((x, y + 3), fill=(46, 40, 38, 235))
        d.line((10 + (i * 7) % 14, y + 3, 15 + (i * 7) % 14, y + 3), fill=(80, 54, 32, 235))
    return img


def wet_planks():
    """Kładka z omszałych, mokrych desek na dwóch belkach, 34x64, bezszwowa w pionie."""
    img = Image.new("RGBA", (34, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    tones = [(78, 66, 48), (70, 60, 44), (84, 72, 52), (74, 64, 46)]
    for x in (4, 27):
        d.rectangle((x, 0, x + 2, 63), fill=(40, 34, 26, 230))
    for i, y in enumerate(range(0, 64, 8)):
        c = tones[i % len(tones)]
        d.rectangle((0, y, 33, y + 5), fill=c + (235,))
        d.line((0, y, 33, y), fill=(112, 104, 78, 235))
        d.line((0, y + 6, 33, y + 6), fill=(30, 28, 22, 220))
        # mech na końcach desek
        d.line((0, y + 1, 2 + i % 3, y + 1), fill=(62, 96, 56, 235))
        d.line((31 - i % 2, y + 4, 33, y + 4), fill=(62, 96, 56, 235))
        d.line((9 + (i * 7) % 14, y + 3, 14 + (i * 7) % 14, y + 3), fill=(56, 48, 34, 235))
    return img


def pool(w, h, seed):
    """Płytkie rozlewisko (nakładka na podłogę): nieregularna plama ciemnej, przejrzystej wody z jaśniejszym
    brzegiem i odblaskami; da się po niej chodzić."""
    import random
    rnd = random.Random(seed)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((w * 0.12, h * 0.16, w * 0.88, h * 0.84), fill=255)
    for _ in range(9):
        cx, cy = rnd.uniform(0.2, 0.8) * w, rnd.uniform(0.25, 0.75) * h
        rx, ry = rnd.uniform(0.12, 0.22) * w, rnd.uniform(0.14, 0.24) * h
        md.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px, mp = img.load(), mask.load()
    inside = lambda x, y: 0 <= x < w and 0 <= y < h and mp[x, y]
    for y in range(h):
        for x in range(w):
            if not mp[x, y]:
                continue
            edge = next((r for r in range(1, 4) if not all(inside(x + a, y + b) for a, b in
                    ((r, 0), (-r, 0), (0, r), (0, -r)))), 4)
            if edge == 1:
                px[x, y] = (122, 168, 150, 170)
            elif edge <= 3:
                px[x, y] = (46, 98, 100, 150)
            else:
                px[x, y] = (24, 64, 74, 165)
    d = ImageDraw.Draw(img)
    for _ in range(max(3, w * h // 1800)):
        x, y = rnd.randrange(w // 4, w * 3 // 4), rnd.randrange(h // 4, h * 3 // 4)
        if mp[x, y] and mp[min(w - 1, x + 6), y]:
            d.line((x, y, x + rnd.randint(3, 6), y), fill=(150, 206, 196, 180))
    return img


STRIPS = {"catacombs": {"runner": runner}, "mine": {"rails": rails, "walkway": walkway},
        "flooded": {"planks": wet_planks, "pool": lambda: pool(176, 112, 3), "pool_small": lambda: pool(104, 68, 5)}}


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
        for name, make in STRIPS.get(climate, {}).items():
            make().save(os.path.join(out, name + ".png"))
        print("%s: %d rekwizytów" % (climate, len(props) + len(STRIPS.get(climate, {}))))


if __name__ == "__main__":
    main()
