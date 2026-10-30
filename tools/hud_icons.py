"""Ikony paska szybkiego wyboru i efektów składane z istniejących grafik:
- assets/skills/attack.png: zwykły atak bronią - ukośny miecz (assets/items/iron_sword.png) na tle ikon
  umiejętności (ciemny kwadrat z obwódką wycięty z assets/skills/lunge.png),
- assets/ui/status_watra.png: płomień Watry (środek pierwszej klatki assets/village/watra.png) na przezroczystym
  tle, ikona Darów i poziomu Watry na liście efektów.
Uruchom: python tools/hud_icons.py"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def path(*parts):
    return os.path.join(ROOT, *parts)


def skill_background():
    """Tło ikon umiejętności: obwódka i ciemne wnętrze z ikony szarży (bez jej rysunku)."""
    src = Image.open(path("assets", "skills", "lunge.png")).convert("RGBA")
    bg = src.copy()
    inner = (20, 22, 35, 255)
    w, h = bg.size
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] == 0:
                continue
            # obwódka: piksele w odległości do 2 od przezroczystego brzegu; reszta (rysunek szarży) to jednolite wnętrze
            edge = any(src.getpixel((x + dx, y + dy))[3] == 0 if 0 <= x + dx < w and 0 <= y + dy < h else True
                       for dx in range(-2, 3) for dy in range(-2, 3))
            if not edge:
                bg.putpixel((x, y), inner)
    return bg


def attack_icon():
    bg = skill_background()
    sword = Image.open(path("assets", "items", "iron_sword.png")).convert("RGBA")
    sword = sword.crop(sword.getbbox())
    scale = 46.0 / max(sword.size)
    sword = sword.resize((max(1, round(sword.width * scale)), max(1, round(sword.height * scale))), Image.NEAREST)
    box = bg.getbbox()
    cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
    bg.alpha_composite(sword, (cx - sword.width // 2, cy - sword.height // 2))
    bg.save(path("assets", "skills", "attack.png"))


def watra_icon():
    sheet = Image.open(path("assets", "village", "watra.png")).convert("RGBA")
    frame = sheet.crop((0, 0, 104, 104))
    # sam płomień ze stosem drewna: środek klatki, bez kamieni z runami po bokach
    fire = frame.crop((40, 4, 64, 66))
    fire = fire.crop(fire.getbbox())
    size = 64
    scale = (size - 4) / max(fire.size)
    fire = fire.resize((max(1, round(fire.width * scale)), max(1, round(fire.height * scale))), Image.NEAREST)
    icon = Image.new("RGBA", (size, size))
    icon.alpha_composite(fire, ((size - fire.width) // 2, size - fire.height - 2))
    icon.save(path("assets", "ui", "status_watra.png"))


def main():
    attack_icon()
    watra_icon()
    print("hud icons: attack, status_watra")


if __name__ == "__main__":
    main()
