extends SceneTree
## Chata jubilera w Ostoi: budowa dopiero po zadaniu "Pierwszy klejnot", koszt (drewno, kamień, ruda), po zbudowaniu
## Dobromir mieszka w Ostoi (z przeszlifowaniem kamieni), a w Orlej Przełęczy go już nie ma; przeszlifowanie
## zachowuje rodzaj, szlif i liczbę premii; u jubilera bez chaty przeszlifowania nie ma.

var _world: Node
var _frame := 0
var _fails := 0
var _phase := 1
var _saved := {}


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_load({"seed": 12345, "zone": "forest", "player": {}})


func _load(save: Dictionary) -> void:
	root.get_node("Game")._pending_load = save
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)
	current_scene = _world
	_frame = 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _world == null or not _world.is_inside_tree():
		return false
	_frame += 1
	if _frame != 5:
		return false
	if _phase == 1:
		_ostoja()
		_phase = 2
		_saved = JSON.parse_string(JSON.stringify(_world.get_save_data()))
		_saved["zone"] = "mountains"
		_world.queue_free()
		_load(_saved)
		return false
	var jeweler = null
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if npc.display_name == "Jubiler Dobromir":
			jeweler = npc
	check("Orla Przełęcz bez jubilera", jeweler == null and _world.village_built("jeweler"))
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _ostoja() -> void:
	var p = _world.player
	var s = _world._settlement
	var Gems = load("res://scripts/gems.gd")
	var Items = load("res://scripts/items.gd")
	p.quests.states["village_help"] = "done"
	for id in ["wood", "stone", "iron_ore"]:
		p.inventory.add_item(id, 200)
	check("przed zadaniem zablokowana", s.project_locked("jeweler", p) != "" and not s.start_project("jeweler", p))
	p.quests.states["jeweler_gem"] = "done"
	var wood: int = p.count_owned("wood")
	check("budowa po zadaniu", s.project_locked("jeweler", p) == "" and s.start_project("jeweler", p)
			and p.count_owned("wood") == wood - 120 and p.count_owned("iron_ore") == 170)
	s._finish_construction("jeweler")
	check("chata zbudowana", s.project_state("jeweler") == "built" and _world.village_built("jeweler"))
	var jeweler = null
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if npc.display_name == "Jubiler Dobromir":
			jeweler = npc
	check("Dobromir w Ostoi", jeweler != null and "jeweler" in jeweler.services and "reshape" in jeweler.services)
	# przeszlifowanie
	var window = _world.find_child("HUD", true, false).jeweler_window
	window.open()
	check("bez chaty bez przeszlifowania", not window.reshape_enabled and not window._reshape_box.visible)
	var gem: String = Gems.roll("ruby", 2, true)
	while Items.get_data(gem)["stats"].size() != 3:
		gem = Gems.roll("ruby", 2, true)
	p.inventory.add_item(gem, 1)
	p.stats.add_gold(5000)
	window.open(jeweler)
	check("przeszlifowanie u Dobromira w Ostoi", window.reshape_enabled and window._reshape_box.visible and window._reshape.get_child_count() > 0)
	var index := -1
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == gem:
			index = i
	var gold: int = p.stats.gold
	window._reshape_gem(index, Gems.RESHAPE_GOLD[2])
	var result: String = p.inventory.slots[index]["id"]
	var data: Dictionary = Items.get_data(result)
	check("nowy kamień: ten sam rodzaj, szlif, 3 premie", result != gem and data["gem"]["kind"] == "ruby" and data["gem"]["cut"] == 2
			and data["stats"].size() == 3 and not Items.generated.has(gem))
	check("przeszlifowanie za złoto", p.stats.gold == gold - Gems.RESHAPE_GOLD[2])
