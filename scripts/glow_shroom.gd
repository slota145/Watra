class_name GlowShroom
extends Node2D
## Kępa świecących grzybów w Prastarym Lesie. Przygaszona, dopóki nikt nie podejdzie -
## gdy gracz się zbliży, grzyby rozjarzają się turkusowym blaskiem, sypią zarodnikami
## i cicho dzwonią; gdy odejdzie, powoli gasną.

const TEXTURE := preload("res://assets/ancient/glow_shroom.png")
const LIGHT_DISTANCE := 72.0
const COLOR := Color(0.4, 0.95, 1.0)

var _player: Node2D
var _sprite: Sprite2D
var _glow: Sprite2D
var _spores: CPUParticles2D
var _light := 0.0
var _lit := false


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 2
	_sprite.offset = Vector2(0, -8)
	_sprite.flip_h = randf() < 0.5
	add_child(_sprite)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(COLOR, 0.6), Color(COLOR, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 72
	texture.height = 48
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_glow = Sprite2D.new()
	_glow.texture = texture
	_glow.position = Vector2(0, -6)
	_glow.modulate.a = 0.0
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	_glow.z_index = 21  # świeci ponad mrokiem lasu
	add_child(_glow)
	_spores = CPUParticles2D.new()
	_spores.position = Vector2(0, -10)
	_spores.amount = 10
	_spores.lifetime = 1.8
	_spores.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_spores.emission_sphere_radius = 8.0
	_spores.direction = Vector2.UP
	_spores.spread = 50.0
	_spores.gravity = Vector2(0, -6)
	_spores.initial_velocity_min = 3.0
	_spores.initial_velocity_max = 8.0
	_spores.scale_amount_max = 1.5
	_spores.color = Color(COLOR, 0.8)
	_spores.material = additive
	_spores.z_index = 21
	_spores.emitting = false
	add_child(_spores)


func _process(delta: float) -> void:
	if _player == null:
		return
	var near := _player.global_position.distance_to(global_position) < LIGHT_DISTANCE
	_light = move_toward(_light, 1.0 if near else 0.0, delta * (2.5 if near else 0.6))
	_glow.modulate.a = _light * (0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004 + position.x))
	_sprite.frame = 1 if _light > 0.35 else 0
	_spores.emitting = _light > 0.5
	if near and not _lit:
		_lit = true
		Sfx.play_at("shroom_chime", global_position)
	elif not near and _light <= 0.0:
		_lit = false
