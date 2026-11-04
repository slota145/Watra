"""Grafiki przywołańców gracza (Summons) przebarwione z gotowych grafik krain, bez PixelLab.

- assets/summons/wisp_fire.png - Błędny Ognik gracza: turkusowy ognik z Leśnego Cmentarza (assets/regions/wisp.png,
  4x2 klatki) przebarwiony na pomarańczowy ogień (obrót barwy, jaśniejsze środki).
Widmowe wilki Watahy to zwykły wilk z lasu (assets/forest/wolf.png) przebarwiony w grze (Summons - modulate).
Uruchom: python tools/minion_art.py
"""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def recolor(src: Path, dst: Path, hue: float, saturation: float = 1.0) -> None:
	image = Image.open(src).convert("RGBA")
	out = Image.new("RGBA", image.size, (0, 0, 0, 0))
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, a = image.getpixel((x, y))
			if a == 0:
				continue
			_, light, sat = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
			nr, ng, nb = colorsys.hls_to_rgb(hue, light, min(sat * saturation, 1.0))
			out.putpixel((x, y), (round(nr * 255), round(ng * 255), round(nb * 255), a))
	dst.parent.mkdir(parents=True, exist_ok=True)
	out.save(dst)


def main() -> None:
	recolor(ROOT / "assets" / "regions" / "wisp.png", ROOT / "assets" / "summons" / "wisp_fire.png", 28 / 360, 1.15)


if __name__ == "__main__":
	main()
