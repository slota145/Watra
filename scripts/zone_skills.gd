class_name ZoneSkills
extends Node
## Umiejętności i węzły stref pośrednich wspólnego drzewka (krok 5) - dziecko gracza, jak SwordSkills, BowSkills
## i SpellSkills. Umiejętności działają z jedną z dwóch broni i z każdą wyglądają trochę inaczej (Skills.HYBRID_TAGS):
## - Ciśnięte Noże (miecz albo łuk): wachlarz noży z krwawieniem; z mieczem noże wracają do ręki i trafiają drugi raz
##   (klasa _Knife), z łukiem lecą prosto i dalej (Projectile, rodzaj "knife").
## - Strzała Gromu (łuk albo księga): piorunowy pocisk; z łuku trafienie przeskakuje piorunem na wrogów obok,
##   z księgi w miejsce trafienia uderza piorun z nieba i rani wrogów wokół.
## - Zaklęte Ostrze (miecz albo księga): płonąca fala (klasa _FlameWave) podpala wrogów; z mieczem najpierw cięcie
##   przed sobą i krótka fala, z księgą dłuższa i szersza fala.
## Węzły: Otwarte rany (trafienia ciosami i pociskami czasem wywołują krwawienie - on_hit), Impet (po umiejętności
## ruchu następne trafienie mocniejsze - damage_factor), Zwiewność (po uniku chwilowa szybkość - on_dodge).
## Węzeł kluczowy Żelazna Wola działa w CharacterStats.attribute_damage.

const FIRE_COLOR := Color(1.0, 0.55, 0.2)
const SHOCK_COLOR := Color(0.6, 0.85, 1.0)
## Otwarte rany: krwawienie - część obrażeń trafienia rozłożona na Skills.BLEED_TICKS ran.
const OPEN_WOUNDS_BLEED := 0.4
## Impet: ile czasu po umiejętności ruchu czeka premia na następne trafienie.
const IMPETUS_TIME := 4.0
## Zwiewność: ile trwa premia po uniku.
const LIGHTNESS_TIME := 2.0
## Efekty z kreatora efektów PixelLab (tools/vfx_art.py, pixellab_src/vfx/ids.json): wirujący nóż, piorunowa
## strzała i płonąca fala (rysowane w prawo, punkt zaczepienia w środku).
const KNIFE_FX := preload("res://assets/effects/thrown_knife.png")
const KNIFE_FRAMES := 4
const KNIFE_FPS := 16.0
const KNIFE_ANCHOR := Vector2(11, 11)
const KNIFE_SCALE := 0.7
const WAVE_FX := preload("res://assets/effects/flame_wave.png")
const WAVE_FRAMES := 6
const WAVE_FPS := 16.0
const WAVE_ANCHOR := Vector2(24, 17)
## Promień cięcia w klatce efektu Traveler.SLASH_FX (do skalowania do zasięgu cięcia Zaklętego Ostrza).
const CUT_FX_RADIUS := 56.0
## Wysokość fali w klatce (do skalowania do szerokości fali).
const WAVE_FX_HEIGHT := 34.0
const ICONS := {
	"thrown_knives": preload("res://assets/skills/thrown_knives.png"),
	"thunder_arrow": preload("res://assets/skills/thunder_arrow.png"),
	"enchanted_blade": preload("res://assets/skills/enchanted_blade.png"),
	"impetus": preload("res://assets/skills/node_momentum.png"),
	"lightness": preload("res://assets/skills/node_lightness.png"),
}

var _player: Player
## odnowienia umiejętności: id -> [zostało, całość]
var _cooldowns := {}
var _impetus_time := 0.0
var _lightness_time := 0.0


func _init(player: Player) -> void:
	_player = player


## Naciśnięty slot umiejętności (Player._press_slot - umiejętność z bronią "a/b").
func press(id: String) -> void:
	if _player.skills.level_of(id) <= 0:
		_player._hint(Lang.t("Wybierz %s w drzewku umiejętności (K)") % Skills.name_of(id))
		return
	if _cooldowns.get(id, [0.0])[0] > 0.0 or _player.is_dashing():
		return
	if not _player.spend_mana(_player.skill_mana(id)):
		_player._hint(Lang.t("Za mało many") if not _player.spell_skills.blood_magic() else Lang.t("Za mało zdrowia"))
		return
	var weapon := _player.stats.weapon_type()
	match id:
		"thrown_knives":
			_start_cooldown(id, Skills.KNIVES_COOLDOWN)
			_thrown_knives(weapon)
		"thunder_arrow":
			_start_cooldown(id, Skills.THUNDER_COOLDOWN)
			_thunder_arrow(weapon)
			_player.support_echo(id, _thunder_arrow.bind(weapon))
		"enchanted_blade":
			_start_cooldown(id, Skills.BLADE_COOLDOWN)
			_enchanted_blade(weapon)
			_player.support_echo(id, _enchanted_blade.bind(weapon))
	_player.note_skill(id)


## Przerwanie (śmierć, zmiana broni).
func cancel() -> void:
	_impetus_time = 0.0
	_lightness_time = 0.0
	_player.stats.set_temp("lightness", {})


func cooldown_of(id: String) -> Vector2:
	var entry: Array = _cooldowns.get(id, [0.0, 0.0])
	return Vector2(entry[0], maxf(entry[1], entry[0]))


func _start_cooldown(id: String, base: float) -> void:
	var time: float = _player._cooldown(base, _tags(id))
	_cooldowns[id] = [time, time]


## Tagi umiejętności dla broni w ręku (Skills.HYBRID_TAGS).
func _tags(id: String) -> Array:
	return Skills.tags(id, _player.stats.weapon_type())


func _level(id: String) -> int:
	return _player.skills.level_of(id)


func _bonus(stat: String) -> float:
	return _player.skills.tree_bonus(stat)


func _physics_process(delta: float) -> void:
	for id: String in _cooldowns:
		_cooldowns[id][0] = maxf(_cooldowns[id][0] - delta, 0.0)
	_impetus_time = maxf(_impetus_time - delta, 0.0)
	if _lightness_time > 0.0:
		_lightness_time -= delta
		if _lightness_time <= 0.0:
			_player.stats.set_temp("lightness", {})


# ---------------------------------------------------------------- węzły
## Wołane po każdej umiejętności ruchu (Player.note_skill): Impet.
func on_movement() -> void:
	if _bonus("impetus") > 0.0:
		_impetus_time = IMPETUS_TIME


## Mnożnik obrażeń trafienia (Player.hit_enemy): Impet - pierwsze trafienie po umiejętności ruchu.
func damage_factor() -> float:
	if _impetus_time <= 0.0:
		return 1.0
	_impetus_time = 0.0
	return 1.0 + _bonus("impetus")


## Unik (Player.take_damage): Zwiewność - chwilowa szybkość ruchu, ataku i rzucania.
func on_dodge() -> void:
	var speed := _bonus("lightness")
	if speed <= 0.0:
		return
	_lightness_time = LIGHTNESS_TIME
	_player.stats.set_temp("lightness", {"move_speed": speed, "attack_speed": speed, "cast_speed": speed})


## Każde trafienie (Player.hit_enemy): Otwarte rany - ciosy i pociski z szansą wywołują krwawienie.
func on_hit(enemy: Goblin, amount: int, tags: Array) -> void:
	var chance := _bonus("open_wounds")
	if chance <= 0.0 or not ("hit" in tags or "projectile" in tags) or randf() >= chance:
		return
	_player.sword_skills.bleed_total(enemy, roundi(amount * OPEN_WOUNDS_BLEED))


func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _impetus_time > 0.0:
		result.append({"name": Lang.t("Impet"), "kind": "good", "left": _impetus_time, "total": IMPETUS_TIME, "icon": ICONS["impetus"],
				"description": Lang.t("Następne trafienie +%d%% obrażeń") % roundi(_bonus("impetus") * 100.0)})
	if _lightness_time > 0.0:
		result.append({"name": Lang.t("Zwiewność"), "kind": "good", "left": _lightness_time, "total": LIGHTNESS_TIME,
				"icon": ICONS["lightness"], "description": Lang.t("+%d%% szybkości ruchu, ataku i rzucania") % roundi(_bonus("lightness") * 100.0)})
	return result


# ---------------------------------------------------------------- Ciśnięte Noże
func _thrown_knives(weapon: String) -> void:
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	var tags := _tags("thrown_knives")
	var multiplier := Skills.knives_damage(_level("thrown_knives"))
	var count := Skills.KNIVES_COUNT + _player.support_count("thrown_knives", "projectiles")
	var spread := deg_to_rad(Skills.KNIVES_SPREAD)
	if weapon == "bow":
		_player.play_skill_anim("shoot", 0.3)
	else:
		_player.play_thrust(dir)
	for i in count:
		var shot := dir.rotated((i - (count - 1) / 2.0) * spread)
		if weapon == "bow":
			_launch_knife(shot, multiplier, tags)
		else:
			var knife := _Knife.new()
			knife.skills = self
			knife.direction = shot
			knife.reach = Skills.KNIVES_MELEE_RANGE
			knife.multiplier = multiplier
			knife.tags = tags
			_player.get_parent().add_child(knife)
			knife.global_position = _player.global_position + shot * 6.0
	Sfx.play("swing", -2.0, 1.5)


## Nóż z łuku: zwykły pocisk z wirującym nożem, dalej i bez powrotu.
func _launch_knife(dir: Vector2, multiplier: float, tags: Array) -> void:
	var knife := _player._make_projectile(_player.equipment.weapon(), dir, "thrown_knives", tags)
	knife.damage_min = maxi(1, roundi(knife.damage_min * multiplier))
	knife.damage_max = maxi(1, roundi(knife.damage_max * multiplier))
	knife.max_range = Skills.KNIVES_BOW_RANGE
	knife.speed = Skills.KNIVES_SPEED * 1.2
	knife.fx_kind = "knife"
	knife.sound = "blade"
	var plain := knife.get_node_or_null("Trail")
	if plain != null:
		knife.remove_child(plain)
		plain.queue_free()
	knife.enemy_hit.connect(func(enemy: Goblin) -> void: knife_bleed(enemy))
	_player.get_parent().add_child(knife)


## Krwawienie od noża.
func knife_bleed(enemy: Goblin) -> void:
	if is_instance_valid(_player):
		_player.sword_skills.bleed_enemy(enemy, Skills.KNIVES_BLEED, _tags("thrown_knives"))


## Trafienie noża z miecza (lot w obie strony).
func knife_hit(enemy: Goblin, multiplier: float, tags: Array, from: Vector2) -> void:
	if not is_instance_valid(_player) or enemy.state == Goblin.State.DEAD:
		return
	_player.hit_enemy(enemy, _player._skill_damage(multiplier, tags), from, 30.0, "blade", tags)
	knife_bleed(enemy)


# ---------------------------------------------------------------- Strzała Gromu
func _thunder_arrow(weapon: String) -> void:
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	var spell := weapon == "spell"
	var tags := _tags("thunder_arrow")
	var level := _level("thunder_arrow")
	_player.play_skill_anim("cast_push" if spell else "shoot", 0.35 if spell else 0.3)
	for shot: Vector2 in Player.split_directions(dir, _player.support_count("thunder_arrow", "projectiles")):
		var bolt := _player._make_projectile(_player.equipment.weapon(), shot, "thunder_arrow", tags)
		var multiplier := Skills.thunder_damage(level)
		bolt.damage_min = maxi(1, roundi(bolt.damage_min * multiplier))
		bolt.damage_max = maxi(1, roundi(bolt.damage_max * multiplier))
		bolt.speed = Skills.THUNDER_SPELL_SPEED if spell else Skills.THUNDER_BOW_SPEED
		bolt.fx_kind = "thunder"
		bolt.sound = "lightning"
		var plain := bolt.get_node_or_null("Trail")
		if plain != null:
			bolt.remove_child(plain)
			plain.queue_free()
		if spell:
			bolt.enemy_hit.connect(func(enemy: Goblin) -> void: _sky_strike(enemy.hurt_center(), level, tags))
		else:
			bolt.enemy_hit.connect(func(enemy: Goblin) -> void:
				_jump(enemy, (bolt.damage_min + bolt.damage_max) * 0.5 * Skills.THUNDER_JUMP_DAMAGE, tags))
		_player.get_parent().add_child(bolt)
	Sfx.play("zap", -2.0, 1.2)


## Z łuku: piorun przeskakuje z trafionego wroga na najbliższych THUNDER_JUMPS innych.
func _jump(from: Goblin, damage: float, tags: Array) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(from):
		return
	var start := from.hurt_center()
	var near: Array[Goblin] = []
	for enemy: Goblin in Goblin.near(_player.get_tree(), start, Skills.THUNDER_JUMP_RANGE + 20.0):
		if enemy != from and enemy.state != Goblin.State.DEAD and enemy.hurt_center().distance_to(start) <= Skills.THUNDER_JUMP_RANGE:
			near.append(enemy)
	near.sort_custom(func(a: Goblin, b: Goblin) -> bool:
		return a.hurt_center().distance_squared_to(start) < b.hurt_center().distance_squared_to(start))
	var jumps := Skills.THUNDER_JUMPS + _player.support_count("thunder_arrow", "chain")
	for i in mini(jumps, near.size()):
		var enemy := near[i]
		SpellSkills.lightning(_player.get_parent(), start, enemy.hurt_center())
		SpellSkills.zap_flash(_player.get_parent(), enemy.hurt_center())
		_player.hit_enemy(enemy, maxi(1, roundi(damage)), start, 20.0, "lightning", tags)
	if not near.is_empty():
		Sfx.play_at("zap", start, -4.0)


## Z księgi: piorun z nieba w miejscu trafienia rani wrogów wokół.
func _sky_strike(at: Vector2, level: int, tags: Array) -> void:
	if not is_instance_valid(_player):
		return
	var radius := Skills.THUNDER_STRIKE_RADIUS * _player.stats.area_multiplier(tags)
	SkillEffects.sheet_once(_player.get_parent(), SpellSkills.STORM_FX, 7, 20.0, at, Vector2(25, 141))
	SpellSkills.zap_flash(_player.get_parent(), at)
	SkillEffects.shockwave(_player.get_parent(), at, radius, SHOCK_COLOR)
	Sfx.play_at("zap", at, 0.0)
	var damage := _player._skill_damage(Skills.thunder_strike_damage(level), tags)
	for enemy: Goblin in Goblin.near(_player.get_tree(), at, radius + 30.0):
		if enemy.state != Goblin.State.DEAD and enemy.hurt_center().distance_to(at) <= radius + enemy.hurt_radius:
			_player.hit_enemy(enemy, damage, at, 40.0, "lightning", tags)


# ---------------------------------------------------------------- Zaklęte Ostrze
func _enchanted_blade(weapon: String) -> void:
	var dir := _player._aim_direction()
	_player._ranged_pose(dir)
	var spell := weapon == "spell"
	var tags := _tags("enchanted_blade")
	var level := _level("enchanted_blade")
	var area := _player.stats.area_multiplier(tags)
	if spell:
		_player.play_skill_anim("cast_push", 0.35)
	else:
		_player.play_skill_anim("sweep")
		_blade_cut(dir, level, tags, area)
	var size: Vector2 = Skills.BLADE_WAVE_SPELL if spell else Skills.BLADE_WAVE_MELEE
	for shot: Vector2 in Player.split_directions(dir, _player.support_count("enchanted_blade", "projectiles")):
		var wave := _FlameWave.new()
		wave.skills = self
		wave.direction = shot
		wave.reach = size.x * area
		wave.width = size.y * area
		wave.damage = _player._skill_damage(Skills.blade_wave_damage(level, spell), tags)
		wave.tags = tags
		_player.get_parent().add_child(wave)
		wave.global_position = _player.global_position + shot * 10.0
	Sfx.play("fireball_launch", -3.0, 1.2)


## Z mieczem: płonące cięcie łukiem przed postacią.
func _blade_cut(dir: Vector2, level: int, tags: Array, area: float) -> void:
	var origin := _player.body_center()
	var reach := Skills.BLADE_CUT_REACH * area
	var half := deg_to_rad(Skills.BLADE_CUT_ARC) / 2.0
	# cięcie mieczem (to samo co u podróżników) w kolorze ognia
	var fx := SkillEffects.sheet_once(_player.get_parent(), Traveler.SLASH_FX, 5, 24.0, origin + dir * reach * 0.2, Vector2(32, 32),
			dir.angle(), 1.0, reach / CUT_FX_RADIUS)
	fx.modulate = Color(1.5, 0.75, 0.35)
	Sfx.play("big_slash", -2.0, 1.2)
	var damage := _player._skill_damage(Skills.blade_cut_damage(level), tags)
	for enemy: Goblin in Goblin.near(_player.get_tree(), origin, reach + 30.0):
		if enemy.state == Goblin.State.DEAD:
			continue
		var to_enemy := enemy.hurt_center() - origin
		if to_enemy.length() > reach + enemy.hurt_radius:
			continue
		if to_enemy.length() > enemy.hurt_radius and absf(angle_difference(dir.angle(), to_enemy.angle())) > half:
			continue
		_player.hit_enemy(enemy, damage, _player.global_position, 60.0, "fire", tags)


## Trafienie fali: obrażenia od ognia i podpalenie (SpellSkills.burn).
func wave_hit(enemy: Goblin, damage: int, tags: Array, from: Vector2) -> void:
	if not is_instance_valid(_player) or enemy.state == Goblin.State.DEAD:
		return
	_player.hit_enemy(enemy, damage, from, 40.0, "fire", tags)
	var burn := damage * Skills.BLADE_BURN * (1.0 + _bonus("burn_damage") + _player.stats.dot_bonus(tags))
	_player.spell_skills.burn(enemy, burn)


# ---------------------------------------------------------------- pociski
## Nóż rzucony z mieczem: leci do `reach`, potem wraca do gracza; w każdą stronę trafia każdego wroga raz.
class _Knife extends Node2D:
	var skills: ZoneSkills
	var direction := Vector2.RIGHT
	var reach := 120.0
	var multiplier := 1.0
	var tags: Array = []
	var _travelled := 0.0
	var _back := false
	var _hit := {}
	var _fx: FxLoop

	func _ready() -> void:
		_fx = FxLoop.make(KNIFE_FX, KNIFE_FRAMES, KNIFE_FPS, KNIFE_ANCHOR)
		_fx.position = Vector2(0, -Projectile.HEIGHT)
		_fx.rotation = direction.angle()
		_fx.flip_v = absf(direction.angle()) > PI / 2.0
		_fx.z_index = 20
		_fx.scale = Vector2.ONE * KNIFE_SCALE
		add_child(_fx)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(skills) or not is_instance_valid(skills._player):
			queue_free()
			return
		var player := skills._player
		var step := Skills.KNIVES_SPEED * delta
		if _back:
			var to_player := player.global_position - global_position
			if to_player.length() <= step + 6.0:
				queue_free()
				return
			direction = to_player.normalized()
			_fx.rotation = direction.angle()
			_fx.flip_v = absf(direction.angle()) > PI / 2.0
		global_position += direction * step
		_travelled += step
		if not _back and _travelled >= reach:
			_back = true
			_hit.clear()
		var flying_at := global_position + Vector2(0, -Projectile.HEIGHT)
		for enemy: Goblin in Goblin.near(get_tree(), flying_at, 40.0):
			if _hit.has(enemy) or enemy.state == Goblin.State.DEAD:
				continue
			if flying_at.distance_to(enemy.hurt_center()) <= enemy.hurt_radius + Projectile.HIT_MARGIN + 2.0:
				_hit[enemy] = true
				skills.knife_hit(enemy, multiplier, tags, global_position - direction * 8.0)


## Płonąca fala Zaklętego Ostrza: leci prosto do `reach`, rani każdego wroga na swojej szerokości raz.
class _FlameWave extends Node2D:
	var skills: ZoneSkills
	var direction := Vector2.RIGHT
	var reach := 120.0
	var width := 40.0
	var damage := 1
	var tags: Array = []
	var _travelled := 0.0
	var _hit := {}
	var _fx: FxLoop

	func _ready() -> void:
		_fx = FxLoop.make(WAVE_FX, WAVE_FRAMES, WAVE_FPS, WAVE_ANCHOR)
		_fx.position = Vector2(0, -6)
		_fx.rotation = direction.angle()
		_fx.flip_v = absf(direction.angle()) > PI / 2.0
		# sierp ognia na całą szerokość fali, spłaszczony wzdłuż lotu
		var size := width / WAVE_FX_HEIGHT * 0.8
		_fx.scale = Vector2(size * 0.6, size)
		_fx.z_index = 20
		add_child(_fx)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(skills):
			queue_free()
			return
		var step := Skills.BLADE_WAVE_SPEED * delta
		global_position += direction * step
		_travelled += step
		# znika pod koniec lotu
		_fx.modulate.a = clampf((reach - _travelled) / 40.0, 0.0, 1.0)
		var across := direction.orthogonal()
		for enemy: Goblin in Goblin.near(get_tree(), global_position, width + 30.0):
			if _hit.has(enemy) or enemy.state == Goblin.State.DEAD:
				continue
			var offset := enemy.global_position - global_position
			if absf(offset.dot(direction)) <= 12.0 + enemy.hurt_radius and absf(offset.dot(across)) <= width / 2.0 + enemy.hurt_radius:
				_hit[enemy] = true
				skills.wave_hit(enemy, damage, tags, global_position - direction * 10.0)
		if _travelled >= reach:
			queue_free()
