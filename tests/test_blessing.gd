extends SceneTree
## Błogosławieństwo Watry (Mapa Nawii, etap 2): oczyszczone węzły obszaru Pól Zbożowych na Mapie Nawii (stopnie 8-10,
## poziomy 45-55) i włączone błogosławieństwo - potwory krainy mają poziomy 51-55 (bossowie 57), łup i doświadczenie
## +6%, zapis przełącznika (Boons), okno przy kapliczce i obwódka na mapie świata. Bez błogosławieństwa krainy mają
## zwykłe poziomy.

const ZONE := "fields"
const SEED := 12345

var _world: Node
var _frame := 0
var _fails := 0
var _N
var _L
var _cleared: Array[int] = []


func _initialize() -> void:
	TranslationServer.set_locale("pl")
	root.get_node("Game").save_path = "user://test_savegame.json"
	_N = load("res://scripts/nawia_map.gd")
	_L = load("res://scripts/levels.gd")
	var nodes: Array[Dictionary] = _N.nodes(SEED)
	for node in nodes:
		if node["area"] == ZONE and int(node["ring"]) <= 2:
			_cleared.append(int(node["id"]))
	check("trzy węzły obszaru (stopnie 8-10)", _cleared.size() == 3)
	check("poziom błogosławieństwa = najtrudniejszy węzeł", _N.blessing_level(nodes, _cleared, ZONE) == 55)
	check("bez węzła - bez błogosławieństwa", _N.blessing_level(nodes, _cleared, "cemetery") == 0)
	check("premia rośnie z węzłami", is_equal_approx(_N.blessing_bonus(nodes, _cleared, ZONE), 0.06))
	check("zwykłe poziomy bez błogosławieństwa", _L.level_at(ZONE, 0.0) == 7 and _L.boss_level(ZONE) == 16)
	var player := {"boons": {"nawia": _cleared, "blessed": [ZONE]}}
	root.get_node("Game")._pending_load = {"seed": SEED, "zone": ZONE, "arrive": "shrine:old_mill", "player": player,
			"shrines": {"old_mill": [0, 0]}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 6:
		var low := 999
		var high := 0
		var boss := 0
		for id in _world._live_goblins:
			var goblin = _world._live_goblins[id]
			if not is_instance_valid(goblin):
				continue
			if _world._goblin_spawns[id].get("type", "") in _world.BOSS_TYPES:
				boss = maxi(boss, goblin.level)
			else:
				low = mini(low, goblin.level)
				high = maxi(high, goblin.level)
		check("potwory na poziomie mapy", low >= 51 and high <= 55, "%d-%d" % [low, high])
		check("bossowie na poziomie mapy", boss == 57, str(boss))
		var mods: Dictionary = load("res://scripts/goblin.gd").dungeon_mods
		check("premia do łupu i doświadczenia", is_equal_approx(mods.get("loot", 1.0), 1.06)
				and is_equal_approx(mods.get("xp", 1.0), 1.06))
		var boons = _world.player.boons
		check("przełącznik w zapisie", boons.get_save_data()["blessed"] == [ZONE])
		var shrine: Vector2 = _world._zone_shrines["old_mill"]
		check("kapliczka pozwala przełączyć", _world.blessing_shrine_near(shrine) == "old_mill"
				and _world.blessing_shrine_near(shrine + Vector2(200, 0)) == "")
		var window = _world.hud.blessing_window
		_world.player.global_position = shrine
		window.open("old_mill")
		check("okno błogosławieństwa", window.visible and window._toggle.text == "Wygaś" and window._info.text.contains("51-55"),
				window._info.text)
		check("obwódka na mapie świata", _world.hud.big_map._view._blessed(ZONE) and not _world.hud.big_map._view._blessed("swamp"))
		boons.set_blessing(ZONE, false)
		check("wygaszenie", boons.nawia_blessed.is_empty())
	if _frame == 8:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
