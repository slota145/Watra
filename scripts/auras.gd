class_name Auras
extends Node2D
## Aury rezerwujące manę (docs/plan_drzewek.md, krok 3; jak aury w Path of Exile) - dziecko gracza.
## Aura to umiejętność wspólnego drzewka (Skills.DATA, type "aura", weapon "any" - działa z każdą bronią). Klawisz
## paska ją włącza albo wyłącza; włączona działa bez końca i rezerwuje część maksymalnej many (AuraData.RESERVE - ułamek
## pełnej many; węzły Skupiona wola i Oszczędne aury zmniejszają rezerwację - SkillTree "aura_reservation").
## Zarezerwowana mana znika z paska (CharacterStats.max_mana zwraca resztę), więc kilka aur naraz zostawia mało many
## na umiejętności. Węzeł kluczowy Krwawa Ofiara: aury rezerwują zdrowie zamiast many.
## Włączone aury trzyma SkillBook.auras (zapis gry); ich premie do statystyk liczy SkillBook.aura_bonus
## (CharacterStats._bonus), a to, czego nie da się zapisać premią (piorun Gniewu Peruna, lodowy wir Mroźnego Oddechu,
## Postrach), robi ten węzeł. Rysuje też kręgi włączonych aur pod postacią.
## Siła aury rośnie z jej poziomem (Skills.power, poziomy 1-20 za punkty umiejętności). Liczby i opisy - AuraData.


var _player: Player
var _wrath_next := AuraData.WRATH_INTERVAL
var _breath_next := AuraData.BREATH_TICK
var _breath_self := 0.0
var _spin := 0.0


func _init(player: Player) -> void:
	_player = player
	name = "Auras"
	show_behind_parent = true


# ---------------------------------------------------------------- włączanie
## Klawisz aury: włącza albo wyłącza. Zwraca, czy coś się zmieniło.
func toggle(id: String) -> bool:
	var book := _player.skills
	if book.level_of(id) <= 0:
		_player._hint(Lang.t("Wybierz %s w drzewku umiejętności (K)") % Skills.name_of(id))
		return false
	if book.auras.has(id):
		book.set_aura(id, false)
		Sfx.play("ui_click")
		return true
	var reason := book.aura_block_reason(id, _player.stats, _player.mana, _player.health)
	if reason != "":
		_player._hint(reason)
		return false
	book.set_aura(id, true)
	if id in ["perun_sparks", "perun_wrath"]:
		Sfx.play_at("zap", _player.global_position, -8.0)
	else:
		Sfx.play("ui_click")
	return true


func is_on(id: String) -> bool:
	return _player.skills.auras.has(id)


# ---------------------------------------------------------------- działanie
func _physics_process(delta: float) -> void:
	var auras: Array = _player.skills.auras
	visible = not auras.is_empty()
	if auras.is_empty() or _player.is_dead:
		return
	_spin += delta
	queue_redraw()
	if auras.has("perun_wrath"):
		_wrath_next -= delta
		if _wrath_next <= 0.0:
			_wrath_next = AuraData.WRATH_INTERVAL
			_wrath()
	if auras.has("frost_breath"):
		_breath_next -= delta
		if _breath_next <= 0.0:
			_breath_next = AuraData.BREATH_TICK
			_breath()
		_burn_self(delta)


func _level(id: String) -> int:
	return _player.skills.level_of(id)


## Gniew Peruna: piorun z nieba w losowego wroga w zasięgu.
func _wrath() -> void:
	var tags := Skills.tags("perun_wrath")
	var near := _near(AuraData.WRATH_RANGE * _player.stats.area_multiplier(tags))
	if near.is_empty():
		_wrath_next = 0.4
		return
	var target: Goblin = near.pick_random()
	SkillEffects.sheet_once(_player.get_parent(), SpellSkills.STORM_FX, 7, 20.0, target.hurt_center(), Vector2(25, 141))
	Sfx.play_at("zap", target.global_position, -4.0)
	var amount := _player._skill_damage(AuraData.wrath_damage(_level("perun_wrath")), tags)
	_player.hit_enemy(target, amount, target.global_position + Vector2(0, -20), 30.0, "lightning", tags)


## Mroźny Oddech: rana od lodu wszystkim wrogom w wirze.
func _breath() -> void:
	var tags := Skills.tags("frost_breath")
	var reach := AuraData.BREATH_RADIUS * _player.stats.area_multiplier(tags)
	var multiplier := AuraData.breath_damage(_level("frost_breath"))
	for enemy: Goblin in _near(reach):
		_player.hit_enemy(enemy, _player._skill_damage(multiplier, tags), _player.global_position, 0.0, "ice", tags)


## Mroźny Oddech rani też gracza (mniej z odpornością na lód), ale nie zabija.
func _burn_self(delta: float) -> void:
	_breath_self += _player.stats.max_health() * AuraData.BREATH_SELF * _player.stats.taken_multiplier(Elements.COLD) * delta
	var whole := int(_breath_self)
	if whole <= 0:
		return
	_breath_self -= whole
	var lost := mini(whole, _player.health - 1)
	if lost > 0:
		_player.health -= lost
		_player.health_changed.emit(_player.health, _player.stats.max_health())


func _near(reach: float) -> Array[Goblin]:
	var found: Array[Goblin] = []
	for node in _player.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Goblin
		if enemy != null and enemy.state != Goblin.State.DEAD and enemy.global_position.distance_to(_player.global_position) <= reach:
			found.append(enemy)
	return found


## Postrach: mnożnik obrażeń ciosu wroga z pozycji `from` (1.0 - bez Postrachu albo poza kręgiem).
func dread_hit(from: Vector2) -> float:
	if not is_on("dread") or from.distance_to(_player.global_position) > AuraData.DREAD_RADIUS:
		return 1.0
	return 1.0 - AuraData.dread_damage(_level("dread"))


## Postrach: mnożnik odstępu między atakami wroga na pozycji `at` (Goblin._process_attack).
func dread_cooldown(at: Vector2) -> float:
	if not is_on("dread") or at.distance_to(_player.global_position) > AuraData.DREAD_RADIUS:
		return 1.0
	return 1.0 + AuraData.dread_slow(_level("dread"))


## Ikony włączonych aur pod paskami zdrowia i many (StatusEffects).
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var book := _player.skills
	for id: String in book.auras:
		var reserved := book.aura_reserve(id)
		var cost := Lang.t("Rezerwuje %d%% zdrowia") % roundi(reserved * 100) if book.has_keystone("blood_offering") \
				else Lang.t("Rezerwuje %d%% many") % roundi(reserved * 100)
		result.append({"name": Skills.name_of(id), "kind": "good", "left": -1.0, "icon": Skills.get_data(id)["icon"],
				"description": "%s\n%s" % [AuraData.effect_text(id, _level(id)), cost if reserved > 0.0 else AuraData.cost_text(id)]})
	return result


# ---------------------------------------------------------------- wygląd
## Kręgi włączonych aur pod stopami: po jednym na aurę, z kropkami krążącymi w jej kolorze; Mroźny Oddech i Postrach
## pokazują swój zasięg.
func _draw() -> void:
	var auras: Array = _player.skills.auras
	var feet := Vector2(0, 2)
	for i in auras.size():
		var id: String = auras[i]
		var color: Color = AuraData.COLORS.get(id, Color.WHITE)
		var radius := 13.0 + i * 3.0
		var squash := Vector2(1.0, 0.45)
		_ellipse(feet, radius, squash, Color(color, 0.6), 1.0)
		for k in 3:
			var angle := _spin * (1.4 - i * 0.1) * (1.0 if i % 2 == 0 else -1.0) + k * TAU / 3.0
			draw_circle(feet + Vector2(cos(angle), sin(angle)) * radius * squash, 1.4, Color(color.lightened(0.3), 0.95))
	if auras.has("frost_breath"):
		var reach := AuraData.BREATH_RADIUS * _player.stats.area_multiplier(Skills.tags("frost_breath"))
		var color: Color = AuraData.COLORS["frost_breath"]
		_ellipse(feet, reach, Vector2(1.0, 0.55), Color(color, 0.4), 1.5)
		for k in 8:
			var angle := -_spin * 2.2 + k * TAU / 8.0
			var r := reach * (0.4 + 0.55 * fposmod(k * 0.37 + _spin * 0.6, 1.0))
			draw_circle(feet + Vector2(cos(angle), sin(angle) * 0.55) * r, 1.0, Color(0.9, 0.97, 1.0, 0.7))
	if auras.has("dread"):
		_ellipse(feet, AuraData.DREAD_RADIUS, Vector2(1.0, 0.55), Color(AuraData.COLORS["dread"], 0.22 + 0.08 * sin(_spin * 2.0)), 1.0)


func _ellipse(center: Vector2, radius: float, squash: Vector2, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for k in 33:
		var angle := k * TAU / 32.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * squash)
	draw_polyline(points, color, width)
