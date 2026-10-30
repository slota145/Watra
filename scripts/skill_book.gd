class_name SkillBook
extends Node
## Umiejętności gracza: poziomy (0 = nieodblokowana) kupowane za złoto i wybrane węzły drzewek (SkillTree).
## Umiejętność, która ma węzeł w drzewku, jest dostępna tylko z wybranym węzłem (odblokowanie = poziom 1),
## a złoto kupuje jej kolejne poziomy. Kupione poziomy zostają zapamiętane także po zapomnieniu drzewka.
## Punkty umiejętności: 1 za każdy poziom postaci plus SkillTree.START_POINTS, minus wybrane węzły.

signal changed

## id umiejętności -> poziom (kupiony; dla umiejętności drzewka - najwyższy osiągnięty)
var levels := {}
## rodzaj broni -> {id węzła: true} (start się nie liczy - jest wybrany zawsze)
var nodes := {}
## Poziom postaci (do punktów) - ustawia gracz.
var character_level := 1


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
	return character_level + SkillTree.START_POINTS


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
func reset_tree(weapon_type: String) -> void:
	nodes.erase(weapon_type)
	changed.emit()


## Suma premii danego rodzaju z wybranych węzłów drzewka broni (statystyki postaci i premie umiejętności).
func tree_bonus(weapon_type: String, stat: String) -> float:
	var total := 0.0
	var tree := SkillTree.nodes(weapon_type)
	for id: String in nodes.get(weapon_type, {}):
		if tree.has(id):
			total += float(tree[id].get("stats", {}).get(stat, 0.0))
	return total


func has_keystone(weapon_type: String, id: String) -> bool:
	return nodes.get(weapon_type, {}).has(id) and SkillTree.nodes(weapon_type).get(id, {}).get("kind", "") == "keystone"


func get_save_data() -> Dictionary:
	var taken := {}
	for weapon_type: String in nodes:
		taken[weapon_type] = nodes[weapon_type].keys()
	return {"levels": levels.duplicate(), "nodes": taken}


## Starsze zapisy to sam słownik poziomów; umiejętności drzewka kupione wtedy za złoto dostają wybrane węzły
## (z drogą od startu), żeby nic nie przepadło.
func load_save_data(data: Dictionary) -> void:
	levels.clear()
	nodes.clear()
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
	if not data.has("nodes"):
		for id: String in levels:
			var node := SkillTree.node_for_skill(id)
			if node == "" or levels[id] <= 0:
				continue
			var weapon_type: String = Skills.get_data(id)["weapon"]
			if not nodes.has(weapon_type):
				nodes[weapon_type] = {}
			for step in SkillTree.path_to(weapon_type, node):
				nodes[weapon_type][step] = true
	changed.emit()
