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
## - Strzała Żmija: jadowa strzała przeskakuje między wrogami (Projectile.chain), każdy przeskok mocniejszy, trafieni
##   zatruci.
## - Rozszczepiona Strzała: po pierwszym trafieniu rozpada się na mniejsze strzały lecące dalej wachlarzem.
## - Kolczatka: pole kolców pod kursorem - wrogowie na nim zwalniają i krwawią.
## Węzły kluczowe strony zręczności (krok 5): Łowca w Cieniu (wrogowie, którzy cię nie zauważyli, dostają więcej
## i krytycznie, walczący z tobą mniej), Szał Bitewny (ładunki szybkości za zabójstwa - on_kill). Węzły: Ciche kroki
## (Goblin.notice_factor), Oddech w biegu (regeneracja w biegu), Szereg (Player.row_offsets).
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
## Łowca w Cieniu: mnożnik obrażeń wrogom, którzy cię nie zauważyli (stan IDLE), i tym, którzy z tobą walczą.
const STALKER_UNSEEN := 1.6
const STALKER_FIGHTING := 0.9
## Szał Bitewny: premie za ładunek, najwięcej ładunków, po ilu s bez zabójstwa znikają.
const FRENZY_ATTACK := 0.04
const FRENZY_MOVE := 0.02
const FRENZY_MAX := 10
const FRENZY_TIME := 3.0
## Ciche kroki: potwory w spoczynku zauważają postać z takiej części zwykłej odległości.
const SILENT_NOTICE := 0.5
const RUN_SPEED := 0.15
## Trucizna Jadowych Grotów: ile trwa i co ile rani.
const POISON_TIME := 3.0
const POISON_TICK := 0.5
const FALCON_TEXTURE := preload("res://assets/bow/falcon.png")
const BALLISTA_TEXTURE := preload("res://assets/bow/ballista.png")
## Efekty łuku z kreatora efektów PixelLab (tools/vfx_art.py, pixellab_src/vfx/ids.json - wpisy "bow_*"): smugi strzał
## (zwykła, jadowa, tropiąca, płonąca; rysowane w prawo, punkt zaczepienia w środku strzały), trafienie strzały, wystrzał
## salwy, napinanie i wybuch Grotu Swaroga, znacznik i uderzenia Deszczu Strzał, odbicie Odskoku, Sidła (zastawione
## i zatrzaśnięcie), nurkowanie i szpony Sokoła, jad Jadowych Grotów i podmuch Strzały Wichru.
const TRAIL_ANCHOR := Vector2(36, 8)
const ARROW_TRAIL_FX := preload("res://assets/effects/bow_arrow_trail.png")
const VENOM_TRAIL_FX := preload("res://assets/effects/bow_venom_trail.png")
const SEEKER_TRAIL_FX := preload("res://assets/effects/bow_seeker_trail.png")
const POWER_TRAIL_FX := preload("res://assets/effects/bow_power_trail.png")
const FALCON_DIVE_FX := preload("res://assets/effects/bow_falcon_dive.png")
const ARROW_HIT_FX := preload("res://assets/effects/bow_arrow_hit.png")
const RELEASE_FX := preload("res://assets/effects/bow_bow_release.png")
const POWER_CHARGE_FX := preload("res://assets/effects/bow_power_charge.png")
const POWER_BLAST_FX := preload("res://assets/effects/bow_power_blast.png")
const RAIN_MARK_FX := preload("res://assets/effects/bow_rain_mark.png")
const RAIN_DROP_FX := preload("res://assets/effects/bow_rain_drop.png")
const VAULT_FX := preload("res://assets/effects/bow_vault_burst.png")
const SNARE_IDLE_FX := preload("res://assets/effects/bow_snare_idle.png")
const SNARE_SNAP_FX := preload("res://assets/effects/bow_snare_snap.png")
const FALCON_CLAW_FX := preload("res://assets/effects/bow_falcon_claw.png")
const VENOM_CAST_FX := preload("res://assets/effects/bow_venom_cast.png")
const VENOM_TICK_FX := preload("res://assets/effects/bow_venom_tick.png")
const WIND_FX := preload("res://assets/effects/bow_wind_cone.png")
const DUST_FX := preload("res://assets/effects/lunge_start.png")
## Efekty nowych umiejętności z kreatora efektów PixelLab (pixellab_src/vfx/ids.json, tools/vfx_art.py).
const VIPER_BITE_FX := preload("res://assets/effects/viper_bite.png")
const SPLIT_BURST_FX := preload("res://assets/effects/split_burst.png")
const CALTROPS_FX := preload("res://assets/effects/caltrops_scatter.png")
const FRENZY_FX := preload("res://assets/effects/battle_frenzy.png")
const ICONS := {
	"venom_arrows": preload("res://assets/skills/venom_arrows.png"), "falcon": preload("res://assets/skills/falcon.png"),
	"ballista": preload("res://assets/skills/ballista.png"), "shadow_hunter": preload("res://assets/skills/ks_shadow_hunter.png"),
	"running_fire": preload("res://assets/skills/ks_running_fire.png"),
	"battle_frenzy": preload("res://assets/skills/ks_battle_frenzy.png"),
	"running_breath": preload("res://assets/skills/node_running_breath.png"),
}

var _player: Player
## odnowienia umiejętności: id -> [zostało, całość]
var _cooldowns := {}
## Napinanie Grotu Swaroga: postęp 0..1 (-1 - nie napinamy) i żar na grocie.
var _power_charge := -1.0
var _power_glow: AnimatedSprite2D
var _venom_time := 0.0
var _venom_spread := false
## Zatruci wrogowie: wróg -> [obrażenia na ranę, zostało sekund, do kolejnej rany]
var _poisoned := {}
var _snares: Array[Node2D] = []
var _falcon: _Falcon
## Pełny czas obecnego Sokoła (dłuższy z kamieniem Watażka).
var _falcon_total := Skills.FALCON_TIME
var _ballista: _Ballista
var _shadow_time := 0.0
var _shadow_shot := false
var _running := false
var _caltrops: Array[Node2D] = []
## Szał Bitewny: ładunki i czas do ich zniknięcia.
var _frenzy := 0
var _frenzy_time := 0.0
## Oddech w biegu: czy premia regeneracji jest włączona.
var _breathing := false


func _init(player: Player) -> void:
	_player = player


## Naciśnięty slot umiejętności (trzymanie sprawdza Player.is_skill_held).
func press(id: String) -> void:
	if _player.skills.level_of(id) <= 0:
		_player._hint(Lang.t("Wybierz %s w drzewku umiejętności (K)") % Skills.name_of(id))
		return
	if _cooldowns.get(id, [0.0])[0] > 0.0 or _power_charge >= 0.0 or _player.is_dashing():
		return
	# Szybka salwa: manę (albo combo po Strzale tropiącej) liczy Player.use_followup
	if id == "rapid_volley":
		if _player.use_followup(id):
			_start_cooldown(id, Skills.VOLLEY_COOLDOWN)
		return
	if not _player.spend_mana(_player.skill_mana(id)):
		_player._hint(Lang.t("Za mało many"))
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
		"viper_arrow":
			_viper_arrow()
		"split_arrow":
			_split_arrow()
		"caltrops":
			_scatter_caltrops()


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
	return _player.skills.tree_bonus(stat)


## Węzły kluczowe wspólnego drzewka działają z każdą bronią (tam, gdzie pasują).
func has_keystone(id: String) -> bool:
	return _player.skills.has_keystone(id)


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
	_update_frenzy(delta)
	_update_breath()
	Goblin.notice_factor = SILENT_NOTICE if _bonus("silent_steps") > 0.0 else 1.0
	if _player.is_dead:
		cancel()
		return
	_process_power(delta)


# ---------------------------------------------------------------- Grot Swaroga
func _start_power() -> void:
	_player._cancel_attack()
	_power_charge = 0.0
	if _power_glow == null:
		_power_glow = SkillEffects.looping(POWER_CHARGE_FX, 8, 16.0, Vector2(18, 20))
		_power_glow.z_index = 1
		_player.add_child(_power_glow)
	_power_glow.visible = true
	Sfx.play("swing", -4.0, 0.6)
	# zaraz po Odskoku grot jest od razu w pełni napięty (combo)
	if _player.combo_after("power_shot") == "vault":
		_player.combo_used()
		_power_charge = 1.0
		MiscVfx.spark(_player.get_parent(), _player.body_center() + _player._aim_direction() * 12.0, FIRE_COLOR, 1.0)
		Sfx.play("fireball_full", -6.0, 1.3)


func _process_power(delta: float) -> void:
	if _power_charge < 0.0:
		return
	if _player.stats.weapon_type() != "bow" or _player.is_dashing():
		_stop_power()
		return
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	_power_glow.position = Player.BODY_OFFSET + dir * 12.0
	_power_glow.scale = Vector2.ONE * (0.6 + 0.5 * _power_charge)
	if not _player.is_skill_held("power_shot"):
		var charge := _power_charge
		_stop_power()
		_fire_power(charge)
		return
	var before := _power_charge
	var speed := _player._skill_speed(Skills.tags("power_shot")) * (1.0 + _bonus("power_charge"))
	_power_charge = minf(_power_charge + delta * speed / Skills.POWER_CHARGE_TIME, 1.0)
	if before < 1.0 and _power_charge >= 1.0:
		MiscVfx.spark(_player.get_parent(), _player.body_center() + dir * 12.0, FIRE_COLOR, 1.0)
		Sfx.play("fireball_full", -6.0, 1.3)


func _stop_power() -> void:
	_power_charge = -1.0
	if _power_glow != null:
		_power_glow.visible = false


## Ile napięcia Grotu Swaroga (0..1, -1 - nie napinamy) - dla testów i paska.
func power_charge() -> float:
	return _power_charge


func _fire_power(charge: float) -> void:
	var level := _level("power_shot")
	var dir := _player._aim_direction()
	# zaraz po Strzale tropiącej grot wybucha ogniem przy każdym trafieniu (combo po Odskoku liczy _start_power)
	var combo := _player.combo_after("power_shot") == "seeker"
	if combo:
		_player.combo_used()
	_player.note_skill("power_shot")
	_start_cooldown("power_shot", Skills.POWER_COOLDOWN)
	var multiplier := Skills.power_damage(level) * lerpf(1.0, Skills.POWER_FULL_DAMAGE, charge) * (1.0 + _bonus("power_damage")) \
			* (_player.combo_damage() if combo else 1.0)
	# Rozszczep (kamień wsparcia): dodatkowe groty wachlarzem
	var shots: Array[Vector2] = []
	var sides: Array[float] = []
	for shot: Vector2 in Player.split_directions(dir, _player.support_count("power_shot", "projectiles")):
		for side: float in _player.row_offsets(shot == dir):
			shots.append(shot)
			sides.append(side)
	for n in shots.size():
		var shot := shots[n]
		var arrow := _player._make_projectile(_player.equipment.weapon(), shot, "power_shot")
		arrow.position += shot.orthogonal() * sides[n]
		arrow.damage_min = maxi(1, roundi(arrow.damage_min * multiplier))
		arrow.damage_max = maxi(1, roundi(arrow.damage_max * multiplier))
		arrow.pierce += Skills.power_pierce(level)
		arrow.speed = 520.0
		arrow.max_range *= 1.4
		arrow.knockback = 120.0
		arrow.size = lerpf(1.0, 1.5, charge)
		arrow.modulate = Color(1.5, 1.05, 0.6)
		var plain := arrow.get_node_or_null("Trail")
		if plain != null:
			arrow.remove_child(plain)
			plain.queue_free()
		var fire_trail := arrow_trail(POWER_TRAIL_FX, shot)
		fire_trail.scale = Vector2.ONE * lerpf(1.0, 1.4, charge)
		arrow.add_child(fire_trail)
		if combo:
			arrow.enemy_hit.connect(func(enemy: Goblin) -> void: _fire_blast(enemy.hurt_center(), multiplier * 0.5))
		_player.get_parent().add_child(arrow)
	Sfx.play("bow", 3.0, lerpf(0.9, 0.7, charge))
	_player.add_shake(1.0 + 2.0 * charge)


func _fire_blast(at: Vector2, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	SkillEffects.sheet_once(_player.get_parent(), POWER_BLAST_FX, 7, 16.0, at, Vector2(28, 28), 0.0, 1.0,
			Skills.POWER_EXPLOSION / 25.0)
	Sfx.play_at("explosion", at, -8.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.hurt_center().distance_to(at) <= Skills.POWER_EXPLOSION + enemy.hurt_radius:
			_player.hit_enemy(enemy, _player._skill_damage(multiplier, Skills.tags("power_shot")), at, 60.0, "fire", Skills.tags("power_shot"))


# ---------------------------------------------------------------- Deszcz Strzał
func _arrow_rain() -> void:
	var level := _level("arrow_rain")
	_start_cooldown("arrow_rain", Skills.RAIN_COOLDOWN)
	# zaraz po Salwie pada dwa razy gęściej; zaraz po Sidłach strzały spadają też na unieruchomionych wrogów
	var after := _player.combo_after("arrow_rain")
	var combo := after == "multishot"
	if after != "":
		_player.combo_used()
	_player.note_skill("arrow_rain")
	var at := _aim_point(Skills.RAIN_RANGE)
	_player._ranged_pose((at - _player.global_position).normalized() if at != _player.global_position else Vector2.UP)
	var hail := has_keystone("hail")
	var rain := _Rain.new()
	rain.player = _player
	rain.position = at
	rain.radius = Skills.RAIN_RADIUS * (1.0 + _bonus("rain_area")) * _player.stats.area_multiplier(Skills.tags("arrow_rain"))
	rain.tick = Skills.RAIN_TICK / (2.0 if combo else 1.0) / (HAIL_DENSITY if hail else 1.0)
	rain.damage = Skills.rain_damage(level) * (1.0 + _bonus("rain_damage")) * (HAIL_DAMAGE if hail else 1.0) \
			* (_player.combo_damage() if combo else 1.0)
	rain.time_left = Skills.RAIN_TIME
	rain.focus = after == "snare"
	_player.get_parent().add_child(rain)
	Sfx.play("bow", 0.0, 0.7)


# ---------------------------------------------------------------- Odskok
func _vault() -> void:
	var level := _level("vault")
	_start_cooldown("vault", Skills.VAULT_COOLDOWN * (1.0 + _bonus("vault_cooldown")))
	var dir := _player._aim_direction()
	SkillEffects.sheet_once(_player.get_parent(), VAULT_FX, 10, 14.0, _player.global_position, Vector2(23, 24))
	_player.leap(-dir, Skills.VAULT_TIME)
	_player.note_skill("vault")
	var weapon := _player.equipment.weapon()
	var spread := deg_to_rad(Skills.VAULT_SPREAD_DEGREES)
	var multiplier := Skills.vault_damage(level)
	var count := Skills.VAULT_ARROWS + _player.support_count("vault", "projectiles")
	spread *= sqrt(count / float(Skills.VAULT_ARROWS))
	for i in count:
		var shot := dir.rotated(lerpf(-spread / 2.0, spread / 2.0, float(i) / (count - 1)))
		for side: float in _player.row_offsets(i == count / 2):
			var arrow := _player._make_projectile(weapon, shot, "vault")
			arrow.position += shot.orthogonal() * side
			arrow.damage_min = maxi(1, roundi(arrow.damage_min * multiplier))
			arrow.damage_max = maxi(1, roundi(arrow.damage_max * multiplier))
			_player.get_parent().add_child(arrow)
	release(_player.get_parent(), _player.body_center() + dir * 6.0, dir.angle(), 0.85)
	Sfx.play("bow", 0.0, 1.1)


## Myśliwy z Cienia: po każdej umiejętności ruchu (tag "movement" - Szarża, Mgnienie, Odskok, Krok przez Mgłę)
## wrogowie na chwilę tracą gracza z oczu, a pierwsze trafienie jest podwójne (Player.note_skill).
func on_movement() -> void:
	if has_keystone("shadow_hunter"):
		_shadow_time = SHADOW_TIME
		_shadow_shot = true
		Goblin.hidden_until = Time.get_ticks_msec() + roundi(SHADOW_TIME * 1000.0)
		MiscVfx.puff(_player.get_parent(), _player.body_center(), Color(0.3, 0.3, 0.4), 0.7)


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
	SkillEffects.sheet_once(_player.get_parent(), SNARE_SNAP_FX, 12, 18.0, at, Vector2(17, 23))
	Sfx.play_at("hit_heavy", at, -2.0)
	var tags := Skills.tags("snare")
	var radius := Skills.SNARE_RADIUS * _player.stats.area_multiplier(tags)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(at) > radius + enemy.hurt_radius:
			continue
		enemy.set_meta("snared_until", Time.get_ticks_msec() + roundi(hold * 1000.0))
		_player.hit_enemy(enemy, _player._skill_damage(Skills.snare_damage(level), tags), at, 0.0, "", tags)
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
	# Watażka (kamień wsparcia przywołań): dłużej
	_falcon_total = Skills.FALCON_TIME * (1.0 + _player.support("falcon", "duration"))
	_falcon.time_left = _falcon_total
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
	SkillEffects.sheet_once(_player.get_parent(), VENOM_CAST_FX, 10, 16.0, _player.global_position, Vector2(28, 28))
	Sfx.play("potion", -2.0, 0.8)


## Zatrucie wroga: `total` obrażeń rozłożone na POISON_TIME s (nowe zatrucie odświeża i bierze mocniejsze).
func poison(enemy: Goblin, total: float) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
		return
	var per_tick := maxf(total * POISON_TICK / POISON_TIME, 1.0)
	var entry: Array = _poisoned.get(enemy, [0.0, 0.0, POISON_TICK])
	_poisoned[enemy] = [maxf(entry[0], per_tick), POISON_TIME, entry[2]]


## Czy trwają Jadowe Groty (strzały zatruwają - zielona smuga strzał).
func venom_active() -> bool:
	return _venom_time > 0.0


func is_poisoned(enemy: Goblin) -> bool:
	return _poisoned.has(enemy)


func _process_poison(delta: float) -> void:
	# klucz bez typu: zabity potwór jest już zwolniony, a przypisanie go do zmiennej Goblin to błąd
	for key in _poisoned.keys():
		if not is_instance_valid(key) or (key as Goblin).state == Goblin.State.DEAD:
			_poisoned.erase(key)
			continue
		var enemy: Goblin = key
		var entry: Array = _poisoned[enemy]
		entry[1] -= delta
		entry[2] -= delta
		if entry[2] <= 0.0:
			entry[2] += POISON_TICK
			enemy.take_damage(roundi(entry[0]), enemy.global_position, 0.0)
			SkillEffects.sheet_once(enemy.get_parent(), VENOM_TICK_FX, 6, 14.0, enemy.hurt_center(), Vector2(8, 17))
		if entry[1] <= 0.0:
			_poisoned.erase(enemy)


# ---------------------------------------------------------------- Strzała Wichru
func _wind_arrow() -> void:
	_start_cooldown("wind_arrow", Skills.WIND_COOLDOWN)
	# zaraz po Odskoku stożek jest dwa razy szerszy; zaraz po Sokole ptak też rzuca podmuch ze swojego miejsca
	var after := _player.combo_after("wind_arrow")
	var combo := after == "vault"
	if after != "":
		_player.combo_used()
	_player.note_skill("wind_arrow")
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	_wind_gust(dir, combo)
	_player.support_echo("wind_arrow", func() -> void: _wind_gust(_player._aim_direction(), combo))
	if after == "falcon" and is_instance_valid(_falcon):
		var from := _falcon.global_position
		_wind_gust((_cursor() - from).normalized(), false, from)


## Podmuch Strzały Wichru (bez many i odnowienia - powtarza go też Echo Rusałki). `from` - skąd wieje
## (INF - od postaci; combo po Sokole - z miejsca sokoła).
func _wind_gust(dir: Vector2, combo: bool, from := Vector2.INF) -> void:
	var from_player := not from.is_finite()
	if from_player:
		_player._ranged_pose(dir)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var tags := Skills.tags("wind_arrow")
	var reach := Skills.WIND_RANGE * _player.stats.area_multiplier(tags)
	var origin := _player.body_center() if from_player else from
	var half := deg_to_rad(Skills.WIND_HALF_ANGLE) * (2.0 if combo else 1.0)
	# podmuch narysowany na stożek 2x28 stopni; w combo (dwa razy szerszy) - trzy podmuchy wachlarzem
	var gusts := [0.0] if not combo else [-half / 2.0, 0.0, half / 2.0]
	for turn: float in gusts:
		SkillEffects.sheet_once(_player.get_parent(), WIND_FX, 9, 18.0, origin, Vector2(4, 53), dir.angle() + turn, 1.0,
				reach / 104.0)
	Sfx.play("whirl", 2.0, 1.3)
	var multiplier := Skills.wind_damage(_level("wind_arrow")) * (1.0 + _bonus("wind_damage")) * (_player.combo_damage() if combo else 1.0)
	for enemy: Goblin in _player.get_tree().get_nodes_in_group("enemies"):
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > reach + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(dir.angle(), to_enemy.angle())) > half:
			continue
		_player.hit_enemy(enemy, _player._skill_damage(multiplier, tags), origin, Skills.WIND_KNOCKBACK, "", tags)
		MiscVfx.spark(_player.get_parent(), enemy.hurt_center(), WIND_COLOR, 0.5)


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
	_ballista.time_left = Skills.BALLISTA_TIME * (1.0 + _bonus("ballista_time") + _player.support("ballista", "duration"))
	_ballista.total = _ballista.time_left
	_ballista.interval = Skills.BALLISTA_INTERVAL / _player._skill_speed(Skills.tags("ballista"))
	_ballista.position = _aim_point(Skills.BALLISTA_PLACE)
	_player.get_parent().add_child(_ballista)
	SkillEffects.sheet_once(_player.get_parent(), DUST_FX, 7, 14.0, _ballista.position, Vector2(21, 12))
	Sfx.play("anvil", -6.0, 1.4)


func ballista() -> Node2D:
	return _ballista if is_instance_valid(_ballista) else null


# ---------------------------------------------------------------- Strzała Żmija
func _viper_arrow() -> void:
	var level := _level("viper_arrow")
	_start_cooldown("viper_arrow", Skills.VIPER_COOLDOWN)
	_player.note_skill("viper_arrow")
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	var multiplier := Skills.viper_damage(level)
	for shot: Vector2 in Player.split_directions(dir, _player.support_count("viper_arrow", "projectiles")):
		for side: float in _player.row_offsets(shot == dir):
			_launch_viper(shot, side, multiplier)
	release(_player.get_parent(), _player.body_center() + dir * 6.0, dir.angle(), 0.8)
	Sfx.play("bow", 0.0, 1.2)


## Jedna Strzała Żmija: przeskakuje (Projectile.chain) do VIPER_JUMPS razy, po każdym trafieniu obrażenia rosną
## o VIPER_GROWTH, a trafiony zostaje zatruty.
func _launch_viper(dir: Vector2, side: float, multiplier: float) -> void:
	var arrow := _player._make_projectile(_player.equipment.weapon(), dir, "viper_arrow")
	arrow.position += dir.orthogonal() * side
	var base_min := arrow.damage_min * multiplier
	var base_max := arrow.damage_max * multiplier
	arrow.damage_min = maxi(1, roundi(base_min))
	arrow.damage_max = maxi(1, roundi(base_max))
	arrow.chain += Skills.VIPER_JUMPS
	arrow.chain_range = Skills.VIPER_RANGE
	arrow.speed *= 1.15
	arrow.modulate = Color(0.8, 1.25, 0.7)
	var plain := arrow.get_node_or_null("Trail")
	if plain != null:
		arrow.remove_child(plain)
		plain.queue_free()
	arrow.add_child(arrow_trail(VENOM_TRAIL_FX, dir))
	var hits: Array[int] = [0]
	var poison_factor := Skills.VIPER_POISON * (1.0 + _bonus("venom_damage") + _player.support("viper_arrow", "dot_damage"))
	arrow.enemy_hit.connect(func(enemy: Goblin) -> void:
		hits[0] += 1
		var growth: float = 1.0 + Skills.VIPER_GROWTH * hits[0]
		arrow.damage_min = maxi(1, roundi(base_min * growth))
		arrow.damage_max = maxi(1, roundi(base_max * growth))
		poison(enemy, (base_min + base_max) * 0.5 * (growth - Skills.VIPER_GROWTH) * poison_factor)
		SkillEffects.sheet_once(arrow.get_parent(), VIPER_BITE_FX, 8, 16.0, enemy.hurt_center(), Vector2(17, 14)))
	_player.get_parent().add_child(arrow)


# ---------------------------------------------------------------- Rozszczepiona Strzała
func _split_arrow() -> void:
	var level := _level("split_arrow")
	_start_cooldown("split_arrow", Skills.SPLIT_COOLDOWN)
	_player.note_skill("split_arrow")
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	for shot: Vector2 in Player.split_directions(dir, _player.support_count("split_arrow", "projectiles")):
		for side: float in _player.row_offsets(shot == dir):
			var arrow := _player._make_projectile(_player.equipment.weapon(), shot, "split_arrow")
			arrow.position += shot.orthogonal() * side
			var multiplier := Skills.split_damage(level)
			var shard := Skills.split_shard_damage(level)
			var weapon_min := arrow.damage_min
			var weapon_max := arrow.damage_max
			arrow.damage_min = maxi(1, roundi(weapon_min * multiplier))
			arrow.damage_max = maxi(1, roundi(weapon_max * multiplier))
			arrow.size = 1.2
			arrow.speed *= 1.1
			var split: Array[bool] = [false]
			arrow.enemy_hit.connect(func(enemy: Goblin) -> void:
				if split[0]:
					return
				split[0] = true
				_split_shards(enemy, arrow.direction, roundi(weapon_min * shard), roundi(weapon_max * shard)))
			_player.get_parent().add_child(arrow)
	release(_player.get_parent(), _player.body_center() + dir * 6.0, dir.angle(), 0.9)
	Sfx.play("bow", 1.0, 0.95)


## Rozpad strzały na trafionym wrogu: SPLIT_SHARDS mniejszych strzał wachlarzem dalej w kierunku lotu (omijają tego wroga).
func _split_shards(enemy: Goblin, dir: Vector2, damage_min: int, damage_max: int) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(enemy):
		return
	var at := enemy.global_position
	SkillEffects.sheet_once(_player.get_parent(), SPLIT_BURST_FX, 7, 16.0, enemy.hurt_center(), Vector2(13, 17), dir.angle())
	Sfx.play_at("hit_arrow", at, -4.0)
	var spread := deg_to_rad(Skills.SPLIT_SPREAD_DEGREES)
	var count := Skills.SPLIT_SHARDS
	for i in count:
		var shot := dir.rotated(lerpf(-spread / 2.0, spread / 2.0, float(i) / (count - 1)))
		var arrow := _player._make_projectile(_player.equipment.weapon(), shot, "split_arrow")
		arrow.position = at + shot * 4.0
		arrow.damage_min = maxi(1, damage_min)
		arrow.damage_max = maxi(1, damage_max)
		arrow.max_range = Skills.SPLIT_RANGE
		arrow.size = Skills.SPLIT_SIZE
		arrow.knockback = 30.0
		arrow.ignore(enemy)
		_player.get_parent().add_child(arrow)


# ---------------------------------------------------------------- Kolczatka
func _scatter_caltrops() -> void:
	_start_cooldown("caltrops", Skills.CALTROPS_COOLDOWN)
	_player.note_skill("caltrops")
	_caltrops = _caltrops.filter(func(c: Node2D) -> bool: return is_instance_valid(c))
	while _caltrops.size() >= Skills.CALTROPS_MAX:
		_caltrops.pop_front().queue_free()
	var tags := Skills.tags("caltrops")
	var field := _Caltrops.new()
	field.player = _player
	field.radius = Skills.CALTROPS_RADIUS * _player.stats.area_multiplier(tags)
	field.time_left = Skills.CALTROPS_TIME * (1.0 + _player.support("caltrops", "duration"))
	field.damage = Skills.caltrops_damage(_level("caltrops")) * (1.0 + _bonus("bleed_damage") + _player.support("caltrops", "dot_damage"))
	field.position = _aim_point(Skills.CALTROPS_RANGE)
	var layer := _player.get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else _player.get_parent()).add_child(field)
	_caltrops.append(field)
	_player._ranged_pose(_player._aim_direction())
	SkillEffects.sheet_once(_player.get_parent(), CALTROPS_FX, 12, 14.0, field.position, Vector2(16, 13), 0.0, 1.0,
			field.radius / Skills.CALTROPS_RADIUS)
	Sfx.play("swing", -2.0, 1.6)


## Pole kolców: rysowane w kodzie kolce w kręgu; co CALTROPS_TICK s rani (krwawienie) i spowalnia wrogów w środku.
class _Caltrops extends Node2D:
	var player: Player
	var radius := 38.0
	var time_left := 6.0
	var damage := 0.3
	var _tick := 0.0
	var _spikes: Array[Vector3] = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(position)
		for i in 26:
			var at := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * radius
			_spikes.append(Vector3(at.x, at.y * 0.8, rng.randf() * TAU))

	func _physics_process(delta: float) -> void:
		time_left -= delta
		if time_left <= 0.0 or not is_instance_valid(player):
			queue_free()
			return
		modulate.a = clampf(time_left / 0.5, 0.0, 1.0)
		_tick -= delta
		if _tick > 0.0:
			return
		_tick = Skills.CALTROPS_TICK
		var tags := Skills.tags("caltrops")
		var amount := player._skill_damage(damage, tags)
		for enemy: Goblin in Goblin.near(get_tree(), global_position, radius + 30.0):
			if enemy.state == Goblin.State.DEAD or enemy.global_position.distance_to(global_position) > radius + enemy.hurt_radius * 0.5:
				continue
			enemy.chill(Skills.CALTROPS_SLOW, Skills.CALTROPS_TICK + 0.2)
			player.hit_enemy(enemy, amount, enemy.global_position, 0.0, "", tags)
			if randf() < 0.35:
				MiscVfx.spark(get_parent(), enemy.global_position + Vector2(0, -3), Color(0.75, 0.1, 0.1), 0.35)

	## Kolec: trzy ramiona w cieniu na ziemi, czwarte sterczy w górę z jasnym czubkiem.
	func _draw() -> void:
		for spike: Vector3 in _spikes:
			var at := Vector2(spike.x, spike.y)
			draw_circle(at + Vector2(0.5, 1.0), 2.5, Color(0, 0, 0, 0.25))
			for k in 3:
				var tip := at + Vector2.from_angle(spike.z + k * TAU / 3.0) * Vector2(4.0, 2.5)
				draw_line(at, tip, Color(0.2, 0.2, 0.24), 1.5)
			draw_line(at, at + Vector2(0, -4), Color(0.45, 0.46, 0.52), 1.5)
			draw_rect(Rect2(at + Vector2(-0.5, -4.5), Vector2(1, 1)), Color(0.85, 0.86, 0.9))


# ---------------------------------------------------------------- trafienia i węzły kluczowe
## Mnożnik obrażeń trafienia (z każdą bronią): Myśliwy z Cienia (pierwsze po umiejętności ruchu podwójne), Oko Sokoła (bliskie słabsze).
func damage_factor(enemy: Goblin) -> float:
	var factor := 1.0
	if _shadow_shot:
		_shadow_shot = false
		factor *= 2.0
	if has_keystone("falcon_eye") and enemy.global_position.distance_to(_player.global_position) <= FALCON_EYE_NEAR:
		factor *= FALCON_EYE_WEAK
	if has_keystone("shadow_stalker"):
		factor *= STALKER_UNSEEN if unseen(enemy) else STALKER_FIGHTING
	return factor


## Łowca w Cieniu: wróg jeszcze cię nie zauważył (stoi w spoczynku albo wraca na swoje miejsce).
static func unseen(enemy: Goblin) -> bool:
	return enemy.state == Goblin.State.IDLE or enemy.state == Goblin.State.RETURN


## Cios musi być krytyczny: wróg w Sidłach albo daleki (Oko Sokoła).
func forced_crit(enemy: Goblin) -> bool:
	if is_snared(enemy):
		return true
	if has_keystone("shadow_stalker") and unseen(enemy):
		return true
	return has_keystone("falcon_eye") and enemy.global_position.distance_to(_player.global_position) >= FALCON_EYE_FAR


## Po trafieniu z łukiem: Jadowe Groty zatruwają (w combo jad przeskakuje na wrogów obok).
func on_hit(enemy: Goblin, amount: int) -> void:
	if _venom_time <= 0.0:
		return
	var total := amount * Skills.venom_damage(_level("venom_arrows")) * (1.0 + _bonus("venom_damage") + _player.support("venom_arrows", "dot_damage"))
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


## Szał Bitewny: zabójstwo (Goblin._die - z każdą bronią, także od jadu i krwawienia) dokłada ładunek.
func on_kill() -> void:
	if not has_keystone("battle_frenzy") or _player.is_dead:
		return
	_frenzy = mini(_frenzy + 1, FRENZY_MAX)
	_frenzy_time = FRENZY_TIME
	_apply_frenzy()
	SkillEffects.sheet_once(_player, FRENZY_FX, 8, 16.0, Vector2(0, -10), Vector2(20, 17), 0.0, 1.0,
			0.6 + 0.04 * _frenzy).modulate.a = 0.8


func frenzy_charges() -> int:
	return _frenzy


func _update_frenzy(delta: float) -> void:
	if _frenzy <= 0:
		return
	_frenzy_time -= delta
	if _frenzy_time <= 0.0 or not has_keystone("battle_frenzy") or _player.is_dead:
		_frenzy = 0
		_apply_frenzy()


func _apply_frenzy() -> void:
	_player.stats.set_temp("frenzy", {} if _frenzy <= 0 else
			{"attack_speed": FRENZY_ATTACK * _frenzy, "move_speed": FRENZY_MOVE * _frenzy})


## Oddech w biegu (węzeł): regeneracja zdrowia, dopóki postać biegnie.
func _update_breath() -> void:
	var regen := _bonus("running_breath")
	var breathing := regen > 0.0 and not _player.is_dead and _player._move_velocity.length() > 20.0
	if breathing != _breathing:
		_breathing = breathing
		_player.stats.set_temp("running_breath", {"health_regen": regen} if breathing else {})


## Efekty do rzędu ikon pod paskami zdrowia i many.
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _frenzy > 0:
		result.append({"name": Lang.t("Szał Bitewny"), "kind": "good", "left": _frenzy_time, "total": FRENZY_TIME, "icon": ICONS["battle_frenzy"],
				"description": Lang.t("%d ładunków: +%d%% szybkości ataku, +%d%% szybkości ruchu") % [_frenzy,
						roundi(FRENZY_ATTACK * _frenzy * 100.0), roundi(FRENZY_MOVE * _frenzy * 100.0)]})
	if _breathing:
		result.append({"name": Lang.t("Oddech w biegu"), "kind": "good", "left": -1.0, "icon": ICONS["running_breath"],
				"description": Lang.t("+%s regeneracji zdrowia/s w biegu") % str(roundi(_bonus("running_breath")))})
	if _venom_time > 0.0:
		result.append({"name": Lang.t("Jadowe Groty"), "kind": "good", "left": _venom_time, "total": Skills.VENOM_TIME, "icon": ICONS["venom_arrows"],
				"description": Lang.t("Strzały zatruwają wrogów - jad przeskakuje na wrogów obok") if _venom_spread else Lang.t("Strzały zatruwają wrogów")})
	if is_instance_valid(_falcon) and not _falcon.leaving:
		result.append({"name": Lang.t("Sokół"), "kind": "good", "left": _falcon.time_left, "total": _falcon_total, "icon": ICONS["falcon"],
				"description": Lang.t("Sokół krąży nad tobą i atakuje wrogów")})
	if is_instance_valid(_ballista) and not _ballista.leaving:
		result.append({"name": Lang.t("Balista"), "kind": "good", "left": _ballista.time_left, "total": _ballista.total, "icon": ICONS["ballista"],
				"description": Lang.t("Balista strzela w najbliższych wrogów")})
	if _shadow_time > 0.0:
		result.append({"name": Lang.t("Myśliwy z Cienia"), "kind": "good", "left": _shadow_time, "total": SHADOW_TIME, "icon": ICONS["shadow_hunter"],
				"description": Lang.t("Wrogowie cię nie widzą, pierwsze trafienie podwójne") if _shadow_shot else Lang.t("Wrogowie cię nie widzą")})
	if _running:
		result.append({"name": Lang.t("Strzelanie w biegu"), "kind": "good", "left": -1.0, "icon": ICONS["running_fire"],
				"description": Lang.t("+%d%% szybkości ataku w biegu") % roundi(RUN_SPEED * 100.0)})
	return result


## Smuga za strzałą (zapętlona, na wysokości lotu, obrócona w kierunku lotu) - węzeł "Trail" pocisku.
static func arrow_trail(texture: Texture2D, dir: Vector2) -> AnimatedSprite2D:
	var trail := SkillEffects.looping(texture, 4, 16.0, TRAIL_ANCHOR)
	trail.name = "Trail"
	trail.position = Vector2(0, -Projectile.HEIGHT)
	trail.rotation = dir.angle()
	trail.z_index = -1
	return trail


## Trafienie strzały: błysk wzdłuż lotu i drzazgi.
static func arrow_hit(parent: Node, at: Vector2, angle: float) -> void:
	SkillEffects.sheet_once(parent, ARROW_HIT_FX, 5, 18.0, at, Vector2(16, 14), angle)


## Wystrzał (salwa, odskok, balista): wachlarz smug i fala powietrza przed łukiem.
static func release(parent: Node, at: Vector2, angle: float, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, RELEASE_FX, 6, 18.0, at, Vector2(3, 21), angle, 1.0, size)


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
	## Combo po Sidłach: strzały spadają też na unieruchomionych wrogów do Skills.RAIN_FOCUS_REACH promieni od środka.
	var focus := false
	var _next := 0.0
	var _fade := 0.3
	## spadające strzały: [punkt na ziemi, postęp 0..1]
	var _drops: Array = []
	var _mark: AnimatedSprite2D

	func _ready() -> void:
		z_index = 3
		# znacznik celu narysowany na promień 56 (spłaszczony jak rzut z góry)
		_mark = SkillEffects.looping(BowSkills.RAIN_MARK_FX, 8, 10.0, Vector2(62, 38))
		_mark.scale = Vector2.ONE * (radius / 56.0)
		_mark.show_behind_parent = true
		add_child(_mark)

	func _process(delta: float) -> void:
		queue_redraw()
		for i in range(_drops.size() - 1, -1, -1):
			_drops[i][1] += delta / DROP_TIME
			if _drops[i][1] >= 1.0:
				SkillEffects.sheet_once(get_parent(), BowSkills.RAIN_DROP_FX, 5, 16.0,
						global_position + _drops[i][0] * Vector2(1.0, 0.6), Vector2(14, 13))
				_drops.remove_at(i)
		if time_left <= 0.0:
			_fade -= delta
			_mark.modulate.a = maxf(_fade / 0.3, 0.0)
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
		var focus_reach := radius * Skills.RAIN_FOCUS_REACH
		for enemy: Goblin in player.get_tree().get_nodes_in_group("enemies"):
			var distance := enemy.global_position.distance_to(global_position)
			var inside := distance <= radius + enemy.hurt_radius
			# unieruchomiony wróg poza kręgiem - strzała spada prosto na niego
			if not inside and focus and distance <= focus_reach and BowSkills.is_snared(enemy):
				inside = true
				_drops.append([(enemy.global_position - global_position) / Vector2(1.0, 0.6), 0.0])
			if inside:
				player.hit_enemy(enemy, player._skill_damage(damage, Skills.tags("arrow_rain")), enemy.global_position + Vector2(0, -20), 10.0,
						"", Skills.tags("arrow_rain"))
		Sfx.play_at("hit", global_position, -14.0)

	func _draw() -> void:
		for drop: Array in _drops:
			var ground: Vector2 = drop[0] * Vector2(1.0, 0.6)
			var fall: float = drop[1]
			var tip := ground + Vector2(4.0, -FALL) * (1.0 - fall)
			# lotki, ciemne drzewce i jasny grot - widoczne na trawie i na ziemi
			draw_line(tip + Vector2(3.0, -14.0), tip + Vector2(2.6, -12.0), Color(0.95, 0.95, 0.9), 2.0)
			draw_line(tip + Vector2(2.6, -12.0), tip, Color(0.3, 0.2, 0.12), 1.5)
			draw_line(tip + Vector2(0.4, -2.0), tip, Color(1.0, 1.0, 1.0), 2.0)


## Sidła: leżą zastawione (zapętlona pętla z pnączy), aż wróg na nie wejdzie - wtedy się zatrzaskują
## (BowSkills.spring_snare - pnącza oplatają wrogów) i po chwili znikają.
class _Snare:
	extends AnimatedSprite2D

	var skills: BowSkills
	var _life := Skills.SNARE_LIFETIME
	var _check := 0.0
	var _sprung := false

	func _ready() -> void:
		var loop := SkillEffects.looping(BowSkills.SNARE_IDLE_FX, 8, 8.0, Vector2(16, 12))
		sprite_frames = loop.sprite_frames
		centered = false
		offset = loop.offset
		loop.free()
		play("default")
		z_index = -1
		MiscVfx.puff(get_parent(), global_position, Color(0.8, 0.8, 0.85), 0.35)

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
		skills.spring_snare(global_position)
		_life = minf(_life, 0.15)

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
	## smuga wiatru i piór za sokołem w trakcie nurkowania
	var _dive_fx: AnimatedSprite2D

	func _ready() -> void:
		z_index = 6
		_dive_fx = SkillEffects.looping(BowSkills.FALCON_DIVE_FX, 4, 16.0, BowSkills.TRAIL_ANCHOR + Vector2(4, 0))
		_dive_fx.visible = false
		add_child(_dive_fx)
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
		if _dive_fx != null:
			_dive_fx.visible = false

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
		_dive_fx.visible = _target != null
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
			player.hit_enemy(_target, player._skill_damage(damage * _strength, Skills.tags("falcon")), global_position, 40.0, "", Skills.tags("falcon"))
			SkillEffects.sheet_once(get_parent(), BowSkills.FALCON_CLAW_FX, 8, 16.0, _target.hurt_center(), Vector2(19, 13),
					0.0, 1.0, 1.0, 0.0, to.x < 0.0)
			Sfx.play_at("hit", global_position, -4.0)
			_target = null
			_strength = 1.0
			_cooldown = Skills.FALCON_INTERVAL
			return
		_velocity = to.normalized() * DIVE_SPEED
		position += _velocity * delta
		_face(_velocity)
		_dive_fx.rotation = _velocity.angle()

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
	## Ile salw już oddała (do testów).
	var shots := 0
	var _next := 0.3
	var _sprite: Sprite2D

	func _ready() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = BowSkills.BALLISTA_TEXTURE
		_sprite.scale = Vector2.ONE * 0.6
		_sprite.offset = Vector2(0, -BowSkills.BALLISTA_TEXTURE.get_height() / 2.0 + 4.0)
		add_child(_sprite)
		MiscVfx.puff(get_parent(), global_position, Color(0.85, 0.7, 0.5), 0.6)
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
		var kind := player.stats.kind_multiplier(Skills.tags("ballista"))
		var low := maxi(1, roundi(player.stats.damage_min() * damage * kind))
		var high := maxi(1, roundi(player.stats.damage_max() * damage * kind))
		var seekers := roundi(player.equipment.effect_power("ballista_seeker"))
		var volley := roundi(player.equipment.effect_power("ballista_volley"))
		var count := 1 + volley + player.support_count("ballista", "projectiles")
		shots += 1
		for i in count:
			var side := 0.0 if count == 1 else lerpf(-0.25, 0.25, float(i) / (count - 1))
			if seekers > 0:
				var arrow := SeekerArrow.new()
				arrow.position = global_position + dir * 8.0
				arrow.velocity = dir.rotated(side) * SeekerArrow.SPEED
				arrow.hits_left = seekers
				arrow.damage_min = low
				arrow.damage_max = high
				arrow.tags = Skills.tags("ballista")
				get_parent().add_child(arrow)
			elif weapon.has("projectile"):
				var bolt := player._make_projectile(weapon, dir.rotated(side), "ballista")
				bolt.position = global_position + dir.rotated(side) * 8.0
				bolt.damage_min = low
				bolt.damage_max = high
				bolt.speed = 460.0
				bolt.size = 1.3
				bolt.pierce += 1
				bolt.max_range = Skills.BALLISTA_RANGE * 1.3
				get_parent().add_child(bolt)
		Sfx.play_at("bow", global_position, -2.0)
		BowSkills.release(get_parent(), muzzle() + dir * 6.0, dir.angle(), 0.7)
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
