class_name PinnacleBoss
extends Boss
## Bóg - boss szczytowy Mapy Nawii (Pinnacles), sam na swojej arenie (Dungeon._plan_arena). Ogromne zdrowie
## (HEALTH_MULT razy zwykły boss), trzy fazy: przy 66% i 33% zdrowia krótsze przerwy, szybszy ruch, mocniejsze
## odmiany ataków i komunikat na ekranie. Trzy rodzaje (`kind`), po trzy ataki z zapowiedzią (Telegraph):
## - "weles" - Weles, Pan Nawii (niedźwiedź-wąż): Korzenie Nawii (krąg wokół niego - rani i spowalnia), Jad Welesa
##   (kałuże trucizny pod graczem i obok - zatruwają, zostaje trujący opar), Wężowy Zryw (szarża po linii);
##   faza 3 - szerszy krąg korzeni i więcej kałuż,
## - "marzanna" - Marzanna, Pani Zimy: Lodowe Włócznie (wachlarz linii - ranią i mrożą), Zamieć (krąg pod graczem -
##   mocno spowalnia), Mroźny Wybuch (krąg wokół niej); od fazy 2 po wybuchu znika we mgle i staje w innym miejscu
##   areny, w fazie 3 więcej włóczni,
## - "czarnobog" - Czarnobóg, Czarny Bóg: Cięcie Mroku (szeroki stożek przed nim), Kolce Cienia (kolejne kolce po linii
##   do gracza - w fazie 3 trzy linie), Krok przez Cień (znika i staje za graczem, uderza wokół siebie).
## Cień boga (`shade`): przyzwany przez Władcę Hordy (HordeLord) - słabszy, ciemny i półprzezroczysty, bez łupu.
## Na arenie z Pomrokiem (Dungeon.pomrok) legendy i pas wypadają częściej (Pinnacles.POMROK_DROP).
## Animacja (assets/pinnacles/<bóg>.png, tools/pinnacle_art.py): klatki 0-8 spoczynek, 9-17 atak - zamach w czasie
## zapowiedzi, uderzenie po niej.
## Efekty bogów z kreatora efektów PixelLab (pixellab_src/vfx/ids.json) i dźwięki z tools/sfx_synth.py: Weles -
## bagienna zieleń i złoto (FX_WELES_*, weles_*), Marzanna - lód, biel i błękit (FX_MARZANNA_*, marzanna_*),
## Czarnobóg - czerń i fiolet (FX_CZARNOBOG_*, czarnobog_*), Władca Hordy - ogień, czerwień i czerń (FX_HORDE_* tu
## i w HordeLord, horde_*).

@export var kind := "weles"
@export var strike_damage := 80
@export var area_damage := 90
@export var special_damage := 100

## Ile razy więcej zdrowia niż zwykły boss tego poziomu (gracz walczy sam, bez podróżników).
const HEALTH_MULT := 6.0
const PHASES := [0.66, 0.33]
const IDLE_FRAMES := 9
const ATTACK_FRAMES := 9
## Klatka ataku, w której pada cios (koniec zamachu) - wcześniejsze lecą w czasie zapowiedzi.
const IMPACT_FRAME := 5
const IDLE_FPS := 7.0

const ROOTS_RADIUS := 120.0
const VENOM_RADIUS := 44.0
const SERPENT_TIME := 0.45
const SERPENT_WIDTH := 64.0
const SERPENT_REACH := 400.0
const LANCE_LENGTH := 330.0
const LANCE_WIDTH := 28.0
const LANCE_SPREAD := deg_to_rad(18.0)
const BLIZZARD_RADIUS := 95.0
const NOVA_RADIUS := 130.0
const BLINK_RANGE := Vector2(180.0, 320.0)
const CLEAVE_RANGE := 170.0
const CLEAVE_ARC := deg_to_rad(55.0)
const SPIKE_RADIUS := 30.0
const SPIKE_STEP := 46.0
const SPIKE_DELAY := 0.08
const STEP_RADIUS := 95.0

const FX_WELES_ROOTS := preload("res://assets/effects/weles_roots.png")
const FX_WELES_VENOM := preload("res://assets/effects/weles_venom.png")
const FX_WELES_SERPENT := preload("res://assets/effects/weles_serpent.png")
const FX_WELES_ENGAGE := preload("res://assets/effects/weles_engage.png")
const FX_WELES_PHASE := preload("res://assets/effects/weles_phase.png")
const FX_WELES_DEATH := preload("res://assets/effects/weles_death.png")
const FX_MARZANNA_NOVA := preload("res://assets/effects/marzanna_nova.png")
const FX_MARZANNA_LANCE := preload("res://assets/effects/marzanna_lance.png")
const FX_MARZANNA_BLIZZARD := preload("res://assets/effects/marzanna_blizzard.png")
const FX_MARZANNA_MIST := preload("res://assets/effects/marzanna_mist.png")
const FX_MARZANNA_ENGAGE := preload("res://assets/effects/marzanna_engage.png")
const FX_MARZANNA_PHASE := preload("res://assets/effects/marzanna_phase.png")
const FX_MARZANNA_DEATH := preload("res://assets/effects/marzanna_death.png")
const FX_CZARNOBOG_CLEAVE := preload("res://assets/effects/czarnobog_cleave.png")
const FX_CZARNOBOG_SPIKE := preload("res://assets/effects/czarnobog_spike.png")
const FX_CZARNOBOG_STEP := preload("res://assets/effects/czarnobog_step.png")
const FX_CZARNOBOG_STRIKE := preload("res://assets/effects/czarnobog_strike.png")
const FX_CZARNOBOG_ENGAGE := preload("res://assets/effects/czarnobog_engage.png")
const FX_CZARNOBOG_PHASE := preload("res://assets/effects/czarnobog_phase.png")
const FX_CZARNOBOG_DEATH := preload("res://assets/effects/czarnobog_death.png")
const FX_HORDE_ENGAGE := preload("res://assets/effects/horde_engage.png")
const FX_HORDE_PHASE := preload("res://assets/effects/horde_phase.png")
const FX_HORDE_DEATH := preload("res://assets/effects/horde_death.png")
## Zasięg sierpa w czarnobog_cleave i promień uderzenia w czarnobog_strike przy skali 1 (piksele klatki).
const CZARNOBOG_CLEAVE_ART_REACH := 90.0
const CZARNOBOG_STRIKE_ART_RADIUS := 70.0
## Promień kręgu lodowych kolców w marzanna_nova, lot włóczni w marzanna_lance i promień zamieci w marzanna_blizzard
## przy skali 1 (piksele klatki).
const MARZANNA_NOVA_ART_RADIUS := 70.0
const MARZANNA_LANCE_ART_LENGTH := 300.0
const MARZANNA_BLIZZARD_ART_RADIUS := 70.0
## Promień kręgu cierni w weles_roots przy skali 1 (piksele klatki).
const WELES_ROOTS_ART_RADIUS := 80.0

var phase := 1
## Cień boga przyzwany przez Władcę Hordy (make_shade).
var shade := false
var _aim := Vector2.DOWN
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _spots: Array[Vector2] = []
var _lines: Array[Vector2] = []
## Czas zapowiedzi bieżącego ataku (do klatek zamachu).
var _windup := 1.0


func _ready() -> void:
	super()
	add_to_group("pinnacle_bosses")
	hurt_radius = 34.0
	map_color = Pinnacles.GODS[kind]["color"] if Pinnacles.GODS.has(kind) else Color.WHITE
	quest_kind = "pinnacle"


## Zdrowie bossa szczytowego: jak boss tego poziomu razy HEALTH_MULT.
func _apply_level() -> void:
	super()
	max_health = roundi(max_health * HEALTH_MULT)


## Bóg nie wraca do leża i nie leczy się, dopóki gracz żyje na arenie (arena jest zamknięta).
func _process_fight(delta: float) -> void:
	if _player_alive() and not _player_is_safe():
		home = global_position
	super(delta)


func take_damage(amount: int, from_position: Vector2, knockback := 0.0) -> void:
	super(amount, from_position, knockback)
	if state == State.DEAD or shade:
		return
	var marks := _phase_marks()
	for i in marks.size():
		if phase == i + 1 and health < max_health * float(marks[i]):
			phase = i + 2
			attack_interval *= 0.75
			speed *= 1.1
			Sfx.play_at("weles_roar" if kind == "weles" else ("marzanna_wail" if kind == "marzanna" else ("czarnobog_roar" if kind == "czarnobog" else "horde_roar")), global_position)
			_shake_camera(9.0)
			_fx_phase()
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null and hud.has_method("show_banner"):
				hud.show_banner(Lang.t("%s - faza %d!") % [boss_name, phase], map_color)
			_on_phase()
			# jedna faza na cios - kolejna przy następnym (Władca nie przyzywa kilku cieni naraz)
			break


## Progi zdrowia kolejnych faz (podklasa może dać inne).
func _phase_marks() -> Array:
	return PHASES


## Wejście w nową fazę (`phase`) - dla podklas.
func _on_phase() -> void:
	pass


## Zamienia boga w cień przyzwany przez Władcę Hordy: `health_part` jego zdrowia, ciemny i półprzezroczysty,
## mało doświadczenia, bez łupu, od razu w walce.
func make_shade(health_part: float) -> void:
	shade = true
	max_health = maxi(1, roundi(max_health * health_part))
	health = max_health
	xp_reward = roundi(xp_reward * 0.1)
	boss_name = Lang.t("Cień: %s") % Pinnacles.god_name(kind)
	modulate = Color(0.75, 0.45, 0.55, 0.82)
	home = global_position
	aggro()


## Stopień Pomroku areny (0 - zwykła albo poza lochem).
func _pomrok() -> int:
	return int(Goblin.pathing.pomrok) if Goblin.pathing is Dungeon else 0


# ---------------------------------------------------------------- wybór ataku
func _choose_attack(to_player: Vector2) -> bool:
	_face(_player.global_position)
	_aim = to_player.normalized() if to_player != Vector2.ZERO else Vector2.DOWN
	match kind:
		"weles":
			return _choose_weles(to_player.length())
		"marzanna":
			return _choose_marzanna(to_player.length())
		_:
			return _choose_czarnobog(to_player.length())


func _choose_weles(distance: float) -> bool:
	if distance < ROOTS_RADIUS * 1.1 and randf() < 0.5:
		_begin("roots", 0.9)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.9)
		circle.radius = _roots_radius()
		circle.modulate = Color(0.6, 1.0, 0.5)
	elif distance < 420.0 and randf() < 0.55:
		_begin("venom", 1.0)
		_spots = [_player.global_position]
		for i in 2 + phase * 2:
			_spots.append(_player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 140.0))
		for spot: Vector2 in _spots:
			_marker(spot, VENOM_RADIUS, 1.0, Color(0.55, 1.0, 0.35))
	elif distance < SERPENT_REACH:
		_from = global_position
		_to = global_position + _aim * minf(distance + 60.0, SERPENT_REACH)
		_begin("serpent", 0.85)
		var line := _show_telegraph(Telegraph.Shape.LINE, global_position, _aim.angle(), 0.85)
		line.length = _from.distance_to(_to)
		line.width = SERPENT_WIDTH
	else:
		return false
	return true


func _choose_marzanna(distance: float) -> bool:
	if distance < NOVA_RADIUS and randf() < 0.45:
		_begin("nova", 0.9)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.9)
		circle.radius = NOVA_RADIUS
		circle.modulate = Color(0.7, 0.9, 1.0)
	elif distance < LANCE_LENGTH and randf() < 0.55:
		_begin("lances", 1.0)
		_lines.clear()
		var count := 3 if phase < 3 else 5
		for i in count:
			var dir := _aim.rotated((i - (count - 1) / 2.0) * LANCE_SPREAD)
			_lines.append(dir)
			_line_marker(global_position, dir, LANCE_LENGTH, LANCE_WIDTH, 1.0, Color(0.7, 0.9, 1.0))
	elif distance < 460.0:
		_spots = [_player.global_position]
		_begin("blizzard", 1.2)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, _spots[0], 0.0, 1.2)
		circle.radius = BLIZZARD_RADIUS
		circle.modulate = Color(0.7, 0.9, 1.0)
		# zamieć trwa całą zapowiedź (1,2 s), a lodowe kolce wyrastają na jej końcu
		SkillEffects.sheet_once(get_parent(), FX_MARZANNA_BLIZZARD, 16, 10.0, _spots[0], Vector2(93, 87), 0.0, 1.0,
				BLIZZARD_RADIUS / MARZANNA_BLIZZARD_ART_RADIUS)
		Sfx.play_at("marzanna_blizzard", _spots[0])
	else:
		return false
	return true


func _choose_czarnobog(distance: float) -> bool:
	if distance < CLEAVE_RANGE and randf() < 0.5:
		_begin("cleave", 0.9)
		var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _aim.angle(), 0.9)
		cone.radius = CLEAVE_RANGE
		cone.half_arc = CLEAVE_ARC
		cone.modulate = Color(0.8, 0.6, 1.0)
	elif distance < 480.0 and randf() < 0.55:
		_begin("spikes", 0.7)
		_spots.clear()
		var directions: Array[Vector2] = [_aim]
		if phase >= 3:
			directions.append_array([_aim.rotated(0.5), _aim.rotated(-0.5)])
		for dir in directions:
			for i in 8 + phase * 2:
				_spots.append(global_position + dir * SPIKE_STEP * (i + 1))
		for i in _spots.size():
			_marker(_spots[i], SPIKE_RADIUS, 0.7 + (i % (8 + phase * 2)) * SPIKE_DELAY, Color(0.8, 0.55, 1.0))
	elif distance < 520.0:
		_begin("step", 0.6)
		_czarnobog_step()
	else:
		return false
	return true


func _begin(attack: String, time: float) -> void:
	_start_attack(attack, time)
	_windup = time
	_wind_up(time)


# ---------------------------------------------------------------- przebieg ataków
func _update_attack(_delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["roots", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				if _player_in_telegraph():
					_hurt_player(area_damage, 200.0)
					_player.apply_slow(0.4, 2.0)
				_remove_telegraph()
				var radius := _roots_radius()
				SkillEffects.sheet_once(get_parent(), FX_WELES_ROOTS, 16, 12.0, global_position, Vector2(94, 101), 0.0, 1.0,
						radius / WELES_ROOTS_ART_RADIUS)
				_ground_crack(global_position, radius * 0.7)
				Sfx.play_at("weles_roots", global_position)
				_shake_camera(6.0)
				_set_stage("recover", 0.7)
		["venom", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				for spot: Vector2 in _spots:
					SkillEffects.sheet_once(get_parent(), FX_WELES_VENOM, 20, 14.0, spot, Vector2(46, 43), 0.0, 1.0,
							VENOM_RADIUS / 38.0)
					_poison_patch(spot)
					if _player_alive() and _player.global_position.distance_to(spot) <= VENOM_RADIUS:
						_hurt_player(strike_damage, 80.0)
						_player.apply_poison(strike_damage * 0.1, 4.0)
				Sfx.play_at("weles_venom", _spots[0])
				_set_stage("recover", 0.6)
		["serpent", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				Sfx.play_at("weles_hiss", global_position)
				_set_stage("act", SERPENT_TIME)
		["serpent", "act"]:
			var t := clampf(1.0 - _stage_timer / SERPENT_TIME, 0.0, 1.0)
			global_position = _from.lerp(_to, t)
			if Engine.get_physics_frames() % 4 == 0:
				_afterimage(Color(0.5, 1.0, 0.45, 0.4))
			if _player_alive() and _player.global_position.distance_to(global_position) < SERPENT_WIDTH * 0.8:
				_hurt_player(special_damage, 300.0)
			if _stage_timer <= 0.0:
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), FX_WELES_SERPENT, 12, 14.0, global_position, Vector2(85, 35), 0.0, 1.0, 1.3)
				_debris(global_position, 8, 140.0, Color(0.3, 0.35, 0.2))
				_set_stage("recover", 0.8)
		["nova", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				if _player_in_telegraph():
					_hurt_player(area_damage, 220.0)
					_player.apply_slow(0.3, 2.5)
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), FX_MARZANNA_NOVA, 14, 12.0, global_position, Vector2(95, 81), 0.0, 1.0,
						NOVA_RADIUS * 0.8 / MARZANNA_NOVA_ART_RADIUS)
				Sfx.play_at("marzanna_nova", global_position)
				_shake_camera(6.0)
				# od fazy 2 Marzanna znika we mgle i staje gdzie indziej
				if phase >= 2:
					_set_stage("act", 0.5)
					_marzanna_mist()
					return
				_set_stage("recover", 0.7)
		["nova", "act"]:
			if _stage_timer <= 0.0:
				_teleport(_blink_spot())
				_marzanna_mist()
				_set_stage("recover", 0.6)
		["lances", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				for dir: Vector2 in _lines:
					if _player_alive() and _on_line(_player.global_position, global_position, dir, LANCE_LENGTH, LANCE_WIDTH):
						_hurt_player(strike_damage, 140.0)
						_player.apply_slow(0.5, 2.0)
					SkillEffects.sheet_once(get_parent(), FX_MARZANNA_LANCE, 10, 12.0, global_position + Vector2(0, -12),
							Vector2(74, 29), dir.angle(), 1.0, LANCE_LENGTH / MARZANNA_LANCE_ART_LENGTH)
				Sfx.play_at("marzanna_lance", global_position)
				_set_stage("recover", 0.6)
		["blizzard", "telegraph"]:
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(special_damage, 60.0)
					_player.apply_slow(0.25, 3.5)
				_remove_telegraph()
				_set_stage("recover", 0.6)
		["cleave", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.25, 0.82))
				if _player_in_telegraph():
					_hurt_player(special_damage, 260.0)
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_CLEAVE, 14, 14.0, global_position, Vector2(4, 62), _aim.angle(),
						1.0, CLEAVE_RANGE / CZARNOBOG_CLEAVE_ART_REACH)
				_ground_crack(global_position + _aim * 70.0, 50.0)
				Sfx.play_at("czarnobog_cleave", global_position)
				_shake_camera(8.0)
				_set_stage("recover", 0.8)
		["spikes", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_set_stage("act", SPIKE_DELAY * (10 + phase * 2) + 0.1)
				_spike_wave()
		["spikes", "act"]:
			if _stage_timer <= 0.0:
				_set_stage("recover", 0.5)
		["step", "telegraph"]:
			if _stage_timer <= 0.0:
				var behind := _player.global_position + (_player.global_position - global_position).normalized() * 60.0
				_teleport(behind if not _blocked(behind) else _player.global_position + Vector2(0, 50))
				_czarnobog_step()
				_face(_player.global_position)
				_hit_player = false
				var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.55)
				circle.radius = STEP_RADIUS
				circle.modulate = Color(0.8, 0.6, 1.0)
				_set_stage("act", 0.55)
		["step", "act"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				if _player_in_telegraph():
					_hurt_player(strike_damage, 240.0)
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_STRIKE, 10, 12.0, global_position, Vector2(78, 39), 0.0, 1.0,
						STEP_RADIUS / CZARNOBOG_STRIKE_ART_RADIUS)
				_ground_crack(global_position, STEP_RADIUS * 0.7)
				Sfx.play_at("czarnobog_strike", global_position)
				_set_stage("recover", 0.7)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Kolce Cienia wyrastają po kolei wzdłuż linii (każdy rani gracza raz na atak).
func _spike_wave() -> void:
	var per_line := 8 + phase * 2
	for i in _spots.size():
		var spot := _spots[i]
		get_tree().create_timer(SPIKE_DELAY * (i % per_line), false).timeout.connect(func() -> void:
			if state == State.DEAD or not is_inside_tree():
				return
			SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_SPIKE, 18, 16.0, spot + Vector2(0, 6), Vector2(51, 47), 0.0, 1.0, 1.0)
			if _player_alive() and _player.global_position.distance_to(spot) <= SPIKE_RADIUS:
				_hurt_player(area_damage, 160.0))
	Sfx.play_at("czarnobog_spike", global_position)


func _roots_radius() -> float:
	return ROOTS_RADIUS * (1.3 if phase >= 3 else 1.0)


## Trujący opar po Jadzie Welesa (BurningPatch w stylu trucizny).
func _poison_patch(at: Vector2) -> void:
	var patch := BurningPatch.new()
	patch.style = "poison"
	patch.radius = VENOM_RADIUS * 0.8
	patch.damage = maxi(1, roundi(strike_damage * 0.1))
	patch.life = 5.0
	patch.position = at
	get_parent().add_child(patch)


## Znacznik miejsca uderzenia (krąg na ziemi znikający sam).
func _marker(spot: Vector2, radius: float, time: float, color: Color) -> void:
	var telegraph := Telegraph.new()
	telegraph.radius = radius
	telegraph.duration = time
	telegraph.modulate = color
	_place_marker(telegraph, spot, 0.0, time)


## Znacznik linii (lodowa włócznia).
func _line_marker(from: Vector2, dir: Vector2, length: float, width: float, time: float, color: Color) -> void:
	var telegraph := Telegraph.new()
	telegraph.shape = Telegraph.Shape.LINE
	telegraph.length = length
	telegraph.width = width
	telegraph.duration = time
	telegraph.modulate = color
	_place_marker(telegraph, from, dir.angle(), time)


func _place_marker(telegraph: Telegraph, at: Vector2, angle: float, time: float) -> void:
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = at
	telegraph.rotation = angle
	get_tree().create_timer(time + 0.1, false).timeout.connect(func() -> void:
		if is_instance_valid(telegraph):
			telegraph.queue_free())


static func _on_line(point: Vector2, from: Vector2, dir: Vector2, length: float, width: float) -> bool:
	var local := (point - from).rotated(-dir.angle())
	return local.x >= -width / 2.0 and local.x <= length and absf(local.y) <= width / 2.0


## Miejsce, w którym Marzanna staje po zniknięciu: z dala od gracza, na podłodze areny.
func _blink_spot() -> Vector2:
	for i in 12:
		var at := _player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(BLINK_RANGE.x, BLINK_RANGE.y)
		if not _blocked(at):
			return at
	return global_position


func _blocked(at: Vector2) -> bool:
	return pathing != null and pathing.has_method("_blocked") and pathing._blocked(at, 20.0)


func _teleport(at: Vector2) -> void:
	global_position = at
	reset_physics_interpolation()


# ---------------------------------------------------------------- wygląd
func _fx_engage() -> void:
	match kind:
		"weles":
			SkillEffects.sheet_once(get_parent(), FX_WELES_ENGAGE, 22, 14.0, global_position, Vector2(63, 134), 0.0, 1.0,
					fx_scale() * 1.1)
			Sfx.play_at("weles_roar", global_position)
		"marzanna":
			SkillEffects.sheet_once(get_parent(), FX_MARZANNA_ENGAGE, 16, 14.0, global_position, Vector2(77, 167), 0.0, 1.0,
					fx_scale() * 1.1)
			Sfx.play_at("marzanna_wail", global_position)
		"czarnobog":
			SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_ENGAGE, 22, 14.0, global_position, Vector2(63, 134), 0.0, 1.0,
					fx_scale() * 1.1)
			Sfx.play_at("czarnobog_roar", global_position)
		_:
			SkillEffects.sheet_once(get_parent(), FX_HORDE_ENGAGE, 22, 14.0, global_position, Vector2(78, 141), 0.0, 1.0,
					fx_scale() * 1.1)
			Sfx.play_at("horde_roar", global_position)
	super()


## Zmiana fazy: Weles - zielono-złoty wybuch mocy z monetami, Marzanna - mroźny błysk, Czarnobóg - wybuch
## ciemności z czaszkami, Władca Hordy - wybuch ognia.
func _fx_phase() -> void:
	match kind:
		"weles":
			SkillEffects.sheet_once(get_parent(), FX_WELES_PHASE, 14, 12.0, global_position, Vector2(78, 53), 0.0, 1.0,
					fx_scale() * 1.2)
		"marzanna":
			SkillEffects.sheet_once(get_parent(), FX_MARZANNA_PHASE, 16, 12.0, global_position, Vector2(76, 78), 0.0, 1.0,
					fx_scale() * 1.2)
		"czarnobog":
			SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_PHASE, 16, 12.0, global_position, Vector2(78, 54), 0.0, 1.0,
					fx_scale() * 1.2)
		_:
			SkillEffects.sheet_once(get_parent(), FX_HORDE_PHASE, 12, 12.0, global_position, Vector2(78, 60), 0.0, 1.0,
					fx_scale() * 1.3)


## Śmierć: Weles - bagienny wybuch i sypiące się złoto, Marzanna - wybuch lodu i śnieg, Czarnobóg -
## zapadnięcie w otchłań, Władca Hordy - ogromny wybuch ognia.
func _fx_death() -> void:
	match kind:
		"weles":
			SkillEffects.sheet_once(get_parent(), FX_WELES_DEATH, 22, 14.0, global_position, Vector2(70, 76), 0.0, 1.0,
					fx_scale() * 1.3)
			Sfx.play_at("weles_death", global_position)
		"marzanna":
			SkillEffects.sheet_once(get_parent(), FX_MARZANNA_DEATH, 16, 14.0, global_position, Vector2(93, 90), 0.0, 1.0,
					fx_scale() * 1.3)
			Sfx.play_at("marzanna_death", global_position)
		"czarnobog":
			SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_DEATH, 22, 14.0, global_position, Vector2(70, 76), 0.0, 1.0,
					fx_scale() * 1.3)
			Sfx.play_at("czarnobog_death", global_position)
		_:
			SkillEffects.sheet_once(get_parent(), FX_HORDE_DEATH, 18, 14.0, global_position, Vector2(86, 78), 0.0, 1.0,
					fx_scale() * 1.5)
			Sfx.play_at("horde_death", global_position)


## Czarnobóg znika albo pojawia się w kłębie czarnego dymu (Krok przez Cień).
func _czarnobog_step() -> void:
	SkillEffects.sheet_once(get_parent(), FX_CZARNOBOG_STEP, 10, 12.0, global_position, Vector2(56, 50), 0.0, 1.0, fx_scale() * 1.1)
	Sfx.play_at("czarnobog_step", global_position)


## Marzanna znika albo pojawia się w lodowej mgle.
func _marzanna_mist() -> void:
	SkillEffects.sheet_once(get_parent(), FX_MARZANNA_MIST, 12, 12.0, global_position, Vector2(60, 54), 0.0, 1.0, fx_scale() * 1.1)
	Sfx.play_at("marzanna_mist", global_position)


func _cancel_attack() -> void:
	super()
	if sprite != null:
		sprite.position = Vector2.ZERO


## Spoczynek w pętli (klatki 0-8), atak: zamach w czasie zapowiedzi (do IMPACT_FRAME), potem reszta klatek.
func _animate(delta: float) -> void:
	if _attack != "":
		var index := 0
		if _attack_stage == "telegraph":
			var t := clampf(1.0 - _stage_timer / maxf(_windup, 0.01), 0.0, 1.0)
			index = int(t * IMPACT_FRAME)
		else:
			_anim_time += delta * 12.0
			index = mini(IMPACT_FRAME + int(_anim_time), ATTACK_FRAMES - 1)
		sprite.frame = IDLE_FRAMES + clampi(index, 0, ATTACK_FRAMES - 1)
		if _attack_stage == "telegraph":
			_anim_time = 0.0
		return
	_anim_time += delta * IDLE_FPS
	sprite.frame = int(_anim_time) % IDLE_FRAMES
	if velocity.length() > 5.0:
		sprite.flip_h = velocity.x < 0.0
	elif state == State.CHASE and _player != null:
		_face(_player.global_position)


## Cień boga nie zostawia niczego; na Pomroku legendy wypadają częściej.
func _drop_loot() -> void:
	if shade:
		return
	legendary_drop_chance = minf(legendary_drop_chance * Pinnacles.pomrok_mult("drop", _pomrok()), 1.0)
	super()


## Serce boga zawsze (waluta na legendy - Pinnacles.HEART_COST) i bardzo rzadko jego pas (Pinnacles.BELT_CHANCE).
func _drop_trophies() -> void:
	_spawn_pickup(Pinnacles.heart(kind), 1)
	var belt := str(Pinnacles.GODS[kind].get("belt", ""))
	if belt != "" and (_dev_mode() or randf() < Pinnacles.BELT_CHANCE * Pinnacles.pomrok_mult("drop", _pomrok())):
		_spawn_pickup(Loot.legendary_at_level(belt, level), 1)
