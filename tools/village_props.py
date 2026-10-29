"""Rekwizyty osady z PixelLab (pixellab_src/village/<paczka>/frame_<i>.png, props/<nazwa>.png - pobrane przez
pixellab_src/village/fetch.py packs props). Grafiki podmieniamy w miejscu dawnych plików assets/village/<nazwa>.png,
więc kod osady się nie zmienia: Settlement._prop stawia je z punktem zaczepienia u podstawy.

Rozmiar: osada urosła razem z postaciami, więc każdy rekwizyt dostaje ok. 1,35 dawnego rozmiaru (dłuższy bok),
ale nigdy nie jest powiększany ponad grafikę z PixelLab. Kilka klatek = pasek (etapy stosów, animacje),
wszystkie w tej samej skali, wyrównane do podstawy.
Uruchom: python tools/village_props.py (albo na końcu generate_art.py)"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "village")
OUT = os.path.join(ROOT, "assets", "village")
GROWTH = 1.35

# nazwa: (paczka, [klatki], dawny dłuższy bok jednej klatki) - "props" = pojedyncze duże obiekty (klatka = nazwa)
PROPS = {
    # meble z paczek 96 px (furniture2-5): w paczce "furniture" (klatki 64 px) wiele wychodziło poza swoją klatkę -
    # były ucięte, a sąsiednie klatki łapały ich kawałki (paski przy krawędzi)
    "counter": ("furniture2", [0], 40), "barrel": ("furniture3", [0], 15), "table": ("furniture3", [1], 26),
    "stool": ("furniture3", [2], 10), "bed": ("furniture2", [2], 26), "chest": ("furniture3", [3], 16),
    "shelf": ("furniture4", [0], 32), "crate": ("furniture4", [1], 14), "forge": ("furniture4", [2], 26),
    "weapon_rack": ("furniture4", [3], 24), "anvil": ("furniture5", [0], 18), "bookshelf_0": ("furniture", [11], 30),
    "bookshelf_1": ("furniture", [12], 30), "lectern": ("furniture", [13, 13], 26), "map_table": ("furniture5", [1], 34),
    "trophy": ("furniture5", [2], 18),
    "well": ("yard", [0], 28), "hay": ("yard", [1], 22), "cart": ("yard", [2], 48), "garden": ("yard", [3], 40),
    "herb_garden": ("yard", [4], 36), "notice_board": ("yard", [5], 40), "banner": ("yard", [6], 34),
    "banner_pole": ("yard", [7, 7], 40), "torch_stand": ("yard", [8, 8], 26), "archery_target": ("yard", [9], 26),
    "dummy": ("yard", [10], 30), "butcher_rack": ("yard", [11, 12], 34), "smokehouse": ("yard", [13], 32),
    "hide_rack": ("yard", [14], 28), "owl_perch": ("yard", [15, 15], 28),
    "wood_pile": ("small", [0, 1, 2, 3], 36), "stone_pile": ("small", [4, 5, 6, 7], 36),
    "plank_pile": ("small", [8, 9, 10, 11], 26), "sack": ("small", [12], 13), "hearth": ("small", [13, 13], 28),
    "cauldron": ("small", [14, 14], 26), "rune_stone": ("small", [15], 18),
    "mug": ("tiny", [0], 8), "quiver": ("tiny", [1], 16), "shield": ("tiny", [2], 16), "mail_bundle": ("tiny", [3], 14),
    "arms_bundle": ("furniture5", [3], 22), "pelt": ("tiny", [5], 20), "plank": ("tiny", [6], 24), "telescope": ("tiny", [7], 26),
    "bench": ("tiny", [8], 30),
    "stable": ("props", ["stable"], 80), "awning": ("props", ["awning"], 56),
}
# animacje z PixelLab zamiast powtórzonej klatki: nazwa -> (folder obiektu, klatki animacji, dawny bok)
ANIMATED = {"horse": ("horse", [0, 2], 34), "hearth": ("hearth", [0, 2], 28), "cauldron": ("cauldron", [0, 2], 26),
            "torch_stand": ("torch_stand", [0, 2], 26)}
# ozdoby osady (Settlement._build_decorations): nazwa -> (paczka, klatka, docelowy dłuższy bok)
DECOR = {
    "deco_lamp_post": ("decor", 0, 40), "deco_flower_box": ("decor", 1, 26), "deco_fence": ("decor", 2, 28),
    "deco_market_stall": ("decor", 3, 48), "deco_scarecrow": ("decor", 4, 34), "deco_beehive": ("decor", 5, 22),
    "deco_rain_barrel": ("decor", 6, 26), "deco_washing_line": ("decor", 7, 44), "deco_kennel": ("decor", 8, 28),
    "deco_chickens": ("decor", 9, 24), "deco_cat": ("decor", 10, 18), "deco_wood_shelter": ("decor", 11, 36),
    "deco_signpost": ("decor", 12, 32), "deco_flower_bed": ("decor", 13, 32), "deco_stone_bench": ("decor", 14, 26),
    "deco_wheelbarrow": ("decor", 15, 26), "deco_flower_pot": ("tiny", 10, 12), "deco_basket": ("tiny", 11, 14),
    "deco_lantern": ("tiny", 12, 12), "deco_bucket": ("tiny", 13, 12), "deco_axe_stump": ("tiny", 18, 16),
    "deco_tools": ("tiny", 63, 16),
}


# meble, przy których kandydat z PixelLab złapał okruch sąsiedniej klatki (pasek przy lewej krawędzi)
CLEAN = {"barrel", "stool", "chest", "anvil", "crate", "table"}


def _main_part(img):
    """Tylko główny kształt: największa spójna bryła i części leżące przy niej (okruchy sąsiednich klatek
    siatki PixelLab - np. pionowy pasek przy krawędzi - znikają)."""
    alpha = img.getchannel("A").load()
    w, h = img.size
    seen = set()
    parts = []
    for y in range(h):
        for x in range(w):
            if alpha[x, y] == 0 or (x, y) in seen:
                continue
            stack, pixels = [(x, y)], []
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                pixels.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1),
                               (cx + 1, cy + 1), (cx - 1, cy - 1), (cx + 1, cy - 1), (cx - 1, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h and alpha[nx, ny] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            parts.append(pixels)
    main = max(parts, key=len)
    left, top = min(p[0] for p in main) - 3, min(p[1] for p in main) - 3
    right, bottom = max(p[0] for p in main) + 3, max(p[1] for p in main) + 3
    out = Image.new("RGBA", img.size)
    src, dst = img.load(), out.load()
    for pixels in parts:
        # zostają części stykające się z obrysem głównej bryły (np. kufle na ladzie), okruchy przy krawędzi klatki nie
        if any(left <= x <= right and top <= y <= bottom for x, y in pixels):
            for px in pixels:
                dst[px] = src[px]
    return out


def _load(pack, frame):
    if pack == "props":
        path = os.path.join(SRC, "props", "%s.png" % frame)
    else:
        path = os.path.join(SRC, pack, "frame_%d.png" % frame)
    return Image.open(path).convert("RGBA") if os.path.exists(path) else None


def _anim_frames(folder):
    anims = os.path.join(SRC, folder, "animations")
    if not os.path.isdir(anims):
        return []
    sub = os.path.join(anims, sorted(os.listdir(anims))[0], "unknown")
    return [Image.open(os.path.join(sub, f)).convert("RGBA") for f in sorted(os.listdir(sub))]


def build(name, images, old_size):
    """Pasek klatek: wspólna skala (z największej klatki - np. pełnego stosu), przycięcie, wyrównanie do podstawy."""
    if name in CLEAN:
        images = [_main_part(img) for img in images]
    largest = max(max(b[2] - b[0], b[3] - b[1]) for b in (img.getbbox() for img in images))
    scale = min(1.0, GROWTH * old_size / largest)
    cells = []
    for img in images:
        if scale < 1.0:
            img = hero_sheets.shrink_image(img, max(1, round(img.width * scale)), max(1, round(img.height * scale)))
        cells.append(img.crop(img.getbbox()))
    w = max(c.width for c in cells)
    h = max(c.height for c in cells)
    strip = Image.new("RGBA", (w * len(cells), h))
    for k, c in enumerate(cells):
        strip.alpha_composite(c, (k * w + (w - c.width) // 2, h - c.height))
    strip.save(os.path.join(OUT, name + ".png"))
    return strip.size


def palisade():
    """Palisada jako pasy powtarzającego się wzoru pali (gra wycina 16-pikselowe kolumny wg pozycji):
    w naprawie - pas z PixelLab z wyłamanymi palami; cała - nienaruszony fragment tego pasu (10 pali)
    powtórzony trzy razy, żeby obie wersje miały ten sam styl."""
    path = os.path.join(SRC, "props", "palisade_broken.png")
    if not os.path.exists(path):
        return
    broken = Image.open(path).convert("RGBA")
    broken.save(os.path.join(OUT, "palisade_broken.png"))
    segment = broken.crop((101, 0, 173, broken.height))
    whole = Image.new("RGBA", (segment.width * 3, broken.height))
    for k in range(3):
        whole.alpha_composite(segment, (k * segment.width, 0))
    whole.save(os.path.join(OUT, "palisade.png"))
    print("palisade", whole.size)


def main():
    palisade()
    for name, (pack, frames, old) in PROPS.items():
        images = [_load(pack, f) for f in frames]
        if all(images):
            print(name, build(name, images, old))
    for name, (pack, frame, size) in DECOR.items():
        image = _load(pack, frame)
        if image:
            print(name, build(name, [image], size / GROWTH))
    for name, (folder, frames, old) in ANIMATED.items():
        anim = _anim_frames(folder)
        if len(anim) > max(frames):
            print(name, build(name, [anim[i] for i in frames], old))


if __name__ == "__main__":
    main()
