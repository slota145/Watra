class_name SwordSkills
extends Node
## Umiejętności drzewka miecza (SkillTree "melee") z własną obsługą - dziecko gracza, jak LegendaryEffects:
## - Mgnienie: dopóki trzymasz klawisz, postać przeskakuje na wylot przez najbliższego widocznego wroga (za każdym razem
##   innego, jeśli jest wybór) i tnie wszystkich na drodze (mana za każdy skok); jednego wroga przebija tam i z powrotem.
##   Combo z Młynkiem: Mgnienie w trakcie Młynka to wirujące Mgnienie - seria szybkich skoków od wroga do wroga
##   z odnowieniem; węzeł kluczowy Nieustający Wir znosi odnowienie (skoki trwają, dopóki trzymasz klawisz).
## - Dymne Wybuchy: przytrzymanie ładuje (1-3 rzędy po 3 wybuchy dymu w stożku przed postacią), puszczenie odpala.
##   Combo: zaraz po innej umiejętności wszystkie 9 wybuchów od razu, bez ładowania. Atak i czar jednocześnie.
## - Rozpłatanie: szerokie cięcie z krwawieniem (po Mgnieniu podwójnym).
## - Rozłupanie Ziemi: fala pęknięć przed postacią, rani i ogłusza (po Półksiężycu - pierścień dookoła).
## - Riposta: krótka zasłona; cios w tym czasie nie rani, a postać kontratakuje wszystkich wokół (potem darmowa Szarża).
## - Zew Peruna: okrzyk - premia do obrażeń, strach wrogów wokół i 3 kolejne ciosy krytyczne.
## - Widmowe Ostrza (czar): krążące miecze raniące wrogów (po Młynku od razu wylatują we wrogów).
## Węzły kluczowe: Nieustający Wir (wirujące Mgnienie bez odnowienia - albo Amulet Wiecznego Wiru), Taniec Ostrzy
## (combo przyspiesza ataki), Dym i Cień (chmura po Dymnych Wybuchach: unik i darmowe Mgnienie), Krwawy Szał
## (krwawienie leczy). Chwilowe premie trafiają do CharacterStats.temp_bonus i na listę efektów (statuses).

const SMOKE_TAGS := ["attack", "spell"]
const SMOKE_COLOR := Color(0.78, 0.78, 0.82)
## Odstęp między rzędami wybuchów (s) i promień cięcia po skoku Mgnienia.
const SMOKE_RING_DELAY := 0.12
const FLICKER_HIT_RADIUS := 30.0
## Mgnienie na wylot: jak daleko za celem ląduje postać i jak szeroki jest pas cięcia wzdłuż drogi skoku.
const FLICKER_OVERSHOOT := 18.0
const FLICKER_PATH_WIDTH := 12.0
## Efekty Mgnienia z kreatora efektów PixelLab (tools/vfx_art.py): smuga za postacią (błysk w miejscu startu,
## rysowana w prawo; długość pasa w klatce - FLICKER_TRAIL_LENGTH) i proste cięcie z błyskiem na trafionym celu.
const FLICKER_TRAIL := preload("res://assets/effects/flicker_trail.png")
const FLICKER_TRAIL_ANCHOR := Vector2(8, 10)
const FLICKER_TRAIL_LENGTH := 62.0
const FLICKER_SLASH := preload("res://assets/effects/flicker_hit.png")
const FLICKER_SLASH_ANCHOR := Vector2(43, 16)
## Cięcie na celu ukośnie do drogi skoku (losowo w jedną lub drugą stronę), żeby nie zlewało się ze smugą.
const FLICKER_SLASH_TILT := 0.6
const BLOOD_COLOR := Color(0.8, 0.1, 0.1)
const SPECTRAL_COLOR := Color(0.65, 0.85, 1.0)
const PERUN_COLOR := Color(1.0, 0.85, 0.35)
## Taniec Ostrzy: premia za combo, ile razy się kumuluje i jak długo trwa; Dym i Cień: chmura; Krwawy Szał: leczenie.
const DANCE_STEP := 0.05
const DANCE_STACKS := 5
const DANCE_TIME := 4.0
const CLOUD_TIME := 5.0
const CLOUD_RADIUS := 70.0
const CLOUD_DODGE := 0.3
const FRENZY_LEECH := 0.3
const ICONS := {
	"war_cry": preload("res://assets/skills/war_cry.png"), "blade_dance": preload("res://assets/skills/ks_blade_dance.png"),
	"smoke_shadow": preload("res://assets/skills/ks_smoke_shadow.png"), "riposte": preload("res://assets/skills/riposte.png"),
}

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
## odnowienia umiejętności: id -> [zostało, całość]
var _cooldowns := {}
var _parry_time := 0.0
var _parry_ring: Node2D
var _cry_time := 0.0
var _forced_crits := 0
var _dance_stacks := 0
var _dance_time := 0.0
## Chmura Dymu i Cienia: środek i ile jeszcze trwa.
var _cloud_at := Vector2.ZERO
var _cloud_time := 0.0
var _cloud_node: CPUParticles2D
var _blades: SpectralBlades


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
		_:
			if _cooldowns.get(id, [0.0])[0] > 0.0:
				return
			var cost := Skills.mana_cost(id)
			if not _player.spend_mana(cost):
				_player._hint("Za mało many")
				return
			match id:
				"rend":
					_rend()
				"ground_slam":
					_ground_slam()
				"riposte":
					_riposte()
				"war_cry":
					_war_cry()
				"spectral_blades":
					_spectral_blades()


## Przerwanie (śmierć, zmiana broni).
func cancel() -> void:
	_whirl_jumps_left = 0
	_stop_smoke_charge()
	_parry_time = 0.0


func cooldown_of(id: String) -> Vector2:
	if id == "flicker":
		# odnowienie ma tylko wirujące Mgnienie - poza Młynkiem zwykłe Mgnienie jest gotowe (sama mana)
		if not _player.is_whirling():
			return Vector2.ZERO
		return Vector2(_whirl_cooldown, maxf(_whirl_cooldown_total, _whirl_cooldown))
	var entry: Array = _cooldowns.get(id, [0.0, 0.0])
	return Vector2(entry[0], maxf(entry[1], entry[0]))


func _start_cooldown(id: String, base: float) -> void:
	var time: float = _player._cooldown(base, Skills.tags(id))
	_cooldowns[id] = [time, time]


func _physics_process(delta: float) -> void:
	_whirl_cooldown = maxf(_whirl_cooldown - delta, 0.0)
	for id: String in _cooldowns:
		_cooldowns[id][0] = maxf(_cooldowns[id][0] - delta, 0.0)
	_process_timed(delta)
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
	return _player.skills.has_keystone("melee", "endless_whirl") or _player.equipment.effect_power("endless_whirl") > 0.0


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
				_player.combo_used()
			else:
				_whirl_jumps_left = 0
		return
	_whirl_jumps_left = 0
	if whirling or not _player.is_skill_held("flicker") or _flicker_timer > 0.0:
		return
	if _player.is_dashing() or _player.is_charging_fireball() or _player.is_chopping():
		return
	var cost := Skills.FLICKER_MANA * (1.0 + _player.skills.tree_bonus("melee", "flicker_mana"))
	if _in_cloud():
		cost = 0.0
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


## Skok na wylot przez najbliższego widocznego wroga (innego niż poprzedni, jeśli jest wybór): postać ląduje za nim
## i rani wszystkich na swojej drodze i wokół celu - przy jednym wrogu przebija go tam i z powrotem.
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
	var travel := spot - from
	_player._face_direction(travel)
	var trail_from := from + Player.BODY_OFFSET
	var trail := _player.body_center() - trail_from
	SkillEffects.sheet_once(_player.get_parent(), FLICKER_TRAIL, 7, 16.0, trail_from, FLICKER_TRAIL_ANCHOR,
			trail.angle(), maxf(0.5, (trail.length() - 8.0) / FLICKER_TRAIL_LENGTH))
	SkillEffects.sheet_once(_player.get_parent(), FLICKER_SLASH, 8, 16.0, best.hurt_center(), FLICKER_SLASH_ANCHOR,
			travel.angle() + FLICKER_SLASH_TILT * (1.0 if randf() < 0.5 else -1.0))
	Sfx.play("dash" if spinning else "swing", 0.0, 1.2)
	var multiplier := Skills.flicker_damage(level) * (1.0 + _player.skills.tree_bonus("melee", "flicker_damage")
			+ _player.equipment.effect_power("endless_whirl"))
	# cięcie wokół celu i wzdłuż drogi skoku (odrzut od postaci, która już stoi za celem)
	var path_from := from + Player.BODY_OFFSET
	var path_to := _player.body_center()
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		var center := enemy.hurt_center()
		var on_path := Geometry2D.get_closest_point_to_segment(center, path_from, path_to).distance_to(center) <= FLICKER_PATH_WIDTH + enemy.hurt_radius
		if on_path or center.distance_to(best.hurt_center()) <= FLICKER_HIT_RADIUS + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier), _player.global_position, 90.0)
	return true


## Wolne miejsce za celem (na wylot): najpierw dokładnie na przedłużeniu skoku, potem coraz bardziej z boku,
## a na końcu - gdy za celem ściana - od strony, z której przychodzimy.
func _landing_spot(target: Goblin) -> Vector2:
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	var space := _player.get_world_2d().direct_space_state
	var through := (target.global_position - _player.global_position).normalized()
	if through == Vector2.ZERO:
		through = _player.facing_dir
	var distance := target.hurt_radius + FLICKER_OVERSHOOT
	for turn in [0.0, 0.5, -0.5, 1.0, -1.0, 1.6, -1.6, PI]:
		var spot: Vector2 = target.global_position + through.rotated(turn) * distance
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
		_player.combo_used()
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
	if _player.skills.has_keystone("melee", "smoke_shadow"):
		_start_cloud(origin + aim * Skills.SMOKE_DISTANCE[rows - 1] * 0.6)
	if combo:
		SkillEffects.spark(_player.get_parent(), _player.body_center(), Color(1.0, 0.9, 0.6), 12)
	for ring in rows:
		var spread := deg_to_rad(Skills.SMOKE_SPREAD_DEGREES[ring])
		for k in 3:
			var at := origin + aim.rotated((k - 1) * spread) * Skills.SMOKE_DISTANCE[ring]
			var timer := _player.get_tree().create_timer(ring * SMOKE_RING_DELAY + k * 0.02, false)
			var bonus := (1.0 + _player.skills.tree_bonus("melee", "smoke_damage")) * (_player.combo_damage() if combo else 1.0)
			timer.timeout.connect(_burst.bind(at, Skills.SMOKE_RADIUS[ring] * _player.stats.area_multiplier(), Skills.smoke_damage(level, ring) * bonus))


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


# ---------------------------------------------------------------- Rozpłatanie i krwawienie
func _rend() -> void:
	var level := _player.skills.level_of("rend")
	var aim := _player._aim_direction()
	var combo := _player.combo_with("rend")
	if combo:
		_player.combo_used()
	_player._ranged_pose(aim)
	_player.note_skill("rend")
	var origin := _player.body_center()
	var half := deg_to_rad(Skills.REND_ARC_DEGREES) / 2.0
	SkillEffects.crescent(_player.get_parent(), origin, aim.angle(), half, Skills.REND_REACH)
	Sfx.play("big_slash", 0.0, 1.1)
	var bleed := Skills.rend_bleed(level) * (2.0 if combo else 1.0) * (_player.combo_damage() if combo else 1.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > Skills.REND_REACH + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(aim.angle(), to_enemy.angle())) > half:
			continue
		_player.hit_enemy(enemy, _player._skill_damage(Skills.rend_damage(level)), _player.global_position, 80.0)
		bleed_enemy(enemy, bleed)


## Krwawienie: `multiplier` obrażeń broni rozłożone na BLEED_TICKS ran co pół sekundy (więcej z węzłów drzewka).
## Z Krwawym Szałem rany leczą gracza.
func bleed_enemy(enemy: Goblin, multiplier: float) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
		return
	var total := _player._skill_damage(multiplier * (1.0 + _player.skills.tree_bonus("melee", "bleed_damage")))
	var per_tick := maxi(1, roundi(float(total) / Skills.BLEED_TICKS))
	var frenzy := _player.skills.has_keystone("melee", "blood_frenzy")
	SkillEffects.spark(_player.get_parent(), enemy.hurt_center(), BLOOD_COLOR, 6)
	for i in Skills.BLEED_TICKS:
		_player.get_tree().create_timer(0.5 * (i + 1), false).timeout.connect(func() -> void:
			if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
				enemy.take_damage(per_tick, enemy.global_position, 0.0)
				SkillEffects.spark(enemy.get_parent(), enemy.hurt_center(), Color(0.7, 0.05, 0.05), 2)
				if frenzy and is_instance_valid(_player) and not _player.is_dead:
					_player.heal(per_tick * FRENZY_LEECH))


# ---------------------------------------------------------------- Rozłupanie Ziemi
func _ground_slam() -> void:
	var level := _player.skills.level_of("ground_slam")
	_start_cooldown("ground_slam", Skills.SLAM_COOLDOWN)
	var aim := _player._aim_direction()
	var combo := _player.combo_with("ground_slam")
	if combo:
		_player.combo_used()
	_player._ranged_pose(aim)
	_player.note_skill("ground_slam")
	_player.add_shake(4.0)
	Sfx.play("explosion", -4.0, 0.7)
	var origin := _player.global_position
	var damage := Skills.slam_damage(level) * (_player.combo_damage() if combo else 1.0)
	var stun := Skills.slam_stun(level) * (1.0 + _player.skills.tree_bonus("melee", "slam_stun"))
	var layer := _player.get_tree().get_first_node_in_group("floor_layer")
	var parent: Node = layer if layer != null else _player.get_parent()
	var hit := {}
	if combo:
		SkillEffects.shockwave(_player.get_parent(), origin, Skills.SLAM_RING, Color(0.75, 0.6, 0.4))
		SkillEffects.ground_crack(parent, origin, Skills.SLAM_RING * 0.7, 2.0)
		for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(origin) <= Skills.SLAM_RING + enemy.hurt_radius:
				_slam_hit(enemy, damage, stun, origin)
		return
	# fala pęknięć biegnie przed postacią
	var steps := 6
	for i in steps:
		var at := origin + aim * (20.0 + (Skills.SLAM_LENGTH - 20.0) * i / (steps - 1))
		_player.get_tree().create_timer(i * 0.05, false).timeout.connect(func() -> void:
			if not is_instance_valid(_player):
				return
			SkillEffects.ground_crack(parent, at, Skills.SLAM_WIDTH, 1.6)
			SkillEffects.spark(_player.get_parent(), at, Color(0.7, 0.55, 0.35), 5)
			for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
				if not hit.has(enemy) and enemy.global_position.distance_to(at) <= Skills.SLAM_WIDTH + enemy.hurt_radius:
					hit[enemy] = true
					_slam_hit(enemy, damage, stun, origin))


func _slam_hit(enemy: Goblin, damage: float, stun: float, from: Vector2) -> void:
	_player.hit_enemy(enemy, _player._skill_damage(damage), from, 60.0)
	if enemy.state != Goblin.State.DEAD:
		enemy.stun(stun)


# ---------------------------------------------------------------- Riposta
func _riposte() -> void:
	_start_cooldown("riposte", Skills.RIPOSTE_COOLDOWN)
	_parry_time = Skills.RIPOSTE_TIME
	_player._ranged_pose(_player._aim_direction())
	Sfx.play("swing", 0.0, 0.8)
	if _parry_ring == null:
		_parry_ring = _ParryRing.new()
		_player.add_child(_parry_ring)
		_parry_ring.position = Player.BODY_OFFSET
	_parry_ring.visible = true


## Wołane przez gracza przy otrzymaniu ciosu: w czasie zasłony cios nie rani, a postać kontratakuje.
func try_parry(from: Vector2) -> bool:
	if _parry_time <= 0.0:
		return false
	_parry_time = 0.0
	if _parry_ring != null:
		_parry_ring.visible = false
	var level := _player.skills.level_of("riposte")
	var damage := Skills.riposte_damage(level) * (1.0 + _player.skills.tree_bonus("melee", "riposte_damage"))
	var origin := _player.body_center()
	_player._invulnerable_timer = maxf(_player._invulnerable_timer, 0.4)
	_player._face_direction(from - _player.global_position)
	SkillEffects.crescent(_player.get_parent(), origin, (from - _player.global_position).angle(), PI * 0.9, Skills.RIPOSTE_RADIUS)
	SkillEffects.spark(_player.get_parent(), origin, Color(1.0, 0.95, 0.7), 14)
	DamageNumber.spawn_text(_player.get_parent(), origin + Vector2(0, -14), "Riposta!", Color(1.0, 0.9, 0.5), 9)
	Sfx.play("hit_heavy", 2.0, 1.2)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(origin) <= Skills.RIPOSTE_RADIUS + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(damage), _player.global_position, 160.0)
			if enemy.state != Goblin.State.DEAD:
				enemy.stun(0.5)
	# po udanej Ripoście Szarża jest darmowa (Skills.COMBOS)
	_player.note_skill("riposte")
	return true


# ---------------------------------------------------------------- Zew Peruna
func _war_cry() -> void:
	var level := _player.skills.level_of("war_cry")
	_start_cooldown("war_cry", Skills.CRY_COOLDOWN)
	_cry_time = Skills.CRY_TIME
	_forced_crits = Skills.CRY_CRITS
	_player.note_skill("war_cry")
	var origin := _player.global_position
	SkillEffects.shockwave(_player.get_parent(), origin, Skills.CRY_RADIUS, PERUN_COLOR)
	SkillEffects.bolt(_player.get_parent(), origin + Vector2(randf_range(-20, 20), -120), _player.body_center(), 0.3, 8.0)
	Sfx.play("thunder", -2.0)
	_player.add_shake(3.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(origin) <= Skills.CRY_RADIUS:
			enemy.fear(Skills.CRY_FEAR, origin)
	_update_temp_bonus()


## Wołane przy trafieniu: po Zewie Peruna kolejne ciosy są krytyczne.
func take_forced_crit() -> bool:
	if _forced_crits <= 0:
		return false
	_forced_crits -= 1
	return true


# ---------------------------------------------------------------- Widmowe Ostrza
func _spectral_blades() -> void:
	var level := _player.skills.level_of("spectral_blades")
	_start_cooldown("spectral_blades", Skills.BLADES_COOLDOWN)
	var combo := _player.combo_with("spectral_blades")
	if combo:
		_player.combo_used()
	_player.note_skill("spectral_blades")
	if is_instance_valid(_blades):
		_blades.queue_free()
	_blades = SpectralBlades.new()
	_blades.player = _player
	_blades.count = Skills.BLADES_COUNT + roundi(_player.skills.tree_bonus("melee", "blade_count"))
	_blades.damage = Skills.blades_damage(level) * (_player.combo_damage() if combo else 1.0)
	_blades.time_left = Skills.BLADES_TIME
	_player.get_parent().add_child(_blades)
	Sfx.play("magic", 0.0, 1.3)
	if combo:
		_blades.launch()


# ---------------------------------------------------------------- premie czasowe i węzły kluczowe
## Wykonane combo: Taniec Ostrzy dokłada ładunek szybkości ataku.
func on_combo() -> void:
	if not _player.skills.has_keystone("melee", "blade_dance"):
		return
	_dance_stacks = mini(_dance_stacks + 1, DANCE_STACKS)
	_dance_time = DANCE_TIME
	_update_temp_bonus()


func _start_cloud(at: Vector2) -> void:
	_cloud_at = at
	_cloud_time = CLOUD_TIME
	if is_instance_valid(_cloud_node):
		_cloud_node.queue_free()
	_cloud_node = CPUParticles2D.new()
	_cloud_node.position = at
	_cloud_node.amount = 40
	_cloud_node.lifetime = 1.6
	_cloud_node.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_cloud_node.emission_sphere_radius = CLOUD_RADIUS * 0.7
	_cloud_node.gravity = Vector2(0, -6)
	_cloud_node.initial_velocity_max = 8.0
	_cloud_node.scale_amount_min = 5.0
	_cloud_node.scale_amount_max = 10.0
	_cloud_node.color_ramp = _smoke_ramp(0.45)
	_player.get_parent().add_child(_cloud_node)
	_update_temp_bonus()


func _in_cloud() -> bool:
	return _cloud_time > 0.0 and _player.global_position.distance_to(_cloud_at) <= CLOUD_RADIUS


func _process_timed(delta: float) -> void:
	var before := [_cry_time > 0.0, _dance_stacks, _in_cloud()]
	if _parry_time > 0.0:
		_parry_time -= delta
		if _parry_time <= 0.0 and _parry_ring != null:
			_parry_ring.visible = false
	_cry_time = maxf(_cry_time - delta, 0.0)
	_dance_time = maxf(_dance_time - delta, 0.0)
	if _dance_time <= 0.0:
		_dance_stacks = 0
	if _cloud_time > 0.0:
		_cloud_time -= delta
		if _cloud_time <= 0.0 and is_instance_valid(_cloud_node):
			_cloud_node.emitting = false
			_player.get_tree().create_timer(1.6).timeout.connect(_cloud_node.queue_free)
	if before != [_cry_time > 0.0, _dance_stacks, _in_cloud()]:
		_update_temp_bonus()


## Chwilowe premie do statystyk postaci: Zew Peruna (obrażenia), Taniec Ostrzy (szybkość ataku), chmura (unik).
func _update_temp_bonus() -> void:
	var bonus := {}
	if _cry_time > 0.0:
		bonus["damage_percent"] = Skills.cry_bonus(_player.skills.level_of("war_cry")) + _player.skills.tree_bonus("melee", "cry_power")
	if _dance_stacks > 0:
		bonus["attack_speed"] = DANCE_STEP * _dance_stacks
	if _in_cloud():
		bonus["dodge_chance"] = CLOUD_DODGE
	_player.stats.set_temp("sword", bonus)


## Efekty do rzędu ikon pod paskami zdrowia i many (jak LegendaryEffects.statuses).
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _cry_time > 0.0:
		result.append({"name": "Zew Peruna", "kind": "good", "left": _cry_time, "total": Skills.CRY_TIME, "icon": ICONS["war_cry"],
				"stacks": _forced_crits, "description": "+%d%% zadawanych obrażeń; ciosy krytyczne w zapasie: %d" % [
					roundi(_player.stats.temp_bonus.get("damage_percent", 0.0) * 100.0), _forced_crits]})
	if _dance_stacks > 0:
		result.append({"name": "Taniec Ostrzy", "kind": "good", "left": _dance_time, "total": DANCE_TIME, "icon": ICONS["blade_dance"],
				"stacks": _dance_stacks, "description": "+%d%% szybkości ataku (każde combo dokłada)" % roundi(DANCE_STEP * _dance_stacks * 100.0)})
	if _in_cloud():
		result.append({"name": "Dym i Cień", "kind": "good", "left": _cloud_time, "total": CLOUD_TIME, "icon": ICONS["smoke_shadow"],
				"description": "+%d%% szansy na unik, Mgnienie nie zużywa many" % roundi(CLOUD_DODGE * 100.0)})
	if _parry_time > 0.0:
		result.append({"name": "Riposta", "kind": "good", "left": _parry_time, "total": Skills.RIPOSTE_TIME, "icon": ICONS["riposte"],
				"description": "Zasłona: następny cios nie zrani, a ty kontratakujesz"})
	return result


## Złoty pierścień wokół postaci w czasie zasłony Riposty.
class _ParryRing:
	extends Node2D

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 60.0)
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.5, pulse), 1.5)
