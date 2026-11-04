class_name Pinnacles
## Bossowie szczytowi Mapy Nawii (jak pinnacle w Path of Exile): słowiańscy bogowie - Weles, Marzanna, Czarnobóg.
## Strażnicy węzłów Nawii (Dungeon._on_boss_died) czasem zostawiają fragment klucza boga (fragment_chance; który bóg -
## według obszaru węzła, GODS "areas"). FRAGMENTS fragmentów otwiera arenę boga z okna Mapy Nawii (NawiaWindow):
## loch z dwiema komnatami - wejście i wielka arena (Dungeon._plan_arena), bez mechanik, bożków i zwykłych potworów,
## tylko bóg (PinnacleBoss, scena scenes/pinnacle_<bóg>.tscn) na poziomie GODS "level".
## Nagrody: pierwsze pokonanie każdego boga - FIRST_KILL_POINTS punktów Watry (Boons.pinnacle_kills), za każdym razem
## serce boga (waluta: HEART_COST serc wymienia się w oknie Mapy Nawii na jedną z jego legend), szansa na jego
## legendy (PinnacleBoss.legendary_drops) i bogaty skarbiec (vault_rewards).
## Władca Hordy (LORD, HordeLord - ostateczny boss): wejście za serce każdego z trzech bogów (LORD_COST), arena
## w Kopalni goblinów; 4 fazy, w kolejnych przyzywa cienie bogów, na końcu fale Hordy. Pierwsze zwycięstwo -
## LORD_POINTS punktów Watry, tytuł „Pogromca Hordy” i posąg w Ostoi; każde zwycięstwo odblokowuje kolejny stopień
## Pomroku (POMROK_*) - trudniejszą i hojniejszą wersję wszystkich aren (bogów i Władcy).

## bóg -> nazwa, klimat lochu (wygląd areny), poziom, kolor, obszary Mapy Nawii, z których wypadają jego fragmenty,
## legendy i bardzo rzadki pas (Weles - mikstury bez końca, Czarnobóg - cechy zabitych elit; BELT_CHANCE, BELT_COST).
const GODS := {
	"weles": {"name": "Weles, Pan Nawii", "climate": "roots", "level": 92, "color": Color(0.45, 0.95, 0.4),
			"areas": ["forest", "swamp"], "legends": ["legend_weles_staff", "legend_weles_hide"], "belt": "legend_weles_belt"},
	"marzanna": {"name": "Marzanna, Pani Zimy", "climate": "flooded", "level": 93, "color": Color(0.6, 0.85, 1.0),
			"areas": ["fields", "mountains"], "legends": ["legend_marzanna_wreath", "legend_marzanna_robe"],
			"belt": "legend_marzanna_belt"},
	"czarnobog": {"name": "Czarnobóg, Czarny Bóg", "climate": "catacombs", "level": 95, "color": Color(0.7, 0.45, 1.0),
			"areas": ["ancient", "cemetery"], "legends": ["legend_czarnobog_sword", "legend_czarnobog_helm"],
			"belt": "legend_czarnobog_belt"},
	"horde": {"name": "Władca Hordy", "climate": "mine", "level": 98, "color": Color(1.0, 0.35, 0.25),
			"areas": [], "legends": ["legend_horde_blade", "legend_horde_crown"], "lord": true},
}
## Trzej bogowie (fragmenty kluczy, cienie w walce z Władcą).
const ORDER: Array[String] = ["weles", "marzanna", "czarnobog"]
## Ostateczny boss - Władca Hordy.
const LORD := "horde"
## Ile serc każdego boga kosztuje wejście na arenę Władcy.
const LORD_COST := 1
## Punkty Watry za pierwsze pokonanie Władcy.
const LORD_POINTS := 5
## Pomrok - stopnie trudności aren po pokonaniu Władcy (Boons.pomrok_unlocked): na każdy stopień poziom potworów
## +POMROK_LEVEL, zdrowie +POMROK_HEALTH, obrażenia +POMROK_DAMAGE, skarbiec +POMROK_LOOT, szansa na legendy
## i pas boga +POMROK_DROP.
const POMROK_MAX := 10
const POMROK_LEVEL := 2
const POMROK_HEALTH := 0.2
const POMROK_DAMAGE := 0.1
const POMROK_LOOT := 0.25
const POMROK_DROP := 0.5
## Rodzaj potwora (World.scene_for) i przedmioty: fragment klucza i serce boga.
const KIND_PREFIX := "pinnacle_"
const FRAGMENT_PREFIX := "pinnacle_fragment_"
const HEART_PREFIX := "pinnacle_heart_"
## Ile fragmentów otwiera arenę i ile serc kosztuje legenda boga.
const FRAGMENTS := 4
const HEART_COST := 3
## Pas boga: szansa z każdego zwycięstwa i cena w sercach.
const BELT_CHANCE := 0.02
const BELT_COST := 10
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


static func is_lord(god: String) -> bool:
	return god == LORD


## Poziom potworów areny (bóg albo Władca) na danym stopniu Pomroku.
static func arena_level(god: String, pomrok := 0) -> int:
	return int(GODS[god]["level"]) + POMROK_LEVEL * pomrok


## Mnożniki Pomroku: "health", "damage", "loot" (skarbiec), "drop" (legendy i pas).
static func pomrok_mult(key: String, pomrok: int) -> float:
	var per: float = {"health": POMROK_HEALTH, "damage": POMROK_DAMAGE, "loot": POMROK_LOOT, "drop": POMROK_DROP}.get(key, 0.0)
	return 1.0 + per * pomrok


## Rzymska liczba stopnia Pomroku (I-X) do napisów.
static func roman(n: int) -> String:
	return ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"][clampi(n, 0, POMROK_MAX)]


## Czy gracz ma serca na wejście do Władcy (po LORD_COST serca każdego boga).
static func can_challenge_lord(inventory: Inventory) -> bool:
	for god: String in ORDER:
		if inventory.count_of(heart(god)) < LORD_COST:
			return false
	return true


## Zużywa serca bogów na wejście do Władcy (false - brak któregoś, nic nie zabrane).
static func pay_lord(inventory: Inventory) -> bool:
	if not can_challenge_lord(inventory):
		return false
	for god: String in ORDER:
		inventory.remove_item(heart(god), LORD_COST)
	return true


## Bóg, którego fragmenty wypadają w obszarze Mapy Nawii ("" - żaden).
static func god_of_area(area: String) -> String:
	for god: String in ORDER:
		if area in (GODS[god]["areas"] as Array):
			return god
	return ""


## Wymiana serc (okno Mapy Nawii): "legend" - jedna z legend boga, "belt" - jego pas. Zwraca id przedmiotu
## albo "" (brak pasa).
static func exchange_item(god: String, what: String) -> String:
	if what == "belt":
		return str(GODS[god].get("belt", ""))
	var legends: Array = GODS[god]["legends"]
	return legends[randi() % legends.size()]


static func exchange_cost(what: String) -> int:
	return BELT_COST if what == "belt" else HEART_COST


static func fragment_chance(tier: int) -> float:
	return FRAGMENT_BASE + FRAGMENT_PER_TIER * maxi(tier - 8, 0)


## Punkty Watry z pokonanych bogów (Boons.pinnacle_kills: bóg -> liczba zwycięstw).
static func points(kills: Dictionary) -> int:
	var total := 0
	for god: String in kills:
		if GODS.has(god) and int(kills[god]) > 0:
			total += LORD_POINTS if is_lord(god) else FIRST_KILL_POINTS
	return total


## Ustawienia wyprawy na arenę boga (Dungeons.config z kluczem "pinnacle"; bez mechanik, bożków i ołtarza).
## `pomrok` - stopień Pomroku (0 - zwykła arena).
static func config(god: String, seed_value: int, tree := {}, pomrok := 0) -> Dictionary:
	var settings := Dungeons.config(GODS[god]["climate"], ARENA_TIER, [], seed_value, [])
	settings["pinnacle"] = god
	settings["pomrok"] = clampi(pomrok, 0, POMROK_MAX)
	settings["mechanics"] = []
	settings["altar"] = false
	settings["tree"] = tree.duplicate()
	return settings


## Szansa na Wielkie Krzesiwo w skarbcu boga (razy mnożnik łupu Władcy i Pomroku).
const GREAT_FLINT_CHANCE := 0.15

## Skarbiec po pokonaniu boga: [przedmiot, liczba] - przedmioty (część rzadkich), runy, kamienie, bożek, kamień
## szlachetny. Złoto i legendy daje sam bóg (Boss._drop_loot). Władca daje dwa razy więcej, Pomrok - o POMROK_LOOT
## więcej za stopień.
static func vault_rewards(level: int, rng: RandomNumberGenerator, lord := false, pomrok := 0) -> Array:
	var rewards: Array = []
	var mult := pomrok_mult("loot", pomrok) * (2.0 if lord else 1.0)
	level = mini(level, Loot.MAX_ITEM_LEVEL)
	for i in roundi(6 * mult):
		rewards.append([Loot.drop_at_level(level, 0.4, Loot.MAGIC, 2), 1])
	for i in roundi(3 * mult):
		rewards.append([Loot.drop_at_level(level, 0.6, Loot.RARE, 3), 1])
	for i in roundi(rng.randi_range(2, 3) * mult):
		rewards.append([ItemCraft.roll_rune(Dungeons.BASE_TIERS, rng), 1])
	rewards.append(["blessed_stone", roundi(rng.randi_range(3, 6) * mult)])
	for i in roundi(mult):
		rewards.append([Idols.roll(rng), 1])
	if Gems.unlocked:
		for i in roundi(mult):
			rewards.append([Gems.roll("", Gems.CUTS.size() - 1), 1])
	# Wielkie Krzesiwo (5. gniazdo umiejętności) - poza Mgłą Nawii tylko z bogów i Władcy
	if rng.randf() < GREAT_FLINT_CHANCE * mult:
		rewards.append([Supports.GREAT_FLINT, 1])
	return rewards
