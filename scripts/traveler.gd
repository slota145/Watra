class_name Traveler
extends CharacterBody2D
## Widoczny podróżnik ze spisu (Travelers) - stawia go świat (World._sync_travelers). Dwa tryby:
## - "hunt" (kraina): krąży wokół siedliska, rzuca się na zwykłe potwory w pobliżu (bossów omija), walczy wręcz,
##   z łuku albo czarami; trafiony potwór odpowiada (Goblin.objective). Zabite przez niego potwory nie dają graczowi
##   łupu ani doświadczenia (Goblin.traveler_damage). Ranny regeneruje się poza walką; gdy padnie - znika i wstaje
##   w Ostoi (Travelers.die), a po łowach wraca do Ostoi w płomieniach Watry.
## - "town" (Ostoja): spaceruje między placem, Watrą, karczmą, tablicą ogłoszeń i gildią, rzuca hasła jak gracze w MMO.
## - "party" (drużyna gracza): idzie za graczem (przez krainy i lochy - World), bije wrogów przy graczu, także bossów
##   (słabiej); jego zabójstwa liczą się graczowi (łup i doświadczenie - nie zapisuje Goblin.traveler_damage).
## Łowcy pozdrawiają przechodzącego gracza i dają wskazówki o krainie (Travelers.GREETINGS / HINTS).
## Nad głową imię i poziom (jasnozielone jak inni gracze, drużyna - niebieskie) oraz pasek zdrowia w walce.

const SHADOW := preload("res://assets/shadow.png")
const NAME_COLOR := Color(0.55, 1.0, 0.6)
const SPEED := 46.0
const WALK_FPS := 8.0
const AGGRO := 150.0
const REACH := {"melee": 22.0, "bow": 115.0, "spell": 100.0}
const COOLDOWN := {"melee": 0.9, "bow": 1.0, "spell": 1.4}
## Ułamek zdrowia celu za cios (przy równym poziomie) - potwór pada po kilku-kilkunastu ciosach.
const HIT_FRACTION := {"melee": 0.11, "bow": 0.09, "spell": 0.15}
const SPELL_COLOR := Color(0.55, 0.75, 1.0)
const PARTY_COLOR := Color(0.55, 0.8, 1.0)
## Bossowie są dużo wytrzymalsi - drużyna pomaga, ale walka zostaje na graczu.
const BOSS_FACTOR := 0.12
const GREET_RANGE := 70.0

var data: Dictionary = {}
var mode := "hunt"
var travelers: Travelers
## Środek siedliska / punkty w Ostoi, wokół których krąży.
var home := Vector2.ZERO
var town_points: Array[Vector2] = []
var hit_radius := 8.0
var max_health := 100.0
var health := 100.0

var _sprite: Sprite2D
var _label: Label
var _bubble: Label
var _bar: ProgressBar
var _target: Goblin
var _waypoint := Vector2.ZERO
var _idle := 0.0
var _cooldown := 0.0
var _scan := 0.0
var _anim := 0.0
var _strike := 0.0
var _facing := Vector2.DOWN
var _stuck := 0.0
var _last_pos := Vector2.ZERO
var _calm := 0.0
var _talk := 0.0
var _leaving := false
var _fighting := false
## Kraina (do wskazówek) i miejsce w szyku drużyny.
var zone_key := "forest"
var slot := Vector2(-24, 14)
var _greet := 0.0
var _player: Node2D


func _ready() -> void:
	add_to_group("travelers")
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.scale = Vector2(1.2, 1)
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/npc/%s.png" % data.get("look", "adventurer_a"))
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.offset = Vector2(0, -19)
	add_child(_sprite)
	_label = _make_label("%s  [%d]" % [data.get("name", "?"), int(data.get("level", 1))], 7, NAME_COLOR)
	_label.position = Vector2(-60, -50)
	_bubble = _make_label("", 7, Color(1, 1, 1))
	_bubble.position = Vector2(-60, -62)
	_bubble.visible = false
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.size = Vector2(22, 3)
	_bar.position = Vector2(-11, -40)
	_bar.max_value = 1.0
	_bar.add_theme_stylebox_override("background", UiStyle.panel(Color(0.1, 0.05, 0.05), Color(0, 0, 0, 0), 0))
	_bar.add_theme_stylebox_override("fill", UiStyle.panel(Color(0.85, 0.25, 0.25), Color(0, 0, 0, 0), 0))
	_bar.visible = false
	add_child(_bar)
	var level := int(data.get("level", 1))
	max_health = Levels.damage(level) * 14.0 * (1.3 if data.get("weapon", "") == "melee" else 1.0)
	health = max_health
	_waypoint = global_position
	_last_pos = global_position
	_talk = randf_range(6.0, 20.0)
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if mode == "party":
		_label.add_theme_color_override("font_color", PARTY_COLOR)
	else:
		refresh_color()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(120, 10)
	label.z_index = 30
	add_child(label)
	return label


func is_alive() -> bool:
	return health > 0.0 and not _leaving and not _fighting


## Cios potwora (Goblin.objective).
func take_hit(amount: float) -> void:
	if not is_alive():
		return
	health -= amount
	_calm = 0.0
	_sprite.modulate = Color(1, 0.5, 0.5)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if health <= 0.0:
		_fall()


func _physics_process(delta: float) -> void:
	if _leaving or _fighting:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_strike = maxf(_strike - delta, 0.0)
	_calm += delta
	match mode:
		"hunt":
			_process_hunt(delta)
			_process_greeting(delta)
		"party":
			_process_party(delta)
		_:
			_process_town(delta)
	_animate(delta)
	_bar.visible = mode != "town" and health < max_health
	_bar.value = health / max_health


# ---------------------------------------------------------------- łowy
func _process_hunt(delta: float) -> void:
	# regeneracja poza walką
	if _calm > 4.0:
		health = minf(health + max_health * 0.04 * delta, max_health)
	if _target != null and (not is_instance_valid(_target) or _target.state == Goblin.State.DEAD):
		_target = null
	_scan -= delta
	if _target == null and _scan <= 0.0:
		_scan = 0.5
		_target = _find_target()
	if _target == null:
		_wander(delta, home, 220.0)
		return
	var weapon: String = data.get("weapon", "melee")
	var to := _target.hurt_center() - global_position
	if to.length() > REACH[weapon]:
		_move(to.normalized(), delta)
		return
	velocity = Vector2.ZERO
	_facing = to.normalized()
	if _cooldown == 0.0:
		_cooldown = COOLDOWN[weapon]
		_attack(weapon)


func _find_target(center := Vector2.INF, bosses := false) -> Goblin:
	if center == Vector2.INF:
		center = global_position
	var best: Goblin = null
	var best_d := AGGRO
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		# bossy zostawia graczowi (w drużynie pomaga), zwierzyny i manekinów treningowych nie rusza
		if (enemy is Boss and not bosses) or enemy.quest_kind == "animal" or enemy.state == Goblin.State.DEAD \
				or enemy.scene_file_path.contains("dummy"):
			continue
		var d := enemy.global_position.distance_to(center)
		if d < best_d:
			best_d = d
			best = enemy
	return best


func _attack(weapon: String) -> void:
	_strike = 0.3
	_calm = 0.0
	var level := int(data.get("level", 1))
	var ratio := clampf(1.0 + (level - _target.level) * 0.06, 0.4, 2.5)
	var amount := maxi(1, roundi(_target.max_health * HIT_FRACTION[weapon] * ratio * randf_range(0.85, 1.15)
			* (BOSS_FACTOR if _target is Boss else 1.0)))
	var at := _target.hurt_center()
	match weapon:
		"melee":
			SkillEffects.crescent(get_parent(), global_position + Vector2(0, -10), _facing.angle(), PI * 0.4, 22.0)
			Sfx.play_at("swing", global_position)
		"bow":
			SkillEffects.spark(get_parent(), at, Color(0.95, 0.85, 0.6), 4)
			Sfx.play_at("bow", global_position)
		"spell":
			SkillEffects.spark(get_parent(), at, SPELL_COLOR, 8)
			Sfx.play_at("magic", global_position)
	_target.objective = self
	# zabójstwa drużyny liczą się graczowi
	if mode != "party":
		_target.traveler_damage += amount
	_target.take_damage(amount, global_position, 40.0)
	if _target.state == Goblin.State.DEAD and travelers != null:
		travelers.add_kills(data, 1)


## Padł: znika, a spis odsyła go do Ostoi (wstanie po chwili).
func _fall() -> void:
	if travelers != null:
		travelers.die(data)
	_leave(Color(0.6, 0.6, 0.65))


## Odejście z krainy (koniec łowów albo śmierć): błysk i zniknięcie.
func _leave(color := Color(1.0, 0.6, 0.25)) -> void:
	if _leaving:
		return
	_leaving = true
	SkillEffects.spark(get_parent(), global_position + Vector2(0, -12), color, 14)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


## Spis odesłał go gdzie indziej - wraca do Ostoi w płomieniach Watry.
func recall() -> void:
	_leave()


# ---------------------------------------------------------------- drużyna
func _process_party(delta: float) -> void:
	if _calm > 4.0:
		health = minf(health + max_health * 0.05 * delta, max_health)
	if _player == null or not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	# daleko w tyle (np. po skoku gracza) - dobiega od razu
	if to_player.length() > 420.0:
		global_position = _player.global_position + slot
		reset_physics_interpolation()
		_target = null
		return
	if _target != null and (not is_instance_valid(_target) or _target.state == Goblin.State.DEAD):
		_target = null
	_scan -= delta
	if _target == null and _scan <= 0.0:
		_scan = 0.4
		_target = _find_target(_player.global_position, true)
	if _target != null and _target.global_position.distance_to(_player.global_position) < AGGRO * 1.4:
		var weapon: String = data.get("weapon", "melee")
		var to := _target.hurt_center() - global_position
		if to.length() > REACH[weapon]:
			_move(to.normalized(), delta, 1.2)
			return
		velocity = Vector2.ZERO
		_facing = to.normalized()
		if _cooldown == 0.0:
			_cooldown = COOLDOWN[weapon]
			_attack(weapon)
		return
	_target = null
	var spot := _player.global_position + slot - global_position
	if spot.length() > 14.0:
		_move(spot.normalized(), delta, clampf(spot.length() / 60.0, 0.8, 1.6))
	else:
		velocity = Vector2.ZERO


## Gracz przechodzi obok łowcy: pozdrowienie albo wskazówka o krainie (co jakiś czas).
func _process_greeting(delta: float) -> void:
	_greet -= delta
	if _greet > 0.0 or _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(global_position) < GREET_RANGE:
		_greet = randf_range(50.0, 90.0)
		var hints: Array = Travelers.HINTS.get(zone_key, [])
		_say(hints.pick_random() if not hints.is_empty() and randf() < 0.55 else Travelers.GREETINGS.pick_random())
	else:
		_greet = 0.5


## Dołączenie do drużyny gracza (w miejscu, bez znikania).
func become_party(at_slot: Vector2) -> void:
	mode = "party"
	slot = at_slot
	_target = null
	_label.add_theme_color_override("font_color", PARTY_COLOR)


## Kolor imienia ostrzega: zielone - przyjazny, żółte - pojedynkowicz, czerwone - zbój (zależnie od trybu świata).
func refresh_color() -> void:
	if mode == "party":
		_label.add_theme_color_override("font_color", PARTY_COLOR)
	elif travelers != null:
		_label.add_theme_color_override("font_color", WorldModes.TEMPERS[travelers.behavior(data)]["color"])


## Walka z graczem (pojedynek, napad): na jej czas podróżnika zastępuje rywal (Rival) - tu znika i czeka.
func hide_for_fight() -> void:
	visible = false
	_fighting = true
	velocity = Vector2.ZERO


func show_after_fight(at: Vector2) -> void:
	if travelers != null and data.get("state", "") == "dead":
		queue_free()
		return
	global_position = at
	reset_physics_interpolation()
	visible = true
	_fighting = false
	_target = null
	_greet = 30.0


## Odmowa gracza: łowcy przenoszą się na inny spot (znikają; świat postawi ich gdzie indziej).
func relocate() -> void:
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func() -> void:
		if mode == "hunt":
			recall())


## Powiedzenie czegoś z zewnątrz (zaproszenie, podziękowanie).
func say(text: String) -> void:
	_say(text)


# ---------------------------------------------------------------- Ostoja
func _process_town(delta: float) -> void:
	_talk -= delta
	if _talk <= 0.0:
		_talk = randf_range(14.0, 35.0)
		_say(Travelers.LINES_TOWN.pick_random())
	if town_points.is_empty():
		velocity = Vector2.ZERO
		return
	if _idle > 0.0:
		_idle -= delta
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(_waypoint) < 6.0 or _waypoint == Vector2.ZERO:
		_idle = randf_range(3.0, 9.0)
		_waypoint = town_points.pick_random() + Vector2(randf_range(-26, 26), randf_range(-14, 14))
		return
	_move(global_position.direction_to(_waypoint), delta, 0.6)


func _say(text: String) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(3.5)
	tween.tween_property(_bubble, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _bubble.visible = false)


# ---------------------------------------------------------------- ruch i animacja
func _wander(delta: float, center: Vector2, radius: float) -> void:
	if _idle > 0.0:
		_idle -= delta
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(_waypoint) < 8.0:
		_idle = randf_range(1.0, 4.0)
		_waypoint = center + Vector2.from_angle(randf() * TAU) * randf_range(20.0, radius)
		return
	_move(global_position.direction_to(_waypoint), delta)


func _move(dir: Vector2, delta: float, speed_factor := 1.0) -> void:
	_facing = dir
	velocity = dir * SPEED * speed_factor
	move_and_slide()
	# utknął na przeszkodzie - inny cel wędrówki
	_stuck += delta
	if _stuck > 1.0:
		if global_position.distance_to(_last_pos) < 4.0:
			_waypoint = global_position + Vector2.from_angle(randf() * TAU) * 60.0
			if _target != null and mode == "hunt":
				_target = null
				_scan = 2.0
		_stuck = 0.0
		_last_pos = global_position


func _animate(delta: float) -> void:
	var row := 0
	if absf(_facing.x) >= absf(_facing.y):
		_sprite.flip_h = _facing.x < 0.0
		row = 2
	else:
		row = 0 if _facing.y > 0.0 else 1
	if _strike > 0.0:
		_sprite.frame = 3 * 4 + int((0.3 - _strike) / 0.3 * 4.0) % 4
		_sprite.flip_h = _facing.x < 0.0
		return
	if velocity.length() > 1.0:
		_anim += delta * WALK_FPS
		_sprite.frame = row * 4 + int(_anim) % 4
	else:
		_sprite.frame = row * 4
