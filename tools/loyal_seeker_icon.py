"""Ikona węzła Wierny tropiciel (assets/skills/node_loyal_seeker.png) złożona z gotowych ikon, bez PixelLab.

Bierze strzałę z ikony Strzały tropiącej (bez ramki), dorysowuje widmowy krąg, po którym krąży (przywołanie),
i złote serce z ikony Wiernych ogników (ten sam znak „wierności” co u ogników).
Uruchom: python tools/loyal_seeker_icon.py
"""
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "assets" / "skills"


def main() -> None:
	seeker = Image.open(SKILLS / "seeker.png").convert("RGBA")
	wisps = Image.open(SKILLS / "node_loyal_wisps.png").convert("RGBA")
	icon = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
	# widmowy krąg (elipsa z kropek) pod strzałą
	cx, cy, rx, ry = 31, 34, 25, 25
	for k in range(72):
		a = k * math.tau / 72
		x, y = round(cx + math.cos(a) * rx), round(cy + math.sin(a) * ry)
		fade = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(a * 1.0 + 1.2))
		icon.putpixel((x, y), (120, 235, 190, round(200 * fade)))
		if k % 9 == 0:
			for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
				icon.putpixel((x + dx, y + dy), (190, 255, 225, 230))
	# strzała z ikony Strzały tropiącej - bez ramki (piksele ciemnoszarej ramki i tła wycięte), przesunięta do środka
	inner = seeker.crop((7, 7, 57, 57))
	clean = Image.new("RGBA", inner.size, (0, 0, 0, 0))
	for y in range(inner.height):
		for x in range(inner.width):
			r, g, b, a = inner.getpixel((x, y))
			# tło ikony jest ciemne i prawie szare - zostają tylko jaśniejsze albo barwne piksele (strzała, smuga, tarcza)
			if a == 0 or (max(r, g, b) < 70 and max(r, g, b) - min(r, g, b) < 18):
				continue
			# fioletowa tarcza celu z ikony - zbędna (cel wybiera sama strzała)
			if b > g + 15 and r > g:
				continue
			# przebarwienie na widmową zieleń (jak kolor przywołania w SummonData.COLORS)
			lum = ((r * 0.3 + g * 0.59 + b * 0.11) / 255) ** 1.5
			clean.putpixel((x, y), (round(35 + 200 * lum), round(90 + 165 * lum), round(75 + 150 * lum), a))
	icon.alpha_composite(clean, (7, 9))
	# złote serce z ikony Wiernych ogników (prawy górny róg)
	heart = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
	box = wisps.crop((40, 6, 64, 30))
	for y in range(box.height):
		for x in range(box.width):
			r, g, b, a = box.getpixel((x, y))
			if a > 0 and r > g > b and r - b > 50:
				heart.putpixel((x, y), (r, g, b, a))
	icon.alpha_composite(heart, (40, 2))
	icon.save(SKILLS / "node_loyal_seeker.png")


if __name__ == "__main__":
	main()
