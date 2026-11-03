"""Ikony bożków (scripts/idols.gd): rzeźbiony słup z twarzą (jak Światowid) w trzech materiałach według rzadkości
(glina - zwykły, ciemne drewno - rzadki, złoto - legendarny) i z żarzącym się kamieniem na piersi w kolorze rodzaju.
Rysuje w siatce 32x32 i powiększa dwa razy (piksele 2x2 jak w innych ikonach 64 px).

Uruchom: python tools/idol_art.py   (wynik: assets/items/idols/<rodzaj>_<rzadkość>.png)
Rodzaje i kolory muszą zgadzać się z Idols.KINDS w scripts/idols.gd."""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "items", "idols")
SIZE = 32

# materiał: (cień, środek, światło, kontur)
MATERIALS = {
	"common": ((104, 62, 40), (150, 92, 58), (190, 128, 84), (46, 26, 18)),
	"rare": ((58, 40, 34), (92, 64, 50), (128, 94, 72), (24, 15, 12)),
	"legendary": ((150, 98, 24), (214, 160, 48), (252, 222, 120), (72, 42, 10)),
}
# kolor kamienia na piersi dla każdego rodzaju bożka
KINDS = {
	"chests": (230, 170, 70), "shrine": (120, 220, 255), "crystal": (255, 120, 50), "elites": (230, 80, 230),
	"uroczysko": (150, 255, 200), "zertwa": (220, 40, 40), "skarbnik": (255, 220, 60),
	"horde": (200, 210, 90), "fury": (255, 70, 30),
	"gold": (255, 200, 40), "items": (110, 150, 255), "runes": (180, 200, 230), "gems": (60, 230, 120),
	"legends": (255, 150, 30),
	"pride": (160, 40, 200), "gloom": (90, 90, 200),
}


def body_width(y: int) -> float:
	"""Połowa szerokości słupa w rzędzie y (0 - góra): czapa, głowa, tułów, podstawa."""
	if y < 3:
		return 0
	if y < 6:  # kolista czapa
		return 4.5 + (y - 3) * 1.2
	if y < 7:
		return 7.5  # rondo czapy
	if y < 15:
		return 5.5  # głowa
	if y < 16:
		return 6.5  # broda / szyja
	if y < 26:
		return 6.0 + (y - 16) * 0.12  # tułów lekko rozszerzony
	if y < 29:
		return 9.0  # podstawa
	return 0


def draw(material: tuple, gem: tuple) -> Image.Image:
	shadow, mid, light, outline = material
	img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	px = img.load()
	cx = 15.5
	inside = set()
	for y in range(SIZE):
		half = body_width(y)
		for x in range(SIZE):
			if half > 0 and abs(x - cx) <= half:
				inside.add((x, y))
	for (x, y) in inside:
		half = body_width(y)
		t = (x - (cx - half)) / (2 * half)  # 0 - lewa krawędź (światło), 1 - prawa (cień)
		color = light if t < 0.3 else mid if t < 0.72 else shadow
		px[x, y] = color + (255,)
	# kontur
	for (x, y) in inside:
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			if (x + dx, y + dy) not in inside and 0 <= x + dx < SIZE and 0 <= y + dy < SIZE:
				px[x + dx, y + dy] = outline + (255,)
	# rzeźbione linie: rondo czapy, broda, pas, podstawa
	for y in (6, 15, 22, 26):
		for x in range(SIZE):
			if (x, y) in inside and px[x, y][:3] != outline:
				r, g, b, _ = px[x, y]
				px[x, y] = (int(r * 0.7), int(g * 0.7), int(b * 0.7), 255)
	# twarz: brwi, oczy (żarzą się kolorem rodzaju), nos, usta
	for x in (12, 13, 18, 19):
		px[x, 8] = outline + (255,)
	for x in (12, 13):
		px[x, 10] = gem + (255,)
	for x in (18, 19):
		px[x, 10] = gem + (255,)
	px[15, 11] = shadow + (255,)
	px[16, 11] = shadow + (255,)
	px[15, 12] = shadow + (255,)
	px[16, 12] = outline + (255,)
	for x in range(13, 19):
		px[x, 14] = outline + (255,)
	# ręce wyrzeźbione na tułowiu, dłonie trzymają kamień
	for y in range(17, 21):
		px[10, y] = outline + (255,)
		px[21, y] = outline + (255,)
	for x in range(11, 14):
		px[x, 21] = outline + (255,)
	for x in range(18, 21):
		px[x, 21] = outline + (255,)
	# kamień na piersi (romb) z odblaskiem
	dark = tuple(int(c * 0.55) for c in gem)
	bright = tuple(min(255, int(c * 0.5 + 140)) for c in gem)
	for dy in range(-2, 3):
		for dx in range(-2 + abs(dy), 3 - abs(dy)):
			x, y = 15 + dx + (1 if dx >= 0 else 0), 19 + dy
			px[x, y] = (gem if abs(dx) + abs(dy) < 2 else dark) + (255,)
	px[15, 18] = bright + (255,)
	# poświata wokół kamienia (półprzezroczysta, tylko na tle)
	return img.resize((SIZE * 2, SIZE * 2), Image.NEAREST)


def main() -> None:
	os.makedirs(OUT, exist_ok=True)
	for kind, gem in KINDS.items():
		for rarity, material in MATERIALS.items():
			draw(material, gem).save(os.path.join(OUT, f"{kind}_{rarity}.png"))
	print(f"Zapisano {len(KINDS) * len(MATERIALS)} ikon w {OUT}")


if __name__ == "__main__":
	main()
