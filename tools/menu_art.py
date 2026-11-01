"""Grafiki menu głównego i kursor z PixelLab (pixellab_src/menu/): tło ze świtem nad osadą (640x360 - rozmiar
ekranu gry), drewniana tablica (dziś nieużywana), płonący napis "WATRA" (logo.png - kandydat 4 z create_image_pro, migotanie
płomieni robi shaders/logo_flames.gdshader) i kursor (wybrany kandydat z paczki 64)
w dwóch wersjach: zwykły i nad przyciskiem (rozżarzony kamień). Plik hotspot: czubek strzałki.
Wynik: assets/menu/*.png. Uruchom: python tools/menu_art.py (albo na końcu generate_art.py)"""
import colorsys
import os
import shutil

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "menu")
OUT = os.path.join(ROOT, "assets", "menu")
CURSOR = 9


def _hot(img):
    """Kursor nad przyciskiem: pomarańczowy żar jaśnieje, złote obrzeże lekko się rozświetla."""
    img = img.copy()
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.0 <= h < 0.17 and s > 0.4 and v > 0.4:
                r, g, b = (min(255, int(c * 1.35 + 30)) for c in (r, g, b))
                px[x, y] = (r, g, b, a)
    return img


def main():
    if not os.path.isdir(SRC):
        return
    os.makedirs(OUT, exist_ok=True)
    shutil.copy(os.path.join(SRC, "background.png"), os.path.join(OUT, "background.png"))
    plaque = Image.open(os.path.join(SRC, "plaque.png")).convert("RGBA")
    plaque.crop(plaque.getbbox()).save(os.path.join(OUT, "plaque.png"))
    logo = Image.open(os.path.join(SRC, "logo_watra.png")).convert("RGBA")
    logo.crop(logo.getbbox()).save(os.path.join(OUT, "logo.png"))
    cursor = Image.open(os.path.join(SRC, "cursors", "%d.png" % CURSOR)).convert("RGBA")
    box = cursor.getbbox()
    # strzałka od lewego górnego rogu płótna (hotspot w 1,1 - czubek z obrysem)
    cursor = cursor.crop((box[0] - 1, box[1] - 1, box[2] + 1, box[3] + 1))
    cursor.save(os.path.join(OUT, "cursor.png"))
    _hot(cursor).save(os.path.join(OUT, "cursor_hover.png"))
    print("menu:", sorted(os.listdir(OUT)))


if __name__ == "__main__":
    main()
