"""Ikona Kości Skarbnika (assets/items/skarbnik_bones.png, 64x64): dwie kościane kostki do gry, rysowane piksel po pikselu
w siatce 32x32 i powiększone dwukrotnie (jak inne ikony przedmiotów). Uruchom: python tools/skarbnik_art.py"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "items" / "skarbnik_bones.png"

OUTLINE = (52, 36, 24, 255)
TOP = (238, 226, 196, 255)
LEFT = (206, 190, 154, 255)
RIGHT = (170, 150, 112, 255)
PIP = (70, 36, 28, 255)
GLOW = (255, 210, 110, 255)


def die(d: ImageDraw.ImageDraw, x: int, y: int, s: int, pips_top: list, pips_side: list) -> None:
	"""Kostka w rzucie z ukosa: górna ściana (romb), lewa i prawa ściana; oczka jako pojedyncze piksele."""
	h = s // 2
	top = [(x + s, y), (x + 2 * s, y + h), (x + s, y + 2 * h), (x, y + h)]
	left = [(x, y + h), (x + s, y + 2 * h), (x + s, y + 2 * h + s), (x, y + h + s)]
	right = [(x + s, y + 2 * h), (x + 2 * s, y + h), (x + 2 * s, y + h + s), (x + s, y + 2 * h + s)]
	d.polygon(left, fill=LEFT, outline=OUTLINE)
	d.polygon(right, fill=RIGHT, outline=OUTLINE)
	d.polygon(top, fill=TOP, outline=OUTLINE)
	for px, py in pips_top:
		d.point((x + px, y + py), fill=PIP)
	for px, py in pips_side:
		d.point((x + px, y + py), fill=PIP)


def main() -> None:
	img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	# tylna kostka (wyżej, po prawej) i przednia (niżej, po lewej)
	die(d, 13, 4, 8, [(8, 4), (5, 3), (11, 5)], [(4, 10), (4, 13), (12, 11), (14, 10)])
	die(d, 3, 12, 8, [(8, 4)], [(3, 9), (5, 12), (11, 10), (13, 13), (12, 12)])
	# złocista poświata ducha w kilku punktach obrysu
	for p in [(21, 4), (29, 8), (3, 16), (11, 12)]:
		img.putpixel(p, GLOW)
	img = img.resize((64, 64), Image.NEAREST)
	img.save(OUT)
	print("zapisano", OUT)


if __name__ == "__main__":
	main()
