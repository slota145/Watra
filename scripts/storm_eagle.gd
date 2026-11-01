class_name StormEagle
extends Boss
## Gromoskrzydły, Pan Burz - olbrzymi burzowy orzeł, wódz ptakoludzi z Wietrznych Turni.
## Unosi się nad wielkim gniazdem, a po jego skrzydłach przeskakują iskry. Ataki:
## - Burza: czerwone koła pod graczem jedno po drugim - w każde po chwili wali piorun,
## - Nurkowanie: czerwony pas w stronę gracza, potem orzeł przelatuje nim z ogromną prędkością,
## - Podmuch: czerwone koło wokół orła, uderzenie skrzydeł odrzuca gracza i rozsiewa
##   wachlarz naelektryzowanych piór.

@export var bolt_damage := 34
@export var dive_damage := 42
@export var gust_damage := 22
@export var feather_damage := 18

const STORM_CHARGE := 0.6
const BOLTS := 4
const BOLT_INTERVAL := 0.45
const BOLT_DELAY := 0.8
const BOLT_RADIUS := 34.0
const DIVE_TELEGRAPH := 0.9
const DIVE_LENGTH := 280.0
const DIVE_WIDTH := 36.0
const DIVE_SPEED := 560.0
const GUST_TELEGRAPH := 0.8
const GUST_RADIUS := 84.0
const FEATHERS := 12
const HOVER := 6.0
const FLAP_FRAMES := 8
const FLAP_FPS := 11.0
const FLAP_FPS_IDLE := 8.0
## Efekty z kreatora efektów PixelLab: piorun z nieba (ten sam co Burza Peruna) z trafieniem, smuga nurkowania
## (rysowana w prawo, długość w klatce DIVE_FX_LENGTH) i podmuch skrzydeł z piórami (promień w klatce GUST_FX_RADIUS).
const BOLT_FX := preload("res://assets/effects/storm_strike.png")
const ZAP_FX := preload("res://assets/effects/spell_zap.png")
const DIVE_FX := preload("res://assets/effects/eagle_dive.png")
const DIVE_FX_LENGTH := 100.0
const GUST_FX := preload("res://assets/effects/eagle_gust.png")
const GUST_FX_RADIUS := 86.0

var _bolts_left := 0
var _bolt_timer := 0.0
var _dive_dir := Vector2.RIGHT
var _dive_left := 0.0
var _crackle: FxLoop
var _hover_time := 0.0


func _ready() -> void:
	super()
	hurt_radius = 16.0
	# trzask wyładowań wokół orła (zapętlony efekt z kreatora efektów PixelLab - MiscVfx)
	_crackle = MiscVfx.looping("crackle")
	_crackle.position = Vector2(0, -30)
	_crackle.scale = Vector2(1.3, 0.9)
	_crackle.z_index = 1
	add_child(_crackle)


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("storm_eagle_screech", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	if distance < GUST_RADIUS * 0.9 and randf() < 0.6:
		_start_attack("gust", GUST_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, GUST_TELEGRAPH)
		telegraph.radius = GUST_RADIUS
	elif distance < DIVE_LENGTH * 0.85 and randf() < 0.45:
		_dive_dir = to_player.normalized()
		_face(_player.global_position)
		_start_attack("dive", DIVE_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _dive_dir.angle(), DIVE_TELEGRAPH)
		telegraph.length = DIVE_LENGTH
		telegraph.width = DIVE_WIDTH
	elif distance < 340.0:
		_start_attack("storm", STORM_CHARGE)
		Sfx.play_at("storm_eagle_screech", global_position, -3.0)
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["storm", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_bolts_left = BOLTS
				_bolt_timer = 0.0
				_set_stage("act", BOLTS * BOLT_INTERVAL + BOLT_DELAY + 0.1)
		["storm", "act"]:
			velocity = Vector2.ZERO
			_bolt_timer -= delta
			if _bolts_left > 0 and _bolt_timer <= 0.0 and _player_alive():
				_bolt_timer = BOLT_INTERVAL
				# pierwszy piorun celuje w gracza, kolejne - tam, dokąd ucieka
				var lead := _player.velocity * 0.35 if _bolts_left < BOLTS else Vector2.ZERO
				_call_bolt(_player.global_position + lead)
				_bolts_left -= 1
			if _stage_timer <= 0.0:
				_set_stage("recover", 0.7)
		["dive", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_dive_left = DIVE_LENGTH
				$CollisionShape2D.set_deferred("disabled", true)
				SkillEffects.sheet_once(get_parent(), DIVE_FX, 8, 16.0, global_position + Vector2(0, -20), Vector2(1, 16), _dive_dir.angle(),
						DIVE_LENGTH / DIVE_FX_LENGTH, 1.0)
				Sfx.play_at("wing_gust", global_position)
				_set_stage("act", DIVE_LENGTH / DIVE_SPEED + 0.2)
		["dive", "act"]:
			var step := minf(DIVE_SPEED * delta, _dive_left)
			_dive_left -= step
			global_position += _dive_dir * step
			velocity = Vector2.ZERO
			if not _hit_player and _player_alive() and hurt_center().distance_to(_player.body_center()) < 30.0:
				_hurt_player(dive_damage, 300.0)
				_shake_camera(6.0)
			if _dive_left <= 0.0:
				$CollisionShape2D.set_deferred("disabled", false)
				_remove_telegraph()
				_burst(global_position, Color(0.7, 0.9, 1.0), 20, 120.0)
				_set_stage("recover", 0.8)
		["gust", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(gust_damage, 420.0)
				_remove_telegraph()
				_shake_camera(5.0)
				SkillEffects.sheet_once(get_parent(), GUST_FX, 9, 16.0, global_position, Vector2(90, 60), 0.0, 1.0,
						GUST_RADIUS / GUST_FX_RADIUS)
				Sfx.play_at("wing_gust", global_position)
				var base := randf() * TAU
				for i in FEATHERS:
					var dart := EnemySpit.new()
					dart.style = "feather"
					dart.direction = Vector2.from_angle(base + TAU * i / FEATHERS)
					dart.position = global_position + Vector2(0, -16) + dart.direction * 20.0
					dart.damage = feather_damage
					get_parent().add_child(dart)
				_set_stage("recover", 0.9)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Wejście do walki: piorun wali w samego orła, a dookoła rozchodzi się ryk z falą.
func _fx_engage() -> void:
	super()
	SkillEffects.sheet_once(get_parent(), BOLT_FX, 7, 20.0, global_position, Vector2(25, 141), 0.0, 1.0, 1.2)


## Koło ostrzegawcze - po chwili wali w nie piorun z nieba.
func _call_bolt(target: Vector2) -> void:
	var telegraph := Telegraph.new()
	telegraph.shape = Telegraph.Shape.CIRCLE
	telegraph.radius = BOLT_RADIUS
	telegraph.duration = BOLT_DELAY
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = target
	Sfx.play_at("telegraph", target, -6.0)
	get_tree().create_timer(BOLT_DELAY).timeout.connect(_bolt.bind(telegraph, target))


func _bolt(telegraph: Telegraph, target: Vector2) -> void:
	if is_instance_valid(telegraph):
		if state != State.DEAD and _player_alive() and telegraph.contains(_player.global_position):
			_player.take_damage(bolt_damage, target)
		telegraph.queue_free()
	if not is_inside_tree():
		return
	SkillEffects.sheet_once(get_parent(), BOLT_FX, 7, 20.0, target, Vector2(25, 141))
	SkillEffects.sheet_once(get_parent(), ZAP_FX, 5, 20.0, target, Vector2(22, 22), 0.0, 1.0, 1.5)
	_burst(target, Color(0.3, 0.3, 0.35), 10, 80.0)
	_shake_camera(3.0)
	Sfx.play_at("thunder", target, -4.0)


func _cancel_attack() -> void:
	super()
	_bolts_left = 0
	$CollisionShape2D.set_deferred("disabled", false)


## Klatki: 0-7 lot (pełne uderzenie skrzydeł: w górze, w dół pod tułów i z powrotem), 8 spoczynek,
## 9 ładowanie burzy, 10 nurkowanie, 11 wrzask / podmuch. Orzeł macha skrzydłami także w spoczynku
## (unosi się nad gniazdem) - wolniej niż w pościgu; tułów podrywa się przy każdym uderzeniu w dół.
func _animate(delta: float) -> void:
	_hover_time += delta
	if _attack == "storm":
		sprite.frame = 9 if _attack_stage != "recover" else 11
	elif _attack == "dive":
		sprite.frame = 10 if _attack_stage == "act" else 9
		sprite.flip_h = _dive_dir.x < 0.0
	elif _attack == "gust":
		sprite.frame = 11 if _attack_stage != "telegraph" else 9
	else:
		_anim_time += delta * (FLAP_FPS_IDLE if state == State.IDLE else FLAP_FPS)
		sprite.frame = int(_anim_time) % FLAP_FRAMES
		if state != State.IDLE:
			if velocity.length() > 8.0:
				sprite.flip_h = velocity.x < 0.0
			elif _player != null:
				_face(_player.global_position)
	if _attack == "dive":
		sprite.position.y = -2.0
	elif sprite.frame < FLAP_FRAMES:
		sprite.position.y = -HOVER - sin(fmod(_anim_time, FLAP_FRAMES) / FLAP_FRAMES * TAU) * 3.0
	else:
		sprite.position.y = -HOVER - sin(_hover_time * 3.0) * 2.0


func _die() -> void:
	super()
	_crackle.visible = false
	Sfx.play_at("storm_eagle_screech", global_position, 3.0)
	Sfx.play_at("thunder", global_position)


func _drop_trophies() -> void:
	_spawn_pickup("storm_feather", 8)
	_spawn_pickup("goat_hide", 3)
