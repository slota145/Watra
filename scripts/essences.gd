class_name Essences
## Esencje legend (końcówka gry): legenda wrzucona w Watrę (za żar) przepada, a gracz dostaje Esencję z jej efektem
## legendarnym. Siła esencji to losowo 40-80% siły legendy na jej poziomie zaklęcia (na Ołtarzu Welesa w lochu -
## za darmo i 60-100%). Esencja to wylosowany przedmiot (Items.generated, przepis z "essence") i pasuje:
## - do gniazda esencji w przedmiocie tego samego rodzaju (broń / zbroja / biżuteria) - gniazdo dorabia kowal
##   Bronisław za Serce Kryształu (z Kryształu Watry od 3. stopnia lochu) i złoto, w rzadkim przedmiocie albo drożej
##   w legendzie; wyjęcie z gniazda niszczy esencję, chyba że zapłaci się kowalowi (EssenceWindow);
## - do gniazda legendarnego w drzewku broni (SkillBook) - dowolna esencja, działa tylko z bronią drzewka.
## Kilka źródeł tego samego efektu łączy Equipment.effect_power (szanse jak niezależne losowania, efekty liczone
## w sztukach - najsilniejszy plus połowa reszty).

const GROUPS := {"weapon": "weapon", "helmet": "armor", "chest": "armor", "gloves": "armor", "boots": "armor",
		"earring": "jewelry", "ring": "jewelry", "necklace": "jewelry", "belt": "armor"}
const GROUP_NAMES := {"weapon": "broń", "armor": "zbroja", "jewelry": "biżuteria"}
const COLORS := {"weapon": "ff8a4a", "armor": "6fb4ff", "jewelry": "c58bff"}
const SOCKET_ICON := preload("res://assets/ui/socket_legend.png")
const ICONS := {"weapon": preload("res://assets/items/essence_weapon.png"), "armor": preload("res://assets/items/essence_armor.png"),
		"jewelry": preload("res://assets/items/essence_jewelry.png")}
## Siła esencji względem legendy: w Watrze i na Ołtarzu Welesa.
const POWER_WATRA := Vector2(0.4, 0.8)
const POWER_ALTAR := Vector2(0.6, 1.0)
## Żar za wyciągnięcie w Watrze: podstawa + za poziom przedmiotu + za poziom zaklęcia.
const EMBER_BASE := 60
const EMBER_PER_LEVEL := 4
const EMBER_PER_ENCHANT := 20
## Gniazdo esencji u kowala: Serca Kryształu i złoto (rzadki przedmiot / legenda).
const HEART := "crystal_heart"
const SOCKET_HEARTS := {"rare": 1, "legendary": 3}
const SOCKET_GOLD := {"rare": 800, "legendary": 2500}
const SOCKET_GOLD_PER_LEVEL := 25
## Wyjęcie esencji z gniazda bez niszczenia (u kowala, w drzewku tak samo).
const SAVE_GOLD := 500
const SAVE_GOLD_PER_LEVEL := 15
## Serce Kryształu z Kryształu Watry (od stopnia HEART_MIN_TIER) i ze skarbca strażnika.
const HEART_MIN_TIER := 3
const HEART_CHANCE := 0.3
const HEART_PER_TIER := 0.1
const HEART_VAULT_CHANCE := 0.2
## Ołtarz Welesa: szansa na ukrytą komnatę w lochu (w trybie deweloperskim zawsze).
const ALTAR_CHANCE := 0.2


static func is_essence(id: String) -> bool:
	return Items.get_data(id).has("essence")


static func is_legend(id: String) -> bool:
	var data := Items.get_data(id)
	return id != "" and data.get("rarity", "") == "legendary" and data.has("effect") and not data.has("essence")


## Rodzaj miejsca przedmiotu: "weapon", "armor" albo "jewelry" ("" - nie wyposażenie).
static func group_of(id: String) -> String:
	return GROUPS.get(Items.get_data(id).get("slot", ""), "")


## Ile żaru kosztuje wyciągnięcie esencji z legendy w Watrze.
static func ember_cost(id: String, enchant := 0) -> int:
	return EMBER_BASE + EMBER_PER_LEVEL * Items.item_level(id) + EMBER_PER_ENCHANT * enchant


## Wyciąga esencję z legendy (legenda przepada - usuwa ją wołający); zwraca id esencji.
static func extract(id: String, enchant := 0, altar := false) -> String:
	var effect: Dictionary = Items.get_data(id)["effect"]
	var span := POWER_ALTAR if altar else POWER_WATRA
	var power := snappedf(randf_range(span.x, span.y), 0.01)
	var base := Items.effect_chance(id, enchant)
	# koszt (np. many Korony Peruna) - im słabsza esencja, tym drożej
	var value := base / power if float(effect.get("per_level", 0.0)) < 0.0 else base * power
	var source: String = Items.get_data(id).get("base", id)
	return register({"essence": true, "kind": effect["kind"], "value": snappedf(value, 0.0001), "power": power,
			"group": group_of(id), "source": source, "source_name": Items.get_data(source).get("name", Items.get_data(id)["name"]),
			"inverse": float(effect.get("per_level", 0.0)) < 0.0})


## Rejestruje esencję z przepisu (także przy wczytaniu zapisu - Loot.import).
static func register(recipe: Dictionary, id := "") -> String:
	if id == "":
		Items.generated_serial += 1
		id = Loot.PREFIX + str(Items.generated_serial)
	var group: String = recipe.get("group", "jewelry")
	recipe["value"] = float(recipe["value"])
	recipe["power"] = float(recipe.get("power", 0.5))
	Items.generated[id] = {
		"name": Lang.t("Esencja: %s") % source_name(recipe),
		"description": Lang.t("Efekt legendy zamknięty w płomieniu (%d%% jej siły). Pasuje do gniazda esencji w przedmiocie (%s) i do gniazda legendarnego w drzewku broni - przeciągnij ją na przedmiot albo gniazdo.") % [roundi(recipe["power"] * 100.0), Lang.t(GROUP_NAMES[group])],
		"name_lang": TranslationServer.get_locale(),
		"icon": ICONS[group], "rarity": "legendary", "essence": recipe,
		"effect": {"kind": recipe["kind"], "chance": recipe["value"], "per_level": 0.0},
		"sell_price": 50, "recipe": recipe,
	}
	return id


## Opis esencji w gnieździe: "Esencja: Łuk Swaroga - 2 strzały ...".
static func socket_text(essence: Dictionary) -> String:
	if essence.is_empty():
		return Lang.t("Puste gniazdo esencji")
	return "[color=#%s]%s[/color] - %s" % [COLORS.get(essence.get("group", ""), "ffb060"), Lang.t("Esencja: %s") % source_name(essence), effect_text(essence)]


## Nazwa legendy, z której pochodzi esencja, w obecnym języku (z id legendy; zapisane "source_name" - gdy legendy
## już nie ma w bazie).
static func source_name(essence: Dictionary) -> String:
	var source: String = essence.get("source", "")
	var name: String = Items.get_data(source).get("name", "") if source != "" and not Loot.is_generated(source) else ""
	return Lang.t(name if name != "" else str(essence.get("source_name", "")))


static func effect_text(essence: Dictionary) -> String:
	var kind: String = essence["kind"]
	var value: float = essence["value"]
	var shown := str(roundi(value)) if kind in Items.COUNT_EFFECTS else "%d%%" % roundi(value * 100.0)
	return Items.effect_text(kind, shown)


static func plain_text(essence: Dictionary) -> String:
	return RegEx.create_from_string("\\[/?color[^\\]]*\\]").sub(socket_text(essence), "", true)


## Łączenie kilku źródeł jednego efektu: [[wartość, odwrotny]]; efekty w sztukach - najsilniejszy plus połowa
## reszty (koszt - najtańszy), szanse - jak niezależne losowania.
static func combine(kind: String, values: Array) -> float:
	if values.is_empty():
		return 0.0
	if kind in Items.COUNT_EFFECTS:
		if values.any(func(entry: Array) -> bool: return entry[1]):
			return values.map(func(entry: Array) -> float: return entry[0]).min()
		var sorted := values.map(func(entry: Array) -> float: return entry[0])
		sorted.sort()
		var total: float = sorted.pop_back()
		for rest: float in sorted:
			total += rest * 0.5
		return total
	var miss := 1.0
	for entry: Array in values:
		miss *= 1.0 - float(entry[0])
	return 1.0 - miss


# ---------------------------------------------------------------- gniazda esencji w przedmiotach
static func socket_of(id: String) -> Variant:
	return Items.get_data(id).get("essence_socket")


static func has_socket(id: String) -> bool:
	return socket_of(id) != null


## Czy kowal może dorobić gniazdo esencji: rzadki przedmiot albo legenda (wylosowane), bez gniazda esencji.
static func can_socket(id: String) -> bool:
	var rarity: String = Items.get_data(id).get("rarity", "common")
	return Items.is_equippable(id) and group_of(id) != "" and SOCKET_HEARTS.has(rarity) and not has_socket(id) \
			and Items.generated.has(id)


static func socket_hearts(id: String) -> int:
	return SOCKET_HEARTS.get(Items.get_data(id).get("rarity", "rare"), 1)


static func socket_gold(id: String) -> int:
	return SOCKET_GOLD.get(Items.get_data(id).get("rarity", "rare"), 800) + SOCKET_GOLD_PER_LEVEL * Items.item_level(id)


static func save_gold(level: int) -> int:
	return SAVE_GOLD + SAVE_GOLD_PER_LEVEL * level


static func add_socket(id: String) -> void:
	var recipe := (Items.generated[id]["recipe"] as Dictionary).duplicate(true)
	recipe["essence_socket"] = {}
	Loot.register(recipe, id)


## Osadza esencję `essence_id` w gnieździe przedmiotu `id` (esencja jako przedmiot przestaje istnieć).
static func insert(id: String, essence_id: String) -> void:
	var recipe := (Items.generated[id]["recipe"] as Dictionary).duplicate(true)
	recipe["essence_socket"] = (Items.generated[essence_id]["recipe"] as Dictionary).duplicate(true)
	Loot.register(recipe, id)
	Items.generated.erase(essence_id)


## Opróżnia gniazdo; `keep` - esencja wraca jako przedmiot (id), inaczej przepada ("").
static func remove(id: String, keep: bool) -> String:
	var recipe := (Items.generated[id]["recipe"] as Dictionary).duplicate(true)
	var essence: Dictionary = recipe["essence_socket"]
	recipe["essence_socket"] = {}
	Loot.register(recipe, id)
	return register(essence.duplicate(true)) if keep and not essence.is_empty() else ""


## Czy esencja pasuje do przedmiotu (ten sam rodzaj miejsca).
static func fits(essence_id: String, item_id: String) -> bool:
	return is_essence(essence_id) and Items.get_data(essence_id)["essence"]["group"] == group_of(item_id)
