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


## Głaz pęka - odłamki rozsypują się dookoła.
func _play_harvest(_from: Vector2) -> void:
	var shards := CPUParticles2D.new()
	shards.position = Vector2(0, -8)
	shards.one_shot = true
	shards.explosiveness = 1.0
	shards.amount = 16
	shards.lifetime = 0.6
	shards.spread = 180.0
	shards.direction = Vector2.UP
	shards.initial_velocity_min = 40.0
	shards.initial_velocity_max = 90.0
	shards.gravity = Vector2(0, 260)
	shards.scale_amount_min = 2.0
	shards.scale_amount_max = 3.0
	shards.color = chip_color
	shards.emitting = true
	add_child(shards)
	shards.finished.connect(shards.queue_free)
