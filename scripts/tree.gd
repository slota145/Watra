class_name ChoppableTree
extends Harvestable
## Drzewo do ścięcia siekierą. Przewraca się, zostawia pieniek i daje drewno.


func _init() -> void:
	action_name = "Zetnij"
	tool_texture = preload("res://assets/weapons/hatchet.png")
	chip_color = Color(0.85, 0.65, 0.4)
	hit_sound = "chop"
	break_sound = "tree_fall"


func _ready() -> void:
	super()
	add_to_group("trees")


func roll_loot() -> Array:
	return [["wood", randi_range(2, 4)]]


## Drzewo pada w przeciwną stronę niż stoi ścinający.
func _play_harvest(from: Vector2) -> void:
	var falling := Sprite2D.new()
	falling.texture = _full_texture
	falling.offset = _full_offset
	add_child(falling)
	var side := 1.0 if global_position.x >= from.x else -1.0
	var tween := falling.create_tween().set_parallel()
	tween.tween_property(falling, "rotation", side * 1.45, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(falling, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(falling.queue_free)
