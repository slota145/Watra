"""Cięciwy łuków rysowane w grze: usuwa cięciwę narysowaną na grafikach łuków w ręku (assets/weapons/*bow*.png)
i zapisuje końce ramion łuku, do których gra przyczepia własną cięciwę (scripts/bow_rig.gd, klasa BowRig).

Łuk w ręku stoi pionowo, brzuścem w prawo (w stronę celu), a cięciwa to wąski pionowy pasek przy lewej krawędzi.
W każdym wierszu najbardziej lewy ciąg pikseli, jeśli ma najwyżej STRING_WIDTH pikseli i dalej w wierszu jest
przerwa, a za nią reszta łuku, to cięciwa - wymazujemy go. Końce ramion to najbardziej lewe piksele w kilku
skrajnych wierszach (u góry i u dołu). Skrypt można uruchamiać wiele razy: bez cięciwy grafika się nie zmienia.
Ręczne poprawki grafik (np. pozioma kreska, która miała być strzałą, i łuk przesunięty od chwytu) są w FIX.

Grafiki łuków robi tools/pixellab_items.py (i legend_held.py) - po ich ponownym uruchomieniu uruchom też ten skrypt.
Uruchom: python tools/bow_strings.py"""
import glob
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEAPONS = os.path.join(ROOT, "assets", "weapons")
STRING_WIDTH = 4
## Ile skrajnych wierszy łuku przeszukać, szukając końca ramienia.
TIP_ROWS = 3
## Poprawki: "erase" - prostokąty [x0, y0, x1, y1] (włącznie) do wymazania, "shift" - przesunięcie całego obrazka
## w poziomie (łuk ma stać tak, żeby chwyt z ItemBases trafiał w majdan, jak w pozostałych łukach).
FIX = {
    "bow_t4": {"erase": [[0, 29, 30, 33]], "shift": -12},
    "bow_t4_magic": {"erase": [[0, 29, 31, 33]], "shift": -12},
    "bow_t4_rare": {"erase": [[0, 29, 32, 33]], "shift": -13},
}


def _strip(img):
    """Wymazuje cięciwę; zwraca liczbę wymazanych pikseli."""
    px = img.load()
    w, h = img.size
    erased = 0
    for y in range(h):
        xs = [x for x in range(w) if px[x, y][3] >= 128]
        if not xs:
            continue
        a = b = xs[0]
        while b + 1 < w and px[b + 1, y][3] >= 128:
            b += 1
        rest = [x for x in xs if x > b + 1]
        if b - a + 1 <= STRING_WIDTH and rest and a < w // 2:
            for x in range(a, b + 1):
                px[x, y] = (0, 0, 0, 0)
                erased += 1
    return erased


def _apply_fix(img, fix):
    px = img.load()
    for x0, y0, x1, y1 in fix.get("erase", []):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if 0 <= x < img.width and 0 <= y < img.height:
                    px[x, y] = (0, 0, 0, 0)
    shift = fix.get("shift", 0)
    if shift:
        moved = Image.new("RGBA", img.size)
        moved.alpha_composite(img.crop((max(0, -shift), 0, img.width, img.height)), (max(0, shift), 0))
        img = moved
    return img


def _tips(img):
    """Końce ramion łuku: [x, y] górny i dolny (środek piksela) - najbardziej lewy piksel w TIP_ROWS skrajnych wierszach."""
    px = img.load()
    w, h = img.size
    rows = [y for y in range(h) if any(px[x, y][3] >= 128 for x in range(w))]
    out = []
    for band in (rows[:TIP_ROWS], rows[-TIP_ROWS:]):
        best = min(((x, y) for y in band for x in range(w) if px[x, y][3] >= 128), key=lambda p: p[0])
        out.append([best[0] + 0.5, best[1] + 0.5])
    return out


def main():
    tips = {}
    for path in sorted(glob.glob(os.path.join(WEAPONS, "*bow*.png"))):
        name = os.path.splitext(os.path.basename(path))[0]
        img = Image.open(path).convert("RGBA")
        before = img.tobytes()
        fix = FIX.get(name)
        # poprawka ręczna tylko raz: po niej po lewej od łuku nie ma już kreski
        if fix and img.getbbox()[0] < 5:
            img = _apply_fix(img, fix)
        erased = _strip(img)
        if img.tobytes() != before:
            img.save(path)
        tips[name] = _tips(img)
        print("%s: wymazano %d px cięciwy, końce %s" % (name, erased, tips[name]))
    lines = [
        "class_name BowRig",
        "## Wygenerowane przez tools/bow_strings.py - nie edytować ręcznie.",
        "## Końce ramion łuków w ręku (piksele grafiki assets/weapons/<łuk>.png, łuk pionowo, cel w prawo):",
        "## tu gra przyczepia cięciwę (BowString).",
        "",
        "const TIPS := {",
    ]
    for name, (top, bottom) in tips.items():
        lines.append('\t"%s": [Vector2(%s, %s), Vector2(%s, %s)],' % (name, top[0], top[1], bottom[0], bottom[1]))
    lines += [
        "}",
        "",
        "",
        "## Końce ramion łuku z tej grafiki (pusta tablica - nie łuk).",
        "static func tips(texture: Texture2D) -> Array:",
        "\tif texture == null:",
        "\t\treturn []",
        '\treturn TIPS.get(texture.resource_path.get_file().get_basename(), [])',
        "",
    ]
    with open(os.path.join(ROOT, "scripts", "bow_rig.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("Zapisano scripts/bow_rig.gd")


if __name__ == "__main__":
    main()
