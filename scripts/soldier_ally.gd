class_name SoldierAlly
extends Node2D
## Żołnierz Ostoi przyzwany Rogiem straży (sprzedaje go sierżant koszar): przez LIFE sekund biegnie
## za graczem, rzuca się na potwory w pobliżu i tnie je mieczem (rząd pracy arkusza żołnierza). Obrażenia
## to część obrażeń gracza, więc pomagają przez całą grę. Potwory go nie atakują - to wsparcie, nie tank.

const LIFE := 30.0
const SPEED := 70.0
const SEEK_RANGE := 170.0
const FOLLOW_DISTANCE := 34.0
const ATTACK_RANGE := 16.0
const ATTACK_TIME := 0.8
const DAMAGE := 0.45
const WALK_FPS := 9.0

var player: Player
var sheet: Texture2D
var _sprite: Sprite2D
var _life := LIFE
var _anim := 0.0
var _attack := 0.0
var _target: Goblin
var _side := 1.0


func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/shadow.png")
	shadow.scale = Vector2(1.2, 1.0)
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.offset = Vector2(0, -19)
	add_child(_sprite)
	_attack = randf() * ATTACK_TIME
	MiscVfx.puff(get_parent(), global_position + Vector2(0, -6), Color(1.0, 0.9, 0.6), 0.55)


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 or not is_instance_valid(player) or player.is_dead:
		MiscVfx.puff(get_parent(), global_position + Vector2(0, -6), Color(1.0, 0.9, 0.6), 0.5)
		queue_free()
		return
	if _target == null or not is_instance_valid(_target) or _target.state == Goblin.State.DEAD:
		_target = _nearest_enemy()
	var goal := player.global_position + Vector2(FOLLOW_DISTANCE * _side, 6)
	if _target != null:
		var to_enemy := _target.global_position - global_position
		if to_enemy.length() <= ATTACK_RANGE + _target.hurt_radius:
			_fight(delta, to_enemy)
			return
		goal = _target.global_position - to_enemy.normalized() * ATTACK_RANGE
	var to_goal := goal - global_position
	if to_goal.length() < 4.0:
		_sprite.frame = 0
		return
	global_position += to_goal.normalized() * minf(SPEED * delta, to_goal.length())
	_anim += delta * WALK_FPS
	_set_row(to_goal, int(_anim) % 4)


func _fight(delta: float, to_enemy: Vector2) -> void:
	_attack -= delta
	_sprite.flip_h = to_enemy.x < 0.0
	var t := 1.0 - maxf(_attack, 0.0) / ATTACK_TIME
	_sprite.frame = 3 * 4 + (2 if t < 0.55 else 1)
	if _attack <= 0.0:
		_attack = ATTACK_TIME
		_target.take_damage(player.roll_damage(DAMAGE), global_position, 60.0)
		Sfx.play_at("hit", global_position, -8.0)


func _nearest_enemy() -> Goblin:
	var best: Goblin = null
	var best_distance := SEEK_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Goblin
		if enemy == null or enemy is Animal or enemy.state == Goblin.State.DEAD:
			continue
		var d := enemy.global_position.distance_to(player.global_position)
		if d < best_distance:
			best_distance = d
			best = enemy
	return best


func _set_row(dir: Vector2, column: int) -> void:
	var row := 2
	if absf(dir.x) >= absf(dir.y):
		_sprite.flip_h = dir.x < 0.0
	else:
		row = 0 if dir.y > 0.0 else 1
	_sprite.frame = row * 4 + column
