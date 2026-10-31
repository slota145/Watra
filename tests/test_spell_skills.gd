extends SceneTree
## Drzewko księgi magii (etap 4): dane drzewka (umiejętności, ok. 35 pasywnych, 4 kluczowe, ikony), przeniesienie
## czarów kupionych za złoto na węzły, Włócznia Marzanny (spowolnienie), Zamieć (combo - zamrożenie), Spadająca
## Gwiazda (podpalenie), Burza Peruna (combo - przeskoki), Kula Piorunów, Krok przez Mgłę (teleport, potem od razu
## naładowana Kula ognia), Tarcza Many (combo - cały cios), Kamień Runiczny (premia w kręgu), węzły kluczowe Harmonia
## Żywiołów, Pełnia Mocy i Ofiara Krwi oraz legendy: Księga Marzanny i Korona Peruna.

var _world: Node
var _frame := 0
var _fails := 0
var _enemy: Node
var _hp := 0
var _x := 0.0
## Zdrowie wrogów w zasięgu Burzy Peruna (piorun wybiera cel losowo).
var _near := {}


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


func _alive() -> bool:
	return is_instance_valid(_enemy) and _enemy.state != 4


## Przed każdym czarem: pełne zdrowie i mana (Ofiara Krwi płaci zdrowiem), bez odnowień.
func _ready_to_cast(p) -> void:
	p.health = p.stats.max_health()
	p.mana = p.stats.max_mana()
	p.spell_skills._cooldowns.clear()


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var ss = p.spell_skills if p != null else null
	match _frame:
		5:
			_check_migration()
			p.equipment.equip("spellbook")
			check("księga w ręku", p.stats.weapon_type() == "spell")
			_check_tree(p)
			# Włócznia Marzanny po Kuli ognia: przebija, spowalnia, odłamki
			_aim_at_enemy(p)
			_ready_to_cast(p)
			p.note_skill("fireball")
			ss.press("frost_lance")
			check("odnowienie Włóczni", p.cooldown_of("frost_lance").x > 0.0)
		25:
			check("Włócznia Marzanny rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("Włócznia spowalnia", not _alive() or _enemy.is_chilled())
			# Zamieć po Włóczni: od razu zamraża
			_aim_at_enemy(p)
			_ready_to_cast(p)
			p.note_skill("frost_lance")
			ss.press("blizzard")
			check("Zamieć zamraża (combo)", not _alive() or _enemy.is_stunned())
		70:
			check("Zamieć rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Spadająca Gwiazda po Zamieci: wybuch i podpalenie
			_aim_at_enemy(p)
			_ready_to_cast(p)
			p.note_skill("blizzard")
			ss.press("meteor")
		120:
			check("Spadająca Gwiazda rani", _hurt(), "%d -> %d" % [_hp, _now()])
			check("podpalenie", not _alive() or ss.is_burning(_enemy))
			# Burza Peruna po Łańcuchu błyskawic
			_aim_at_enemy(p)
			_ready_to_cast(p)
			p.note_skill("chain_lightning")
			ss.press("storm_call")
			_near.clear()
			for e in _world.get_tree().get_nodes_in_group("enemies"):
				if e.state != 4 and e.global_position.distance_to(p.global_position) <= load("res://scripts/skills.gd").STORM_RANGE:
					e.set_physics_process(false)
					_near[e] = e.health
			check("Burza Peruna (combo - przeskoki)", ss.storm_active() and ss._storm_chain)
			check("Burza w efektach", load("res://scripts/status_effects.gd").list(p).any(func(e: Dictionary) -> bool: return e["name"] == "Burza Peruna"))
		170:
			check("Burza Peruna rani", _near.keys().any(func(e) -> bool: return not is_instance_valid(e) or e.health < _near[e] or e.state == 4),
					"%d wrogów w zasięgu" % _near.size())
			# Kula Piorunów
			_aim_at_enemy(p)
			_ready_to_cast(p)
			ss._storm_time = 0.0
			p.note_skill("thunder_wave")
			ss.press("ball_lightning")
			check("Kula Piorunów leci", _find(func(n: Node) -> bool: return n.has_method("_zap")) != null)
		200:
			check("Kula Piorunów rani", _hurt(), "%d -> %d" % [_hp, _now()])
			# Krok przez Mgłę i od razu naładowana Kula ognia
			_ready_to_cast(p)
			_x = p.global_position.x
			p.aim_override = Vector2(-90, 0)
			ss.press("blink")
			check("Krok przez Mgłę", p.global_position.x < _x - 30.0, "%.0f -> %.0f" % [_x, p.global_position.x])
			check("po Kroku Kula ognia jako combo", p.combo_with("fireball"))
			p._skill_cooldown_timer = 0.0
			p._attack_timer = 0.0
			p._skill_held = true
			p._process_skill(0.016)
			p._skill_held = false
			check("Kula ognia od razu naładowana", not p.is_charging_fireball() and p._skill_cooldown_timer > 0.0)
			# Tarcza Many po Kroku: cały cios zabiera mana
			_ready_to_cast(p)
			p.note_skill("blink")
			ss.press("mana_shield")
			var hp: int = p.health
			var mana: float = p.mana
			p._invulnerable_timer = 0.0
			p.take_damage(30, p.global_position + Vector2(20, 0))
			check("Tarcza Many przyjmuje cały cios", ss.shield_active() and p.health == hp and p.mana < mana, "%d -> %d, mana %.0f -> %.0f" % [hp, p.health, mana, p.mana])
			# Kamień Runiczny pod nogami
			_ready_to_cast(p)
			p.aim_override = Vector2(0, 10)
			ss.press("rune_stone")
			_x = p.stats.cast_speed()
		202:
			check("Kamień Runiczny: premia w kręgu", ss.in_rune() and p.stats.cast_speed() > _x - 0.001 and p.stats.temp_bonus.get("cast_speed", 0.0) > 0.1,
					"%.2f" % p.stats.temp_bonus.get("cast_speed", 0.0))
			_check_keystones(p, ss)
			_check_legends(p, ss)
		260:
			check("spowolnienie mija", not _alive() or not _enemy.is_chilled())
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


func _check_tree(p) -> void:
	var Tree = load("res://scripts/skill_tree.gd")
	var nodes: Dictionary = Tree.nodes("spell")
	var kinds := {}
	for id: String in nodes:
		kinds[nodes[id]["kind"]] = kinds.get(nodes[id]["kind"], 0) + 1
	check("drzewko księgi: rozmiar", kinds.get("passive", 0) >= 30 and kinds.get("skill", 0) == 13 and kinds.get("keystone", 0) == 4, str(kinds))
	var broken := []
	for id: String in nodes:
		for link: String in nodes[id]["links"]:
			if not nodes.has(link):
				broken.append(link)
		if id != "start" and Tree.path_to("spell", id).is_empty():
			broken.append(id)
	check("drzewko księgi: połączenia i osiągalność", broken.is_empty(), str(broken))
	var view = load("res://scripts/ui/skill_tree_view.gd").new()
	view.weapon_type = "spell"
	var no_icon := nodes.keys().filter(func(id: String) -> bool: return view.icon_of(id) == null)
	var no_text := nodes.keys().filter(func(id: String) -> bool: return view.describe(id).split("\n").size() < 2)
	view.free()
	check("drzewko księgi: ikony i opisy", no_icon.is_empty() and no_text.is_empty(), str(no_icon + no_text))
	var close := []
	for a: String in nodes:
		for b: String in nodes:
			if a < b and nodes[a]["pos"].distance_to(nodes[b]["pos"]) < 1.2:
				close.append(a + "/" + b)
	check("drzewko księgi: węzły nie nachodzą", close.is_empty(), str(close))
	var Skills = load("res://scripts/skills.gd")
	var missing := []
	for id in ["frost_lance", "blizzard", "storm_call", "ball_lightning", "meteor", "blink", "mana_shield", "rune_stone"]:
		if Skills.effect_text(id, 1) == "" or Skills.mana_cost_text(id) == "" or not load("res://scripts/hotbar.gd").can_slot_skill(id):
			missing.append(id)
	check("czary: opisy i pasek", missing.is_empty(), str(missing))
	p.stats.level = 60
	p.skills.character_level = 60
	for i in 5:
		for id: String in nodes:
			p.skills.take("spell", id)
	check("całe drzewko księgi do wybrania", p.skills.nodes["spell"].size() == nodes.size() - 1)


## Starsze zapisy: czary kupione za złoto dostają węzły.
func _check_migration() -> void:
	var book = load("res://scripts/skill_book.gd").new()
	book.load_save_data({"levels": {"fireball": 3, "chain_lightning": 1, "thunder_wave": 1}, "nodes": {"melee": []}})
	check("czary ze starszego zapisu", book.has_node_id("spell", "fireball") and book.has_node_id("spell", "thunder_wave")
			and book.level_of("fireball") == 3)
	book.free()


func _check_keystones(p, ss) -> void:
	# Harmonia Żywiołów: czar innego żywiołu niż poprzedni
	ss._harmony_time = 0.0
	ss.on_cast("fireball")
	ss.on_cast("frost_lance")
	check("Harmonia Żywiołów", ss._harmony_time > 0.0)
	ss.on_cast("blizzard")
	# Pełnia Mocy: przy pełnej manie mocniejsze czary, umiejętności droższe
	p.mana = p.stats.max_mana()
	ss._physics_process(0.0)
	check("Pełnia Mocy", p.stats.temp_bonus.get("spell_damage", 0.0) >= 0.4 and ss.mana_cost_factor() > 1.0)
	# Ofiara Krwi: umiejętności kosztują zdrowie
	var hp: int = p.health
	var mana: float = p.mana
	p.spend_mana(10.0)
	check("Ofiara Krwi płaci zdrowiem", p.health < hp and is_equal_approx(p.mana, mana), "%d -> %d" % [hp, p.health])
	p.health = 5
	check("Ofiara Krwi nie zabija", not p.spend_mana(50.0) and p.health == 5)
	p.health = p.stats.max_health()


func _check_legends(p, ss) -> void:
	var Loot = load("res://scripts/loot.gd")
	var Items = load("res://scripts/items.gd")
	check("legendy księgi w skarbcu lochów", load("res://scripts/dungeons.gd").VAULT_LEGENDS.has("legend_marzanna_book")
			and load("res://scripts/dungeons.gd").VAULT_LEGENDS.has("legend_perun_crown"))
	# Księga Marzanny: Zamieć zawsze zamraża
	var book: String = Loot.legendary_at_level("legend_marzanna_book", 20)
	p.equipment.equip(book, 0)
	_aim_at_enemy(p)
	_ready_to_cast(p)
	p._chain_time = 0.0
	ss.press("blizzard")
	check("Księga Marzanny zamraża", not _alive() or _enemy.is_stunned())
	check("opis księgi", Items.describe(book).contains("zamraża"))
	# Korona Peruna: Burza trwa, dopóki trzymasz klawisz
	var crown: String = Loot.legendary_at_level("legend_perun_crown", 20)
	p.equipment.equip(crown, 0)
	_ready_to_cast(p)
	ss.press("storm_call")
	p._held_ids["storm_call"] = true
	ss._storm_time = 0.05
	ss._process_storm(0.1)
	check("Korona Peruna podtrzymuje burzę", ss.storm_active())
	p._held_ids.erase("storm_call")
	check("opis korony", Items.describe(crown).contains("trzymasz"))


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
