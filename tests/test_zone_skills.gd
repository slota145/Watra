extends SceneTree
## Krok 5 wspólnego drzewka, strefy pośrednie: umiejętności z dwiema broniami (Ciśnięte Noże, Strzała Gromu,
## Zaklęte Ostrze - inne z każdą bronią), węzły Otwarte rany, Impet, Zwiewność i węzeł kluczowy Żelazna Wola.

const S := preload("res://scripts/skills.gd")

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0


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
	var zs = p.zone_skills if p != null else null
	match _frame:
		5:
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
			check("pasek: Noże pasują do miecza i łuku", load("res://scripts/hotbar.gd").fits("thrown_knives", 3, "melee") and load("res://scripts/hotbar.gd").fits("thrown_knives", 3, "bow")
					and not load("res://scripts/hotbar.gd").fits("thrown_knives", 3, "spell"))
			_unlock(p)
			check("nowe umiejętności w drzewku", ["thrown_knives", "thunder_arrow", "enchanted_blade"].all(func(id: String) -> bool:
					return p.skills.level_of(id) > 0))
			check("nowe węzły wybrane", ["open_wounds", "momentum", "lightness", "iron_will"].all(
					func(id: String) -> bool: return p.skills.has_node_id(id)))
			# Ciśnięte Noże z mieczem - noże wracają
			p.equipment.equip("iron_sword")
			_aim_at_enemy(p)
			_full(p)
			p._press_slot(_put(p, "thrown_knives"))
			check("odnowienie Noży", p.cooldown_of("thrown_knives").x > 0.0)
			check("noże z miecza lecą", _count(_zone()._Knife) == S.KNIVES_COUNT, str(_count(_zone()._Knife)))
		50:
			check("noże z miecza ranią", _hurt(), "%d -> %d" % [_hp, _now()])
			check("noże z miecza wracają", _count(_zone()._Knife) == 0, str(_count(_zone()._Knife)))
			# Ciśnięte Noże z łukiem - zwykłe pociski z nożem
			p.equipment.equip("short_bow")
			_aim_at_enemy(p)
			_full(p)
			p._press_slot(_put(p, "thrown_knives"))
			var knives := _world.get_tree().get_nodes_in_group("player_projectiles").filter(func(s: Node) -> bool: return s.fx_kind == "knife")
			check("noże z łuku to pociski", knives.size() == S.KNIVES_COUNT and knives[0].max_range == S.KNIVES_BOW_RANGE, str(knives.size()))
		75:
			check("noże z łuku ranią", _hurt(), "%d -> %d" % [_hp, _now()])
			# Strzała Gromu z łuku: przeskok na drugiego wroga
			_aim_at_enemy(p)
			var other := _second_enemy()
			_full(p)
			p._press_slot(_put(p, "thunder_arrow"))
			var bolts := _world.get_tree().get_nodes_in_group("player_projectiles").filter(func(s: Node) -> bool: return s.fx_kind == "thunder")
			check("Strzała Gromu z łuku leci", bolts.size() == 1 and "attack" in bolts[0].tags)
			_hp2 = other.health if other != null else 0
			_other = other
		100:
			check("Strzała Gromu rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("Strzała Gromu przeskakuje", _other == null or not is_instance_valid(_other) or _other.health < _hp2 or _other.state == 4,
					"%d -> %d" % [_hp2, _other.health if is_instance_valid(_other) else 0])
			# z księgi: piorun z nieba
			p.equipment.equip("spellbook")
			_aim_at_enemy(p)
			var other := _second_enemy()
			_hp2 = other.health if other != null else 0
			_other = other
			_full(p)
			p._press_slot(_put(p, "thunder_arrow"))
			var bolts := _world.get_tree().get_nodes_in_group("player_projectiles").filter(func(s: Node) -> bool: return s.fx_kind == "thunder")
			check("Strzała Gromu z księgi to czar", bolts.size() == 1 and "spell" in bolts[0].tags and not "attack" in bolts[0].tags)
		140:
			check("piorun z nieba rani też sąsiada", _other == null or not is_instance_valid(_other) or _other.health < _hp2 or _other.state == 4,
					"%d -> %d" % [_hp2, _other.health if is_instance_valid(_other) else 0])
			# Zaklęte Ostrze z księgą - sama fala
			_aim_at_enemy(p)
			_full(p)
			p._press_slot(_put(p, "enchanted_blade"))
			check("fala z księgi", _count(_zone()._FlameWave) == 1)
			check("fala z księgi dłuższa", _waves()[0].reach > S.BLADE_WAVE_MELEE.x)
		175:
			check("fala rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("fala podpala", not is_instance_valid(_enemy) or _enemy.state == 4 or p.spell_skills.is_burning(_enemy))
			# z mieczem: cięcie od razu, potem fala
			p.equipment.equip("iron_sword")
			_aim_at_enemy(p)
			_enemy.global_position = p.global_position + Vector2(25, 0)
			_hp = _enemy.health
			_full(p)
			p._press_slot(_put(p, "enchanted_blade"))
			check("cięcie Zaklętego Ostrza rani od razu", _hurt(), "%d -> %d" % [_hp, _now()])
			check("fala z miecza krótsza", is_equal_approx(_waves()[-1].reach,
					S.BLADE_WAVE_MELEE.x * p.stats.area_multiplier(S.tags("enchanted_blade", "melee"))),
					"%d, %s" % [_count(_zone()._FlameWave), str(_waves().map(func(w: Node) -> float: return w.reach))])
		180:
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
		185:
			check("Zwiewność mija", p.stats.temp_bonus.get("move_speed", 0.0) == 0.0 or not p.stats._temp_sources.get("lightness", {}).has("move_speed"))
			# Otwarte rany: ciosy i pociski krwawią, czary bez formy nie
			_aim_at_enemy(p)
			for i in 40:
				zs.on_hit(_enemy, 50, ["attack", "hit"])
		230:
			check("Otwarte rany ranią krwawieniem", _hurt(), "%d -> %d" % [_hp, _now()])
			# Żelazna Wola: czary liczą siłę zamiast inteligencji
			p.stats.attributes["strength"] = 200
			p.stats.attributes["intelligence"] = 0
			var with_will: float = p.stats.attribute_damage(S.tags("fireball"))
			check("Żelazna Wola: czar z siły", with_will >= 2.0, "%.2f" % with_will)
			check("Żelazna Wola: ataki bez zmian", p.stats.attribute_damage(S.tags("multishot")) < with_will)
			print("WYNIK: %s" % ("OK" if _fails == 0 else "%d bledow" % _fails))
			return true
	return false


var _hp2 := 0
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


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.health < _hp


## Drugi wróg tuż za pierwszym (do przeskoku pioruna i pioruna z nieba).
func _second_enemy() -> Node:
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy == _enemy or enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		enemy.global_position = _enemy.global_position + Vector2(18, 10)
		enemy.reset_physics_interpolation()
		enemy.set_physics_process(false)
		return enemy
	return null


## Gracz przed najbliższym prawdziwym wrogiem (nie kukłą), celując w niego.
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
