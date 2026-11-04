extends SceneTree
## Krok 5 wspólnego drzewka, strefy pośrednie: umiejętności z dwiema broniami (Ciśnięte Noże, Strzała Gromu,
## Zaklęte Ostrze - inne z każdą bronią), węzły Otwarte rany, Impet, Zwiewność i węzeł kluczowy Żelazna Wola.

const S := preload("res://scripts/skills.gd")

## Test nie liczy klatek: każdy krok czeka na wynik (z limitem czasu), bo klatki w trybie bez okna mają różną długość.
## Każdy krok dostaje świeżego wroga na pustej „arenie” (bez przeszkód i innych wrogów w pobliżu), żeby pociski
## nie trafiały w ściany ani przypadkowych wrogów, a krwawienie i podpalenie z poprzednich kroków nie myliły wyniku.

## Wrogowie są typu Node, a stan 4 to Goblin.State.DEAD: typ Goblin skompilowałby goblin.gd przed autoloadami (Sfx).
const WAIT := 4.0
## Prostokąt bez przeszkód i wrogów wokół gracza na arenie (pociski lecą w prawo do 280 px).
const ARENA_SIZE := Vector2(720, 260)

var _world: Node
var _fails := 0
var _enemy: Node
var _hp := 0
var _arena := Vector2.ZERO
var _used: Array[Node] = []


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


## Czeka, aż warunek się spełni (najwyżej `seconds` sekund); zwraca, czy się spełnił.
func _until(cond: Callable, seconds := WAIT) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > end:
			return false
		await process_frame
	return true


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	await _frames(5)
	var p = _world.player
	var zs = p.zone_skills
	# dane: z którą bronią działa która umiejętność
	check("Noże: miecz i łuk", S.works_with("thrown_knives", "melee") and S.works_with("thrown_knives", "bow")
			and not S.works_with("thrown_knives", "spell"))
	check("Grom: łuk i księga", S.works_with("thunder_arrow", "bow") and S.works_with("thunder_arrow", "spell")
			and not S.works_with("thunder_arrow", "melee"))
	check("Ostrze: miecz i księga", S.works_with("enchanted_blade", "melee") and S.works_with("enchanted_blade", "spell")
			and not S.works_with("enchanted_blade", "bow"))
	check("tagi odmiany: Grom z łuku to atak", "attack" in S.tags("thunder_arrow", "bow") and not "spell" in S.tags("thunder_arrow", "bow"))
	check("tagi odmiany: Grom z księgi to czar", "spell" in S.tags("thunder_arrow", "spell") and not "attack" in S.tags("thunder_arrow", "spell"))
	check("tagi: znacznik umiejętności", S.skill_of(S.tags("enchanted_blade", "melee")) == "enchanted_blade")
	check("nazwa dwóch broni", S.weapon_name("melee/bow") != "" and "/" not in S.weapon_name("melee/bow"), S.weapon_name("melee/bow"))
	var hotbar = load("res://scripts/hotbar.gd")
	check("pasek: Noże pasują do miecza i łuku", hotbar.fits("thrown_knives", 3, "melee") and hotbar.fits("thrown_knives", 3, "bow")
			and not hotbar.fits("thrown_knives", 3, "spell"))
	_unlock(p)
	check("nowe umiejętności w drzewku", ["thrown_knives", "thunder_arrow", "enchanted_blade"].all(func(id: String) -> bool:
			return p.skills.level_of(id) > 0))
	check("nowe węzły wybrane", ["open_wounds", "momentum", "lightness", "iron_will"].all(
			func(id: String) -> bool: return p.skills.has_node_id(id)))
	_arena = _find_arena(p.global_position)
	check("pusta arena", _arena != Vector2.INF, str(_arena))
	if _arena == Vector2.INF:
		_finish()
		return

	# Ciśnięte Noże z mieczem - noże wracają
	p.equipment.equip("iron_sword")
	await _stage(p)
	_press(p, "thrown_knives")
	check("odnowienie Noży", p.cooldown_of("thrown_knives").x > 0.0)
	check("noże z miecza lecą", _count(_zone()._Knife) == S.KNIVES_COUNT, str(_count(_zone()._Knife)))
	check("noże z miecza ranią", await _until(_hurt), "%d -> %d" % [_hp, _now()])
	check("noże z miecza wracają", await _until(func() -> bool: return _count(_zone()._Knife) == 0), str(_count(_zone()._Knife)))

	# Ciśnięte Noże z łukiem - zwykłe pociski z nożem
	p.equipment.equip("short_bow")
	await _stage(p)
	_press(p, "thrown_knives")
	var knives := _projectiles("knife")
	check("noże z łuku to pociski", knives.size() == S.KNIVES_COUNT and knives[0].max_range == S.KNIVES_BOW_RANGE, str(knives.size()))
	check("noże z łuku ranią", await _until(_hurt), "%d -> %d" % [_hp, _now()])

	# Strzała Gromu z łuku: przeskok na drugiego wroga
	await _stage(p, true)
	var other: Node = _other
	var other_hp: int = other.health
	_press(p, "thunder_arrow")
	var bolts := _projectiles("thunder")
	check("Strzała Gromu z łuku leci", bolts.size() == 1 and "attack" in bolts[0].tags)
	check("Strzała Gromu rani", await _until(_hurt), "%d -> %d" % [_hp, _now()])
	check("Strzała Gromu przeskakuje", await _until(func() -> bool: return _hurt_other(other, other_hp)),
			"%d -> %d" % [other_hp, other.health if is_instance_valid(other) else 0])

	# z księgi: piorun z nieba rani też sąsiada
	p.equipment.equip("spellbook")
	await _stage(p, true)
	other = _other
	other_hp = other.health
	_press(p, "thunder_arrow")
	bolts = _projectiles("thunder")
	check("Strzała Gromu z księgi to czar", bolts.size() == 1 and "spell" in bolts[0].tags and not "attack" in bolts[0].tags)
	check("piorun z nieba rani też sąsiada", await _until(func() -> bool: return _hurt_other(other, other_hp)),
			"%d -> %d" % [other_hp, other.health if is_instance_valid(other) else 0])

	# Zaklęte Ostrze z księgą - sama fala
	await _stage(p)
	_press(p, "enchanted_blade")
	check("fala z księgi", _count(_zone()._FlameWave) == 1)
	check("fala z księgi dłuższa", not _waves().is_empty() and _waves()[0].reach > S.BLADE_WAVE_MELEE.x)
	check("fala rani", await _until(_hurt), "%d -> %d" % [_hp, _now()])
	check("fala podpala", not is_instance_valid(_enemy) or _enemy.state == 4 or p.spell_skills.is_burning(_enemy))

	# z mieczem: cięcie od razu, potem fala
	p.equipment.equip("iron_sword")
	await _stage(p, false, 25.0)
	_press(p, "enchanted_blade")
	check("cięcie Zaklętego Ostrza rani od razu", _hurt(), "%d -> %d" % [_hp, _now()])
	check("fala z miecza krótsza", not _waves().is_empty() and is_equal_approx(_waves()[-1].reach,
			S.BLADE_WAVE_MELEE.x * p.stats.area_multiplier(S.tags("enchanted_blade", "melee"))),
			"%d, %s" % [_count(_zone()._FlameWave), str(_waves().map(func(w: Node) -> float: return w.reach))])

	# Impet: po umiejętności ruchu następne trafienie mocniejsze
	zs.on_movement()
	check("Impet czeka", zs._impetus_time > 0.0)
	check("Impet w efektach", load("res://scripts/status_effects.gd").list(p).any(func(e: Dictionary) -> bool: return e["name"] == "Impet"))
	check("Impet: +30%", is_equal_approx(zs.damage_factor(), 1.3))
	check("Impet: tylko raz", zs.damage_factor() == 1.0)
	# Zwiewność: po uniku szybkość
	zs.cancel()
	var move: float = p.stats.move_speed()
	zs.on_dodge()
	check("Zwiewność: szybciej", p.stats.move_speed() > move and p.stats.temp_bonus.get("cast_speed", 0.0) > 0.0)
	zs._lightness_time = 0.01
	var lightness_gone := func() -> bool:
		return p.stats.temp_bonus.get("move_speed", 0.0) == 0.0 or not p.stats._temp_sources.get("lightness", {}).has("move_speed")
	check("Zwiewność mija", await _until(lightness_gone))

	# Otwarte rany: ciosy i pociski krwawią, czary bez formy nie
	await _stage(p)
	for i in 40:
		zs.on_hit(_enemy, 50, ["attack", "hit"])
	check("Otwarte rany ranią krwawieniem", await _until(_hurt), "%d -> %d" % [_hp, _now()])

	# Żelazna Wola: czary liczą siłę zamiast inteligencji
	p.stats.attributes["strength"] = 200
	p.stats.attributes["intelligence"] = 0
	var with_will: float = p.stats.attribute_damage(S.tags("fireball"))
	check("Żelazna Wola: czar z siły", with_will >= 2.0, "%.2f" % with_will)
	check("Żelazna Wola: ataki bez zmian", p.stats.attribute_damage(S.tags("multishot")) < with_will)
	_finish()


func _finish() -> void:
	print("WYNIK: %s" % ("OK" if _fails == 0 else "%d bledow" % _fails))
	quit()


var _other: Node


func _unlock(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	p.stats.level = 60
	p.skills.character_level = 60
	p.skills.bonus_points += 3000
	for id: String in Tree.nodes():
		if not Tree.nodes()[id]["region"] in ["sz", "zi", "si"] or Tree.is_soon(id) or id in ["shadow_hunter", "blood_frenzy"]:
			continue
		for step: String in Tree.path_to(id):
			if step in ["blood_offering", "echo_runes", "full_power", "shadow_hunter", "blood_sacrifice", "elem_master",
					"shadow_stalker", "falcon_eye", "hail", "last_bastion", "battle_frenzy"]:
				continue
			p.skills.take(step)
	p.mana = p.stats.max_mana()


## Kładzie umiejętność na slot paska broni w ręku (R) i zwraca jego numer.
func _put(p, id: String) -> int:
	p.hotbar.put(p.stats.weapon_type(), 4, id)
	return 4


func _full(p) -> void:
	p.mana = p.stats.max_mana()
	p.health = p.stats.max_health()
	p.zone_skills._cooldowns.clear()
	p.zone_skills._impetus_time = 0.0


func _zone() -> GDScript:
	return load("res://scripts/zone_skills.gd")


func _count(kind) -> int:
	return _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return is_instance_of(n, kind)).size()


func _waves() -> Array:
	return _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return is_instance_of(n, _zone()._FlameWave))


## Wciśnięcie i od razu puszczenie slotu z umiejętnością (żeby trzymany slot nie rzucał jej ponownie).
func _press(p, id: String) -> void:
	_full(p)
	p._press_slot(_put(p, id))
	p._held_slots[4] = false
	p._update_held_slots()


func _projectiles(kind: String) -> Array:
	return _world.get_tree().get_nodes_in_group("player_projectiles").filter(func(s: Node) -> bool:
		return is_instance_valid(s) and not s.is_queued_for_deletion() and s.fx_kind == kind)


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.health < _hp


func _hurt_other(other: Node, before: int) -> bool:
	return not is_instance_valid(other) or other.state == 4 or other.health < before


## Szuka w pobliżu gracza prostokąta bez przeszkód (świat i granica krainy) i bez wrogów; Vector2.INF - nie ma.
func _find_arena(from: Vector2) -> Vector2:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = ARENA_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1 | load("res://scripts/world.gd").BOUNDS_LAYER
	var enemies := _world.get_tree().get_nodes_in_group("enemies")
	for radius in range(0, 6000, 160):
		for i in maxi(1, radius / 40):
			var spot: Vector2 = from + Vector2.from_angle(TAU * i / maxi(1, radius / 40)) * radius
			# gracz stoi w lewej części prostokąta, pociski lecą w prawo
			query.transform = Transform2D(0.0, spot + Vector2(ARENA_SIZE.x * 0.5 - 120.0, 0))
			if not space.intersect_shape(query, 1).is_empty():
				continue
			if enemies.any(func(e: Node) -> bool: return e.global_position.distance_to(spot) < ARENA_SIZE.x + 200.0):
				continue
			return spot
	return Vector2.INF


## Przygotowuje krok: czeka, aż znikną pociski i fale poprzednich kroków, odsuwa zużytych wrogów, stawia gracza
## na arenie i świeżego wroga `distance` px na prawo (z `pair` - drugiego tuż za nim, do przeskoku i pioruna z nieba).
func _stage(p, pair := false, distance := 60.0) -> void:
	var clear := func() -> bool:
		return _world.get_tree().get_nodes_in_group("player_projectiles").is_empty() and _count(_zone()._Knife) == 0 and _waves().is_empty()
	await _until(clear)
	for used in _used:
		if is_instance_valid(used):
			used.global_position = _arena + Vector2(0, 5000 + 200 * _used.find(used))
			used.reset_physics_interpolation()
	p.global_position = _arena
	p.reset_physics_interpolation()
	p.aim_override = Vector2.RIGHT
	_enemy = _fresh_enemy(_arena + Vector2(distance, 0))
	_other = _fresh_enemy(_enemy.global_position + Vector2(18, 10)) if pair else null
	# klatka na przeliczenie siatki wrogów (Goblin.near) z nowymi miejscami
	await _frames(2)
	_hp = _enemy.health


## Nieużywany jeszcze, żywy zwykły wróg (nie boss, nie kukła) postawiony w miejscu i zatrzymany.
func _fresh_enemy(at: Vector2) -> Node:
	for enemy: Node in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy in _used or enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		_used.append(enemy)
		enemy.set_physics_process(false)
		enemy.global_position = at
		enemy.reset_physics_interpolation()
		return enemy
	return null
