class_name TowerArcher
extends Node2D
## Łucznik z koszar na wieży palisady: stoi na platformie, rozgląda się, a gdy potwór podejdzie
## pod osadę (w zasięgu RANGE), strzela do niego co SHOT_TIME. Obrażenia rosną z poziomem gracza,
## żeby straż przydawała się przez całą grę - ale nie zastąpi walki (to wsparcie przy bramach).
## Zwierzyny nie rusza.

const RANGE := 210.0
const SHOT_TIME := 1.6
const ARROW := preload("res://assets/projectiles/arrow.png")
const ARROW_SPEED := 320.0

var sheet: Texture2D
var _sprite: Sprite2D
var _timer := 0.0
var _look_timer := 0.0
var _player: Player


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.offset = Vector2(0, -19)
	add_child(_sprite)
	_timer = randf_range(0.0, SHOT_TIME)
	_look_timer = randf_range(1.0, 4.0)


func _process(delta: float) -> void:
	_timer -= delta
	_look_timer -= delta
	if _look_timer <= 0.0:
		_look_timer = randf_range(2.0, 5.0)
		_face([Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random())
	if _timer > 0.0:
		return
	_timer = SHOT_TIME
	var target := _find_target()
	if target != null:
		_shoot(target)


func _find_target() -> Goblin:
	var best: Goblin = null
	var best_distance := RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Goblin
		if enemy == null or enemy is Animal or enemy.state == Goblin.State.DEAD:
			continue
		var distance := enemy.global_position.distance_to(global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _shoot(enemy: Goblin) -> void:
	var to := enemy.hurt_center()
	_face(to - global_position)
	var from := global_position + Vector2(0, -16)
	var arrow := Sprite2D.new()
	arrow.texture = ARROW
	arrow.position = from
	arrow.rotation = (to - from).angle()
	arrow.z_index = 20
	(_player.get_parent() if _player != null else get_parent()).add_child(arrow)
	Sfx.play_at("bow", global_position, -6.0)
	var damage := 8 + 3 * (_player.stats.level if _player != null else 1)
	var tween := arrow.create_tween()
	tween.tween_property(arrow, "position", to, from.distance_to(to) / ARROW_SPEED)
	tween.tween_callback(func() -> void:
		if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
			enemy.take_damage(damage, global_position, 40.0)
		arrow.queue_free())


func _face(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		_sprite.flip_h = dir.x < 0.0
		_sprite.frame = 2 * 4
	else:
		_sprite.frame = 0 if dir.y > 0.0 else 4
