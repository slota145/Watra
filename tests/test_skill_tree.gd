extends SceneTree
## Drzewko miecza: poprawne dane (połączenia, każdy węzeł osiągalny), punkty z poziomów, wybieranie tylko obok
## wybranych, umiejętność odblokowana węzłem, premie pasywne, starsze zapisy (umiejętności kupione za złoto dostają
## węzły), zapomnienie u mędrca, ataki i czary (szybkość, obrażenia), combo po umiejętności, Mgnienie (skok do wroga,
## mana za skok, trzymanie), wirujące Mgnienie z odnowieniem i Dymne Wybuchy (ładowanie i combo bez ładowania).

var _world: Node
var _start := Vector2.ZERO
var _frame := 0
var _fails := 0
var _enemy: Node
var _enemy_hp := 0


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
	match _frame:
		5:
			_check_data()
			_check_points(p)
		6:
			_place_near_enemy(p)
		7:
			_start = p.global_position
			p._held_ids["flicker"] = true
			p.sword_skills.press("flicker")
		9:
			# na wylot: po pierwszym skoku postać stoi po drugiej stronie wroga
			check("Mgnienie: skok na wylot", (p.global_position - _enemy.global_position).dot(_start - _enemy.global_position) < 0.0)
		30:
			p._held_ids.erase("flicker")
			check("Mgnienie: skok do wroga", p.global_position.distance_to(_enemy.global_position) < 70.0,
					"%.0f px" % p.global_position.distance_to(_enemy.global_position))
			check("Mgnienie: cios i mana", (_enemy.health < _enemy_hp or _enemy.state == 4) and p.mana < p.stats.max_mana())
			check("Mgnienie zapisane do combo", p._chain_skill == "flicker" or p._chain_skill == "smoke_burst")
			# Dymne Wybuchy jako combo - od razu 9 wybuchów, bez ładowania
			_place_near_enemy(p)
			p.mana = p.stats.max_mana()
			p.note_skill("lunge")
			check("combo po umiejętności", p.combo_with("smoke_burst") and not p.combo_with("flicker"))
			p.sword_skills.press("smoke_burst")
			check("Dymne Wybuchy combo bez ładowania", p.sword_skills._smoke_charge < 0.0 and p._chain_skill == "smoke_burst")
		60:
			check("Dymne Wybuchy ranią", _enemy.health < _enemy_hp or _enemy.state == 4, "%d -> %d" % [_enemy_hp, _enemy.health])
			check("bez combo po samym sobie", not p.combo_with("smoke_burst"))
			# ładowanie: trzymane około sekundy - dwa rzędy więcej
			p._chain_time = 0.0
			p.mana = p.stats.max_mana()
			p._held_ids["smoke_burst"] = true
			p.sword_skills.press("smoke_burst")
		130:
			check("Dymne Wybuchy ładują rzędy", p.sword_skills._smoke_stage == 2, "rząd %d" % p.sword_skills._smoke_stage)
			p._held_ids.erase("smoke_burst")
		135:
			check("puszczenie odpala", p.sword_skills._smoke_charge < 0.0)
			# wirujące Mgnienie: w trakcie Młynka seria skoków i odnowienie
			_place_near_enemy(p)
			p.mana = p.stats.max_mana()
			p._skill_held = true
		137:
			p.sword_skills.press("flicker")
			check("wirujące Mgnienie startuje", p.is_whirling() and p.sword_skills._whirl_jumps_left > 0 and p.cooldown_of("flicker").x > 0.0)
		160:
			check("wirujące Mgnienie skacze", p.sword_skills._whirl_jumps_left < load("res://scripts/skills.gd").whirl_flicker_jumps(1),
					"zostało %d skoków" % p.sword_skills._whirl_jumps_left)
			p.sword_skills.press("flicker")
			check("odnowienie wirującego Mgnienia", p.sword_skills._whirl_jumps_left == 0 or p.cooldown_of("flicker").x > 0.0)
			p._skill_held = false
			_check_respec(p)
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


func _check_data() -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	var nodes: Dictionary = Tree.nodes("melee")
	var broken := []
	for id: String in nodes:
		for link: String in nodes[id]["links"]:
			if not nodes.has(link):
				broken.append(link)
		if id != "start" and Tree.path_to("melee", id).is_empty():
			broken.append(id)
	check("drzewko: połączenia i osiągalność", broken.is_empty(), str(broken))
	check("węzeł umiejętności", Tree.node_for_skill("flicker") == "flicker" and Tree.node_for_skill("fireball") == "fireball")
	check("na pasek", load("res://scripts/hotbar.gd").can_slot_skill("flicker") and load("res://scripts/hotbar.gd").can_slot_skill("smoke_burst"))


func _check_points(p) -> void:
	var book = p.skills
	check("punkty na start", book.points_total() == 2 and book.points_left() == 2, "%d" % book.points_left())
	check("tylko obok wybranego", book.can_take("melee", "whirlwind") and not book.can_take("melee", "flicker"))
	check("bez węzła nie ma umiejętności", book.level_of("flicker") == 0 and book.next_cost("flicker") < 0)
	book.take("melee", "whirlwind")
	check("węzeł odblokowuje umiejętność", book.level_of("whirlwind") == 1 and book.points_left() == 1)
	# starszy zapis: umiejętności kupione za złoto dostają węzły (z drogą od startu)
	book.load_save_data({"whirlwind": 3, "lunge": 1, "crescent": 2, "fireball": 2})
	check("starszy zapis", book.level_of("whirlwind") == 3 and book.level_of("crescent") == 2 and book.level_of("fireball") == 2
			and book.has_node_id("melee", "lunge"))
	# więcej punktów na resztę testu
	p.stats.level = 20
	book.character_level = 20
	for id in ["phys_1", "flicker", "smoke_burst", "whirl_reach", "whirl_dmg", "cyclone_eye"]:
		book.take("melee", id)
	check("drzewko na poziomie 20", book.has_node_id("melee", "flicker") and book.has_node_id("melee", "smoke_burst")
			and book.points_left() == 21 - book.points_spent() + 0)
	check("premia z węzła", is_equal_approx(p.stats.kind_multiplier(["attack"]), 1.08) and is_equal_approx(p.stats.kind_multiplier(["spell"]), 1.0))
	check("ataki i czary", is_equal_approx(p.stats.skill_speed(["attack", "spell"]), (p.stats.attack_speed() + p.stats.cast_speed()) / 2.0))
	check("węzeł kluczowy", book.has_keystone("melee", "cyclone_eye") and p.whirl_mana_factor() == 2.0)
	p._whirl_time = 2.0
	check("Oko Cyklonu rozkręca Młynek", is_equal_approx(p.whirl_spin_up(), 1.5))
	p._whirl_time = 30.0
	check("Oko Cyklonu - górna granica", is_equal_approx(p.whirl_spin_up(), 2.0))
	var old_save = load("res://scripts/skill_book.gd").new()
	old_save.load_save_data({"levels": {}, "nodes": {"melee": ["whirlwind", "phys_1", "whirl_reach", "whirl_dmg", "endless_whirl"]}})
	check("dawny Nieustający Wir -> Oko Cyklonu", old_save.has_keystone("melee", "cyclone_eye"))
	old_save.free()
	book.nodes["melee"].erase("cyclone_eye")
	check("bez węzła Młynek się nie rozkręca", p.whirl_spin_up() == 1.0)
	# cofanie prawym przyciskiem: liść tak, węzeł, od którego zależą inne - nie
	var spent: int = book.points_spent()
	check("nie cofa węzła, od którego zależą inne", not book.refund("melee", "phys_1") and book.refund_reason("melee", "phys_1") != "")
	check("cofa liść", book.refund("melee", "whirl_dmg") and book.points_spent() == spent - 1 and not book.has_node_id("melee", "whirl_dmg"))
	book.take("melee", "whirl_dmg")
	p.stats.unspent_points = 1
	p.stats.spend_point("strength")
	var strength: int = p.stats.attributes["strength"]
	check("cofnięcie punktu atrybutu", p.stats.refund_point("strength") and p.stats.attributes["strength"] == strength - 1 and p.stats.unspent_points == 1)
	var copy = load("res://scripts/skill_book.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(book.get_save_data())))
	check("zapis drzewka", copy.nodes["melee"].size() == book.nodes["melee"].size() and copy.level_of("whirlwind") == 3)
	copy.free()


func _check_respec(p) -> void:
	p.stats.add_gold(5000)
	var offers: Dictionary = load("res://scripts/village_services.gd").offers("respec", p, _FakeNpc.new())
	var row: Dictionary = offers["rows"][0]
	check("zapomnienie u mędrca dostępne", row["enabled"])
	row["action"].call()
	check("zapomnienie drzewka", p.skills.nodes["melee"].is_empty() and p.skills.level_of("whirlwind") == 0)
	p.skills.take("melee", "whirlwind")
	check("kupione poziomy zostają", p.skills.level_of("whirlwind") == 3)


## Gracz kilkadziesiąt pikseli od najbliższego goblina, z czystą linią do niego.
func _place_near_enemy(p) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		for offset in [Vector2(70, 0), Vector2(-70, 0), Vector2(0, 70), Vector2(0, -70)]:
			var spot: Vector2 = enemy.global_position + offset
			var ray := PhysicsRayQueryParameters2D.create(spot + Vector2(0, -13), enemy.hurt_center(), 1)
			if space.intersect_ray(ray).is_empty():
				p.global_position = spot
				p.reset_physics_interpolation()
				_enemy = enemy
				_enemy.set_physics_process(false)
				_enemy_hp = enemy.health
				return


class _FakeNpc:
	extends Node
	func say(_text: String) -> void:
		pass
