class_name Ghoul
extends Goblin
## Trupojad: przygarbiony, szybki pożeracz zwłok. Z kilku kroków rzuca się na gracza w skoku (krótki
## przysiad - wtedy można uskoczyć), a potem tnie pazurami.

const GHOUL_COLOR := Color(0.6, 0.75, 0.45)
const POUNCE_WINDUP := 0.45
const POUNCE_TIME := 0.28

@export var pounce_damage := 22
@export var pounce_range := 90.0
@export var pounce_cooldown := 3.5

var _pounce_cd := 1.0
var _pounce_stage := ""
var _pounce_timer := 0.0
var _pounce_dir := Vector2.ZERO
var _pounce_hit := false


func _ready() -> void:
	super()
	hurt_radius = 8.0
	heart_drop_chance = 0.0
	equipment_drop_chance = 0.05
	map_color = GHOUL_COLOR
	quest_kind = "ghoul"
	fearless = true
	alert_radius = 110.0


func _physics_process(delta: float) -> void:
	if state == State.CHASE and _pounce_stage == "" and _player_alive():
		_pounce_cd -= delta
		var distance := global_position.distance_to(_player.global_position)
		if _pounce_cd <= 0.0 and distance > attack_range * 1.5 and distance < pounce_range and not is_stunned():
			_pounce_stage = "crouch"
			_pounce_timer = POUNCE_WINDUP
			_pounce_dir = global_position.direction_to(_player.global_position)
			sprite.flip_h = _pounce_dir.x < 0.0
	if _pounce_stage != "" and state != State.DEAD:
		if is_stunned():
			_pounce_stage = ""
		else:
			_process_pounce(delta)
			return
	super(delta)


func _process_pounce(delta: float) -> void:
	_pounce_timer -= delta
	if _pounce_stage == "crouch":
		velocity = Vector2.ZERO
		sprite.frame = 6
		sprite.scale = Vector2(1.15, 0.85)
		if _pounce_timer <= 0.0:
			_pounce_stage = "leap"
			_pounce_timer = POUNCE_TIME
			_pounce_hit = false
			sprite.scale = Vector2(0.9, 1.1)
			Sfx.play_at("claw", global_position, -6.0)
	else:
		velocity = _pounce_dir * pounce_range / POUNCE_TIME
		sprite.frame = 7
		if not _pounce_hit and _player_alive() and global_position.distance_to(_player.global_position) < 16.0:
			_pounce_hit = true
			_player.take_damage(pounce_damage, global_position)
		if _pounce_timer <= 0.0:
			_pounce_stage = ""
			_pounce_cd = pounce_cooldown
			_cooldown = 0.4
			sprite.scale = Vector2.ONE
	move_and_slide()


func _drop_loot() -> void:
	super()
	if randf() < 0.25:
		_spawn_pickup("ghoul_claw", 1)
