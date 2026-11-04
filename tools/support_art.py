"""Ikony kamieni wsparcia (scripts/supports.gd) i krzesiw na gniazda umiejętności - bez nowych generacji PixelLab.
Kamień wsparcia: owalny klejnot (assets/items/gems/amethyst_3.png) przebarwiony na kolor kamienia (Supports.DATA "color")
z wyrytą jasną ikonką jego tagu (assets/ui/tags/<tag>.png, tools/tag_icons.py) - po tagu widać, do czego pasuje.
Krzesiwa: surowy klejnot (assets/items/rough_gem.png) przebarwiony na sino (Krzesiwo Nawii) i na żar (Wielkie Krzesiwo),
z iskrami.
Wynik: assets/items/supports/<rodzaj>.png, assets/items/nawia_flint.png, assets/items/great_flint.png.
Uruchom: python tools/support_art.py"""
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# rodzaj -> (kolor, tag ikonki) - jak Supports.DATA
SUPPORTS = {
    "area": ("e0c070", "area"), "split": ("d8cbb0", "projectile"), "pierce": ("b8c4d8", "projectile"),
    "chain": ("a0b0ff", "projectile"), "fire_edge": ("ff8a3d", "fire"), "frost_edge": ("8fd8ff", "ice"),
    "storm_edge": ("ffe45c", "lightning"), "ember": ("ff6a2a", "fire"), "rime": ("6ec8ff", "ice"),
    "discharge": ("fff07a", "lightning"), "venom": ("8fdc5a", "dot"), "brutal": ("ff7a6a", "hit"),
    "fury": ("ffa060", "attack"), "echo": ("c79bff", "spell"), "momentum": ("7fe08a", "movement"),
    "warlord": ("d0a0ff", "summon"), "herald": ("ff9a7a", "cry"),
}


def rgb(hex_color):
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))


def tint(image, color, strength=1.0):
    """Przebarwia obrazek: jasność piksela razy kolor (cienie ciemne, blaski jasne)."""
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            light = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
            boost = min(1.0, light * 1.9)
            nr = [int(c * boost + 255 * max(0.0, light - 0.75) * 1.2) for c in color]
            px[x, y] = tuple(min(255, int(o * (1 - strength) + n * strength)) for o, n in zip((r, g, b), nr)) + (a,)
    return out


def glyph(tag, size, color):
    """Ikonka tagu w kolorze `color` z ciemnym obrysem, wielkości `size` px."""
    icon = Image.open(os.path.join(ROOT, "assets", "ui", "tags", tag + ".png")).convert("RGBA").resize((size, size), Image.NEAREST)
    # tylko jasne kreski ikonki (jej ciemny obrys i wnętrze zostają przezroczyste)
    lines = Image.new("L", icon.size, 0)
    src, dst = icon.load(), lines.load()
    for y in range(icon.height):
        for x in range(icon.width):
            r, g, b, a = src[x, y]
            dst[x, y] = 255 if a > 0 and (r + g + b) / 3 > 110 else 0
    shape = Image.new("RGBA", icon.size, color + (255,))
    shape.putalpha(lines)
    out = Image.new("RGBA", (size + 4, size + 4), (0, 0, 0, 0))
    dark = Image.new("RGBA", icon.size, (20, 14, 30, 220))
    dark.putalpha(lines.point(lambda a: 220 if a > 0 else 0))
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (1, 1)):
        out.alpha_composite(dark, (2 + dx, 2 + dy))
    out.alpha_composite(shape, (2, 2))
    return out


def sparks(image, color, count, seed):
    rnd = random.Random(seed)
    px = image.load()
    for _ in range(count):
        x, y = rnd.randint(40, 60), rnd.randint(4, 24)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= x + dx < image.width and 0 <= y + dy < image.height:
                px[x + dx, y + dy] = color + (255 if (dx, dy) == (0, 0) else 170,)


def main():
    out = os.path.join(ROOT, "assets", "items", "supports")
    os.makedirs(out, exist_ok=True)
    base = Image.open(os.path.join(ROOT, "assets", "items", "gems", "amethyst_3.png")).convert("RGBA")
    for kind, (color, tag) in SUPPORTS.items():
        icon = tint(base, rgb(color))
        mark = glyph(tag, 26, (250, 246, 232))
        icon.alpha_composite(mark, ((64 - mark.width) // 2, (64 - mark.height) // 2 + 1))
        icon.save(os.path.join(out, kind + ".png"))
    rough = Image.open(os.path.join(ROOT, "assets", "items", "rough_gem.png")).convert("RGBA")
    flint = tint(rough, (120, 140, 200), 0.85)
    sparks(flint, (190, 170, 255), 7, 3)
    flint.save(os.path.join(ROOT, "assets", "items", "nawia_flint.png"))
    great = tint(rough, (255, 150, 70), 0.85)
    sparks(great, (255, 230, 120), 10, 5)
    great.save(os.path.join(ROOT, "assets", "items", "great_flint.png"))
    print("kamienie wsparcia: %d ikon, 2 krzesiwa" % len(SUPPORTS))


if __name__ == "__main__":
    main()
