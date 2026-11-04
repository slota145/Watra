extends SceneTree
## Test tagów umiejętności i atrybutów jak w Last Epoch: każda umiejętność ma tagi z każdej grupy, atrybut z tagu
## daje +1% obrażeń za punkt (zamiast płaskich), zręczność - unik z malejącymi zyskami (nie szybkość), szybkość
## umiejętności liczy prędkość broni, a stary zapis oddaje punkty atrybutów do rozdania.

func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


var _fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1


func _run() -> void:
	var Sk: GDScript = load("res://scripts/skills.gd")
	# tagi: każda umiejętność broni (poza pasywnymi regeneracjami) ma rodzaj i atrybut, każdy tag ma nazwę i ikonkę
	var missing: Array[String] = []
	for id: String in Sk.DATA:
		if Sk.DATA[id]["type"] in ["health_regen", "mana_regen"]:
			continue
		var tags: Array = Sk.tags(id)
		var kind := tags.any(func(t: String) -> bool: return t in Sk.TAG_GROUPS[0])
		var attribute := tags.any(func(t: String) -> bool: return t in Sk.TAG_GROUPS[3])
		if not kind or not attribute:
			missing.append(id)
	_check(missing.is_empty(), "umiejętności mają rodzaj i atrybut %s" % [missing])
	var known := {}
	for group: Array in Sk.TAG_GROUPS:
		for tag: String in group:
			known[tag] = true
	var bad: Array[String] = []
	for id: String in Sk.TAGS:
		for tag: String in Sk.TAGS[id]:
			if not known.has(tag):
				bad.append("%s:%s" % [id, tag])
	for tag: String in known:
		if not Sk.TAG_NAMES.has(tag) or not ResourceLoader.exists(Sk.tag_icon_path(tag)):
			bad.append(tag)
	_check(bad.is_empty(), "tagi znane, z nazwą i ikonką %s" % [bad])
	_check(Sk.tags_text("flicker").begins_with("Atak, cios, ruch, fizyczne, siła"), "opis tagów: %s" % Sk.tags_text("flicker"))
	_check(Sk.tags_bbcode(Sk.tags("fireball")).count("[img") == 5, "linia tagów z ikonkami")

	var eq: Node = load("res://scripts/equipment.gd").new()
	root.add_child(eq)
	var stats: Node = load("res://scripts/character_stats.gd").new()
	root.add_child(stats)
	stats.equipment = eq
	eq.equip("iron_sword")
	var base_min: int = stats.damage_min()
	stats.attributes["strength"] = 30
	stats.attributes["dexterity"] = 10
	stats.attributes["intelligence"] = 20
	_check(stats.damage_min() == base_min, "atrybuty nie dodają płaskich obrażeń")
	_check(is_equal_approx(stats.attribute_damage(Sk.tags("lunge")), 0.3), "siła: +30% Szarży")
	_check(is_equal_approx(stats.attribute_damage(Sk.tags("flicker")), 0.4), "Mgnienie liczy siłę i zręczność (+40%)")
	_check(is_equal_approx(stats.attribute_damage(Sk.tags("fireball")), 0.2), "inteligencja: +20% Kuli ognia")
	_check(is_equal_approx(stats.attribute_damage(["attack"]), 0.3), "bez tagu atrybutu - główny atrybut broni (siła)")
	_check(is_equal_approx(stats.kind_multiplier(Sk.tags("lunge")), 1.3), "mnożnik rodzaju z atrybutem")
	# szybkość nie rośnie z atrybutami, ale umiejętności liczą prędkość broni
	_check(is_equal_approx(stats.attack_speed(), 1.0) and is_equal_approx(stats.cast_speed(), 1.0), "zręczność i inteligencja nie dają szybkości")
	eq.equip("dagger_t1")
	_check(is_equal_approx(stats.skill_speed(Sk.tags("lunge")), 1.4), "umiejętność ze sztyletem szybsza (x1,4)")
	# unik ze zręczności: 0,4% za punkt, malejące zyski, wspólny limit
	stats.attributes["dexterity"] = 25
	_check(is_equal_approx(stats.dodge_chance(), 0.1), "25 zręczności - 10% uniku")
	stats.attributes["dexterity"] = 60
	var dodge60: float = stats.dodge_chance()
	stats.attributes["dexterity"] = 500
	var dodge500: float = stats.dodge_chance()
	_check(dodge60 > 0.2 and dodge60 < 0.24 and dodge500 <= stats.DODGE_CAP and dodge500 > 0.33,
			"malejące zyski uniku: 60 pkt %d%%, 500 pkt %d%%" % [roundi(dodge60 * 100), roundi(dodge500 * 100)])
	# stary zapis: wszystkie punkty atrybutów wracają do rozdania, nowy zostaje
	stats.load_save_data({"level": 20, "unspent_points": 2, "attributes": {"strength": 10, "vitality": 7}})
	_check(stats.unspent_points == 38 and stats.attributes["strength"] == 0 and stats.attributes_reset, "stary zapis - darmowy reset atrybutów, 2 punkty za poziom")
	stats.attributes["strength"] = 5
	stats.unspent_points = 14
	stats.load_save_data(stats.get_save_data())
	_check(stats.attributes["strength"] == 5 and stats.unspent_points == 14 and not stats.attributes_reset, "nowy zapis bez resetu")
	print("WYNIK: ", "OK" if _fails == 0 else "FAIL")
	quit()
