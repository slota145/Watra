"""Ikony aur (Auras, docs/plan_drzewek.md krok 3): okrągły medalion w kolorze aury z symbolem w środku.

Rysowane w kodzie (bez PixelLab): 32x32 pikseli powiększone 2x do 64x64, jak pozostałe ikony umiejętności.
Wynik: assets/skills/aura_<id>.png (Skills.DATA, pasek szybkiego wyboru, ikony pod paskami zdrowia i many).

Uruchom: python tools/aura_icons.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "skills"
S = 32

# kolor aury: (ciemny środek, jasny pierścień) - te same kolory rysuje Auras w grze
COLORS = {
	"dread": ((40, 18, 48), (170, 70, 200)),
	"vigor": ((60, 16, 16), (220, 70, 60)),
	"strzybog_wind": ((16, 48, 46), (120, 230, 200)),
	"life_spring": ((56, 18, 26), (240, 110, 120)),
	"mana_spring": ((14, 26, 64), (90, 150, 255)),
	"swarog_ember": ((64, 26, 8), (255, 140, 50)),
	"marzanna_frost": ((14, 40, 60), (150, 220, 255)),
	"perun_sparks": ((50, 44, 10), (255, 225, 80)),
	"perun_wrath": ((30, 30, 52), (230, 230, 120)),
	"frost_breath": ((10, 30, 56), (110, 200, 255)),
}


def medallion(aura):
	dark, light = COLORS[aura]
	img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	d.ellipse([1, 1, S - 2, S - 2], fill=(20, 18, 24, 255))
	d.ellipse([2, 2, S - 3, S - 3], fill=light + (255,))
	d.ellipse([4, 4, S - 5, S - 5], fill=dark + (255,))
	# kropki aury na pierścieniu
	for k in range(8):
		a = k * math.pi / 4
		x, y = S / 2 - 0.5 + math.cos(a) * 12.5, S / 2 - 0.5 + math.sin(a) * 12.5
		d.point((round(x), round(y)), fill=(255, 255, 255, 200))
	return img, d


def flame(d, cx, cy, h, outer, inner):
	pts = [(cx, cy - h), (cx + h * 0.55, cy - h * 0.1), (cx + h * 0.45, cy + h * 0.5), (cx, cy + h * 0.65),
			(cx - h * 0.45, cy + h * 0.5), (cx - h * 0.55, cy - h * 0.1)]
	d.polygon(pts, fill=outer)
	k = 0.55
	d.polygon([(cx, cy - h * k), (cx + h * 0.3, cy + h * 0.15), (cx, cy + h * 0.55), (cx - h * 0.3, cy + h * 0.15)], fill=inner)


def drop(d, cx, cy, r, color, shine):
	d.ellipse([cx - r, cy - r + 2, cx + r, cy + r + 2], fill=color)
	d.polygon([(cx, cy - r - 4), (cx + r - 1, cy + 1), (cx - r + 1, cy + 1)], fill=color)
	d.point((cx - 2, cy + 1), fill=shine)
	d.point((cx - 2, cy), fill=shine)


def bolt(d, pts, color, width=1):
	d.line(pts, fill=color, width=width)


def snowflake(d, cx, cy, r, color):
	for k in range(3):
		a = k * math.pi / 3
		dx, dy = math.cos(a) * r, math.sin(a) * r
		d.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], fill=color)
	for k in range(6):
		a = k * math.pi / 3
		x, y = cx + math.cos(a) * r * 0.6, cy + math.sin(a) * r * 0.6
		for b in (a + 0.9, a - 0.9):
			d.line([(x, y), (x + math.cos(b) * 2, y + math.sin(b) * 2)], fill=color)


def draw(aura):
	img, d = medallion(aura)
	c = S // 2
	white = (255, 255, 255, 255)
	if aura == "dread":
		d.ellipse([c - 7, c - 8, c + 6, c + 5], fill=(210, 200, 220, 255))
		d.rectangle([c - 4, c + 4, c + 3, c + 7], fill=(210, 200, 220, 255))
		d.rectangle([c - 5, c - 4, c - 2, c - 1], fill=(30, 0, 30, 255))
		d.rectangle([c + 1, c - 4, c + 4, c - 1], fill=(30, 0, 30, 255))
		d.point((c - 4, c - 3), fill=(255, 60, 60, 255))
		d.point((c + 2, c - 3), fill=(255, 60, 60, 255))
		for x in (c - 3, c - 1, c + 1):
			d.point((x, c + 6), fill=(30, 0, 30, 255))
	elif aura == "vigor":
		red, hi = (220, 40, 50, 255), (255, 150, 150, 255)
		d.ellipse([c - 8, c - 7, c - 1, c], fill=red)
		d.ellipse([c, c - 7, c + 7, c], fill=red)
		d.polygon([(c - 8, c - 3), (c + 7, c - 3), (c, c + 7)], fill=red)
		d.point((c - 5, c - 5), fill=hi)
		d.point((c - 6, c - 4), fill=hi)
	elif aura == "strzybog_wind":
		col = (220, 255, 245, 255)
		for k, (y, w) in enumerate(((c - 6, 12), (c - 1, 15), (c + 4, 10))):
			x0 = c - 8 + k
			d.line([(x0, y), (x0 + w - 3, y)], fill=col, width=2)
			d.arc([x0 + w - 6, y - 5, x0 + w, y + 1], -90, 90, fill=col, width=2)
	elif aura == "life_spring":
		drop(d, c, c - 1, 6, (220, 40, 60, 255), (255, 190, 190, 255))
		d.rectangle([c + 3, c + 2, c + 9, c + 4], fill=white)
		d.rectangle([c + 5, c, c + 7, c + 6], fill=white)
	elif aura == "mana_spring":
		drop(d, c, c - 1, 6, (60, 110, 240, 255), (200, 220, 255, 255))
		d.rectangle([c + 3, c + 2, c + 9, c + 4], fill=white)
		d.rectangle([c + 5, c, c + 7, c + 6], fill=white)
	elif aura == "swarog_ember":
		flame(d, c, c + 1, 10, (240, 90, 30, 255), (255, 220, 90, 255))
	elif aura == "marzanna_frost":
		snowflake(d, c - 0.5, c - 0.5, 9, (220, 245, 255, 255))
	elif aura == "perun_sparks":
		yellow = (255, 240, 120, 255)
		bolt(d, [(c - 6, c - 8), (c - 2, c - 2), (c - 5, c - 1), (c - 1, c + 6)], yellow, 2)
		bolt(d, [(c + 4, c - 8), (c + 7, c - 3), (c + 4, c - 2), (c + 7, c + 4)], yellow, 2)
		for x, y in ((c - 8, c + 3), (c + 1, c - 6), (c + 2, c + 7), (c + 8, c)):
			d.point((x, y), fill=white)
	elif aura == "perun_wrath":
		cloud = (120, 120, 150, 255)
		for x, y, r in ((c - 5, c - 6, 4), (c, c - 8, 5), (c + 5, c - 6, 4)):
			d.ellipse([x - r, y - r, x + r, y + r], fill=cloud)
		d.polygon([(c + 1, c - 4), (c - 4, c + 3), (c, c + 3), (c - 3, c + 10), (c + 5, c), (c + 1, c), (c + 4, c - 4)],
				fill=(255, 235, 90, 255))
	elif aura == "frost_breath":
		col = (190, 235, 255, 255)
		for k in range(3):
			r = 3 + k * 3
			d.arc([c - r, c - r, c + r - 1, c + r - 1], 40 + k * 90, 300 + k * 90, fill=col, width=2 if k else 1)
		for x, y in ((c - 8, c - 7), (c + 7, c - 5), (c - 6, c + 7), (c + 6, c + 7), (c, c)):
			d.point((x, y), fill=white)
	return img.resize((S * 2, S * 2), Image.NEAREST)


if __name__ == "__main__":
	for aura in COLORS:
		path = OUT / f"aura_{aura}.png"
		draw(aura).save(path)
		print(path.relative_to(ROOT))
