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
	# zadanie jubilera: pierwszy surowy klejnot wyskakuje z rudy na pewno
	var player: Player = get_tree().get_first_node_in_group("player")
	if player != null and player.quests.state_of(Gems.QUEST) == Quests.STATE_ACTIVE \
			and player.inventory.count_of(Gems.ROUGH_GEM) + player.storage.count_of(Gems.ROUGH_GEM) == 0:
		loot.append([Gems.ROUGH_GEM, 1])
	return loot
