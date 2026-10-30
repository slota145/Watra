class_name KoboldBomb
extends Node2D
## Bomba kobolda: leci łukiem do celu (czarna kula z iskrzącym lontem i cieniem na ziemi), a miejsce
## upadku od razu pokazuje czerwone koło (Telegraph) - po wylądowaniu wybucha i rani gracza w kole.
## Odmiany: zwykła bomba saperów, ciężka beczka bombardiera (duży promień, dłuższy lot) i "fire" - zapalająca,
## po wybuchu zostawia na chwilę płonącą plamę, "acid" - kula kwasu czerwia (trująca kałuża).

var target := Vector2.ZERO
var damage := 20
var radius := 30.0
var flight := 0.9
var height := 40.0
## Po wylądowaniu lont tli się jeszcze tyle sekund (koło dalej się wypełnia), potem wybuch.
var fuse := 0.0
var style := "bomb"
## Rani też wrogów (bomba gracza z legendy).
var hurts_enemies := false

var _from := Vector2.ZERO
var _time := 0.0
var _landed := false
var _telegraph: Telegraph
var _spark := 0.0


func _ready() -> void:
	_from = global_position
	z_index = 3
	var telegraph := Telegraph.new()
	telegraph.shape = Telegraph.Shape.CIRCLE
	telegraph.radius = radius
	telegraph.duration = flight + fuse
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = target
	_telegraph = telegraph


func _process(delta: float) -> void:
	_time += delta
	_spark += delta
	if not _landed:
		var t := minf(_time / flight, 1.0)
		global_position = _from.lerp(target, t)
		if t >= 1.0:
			_landed = true
			Sfx.play_at("hammer", target, -6.0)
	if _landed and _time >= flight + fuse:
		_explode()
		return
	queue_redraw()


func _draw() -> void:
	var t := minf(_time / flight, 1.0)
	var lift := sin(t * PI) * height if not _landed else 0.0
	var size := 3.5 if style == "bomb" else 6.0 if style == "barrel" else 3.0
	# cień na ziemi
	draw_circle(Vector2(0, 1), size * (0.9 - lift / height * 0.4), Color(0, 0, 0, 0.3))
	var body := Vector2(0, -lift - size)
	if style == "barrel":
		draw_rect(Rect2(body - Vector2(5, 6), Vector2(10, 12)), Color(0.42, 0.27, 0.14))
		draw_rect(Rect2(body - Vector2(5, 3), Vector2(10, 1.5)), Color(0.2, 0.2, 0.22))
		draw_rect(Rect2(body + Vector2(-5, 2), Vector2(10, 1.5)), Color(0.2, 0.2, 0.22))
	elif style == "acid":
		draw_circle(body, size + 1.0, Color(0.2, 0.4, 0.1))
		draw_circle(body + Vector2(-1, -1), size * 0.6, Color(0.6, 1.0, 0.35))
		return
	elif style == "fire":
		draw_circle(body, size, Color(0.55, 0.2, 0.08))
		draw_circle(body + Vector2(-1, -1), size * 0.5, Color(1.0, 0.6, 0.2))
	else:
		draw_circle(body, size, Color(0.1, 0.1, 0.12))
		draw_circle(body + Vector2(-1.2, -1.2), 1.0, Color(0.5, 0.5, 0.55))
	# iskrzący lont
	var flick := 1.0 if fmod(_spark, 0.12) < 0.06 else 0.6
	draw_line(body + Vector2(0, -size), body + Vector2(1.5, -size - 3), Color(0.7, 0.6, 0.4), 1.0)
	draw_circle(body + Vector2(2, -size - 3.5), 1.4 * flick, Color(1.0, 0.85, 0.3))


func _explode() -> void:
	set_process(false)
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	var parent := get_parent()
	var acid := style == "acid"
	Sfx.play_at("spit_hit" if acid else "explosion", target, -2.0 if style == "barrel" else -6.0)
	SkillEffects.shockwave(parent, target, radius, Color(0.5, 0.95, 0.3) if acid else Color(1.0, 0.55, 0.2))
	var layer := get_tree().get_first_node_in_group("floor_layer")
	if not acid:
		SkillEffects.ground_crack(layer if layer != null else parent, target, radius * 0.8, 2.5)
	if not acid:
		_fire_burst(parent)
	var player: Player = get_tree().get_first_node_in_group("player")
	if hurts_enemies:
		for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(target) <= radius:
				enemy.take_damage(damage, target, 160.0)
	elif player != null and not player.is_dead and player.global_position.distance_to(target) <= radius:
		player.take_damage(damage, target)
		player._knockback = (player.global_position - target).normalized() * 200.0
	if player != null and player.global_position.distance_to(target) < 260.0:
		player.add_shake(5.0 if style == "barrel" else 2.5)
	if style == "fire" or acid:
		var patch := BurningPatch.new()
		patch.style = "poison" if acid else "fire"
		patch.radius = radius * 0.8
		patch.damage = maxi(1, damage / 5)
		patch.hurts_enemies = hurts_enemies
		(layer if layer != null else parent).add_child(patch)
		patch.global_position = target
	queue_free()


func _fire_burst(parent: Node) -> void:
	for kind in 2:
		var p := CPUParticles2D.new()
		p.global_position = target
		p.one_shot = true
		p.explosiveness = 1.0
		p.amount = 26 if kind == 0 else 14
		p.lifetime = 0.5 if kind == 0 else 1.0
		p.spread = 180.0
		p.direction = Vector2.UP
		p.initial_velocity_min = radius * 1.5
		p.initial_velocity_max = radius * 3.5
		p.gravity = Vector2(0, -20) if kind == 1 else Vector2(0, 60)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0 if kind == 0 else 6.0
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(0.3, 0.25, 0.22, 0.0)]) if kind == 0 \
				else PackedColorArray([Color(0.35, 0.32, 0.3, 0.7), Color(0.25, 0.23, 0.22, 0.0)])
		p.color_ramp = ramp
		p.z_index = 4
		p.emitting = true
		parent.add_child(p)
		p.finished.connect(p.queue_free)
