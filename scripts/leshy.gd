class_name Leshy
extends Boss
## Leszy, Pan Puszczy - wysoki, chudy duch lasu z ciałem z kory, brodą z mchu i porożem.
## Mieszka w kamiennym kręgu oplecionym pnączami, wśród prastarych drzew. Ataki:
## - Korzenie: czerwony pas w stronę gracza, potem z ziemi wybuchają korzenie - ranią
##   i na chwilę unieruchamiają (prawie całkowite spowolnienie),
## - Przebudzenie: z ziemi wyrastają dwa drzewce,
## - Wir liści: stożek przed Leszym - wirujące liście tną wszystko na drodze.

@export var roots_damage := 30
@export var leaves_damage := 26
@export var max_adds := 4

const ROOTS_LENGTH := 240.0
const ROOTS_WIDTH := 30.0
const LEAVES_RADIUS := 140.0
const LEAVES_ARC := 0.6
const TREANT := preload("res://scenes/treant.tscn")

var _dir := Vector2.RIGHT
var _adds: Array[Node] = []


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -40)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("leshy_whisper", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_adds.assign(_adds.filter(func(a) -> bool: return is_instance_valid(a) and a.state != State.DEAD))
	var roll := randf()
	_dir = to_player.normalized()
	if _adds.size() < max_adds and roll < 0.25:
		_start_attack("summon", 1.0)
		Sfx.play_at("leshy_whisper", global_position, -2.0)
	elif distance < LEAVES_RADIUS * 0.85 and roll < 0.6:
		_face(_player.global_position)
		_start_attack("leaves", 0.8)
		var telegraph := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.8)
		telegraph.radius = LEAVES_RADIUS
		telegraph.half_arc = LEAVES_ARC
	elif distance < ROOTS_LENGTH * 0.95:
		_face(_player.global_position)
		_start_attack("roots", 0.9)
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _dir.angle(), 0.9)
		telegraph.length = ROOTS_LENGTH
		telegraph.width = ROOTS_WIDTH
	else:
		return false
	return true


func _update_attack(_delta: float) -> void:
	match [_attack, _attack_stage]:
		["roots", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(roots_damage)
					_player.apply_slow(0.1, 1.4)
				_remove_telegraph()
				for i in 8:  # korzenie wybijające się z ziemi wzdłuż pasa
					var at := global_position + _dir * (30.0 + i * 26.0)
					_burst(at, Color(0.35, 0.25, 0.15), 6, 70.0)
				Sfx.play_at("roots_burst", global_position + _dir * 100.0)
				_shake_camera(4.0)
				_set_stage("recover", 0.7)
		["leaves", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(leaves_damage, 140.0)
				_remove_telegraph()
				SkillEffects.cone(get_parent(), global_position, _dir.angle(), LEAVES_ARC, LEAVES_RADIUS)
				for i in 3:
					_burst(global_position + _dir.rotated(randf_range(-LEAVES_ARC, LEAVES_ARC)) * randf_range(40, LEAVES_RADIUS),
							Color(0.75, 0.6, 0.2), 10, 80.0)
				Sfx.play_at("wing_gust", global_position, -3.0)
				_set_stage("recover", 0.6)
		["summon", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				for i in 2:
					var treant: Node = TREANT.instantiate()
					treant.position = global_position + Vector2.from_angle(randf() * TAU) * 50.0
					treant.xp_reward = 25
					treant.equipment_drop_chance = 0.0
					treant.bark_drop_chance = 0.2
					treant.leash_radius = 320.0
					get_parent().add_child(treant)
					treant.aggro()
					_adds.append(treant)
					_burst(treant.global_position, Color(0.35, 0.25, 0.15), 14, 90.0)
				Sfx.play_at("roots_burst", global_position)
				_set_stage("recover", 0.6)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Arkusz z PixelLab (tools/pixellab_sheets.py): 0-3 chód, 4-7 wezwanie, 8-11 korzenie,
## 12-15 wir liści, 16 spoczynek. Zamach ataku rozciąga się na zapowiedź (klatki 0-2),
## a ostatnia klatka - uderzenie - trwa przez odpoczynek po ataku.
const ATTACK_FRAMES := {"summon": 4, "roots": 8, "leaves": 12}
const IDLE_FRAME := 16

var _stage_name := ""
var _stage_length := 0.0


func _animate(delta: float) -> void:
	if ATTACK_FRAMES.has(_attack):
		if _attack_stage != _stage_name:
			_stage_name = _attack_stage
			_stage_length = maxf(_stage_timer, 0.01)
		var first: int = ATTACK_FRAMES[_attack]
		if _attack_stage == "telegraph":
			var progress := 1.0 - _stage_timer / _stage_length
			sprite.frame = first + mini(int(progress * 3.0), 2)
		else:
			sprite.frame = first + 3
		return
	_stage_name = ""
	if velocity.length() > 8.0:
		_anim_time += delta * 6.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = IDLE_FRAME
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _die() -> void:
	super()
	for add in _adds:
		if is_instance_valid(add) and add.state != State.DEAD:
			add.take_damage(99999, global_position)
	Sfx.play_at("leshy_whisper", global_position, 3.0)
	Sfx.play_at("tree_fall", global_position)


func _drop_trophies() -> void:
	_spawn_pickup("ancient_bark", 10)
