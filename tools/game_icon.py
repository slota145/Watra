"""Ikona gry z pierwszej klatki Watry (assets/village/watra.png - ognisko w kręgu kamieni): ciemny zaokrąglony
kwadrat z poświatą ognia i złotą obwódką.
- assets/icon.png - 256x256, ikona okna gry (project.godot - application/config/icon),
- assets/icon.ico - ikona pliku .exe (export_presets.cfg - application/icon) w rozmiarach 16-256; małe rozmiary
  (do 48 px) mają kadr przybliżony na ogień i polana, żeby płomień był czytelny na pasku zadań.
Uruchom: python tools/game_icon.py"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "assets", "village", "watra.png")
FRAME = 104  # klatka Watry 104x104 (arkusz 6 klatek w rzędzie)
CANVAS = 128  # ikona rysowana w 128x128 i powiększana bez wygładzania
BG = (22, 18, 28, 255)
BORDER = (180, 120, 50, 255)
GLOW = (255, 140, 40, 150)


def watra_frame() -> Image.Image:
    frame = Image.open(SOURCE).convert("RGBA").crop((0, 0, FRAME, FRAME))
    return frame.crop(frame.getbbox())


def compose(art: Image.Image, glow_box: tuple, radius: int = 18, border: int = 3) -> Image.Image:
    """Grafika na środku ciemnego zaokrąglonego kwadratu z poświatą i obwódką (CANVAS x CANVAS)."""
    size = CANVAS
    base = Image.new("RGBA", (size, size), BG)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(glow_box, fill=GLOW)
    base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(18)))
    base.alpha_composite(art, ((size - art.width) // 2, (size - art.height) // 2 + 2))
    ImageDraw.Draw(base).rounded_rectangle((2, 2, size - 3, size - 3), radius, outline=BORDER, width=border)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((2, 2, size - 3, size - 3), radius, fill=255)
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon.paste(base, (0, 0), mask)
    return icon


def main() -> None:
    frame = watra_frame()
    full = compose(frame, (24, 18, 104, 98))
    # mały kadr: ogień i polana ze środka klatki, powiększone, żeby wypełniły ikonę
    w, h = frame.size
    close = frame.crop((int(w * 0.22), int(h * 0.0), int(w * 0.78), int(h * 0.72)))
    scale = (CANVAS - 20) / max(close.size)
    close = close.resize((round(close.width * scale), round(close.height * scale)), Image.NEAREST)
    small = compose(close, (14, 10, 114, 110), radius=22, border=6)

    big = full.resize((256, 256), Image.NEAREST)
    big.save(os.path.join(ROOT, "assets", "icon.png"))
    sizes = {s: (full if s > 48 else small).resize((s, s), Image.NEAREST if s in (128, 256) else Image.LANCZOS)
             for s in (16, 24, 32, 48, 64, 128, 256)}
    sizes[256].save(os.path.join(ROOT, "assets", "icon.ico"), format="ICO", sizes=[(s, s) for s in sizes],
                    append_images=[sizes[s] for s in sizes if s != 256])
    preview = Image.new("RGBA", (256 + 10 + sum(s + 10 for s in (64, 48, 32, 24, 16)), 256), (60, 60, 70, 255))
    preview.alpha_composite(big, (0, 0))
    x = 266
    for s in (64, 48, 32, 24, 16):
        preview.alpha_composite(sizes[s], (x, 128 - s // 2))
        x += s + 10
    preview.save(os.path.join(ROOT, "pixellab_src", "icon_preview.png"))
    print("assets/icon.png, assets/icon.ico, podgląd: pixellab_src/icon_preview.png")


if __name__ == "__main__":
    main()
