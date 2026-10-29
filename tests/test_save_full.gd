extends SceneTree
## Pełny zapis i odczyt gry: zmieniony stan (poziom, złoto, plecak z wylosowanym przedmiotem, zaklęta broń,
## magazyn, umiejętności, premie z osady i bestiariusz, zbudowane budowle, pokonany potwór, licznik zabitych)
## -> zapis -> JSON -> nowy świat z tego zapisu -> porównanie. Do tego starszy zapis bez nowych pól
## (premie, nowe budowle) - musi się wczytać bez błędów.

var _game: Node
var _world: Node
var _frame := 0
var _fails := 0
var _saved := {}
var _expect := {}
var _phase := 0


func _initialize() -> void:
	_game = root.get_node("Game")
	_game.save_path = "user://test_savegame.json"
	_start.call_deferred({"seed": 777, "zone": "forest", "player": {}})


func _start(data: Dictionary) -> void:
	_game._pending_load = data
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	_frame = 0


func _check(what: String, ok: bool, info := "") -> void:
	print(("OK   " if ok else "FAIL ") + what + (" " + info if info != "" else ""))
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 8:
		return false
	var p = _world.player
	var s = _world._settlement
	match _phase:
		0:
			var loot = load("res://scripts/loot.gd")
			p.stats.level = 12
			p.stats.gold = 4321
			var item: String = loot.generate(loot.base_for("plate", 12), "rare", 12)
			p.inventory.add_item(item, 1)
			var sword: String = loot.generate(loot.base_for("sword", 12), "magic", 12)
			p.equipment.equip_to("weapon", sword, 7)
			p.storage.add_item("goblin_heart", 33)
			p.boons.grant("stew")
			p.boons.grant("bless_might")
			p.boons.advance("goblin")
			for project in ["barracks", "chapel", "houses"]:
				s.set_project(project, "built")
			s.set_project("market", "building", 50.0)
			_world.hud.set_kills(77)
			_expect = {"item": item, "item_stats": load("res://scripts/items.gd").get_data(item)["stats"].duplicate(),
					"sword": sword}
			_saved = JSON.parse_string(JSON.stringify(_world.get_save_data()))
			_world.queue_free()
			_world = null
			_phase = 1
			_start.call_deferred(_saved)
		1:
			_check("poziom i złoto", p.stats.level == 12 and p.stats.gold == 4321, "%d %d" % [p.stats.level, p.stats.gold])
			_check("wylosowany przedmiot w plecaku", p.inventory.count_of(_expect["item"]) == 1)
			var items = load("res://scripts/items.gd")
			_check("statystyki przedmiotu po odczycie", items.get_data(_expect["item"]).get("stats", {}) == _expect["item_stats"])
			_check("zaklęta broń", p.equipment.items["weapon"].get("id", "") == _expect["sword"]
					and p.equipment.items["weapon"].get("enchant", 0) == 7)
			_check("magazyn", p.storage.count_of("goblin_heart") == 33)
			_check("premie z osady", p.boons.active.has("meal") and p.boons.active.has("blessing"))
			_check("bestiariusz", p.boons.rank("goblin") == 1)
			_check("budowle", s.project_state("chapel") == "built" and s.project_state("houses") == "built"
					and s.project_state("market") == "building", "%s %s" % [s.project_state("chapel"), s.project_state("market")])
			_check("licznik zabitych", _world.hud.kills == 77)
			# starszy zapis: bez premii z osady i bez nowych budowli
			var old: Dictionary = _saved.duplicate(true)
			(old["player"] as Dictionary).erase("boons")
			var projects: Dictionary = old["zones"]["forest"]["settlement"]["projects"]
			for key in ["chapel", "houses", "market"]:
				projects.erase(key)
			_world.queue_free()
			_world = null
			_phase = 2
			_start.call_deferred(old)
		2:
			_check("starszy zapis się wczytuje", p.stats.level == 12 and p.boons.active.is_empty()
					and s.project_state("barracks") == "built" and s.project_state("chapel") == "none")
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false
