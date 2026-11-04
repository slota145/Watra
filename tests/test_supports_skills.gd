extends SceneTree
## Kamienie wsparcia w umiejętnościach (Supports, krok 4 dopieszczenia walki): które kamienie pasują (EXCEPT),
## koszt many, Rozszczep (więcej kul ognia), Rozległość (obszar), Okrutny Cios (obrażenia), Żarowe Ostrze (podpalenie
## od fizycznego trafienia), Echo Rusałki (powtórka czaru), Łańcuch (odbicie strzały do drugiego wroga).

var _world: Node
var _frame := 0
var _fails := 0
var _echoes := 0
var _lances := 0
var _chain_hits := {}
var _a: Node
var _b: Node
var _b_hp := 0
var Skills
var SkillTree
var Supports


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _gem(kind: String, level := 1) -> Dictionary:
	return {"support": kind, "level": level, "xp": 0}


func _give(p, skill: String, gems: Array) -> void:
	p.skills.supports[skill] = {"sockets": gems.size(), "gems": gems}


func _unlock(p, skill: String) -> void:
	var weapon: String = Skills.get_data(skill)["weapon"]
	var node: String = SkillTree.node_for_skill(skill)
	if not p.skills.nodes.has(weapon):
		p.skills.nodes[weapon] = {}
	for step in SkillTree.path_to(weapon, node):
		p.skills.nodes[weapon][step] = true
	p.skills.levels[skill] = maxi(int(p.skills.levels.get(skill, 0)), 1)


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	match _frame:
		5:
			Skills = load("res://scripts/skills.gd")
			SkillTree = load("res://scripts/skill_tree.gd")
			Supports = load("res://scripts/supports.gd")
			_check_fits()
			p.equipment.equip("spellbook")
			for id in ["fireball", "frost_lance"]:
				_unlock(p, id)
			_check_mana(p)
			_check_split(p)
			_check_area(p)
			_check_echo(p)
		60:
			check("Echo Rusałki: powtórka po chwili", _echoes == 1, "%d" % _echoes)
			check("Echo Rusałki: Włócznia leci dwa razy", _lances == 2, "%d" % _lances)
			p.skills.supports.clear()
			p.equipment.equip("iron_sword")
			_check_brutal(p)
			_check_fire_edge(p)
			p.equipment.equip("short_bow")
			_check_chain(p)
		120:
			check("Łańcuch: strzała trafia drugiego wroga", _chain_hits.size() >= 2 or (is_instance_valid(_b) and _b.health < _b_hp),
					"%d trafionych" % _chain_hits.size())
			print("WYNIK: %s" % ("OK" if _fails == 0 else "FAIL (%d)" % _fails))
			quit(1 if _fails > 0 else 0)
	return false


func _check_fits() -> void:
	check("Rozszczep pasuje do Salwy", Supports.fits("split", "multishot"))
	check("Rozszczep nie pasuje do Deszczu Strzał", not Supports.fits("split", "arrow_rain"))
	check("Echo nie pasuje do Kroku przez Mgłę", not Supports.fits("echo", "blink"))
	check("Okrutny Cios nie pasuje do czaru", not Supports.fits("brutal", "fireball"))
	check("regeneracja bez gniazd", not Supports.has_sockets("warrior_blood") and not Supports.fits("area", "warrior_blood"))


func _check_mana(p) -> void:
	var base: float = p.skill_mana("frost_lance")
	_give(p, "frost_lance", [_gem("rime"), _gem("pierce")])
	var more: float = p.skill_mana("frost_lance")
	check("kamienie podnoszą koszt many", is_equal_approx(more, base * 1.15 * 1.15), "%.1f -> %.1f" % [base, more])
	p.mana = p.stats.max_mana()
	p.spell_skills._cooldowns.clear()
	var before: float = p.mana
	p.aim_override = Vector2(1, 0)
	p.spell_skills.press("frost_lance")
	check("rzut płaci podwyższony koszt", is_equal_approx(before - p.mana, more), "%.1f" % (before - p.mana))
	p.skills.supports.clear()


func _check_split(p) -> void:
	var parent: Node = p.get_parent()
	var count := func() -> int:
		return parent.get_children().filter(func(n: Node) -> bool: return n.get_script() == load("res://scripts/projectile.gd") and n.fire and n.explosion_radius > 0.0).size()
	var start: int = count.call()
	p._launch_fireballs(Vector2.RIGHT, 1, 0.0)
	var one: int = count.call() - start
	_give(p, "fireball", [_gem("split")])
	p._launch_fireballs(Vector2.RIGHT, 1, 0.0)
	var three: int = count.call() - start - one
	check("Rozszczep: 3 kule ognia zamiast 1", one == 1 and three == 3, "%d / %d" % [one, three])
	p.skills.supports.clear()


func _check_area(p) -> void:
	var tags: Array = Skills.tags("fireball")
	var plain: float = p.stats.area_multiplier(tags)
	_give(p, "fireball", [_gem("area", 20)])
	var wide: float = p.stats.area_multiplier(tags)
	check("Rozległość: obszar +45% na poziomie 20", is_equal_approx(wide - plain, 0.45), "%.2f -> %.2f" % [plain, wide])
	check("Rozległość nie działa na inną umiejętność", is_equal_approx(p.stats.area_multiplier(Skills.tags("meteor")), plain))
	p.skills.supports.clear()


func _check_echo(p) -> void:
	_give(p, "fireball", [_gem("echo")])
	p.support_echo("fireball", func() -> void: _echoes += 1)
	p.support_echo("meteor", func() -> void: _echoes += 10)
	# Włócznia Marzanny z Echem: druga włócznia po chwili
	_give(p, "frost_lance", [_gem("echo")])
	p.get_tree().node_added.connect(func(n: Node) -> void:
		if n.get_script() == load("res://scripts/projectile.gd") and n.fx_kind == "ice" and is_equal_approx(n.size, 0.9):
			_lances += 1)
	p.mana = p.stats.max_mana()
	p.spell_skills._cooldowns.clear()
	p.spell_skills.press("frost_lance")


func _check_brutal(p) -> void:
	var tags: Array = Skills.tags("whirlwind")
	var plain: float = p.stats.kind_multiplier(tags)
	_give(p, "whirlwind", [_gem("brutal")])
	var hard: float = p.stats.kind_multiplier(tags)
	check("Okrutny Cios: +25% obrażeń", is_equal_approx(hard / plain, 1.25), "%.2f -> %.2f" % [plain, hard])
	var slow: float = p.stats.skill_speed(tags)
	p.skills.supports.clear()
	check("Okrutny Cios: wolniejsza umiejętność", slow < p.stats.skill_speed(tags))


func _check_fire_edge(p) -> void:
	_give(p, "lunge", [_gem("fire_edge", 20)])
	var tags: Array = Skills.tags("lunge")
	check("Żarowe Ostrze: szansa na podpalenie", p.stats.ailment_chance("ignite", tags) >= 0.05)
	check("Żarowe Ostrze: +40% obrażeń jako ogień", p.stats.support_elements(tags) == ["fire"])
	var enemy = null
	for e in _world.get_tree().get_nodes_in_group("enemies"):
		if e.state != 4 and not e.is_in_group("bosses") and not e.scene_file_path.contains("dummy"):
			enemy = e
			break
	enemy.set_physics_process(false)
	enemy.health = 1000000
	p.stats.temp_bonus["ignite_chance"] = 0.45
	for i in 40:
		if enemy.is_burning():
			break
		p.hit_enemy(enemy, 1, enemy.global_position, 0.0, "", tags)
	check("Żarowe Ostrze: fizyczny cios podpala", enemy.is_burning())
	p.stats.temp_bonus.erase("ignite_chance")
	p.skills.supports.clear()


## Dwaj wrogowie blisko siebie: strzała z Łańcuchem w pierwszego odbija się do drugiego.
func _check_chain(p) -> void:
	var enemies: Array = _world.get_tree().get_nodes_in_group("enemies").filter(func(e) -> bool:
		return e.state != 4 and not e.is_in_group("bosses") and not e.scene_file_path.contains("dummy"))
	for a in enemies:
		for b in enemies:
			if a != b and a.global_position.distance_to(b.global_position) < 90.0:
				_a = a
				_b = b
				break
		if _a != null:
			break
	if _a == null:
		check("Łańcuch: para wrogów", false)
		return
	_a.set_physics_process(false)
	_b.set_physics_process(false)
	_a.health = 1000000
	_b.health = 1000000
	_b_hp = _b.health
	_unlock(p, "multishot")
	_give(p, "multishot", [_gem("chain")])
	var spot: Vector2 = _a.global_position + (_a.global_position - _b.global_position).normalized() * 40.0
	p.global_position = spot
	p.reset_physics_interpolation()
	var dir: Vector2 = (_a.hurt_center() - (spot + Vector2(0, -13))).normalized()
	var arrow = p._make_projectile(p.equipment.weapon(), dir, "multishot")
	check("Łańcuch: pocisk ma odbicie", arrow.chain == 1)
	arrow.enemy_hit.connect(func(e) -> void: _chain_hits[e] = true)
	p.get_parent().add_child(arrow)
