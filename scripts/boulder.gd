class_name Boulder
extends Harvestable
## Głaz do rozbicia kilofem. Rozpada się na odłamki, zostawia gruz i daje kamień,
## a czasem trochę rudy żelaza.

## Żyła rudy żelaza w zwykłym głazie - kowal może wykuwać, zanim gracz dotrze w góry.
const ORE_CHANCE := 0.3


func _init() -> void:
	action_name = "Rozbij"
	tool_texture = preload("res://assets/weapons/pickaxe.png")
	chip_color = Color(0.64, 0.66, 0.73)
	hit_sound = "mine"
	break_sound = "rock_break"


func roll_loot() -> Array:
	var loot := [["stone", randi_range(2, 4)]]
	if randf() < ORE_CHANCE:
		loot.append(["iron_ore", randi_range(1, 2)])
	return loot


## Głaz pęka - odłamki i pył rozsypują się dookoła (efekt z kreatora efektów PixelLab).
func _play_harvest(_from: Vector2) -> void:
	WorldVfx.boulder_break(get_parent(), global_position + Vector2(0, -10))
