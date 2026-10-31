extends SceneTree
## Torby z łupu (Bags): 6 rodzajów o stałej, rosnącej pojemności, rodzaj wg poziomu potwora, łup ze zwykłych potworów
## (rzadko), bossów (często, czasem Legendarny tobół), skarbca i najlepszej skrzyni wydarzenia, zakładanie i zdejmowanie,
## szycie w oknie Rzemiosła (zakładka Torby), sklep bez dawnych toreb, dawna Sakwa dalej działa.

var _world: Node
var _frame := 0
var _fails := 0
var B = null
var I = null


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
	if _frame == 3:
		B = load("res://scripts/bags.gd")
		I = load("res://scripts/items.gd")
	if _frame == 10:
		_finish()
	if _frame != 6:
		return false
	var p = _world.player
	# rodzaje
	var sizes: Array = B.ORDER.map(func(id: String) -> int: return int(I.get_data(id).get("bag", 0)))
	check("6 rodzajów, rosnąca pojemność", sizes == [5, 8, 12, 18, 24, 35], str(sizes))
	check("wszystkie mają ikonę i nazwę", B.ORDER.all(func(id: String) -> bool: return I.get_data(id).get("icon") != null and I.is_bag(id)))
	check("rodzaj wg poziomu", B.ORDER.slice(0, 2).has(B.for_level(10)) and B.for_level(1) == "bag_purse"
			and B.for_level(40) in ["bag_hunter", "bag_expedition"])
	# łup
	var monster := 0
	var boss := 0
	var legend := 0
	for i in 4000:
		if B.roll_drop(20) != "":
			monster += 1
		var drop: String = B.roll_drop(35, true)
		if drop != "":
			boss += 1
		if drop == B.LEGENDARY:
			legend += 1
	check("zwykłe potwory - rzadko, bossowie - często", monster > 0 and monster < 60 and boss > 400 and legend > 20,
			"%d / %d / %d" % [monster, boss, legend])
	var vault := 0
	for i in 400:
		if B.roll_vault(30) != "":
			vault += 1
	check("skarbiec lochu", vault > 80, str(vault))
	var chest := 0
	for i in 400:
		for drop: Array in load("res://scripts/event_site.gd").chest_loot(1, 30):
			if I.is_bag(drop[0]):
				chest += 1
	check("skrzynia wydarzenia (1. miejsce)", chest > 30, str(chest))
	# potwór wysypuje torbę (boss przez _drop_bag)
	var bosses: Array = _world.get_tree().get_nodes_in_group("bosses")
	if not bosses.is_empty():
		for i in 120:
			bosses[0]._drop_bag()
	# zakładanie
	for i in p.inventory.slots.size():
		p.inventory.slots[i] = {}
	var size: int = p.inventory.slots.size()
	p.inventory.add_item("bag_hunter", 1)
	var index := -1
	for i in p.inventory.slots.size():
		if p.inventory.slots[i].get("id", "") == "bag_hunter":
			index = i
	p.equip_bag(index)
	check("założona torba +18", p.inventory.slots.size() == size + 18 and p.bags.has("bag_hunter"))
	p.unequip_bag(p.bags.find("bag_hunter"))
	check("zdjęta torba", p.inventory.slots.size() == size and p.inventory.count_of("bag_hunter") == 1)
	# dawna Sakwa dalej działa
	p.inventory.add_item("pouch", 1)
	for i in p.inventory.slots.size():
		if p.inventory.slots[i].get("id", "") == "pouch":
			p.equip_bag(i)
	check("dawna Sakwa działa", p.inventory.slots.size() == size + 10)
	p.unequip_bag(p.bags.find("pouch"))
	# szycie
	var recipe: Dictionary = {}
	for r: Dictionary in load("res://scripts/crafting.gd").RECIPES:
		if r["result"] == "bag_satchel":
			recipe = r
	for id: String in recipe["ingredients"]:
		p.inventory.add_item(id, int(recipe["ingredients"][id]))
	check("szycie sakwy", load("res://scripts/crafting.gd").craft(recipe, p.inventory) and p.inventory.count_of("bag_satchel") == 1)
	var bag_recipes: Array = load("res://scripts/crafting.gd").RECIPES.filter(func(r: Dictionary) -> bool: return r.get("group", "") == "bags")
	check("receptury wszystkich toreb", bag_recipes.size() == 6)
	var window = _world.hud.crafting_window
	window.show_group("bags")
	var shown := 0
	for index_row: int in window._rows:
		if window._rows[index_row]["row"].visible:
			shown += 1
	check("zakładka Torby", shown == 6)
	window.show_group("summon")
	# sklep
	var sells: Array = []
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if "shop_sells" in npc:
			sells.append_array(npc.shop_sells)
	check("sklep bez dawnych toreb", not sells.has("pouch") and not sells.has("backpack") and not sells.is_empty())
	return false


func _finish() -> void:
	var dropped := 0
	for pickup in _world.get_tree().get_nodes_in_group("pickups"):
		if I.is_bag(pickup.item_id):
			dropped += 1
	check("boss wysypuje torby", dropped > 0, str(dropped))
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
