extends SceneTree
## Esencje legend: wyciąganie w Watrze (za żar, 40-80% siły legendy, legenda przepada), Ołtarz Welesa w lochu
## (za darmo, 60-100%, raz), esencja w gnieździe legendarnym drzewka (tylko z bronią drzewka, nie w zwykłym
## gnieździe), gniazdo esencji u kowala (Serce Kryształu i złoto, rzadki przedmiot / legenda), esencja tylko
## tego samego rodzaju, sumowanie efektów, wyjęcie za złoto albo zniszczenie, zapis, Serca z Kryształu Watry.

var _world: Node
var _frame := 0
var _fails := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	var config: Dictionary = load("res://scripts/dungeons.gd").config("catacombs", 3, [], 777)
	config["altar"] = true
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
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
	var Ess = load("res://scripts/essences.gd")
	var Items = load("res://scripts/items.gd")
	var Loot = load("res://scripts/loot.gd")
	var Tree = load("res://scripts/skill_tree.gd")
	var hud = _world.find_child("HUD", true, false)
	var window = hud.essence_window
	# ---- Watra: legenda -> esencja za żar
	var pelt: String = Loot.legendary_at_level("legend_alpha_pelt", 30)
	var base: float = Items.effect_chance(pelt, 0)
	p.inventory.add_item(pelt, 1)
	var index := _index_of(p, pelt)
	p.boons.ember = 5000
	var cost: int = Ess.ember_cost(pelt, 0)
	window.open("watra")
	window._selected = {"inv": index}
	window._refresh()
	window._extract()
	var essence: String = p.inventory.slots[index].get("id", "")
	var recipe: Dictionary = Items.get_data(essence).get("essence", {})
	check("esencja w miejscu legendy", Ess.is_essence(essence) and p.inventory.count_of(pelt) == 0 and not Items.generated.has(pelt))
	check("żar wydany", p.boons.ember_spent == cost, "%d / %d" % [p.boons.ember_spent, cost])
	check("siła 40-80%", recipe.get("value", 0.0) >= base * 0.4 - 0.001 and recipe.get("value", 0.0) <= base * 0.8 + 0.001
			and recipe.get("group", "") == "armor" and recipe.get("kind", "") == "pack_call", str(recipe))
	check("opis esencji", Items.describe(essence).contains("Efekt") and Items.get_data(essence)["name"].contains("Szarokła"))
	var weak := 1.0
	var strong := 0.0
	for i in 40:
		var r: Dictionary = Items.get_data(Ess.extract(pelt if Items.generated.has(pelt) else Loot.legendary_at_level("legend_alpha_pelt", 30), 0, true))["essence"]
		weak = minf(weak, r["power"])
		strong = maxf(strong, r["power"])
	check("ołtarz: 60-100%", weak >= 0.6 and strong <= 1.0 and strong > 0.85, "%.2f-%.2f" % [weak, strong])
	# ---- Ołtarz Welesa w lochu
	var dungeon = _world._dungeon
	check("ołtarz w ukrytej komnacie", dungeon.altar != null and dungeon.altar_room != Rect2i() and not dungeon.rooms.has(dungeon.altar_room))
	var area := Rect2(Vector2(dungeon.altar_room.position) * dungeon.CELL, Vector2(dungeon.altar_room.size) * dungeon.CELL)
	var inside: Array = _world.get_tree().get_nodes_in_group("enemies").filter(func(e) -> bool: return area.has_point(e.global_position))
	check("bez potworów przy ołtarzu", inside.is_empty(), "%d" % inside.size())
	var bow: String = Loot.legendary_at_level("legend_swarog_bow", 30)
	p.inventory.add_item(bow, 1)
	hud.npc_dialog.open(dungeon.altar)
	check("ołtarz otwiera okno", window.visible and window.mode == "altar")
	window._selected = {"inv": _index_of(p, bow)}
	var bow_index := _index_of(p, bow)
	window._extract()
	var bow_essence: String = p.inventory.slots[bow_index].get("id", "")
	check("ołtarz: esencja za darmo", Ess.is_essence(bow_essence) and p.boons.ember_spent == cost
			and Items.get_data(bow_essence)["essence"]["power"] >= 0.6)
	check("ołtarz gaśnie", not dungeon.altar.is_in_group("interactables") and dungeon.altar.services.is_empty())
	# ---- gniazdo legendarne drzewka
	var book = p.skills
	book.character_level = 60
	for step in Tree.path_to("melee", "socket_legend"):
		book.take("melee", step)
	for step in Tree.path_to("melee", "socket_1"):
		book.take("melee", step)
	check("esencja nie w zwykłym gnieździe", book.socket_from(p.inventory, "melee", "socket_1", _index_of(p, essence)) != "")
	var before: float = p.equipment.effect_power("pack_call")
	check("bez esencji brak efektu", before == 0.0)
	check("esencja w gnieździe legendarnym", book.socket_from(p.inventory, "melee", "socket_legend", _index_of(p, essence)) == "")
	check("efekt z drzewka", is_equal_approx(p.equipment.effect_power("pack_call"), recipe["value"]) and p.stats.weapon_type() == "melee")
	check("tylko z bronią drzewka", book.essence_in("bow").is_empty())
	check("kamień nie wypiera esencji", book.socket_from(p.inventory, "melee", "socket_legend", 0) != "")
	# ---- kowal: gniazdo esencji w rzadkim przedmiocie
	var armor: String = Loot.generate("leather_armor", "rare", 20)
	p.inventory.add_item(armor, 1)
	p.inventory.add_item("crystal_heart", 2)
	p.stats.add_gold(100000)
	window.open("smith")
	window._selected = {"inv": _index_of(p, armor)}
	window._refresh()
	window._add_socket(Ess.socket_hearts(armor), Ess.socket_gold(armor))
	check("gniazdo esencji u kowala", Ess.has_socket(armor) and p.inventory.count_of("crystal_heart") == 1)
	var second: String = Ess.extract(Loot.legendary_at_level("legend_alpha_pelt", 30))
	check("broń nie pasuje do zbroi", not Ess.fits(bow_essence, armor) and Ess.fits(second, armor))
	p.inventory.add_item(second, 1)
	window._selected = {"inv": _index_of(p, armor)}
	window._insert(_index_of(p, second))
	check("esencja osadzona", not (Ess.socket_of(armor) as Dictionary).is_empty() and Items.describe(armor).contains("Esencja"))
	# założony przedmiot z esencją: dwie esencje jednego efektu łączą się jak losowania
	p.equipment.items["chest"] = {"id": armor, "enchant": 0}
	p.equipment.changed.emit()
	var a: float = recipe["value"]
	var b: float = Items.get_data(armor)["essence_socket"]["value"]
	check("efekty się sumują", is_equal_approx(p.equipment.effect_power("pack_call"), 1.0 - (1.0 - a) * (1.0 - b)))
	check("w sztukach: najsilniejszy + połowa", is_equal_approx(Ess.combine("seeker_split", [[2.0, false], [1.0, false]]), 2.5)
			and is_equal_approx(Ess.combine("endless_storm", [[8.0, true], [12.0, true]]), 8.0))
	# zapis przedmiotu z esencją
	var saved: Dictionary = JSON.parse_string(JSON.stringify(Loot.export_used([armor, bow_essence])))
	Items.generated.erase(armor)
	Items.generated.erase(bow_essence)
	Loot.import(saved)
	check("zapis esencji", Ess.is_essence(bow_essence) and is_equal_approx(Items.get_data(armor)["essence_socket"]["value"], b))
	var tree_saved: Dictionary = JSON.parse_string(JSON.stringify(book.get_save_data()))
	var copy = load("res://scripts/skill_book.gd").new()
	copy.load_save_data(tree_saved)
	check("zapis esencji w drzewku", is_equal_approx(copy.essence_in("melee").get("value", 0.0), a))
	copy.free()
	# wyjęcie u kowala za złoto i zniszczenie
	p.equipment.items["chest"] = {}
	p.equipment.changed.emit()
	window._selected = {"inv": _index_of(p, armor)}
	var gold: int = p.stats.gold
	window._remove(true, Ess.save_gold(p.stats.level))
	check("wyjęcie za złoto", (Ess.socket_of(armor) as Dictionary).is_empty() and p.stats.gold < gold and _count_essences(p, Ess) >= 2)
	var gold_before: int = p.stats.gold
	check("wyjęcie z drzewka za złoto", book.unsocket_to(p.inventory, "melee", "socket_legend", p.stats) == "" and p.stats.gold < gold_before
			and book.essence_in("melee").is_empty())
	# ---- Serce Kryształu z Kryształu Watry od 3. stopnia
	var hearts := 0
	var low := 0
	for i in 100:
		for entry: Array in load("res://scripts/watra_crystal.gd").reward(5, 1.0):
			if entry[0] == "crystal_heart":
				hearts += 1
		for entry: Array in load("res://scripts/watra_crystal.gd").reward(2, 1.0):
			if entry[0] == "crystal_heart":
				low += 1
	check("Serce Kryształu z kryształu", hearts > 30 and hearts < 75 and low == 0, "%d / %d" % [hearts, low])
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _count_essences(p, Ess) -> int:
	return p.inventory.slots.filter(func(s: Dictionary) -> bool: return not s.is_empty() and Ess.is_essence(s["id"])).size()


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1
