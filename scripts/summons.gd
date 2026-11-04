class_name Summons
extends Node
## Przywołania rezerwujące manę (docs/plan_drzewek.md, krok 5 - przywołania) - dziecko gracza, jak Auras.
## Klawisz paska przywołuje albo odsyła; przywołańcy zostają bez końca i rezerwują część pełnej many (SkillBook.summons,
## rezerwację liczy SkillBook.aura_reserve razem z aurami - węzły Skupiona wola i Oszczędne aury też działają).
## Liczby i opisy - SummonData. Przywołanie działa tylko z bronią swojej umiejętności - po zmianie broni znika.
## - Wataha (_Wolf): widmowe wilki biegną do wrogów przy graczu, gryzą i czasem powalają (Goblin.stun);
## - Błędne Ogniki (_Wisp): krążą przy graczu i strzelają ognistymi pociskami (Projectile "fire");
## - Wierny tropiciel (_Seeker, id "seeker"): widmowa strzała krąży przy graczu i sama wypuszcza Strzały tropiące
##   (Player.seeker_arrow); klawisz Strzały tropiącej z węzłem loyal_seeker przywołuje ją zamiast strzelać.
## Wilki i ogniki mają zdrowie (ułamek zdrowia postaci - SummonData.health_share, więcej z kamieniem Watażka):
## trafiony przez nie wróg bierze je za cel (Goblin.objective), gdy gracz jest dalej; zabity przywołaniec wraca po
## SummonData.RESPAWN s. Obrażenia: Player._skill_damage z tagami umiejętności (kamienie wsparcia, atrybuty), razy
## premia węzłów Przewodnik stada i Wierne ogniki (SkillTree "minion_damage").

const WOLF_SHEET := preload("res://assets/forest/wolf.png")
const WISP_SHEET := preload("res://assets/summons/wisp_fire.png")
const SHADOW := preload("res://assets/shadow.png")

var _player: Player
## id przywołania -> żywi przywołańcy (węzły w świecie)
var _minions := {}
## id przywołania -> sekundy do powrotu zabitych
var _respawn := {}
var _warned := ""


func _init(player: Player) -> void:
	_player = player
	name = "Summons"


# ---------------------------------------------------------------- przywoływanie
## Klawisz przywołania: przywołuje albo odsyła. Zwraca, czy coś się zmieniło.
func toggle(id: String) -> bool:
	var book := _player.skills
	if not book.can_summon(id):
		_player._hint(Lang.t("Wybierz %s w drzewku umiejętności (K)") % Skills.name_of(id))
		return false
	if book.summons.has(id):
		book.set_summon(id, false)
		Sfx.play("ui_click")
		return true
	var reason := book.aura_block_reason(id, _player.stats, _player.mana, _player.health)
	if reason != "":
		_player._hint(reason)
		return false
	book.set_summon(id, true)
	Sfx.play("magic", -4.0, 0.7)
	return true


func is_on(id: String) -> bool:
	return _player.skills.summons.has(id)


## Żywi przywołańcy danego przywołania (testy, legendy).
func alive(id: String) -> Array:
	var result := []
	for minion in _minions.get(id, []):
		if is_instance_valid(minion) and not minion.leaving:
			result.append(minion)
	return result


## Ikony przywołań pod paskami zdrowia i many (StatusEffects): ilu żyje i ile rezerwują.
func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var book := _player.skills
	for id: String in book.summons:
		var icon: Texture2D = preload("res://assets/skills/node_loyal_seeker.png") if id == "seeker" else Skills.get_data(id)["icon"]
		var text := SummonData.effect_text(id, book.level_of(id), book.summon_count(id) - SummonData.count(id, book.level_of(id)))
		var reserved := book.aura_reserve(id)
		var cost := Lang.t("Rezerwuje %d%% zdrowia") % roundi(reserved * 100) if book.has_keystone("blood_offering") \
				else Lang.t("Rezerwuje %d%% many") % roundi(reserved * 100)
		result.append({"name": _name(id), "kind": "good", "left": -1.0, "icon": icon,
				"description": "%s\n%s\n%s" % [text, Lang.t("Przy tobie: %d") % alive(id).size(), cost]})
	return result


# ---------------------------------------------------------------- utrzymanie liczby
func _physics_process(delta: float) -> void:
	var book := _player.skills
	var weapon := _player.stats.weapon_type()
	for id: String in book.summons.duplicate():
		if SummonData.WEAPON[id] != weapon:
			book.set_summon(id, false)
			_player._hint(Lang.t("%s odchodzi - działa z bronią: %s") % [_name(id), Skills.weapon_name(SummonData.WEAPON[id]).to_lower()])
	for id: String in SummonData.RESERVE:
		_keep(id, delta)


func _name(id: String) -> String:
	return Lang.t("Wierny tropiciel") if id == "seeker" else Skills.name_of(id)


## Pilnuje liczby przywołańców: zabici wracają po czasie, nowi pojawiają się od razu, nadmiarowi odchodzą.
func _keep(id: String, delta: float) -> void:
	var book := _player.skills
	var want := book.summon_count(id) if book.summons.has(id) and not _player.is_dead else 0
	var list: Array = _minions.get(id, [])
	var timers: Array = _respawn.get(id, [])
	# węzły zniknięte bez śmierci (zmiana krainy) wracają od razu
	list = list.filter(func(m) -> bool: return is_instance_valid(m) and not m.leaving)
	for i in range(timers.size() - 1, -1, -1):
		timers[i] -= delta
		if timers[i] <= 0.0:
			timers.remove_at(i)
	while list.size() + timers.size() > want:
		if not timers.is_empty():
			timers.pop_back()
		else:
			var extra: _Minion = list.pop_back()
			extra.leave()
	if want > 0:
		while list.size() + timers.size() < want:
			list.append(_spawn(id, list.size()))
	_minions[id] = list
	_respawn[id] = timers


## Zabity przywołaniec (wilk, ognik) wraca po SummonData.RESPAWN s.
func _died(id: String) -> void:
	var timers: Array = _respawn.get(id, [])
	timers.append(SummonData.RESPAWN)
	_respawn[id] = timers


func _spawn(id: String, index: int) -> _Minion:
	var minion: _Minion
	match id:
		"wolf_pack":
			minion = _Wolf.new()
		"wisps":
			minion = _Wisp.new()
		_:
			minion = _Seeker.new()
	minion.summons = self
	minion.player = _player
	minion.id = id
	minion.index = index
	var level := _player.skills.level_of(id)
	minion.max_health = maxf(_player.stats.max_health() * SummonData.health_share(id, level) * (1.0 + _player.support(id, "duration")), 1.0)
	minion.health = minion.max_health
	minion.position = _player.global_position + Vector2.from_angle(randf() * TAU) * 14.0
	_player.get_parent().add_child(minion)
	MiscVfx.puff(_player.get_parent(), minion.global_position + Vector2(0, -6), SummonData.COLORS[id], 0.45)
	return minion


## Obrażenia przywołańca: procent obrażeń broni z poziomu i premie (kamienie wsparcia, węzły przywołań).
func damage_of(id: String) -> int:
	var multiplier := SummonData.damage(id, _player.skills.level_of(id)) * (1.0 + _player.skills.tree_bonus("minion_damage"))
	return _player._skill_damage(multiplier, Skills.tags(id))


static func _nearest(tree: SceneTree, at: Vector2, reach: float) -> Goblin:
	var best: Goblin
	var best_distance := reach
	for enemy: Goblin in Goblin.near(tree, at, reach):
		var distance := enemy.global_position.distance_to(at)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


# ---------------------------------------------------------------- przywołańcy
## Wspólna część przywołańców: zdrowie, cel dla potworów (Goblin.objective: is_alive, hit_radius, take_hit), odejście.
class _Minion:
	extends Node2D

	var summons: Summons
	var player: Player
	var id := ""
	var index := 0
	var max_health := 10.0
	var health := 10.0
	var hit_radius := 6.0
	var leaving := false
	## wrogowie, którzy wzięli przywołańca za cel - przy odejściu dostają go z powrotem na gracza
	var _taunted: Array[Goblin] = []
	var _flash := 0.0

	func is_alive() -> bool:
		return not leaving and health > 0.0

	## Cios potwora (Goblin._process_objective).
	func take_hit(amount: float) -> void:
		if not is_alive():
			return
		health -= amount * SummonData.TAKEN
		_flash = 0.15
		if health <= 0.0:
			summons._died(id)
			leave()

	## Trafiony wróg bierze przywołańca za cel (gdy nie ma innego - np. Kryształu Watry).
	func taunt(enemy: Goblin) -> void:
		if not has_hit_points() or not is_instance_valid(enemy) or enemy.objective != null and is_instance_valid(enemy.objective):
			return
		enemy.objective = self
		_taunted.append(enemy)

	func has_hit_points() -> bool:
		return true

	## Odejście (odesłanie albo śmierć): rozwiewa się w kłąb w kolorze przywołania.
	func leave() -> void:
		if leaving:
			return
		leaving = true
		for enemy: Goblin in _taunted:
			if is_instance_valid(enemy) and enemy.objective == self:
				enemy.objective = null
		_taunted.clear()
		if is_inside_tree():
			MiscVfx.puff(get_parent(), global_position + Vector2(0, -6), SummonData.COLORS.get(id, Color.WHITE), 0.45)
		queue_free()

	func _process(delta: float) -> void:
		if not is_instance_valid(player):
			queue_free()
			return
		_flash = maxf(_flash - delta, 0.0)
		# za daleko od gracza (portal, skok) - wraca do niego
		if global_position.distance_to(player.global_position) > SummonData.WOLF_LEASH * 1.6:
			global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 16.0
		queue_redraw()

	## Pasek zdrowia nad przywołańcem, gdy jest ranny.
	func _draw_health(height: float) -> void:
		if not has_hit_points() or health >= max_health:
			return
		var width := 14.0
		var at := Vector2(-width * 0.5, -height)
		draw_rect(Rect2(at, Vector2(width, 2)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(at, Vector2(width * clampf(health / max_health, 0.0, 1.0), 2)), SummonData.COLORS.get(id, Color.WHITE))


## Widmowy wilk Watahy: biegnie do wroga najbliżej siebie (w zasięgu od gracza), gryzie, czasem powala.
class _Wolf:
	extends _Minion

	var _sprite: Sprite2D
	var _target: Goblin
	var _bite := 0.0
	var _run := 0.0
	var _lunge := 0.0
	var _look := 0.0

	func _ready() -> void:
		var shadow := Sprite2D.new()
		shadow.texture = Summons.SHADOW
		shadow.position = Vector2(0, -1)
		shadow.scale = Vector2(1.9, 1)
		shadow.modulate.a = 0.5
		add_child(shadow)
		_sprite = Sprite2D.new()
		_sprite.texture = Summons.WOLF_SHEET
		_sprite.hframes = 4
		_sprite.vframes = 3
		_sprite.offset = Vector2(0, -14.5)
		add_child(_sprite)
		_bite = randf_range(0.0, 0.4)

	func _process(delta: float) -> void:
		super(delta)
		if leaving or not is_instance_valid(player):
			return
		# widmowa poświata: chłodny błękit, lekko przezroczysty, błysk przy ciosie potwora
		var pulse := 0.85 + 0.1 * sin(Time.get_ticks_msec() * 0.004 + index)
		_sprite.modulate = Color(1.4, 0.6, 0.6, 0.9) if _flash > 0.0 else Color(0.75 * pulse, 0.95 * pulse, 1.35 * pulse, 0.82)
		_bite = maxf(_bite - delta, 0.0)
		_lunge = maxf(_lunge - delta, 0.0)
		if player.is_dead:
			return
		if not _valid(_target) or _target.global_position.distance_to(player.global_position) > SummonData.WOLF_SEEK_RANGE * 1.3:
			_target = Summons._nearest(get_tree(), global_position, SummonData.WOLF_SEEK_RANGE) \
					if player.global_position.distance_to(global_position) < SummonData.WOLF_LEASH else null
			if _target != null and _target.global_position.distance_to(player.global_position) > SummonData.WOLF_SEEK_RANGE:
				_target = null
		if _target != null:
			_chase(delta)
		else:
			_follow(delta)

	func _valid(enemy: Goblin) -> bool:
		return is_instance_valid(enemy) and enemy.state != Goblin.State.DEAD

	func _chase(delta: float) -> void:
		var to := _target.global_position - global_position
		var reach := SummonData.WOLF_REACH + _target.hurt_radius
		if to.length() > reach:
			_move(to.normalized() * SummonData.WOLF_SPEED * delta, to)
			return
		_sprite.flip_h = to.x < 0.0
		if _lunge > 0.0:
			_sprite.frame = 9
			return
		_sprite.frame = 8
		if _bite <= 0.0:
			_bite = SummonData.WOLF_BITE_INTERVAL / player._skill_speed(Skills.tags(id))
			_lunge = 0.2
			var amount := summons.damage_of(id)
			player.hit_enemy(_target, amount, global_position, 25.0, "", Skills.tags(id))
			MiscVfx.spark(get_parent(), _target.hurt_center(), SummonData.COLORS[id], 0.5)
			if randf() < SummonData.WOLF_STUN_CHANCE and _valid(_target):
				_target.stun(SummonData.WOLF_STUN)
			taunt(_target)

	## Bez wroga: trzyma się blisko gracza (każdy wilk w swoim miejscu za nim).
	func _follow(delta: float) -> void:
		var slot := player.global_position + Vector2.from_angle(PI * 0.5 + (index - 1) * 0.9) * 22.0
		var to := slot - global_position
		if to.length() > 6.0:
			var speed := SummonData.WOLF_SPEED * (1.0 if to.length() > 40.0 else 0.6)
			_move(to.normalized() * minf(speed * delta, to.length()), to)
		else:
			_sprite.frame = 0
			_look += delta
			_sprite.flip_h = player.global_position.x < global_position.x

	func _move(step: Vector2, to: Vector2) -> void:
		global_position += step
		_run += step.length() * 0.12
		_sprite.frame = int(_run) % 4
		_sprite.flip_h = to.x < 0.0

	func _draw() -> void:
		_draw_health(28.0)


## Błędny Ognik: krąży wokół gracza i co chwilę strzela ognistym pociskiem w najbliższego wroga.
class _Wisp:
	extends _Minion

	var _sprite: Sprite2D
	var _shot := 0.0
	var _anim := 0.0
	var _angle := 0.0

	func _ready() -> void:
		hit_radius = 5.0
		_sprite = Sprite2D.new()
		_sprite.texture = Summons.WISP_SHEET
		_sprite.hframes = 4
		_sprite.vframes = 2
		_sprite.offset = Vector2(0, -8)
		add_child(_sprite)
		_shot = randf_range(0.2, SummonData.WISP_INTERVAL)
		_angle = randf() * TAU

	func _process(delta: float) -> void:
		super(delta)
		if leaving or not is_instance_valid(player):
			return
		_anim += delta * 10.0
		_sprite.frame = int(_anim) % 8
		_sprite.modulate = Color(1.6, 0.6, 0.6) if _flash > 0.0 else Color(1, 1, 1, 0.92)
		var count := maxi(summons.alive(id).size(), 1)
		_angle += delta * 1.6
		var phase := _angle + TAU * index / count
		var goal := player.global_position + Vector2(cos(phase), sin(phase) * 0.6) * SummonData.WISP_ORBIT + Vector2(0, -14)
		global_position = global_position.lerp(goal, minf(delta * 6.0, 1.0))
		_shot -= delta
		if _shot <= 0.0 and not player.is_dead:
			var target := Summons._nearest(get_tree(), global_position, SummonData.WISP_RANGE)
			_shot = SummonData.WISP_INTERVAL / player._skill_speed(Skills.tags(id)) if target != null else 0.3
			if target != null:
				_fire(target)

	func _fire(target: Goblin) -> void:
		var dir := global_position.direction_to(target.hurt_center())
		var amount := summons.damage_of(id)
		for shot: Vector2 in Player.split_directions(dir, player.support_count(id, "projectiles")):
			var bolt := player._make_projectile(player.equipment.weapon(), shot, id, Skills.tags(id))
			bolt.position = global_position + Vector2(0, Projectile.HEIGHT) + shot * 4.0
			bolt.damage_min = maxi(1, roundi(amount * 0.9))
			bolt.damage_max = maxi(1, roundi(amount * 1.1))
			bolt.speed = SummonData.WISP_SPEED
			bolt.max_range = SummonData.WISP_RANGE * 1.2
			bolt.fx_kind = "fire"
			bolt.size = 0.45
			bolt.sound = "fire"
			bolt.knockback = 10.0
			bolt.enemy_hit.connect(taunt)
			player.get_parent().add_child(bolt)
		Sfx.play_at("magic", global_position, -12.0)

	func _draw() -> void:
		_draw_health(22.0)


## Wierny tropiciel: widmowa strzała krąży wokół gracza i sama wypuszcza Strzały tropiące. Bez zdrowia.
class _Seeker:
	extends _Minion

	var _shot := 0.6
	var _angle := 0.0
	var _trail: Array[Vector2] = []

	func has_hit_points() -> bool:
		return false

	func is_alive() -> bool:
		return false

	func _process(delta: float) -> void:
		super(delta)
		if leaving or not is_instance_valid(player):
			return
		_angle += delta * 3.2
		var goal := player.global_position + Vector2(cos(_angle) * 20.0, sin(_angle) * 11.0 - 16.0)
		global_position = global_position.lerp(goal, minf(delta * 10.0, 1.0))
		_trail.push_front(global_position)
		if _trail.size() > 8:
			_trail.pop_back()
		_shot -= delta
		if _shot <= 0.0 and not player.is_dead:
			var target := Summons._nearest(get_tree(), player.global_position, SummonData.SEEKER_RANGE)
			_shot = SummonData.SEEKER_INTERVAL / player._skill_speed(Skills.tags("seeker")) if target != null else 0.3
			if target != null:
				player.seeker_arrow(player.skills.level_of("seeker"), global_position + Vector2(0, 16),
						global_position.direction_to(target.hurt_center()))

	func _draw() -> void:
		var color: Color = SummonData.COLORS["seeker"]
		for i in range(_trail.size() - 1):
			draw_line(to_local(_trail[i]), to_local(_trail[i + 1]), Color(color, 0.5 * (1.0 - i / 8.0)), 2.0)
		var dir := Vector2(-sin(_angle) * 20.0, cos(_angle) * 11.0).normalized()
		draw_line(-dir * 6.0, dir * 6.0, Color(0.85, 1.0, 0.92), 1.0)
		draw_colored_polygon(PackedVector2Array([dir * 8.0, dir * 4.0 + dir.orthogonal() * 2.5, dir * 4.0 - dir.orthogonal() * 2.5]), color.lightened(0.4))
		draw_circle(Vector2.ZERO, 3.5, Color(color, 0.25))
