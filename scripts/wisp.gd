class_name Wisp
extends Goblin
## Błędny ognik z Topielczego Uroczyska: zielonkawe światełko, które leniwie dryfuje nad
## sadzawkami. Gdy zauważy gracza, leci ku niemu (unosi się nad wodą i przeszkodami),
## a tuż przy nim rozjarza się - czerwone koło ostrzega - i po chwili wybucha.
## Wybuch niszczy ognik. Można go zestrzelić wcześniej.

@export var blast_damage := 26
@export var blast_radius := 34.0

const FUSE := 0.65
const WISP_COLOR := Color(0.7, 1.0, 0.55)

var _fuse := -1.0
var _telegraph: Telegraph
var _drift := Vector2.ZERO
var _glow: Sprite2D


func _ready() -> void:
	super()
	collision_mask = 0  # unosi się nad wodą i przeszkodami
	hurt_radius = 7.0
	map_color = WISP_COLOR
	quest_kind = "wisp"
	_anim_time = randf() * 10.0
	_glow = Sprite2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.6, 1.0, 0.5, 0.55), Color(0.4, 1.0, 0.4, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 48
	texture.height = 48
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_glow.texture = texture
	_glow.position = Vector2(0, -16)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	add_child(_glow)


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -16)


func _physics_process(delta: float) -> void:
	if state == State.DEAD or _process_stun(delta):
		return
	_anim_time += delta
	sprite.frame = int(_anim_time * 10.0) % 8
	sprite.position.y = sin(_anim_time * 2.5) * 3.0
	_glow.modulate.a = 0.7 + 0.3 * sin(_anim_time * 6.0)
	if _fuse >= 0.0:
		_fuse -= delta
		velocity = Vector2.ZERO
		sprite.modulate = Color(1.6, 1.3, 1.0) if fmod(_fuse, 0.16) < 0.08 else Color.WHITE
		if _fuse < 0.0:
			_explode()
		return
	match state:
		State.IDLE:
			# leniwe dryfowanie wokół swojego miejsca
			if randf() < delta * 0.5:
				_drift = Vector2.from_angle(randf() * TAU) * 18.0
			velocity = (home + _drift - global_position).limit_length(20.0)
			if _player_alive() and global_position.distance_to(_player.global_position) < aggro_radius:
				aggro()
		State.CHASE, State.ATTACK:
			if not _player_alive() or _player_is_safe() or position.distance_to(home) > leash_radius:
				state = State.RETURN
			else:
				var to_player := _player.global_position - global_position
				velocity = to_player.normalized() * speed
				if to_player.length() < 22.0:
					_ignite()
		State.RETURN:
			velocity = (home - global_position).limit_length(speed)
			if position.distance_to(home) < 4.0:
				state = State.IDLE
				health = max_health
	move_and_slide()


func _ignite() -> void:
	_fuse = FUSE
	Sfx.play_at("wisp_charge", global_position)
	_telegraph = Telegraph.new()
	_telegraph.shape = Telegraph.Shape.CIRCLE
	_telegraph.radius = blast_radius
	_telegraph.duration = FUSE
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(_telegraph)
	_telegraph.global_position = global_position


func _explode() -> void:
	if is_instance_valid(_telegraph):
		if _player_alive() and _telegraph.contains(_player.global_position):
			_player.take_damage(blast_damage, global_position)
		_telegraph.queue_free()
	MonsterFx.wisp_burst(get_parent(), hurt_center())
	Sfx.play_at("wisp_burst", global_position)
	health = 0
	_die()


func _die() -> void:
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	super()


func _animate(_delta: float) -> void:
	pass
