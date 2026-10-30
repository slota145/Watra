extends SceneTree
## Drzewko łuku (etap 3): dane drzewka (umiejętności, ok. 35 pasywnych, 4 kluczowe, ikony), przeniesienie umiejętności
## łuku kupionych za złoto na węzły, Grot Swaroga (napinanie, strzał, wybuch combo), Deszcz Strzał, Odskok (skok,
## darmowa Salwa z większą liczbą strzał, Myśliwy z Cienia), Sidła (unieruchomienie, ciosy krytyczne), Sokół (combo -
## od razu nurkuje), Jadowe Groty (trucizna, przeskok w combo), Strzała Wichru, Balista (strzela, legendarna salwa
## i strzały tropiące), Łuk Swaroga (rozszczepienie strzały tropiącej) i Strzelanie w biegu.

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0
var _x := 0.0


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


## Wróg ranny albo martwy (martwy może już zniknąć ze świata).
func _hurt() -> bool:
	return not is_instance_valid(_enemy) or _enemy.health < _hp or _enemy.state == 4


func _now() -> int:
	return _enemy.health if is_instance_valid(_enemy) else 0


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var bs = p.bow_skills if p != null else null
	match _frame:
		5:
			_check_migration()
			p.equipment.equip("short_bow")
			check("łuk w ręku", p.stats.weapon_type() == "bow")
			_check_tree(p)
			# Strzała Wichru: rani i odrzuca
			_aim_at_enemy(p)
			var at: Vector2 = _enemy.global_position
			_enemy.set_physics_process(true)
			bs.press("wind_arrow")
			check("Strzała Wichru rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("odnowienie Strzały Wichru", p.cooldown_of("wind_arrow").x > 0.0)
			_x = at.x
		8:
			check("Strzała Wichru odrzuca", not is_instance_valid(_enemy) or _enemy.state == 4 or _enemy.global_position.x > _x + 2.0)
			# Grot Swaroga: napinanie
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			p._held_ids["power_shot"] = true
			bs.press("power_shot")
			check("Grot Swaroga napina", bs.power_charge() >= 0.0)
		50:
			check("pełne napięcie", is_equal_approx(bs.power_charge(), 1.0), "%.2f" % bs.power_charge())
			p.aim_override = _enemy.hurt_center() - p.body_center()
			p._held_ids.erase("power_shot")
		52:
			check("puszczenie wypuszcza strzałę", bs.power_charge() < 0.0 and p.cooldown_of("power_shot").x > 0.0)
		60:
			check("Grot Swaroga rani", _hurt(), "%d -> %d" % [_hp, _now()])
			_aim_at_enemy(p)
			bs._fire_blast(_enemy.hurt_center(), 1.0)
			check("wybuch ognia (combo)", _hurt())
			# Deszcz Strzał po Salwie: gęściej
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			p.note_skill("multishot")
			bs.press("arrow_rain")
			var rain = _find(func(n: Node) -> bool: return n.has_method("_wave"))
			check("Deszcz Strzał pada", rain != null)
			if rain != null:
				rain.global_position = _enemy.global_position
				check("combo: gęstszy deszcz", rain.tick < 0.25 / 1.9, "%.3f" % rain.tick)
		100:
			check("Deszcz Strzał rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Odskok: skok do tyłu, darmowa Salwa z większą liczbą strzał, Myśliwy z Cienia
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			_x = p.global_position.x
			bs.press("vault")
			check("Odskok: skok", p.is_dashing() and p.cooldown_of("vault").x > 0.0)
			check("Myśliwy z Cienia: wrogowie nie widzą", _enemy._player_is_safe())
		125:
			check("Odskok do tyłu", p.global_position.x < _x - 40.0, "%.0f -> %.0f" % [_x, p.global_position.x])
			check("po Odskoku Salwa jako combo", p.combo_with("multishot"))
			var before := _count_arrows()
			var mana: float = p.mana
			p._skill_cooldown_timer = 0.0
			p._attack_timer = 0.0
			p._skill_held = true
			p._process_skill(0.016)
			p._skill_held = false
			# 5 strzał combo + 1 z węzła + 2 z Gradu
			check("darmowa Salwa z 8 strzałami", is_equal_approx(p.mana, mana) and _count_arrows() - before == 8,
					"%d strzał" % (_count_arrows() - before))
			# Sidła: unieruchomienie i ciosy krytyczne
			_aim_at_enemy(p)
			bs.press("snare")
			var snare = _find(func(n: Node) -> bool: return n.has_method("spring"))
			check("Sidła zastawione", snare != null)
			if snare != null:
				snare.global_position = _enemy.global_position
				snare.spring()
			check("Sidła unieruchamiają", not is_instance_valid(_enemy) or _enemy.state == 4 or (_enemy.is_stunned() and load("res://scripts/bow_skills.gd").is_snared(_enemy)))
			check("trafienie w Sidłach krytyczne", bs.forced_crit(_enemy))
		130:
			# Sokół po Strzale tropiącej: od razu nurkuje
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			p.note_skill("seeker")
			bs.press("falcon")
			check("Sokół przywołany i nurkuje", is_instance_valid(bs._falcon) and bs._falcon._target != null)
		190:
			check("Sokół rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Jadowe Groty po Sidłach: trucizna przeskakuje
			_aim_at_enemy(p)
			p.mana = p.stats.max_mana()
			p.note_skill("snare")
			bs.press("venom_arrows")
			check("Jadowe Groty combo", bs._venom_time > 0.0 and bs._venom_spread)
			p.hit_enemy(_enemy, 5, p.global_position, 0.0)
			check("trucizna", not is_instance_valid(_enemy) or _enemy.state == 4 or bs.is_poisoned(_enemy))
			check("Jadowe Groty w efektach", load("res://scripts/status_effects.gd").list(p).any(func(e: Dictionary) -> bool: return e["name"] == "Jadowe Groty"))
			_hp = _now()
			# Balista
			p.mana = p.stats.max_mana()
			bs.press("ballista")
			check("Balista stoi", bs.ballista() != null)
			if bs.ballista() != null and is_instance_valid(_enemy):
				bs.ballista().global_position = _enemy.global_position + Vector2(-60, 0)
		250:
			check("trucizna rani", _hurt(), "%d -> %d" % [_hp, _now()])
			_aim_at_enemy(p)
			if bs.ballista() != null and is_instance_valid(_enemy):
				bs.ballista().global_position = _enemy.global_position + Vector2(-60, 0)
				bs.ballista()._next = 0.0
		280:
			check("Balista strzela", _hurt(), "%d -> %d" % [_hp, _now()])
			_check_legends(p, bs)
			# Strzelanie w biegu
			var speed: float = p.stats.attack_speed()
			p._move_velocity = Vector2(100, 0)
			bs._update_running()
			check("Strzelanie w biegu", p.stats.attack_speed() > speed + 0.1 and bs.running_fire(), "%.2f -> %.2f" % [speed, p.stats.attack_speed()])
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


func _check_tree(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	var nodes: Dictionary = Tree.nodes("bow")
	var kinds := {}
	for id: String in nodes:
		kinds[nodes[id]["kind"]] = kinds.get(nodes[id]["kind"], 0) + 1
	check("drzewko łuku: rozmiar", kinds.get("passive", 0) >= 30 and kinds.get("skill", 0) == 13 and kinds.get("keystone", 0) == 4, str(kinds))
	var broken := []
	for id: String in nodes:
		for link: String in nodes[id]["links"]:
			if not nodes.has(link):
				broken.append(link)
		if id != "start" and Tree.path_to("bow", id).is_empty():
			broken.append(id)
	check("drzewko łuku: połączenia i osiągalność", broken.is_empty(), str(broken))
	var view = load("res://scripts/ui/skill_tree_view.gd").new()
	view.weapon_type = "bow"
	var no_icon := nodes.keys().filter(func(id: String) -> bool: return view.icon_of(id) == null)
	var described := nodes.keys().filter(func(id: String) -> bool: return view.describe(id).contains("%"))
	view.free()
	check("drzewko łuku: ikony", no_icon.is_empty(), str(no_icon))
	var close := []
	for a: String in nodes:
		for b: String in nodes:
			if a < b and nodes[a]["pos"].distance_to(nodes[b]["pos"]) < 1.2:
				close.append(a + "/" + b)
	check("drzewko łuku: węzły nie nachodzą", close.is_empty(), str(close))
	check("opisy węzłów", described.size() > 30)
	var Skills = load("res://scripts/skills.gd")
	var no_text := []
	for id in ["power_shot", "arrow_rain", "vault", "snare", "falcon", "venom_arrows", "wind_arrow", "ballista"]:
		if Skills.effect_text(id, 1) == "" or Skills.mana_cost_text(id) == "" or not load("res://scripts/hotbar.gd").can_slot_skill(id):
			no_text.append(id)
	check("umiejętności: opisy i pasek", no_text.is_empty(), str(no_text))
	p.stats.level = 60
	p.skills.character_level = 60
	for i in 5:
		for id: String in nodes:
			p.skills.take("bow", id)
	check("całe drzewko łuku do wybrania", p.skills.nodes["bow"].size() == nodes.size() - 1)
	check("przebicie i zasięg z węzłów", p._make_projectile(p.equipment.weapon(), Vector2.RIGHT).pierce == 1)
	p.mana = p.stats.max_mana()


## Starsze zapisy: umiejętności łuku kupione za złoto dostają węzły; po zapomnieniu drzewka nie wracają.
func _check_migration() -> void:
	var Book = load("res://scripts/skill_book.gd")
	var book = Book.new()
	book.load_save_data({"levels": {"multishot": 2, "seeker": 1, "whirlwind": 1}, "nodes": {"melee": ["whirlwind"]}})
	check("łuk ze starszego zapisu", book.has_node_id("bow", "multishot") and book.has_node_id("bow", "seeker") and book.level_of("multishot") == 2)
	book.reset_tree("bow")
	var copy = Book.new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(book.get_save_data())))
	check("zapomniane drzewko łuku nie wraca", copy.level_of("multishot") == 0 and copy.levels.get("multishot", 0) == 2)
	book.free()
	copy.free()


func _check_legends(p, bs) -> void:
	var Loot = load("res://scripts/loot.gd")
	var Items = load("res://scripts/items.gd")
	check("legendy w skarbcu lochów", load("res://scripts/dungeons.gd").VAULT_LEGENDS.size() == 4)
	var ballista = bs.ballista()
	if ballista == null:
		check("balista do legend", false)
		return
	# Rękawice Cieśli: salwa trzech bełtów
	var gloves: String = Loot.legendary_at_level("legend_engineer_gloves", 20)
	p.equipment.equip(gloves, 0)
	var before := _count_arrows()
	ballista._shoot(Vector2.RIGHT)
	check("Balista strzela salwą", _count_arrows() - before == 3, "%d" % (_count_arrows() - before))
	check("opis rękawic", Items.describe(gloves).contains("salwą"))
	# Talizman Tropiciela: strzały tropiące
	var talisman: String = Loot.legendary_at_level("legend_tracker_talisman", 20)
	p.equipment.equip(talisman, 0)
	var seekers := _count_seekers()
	ballista._shoot(Vector2.RIGHT)
	check("Balista strzela strzałami tropiącymi", _count_seekers() - seekers == 3, "%d" % (_count_seekers() - seekers))
	# Łuk Swaroga: rozszczepienie strzały tropiącej
	var bow: String = Loot.legendary_at_level("legend_swarog_bow", 20)
	p.equipment.equip(bow, 0)
	seekers = _count_seekers()
	p._cast_seeker(1)
	var newest = _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return n is Node2D and n.get("split") != null).back()
	check("Łuk Swaroga: strzała się rozszczepi", newest != null and newest.split == 2 and _count_seekers() - seekers == 1)
	check("opis łuku", Items.describe(bow).contains("rozszczepia"))


func _count_arrows() -> int:
	return _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return n.scene_file_path == "res://scenes/projectile.tscn").size()


func _count_seekers() -> int:
	return _world.player.get_parent().get_children().filter(func(n: Node) -> bool: return n.get("split") != null).size()


func _find(test: Callable) -> Node:
	for child in _world.player.get_parent().get_children():
		if test.call(child):
			return child
	return null


## Gracz kilkadziesiąt pikseli przed najbliższym prawdziwym wrogiem (nie kukłą), celując w niego.
func _aim_at_enemy(p) -> void:
	var space: PhysicsDirectSpaceState2D = _world.get_world_2d().direct_space_state
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		if enemy.state == 4 or enemy.is_in_group("bosses") or enemy.scene_file_path.contains("dummy"):
			continue
		var spot: Vector2 = enemy.global_position + Vector2(-40, 0)
		var ray := PhysicsRayQueryParameters2D.create(spot + Vector2(0, -13), enemy.hurt_center(), 1)
		if space.intersect_ray(ray).is_empty():
			p.global_position = spot
			p.reset_physics_interpolation()
			p.aim_override = enemy.hurt_center() - (spot + Vector2(0, -13))
			_enemy = enemy
			_enemy.set_physics_process(false)
			_hp = enemy.health
			return
