class_name AlphaWolf
extends Boss
## Wilk Alfa - przewodnik watahy z czerwonymi oczami. Ataki:
## - Skok: czerwone koło w miejscu gracza, Alfa przyczaja się i spada na nie z góry.
## - Rozszarpanie: czerwony stożek przed Alfą, potem cios pazurami i kłami.

@export var pounce_damage := 28
@export var pounce_radius := 38.0
@export var pounce_range := 260.0
@export var cleave_damage := 22
@export var cleave_radius := 74.0
@export var cleave_arc_degrees := 100.0

const POUNCE_TELEGRAPH := 0.9
const LEAP_TIME := 0.45
const LEAP_HEIGHT := 28.0
const CLEAVE_TELEGRAPH := 0.7

var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_t := 0.0
var _ghost_time := 0.0


func _ready() -> void:
	super()
	map_color = Wolf.WOLF_COLOR
	quest_kind = "wolf"


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -16)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	if distance < 64.0:
		_start_attack("cleave", CLEAVE_TELEGRAPH)
		_wind_up(CLEAVE_TELEGRAPH * 0.8, Vector2(1.08, 0.92))
		Sfx.play_at("claw", global_position, -6.0)
		var telegraph := _show_telegraph(Telegraph.Shape.CONE, global_position, to_player.angle(), CLEAVE_TELEGRAPH)
		telegraph.radius = cleave_radius
		telegraph.half_arc = deg_to_rad(cleave_arc_degrees / 2.0)
	elif distance < pounce_range:
		_leap_to = _player.global_position
		_start_attack("pounce", POUNCE_TELEGRAPH)
		_wind_up(POUNCE_TELEGRAPH * 0.9, Vector2(1.16, 0.82))
		Sfx.play_at("werewolf_howl", global_position, -10.0)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, _leap_to, 0.0, POUNCE_TELEGRAPH)
		telegraph.radius = pounce_radius
	else:
		return false
	_face(_player.global_position)
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["pounce", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_leap_from = global_position
				_leap_t = 0.0
				_ghost_time = 0.0
				# wybicie: kurz spod łap, wyrzut sylwetki
				_snap(Vector2(0.82, 1.22))
				BossFx.dust(get_parent(), global_position, 1.3)
				Sfx.play_at("dash", global_position, -4.0)
				_set_stage("act", LEAP_TIME + 0.2)
		["pounce", "act"]:
			# lot łukiem nad przeszkodami - cel to miejsce, gdzie stał gracz
			velocity = Vector2.ZERO
			_leap_t = minf(1.0, _leap_t + delta / LEAP_TIME)
			global_position = _leap_from.lerp(_leap_to, _leap_t)
			sprite.position.y = -sin(_leap_t * PI) * LEAP_HEIGHT
			_ghost_time -= delta
			if _ghost_time <= 0.0:
				_ghost_time = 0.045
				_afterimage(Color(0.9, 0.25, 0.2, 0.5))
			if _leap_t >= 1.0:
				sprite.position.y = 0.0
				# lądowanie: fala uderzeniowa, pęknięcia, odłamki, mocne trzęsienie
				if _player_in_telegraph():
					_hurt_player(pounce_damage, 260.0)
					BossFx.claw(get_parent(), _player.global_position + Vector2(0, -14), -1.0 if sprite.flip_h else 1.0)
				_shake_camera(9.0)
				_snap(Vector2(1.25, 0.8))
				BossFx.slam(get_parent(), global_position, pounce_radius * 1.2)
				_ground_crack(global_position, pounce_radius * 0.9)
				_debris(global_position, 6, 170.0)
				Sfx.play_at("hit_heavy", global_position)
				Sfx.play_at("shockwave", global_position, -6.0)
				_remove_telegraph()
				_set_stage("recover", 0.5)
		["cleave", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				var angle := _telegraph.rotation
				if _player_in_telegraph():
					_hurt_player(cleave_damage, 200.0)
				var tip := global_position + Vector2.from_angle(angle) * cleave_radius * 0.6
				# rozszarpanie: fala cięcia po stożku, dwa krzyżujące się ślady pazurów, rzut do przodu
				BossFx.cleave(get_parent(), global_position + Vector2(0, -8), angle, cleave_radius)
				BossFx.claw(get_parent(), tip + Vector2(0, -10), -1.0, 1.2)
				_snap(Vector2(1.18, 0.88))
				var lunge := sprite.create_tween()
				lunge.tween_property(sprite, "position", Vector2.from_angle(angle) * 10.0, 0.07)
				lunge.tween_property(sprite, "position", Vector2.ZERO, 0.2)
				_shake_camera(5.0)
				Sfx.play_at("big_slash", global_position, -4.0)
				Sfx.play_at("claw", global_position)
				_remove_telegraph()
				_set_stage("recover", 0.5)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Klatki: 0-3 bieg, 4 spoczynek, 5 przyczajenie, 6 skok, 7 rozszarpanie.
func _animate(delta: float) -> void:
	if _attack == "pounce":
		sprite.frame = 5 if _attack_stage == "telegraph" else 6 if _attack_stage == "act" else 4
	elif _attack == "cleave":
		sprite.frame = 5 if _attack_stage == "telegraph" and _stage_timer > CLEAVE_TELEGRAPH * 0.4 else 7
	elif velocity.length() > 8.0:
		_anim_time += delta * 10.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup("wolf_pelt", 5)
