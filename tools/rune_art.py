"""Ikony run do warsztatu kowala (scripts/item_craft.gd) z PixelLab (create_1_direction_object; identyfikator
w pixellab_src/runes/ids.json). Arkusz pixellab_src/runes/runes.png (4 ikony 64x64, złożone przez pixelart_workbench join):
Runa Zmiany (pierwsza), Runa Pieczęci (druga), fioletowy kryształ (trzecia) i okrągła runa z brązu (czwarta).
Ciemne tło znika wypełnianiem od krawędzi klatki (herb_art.cells).
Pozostałe runy to przebarwienia tych czterech (obrót barwy w HSV, bez nowych generacji):
- Runa Przekucia - runa z brązu,
- Runa Szlifu - runa z brązu przebarwiona na srebrnobłękitną,
- Runa Zatarcia - fioletowy kryształ,
- Runa Przydania - kryształ przebarwiony na zielony,
- Runa Wyniesienia - Runa Zmiany pozłocona (barwa wg jasności, gild).
Wynik: assets/items/rune_*.png.
Uruchom: python tools/rune_art.py"""
import os
import sys

from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from herb_art import cells  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def recolor(icon, hue_shift, saturation=1.0, value=1.0):
    """Obrót barwy (0-255 to pełne koło) i mnożniki nasycenia i jasności; przezroczystość bez zmian."""
    alpha = icon.getchannel("A")
    h, s, v = icon.convert("RGB").convert("HSV").split()
    h = h.point(lambda x: (x + hue_shift) % 256)
    s = s.point(lambda x: min(255, int(x * saturation)))
    v = v.point(lambda x: min(255, int(x * value)))
    out = Image.merge("HSV", (h, s, v)).convert("RGB").convert("RGBA")
    out.putalpha(alpha)
    return out


def gild(icon, dark=(40, 22, 8), mid=(214, 150, 40), light=(255, 240, 190)):
    """Przebarwienie wg jasności (od ciemnego brązu przez złoto do jasnej żółci) - kamień wielobarwny robi się złoty."""
    alpha = icon.getchannel("A")
    out = ImageOps.colorize(ImageOps.autocontrast(icon.convert("L")), dark, light, mid).convert("RGBA")
    out.putalpha(alpha)
    return out


def main():
    icons = list(cells(Image.open(os.path.join(ROOT, "pixellab_src", "runes", "runes.png")), 4, 4))
    out = {
        "rune_chaos": icons[0],
        "rune_seal": icons[1],
        "rune_erase": icons[2],
        "rune_reforge": icons[3],
        "rune_polish": recolor(icons[3], 120, 0.45, 1.1),
        "rune_growth": recolor(icons[2], 165, 1.0, 1.05),
        "rune_ascend": gild(icons[0]),
    }
    for name, image in out.items():
        image.save(os.path.join(ROOT, "assets", "items", name + ".png"))
    print("runy:", ", ".join(out))


if __name__ == "__main__":
    main()
