extends SceneTree
## Mapa Nawii (scripts/nawia_map.gd): układ z ziarna (90 węzłów, 6 obszarów, stopnie 8-17, ten sam dla tego samego
## ziarna), każdy węzeł osiągalny od pierwszego pierścienia, klimaty pasujące do krain, odsłanianie sąsiadów, punkty
## Watry, zapis postępu (Boons), stopnie i poziomy końcówki (Dungeons, Levels); potem loch z węzła na stopniu 12:
## poziom potworów, liczebność jak na stopniu 7, a pokonany strażnik oczyszcza węzeł; na koniec okno mapy w HUD.

var _world: Node
var _frame := 0
var _fails := 0
var _N
var _D
var _L
const NODE_TIER := 12


func _initialize() -> void:
	TranslationServer.set_locale("pl")
	root.get_node("Game").save_path = "user://test_savegame.json"
	_N = load("res://scripts/nawia_map.gd")
	_D = load("res://scripts/dungeons.gd")
	_L = load("res://scripts/levels.gd")
	_check_map()
	_check_levels()
	var config: Dictionary = _D.config("catacombs", NODE_TIER, [], 4242, [])
	config["nawia_node"] = 7
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _check_map() -> void:
	var nodes: Array[Dictionary] = _N.generate(12345)
	check("90 węzłów", nodes.size() == 90 and _N.node_count() == 90, str(nodes.size()))
	var areas := {}
	var tiers_ok := true
	var own := 0
	for node in nodes:
		areas[node["area"]] = int(areas.get(node["area"], 0)) + 1
		if int(node["tier"]) != 8 + int(node["ring"]) or int(node["tier"]) > 17:
			tiers_ok = false
		if (_N.AREA_CLIMATES[node["area"]] as Array).has(node["climate"]):
			own += 1
		if (node["pos"] as Vector2).length() > 1.0:
			tiers_ok = false
	check("6 obszarów po 15 węzłów", areas.size() == 6 and areas.values().all(func(n: int) -> bool: return n == 15), str(areas))
	check("stopnie 8-17 od środka, w kole", tiers_ok)
	check("klimaty pasujące do krainy przeważają", own > 55 and own < 90, str(own))
	var again: Array[Dictionary] = _N.generate(12345)
	var other: Array[Dictionary] = _N.generate(999)
	check("ten sam układ dla ziarna", str(again) == str(nodes))
	check("inny układ dla innego ziarna", str(other) != str(nodes))
	# osiągalność: od pierwszego pierścienia po drogach
	var seen := {}
	var queue: Array[int] = []
	for node in nodes:
		if int(node["ring"]) == 0:
			queue.append(node["id"])
			seen[node["id"]] = true
	while not queue.is_empty():
		var id: int = queue.pop_back()
		for next: int in nodes[id]["links"]:
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	check("każdy węzeł osiągalny", seen.size() == nodes.size(), "%d/%d" % [seen.size(), nodes.size()])
	var symmetric := true
	for node in nodes:
		for next: int in node["links"]:
			if not (nodes[next]["links"] as Array).has(node["id"]):
				symmetric = false
	check("drogi w obie strony", symmetric)
	var start: Dictionary = _N.revealed(nodes, [])
	check("na początku widać tylko pierwszy pierścień", start.size() == 6)
	var first: int = start.keys()[0]
	var after: Dictionary = _N.revealed(nodes, [first])
	check("oczyszczony węzeł odsłania sąsiadów", (nodes[first]["links"] as Array).all(func(n: int) -> bool: return after.has(n))
			and after.size() > start.size())
	check("zamknięty węzeł", not _N.is_open(nodes, [], 89))
	check("punkty Watry za węzły", _N.points([1, 2, 3]) == 3)
	var area: String = nodes[0]["area"]
	var all_ids := []
	for node in nodes:
		if node["area"] == area:
			all_ids.append(node["id"])
	check("oczyszczony obszar", _N.area_cleared(nodes, all_ids, area) and not _N.area_cleared(nodes, all_ids.slice(1), area))
	check("mapa od 40. poziomu", _N.unlocked(40) and not _N.unlocked(39))


## Zapis postępu (Boons) - dopiero po starcie gry (autoloady).
func _check_boons() -> void:
	var boons = load("res://scripts/boons.gd").new()
	check("nowy węzeł daje punkt, powtórzony nie", boons.clear_nawia_node(5) and not boons.clear_nawia_node(5) and boons.watra_points() == 1)
	var data: Dictionary = JSON.parse_string(JSON.stringify(boons.get_save_data()))
	var loaded = load("res://scripts/boons.gd").new()
	loaded.load_save_data(data)
	check("postęp mapy w zapisie", str(loaded.nawia_cleared) == "[5]", str(loaded.nawia_cleared))
	loaded.load_save_data({})
	check("stary zapis bez mapy", loaded.nawia_cleared.is_empty())
	boons.free()
	loaded.free()


func _check_levels() -> void:
	check("stopnie 8-17: poziomy 45-90", _D.TIER_LEVELS.size() == 17 and _D.tier_level(8) == 45 and _D.tier_level(17) == 90)
	check("zwykłe okno lochów do stopnia 7", _D.BASE_TIERS == 7 and _D.power_tier(12) == 7 and _D.power_tier(3) == 3)
	check("krainy bez zmian (do 41. poziomu)", is_equal_approx(_L.damage(40), 13.0 * (1.0 + 0.1 * 39)) and is_equal_approx(_L.xp(40), 11.0 * pow(40, 0.7)))
	check("końcówka: mocniejsze potwory", _L.damage(90) > 13.0 * (1.0 + 0.1 * 89) * 1.5)


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 6:
		_check_boons()
		var dungeon = _world._dungeon
		check("loch z węzła: poziom stopnia 12", dungeon != null and dungeon.level == _D.tier_level(NODE_TIER), str(dungeon.level if dungeon else -1))
		var hud = _world.hud
		check("okno mapy w HUD", hud.nawia_window != null)
		dungeon._on_boss_died()
		var boons = _world.player.boons
		check("pokonany strażnik oczyszcza węzeł", boons.nawia_cleared.has(7) and boons.watra_points() == 1)
		hud.nawia_window.open()
		check("okno mapy otwiera się z 90 węzłami", hud.nawia_window.visible and hud.nawia_window._nodes.size() == 90)
		var open_ids: Dictionary = _N.revealed(hud.nawia_window._nodes, boons.nawia_cleared)
		var pick: int = open_ids.keys()[0]
		hud.nawia_window.select(pick)
		hud.nawia_window._on_go()
		check("Wyrusz otwiera okno lochów w trybie węzła", hud.dungeon_window.visible and hud.dungeon_window._nawia_node == pick
				and hud.dungeon_window._tier == int(hud.nawia_window._nodes[pick]["tier"]) and not hud.dungeon_window._climate_row.visible)
		hud.dungeon_window.open()
		check("zwykłe okno lochów wraca do stopni 1-7", hud.dungeon_window._nawia_node == -1 and hud.dungeon_window._tier <= 7
				and hud.dungeon_window._climate_row.visible)
	if _frame == 8:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
