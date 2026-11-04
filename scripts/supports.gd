class_name Supports
## Kamienie wsparcia i gniazda umiejętności (jak w Path of Exile; krok 4 dopieszczenia walki).
## - Gniazda mają tylko umiejętności aktywne (bez zwykłego ataku i regeneracji). Na start umiejętność nie ma żadnego;
##   gniazda 1-4 dorabia się Krzesiwem Nawii (SOCKET_COST - zawsze się udaje), 5. tylko Wielkim Krzesiwem.
##   Gniazda i kamienie w nich trzyma SkillBook (supports), zapis gry - przy umiejętności.
## - Kamień wsparcia pasuje tylko do umiejętności z jednym z jego tagów (DATA "tags", Skills.TAGS); "except" - umiejętności,
##   na które jego działanie nie ma wpływu (np. Echo nie powtarza teleportu). W jednej umiejętności każdy kamień raz.
## - Kamień ma poziom 1-20 (MAX_LEVEL): siła premii rośnie liniowo od "stats"[stat][0] do [1]. Kamień w gnieździe
##   zbiera doświadczenie razem z postacią (XP_SHARE) i awansuje sam; 3 takie same kamienie łączą się w 1 o
##   COMBINE_LEVELS wyższy (najwyższy z trzech + COMBINE_LEVELS).
## - Każdy kamień podnosi koszt many umiejętności ("mana" - mnożnik; mnożniki się mnożą).
## - Premie (klucze "stats"): area - obszar, more - mnożnik obrażeń (mnożniki kamieni się mnożą), speed - szybkość
##   umiejętności (i odnowienie), projectiles - dodatkowe pociski, pierce - przebicie, chain - odbicia pocisku,
##   added_<żywioł> - część obrażeń dodana jako żywioł (z szansą na jego stan), <stan>_chance - szansa na stan,
##   ignite_damage - siła podpalenia, freeze_time - dłuższe zamrożenie, shock_effect - porażeni dostają więcej,
##   dot_damage - obrażenia w czasie, echo - czar powtarza się raz, momentum - po użyciu ruch +15% i tyle obrażeń
##   przez MOMENTUM_TIME, duration - czas działania (przywołania, okrzyki).
## Działanie w umiejętnościach: Skills.tags(id) niesie znacznik umiejętności (Skills.skill_of), więc CharacterStats
## (kind_multiplier, skill_speed, area_multiplier, ailment_chance, dot_bonus) i Player.hit_enemy wiedzą, czyje to premie.

const MAX_LEVEL := 20
const MAX_SOCKETS := 5
## Krzesiwa Nawii za kolejne gniazdo (1., 2., 3., 4.); 5. gniazdo - jedno Wielkie Krzesiwo.
const SOCKET_COST: Array[int] = [1, 2, 4, 8]
const FLINT := "nawia_flint"
const GREAT_FLINT := "great_flint"
## Ile doświadczenia postaci dostaje każdy kamień w gnieździe (ułamek).
const XP_SHARE := 1.0
## Doświadczenie na kolejny poziom kamienia: XP_BASE * poziom^XP_EXPONENT (1 -> 2: 400, 19 -> 20: około 45 tys.).
const XP_BASE := 400.0
const XP_EXPONENT := 1.6
const COMBINE_COUNT := 3
const COMBINE_LEVELS := 2
## Rozpęd: czas premii po użyciu umiejętności ruchu i premia do szybkości ruchu.
const MOMENTUM_TIME := 3.0
const MOMENTUM_MOVE := 0.15
## Łańcuch: zasięg szukania kolejnego celu przez odbity pocisk.
const CHAIN_RANGE := 170.0
## Rozszczep: kąt między dodatkowymi pociskami (stopnie).
const SPLIT_SPREAD := 10.0
## Premie liczone jako liczby całkowite (zaokrąglane).
const COUNT_STATS: Array[String] = ["projectiles", "pierce", "chain", "echo"]

## Kamienie wsparcia: nazwa, tagi (pasuje do umiejętności z którymkolwiek), premie [poziom 1, poziom 20],
## mnożnik many, kolor ikony.
const DATA := {
	"area": {"name": "Rozległość", "tags": ["area"], "stats": {"area": [0.2, 0.45]}, "mana": 1.2, "color": "e0c070"},
	"split": {"name": "Rozszczep", "tags": ["projectile"], "stats": {"projectiles": [2, 2], "more": [-0.3, -0.15]},
			"mana": 1.3, "color": "d8cbb0"},
	"pierce": {"name": "Przeszycie", "tags": ["projectile"], "stats": {"pierce": [2, 4]}, "mana": 1.15, "color": "b8c4d8"},
	"chain": {"name": "Łańcuch", "tags": ["projectile"], "stats": {"chain": [1, 2], "more": [-0.15, -0.15]},
			"mana": 1.25, "color": "a0b0ff"},
	"fire_edge": {"name": "Żarowe Ostrze", "tags": ["physical"], "stats": {"added_fire": [0.2, 0.4], "ignite_chance": [0.05, 0.05]},
			"mana": 1.2, "color": "ff8a3d"},
	"frost_edge": {"name": "Mroźne Ostrze", "tags": ["physical"], "stats": {"added_ice": [0.2, 0.4], "freeze_chance": [0.05, 0.05]},
			"mana": 1.2, "color": "8fd8ff"},
	"storm_edge": {"name": "Burzowe Ostrze", "tags": ["physical"], "stats": {"added_lightning": [0.2, 0.4], "shock_chance": [0.05, 0.05]},
			"mana": 1.2, "color": "ffe45c"},
	"ember": {"name": "Żar", "tags": ["fire"], "stats": {"ignite_chance": [0.15, 0.3], "ignite_damage": [0.2, 0.5]},
			"mana": 1.15, "color": "ff6a2a"},
	"rime": {"name": "Szron", "tags": ["ice"], "stats": {"freeze_chance": [0.1, 0.25], "freeze_time": [0.3, 0.6]},
			"mana": 1.15, "color": "6ec8ff"},
	"discharge": {"name": "Wyładowanie", "tags": ["lightning"], "stats": {"shock_chance": [0.15, 0.3], "shock_effect": [0.1, 0.2]},
			"mana": 1.15, "color": "fff07a"},
	"venom": {"name": "Jad", "tags": ["dot"], "stats": {"dot_damage": [0.25, 0.55]}, "mana": 1.15, "color": "8fdc5a"},
	"brutal": {"name": "Okrutny Cios", "tags": ["hit"], "stats": {"more": [0.25, 0.5], "speed": [-0.1, -0.1]},
			"mana": 1.3, "color": "ff7a6a"},
	"fury": {"name": "Furia", "tags": ["attack"], "stats": {"speed": [0.15, 0.3], "more": [-0.1, -0.1]},
			"mana": 1.2, "color": "ffa060"},
	"echo": {"name": "Echo Rusałki", "tags": ["spell"], "stats": {"echo": [1, 1], "more": [-0.35, -0.2]},
			"mana": 1.4, "color": "c79bff"},
	"momentum": {"name": "Rozpęd", "tags": ["movement"], "stats": {"momentum": [0.15, 0.3]}, "mana": 1.1, "color": "7fe08a"},
	"warlord": {"name": "Watażka", "tags": ["summon"], "stats": {"more": [0.2, 0.4], "duration": [0.25, 0.5]},
			"mana": 1.25, "color": "d0a0ff"},
	"herald": {"name": "Donośny Głos", "tags": ["cry"], "stats": {"area": [0.25, 0.5], "duration": [0.25, 0.5]},
			"mana": 1.2, "color": "ff9a7a"},
}
## Kolejność na liście (okno K, encyklopedia, tryb deweloperski).
const ORDER: Array[String] = ["area", "split", "pierce", "chain", "fire_edge", "frost_edge", "storm_edge", "ember", "rime",
		"discharge", "venom", "brutal", "fury", "echo", "momentum", "warlord", "herald"]
## Umiejętności, na które kamień nie działa, choć mają jego tag (nie da się go tam włożyć).
const EXCEPT := {
	"split": ["arrow_rain", "venom_arrows"],
	"pierce": ["arrow_rain", "venom_arrows", "fireball", "chain_lightning", "ball_lightning"],
	"chain": ["arrow_rain", "venom_arrows", "fireball", "ball_lightning", "seeker"],
	"echo": ["spectral_blades", "storm_call", "blink", "mana_shield", "rune_stone"],
}
## Opisy premii: wzór z jedną liczbą (procent albo liczba całkowita).
const STAT_TEXTS := {
	"area": "+%d%% obszaru", "more": "%+d%% obrażeń", "speed": "%+d%% szybkości umiejętności",
	"projectiles": "+%d dodatkowe pociski", "pierce": "Pocisk przebija %d dodatkowych wrogów",
	"chain": "Pocisk odbija się do %d kolejnych wrogów",
	"added_fire": "%d%% obrażeń dodane jako ogień", "added_ice": "%d%% obrażeń dodane jako lód",
	"added_lightning": "%d%% obrażeń dodane jako piorun",
	"ignite_chance": "+%d%% szansy na podpalenie", "freeze_chance": "+%d%% szansy na zamrożenie",
	"shock_chance": "+%d%% szansy na porażenie", "ignite_damage": "+%d%% obrażeń podpalenia",
	"freeze_time": "+%d%% czasu zamrożenia", "shock_effect": "Porażeni wrogowie dostają +%d%% obrażeń",
	"dot_damage": "+%d%% obrażeń w czasie", "echo": "Czar powtarza się %d raz",
	"momentum": "Po użyciu przez 3 s: +15%% szybkości ruchu i +%d%% obrażeń",
	"duration": "+%d%% czasu działania",
}


static func is_support(id: String) -> bool:
	return Items.get_data(id).has("support")


static func name_of(kind: String) -> String:
	return Lang.t(str(DATA.get(kind, {}).get("name", kind)))


## Wartość premii kamienia na poziomie `level`.
static func value(kind: String, stat: String, level: int) -> float:
	var span: Array = DATA[kind]["stats"].get(stat, [0.0, 0.0])
	var t := clampf((level - 1) / float(MAX_LEVEL - 1), 0.0, 1.0)
	var result := lerpf(float(span[0]), float(span[1]), t)
	return float(roundi(result)) if stat in COUNT_STATS else result


## Czy kamień pasuje do umiejętności (jeden ze wspólnych tagów, umiejętność z gniazdami, nie na liście EXCEPT).
static func fits(kind: String, skill: String) -> bool:
	if not DATA.has(kind) or not has_sockets(skill) or skill in EXCEPT.get(kind, []):
		return false
	var tags := Skills.tags(skill)
	for tag: String in DATA[kind]["tags"]:
		if tag in tags:
			return true
	return false


## Czy umiejętność może mieć gniazda (aktywne umiejętności, bez regeneracji).
static func has_sockets(skill: String) -> bool:
	return Skills.DATA.has(skill) and Skills.get_data(skill)["type"] in ["active", "strike", "combo", "skill"]


## Doświadczenie potrzebne na kolejny poziom kamienia (0 - poziom maksymalny).
static func xp_to_next(level: int) -> int:
	return 0 if level >= MAX_LEVEL else roundi(XP_BASE * pow(level, XP_EXPONENT))


## Ile krzesiw (i jakich) kosztuje kolejne gniazdo umiejętności, która ma ich `sockets`: [id przedmiotu, liczba]; [] - koniec.
static func socket_cost(sockets: int) -> Array:
	if sockets < SOCKET_COST.size():
		return [FLINT, SOCKET_COST[sockets]]
	if sockets < MAX_SOCKETS:
		return [GREAT_FLINT, 1]
	return []


## Nowy kamień wsparcia (przedmiot) danego rodzaju (losowy, gdy "") i poziomu.
static func roll(kind := "", level := 1) -> String:
	if kind == "":
		kind = ORDER.pick_random()
	return register({"support": kind, "level": level, "xp": 0})


## Rejestruje kamień wsparcia z przepisu ({"support": rodzaj, "level", "xp"}; także przy wczytaniu - Loot.import).
static func register(recipe: Dictionary, id := "") -> String:
	var kind: String = recipe["support"]
	if not DATA.has(kind):
		return ""
	if id == "":
		Items.generated_serial += 1
		id = Loot.PREFIX + str(Items.generated_serial)
	recipe["level"] = clampi(int(recipe.get("level", 1)), 1, MAX_LEVEL)
	recipe["xp"] = int(recipe.get("xp", 0))
	Items.generated[id] = {
		"name": Lang.t("%s (poziom %d)") % [name_of(kind), recipe["level"]],
		"short_name": name_of(kind),
		"description": Lang.t("Kamień wsparcia. Osadza się w gnieździe umiejętności w oknie K (umiejętność z tagiem: %s). W gnieździe zbiera doświadczenie i awansuje.")
				% tags_text(kind),
		"icon": icon(kind), "rarity": "rare" if int(recipe["level"]) >= 15 else "magic",
		"support": {"kind": kind, "level": recipe["level"]}, "stats": {}, "sell_price": 20 + 4 * int(recipe["level"]),
		"recipe": recipe, "name_lang": TranslationServer.get_locale(),
	}
	return id


static func icon(kind: String) -> Texture2D:
	return load("res://assets/items/supports/%s.png" % kind)


## Tagi kamienia słowami ("pocisk", "atak").
static func tags_text(kind: String) -> String:
	var names: Array[String] = []
	for tag: String in DATA[kind]["tags"]:
		names.append(Skills.tag_name(tag))
	return Lang.join(names)


## Linie działania kamienia na poziomie (z kosztem many).
static func effect_lines(kind: String, level: int) -> Array[String]:
	var lines: Array[String] = []
	for stat: String in DATA[kind]["stats"]:
		var amount := value(kind, stat, level)
		var number := roundi(amount) if stat in COUNT_STATS else roundi(amount * 100.0)
		lines.append(Lang.t(STAT_TEXTS[stat]) % number)
	lines.append(Lang.t("Koszt many umiejętności: x%s") % Skills.decimal(float(DATA[kind]["mana"]), 2))
	return lines


## Opis kamienia w BBCode (dymek i okno K): nazwa, poziom, tagi, działanie, doświadczenie.
static func describe(recipe: Dictionary) -> String:
	var kind: String = recipe["support"]
	var level := int(recipe.get("level", 1))
	var lines: Array[String] = ["[color=#%s]%s[/color]" % [DATA[kind]["color"], name_of(kind)]]
	lines.append(Lang.t("Kamień wsparcia - poziom %d/%d") % [level, MAX_LEVEL])
	lines.append(Lang.t("Pasuje do: %s") % Skills.tags_bbcode(DATA[kind]["tags"]))
	for line in effect_lines(kind, level):
		lines.append(line)
	if level < MAX_LEVEL:
		lines.append(Lang.t("Doświadczenie: %d/%d") % [int(recipe.get("xp", 0)), xp_to_next(level)])
	return "\n".join(lines)


## Dodaje doświadczenie przepisowi kamienia (awans, gdy się zbierze). Zwraca true, gdy kamień awansował.
static func add_xp(recipe: Dictionary, amount: int) -> bool:
	var level := int(recipe.get("level", 1))
	if level >= MAX_LEVEL or amount <= 0:
		return false
	var xp := int(recipe.get("xp", 0)) + amount
	var leveled := false
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		leveled = true
	recipe["level"] = level
	recipe["xp"] = 0 if level >= MAX_LEVEL else xp
	return leveled


## Pola plecaka z kamieniami danego rodzaju.
static func slots_of(inventory: Inventory, kind: String) -> Array[int]:
	var found: Array[int] = []
	for index in inventory.slots.size():
		var slot: Dictionary = inventory.slots[index]
		if not slot.is_empty() and Items.get_data(slot["id"]).get("support", {}).get("kind", "") == kind:
			found.append(index)
	return found


## Łączy COMBINE_COUNT kamieni tego rodzaju z plecaka w jeden o COMBINE_LEVELS poziomy wyższy od najlepszego.
## Zwraca "" albo powód, dla którego się nie da.
static func combine(inventory: Inventory, kind: String) -> String:
	var found := slots_of(inventory, kind)
	if found.size() < COMBINE_COUNT:
		return Lang.t("Potrzeba %d takich samych kamieni wsparcia.") % COMBINE_COUNT
	# najsłabsze idą pierwsze, najlepszy wyznacza poziom
	found.sort_custom(func(a: int, b: int) -> bool:
		return int(Items.get_data(inventory.slots[a]["id"])["support"]["level"]) < int(Items.get_data(inventory.slots[b]["id"])["support"]["level"]))
	found = found.slice(found.size() - COMBINE_COUNT)
	var best := 1
	for index in found:
		best = maxi(best, int(Items.get_data(inventory.slots[index]["id"])["support"]["level"]))
	for index in found:
		var id: String = inventory.slots[index]["id"]
		inventory.take_one(index)
		Items.generated.erase(id)
	inventory.add_item(register({"support": kind, "level": mini(best + COMBINE_LEVELS, MAX_LEVEL), "xp": 0}), 1)
	return ""
