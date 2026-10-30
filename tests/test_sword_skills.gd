extends SceneTree
## Drzewko miecza, etap 2: pełne drzewko (umiejętności, ok. 35 pasywnych, 4 kluczowe, ikony), Rozpłatanie (krwawienie,
## podwójne po Mgnieniu), Rozłupanie Ziemi (ogłuszenie), Riposta (zasłona, kontra, darmowa Szarża), Zew Peruna
## (premia, strach, ciosy krytyczne), Widmowe Ostrza (krążą i ranią, po Młynku wylatują), węzły kluczowe Taniec Ostrzy,
## Dym i Cień, Krwawy Szał oraz Amulet Wiecznego Wiru (wirujące Mgnienie bez odnowienia).

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
	var ss = p.sword_skills if p != null else null
	match _frame:
		5:
			_check_tree(p)
			_aim_at_enemy(p)
			ss.press("rend")
			check("Rozpłatanie rani", _enemy.health < _hp or _enemy.state == 4, "%d -> %d" % [_hp, _enemy.health])
			_hp = _enemy.health
		75:
			check("krwawienie", _enemy.health < _hp or _enemy.state == 4, "%d -> %d" % [_hp, _enemy.health])
			# Rozłupanie Ziemi ogłusza
			_aim_at_enemy(p)
			ss.press("ground_slam")
		90:
			check("Rozłupanie Ziemi ogłusza", _enemy.state == 4 or _enemy.is_stunned())
			check("odnowienie Rozłupania", p.cooldown_of("ground_slam").x > 0.0)
			# Riposta: zasłona przyjmuje cios, kontra i darmowa Szarża
			_aim_at_enemy(p)
			ss.press("riposte")
			var hp: int = p.health
			p._invulnerable_timer = 0.0
			p.take_damage(30, _enemy.global_position)
			check("Riposta przyjmuje cios", p.health == hp)
			check("po Ripoście darmowa Szarża", p.combo_with("lunge"))
			var mana: float = p.mana
			p._strike_cooldown = 0.0
			p._use_strike()
			check("Szarża bez many i odnowienia", is_equal_approx(p.mana, mana) and p._strike_cooldown == 0.0)
		120:
			# Zew Peruna: premia do obrażeń, strach, ciosy krytyczne
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			var mult: float = p.stats.damage_multiplier()
			ss.press("war_cry")
			check("Zew Peruna: premia", p.stats.damage_multiplier() > mult and ss._forced_crits == 3)
			check("Zew Peruna w efektach", load("res://scripts/status_effects.gd").list(p).any(func(e: Dictionary) -> bool: return e["name"] == "Zew Peruna"))
			check("strach", _enemy.state == 4 or _enemy._fear_time > 0.0)
			check("ciosy krytyczne", ss.take_forced_crit() and ss._forced_crits == 2)
			# Taniec Ostrzy
			var speed: float = p.stats.attack_speed()
			p.combo_used()
			p.combo_used()
			check("Taniec Ostrzy", p.stats.attack_speed() > speed + 0.09, "%.2f -> %.2f" % [speed, p.stats.attack_speed()])
			# Widmowe Ostrza: krążą, po Młynku wylatują
			p.mana = p.stats.max_mana()
			ss.press("spectral_blades")
			check("Widmowe Ostrza krążą", is_instance_valid(ss._blades) and ss._blades.count == 4)
		140:
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			ss._cooldowns.clear()
			p.note_skill("whirlwind")
			ss.press("spectral_blades")
			check("po Młynku ostrza wylatują", is_instance_valid(ss._blades) and ss._blades._launched)
			# Dym i Cień: chmura po Dymnych Wybuchach
			p.mana = p.stats.max_mana()
			ss._fire_smoke(1, false)
			ss._physics_process(0.01)
			check("Dym i Cień: unik w chmurze", ss._in_cloud() and p.stats.dodge_chance() >= 0.3)
			# Krwawy Szał: krwawienie leczy
			_aim_at_enemy(p)
			p.health = 10
			ss.bleed_enemy(_enemy, 5.0)
		200:
			check("Krwawy Szał leczy", p.health > 10, "%d" % p.health)
			# Amulet Wiecznego Wiru
			var amulet: String = load("res://scripts/loot.gd").legendary_at_level("legend_endless_amulet", 20)
			p.equipment.equip(amulet, 0)
			p.skills.nodes["melee"].erase("endless_whirl")
			check("Amulet Wiecznego Wiru", ss._endless_whirl() and p.equipment.effect_power("endless_whirl") > 0.0)
			check("opis amuletu", load("res://scripts/items.gd").describe(amulet).contains("odnowienia"))
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


func _check_tree(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	var nodes: Dictionary = Tree.nodes("melee")
	var kinds := {}
	for id: String in nodes:
		kinds[nodes[id]["kind"]] = kinds.get(nodes[id]["kind"], 0) + 1
	check("drzewko: rozmiar", kinds.get("passive", 0) >= 30 and kinds.get("skill", 0) == 12 and kinds.get("keystone", 0) == 4, str(kinds))
	var unreachable := nodes.keys().filter(func(id: String) -> bool: return id != "start" and Tree.path_to("melee", id).is_empty())
	check("drzewko: każdy węzeł osiągalny", unreachable.is_empty(), str(unreachable))
	var view = load("res://scripts/ui/skill_tree_view.gd").new()
	var no_icon := nodes.keys().filter(func(id: String) -> bool: return view.icon_of(id) == null)
	view.free()
	check("drzewko: ikony", no_icon.is_empty(), str(no_icon))
	var close := []
	for a: String in nodes:
		for b: String in nodes:
			if a < b and nodes[a]["pos"].distance_to(nodes[b]["pos"]) < 1.2:
				close.append(a + "/" + b)
	check("drzewko: węzły nie nachodzą", close.is_empty(), str(close))
	p.stats.level = 60
	p.skills.character_level = 60
	# cała reszta testu na pełnym drzewku
	var taken := 0
	for i in 5:
		for id: String in nodes:
			if p.skills.take("melee", id):
				taken += 1
	check("całe drzewko do wybrania", p.skills.nodes["melee"].size() == nodes.size() - 1, "%d/%d" % [p.skills.nodes["melee"].size(), nodes.size() - 1])
	p.mana = p.stats.max_mana()


## Gracz tuż przed najbliższym prawdziwym wrogiem (nie kukłą), celując w niego.
func _aim_at_enemy(p) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		var spot: Vector2 = enemy.global_position + Vector2(-26, 0)
		var ray := PhysicsRayQueryParameters2D.create(spot + Vector2(0, -13), enemy.hurt_center(), 1)
		if space.intersect_ray(ray).is_empty():
			p.global_position = spot
			p.reset_physics_interpolation()
			p.aim_override = Vector2.RIGHT
			_enemy = enemy
			_enemy.set_physics_process(false)
			_hp = enemy.health
			return
