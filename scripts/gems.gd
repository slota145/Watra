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
##   (Loot.generate); gniazdo dorabia i kamienie łączy (3 jednego szlifu -> 1 lepszego) jubiler (JewelerWindow).

const KINDS := {
	"ruby": {"name": "Rubin", "pool": ["health", "health_regen", "life_on_hit"]},
	"sapphire": {"name": "Szafir", "pool": ["mana", "mana_regen", "spell_damage"]},
	"emerald": {"name": "Szmaragd", "pool": ["dexterity", "dodge_chance", "move_speed"]},
	"topaz": {"name": "Topaz", "pool": ["strength", "physical_damage", "damage"]},
	"amethyst": {"name": "Ametyst", "pool": ["intelligence", "cooldown_reduction", "spell_damage"]},
	"onyx": {"name": "Onyks", "pool": ["vitality", "armor", "damage_percent"]},
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
const QUEST := "jeweler_gem"
const ROUGH_GEM := "rough_gem"
const SOCKET_ICON := preload("res://assets/ui/socket.png")
const COLORS := {"ruby": "ff6b6b", "sapphire": "6ea8ff", "emerald": "5fdc7d", "topaz": "ffc24a", "amethyst": "c07bff", "onyx": "c8c8d2"}

## Czy kamienie i gniazda już wypadają (zadanie jubilera wykonane) - ustawia gracz po wczytaniu i po zadaniu.
static var unlocked := false


static func is_gem(id: String) -> bool:
	return Items.get_data(id).has("gem")


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
	var stats := {}
	for stat: String in recipe["affixes"]:
		var value: float = recipe["affixes"][stat]
		stats[stat] = value if Loot._step(stat) > 0.0 else int(value)
	recipe["affixes"] = stats
	Items.generated[id] = {
		"name": "%s (%s)" % [KINDS[kind]["name"], CUTS[cut].to_lower()],
		"description": "Kamień szlachetny. Jubiler Dobromir osadzi go w gnieździe przedmiotu - premie działają, dopóki kamień w nim tkwi.",
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
	var parts: Array[String] = []
	for stat: String in gem["affixes"]:
		parts.append(Items._stat_text(stat, gem["affixes"][stat]))
	return "[color=#%s]%s (%s)[/color]: %s" % [COLORS[gem["kind"]], KINDS[gem["kind"]]["name"],
			CUTS[int(gem["cut"])].to_lower(), ", ".join(parts)]


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


## Łączenie: trzy kamienie tego samego szlifu (dowolnych rodzajów) -> jeden lepszego szlifu, rodzaju jednego z nich.
static func combine(gem_ids: Array) -> String:
	var kinds: Array = gem_ids.map(func(gem_id: String) -> String: return Items.get_data(gem_id)["gem"]["kind"])
	var cut: int = Items.get_data(gem_ids[0])["gem"]["cut"]
	for gem_id: String in gem_ids:
		Items.generated.erase(gem_id)
	return roll(kinds.pick_random(), mini(cut + 1, CUTS.size() - 1))
