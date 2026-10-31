class_name Gems
## Kamienie szlachetne i gniazda w przedmiotach (od środka gry - odblokowuje je zadanie jubilera Dobromira w Orlej
## Przełęczy, "jeweler_gem"):
## - kamień ma rodzaj (rubin, szafir, szmaragd, topaz, ametyst, onyks) i szlif (okruch ... królewski - SZLIFY) oraz
##   2 premie: jedną z puli swojego rodzaju i jedną z puli wspólnej (szybkość ataku i rzucania, krytyki, obszar,
##   regeneracja); lepszy szlif - mocniejsze premie, a lepsze kamienie (końcówka gry) mogą mieć trzecią premię;
## - kamień to wylosowany przedmiot (Items.generated, przepis z "gem") - jedna sztuka, z ikoną rodzaju i szlifu;
## - gniazdo: przepis przedmiotu (Loot.register) ma "sockets": lista kamieni (przepisów, {} - puste gniazdo); premie
##   kamieni liczą się do statystyk przedmiotu (Items.stats_of), a kamień wyjęty z gniazda wraca jako przedmiot;
## - po zadaniu kamienie wypadają z potworów (Goblin._drop_loot), a magiczne i rzadkie przedmioty czasem mają gniazdo
##   (Loot.generate); gniazdo dorabia i kamienie łączy (3 jednego szlifu -> 1 lepszego) jubiler (JewelerWindow);
## - kamień promienia (rodzaj "radius", końcówka gry - Kryształ Watry i skarbiec lochu) pasuje tylko do gniazd drzewek
##   broni: wzmacnia wybrane węzły pasywne w swoim promieniu (SkillBook.RADIUS_RANGE) o "radius_power".

const KINDS := {
	"ruby": {"name": "Rubin", "pool": ["health", "health_regen", "life_on_hit"]},
	"sapphire": {"name": "Szafir", "pool": ["mana", "mana_regen", "spell_damage"]},
	"emerald": {"name": "Szmaragd", "pool": ["dexterity", "dodge_chance", "move_speed"]},
	"topaz": {"name": "Topaz", "pool": ["strength", "physical_damage", "damage"]},
	"amethyst": {"name": "Ametyst", "pool": ["intelligence", "cooldown_reduction", "spell_damage"]},
	"onyx": {"name": "Onyks", "pool": ["vitality", "armor", "damage_percent"]},
	"radius": {"name": "Kamień Promienia", "pool": []},
}
const KIND_ORDER: Array[String] = ["ruby", "sapphire", "emerald", "topaz", "amethyst", "onyx"]
## Premie wspólne dla wszystkich kamieni.
const SHARED: Array[String] = ["attack_speed", "cast_speed", "crit_chance", "crit_damage", "area", "health_regen", "mana_regen"]
const CUTS: Array[String] = ["Okruch", "Odłamek", "Kamień", "Szlifowany", "Królewski"]
## Siła premii na szlifie 1 (dalej razy CUT_POWER).
const BASE_VALUES := {
	"health": 12.0, "health_regen": 0.6, "life_on_hit": 1.0, "mana": 10.0, "mana_regen": 0.5, "spell_damage": 0.03,
	"dexterity": 2.0, "dodge_chance": 0.01, "move_speed": 0.015, "strength": 2.0, "physical_damage": 0.03, "damage": 2.0,
	"intelligence": 2.0, "cooldown_reduction": 0.01, "vitality": 2.0, "armor": 3.0, "damage_percent": 0.02,
	"attack_speed": 0.02, "cast_speed": 0.02, "crit_chance": 0.01, "crit_damage": 0.05, "area": 0.03,
}
const CUT_POWER: Array[float] = [1.0, 1.6, 2.3, 3.1, 4.0]
## Szansa na kamień z potwora i na gniazdo w magicznym / rzadkim przedmiocie (po zadaniu jubilera).
const DROP_CHANCE := 0.012
const SOCKET_CHANCE := 0.15
## Lepszy kamień (końcówka gry - lochy): szansa na trzecią premię.
const EXTRA_AFFIX_CHANCE := 0.35
## Ceny u jubilera: gniazdo (rośnie z poziomem przedmiotu) i łączenie (rośnie ze szlifem).
const SOCKET_GOLD := 150
const SOCKET_GOLD_PER_LEVEL := 12
const COMBINE_GOLD: Array[int] = [40, 120, 300, 700]
## Przeszlifowanie (jubiler w swojej chacie w Ostoi): nowe premie kamienia za złoto (wg szlifu).
const RESHAPE_GOLD: Array[int] = [50, 120, 280, 600, 1200]
const QUEST := "jeweler_gem"
const ROUGH_GEM := "rough_gem"
const SOCKET_ICON := preload("res://assets/ui/socket.png")
const COLORS := {"ruby": "ff6b6b", "sapphire": "6ea8ff", "emerald": "5fdc7d", "topaz": "ffc24a", "amethyst": "c07bff", "onyx": "c8c8d2",
		"radius": "5fe0d0"}
## Kamień promienia: szansa w nagrodzie Kryształu Watry (plus za stopień lochu) i w skarbcu strażnika.
const RADIUS_CRYSTAL_CHANCE := 0.2
const RADIUS_CRYSTAL_PER_TIER := 0.04
const RADIUS_VAULT_CHANCE := 0.25
const RADIUS_ICON := preload("res://assets/items/gems/radius.png")

## Czy kamienie i gniazda już wypadają (zadanie jubilera wykonane) - ustawia gracz po wczytaniu i po zadaniu.
static var unlocked := false


static func is_gem(id: String) -> bool:
	return Items.get_data(id).has("gem")


static func is_radius(id: String) -> bool:
	return Items.get_data(id).get("gem", {}).get("kind", "") == "radius"


## Nowy kamień promienia; moc (wzmocnienie węzłów pasywnych) rośnie ze stopniem lochu 1-7.
static func roll_radius(tier := 1) -> String:
	var power := snappedf(randf_range(0.2, 0.35) + 0.02 * clampi(tier, 1, 7), 0.01)
	return register({"gem": true, "kind": "radius", "cut": CUTS.size() - 1, "affixes": {"radius_power": power}})


## Opis działania kamienia promienia: "Wybrane węzły pasywne w promieniu: +30% premii".
static func radius_text(power: float) -> String:
	return "Wybrane węzły pasywne w promieniu: +%d%% premii" % roundi(power * 100.0)


## Szlif kamienia z poziomu potwora / lochu (0-4): poziom 16 - okruch, co około 7 poziomów lepszy.
static func cut_for_level(level: int) -> int:
	return clampi(floori((level - 13) / 7.0) + (1 if randf() < 0.15 else 0), 0, CUTS.size() - 1)


## Nowy kamień: rodzaj (losowy, gdy ""), szlif 0-4; `better` - lepszy kamień z lochów (szansa na 3. premię).
static func roll(kind := "", cut := 0, better := false) -> String:
	if kind == "":
		kind = KIND_ORDER.pick_random()
	var affixes := {}
	var own: Array = KINDS[kind]["pool"]
	affixes[own.pick_random()] = 0.0
	var shared := SHARED.filter(func(stat: String) -> bool: return not affixes.has(stat))
	affixes[shared.pick_random()] = 0.0
	if better and randf() < EXTRA_AFFIX_CHANCE:
		var rest := (own + SHARED).filter(func(stat: String) -> bool: return not affixes.has(stat))
		affixes[rest.pick_random()] = 0.0
	for stat: String in affixes:
		affixes[stat] = _value(stat, cut)
	return register({"gem": true, "kind": kind, "cut": cut, "affixes": affixes})


static func _value(stat: String, cut: int) -> float:
	var value: float = BASE_VALUES[stat] * CUT_POWER[cut] * randf_range(0.8, 1.2)
	var step := Loot._step(stat)
	return snappedf(value, step) if step > 0.0 else float(maxi(1, roundi(value)))


## Rejestruje kamień z przepisu (także przy wczytaniu zapisu - Loot.import).
static func register(recipe: Dictionary, id := "") -> String:
	if id == "":
		Items.generated_serial += 1
		id = Loot.PREFIX + str(Items.generated_serial)
	var kind: String = recipe["kind"]
	var cut := clampi(int(recipe["cut"]), 0, CUTS.size() - 1)
	recipe["cut"] = cut
	if kind == "radius":
		recipe["affixes"] = {"radius_power": float(recipe["affixes"].get("radius_power", 0.25))}
		Items.generated[id] = {
			"name": KINDS[kind]["name"],
			"description": "Kamień do gniazda w drzewku umiejętności broni (okno K). %s. Nie pasuje do przedmiotów."
					% radius_text(recipe["affixes"]["radius_power"]),
			"icon": RADIUS_ICON, "rarity": "rare",
			"gem": {"kind": kind, "cut": cut}, "stats": {}, "sell_price": 400, "recipe": recipe,
		}
		return id
	var stats := {}
	for stat: String in recipe["affixes"]:
		var value: float = recipe["affixes"][stat]
		stats[stat] = value if Loot._step(stat) > 0.0 else int(value)
	recipe["affixes"] = stats
	Items.generated[id] = {
		"name": "%s (%s)" % [KINDS[kind]["name"], CUTS[cut].to_lower()],
		"description": "Kamień szlachetny. Przeciągnij go na przedmiot z pustym gniazdem (w plecaku albo założony) - premie działają, dopóki kamień w nim tkwi. Wyjmuje jubiler Dobromir.",
		"icon": load("res://assets/items/gems/%s_%d.png" % [kind, cut + 1]),
		"rarity": "rare" if stats.size() > 2 else "magic",
		"gem": {"kind": kind, "cut": cut},
		"stats": stats,
		"sell_price": 15 * (cut + 1) * (cut + 1),
		"recipe": recipe,
	}
	return id


## Krótki opis kamienia w gnieździe: "Rubin (okruch): +12 zdrowie, +2% szybkość ataku".
static func socket_text(gem: Dictionary) -> String:
	if gem.is_empty():
		return "Puste gniazdo"
	if gem.get("kind", "") == "radius":
		return "[color=#%s]%s[/color]: %s" % [COLORS["radius"], KINDS["radius"]["name"], radius_text(float(gem["affixes"].get("radius_power", 0.0)))]
	var parts: Array[String] = []
	for stat: String in gem["affixes"]:
		parts.append(Items._stat_text(stat, gem["affixes"][stat]))
	return "[color=#%s]%s (%s)[/color]: %s" % [COLORS[gem["kind"]], KINDS[gem["kind"]]["name"],
			CUTS[int(gem["cut"])].to_lower(), ", ".join(parts)]


## Opis kamienia bez kolorów (zwykłe etykiety i dymki).
static func plain_text(gem: Dictionary) -> String:
	var regex := RegEx.create_from_string("\\[/?color[^\\]]*\\]")
	return regex.sub(socket_text(gem), "", true)


## Ikona kamienia z przepisu (kamień w gnieździe nie jest przedmiotem).
static func icon_of(gem: Dictionary) -> Texture2D:
	if gem.get("kind", "") == "radius":
		return RADIUS_ICON
	return load("res://assets/items/gems/%s_%d.png" % [gem["kind"], int(gem["cut"]) + 1])


# ---------------------------------------------------------------- gniazda w przedmiotach
## Czy w przedmiot da się wstawić gniazdo (broń, zbroja, biżuteria - bez legend, te dostaną gniazda z esencjami).
static func can_socket(id: String) -> bool:
	var item := Items.get_data(id)
	return Items.is_equippable(id) and item.get("rarity", "common") != "legendary" and sockets_of(id).is_empty()


static func sockets_of(id: String) -> Array:
	return Items.get_data(id).get("sockets", [])


static func socket_price(id: String) -> int:
	return SOCKET_GOLD + SOCKET_GOLD_PER_LEVEL * int(Items.get_data(id).get("item_level", 1))


## Przepis przedmiotu (zwykły przedmiot ze sklepu dostaje go teraz - jako wylosowany bez premii, poziom 1).
static func _recipe_of(id: String) -> Dictionary:
	if Items.generated.has(id):
		return (Items.generated[id]["recipe"] as Dictionary).duplicate(true)
	return {"base": id, "quality": "common", "level": 1, "affixes": {}, "tiers": {}, "name": Items.get_data(id)["name"]}


## Dorabia gniazdo; zwraca id przedmiotu (zwykły przedmiot dostaje nowe id - trzeba je podmienić w plecaku/postaci).
static func add_socket(id: String) -> String:
	var recipe := _recipe_of(id)
	recipe["sockets"] = [{}]
	return Loot.register(recipe, id if Items.generated.has(id) else "")


## Osadza kamień `gem_id` w gnieździe `index` przedmiotu `id` (kamień jako przedmiot przestaje istnieć).
static func insert(id: String, index: int, gem_id: String) -> void:
	var recipe := _recipe_of(id)
	recipe["sockets"][index] = (Items.generated[gem_id]["recipe"] as Dictionary).duplicate(true)
	Loot.register(recipe, id)
	Items.generated.erase(gem_id)


## Wyjmuje kamień z gniazda - wraca jako nowy przedmiot (id kamienia).
static func remove(id: String, index: int) -> String:
	var recipe := _recipe_of(id)
	var gem: Dictionary = recipe["sockets"][index]
	recipe["sockets"][index] = {}
	Loot.register(recipe, id)
	return register(gem.duplicate(true))


# ---------------------------------------------------------------- przeciąganie na przedmiot
## Kamień albo esencja przeciągnięta z plecaka na przedmiot (w plecaku albo założony - InventoryWindow):
## "gem" / "essence" - da się osadzić, "" - nie dotyczy (zwykłe przeniesienie), inaczej powód odmowy.
## Kamień trafia tylko do pustego gniazda (wyjmuje jubiler), esencja - do pustego gniazda esencji tego samego rodzaju.
static func drag_target(source_id: String, item_id: String) -> String:
	if source_id == "" or item_id == "" or source_id == item_id:
		return ""
	if is_gem(source_id):
		if sockets_of(item_id).is_empty():
			return ""
		if is_radius(source_id):
			return "Kamień Promienia pasuje tylko do gniazd drzewka umiejętności."
		if not sockets_of(item_id).any(func(gem: Dictionary) -> bool: return gem.is_empty()):
			return "Gniazdo zajęte - kamień wyjmie jubiler Dobromir."
		return "gem"
	if Essences.is_essence(source_id):
		if not Essences.has_socket(item_id):
			return ""
		if not (Essences.socket_of(item_id) as Dictionary).is_empty():
			return "Gniazdo esencji zajęte - esencję wyjmie kowal Bronisław."
		if not Essences.fits(source_id, item_id):
			return "Ta esencja pasuje tylko do: %s." % Essences.GROUP_NAMES[Items.get_data(source_id)["essence"]["group"]]
		return "essence"
	return ""


## Osadza kamień / esencję z pola `index` plecaka w przedmiocie `item_id` (wg drag_target - "gem" albo "essence").
static func drag_insert(inventory: Inventory, index: int, item_id: String, target: String) -> void:
	var source_id: String = inventory.slots[index]["id"]
	inventory.take_one(index)
	if target == "essence":
		Essences.insert(item_id, source_id)
	else:
		var sockets := sockets_of(item_id)
		for i in sockets.size():
			if (sockets[i] as Dictionary).is_empty():
				insert(item_id, i, source_id)
				return


## Przeszlifowanie: ten sam rodzaj, szlif i liczba premii, ale premie (i ich siła) losowane od nowa.
## Kamień jako przedmiot dostaje nowe id (stary znika).
static func reshape(gem_id: String) -> String:
	var gem: Dictionary = Items.get_data(gem_id)["gem"]
	var count: int = Items.get_data(gem_id)["stats"].size()
	Items.generated.erase(gem_id)
	var kind: String = gem["kind"]
	var cut: int = gem["cut"]
	var own: Array = KINDS[kind]["pool"]
	var affixes := {}
	affixes[own.pick_random()] = 0.0
	var shared := SHARED.filter(func(stat: String) -> bool: return not affixes.has(stat))
	affixes[shared.pick_random()] = 0.0
	while affixes.size() < count:
		var rest := (own + SHARED).filter(func(stat: String) -> bool: return not affixes.has(stat))
		affixes[rest.pick_random()] = 0.0
	for stat: String in affixes:
		affixes[stat] = _value(stat, cut)
	return register({"gem": true, "kind": kind, "cut": cut, "affixes": affixes})


## Łączenie: trzy kamienie tego samego szlifu (dowolnych rodzajów) -> jeden lepszego szlifu, rodzaju jednego z nich.
static func combine(gem_ids: Array) -> String:
	var kinds: Array = gem_ids.map(func(gem_id: String) -> String: return Items.get_data(gem_id)["gem"]["kind"])
	var cut: int = Items.get_data(gem_ids[0])["gem"]["cut"]
	for gem_id: String in gem_ids:
		Items.generated.erase(gem_id)
	return roll(kinds.pick_random(), mini(cut + 1, CUTS.size() - 1))
