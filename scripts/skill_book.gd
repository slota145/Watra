class_name SkillBook
extends Node
## Umiejętności gracza: poziomy (0 = nieodblokowana) kupowane za złoto i wybrane węzły drzewek (SkillTree).
## Umiejętność, która ma węzeł w drzewku, jest dostępna tylko z wybranym węzłem (odblokowanie = poziom 1),
## a złoto kupuje jej kolejne poziomy. Kupione poziomy zostają zapamiętane także po zapomnieniu drzewka.
## Punkty umiejętności: 1 za każdy poziom postaci plus SkillTree.START_POINTS, minus wybrane węzły.
## Gniazda drzewek (węzły "socket") trzymają kamienie szlachetne (przepisy Gems): premie kamienia działają o połowę
## mocniej (TREE_GEM_POWER), a kamień promienia wzmacnia wybrane węzły pasywne w promieniu RADIUS_RANGE.
## Gniazdo legendarne przyjmuje też esencję legendy (Essences) - jej efekt działa z bronią drzewka
## (Equipment.effect_power); wyjęcie esencji kosztuje złoto (Essences.save_gold), inaczej esencja przepada.

signal changed

## id umiejętności -> poziom (kupiony; dla umiejętności drzewka - najwyższy osiągnięty)
var levels := {}
## rodzaj broni -> {id węzła: true} (start się nie liczy - jest wybrany zawsze)
var nodes := {}
## rodzaj broni -> {id gniazda: przepis kamienia} (kamień w gnieździe nie istnieje jako przedmiot)
var tree_gems := {}
## Poziom postaci (do punktów) - ustawia gracz.
var character_level := 1
## Dodatkowe punkty umiejętności z zadań głównych (MainQuests - skill_points).
var bonus_points := 0

## Kamień w gnieździe drzewka działa mocniej niż w przedmiocie.
const TREE_GEM_POWER := 1.5
## Promień kamienia promienia (w jednostkach pozycji węzłów drzewka).
const RADIUS_RANGE := 2.6


func level_of(id: String) -> int:
	var node := SkillTree.node_for_skill(id)
	if node != "":
		return maxi(levels.get(id, 0), 1) if has_node_id(Skills.get_data(id)["weapon"], node) else 0
	return levels.get(id, 0)


## Koszt następnego poziomu albo -1, gdy umiejętność ma już maksymalny poziom (albo nie ma jeszcze węzła).
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


func upgrade(id: String, stats: CharacterStats) -> bool:
	var price := next_cost(id)
	if price < 0 or stats.gold < price or not can_learn(id):
		return false
	stats.add_gold(-price)
	levels[id] = level_of(id) + 1
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
	return character_level + SkillTree.START_POINTS + bonus_points


func points_spent() -> int:
	var total := 0
	for weapon_type: String in nodes:
		total += nodes[weapon_type].size()
	return total


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


## Zapomnienie drzewka (u mędrca): wszystkie węzły wracają jako punkty; kupione poziomy umiejętności zostają.
## Zwraca przepisy kamieni wyjętych z gniazd (wracają do plecaka - VillageServices._respec).
func reset_tree(weapon_type: String) -> Array:
	nodes[weapon_type] = {}
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


func has_keystone(weapon_type: String, id: String) -> bool:
	return nodes.get(weapon_type, {}).has(id) and SkillTree.nodes(weapon_type).get(id, {}).get("kind", "") == "keystone"


func get_save_data() -> Dictionary:
	var taken := {}
	for weapon_type: String in nodes:
		taken[weapon_type] = nodes[weapon_type].keys()
	return {"levels": levels.duplicate(), "nodes": taken, "gems": tree_gems.duplicate(true), "bonus_points": bonus_points}


## Starsze zapisy to sam słownik poziomów; umiejętności drzewka kupione wtedy za złoto dostają wybrane węzły
## (z drogą od startu), żeby nic nie przepadło. Tak samo broń, która dostała drzewko później (łuk), a w zapisie nie
## ma jeszcze żadnych jej węzłów (po zapomnieniu drzewka zapis ma pustą listę, więc węzły nie wracają).
func load_save_data(data: Dictionary) -> void:
	levels.clear()
	nodes.clear()
	tree_gems.clear()
	bonus_points = int(data.get("bonus_points", 0))
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
			if tree.has(str(id)) and str(id) != "start":
				nodes[weapon_type][str(id)] = true
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
