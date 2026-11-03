class_name HordeLord
extends PinnacleBoss
## Władca Hordy - ostateczny boss Mapy Nawii (Pinnacles.LORD), rogaty demon-król w koronie z kości. Arena w Kopalni
## goblinów, wejście za serce każdego z trzech bogów. Cztery fazy (PHASES: 75%, 50%, 25% zdrowia):
## - faza 1 - własne ataki: Rozpłatanie (szeroki stożek), Ogień Hordy (deszcz ognia - wybuchy i płonące plamy),
##   Skok Władcy (spada na miejsce gracza z falą uderzeniową), Zew Hordy (przyzywa kilku potworów Hordy),
## - fazy 2-4 - przyzywa cień kolejnego boga (Weles, Marzanna, Czarnobóg - PinnacleBoss.make_shade) z jego atakami;
##   dopóki cień żyje, Władca jest osłonięty (SHADE_SHIELD - obrywa dużo słabiej),
## - faza 4 - wściekłość (aura) i fale Hordy z krawędzi areny co WAVE_TIME s.
## Animacja jak u bogów (assets/pinnacles/horde.png): klatki 0-8 spoczynek, 9-17 atak.
## Efekty z kreatora efektów PixelLab (ogień, czerwień i czerń - FX_HORDE_*, pixellab_src/vfx/ids.json) i dźwięki
## horde_* z tools/sfx_synth.py; pojawienie się, zmiana fazy i śmierć - w PinnacleBoss (rodzaj "horde").

const LORD_PHASES := [0.75, 0.5, 0.25]
const LORD_HEALTH := 1.5
## Część zdrowia boga, z jaką przychodzi jego cień (bogowie mają PinnacleBoss.HEALTH_MULT razy zdrowie bossa).
const SHADE_HEALTH := 0.15
## Ile obrażeń dochodzi do Władcy, gdy żyje cień boga.
const SHADE_SHIELD := 0.3
## Potwory Hordy (fale i Zew Hordy) - z różnych krain, bo Horda zalała cały świat.
const HORDE_KINDS: Array[String] = ["goblin", "brute", "archer", "skeleton", "skeleton_knight", "ghoul", "frogman", "spider", "satyr_brute"]
const CALL_COUNT := 3
const WAVE_TIME := 9.0
const WAVE_SIZE := 5
## Najwięcej żywych potworów Hordy naraz (Zew i fale się nie dokładają ponad to).
const MAX_MINIONS := 14
const CLEAVE_RANGE_LORD := 185.0
const CLEAVE_ARC_LORD := deg_to_rad(60.0)
const METEOR_RADIUS := 50.0
const LEAP_RADIUS := 110.0
const LEAP_TIME := 0.4
const FIRE := Color(1.0, 0.4, 0.25)

const FX_HORDE_CLEAVE := preload("res://assets/effects/horde_cleave.png")
const FX_HORDE_METEOR := preload("res://assets/effects/horde_meteor.png")
const FX_HORDE_LEAP := preload("res://assets/effects/horde_leap.png")
const FX_HORDE_PORTAL := preload("res://assets/effects/horde_portal.png")
const FX_HORDE_CALL := preload("res://assets/effects/horde_call.png")
const FX_HORDE_SHADE := preload("res://assets/effects/horde_shade.png")
const FX_HORDE_SHIELD := preload("res://assets/effects/horde_shield.png")
## Zasięg sierpa w horde_cleave, promień wybuchu w horde_meteor i lądowania w horde_leap przy skali 1 (piksele klatki).
const HORDE_CLEAVE_ART_REACH := 90.0
const HORDE_METEOR_ART_RADIUS := 45.0
const HORDE_LEAP_ART_RADIUS := 85.0
## Meteor w horde_meteor spada przez tyle sekund (4 klatki z 14 na sekundę), zanim wybuchnie.
const METEOR_FALL := 0.29

var _minions: Array[Goblin] = []
## Kopuła osłony cienia (FxLoop) - widoczna, dopóki żyje cień boga.
var _shield_fx: FxLoop
var _shade: Goblin
var _wave_timer := WAVE_TIME
var _call_cooldown := 6.0
var _shield_note := 0.0


func _ready() -> void:
	kind = Pinnacles.LORD
	super()
	hurt_radius = 36.0


## Władca ma jeszcze LORD_HEALTH razy więcej zdrowia niż bóg.
func _apply_level() -> void:
	super()
	max_health = roundi(max_health * LORD_HEALTH)


func _phase_marks() -> Array:
	return LORD_PHASES


## Nowa faza: cień kolejnego boga; w ostatniej wściekłość i fale Hordy.
func _on_phase() -> void:
	var god_index := phase - 2
	if god_index >= 0 and god_index < Pinnacles.ORDER.size():
		_summon_shade(Pinnacles.ORDER[god_index])
	if phase >= LORD_PHASES.size() + 1:
		enraged = true
		_wave_timer = 2.0


## Osłona cienia: dopóki cień boga żyje, do Władcy dochodzi tylko SHADE_SHIELD obrażeń.
func take_damage(amount: int, from_position: Vector2, knockback := 0.0) -> void:
	if shade_alive():
		amount = maxi(1, roundi(amount * SHADE_SHIELD))
		_shield_note -= 1.0
		if _shield_note <= 0.0:
			_shield_note = 12.0
			DamageNumber.spawn_text(get_parent(), hurt_center() + Vector2(0, -24), Lang.t("Osłona cienia!"), Color(0.8, 0.55, 1.0), 9)
	super(amount, from_position, knockback)


func shade_alive() -> bool:
	return is_instance_valid(_shade) and _shade.state != State.DEAD


func minion_count() -> int:
	_minions = _minions.filter(func(m: Goblin) -> bool: return is_instance_valid(m) and m.state != State.DEAD)
	return _minions.size()


func _process_fight(delta: float) -> void:
	super(delta)
	_update_shield()
	if state != State.CHASE:
		return
	_call_cooldown -= delta
	if phase >= LORD_PHASES.size() + 1:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_wave_timer = WAVE_TIME
			_horde_wave()


## Kopuła osłony cienia nad Władcą, dopóki żyje cień boga (półprzezroczysta, żeby Władca był widoczny).
func _update_shield() -> void:
	var show := shade_alive() and state != State.DEAD
	if show and _shield_fx == null:
		_shield_fx = FxLoop.make(FX_HORDE_SHIELD, 16, 12.0, Vector2(74, 74))
		_shield_fx.modulate = Color(1, 1, 1, 0.45)
		_shield_fx.scale = Vector2.ONE * fx_scale()
		_shield_fx.z_index = 1
		add_child(_shield_fx)
	if _shield_fx != null:
		_shield_fx.visible = show


# ---------------------------------------------------------------- przyzwania
## Potwór Hordy w miejscu `at` (przez generator lochu, żeby miał drogę po arenie); null poza lochem.
func _spawn_minion(kind_name: String, at: Vector2) -> Goblin:
	var dungeon := Goblin.pathing as Dungeon
	if dungeon == null:
		return null
	var spawn := dungeon._spawn(kind_name, at, global_position, level)
	var goblin: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if goblin != null:
		_minions.append(goblin)
		goblin.aggro()
		SkillEffects.sheet_once(get_parent(), FX_HORDE_PORTAL, 22, 18.0, goblin.global_position, Vector2(44, 90), 0.0, 1.0, 1.2)
		Sfx.play_at("horde_portal", goblin.global_position)
	return goblin


## Wolne miejsce na arenie w odległości `near`-`far` od punktu `around`.
func _free_around(around: Vector2, near: float, far: float) -> Vector2:
	for i in 12:
		var at := around + Vector2.from_angle(randf() * TAU) * randf_range(near, far)
		if not _blocked(at):
			return at
	return around


func _summon_shade(god: String) -> void:
	var dungeon := Goblin.pathing as Dungeon
	if dungeon == null:
		return
	var at := _free_around(global_position, 120.0, 200.0)
	var spawn := dungeon._spawn(Pinnacles.kind(god), at, _player.global_position if _player_alive() else at, level)
	var node: Goblin = dungeon.w._live_goblins.get(spawn["id"])
	if not node is PinnacleBoss:
		return
	(node as PinnacleBoss).make_shade(SHADE_HEALTH)
	_shade = node
	SkillEffects.sheet_once(get_parent(), FX_HORDE_SHADE, 16, 12.0, node.global_position, Vector2(50, 134), 0.0, 1.0, 1.3)
	Sfx.play_at("horde_shade", node.global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_banner"):
		hud.show_banner(Lang.t("Władca przyzywa cień: %s!\nZabij cień, by zdjąć osłonę") % Pinnacles.god_name(god), Pinnacles.GODS[god]["color"])


## Fala Hordy z krawędzi areny (ostatnia faza).
func _horde_wave() -> void:
	var room := (Goblin.pathing as Dungeon).boss_room if Goblin.pathing is Dungeon else Rect2i()
	for i in mini(WAVE_SIZE, MAX_MINIONS - minion_count()):
		var at := _free_around(global_position, 220.0, 320.0)
		if room.size != Vector2i.ZERO:
			var edge := Vector2(room.position) * Dungeon.CELL + Vector2(randf() * room.size.x, [0.6, room.size.y - 0.6][randi() % 2]) * Dungeon.CELL
			if not _blocked(edge):
				at = edge
		_spawn_minion(HORDE_KINDS.pick_random(), at)
	Sfx.play_at("horde_roar", global_position, -4.0)


# ---------------------------------------------------------------- ataki
func _choose_attack(to_player: Vector2) -> bool:
	_face(_player.global_position)
	_aim = to_player.normalized() if to_player != Vector2.ZERO else Vector2.DOWN
	var distance := to_player.length()
	if _call_cooldown <= 0.0 and minion_count() < MAX_MINIONS / 2 and randf() < 0.3:
		_call_cooldown = 14.0
		_begin("call", 0.9)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.9)
		circle.radius = 70.0
		circle.modulate = FIRE
	elif distance < CLEAVE_RANGE_LORD and randf() < 0.5:
		_begin("lord_cleave", 0.85)
		var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _aim.angle(), 0.85)
		cone.radius = CLEAVE_RANGE_LORD
		cone.half_arc = CLEAVE_ARC_LORD
		cone.modulate = FIRE
	elif distance < 460.0 and randf() < 0.55:
		_begin("meteors", 1.1)
		_spots = [_player.global_position]
		for i in 3 + phase:
			_spots.append(_free_around(_player.global_position, 40.0, 170.0))
		for spot: Vector2 in _spots:
			_marker(spot, METEOR_RADIUS, 1.1, FIRE)
		# meteory zaczynają spadać tak, żeby uderzyć z końcem zapowiedzi
		var spots := _spots.duplicate()
		get_tree().create_timer(1.1 - METEOR_FALL, false).timeout.connect(func() -> void:
			if state == State.DEAD or not is_inside_tree():
				return
			for spot: Vector2 in spots:
				SkillEffects.sheet_once(get_parent(), FX_HORDE_METEOR, 12, 14.0, spot, Vector2(153, 132), 0.0, 1.0,
						METEOR_RADIUS / HORDE_METEOR_ART_RADIUS)
			Sfx.play_at("horde_meteor", spots[0]))
	elif distance < 520.0:
		_from = global_position
		_to = _player.global_position
		_begin("leap", 0.9)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, _to, 0.0, 0.9 + LEAP_TIME)
		circle.radius = LEAP_RADIUS
		circle.modulate = FIRE
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["call", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), FX_HORDE_CALL, 12, 16.0, global_position, Vector2(66, 59), 0.0, 1.0, fx_scale() * 1.3)
				Sfx.play_at("horde_roar", global_position)
				_shake_camera(7.0)
				for i in mini(CALL_COUNT, MAX_MINIONS - minion_count()):
					_spawn_minion(HORDE_KINDS.pick_random(), _free_around(global_position, 60.0, 130.0))
				_set_stage("recover", 0.7)
		["lord_cleave", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.25, 0.82))
				if _player_in_telegraph():
					_hurt_player(special_damage, 260.0)
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), FX_HORDE_CLEAVE, 12, 16.0, global_position, Vector2(4, 55), _aim.angle(), 1.0,
						CLEAVE_RANGE_LORD / HORDE_CLEAVE_ART_REACH)
				_ground_crack(global_position + _aim * 80.0, 60.0)
				Sfx.play_at("horde_cleave", global_position)
				_shake_camera(8.0)
				_set_stage("recover", 0.7)
		["meteors", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				for spot: Vector2 in _spots:
					_fire_patch(spot)
					if _player_alive() and _player.global_position.distance_to(spot) <= METEOR_RADIUS:
						_hit_player = false
						_hurt_player(area_damage, 120.0)
				_shake_camera(6.0)
				_set_stage("recover", 0.6)
		["leap", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				Sfx.play_at("horde_leap", global_position)
				_set_stage("act", LEAP_TIME)
		["leap", "act"]:
			var t := clampf(1.0 - _stage_timer / LEAP_TIME, 0.0, 1.0)
			global_position = _from.lerp(_to, t)
			sprite.position.y = -sin(t * PI) * 60.0
			if Engine.get_physics_frames() % 3 == 0:
				_afterimage(Color(1.0, 0.35, 0.25, 0.4))
			if _stage_timer <= 0.0:
				sprite.position = Vector2.ZERO
				if _blocked(global_position):
					_teleport(_free_around(_to, 0.0, 60.0))
				if _player_in_telegraph():
					_hurt_player(strike_damage, 280.0)
				_remove_telegraph()
				_ground_crack(global_position, LEAP_RADIUS * 0.7)
				_debris(global_position, 10, 160.0, Color(0.35, 0.2, 0.15))
				SkillEffects.sheet_once(get_parent(), FX_HORDE_LEAP, 12, 12.0, global_position, Vector2(86, 41), 0.0, 1.0,
						LEAP_RADIUS / HORDE_LEAP_ART_RADIUS)
				_shake_camera(10.0)
				_set_stage("recover", 0.8)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Płonąca plama po deszczu ognia (BurningPatch).
func _fire_patch(at: Vector2) -> void:
	var patch := BurningPatch.new()
	patch.radius = METEOR_RADIUS * 0.75
	patch.damage = maxi(1, roundi(area_damage * 0.08))
	patch.life = 4.0
	patch.position = at
	get_parent().add_child(patch)


## Śmierć Władcy rozwiewa jego cień i Hordę.
func _die() -> void:
	if shade_alive():
		_shade.take_damage(_shade.health + 1, global_position)
	for minion in _minions:
		if is_instance_valid(minion) and minion.state != State.DEAD:
			minion.take_damage(minion.health + 1, global_position)
	super()
