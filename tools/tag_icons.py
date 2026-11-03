"""Ikonki tagów umiejętności (Skills.TAG_NAMES): rysowane w kodzie, 16x16 px powiększone 4x do 64x64.

Każdy tag to prosty symbol w kolorze swojej grupy (rodzaj, forma) albo żywiołu / atrybutu (kolory jak
Skills.TAG_COLORS), z ciemnym obrysem, żeby był czytelny na każdym tle dymka.
Wynik: assets/ui/tags/<tag>.png (w grze: [img=8x8] w opisach umiejętności - Skills.tags_bbcode).

Uruchom: python tools/tag_icons.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "ui" / "tags"
SIZE = 16
SCALE = 4
OUTLINE = (26, 28, 43, 255)

KIND = (240, 200, 110, 255)
FORM = (190, 205, 225, 255)
COLORS = {
	"physical": (216, 203, 176, 255), "fire": (255, 138, 61, 255), "ice": (143, 216, 255, 255),
	"lightning": (255, 228, 92, 255), "poison": (143, 220, 90, 255), "arcane": (199, 155, 255, 255),
	"dot": (224, 112, 112, 255), "str": (255, 122, 106, 255), "dex": (127, 224, 138, 255), "int": (127, 178, 255, 255),
}


def attack(d, c):
	d.line([(3, 12), (11, 4)], fill=c, width=2)
	d.line([(5, 8), (8, 11)], fill=c, width=1)
	d.point([(2, 13), (12, 3)], fill=c)


def spell(d, c):
	d.polygon([(8, 2), (9, 7), (14, 8), (9, 9), (8, 14), (7, 9), (2, 8), (7, 7)], fill=c)


def cry(d, c):
	d.ellipse([2, 6, 5, 9], fill=c)
	for r in (4, 7):
		d.arc([5 - r + 2, 8 - r, 5 + r, 8 + r], -50, 50, fill=c, width=1)


def aura(d, c):
	d.ellipse([3, 3, 12, 12], outline=c, width=1)
	d.ellipse([6, 6, 9, 9], fill=c)
	for x, y in ((7, 0), (7, 14), (0, 7), (14, 7)):
		d.rectangle([x, y, x + 1, y + 1], fill=c)


def hit(d, c):
	for a, b in (((7, 1), (7, 5)), ((7, 10), (7, 14)), ((1, 7), (5, 7)), ((10, 7), (14, 7)),
			((3, 3), (5, 5)), ((10, 10), (12, 12)), ((12, 3), (10, 5)), ((3, 12), (5, 10))):
		d.line([a, b], fill=c, width=1)
	d.rectangle([7, 7, 8, 8], fill=c)


def projectile(d, c):
	d.line([(2, 8), (12, 8)], fill=c, width=1)
	d.polygon([(14, 8), (10, 5), (10, 11)], fill=c)
	d.line([(2, 5), (4, 8)], fill=c)
	d.line([(2, 11), (4, 8)], fill=c)


def area(d, c):
	d.ellipse([1, 1, 14, 14], outline=c, width=1)
	d.ellipse([4, 4, 11, 11], outline=c, width=1)
	d.ellipse([7, 7, 8, 8], fill=c)


def summon(d, c):
	d.ellipse([6, 1, 10, 5], fill=c)
	d.polygon([(8, 6), (12, 14), (4, 14)], fill=c)


def movement(d, c):
	for x in (2, 8):
		d.line([(x, 3), (x + 4, 8), (x, 13)], fill=c, width=2)


def physical(d, c):
	for x in (3, 7, 11):
		d.line([(x, 13), (x + 3, 3)], fill=c, width=1)


def fire(d, c):
	d.polygon([(8, 1), (12, 7), (12, 11), (10, 14), (6, 14), (4, 11), (4, 8), (6, 9), (7, 5)], fill=c)
	d.polygon([(8, 8), (10, 11), (9, 13), (7, 13), (6, 11)], fill=(255, 230, 140, 255))


def ice(d, c):
	d.line([(8, 1), (8, 14)], fill=c)
	d.line([(2, 4), (13, 11)], fill=c)
	d.line([(2, 11), (13, 4)], fill=c)
	for x, y in ((6, 2), (9, 2), (6, 13), (9, 13)):
		d.point((x, y), fill=c)


def lightning(d, c):
	d.polygon([(10, 1), (4, 9), (8, 9), (5, 15), (12, 6), (8, 6)], fill=c)


def poison(d, c):
	d.polygon([(7, 2), (11, 8), (7, 8)], fill=c)
	d.ellipse([3, 6, 11, 14], fill=c)
	d.ellipse([11, 2, 13, 4], outline=c)


def arcane(d, c):
	d.polygon([(8, 1), (14, 8), (8, 14), (2, 8)], outline=c)
	d.polygon([(8, 4), (11, 8), (8, 11), (5, 8)], fill=c)


def dot(d, c):
	d.polygon([(3, 2), (12, 2), (8, 7), (12, 13), (3, 13), (7, 7)], outline=c)
	d.polygon([(5, 12), (10, 12), (8, 9)], fill=c)
	d.line([(3, 1), (12, 1)], fill=c)
	d.line([(3, 14), (12, 14)], fill=c)


def strength(d, c):
	d.rectangle([3, 2, 12, 6], fill=c)
	d.rectangle([7, 7, 8, 14], fill=c)


def dexterity(d, c):
	d.polygon([(13, 1), (10, 9), (4, 12), (5, 7)], fill=c)
	d.line([(2, 14), (8, 7)], fill=c)


def intelligence(d, c):
	d.polygon([(1, 8), (5, 4), (11, 4), (15, 8), (11, 12), (5, 12)], fill=c)
	d.ellipse([6, 5, 10, 11], fill=OUTLINE)
	d.rectangle([7, 7, 8, 8], fill=c)


ICONS = {
	"attack": (attack, KIND), "spell": (spell, KIND), "cry": (cry, KIND), "aura": (aura, KIND),
	"hit": (hit, FORM), "projectile": (projectile, FORM), "area": (area, FORM), "summon": (summon, FORM),
	"movement": (movement, FORM),
	"physical": (physical, COLORS["physical"]), "fire": (fire, COLORS["fire"]), "ice": (ice, COLORS["ice"]),
	"lightning": (lightning, COLORS["lightning"]), "poison": (poison, COLORS["poison"]),
	"arcane": (arcane, COLORS["arcane"]), "dot": (dot, COLORS["dot"]),
	"str": (strength, COLORS["str"]), "dex": (dexterity, COLORS["dex"]), "int": (intelligence, COLORS["int"]),
}


def outlined(img: Image.Image) -> Image.Image:
	"""Ciemny obrys 1 px wokół symbolu (także po skosie)."""
	out = Image.new("RGBA", img.size, (0, 0, 0, 0))
	src = img.load()
	dst = out.load()
	for y in range(SIZE):
		for x in range(SIZE):
			if src[x, y][3] > 0:
				continue
			for dx in (-1, 0, 1):
				for dy in (-1, 0, 1):
					nx, ny = x + dx, y + dy
					if 0 <= nx < SIZE and 0 <= ny < SIZE and src[nx, ny][3] > 0 and src[nx, ny] != OUTLINE:
						dst[x, y] = OUTLINE
	out.alpha_composite(img)
	return out


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	for tag, (draw, colour) in ICONS.items():
		img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
		draw(ImageDraw.Draw(img), colour)
		img = outlined(img).resize((SIZE * SCALE, SIZE * SCALE), Image.NEAREST)
		img.save(OUT / f"{tag}.png")
	print(f"{len(ICONS)} ikonek w {OUT}")


if __name__ == "__main__":
	main()
