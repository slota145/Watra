class_name EnemySpit
extends Node2D
## Kula jadu wypluta przez żaboczłeka: leci prosto, rani gracza przy trafieniu
## i rozpryskuje się na przeszkodach. Da się jej uniknąć - nie skręca za graczem.
## Odmiany (style): "spit" - jad, "javelin" - oszczep ptakoczłeka, "feather" - naelektryzowane
## pióro burzowego orła, "water" - kula wody topielicy, "web" - kłębek sieci pająka (spowalnia),
## "arrow" - strzała goblina łucznika, "note" - zaczarowana nuta satyra grajka (spowalnia).

const SPEED := 170.0
const MAX_RANGE := 260.0
const HIT_RADIUS := 10.0
const COLOR := Color(0.5, 0.9, 0.3)

var direction := Vector2.RIGHT
var damage := 12
var style := "spit"
const STYLE_SPEED := {"spit": SPEED, "javelin": 230.0, "feather": 200.0, "water": 150.0, "web": 160.0, "arrow": 260.0, "note": 175.0}
const STYLE_COLOR := {"spit": COLOR, "javelin": Color(0.75, 0.7, 0.6), "feather": Color(0.55, 0.8, 1.0),
		"water": Color(0.45, 0.8, 0.95), "web": Color(0.9, 0.9, 0.95), "arrow": Color(0.6, 0.5, 0.35), "note": Color(1.0, 0.8, 0.35)}
## Po trafieniu: spowolnienie (mnożnik prędkości, 0 = brak) i zatrucie (obrażenia na sekundę).
var slow := 0.0
var poison := 0.0

var _travelled := 0.0
var _player: Player



## Ruch w _physics_process (60 razy na sekundę) - interpolacja fizyki wygładza go do klatek obrazu
## (np. monitor 240 Hz). Reszta świata ma ją wyłączoną (World), bo porusza się w _process.
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	var trail := CPUParticles2D.new()
	trail.amount = 10
	trail.lifetime = 0.25
	trail.local_coords = false
	trail.spread = 180.0
	trail.initial_velocity_max = 6.0
	trail.gravity = Vector2(0, 40)
	trail.scale_amount_max = 2.0
	trail.color = Color(STYLE_COLOR[style], 0.7)
	if style != "spit":
		trail.gravity = Vector2.ZERO
		trail.amount = 6
	add_child(trail)


func _physics_process(delta: float) -> void:
	var step := direction * float(STYLE_SPEED[style]) * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_splat()
		return
	global_position += step
	_travelled += step.length()
	if _player != null and not _player.is_dead and _player.body_center().distance_to(global_position) < HIT_RADIUS:
		_player.take_damage(damage, global_position - direction * 10.0)
		if slow > 0.0:
			_player.apply_slow(slow, 2.0)
		if poison > 0.0:
			_player.apply_poison(poison, 3.0)
		_splat()
		return
	if _travelled >= MAX_RANGE:
		_splat()


func _draw() -> void:
	if style == "javelin":  # drzewce z kamiennym grotem
		draw_line(-direction * 9.0, direction * 4.0, Color(0.42, 0.3, 0.18), 2.0)
		draw_line(direction * 3.0, direction * 7.0, Color(0.75, 0.75, 0.8), 3.0)
		return
	if style == "arrow":  # drzewce, grot i lotki
		draw_line(-direction * 7.0, direction * 4.0, Color(0.5, 0.36, 0.2), 1.0)
		draw_line(direction * 3.0, direction * 6.0, Color(0.75, 0.75, 0.8), 2.0)
		draw_line(-direction * 7.0, -direction * 4.0 + direction.orthogonal() * 1.5, Color(0.85, 0.25, 0.2), 1.0)
		draw_line(-direction * 7.0, -direction * 4.0 - direction.orthogonal() * 1.5, Color(0.85, 0.25, 0.2), 1.0)
		return
	if style == "note":  # nuta: główka, laska i chorągiewka, lekko kołysząca się w locie
		var sway := Vector2(0, sin(_travelled * 0.15) * 2.0)
		draw_circle(sway, 2.6, Color(0.35, 0.2, 0.05))
		draw_circle(sway, 2.0, Color(1.0, 0.82, 0.35))
		draw_line(sway + Vector2(1.8, 0), sway + Vector2(1.8, -7), Color(0.35, 0.2, 0.05), 1.0)
		draw_line(sway + Vector2(1.8, -7), sway + Vector2(4.5, -4.5), Color(0.35, 0.2, 0.05), 1.0)
		return
	if style == "web":  # kłębek pajęczyny
		for k in 6:
			var a := TAU * k / 6.0
			draw_line(Vector2.ZERO, Vector2.from_angle(a) * 5.0, Color(0.95, 0.95, 1.0, 0.85), 1.0)
		draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.9))
		return
	if style == "water":  # kula wody z jaśniejszym środkiem
		draw_circle(Vector2.ZERO, 4.0, Color(0.15, 0.35, 0.5))
		draw_circle(Vector2.ZERO, 3.0, Color(0.45, 0.8, 0.95))
		draw_circle(Vector2(-1, -1), 1.2, Color(0.9, 1.0, 1.0))
		return
	if style == "feather":  # pióro z iskrami
		draw_line(-direction * 6.0, direction * 5.0, Color(0.85, 0.9, 1.0), 3.0)
		draw_line(-direction * 6.0, direction * 5.0, Color(0.35, 0.6, 1.0), 1.0)
		draw_circle(direction * 5.0, 1.5, Color(0.9, 0.97, 1.0))
		return
	draw_circle(Vector2.ZERO, 3.5, Color(0.18, 0.35, 0.12))
	draw_circle(Vector2.ZERO, 2.6, COLOR)
	draw_circle(Vector2(-1, -1), 1.0, Color(0.85, 1.0, 0.7))


func _splat() -> void:
	var wet := style in ["spit", "water"]
	Sfx.play_at("spit_hit" if wet else "hit", global_position, 0.0 if wet else -6.0)
	var burst := CPUParticles2D.new()
	burst.global_position = global_position
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 10
	burst.lifetime = 0.4
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 20.0
	burst.initial_velocity_max = 50.0
	burst.gravity = Vector2(0, 150)
	burst.scale_amount_max = 2.0
	burst.color = STYLE_COLOR[style]
	burst.emitting = true
	get_parent().add_child(burst)
	burst.finished.connect(burst.queue_free)
	queue_free()
