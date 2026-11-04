extends SceneTree
## Aury rezerwujące manę (Auras, SkillBook.auras): dane (ikona, tagi, węzeł w drzewku), włączanie i wyłączanie
## klawiszem paska z każdą bronią, rezerwacja many (maksimum maleje, pasek), Skupiona wola i Oszczędne aury,
## Krwawa Ofiara (rezerwacja zdrowia), premie aur (Krzepa, Wiatr Strzyboga, Źródła, żywioły), Postrach, Gniew Peruna,
## Mroźny Oddech (rani wrogów i gracza, nie zabija), zapis i wczytanie, naprawa zapisu z węzłami za dawnymi pustymi
## miejscami, wyłączenie aury po cofnięciu węzła.

var _world: Node
var _frame := 0
var _fails := 0
var p
var book


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame == 5:
		_part_one()
	elif _frame == 5 + 130:
		_part_two()
		print("WYNIK: %s" % ("OK" if _fails == 0 else "FAIL (%d)" % _fails))
		quit(1 if _fails > 0 else 0)
		return true
	return false


func _part_one() -> void:
	p = _world.player
	book = p.skills
	var Skills = load("res://scripts/skills.gd")
	var SkillTree = load("res://scripts/skill_tree.gd")
	var AuraData = load("res://scripts/aura_data.gd")
	var Hotbar = load("res://scripts/hotbar.gd")
	# dane
	var data_ok := true
	for id: String in AuraData.RESERVE:
		data_ok = data_ok and Skills.get_data(id).get("type", "") == "aura" and Skills.get_data(id)["icon"] != null \
				and "aura" in Skills.TAGS[id] and SkillTree.node_for_skill(id) != "" and not SkillTree.is_soon(SkillTree.node_for_skill(id)) \
				and AuraData.effect_text(id, 1) != "" and AuraData.COLORS.has(id)
	check("10 aur: dane, ikony, tagi i węzły w drzewku", data_ok and AuraData.RESERVE.size() == 10)
	check("węzły rezerwacji działają", not SkillTree.is_soon("focused_will") and not SkillTree.is_soon("thrifty_auras")
			and not SkillTree.is_soon("blood_offering") and SkillTree.node("blood_offering")["kind"] == "keystone")
	check("aura pasuje na pasek każdej broni", Hotbar.fits("vigor", 3, "melee") and Hotbar.fits("vigor", 3, "bow")
			and Hotbar.fits("vigor", 3, "spell") and Skills.works_with("dread", "bow") and not Skills.works_with("fireball", "bow"))
	# włączanie bez węzła
	p.skills.auras.clear()
	check("bez węzła aura się nie włącza", not p.auras.toggle("vigor") and book.auras.is_empty())
	for id: String in ["vigor", "strzybog_wind", "dread", "perun_wrath", "frost_breath", "swarog_ember", "life_spring", "mana_spring"]:
		book.grant_node(SkillTree.node_for_skill(id))
	p.stats.attributes["intelligence"] = 60
	p.stats.changed.emit()
	p.mana = p.stats.max_mana()
	var full_mana: int = p.stats.max_mana()
	var full_hp: int = p.stats.max_health()
	var speed: float = p.stats.move_speed()
	# Krzepa przez klawisz paska
	p.hotbar.put("melee", 3, "vigor")
	p._press_slot(3)
	p._held_slots[3] = false
	check("Krzepa włączona klawiszem paska", book.auras.has("vigor"))
	check("rezerwacja 30% many", p.stats.max_mana() == full_mana - roundi(full_mana * 0.3) and p.stats.full_max_mana() == full_mana,
			"%d / %d" % [p.stats.max_mana(), full_mana])
	check("mana spadła o rezerwację", p.mana <= p.stats.max_mana())
	check("Krzepa: +12% zdrowia", p.stats.max_health() == roundi(full_hp / 1.0 * 1.12) or absi(p.stats.max_health() - roundi(full_hp * 1.12)) <= 1,
			"%d -> %d" % [full_hp, p.stats.max_health()])
	check("ikona pod paskami", load("res://scripts/status_effects.gd").list(p).any(func(e: Dictionary) -> bool: return e["name"] == Skills.name_of("vigor")))
	var bar = _world.find_child("HUD", true, false).mana_bar
	check("pasek many: część zarezerwowana", bar.max_value == full_mana and bar.get_node("Reserved").visible)
	# z łukiem też działa
	p.mana = p.stats.max_mana()
	p.auras.toggle("strzybog_wind")
	check("Wiatr Strzyboga: szybkość", book.auras.has("strzybog_wind") and p.stats.move_speed() > speed + 0.07)
	# za mało many
	p.mana = p.stats.max_mana()
	p.auras.toggle("dread")
	check("trzecia aura (30%) mieści się", book.auras.has("dread") and p.stats.max_mana() == full_mana - roundi(full_mana * 0.9))
	p.mana = p.stats.max_mana()
	check("czwarta aura się nie mieści", not p.auras.toggle("perun_wrath") and not book.auras.has("perun_wrath"))
	# Skupiona wola i Oszczędne aury
	var before: float = book.aura_reserve("vigor")
	book.grant_node("focused_will")
	book.grant_node("thrifty_auras")
	check("Skupiona wola i Oszczędne aury: -18% rezerwacji", absf(book.aura_reserve("vigor") - before * 0.82) < 0.0001,
			"%.3f" % book.aura_reserve("vigor"))
	# wyłączanie oddaje manę
	var mana_before: float = p.mana
	p.auras.toggle("dread")
	check("wyłączenie zwalnia manę", not book.auras.has("dread") and p.stats.max_mana() > full_mana * 0.4 and p.mana >= mana_before)
	# Postrach
	p.auras.toggle("dread")
	check("Postrach: słabsze ciosy z bliska", p.auras.dread_hit(p.global_position + Vector2(20, 0)) < 0.95
			and p.auras.dread_hit(p.global_position + Vector2(400, 0)) == 1.0
			and p.auras.dread_cooldown(p.global_position + Vector2(20, 0)) > 1.05)
	p.auras.toggle("dread")
	p.auras.toggle("strzybog_wind")
	# Krwawa Ofiara: rezerwacja zdrowia
	book.grant_node("blood_offering")
	p.stats.changed.emit()
	p.health = p.stats.max_health()
	var mana_max: int = p.stats.max_mana()
	check("Krwawa Ofiara: mana bez rezerwacji, zdrowie zarezerwowane", mana_max == p.stats.full_max_mana()
			and p.stats.reserved_health() > 0 and p.stats.max_health() < p.stats.full_max_health())
	book.nodes.erase("blood_offering")
	book.set_aura("vigor", false)
	# żywioły
	p.stats.changed.emit()
	p.mana = p.stats.max_mana()
	var dmg: float = p.stats.kind_multiplier(Skills.basic_tags("melee"))
	p.auras.toggle("swarog_ember")
	check("Żar Swaroga: obrażenia i podpalenie", p.stats.kind_multiplier(Skills.basic_tags("melee")) > dmg
			and p.stats.ailment_chance("ignite") > 0.0 and "fire" in p.stats.support_elements(Skills.basic_tags("melee")))
	p.auras.toggle("swarog_ember")
	# Źródła
	var regen: float = p.stats.health_regen()
	var mregen: float = p.stats.mana_regen()
	p.mana = p.stats.max_mana()
	p.auras.toggle("life_spring")
	p.mana = p.stats.max_mana()
	p.auras.toggle("mana_spring")
	check("Źródła: regeneracja zdrowia i many", p.stats.health_regen() > regen and p.stats.mana_regen() > mregen)
	p.auras.toggle("life_spring")
	p.auras.toggle("mana_spring")
	# Gniew Peruna i Mroźny Oddech - wróg obok gracza
	p.mana = p.stats.max_mana()
	p.auras.toggle("perun_wrath")
	p.auras.toggle("frost_breath")
	check("Mroźny Oddech nie rezerwuje many", book.auras.has("frost_breath") and book.aura_reserve("frost_breath") == 0.0)
	p.health = p.stats.max_health()
	p.stats.temp_bonus["cold_resistance"] = 0.0
	_spawn_dummy()


var _dummy
var _dummy_hp := 0


func _spawn_dummy() -> void:
	var scene: PackedScene = load("res://scenes/goblin.tscn")
	_dummy = scene.instantiate()
	_dummy.position = p.global_position + Vector2(30, 0)
	p.get_parent().add_child(_dummy)
	_dummy.max_health = 100000
	_dummy.health = 100000
	_dummy.damage = 0
	_dummy_hp = _dummy.health
	p.auras._wrath_next = 0.1


func _part_two() -> void:
	check("aury ranią wroga obok", is_instance_valid(_dummy) and _dummy.health < _dummy_hp, "%d" % (_dummy.health if is_instance_valid(_dummy) else -1))
	check("Mroźny Oddech rani gracza", p.health < p.stats.max_health())
	p.health = 3
	p.auras._burn_self(10.0)
	check("Mroźny Oddech nie zabija", p.health == 1 and not p.is_dead)
	# zapis i wczytanie
	var saved: Dictionary = JSON.parse_string(JSON.stringify(book.get_save_data()))
	book.load_save_data(saved)
	check("zapis: włączone aury wracają", book.auras.has("perun_wrath") and book.auras.has("frost_breath"))
	# cofnięcie węzła wyłącza aurę
	var SkillTree = load("res://scripts/skill_tree.gd")
	book.nodes.erase(SkillTree.node_for_skill("perun_wrath"))
	book.set_aura("frost_breath", true)
	check("bez węzła aura gaśnie", not book.auras.has("perun_wrath"))
	# stary zapis: węzeł za dawnym pustym miejscem (Krwawa Ofiara za Skupioną wolą) - Skupiona wola za darmo
	var path: Array = SkillTree.path_to("blood_offering")
	var old_nodes: Array = []
	for id: String in path:
		if id != "focused_will":
			old_nodes.append(id)
	var old := {"tree": 2, "nodes": old_nodes, "levels": {}, "skill_xp": 0, "bonus_points": 0}
	book.load_save_data(old)
	check("stary zapis: dawne puste miejsce za darmo", book.nodes.has("focused_will") and book.nodes.has("blood_offering")
			and book.bonus_points >= 1, str(book.bonus_points))
	var reached: Dictionary = book.reachable()
	check("stary zapis: wszystkie węzły osiągalne", book.nodes.keys().all(func(id: String) -> bool: return reached.has(id)))
