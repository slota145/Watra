class_name IronOre
extends Boulder
## Złoże rudy żelaza w Wietrznych Turniach - rozbija się kilofem jak głaz, ale daje rudę
## (kowal wykuwa z niej przedmioty zamiast z kamienia) i trochę kamienia.


func _init() -> void:
	super()
	action_name = "Wydobądź"
	chip_color = Color(0.72, 0.42, 0.22)


func roll_loot() -> Array:
	var loot := [["iron_ore", randi_range(2, 4)]]
	if randf() < 0.5:
		loot.append(["stone", randi_range(1, 2)])
	return loot
