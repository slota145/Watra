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
## - raise_dead (Kostur Mortana): pokonany wróg wstaje jako szkielet sługa (on_kill),
## - soul_harvest (Całun Nekromanty): co 10 zabójstw fala dusz wokół gracza (on_kill),
## - bone_armor (Kościana Korona): co 8 s kości pochłaniają następny cios (on_hurt),
## - undying (Filakteria Mortana): raz na 90 s cios śmiertelny zostawia przy życiu (on_hurt),
## - rend (Szpony Gnilca): trafiony krwawi (obrażenia przez 3 s),
## - corpse_leap (Nagolenice Trupojada): unik kończy się uderzeniem w ziemię (on_dash),
## - execute (Rzeźnicki Topór): dodatkowe obrażenia przy trafieniu wrogów poniżej 25% zdrowia,
## - bile_spit (Paszcza Gnilca): co 5. trafienie stożek żółci przed graczem (trujące kałuże).
## - plunder (Maczuga Gruzłoga): pokonany wróg upuszcza dodatkowy przedmiot (on_kill),
## - pack_call (Skóra Szarokła): gdy gracz oberwie, widmowy wilk walczy u jego boku (on_hurt),
## - tongue (Płetwy Bulgora): język przyciąga kolejnego wroga do trafionego,
## - storm_arrows (Łuk Gromowładnego): piorun przeskakuje ze strzałą trafionego wroga,
## - tidal_dodge (Płaszcz Topielca): unik ciągnie falę odpychającą wrogów (on_dash),
## - rooted_regen (Kostur Leszego): stojąc w miejscu, gracz odzyskuje zdrowie (bierne),
## - web_burst (Żądło Królowej): sieć oplątuje wrogów wokół trafionego,
## - berserk (Topór Biesa): przy niskim zdrowiu więcej obrażeń (damage_multiplier).
## Legendy Hydry i Gryfa (węzły efektów w LegendFx):
## - corpse_blast (Kieł Hydry): wróg padający w pobliżu (także od efektów) wybucha trucizną (on_enemy_died),
## - toxic_aura (Łuski Hydry): trująca chmura wokół gracza (bierne),
## - hydra_seekers (Łuk Siedmiu Głów): strzała tropiąca wylatuje z dodatkowymi (extra_seekers),
## - regrowth (Korona Odrastających Głów): przy niskim zdrowiu regeneracja (bierne),
## - venom_chain (Rękawice Jadu): jad przeskakuje z trafionego na sąsiadów,
## - acid_trail (Buty Bagiennego Śladu): żrące kałuże za idącym graczem (bierne),
## - wind_crescent (Ostrze Gryfa): cięcie wypuszcza półksiężyc wiatru (on_melee_swing),
## - gather (Szpony Gryfa): zamach ściąga wrogów przed gracza (on_melee_swing),
## - fire_turret (Księga Gryfiego Płomienia): kula ognia zawisa i strzela (fire_turret_damage),
## - tornado_walk (Skrzydlate Buty): trąby powietrzne za biegnącym graczem (bierne),
## - feather_storm (Grzebień Gryfa): wachlarz piór wokół trafionego,
## - wind_shield (Serce Wichru): wiatr odbija wrogie pociski (deflects).
## Legendy Faun-Króla: dance (Fletnia Fauna - wrogowie tańczą), horn_charge (Rogi Króla - unik jako szarża),
## vine_snare (Kopyta Fauna - pnącza po otrzymaniu ciosu), pan_echo (Berło - fala dźwięku płoszy wrogów).
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
const ON_HIT := ["shockwave", "tide", "claws", "thunder", "whirlpool", "roots", "venom", "fear", "bomb", "blast_shot", "earth_arrow", "rend",
		"tongue", "storm_arrows", "web_burst", "venom_chain", "feather_storm", "dance", "pan_echo"]
## Efekty przy trafieniu działające tylko z danym rodzajem broni.
const WEAPON_ONLY := {"blast_shot": ["bow", "spell"], "earth_arrow": ["bow"], "storm_arrows": ["bow"]}
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
const SOUL_COUNT := 10
const SOUL_RADIUS := 90.0
const BONE_ARMOR_PERIOD := 8.0
const UNDYING_COOLDOWN := 90.0
const REND_TICKS := 6
const LEAP_RADIUS := 52.0
const EXECUTE_THRESHOLD := 0.25
const BILE_EVERY := 5
const SOUL_COLOR := Color(0.5, 1.0, 0.6)
var _souls := 0
var _bone_armor_timer := 0.0
var _bone_orbit: Node2D
var _hits := 0
const WOLF_TEXTURE := preload("res://assets/forest/wolf.png")
const TONGUE_RANGE := 130.0
const WEB_RADIUS := 40.0
const WEB_HOLD := 1.0
const TIDE_DODGE_RADIUS := 70.0
const BERSERK_THRESHOLD := 0.4
var _still_time := 0.0
const CORPSE_RADIUS := 44.0
const CORPSE_RANGE := 320.0
const AURA_RADIUS := 52.0
const AURA_TICK := 0.5
const TRAIL_STEP := 0.35
const TORNADO_STEP := 1.0
const GATHER_RANGE := 110.0
const FEATHER_RADIUS := 60.0
const POISON_COLOR := Color(0.55, 0.95, 0.35)
var _aura_tick := 0.0
var _aura: CPUParticles2D
var _trail_timer := 0.0
var _tornado_timer := 0.0
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
	_process_bone_armor(delta)
	_process_rooted_regen(delta)
	_process_hydra_gryf(delta)
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
		"rend":
			_rend(enemy)
		"tongue":
			_tongue(enemy, at)
		"storm_arrows":
			_thunder(enemy, at, echo)
		"web_burst":
			_web_burst(at)
		"venom_chain":
			_venom_chain(enemy)
		"feather_storm":
			_feather_storm(at, echo)
		"dance":
			_dance(at)
		"pan_echo":
			_pan_echo(away, echo)
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
	_corpse_leap(to)
	_tidal_dodge(from, to)
	_horn_charge(from, to)
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
	if _try_bone_armor(amount) or _try_undying(amount) or _try_burrow(amount):
		return true
	_thorns()
	_pack_call()
	_vine_snare()
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
	if randf() < chance("plunder"):
		var pickup: Pickup = load(Goblin.PICKUP_PATH).instantiate()
		pickup.item_id = Loot.drop_at_level(enemy.level)
		pickup.amount = 1
		pickup.position = at
		_player.get_parent().add_child.call_deferred(pickup)
	if randf() < chance("raise_dead"):
		var ally := SkeletonAlly.new()
		ally.player = _player
		_player.get_parent().add_child(ally)
		ally.global_position = at
	if _player.equipment.effect_power("soul_harvest") > 0.0:
		_souls += 1
		if _souls >= SOUL_COUNT:
			_souls = 0
			_soul_nova(_player.equipment.effect_power("soul_harvest"))
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
	var multiplier := 1.0
	if _bloodlust > 0:
		multiplier += _bloodlust * _player.equipment.effect_power("bloodlust")
	if _player.health < _player.stats.max_health() * BERSERK_THRESHOLD:
		multiplier += _player.equipment.effect_power("berserk")
	return multiplier


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


# ---------------------------------------------------------------- legendy Leśnego Cmentarza
## Całun Nekromanty: zebrane dusze wyrywają się falą wokół gracza.
func _soul_nova(power: float) -> void:
	var at := _player.global_position
	var parent := _player.get_parent()
	SkillEffects.shockwave(parent, at, SOUL_RADIUS, SOUL_COLOR)
	for i in 12:
		SkillEffects.spark(parent, at + Vector2.from_angle(TAU * i / 12.0) * SOUL_RADIUS * 0.6 + Vector2(0, -10), SOUL_COLOR, 3)
	Sfx.play_at("wisp_burst", at, -4.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(at) <= SOUL_RADIUS + other.hurt_radius:
			other.take_damage(_player.roll_damage(power), at, 120.0)


## Kościana Korona: co 8 s gotowa tarcza z krążących kości - pochłania następny cios do części maks. zdrowia.
func _process_bone_armor(delta: float) -> void:
	var power := _player.equipment.effect_power("bone_armor")
	if power <= 0.0:
		if _bone_orbit != null:
			_bone_orbit.queue_free()
			_bone_orbit = null
		return
	if _bone_orbit != null:
		_bone_orbit.rotation += delta * 3.0
		return
	_bone_armor_timer -= delta
	if _bone_armor_timer > 0.0:
		return
	_bone_orbit = Node2D.new()
	_bone_orbit.position = Vector2(0, -12)
	_bone_orbit.z_index = 2
	for i in 4:
		var bone := Line2D.new()
		var dir := Vector2.from_angle(TAU * i / 4.0)
		bone.points = PackedVector2Array([dir * 14.0 - dir.orthogonal() * 3.0, dir * 14.0 + dir.orthogonal() * 3.0])
		bone.width = 2.0
		bone.default_color = Skeleton.BONE_COLOR
		_bone_orbit.add_child(bone)
	_player.add_child(_bone_orbit)


func _try_bone_armor(amount: int) -> bool:
	if _bone_orbit == null:
		return false
	var limit := _player.stats.max_health() * _player.equipment.effect_power("bone_armor")
	_bone_orbit.queue_free()
	_bone_orbit = null
	_bone_armor_timer = BONE_ARMOR_PERIOD
	SkillEffects.spark(_player.get_parent(), _player.body_center(), Skeleton.BONE_COLOR, 12)
	Sfx.play_at("rock_break", _player.global_position, -8.0)
	if amount <= limit:
		_player._invulnerable_timer = _player.invulnerability_time
		return true
	return false


## Filakteria Mortana: cios śmiertelny zostawia przy życiu (raz na 90 s).
func _try_undying(amount: int) -> bool:
	if _cooldowns.get("undying", 0.0) > 0.0 or amount < _player.health:
		return false
	var power := _player.equipment.effect_power("undying")
	if power <= 0.0:
		return false
	_cooldowns["undying"] = UNDYING_COOLDOWN
	_player.health = maxi(1, roundi(_player.stats.max_health() * power))
	_player.health_changed.emit(_player.health, _player.stats.max_health())
	_player._invulnerable_timer = 1.5
	DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -16), "Filakteria!", SOUL_COLOR, 10)
	_soul_nova(2.0)
	return true


## Szpony Gnilca: krwawienie - 6 ran po 25% obrażeń broni co pół sekundy.
func _rend(enemy: Goblin) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
		return
	var per_tick := _player.roll_damage(1.5 / REND_TICKS)
	SkillEffects.spark(_player.get_parent(), enemy.hurt_center(), Color(0.8, 0.1, 0.1), 6)
	for i in REND_TICKS:
		get_tree().create_timer(0.5 * (i + 1)).timeout.connect(func() -> void:
			if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
				enemy.take_damage(per_tick, enemy.global_position, 0.0)
				SkillEffects.spark(enemy.get_parent(), enemy.hurt_center(), Color(0.7, 0.05, 0.05), 2))


## Nagolenice Trupojada: koniec uniku miażdży ziemię.
func _corpse_leap(at: Vector2) -> void:
	var power := _player.equipment.effect_power("corpse_leap")
	if power <= 0.0 or _cooldowns.get("corpse_leap", 0.0) > 0.0:
		return
	_cooldowns["corpse_leap"] = 0.8
	var layer := get_tree().get_first_node_in_group("floor_layer")
	SkillEffects.ground_crack(layer if layer != null else _player.get_parent(), at, LEAP_RADIUS * 0.8, 2.0)
	SkillEffects.shockwave(_player.get_parent(), at, LEAP_RADIUS, Color(0.6, 0.75, 0.45))
	Sfx.play_at("rock_break", at, -6.0)
	_player.add_shake(3.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(at) <= LEAP_RADIUS + other.hurt_radius:
			other.take_damage(_player.roll_damage(power), at, 150.0)


## Rzeźnicki Topór: dodatkowe obrażenia w słabnących wrogów (woła Player.hit_enemy przed ciosem).
func execute_bonus(enemy: Goblin) -> int:
	var power := _player.equipment.effect_power("execute")
	if power <= 0.0 or enemy is Boss or enemy.health > enemy.max_health * EXECUTE_THRESHOLD:
		return 0
	return _player.roll_damage(power)


## Paszcza Gnilca: co 5. trafienie stożek żółci w stronę trafionego - trujące kałuże ranią wrogów.
func count_hit(enemy: Goblin) -> void:
	var power := _player.equipment.effect_power("bile_spit")
	if power <= 0.0:
		return
	_hits += 1
	if _hits < BILE_EVERY:
		return
	_hits = 0
	var dir := (enemy.global_position - _player.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var layer := get_tree().get_first_node_in_group("floor_layer")
	Sfx.play_at("spit", _player.global_position, -4.0)
	for i in 3:
		var patch := BurningPatch.new()
		patch.style = "poison"
		patch.radius = 24.0
		patch.life = 3.0
		patch.damage = _player.roll_damage(power)
		patch.hurts_enemies = true
		(layer if layer != null else _player.get_parent()).add_child(patch)
		patch.global_position = _player.global_position + dir.rotated(randf_range(-0.4, 0.4)) * (30.0 + i * 26.0)


# ---------------------------------------------------------------- legendy dawnych bossów
## Skóra Szarokła: widmowy wilk z watahy alfy.
func _pack_call() -> void:
	if _cooldowns.get("pack_call", 0.0) > 0.0 or randf() >= chance("pack_call"):
		return
	_cooldowns["pack_call"] = 4.0
	var wolf := SkeletonAlly.new()
	wolf.player = _player
	wolf.texture = WOLF_TEXTURE
	wolf.vframes = 3
	wolf.idle_frame = 4
	wolf.attack_frames = Vector2i(8, 9)
	wolf.tint = Color(0.65, 0.8, 1.0, 0.85)
	_player.get_parent().add_child(wolf)
	wolf.global_position = _player.global_position + Vector2.from_angle(randf() * TAU) * 20.0
	Sfx.play_at("werewolf_howl", _player.global_position, -10.0)


## Płetwy Bulgora: język przyciąga najbliższego innego wroga do trafionego.
func _tongue(enemy: Goblin, at: Vector2) -> void:
	var best: Goblin = null
	var best_distance := TONGUE_RANGE
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other == enemy:
			continue
		var d := other.global_position.distance_to(at)
		if d < best_distance and d > 20.0:
			best_distance = d
			best = other
	if best == null:
		return
	var line := Line2D.new()
	line.points = PackedVector2Array([at, best.hurt_center()])
	line.width = 4.0
	line.default_color = Color(0.85, 0.35, 0.45)
	line.z_index = 4
	_player.get_parent().add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.25)
	tween.tween_callback(line.queue_free)
	Sfx.play_at("tongue_lash", at, -6.0)
	best.take_damage(_player.roll_damage(0.8), at, 0.0)
	if not best is Boss and best.state != Goblin.State.DEAD:
		best._knockback = (at - best.global_position).normalized() * 360.0


## Żądło Królowej: sieć oplątuje wrogów wokół trafionego.
func _web_burst(at: Vector2) -> void:
	var parent := _player.get_parent()
	for i in 8:
		SkillEffects.spark(parent, at + Vector2.from_angle(TAU * i / 8.0) * WEB_RADIUS * 0.6, Color(0.92, 0.92, 1.0), 2)
	Sfx.play_at("spider_hiss", at, -10.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.hurt_center().distance_to(at) <= WEB_RADIUS + other.hurt_radius:
			other.stun(WEB_HOLD)


## Płaszcz Topielca: fala za unikiem odpycha wrogów od drogi uniku.
func _tidal_dodge(from: Vector2, to: Vector2) -> void:
	var power := _player.equipment.effect_power("tidal_dodge")
	if power <= 0.0 or from.distance_to(to) < 8.0 or _cooldowns.get("tidal_dodge", 0.0) > 0.0:
		return
	_cooldowns["tidal_dodge"] = 0.8
	var dir := from.direction_to(to)
	SkillEffects.tide(_player.get_parent(), from, dir.angle(), 0.7, TIDE_DODGE_RADIUS)
	Sfx.play_at("tide_wave", from, -6.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		var rel := other.global_position - from
		if rel.length() <= TIDE_DODGE_RADIUS + other.hurt_radius and absf(rel.angle_to(dir)) < 1.0:
			other.take_damage(_player.roll_damage(power), from, 280.0)


## Kostur Leszego: stojąc w miejscu ponad 0,8 s, gracz odzyskuje zdrowie (zielone iskry z ziemi).
func _process_rooted_regen(delta: float) -> void:
	var power := _player.equipment.effect_power("rooted_regen")
	if power <= 0.0 or _player.is_dead:
		return
	if _player.velocity.length() > 5.0:
		_still_time = 0.0
		return
	_still_time += delta
	if _still_time < 0.8 or _player.health >= _player.stats.max_health():
		return
	_player.heal(_player.stats.max_health() * power * delta)
	if randf() < delta * 3.0:
		SkillEffects.spark(_player.get_parent(), _player.global_position + Vector2(randf_range(-8, 8), -2), ROOTS_COLOR, 2)


# ---------------------------------------------------------------- legendy Hydry i Gryfa
## Kieł Hydry: padający w pobliżu wróg (także od efektów) może wybuchnąć trucizną.
func on_enemy_died(enemy: Goblin) -> void:
	if _player == null or _player.is_dead or enemy.global_position.distance_to(_player.global_position) > CORPSE_RANGE:
		return
	if _cooldowns.get("corpse_blast", 0.0) > 0.0 or randf() >= chance("corpse_blast"):
		return
	_cooldowns["corpse_blast"] = 0.08
	var at := enemy.global_position
	var parent := _player.get_parent()
	SkillEffects.shockwave(parent, at, CORPSE_RADIUS, POISON_COLOR)
	SkillEffects.spark(parent, at + Vector2(0, -6), POISON_COLOR, 12)
	Sfx.play_at("spit_hit", at, -4.0)
	# obrażenia z opóźnieniem - wybuch nie rani w tej samej klatce, w której wróg padł (łańcuchy wybuchów)
	get_tree().create_timer(0.05).timeout.connect(func() -> void:
		if not is_instance_valid(_player):
			return
		for other: Goblin in get_tree().get_nodes_in_group("enemies"):
			if other.global_position.distance_to(at) <= CORPSE_RADIUS + other.hurt_radius:
				other.take_damage(_player.roll_damage(0.8), at, 120.0)
				poison(other))


## Łuk Siedmiu Głów: ile dodatkowych strzał tropiących.
func extra_seekers() -> int:
	return roundi(_player.equipment.effect_power("hydra_seekers"))


## Księga Gryfiego Płomienia: obrażenia jednego płomienia wieżyczki (0 - kula wybucha normalnie).
func fire_turret_damage(multiplier: float) -> int:
	var power := _player.equipment.effect_power("fire_turret")
	if power <= 0.0:
		return 0
	return maxi(1, _player.roll_damage(multiplier * power))


## Serce Wichru: czy wiatr odbija wrogi pocisk.
func deflects() -> bool:
	return randf() < chance("wind_shield")


## Ostrze Gryfa i Szpony Gryfa: przy zamachu bronią do walki wręcz.
func on_melee_swing(dir: Vector2) -> void:
	var crescent := _player.equipment.effect_power("wind_crescent")
	if crescent > 0.0:
		var wave := LegendFx.WindCrescent.new()
		wave.direction = dir
		wave.damage = _player.roll_damage(crescent)
		_player.get_parent().add_child(wave)
		wave.global_position = _player.global_position + dir * 14.0
	var gather := _player.equipment.effect_power("gather")
	if gather > 0.0:
		var point := _player.global_position + dir * 34.0
		for other: Goblin in get_tree().get_nodes_in_group("enemies"):
			var rel := other.global_position - _player.global_position
			if other is Boss or rel.length() > GATHER_RANGE or rel.length() < 20.0 or absf(rel.angle_to(dir)) > 1.0:
				continue
			other._knockback = (point - other.global_position).normalized() * 260.0 * gather


## Rękawice Jadu: jad na trafionym i dwóch najbliższych wrogach.
func _venom_chain(enemy: Goblin) -> void:
	poison(enemy)
	var others: Array = get_tree().get_nodes_in_group("enemies").filter(func(o) -> bool:
		return o != enemy and o.global_position.distance_to(enemy.global_position) < 90.0)
	others.sort_custom(func(a, b) -> bool:
		return a.global_position.distance_to(enemy.global_position) < b.global_position.distance_to(enemy.global_position))
	for other in others.slice(0, 2):
		SkillEffects.bolt(_player.get_parent(), enemy.hurt_center(), other.hurt_center(), 0.25, 3.0)
		poison(other)


## Grzebień Gryfa: wachlarz piór z trafionego.
func _feather_storm(at: Vector2, echo: bool) -> void:
	var parent := _player.get_parent()
	for i in 10:
		var dir := Vector2.from_angle(TAU * i / 10.0)
		var line := Line2D.new()
		line.points = PackedVector2Array([at + dir * 6.0, at + dir * FEATHER_RADIUS])
		line.width = 2.0
		line.default_color = ECHO_COLOR if echo else Color(1.0, 0.85, 0.45)
		line.z_index = 4
		parent.add_child(line)
		var tween := line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.3)
		tween.tween_callback(line.queue_free)
	Sfx.play_at("wing_gust", at, -8.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.hurt_center().distance_to(at) <= FEATHER_RADIUS + other.hurt_radius:
			other.take_damage(_player.roll_damage(0.7), at, 80.0)


## Bierne efekty Hydry i Gryfa: trująca chmura, odrastanie, żrący ślad, trąby powietrzne.
func _process_hydra_gryf(delta: float) -> void:
	if _player == null or _player.is_dead:
		return
	var equipment := _player.equipment
	var aura := equipment.effect_power("toxic_aura")
	if aura > 0.0 and _aura == null:
		_aura = CPUParticles2D.new()
		_aura.amount = 16
		_aura.lifetime = 1.2
		_aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		_aura.emission_sphere_radius = AURA_RADIUS * 0.8
		_aura.gravity = Vector2(0, -10)
		_aura.initial_velocity_max = 6.0
		_aura.scale_amount_min = 2.0
		_aura.scale_amount_max = 4.0
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([Color(POISON_COLOR, 0.0), Color(POISON_COLOR, 0.35), Color(POISON_COLOR, 0.0)])
		_aura.color_ramp = ramp
		_aura.position = Vector2(0, -6)
		_player.add_child(_aura)
	elif aura <= 0.0 and _aura != null:
		_aura.queue_free()
		_aura = null
	if aura > 0.0:
		_aura_tick -= delta
		if _aura_tick <= 0.0:
			_aura_tick = AURA_TICK
			for other: Goblin in get_tree().get_nodes_in_group("enemies"):
				if other.global_position.distance_to(_player.global_position) <= AURA_RADIUS + other.hurt_radius:
					other.take_damage(_player.roll_damage(aura), _player.global_position, 0.0)
	var regrowth := equipment.effect_power("regrowth")
	if regrowth > 0.0 and _player.health < _player.stats.max_health() * 0.5:
		_player.heal(_player.stats.max_health() * regrowth * delta)
	var moving := _player.velocity.length() > 20.0
	var trail := equipment.effect_power("acid_trail")
	if trail > 0.0 and moving:
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = TRAIL_STEP
			var patch := BurningPatch.new()
			patch.style = "poison"
			patch.radius = 16.0
			patch.life = 2.5
			patch.damage = _player.roll_damage(trail)
			patch.hurts_enemies = true
			var layer := get_tree().get_first_node_in_group("floor_layer")
			(layer if layer != null else _player.get_parent()).add_child(patch)
			patch.global_position = _player.global_position
	var tornado := equipment.effect_power("tornado_walk")
	if tornado > 0.0 and moving:
		_tornado_timer -= delta
		if _tornado_timer <= 0.0:
			_tornado_timer = TORNADO_STEP
			var twister := LegendFx.Tornado.new()
			twister.direction = _player.velocity.normalized()
			twister.damage = _player.roll_damage(tornado)
			_player.get_parent().add_child(twister)
			twister.global_position = _player.global_position
			Sfx.play_at("wing_gust", _player.global_position, -14.0)


# ---------------------------------------------------------------- legendy Faun-Króla
const NOTE_COLOR := Color(1.0, 0.8, 0.35)


## Fletnia Fauna: wrogowie wokół trafionego tańczą (ogłuszeni).
func _dance(at: Vector2) -> void:
	var parent := _player.get_parent()
	for i in 6:
		SkillEffects.spark(parent, at + Vector2.from_angle(TAU * i / 6.0) * 24.0 + Vector2(0, -10), NOTE_COLOR, 2)
	Sfx.play_at("magic", at, -8.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.hurt_center().distance_to(at) <= 50.0 + other.hurt_radius:
			other.stun(2.0)


## Berło Króla Satyrów: fala dźwięku stożkiem przed graczem - rani i płoszy.
func _pan_echo(away: Vector2, echo: bool) -> void:
	var from := _player.global_position
	SkillEffects.tide(_player.get_parent(), from, away.angle(), 0.6, 90.0, echo)
	Sfx.play_at("magic", from, -4.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		var rel := other.global_position - from
		if rel.length() <= 90.0 + other.hurt_radius and absf(rel.angle_to(away)) < 0.7:
			other.take_damage(_player.roll_damage(0.9), from, 120.0)
			other.fear(1.5, from)


## Kopyta Fauna: pnącza oplątują wrogów wokół zranionego gracza.
func _vine_snare() -> void:
	if _cooldowns.get("vine_snare", 0.0) > 0.0 or randf() >= chance("vine_snare"):
		return
	_cooldowns["vine_snare"] = 2.0
	var at := _player.global_position
	SkillEffects.shockwave(_player.get_parent(), at, 64.0, ROOTS_COLOR)
	Sfx.play_at("roots_burst", at, -6.0)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(at) <= 64.0 + other.hurt_radius:
			other.stun(1.5)


## Rogi Króla: unik jako szarża - rani wrogów na drodze i odrzuca ich na boki.
func _horn_charge(from: Vector2, to: Vector2) -> void:
	var power := _player.equipment.effect_power("horn_charge")
	if power <= 0.0 or from.distance_to(to) < 8.0:
		return
	var dir := from.direction_to(to)
	var length := from.distance_to(to)
	for other: Goblin in get_tree().get_nodes_in_group("enemies"):
		var rel := other.global_position - from
		var along := rel.dot(dir)
		if along < -8.0 or along > length + 12.0 or absf(rel.cross(dir)) > 18.0 + other.hurt_radius:
			continue
		var side := signf(rel.cross(dir)) if rel.cross(dir) != 0.0 else 1.0
		other.take_damage(_player.roll_damage(power), other.global_position - dir.orthogonal() * side * 10.0, 220.0)
		SkillEffects.spark(_player.get_parent(), other.hurt_center(), NOTE_COLOR, 4)
