"""Broń w ręku dla legendarnych broni (scripts/legends.gd): zamiast grafiki broni bazowej legenda trzyma w ręku
siebie. Źródłem jest ikona legendy z PixelLab (assets/items/legends/<id>.png) albo - gdy ikona ma ramkę lub
poświatę - osobny rysunek z PixelLab w pixellab_src/legend_held/<id>.png (create_1_direction_object, identyfikator
w pixellab_src/legend_held/ids.json; tło usunięte wypełnianiem od krawędzi). Obrót, zmniejszenie i chwyt - jak
w tools/pixellab_items.py (held_sprite) dla linii broni bazowej.
Wynik: assets/weapons/<id>.png i scripts/legend_held.gd (chwyty). Uruchom: python tools/legend_held.py"""
import os
import re
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import item_catalog as cat  # noqa: E402
from pixellab_items import HELD_DENSITY, held_sprite  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = os.path.join(ROOT, "pixellab_src", "legend_held")
OUT_GD = os.path.join(ROOT, "scripts", "legend_held.gd")


def _base_lines():
    """Baza przedmiotu -> linia z katalogu (ustawienia broni w ręku)."""
    result = {}
    for line in cat.LINES:
        for tier in range(5):
            result[cat.base_id(line, tier)] = line
    return result


def _legends():
    text = open(os.path.join(ROOT, "scripts", "legends.gd"), encoding="utf-8-sig").read()
    return re.findall(r'"(legend_[a-z_]+)": \{"base": "([a-z_0-9]+)"', text)


def main():
    lines = _base_lines()
    grips = {}
    for legend, base in _legends():
        line = lines.get(base)
        if line is None or "held" not in line:
            continue
        source = os.path.join(SOURCES, legend + ".png")
        if not os.path.exists(source):
            source = os.path.join(ROOT, "assets", "items", "legends", legend + ".png")
        if not os.path.exists(source):
            continue
        sprite, grip = held_sprite(Image.open(source), line["held"], legend)
        sprite.save(os.path.join(ROOT, "assets", "weapons", legend + ".png"))
        grips[legend] = grip
    out = ["class_name LegendHeld",
           "## Wygenerowane przez tools/legend_held.py - nie edytować ręcznie.",
           "## Legendarne bronie trzymane w ręku: grafika assets/weapons/<id>.png i chwyt w jej pikselach",
           "## (Legends.data podmienia nimi broń w ręku przedmiotu bazowego).",
           "",
           "const GRIPS := {"]
    for legend in sorted(grips):
        out.append('\t"%s": Vector2(%s, %s),' % (legend, round(grips[legend][0], 1), round(grips[legend][1], 1)))
    out.append("}")
    open(OUT_GD, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("legendy w ręku: %d (skala 1/%d)" % (len(grips), HELD_DENSITY))


if __name__ == "__main__":
    main()
