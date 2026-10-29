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
    "v2_cattails": ("bank", [0, 1, 8], 28),
    "v2_reeds": ("bank", [8, 1], 24),
    "v2_lilies": ("bank", [2, 3, 9], 16),
    "v2_rocks": ("bank", [4, 5], 20),
    "v2_log": ("bank", [6], 30),
    "v2_roots": ("bank", [7], 22),
    "v2_rail": ("bridge", [2], 24),
    "v2_post": ("bridge", [4], 16),
    "v2_abutment_l": ("bridge", [5], 40),
    "v2_abutment_r": ("bridge", [6], 40),
    "v2_pillar": ("bridge", [7], 18),
    "v2_lantern": ("bridge", [12], 30),
    "v2_fish_basket": ("bridge", [13], 14),
}
# tekstury desek (pełne 64x64, przycięte do zawartości i rozciągnięte z powrotem do 64 - bez przezroczystych brzegów)
TEXTURES = {"v2_walk_h": ("bridge", 8), "v2_walk_v": ("bridge", 9)}


def _load(pack, frame):
    path = os.path.join(SRC, pack, "frame_%d.png" % frame)
    return Image.open(path).convert("RGBA") if os.path.exists(path) else None


def strip(name, pack, frames, size):
    images = [_load(pack, f) for f in frames]
    if not all(images):
        return
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
