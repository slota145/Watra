class_name SkarbnikOffer
## Oferta Skarbnika (mechanika lochu "skarbnik", stałe SKA_* w Dungeons; obiekt w lochu - scripts/skarbnik.gd).
## Oferta to słownik (da się zapisać w JSON):
##   {"uid": String, "level": int - poziom przedmiotów, "tier": int - stopień lochu, "step": int - wzmocnienia,
##    "rewards": [nagrody]}
## Nagroda: {"kind": "item", "recipe": przepis Loot}, {"kind": "rune" / "stone", "id": String, "base": int}
## (sztuk: base, więcej z każdym wzmocnieniem - count_of) albo {"kind": "gem", "recipe": przepis Gems}.
##
## Wzmocnienie działa na całą ofertę naraz: premiom przedmiotów rosną tiery (rodzaje bez zmian) aż do sufitu,
## runom i kamieniom zaklinania - liczba sztuk, kamieniom szlachetnym - szlif. Ostatnie wzmocnienie
## (SKA_MAX_STEPS) podnosi wszystkie premie na sufit i przemienia przedmioty w losowe legendy tego samego rodzaju.
## Przelosowanie losuje od nowa rodzaje premii (tiery zostają), rodzaj kamienia i rodzaj runy.
##
## Zabezpieczenie przed wczytywaniem zapisu - księga ofert (plik obok zapisów, LEDGER): w chwili wzmocnienia albo
## przelosowania oferta zapisuje się w księdze jako „zagrożona”, dopiero wygrana w falach ją zabezpiecza. Zapis gry
## trzyma tylko identyfikator oferty (Player.skarbnik_uid); wczytana gra bierze ofertę z księgi, a zagrożona
## (gracz wyszedł albo wczytał grę w trakcie fal) przepada. Nagroda wzięta albo stracona znika z księgi, więc
## starszy zapis jej nie przywróci.

const LEDGER := "user://skarbnik.json"
## Plik księgi (testy podmieniają na własny).
static var ledger_path := LEDGER
## Przepis -> identyfikator zarejestrowanego przedmiotu (żeby okno nie rejestrowało go przy każdym otwarciu).
static var _shown := {}


## Nowa oferta na poziomie lochu `level` i stopniu `tier` (stopień wybiera runy).
static func roll(level: int, tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var item_level := clampi(level + Dungeons.SKA_ITEM_LEVEL_BONUS, 1, Loot.MAX_ITEM_LEVEL)
	var offer := {"uid": "%d_%d" % [int(Time.get_unix_time_from_system()), rng.randi()], "level": item_level,
			"tier": tier, "step": 0, "rewards": []}
	var count := Dungeons.SKA_OFFER + (1 if rng.randf() < Dungeons.SKA_OFFER_EXTRA else 0)
	var kinds := Dungeons.SKA_REWARDS.duplicate()
	if not Gems.unlocked:
		kinds.erase("gem")
	for i in count:
		var kind := "item" if i == 0 else Dungeons.weighted(rng, kinds)
		(offer["rewards"] as Array).append(_roll_reward(kind, offer, rng))
	return offer


static func _roll_reward(kind: String, offer: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var level := int(offer["level"])
	match kind:
		"rune":
			return {"kind": "rune", "id": ItemCraft.roll_rune(int(offer["tier"]), rng),
					"base": rng.randi_range(Dungeons.SKA_RUNES.x, Dungeons.SKA_RUNES.y)}
		"stone":
			var id := _roll_stone(rng)
			var span: Array = Dungeons.SKA_STONES[id]
			return {"kind": "stone", "id": id, "base": rng.randi_range(span[0], span[1])}
		"gem":
			var gem := Gems.roll("", Gems.cut_for_level(level), true)
			return {"kind": "gem", "recipe": Items.get_data(gem)["recipe"].duplicate(true)}
	var line: String = ItemBases.LINES.keys()[rng.randi_range(0, ItemBases.LINES.size() - 1)]
	var id := Loot.generate(Loot.base_for(line, level), Loot.RARE, level)
	var recipe: Dictionary = Items.get_data(id)["recipe"].duplicate(true)
	recipe.erase("sockets")
	return {"kind": "item", "recipe": recipe}


static func _roll_stone(rng: RandomNumberGenerator, other := "") -> String:
	var weights := {}
	for id: String in Dungeons.SKA_STONES:
		if id != other:
			weights[id] = float(Dungeons.SKA_STONES[id][2])
	return Dungeons.weighted(rng, weights)


## Sufit tierów premii dla poziomu przedmiotu (najlepszy tier, do jakiego dochodzi wzmacnianie).
static func ceiling_tier(item_level: int) -> int:
	return maxi(1, Loot.top_tier(item_level) - Dungeons.SKA_CEILING_EXTRA)


## Ile sztuk runy / kamienia zaklinania daje nagroda przy obecnym wzmocnieniu.
static func count_of(reward: Dictionary, step: int) -> int:
	return roundi(int(reward.get("base", 1)) * (1.0 + Dungeons.SKA_COUNT_GROWTH * step))


## Czy można jeszcze wzmocnić ofertę.
static func can_strengthen(offer: Dictionary) -> bool:
	return int(offer["step"]) < Dungeons.SKA_MAX_STEPS


## Ile fal czeka przy wzmocnieniu (`reroll` - przy przelosowaniu, bez wzrostu siły).
static func waves_for(offer: Dictionary, reroll := false) -> int:
	var step := int(offer["step"]) if reroll else int(offer["step"]) + 1
	return Dungeons.SKA_WAVES[clampi(step, 1, Dungeons.SKA_WAVES.size()) - 1]


## Wzmocnienie oferty (od razu, przed falami - fale tylko ją zabezpieczają).
static func strengthen(offer: Dictionary, rng: RandomNumberGenerator) -> void:
	if not can_strengthen(offer):
		return
	offer["step"] = int(offer["step"]) + 1
	var final := int(offer["step"]) >= Dungeons.SKA_MAX_STEPS
	var level := int(offer["level"])
	for reward: Dictionary in offer["rewards"]:
		match str(reward["kind"]):
			"item":
				var recipe: Dictionary = reward["recipe"]
				var ceiling := ceiling_tier(int(recipe.get("level", level)))
				var tiers: Dictionary = recipe.get("tiers", {})
				for stat: String in recipe["affixes"]:
					var tier := ceiling if final else maxi(ceiling, int(tiers.get(stat, Loot.TIERS)) - Dungeons.SKA_TIER_STEP)
					_set_affix(recipe, stat, tier, rng)
				if final:
					_to_legend(reward, rng)
			"gem":
				var recipe: Dictionary = reward["recipe"]
				var cut := mini(int(recipe["cut"]) + 1, Gems.CUTS.size() - 1)
				recipe["cut"] = cut
				for stat: String in recipe["affixes"]:
					recipe["affixes"][stat] = Gems._value(stat, cut)


## Przelosowanie: nowe rodzaje premii (te same tiery), inny kamień szlachetny, inna runa i inny kamień zaklinania.
static func reroll(offer: Dictionary, rng: RandomNumberGenerator) -> void:
	for reward: Dictionary in offer["rewards"]:
		match str(reward["kind"]):
			"item":
				var recipe: Dictionary = reward["recipe"]
				var base: String = recipe["base"]
				var pool: Array = Loot.POOLS[Items.get_data(base)["slot"]].duplicate()
				var tiers: Array = []
				for stat: String in recipe["affixes"]:
					tiers.append(int(recipe.get("tiers", {}).get(stat, Loot.TIERS)))
				recipe["affixes"] = {}
				recipe["tiers"] = {}
				for tier: int in tiers:
					if pool.is_empty():
						break
					_set_affix(recipe, pool.pop_at(rng.randi_range(0, pool.size() - 1)), tier, rng)
				recipe["name_stats"] = recipe["affixes"].keys().slice(0, 2) if recipe["quality"] != Loot.LEGENDARY else []
			"rune":
				var id := str(reward["id"])
				for attempt in 8:
					id = ItemCraft.roll_rune(int(offer["tier"]), rng)
					if id != reward["id"]:
						break
				reward["id"] = id
			"stone":
				var id := _roll_stone(rng, str(reward["id"]))
				var span: Array = Dungeons.SKA_STONES[id]
				var old: Array = Dungeons.SKA_STONES[str(reward["id"])]
				# ta sama część zakresu sztuk (kamienie uświęcone idą dziesiątkami)
				var t := inverse_lerp(float(old[0]), float(old[1]), float(reward["base"])) if old[1] > old[0] else 0.5
				reward["id"] = id
				reward["base"] = roundi(lerpf(float(span[0]), float(span[1]), clampf(t, 0.0, 1.0)))
			"gem":
				var recipe: Dictionary = reward["recipe"]
				var kinds := Gems.KIND_ORDER.filter(func(k: String) -> bool: return k != recipe["kind"])
				var gem := Gems.roll(kinds[rng.randi_range(0, kinds.size() - 1)], int(recipe["cut"]), true)
				reward["recipe"] = Items.get_data(gem)["recipe"].duplicate(true)


static func _set_affix(recipe: Dictionary, stat: String, tier: int, rng: RandomNumberGenerator) -> void:
	var span := Loot.tier_range(stat, tier)
	var step := Loot._step(stat)
	recipe["affixes"][stat] = snappedf(rng.randf_range(span[0], span[1]), step) if step > 0.0 \
			else float(rng.randi_range(int(span[0]), int(span[1])))
	if not recipe.has("tiers"):
		recipe["tiers"] = {}
	recipe["tiers"][stat] = tier


## Legendy, w które może się przemienić przedmiot: to samo miejsce na postaci, broń - ten sam rodzaj broni.
static func legend_bases(base: String) -> Array[String]:
	var data := Items.get_data(base)
	var result: Array[String] = []
	for id: String in Items.DATA.keys() + Legends.DATA.keys():
		var other := Items.get_data(id)
		if other.get("rarity", "") != Loot.LEGENDARY or other.get("slot", "") != data.get("slot", "-"):
			continue
		if data.has("weapon") and other.get("weapon", {}).get("type", "") != data["weapon"]["type"]:
			continue
		result.append(id)
	return result


static func _to_legend(reward: Dictionary, rng: RandomNumberGenerator) -> void:
	var recipe: Dictionary = reward["recipe"]
	var options := legend_bases(str(recipe["base"]))
	if options.is_empty():
		return
	recipe["base"] = options[rng.randi_range(0, options.size() - 1)]
	recipe["quality"] = Loot.LEGENDARY
	recipe["name_stats"] = []


## Przedmiot nagrody do pokazania w oknie: [id, sztuk] (przedmioty i kamienie szlachetne rejestrowane raz).
static func shown(reward: Dictionary, step: int) -> Array:
	match str(reward["kind"]):
		"rune", "stone":
			return [str(reward["id"]), count_of(reward, step)]
	var key := JSON.stringify(reward["recipe"])
	if not _shown.has(key) or Items.get_data(_shown[key]).is_empty():
		_shown[key] = _register(reward)
	return [_shown[key], 1]


static func _register(reward: Dictionary) -> String:
	var recipe: Dictionary = reward["recipe"].duplicate(true)
	if str(reward["kind"]) == "gem":
		return Gems.register(recipe)
	return Loot.register(recipe)


## Daje nagrodę graczowi: [id, sztuk] (przedmiot zawsze nowy - podgląd z okna mógł zostać w pamięci).
static func give(reward: Dictionary, step: int) -> Array:
	if str(reward["kind"]) in ["rune", "stone"]:
		return [str(reward["id"]), count_of(reward, step)]
	return [_register(reward), 1]


# ---------------------------------------------------------------- księga ofert
static func _read() -> Dictionary:
	if not FileAccess.file_exists(ledger_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ledger_path))
	return parsed if parsed is Dictionary else {}


static func _write(ledger: Dictionary) -> void:
	var file := FileAccess.open(ledger_path, FileAccess.WRITE)
	if file == null:
		push_error("Nie udało się zapisać księgi Skarbnika: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(ledger))
	file.close()


## Zapisuje ofertę w księdze; `risk` - zagrożona (trwają fale).
static func persist(offer: Dictionary, risk: bool) -> void:
	var ledger := _read()
	ledger[str(offer["uid"])] = {"offer": offer.duplicate(true), "risk": risk}
	_write(ledger)


## Oferta wzięta albo stracona - znika z księgi.
static func forget(uid: String) -> void:
	if uid == "":
		return
	var ledger := _read()
	if ledger.erase(uid):
		_write(ledger)


## Oferta z księgi przy wczytaniu gry: zabezpieczona - wraca, zagrożona albo nieznana - przepada ({}).
static func restore(uid: String) -> Dictionary:
	if uid == "":
		return {}
	var entry: Variant = _read().get(uid)
	if not entry is Dictionary or bool(entry.get("risk", true)):
		forget(uid)
		return {}
	return entry["offer"]
