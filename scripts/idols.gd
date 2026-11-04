class_name Idols
## Bożki (jak skaraby w Path of Exile): małe figurki wypadające rzadko z każdego potwora (po otwarciu lochów Watry -
## MainQuests.dungeons_unlocked). Przed wejściem do lochu gracz wkłada je w sloty w oknie lochów (DungeonWindow);
## przy wejściu bożki się zużywają i zmieniają loch.
## Przedmiot bożka to stały identyfikator "idol_<rodzaj>_<rzadkość>" (Items.get_data -> Idols.data), więc bożki
## układają się w stosy. Rodzaje (KINDS) dzielą się na grupy:
## - "mechanic" - jedna mechanika lochu (Dungeons.MECHANICS): zwykły częściej ją losuje, rzadki zawsze ją daje,
##   legendarny daje ją wzmocnioną (MECHANIC_POWER - więcej skrzyń, run, talizmanów do wyboru…),
## - "monsters" - więcej albo silniejszych potworów, za to więcej doświadczenia i łupu,
## - "loot" - więcej łupu danego rodzaju,
## - "risk" - mocne utrudnienie za lepszy łup,
## - "special" - zmiany lochu (strażnik, dodatkowi bossowie, tańsze modyfikatory),
## - "ancient" - bardzo rzadkie bożki tylko w rzadkości „prastary” (ANCIENT_CHANCE): loch samych elit albo bossów.
## Bożki potworów i łupu (STACK_GROUPS) można wkładać w kilka slotów naraz - działanie się sumuje; pozostałe tylko raz,
## a prastary najwyżej jeden.
## Siła rośnie z rzadkością (wartości w KINDS: [zwykły, rzadki, legendarny], prastare - jedna wartość). Mnożniki łączą się z modyfikatorami
## za żar (Dungeons.mult), premie mechanik idą do Dungeons.roll_mechanics (Dungeons.mechanic_bonus).
## Slotów jest 2, kolejne odblokowuje poziom Watry (SLOT_LEVELS); drzewko Watry (WatraTree) dokłada sloty
## (`extra_slots` w slot_count), częstsze wypadanie (`chance_bonus` w drop_chance) i rzadsze odmiany (roll).

const PREFIX := "idol_"
const RARITIES: Array[String] = ["common", "rare", "legendary", "ancient"]
## Rzadkości zwykłych rodzajów (prastare rodzaje mają w KINDS "rarities": ["ancient"]).
const NORMAL_RARITIES: Array[String] = ["common", "rare", "legendary"]
## Nazwy materiału według rzadkości (część nazwy bożka).
const MATERIAL_NAMES := {"common": "Gliniany", "rare": "Rzeźbiony", "legendary": "Złocony", "ancient": "Prastary"}
## Szansa na bożka z każdego potwora (bossowie BOSS_MULT razy więcej) i wagi rzadkości.
const DROP_CHANCE := 0.0035
const BOSS_MULT := 15.0
const RARITY_WEIGHTS := {"common": 70.0, "rare": 25.0, "legendary": 5.0}
## Szansa, że wypadnie bożek prastary (około 1 na 100 bożków).
const ANCIENT_CHANCE := 0.01
## Grupy, których bożki można wkładać w kilka slotów naraz.
const STACK_GROUPS: Array[String] = ["monsters", "loot"]
## Górne granice sumowanych szans (kilka bożków w slotach).
const ADD_CAPS := {"nawia": 0.6, "herbs": 0.6, "res_wood": 0.6, "res_stone": 0.6, "res_ore": 0.6}
## Od którego poziomu Watry działa kolejny slot (dwa pierwsze od początku).
const SLOT_LEVELS: Array[int] = [1, 1, 4, 6]
## Mechanika z bożka: mnożnik wagi zwykłego bożka, moc mechaniki z legendarnego (Dungeon.mechanic_power).
const MECHANIC_WEIGHT := 4.0
const MECHANIC_POWER := 1.5
## Cena skupu według rzadkości.
const SELL := {"common": 25, "rare": 70, "legendary": 200, "ancient": 800}

## Rodzaje bożków. "mult" - mnożniki lochu (klucze jak w Dungeons.MODIFIERS: count, health, damage, xp, gold, loot,
## treasure, oraz gems - kamienie szlachetne z potworów, legend - legendy z potworów i skarbca), "add" - premie
## dodawane (item_level - poziom przedmiotów z lochu, quality - szansa na lepszą rzadkość, vault_runes - runy w skarbcu).
## Każda wartość to [zwykły, rzadki, legendarny]. "weight" - jak często wypada.
const KINDS := {
	"chests": {"group": "mechanic", "mechanic": "chests", "name": "Bożek Skrzyń", "weight": 1.0,
			"description": "Pachnie kurzem starych skarbców."},
	"shrine": {"group": "mechanic", "mechanic": "shrine", "name": "Bożek Kapliczek", "weight": 1.0,
			"description": "Szepcze modlitwy, których nikt już nie pamięta."},
	"crystal": {"group": "mechanic", "mechanic": "crystal", "name": "Bożek Kryształu", "weight": 1.0,
			"description": "W jego oczach tli się żar Kryształu Watry."},
	"elites": {"group": "mechanic", "mechanic": "elites", "name": "Bożek Wybrańców", "weight": 1.0,
			"description": "Przyciąga najsilniejsze bestie z głębin."},
	"uroczysko": {"group": "mechanic", "mechanic": "uroczysko", "name": "Bożek Uroczyska", "weight": 0.8,
			"description": "Zimny w dłoni, jakby przyszedł z innego świata."},
	"zertwa": {"group": "mechanic", "mechanic": "zertwa", "name": "Bożek Żertwy", "weight": 0.8,
			"description": "Na jego dłoniach zaschła dawna danina."},
	"skarbnik": {"group": "mechanic", "mechanic": "skarbnik", "name": "Bożek Skarbnika", "weight": 0.8,
			"description": "Chichocze cicho, gdy brzęczy złoto."},
	"mist": {"group": "mechanic", "mechanic": "mist", "name": "Bożek Mgły", "weight": 0.8,
			"description": "Owiany sinym oparem, zimny jak mgła nad mogiłą."},
	"horde": {"group": "monsters", "name": "Bożek Hordy", "weight": 1.2,
			"description": "Woła potwory z całej okolicy.",
			"mult": {"count": [1.2, 1.4, 1.7]}},
	"fury": {"group": "monsters", "name": "Bożek Gniewu", "weight": 1.2,
			"description": "Budzi w potworach wściekłość.",
			"mult": {"health": [1.15, 1.3, 1.5], "damage": [1.1, 1.2, 1.35], "xp": [1.25, 1.5, 1.8], "loot": [1.1, 1.2, 1.35]}},
	"gold": {"group": "loot", "name": "Bożek Złota", "weight": 1.2,
			"description": "Potwory w lochu noszą pełniejsze sakwy.",
			"mult": {"gold": [1.3, 1.6, 2.0]}},
	"items": {"group": "loot", "name": "Bożek Łupu", "weight": 1.2,
			"description": "Z potworów i skarbca sypie się więcej przedmiotów.",
			"mult": {"loot": [1.25, 1.5, 2.0]}},
	"runes": {"group": "loot", "name": "Bożek Run", "weight": 0.9,
			"description": "Skarbiec strażnika kryje dodatkowe runy.",
			"add": {"vault_runes": [1, 2, 4]}},
	"gems": {"group": "loot", "name": "Bożek Klejnotów", "weight": 0.9,
			"description": "Potwory częściej gubią kamienie szlachetne (po zadaniu jubilera).",
			"mult": {"gems": [2.0, 3.0, 5.0]}},
	"legends": {"group": "loot", "name": "Bożek Legend", "weight": 0.5,
			"description": "Przyciąga przedmioty z dawnych opowieści.",
			"mult": {"legend": [1.5, 2.0, 3.0]}},
	"pride": {"group": "risk", "name": "Bożek Pychy", "weight": 0.8,
			"description": "Potwory biją mocniej, ale łup z lochu ma wyższy poziom.",
			"mult": {"damage": [1.4, 1.6, 1.8]}, "add": {"item_level": [2, 4, 6]}},
	"gloom": {"group": "risk", "name": "Bożek Mroku", "weight": 0.8,
			"description": "Potwory są twardsze, ale łup z lochu bywa rzadszy i cenniejszy.",
			"mult": {"health": [1.5, 1.75, 2.0]}, "add": {"quality": [0.15, 0.25, 0.4]}},
	"packs": {"group": "monsters", "name": "Bożek Gromad", "weight": 1.0,
			"description": "Ściąga do lochu dodatkowe gromady potworów.",
			"add": {"packs": [3, 5, 5], "pack_elites": [0, 0, 1]}},
	# żywioły (Elements, etap 3) - ryzyko za łup
	"blaze": {"group": "risk", "name": "Bożek Pożogi", "weight": 0.7,
			"description": "Każdy cios potworów parzy ogniem, ale łupu jest więcej.",
			"add": {"added_fire": [0.2, 0.3, 0.4]}, "mult": {"loot": [1.2, 1.3, 1.4]}},
	"rime": {"group": "risk", "name": "Bożek Szronu", "weight": 0.7,
			"description": "Każdy cios potworów mrozi, ale doświadczenia jest więcej.",
			"add": {"added_cold": [0.2, 0.3, 0.4]}, "mult": {"xp": [1.25, 1.4, 1.6]}},
	"thunder": {"group": "risk", "name": "Bożek Gromu", "weight": 0.7,
			"description": "Każdy cios potworów razi piorunem, ale łup bywa rzadszy i cenniejszy.",
			"add": {"added_lightning": [0.2, 0.3, 0.4], "quality": [0.1, 0.15, 0.2]}},
	"bane": {"group": "risk", "name": "Bożek Klątwy", "weight": 0.6,
			"description": "Odbiera odporność na żywioły, ale łup z lochu ma wyższy poziom.",
			"add": {"elemental_curse": [0.15, 0.2, 0.3], "item_level": [1, 2, 3]}},
	"nawia": {"group": "monsters", "name": "Bożek Nawii", "weight": 0.8,
			"description": "Polegli nie zaznają spokoju - wstają jako upiory.",
			"add": {"nawia": [0.1, 0.2, 0.3]}},
	"herbs": {"group": "loot", "name": "Bożek Zielarki", "weight": 0.9,
			"description": "Potwory gubią zioła z krain.",
			"add": {"herbs": [0.05, 0.1, 0.15]}},
	"wood": {"group": "loot", "name": "Bożek Drwala", "weight": 0.9,
			"description": "Potwory gubią drewno.",
			"add": {"res_wood": [0.05, 0.1, 0.15]}},
	"stone": {"group": "loot", "name": "Bożek Kamieniarza", "weight": 0.9,
			"description": "Potwory gubią kamień.",
			"add": {"res_stone": [0.05, 0.1, 0.15]}},
	"ore": {"group": "loot", "name": "Bożek Górnika", "weight": 0.9,
			"description": "Potwory gubią rudę żelaza.",
			"add": {"res_ore": [0.05, 0.1, 0.15]}},
	"cutter": {"group": "loot", "name": "Bożek Szlifierza", "weight": 0.7,
			"description": "Kamienie szlachetne z potworów bywają lepiej oszlifowane.",
			"add": {"gem_cut": [0.25, 0.5, 1.0]}},
	"guardian": {"group": "special", "name": "Bożek Strażnika", "weight": 0.7,
			"description": "Strażnik lochu wpada w szał, ale jego skarbiec jest pełniejszy.",
			"mult": {"boss_health": [1.5, 2.0, 2.5], "boss_damage": [1.2, 1.3, 1.4], "treasure": [1.5, 2.0, 2.5]}},
	"echo": {"group": "special", "name": "Bożek Echa", "weight": 0.6,
			"description": "Przywołuje do lochu echo bossa z innej krainy.",
			"add": {"echo": [1, 1, 2], "echo_level": [0, 3, 3]}},
	"ember": {"group": "special", "name": "Bożek Żaru", "weight": 0.7,
			"description": "Watra przyjmuje mniejszą ofiarę za modyfikatory.",
			"mult": {"ember_cost": [0.75, 0.5, 0.0]}},
	"hosts": {"group": "ancient", "name": "Bożek Zastępów", "weight": 1.0, "rarities": ["ancient"],
			"description": "W lochu stają same elity. Wysokie ryzyko, wielka nagroda.",
			"mult": {"count": [0.5]}, "add": {"all_elite": [1]}},
	"lords": {"group": "ancient", "name": "Bożek Władców", "weight": 1.0, "rarities": ["ancient"],
			"description": "Zamiast gromad w komnatach czekają bossowie krain. Wysokie ryzyko, wielka nagroda.",
			"add": {"lords": [1]}},
}
const KIND_ORDER: Array[String] = ["chests", "shrine", "crystal", "elites", "uroczysko", "zertwa", "skarbnik", "mist",
		"horde", "fury", "packs", "nawia", "gold", "items", "runes", "gems", "cutter", "legends", "herbs", "wood", "stone",
		"ore", "pride", "gloom", "blaze", "rime", "thunder", "bane", "guardian", "echo", "ember", "hosts", "lords"]
## Grupy w kolejności pokazywania i ich nazwy.
const GROUP_NAMES := {"mechanic": "Bożek mechaniki", "monsters": "Bożek potworów", "loot": "Bożek łupu",
		"risk": "Bożek ryzyka", "special": "Bożek przemiany", "ancient": "Bożek prastary"}
## Opisy działania (jeden wzór na wartość). Mnożniki pokazywane jako "+N%".
const EFFECT_TEXTS := {
	"count": "+%d%% potworów",
	"health": "Potwory: +%d%% zdrowia",
	"damage": "Potwory: +%d%% obrażeń",
	"xp": "+%d%% doświadczenia",
	"gold": "+%d%% złota",
	"loot": "+%d%% przedmiotów",
	"gems": "+%d%% kamieni szlachetnych z potworów",
	"legend": "+%d%% szansy na legendy",
	"vault_runes": "Skarbiec: +%d run",
	"item_level": "Łup z lochu: +%d poziomu przedmiotu",
	"quality": "Łup z lochu: +%d%% szansy na lepszą rzadkość",
	"packs": "+%d gromad potworów",
	"pack_elites": "W każdej dodatkowej gromadzie elita",
	"nawia": "%d%% szansy, że zabity wróg wstanie jako upiór",
	"herbs": "%d%% szansy na zioła z potworów",
	"res_wood": "%d%% szansy na drewno z potworów",
	"res_stone": "%d%% szansy na kamień z potworów",
	"res_ore": "%d%% szansy na rudę żelaza z potworów",
	"gem_cut": "%d%% szansy na lepszy szlif kamieni szlachetnych",
	"boss_health": "Strażnik: +%d%% zdrowia, wściekły",
	"boss_damage": "Strażnik: +%d%% obrażeń",
	"treasure": "Skarbiec: +%d%% łupu",
	"echo": "Bossowie z innych krain w lochu: %d",
	"echo_level": "Bossowie echa: +%d poziomu",
	"ember_cost": "Modyfikatory za żar: -%d%% kosztu",
	"all_elite": "Wszystkie potwory to elity",
	"lords": "W każdej komnacie boss krainy",
	"added_fire": "Potwory zadają dodatkowo %d%% obrażeń od ognia",
	"added_cold": "Potwory zadają dodatkowo %d%% obrażeń od lodu",
	"added_lightning": "Potwory zadają dodatkowo %d%% obrażeń od piorunów",
	"added_nawia": "Potwory zadają dodatkowo %d%% obrażeń od Nawii",
	"elemental_curse": "Odporności na żywioły: -%d%%",
	"monster_resistance": "Potwory: +%d%% odporności na żywioły",
}
## Klucze bez liczby w opisie, procentowe dodawane i mnożniki pokazywane jako ubytek ("-N%").
const FLAG_KEYS: Array[String] = ["pack_elites", "all_elite", "lords"]
const PERCENT_ADDS: Array[String] = ["quality", "nawia", "herbs", "res_wood", "res_stone", "res_ore", "gem_cut",
		"added_fire", "added_cold", "added_lightning", "added_nawia", "elemental_curse", "monster_resistance"]
const REDUCING_MULTS: Array[String] = ["ember_cost"]
## Opisy wzmocnionej mechaniki (legendarny bożek mechaniki).
const POWER_TEXTS := {
	"chests": "Więcej skrzyń",
	"shrine": "Dodatkowa kapliczka",
	"crystal": "Kryształ daje o połowę więcej kamieni",
	"elites": "Więcej elitarnych potworów",
	"uroczysko": "Uroczysko daje o połowę więcej run",
	"zertwa": "Krąg Żertwy: jeden talizman więcej do wyboru",
	"skarbnik": "Dodatkowy Skarbnik",
	"mist": "Bogatsza Skrzynia Mgły",
}

static var _cache := {}


static func id_of(kind: String, rarity: String) -> String:
	return "%s%s_%s" % [PREFIX, kind, rarity]


static func is_idol(id: String) -> bool:
	return id.begins_with(PREFIX) and not data(id).is_empty()


## [rodzaj, rzadkość] z identyfikatora (puste - to nie bożek).
static func parse(id: String) -> Array:
	if not id.begins_with(PREFIX):
		return []
	var rest := id.substr(PREFIX.length())
	for rarity in RARITIES:
		if rest.ends_with("_" + rarity):
			var kind := rest.substr(0, rest.length() - rarity.length() - 1)
			if KINDS.has(kind) and rarities_of(kind).has(rarity):
				return [kind, rarity]
	return []


## Rzadkości, w jakich występuje rodzaj.
static func rarities_of(kind: String) -> Array:
	return KINDS[kind].get("rarities", NORMAL_RARITIES)


## Wartość z listy [zwykły, rzadki, legendarny] (prastare rodzaje - jedna wartość) dla rzadkości bożka.
static func _pick(kind: String, rarity: String, values: Array) -> float:
	return float(values[clampi(rarities_of(kind).find(rarity), 0, values.size() - 1)])


## Czy bożek tego rodzaju można włożyć w kilka slotów naraz.
static func stacks(kind: String) -> bool:
	return KINDS.has(kind) and STACK_GROUPS.has(KINDS[kind]["group"])


static func kind_of(id: String) -> String:
	var parts := parse(id)
	return parts[0] if not parts.is_empty() else ""


## Dane przedmiotu bożka dla Items.get_data ({} - nie ma takiego bożka). Nazwa i opis po polsku - tłumaczone
## przy pokazywaniu (Items.display_name, Items.describe).
static func data(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var parts := parse(id)
	if parts.is_empty():
		return {}
	var kind: String = parts[0]
	var rarity: String = parts[1]
	var item := {
		"name": "%s %s" % [MATERIAL_NAMES[rarity], KINDS[kind]["name"]],
		"description": KINDS[kind]["description"],
		"icon": load("res://assets/items/idols/%s_%s.png" % [kind, rarity]),
		"rarity": rarity, "sell_price": SELL[rarity], "idol": kind,
	}
	_cache[id] = item
	return item


## Nazwa do pokazania: materiał i rodzaj tłumaczone osobno ("Gliniany" + "Bożek Skrzyń").
static func display_name(id: String) -> String:
	var parts := parse(id)
	if parts.is_empty():
		return ""
	return "%s %s" % [Lang.t(MATERIAL_NAMES[parts[1]]), Lang.t(KINDS[parts[0]]["name"])]


## Linie opisu działania bożka (już przetłumaczone).
static func effect_lines(id: String) -> Array[String]:
	var lines: Array[String] = []
	var parts := parse(id)
	if parts.is_empty():
		return lines
	var kind: Dictionary = KINDS[parts[0]]
	var index := RARITIES.find(parts[1])
	var rarity: String = parts[1]
	lines.append(Lang.t("%s - %s") % [Lang.t(Items.RARITY_NAMES[parts[1]]), Lang.t(GROUP_NAMES[kind["group"]])])
	if kind["group"] == "mechanic":
		var mechanic: String = Lang.t(Dungeons.MECHANICS[kind["mechanic"]]["name"])
		match index:
			0: lines.append(Lang.t("Mechanika „%s” pojawia się dużo częściej") % mechanic)
			1: lines.append(Lang.t("Mechanika „%s” jest zawsze w lochu") % mechanic)
			_:
				lines.append(Lang.t("Mechanika „%s” jest zawsze w lochu") % mechanic)
				lines.append(Lang.t(POWER_TEXTS[kind["mechanic"]]))
	for key: String in kind.get("mult", {}):
		var factor := _pick(parts[0], rarity, kind["mult"][key])
		if key == "count" and factor < 1.0:
			lines.append(Lang.t("%d%% potworów") % roundi((factor - 1.0) * 100.0))
		else:
			lines.append(Lang.t(EFFECT_TEXTS[key]) % roundi(absf(factor - 1.0) * 100.0))
	for key: String in kind.get("add", {}):
		var value := _pick(parts[0], rarity, kind["add"][key])
		if value <= 0.0:
			continue
		if key in FLAG_KEYS:
			lines.append(Lang.t(EFFECT_TEXTS[key]))
		else:
			lines.append(Lang.t(EFFECT_TEXTS[key]) % (roundi(value * 100.0) if key in PERCENT_ADDS else int(value)))
	if stacks(parts[0]):
		lines.append(Lang.t("Można włożyć w kilka slotów - działanie się sumuje."))
	lines.append(Lang.t("Włóż w slot w oknie lochów Watry - zużywa się przy wejściu."))
	return lines


# ---------------------------------------------------------------- sloty i wypadanie
## Ile slotów na bożki przy danym poziomie Watry. `extra_slots` - z drzewka Watry (WatraTree.idol_slots).
static func slot_count(watra_level: int, extra_slots := 0) -> int:
	var count := 0
	for level in SLOT_LEVELS:
		if watra_level >= level:
			count += 1
	return count + extra_slots


## Od którego poziomu Watry działa slot o numerze `index` (0 - nie odblokowuje go poziom Watry).
static func slot_unlock(index: int) -> int:
	return SLOT_LEVELS[index] if index < SLOT_LEVELS.size() else 0


## Szansa na bożka z jednego potwora. `chance_bonus` - mnożnik z drzewka Watry (1 + premia "idol_drop").
static func drop_chance(boss: bool, chance_bonus := 1.0) -> float:
	return DROP_CHANCE * (BOSS_MULT if boss else 1.0) * chance_bonus


## Losowy bożek: z szansą ANCIENT_CHANCE prastary, inaczej zwykły rodzaj (KINDS "weight") w rzadkości według
## RARITY_WEIGHTS. Drzewko Watry: `rarity_bonus` podnosi wagi rzadkich i legendarnych, `ancient_bonus` szansę
## na prastarego (ułamki, np. 0.3 = +30%).
static func roll(rng: RandomNumberGenerator = null, rarity_bonus := 0.0, ancient_bonus := 0.0) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var ancient := rng.randf() < ANCIENT_CHANCE * (1.0 + ancient_bonus)
	var kinds := {}
	for kind: String in KINDS:
		if rarities_of(kind).has("ancient") == ancient:
			kinds[kind] = KINDS[kind]["weight"]
	var kind := Dungeons.weighted(rng, kinds)
	var rarities := RARITY_WEIGHTS.duplicate()
	for rarity: String in ["rare", "legendary"]:
		rarities[rarity] = float(rarities[rarity]) * (1.0 + rarity_bonus)
	return id_of(kind, "ancient" if ancient else Dungeons.weighted(rng, rarities))


# ---------------------------------------------------------------- działanie w lochu
## Bossowie dla Bożka Echa i Bożka Władców: strażnicy klimatów lochów (sprawdzeni w komnatach lochu), bez `exclude`.
static func boss_pool(exclude := "") -> Array[String]:
	var pool: Array[String] = []
	for climate: String in Dungeons.CLIMATES:
		var boss: String = Dungeons.CLIMATES[climate]["boss"]
		if boss != exclude and not pool.has(boss):
			pool.append(boss)
	return pool


## Zioło z krain do poziomu `level` (Bożek Zielarki): kraina musi zaczynać się najwyżej na tym poziomie,
## częściej zioła pospolite (Herbs.KINDS "count").
static func herb_for_level(level: int) -> String:
	var weights := {}
	for kind: String in Herbs.ORDER:
		var zone: String = Herbs.KINDS[kind]["zone"]
		if int(Levels.ZONES.get(zone, [1])[0]) <= level:
			weights[Herbs.KINDS[kind]["item"]] = float(Herbs.KINDS[kind]["count"])
	if weights.is_empty():
		return Herbs.KINDS[Herbs.ORDER[0]]["item"]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return Dungeons.weighted(rng, weights)


## Szlif kamienia szlachetnego z Bożkiem Szlifierza: `bonus` 0,5 - połowa szans na +1, 1,5 - +1 i połowa szans na +2.
static func better_cut(cut: int, bonus: float) -> int:
	var extra := floori(bonus) + (1 if randf() < bonus - floorf(bonus) else 0)
	return clampi(cut + extra, 0, Gems.CUTS.size() - 1)


## Łączny mnożnik danego rodzaju z bożków (1 - bez zmian).
static func multiplier(ids: Array, key: String) -> float:
	var total := 1.0
	for id: String in ids:
		var parts := parse(id)
		if parts.is_empty():
			continue
		var values: Array = KINDS[parts[0]].get("mult", {}).get(key, [])
		if not values.is_empty():
			total *= _pick(parts[0], parts[1], values)
	return total


## Suma premii dodawanych danego rodzaju z bożków (0 - bez zmian).
static func added(ids: Array, key: String) -> float:
	var total := 0.0
	for id: String in ids:
		var parts := parse(id)
		if parts.is_empty():
			continue
		var values: Array = KINDS[parts[0]].get("add", {}).get(key, [])
		if not values.is_empty():
			total += _pick(parts[0], parts[1], values)
	return minf(total, ADD_CAPS[key]) if ADD_CAPS.has(key) else total


## Premie mechanik z bożków dla Dungeons.roll_mechanics: {"weights", "forced", "power"}.
static func mechanic_bonus(ids: Array) -> Dictionary:
	var weights := {}
	var forced: Array[String] = []
	var power := {}
	for id: String in ids:
		var parts := parse(id)
		if parts.is_empty() or KINDS[parts[0]]["group"] != "mechanic":
			continue
		var mechanic: String = KINDS[parts[0]]["mechanic"]
		match parts[1]:
			"common":
				weights[mechanic] = float(weights.get(mechanic, 1.0)) * MECHANIC_WEIGHT
			"rare":
				if not forced.has(mechanic):
					forced.append(mechanic)
			_:
				if not forced.has(mechanic):
					forced.append(mechanic)
				power[mechanic] = MECHANIC_POWER
	return {"weights": weights, "forced": forced, "power": power}


## Czy bożki można włożyć razem: rodzaje spoza STACK_GROUPS najwyżej raz, prastary najwyżej jeden.
static func can_combine(ids: Array) -> bool:
	var kinds := {}
	var ancient := 0
	for id: String in ids:
		var kind := kind_of(id)
		if kind == "" or (kinds.has(kind) and not stacks(kind)):
			return false
		kinds[kind] = true
		if KINDS[kind]["group"] == "ancient":
			ancient += 1
	return ancient <= 1


## Czy bożek `id` można dołożyć do już wybranych `ids`.
static func fits(ids: Array, id: String) -> bool:
	return can_combine(ids + [id])
