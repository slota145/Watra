"""Rekwizyty Rozlewisk i Wietrznych Turni z paczek obiektów PixelLab (pixellab_src/regions/<paczka>/frame_<i>.png,
pobrane przez pixellab_src/regions/fetch.py packs). Grafiki podmieniamy w miejscu dawnych plików
(assets/swamp, frogs, drowned, mountains), więc kod się nie zmienia: gra stawia je z punktem
zaczepienia u podstawy (offset liczony z wysokości tekstury). Każda klatka jest zmniejszana jak
postacie (hero_sheets.shrink_image), przycinana do sylwetki i wyśrodkowana poziomo.
Rekwizyty animowane w grze (np. kosz z ogniem) dostają pasek z kilku wariantów.
Uruchom: python tools/region_props.py"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "regions")
ASSETS = os.path.join(ROOT, "assets")

# plik w assets: (paczka, [klatki], skala) - kilka klatek = pasek animacji / wariantów (hframes w grze)
PROPS = {
    # Rozlewiska i wioska żaboludzi
    "swamp/mangrove_0.png": ("swamp_trees", [0], 0.75),
    "swamp/mangrove_1.png": ("swamp_trees", [1], 0.75),
    "swamp/mangrove_2.png": ("swamp_trees", [2], 0.75),
    "drowned/drowned_tree_0.png": ("swamp_trees", [3], 0.75),
    "drowned/drowned_tree_1.png": ("swamp_trees", [4], 0.75),
    "frogs/hut_tree_0.png": ("swamp_trees", [5], 1.0),
    "frogs/hut_tree_1.png": ("swamp_trees", [6], 1.0),
    "frogs/hut_tree_2.png": ("swamp_trees", [7], 1.0),
    "swamp/cattails.png": ("swamp_trees", [9, 9, 9], 0.4),
    "swamp/reeds.png": ("swamp_trees", [10, 10], 0.35),
    "drowned/rotten_stump.png": ("swamp_trees", [11], 0.4),
    "drowned/sunken_boat.png": ("swamp_trees", [12], 0.55),
    "drowned/sunken_cross.png": ("swamp_trees", [13], 0.45),
    "swamp/signpost.png": ("swamp_trees", [14], 0.45),
    "frogs/shell_throne.png": ("swamp_trees", [15], 0.7),
    "frogs/fish_rack.png": ("swamp_small", [0], 0.75),
    "frogs/fish_net.png": ("swamp_small", [1], 0.75),
    "frogs/frog_totem.png": ("swamp_small", [2], 0.75),
    "frogs/brazier.png": ("swamp_small", [3, 3], 0.6),
    "frogs/canoe.png": ("swamp_small", [4], 0.75),
    "frogs/clay_pots.png": ("swamp_small", [5], 0.55),
    "drowned/soul_jars.png": ("swamp_small", [6], 0.6),
    "swamp/lilies.png": ("swamp_small", [7, 8, 9], 0.45),
    # Wietrzne Turnie i wioska ptakoludzi
    "mountains/stilt_hut_0.png": ("mountain", [0], 1.0),
    "mountains/stilt_hut_1.png": ("mountain", [1], 1.0),
    "mountains/pillar_nest_0.png": ("mountain", [2], 1.0),
    "mountains/pillar_nest_1.png": ("mountain", [3], 1.0),
    "mountains/eagle_totem.png": ("mountain", [4], 0.75),
    "mountains/perch_pole.png": ("mountain", [5, 5], 0.75),
    "mountains/storm_rod.png": ("mountain", [6, 6], 0.75),
    "mountains/wind_chime.png": ("mountain", [7, 7], 0.6),
    "mountains/dead_tree_0.png": ("mountain", [9], 0.8),
    "mountains/dead_tree_1.png": ("mountain", [10], 0.8),
    "mountains/peak_0.png": ("mountain", [11], 1.15),
    "mountains/peak_1.png": ("mountain", [12], 1.15),
    "mountains/peak_2.png": ("mountain", [13], 1.15),
    "mountains/iron_ore_0.png": ("mountain", [14], 0.4),
    "mountains/iron_ore_1.png": ("mountain", [15], 0.4),
    "mountains/iron_ore_2.png": ("mountain", [14], 0.36),
    "mountains/aerie.png": ("mountain", [8], 1.0),
    "mountains/egg_nest.png": ("mountain_small", [0], 0.6),
    "mountains/bone_pile.png": ("mountain_small", [1], 0.6),
    "mountains/cairn.png": ("mountain_small", [2], 0.6),
}
# drobne ozdoby (paski klatek o stałej komórce): plik -> (paczka, klatki, komórka)
DECOR = {
    "mountains/decor.png": ("mountain_small", [3, 4, 5, 6, 7, 8, 9, 10], 20),
}


def _frame(pack, index, scale):
    src = Image.open(os.path.join(SRC, pack, "frame_%d.png" % index)).convert("RGBA")
    if scale != 1.0:
        src = hero_sheets.shrink_image(src, round(src.width * scale), round(src.height * scale))
    box = src.getbbox()
    cx = src.width / 2.0
    half = int(max(cx - box[0], box[2] - cx) + 0.999)
    left = int(cx) - half
    return src.crop((left, box[1], left + half * 2, box[3]))


def build(path, pack, frames, scale):
    imgs = [_frame(pack, i, scale) for i in frames]
    w = max(i.width for i in imgs)
    h = max(i.height for i in imgs)
    strip = Image.new("RGBA", (w * len(imgs), h))
    for k, img in enumerate(imgs):
        # podstawa przy dolnej krawędzi, poziomo pośrodku komórki
        strip.alpha_composite(img, (k * w + (w - img.width) // 2, h - img.height))
    strip.save(os.path.join(ASSETS, path))
    return strip.size


def decor(path, pack, frames, cell):
    strip = Image.new("RGBA", (cell * len(frames), cell))
    for k, index in enumerate(frames):
        src = Image.open(os.path.join(SRC, pack, "frame_%d.png" % index)).convert("RGBA")
        strip.alpha_composite(hero_sheets.shrink_image(src, cell, cell), (k * cell, 0))
    strip.save(os.path.join(ASSETS, path))
    return strip.size


def cliffs():
    """Klify gór z pasa skalnej ściany z PixelLab (pixellab_src/regions/cliffs/strip_b.png, 256x32, wzór
    powtarza się poziomo): ściana jako pas, z którego gra wycina kolumnę wg pozycji x (sąsiednie odcinki
    pasują do siebie), przyciemnione końce ścian, krawędzie płaskowyżów (pasy 256 px) i rampa ze schodami."""
    folder = os.path.join(SRC, "cliffs")
    if not os.path.exists(os.path.join(folder, "strip_b.png")):
        return
    from PIL import ImageEnhance
    strip = ImageEnhance.Brightness(Image.open(os.path.join(folder, "strip_b.png")).convert("RGBA")).enhance(0.95)
    out = os.path.join(ASSETS, "mountains")
    strip.save(os.path.join(out, "cliff_strip.png"))
    # przejścia klifów do otoczenia: piarg u podstawy, gzyms z trawą na górze (i obrócony - na bokach),
    # zaokrąglone skały na końcach ścian (warianty w pasku; to prawy koniec, lewy = odbicie)
    if os.path.exists(os.path.join(folder, "foot.png")):
        ImageEnhance.Brightness(Image.open(os.path.join(folder, "foot.png")).convert("RGBA")).enhance(0.9).save(os.path.join(out, "cliff_foot.png"))
        # górne zakończenie ściany: maska nawisu (białe - podłoże, szare - obrys, półprzezroczyste - cień na
        # ścianie) z nierównym dolnym brzegiem; gra wypełnia ją teksturą podłoża płaskowyżu (shaders/cliff_lip.gdshader).
        # Obrócona - na bokach i schodkach (przyczepiona z prawej). Nawis trawy to pas z PixelLab (alpine_tiles.py).
        white = Image.new("RGBA", (16, 16), (255, 255, 255, 255))
        lip = _overhang(white, seed=5)
        lip.save(os.path.join(out, "cliff_lip_mask.png"))
        lip.rotate(-90, expand=True).save(os.path.join(out, "cliff_lip_mask_side.png"))
        _overhang_corner(white).save(os.path.join(out, "cliff_lip_mask_corner.png"))
        ends = [ImageEnhance.Brightness(Image.open(os.path.join(folder, "ends", "frame_%d.png" % i)).convert("RGBA")).enhance(0.72)
                .crop((0, 6, 24, 40)) for i in (2, 20, 44, 52)]
        cap = Image.new("RGBA", (ends[0].width * len(ends), ends[0].height))
        for k, img in enumerate(ends):
            cap.alpha_composite(img, (k * img.width, 0))
        cap.save(os.path.join(out, "cliff_end.png"))
    ramp = Image.open(os.path.join(folder, "ramps.png")).convert("RGBA")
    ImageEnhance.Brightness(ramp).enhance(1.1).save(os.path.join(out, "ramp.png"))
    print("klify", strip.size)


def _overhang(tile, width=256, seed=1):
    """Nawis krawędzi płaskowyżu: kafelek podłoża powtórzony w pasie, z dolnym brzegiem błądzącym 3-9 px,
    ciemnym obrysem pod brzegiem i trzema rzędami cienia rzucanego na ścianę."""
    import random
    rng = random.Random(seed)
    ground = Image.new("RGBA", (width, 16))
    for x in range(0, width, 16):
        ground.paste(tile, (x, 0))
    lip = Image.new("RGBA", (width, 16))
    depth = 6
    for x in range(width):
        depth = max(3, min(9, depth + rng.choice((-1, 0, 0, 1))))
        if x > width - 6:  # koniec pasa łączy się z początkiem
            depth += (6 > depth) - (6 < depth)
        for y in range(depth):
            lip.putpixel((x, y), ground.getpixel((x, y)))
        r, g, b, _a = ground.getpixel((x, depth))
        lip.putpixel((x, depth), (int(r * 0.35), int(g * 0.35), int(b * 0.35), 255))
        for k, alpha in enumerate((110, 70, 35)):
            if depth + 1 + k < 16:
                lip.putpixel((x, depth + 1 + k), (10, 12, 16, alpha))
    return lip


def _overhang_corner(tile, seed=3):
    """Zaokrąglony róg nawisu (wypukły róg płaskowyżu): ćwiartka koła o poszarpanym promieniu 6-9 px,
    przyczepiona w prawym dolnym rogu kafelka, z obrysem i cieniem jak w pasie nawisu."""
    import math
    import random
    rng = random.Random(seed)
    radius = [rng.choice((6, 7, 7, 8, 8, 9)) for _ in range(8)]
    out = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            dx, dy = 15.5 - x, 15.5 - y
            d = math.hypot(dx, dy)
            r = radius[min(7, int(math.atan2(dy, dx) / (math.pi / 2) * 8))]
            if d < r:
                out.putpixel((x, y), tile.getpixel((x, y)))
            elif d < r + 1:
                cr, cg, cb, _a = tile.getpixel((x, y))
                out.putpixel((x, y), (int(cr * 0.35), int(cg * 0.35), int(cb * 0.35), 255))
            elif d < r + 4:
                out.putpixel((x, y), (10, 12, 16, (110, 70, 35)[int(d - r - 1)]))
    return out


def main():
    cliffs()
    for path, (pack, frames, scale) in PROPS.items():
        if all(os.path.exists(os.path.join(SRC, pack, "frame_%d.png" % i)) for i in frames):
            print(path, build(path, pack, frames, scale))
    for path, (pack, frames, cell) in DECOR.items():
        if all(os.path.exists(os.path.join(SRC, pack, "frame_%d.png" % i)) for i in frames):
            print(path, decor(path, pack, frames, cell))


if __name__ == "__main__":
    main()
