class_name SpectralBlades
extends Node2D
## Widmowe Ostrza (umiejętność drzewka miecza, SwordSkills): miecze z bladego światła krążą wokół gracza i ranią
## wrogów, których dotkną (każdego co chwilę). launch() wystrzeliwuje je we wrogów - każde leci do innego, zadaje
## mocniejszy cios i znika (combo z Młynkiem). Rysowane kształtem broni gracza w świetlistym kolorze.

const SPIN_SPEED := 3.2
const HIT_RADIUS := 11.0
const HIT_INTERVAL := 0.45
const LAUNCH_SPEED := 340.0
const COLOR := Color(0.65, 0.85, 1.0, 0.85)
const TAGS := ["spell"]

var player: Player
var count := 3
## Procent obrażeń broni za dotknięcie (wylot: razy Skills.BLADES_LAUNCH).
var damage := 0.5
var time_left := 8.0
var _angle := 0.0
var _texture: Texture2D
## wróg -> sekundy do kolejnego trafienia tym samym wrogiem
var _recent := {}
## Lecące ostrza: [pozycja, cel (Goblin)]
var _flying: Array = []
var _launched := false


func _ready() -> void:
	z_index = 5
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_texture = player.sword.texture if player != null else null
	global_position = player.body_center()


func blade_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in count:
		result.append(Vector2.from_angle(_angle + TAU * i / count) * Skills.BLADES_ORBIT)
	return result


## Wszystkie krążące ostrza lecą do najbliższych wrogów (każde do innego, jeśli się da).
func launch() -> void:
	if _launched or player == null:
		return
	_launched = true
	var enemies: Array = player.get_tree().get_nodes_in_group("enemies").filter(func(e: Goblin) -> bool:
		return e.global_position.distance_to(player.global_position) < 260.0)
	enemies.sort_custom(func(a: Goblin, b: Goblin) -> bool:
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	var positions := blade_positions()
	for i in positions.size():
		if enemies.is_empty():
			break
		_flying.append([global_position + positions[i], enemies[i % enemies.size()]])
	Sfx.play("seeker", 0.0, 1.2)
	if _flying.is_empty():
		queue_free()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	queue_redraw()
	if _launched:
		_process_flying(delta)
		return
	global_position = player.body_center()
	_angle += SPIN_SPEED * delta
	time_left -= delta
	if time_left <= 0.0 or player.is_dead:
		queue_free()
		return
	for enemy: Goblin in _recent.keys():
		_recent[enemy] -= delta
		if _recent[enemy] <= 0.0 or not is_instance_valid(enemy):
			_recent.erase(enemy)
	for offset in blade_positions():
		var at := global_position + offset
		for enemy: Goblin in player.get_tree().get_nodes_in_group("enemies"):
			if _recent.has(enemy):
				continue
			if enemy.hurt_center().distance_to(at) <= HIT_RADIUS + enemy.hurt_radius:
				_recent[enemy] = HIT_INTERVAL
				player.hit_enemy(enemy, player._skill_damage(damage, TAGS), at, 30.0)
				SkillEffects.spark(player.get_parent(), at, COLOR, 3)


func _process_flying(delta: float) -> void:
	for i in range(_flying.size() - 1, -1, -1):
		var blade: Array = _flying[i]
		var target: Goblin = blade[1]
		if not is_instance_valid(target) or target.state == Goblin.State.DEAD:
			_flying.remove_at(i)
			continue
		var at: Vector2 = blade[0]
		var to := target.hurt_center() - at
		if to.length() <= LAUNCH_SPEED * delta + 4.0:
			player.hit_enemy(target, player._skill_damage(damage * Skills.BLADES_LAUNCH, TAGS), at, 120.0)
			SkillEffects.spark(player.get_parent(), target.hurt_center(), COLOR, 10)
			_flying.remove_at(i)
			continue
		blade[0] = at + to.normalized() * LAUNCH_SPEED * delta
	if _flying.is_empty():
		queue_free()


func _draw() -> void:
	if _launched:
		for blade: Array in _flying:
			var target: Goblin = blade[1]
			if is_instance_valid(target):
				_draw_blade(to_local(blade[0]), (target.hurt_center() - blade[0]).angle())
		return
	for offset in blade_positions():
		_draw_blade(offset, offset.angle() + PI / 2.0)


func _draw_blade(at: Vector2, angle: float) -> void:
	draw_set_transform(at, angle, Vector2.ONE * 0.8)
	if _texture != null:
		draw_texture(_texture, -_texture.get_size() / 2.0, COLOR)
	else:
		draw_line(Vector2(-8, 0), Vector2(8, 0), COLOR, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
