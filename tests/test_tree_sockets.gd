extends SceneTree
## Gniazda w drzewkach broni: 3 gniazda w każdym drzewku (2 zwykłe + legendarne przy węźle kluczowym), osadzanie
## kamienia z plecaka (w oknie umiejętności i przeciąganiem na drzewko), premie +50% tylko z bronią drzewka, zamiana
## i wyjmowanie, kamień promienia wzmacnia wybrane węzły pasywne w zasięgu, zapis, zapomnienie drzewka u mędrca
## zwraca kamienie, kamienie promienia z Kryształu Watry i nie u jubilera.

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


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 5:
		return false
	var p = _world.player
	var Gems = load("res://scripts/gems.gd")
	var Items = load("res://scripts/items.gd")
	var Tree = load("res://scripts/skill_tree.gd")
	var book = p.skills
	for weapon in ["melee", "bow", "spell"]:
		var sockets: Array = Tree.nodes(weapon).keys().filter(func(id: String) -> bool: return Tree.nodes(weapon)[id]["kind"] == "socket")
		var legend: Array = sockets.filter(func(id: String) -> bool: return Tree.nodes(weapon)[id].get("legendary", false))
		var by_keystone: bool = legend.size() == 1 and Tree.nodes(weapon)[legend[0]]["links"].any(
				func(link: String) -> bool: return Tree.nodes(weapon)[link]["kind"] == "keystone")
		check("3 gniazda w drzewku: " + weapon, sockets.size() == 3 and by_keystone, str(sockets))
	book.character_level = 60
	check("broń: miecz", p.stats.weapon_type() == "melee", p.stats.weapon_type())
	for step in Tree.path_to("melee", "socket_1"):
		book.take("melee", step)
	check("gniazdo wybrane za punkty", book.can_socket("melee", "socket_1") and not book.can_socket("melee", "socket_2"))
	# osadzenie z plecaka (okno umiejętności)
	var gem := _gem_with(p, Gems, "health")
	var value: float = Items.get_data(gem)["stats"]["health"]
	var health_before: int = p.stats.max_health()
	var window = _world.find_child("HUD", true, false).skill_window
	window.toggle()
	window._trees["melee"]["view"].selected_id = "socket_1"
	window._refresh()
	check("kamienie z plecaka w szczegółach", window._trees["melee"]["gems"].get_child_count() >= 1 and not window._trees["melee"]["unsocket"].visible)
	window._socket("melee", _index_of(p, gem))
	check("kamień w gnieździe drzewka", not book.gem_in("melee", "socket_1").is_empty() and p.inventory.count_of(gem) == 0
			and not Items.generated.has(gem))
	check("premia +50%", is_equal_approx(book.tree_bonus("melee", "health"), value * 1.5) and p.stats.max_health() > health_before,
			"%s vs %s" % [book.tree_bonus("melee", "health"), value * 1.5])
	check("tylko z bronią drzewka", book.tree_bonus("bow", "health") == 0.0)
	check("wyjmowanie widoczne", window._trees["melee"]["unsocket"].visible)
	# zamiana przeciąganiem z plecaka na drzewko
	var view = window._trees["melee"]["view"]
	var second: String = Gems.roll("sapphire", 1)
	p.inventory.add_item(second, 1)
	var drag := {"inventory": p.inventory, "index": _index_of(p, second)}
	var at: Vector2 = view.node_position("socket_1")
	check("przeciąganie na gniazdo", view._can_drop_data(at, drag) and not view._can_drop_data(view.node_position("socket_2"), drag))
	view._drop_data(at, drag)
	check("zamiana kamieni", book.gem_in("melee", "socket_1")["kind"] == "sapphire" and _count_kind(p, Items, "ruby") == 1
			and is_equal_approx(book.tree_bonus("melee", "health"), 0.0))
	window._unsocket("melee")
	check("wyjęcie kamienia", book.gem_in("melee", "socket_1").is_empty() and _count_kind(p, Items, "sapphire") == 1)
	# kamień promienia: wzmacnia wybrane węzły pasywne w zasięgu
	var tree: Dictionary = Tree.nodes("melee")
	var near := ""
	for id: String in tree:
		if tree[id]["kind"] == "passive" and book.has_node_id("melee", id) and tree[id]["pos"].distance_to(tree["socket_1"]["pos"]) <= book.RADIUS_RANGE:
			near = id
	if near == "":
		for id: String in tree:
			if near == "" and tree[id]["kind"] == "passive" and tree[id]["pos"].distance_to(tree["socket_1"]["pos"]) <= book.RADIUS_RANGE:
				for step in Tree.path_to("melee", id):
					book.take("melee", step)
				near = id
	var stat: String = tree[near]["stats"].keys()[0]
	var plain: float = book.tree_bonus("melee", stat)
	var radius: String = Gems.roll_radius(5)
	var power: float = Items.get_data(radius)["recipe"]["affixes"]["radius_power"]
	check("kamień promienia nie u jubilera", Gems.is_radius(radius) and Items.describe(radius).contains("promieniu"))
	p.inventory.add_item(radius, 1)
	window._socket("melee", _index_of(p, radius))
	var boosted: float = book.tree_bonus("melee", stat)
	check("promień wzmacnia węzeł " + near, boosted > plain and book.radius_factor("melee", near) > 1.0
			and is_equal_approx(book.radius_factor("melee", near), 1.0 + power), "%s -> %s" % [plain, boosted])
	var far := ""
	for id: String in tree:
		if tree[id]["kind"] == "passive" and tree[id]["pos"].distance_to(tree["socket_1"]["pos"]) > book.RADIUS_RANGE:
			far = id
	check("daleki węzeł bez wzmocnienia", book.radius_factor("melee", far) == 1.0)
	check("opis węzła w promieniu", view.describe(near).contains("promienia"))
	# zapis i wczytanie
	var saved: Dictionary = JSON.parse_string(JSON.stringify(book.get_save_data()))
	var copy = load("res://scripts/skill_book.gd").new()
	copy.load_save_data(saved)
	check("zapis kamieni drzewka", copy.gem_in("melee", "socket_1").get("kind", "") == "radius"
			and is_equal_approx(copy.tree_bonus("melee", stat), boosted))
	copy.free()
	# zapomnienie drzewka u mędrca - kamienie wracają
	var npc_script := GDScript.new()
	npc_script.source_code = "extends Node\nfunc say(_line: Variant) -> void:\n\tpass\n"
	npc_script.reload()
	var npc := Node.new()
	npc.set_script(npc_script)
	p.stats.add_gold(100000)
	var rows: Array = load("res://scripts/village_services.gd")._respec(p, npc)["rows"]
	for row: Dictionary in rows:
		if row["name"].contains(load("res://scripts/skills.gd").WEAPON_NAMES["melee"]):
			row["action"].call()
	var radius_back: bool = p.inventory.slots.any(func(s: Dictionary) -> bool: return not s.is_empty() and Gems.is_radius(s["id"]))
	check("zapomnienie zwraca kamienie", book.gem_in("melee", "socket_1").is_empty() and radius_back and book.tree_bonus("melee", stat) == 0.0)
	npc.free()
	# kamienie promienia w nagrodzie Kryształu Watry
	var found := 0
	for i in 100:
		for entry: Array in load("res://scripts/watra_crystal.gd").reward(7, 1.0):
			if Gems.is_radius(entry[0]):
				found += 1
	check("kamień promienia z kryształu", found > 25 and found < 75, "%d/100" % found)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _count_kind(p, Items, kind: String) -> int:
	return p.inventory.slots.filter(func(s: Dictionary) -> bool:
		return not s.is_empty() and Items.get_data(s["id"]).get("gem", {}).get("kind", "") == kind).size()


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1


func _gem_with(p, Gems, stat: String) -> String:
	var Items = load("res://scripts/items.gd")
	for i in 50:
		var id: String = Gems.roll("ruby", 2)
		if Items.get_data(id)["stats"].has(stat):
			p.inventory.add_item(id, 1)
			return id
	return ""
