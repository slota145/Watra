class_name Levels
## Poziomy potworów - wspólna miara balansu. Każda kraina ma zakres poziomów: tuż przy jej wejściu (w lesie
## przy Ostoi) potwory mają najniższy poziom, a im dalej, tym wyższy; bossowie są ponad zakresem.
##
## Statystyki biorą się z jednej krzywej "zwykłego potwora" na danym poziomie (zdrowie, obrażenia,
## doświadczenie, złoto - HEALTH/DAMAGE/XP/GOLD_CURVE), pomnożonej przez siłę typu względem zwykłego potwora
## jego krainy (scena: osiłek ma 4x zdrowia goblina, drzewiec 2,2x pająka itd.). Dzięki temu krainy są
## spójne (dawniej pająki Prastarego Lasu były słabsze od ptakoludzi z gór), a symulacja balansu
## (tests/balance_sim.gd) może sprawdzać jedną miarę: ile ciosów potrzebuje typowy gracz danego etapu.
## Z poziomu wynikają też poziom wypadających przedmiotów i szanse na kamienie (doskonałe, uświęcone
## i miłosierdzia dopiero od wyższych poziomów); za potwory dużo słabsze od gracza jest mniej doświadczenia.

## kraina: [poziom przy wejściu, poziom w najdalszym zakątku, poziom bossów]
const ZONES := {
	"forest": [1, 7, 9],
	"fields": [7, 14, 16],
	"swamp": [9, 16, 18],
	"mountains": [16, 24, 26],
	"ancient": [23, 32, 34],
	"cemetery": [32, 40, 42],
}
## Zwykły potwór każdej krainy - wzorzec siły typów (statystyki jego sceny): [zdrowie, obrażenia, xp, złoto średnio].
const REFERENCE := {
	"forest": [40.0, 12.0, 11.0, 2.5],
	"fields": [70.0, 13.0, 14.0, 6.5],
	"swamp": [100.0, 17.0, 55.0, 7.0],
	"mountains": [230.0, 26.0, 120.0, 12.0],
	"ancient": [120.0, 18.0, 85.0, 9.0],
	"cemetery": [140.0, 20.0, 95.0, 10.0],
}
## Kraina, z której pochodzi scena potwora (wg nazwy pliku) - jej wzorzec mierzy siłę typu.
const HOME := {
	"goblin": "forest", "goblin_archer": "forest", "goblin_brute": "forest", "wolf": "forest", "warg": "forest",
	"goblin_chief": "forest", "alpha_wolf": "forest",
	"frogman": "swamp", "frog_spitter": "swamp", "drowner": "swamp", "rusalka": "swamp", "wisp": "swamp",
	"frog_chief": "swamp", "wodnik": "swamp",
	"birdman": "mountains", "birdman_thrower": "mountains", "birdman_shaman": "mountains", "satyr": "mountains",
	"satyr_piper": "mountains", "satyr_brute": "mountains", "storm_eagle": "mountains",
	"spider": "ancient", "web_spider": "ancient", "spiderling": "ancient", "cocoon": "ancient", "treant": "ancient",
	"ancient_tree": "ancient", "beast_bear": "ancient", "beast_werewolf": "ancient", "spider_queen": "ancient",
	"leshy": "ancient", "bies": "ancient",
	"kobold": "fields", "kobold_slinger": "fields", "kobold_bomber": "fields", "field_worm": "fields",
	"kobold_bombardier": "fields", "giant_worm": "fields",
	"skeleton": "cemetery", "skeleton_archer": "cemetery", "skeleton_knight": "cemetery", "ghoul": "cemetery",
	"zombie": "cemetery", "necromancer": "cemetery", "colossal_ghoul": "cemetery",
}
## Krzywe zwykłego potwora: zdrowie i obrażenia rosną liniowo (jak obrażenia i zdrowie gracza z poziomu,
## przedmiotów i zaklęć), doświadczenie i złoto wolniej niż potrzebne doświadczenie gracza.
const HEALTH_BASE := 60.0
const HEALTH_GROWTH := 0.13
const DAMAGE_BASE := 13.0
const DAMAGE_GROWTH := 0.1
const XP_BASE := 11.0
const XP_POWER := 0.7
const GOLD_BASE := 1.0
const GOLD_POWER := 0.7
## Siła bossa (zdrowie) względem zwykłego potwora - mieści się w tych granicach niezależnie od sceny.
const BOSS_HEALTH := Vector2(10.0, 14.0)
## Przedmioty: poziom potwora -1 ... +2.
const ITEM_LEVEL_SPREAD := Vector2i(-1, 2)

## Poziom stosowany, gdy potwór nie dostał go od świata (np. przywołany przez bossa) - ustawia świat.
static var zone_default := 1


static func level_at(zone: String, distance_fraction: float) -> int:
	var range: Array = ZONES.get(zone, [1, 1, 1])
	return roundi(lerpf(range[0], range[1], clampf(distance_fraction, 0.0, 1.0)))


static func boss_level(zone: String) -> int:
	return ZONES.get(zone, [1, 1, 1])[2]


## Wzorzec krainy sceny: [zdrowie, obrażenia, xp, złoto] zwykłego potwora, z którym porównujemy scenę.
static func reference_of(scene_path: String) -> Array:
	return REFERENCE[HOME.get(scene_path.get_file().get_basename(), "forest")]


static func health(level: int) -> float:
	return HEALTH_BASE * (1.0 + HEALTH_GROWTH * (level - 1))


static func damage(level: int) -> float:
	return DAMAGE_BASE * (1.0 + DAMAGE_GROWTH * (level - 1))


static func xp(level: int) -> float:
	return XP_BASE * pow(level, XP_POWER)


static func gold(level: int) -> float:
	return GOLD_BASE * pow(level, GOLD_POWER)


static func item_level(level: int) -> int:
	return clampi(level + randi_range(ITEM_LEVEL_SPREAD.x, ITEM_LEVEL_SPREAD.y), 1, Loot.MAX_ITEM_LEVEL)


## Szanse na kamienie z jednego zwykłego potwora: [zwykły, doskonały, uświęcone, miłosierdzia].
static func stone_chances(level: int) -> Array[float]:
	var normal := 0.012 + 0.0008 * level
	var perfect := 0.0 if level < 18 else 0.002 + 0.0002 * (level - 18)
	var blessed := 0.0 if level < 14 else 0.03 + 0.002 * (level - 14)
	var mercy := 0.0 if level < 14 else 0.02 + 0.001 * (level - 14)
	return [normal, perfect, blessed, mercy]


## Ułamek doświadczenia za potwora: pełne do 3 poziomów poniżej gracza, potem po 15% mniej na poziom (min. 10%).
static func xp_fraction(player_level: int, enemy_level: int) -> float:
	return clampf(1.0 - 0.15 * (player_level - enemy_level - 3), 0.1, 1.0)
