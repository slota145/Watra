"""Grafiki przeróbki Rozlewisk z PixelLab (pixellab_src/swamp_v2/<paczka>/frame_<i>.png - fetch.py):
rośliny i rekwizyty brzegu (paski klatek jak dawne cattails/reeds/lilies), deski mostu i kładek (tekstury
64 px kładzione w przestrzeni świata), poręcz, słup, przyczółki i pale w wodzie.
Wynik: assets/swamp/v2_<nazwa>.png. Uruchom: python tools/swamp_v2.py (albo na końcu generate_art.py)"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "swamp_v2")
OUT = os.path.join(ROOT, "assets", "swamp")

# nazwa: (paczka, [klatki], docelowy dłuższy bok najwyższej klatki) - kilka klatek = pasek wyrównany do dołu
STRIPS = {
    # bez klatki 1 - pałki na brązowej łacie błota wyglądały na wodzie jak wklejony kwadrat
    "v2_cattails": ("bank", [0, 8, 0], 36),
    "v2_reeds": ("bank", [8, 0], 30),
    "v2_lilies": ("bank", [2, 3, 9], 16),
    "v2_rocks": ("bank", [4, 5], 20),
    "v2_rail": ("bridge", [2], 24),
    "v2_post": ("bridge", [4], 16),
    "v2_pillar": ("bridge", [7], 18),
    "v2_lantern": ("bridge", [12], 30),
    "v2_fish_basket": ("bridge", [13], 14),
}
# tekstury desek (pełne 64x64, przycięte do zawartości i rozciągnięte z powrotem do 64 - bez przezroczystych brzegów)
TEXTURES = {"v2_walk_h": ("bridge", 8), "v2_walk_v": ("bridge", 9)}


def _load(pack, frame):
    path = os.path.join(SRC, pack, "frame_%d.png" % frame)
    return Image.open(path).convert("RGBA") if os.path.exists(path) else None


def _no_base(img):
    """Rośliny wodne bez szarej/błotnistej podstawy narysowanej pod nimi przez PixelLab (dolna piąta część
    grafiki: piksele mało nasycone albo ciemnobrązowe) - stoją wprost w wodzie gry."""
    import colorsys
    img = img.copy()
    box = img.getbbox()
    px = img.load()
    for y in range(box[3] - (box[3] - box[1]) // 5, box[3]):
        for x in range(box[0], box[2]):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, sat, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if sat < 0.25 or (0.03 < h < 0.14 and v < 0.45):
                px[x, y] = (0, 0, 0, 0)
    return img


def strip(name, pack, frames, size):
    images = [_load(pack, f) for f in frames]
    if not all(images):
        return
    if name in ("v2_cattails", "v2_reeds"):
        images = [_no_base(img) for img in images]
    largest = max(max(b[2] - b[0], b[3] - b[1]) for b in (img.getbbox() for img in images))
    scale = min(1.0, size / largest)
    cells = []
    for img in images:
        img = img.crop(img.getbbox())
        if scale < 1.0:
            img = hero_sheets.shrink_image(img, max(1, round(img.width * scale)), max(1, round(img.height * scale)))
        cells.append(img)
    w = max(c.width for c in cells)
    h = max(c.height for c in cells)
    sheet = Image.new("RGBA", (w * len(cells), h))
    for k, c in enumerate(cells):
        sheet.alpha_composite(c, (k * w + (w - c.width) // 2, h - c.height))
    sheet.save(os.path.join(OUT, name + ".png"))


def texture(name, pack, frame):
    img = _load(pack, frame)
    if img is None:
        return
    box = img.getbbox()
    # odcinamy obwódkę klatki (2 px), żeby deski stykały się bez ciemnych szwów
    img = img.crop((box[0] + 2, box[1] + 2, box[2] - 2, box[3] - 2)).resize((64, 64), Image.NEAREST)
    img.save(os.path.join(OUT, name + ".png"))


def main():
    for name, (pack, frames, size) in STRIPS.items():
        strip(name, pack, frames, size)
    # pokład mostu: odcinek na całą szerokość mostu (3 kafelki = 48 px)
    deck = _load("bridge", 0)
    if deck is not None:
        box = deck.getbbox()
        deck = deck.crop((box[0] + 2, box[1] + 2, box[2] - 2, box[3] - 2))
        hero_sheets.shrink_image(deck, 48, 48).save(os.path.join(OUT, "v2_deck48.png"))
    for name, (pack, frame) in TEXTURES.items():
        texture(name, pack, frame)
    print("rozlewiska v2:", sorted(f for f in os.listdir(OUT) if f.startswith("v2_") and f.endswith(".png")))


if __name__ == "__main__":
    main()
