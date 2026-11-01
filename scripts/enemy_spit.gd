class_name EnemySpit
extends Node2D
## Kula jadu wypluta przez żaboczłeka: leci prosto, rani gracza przy trafieniu
## i rozpryskuje się na przeszkodach. Da się jej uniknąć - nie skręca za graczem.
## Odmiany (style): "spit" - jad, "javelin" - oszczep ptakoczłeka, "feather" - naelektryzowane
## pióro burzowego orła, "water" - kula wody topielicy, "web" - kłębek sieci pająka (spowalnia),
## "arrow" - strzała goblina łucznika, "note" - zaczarowana nuta satyra grajka (spowalnia),
## "stone" - kamień z procy kobolda, "bone" - kościana włócznia nekromanty.

const SPEED := 170.0
const MAX_RANGE := 260.0
const HIT_RADIUS := 10.0

var direction := Vector2.RIGHT
var damage := 12
var style := "spit"
const STYLE_SPEED := {"spit": SPEED, "javelin": 230.0, "feather": 200.0, "water": 150.0, "web": 160.0, "arrow": 260.0, "note": 175.0, "stone": 220.0, "bone": 210.0}
## Odmiany rysowane animacją z kreatora efektów i odmiany ze smugą za grotem.
const ORB_STYLES := ["spit", "water"]
const TRAIL_STYLES := ["javelin", "feather", "arrow", "stone", "bone"]
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
	# lot z kreatora efektów (MonsterFx): kula jadu i kula wody to zapętlona animacja zamiast rysunku,
	# pociski z drzewcem ciągną za sobą smugę (nuta i sieć - bez smugi)
	var fx: AnimatedSprite2D = null
	if style in ORB_STYLES:
		fx = MonsterFx.orb(style == "water")
	elif style in TRAIL_STYLES:
		fx = MonsterFx.trail()
		fx.z_index = -1
	if fx != null:
		fx.rotation = direction.angle()
		add_child(fx)


func _physics_process(delta: float) -> void:
	var step := direction * float(STYLE_SPEED[style]) * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_splat()
		return
	global_position += step
	_travelled += step.length()
	if _player != null and not _player.is_dead and _player.body_center().distance_to(global_position) < HIT_RADIUS:
		# Serce Gryfa: wiatr odbija pocisk
		if _player.legendary.deflects():
			MonsterFx.hit(get_parent(), global_position)
			queue_free()
			return
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
	if style in ORB_STYLES:  # kula to animacja (MonsterFx.orb)
		return
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
	if style == "bone":  # kościana włócznia nekromanty z zieloną poświatą
		draw_line(-direction * 8.0, direction * 6.0, Color(0.3, 0.8, 0.4, 0.5), 4.0)
		draw_line(-direction * 8.0, direction * 6.0, Color(0.92, 0.9, 0.8), 2.0)
		draw_circle(direction * 6.0, 1.5, Color(1, 1, 0.95))
		return
	if style == "stone":  # kamień z procy kobolda
		draw_circle(Vector2.ZERO, 2.5, Color(0.25, 0.23, 0.2))
		draw_circle(Vector2(-0.5, -0.5), 1.8, Color(0.62, 0.58, 0.52))
		return
	if style == "web":  # kłębek pajęczyny
		for k in 6:
			var a := TAU * k / 6.0
			draw_line(Vector2.ZERO, Vector2.from_angle(a) * 5.0, Color(0.95, 0.95, 1.0, 0.85), 1.0)
		draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.9))
		return
	if style == "feather":  # pióro z iskrami
		draw_line(-direction * 6.0, direction * 5.0, Color(0.85, 0.9, 1.0), 3.0)
		draw_line(-direction * 6.0, direction * 5.0, Color(0.35, 0.6, 1.0), 1.0)
		draw_circle(direction * 5.0, 1.5, Color(0.9, 0.97, 1.0))
		return


func _splat() -> void:
	var wet := style in ["spit", "water"]
	Sfx.play_at("spit_hit" if wet else "hit", global_position, 0.0 if wet else -6.0)
	match style:
		"spit":
			BossFx.acid(get_parent(), global_position, 10.0)
		"water":
			MonsterFx.splash(get_parent(), global_position)
		"feather":
			MonsterFx.zap(get_parent(), global_position)
		_:
			MonsterFx.hit(get_parent(), global_position)
	queue_free()
