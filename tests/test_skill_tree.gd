extends SceneTree
## Wspólne drzewko: poprawne dane (połączenia, każdy węzeł osiągalny, każda umiejętność ma węzeł), punkty z paska,
## wybieranie tylko obok wybranych (puste miejsca drzewko przechodzi samo), umiejętność odblokowana węzłem, premie
## pasywne z każdą bronią, starsze zapisy (zwrot wszystkich punktów, kamienie z gniazd), zapomnienie u mędrca, ataki i czary (szybkość, obrażenia), combo po umiejętności, Mgnienie (skok do wroga,
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
	var nodes: Dictionary = Tree.nodes()
	var broken := []
	for id: String in nodes:
		for link: String in nodes[id]["links"]:
			if not nodes.has(link):
				broken.append(link)
	# każdy węzeł osiągalny od startu (przez wybrane i puste miejsca)
	var reached := {"start": true}
	var queue: Array = ["start"]
	while not queue.is_empty():
		for other: String in Tree.neighbors(queue.pop_back()):
			if not reached.has(other):
				reached[other] = true
				queue.append(other)
	check("drzewko: połączenia i osiągalność", broken.is_empty() and reached.size() == nodes.size(), "%s %d/%d" % [broken, reached.size(), nodes.size()])
	check("wspólne drzewko: 235 węzłów", nodes.size() == 235, "%d" % nodes.size())
	var missing := []
	for skill: String in Skills.DATA:
		var node: String = Tree.node_for_skill(skill)
		if node == "" or Tree.is_soon(node):
			missing.append(skill)
	check("każda umiejętność ma węzeł", missing.is_empty(), str(missing))
	var keystones := []
	for id: String in nodes:
		if nodes[id]["kind"] == "keystone" and not nodes[id].get("soon", false):
			keystones.append(id)
	check("obecne węzły kluczowe", keystones.size() == 14 and "last_bastion" in keystones and "blood_offering" in keystones and "blood_sacrifice" in keystones and "shadow_hunter" in keystones, str(keystones))
	check("węzeł umiejętności", Tree.node_for_skill("flicker") == "flicker" and Tree.node_for_skill("fireball") == "fireball")
	check("na pasek", load("res://scripts/hotbar.gd").can_slot_skill("flicker") and load("res://scripts/hotbar.gd").can_slot_skill("smoke_burst"))
	check("bez regeneracji jako umiejętności", not Skills.DATA.has("warrior_blood") and not Skills.DATA.has("mana_stream"))


## Bierze węzły po kolei drogą od startu (puste miejsca drzewko przechodzi samo).
func _take_path(book, target: String) -> bool:
	for step: String in load("res://scripts/skill_tree.gd").path_to(target):
		if not book.has_node_id(step) and not book.take(step):
			print("  nie da się wziąć: ", step)
			return false
	return true


func _check_points(p) -> void:
	var book = p.skills
	check("punkty na start", book.points_total() == 2 and book.points_left() == 2, "%d" % book.points_left())
	check("tylko obok wybranego", book.can_take("whirlwind") and book.can_take("multishot") and not book.can_take("flicker"))
	check("bez węzła nie ma umiejętności", book.level_of("flicker") == 0 and book.next_cost("flicker") < 0)
	book.take("whirlwind")
	check("węzeł odblokowuje umiejętność", book.level_of("whirlwind") == 1 and book.points_left() == 1)
	check("pustego miejsca nie da się wybrać", not book.can_take("loyal_seeker") and not book.take("loyal_seeker"))
	# bardzo stary zapis (sam słownik poziomów): złoto za poziomy 2+ wraca (300 + 600 + 300 + 300)
	book.load_save_data({"whirlwind": 3, "lunge": 1, "crescent": 2, "fireball": 2})
	check("starszy zapis", book.needs_migration and book.tree_reset and book.nodes.is_empty())
	var migrated: Dictionary = book.migrate_old(10000)
	check("przeliczenie starego zapisu", migrated["gold"] == 1500 and book.levels.is_empty() and book.nodes.is_empty()
			and book.earned_points() == 5 and book.points_left() == 7 and not book.needs_migration, str(migrated))
	check("drugi raz nie przelicza", book.migrate_old(10000).is_empty())
	# zapis z osobnymi drzewkami broni: wszystkie punkty wracają, kamienie z gniazd do plecaka
	var ruby := {"kind": "ruby", "cut": 1, "affixes": {"health": 20.0}}
	book.load_save_data({"skill_xp": 4000, "levels": {"whirlwind": 4, "fireball": 2}, "bonus_points": 1,
			"nodes": {"melee": ["whirlwind", "phys_1", "socket_1"], "spell": ["fireball"]}, "gems": {"melee": {"socket_1": ruby}}})
	check("dawne drzewka broni - zwrot punktów", book.tree_reset and not book.needs_migration and book.nodes.is_empty()
			and book.levels.is_empty() and book.points_left() == 5 and book.reset_gems.size() == 1)
	var gems: Array = book.take_reset_gems()
	check("kamienie z dawnych gniazd", gems.size() == 1 and gems[0]["kind"] == "ruby" and book.reset_gems.is_empty())
	var fresh = load("res://scripts/skill_book.gd").new()
	fresh.load_save_data(JSON.parse_string(JSON.stringify(book.get_save_data())))
	check("nowy zapis bez ponownego zwrotu", not fresh.tree_reset and fresh.points_left() == 5)
	fresh.free()
	book.load_save_data({"skill_xp": 10000, "tree": 2})
	# pasek umiejętności: progi ceny punktu
	var bar = load("res://scripts/skill_book.gd").new()
	bar.skill_xp = 20 * 2000 + 15000 * 3 + 100
	check("progi paska", bar.earned_points() == 23 and bar.skill_xp_progress() == [100, 15000], "%d" % bar.earned_points())
	bar.free()
	var gained := [0]
	book.skill_points_gained.connect(func(count: int) -> void: gained[0] += count)
	p.stats.add_xp(4100)
	# awanse postaci też dają punkty (1 co 2 poziomy) - sygnał liczy oba źródła
	check("exp napełnia pasek umiejętności", book.skill_xp == 14100 and gained[0] == 2 + book.level_points() and book.earned_points() == 7,
			"%d" % gained[0])
	# więcej punktów na resztę testu
	p.stats.level = 20
	book.character_level = 20
	book.skill_xp = 19 * 2000
	check("droga przez puste miejsca", _take_path(book, "cyclone_eye") and _take_path(book, "smoke_burst")
			and _take_path(book, "whirl_dmg") and book.has_node_id("flicker") and _take_path(book, "seeker_hits")
			and not book.has_node_id("loyal_seeker"), str(book.nodes.keys()))
	var spent: int = book.points_spent()
	check("drzewko za punkty z paska", spent == book.nodes.size() and book.points_left() == 31 - spent, "%d" % spent)
	check("punkty za poziom postaci", book.level_points() == 10)
	var gained_level := [0]
	book.skill_points_gained.connect(func(count: int) -> void: gained_level[0] += count)
	book.set_character_level(21)
	book.set_character_level(22)
	check("awans daje punkt co 2 poziomy", gained_level[0] == 1 and book.level_points() == 11)
	book.set_character_level(20)
	# poziomy umiejętności za punkty: 1-5 po 1, 6-10 po 2, 11-15 po 3, 16-20 po 5
	check("koszty poziomów", Skills.cost("whirlwind", 5) == 1 and Skills.cost("whirlwind", 6) == 2
			and Skills.cost("whirlwind", 15) == 3 and Skills.cost("whirlwind", 20) == 5 and Skills.MAX_LEVEL == 20)
	check("ulepszenie za punkty", book.upgrade("whirlwind") and book.upgrade("whirlwind") and book.level_of("whirlwind") == 3
			and book.points_spent() == spent + 2)
	check("siła poziomu", Skills.power(5) == 5.0 and Skills.power(20) == 12.5 and Skills.count(20) == 10 and Skills.count(4) == 4)
	check("węzła z poziomami nie cofa", book.refund_reason("whirlwind") != "")
	p.stats.gold = 0
	check("cofnięcie poziomu wymaga złota", book.downgrade_gold("whirlwind") == 160 and not book.downgrade("whirlwind", p.stats))
	p.stats.gold = 1000
	check("cofnięcie poziomu za złoto", book.downgrade("whirlwind", p.stats) and book.level_of("whirlwind") == 2
			and p.stats.gold == 840 and book.points_spent() == spent + 1)
	check("poziomu 1 z węzła nie cofa", book.downgrade("whirlwind", p.stats) and book.downgrade_gold("whirlwind") == -1)
	book.upgrade("whirlwind")
	book.upgrade("whirlwind")
	# premie z węzłów działają z każdą bronią: Wirujące ostrze (+20% Młynka), Twarda skóra (+8% zdrowia)
	check("premia z węzła", is_equal_approx(book.tree_bonus("whirl_damage"), 0.2) and is_equal_approx(book.tree_bonus("health_percent"), 0.08)
			and is_equal_approx(p.stats._bonus("health_percent") - p.stats.equipment.bonus("health_percent") - p.boons.bonus("health_percent"), 0.08))
	check("ataki i czary", is_equal_approx(p.stats.skill_speed(["attack", "spell"]), (p.stats.attack_speed() + p.stats.cast_speed()) / 2.0))
	check("węzeł kluczowy", book.has_keystone("cyclone_eye") and p.whirl_mana_factor() == 2.0)
	p._whirl_time = 2.0
	check("Oko Cyklonu rozkręca Młynek", is_equal_approx(p.whirl_spin_up(), 1.5))
	p._whirl_time = 30.0
	check("Oko Cyklonu - górna granica", is_equal_approx(p.whirl_spin_up(), 2.0))
	book.nodes.erase("cyclone_eye")
	check("bez węzła Młynek się nie rozkręca", p.whirl_spin_up() == 1.0)
	# cofanie prawym przyciskiem: liść tak, węzeł, od którego zależą inne - nie
	spent = book.points_spent()
	check("nie cofa węzła, od którego zależą inne", not book.refund("hp_1") and book.refund_reason("hp_1") != "")
	check("cofa liść", book.refund("smoke_burst") and book.points_spent() == spent - 1 and not book.has_node_id("smoke_burst"))
	book.take("smoke_burst")
	p.stats.gold = 100
	check("cofnięcie węzła wymaga złota", not book.refund("smoke_burst", p.stats) and book.has_node_id("smoke_burst"))
	p.stats.gold = 1000
	check("cofnięcie węzła za złoto", book.refund("smoke_burst", p.stats) and p.stats.gold == 840)
	book.take("smoke_burst")
	p.stats.unspent_points = 1
	p.stats.spend_point("strength")
	var strength: int = p.stats.attributes["strength"]
	check("cofnięcie punktu atrybutu", p.stats.refund_point("strength") and p.stats.attributes["strength"] == strength - 1 and p.stats.unspent_points == 1)
	var copy = load("res://scripts/skill_book.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(book.get_save_data())))
	check("zapis drzewka", copy.nodes.size() == book.nodes.size() and copy.level_of("whirlwind") == 3 and not copy.tree_reset)
	copy.free()


func _check_respec(p) -> void:
	p.stats.add_gold(5000)
	var gold: int = p.stats.gold
	var price: int = p.skills.points_spent() * p.skills.refund_gold()
	var offers: Dictionary = load("res://scripts/village_services.gd").offers("respec", p, _FakeNpc.new())
	var row: Dictionary = offers["rows"][0]
	check("zapomnienie u mędrca dostępne", row["enabled"] and price > 0)
	row["action"].call()
	check("zapomnienie drzewka", p.skills.nodes.is_empty() and p.skills.level_of("whirlwind") == 0
			and p.stats.gold == gold - price and p.skills.points_spent() == 0)
	p.skills.take("whirlwind")
	check("poziomy też wracają jako punkty", p.skills.level_of("whirlwind") == 1)


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
