"""Animowane efekty umiejętności z kreatora efektów PixelLab (vfx_workbench; identyfikatory efektów, rozmiar klatki,
liczba klatek i punkt zaczepienia w pixellab_src/vfx/ids.json). Arkusze klatek złożone przez pixelart_workbench join
(jeden rząd klatek, a przy dużych klatkach - siatka "columns" kolumn, bo narzędzie składa najwyżej 1024 px na bok)
leżą w pixellab_src/vfx/<nazwa>.png bez paska podpisu, ale z ciemnym tłem (31, 37, 44).
Tło znika (kolor tła nie występuje w efektach, więc znika w całej klatce, także w szczelinach między iskrami).
Wynik: assets/effects/<nazwa>.png - zawsze jeden rząd klatek. Uruchom: python tools/vfx_art.py"""
import json
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "vfx")
BACKGROUND = (31, 37, 44)


def clear(sheet):
    px = sheet.load()
    for y in range(sheet.height):
        for x in range(sheet.width):
            r, g, b, _a = px[x, y]
            if abs(r - BACKGROUND[0]) + abs(g - BACKGROUND[1]) + abs(b - BACKGROUND[2]) <= 6:
                px[x, y] = (0, 0, 0, 0)
    return sheet


def main():
    out = os.path.join(ROOT, "assets", "effects")
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(SRC, "ids.json"), encoding="utf-8") as f:
        effects = json.load(f)
    for name, info in effects.items():
        sheet = clear(Image.open(os.path.join(SRC, name + ".png")).convert("RGBA"))
        w, h = info["frame"]
        columns = info.get("columns", info["frames"])
        if columns < info["frames"]:
            row = Image.new("RGBA", (w * info["frames"], h))
            for i in range(info["frames"]):
                x, y = (i % columns) * w, (i // columns) * h
                row.alpha_composite(sheet.crop((x, y, x + w, y + h)), (i * w, 0))
            sheet = row
        assert sheet.size == (w * info["frames"], h), (name, sheet.size)
        sheet.save(os.path.join(out, name + ".png"))
        print(name, sheet.size)


if __name__ == "__main__":
    main()
