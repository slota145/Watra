extends SceneTree
## Krok 5 wspólnego drzewka, strona inteligencji: Ściana Ognia (pali wrogów, zapala pociski gracza), Lodowy Pancerz
## (tarcza przyjmuje ciosy, pęka z wybuchem i zamrożeniem), węzły Przelana moc i Pełnia umysłu, węzeł kluczowy
## Mistrz Żywiołów (żywioł ostatniego ciosu, +40% obrażeń).

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
	var ss = p.spell_skills if p != null else null
	match _frame:
		5:
			p.equipment.equip("spellbook")
			check("księga w ręku", p.stats.weapon_type() == "spell")
			_unlock(p)
			check("nowe umiejętności w drzewku", ["fire_wall", "ice_armor"].all(func(id: String) -> bool:
					return p.skills.level_of(id) > 0 and load("res://scripts/hotbar.gd").can_slot_skill(id)))
			check("nowe węzły do wybrania", ["mana_flow", "full_mind", "elem_master"].all(
					func(id: String) -> bool: return p.skills.has_node_id(id)))
			check("Mistrz Żywiołów wybrany", p.skills.has_keystone("elem_master"))
			# Ściana Ognia pod wrogiem
			_aim_at_enemy(p)
			_full(p)
			p.aim_override = _enemy.global_position - p.body_center()
			ss.press("fire_wall")
			check("Ściana Ognia stoi", ss._walls.size() == 1 and is_instance_valid(ss._walls[0]))
			check("odnowienie Ściany Ognia", p.cooldown_of("fire_wall").x > 0.0)
			# pocisk gracza przelatujący przez ścianę zapala się
			var shot = _make_shot(p)
			shot.global_position = ss._walls[0].global_position
			p.aim_override = Vector2.RIGHT
		8:
			var lit := _world.get_tree().get_nodes_in_group("player_projectiles").any(func(s: Node) -> bool: return s.ignited > 0.0)
			check("Ściana Ognia zapala pociski", lit)
		40:
			check("Ściana Ognia rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("Ściana Ognia podpala", not is_instance_valid(_enemy) or _enemy.state == 4 or ss.is_burning(_enemy))
			for w in ss._walls:
				w.queue_free()
			# Lodowy Pancerz
			_full(p)
			ss.press("ice_armor")
			check("Lodowy Pancerz działa", ss.ice_armor_active() and ss._ice_hp > 0, str(ss._ice_hp))
			var hp: int = p.health
			p._invulnerable_timer = 0.0
			p.take_damage(5, p.global_position + Vector2(10, 0))
			check("Lodowy Pancerz przyjmuje cios", p.health == hp, "%d -> %d" % [hp, p.health])
			check("Lodowy Pancerz w efektach", load("res://scripts/status_effects.gd").list(p).any(
					func(e: Dictionary) -> bool: return e["name"] == "Lodowy Pancerz"))
			# pęknięcie: wybuch zamraża wroga obok
			_aim_at_enemy(p)
			_enemy.global_position = p.global_position + Vector2(20, 0)
			_hp = _enemy.health
			p._invulnerable_timer = 0.0
			p.take_damage(ss._ice_hp + 50, p.global_position + Vector2(10, 0))
			check("Lodowy Pancerz pęka", not ss.ice_armor_active())
			check("wybuch rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("wybuch zamraża", not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.is_chilled())
		45:
			_full(p)
			# Przelana moc: 8% ciosu zabiera mana
			ss._ice_time = 0.0
			p.mana = 100.0
			var left: int = ss.mana_flow(100)
			check("Przelana moc", left == 92 and is_equal_approx(p.mana, 92.0), "%d, mana %.1f" % [left, p.mana])
			p.mana = 0.0
			check("Przelana moc: bez many nic", ss.mana_flow(100) == 100)
			# Pełnia umysłu
			var max_mana: float = p.stats.max_mana()
			p.mana = max_mana
			check("Pełnia umysłu: pełna mana +10%", is_equal_approx(ss.full_mind_bonus(), 0.1), "%.3f" % ss.full_mind_bonus())
			p.mana = max_mana * 0.61
			check("Pełnia umysłu: 61% many +2%", is_equal_approx(ss.full_mind_bonus(), 0.02), "%.3f" % ss.full_mind_bonus())
			p.mana = max_mana * 0.4
			check("Pełnia umysłu: poniżej połowy nic", ss.full_mind_bonus() == 0.0)
			p.mana = max_mana
			ss._update_temp()
			check("Pełnia umysłu w premiach", is_equal_approx(p.stats.temp_bonus.get("damage_percent", 0.0), 0.1))
			# Mistrz Żywiołów
			check("Mistrz Żywiołów: +40%", is_equal_approx(ss.master_factor(), 1.4))
			check("Mistrz Żywiołów: zanim coś trafi - własny żywioł", ss.master_sound("arrow") == "arrow")
			ss.on_hurt("cold")
			check("Mistrz Żywiołów: lód", ss.master_sound("fire") == "ice" and ss.master_sound("arrow") == "ice")
			ss.on_hurt("physical")
			ss.on_hurt("nawia")
			check("Mistrz Żywiołów: fizyczne i Nawia nie zmieniają", ss.master_sound("") == "ice")
			ss.on_hurt("lightning")
			check("Mistrz Żywiołów: piorun", ss.master_sound("ice") == "lightning")
			check("Mistrz Żywiołów w efektach", load("res://scripts/status_effects.gd").list(p).any(
					func(e: Dictionary) -> bool: return e["name"] == "Mistrz Żywiołów"))
		50:
			print("WYNIK: %s" % ("OK" if _fails == 0 else "%d bledow" % _fails))
			return true
	return false


func _unlock(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	p.stats.level = 60
	p.skills.character_level = 60
	p.skills.bonus_points += 3000
	for id: String in Tree.nodes():
		if Tree.nodes()[id]["region"] != "int" or Tree.is_soon(id) or id in ["blood_offering", "echo_runes", "full_power"]:
			continue
		for step: String in Tree.path_to(id):
			p.skills.take(step)
	p.mana = p.stats.max_mana()


func _full(p) -> void:
	p.mana = p.stats.max_mana()
	p.health = p.stats.max_health()
	p.spell_skills._cooldowns.clear()


## Wolny pocisk gracza (jak strzała) do sprawdzenia Ściany Ognia.
func _make_shot(p) -> Node:
	var shot = p._make_projectile(p.equipment.weapon(), Vector2.RIGHT, "")
	shot.speed = 1.0
	p.get_parent().add_child(shot)
	return shot


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.health < _hp


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
