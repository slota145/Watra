class_name VillageServices
## Oferty usług osady do OfferWindow: posiłki u karczmarza (mięso z plecaka/magazynu + złoto),
## błogosławieństwa w kaplicy (złoto rosnące z poziomem) i bestiariusz mędrca (trofea -> stałe
## +3% obrażeń przeciw gatunkowi za stopień). Każda akcja zwraca komunikat do paska okna.

const MEAT := "meat"


static func offers(kind: String, player: Player, npc: Node) -> Dictionary:
	match kind:
		"meals":
			return _meals(player, npc)
		"blessing":
			return _blessings(player, npc)
		"bestiary":
			return _bestiary(player, npc)
		"reforge":
			return _reforge(player, npc)
		"elixirs":
			return _elixirs(player, npc)
		"respec":
			return _respec(player, npc)
		"marks":
			return _marks(player, npc)
	return {}


static func _time_left(player: Player, group: String, id: String) -> String:
	var entry: Dictionary = player.boons.active.get(group, {})
	if entry.get("id", "") != id:
		return ""
	return "działa: %d min" % ceili(float(entry["left"]) / 60.0)


static func _meals(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	for id: String in ["stew", "roast", "broth"]:
		var data: Dictionary = Boons.DEFS[id]
		var meat: int = data["meat"]
		var gold := Boons.gold_cost(id, player.stats.level)
		var have := player.count_owned(MEAT)
		rows.append({
			"name": data["name"], "icon": Items.get_data(MEAT)["icon"],
			"text": "%s przez %d min." % [data["description"], int(data["time"] / 60.0)],
			"cost": "Mięso: %d/%d   Złoto: %d" % [mini(have, meat), meat, gold],
			"enabled": have >= meat and player.stats.gold >= gold,
			"state": _time_left(player, "meal", id), "button": "Zamów",
			"action": func() -> String:
				player.take_owned(MEAT, meat)
				player.stats.add_gold(-gold)
				player.boons.grant(id)
				Sfx.play("coins")
				Sfx.play("potion")
				npc.say(["Smacznego!", "Prosto z kotła!", "Myśliwi dziś się spisali."].pick_random())
				return "Zjedzono: %s" % data["name"],
		})
	return {"title": "Kuchnia karczmy", "rows": rows,
			"hint": "Mięso z plecaka albo z magazynu (znoszą je myśliwi). Działa jeden posiłek naraz - nowy zastępuje poprzedni."}


## Warsztat zielarki: mikstura wzmacniająca z 3 ziół (z plecaka albo magazynu) i trochę złota - trafia do plecaka.
static func _elixirs(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	var gold := Herbs.brew_gold(player.stats.level)
	var need := Herbs.HERBS_PER_ELIXIR
	for kind in Herbs.ORDER:
		var herb: Dictionary = Herbs.KINDS[kind]
		var id: String = herb["elixir"]
		var item := Items.get_data(id)
		var have := player.count_owned(herb["item"])
		var data: Dictionary = Boons.DEFS[id]
		rows.append({
			"name": item["name"], "icon": item["icon"],
			"text": "%s przez %d min. Zioło: %s (%s)." % [data["description"], int(data["time"] / 60.0), herb["name"],
					Zones.zone_name(herb["zone"])],
			"cost": "%s: %d/%d   Złoto: %d   W plecaku: %d" % [herb["name"], mini(have, need), need, gold, player.inventory.count_of(id)],
			"enabled": have >= need and player.stats.gold >= gold and player.inventory.can_add(id, 1),
			"state": _time_left(player, "elixir", id), "button": "Uwarz",
			"action": func() -> String:
				player.take_owned(herb["item"], need)
				player.stats.add_gold(-gold)
				player.inventory.add_item(id, 1)
				Sfx.play("craft")
				npc.say(["Proszę, jeszcze ciepłe.", "Tylko nie pij wszystkiego naraz!", "Zioła zebrane o świcie działają najlepiej."].pick_random())
				return "Uwarzono: %s" % item["name"],
		})
	return {"title": "Warsztat zielarki", "rows": rows,
			"hint": "Zioła zerwiesz w krainach (F przy roślinie). Miksturę wypijesz z plecaka albo z paska 1-0. Działa jedna naraz - krócej niż posiłek, ale mocniej."}


## Wymiana Znaków Zwycięstwa (wydarzenia w świecie - WorldEvents) u pisarza gildii: [id, cena, ilość, opis].
const MARK_OFFERS := [
	["gem", 6, 1, "Losowy kamień szlachetny o szlifie na twój poziom (po zadaniu jubilera)."],
	["rune_chaos", 12, 1, "W warsztacie kowala przelosuje wszystkie premie przedmiotu."],
	["mercy_stone", 10, 1, "Przy nieudanym zaklinaniu przedmiot nie traci poziomu."],
	["backpack", 15, 1, "+20 miejsc w plecaku (załóż PPM)."],
	["crystal_heart", 20, 1, "Gniazdo na esencję u kowala i Pieczęć w warsztacie."],
	["rune_seal", 45, 1, "Zapieczętuje jedną premię, a resztę przelosuje (z Sercem Kryształu)."],
	["legend", 80, 1, "Losowa legenda ze skarbca lochów na twoim poziomie."],
]


static func _marks(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	var have := player.count_owned(WorldEvents.MARK)
	for offer: Array in MARK_OFFERS:
		var id: String = offer[0]
		var price: int = offer[1]
		if id == "gem" and not Gems.unlocked:
			continue
		var shown: String = "Kamień szlachetny" if id == "gem" else "Legenda ze skarbca" if id == "legend" else Items.get_data(id)["name"]
		var icon: Texture2D = Items.get_data(WorldEvents.MARK if id in ["gem", "legend"] else id)["icon"]
		rows.append({
			"name": shown, "icon": icon, "text": offer[3],
			"cost": "Znaki Zwycięstwa: %d/%d" % [mini(have, price), price],
			"enabled": have >= price, "state": "", "button": "Wymień",
			"action": func() -> String:
				var item := id
				if id == "gem":
					item = Gems.roll("", Gems.cut_for_level(player.stats.level))
				elif id == "legend":
					item = Loot.legendary_at_level(Dungeons.VAULT_LEGENDS.pick_random(), player.stats.level)
				player.take_owned(WorldEvents.MARK, price)
				if player.inventory.add_item(item, offer[2]) > 0:
					player.storage.add_item(item, offer[2])
				Sfx.play("coins")
				npc.say(["Zasłużone!", "Gildia nagradza bohaterów.", "Niech ci dobrze służy."].pick_random())
				return "Wymieniono: %s" % Items.get_data(item)["name"],
		})
	return {"title": "Znaki Zwycięstwa", "rows": rows,
			"hint": "Znaki dostajesz za udział w wydarzeniach w świecie (najazdy, czempioni, meteoryty, polowania) - więcej za wyższe miejsce w rankingu. Masz: %d." % have}


## Zapomnienie drzewka umiejętności u mędrca: wszystkie wybrane węzły wracają jako punkty (kupione poziomy zostają).
static func _respec(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	var gold := SkillTree.RESPEC_GOLD_PER_LEVEL * player.stats.level
	for weapon_type in Skills.WEAPON_TYPES:
		if not SkillTree.has_tree(weapon_type):
			continue
		var spent: int = player.skills.nodes.get(weapon_type, {}).size()
		rows.append({
			"name": "Drzewko: %s" % Skills.WEAPON_NAMES[weapon_type], "icon": Hotbar.ATTACK_ICON,
			"text": "Mędrzec pomoże zapomnieć wybrane węzły - wrócą jako punkty umiejętności. Kupione poziomy umiejętności zostają, a kamienie z gniazd wrócą do plecaka.",
			"cost": "Wybrane węzły: %d   Złoto: %d" % [spent, gold],
			"enabled": spent > 0 and player.stats.gold >= gold, "state": "", "button": "Zapomnij",
			"action": func() -> String:
				player.stats.add_gold(-gold)
				# kamienie z gniazd drzewka wracają do plecaka (gdy pełny - do magazynu)
				for recipe: Dictionary in player.skills.reset_tree(weapon_type):
					var gem_id := Essences.register(recipe.duplicate(true)) if recipe.has("essence") else Gems.register(recipe.duplicate(true))
					if player.inventory.add_item(gem_id, 1) > 0:
						player.storage.add_item(gem_id, 1)
				Sfx.play("magic")
				npc.say(["Pamięć ciała jest krótsza, niż myślisz.", "Zacznij ścieżkę od nowa.", "Niech ostrze znajdzie nową drogę."].pick_random())
				return "Zapomniano drzewko: %s" % Skills.WEAPON_NAMES[weapon_type],
		})
	return {"title": "Zapomnienie umiejętności", "rows": rows,
			"hint": "Punkty umiejętności dostajesz za każdy poziom postaci. Węzły wybierasz w oknie umiejętności (K)."}


static func _blessings(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	for id: String in ["bless_wisdom", "bless_might"]:
		var data: Dictionary = Boons.DEFS[id]
		var gold := Boons.gold_cost(id, player.stats.level)
		rows.append({
			"name": data["name"],
			"text": "%s przez %d min." % [data["description"], int(data["time"] / 60.0)],
			"cost": "Datek: %d zł" % gold, "enabled": player.stats.gold >= gold,
			"state": _time_left(player, "blessing", id), "button": "Złóż datek",
			"action": func() -> String:
				player.stats.add_gold(-gold)
				player.boons.grant(id)
				Sfx.play("coins")
				Sfx.play("enchant_success")
				npc.say("Niech światło cię prowadzi, wędrowcze.")
				return "Otrzymano: %s" % data["name"],
		})
	return {"title": "Kaplica", "rows": rows,
			"hint": "Działa jedno błogosławieństwo naraz - nowe zastępuje poprzednie."}


static func _bestiary(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	for kind: String in Boons.BESTIARY:
		var data: Dictionary = Boons.BESTIARY[kind]
		var trophy: String = data["trophy"]
		var rank := player.boons.rank(kind)
		var need := player.boons.next_cost(kind)
		var have := player.count_owned(trophy)
		var row := {
			"name": "%s - stopień %d/%d" % [data["name"], rank, Boons.BESTIARY_COSTS.size()],
			"icon": Items.get_data(trophy)["icon"],
			"text": "Obecnie +%d%% obrażeń przeciw nim." % roundi(rank * Boons.BESTIARY_STEP * 100.0),
		}
		if need == 0:
			row["state"] = "zbadane"
			row["cost"] = "Mędrzec wie o nich wszystko."
			row["enabled"] = true
		else:
			row["cost"] = "%s: %d/%d" % [Items.get_data(trophy)["name"], mini(have, need), need]
			row["enabled"] = have >= need
			row["button"] = "Oddaj trofea"
			row["action"] = func() -> String:
				player.take_owned(trophy, need)
				player.boons.advance(kind)
				Sfx.play("ui_book")
				Sfx.play("enchant_success")
				npc.say(["Fascynujące... Widzisz te ścięgna?", "Teraz wiem, gdzie bić!", "Zapiszę to w księdze."].pick_random())
				return "%s: stopień %d" % [data["name"], rank + 1]
		rows.append(row)
	return {"title": "Bestiariusz mędrca", "rows": rows,
			"hint": "Przynieś trofea z potworów - mędrzec zbada ich słabości. Każdy stopień to stałe +3% obrażeń przeciw temu gatunkowi."}


## Przekuwanie: przedmioty z plecaka z dolosowanymi premiami (bez legend) - jedna losowa premia od nowa.
static func _reforge(player: Player, npc: Node) -> Dictionary:
	var rows: Array = []
	var ore := "iron_ore"
	for i in player.inventory.slots.size():
		var slot: Dictionary = player.inventory.slots[i]
		if slot.is_empty() or not Loot.is_generated(slot["id"]):
			continue
		var id: String = slot["id"]
		var data := Items.get_data(id)
		if data.get("rarity", "") == Loot.LEGENDARY or data.get("affixes", {}).is_empty():
			continue
		var gold := 30 + 8 * int(data.get("item_level", 1))
		var ore_need := 3
		var have := player.count_owned(ore)
		var lines: Array[String] = []
		for stat: String in data["affixes"]:
			lines.append(Items._stat_text(stat, data["affixes"][stat]))
		rows.append({
			"name": data["name"], "icon": data["icon"],
			"text": "Poz. %d. Premie: %s" % [data.get("item_level", 1), ", ".join(lines)],
			"cost": "Złoto: %d   Ruda żelaza: %d/%d" % [gold, mini(have, ore_need), ore_need],
			"enabled": player.stats.gold >= gold and have >= ore_need, "button": "Przekuj",
			"action": func() -> String:
				if player.inventory.slots[i].get("id", "") != id:
					return "Przedmiot zniknął z plecaka"
				var result := Loot.reforge(id)
				if result.is_empty():
					return "Tego nie da się przekuć"
				player.stats.add_gold(-gold)
				player.take_owned(ore, ore_need)
				player.inventory.slots[i]["id"] = result["id"]
				player.inventory.changed.emit()
				Sfx.play("anvil")
				Sfx.play("enchant_success")
				npc.say(["Gotowe! Lepsze niż nowe.", "Hartowane drugi raz - zobacz sam.", "Uderzyłem raz a dobrze!"].pick_random())
				return "%s  ->  %s" % [Items._stat_text(result["stat"], result["before"]),
						Items._stat_text(result["stat"], result["after"])],
		})
	return {"title": "Warsztat płatnerza", "rows": rows,
			"hint": "Kowal wylosuje od nowa jedną premię przedmiotu z plecaka (tier zależy od poziomu przedmiotu). Legend nie przekuwa."
			if not rows.is_empty() else "Nie masz w plecaku przedmiotów z premiami do przekucia."}
