class_name SkillBook
extends Node
## Umiejętności gracza: poziomy (0 = nieodblokowana) i wybrane węzły drzewek (SkillTree), jedno i drugie za punkty
## umiejętności. Umiejętność, która ma węzeł w drzewku, jest dostępna tylko z wybranym węzłem (odblokowanie = poziom 1),
## a kolejne poziomy kosztują Skills.cost punktów (do Skills.MAX_LEVEL).
## Punkty umiejętności daje osobny pasek doświadczenia (skill_xp - napełnia się zwykłym expem, Skills.SKILL_XP_BANDS),
## plus SkillTree.START_POINTS i nagrody zadań głównych. Cofnięcie wydanego punktu (węzeł, poziom, całe drzewko
## u mędrca) kosztuje złoto (refund_gold). Starsze zapisy (poziomy za złoto) przelicza migrate_old.
## Gniazda drzewek (węzły "socket") trzymają kamienie szlachetne (przepisy Gems): premie kamienia działają o połowę
## mocniej (TREE_GEM_POWER), a kamień promienia wzmacnia wybrane węzły pasywne w promieniu RADIUS_RANGE.
## Gniazdo legendarne przyjmuje też esencję legendy (Essences) - jej efekt działa z bronią drzewka
## (Equipment.effect_power); wyjęcie esencji kosztuje złoto (Essences.save_gold), inaczej esencja przepada.
## Gniazda umiejętności aktywnych (Supports): liczba gniazd i kamienie wsparcia w nich (supports), dorabiane krzesiwami.

signal changed
## Kamienie wsparcia awansowały (nazwy z nowym poziomem) - HUD pokazuje napis.
signal supports_leveled(names: Array)
## Pasek doświadczenia umiejętności dał nowe punkty (ile) - HUD pokazuje napis.
signal skill_points_gained(count: int)

## id umiejętności -> kupiony poziom (umiejętność drzewka ma poziom 1 z samego węzła)
var levels := {}
## rodzaj broni -> {id węzła: true} (start się nie liczy - jest wybrany zawsze)
var nodes := {}
## rodzaj broni -> {id gniazda: przepis kamienia} (kamień w gnieździe nie istnieje jako przedmiot)
var tree_gems := {}
## Poziom postaci (do ceny cofania punktów i wyjmowania esencji) - ustawia gracz.
var character_level := 1
## Dodatkowe punkty umiejętności z zadań głównych (MainQuests - skill_points).
var bonus_points := 0
## id umiejętności -> {"sockets": liczba gniazd, "gems": [przepis kamienia wsparcia albo {} - puste gniazdo]}
var supports := {}
## Cały exp zebrany na pasek umiejętności (rośnie bez końca, punkty liczy earned_points).
var skill_xp := 0
## Wczytany zapis jest sprzed paska umiejętności - gracz przelicza go (migrate_old) po wczytaniu statystyk.
var needs_migration := false
## Ostatnie przeliczenie starego zapisu (zwrócone złoto) - okno umiejętności pokazuje informację.
var migrated_gold := -1

## Kamień w gnieździe drzewka działa mocniej niż w przedmiocie.
const TREE_GEM_POWER := 1.5
## Promień kamienia promienia (w jednostkach pozycji węzłów drzewka).
const RADIUS_RANGE := 2.6


func level_of(id: String) -> int:
	var node := SkillTree.node_for_skill(id)
	if node != "":
		return maxi(levels.get(id, 0), 1) if has_node_id(Skills.get_data(id)["weapon"], node) else 0
	return levels.get(id, 0)


## Koszt następnego poziomu w punktach albo -1, gdy umiejętność ma już maksymalny poziom (albo nie ma jeszcze węzła).
func next_cost(id: String) -> int:
	var level := level_of(id)
	if level == 0 and SkillTree.node_for_skill(id) != "":
		return -1
	return -1 if level >= Skills.MAX_LEVEL else Skills.cost(id, level + 1)


## Czy umiejętność da się już odblokować (dodatkowy cios wymaga najpierw uderzenia; umiejętność drzewka - węzła).
func can_learn(id: String) -> bool:
	var node := SkillTree.node_for_skill(id)
	if node != "":
		return has_node_id(Skills.get_data(id)["weapon"], node)
	var required: String = Skills.get_data(id).get("requires", "")
	return required == "" or level_of(required) > 0


func upgrade(id: String) -> bool:
	var price := next_cost(id)
	if price < 0 or points_left() < price or not can_learn(id):
		return false
	levels[id] = level_of(id) + 1
	changed.emit()
	return true


## Najniższy poziom, do którego można cofnąć umiejętność (drzewka - 1, bo poziom 1 daje węzeł).
func _min_level(id: String) -> int:
	return 1 if SkillTree.node_for_skill(id) != "" else 0


## Złoto za cofnięcie jednego punktu umiejętności.
func refund_gold() -> int:
	return Skills.REFUND_GOLD_PER_LEVEL * maxi(character_level, 1)


## Ile złota kosztuje cofnięcie ostatniego poziomu (-1 - nie ma czego cofnąć).
func downgrade_gold(id: String) -> int:
	var level := level_of(id)
	if level <= _min_level(id):
		return -1
	return refund_gold() * Skills.cost(id, level)


## Cofa ostatni poziom umiejętności za złoto - punkty wracają.
func downgrade(id: String, stats: CharacterStats) -> bool:
	var price := downgrade_gold(id)
	if price < 0 or stats.gold < price:
		return false
	stats.add_gold(-price)
	levels[id] = level_of(id) - 1
	if levels[id] <= 0:
		levels.erase(id)
	changed.emit()
	return true


## Odblokowana aktywna umiejętność dla rodzaju broni ("" jeśli brak).
func active_for(weapon_type: String) -> String:
	var id: String = Skills.for_weapon(weapon_type)[0]
	return id if level_of(id) > 0 else ""


## Odblokowane uderzenie i dodatkowy cios dla rodzaju broni ("" jeśli brak).
func strike_for(weapon_type: String) -> String:
	return _learned_of_type(weapon_type, "strike")


func combo_for(weapon_type: String) -> String:
	return _learned_of_type(weapon_type, "combo")


func _learned_of_type(weapon_type: String, kind: String) -> String:
	for id in Skills.for_weapon(weapon_type):
		if Skills.DATA[id]["type"] == kind:
			return id if level_of(id) > 0 else ""
	return ""


## Regeneracja zdrowia/many (na sekundę) z umiejętności danego rodzaju broni.
func regen(kind: String, weapon_type: String, maximum := 0.0) -> float:
	var total := 0.0
	for id in Skills.for_weapon(weapon_type):
		if Skills.DATA[id]["type"] == kind:
			var level := level_of(id)
			total += Skills.health_regen(level, maximum) if kind == "health_regen" else Skills.mana_regen(level, maximum)
	return total


# ---------------------------------------------------------------- drzewko
func has_node_id(weapon_type: String, id: String) -> bool:
	return id == "start" or nodes.get(weapon_type, {}).has(id)


func points_total() -> int:
	return earned_points() + SkillTree.START_POINTS + bonus_points


func points_spent() -> int:
	var total := 0
	for weapon_type: String in Skills.WEAPON_TYPES:
		total += points_in(weapon_type)
	return total


## Punkty wydane na broń: węzły drzewka i poziomy jej umiejętności.
func points_in(weapon_type: String) -> int:
	var total: int = nodes.get(weapon_type, {}).size()
	for id in Skills.for_weapon(weapon_type):
		total += _level_points(id, level_of(id))
	return total


## Punkty za poziomy umiejętności ponad to, co daje węzeł drzewka.
func _level_points(id: String, level: int) -> int:
	var total := 0
	for l in range(_min_level(id) + 1, level + 1):
		total += Skills.cost(id, l)
	return total


# ---------------------------------------------------------------- pasek doświadczenia umiejętności
## Punkty zdobyte na pasku (bez punktów startowych i z zadań).
func earned_points() -> int:
	var left := skill_xp
	var points := 0
	while true:
		var need := Skills.skill_point_xp(points + 1)
		if left < need:
			return points
		left -= need
		points += 1
	return points


## [exp na pasku od ostatniego punktu, exp potrzebny na następny punkt].
func skill_xp_progress() -> Array[int]:
	var left := skill_xp
	var point := 1
	while left >= Skills.skill_point_xp(point):
		left -= Skills.skill_point_xp(point)
		point += 1
	return [left, Skills.skill_point_xp(point)]


func add_skill_xp(amount: int) -> void:
	if amount <= 0:
		return
	var before := earned_points()
	skill_xp += amount
	var gained := earned_points() - before
	if gained > 0:
		skill_points_gained.emit(gained)
		changed.emit()


func points_left() -> int:
	return maxi(points_total() - points_spent(), 0)


## Czy węzeł można teraz wybrać: jeszcze niewybrany, obok wybranego i jest wolny punkt.
func can_take(weapon_type: String, id: String) -> bool:
	if has_node_id(weapon_type, id) or points_left() <= 0:
		return false
	return SkillTree.neighbors(weapon_type, id).any(func(other: String) -> bool: return has_node_id(weapon_type, other))


func take(weapon_type: String, id: String) -> bool:
	if not can_take(weapon_type, id):
		return false
	if not nodes.has(weapon_type):
		nodes[weapon_type] = {}
	nodes[weapon_type][id] = true
	changed.emit()
	return true


## Dlaczego węzła nie da się cofnąć ("" - da się): start, niewybrany, kamień w gnieździe albo węzeł, przez który
## inne wybrane węzły łączą się ze startem.
## Z `gold` (>= 0) sprawdza też, czy starczy złota na cofnięcie (refund_gold).
func refund_reason(weapon_type: String, id: String, gold := -1) -> String:
	if id == "start" or not nodes.get(weapon_type, {}).has(id):
		return Lang.t("Ten węzeł nie jest wybrany.")
	if not gem_in(weapon_type, id).is_empty():
		return Lang.t("Wyjmij najpierw kamień z gniazda.")
	var skill: String = SkillTree.nodes(weapon_type)[id].get("skill", "")
	if skill != "" and level_of(skill) > 1:
		return Lang.t("Cofnij najpierw poziomy umiejętności.")
	if gold >= 0 and gold < refund_gold():
		return Lang.t("Za mało złota: cofnięcie kosztuje %d zł.") % refund_gold()
	# przeszukanie od startu po wybranych węzłach bez cofanego - każdy musi zostać osiągalny
	var reached := {"start": true}
	var queue: Array[String] = ["start"]
	while not queue.is_empty():
		for other in SkillTree.neighbors(weapon_type, queue.pop_back()):
			if other != id and not reached.has(other) and nodes[weapon_type].has(other):
				reached[other] = true
				queue.append(other)
	if reached.size() - 1 < nodes[weapon_type].size() - 1:
		return Lang.t("Inne wybrane węzły zależą od tego węzła.")
	return ""


## Cofa jeden węzeł (prawy przycisk w drzewku) - punkt wraca. Ze `stats` pobiera złoto (refund_gold).
func refund(weapon_type: String, id: String, stats: CharacterStats = null) -> bool:
	if refund_reason(weapon_type, id, stats.gold if stats != null else -1) != "":
		return false
	if stats != null:
		stats.add_gold(-refund_gold())
	nodes[weapon_type].erase(id)
	changed.emit()
	return true


## Zapomnienie drzewka (u mędrca): wszystkie węzły i poziomy umiejętności tej broni wracają jako punkty
## (złoto liczy VillageServices._respec - points_in * refund_gold).
## Zwraca przepisy kamieni wyjętych z gniazd (wracają do plecaka - VillageServices._respec).
func reset_tree(weapon_type: String) -> Array:
	nodes[weapon_type] = {}
	for id in Skills.for_weapon(weapon_type):
		levels.erase(id)
	var gems: Array = tree_gems.get(weapon_type, {}).values()
	tree_gems.erase(weapon_type)
	changed.emit()
	return gems


# ---------------------------------------------------------------- gniazda drzewka
## Przepis kamienia w gnieździe drzewka ({} - puste).
func gem_in(weapon_type: String, id: String) -> Dictionary:
	return tree_gems.get(weapon_type, {}).get(id, {})


## Esencja legendy w wybranym gnieździe legendarnym drzewka ({} - brak).
func essence_in(weapon_type: String) -> Dictionary:
	var gems: Dictionary = tree_gems.get(weapon_type, {})
	for id: String in gems:
		if gems[id].has("essence") and has_node_id(weapon_type, id):
			return gems[id]
	return {}


func is_legendary_socket(weapon_type: String, id: String) -> bool:
	return SkillTree.nodes(weapon_type).get(id, {}).get("legendary", false)


## Czy w węzeł da się włożyć kamień: wybrane gniazdo.
func can_socket(weapon_type: String, id: String) -> bool:
	return SkillTree.nodes(weapon_type).get(id, {}).get("kind", "") == "socket" and has_node_id(weapon_type, id)


## Wkłada kamień (przepis); zwraca przepis kamienia, który był w gnieździe wcześniej ({} - nie było).
func set_gem(weapon_type: String, id: String, recipe: Dictionary) -> Dictionary:
	var old := gem_in(weapon_type, id)
	if not tree_gems.has(weapon_type):
		tree_gems[weapon_type] = {}
	tree_gems[weapon_type][id] = recipe.duplicate(true)
	changed.emit()
	return old


## Wyjmuje kamień z gniazda; zwraca jego przepis ({} - gniazdo było puste).
func take_gem(weapon_type: String, id: String) -> Dictionary:
	var old := gem_in(weapon_type, id)
	if not old.is_empty():
		tree_gems[weapon_type].erase(id)
		changed.emit()
	return old


## Osadza kamień z pola `index` plecaka w gnieździe drzewka; kamień, który tam był, wraca do plecaka (zamiana).
## Zwraca "" albo powód, dla którego się nie da.
func socket_from(inventory: Inventory, weapon_type: String, id: String, index: int) -> String:
	if not can_socket(weapon_type, id):
		return Lang.t("Najpierw wybierz gniazdo w drzewku.")
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty() \
			or not (Gems.is_gem(inventory.slots[index]["id"]) or Essences.is_essence(inventory.slots[index]["id"])):
		return Lang.t("To nie jest kamień szlachetny ani esencja.")
	var gem_id: String = inventory.slots[index]["id"]
	if Essences.is_essence(gem_id) and not is_legendary_socket(weapon_type, id):
		return Lang.t("Esencja pasuje tylko do gniazda legendarnego.")
	if gem_in(weapon_type, id).has("essence"):
		return Lang.t("Najpierw wyjmij esencję z gniazda.")
	inventory.take_one(index)
	var old := set_gem(weapon_type, id, Items.generated[gem_id]["recipe"])
	Items.generated.erase(gem_id)
	if not old.is_empty():
		inventory.put(index, Gems.register(old.duplicate(true)))
	return ""


## Wyjmuje kamień z gniazda drzewka do plecaka (za darmo; esencję - za złoto z `stats`, Essences.save_gold).
## Zwraca "" albo powód, dla którego się nie da.
func unsocket_to(inventory: Inventory, weapon_type: String, id: String, stats: CharacterStats = null) -> String:
	var gem := gem_in(weapon_type, id)
	if gem.is_empty():
		return Lang.t("Gniazdo jest puste.")
	if not inventory.slots.any(func(slot: Dictionary) -> bool: return slot.is_empty()):
		return Lang.t("Plecak jest pełny.")
	if gem.has("essence"):
		var price := Essences.save_gold(character_level)
		if stats == null or stats.gold < price:
			return Lang.t("Wyjęcie esencji kosztuje %d zł.") % price
		stats.add_gold(-price)
		inventory.add_item(Essences.register(take_gem(weapon_type, id).duplicate(true)), 1)
		return ""
	inventory.add_item(Gems.register(take_gem(weapon_type, id).duplicate(true)), 1)
	return ""


## Niszczy esencję w gnieździe drzewka (za darmo).
func destroy_essence(weapon_type: String, id: String) -> void:
	if gem_in(weapon_type, id).has("essence"):
		take_gem(weapon_type, id)


## Kamienie promienia w wybranych gniazdach: [pozycja gniazda, moc].
func _radius_gems(weapon_type: String, tree: Dictionary) -> Array:
	var found := []
	var gems: Dictionary = tree_gems.get(weapon_type, {})
	for id: String in gems:
		if gems[id].get("kind", "") == "radius" and has_node_id(weapon_type, id) and tree.has(id):
			found.append([tree[id]["pos"], float(gems[id]["affixes"].get("radius_power", 0.0))])
	return found


## Mnożnik premii węzła pasywnego od kamieni promienia (1.0 - poza promieniem).
func radius_factor(weapon_type: String, id: String) -> float:
	var tree := SkillTree.nodes(weapon_type)
	var factor := 1.0
	if tree.get(id, {}).get("kind", "") != "passive":
		return factor
	for gem: Array in _radius_gems(weapon_type, tree):
		if (gem[0] as Vector2).distance_to(tree[id]["pos"]) <= RADIUS_RANGE:
			factor += gem[1]
	return factor


## Suma premii danego rodzaju z wybranych węzłów drzewka broni (statystyki postaci i premie umiejętności).
func tree_bonus(weapon_type: String, stat: String) -> float:
	var total := 0.0
	var tree := SkillTree.nodes(weapon_type)
	var radius := _radius_gems(weapon_type, tree)
	for id: String in nodes.get(weapon_type, {}):
		if not tree.has(id):
			continue
		var value := float(tree[id].get("stats", {}).get(stat, 0.0))
		if value != 0.0 and not radius.is_empty() and tree[id]["kind"] == "passive" and stat not in SkillTree.COUNT_STATS:
			var factor := 1.0
			for gem: Array in radius:
				if (gem[0] as Vector2).distance_to(tree[id]["pos"]) <= RADIUS_RANGE:
					factor += gem[1]
			value *= factor
		total += value
	var gems: Dictionary = tree_gems.get(weapon_type, {})
	for id: String in gems:
		if has_node_id(weapon_type, id):
			total += float(gems[id].get("affixes", {}).get(stat, 0.0)) * TREE_GEM_POWER
	return total


# ---------------------------------------------------------------- gniazda umiejętności (kamienie wsparcia)
func sockets_of(skill: String) -> int:
	return int(supports.get(skill, {}).get("sockets", 0))


## Kamienie wsparcia w gniazdach umiejętności (przepisy; {} - puste gniazdo), zawsze tyle, ile gniazd.
func support_gems(skill: String) -> Array:
	return supports.get(skill, {}).get("gems", [])


## Dorabia gniazdo umiejętności za krzesiwa z plecaka (Supports.socket_cost). Zwraca "" albo powód.
func add_socket(skill: String, inventory: Inventory) -> String:
	if not Supports.has_sockets(skill):
		return Lang.t("Ta umiejętność nie może mieć gniazd.")
	if level_of(skill) <= 0:
		return Lang.t("Najpierw odblokuj umiejętność.")
	var cost := Supports.socket_cost(sockets_of(skill))
	if cost.is_empty():
		return Lang.t("Umiejętność ma już wszystkie gniazda.")
	if inventory.count_of(cost[0]) < int(cost[1]):
		return Lang.t("Potrzeba: %s x%d.") % [Items.short_name(cost[0]), cost[1]]
	inventory.remove_item(cost[0], int(cost[1]))
	if not supports.has(skill):
		supports[skill] = {"sockets": 0, "gems": []}
	supports[skill]["sockets"] = sockets_of(skill) + 1
	supports[skill]["gems"].append({})
	changed.emit()
	return ""


## Osadza kamień wsparcia z pola `index` plecaka w gnieździe `slot` umiejętności (-1 - pierwsze wolne);
## kamień, który tam był, wraca do plecaka. Zwraca "" albo powód.
func support_socket_from(inventory: Inventory, skill: String, index: int, slot := -1) -> String:
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty() \
			or not Supports.is_support(inventory.slots[index]["id"]):
		return Lang.t("To nie jest kamień wsparcia.")
	var item_id: String = inventory.slots[index]["id"]
	var recipe: Dictionary = Items.generated[item_id]["recipe"]
	var kind: String = recipe["support"]
	if not Supports.fits(kind, skill):
		return Lang.t("%s nie pasuje do tej umiejętności.") % Supports.name_of(kind)
	var gems := support_gems(skill)
	if gems.is_empty():
		return Lang.t("Umiejętność nie ma gniazd - dorób je krzesiwem.")
	if slot < 0:
		slot = gems.find({})
		if slot < 0:
			return Lang.t("Wszystkie gniazda są zajęte - wyjmij najpierw któryś kamień.")
	for i in gems.size():
		if i != slot and gems[i].get("support", "") == kind:
			return Lang.t("Ten kamień już jest w tej umiejętności.")
	inventory.take_one(index)
	Items.generated.erase(item_id)
	var old: Dictionary = gems[slot]
	gems[slot] = recipe.duplicate(true)
	if not old.is_empty():
		inventory.put(index, Supports.register(old.duplicate(true)))
	changed.emit()
	return ""


## Wyjmuje kamień wsparcia z gniazda do plecaka (za darmo). Zwraca "" albo powód.
func support_unsocket_to(inventory: Inventory, skill: String, slot: int) -> String:
	var gems := support_gems(skill)
	if slot < 0 or slot >= gems.size() or gems[slot].is_empty():
		return Lang.t("Gniazdo jest puste.")
	if not inventory.slots.any(func(entry: Dictionary) -> bool: return entry.is_empty()):
		return Lang.t("Plecak jest pełny.")
	inventory.add_item(Supports.register((gems[slot] as Dictionary).duplicate(true)), 1)
	gems[slot] = {}
	changed.emit()
	return ""


## Suma premii `stat` kamieni wsparcia umiejętności (more i mana - patrz support_more i support_mana).
func support_value(skill: String, stat: String) -> float:
	var total := 0.0
	for gem: Dictionary in support_gems(skill):
		if not gem.is_empty() and Supports.DATA[gem["support"]]["stats"].has(stat):
			total += Supports.value(gem["support"], stat, int(gem["level"]))
	return total


## Mnożnik obrażeń kamieni wsparcia (premie "more" się mnożą).
func support_more(skill: String) -> float:
	var total := 1.0
	for gem: Dictionary in support_gems(skill):
		if not gem.is_empty() and Supports.DATA[gem["support"]]["stats"].has("more"):
			total *= 1.0 + Supports.value(gem["support"], "more", int(gem["level"]))
	return total


## Mnożnik kosztu many umiejętności od kamieni wsparcia.
func support_mana(skill: String) -> float:
	var total := 1.0
	for gem: Dictionary in support_gems(skill):
		if not gem.is_empty():
			total *= float(Supports.DATA[gem["support"]]["mana"])
	return total


## Doświadczenie dla kamieni wsparcia we wszystkich gniazdach (Supports.XP_SHARE doświadczenia postaci).
## Zwraca nazwy kamieni, które awansowały.
func add_support_xp(amount: int) -> Array[String]:
	var leveled: Array[String] = []
	var share := roundi(amount * Supports.XP_SHARE)
	for skill: String in supports:
		for gem: Dictionary in supports[skill]["gems"]:
			if not gem.is_empty() and Supports.add_xp(gem, share):
				leveled.append(Lang.t("%s (poziom %d)") % [Supports.name_of(gem["support"]), int(gem["level"])])
	if not leveled.is_empty():
		changed.emit()
		supports_leveled.emit(leveled)
	return leveled


func has_keystone(weapon_type: String, id: String) -> bool:
	return nodes.get(weapon_type, {}).has(id) and SkillTree.nodes(weapon_type).get(id, {}).get("kind", "") == "keystone"


func get_save_data() -> Dictionary:
	var taken := {}
	for weapon_type: String in nodes:
		taken[weapon_type] = nodes[weapon_type].keys()
	return {"levels": levels.duplicate(), "nodes": taken, "gems": tree_gems.duplicate(true), "bonus_points": bonus_points,
			"supports": supports.duplicate(true), "skill_xp": skill_xp}


## Starsze zapisy to sam słownik poziomów; umiejętności drzewka kupione wtedy za złoto dostają wybrane węzły
## (z drogą od startu), żeby nic nie przepadło. Tak samo broń, która dostała drzewko później (łuk), a w zapisie nie
## ma jeszcze żadnych jej węzłów (po zapomnieniu drzewka zapis ma pustą listę, więc węzły nie wracają).
func load_save_data(data: Dictionary) -> void:
	levels.clear()
	nodes.clear()
	tree_gems.clear()
	supports.clear()
	bonus_points = int(data.get("bonus_points", 0))
	skill_xp = int(data.get("skill_xp", 0))
	needs_migration = not data.has("skill_xp")
	migrated_gold = -1
	var saved_supports: Dictionary = data.get("supports", {})
	for skill: String in saved_supports:
		if not Supports.has_sockets(skill):
			continue
		var count := clampi(int(saved_supports[skill].get("sockets", 0)), 0, Supports.MAX_SOCKETS)
		var gems := []
		for gem in saved_supports[skill].get("gems", []):
			if gems.size() >= count:
				break
			var recipe: Dictionary = gem if gem is Dictionary else {}
			if Supports.DATA.has(recipe.get("support", "")):
				recipe["level"] = clampi(int(recipe.get("level", 1)), 1, Supports.MAX_LEVEL)
				recipe["xp"] = int(recipe.get("xp", 0))
				gems.append(recipe)
			else:
				gems.append({})
		while gems.size() < count:
			gems.append({})
		supports[skill] = {"sockets": count, "gems": gems}
	var saved_gems: Dictionary = data.get("gems", {})
	for weapon_type: String in saved_gems:
		var tree := SkillTree.nodes(weapon_type)
		for id: String in saved_gems[weapon_type]:
			var recipe: Dictionary = saved_gems[weapon_type][id]
			if tree.has(id) and recipe.has("kind"):
				if recipe.has("essence"):
					recipe["value"] = float(recipe["value"])
				else:
					recipe["cut"] = int(recipe.get("cut", 0))
				if not tree_gems.has(weapon_type):
					tree_gems[weapon_type] = {}
				tree_gems[weapon_type][id] = recipe
	var saved_levels: Dictionary = data.get("levels", {}) if data.has("levels") else data
	for id: String in saved_levels:
		if Skills.DATA.has(id):
			levels[id] = clampi(int(saved_levels[id]), 0, Skills.MAX_LEVEL)
	var saved_nodes: Dictionary = data.get("nodes", {})
	for weapon_type: String in saved_nodes:
		var tree := SkillTree.nodes(weapon_type)
		nodes[weapon_type] = {}
		for id in saved_nodes[weapon_type]:
			# dawny węzeł kluczowy Nieustający Wir zastąpiło Oko Cyklonu w tym samym miejscu
			var node_id := "cyclone_eye" if str(id) == "endless_whirl" else str(id)
			if tree.has(node_id) and node_id != "start":
				nodes[weapon_type][node_id] = true
	for id: String in levels:
		var node := SkillTree.node_for_skill(id)
		var weapon_type: String = Skills.get_data(id)["weapon"]
		if node == "" or levels[id] <= 0 or saved_nodes.has(weapon_type):
			continue
		if not nodes.has(weapon_type):
			nodes[weapon_type] = {}
		for step in SkillTree.path_to(weapon_type, node):
			nodes[weapon_type][step] = true
	changed.emit()


## Przelicza zapis sprzed paska umiejętności: złoto wydane na poziomy umiejętności wraca, węzły i poziomy wracają
## jako punkty, a pasek dostaje cały exp zdobyty przez postać (`total_xp`). Zwraca {"gold": zwrot złota,
## "gems": przepisy kamieni z gniazd drzewek - gracz odkłada je do plecaka}. Bez starego zapisu - {}.
func migrate_old(total_xp: int) -> Dictionary:
	if not needs_migration:
		return {}
	needs_migration = false
	var gold := 0
	for id: String in levels:
		var first := 2 if SkillTree.node_for_skill(id) != "" else 1
		for level in range(first, mini(levels[id], 5) + 1):
			gold += Skills.old_gold_cost(id, level)
	levels.clear()
	var gems: Array = []
	for weapon_type: String in tree_gems:
		gems.append_array(tree_gems[weapon_type].values())
	tree_gems.clear()
	for weapon_type: String in nodes:
		nodes[weapon_type] = {}
	skill_xp = maxi(total_xp, 0)
	migrated_gold = gold
	changed.emit()
	return {"gold": gold, "gems": gems}
