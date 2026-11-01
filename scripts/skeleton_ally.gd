class_name SkeletonAlly
extends Node2D
## Szkielet sługa z Kostura Mortana: wstaje z pokonanego wroga, rzuca się na najbliższych wrogów i tnie ich
## mieczem, a po LIFE sekundach rozsypuje się w proch.

const TEXTURE := preload("res://assets/cemetery/skeleton.png")
const SPEED := 90.0
const SEEK_RANGE := 240.0
const LIFE := 12.0
const HIT_DAMAGE := 0.6
const HIT_COOLDOWN := 0.8
const TINT := Color(0.7, 1.0, 0.75)

var player: Player
## Grafika sługi (domyślnie szkielet; widmowy wilk Skóry Szarokła podaje własną): arkusz 4 x vframes,
## klatki spoczynku i ataku.
var texture: Texture2D = TEXTURE
var vframes := 2
var idle_frame := 4
var attack_frames := Vector2i(6, 7)
var tint := TINT
var _sprite: Sprite2D
var _life := LIFE
var _anim := 0.0
var _cooldown := 0.0
var _strike := 0.0
var _target: Goblin


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = 4
	_sprite.vframes = vframes
	_sprite.offset = Vector2(0, -texture.get_height() / (2.0 * vframes) + 3.0)
	_sprite.modulate = tint
	add_child(_sprite)
	_sprite.scale = Vector2(1.2, 0.1)
	create_tween().tween_property(_sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_life -= delta
	_cooldown -= delta
	_strike -= delta
	if _life <= 0.0 or not is_instance_valid(player):
		_crumble()
		return
	if _target == null or not is_instance_valid(_target) or _target.state == Goblin.State.DEAD:
		_target = _nearest_enemy()
	if _target == null:
		_sprite.frame = idle_frame
		return
	var to_target := _target.global_position - global_position
	_sprite.flip_h = to_target.x < 0.0
	if to_target.length() < 14.0 + _target.hurt_radius:
		if _cooldown <= 0.0:
			_cooldown = HIT_COOLDOWN
			_strike = 0.25
			_target.take_damage(player.roll_damage(HIT_DAMAGE), global_position, 60.0)
			Sfx.play_at("swing", global_position, -10.0)
		_sprite.frame = attack_frames.y if _strike > 0.0 else attack_frames.x
		return
	global_position += to_target.normalized() * SPEED * delta
	_anim += delta * 8.0
	_sprite.frame = int(_anim) % 4


func _nearest_enemy() -> Goblin:
	var best: Goblin = null
	var best_distance := SEEK_RANGE
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		var d := enemy.global_position.distance_to(global_position)
		if d < best_distance and enemy.state != Goblin.State.DEAD:
			best_distance = d
			best = enemy
	return best


func _crumble() -> void:
	MiscVfx.debris(get_parent(), global_position, tint, 0.5)
	MiscVfx.puff(get_parent(), global_position + Vector2(0, -4), tint, 0.4)
	queue_free()
