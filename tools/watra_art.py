"""Watra - wielki ogień na placu Ostoi, z PixelLab (pixellab_src/village/watra/frame_0..7.png: obiekt z animacją
płonięcia, przezroczyste tło). Późniejsze klatki animacji PixelLab dorysowały przy kamieniach znicze, więc bierzemy
pierwsze klatki (0-3), dół obrazka (kamienie i ziemia pod ogniem, gdzie pojawiły się znicze) bierzemy zawsze
z klatki 0 i odtwarzamy je tam i z powrotem (0,1,2,3,2,1) - płomień zapętla się płynnie.
Klatki zmniejszamy jak postacie (hero_sheets.shrink_image).
Wynik: assets/village/watra.png (6 klatek w rzędzie).
Uruchom: python tools/watra_art.py"""
import os

from PIL import Image

import hero_sheets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "village", "watra")
OUT = os.path.join(ROOT, "assets", "village", "watra.png")
CELL = 104
ORDER = [0, 1, 2, 3, 2, 1]
## Od tego wiersza (w klatce 128 px) w dół obrazek jest zawsze z klatki 0.
BOTTOM = 97


def main():
    raw = [Image.open(os.path.join(SRC, "frame_%d.png" % i)).convert("RGBA") for i in range(4)]
    base = raw[0]
    for f in raw[1:]:
        bottom = base.crop((0, BOTTOM, base.width, base.height))
        f.paste(bottom, (0, BOTTOM))
    frames = [raw[i] for i in ORDER]
    sheet = Image.new("RGBA", (CELL * len(frames), CELL))
    for k, f in enumerate(frames):
        sheet.alpha_composite(hero_sheets.shrink_image(f, CELL, CELL), (k * CELL, 0))
    sheet.save(OUT)
    print("watra", sheet.size)


if __name__ == "__main__":
    main()
