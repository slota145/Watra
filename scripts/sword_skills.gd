class_name SwordSkills
extends Node
## Umiejętności drzewka miecza (SkillTree "melee") z własną obsługą - dziecko gracza, jak LegendaryEffects:
## - Mgnienie: dopóki trzymasz klawisz, postać doskakuje do najbliższego widocznego wroga i tnie (mana za każdy skok).
##   Combo z Młynkiem: Mgnienie w trakcie Młynka to wirujące Mgnienie - seria szybkich skoków od wroga do wroga
##   z odnowieniem; węzeł kluczowy Nieustający Wir znosi odnowienie (skoki trwają, dopóki trzymasz klawisz).
## - Dymne Wybuchy: przytrzymanie ładuje (1-3 rzędy po 3 wybuchy dymu w stożku przed postacią), puszczenie odpala.
##   Combo: zaraz po innej umiejętności wszystkie 9 wybuchów od razu, bez ładowania. Atak i czar jednocześnie.

const SMOKE_TAGS := ["attack", "spell"]
const SMOKE_COLOR := Color(0.78, 0.78, 0.82)
const FLICKER_COLOR := Color(0.6, 0.85, 1.0)
## Odstęp między rzędami wybuchów (s) i promień cięcia po skoku Mgnienia.
const SMOKE_RING_DELAY := 0.12
const FLICKER_HIT_RADIUS := 30.0

var _player: Player
var _flicker_timer := 0.0
var _whirl_cooldown := 0.0
var _whirl_cooldown_total := 0.0
var _whirl_jumps_left := 0
var _whirl_jump_timer := 0.0
var _last_target: Goblin
## Ładowanie Dymnych Wybuchów: sekundy ładowania (-1 - nie ładujemy) i ostatni osiągnięty rząd (do błysku).
var _smoke_charge := -1.0
var _smoke_stage := 0
var _smoke_swirl: CPUParticles2D


func _init(player: Player) -> void:
	_player = player


## Naciśnięty slot umiejętności (trzymanie sprawdza Player.is_skill_held).
func press(id: String) -> void:
	if _player.skills.level_of(id) <= 0:
		_player._hint("Wybierz %s w drzewku umiejętności (K)" % Skills.get_data(id)["name"])
		return
	match id:
		"flicker":
			_press_flicker()
		"smoke_burst":
			_press_smoke()


## Przerwanie (śmierć, zmiana broni).
func cancel() -> void:
	_whirl_jumps_left = 0
	_stop_smoke_charge()


func cooldown_of(id: String) -> Vector2:
	if id == "flicker":
		return Vector2(_whirl_cooldown, maxf(_whirl_cooldown_total, _whirl_cooldown))
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	_whirl_cooldown = maxf(_whirl_cooldown - delta, 0.0)
	if _player.is_dead:
		cancel()
		return
	_process_flicker(delta)
	_process_smoke(delta)


# ---------------------------------------------------------------- Mgnienie
func _press_flicker() -> void:
	if _player.is_whirling():
		if _endless_whirl():
			return
		if _whirl_cooldown > 0.0:
			_player._hint("Wirujące Mgnienie się odnawia")
			return
		_whirl_jumps_left = Skills.whirl_flicker_jumps(_player.skills.level_of("flicker"))
		_whirl_jump_timer = 0.0
		_whirl_cooldown = Skills.WHIRL_FLICKER_COOLDOWN * _player.stats.cooldown_multiplier()
		_whirl_cooldown_total = _whirl_cooldown
		Sfx.play("whirl", 2.0, 1.3)
		return
	_flicker_timer = 0.0


func _endless_whirl() -> bool:
	return _player.skills.has_keystone("melee", "endless_whirl")


func _process_flicker(delta: float) -> void:
	_flicker_timer -= delta
	_whirl_jump_timer -= delta
	var whirling := _player.is_whirling()
	var level := _player.skills.level_of("flicker")
	if level <= 0 or _player.stats.weapon_type() != "melee":
		_whirl_jumps_left = 0
		return
	# wirujące Mgnienie: seria skoków w trakcie Młynka (z Nieustającym Wirem - dopóki trzymasz klawisz)
	var endless := whirling and _endless_whirl() and _player.is_skill_held("flicker")
	if whirling and (_whirl_jumps_left > 0 or endless):
		if _whirl_jump_timer <= 0.0:
			_whirl_jump_timer = Skills.WHIRL_FLICKER_INTERVAL / _player._skill_speed()
			if _jump(Skills.FLICKER_RANGE * 1.2, level, true):
				_whirl_jumps_left -= 1
				_player.note_skill("flicker")
			else:
				_whirl_jumps_left = 0
		return
	_whirl_jumps_left = 0
	if whirling or not _player.is_skill_held("flicker") or _flicker_timer > 0.0:
		return
	if _player.is_dashing() or _player.is_charging_fireball() or _player.is_chopping():
		return
	var cost := Skills.FLICKER_MANA * (1.0 + _player.skills.tree_bonus("melee", "flicker_mana"))
	if _player.mana < cost:
		_player._hint("Za mało many")
		_flicker_timer = 0.3
		return
	if not _jump(Skills.FLICKER_RANGE, level, false):
		_player._hint("Brak wrogów w zasięgu")
		_flicker_timer = 0.3
		return
	_player.spend_mana(cost)
	_player.note_skill("flicker")
	_flicker_timer = Skills.FLICKER_INTERVAL / _player._skill_speed()


## Skok do najbliższego widocznego wroga (innego niż poprzedni, jeśli jest wybór) i cięcie wokół niego.
func _jump(reach: float, level: int, spinning: bool) -> bool:
	var origin := _player.body_center()
	var space := _player.get_world_2d().direct_space_state
	var best: Goblin = null
	var best_d := INF
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		var d := enemy.global_position.distance_to(_player.global_position)
		if d > reach:
			continue
		if enemy == _last_target and is_instance_valid(_last_target):
			d += reach  # poprzedni cel tylko wtedy, gdy nie ma innego
		var ray := PhysicsRayQueryParameters2D.create(origin, enemy.hurt_center(), 1)
		if not space.intersect_ray(ray).is_empty():
			continue
		if d < best_d:
			best_d = d
			best = enemy
	if best == null:
		return false
	var spot := _landing_spot(best)
	if not spot.is_finite():
		return false
	var from := _player.global_position
	_player._spawn_ghost()
	_player.global_position = spot
	_player.reset_physics_interpolation()
	_player._invulnerable_timer = maxf(_player._invulnerable_timer, 0.15)
	_last_target = best
	var to_target := best.hurt_center() - _player.body_center()
	_player._face_direction(to_target)
	SkillEffects.bolt(_player.get_parent(), from + Player.BODY_OFFSET, _player.body_center(), 0.18, 3.0)
	SkillEffects.crescent(_player.get_parent(), _player.body_center(), to_target.angle(), PI * 0.45, FLICKER_HIT_RADIUS + 6.0)
	Sfx.play("dash" if spinning else "swing", 0.0, 1.2)
	var multiplier := Skills.flicker_damage(level)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(best.hurt_center()) <= FLICKER_HIT_RADIUS + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier), _player.global_position, 90.0)
	SkillEffects.spark(_player.get_parent(), best.hurt_center(), FLICKER_COLOR, 6)
	return true


## Wolne miejsce obok celu: najpierw z tej strony, z której przychodzimy, potem dookoła.
func _landing_spot(target: Goblin) -> Vector2:
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	var space := _player.get_world_2d().direct_space_state
	var back := (_player.global_position - target.global_position).normalized()
	if back == Vector2.ZERO:
		back = Vector2.LEFT
	var distance := target.hurt_radius + 12.0
	for turn in [0.0, 0.8, -0.8, 1.6, -1.6, PI]:
		var spot: Vector2 = target.global_position + back.rotated(turn) * distance
		query.transform = Transform2D(0.0, spot)
		if space.intersect_shape(query, 1).is_empty():
			var ray := PhysicsRayQueryParameters2D.create(target.global_position, spot, 1)
			if space.intersect_ray(ray).is_empty():
				return spot
	return Vector2.INF


# ---------------------------------------------------------------- Dymne Wybuchy
func _press_smoke() -> void:
	if _smoke_charge >= 0.0:
		return
	if not _player.spend_mana(Skills.SMOKE_MANA):
		_player._hint("Za mało many")
		return
	if _player.combo_with("smoke_burst"):
		_fire_smoke(3, true)
		return
	_smoke_charge = 0.0
	_smoke_stage = 0
	_smoke_swirl = CPUParticles2D.new()
	_smoke_swirl.position = Player.BODY_OFFSET
	_smoke_swirl.amount = 14
	_smoke_swirl.lifetime = 0.6
	_smoke_swirl.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_smoke_swirl.emission_sphere_radius = 14.0
	_smoke_swirl.gravity = Vector2(0, -10)
	_smoke_swirl.radial_accel_min = -40.0
	_smoke_swirl.radial_accel_max = -30.0
	_smoke_swirl.scale_amount_min = 2.0
	_smoke_swirl.scale_amount_max = 4.0
	_smoke_swirl.color_ramp = _smoke_ramp(0.6)
	_player.add_child(_smoke_swirl)
	Sfx.play("magic", -4.0, 0.7)


## Czas ładowania jednego rzędu: szybszy z szybkością ataku i rzucania oraz z węzłem drzewka.
func _smoke_row_time() -> float:
	return Skills.SMOKE_CHARGE_TIME / (_player.stats.skill_speed(SMOKE_TAGS) * (1.0 + _player.skills.tree_bonus("melee", "smoke_charge")))


func _process_smoke(delta: float) -> void:
	if _smoke_charge < 0.0:
		return
	if _player.is_dashing() or _player.stats.weapon_type() != "melee":
		_stop_smoke_charge()
		return
	var aim := _player._aim_direction()
	_player._ranged_pose(aim)
	if _player.is_skill_held("smoke_burst"):
		_smoke_charge += delta
		var stage := mini(int(_smoke_charge / _smoke_row_time()), 2)
		if stage > _smoke_stage:
			_smoke_stage = stage
			Sfx.play("magic", -2.0, 0.8 + 0.2 * stage)
			SkillEffects.spark(_player.get_parent(), _player.body_center(), SMOKE_COLOR, 6 + 4 * stage)
			if _smoke_swirl != null:
				_smoke_swirl.amount = 14 + 8 * stage
		return
	var rows := 1 + _smoke_stage
	_stop_smoke_charge()
	_fire_smoke(rows, false)


func _stop_smoke_charge() -> void:
	_smoke_charge = -1.0
	_smoke_stage = 0
	if _smoke_swirl != null:
		_smoke_swirl.queue_free()
		_smoke_swirl = null


## Odpala `rows` rzędów po 3 wybuchy w stożku przed postacią (kolejne rzędy dalej, większe i mocniejsze).
func _fire_smoke(rows: int, combo: bool) -> void:
	var aim := _player._aim_direction()
	var origin := _player.global_position
	var level := _player.skills.level_of("smoke_burst")
	_player._ranged_pose(aim)
	_player.note_skill("smoke_burst")
	if combo:
		SkillEffects.spark(_player.get_parent(), _player.body_center(), Color(1.0, 0.9, 0.6), 12)
	for ring in rows:
		var spread := deg_to_rad(Skills.SMOKE_SPREAD_DEGREES[ring])
		for k in 3:
			var at := origin + aim.rotated((k - 1) * spread) * Skills.SMOKE_DISTANCE[ring]
			var timer := _player.get_tree().create_timer(ring * SMOKE_RING_DELAY + k * 0.02, false)
			timer.timeout.connect(_burst.bind(at, Skills.SMOKE_RADIUS[ring], Skills.smoke_damage(level, ring)))


func _burst(at: Vector2, radius: float, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	var parent := _player.get_parent()
	SkillEffects.shockwave(parent, at, radius, SMOKE_COLOR)
	var puff := CPUParticles2D.new()
	puff.position = at + Vector2(0, -6)
	puff.one_shot = true
	puff.explosiveness = 0.85
	puff.amount = 30
	puff.lifetime = 1.3
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = radius * 0.4
	puff.direction = Vector2.UP
	puff.spread = 180.0
	puff.initial_velocity_min = 10.0
	puff.initial_velocity_max = radius * 1.4
	puff.damping_min = 30.0
	puff.damping_max = 50.0
	puff.gravity = Vector2(0, -14)
	puff.scale_amount_min = 4.0
	puff.scale_amount_max = 9.0
	puff.color_ramp = _smoke_ramp(1.0)
	puff.emitting = true
	parent.add_child(puff)
	puff.finished.connect(puff.queue_free)
	Sfx.play_at("explosion", at, -12.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(at + Vector2(0, -6)) <= radius + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier, SMOKE_TAGS), at, 110.0)


static func _smoke_ramp(alpha: float) -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.92, 0.92, 0.95, alpha), Color(0.62, 0.62, 0.68, alpha * 0.85),
			Color(0.42, 0.42, 0.48, alpha * 0.5), Color(0.35, 0.35, 0.4, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	return ramp
