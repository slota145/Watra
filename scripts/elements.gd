class_name Elements
## Rodzaje obrażeń zadawanych graczowi i odporności na nie (etap 1 żywiołów, listopad 2026). Fizyczne osłabia pancerz,
## żywioły (ogień, lód, pioruny) i Nawię (zgnilizna, jad, moc zaświatów - jak chaos w Path of Exile) - odporność
## gracza z przedmiotów (CharacterStats.resistance), a pancerz tylko w ARMOR_SHARE. Siła zmniejsza wszystkie.
## W lochach Mapy Nawii odporności spadają (penalty): stopień 8 o 20%, najwyższy o 60% - bez odporności z przedmiotów
## gracz dostaje tam więcej niż pełne obrażenia, z odpornościami na sufit (MAX_RESISTANCE) - ćwierć.
## Potwory biją swoim żywiołem (MONSTERS wg sceny, Goblin.element); szczególne ataki podają żywioł same.

const PHYSICAL := "physical"
const FIRE := "fire"
const COLD := "cold"
const LIGHTNING := "lightning"
const NAWIA := "nawia"
## Żywioły z odpornością (premia "<żywioł>_resistance"); trzy pierwsze podnosi też "all_resistances".
const RESISTED: Array[String] = [FIRE, COLD, LIGHTNING, NAWIA]
const ELEMENTAL: Array[String] = [FIRE, COLD, LIGHTNING]
const NAMES := {PHYSICAL: "Fizyczne", FIRE: "Ogień", COLD: "Lód", LIGHTNING: "Pioruny", NAWIA: "Nawia"}
const COLORS := {PHYSICAL: Color(1.0, 0.35, 0.3), FIRE: Color(1.0, 0.55, 0.2), COLD: Color(0.55, 0.85, 1.0),
		LIGHTNING: Color(1.0, 0.95, 0.45), NAWIA: Color(0.65, 0.95, 0.45)}
## Najwyższa i najniższa odporność.
const MAX_RESISTANCE := 0.75
const MIN_RESISTANCE := -1.0
## Ile ochrony pancerza działa na żywioły i Nawię (fizyczne - całość).
const ARMOR_SHARE := 0.5
## Kara do odporności na Mapie Nawii: [na pierwszym stopniu Nawii, na najwyższym]; areny bogów - najwyższa.
const NAWIA_PENALTY := Vector2(0.2, 0.6)
const NAWIA_FIRST_TIER := 8
const NAWIA_LAST_TIER := 17

## Żywioł zwykłego ataku potwora (nazwa sceny); brak - fizyczne.
const MONSTERS := {
	"frog_spitter": NAWIA, "drowner": COLD, "rusalka": COLD, "wisp": FIRE, "wodnik": COLD,
	"birdman_shaman": LIGHTNING, "satyr_piper": LIGHTNING, "storm_eagle": LIGHTNING,
	"spider": NAWIA, "web_spider": NAWIA, "spiderling": NAWIA, "spider_queen": NAWIA, "leshy": NAWIA, "bies": FIRE,
	"kobold_bomber": FIRE, "kobold_bombardier": FIRE,
	"zombie": NAWIA, "necromancer": NAWIA, "hydra": NAWIA, "gryf": LIGHTNING,
	"world_boss_zmij": FIRE, "world_boss_wij": NAWIA,
	"pinnacle_weles": NAWIA, "pinnacle_marzanna": COLD, "pinnacle_czarnobog": NAWIA, "pinnacle_horde": NAWIA,
}

## Odporności potworów (etap 2): ułamek zmniejszający obrażenia od żywiołu i Nawii zadawane przez gracza; ujemny -
## wrażliwość. Umiarkowane (najwyżej +50%), żeby mag jednego żywiołu nie był bezradny w żadnej krainie; przebicie
## odporności z przedmiotów (CharacterStats.penetration) je zmniejsza. Brak wpisu - bez odporności.
const UNDEAD := {COLD: 0.3, NAWIA: 0.4, FIRE: -0.25}
const ROTTEN := {NAWIA: 0.4, FIRE: -0.3}
const WOOD := {FIRE: -0.4, COLD: 0.2}
const SPIDER := {NAWIA: 0.3, FIRE: -0.25}
const WATER := {COLD: 0.3, LIGHTNING: -0.3}
const STORM := {LIGHTNING: 0.3, COLD: -0.2}
const KOBOLD := {FIRE: 0.2, COLD: -0.2}
const MONSTER_RESIST := {
	"skeleton": UNDEAD, "skeleton_archer": UNDEAD, "skeleton_knight": UNDEAD, "necromancer": UNDEAD,
	"zombie": ROTTEN, "ghoul": ROTTEN, "colossal_ghoul": ROTTEN,
	"treant": WOOD, "ancient_tree": WOOD, "cocoon": WOOD, "leshy": {NAWIA: 0.3, FIRE: -0.3},
	"spider": SPIDER, "web_spider": SPIDER, "spiderling": SPIDER, "spider_queen": SPIDER,
	"beast_bear": {COLD: 0.2}, "beast_werewolf": {COLD: 0.2, NAWIA: 0.2},
	"frogman": WATER, "frog_spitter": WATER, "frog_chief": WATER, "rusalka": WATER,
	"drowner": {COLD: 0.4, LIGHTNING: -0.3}, "wodnik": {COLD: 0.5, LIGHTNING: -0.3},
	"wisp": {FIRE: 0.5, COLD: -0.3},
	"birdman": STORM, "birdman_thrower": STORM, "birdman_shaman": {LIGHTNING: 0.4, COLD: -0.2},
	"storm_eagle": {LIGHTNING: 0.5, COLD: -0.2}, "gryf": {LIGHTNING: 0.4, COLD: -0.2},
	"satyr": {COLD: -0.2}, "satyr_piper": {COLD: -0.2, LIGHTNING: 0.2}, "satyr_brute": {COLD: -0.2}, "satyr_king": {COLD: -0.2, NAWIA: 0.2},
	"kobold": KOBOLD, "kobold_slinger": KOBOLD, "kobold_bomber": {FIRE: 0.4, COLD: -0.2}, "kobold_bombardier": {FIRE: 0.4, COLD: -0.2},
	"field_worm": {FIRE: -0.2, LIGHTNING: 0.2}, "giant_worm": {FIRE: -0.2, LIGHTNING: 0.2},
	"bies": {FIRE: 0.5, COLD: -0.3}, "hydra": {NAWIA: 0.4, FIRE: -0.2},
	"world_boss_zmij": {FIRE: 0.5, COLD: -0.25}, "world_boss_wij": {NAWIA: 0.4, FIRE: -0.25},
	"pinnacle_weles": {NAWIA: 0.4, LIGHTNING: 0.2}, "pinnacle_marzanna": {COLD: 0.5, FIRE: -0.25},
	"pinnacle_czarnobog": {NAWIA: 0.5, FIRE: -0.15}, "pinnacle_horde": {FIRE: 0.2, COLD: 0.2, LIGHTNING: 0.2, NAWIA: 0.2},
}
## Żywioł trafienia gracza wg rodzaju odgłosu (Player.hit_enemy, sound) - reszta to obrażenia fizyczne / tajemne.
const SOUND_ELEMENTS := {"fire": FIRE, "ice": COLD, "lightning": LIGHTNING}
## Premia do obrażeń umiejętności z tagiem żywiołu (Skills.TAGS) - "elemental_damage" działa na wszystkie trzy.
const TAG_DAMAGE := {"fire": "fire_damage", "ice": "cold_damage", "lightning": "lightning_damage"}
## Najwyższa odporność potwora po przebiciu (ułamek) - pełnej odporności nie ma nigdy.
const MAX_MONSTER_RESISTANCE := 0.9


## Odporności potwora danej sceny {żywioł: ułamek}.
static func monster_resistances(scene_id: String) -> Dictionary:
	return MONSTER_RESIST.get(scene_id, {})


## Mnożnik obrażeń gracza od żywiołu przy odporności potwora `resist` i przebiciu `penetration`.
static func hit_multiplier(resist: float, penetration: float) -> float:
	return 1.0 - clampf(resist - penetration, MIN_RESISTANCE, MAX_MONSTER_RESISTANCE)


## Kara do odporności w bieżącym miejscu (ustawia świat przy wejściu: 0 w krainach i zwykłych lochach).
static var penalty := 0.0


## Kara do odporności w lochu danego stopnia (0 poniżej Mapy Nawii, liniowo do NAWIA_PENALTY.y).
static func penalty_for_tier(tier: int) -> float:
	if tier < NAWIA_FIRST_TIER:
		return 0.0
	var t := clampf(float(tier - NAWIA_FIRST_TIER) / (NAWIA_LAST_TIER - NAWIA_FIRST_TIER), 0.0, 1.0)
	return lerpf(NAWIA_PENALTY.x, NAWIA_PENALTY.y, t)


static func of_monster(scene_id: String) -> String:
	return MONSTERS.get(scene_id, PHYSICAL)


static func name_of(element: String) -> String:
	return Lang.t(NAMES.get(element, NAMES[PHYSICAL]))


static func color_of(element: String) -> Color:
	return COLORS.get(element, COLORS[PHYSICAL])
