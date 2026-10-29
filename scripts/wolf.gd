class_name Wolf
extends Goblin
## Wilk z siedliska w ciemnej części lasu. Zachowuje się jak goblin (czuwa, goni w stadzie,
## gryzie, wraca na swoje miejsce), ale jest szybszy, silniejszy i daje więcej expa.
## Odpoczywa przy norze albo pożera truchło jelenia. Zostawia skóry.

## Co robi wilk na swoim miejscu: "lie" (leży przy norze) albo "eat" (je truchło).
var pose := "lie"

@export_range(0.0, 1.0) var pelt_drop_chance := 0.45

const WOLF_COLOR := Color(0.78, 0.82, 0.9)


func _ready() -> void:
	super()
	equipment_drop_chance = 0.05
	hurt_radius = 7.0
	map_color = WOLF_COLOR
	quest_kind = "wolf"


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


## Klatki: 0-3 bieg, 4 leżenie, 5-6 jedzenie, 8 przyczajenie (zamach), 9 skok z kłapnięciem.
func _animate(delta: float) -> void:
	if state == State.ATTACK:
		sprite.frame = 8
		sprite.flip_h = _player.global_position.x < global_position.x
		return
	if _strike_anim > 0.0:
		sprite.frame = 9
		return
	if sitting and state == State.IDLE:
		sprite.flip_h = look_at_point.x < global_position.x
		if pose == "eat":
			_anim_time += delta * 3.0
			sprite.frame = 5 + int(_anim_time) % 2
		else:
			sprite.frame = 4
		return
	if velocity.length() > 8.0:
		_anim_time += delta * 11.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 0


func _drop_loot() -> void:
	super()
	if randf() < pelt_drop_chance:
		_spawn_pickup("wolf_pelt", 1)
