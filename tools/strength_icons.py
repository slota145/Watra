"""Tymczasowe ikony nowych węzłów strony siły (krok 5 wspólnego drzewka, docs/plan_drzewek.md): przebarwione ikony
pokrewnych umiejętności z assets/skills, dopóki nie powstanie paczka ikon z PixelLab.
- wolf_fang (Wilczy Kieł) - Szarża w zimnej stali,
- bull_roar (Ryk Tura) - Zew Peruna w ogniście czerwonych barwach,
- bear_leap (Skok Niedźwiedzia) - Rozłupanie Ziemi w brązie,
- ks_last_bastion (Ostatni Bastion) - Krew za Manę w złocie.
Uruchom: python tools/strength_icons.py"""
import colorsys
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(ROOT, "assets", "skills")
# nazwa: (ikona źródłowa, przesunięcie odcienia 0..1, mnożnik nasycenia, mnożnik jasności)
ICONS = {
    "wolf_fang": ("lunge", 0.55, 0.35, 1.05),
    "bull_roar": ("war_cry", -0.12, 1.3, 1.0),
    "bear_leap": ("ground_slam", 0.05, 0.6, 0.9),
    "ks_last_bastion": ("ks_blood_sacrifice", 0.12, 0.9, 1.1),
}


def recolor(image, shift, saturation, value):
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            r2, g2, b2 = colorsys.hsv_to_rgb((h + shift) % 1.0, min(s * saturation, 1.0), min(v * value, 1.0))
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return out


def main():
    for name, (source, shift, saturation, value) in ICONS.items():
        image = Image.open(os.path.join(SKILLS, source + ".png")).convert("RGBA")
        recolor(image, shift, saturation, value).save(os.path.join(SKILLS, name + ".png"))
    print("ikony strony siły: %d" % len(ICONS))


if __name__ == "__main__":
    main()
