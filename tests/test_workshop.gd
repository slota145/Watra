extends SceneTree
## Rzemiosło premii (ItemCraft, okno warsztatu u kowala): przerzut wartości (ten sam tier), przekucie, usunięcie,
## dodanie premii (do limitu rzadkości), ulepszenie rzadkości (także zwykłego przedmiotu ze sklepu), Runa Zmiany,
## Pieczęć (wybrana premia zostaje), koszty w trofeach krainy wg poziomu przedmiotu (legendy 3x), zakładany przedmiot,
## runy z Kryształu Watry, przycisk "Warsztat" u kowala.

var _world: Node
var _frame := 0
var _fails := 0


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


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 6:
		return false
	var p = _world.player
	var C = load("res://scripts/item_craft.gd")
	var Loot = load("res://scripts/loot.gd")
	var Items = load("res://scripts/items.gd")
	var hud = _world.find_child("HUD", true, false)
	# warsztat u kowala po warsztacie płatnerza
	p.quests.states["village_help"] = "done"
	_world._settlement.set_project("armory", "built")
	var smith = _world._settlement._smith
	hud.npc_dialog.open(smith)
	var labels: Array = hud.npc_dialog._buttons.get_children().map(func(b) -> String: return b.text)
	check("przycisk Warsztat u kowala", "Warsztat" in labels, str(labels))
	hud.npc_dialog.close()
	# materiały
	p.stats.add_gold(1000000)
	for item in ["goblin_heart", "kobold_fuse", "frog_tongue", "satyr_horn", "spider_silk", "bone_dust", "iron_ore"]:
		p.storage.add_item(item, 500)
	var sword: String = Loot.generate("sword_t2", "magic", 20)
	p.inventory.add_item(sword, 1)
	check("trofea wg poziomu przedmiotu", C.trophy_for(sword) == "satyr_horn" and C.trophy_for(Loot.generate("sword_t2", "magic", 3)) == "goblin_heart")
	var window = hud.workshop_window
	window.open()
	window._selected = {"inv": _index_of(p, sword)}
	var recipe: Dictionary = Items.get_data(sword)["recipe"]
	var stat: String = recipe["affixes"].keys()[0]
	var tier := int(recipe["tiers"][stat])
	window._stat = stat
	var hearts: int = p.count_owned("satyr_horn")
	var gold: int = p.stats.gold
	window._do("value")
	recipe = Items.get_data(sword)["recipe"]
	var span: Array = Loot.tier_range(stat, tier)
	check("przerzut wartości: ten sam tier, płaci", int(recipe["tiers"][stat]) == tier and float(recipe["affixes"][stat]) >= span[0] - 0.01
			and float(recipe["affixes"][stat]) <= span[1] + 0.01 and p.count_owned("satyr_horn") == hearts - 2 and p.stats.gold < gold)
	window._do("reforge")
	check("przekucie premii", Items.get_data(sword)["recipe"]["affixes"].has(stat))
	var count: int = Items.get_data(sword)["recipe"]["affixes"].size()
	window._do("remove")
	check("usunięcie premii", Items.get_data(sword)["recipe"]["affixes"].size() == count - 1 and not Items.get_data(sword)["recipe"]["affixes"].has(stat))
	while Items.get_data(sword)["recipe"]["affixes"].size() < 4:
		window._do("add")
	check("dodanie do limitu (magiczny: 4)", Items.get_data(sword)["recipe"]["affixes"].size() == 4 and C.check(sword, "add") != "")
	window._do("rarity")
	check("ulepszenie rzadkości", C.quality_of(sword) == "rare" and Items.get_data(sword)["rarity"] == "rare" and Items.get_data(sword)["recipe"]["affixes"].size() >= 4)
	# runy
	check("bez runy nie da się", not C.afford(p, sword, "chaos"))
	p.inventory.add_item("rune_chaos", 1)
	window._do("chaos")
	check("Runa Zmiany: nowe premie", p.count_owned("rune_chaos") == 0 and Items.get_data(sword)["recipe"]["affixes"].size() >= 4)
	var keep: String = Items.get_data(sword)["recipe"]["affixes"].keys()[0]
	var value = Items.get_data(sword)["recipe"]["affixes"][keep]
	p.inventory.add_item("rune_seal", 1)
	p.inventory.add_item("crystal_heart", 1)
	window._stat = keep
	window._do("lock")
	check("Pieczęć: wybrana premia zostaje", Items.get_data(sword)["recipe"]["affixes"].get(keep) == value and p.count_owned("rune_seal") == 0
			and p.count_owned("crystal_heart") == 0)
	# zwykły przedmiot ze sklepu
	p.inventory.add_item("leather_boots", 1)
	window._selected = {"inv": _index_of(p, "leather_boots")}
	window._do("rarity")
	var boots: String = p.inventory.slots[window._selected["inv"]]["id"]
	check("zwykły przedmiot -> magiczny", Loot.is_generated(boots) and C.quality_of(boots) == "magic" and Items.get_data(boots)["recipe"]["affixes"].size() >= 2)
	# legenda - drożej, ale działa
	var legend: String = Loot.legendary_at_level("legend_alpha_pelt", 20)
	check("legenda 3x drożej", C.cost(legend, "value")["gold"] == C.cost(Loot.generate("leather_armor", "rare", Items.item_level(legend)), "value")["gold"] * 3)
	p.inventory.add_item(legend, 1)
	window._selected = {"inv": _index_of(p, legend)}
	window._stat = Items.get_data(legend)["recipe"]["affixes"].keys()[0]
	var legend_count: int = Items.get_data(legend)["recipe"]["affixes"].size()
	window._do("remove")
	check("legenda: usunięcie premii", Items.get_data(legend)["recipe"]["affixes"].size() == legend_count - 1 and Items.get_data(legend).has("effect"))
	# założony przedmiot
	var worn: String = Loot.generate("leather_armor", "rare", 10)
	p.equipment.items["chest"] = {"id": worn, "enchant": 0}
	p.equipment.changed.emit()
	window._selected = {"equip": "chest"}
	window._do("add")
	check("założony przedmiot", p.equipment.get_item("chest") == worn)
	# runy z Kryształu Watry
	var runes := 0
	for i in 100:
		for entry: Array in load("res://scripts/watra_crystal.gd").reward(5, 1.0):
			if str(entry[0]).begins_with("rune_"):
				runes += 1
	check("runy z Kryształu Watry", runes > 10 and runes < 60, "%d" % runes)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false
