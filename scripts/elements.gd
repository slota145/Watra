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
