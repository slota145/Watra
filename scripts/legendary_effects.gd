class_name LegendaryEffects
extends Node
## Efekty legendarnej biżuterii, odpalane przy trafieniu wroga (Player.hit_enemy):
## - shockwave (Sygnet Gruzłoga): fala uderzeniowa wokół trafionego - rani i ogłusza wszystkich w pobliżu,
## - tide (Oko Przypływu): fala wody bije stożkiem od trafionego w stronę od gracza - rani i odpycha,
## - claws (Pazur Szarokła): pazury tną zamaszyście dwoma łukami na krzyż - ranią trafionego i wszystkich obok,
## - echo (Kieł Alfy): odpalony efekt ma szansę zadziałać drugi raz, chwilę później,
## - thunder (Pierścień Gromu): z nieba wali piorun w trafionego i przeskakuje na dwóch pobliskich wrogów,
## - fortune (Łza Bulgora): zwiększa wszystkie powyższe szanse o swój procent,
## - storm_dash (Lotka Burzy): unik zostawia ślad piorunów raniący wrogów na drodze (on_dash),
## - whirlpool (Pierścień Topieli): pod trafionym otwiera się wir - wciąga pobliskich wrogów i rani,
## - leech (Perła Wodnika): część zadanych obrażeń wraca jako zdrowie (leech),
## - roots (Obręcz Leszego): spod trafionego wystrzelają korzenie - ranią i oplątują wrogów wokół,
## - thorns (Żołądź Leszego): gdy ktoś cię zrani, wokół ciebie wybuchają ciernie (on_hurt),
## - venom (Pierścień Królowej): jad zatruwa trafionego i wrogów tuż obok,
## - brood (Jedwabny Kokon): z zabitego wroga wybiegają jadowite pajączki i rzucają się na wrogów (on_kill),
## - fear (Róg Biesa): mroczny ryk - rani i płoszy wrogów wokół trafionego (uciekają w strachu),
## - bloodlust (Szpon Biesa): każde zabójstwo na chwilę zwiększa obrażenia, do 5 razy (on_kill).
## Legendy bossów na inne miejsca (Legends):
## - bomb (Rękawice Podpalacza): rzut bombą zapalającą w trafionego (wybuch i płonąca plama),
## - blast_shot (Kostur Bombardiera): pocisk łuku / kostura / księgi wybucha przy trafieniu,
## - earth_arrow (Łuk z Żuchwy): spod trafionego strzałą wroga wystrzela kolec ziemi - rani i ogłusza,
## - kaboom (Naszyjnik z Lontów): pokonany wróg wybucha, raniąc sąsiadów (on_kill),
## - devour (Szczęka Pożeracza): pokonany wróg leczy o 3% maks. zdrowia (on_kill),
## - mine_trail (Buty Sapera): unik zostawia bomby na drodze (on_dash),
## - burrow (Pancerz z Łusek Czerwia): cios, po którym zostałoby mniej niż 35% zdrowia, może zostać
##   pochłonięty - zakopujesz się na chwilę (nietykalny) i wystrzelasz z ziemi, raniąc wszystko wokół (on_hurt),
## - tremor (Serce Głębin): co kilka sekund wokół gracza drży ziemia, raniąc pobliskich wrogów (bierne).
## (Kieł Gruzłoga - "might" - działa biernie na obrażenia, w CharacterStats.)
## Obrażenia z efektów nie wywołują kolejnych efektów, a każdy efekt ma krótki czas odnowienia,
## żeby szybkie ataki (salwa, łańcuch) nie zamieniały ekranu w ciągłą falę.

const COOLDOWN := 0.5
const ECHO_DELAY := 0.22

const SHOCK_RADIUS := 42.0
const SHOCK_DAMAGE := 0.9
const SHOCK_STUN := 1.4

const TIDE_RADIUS := 80.0
const TIDE_HALF_ANGLE := 0.6
const TIDE_DAMAGE := 0.8
const TIDE_KNOCKBACK := 320.0

const CLAW_DAMAGE := 0.6
const CLAW_GAP := 0.12
const CLAW_SIZE := 34.0
## Promień, w jakim łuk pazurów sięga wrogów wokół trafionego.
const CLAW_RADIUS := 30.0

const THUNDER_DAMAGE := 1.1
const THUNDER_JUMPS := 2
const THUNDER_JUMP_RANGE := 70.0
const DASH_TRAIL_WIDTH := 20.0

const ECHO_COLOR := Color(0.7, 0.85, 1.0)
## Efekty odpalane przy trafieniu (echo i fortune tylko je wzmacniają).
const ON_HIT := ["shockwave", "tide", "claws", "thunder", "whirlpool", "roots", "venom", "fear", "bomb", "blast_shot", "earth_arrow"]
## Efekty przy trafieniu działające tylko z danym rodzajem broni.
const WEAPON_ONLY := {"blast_shot": ["bow", "spell"], "earth_arrow": ["bow"]}
const BOMB_DAMAGE := 1.3
const BOMB_RADIUS := 34.0
const BLAST_DAMAGE := 0.8
const BLAST_RADIUS := 30.0
const SPIKE_DAMAGE := 1.4
const SPIKE_RADIUS := 22.0
const SPIKE_STUN := 0.8
const KABOOM_DAMAGE := 1.0
const KABOOM_RADIUS := 40.0
const DEVOUR_HEAL := 0.03
const MINE_DAMAGE := 1.0
const MINE_COOLDOWN := 1.2
const BURROW_THRESHOLD := 0.35
const BURROW_COOLDOWN := 25.0
const BURROW_TIME := 1.2
const BURROW_DAMAGE := 2.0
const BURROW_RADIUS := 70.0
const TREMOR_PERIOD := 4.0
const TREMOR_RADIUS := 64.0
const FIRE_COLOR := Color(1.0, 0.55, 0.2)
const EARTH_COLOR := Color(0.55, 0.42, 0.28)
var _tremor_timer := TREMOR_PERIOD
const WHIRL_RADIUS := 64.0
const WHIRL_TIME := 2.2
const WHIRL_PULL := 70.0
const WHIRL_DAMAGE := 0.3

const ROOTS_RADIUS := 46.0
const ROOTS_DAMAGE := 1.0
const ROOTS_HOLD := 1.0
const ROOTS_COLOR := Color(0.55, 0.42, 0.25)
const THORNS_RADIUS := 58.0
const THORNS_DAMAGE := 1.2
const VENOM_RADIUS := 30.0
const VENOM_TICK := 0.25
const VENOM_TICKS := 6
const VENOM_COLOR := Color(0.45, 0.95, 0.3)
const BROOD_COUNT := 2
const FEAR_RADIUS := 72.0
const FEAR_DAMAGE := 0.5
const FEAR_TIME := 2.5
const BLOODLUST_TIME := 5.0
const BLOODLUST_STACKS := 5

var _player: Player
var _bloodlust := 0
var _bloodlust_time := 0.0
## rodzaj efektu -> pozostały czas odnowienia
var _cooldowns := {}


func _init(player: Player) -> void:
	_player = player


func _process(delta: float) -> void:
	for kind: String in _cooldowns:
		_cooldowns[kind] = maxf(_cooldowns[kind] - delta, 0.0)
	_process_tremor(delta)
	if _bloodlust > 0:
		_bloodlust_time -= delta
		if _bloodlust_time <= 0.0:
			_bloodlust = 0


## Szansa (0..1) na efekt danego rodzaju z założonych przedmiotów, powiększona przez Łzę Bulgora.
func chance(kind: String) -> float:
	var base := _player.equipment.effect_power(kind)
	return minf(base * (1.0 + _player.equipment.effect_power("fortune")), 1.0)


## Trafienie wroga - losujemy efekty założonych pierścieni.
func on_hit(enemy: Goblin) -> void:
	for kind: String in ON_HIT:
		if _cooldowns.get(kind, 0.0) > 0.0:
			continue
		if WEAPON_ONLY.has(kind) and not _player.stats.weapon_type() in WEAPON_ONLY[kind]:
			continue
		var p := chance(kind)
		if p <= 0.0 or randf() >= p:
			continue
		_cooldowns[kind] = COOLDOWN
		var at := enemy.hurt_center()
		var away := (enemy.global_position - _player.global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		_trigger(kind, enemy, at, away)
		if randf() < chance("echo"):
			get_tree().create_timer(ECHO_DELAY).timeout.connect(_echo.bind(kind, enemy, at, away))


func _echo(kind: String, enemy: Goblin, at: Vector2, away: Vector2) -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return
	if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
		at = enemy.hurt_center()
	DamageNumber.spawn_text(_player.get_parent(), at + Vector2(0, -16), "Echo!", ECHO_COLOR, 8)
	_trigger(kind, enemy, at, away, true)


func _trigger(kind: String, enemy: Goblin, at: Vector2, away: Vector2, echo := false) -> void:
	match kind:
		"shockwave":
			_shockwave(at, echo)
		"tide":
			_tide(at, away, echo)
		"thunder":
			_thunder(enemy, at, echo)
		"whirlpool":
			_whirlpool(at + Vector2(0, 8), echo)
		"roots":
			_roots(at + Vector2(0, 6), echo)
		"venom":
			_venom_burst(enemy, at)
		"fear":
			_fear(at, echo)
		"bomb":
			_throw_bomb(enemy.global_position)
		"blast_shot":
			_explosion(at, BLAST_RADIUS, BLAST_DAMAGE, echo)
		"earth_arrow":
			_earth_spike(enemy.global_position, echo)
		"claws":
			_claw(enemy, at, -1.0, echo)
			get_tree().create_timer(CLAW_GAP).timeout.connect(_claw.bind(enemy, at, 1.0, echo))


## Jedno zamaszyste cięcie trzema pazurami po łuku (pierwsze z lewej góry, drugie z prawej -
## razem krzyż). Rani wszystkich wrogów w zasięgu łuku wokół trafionego.
func _claw(enemy: Goblin, at: Vector2, side: float, echo: bool) -> void:
	if not is_instance_valid(_player):
		return
	if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
		at = enemy.hurt_center()
	SkillEffects.claw(_player.get_parent(), at, side, CLAW_SIZE, ECHO_COLOR if echo else Color.WHITE)
	Sfx.play_at("claw", at)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.hurt_center().distance_to(at) <= CLAW_RADIUS + other.hurt_radius:
			other.take_damage(_player.roll_damage(CLAW_DAMAGE), at - Vector2(side * 10.0, 10.0), 70.0)


## Piorun z nieba w trafionego, potem przeskok na najbliższych wrogów (każdy raz).
func _thunder(enemy: Goblin, at: Vector2, echo: bool) -> void:
	var targets: Array[Goblin] = []
	if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
		targets.append(enemy)
		at = enemy.hurt_center()
	var from := at
	for i in THUNDER_JUMPS:
		var next: Goblin = null
		var best := THUNDER_JUMP_RANGE
		for other: Goblin in get_tree().get_nodes_in_group("enemies"):
			if other in targets:
				continue
			var d := other.hurt_center().distance_to(from)
			if d < best:
				best = d
				next = other
		if next == null:
			break
		targets.append(next)
		from = next.hurt_center()
	var parent := _player.get_parent()
	SkillEffects.bolt(parent, at + Vector2(randf_range(-16, 16), -170), at, 0.35, 9.0)
	SkillEffects.spark(parent, at, ECHO_COLOR if echo else Color(0.75, 0.9, 1.0), 12)
	Sfx.play_at("thunder", at, -6.0 if echo else -3.0)
	_player.add_shake(2.0)
	from = at
	for target in targets:
		if target != enemy:
			SkillEffects.bolt(parent, from, target.hurt_center(), 0.3, 6.0)
		target.take_damage(_player.roll_damage(THUNDER_DAMAGE), from, 60.0)
		from = target.hurt_center()


## Wir pod trafionym: przez chwilę wciąga wrogów do środka i co pół sekundy rani.
func _whirlpool(at: Vector2, echo: bool) -> void:
	var fx := Wodnik.WhirlFx.new()
	fx.radius = WHIRL_RADIUS
	fx.life = WHIRL_TIME
	if echo:
		fx.modulate = ECHO_COLOR
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else _player.get_parent()).add_child(fx)
	fx.global_position = at
	Sfx.play_at("whirlpool", at, -4.0)
	var ticks := int(WHIRL_TIME / 0.5)
	for i in ticks:
		get_tree().create_timer(0.5 * (i + 1)).timeout.connect(_whirl_tick.bind(at))


func _whirl_tick(at: Vector2) -> void:
	if not is_instance_valid(_player):
		return
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		var to_center := at - enemy.global_position
		if to_center.length() > WHIRL_RADIUS + enemy.hurt_radius:
			continue
		enemy.take_damage(_player.roll_damage(WHIRL_DAMAGE), at, 0.0)
		if not enemy is Boss and enemy.state != Goblin.State.DEAD:
			enemy._knockback = to_center.normalized() * WHIRL_PULL


## Perła Wodnika: leczy o część zadanych obrażeń.
func leech(amount: int) -> void:
	var power := _player.equipment.effect_power("leech")
	if power > 0.0:
		_player.heal(amount * power)


## Lotka Burzy: unik zostawia ślad piorunów od miejsca startu do końca - rani wrogów na drodze.
func on_dash(from: Vector2, to: Vector2) -> void:
	_mine_trail(from, to)
	var power := _player.equipment.effect_power("storm_dash")
	if power <= 0.0 or from.distance_to(to) < 8.0:
		return
	var parent := _player.get_parent()
	var lift := Vector2(0, -8)
	SkillEffects.bolt(parent, from + lift, to + lift, 0.45, 5.0)
	SkillEffects.bolt(parent, from + lift, to + lift, 0.3, 7.0)
	Sfx.play_at("zap", to)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		var point := Geometry2D.get_closest_point_to_segment(enemy.global_position, from, to)
		if point.distance_to(enemy.global_position) <= DASH_TRAIL_WIDTH + enemy.hurt_radius:
			enemy.take_damage(_player.roll_damage(power), point, 50.0)
			SkillEffects.spark(parent, enemy.hurt_center(), Color(0.75, 0.9, 1.0), 6)


## Fala uderzeniowa: rani i ogłusza trafionego oraz wszystkich dookoła.
func _shockwave(at: Vector2, echo: bool) -> void:
	SkillEffects.shockwave(_player.get_parent(), at + Vector2(0, 4), SHOCK_RADIUS, ECHO_COLOR if echo else Items.LEGENDARY_COLOR)
	Sfx.play_at("shockwave", at, -2.0 if echo else 0.0)
	_player.add_shake(3.0)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(at) > SHOCK_RADIUS + enemy.hurt_radius:
			continue
		enemy.take_damage(_player.roll_damage(SHOCK_DAMAGE), at, 90.0)
		if enemy.state != Goblin.State.DEAD:
			enemy.stun(SHOCK_STUN)
	Sfx.play_at("stun", at)


## Fala wody: stożek od trafionego w stronę od gracza - rani i odrzuca wrogów.
func _tide(at: Vector2, away: Vector2, echo: bool) -> void:
	var origin := at - away * 10.0
	SkillEffects.tide(_player.get_parent(), origin, away.angle(), TIDE_HALF_ANGLE, TIDE_RADIUS, echo)
	Sfx.play_at("tide_wave", at, -2.0 if echo else 0.0)
	_player.add_shake(2.0)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > TIDE_RADIUS + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius + 10.0 and absf(angle_difference(away.angle(), to_enemy.angle())) > TIDE_HALF_ANGLE:
			continue
		# wszystkich odrzuca w kierunku fali, niezależnie od tego, gdzie stoją w stożku
		enemy.take_damage(_player.roll_damage(TIDE_DAMAGE), enemy.global_position - away * 20.0, TIDE_KNOCKBACK)


# ---------------------------------------------------------------- Prastary Las
## Korzenie spod ziemi: ranią i oplątują (ogłuszają) wrogów wokół trafionego.
func _roots(at: Vector2, echo: bool) -> void:
	var parent := _player.get_parent()
	SkillEffects.shockwave(parent, at, ROOTS_RADIUS, ECHO_COLOR if echo else ROOTS_COLOR)
	for i in 6:
		var spot := at + Vector2.from_angle(TAU * i / 6.0 + randf()) * randf_range(8.0, ROOTS_RADIUS)
		SkillEffects.spark(parent, spot, ROOTS_COLOR, 5)
		SkillEffects.spark(parent, spot, Color(0.4, 0.7, 0.3), 3)
	Sfx.play_at("roots_burst", at, -3.0)
	_player.add_shake(2.0)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(at) > ROOTS_RADIUS + enemy.hurt_radius:
			continue
		enemy.take_damage(_player.roll_damage(ROOTS_DAMAGE), at, 0.0)
		if enemy.state != Goblin.State.DEAD:
			enemy.stun(ROOTS_HOLD)


## Żołądź Leszego: gdy gracz oberwie, czasem wokół niego wybuchają ciernie.
## Zwraca true, gdy cios został pochłonięty (Pancerz z Łusek Czerwia).
func on_hurt(amount := 0) -> bool:
	if _try_burrow(amount):
		return true
	_thorns()
	return false


func _thorns() -> void:
	if _cooldowns.get("thorns", 0.0) > 0.0 or randf() >= chance("thorns"):
		return
	_cooldowns["thorns"] = COOLDOWN
	var at := _player.global_position
	var parent := _player.get_parent()
	SkillEffects.shockwave(parent, at, THORNS_RADIUS, Color(0.45, 0.75, 0.3))
	for i in 10:
		SkillEffects.spark(parent, at + Vector2.from_angle(TAU * i / 10.0) * THORNS_RADIUS * 0.7, ROOTS_COLOR, 3)
	Sfx.play_at("roots_burst", at, -2.0)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(at) <= THORNS_RADIUS + enemy.hurt_radius:
			enemy.take_damage(_player.roll_damage(THORNS_DAMAGE), at, 160.0)


## Pierścień Królowej: jad na trafionym i wrogach tuż obok.
func _venom_burst(enemy: Goblin, at: Vector2) -> void:
	SkillEffects.spark(_player.get_parent(), at, VENOM_COLOR, 10)
	Sfx.play_at("spit_hit", at, -6.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.hurt_center().distance_to(at) <= VENOM_RADIUS + other.hurt_radius:
			poison(other)


## Zatruwa wroga: przez 3 s co pół sekundy traci zdrowie (unosi się nad nim zielony opar).
func poison(enemy: Goblin) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD or enemy.has_node("Venom"):
		return
	var fumes := CPUParticles2D.new()
	fumes.name = "Venom"
	fumes.position = enemy.hurt_center() - enemy.global_position
	fumes.amount = 8
	fumes.lifetime = 0.8
	fumes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	fumes.emission_sphere_radius = 6.0
	fumes.direction = Vector2.UP
	fumes.gravity = Vector2(0, -25)
	fumes.initial_velocity_min = 4.0
	fumes.initial_velocity_max = 10.0
	fumes.scale_amount_max = 2.0
	fumes.color = Color(VENOM_COLOR, 0.8)
	enemy.add_child(fumes)
	for i in VENOM_TICKS:
		get_tree().create_timer(0.5 * (i + 1)).timeout.connect(_venom_tick.bind(enemy.get_instance_id(), i == VENOM_TICKS - 1))


## Wroga przekazujemy przez id - mógł zniknąć, zanim minął czas trucizny.
func _venom_tick(enemy_id: int, last: bool) -> void:
	var enemy := instance_from_id(enemy_id) as Goblin
	if enemy == null:
		return
	if enemy.state != Goblin.State.DEAD and is_instance_valid(_player):
		enemy.take_damage(_player.roll_damage(VENOM_TICK), enemy.global_position, 0.0)
	if last and enemy.has_node("Venom"):
		enemy.get_node("Venom").queue_free()


## Róg Biesa: kłąb czarnego dymu i ryk - rani wrogów wokół trafionego, a ci w strachu uciekają od gracza.
func _fear(at: Vector2, echo: bool) -> void:
	var smoke := CPUParticles2D.new()
	smoke.one_shot = true
	smoke.explosiveness = 0.9
	smoke.amount = 30
	smoke.lifetime = 0.9
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 14.0
	smoke.spread = 180.0
	smoke.gravity = Vector2(0, -20)
	smoke.initial_velocity_min = 30.0
	smoke.initial_velocity_max = 80.0
	smoke.scale_amount_min = 3.0
	smoke.scale_amount_max = 6.0
	smoke.color = ECHO_COLOR if echo else Color(0.1, 0.05, 0.08, 0.8)
	smoke.emitting = true
	_player.get_parent().add_child(smoke)
	smoke.global_position = at
	smoke.finished.connect(smoke.queue_free)
	SkillEffects.shockwave(_player.get_parent(), at, FEAR_RADIUS, Color(0.8, 0.15, 0.1))
	Sfx.play_at("bies_roar", at, -8.0)
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(at) > FEAR_RADIUS + enemy.hurt_radius:
			continue
		enemy.take_damage(_player.roll_damage(FEAR_DAMAGE), at, 0.0)
		if enemy.state != Goblin.State.DEAD:
			enemy.fear(FEAR_TIME, _player.global_position)


## Zabójstwo wroga: Jedwabny Kokon wypuszcza pajączki, Szpon Biesa podsyca żądzę krwi.
func on_kill(enemy: Goblin) -> void:
	var at := enemy.global_position
	if _cooldowns.get("kaboom", 0.0) <= 0.0 and randf() < chance("kaboom"):
		_cooldowns["kaboom"] = 0.15
		_explosion(enemy.hurt_center(), KABOOM_RADIUS, KABOOM_DAMAGE, false)
	if randf() < chance("devour"):
		_player.heal(_player.stats.max_health() * DEVOUR_HEAL)
		SkillEffects.spark(_player.get_parent(), _player.body_center(), Color(0.9, 0.4, 0.4), 6)
	if _cooldowns.get("brood", 0.0) <= 0.0 and randf() < chance("brood"):
		_cooldowns["brood"] = COOLDOWN
		for i in BROOD_COUNT:
			var spiderling := SpiderlingAlly.new()
			spiderling.effects = self
			spiderling.player = _player
			_player.get_parent().add_child(spiderling)
			spiderling.global_position = at + Vector2.from_angle(randf() * TAU) * 6.0
		Sfx.play_at("cocoon_burst", at, -4.0)
	if _player.equipment.effect_power("bloodlust") > 0.0:
		_bloodlust = mini(_bloodlust + 1, BLOODLUST_STACKS)
		_bloodlust_time = BLOODLUST_TIME
		DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -18), "Żądza krwi x%d" % _bloodlust,
				Color(1.0, 0.35, 0.3), 8)


## Mnożnik obrażeń z żądzy krwi (Szpon Biesa).
func damage_multiplier() -> float:
	if _bloodlust <= 0:
		return 1.0
	return 1.0 + _bloodlust * _player.equipment.effect_power("bloodlust")


# ---------------------------------------------------------------- legendy bossów (Legends)
## Rękawice Podpalacza: bomba zapalająca leci łukiem w trafionego.
func _throw_bomb(target: Vector2) -> void:
	var bomb := KoboldBomb.new()
	bomb.position = _player.body_center()
	bomb.target = target
	bomb.damage = _player.roll_damage(BOMB_DAMAGE)
	bomb.radius = BOMB_RADIUS
	bomb.flight = 0.45
	bomb.height = 30.0
	bomb.style = "fire"
	bomb.hurts_enemies = true
	_player.get_parent().add_child(bomb)


## Wybuch raniący wrogów w promieniu (Kostur Bombardiera, Naszyjnik z Lontów).
func _explosion(at: Vector2, radius: float, damage: float, echo: bool) -> void:
	var parent := _player.get_parent()
	SkillEffects.shockwave(parent, at, radius, ECHO_COLOR if echo else FIRE_COLOR)
	SkillEffects.spark(parent, at, FIRE_COLOR, 10)
	Sfx.play_at("explosion", at, -10.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.hurt_center().distance_to(at) <= radius + other.hurt_radius:
			other.take_damage(_player.roll_damage(damage), at, 140.0)


## Łuk z Żuchwy: kolec ziemi spod trafionego.
func _earth_spike(at: Vector2, echo: bool) -> void:
	var layer := get_tree().get_first_node_in_group("floor_layer")
	SkillEffects.ground_crack(layer if layer != null else _player.get_parent(), at, SPIKE_RADIUS, 1.5)
	SkillEffects.spark(_player.get_parent(), at + Vector2(0, -8), ECHO_COLOR if echo else EARTH_COLOR, 12)
	Sfx.play_at("rock_break", at, -8.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(at) <= SPIKE_RADIUS + other.hurt_radius:
			other.take_damage(_player.roll_damage(SPIKE_DAMAGE), at, 0.0)
			if other.state != Goblin.State.DEAD:
				other.stun(SPIKE_STUN)


## Buty Sapera: trzy bomby wzdłuż drogi uniku, wybuchają chwilę później.
func _mine_trail(from: Vector2, to: Vector2) -> void:
	var power := _player.equipment.effect_power("mine_trail")
	if power <= 0.0 or from.distance_to(to) < 8.0 or _cooldowns.get("mine_trail", 0.0) > 0.0:
		return
	_cooldowns["mine_trail"] = MINE_COOLDOWN
	for i in 3:
		var spot := from.lerp(to, i / 2.0)
		var bomb := KoboldBomb.new()
		bomb.position = spot
		bomb.target = spot
		bomb.height = 0.0
		bomb.flight = 0.05
		bomb.fuse = 0.6 + i * 0.1
		bomb.damage = _player.roll_damage(MINE_DAMAGE * power)
		bomb.radius = 30.0
		bomb.hurts_enemies = true
		_player.get_parent().add_child(bomb)


## Pancerz z Łusek Czerwia: cios, który zostawiłby mało zdrowia, zostaje pochłonięty - gracz zapada się
## pod ziemię, na chwilę jest nietykalny i wystrzela z niej, raniąc wszystko wokół.
func _try_burrow(amount: int) -> bool:
	if _cooldowns.get("burrow", 0.0) > 0.0 or amount <= 0:
		return false
	if _player.health - amount >= _player.stats.max_health() * BURROW_THRESHOLD or randf() >= chance("burrow"):
		return false
	_cooldowns["burrow"] = BURROW_COOLDOWN
	_player._invulnerable_timer = BURROW_TIME + 0.3
	var at := _player.global_position
	var parent := _player.get_parent()
	SkillEffects.spark(parent, at, EARTH_COLOR, 16)
	Sfx.play_at("mine", at)
	DamageNumber.spawn_text(parent, _player.body_center() + Vector2(0, -16), "Zakopanie!", EARTH_COLOR, 9)
	var tween := _player.create_tween()
	tween.tween_property(_player, "modulate:a", 0.25, 0.15)
	tween.tween_interval(BURROW_TIME)
	tween.tween_property(_player, "modulate:a", 1.0, 0.1)
	tween.tween_callback(_erupt_from_burrow)
	return true


func _erupt_from_burrow() -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return
	var at := _player.global_position
	var parent := _player.get_parent()
	var layer := get_tree().get_first_node_in_group("floor_layer")
	SkillEffects.ground_crack(layer if layer != null else parent, at, BURROW_RADIUS * 0.7, 3.0)
	SkillEffects.shockwave(parent, at, BURROW_RADIUS, EARTH_COLOR)
	Sfx.play_at("rock_break", at)
	_player.add_shake(5.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(at) <= BURROW_RADIUS + other.hurt_radius:
			other.take_damage(_player.roll_damage(BURROW_DAMAGE), at, 220.0)


## Serce Głębin: co kilka sekund drży ziemia wokół gracza (tylko gdy w pobliżu są wrogowie).
func _process_tremor(delta: float) -> void:
	if _player == null or _player.is_dead:
		return
	var power := _player.equipment.effect_power("tremor")
	if power <= 0.0:
		return
	_tremor_timer -= delta
	if _tremor_timer > 0.0:
		return
	_tremor_timer = TREMOR_PERIOD
	var at := _player.global_position
	var hit: Array[Goblin] = []
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(at) <= TREMOR_RADIUS + other.hurt_radius:
			hit.append(other)
	if hit.is_empty():
		return
	SkillEffects.shockwave(_player.get_parent(), at, TREMOR_RADIUS, EARTH_COLOR)
	Sfx.play_at("tree_rumble", at, -10.0)
	for other in hit:
		other.take_damage(_player.roll_damage(power), at, 90.0)
