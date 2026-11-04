extends SceneTree
## Krok 5 wspólnego drzewka, strona zręczności: Strzała Żmija (przeskoki z rosnącymi obrażeniami, jad), Rozszczepiona
## Strzała (rozpad na mniejsze strzały), Kolczatka (pole kolców rani i spowalnia), węzły Szereg, Ciche kroki,
## Oddech w biegu i kluczowe Łowca w Cieniu i Szał Bitewny.

const S := preload("res://scripts/skills.gd")

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0
var _caltrops_enemy: Node
var _caltrops_hp := 0


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


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var bs = p.bow_skills if p != null else null
	match _frame:
		5:
			p.equipment.equip("short_bow")
			check("łuk w ręku", p.stats.weapon_type() == "bow")
			_unlock(p)
			check("nowe umiejętności w drzewku", ["viper_arrow", "split_arrow", "caltrops"].all(func(id: String) -> bool:
					return p.skills.level_of(id) > 0 and load("res://scripts/hotbar.gd").can_slot_skill(id)))
			check("nowe węzły do wybrania", ["row_shot", "silent_steps", "running_breath", "shadow_stalker", "battle_frenzy"].all(
					func(id: String) -> bool: return p.skills.has_node_id(id)))
			check("węzły kluczowe", p.skills.has_keystone("shadow_stalker") and p.skills.has_keystone("battle_frenzy"))
			check("Szereg: 2 strzały obok siebie", p.row_offsets().size() == 2 and p.row_offsets(false).size() == 1,
					str(p.row_offsets()))
			# Strzała Żmija: z Szeregiem 2 strzały, każda przeskakuje
			_aim_at_enemy(p)
			_full(p)
			var before := _arrows()
			bs.press("viper_arrow")
			var vipers := _arrows().filter(func(a: Node) -> bool: return a not in before)
			check("Strzała Żmija: 2 strzały (Szereg)", vipers.size() == 2, str(vipers.size()))
			var jumping := true
			for a in vipers:
				jumping = jumping and a.chain >= S.VIPER_JUMPS and a.chain_range == S.VIPER_RANGE
			check("Strzała Żmija przeskakuje", jumping)
			check("odnowienie Strzały Żmija", p.cooldown_of("viper_arrow").x > 0.0)
		30:
			check("Strzała Żmija rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("Strzała Żmija zatruwa", not is_instance_valid(_enemy) or _enemy.state == 4 or p.bow_skills.is_poisoned(_enemy))
			# Rozszczepiona Strzała: rozpad na 3 mniejsze strzały, które omijają trafionego
			_aim_at_enemy(p)
			_full(p)
			var before := _arrows()
			bs._split_shards(_enemy, Vector2.RIGHT, 5, 5)
			var shards := _arrows().filter(func(a: Node) -> bool: return a not in before)
			var skipping := true
			for a in shards:
				skipping = skipping and a._hit.has(_enemy) and a.max_range == S.SPLIT_RANGE
			check("rozpad na 3 strzały", shards.size() == S.SPLIT_SHARDS and skipping, str(shards.size()))
			bs.press("split_arrow")
			check("odnowienie Rozszczepionej Strzały", p.cooldown_of("split_arrow").x > 0.0)
		55:
			check("Rozszczepiona Strzała rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Kolczatka pod wrogiem
			_aim_at_enemy(p)
			_full(p)
			p.aim_override = _enemy.global_position - p.body_center()
			bs.press("caltrops")
			check("Kolczatka leży", bs._caltrops.size() == 1 and is_instance_valid(bs._caltrops[0]))
			_caltrops_enemy = _enemy
			_caltrops_hp = _enemy.health
			p.aim_override = Vector2.RIGHT
		90:
			check("Kolczatka rani", not is_instance_valid(_caltrops_enemy) or _caltrops_enemy.state == 4
					or _caltrops_enemy.health < _caltrops_hp, "%d" % _caltrops_hp)
			check("Kolczatka spowalnia", not is_instance_valid(_caltrops_enemy) or _caltrops_enemy.state == 4
					or _caltrops_enemy.is_chilled())
			# Ciche kroki
			check("Ciche kroki", is_equal_approx(load("res://scripts/goblin.gd").notice_factor, 0.5))
			# Łowca w Cieniu
			_aim_at_enemy(p)
			_enemy.state = 0
			check("Łowca w Cieniu: niezauważony +60%", is_equal_approx(bs.damage_factor(_enemy), 1.6) and bs.forced_crit(_enemy),
					"%.2f" % bs.damage_factor(_enemy))
			_enemy.state = 1
			check("Łowca w Cieniu: w walce -10%", is_equal_approx(bs.damage_factor(_enemy), 0.9) and not bs.forced_crit(_enemy),
					"%.2f" % bs.damage_factor(_enemy))
			# Szał Bitewny: zabójstwo daje ładunek
			bs._frenzy = 0
			bs._apply_frenzy()
			var speed: float = p.stats.attack_speed()
			_enemy.take_damage(999999, p.global_position, 0.0)
			check("Szał Bitewny: ładunek za zabójstwo", bs.frenzy_charges() == 1, str(bs.frenzy_charges()))
			bs.on_kill()
			bs.on_kill()
			check("Szał Bitewny: szybkość", p.stats.attack_speed() > speed
					and is_equal_approx(p.stats.temp_bonus.get("move_speed", 0.0), 0.06), "%.2f -> %.2f" % [speed, p.stats.attack_speed()])
			check("Szał Bitewny w efektach", load("res://scripts/status_effects.gd").list(p).any(
					func(e: Dictionary) -> bool: return e["name"] == "Szał Bitewny"))
			for i in 20:
				bs.on_kill()
			check("Szał Bitewny: najwyżej 10 ładunków", bs.frenzy_charges() == 10)
			bs._update_frenzy(3.1)
			check("Szał Bitewny: ładunki znikają", bs.frenzy_charges() == 0 and p.stats.attack_speed() <= speed + 0.001)
			# Oddech w biegu
			p._move_velocity = Vector2(100, 0)
			bs._update_breath()
			check("Oddech w biegu", is_equal_approx(p.stats.temp_bonus.get("health_regen", 0.0), 3.0))
			p._move_velocity = Vector2.ZERO
			bs._update_breath()
			check("Oddech w biegu: tylko w biegu", p.stats.temp_bonus.get("health_regen", 0.0) == 0.0)
		95:
			print("WYNIK: %s" % ("OK" if _fails == 0 else "%d bledow" % _fails))
			return true
	return false


func _unlock(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	p.stats.level = 60
	p.skills.character_level = 60
	p.skills.bonus_points += 3000
	for id: String in Tree.nodes():
		if Tree.nodes()[id]["region"] != "dex" or Tree.is_soon(id) or id in ["falcon_eye", "hail", "running_fire"]:
			continue
		for step: String in Tree.path_to(id):
			p.skills.take(step)
	p.mana = p.stats.max_mana()


func _full(p) -> void:
	p.mana = p.stats.max_mana()
	p.health = p.stats.max_health()
	p.bow_skills._cooldowns.clear()


func _arrows() -> Array:
	return _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return n.has_method("ignore"))


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.health < _hp


## Gracz przed najbliższym prawdziwym wrogiem (nie kukłą) w odległości strzału, celując w niego.
func _aim_at_enemy(p) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		var spot: Vector2 = enemy.global_position + Vector2(-60, 0)
		var ray := PhysicsRayQueryParameters2D.create(spot + Vector2(0, -9), enemy.hurt_center(), 1)
		if space.intersect_ray(ray).is_empty():
			p.global_position = spot
			p.reset_physics_interpolation()
			p.aim_override = Vector2.RIGHT
			_enemy = enemy
			_enemy.set_physics_process(false)
			_hp = enemy.health
			return
