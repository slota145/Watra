class_name SpellSkills
extends Node
## Umiejętności drzewka księgi magii (SkillTree "spell") z własną obsługą - dziecko gracza, jak SwordSkills i BowSkills:
## - Włócznia Marzanny: lodowy pocisk przebija i spowalnia (Goblin.chill); po Kuli ognia rozpryskuje się na odłamki.
## - Zamieć: śnieżyca pod kursorem rani i spowalnia; po Włóczni Marzanny od razu zamraża (ogłuszenie).
## - Burza Peruna: przez chwilę pioruny biją w wrogów wokół gracza; po Łańcuchu błyskawic każdy piorun przeskakuje dalej.
## - Kula Piorunów: powolna kula razi wyładowaniami wrogów obok; po Fali piorunów wybucha na końcu lotu.
## - Spadająca Gwiazda: po chwili wybuch pod kursorem podpala wrogów; po Zamieci podwójne obrażenia.
## - Krok przez Mgłę: teleport pod kursor (potem Kula ognia od razu naładowana - Player._process_skill).
## - Tarcza Many: część ciosów zabiera mana (absorb); po Kroku przez Mgłę przez chwilę całe ciosy.
## - Kamień Runiczny: w jego kręgu czary są mocniejsze i szybsze.
## - Ściana Ognia: ściana płomieni w poprzek drogi pod kursorem - pali wrogów, a pociski gracza lecące przez nią
##   dostają dodatkowe obrażenia od ognia (Projectile.ignite).
## - Lodowy Pancerz: tarcza z lodu przyjmuje ciosy (absorb_ice); gdy pęknie, wybucha lodem i zamraża wrogów wokół.
## Węzły kluczowe: Harmonia Żywiołów (czar innego żywiołu niż poprzedni - premia), Krew za Manę (umiejętności kosztują
## zdrowie - Player.spend_mana), Pełnia Mocy (pełna mana - mocniejsze czary, droższe umiejętności), Echo Run (nowe czary
## czasem wybrzmiewają drugi raz), Mistrz Żywiołów (twoje trafienia przyjmują żywioł, który ostatnio trafił
## ciebie, +40% obrażeń). Węzły: Przelana moc (część ciosów zabiera mana - mana_flow), Pełnia umysłu (obrażenia
## z many ponad połowę). Legendy: Księga Marzanny (Zamieć zawsze zamraża), Korona Peruna (Burza trwa,
## dopóki trzymasz klawisz i starcza many). Chwilowe premie idą do CharacterStats.set_temp("spell", ...).

const FIRE_COLOR := Color(1.0, 0.55, 0.2)
## Harmonia Żywiołów, Pełnia Mocy (próg many, premia, droższe umiejętności), Echo Run (szansa i opóźnienie powtórki).
const HARMONY_TIME := 4.0
const HARMONY_BONUS := 0.3
const FULL_POWER_AT := 0.9
const FULL_POWER_BONUS := 0.4
const FULL_POWER_COST := 1.2
const ECHO_CHANCE := 0.3
const ECHO_DELAY := 0.35
## Podpalenie: co ile rani.
const BURN_TICK := 0.5
## Burza Peruna: przeskoki pioruna (combo) - zasięg i siła kolejnych.
const STORM_JUMP_RANGE := 90.0
const STORM_JUMP_DAMAGE := 0.7
const LANCE_TEXTURE := preload("res://assets/spell/frost_lance.png")
const METEOR_TEXTURE := preload("res://assets/spell/meteor.png")
## Efekty z kreatora efektów PixelLab (tools/vfx_art.py, wpisy w pixellab_src/vfx/ids.json): błyskawica rozciągana
## między dwoma punktami (długość w klatce BOLT_LENGTH), trafienie piorunem, piorun Burzy z nieba, Kula Piorunów
## i jej wybuch (promień w klatce ORB_BLAST_RADIUS), lodowy rozprysk, Zamieć (promień BLIZZARD_FX_RADIUS),
## Spadająca Gwiazda, mgła Kroku, Tarcza Many, Kamień Runiczny i jego krąg (promień RUNE_CIRCLE_RADIUS).
const BOLT_FX := preload("res://assets/effects/spell_bolt.png")
const BOLT_LENGTH := 92.0
const ZAP_FX := preload("res://assets/effects/spell_zap.png")
const STORM_FX := preload("res://assets/effects/storm_strike.png")
const ORB_FX := preload("res://assets/effects/ball_lightning.png")
const ORB_BLAST_FX := preload("res://assets/effects/orb_blast.png")
const ORB_BLAST_RADIUS := 70.0
const SHATTER_FX := preload("res://assets/effects/ice_shatter.png")
const BLIZZARD_FX := preload("res://assets/effects/blizzard.png")
const BLIZZARD_FX_RADIUS := 60.0
const METEOR_FX := preload("res://assets/effects/meteor.png")
const BLINK_FX := preload("res://assets/effects/blink.png")
const SHIELD_FX := preload("res://assets/effects/mana_shield.png")
const RUNE_FX := preload("res://assets/effects/rune_stone.png")
const RUNE_CIRCLE_FX := preload("res://assets/effects/rune_circle.png")
const RUNE_CIRCLE_RADIUS := 70.0
## Ściana Ognia: zapętlony płomień (z kreatora efektów) stawiany co WALL_FLAME_GAP wzdłuż ściany.
const WALL_FX := preload("res://assets/effects/fire_wall.png")
const WALL_FLAME_GAP := 18.0
## Lodowy Pancerz: zapętlona lodowa skorupa wokół postaci i wybuch przy pęknięciu.
const ICE_ARMOR_FX := preload("res://assets/effects/ice_armor.png")
const ICE_ARMOR_BURST_FX := preload("res://assets/effects/ice_armor_burst.png")
const ICE_ARMOR_BURST_RADIUS := 52.0
## Mistrz Żywiołów: premia obrażeń, wir żywiołu przy zmianie (biały arkusz barwiony kolorem żywiołu).
const MASTER_BONUS := 0.4
const MASTER_FX := preload("res://assets/effects/elem_shift.png")
## Odgłos trafienia (Player.hit_enemy) dla żywiołu z Elements - Nawia nie zmienia żywiołu Mistrza.
const MASTER_SOUNDS := {Elements.FIRE: "fire", Elements.COLD: "ice", Elements.LIGHTNING: "lightning"}
## Pełnia umysłu: +1% obrażeń za każde FULL_MIND_STEP many ponad połowę, najwyżej FULL_MIND_MAX.
const FULL_MIND_STEP := 0.05
const FULL_MIND_MAX := 0.1
const ICONS := {
	"storm_call": preload("res://assets/skills/storm_call.png"), "mana_shield": preload("res://assets/skills/mana_shield.png"),
	"rune_stone": preload("res://assets/skills/rune_stone.png"), "harmony": preload("res://assets/skills/ks_harmony.png"),
	"full_power": preload("res://assets/skills/ks_full_power.png"), "ice_armor": preload("res://assets/skills/ice_armor.png"),
	"elem_master": preload("res://assets/skills/ks_elem_master.png"), "full_mind": preload("res://assets/skills/node_full_mind.png"),
}

var _player: Player
## odnowienia umiejętności: id -> [zostało, całość]
var _cooldowns := {}
var _storm_time := 0.0
var _storm_next := 0.0
var _storm_chain := false
var _shield_time := 0.0
var _shield_full := 0.0
var _shield_ring: Node2D
var _rune: _Rune
## Skąd postać zniknęła przy ostatnim Kroku przez Mgłę (Spadająca Gwiazda po nim spada tam - combo).
var _blink_from := Vector2.ZERO
## Pełny czas obecnego Kamienia Runicznego (dłuższy z kamieniem Watażka).
var _rune_total := Skills.RUNE_TIME
var _last_element := ""
var _harmony_time := 0.0
var _echoing := false
var _temp := {}
## Podpaleni wrogowie: wróg -> [obrażenia na ranę, zostało sekund, do kolejnej rany]
var _burning := {}
var _walls: Array[Node2D] = []
## Lodowy Pancerz: zostały czas, wytrzymałość tarczy (punkty obrażeń), skorupa wokół postaci.
var _ice_time := 0.0
var _ice_hp := 0
var _ice_shell: FxLoop
## Mistrz Żywiołów: żywioł ostatniego trafienia (Elements; "" - jeszcze żaden).
var _master_element := ""


func _init(player: Player) -> void:
	_player = player


## Naciśnięty slot umiejętności (trzymanie sprawdza Player.is_skill_held).
func press(id: String) -> void:
	if _player.skills.level_of(id) <= 0:
		_player._hint(Lang.t("Wybierz %s w drzewku umiejętności (K)") % Skills.name_of(id))
		return
	if _cooldowns.get(id, [0.0])[0] > 0.0 or _player.is_dashing():
		return
	# Fala piorunów: manę (albo combo po Łańcuchu błyskawic) liczy Player.use_followup
	if id == "thunder_wave":
		if _player.use_followup(id):
			_start_cooldown(id, Skills.WAVE_COOLDOWN)
		return
	if not _player.spend_mana(_player.skill_mana(id)):
		_player._hint(Lang.t("Za mało many") if not blood_magic() else Lang.t("Za mało zdrowia"))
		return
	var after := _player.combo_after(id)
	var combo := after != ""
	if combo:
		_player.combo_used()
	_player._ranged_pose(_player._aim_direction())
	match id:
		"frost_lance":
			_start_cooldown(id, Skills.LANCE_COOLDOWN)
			_frost_lance(combo)
			_echo(_frost_lance.bind(combo))
			_player.support_echo(id, _frost_lance.bind(combo))
		"blizzard":
			_start_cooldown(id, Skills.BLIZZARD_COOLDOWN)
			var at := _aim_point(Skills.BLIZZARD_RANGE)
			_blizzard(at, combo)
			_echo(_blizzard.bind(at, combo))
			_player.support_echo(id, _blizzard.bind(at, combo))
		"storm_call":
			_start_cooldown(id, Skills.STORM_COOLDOWN)
			_storm_call(combo)
		"ball_lightning":
			_start_cooldown(id, Skills.ORB_COOLDOWN)
			_ball_lightning(combo)
			_echo(_ball_lightning.bind(combo))
			_player.support_echo(id, _ball_lightning.bind(combo))
		"meteor":
			_start_cooldown(id, Skills.METEOR_COOLDOWN)
			# zaraz po Kroku przez Mgłę gwiazda spada tam, skąd zniknęła postać; zaraz po Zamieci - podwójne obrażenia
			var at := _blink_from if after == "blink" else _aim_point(Skills.METEOR_RANGE)
			_meteor(at, after == "blizzard")
			_echo(_meteor.bind(at, after == "blizzard"))
			_player.support_echo(id, _meteor.bind(at, after == "blizzard"))
		"blink":
			_start_cooldown(id, Skills.BLINK_COOLDOWN * (1.0 + _bonus("blink_cooldown")))
			_blink()
		"mana_shield":
			_start_cooldown(id, Skills.SHIELD_COOLDOWN)
			_mana_shield(combo)
		"rune_stone":
			_start_cooldown(id, Skills.RUNE_COOLDOWN)
			_rune_stone()
		"fire_wall":
			_start_cooldown(id, Skills.WALL_COOLDOWN)
			_fire_wall(_aim_point(Skills.WALL_RANGE))
		"ice_armor":
			_start_cooldown(id, Skills.ICE_ARMOR_COOLDOWN)
			_ice_armor()
	_player.note_skill(id)


## Przerwanie (śmierć, zmiana broni).
func cancel() -> void:
	_storm_time = 0.0
	_ice_time = 0.0
	_ice_hp = 0


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


## Węzły kluczowe wspólnego drzewka działają z każdą bronią (tam, gdzie pasują - np. Pełnia Mocy na czary).
func has_keystone(id: String) -> bool:
	return _player.skills.has_keystone(id)


## Punkt pod kursorem (tester-bot i testy celują przez Player.aim_override - wektor od środka postaci).
func _cursor() -> Vector2:
	if _player.aim_override != Vector2.ZERO:
		return _player.body_center() + _player.aim_override
	return _player.get_global_mouse_position()


func _aim_point(reach: float) -> Vector2:
	var origin := _player.global_position
	return origin + (_cursor() - origin).limit_length(reach)


## `id` - umiejętność (jej tagi i kamienie wsparcia); "" - sam czar.
func _damage(multiplier: float, id := "") -> int:
	return _player._skill_damage(multiplier, Skills.tags(id) if id != "" else ["spell"])


func _enemies() -> Array[Node]:
	return _player.get_tree().get_nodes_in_group("enemies")


func _physics_process(delta: float) -> void:
	for id: String in _cooldowns:
		_cooldowns[id][0] = maxf(_cooldowns[id][0] - delta, 0.0)
	_harmony_time = maxf(_harmony_time - delta, 0.0)
	_shield_full = maxf(_shield_full - delta, 0.0)
	if _shield_time > 0.0:
		_shield_time -= delta
		if _shield_time <= 0.0:
			_shield_full = 0.0
	if _shield_ring != null:
		_shield_ring.visible = _shield_time > 0.0
	if _ice_time > 0.0:
		_ice_time -= delta
		if _ice_time <= 0.0:
			_ice_hp = 0
	if _ice_shell != null:
		_ice_shell.visible = _ice_time > 0.0
	_process_burn(delta)
	_update_temp()
	if _player.is_dead:
		cancel()
		return
	_process_storm(delta)


# ---------------------------------------------------------------- węzły kluczowe i premie
## Wołane przy każdej użytej umiejętności (Player.note_skill): Harmonia Żywiołów.
func on_cast(id: String) -> void:
	var element: String = Skills.ELEMENTS.get(id, "")
	if element == "":
		return
	if has_keystone("harmony") and _last_element != "" and element != _last_element:
		_harmony_time = HARMONY_TIME
	_last_element = element


## Krew za Manę (dawna Ofiara Krwi): umiejętności kosztują zdrowie zamiast many (Player.spend_mana).
func blood_magic() -> bool:
	return has_keystone("blood_sacrifice")


## Mnożnik kosztu umiejętności (Pełnia Mocy).
func mana_cost_factor() -> float:
	return FULL_POWER_COST if has_keystone("full_power") else 1.0


func _full_power() -> bool:
	return has_keystone("full_power") and _player.mana >= _player.stats.max_mana() * FULL_POWER_AT


## Gdzie stoi Kamień Runiczny (INF - nie stoi) - Łańcuch błyskawic po nim przeskakuje przez kamień (combo).
func rune_at() -> Vector2:
	if not is_instance_valid(_rune) or _rune.leaving:
		return Vector2.INF
	return _rune.global_position + Vector2(0, -12)


## Kula ognia po Zamieci (combo): spowolnieni lodem wrogowie w wybuchu (i tuż za nim) pękają - lód i ogień
## ranią wszystkich wokół każdego z nich (każdego wroga raz). `multiplier` - procent obrażeń broni kuli.
func fire_shatter(at: Vector2, radius: float, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	var tags := Skills.tags("fireball")
	var blast := Skills.SHATTER_BLAST_RADIUS * _player.stats.area_multiplier(tags)
	var damage := _damage(multiplier * Skills.SHATTER_BLAST_DAMAGE * _player.combo_damage(), "fireball")
	var frozen: Array[Goblin] = []
	for enemy: Goblin in Goblin.near(_player.get_tree(), at, radius * 1.5 + 40.0):
		if enemy.state != Goblin.State.DEAD and enemy.is_chilled() and enemy.global_position.distance_to(at) <= radius * 1.5 + enemy.hurt_radius:
			frozen.append(enemy)
	var hit := {}
	for victim in frozen:
		if not is_instance_valid(victim):
			continue
		var spot := victim.hurt_center()
		shatter_flash(_player.get_parent(), spot, 1.3)
		MiscVfx.spark(_player.get_parent(), spot, FIRE_COLOR, 1.0)
		for enemy: Goblin in Goblin.near(_player.get_tree(), spot, blast + 40.0):
			if hit.has(enemy):
				continue
			if enemy.state != Goblin.State.DEAD and enemy.hurt_center().distance_to(spot) <= blast + enemy.hurt_radius:
				hit[enemy] = true
				_player.hit_enemy(enemy, damage, spot, 60.0, "ice", tags)
				_player.hit_enemy(enemy, damage, spot, 0.0, "fire", tags)
	if not frozen.is_empty():
		Sfx.play_at("hit", at, 0.0)


func in_rune() -> bool:
	return is_instance_valid(_rune) and not _rune.leaving and _player.global_position.distance_to(_rune.global_position) <= Skills.RUNE_RADIUS


func _update_temp() -> void:
	var spell := 0.0
	var cast := 0.0
	if not _player.is_dead:
		if in_rune():
			var rune := Skills.rune_bonus(_level("rune_stone")) * (1.0 + _bonus("rune_bonus"))
			spell += rune
			cast += rune
		if _harmony_time > 0.0:
			spell += HARMONY_BONUS
		if _full_power():
			spell += FULL_POWER_BONUS
	var any := full_mind_bonus() if not _player.is_dead else 0.0
	var temp := {}
	if any > 0.0:
		temp["damage_percent"] = any
	if spell > 0.0:
		temp["spell_damage"] = spell
	if cast > 0.0:
		temp["cast_speed"] = cast
	if temp != _temp:
		_temp = temp
		_player.stats.set_temp("spell", temp)


## Pełnia umysłu (węzeł): +1% obrażeń za każde 5% many ponad połowę, najwyżej +10%.
func full_mind_bonus() -> float:
	if _bonus("full_mind") <= 0.0:
		return 0.0
	var share := _player.mana / maxf(float(_player.stats.max_mana()), 1.0)
	return minf(floorf(maxf(share - 0.5, 0.0) / FULL_MIND_STEP + 0.001) * 0.01, FULL_MIND_MAX)


## Mistrz Żywiołów: wołane przy każdym otrzymanym ciosie (Player.take_damage) - ogień, lód i piorun zmieniają żywioł
## twoich trafień; fizyczne i Nawia go nie zmieniają.
func on_hurt(element: String) -> void:
	if not has_keystone("elem_master") or not MASTER_SOUNDS.has(element) or element == _master_element:
		return
	_master_element = element
	var fx := SkillEffects.sheet_once(_player.get_parent(), MASTER_FX, 12, 18.0, _player.body_center(), Vector2(21, 21))
	if fx != null:
		fx.modulate = Elements.color_of(element)


## Mistrz Żywiołów: odgłos (żywioł) trafienia gracza - żywioł ostatniego ciosu zamiast własnego.
func master_sound(sound: String) -> String:
	if not has_keystone("elem_master") or _master_element == "":
		return sound
	return MASTER_SOUNDS[_master_element]


func master_factor() -> float:
	return 1.0 + MASTER_BONUS if has_keystone("elem_master") else 1.0


## Przelana moc (węzeł): część otrzymanych obrażeń zabiera mana zamiast zdrowia (póki starcza many).
## Zwraca obrażenia, które zostają dla zdrowia.
func mana_flow(amount: int) -> int:
	var share := _bonus("mana_flow")
	if share <= 0.0 or amount <= 0:
		return amount
	var taken := mini(roundi(amount * share), floori(_player.mana))
	if taken <= 0:
		return amount
	_player.mana -= taken
	_player.mana_changed.emit(int(_player.mana), _player.stats.max_mana())
	return amount - taken


## Echo Run: czar może wybrzmieć drugi raz za darmo (powtórka nie ma już echa).
func _echo(again: Callable) -> void:
	if _echoing or not has_keystone("echo_runes") or randf() >= ECHO_CHANCE:
		return
	_player.get_tree().create_timer(ECHO_DELAY, false).timeout.connect(func() -> void:
		if not is_instance_valid(_player) or _player.is_dead or _player.stats.weapon_type() != "spell":
			return
		_echoing = true
		MiscVfx.spark(_player.get_parent(), _player.body_center(), Color(0.75, 0.5, 1.0), 1.0)
		again.call()
		_echoing = false)



# ---------------------------------------------------------------- efekty piorunów
## Złoto-niebieska błyskawica od `from` do `to` (arkusz rozciągany wzdłuż drogi).
static func lightning(parent: Node, from: Vector2, to: Vector2) -> void:
	var path := to - from
	SkillEffects.sheet_once(parent, BOLT_FX, 6, 20.0, from, Vector2(6, 19), path.angle(), maxf(path.length(), 8.0) / BOLT_LENGTH)


## Trzask pioruna w trafionym miejscu.
static func zap_flash(parent: Node, at: Vector2) -> void:
	SkillEffects.sheet_once(parent, ZAP_FX, 5, 20.0, at, Vector2(22, 22))


## Lodowy rozprysk (odłamki, szron) w rozmiarze `size`.
static func shatter_flash(parent: Node, at: Vector2, size := 1.0) -> void:
	SkillEffects.sheet_once(parent, SHATTER_FX, 8, 16.0, at, Vector2(27, 19), 0.0, 1.0, size)


# ---------------------------------------------------------------- podpalenie
## Podpalenie wroga: `total` obrażeń rozłożone na Skills.BURN_TIME s (nowe odświeża i bierze mocniejsze).
func burn(enemy: Goblin, total: float) -> void:
	if not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
		return
	var per_tick := maxf(total * BURN_TICK / Skills.BURN_TIME, 1.0)
	var entry: Array = _burning.get(enemy, [0.0, 0.0, BURN_TICK])
	_burning[enemy] = [maxf(entry[0], per_tick), Skills.BURN_TIME, entry[2]]


func is_burning(enemy: Goblin) -> bool:
	return _burning.has(enemy)


func _process_burn(delta: float) -> void:
	# klucz bez typu: zabity potwór jest już zwolniony, a przypisanie go do zmiennej Goblin to błąd
	for key in _burning.keys():
		if not is_instance_valid(key) or (key as Goblin).state == Goblin.State.DEAD:
			_burning.erase(key)
			continue
		var enemy: Goblin = key
		var entry: Array = _burning[enemy]
		entry[1] -= delta
		entry[2] -= delta
		if entry[2] <= 0.0:
			entry[2] += BURN_TICK
			enemy.take_damage(roundi(entry[0]), enemy.global_position, 0.0)
			MiscVfx.spark(enemy.get_parent(), enemy.hurt_center(), FIRE_COLOR, 0.45)
		if entry[1] <= 0.0:
			_burning.erase(enemy)


func _chill(enemy: Goblin) -> void:
	if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
		enemy.chill(Skills.CHILL_FACTOR, Skills.CHILL_TIME * (1.0 + _bonus("chill_time")))


# ---------------------------------------------------------------- Włócznia Marzanny
func _frost_lance(combo: bool) -> void:
	var dir := _player._aim_direction()
	var multiplier := Skills.lance_damage(_level("frost_lance")) * (1.0 + _bonus("lance_damage")) * (_player.combo_damage() if combo else 1.0)
	# Rozszczep (kamień wsparcia): dodatkowe włócznie wachlarzem
	for shot: Vector2 in Player.split_directions(dir, _player.support_count("frost_lance", "projectiles")):
		var lance := _player._make_projectile(_player.equipment.weapon(), shot, "frost_lance")
		lance.texture = LANCE_TEXTURE
		lance.magic = false
		lance.fx_kind = "ice"
		lance.speed = Skills.LANCE_SPEED
		lance.size = 0.9
		lance.pierce = Skills.lance_pierce(_level("frost_lance")) + roundi(_bonus("lance_pierce")) + _player.support_count("frost_lance", "pierce")
		lance.damage_min = maxi(1, roundi(lance.damage_min * multiplier))
		lance.damage_max = maxi(1, roundi(lance.damage_max * multiplier))
		lance.max_range *= 1.2
		var shattered := [not combo]
		lance.enemy_hit.connect(func(enemy: Goblin) -> void:
			_chill(enemy)
			if not shattered[0]:
				shattered[0] = true
				_shatter(enemy, lance.global_position, multiplier))
		_player.get_parent().add_child(lance)
	Sfx.play("magic", 0.0, 0.7)


## Odłamki lodu rozpryskujące się z trafionego wroga (combo po Kuli ognia).
func _shatter(enemy: Goblin, at: Vector2, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	shatter_flash(_player.get_parent(), at + Vector2(0, -Projectile.HEIGHT), 1.2)
	Sfx.play_at("hit", at, -4.0)
	for i in Skills.LANCE_SHARDS:
		var dir := Vector2.from_angle(TAU * i / Skills.LANCE_SHARDS + randf_range(-0.2, 0.2))
		var shard := _player._make_projectile(_player.equipment.weapon(), dir, "frost_lance")
		shard.position = at
		shard.texture = LANCE_TEXTURE
		shard.magic = false
		shard.fx_kind = "ice"
		shard.size = 0.45
		shard.speed = 260.0
		shard.max_range = 90.0
		shard.pierce = 0
		shard.chain = 0
		shard.damage_min = maxi(1, roundi(shard.damage_min * multiplier * Skills.LANCE_SHARD_DAMAGE))
		shard.damage_max = maxi(1, roundi(shard.damage_max * multiplier * Skills.LANCE_SHARD_DAMAGE))
		if is_instance_valid(enemy):
			shard._hit[enemy] = true
		shard.enemy_hit.connect(_chill)
		_player.get_parent().add_child.call_deferred(shard)


# ---------------------------------------------------------------- Zamieć
func _blizzard(at: Vector2, combo: bool) -> void:
	var storm := _Blizzard.new()
	storm.skills = self
	storm.position = at
	storm.radius = Skills.BLIZZARD_RADIUS * _player.stats.area_multiplier(Skills.tags("blizzard"))
	storm.time_left = Skills.BLIZZARD_TIME * (1.0 + _bonus("blizzard_time"))
	storm.damage = Skills.blizzard_damage(_level("blizzard")) * (1.0 + _bonus("blizzard_damage")) * (_player.combo_damage() if combo else 1.0)
	var legend := _player.equipment.effect_power("blizzard_freeze")
	storm.freeze = maxf(Skills.FREEZE_TIME if combo else 0.0, legend)
	_player.get_parent().add_child(storm)
	Sfx.play("whirl", 0.0, 0.6)


# ---------------------------------------------------------------- Burza Peruna
func _storm_call(combo: bool) -> void:
	_storm_time = Skills.STORM_TIME * (1.0 + _bonus("storm_time"))
	_storm_next = 0.0
	_storm_chain = combo
	Sfx.play("thunder", -2.0, 0.9)


func storm_active() -> bool:
	return _storm_time > 0.0


func _process_storm(delta: float) -> void:
	if _storm_time <= 0.0:
		return
	# Korona Peruna: burza trwa, dopóki trzymasz klawisz i starcza many
	var crown := _player.equipment.effect_power("endless_storm")
	if crown > 0.0 and _player.is_skill_held("storm_call") and _storm_time < 0.3 and _player.spend_mana(crown * delta):
		_storm_time = 0.3
	_storm_time -= delta
	_storm_next -= delta
	if _storm_next > 0.0:
		return
	var tags := Skills.tags("storm_call")
	_storm_next = Skills.STORM_INTERVAL / _player._skill_speed(tags)
	var reach := Skills.STORM_RANGE * _player.stats.area_multiplier(tags)
	var near: Array[Goblin] = []
	for enemy: Goblin in _enemies():
		if enemy.state != Goblin.State.DEAD and enemy.global_position.distance_to(_player.global_position) <= reach:
			near.append(enemy)
	if near.is_empty():
		return
	var target: Goblin = near.pick_random()
	var multiplier := Skills.storm_damage(_level("storm_call")) * (_player.combo_damage() if _storm_chain else 1.0)
	SkillEffects.sheet_once(_player.get_parent(), STORM_FX, 7, 20.0, target.hurt_center(), Vector2(25, 141))
	Sfx.play_at("zap", target.global_position, -2.0)
	_player.hit_enemy(target, _damage(multiplier, "storm_call"), target.global_position + Vector2(0, -20), 30.0, "lightning", tags)
	if not _storm_chain:
		return
	var hit := [target]
	var from := target.hurt_center()
	for i in Skills.STORM_JUMPS:
		var next: Goblin = null
		var best := STORM_JUMP_RANGE
		for enemy: Goblin in near:
			if enemy in hit or not is_instance_valid(enemy) or enemy.state == Goblin.State.DEAD:
				continue
			var d := enemy.hurt_center().distance_to(from)
			if d < best:
				best = d
				next = enemy
		if next == null:
			return
		hit.append(next)
		lightning(_player.get_parent(), from, next.hurt_center())
		zap_flash(_player.get_parent(), next.hurt_center())
		_player.hit_enemy(next, _damage(multiplier * STORM_JUMP_DAMAGE, "storm_call"), from, 20.0, "lightning", tags)
		from = next.hurt_center()


# ---------------------------------------------------------------- Kula Piorunów
func _ball_lightning(combo: bool) -> void:
	var area := _player.stats.area_multiplier(Skills.tags("ball_lightning"))
	# Rozszczep (kamień wsparcia): dodatkowe kule wachlarzem
	for shot: Vector2 in Player.split_directions(_player._aim_direction(), _player.support_count("ball_lightning", "projectiles")):
		var orb := _Orb.new()
		orb.skills = self
		orb.position = _player.global_position + shot * 8.0
		orb.direction = shot
		orb.damage = Skills.orb_damage(_level("ball_lightning")) * (1.0 + _bonus("orb_damage")) * (_player.combo_damage() if combo else 1.0)
		orb.blast = combo
		orb.area = area
		_player.get_parent().add_child(orb)
	Sfx.play("zap", 0.0, 0.7)


# ---------------------------------------------------------------- Spadająca Gwiazda
func _meteor(at: Vector2, combo: bool) -> void:
	var star := _Meteor.new()
	star.skills = self
	star.position = at
	star.radius = Skills.METEOR_RADIUS * (1.0 + _bonus("meteor_radius")) * _player.stats.area_multiplier(Skills.tags("meteor"))
	star.damage = Skills.meteor_damage(_level("meteor")) * (2.0 * _player.combo_damage() if combo else 1.0)
	_player.get_parent().add_child(star)
	Sfx.play("fireball_launch", 0.0, 0.6)


## Uderzenie Spadającej Gwiazdy: wybuch ognia (jak kula ognia) i podpalenie wrogów w kręgu.
func meteor_impact(at: Vector2, radius: float, multiplier: float) -> void:
	if not is_instance_valid(_player):
		return
	var kind := _player.stats.kind_multiplier(Skills.tags("meteor"))
	var blast: Projectile = _player.PROJECTILE.instantiate()
	blast.texture = METEOR_TEXTURE
	blast.fire = true
	blast.explosion_radius = radius
	blast.explosion_min = maxi(1, roundi(_player.stats.damage_min() * multiplier * kind))
	blast.explosion_max = maxi(1, roundi(_player.stats.damage_max() * multiplier * kind))
	blast.tags = Skills.tags("meteor")
	blast.position = at
	_player.get_parent().add_child(blast)
	blast._explode()
	_player.add_shake(4.0)
	var total := (blast.explosion_min + blast.explosion_max) / 2.0 * Skills.METEOR_BURN * (1.0 + _bonus("burn_damage"))
	for enemy: Goblin in _enemies():
		if enemy.global_position.distance_to(at) <= radius + enemy.hurt_radius:
			burn(enemy, total)


# ---------------------------------------------------------------- Krok przez Mgłę
func _blink() -> void:
	var from := _player.global_position
	_blink_from = from
	var target := _aim_point(Skills.BLINK_RANGE)
	# teleport przenosi nad przeszkodami (płoty, klify, drzewa) - zatrzymuje go tylko granica mapy i ściany
	# podziemi, a w przeszkodzie postać ląduje obok, na linii teleportu
	var ray := PhysicsRayQueryParameters2D.create(from, target, Player.JUMP_MASK)
	var hit := _player.get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		target = hit["position"] - (target - from).normalized() * 10.0
	target = _player.free_landing(target, from)
	SkillEffects.sheet_once(_player.get_parent(), BLINK_FX, 8, 14.0, _player.body_center(), Vector2(23, 21))
	_player.global_position = target
	_player.reset_physics_interpolation()
	_player._invulnerable_timer = maxf(_player._invulnerable_timer, 0.25)
	SkillEffects.sheet_once(_player.get_parent(), BLINK_FX, 8, 14.0, _player.body_center(), Vector2(23, 21), 0.0, 1.0, 1.0, 0.0, true)
	Sfx.play("dash", 0.0, 1.3)


# ---------------------------------------------------------------- Tarcza Many
func _mana_shield(combo: bool) -> void:
	_shield_time = Skills.SHIELD_TIME
	_shield_full = Skills.SHIELD_FULL_TIME if combo else 0.0
	if _shield_ring == null:
		_shield_ring = _ShieldRing.new()
		_shield_ring.skills = self
		_player.add_child(_shield_ring)
		_shield_ring.position = Player.BODY_OFFSET
	_shield_ring.visible = true
	Sfx.play("magic", 0.0, 1.4)


func shield_active() -> bool:
	return _shield_time > 0.0


## Wołane przy otrzymaniu ciosu (Player.take_damage): część obrażeń (albo całe - combo) zabiera mana.
## Zwraca obrażenia, które zostają dla zdrowia.
func absorb(amount: int) -> int:
	if _shield_time <= 0.0 or amount <= 0:
		return amount
	var share := 1.0 if _shield_full > 0.0 else minf(Skills.SHIELD_SHARE + _bonus("shield_share"), 1.0)
	var taken := mini(roundi(amount * share), floori(_player.mana / Skills.SHIELD_MANA_PER_DAMAGE))
	if taken <= 0:
		return amount
	_player.mana -= taken * Skills.SHIELD_MANA_PER_DAMAGE
	_player.mana_changed.emit(int(_player.mana), _player.stats.max_mana())
	MiscVfx.spark(_player.get_parent(), _player.body_center(), Color(0.5, 0.7, 1.0), 0.7)
	return amount - taken


# ---------------------------------------------------------------- Ściana Ognia
func _fire_wall(at: Vector2) -> void:
	_walls = _walls.filter(func(w: Node2D) -> bool: return is_instance_valid(w))
	while _walls.size() >= Skills.WALL_MAX:
		_walls.pop_front().queue_free()
	var tags := Skills.tags("fire_wall")
	var wall := _FireWall.new()
	wall.skills = self
	wall.position = at
	var aim := (at - _player.global_position)
	wall.axis = (aim.orthogonal() if aim.length() > 4.0 else _player._aim_direction().orthogonal()).normalized()
	wall.half_length = Skills.WALL_LENGTH * 0.5 * _player.stats.area_multiplier(tags)
	wall.time_left = Skills.WALL_TIME * (1.0 + _player.support("fire_wall", "duration"))
	wall.damage = Skills.wall_damage(_level("fire_wall")) * (1.0 + _bonus("burn_damage") + _player.support("fire_wall", "dot_damage"))
	_player.get_parent().add_child(wall)
	_walls.append(wall)
	Sfx.play_at("fireball_launch", at, -2.0)


## Ściana płomieni: odcinek ±half_length wzdłuż `axis`; co WALL_TICK s rani i podpala wrogów w ogniu, a pociski
## gracza lecące przez nią zapala (Projectile.ignite - dodatkowe obrażenia od ognia).
class _FireWall extends Node2D:
	var skills: SpellSkills
	var axis := Vector2.RIGHT
	var half_length := 55.0
	var time_left := 4.0
	var damage := 0.35
	var _tick := 0.0

	func _ready() -> void:
		y_sort_enabled = true
		var count := maxi(roundi(half_length * 2.0 / SpellSkills.WALL_FLAME_GAP), 2)
		for i in count + 1:
			var flame := FxLoop.make(SpellSkills.WALL_FX, 8, 12.0, Vector2(16, 30))
			flame.position = axis * lerpf(-half_length, half_length, float(i) / count)
			flame.frame = (i * 3) % 8
			flame.scale = Vector2.ONE * (0.8 if i % 2 == 1 else 1.0)
			add_child(flame)

	func _near(point: Vector2, margin: float) -> bool:
		var a := global_position - axis * half_length
		var b := global_position + axis * half_length
		return point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)) <= margin

	func _physics_process(delta: float) -> void:
		time_left -= delta
		if time_left <= 0.0 or not is_instance_valid(skills) or not is_instance_valid(skills._player):
			queue_free()
			return
		modulate.a = clampf(time_left / 0.4, 0.0, 1.0)
		for shot in get_tree().get_nodes_in_group("player_projectiles"):
			if not shot.ignited and _near(shot.global_position, Skills.WALL_THICKNESS):
				shot.ignite(Skills.WALL_IGNITE)
		_tick -= delta
		if _tick > 0.0:
			return
		_tick = Skills.WALL_TICK
		var player := skills._player
		var tags := Skills.tags("fire_wall")
		var amount := player._skill_damage(damage, tags)
		for enemy: Goblin in Goblin.near(get_tree(), global_position, half_length + 40.0):
			if enemy.state == Goblin.State.DEAD or not _near(enemy.global_position, Skills.WALL_THICKNESS + enemy.hurt_radius * 0.5):
				continue
			player.hit_enemy(enemy, amount, enemy.global_position, 0.0, "fire", tags)
			skills.burn(enemy, amount * Skills.WALL_BURN)


# ---------------------------------------------------------------- Lodowy Pancerz
func _ice_armor() -> void:
	_ice_time = Skills.ICE_ARMOR_TIME * (1.0 + _player.support("ice_armor", "duration"))
	_ice_hp = maxi(roundi(_player.stats.max_health() * Skills.ice_armor_share(_level("ice_armor"))), 1)
	if _ice_shell == null:
		_ice_shell = FxLoop.make(ICE_ARMOR_FX, 16, 12.0, Vector2(29, 29))
		_ice_shell.z_index = 1
		_player.add_child(_ice_shell)
		_ice_shell.position = Player.BODY_OFFSET
	_ice_shell.visible = true
	shatter_flash(_player.get_parent(), _player.body_center(), 0.8)
	Sfx.play("magic", 0.0, 0.8)


func ice_armor_active() -> bool:
	return _ice_time > 0.0 and _ice_hp > 0


## Wołane przy otrzymaniu ciosu (Player.take_damage) przed Tarczą Many: lodowa tarcza przyjmuje cios; gdy pęknie,
## wybucha. Zwraca obrażenia, które zostają.
func absorb_ice(amount: int) -> int:
	if not ice_armor_active() or amount <= 0:
		return amount
	var taken := mini(amount, _ice_hp)
	_ice_hp -= taken
	if _ice_hp <= 0:
		_ice_time = 0.0
		_ice_burst()
	else:
		MiscVfx.spark(_player.get_parent(), _player.body_center(), Color(0.7, 0.9, 1.0), 0.6)
	return amount - taken


## Pęknięcie Lodowego Pancerza: lodowy wybuch rani i zamraża wrogów wokół.
func _ice_burst() -> void:
	var tags := Skills.tags("ice_armor")
	var at := _player.body_center()
	var radius := Skills.ICE_ARMOR_RADIUS * _player.stats.area_multiplier(tags)
	SkillEffects.sheet_once(_player.get_parent(), ICE_ARMOR_BURST_FX, 14, 16.0, at, Vector2(67, 59), 0.0, 1.0,
			radius / ICE_ARMOR_BURST_RADIUS)
	var damage := _damage(Skills.ice_armor_damage(_level("ice_armor")), "ice_armor")
	for enemy: Goblin in Goblin.near(_player.get_tree(), at, radius + 40.0):
		if enemy.state == Goblin.State.DEAD or enemy.hurt_center().distance_to(at) > radius + enemy.hurt_radius:
			continue
		_player.hit_enemy(enemy, damage, at, 80.0, "ice", tags)
		if is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD:
			enemy.freeze(Skills.ICE_ARMOR_FREEZE)
	Sfx.play("hit", 0.0, 1.4)
	_player._shake = maxf(_player._shake, 2.0)


# ---------------------------------------------------------------- Kamień Runiczny
func _rune_stone() -> void:
	if is_instance_valid(_rune):
		_rune.leave()
	_rune = _Rune.new()
	_rune.position = _aim_point(Skills.RUNE_PLACE)
	# Watażka (kamień wsparcia przywołań): dłużej
	_rune_total = Skills.RUNE_TIME * (1.0 + _player.support("rune_stone", "duration"))
	_rune.time_left = _rune_total
	_player.get_parent().add_child(_rune)
	Sfx.play("anvil", -6.0, 0.8)


func rune() -> Node2D:
	return _rune if is_instance_valid(_rune) and not _rune.leaving else null


## Efekty do rzędu ikon pod paskami zdrowia i many.
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _storm_time > 0.0:
		result.append({"name": Lang.t("Burza Peruna"), "kind": "good", "left": _storm_time, "total": Skills.STORM_TIME, "icon": ICONS["storm_call"],
				"description": Lang.t("Pioruny biją w wrogów wokół ciebie i przeskakują dalej") if _storm_chain else Lang.t("Pioruny biją w wrogów wokół ciebie")})
	if _shield_time > 0.0:
		result.append({"name": Lang.t("Tarcza Many"), "kind": "good", "left": _shield_time, "total": Skills.SHIELD_TIME, "icon": ICONS["mana_shield"],
				"description": Lang.t("Całe ciosy zabiera mana") if _shield_full > 0.0 else Lang.t("Część ciosów zabiera mana zamiast zdrowia")})
	if in_rune():
		result.append({"name": Lang.t("Kamień Runiczny"), "kind": "good", "left": _rune.time_left, "total": _rune_total, "icon": ICONS["rune_stone"],
				"description": Lang.t("+%d%% obrażeń magicznych i szybkości rzucania") % roundi(_temp.get("cast_speed", 0.0) * 100.0)})
	if _harmony_time > 0.0:
		result.append({"name": Lang.t("Harmonia Żywiołów"), "kind": "good", "left": _harmony_time, "total": HARMONY_TIME, "icon": ICONS["harmony"],
				"description": Lang.t("+%d%% obrażeń magicznych") % roundi(HARMONY_BONUS * 100.0)})
	if ice_armor_active():
		result.append({"name": Lang.t("Lodowy Pancerz"), "kind": "good", "left": _ice_time, "total": Skills.ICE_ARMOR_TIME, "icon": ICONS["ice_armor"],
				"description": Lang.t("Tarcza z lodu przyjmie jeszcze %d obrażeń") % _ice_hp})
	if has_keystone("elem_master") and _master_element != "":
		result.append({"name": Lang.t("Mistrz Żywiołów"), "kind": "good", "left": -1.0, "icon": ICONS["elem_master"],
				"description": Lang.t("Twoje trafienia zadają: %s, +%d%% obrażeń") % [Elements.name_of(_master_element).to_lower(), roundi(MASTER_BONUS * 100.0)]})
	var mind := full_mind_bonus()
	if mind > 0.0:
		result.append({"name": Lang.t("Pełnia umysłu"), "kind": "good", "left": -1.0, "icon": ICONS["full_mind"],
				"description": Lang.t("+%d%% obrażeń przy wysokiej manie") % roundi(mind * 100.0)})
	if _full_power():
		result.append({"name": Lang.t("Pełnia Mocy"), "kind": "good", "left": -1.0, "icon": ICONS["full_power"],
				"description": Lang.t("+%d%% obrażeń magicznych przy pełnej manie") % roundi(FULL_POWER_BONUS * 100.0)})
	return result


## Krąg Zamieci: śnieg pada w kręgu, co chwilę rani i spowalnia wrogów; z combo / Księgą Marzanny od razu zamraża.
class _Blizzard:
	extends Node2D

	var skills: SpellSkills
	var radius := 60.0
	var damage := 0.4
	var time_left := 3.5
	var freeze := 0.0
	var _next := 0.0
	var _fade := 0.4
	var _storm: FxLoop

	func _ready() -> void:
		z_index = 3
		_storm = FxLoop.make(SpellSkills.BLIZZARD_FX, 12, 12.0, Vector2(72, 77))
		_storm.scale = Vector2.ONE * (radius / SpellSkills.BLIZZARD_FX_RADIUS)
		add_child(_storm)
		if freeze > 0.0 and is_instance_valid(skills):
			for enemy: Goblin in skills._enemies():
				if _inside(enemy):
					enemy.stun(freeze)
					skills._chill(enemy)
					SpellSkills.shatter_flash(get_parent(), enemy.hurt_center(), 0.8)

	func _inside(enemy: Goblin) -> bool:
		return enemy.state != Goblin.State.DEAD and enemy.global_position.distance_to(global_position) <= radius + enemy.hurt_radius

	func _process(delta: float) -> void:
		if time_left <= 0.0:
			_fade -= delta
			_storm.modulate.a = maxf(_fade / 0.4, 0.0)
			if _fade <= 0.0:
				queue_free()
			return
		time_left -= delta
		_next -= delta
		if _next > 0.0 or not is_instance_valid(skills) or skills._player.is_dead:
			return
		_next = Skills.BLIZZARD_TICK
		for enemy: Goblin in skills._enemies():
			if _inside(enemy):
				skills._player.hit_enemy(enemy, skills._damage(damage, "blizzard"), enemy.global_position + Vector2(0, -20), 0.0, "ice",
						Skills.tags("blizzard"))
				skills._chill(enemy)


## Kula Piorunów: leci powoli przed siebie, co chwilę razi wrogów obok; z combo na końcu wybucha.
class _Orb:
	extends Node2D

	const HEIGHT := 12.0
	var skills: SpellSkills
	var direction := Vector2.RIGHT
	var damage := 0.4
	var blast := false
	## Mnożnik obszaru (kamień wsparcia Rozległość) - zasięg wyładowań i wybuchu.
	var area := 1.0
	var _travelled := 0.0
	var _next := 0.1
	var _sprite: FxLoop

	func _ready() -> void:
		z_index = 4
		_sprite = FxLoop.make(SpellSkills.ORB_FX, 8, 16.0, Vector2(22, 22))
		_sprite.position = Vector2(0, -HEIGHT)
		add_child(_sprite)

	func _process(delta: float) -> void:
		if not is_instance_valid(skills):
			queue_free()
			return
		position += direction * Skills.ORB_SPEED * delta
		_travelled += Skills.ORB_SPEED * delta
		_next -= delta
		if _next <= 0.0:
			_next = Skills.ORB_TICK
			_zap()
		if _travelled >= Skills.ORB_RANGE:
			if blast:
				_explode()
			queue_free()

	func _zap() -> void:
		var center := global_position + Vector2(0, -HEIGHT)
		var count := 0
		for enemy: Goblin in skills._enemies():
			if count >= 4:
				break
			if enemy.state != Goblin.State.DEAD and enemy.hurt_center().distance_to(center) <= Skills.ORB_RADIUS * area + enemy.hurt_radius:
				count += 1
				SpellSkills.lightning(get_parent(), center, enemy.hurt_center())
				skills._player.hit_enemy(enemy, skills._damage(damage, "ball_lightning"), center, 20.0, "lightning", Skills.tags("ball_lightning"))
		if count > 0:
			Sfx.play_at("zap", global_position, -8.0)

	func _explode() -> void:
		var center := global_position + Vector2(0, -HEIGHT)
		SkillEffects.sheet_once(get_parent(), SpellSkills.ORB_BLAST_FX, 7, 18.0, center, Vector2(73, 50), 0.0, 1.0,
				Skills.ORB_BLAST * area / SpellSkills.ORB_BLAST_RADIUS)
		Sfx.play_at("thunder", global_position, -4.0)
		for enemy: Goblin in skills._enemies():
			if enemy.state != Goblin.State.DEAD and enemy.global_position.distance_to(global_position) <= Skills.ORB_BLAST * area + enemy.hurt_radius:
				skills._player.hit_enemy(enemy, skills._damage(damage * 3.0, "ball_lightning"), global_position, 120.0, "lightning",
						Skills.tags("ball_lightning"))


## Spadająca Gwiazda: cień na ziemi rośnie, gwiazda spada z nieba i wybucha (SpellSkills.meteor_impact).
class _Meteor:
	extends Node2D

	const FALL_FROM := Vector2(90, -180)
	var skills: SpellSkills
	var radius := 60.0
	var damage := 3.0
	var _time := 0.0
	var _sprite: FxLoop

	func _ready() -> void:
		z_index = 5
		# płonący kamień rysowany w prawo - obrócony w kierunku spadania (płomienie za nim)
		_sprite = FxLoop.make(SpellSkills.METEOR_FX, 8, 16.0, Vector2(45, 15))
		_sprite.position = FALL_FROM
		_sprite.rotation = (-FALL_FROM).angle()
		_sprite.flip_v = absf(_sprite.rotation) > PI / 2.0
		add_child(_sprite)

	func _process(delta: float) -> void:
		_time += delta
		var t := clampf(_time / Skills.METEOR_DELAY, 0.0, 1.0)
		_sprite.position = FALL_FROM * (1.0 - t * t)
		queue_redraw()
		if t >= 1.0:
			if is_instance_valid(skills):
				skills.meteor_impact(global_position, radius, damage)
			queue_free()

	func _draw() -> void:
		var t := clampf(_time / Skills.METEOR_DELAY, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius * lerpf(0.2, 1.0, t), Color(0.1, 0.03, 0.0, 0.3))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.5, 0.2, 0.3 + 0.5 * t), 1.5)


## Kamień Runiczny: stoi, świeci krąg; gracz w kręgu dostaje premię (SpellSkills._update_temp).
class _Rune:
	extends Node2D

	var time_left := 15.0
	var leaving := false
	var _sprite: FxLoop

	func _ready() -> void:
		var circle := FxLoop.make(SpellSkills.RUNE_CIRCLE_FX, 12, 8.0, Vector2(76, 48))
		circle.scale = Vector2.ONE * (Skills.RUNE_RADIUS / SpellSkills.RUNE_CIRCLE_RADIUS)
		add_child(circle)
		_sprite = FxLoop.make(SpellSkills.RUNE_FX, 8, 8.0, Vector2(15, 39))
		add_child(_sprite)
		SkillEffects.sheet_once(get_parent(), SpellSkills.BLINK_FX, 8, 14.0, global_position + Vector2(0, -12), Vector2(23, 21))
		_sprite.scale = Vector2(0.8, 0.0)
		create_tween().tween_property(_sprite, "scale", Vector2.ONE * 0.8, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
		time_left -= delta
		if time_left <= 0.0:
			leave()


## Bańka z heksagonów wokół postaci w czasie Tarczy Many (zapętlona, z kreatora efektów; jaśniejsza, gdy przyjmuje
## całe ciosy).
class _ShieldRing:
	extends Node2D

	var skills: SpellSkills
	var _bubble: FxLoop

	func _ready() -> void:
		z_index = 1
		_bubble = FxLoop.make(SpellSkills.SHIELD_FX, 8, 10.0, Vector2(24, 24))
		add_child(_bubble)

	func _process(_delta: float) -> void:
		if visible:
			var full := is_instance_valid(skills) and skills._shield_full > 0.0
			_bubble.modulate = Color(1.5, 1.5, 1.6) if full else Color.WHITE
