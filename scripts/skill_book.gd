class_name SkillBook
extends Node
## Poziomy umiejętności gracza (0 = nieodblokowana). Kupowane za złoto.

signal changed

## id umiejętności -> poziom
var levels := {}


func level_of(id: String) -> int:
	return levels.get(id, 0)


## Koszt następnego poziomu albo -1, gdy umiejętność ma już maksymalny poziom.
func next_cost(id: String) -> int:
	var level := level_of(id)
	return -1 if level >= Skills.MAX_LEVEL else Skills.cost(id, level + 1)


## Czy umiejętność da się już odblokować (dodatkowy cios wymaga najpierw uderzenia).
func can_learn(id: String) -> bool:
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


## Odblokowane uderzenie (Shift+LPM) i dodatkowy cios dla rodzaju broni ("" jeśli brak).
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
func regen(kind: String, weapon_type: String) -> float:
	var total := 0.0
	for id in Skills.for_weapon(weapon_type):
		if Skills.DATA[id]["type"] == kind:
			total += Skills.health_regen(level_of(id)) if kind == "health_regen" else Skills.mana_regen(level_of(id))
	return total


func get_save_data() -> Dictionary:
	return levels.duplicate()


func load_save_data(data: Dictionary) -> void:
	levels.clear()
	for id: String in data:
		if Skills.DATA.has(id):
			levels[id] = clampi(int(data[id]), 0, Skills.MAX_LEVEL)
	changed.emit()
