class_name BowSkills
extends Node
## Umiejętności drzewka łuku (SkillTree "bow") z własną obsługą - dziecko gracza, jak SwordSkills:
## - Grot Swaroga: przytrzymanie napina łuk, puszczenie wypuszcza płonącą strzałę przebijającą wrogów (mocniejsza
##   z napięciem). Combo po Strzale tropiącej: grot wybucha ogniem przy każdym trafieniu.
## - Deszcz Strzał: krąg pod kursorem, na który przez chwilę spadają strzały (po Salwie - dwa razy gęściej).
## - Odskok: skok do tyłu i trzy strzały w locie; potem Salwa jest darmowa i ma 5 strzał (Player._process_skill).
## - Sidła: pułapki pod kursorem - wróg, który wejdzie, zostaje unieruchomiony z sąsiadami; trafienia unieruchomionych
##   są krytyczne.
## - Sokół: przywołany ptak krąży nad graczem i spada na wrogów (po Strzale tropiącej od razu nurkuje z potrójną siłą).
## - Jadowe Groty: przez chwilę trafienia zatruwają (po Sidłach jad przeskakuje na wrogów obok).
## - Strzała Wichru: podmuch w stożku rani i odrzuca (po Odskoku - dwa razy szerszy). Atak i czar.
## - Balista: wieżyczka pod kursorem strzelająca w najbliższych wrogów; legendarne przedmioty zmieniają jej strzały
##   w salwę (ballista_volley) albo w strzały tropiące (ballista_seeker).
## Węzły kluczowe: Oko Sokoła (dalekie trafienia krytyczne, bliskie słabsze), Grad (więcej strzał Salwy i Deszczu,
## słabszych), Myśliwy z Cienia (po Odskoku wrogowie tracą gracza z oczu, pierwsze trafienie podwójne), Strzelanie
## w biegu (bez spowolnienia przy strzale, szybciej w biegu). Trafienia z łukiem w ręku przechodzą przez
## damage_factor / forced_crit / on_hit (Player.hit_enemy).

const FIRE_COLOR := Color(1.0, 0.6, 0.2)
const VENOM_COLOR := Color(0.5, 0.95, 0.3)
const WIND_COLOR := Color(0.8, 0.95, 1.0)
## Oko Sokoła: od jakiej odległości trafienia są krytyczne, do jakiej słabsze i o ile.
const FALCON_EYE_FAR := 150.0
const FALCON_EYE_NEAR := 70.0
const FALCON_EYE_WEAK := 0.7
## Grad: mniej obrażeń na strzałę, dodatkowe strzały Salwy, gęstszy Deszcz.
const HAIL_DAMAGE := 0.8
const HAIL_ARROWS := 2
const HAIL_DENSITY := 1.5
## Myśliwy z Cienia: ile wrogowie nie widzą gracza; Strzelanie w biegu: premia do szybkości ataku.
const SHADOW_TIME := 2.0
const RUN_SPEED := 0.15
## Trucizna Jadowych Grotów: ile trwa i co ile rani.
const POISON_TIME := 3.0
const POISON_TICK := 0.5
const SNARE_OPEN := preload("res://assets/bow/snare_open.png")
const SNARE_CLOSED := preload("res://assets/bow/snare_closed.png")
const FALCON_TEXTURE := preload("res://assets/bow/falcon.png")
const BALLISTA_TEXTURE := preload("res://assets/bow/ballista.png")
const ICONS := {
	"venom_arrows": preload("res://assets/skills/venom_arrows.png"), "falcon": preload("res://assets/skills/falcon.png"),
	"ballista": preload("res://assets/skills/ballista.png"), "shadow_hunter": preload("res://assets/skills/ks_shadow_hunter.png"),
	"running_fire": preload("res://assets/skills/ks_running_fire.png"),
}

var _player: Player
## odnowienia umiejętności: id -> [zostało, całość]
var _cooldowns := {}
## Napinanie Grotu Swaroga: postęp 0..1 (-1 - nie napinamy) i żar na grocie.
var _power_charge := -1.0
var _power_glow: CPUParticles2D
var _venom_time := 0.0
var _venom_spread := false
## Zatruci wrogowie: wróg -> [obrażenia na ranę, zostało sekund, do kolejnej rany]
var _poisoned := {}
var _snares: Array[Node2D] = []
var _falcon: _Falcon
var _ballista: _Ballista
var _shadow_time := 0.0
var _shadow_shot := false
var _running := false


func _init(player: Player) -> void:
	_player = player


## Naciśnięty slot umiejętności (trzymanie sprawdza Player.is_skill_held).
func press(id: String) -> void:
	if _player.skills.level_of(id) <= 0:
		_player._hint("Wybierz %s w drzewku umiejętności (K)" % Skills.get_data(id)["name"])
		return
	if _cooldowns.get(id, [0.0])[0] > 0.0 or _power_charge >= 0.0 or _player.is_dashing():
		return
	if not _player.spend_mana(Skills.mana_cost(id)):
		_player._hint("Za mało many")
		return
	match id:
		"power_shot":
			_start_power()
		"arrow_rain":
			_arrow_rain()
		"vault":
			_vault()
		"snare":
			_snare()
		"falcon":
			_summon_falcon()
		"venom_arrows":
			_venom_arrows()
		"wind_arrow":
			_wind_arrow()
		"ballista":
			_place_ballista()


## Przerwanie (śmierć, zmiana broni).
func cancel() -> void:
	_stop_power()


func cooldown_of(id: String) -> Vector2:
	var entry: Array = _cooldowns.get(id, [0.0, 0.0])
	return Vector2(entry[0], maxf(entry[1], entry[0]))


func _start_cooldown(id: String, base: float) -> void:
	var time: float = _player._cooldown(base, Skills.tags(id))
	_cooldowns[id] = [time, time]


func _level(id: String) -> int:
	return _player.skills.level_of(id)


func _bonus(stat: String) -> float:
	return _player.skills.tree_bonus("bow", stat)


func has_keystone(id: String) -> bool:
	return _player.skills.has_keystone("bow", id) and _player.stats.weapon_type() == "bow"


## Punkt pod kursorem (tester-bot i testy celują przez Player.aim_override - wektor od środka postaci).
func _cursor() -> Vector2:
	if _player.aim_override != Vector2.ZERO:
		return _player.body_center() + _player.aim_override
	return _player.get_global_mouse_position()


## Punkt pod kursorem, ale nie dalej od gracza niż `reach`.
func _aim_point(reach: float) -> Vector2:
	var origin := _player.global_position
	return origin + (_cursor() - origin).limit_length(reach)


func _physics_process(delta: float) -> void:
	for id: String in _cooldowns:
		_cooldowns[id][0] = maxf(_cooldowns[id][0] - delta, 0.0)
	_venom_time = maxf(_venom_time - delta, 0.0)
	_shadow_time = maxf(_shadow_time - delta, 0.0)
	if _shadow_time <= 0.0:
		_shadow_shot = false
	_process_poison(delta)
	_update_running()
	if _player.is_dead:
		cancel()
		return
	_process_power(delta)


# ---------------------------------------------------------------- Grot Swaroga
func _start_power() -> void:
	_player._cancel_attack()
	_power_charge = 0.0
	if _power_glow == null:
		_power_glow = CPUParticles2D.new()
		_power_glow.amount = 14
		_power_glow.lifetime = 0.4
		_power_glow.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		_power_glow.emission_sphere_radius = 6.0
		_power_glow.gravity = Vector2(0, -30)
		_power_glow.radial_accel_min = -60.0
		_power_glow.radial_accel_max = -30.0
		_power_glow.scale_amount_max = 2.0
		_power_glow.color_ramp = _ramp(FIRE_COLOR)
		_player.add_child(_power_glow)
	_power_glow.emitting = true
	Sfx.play("swing", -4.0, 0.6)


func _process_power(delta: float) -> void:
	if _power_charge < 0.0:
		return
	if _player.stats.weapon_type() != "bow" or _player.is_dashing():
		_stop_power()
		return
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	_power_glow.position = Player.BODY_OFFSET + dir * 12.0
	_power_glow.emission_sphere_radius = 4.0 + 6.0 * _power_charge
	if not _player.is_skill_held("power_shot"):
		var charge := _power_charge
		_stop_power()
		_fire_power(charge)
		return
	var before := _power_charge
	var speed := _player._skill_speed(Skills.tags("power_shot")) * (1.0 + _bonus("power_charge"))
	_power_charge = minf(_power_charge + delta * speed / Skills.POWER_CHARGE_TIME, 1.0)
	if before < 1.0 and _power_charge >= 1.0:
		SkillEffects.spark(_player.get_parent(), _player.body_center() + dir * 12.0, FIRE_COLOR, 10)
		Sfx.play("fireball_full", -6.0, 1.3)


func _stop_power() -> void:
	_power_charge = -1.0
	if _power_glow != null:
		_power_glow.emitting = false


## Ile napięcia Grotu Swaroga (0..1, -1 - nie napinamy) - dla testów i paska.
func power_charge() -> float:
	return _power_charge


func _fire_power(charge: float) -> void:
	var level := _level("power_shot")
	var dir := _player._aim_direction()
	var combo := _player.combo_with("power_shot")
	if combo:
		_player.combo_used()
	_player.note_skill("power_shot")
	_start_cooldown("power_shot", Skills.POWER_COOLDOWN)
	var multiplier := Skills.power_damage(level) * lerpf(1.0, Skills.POWER_FULL_DAMAGE, charge) * (1.0 + _bonus("power_damage")) \
			* (_player.combo_damage() if combo else 1.0)
	var arrow := _player._make_projectile(_player.equipment.weapon(), dir)
	arrow.damage_min = maxi(1, roundi(arrow.damage_min * multiplier))
	arrow.damage_max = maxi(1, roundi(arrow.damage_max * multiplier))
	arrow.pierce += Skills.power_pierce(level)
	arrow.speed = 520.0
	arrow.max_range *= 1.4
	arrow.knockback = 120.0
	arrow.size = lerpf(1.0, 1.5, charge)
	arrow.modulate = Color(1.5, 1.05, 0.6)
	arrow.add_child(_trail(FIRE_COLOR, Projectile.HEIGHT))
	if combo:
		arrow.enemy_hit.connect(func(enemy: Goblin) -> void: _fire_blast(enemy.hurt_center(), multiplier * 0.5))
	_player.get_parent().add_child(arrow)
	Sfx.play("bow", 3.0, lerpf(0.9, 0.7, charge))
	_player.add_shake(1.0 + 2.0 * charge)


func _fire_blast(at: Vector2, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	SkillEffects.shockwave(_player.get_parent(), at, Skills.POWER_EXPLOSION, FIRE_COLOR)
	SkillEffects.spark(_player.get_parent(), at, FIRE_COLOR, 10)
	Sfx.play_at("explosion", at, -8.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(at) <= Skills.POWER_EXPLOSION + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier), at, 60.0)


# ---------------------------------------------------------------- Deszcz Strzał
func _arrow_rain() -> void:
	var level := _level("arrow_rain")
	_start_cooldown("arrow_rain", Skills.RAIN_COOLDOWN)
	var combo := _player.combo_with("arrow_rain")
	if combo:
		_player.combo_used()
	_player.note_skill("arrow_rain")
	var at := _aim_point(Skills.RAIN_RANGE)
	_player._ranged_pose((at - _player.global_position).normalized() if at != _player.global_position else Vector2.UP)
	var hail := has_keystone("hail")
	var rain := _Rain.new()
	rain.player = _player
	rain.position = at
	rain.radius = Skills.RAIN_RADIUS * (1.0 + _bonus("rain_area"))
	rain.tick = Skills.RAIN_TICK / (2.0 if combo else 1.0) / (HAIL_DENSITY if hail else 1.0)
	rain.damage = Skills.rain_damage(level) * (1.0 + _bonus("rain_damage")) * (HAIL_DAMAGE if hail else 1.0) \
			* (_player.combo_damage() if combo else 1.0)
	rain.time_left = Skills.RAIN_TIME
	_player.get_parent().add_child(rain)
	Sfx.play("bow", 0.0, 0.7)


# ---------------------------------------------------------------- Odskok
func _vault() -> void:
	var level := _level("vault")
	_start_cooldown("vault", Skills.VAULT_COOLDOWN * (1.0 + _bonus("vault_cooldown")))
	var dir := _player._aim_direction()
	_player.leap(-dir, Skills.VAULT_TIME)
	_player.note_skill("vault")
	var weapon := _player.equipment.weapon()
	var spread := deg_to_rad(Skills.VAULT_SPREAD_DEGREES)
	var multiplier := Skills.vault_damage(level)
	for i in Skills.VAULT_ARROWS:
		var arrow := _player._make_projectile(weapon, dir.rotated(lerpf(-spread / 2.0, spread / 2.0, float(i) / (Skills.VAULT_ARROWS - 1))))
		arrow.damage_min = maxi(1, roundi(arrow.damage_min * multiplier))
		arrow.damage_max = maxi(1, roundi(arrow.damage_max * multiplier))
		_player.get_parent().add_child(arrow)
	Sfx.play("bow", 0.0, 1.1)
	if has_keystone("shadow_hunter"):
		_shadow_time = SHADOW_TIME
		_shadow_shot = true
		Goblin.hidden_until = Time.get_ticks_msec() + roundi(SHADOW_TIME * 1000.0)
		SkillEffects.spark(_player.get_parent(), _player.body_center(), Color(0.3, 0.3, 0.4), 12)


# ---------------------------------------------------------------- Sidła
func _snare() -> void:
	_start_cooldown("snare", Skills.SNARE_COOLDOWN)
	_player.note_skill("snare")
	_snares = _snares.filter(func(s: Node2D) -> bool: return is_instance_valid(s))
	while _snares.size() >= Skills.SNARE_MAX:
		_snares.pop_front().queue_free()
	var snare := _Snare.new()
	snare.skills = self
	snare.position = _aim_point(Skills.SNARE_RANGE)
	_player.get_parent().add_child(snare)
	_snares.append(snare)
	Sfx.play("swing", -2.0, 1.4)


## Sidła się zatrzasnęły: rani i unieruchamia wrogów wokół.
func spring_snare(at: Vector2) -> void:
	var level := _level("snare")
	var hold := Skills.snare_time(level) * (1.0 + _bonus("snare_time"))
	SkillEffects.spark(_player.get_parent(), at, Color(0.8, 0.8, 0.85), 10)
	Sfx.play_at("hit_heavy", at, -2.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(at) > Skills.SNARE_RADIUS + enemy.hurt_radius:
			continue
		enemy.set_meta("snared_until", Time.get_ticks_msec() + roundi(hold * 1000.0))
		_player.hit_enemy(enemy, _player._skill_damage(Skills.snare_damage(level)), at, 0.0)
		if enemy.state != Goblin.State.DEAD:
			enemy.stun(hold)


static func is_snared(enemy: Goblin) -> bool:
	return Time.get_ticks_msec() < int(enemy.get_meta("snared_until", 0))


# ---------------------------------------------------------------- Sokół
func _summon_falcon() -> void:
	_start_cooldown("falcon", Skills.FALCON_COOLDOWN)
	var combo := _player.combo_with("falcon")
	if combo:
		_player.combo_used()
	_player.note_skill("falcon")
	if is_instance_valid(_falcon):
		_falcon.leave()
	_falcon = _Falcon.new()
	_falcon.player = _player
	_falcon.damage = Skills.falcon_damage(_level("falcon")) * (1.0 + _bonus("falcon_damage"))
	_falcon.time_left = Skills.FALCON_TIME
	_falcon.position = _player.global_position + Vector2(0, -60)
	_player.get_parent().add_child(_falcon)
	if combo:
		_falcon.dive_now(3.0 * _player.combo_damage(), _cursor())
	Sfx.play("swing", 0.0, 1.6)


# ---------------------------------------------------------------- Jadowe Groty
func _venom_arrows() -> void:
	_start_cooldown("venom_arrows", Skills.VENOM_COOLDOWN)
	_venom_spread = _player.combo_with("venom_arrows")
	if _venom_spread:
		_player.combo_used()
	_player.note_skill("venom_arrows")
	_venom_time = Skills.VENOM_TIME
	SkillEffects.spark(_player.get_parent(), _player.body_center(), VENOM_COLOR, 12)
	Sfx.play("potion", -2.0, 0.8)


## Zatrucie wroga: `total` obrażeń rozłożone na POISON_TIME s (nowe zatrucie odświeża i bierze mocniejsze).
func poison(enemy: Goblin, total: float) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
		return
	var per_tick := maxf(total * POISON_TICK / POISON_TIME, 1.0)
	var entry: Array = _poisoned.get(enemy, [0.0, 0.0, POISON_TICK])
	_poisoned[enemy] = [maxf(entry[0], per_tick), POISON_TIME, entry[2]]


func is_poisoned(enemy: Goblin) -> bool:
	return _poisoned.has(enemy)


func _process_poison(delta: float) -> void:
	for enemy: Goblin in _poisoned.keys():
		if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
			_poisoned.erase(enemy)
			continue
		var entry: Array = _poisoned[enemy]
		entry[1] -= delta
		entry[2] -= delta
		if entry[2] <= 0.0:
			entry[2] += POISON_TICK
			enemy.take_damage(roundi(entry[0]), enemy.global_position, 0.0)
			SkillEffects.spark(enemy.get_parent(), enemy.hurt_center(), VENOM_COLOR, 2)
		if entry[1] <= 0.0:
			_poisoned.erase(enemy)


# ---------------------------------------------------------------- Strzała Wichru
func _wind_arrow() -> void:
	_start_cooldown("wind_arrow", Skills.WIND_COOLDOWN)
	var combo := _player.combo_with("wind_arrow")
	if combo:
		_player.combo_used()
	_player.note_skill("wind_arrow")
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	var origin := _player.body_center()
	var half := deg_to_rad(Skills.WIND_HALF_ANGLE) * (2.0 if combo else 1.0)
	SkillEffects.cone(_player.get_parent(), origin, dir.angle(), half, Skills.WIND_RANGE)
	Sfx.play("whirl", 2.0, 1.3)
	var multiplier := Skills.wind_damage(_level("wind_arrow")) * (1.0 + _bonus("wind_damage")) * (_player.combo_damage() if combo else 1.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > Skills.WIND_RANGE + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(dir.angle(), to_enemy.angle())) > half:
			continue
		_player.hit_enemy(enemy, _player._skill_damage(multiplier, Skills.tags("wind_arrow")), _player.global_position, Skills.WIND_KNOCKBACK)
		SkillEffects.spark(_player.get_parent(), enemy.hurt_center(), WIND_COLOR, 4)


# ---------------------------------------------------------------- Balista
func _place_ballista() -> void:
	_start_cooldown("ballista", Skills.BALLISTA_COOLDOWN)
	_player.note_skill("ballista")
	if is_instance_valid(_ballista):
		_ballista.leave()
	_ballista = _Ballista.new()
	_ballista.player = _player
	_ballista.weapon = _player.equipment.weapon()
	_ballista.damage = Skills.ballista_damage(_level("ballista")) * (1.0 + _bonus("ballista_damage"))
	_ballista.time_left = Skills.BALLISTA_TIME * (1.0 + _bonus("ballista_time"))
	_ballista.total = _ballista.time_left
	_ballista.interval = Skills.BALLISTA_INTERVAL / _player._skill_speed(Skills.tags("ballista"))
	_ballista.position = _aim_point(Skills.BALLISTA_PLACE)
	_player.get_parent().add_child(_ballista)
	Sfx.play("anvil", -6.0, 1.4)


func ballista() -> Node2D:
	return _ballista if is_instance_valid(_ballista) else null


# ---------------------------------------------------------------- trafienia i węzły kluczowe
## Mnożnik obrażeń trafienia z łukiem w ręku: Myśliwy z Cienia (pierwsze po Odskoku podwójne), Oko Sokoła (bliskie słabsze).
func damage_factor(enemy: Goblin) -> float:
	var factor := 1.0
	if _shadow_shot:
		_shadow_shot = false
		factor *= 2.0
	if has_keystone("falcon_eye") and enemy.global_position.distance_to(_player.global_position) <= FALCON_EYE_NEAR:
		factor *= FALCON_EYE_WEAK
	return factor


## Cios musi być krytyczny: wróg w Sidłach albo daleki (Oko Sokoła).
func forced_crit(enemy: Goblin) -> bool:
	if is_snared(enemy):
		return true
	return has_keystone("falcon_eye") and enemy.global_position.distance_to(_player.global_position) >= FALCON_EYE_FAR


## Po trafieniu z łukiem: Jadowe Groty zatruwają (w combo jad przeskakuje na wrogów obok).
func on_hit(enemy: Goblin, amount: int) -> void:
	if _venom_time <= 0.0:
		return
	var total := amount * Skills.venom_damage(_level("venom_arrows")) * (1.0 + _bonus("venom_damage"))
	poison(enemy, total)
	if _venom_spread:
		for other: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
			if other != enemy and other.global_position.distance_to(enemy.global_position) <= Skills.VENOM_SPREAD:
				poison(other, total)


## Strzelanie w biegu: strzał nie spowalnia, a bieg przyspiesza ataki (premia chwilowa).
func running_fire() -> bool:
	return has_keystone("running_fire")


func _update_running() -> void:
	var running := running_fire() and not _player.is_dead and _player._move_velocity.length() > 20.0
	if running != _running:
		_running = running
		_player.stats.set_temp("bow", {"attack_speed": RUN_SPEED} if running else {})


## Efekty do rzędu ikon pod paskami zdrowia i many.
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _venom_time > 0.0:
		result.append({"name": "Jadowe Groty", "kind": "good", "left": _venom_time, "total": Skills.VENOM_TIME, "icon": ICONS["venom_arrows"],
				"description": "Strzały zatruwają wrogów" + (" - jad przeskakuje na wrogów obok" if _venom_spread else "")})
	if is_instance_valid(_falcon) and not _falcon.leaving:
		result.append({"name": "Sokół", "kind": "good", "left": _falcon.time_left, "total": Skills.FALCON_TIME, "icon": ICONS["falcon"],
				"description": "Sokół krąży nad tobą i atakuje wrogów"})
	if is_instance_valid(_ballista) and not _ballista.leaving:
		result.append({"name": "Balista", "kind": "good", "left": _ballista.time_left, "total": _ballista.total, "icon": ICONS["ballista"],
				"description": "Balista strzela w najbliższych wrogów"})
	if _shadow_time > 0.0:
		result.append({"name": "Myśliwy z Cienia", "kind": "good", "left": _shadow_time, "total": SHADOW_TIME, "icon": ICONS["shadow_hunter"],
				"description": "Wrogowie cię nie widzą" + (", pierwsze trafienie podwójne" if _shadow_shot else "")})
	if _running:
		result.append({"name": "Strzelanie w biegu", "kind": "good", "left": -1.0, "icon": ICONS["running_fire"],
				"description": "+%d%% szybkości ataku w biegu" % roundi(RUN_SPEED * 100.0)})
	return result


static func _ramp(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 1, 0.85, 0.9), color, Color(color, 0.0)])
	return ramp


## Smuga za strzałą (na wysokości lotu pocisku).
static func _trail(color: Color, height: float) -> CPUParticles2D:
	var trail := CPUParticles2D.new()
	trail.position = Vector2(0, -height)
	trail.amount = 24
	trail.lifetime = 0.3
	trail.local_coords = false
	trail.spread = 180.0
	trail.initial_velocity_max = 10.0
	trail.gravity = Vector2(0, -20)
	trail.scale_amount_min = 1.0
	trail.scale_amount_max = 2.5
	trail.color_ramp = _ramp(color)
	return trail


## Krąg Deszczu Strzał: co `tick` s fala strzał rani wszystkich w kręgu; spadające strzały to kreski z nieba.
class _Rain:
	extends Node2D

	const FALL := 70.0
	const DROP_TIME := 0.18
	var player: Player
	var radius := 56.0
	var tick := 0.25
	var damage := 0.4
	var time_left := 2.0
	var _next := 0.0
	var _fade := 0.3
	## spadające strzały: [punkt na ziemi, postęp 0..1]
	var _drops: Array = []

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		queue_redraw()
		for i in range(_drops.size() - 1, -1, -1):
			_drops[i][1] += delta / DROP_TIME
			if _drops[i][1] >= 1.0:
				_drops.remove_at(i)
		if time_left <= 0.0:
			_fade -= delta
			if _fade <= 0.0 and _drops.is_empty():
				queue_free()
			return
		time_left -= delta
		_next -= delta
		while _next <= 0.0 and time_left > 0.0:
			_next += tick
			_wave()

	func _wave() -> void:
		for i in 6:
			var at := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
			_drops.append([at, 0.0])
		if not is_instance_valid(player) or player.is_dead:
			return
		for enemy: Goblin in player.get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position) <= radius + enemy.hurt_radius:
				player.hit_enemy(enemy, player._skill_damage(damage), enemy.global_position + Vector2(0, -20), 10.0)
		Sfx.play_at("hit", global_position, -14.0)

	func _draw() -> void:
		var alpha := 1.0 if time_left > 0.0 else maxf(_fade / 0.3, 0.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius, Color(0.1, 0.08, 0.05, 0.25 * alpha))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.9, 0.6, 0.8 * alpha), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for drop: Array in _drops:
			var ground: Vector2 = drop[0] * Vector2(1.0, 0.6)
			var fall: float = drop[1]
			var tip := ground + Vector2(4.0, -FALL) * (1.0 - fall)
			# lotki, ciemne drzewce i jasny grot - widoczne na trawie i na ziemi
			draw_line(tip + Vector2(3.0, -14.0), tip + Vector2(2.6, -12.0), Color(0.95, 0.95, 0.9), 2.0)
			draw_line(tip + Vector2(2.6, -12.0), tip, Color(0.3, 0.2, 0.12), 1.5)
			draw_line(tip + Vector2(0.4, -2.0), tip, Color(1.0, 1.0, 1.0), 2.0)
			if fall > 0.85:
				draw_circle(ground, 1.5, Color(1.0, 0.95, 0.7, 0.8))


## Sidła: leżą otwarte, aż wróg na nie wejdzie - wtedy się zatrzaskują (BowSkills.spring_snare) i po chwili znikają.
class _Snare:
	extends Sprite2D

	var skills: BowSkills
	var _life := Skills.SNARE_LIFETIME
	var _check := 0.0
	var _sprung := false

	func _ready() -> void:
		texture = BowSkills.SNARE_OPEN
		scale = Vector2.ONE * 0.36
		z_index = -1
		SkillEffects.spark(get_parent(), global_position, Color(0.8, 0.8, 0.85), 4)

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0 or not is_instance_valid(skills):
			_vanish()
			return
		if _sprung:
			return
		_check -= delta
		if _check > 0.0:
			return
		_check = 0.05
		for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position) <= Skills.SNARE_TRIGGER + enemy.hurt_radius:
				spring()
				return

	func spring() -> void:
		if _sprung:
			return
		_sprung = true
		texture = BowSkills.SNARE_CLOSED
		skills.spring_snare(global_position)
		_life = minf(_life, 1.2)

	func _vanish() -> void:
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)


## Sokół: krąży nad graczem, co chwilę nurkuje do najbliższego wroga, rani szponami i wraca; potem odlatuje.
class _Falcon:
	extends Node2D

	const ORBIT := 34.0
	const HEIGHT := 26.0
	const SPEED := 240.0
	const DIVE_SPEED := 420.0
	var player: Player
	var damage := 0.8
	var time_left := 12.0
	var leaving := false
	var _angle := 0.0
	var _cooldown := 0.4
	var _target: Goblin
	var _strength := 1.0
	var _velocity := Vector2.ZERO
	var _sprite: Sprite2D
	var _shadow: Node2D
	var _flap := 0.0

	func _ready() -> void:
		z_index = 6
		_sprite = Sprite2D.new()
		_sprite.texture = BowSkills.FALCON_TEXTURE
		_sprite.scale = Vector2.ONE * 0.4
		add_child(_sprite)

	## Combo: od razu nurkuje do wroga najbliżej kursora, mocniej.
	func dive_now(strength: float, near: Vector2) -> void:
		_strength = strength
		_cooldown = 0.0
		_target = _closest(near)

	func leave() -> void:
		leaving = true
		_target = null

	func _process(delta: float) -> void:
		if not is_instance_valid(player):
			queue_free()
			return
		_flap += delta * (18.0 if _target != null else 11.0)
		_sprite.scale.x = 0.4 * (0.75 + 0.25 * absf(sin(_flap)))
		if leaving:
			_velocity = _velocity.move_toward(Vector2(0, -1).rotated(0.4) * SPEED * 1.4, 600.0 * delta)
			position += _velocity * delta
			modulate.a -= delta
			if modulate.a <= 0.0:
				queue_free()
			_face(_velocity)
			return
		time_left -= delta
		if time_left <= 0.0 or player.is_dead:
			leave()
			return
		_cooldown -= delta
		if _target != null:
			_dive(delta)
			return
		if _cooldown <= 0.0:
			_target = _closest(player.global_position)
			if _target == null:
				_cooldown = 0.3
		# krążenie nad graczem
		_angle += delta * 2.4
		var goal := player.global_position + Vector2(cos(_angle) * ORBIT, sin(_angle) * ORBIT * 0.5 - HEIGHT)
		_velocity = (goal - global_position) * 6.0
		_velocity = _velocity.limit_length(SPEED)
		position += _velocity * delta
		_face(Vector2(-sin(_angle), cos(_angle)))

	func _dive(delta: float) -> void:
		if not is_instance_valid(_target) or _target.state == Goblin.State.DEAD:
			_target = null
			return
		var to := _target.hurt_center() - global_position
		if to.length() <= DIVE_SPEED * delta + 6.0:
			player.hit_enemy(_target, player._skill_damage(damage * _strength), global_position, 40.0)
			SkillEffects.claw(get_parent(), _target.hurt_center(), 1.0 if to.x > 0.0 else -1.0, 10.0, Color(1.0, 0.9, 0.7))
			Sfx.play_at("hit", global_position, -4.0)
			_target = null
			_strength = 1.0
			_cooldown = Skills.FALCON_INTERVAL
			return
		_velocity = to.normalized() * DIVE_SPEED
		position += _velocity * delta
		_face(_velocity)

	## Grafika sokoła patrzy w górę - obracamy ją w stronę lotu.
	func _face(dir: Vector2) -> void:
		if dir.length() > 1.0:
			_sprite.rotation = dir.angle() + PI / 2.0

	func _closest(from: Vector2) -> Goblin:
		var best: Goblin = null
		var best_distance := Skills.FALCON_RANGE
		for enemy: Goblin in player.get_tree().get_nodes_in_group("enemies"):
			if enemy.state == Goblin.State.DEAD:
				continue
			var d := enemy.global_position.distance_to(from)
			if d < best_distance:
				best_distance = d
				best = enemy
		return best


## Balista: stoi w miejscu i co `interval` s strzela w najbliższego wroga w zasięgu - zwykłym bełtem, salwą
## (legendarny efekt ballista_volley) albo strzałami tropiącymi (ballista_seeker).
class _Ballista:
	extends Node2D

	var player: Player
	var weapon: Dictionary
	var damage := 0.8
	var time_left := 15.0
	var total := 15.0
	var interval := 1.1
	var leaving := false
	var _next := 0.3
	var _sprite: Sprite2D

	func _ready() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = BowSkills.BALLISTA_TEXTURE
		_sprite.scale = Vector2.ONE * 0.6
		_sprite.offset = Vector2(0, -BowSkills.BALLISTA_TEXTURE.get_height() / 2.0 + 4.0)
		add_child(_sprite)
		SkillEffects.spark(get_parent(), global_position, Color(0.85, 0.7, 0.5), 8)
		_sprite.scale = Vector2(0.6, 0.0)
		create_tween().tween_property(_sprite, "scale", Vector2.ONE * 0.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func leave() -> void:
		if leaving:
			return
		leaving = true
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)

	func _process(delta: float) -> void:
		if leaving:
			return
		if not is_instance_valid(player):
			queue_free()
			return
		time_left -= delta
		if time_left <= 0.0:
			leave()
			return
		_next -= delta
		if _next > 0.0:
			return
		var target := _closest()
		if target == null:
			_next = 0.2
			return
		_next = interval
		_shoot((target.hurt_center() - muzzle()).normalized())

	func muzzle() -> Vector2:
		return global_position + Vector2(0, -14)

	func _shoot(dir: Vector2) -> void:
		var kind := player.stats.kind_multiplier(["attack"])
		var low := maxi(1, roundi(player.stats.damage_min() * damage * kind))
		var high := maxi(1, roundi(player.stats.damage_max() * damage * kind))
		var seekers := roundi(player.equipment.effect_power("ballista_seeker"))
		var volley := roundi(player.equipment.effect_power("ballista_volley"))
		var count := 1 + volley
		for i in count:
			var side := 0.0 if count == 1 else lerpf(-0.25, 0.25, float(i) / (count - 1))
			if seekers > 0:
				var arrow := SeekerArrow.new()
				arrow.position = global_position + dir * 8.0
				arrow.velocity = dir.rotated(side) * SeekerArrow.SPEED
				arrow.hits_left = seekers
				arrow.damage_min = low
				arrow.damage_max = high
				get_parent().add_child(arrow)
			elif weapon.has("projectile"):
				var bolt := player._make_projectile(weapon, dir.rotated(side))
				bolt.position = global_position + dir.rotated(side) * 8.0
				bolt.damage_min = low
				bolt.damage_max = high
				bolt.speed = 460.0
				bolt.size = 1.3
				bolt.pierce += 1
				bolt.max_range = Skills.BALLISTA_RANGE * 1.3
				get_parent().add_child(bolt)
		Sfx.play_at("bow", global_position, -2.0)
		var tween := _sprite.create_tween()
		tween.tween_property(_sprite, "position", -dir * 2.0, 0.05)
		tween.tween_property(_sprite, "position", Vector2.ZERO, 0.15)

	func _closest() -> Goblin:
		var best: Goblin = null
		var best_distance := Skills.BALLISTA_RANGE
		for enemy: Goblin in player.get_tree().get_nodes_in_group("enemies"):
			if enemy.state == Goblin.State.DEAD:
				continue
			var d := enemy.global_position.distance_to(global_position)
			if d < best_distance:
				best_distance = d
				best = enemy
		return best
