class_name Pinnacles
## Bossowie szczytowi Mapy Nawii (jak pinnacle w Path of Exile): słowiańscy bogowie - Weles, Marzanna, Czarnobóg.
## Strażnicy węzłów Nawii (Dungeon._on_boss_died) czasem zostawiają fragment klucza boga (fragment_chance; który bóg -
## według obszaru węzła, GODS "areas"). FRAGMENTS fragmentów otwiera arenę boga z okna Mapy Nawii (NawiaWindow):
## loch z dwiema komnatami - wejście i wielka arena (Dungeon._plan_arena), bez mechanik, bożków i zwykłych potworów,
## tylko bóg (PinnacleBoss, scena scenes/pinnacle_<bóg>.tscn) na poziomie GODS "level".
## Nagrody: pierwsze pokonanie każdego boga - FIRST_KILL_POINTS punktów Watry (Boons.pinnacle_kills), za każdym razem
## serce boga (waluta: HEART_COST serc wymienia się w oknie Mapy Nawii na jedną z jego legend), szansa na jego
## legendy (PinnacleBoss.legendary_drops) i bogaty skarbiec (vault_rewards).

## bóg -> nazwa, klimat lochu (wygląd areny), poziom, kolor, obszary Mapy Nawii, z których wypadają jego fragmenty,
## legendy.
const GODS := {
	"weles": {"name": "Weles, Pan Nawii", "climate": "roots", "level": 92, "color": Color(0.45, 0.95, 0.4),
			"areas": ["forest", "swamp"], "legends": ["legend_weles_staff", "legend_weles_hide"]},
	"marzanna": {"name": "Marzanna, Pani Zimy", "climate": "flooded", "level": 93, "color": Color(0.6, 0.85, 1.0),
			"areas": ["fields", "mountains"], "legends": ["legend_marzanna_wreath", "legend_marzanna_robe"]},
	"czarnobog": {"name": "Czarnobóg, Czarny Bóg", "climate": "catacombs", "level": 95, "color": Color(0.7, 0.45, 1.0),
			"areas": ["ancient", "cemetery"], "legends": ["legend_czarnobog_sword", "legend_czarnobog_helm"]},
}
const ORDER: Array[String] = ["weles", "marzanna", "czarnobog"]
## Rodzaj potwora (World.scene_for) i przedmioty: fragment klucza i serce boga.
const KIND_PREFIX := "pinnacle_"
const FRAGMENT_PREFIX := "pinnacle_fragment_"
const HEART_PREFIX := "pinnacle_heart_"
## Ile fragmentów otwiera arenę i ile serc kosztuje legenda boga.
const FRAGMENTS := 4
const HEART_COST := 3
## Szansa na fragment ze strażnika węzła Nawii: na stopniu 8 i przyrost za każdy stopień wyżej (stopień 17 - 46%).
const FRAGMENT_BASE := 0.1
const FRAGMENT_PER_TIER := 0.04
## Punkty Watry za pierwsze pokonanie każdego boga.
const FIRST_KILL_POINTS := 3
## Stopień lochu areny (poziom potworów bierze się z GODS "level").
const ARENA_TIER := 17


static func kind(god: String) -> String:
	return KIND_PREFIX + god


static func fragment(god: String) -> String:
	return FRAGMENT_PREFIX + god


static func heart(god: String) -> String:
	return HEART_PREFIX + god


static func god_name(god: String) -> String:
	return Lang.t(GODS[god]["name"]) if GODS.has(god) else ""


## Bóg, którego fragmenty wypadają w obszarze Mapy Nawii ("" - żaden).
static func god_of_area(area: String) -> String:
	for god: String in ORDER:
		if area in (GODS[god]["areas"] as Array):
			return god
	return ""


static func fragment_chance(tier: int) -> float:
	return FRAGMENT_BASE + FRAGMENT_PER_TIER * maxi(tier - 8, 0)


## Punkty Watry z pokonanych bogów (Boons.pinnacle_kills: bóg -> liczba zwycięstw).
static func points(kills: Dictionary) -> int:
	var total := 0
	for god: String in kills:
		if GODS.has(god) and int(kills[god]) > 0:
			total += FIRST_KILL_POINTS
	return total


## Ustawienia wyprawy na arenę boga (Dungeons.config z kluczem "pinnacle"; bez mechanik, bożków i ołtarza).
static func config(god: String, seed_value: int, tree := {}) -> Dictionary:
	var settings := Dungeons.config(GODS[god]["climate"], ARENA_TIER, [], seed_value, [])
	settings["pinnacle"] = god
	settings["mechanics"] = []
	settings["altar"] = false
	settings["tree"] = tree.duplicate()
	return settings


## Skarbiec po pokonaniu boga: [przedmiot, liczba] - przedmioty (część rzadkich), runy, kamienie, bożek, kamień
## szlachetny. Złoto i legendy daje sam bóg (Boss._drop_loot).
static func vault_rewards(level: int, rng: RandomNumberGenerator) -> Array:
	var rewards: Array = []
	for i in 6:
		rewards.append([Loot.drop_at_level(level, 0.4, Loot.MAGIC, 2), 1])
	for i in 3:
		rewards.append([Loot.drop_at_level(level, 0.6, Loot.RARE, 3), 1])
	for i in rng.randi_range(2, 3):
		rewards.append([ItemCraft.roll_rune(Dungeons.BASE_TIERS, rng), 1])
	rewards.append(["blessed_stone", rng.randi_range(3, 6)])
	rewards.append([Idols.roll(rng), 1])
	if Gems.unlocked:
		rewards.append([Gems.roll("", Gems.CUTS.size() - 1), 1])
	return rewards
