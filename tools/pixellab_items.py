"""Grafiki przedmiotów z PixelLab (pixellab_src/items/raw, pobierane przez pixellab_src/items/fetch.py), które
nadpisują dawne grafiki 16 px z tools/item_art.py, skill_art.py i ui_art.py:
- ikony 64x64 -> assets/items/<plik>.png (UI pokazuje je w kratce 16 px, czyli piksel w piksel przy skali okna x4),
- broń w ręku -> assets/weapons/<plik>.png: ikona obrócona wzdłuż osi i zmniejszona do 2x gęstości pikseli
  świata (gra rysuje ją w skali 1/2), z wyliczonym punktem chwytu,
- ikony umiejętności i interfejsu -> assets/skills, assets/ui,
- scripts/item_bases.gd - przedmioty bazowe z katalogu (tools/item_catalog.py) z ikonami, bronią w ręku i chwytem.
Wywoływane z generate_art.py (na końcu) albo samodzielnie: python tools/pixellab_items.py
"""
import json
import os

from PIL import Image

import item_catalog as cat

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "pixellab_src", "items", "raw")
ITEMS = os.path.join(ROOT, "assets", "items")
WEAPONS = os.path.join(ROOT, "assets", "weapons")
OUTLINE = (20, 16, 24, 255)
## Broń w ręku ma 2x gęstszy piksel niż świat: grafika ma podwójną długość, a gra rysuje ją w skali 1/2
## (przy skali okna x4 każdy piksel broni to równo 2 piksele monitora - więcej detalu bez migotania).
HELD_DENSITY = 2


def _crop(img):
    box = img.getbbox()
    return img.crop(box) if box else img


def _clean_alpha(img, threshold=110):
    """Piksele półprzezroczyste z PixelLab: pełne albo puste (krawędzie pixel artu bez rozmycia)."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= threshold else (0, 0, 0, 0)
    return img


def _shrink(img, scale):
    """Zmniejsza z mieszaniem kolorów z wagą krycia (bez ciemnych obwódek), potem ostra alfa i paleta."""
    size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
    small = img.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA")
    small = _clean_alpha(small, 100)
    rgb = small.convert("RGB").quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert("RGB")
    out = Image.new("RGBA", small.size)
    out.paste(rgb, mask=small.split()[3])
    return out


def _outline(img):
    """Ciemny obrys dookoła sylwetki (o piksel na zewnątrz) - wnętrze zachowuje kolory, a cienka broń
    nie ginie na tle trawy."""
    out = Image.new("RGBA", (img.width + 2, img.height + 2))
    out.paste(img, (1, 1))
    src = out.copy().load()
    dst = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < out.width and 0 <= ny < out.height and src[nx, ny][3]:
                    dst[x, y] = OUTLINE
                    break
    return out


def held_sprite(icon, held, kind):
    """Broń w ręku z ikony: (obraz, chwyt [x, y] w pikselach obrazu). Broń biała i kostury - ostrzem
    w prawo (ikona ma je po skosie w prawy górny róg), łuk - pionowo, księga - bez obrotu."""
    img = _crop(icon.convert("RGBA"))
    if held["grip"] != "book":
        big = img.resize((img.width * 4, img.height * 4), Image.NEAREST)
        # łuk: ramiona wzdłuż skosu -> pionowo; reszta: ostrze z prawego górnego rogu -> w prawo
        big = big.rotate(45 if held["grip"] == "bow" else -45, resample=Image.BICUBIC, expand=True)
        img = _crop(big)
        length = img.height if held["grip"] == "bow" else img.width
    else:
        length = img.width
    sprite = _outline(_crop(_shrink(img, held["length"] * HELD_DENSITY / length)))
    return sprite, _grip(sprite, held["grip"])


def _grip(img, rule):
    alpha = img.split()[3].load()
    cols = []
    for x in range(img.width):
        ys = [y for y in range(img.height) if alpha[x, y]]
        cols.append(ys)
    filled = [x for x in range(img.width) if cols[x]]
    left, right = filled[0], filled[-1]
    if rule in ("bow", "book"):
        return [img.width / 2.0, img.height / 2.0]
    if rule == "guard":
        # jelec: najwyższa kolumna w lewej części broni; chwyt w połowie rękojeści przed nim
        span = left + int((right - left) * 0.45)
        guard = max(range(left, span + 1), key=lambda x: len(cols[x]))
        x = (left + guard) // 2
    else:
        x = left + int((right - left) * float(rule))
    ys = cols[x] or cols[left]
    return [x + 0.5, (ys[0] + ys[-1]) / 2.0 + 0.5]


SKILLS = os.path.join(ROOT, "assets", "skills")
UI = os.path.join(ROOT, "assets", "ui")
BASES_GD = os.path.join(ROOT, "scripts", "item_bases.gd")
PROJECTILES = {"arrow": "res://assets/projectiles/arrow.png", "magic_missile": "res://assets/projectiles/magic_missile.png"}
# sposób trzymania broni w grze: książka bez obrotu, łuk pionowo, reszta ostrzem wzdłuż ręki
HOLD = {"book": "book", "bow": "bow"}
# przedmioty spoza linii z bronią w ręku (startowy miecz)
EXTRA_WEAPONS = {
    "rusty_sword": {"name": "Zardzewiały miecz", "description": "Lepszy taki niż żaden.", "price": 20, "sell": 5,
                    "weapon": {"type": "melee", "damage": [10, 15], "speed": 1.0, "reach": 30.0, "arc": 160.0},
                    "held": {"length": 28, "grip": "guard"}},
}


def _icon(name):
    path = os.path.join(RAW, name + ".png")
    return _clean_alpha(Image.open(path).convert("RGBA")) if os.path.exists(path) else None


def _gd(value):
    """Wartość Pythona jako literał GDScript (słowniki, listy, liczby, napisy, True/False)."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return value[1:] if value.startswith("@") else json.dumps(value, ensure_ascii=False)
    if isinstance(value, (list, tuple)):
        return "[" + ", ".join(_gd(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{" + ", ".join("%s: %s" % (json.dumps(k), _gd(v)) for k, v in value.items()) + "}"
    raise TypeError(value)


def _weapon(name, icon, weapon, held):
    """Broń w ręku z ikony (zapisana w assets/weapons) i dane broni z chwytem."""
    sprite, grip = held_sprite(icon, held, name)
    sprite.save(os.path.join(WEAPONS, name + ".png"))
    data = dict(weapon)
    if "projectile" in data:
        data["projectile"] = dict(data["projectile"], texture="@preload(%s)" % json.dumps(PROJECTILES[data["projectile"]["texture"]]))
    data["held"] = '@preload("res://assets/weapons/%s.png")' % name
    data["grip"] = "@Vector2(%s, %s)" % (round(grip[0], 1), round(grip[1], 1))
    data["hold"] = HOLD.get(held["grip"], "blade")
    data["held_scale"] = 1.0 / HELD_DENSITY
    return data


def build():
    """Ikony, broń w ręku i scripts/item_bases.gd ze wszystkiego, co jest w pixellab_src/items/raw."""
    os.makedirs(WEAPONS, exist_ok=True)
    entries = {}
    lines = {}
    missing = []
    for line in cat.LINES:
        lines[line["id"]] = []
        for tier in range(5):
            base = cat.base_id(line, tier)
            lines[line["id"]].append(base)
            entry = {"name": line["names"][tier], "description": line["description"], "slot": line["slot"],
                     "rarity": "common", "sell_price": int(line["sell"] * (1 + tier * 0.5)), "line": line["id"], "tier": tier + 1}
            if base in cat.SHOP_PRICES:
                entry["price"] = cat.SHOP_PRICES[base]
            if "stats" in line:
                entry["stats"] = line["stats"]
            looks = {}
            for rarity in cat.RARITIES:
                name = cat.icon_name(line, tier, rarity)
                icon = _icon(name)
                if icon is None:
                    missing.append(name)
                    continue
                icon.save(os.path.join(ITEMS, name + ".png"))
                look = {"icon": '@preload("res://assets/items/%s.png")' % name}
                if "weapon" in line:
                    look["weapon"] = _weapon(name, icon, line["weapon"], line["held"])
                looks[rarity] = look
            if "common" not in looks:
                continue
            entry["icon"] = looks["common"]["icon"]
            if "weapon" in line:
                entry["weapon"] = looks["common"]["weapon"]
            entry["looks"] = {r: looks[r] for r in looks if r != "common"}
            entries[base] = entry
    for name, extra in EXTRA_WEAPONS.items():
        icon = _icon(name)
        if icon is None:
            missing.append(name)
            continue
        icon.save(os.path.join(ITEMS, name + ".png"))
        entries[name] = {"name": extra["name"], "description": extra["description"], "slot": "weapon",
                         "rarity": "common", "price": extra["price"], "sell_price": extra["sell"],
                         "icon": '@preload("res://assets/items/%s.png")' % name,
                         "weapon": _weapon(name, icon, extra["weapon"], extra["held"]), "looks": {}}
    # pozostałe ikony: łupy, legendy, mikstury (te same nazwy plików co dotąd), umiejętności, interfejs
    for folder, items in ((ITEMS, cat.MISC), (SKILLS, cat.SKILLS), (UI, cat.UI_ICONS)):
        for name, _prompt in items:
            if name in EXTRA_WEAPONS:
                continue
            icon = _icon(name)
            if icon is None:
                missing.append(name)
            else:
                icon.save(os.path.join(folder, name + ".png"))
    _write_bases(entries, lines)
    print("przedmioty: %d baz, brak ikon: %d %s" % (len(entries), len(missing), missing[:8]))


def _write_bases(entries, lines):
    out = [
        "class_name ItemBases",
        "## Wygenerowane przez tools/pixellab_items.py z tools/item_catalog.py - nie edytować ręcznie.",
        "## Przedmioty bazowe do założenia: linie (miecz, kaptur, pierścień...) w 5 poziomach (zakresy poziomu",
        "## przedmiotu w TIER_LEVELS). Statystyki są podane na poziom przedmiotu 1 (rosną z nim - Loot).",
        "## looks - wygląd magicznej i rzadkiej wersji (ikona, broń w ręku); weapon.grip - chwyt w pikselach",
        "## grafiki broni w ręku, weapon.hold - jak ją trzymać (blade / bow / book).",
        "",
        "const TIER_LEVELS := %s" % _gd([list(t) for t in cat.TIER_LEVELS]),
        "const LINES := %s" % _gd(lines),
        "const DATA := {",
    ]
    for base, entry in entries.items():
        out.append("\t%s: %s," % (json.dumps(base), _gd(entry)))
    out.append("}")
    open(BASES_GD, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")


def preview(path):
    """Podgląd: ikony linii i broń w ręku w skali świata x4 (do oceny)."""
    rows = []
    for line in cat.LINES:
        if "held" not in line:
            continue
        for tier in range(5):
            for rarity in cat.RARITIES:
                name = cat.icon_name(line, tier, rarity)
                src = os.path.join(RAW, name + ".png")
                if os.path.exists(src):
                    sprite, grip = held_sprite(Image.open(src), line["held"], line["id"])
                    rows.append((Image.open(src).convert("RGBA"), sprite, grip))
    if not rows:
        return
    cell = 72
    sheet = Image.new("RGBA", (cell * 2 * 15, cell * ((len(rows) + 14) // 15)), (40, 44, 52, 255))
    for i, (icon, sprite, grip) in enumerate(rows):
        x, y = (i % 15) * cell * 2, (i // 15) * cell
        sheet.alpha_composite(icon, (x + 4, y + 4))
        big = sprite.resize((sprite.width * 2, sprite.height * 2), Image.NEAREST)
        sx, sy = x + cell + 4, y + 4
        sheet.alpha_composite(big, (sx, sy))
        gx, gy = int(sx + grip[0] * 2), int(sy + grip[1] * 2)
        for d in range(-2, 3):
            sheet.putpixel((min(gx + d, sheet.width - 1), gy), (255, 0, 255, 255))
            sheet.putpixel((gx, min(gy + d, sheet.height - 1)), (255, 0, 255, 255))
    sheet.save(path)


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        preview(sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "pixellab_src", "items", "held_preview.png"))
    else:
        build()
