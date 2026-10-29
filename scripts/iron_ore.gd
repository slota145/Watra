class_name IronOre
extends Boulder
## Złoże rudy żelaza w Wietrznych Turniach - rozbija się kilofem jak głaz, ale daje rudę
## (kowal wykuwa z niej przedmioty zamiast z kamienia), trochę kamienia i czasem kamień zaklinający.


func _init() -> void:
	super()
	action_name = "Wydobądź"
	chip_color = Color(0.72, 0.42, 0.22)


func roll_loot() -> Array:
	var loot := [["iron_ore", randi_range(2, 4)]]
	if randf() < 0.5:
		loot.append(["stone", randi_range(1, 2)])
	var category: String = ["weapon", "armor", "jewelry"].pick_random()
	if randf() < PERFECT_STONE_CHANCE * 2.0:
		loot.append([Enchanting.stone_id(category, true), 1])
	elif randf() < STONE_CHANCE * 1.5:
		loot.append([Enchanting.stone_id(category, false), 1])
	return loot
