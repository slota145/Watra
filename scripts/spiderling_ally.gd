class_name SpiderlingAlly
extends Node2D
## Jadowity pajączek z Jedwabnego Kokonu (legendarny kolczyk Królowej Pająków). Wybiega z zabitego
## wroga, pędzi do najbliższego wroga i wybucha na nim jadem - rani i zatruwa wszystkich obok.
## Jeśli w pobliżu nie ma nikogo, po chwili rozpływa się w zielonym oparze.

const TEXTURE := preload("res://assets/ancient/spiderling.png")
const SPEED := 150.0
const SEEK_RANGE := 220.0
const LIFE := 5.0
const BURST_RADIUS := 28.0
const BURST_DAMAGE := 0.8

var effects: LegendaryEffects
var player: Player
var _sprite: Sprite2D
var _life := LIFE
var _anim := 0.0
var _target: Goblin


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 4
	_sprite.vframes = 2
	_sprite.offset = Vector2(0, -5)
	_sprite.modulate = Color(0.75, 1.0, 0.6)  # jadowicie zielonkawy - widać, że to nasz
	add_child(_sprite)


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 or not is_instance_valid(player):
		_burst(false)
		return
	if _target == null or not is_instance_valid(_target) or _target.state == Goblin.State.DEAD:
		_target = _nearest_enemy()
	if _target == null:
		return
	var to_target := _target.global_position - global_position
	if to_target.length() < 10.0 + _target.hurt_radius:
		_burst(true)
		return
	global_position += to_target.normalized() * SPEED * delta
	_anim += delta * 14.0
	_sprite.frame = int(_anim) % 4
	_sprite.flip_h = to_target.x < 0.0


func _nearest_enemy() -> Goblin:
	var best: Goblin = null
	var best_distance := SEEK_RANGE
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		var d := enemy.global_position.distance_to(global_position)
		if d < best_distance and enemy.state != Goblin.State.DEAD:
			best_distance = d
			best = enemy
	return best


func _burst(hit: bool) -> void:
	SkillEffects.spark(get_parent(), global_position + Vector2(0, -4), LegendaryEffects.VENOM_COLOR, 10 if hit else 5)
	if hit and is_instance_valid(player):
		Sfx.play_at("spit_hit", global_position, -4.0)
		for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
			if enemy.hurt_center().distance_to(global_position) <= BURST_RADIUS + enemy.hurt_radius:
				enemy.take_damage(player.roll_damage(BURST_DAMAGE), global_position, 40.0)
				effects.poison(enemy)
	queue_free()
