"""Budynki osady z PixelLab: dach z fasadą (obiekt mapy z pixellab_src/village/buildings/<nazwa>.png,
pobrany przez pixellab_src/village/fetch.py) i dopasowana do niego podłoga z wnętrzem.

Duże płótna PixelLab mają jednolite tło zamiast przezroczystego - usuwamy je wypełnieniem od brzegów.
Grafika jest przycinana do sylwetki i staje się dachem (assets/village/<nazwa>_roof.png); podłogę
rysuje village_art.make_building (a dla chaty mędrca i gildii landmark_art) w tym samym rozmiarze.
Uruchom: python tools/village_buildings.py (albo na końcu generate_art.py)"""
import os
from collections import deque

from PIL import Image

import hero_sheets
import landmark_art
import village_art

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "village", "buildings")
OUT = os.path.join(ROOT, "assets", "village")


def remove_flat_background(img, tolerance=24):
    """Jeśli narożniki mają ten sam nieprzezroczysty kolor - zalewamy go od brzegów przezroczystością."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    corner = px[0, 0]
    if corner[3] == 0:
        return img
    def close(c):
        return c[3] > 0 and sum(abs(c[i] - corner[i]) for i in range(3)) <= tolerance
    seen = set()
    queue = deque([(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)])
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        if not close(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return img


def roof(name):
    img = remove_flat_background(Image.open(os.path.join(SRC, name + ".png")))
    return img.crop(img.getbbox())


def wagon(folder="wagon", out_name="wagon.png"):
    """Wóz kupiecki z koniem: 4 klatki animacji obiektu z PixelLab (pixellab_src/village/<folder>/),
    zmniejszone jak postacie i przycięte do wspólnej sylwetki - pasek assets/village/<out_name>.
    Dwa warianty: jazda po skosie w dół (wagon) i w górę (wagon_up)."""
    anims = os.path.join(ROOT, "pixellab_src", "village", folder, "animations")
    if not os.path.isdir(anims):
        return
    folder = os.path.join(anims, os.listdir(anims)[0], "unknown")
    frames = [Image.open(os.path.join(folder, f)).convert("RGBA") for f in sorted(os.listdir(folder))]
    size = round(frames[0].width * hero_sheets.SCALE)
    small = [hero_sheets.shrink_image(img, size, size) for img in frames]
    box = small[0].getbbox()
    for img in small[1:]:
        b = img.getbbox()
        box = (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    w, h = box[2] - box[0], box[3] - box[1]
    strip = Image.new("RGBA", (w * len(small), h))
    for i, img in enumerate(small):
        strip.alpha_composite(img.crop(box), (i * w, 0))
    strip.save(os.path.join(OUT, out_name))
    print(out_name, strip.size)


def main():
    wagon()
    wagon("wagon_up", "wagon_up.png")
    if not os.path.isdir(SRC):
        return
    roofs = {}
    for f in sorted(os.listdir(SRC)):
        if f.endswith(".png"):
            name = f[:-4]
            roofs[name] = roof(name)
            village_art.SIZE_OVERRIDE[name] = roofs[name].size
    # podłogi w rozmiarze dachów (make_building rysuje też stary dach - zaraz go podmieniamy)
    for b in village_art.BUILDINGS:
        if b[0] in roofs:
            village_art.make_building(*b)
    if "sage_hut" in roofs:
        landmark_art.sage_hut()
    if "guild" in roofs:
        landmark_art.guild()
    for name, img in roofs.items():
        img.save(os.path.join(OUT, name + "_roof.png"))
        print(name, img.size)


if __name__ == "__main__":
    main()
