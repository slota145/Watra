extends SceneTree
## Kamienie wsparcia i gniazda umiejętności (Supports, SkillBook.supports): dane (każdy kamień ma ikonę i pasuje do
## jakiejś umiejętności), dorabianie gniazd krzesiwami (1-4 Krzesiwem Nawii, 5. Wielkim), osadzanie tylko pasujących
## kamieni (tag umiejętności, bez powtórek), premie z tagami umiejętności (znacznik Skills.tags), koszt many, wyjmowanie,
## doświadczenie i awans kamieni w gniazdach, łączenie 3 kamieni, zapis i wczytanie, okno K i przeciąganie na drzewko.

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
	if _frame != 5:
		return false
	var p = _world.player
	var book = p.skills
	var Supports = load("res://scripts/supports.gd")
	var Skills = load("res://scripts/skills.gd")
	var SkillTree = load("res://scripts/skill_tree.gd")
	var Items = load("res://scripts/items.gd")
	var Loot = load("res://scripts/loot.gd")
	# dane
	var all_fit := true
	for kind: String in Supports.ORDER:
		var any := false
		for skill: String in Skills.TAGS:
			if Supports.fits(kind, skill):
				any = true
		all_fit = all_fit and any and Supports.icon(kind) != null and Supports.DATA.has(kind)
	check("każdy kamień ma ikonę i pasuje do umiejętności", all_fit and Supports.ORDER.size() == Supports.DATA.size())
	check("bez gniazd w regeneracji i zwykłym ataku", not Supports.has_sockets("") and Supports.has_sockets("crescent")
			and Skills.DATA.keys().filter(func(id: String) -> bool: return Skills.get_data(id)["type"] in ["health_regen", "mana_regen"])
			.all(func(id: String) -> bool: return not Supports.has_sockets(id)))
	check("wartości rosną z poziomem", Supports.value("area", "area", 1) < Supports.value("area", "area", 20)
			and is_equal_approx(Supports.value("area", "area", 20), 0.45))
	check("znacznik umiejętności w tagach", Skills.skill_of(Skills.tags("crescent")) == "crescent" and Skills.skill_of(["attack"]) == ""
			and Skills.tags_text("crescent").find("@") < 0)
	# odblokowanie Półksiężyca (obszar, cios, fizyczne)
	book.character_level = 60
	for step in SkillTree.path_to("melee", SkillTree.node_for_skill("crescent")):
		book.take("melee", step)
	check("Półksiężyc odblokowany", book.level_of("crescent") > 0)
	# gniazda za krzesiwa
	check("bez krzesiwa nie ma gniazda", book.add_socket("crescent", p.inventory) != "" and book.sockets_of("crescent") == 0)
	p.inventory.add_item(Supports.FLINT, 15)
	for i in 4:
		book.add_socket("crescent", p.inventory)
	check("4 gniazda za 1+2+4+8 krzesiw", book.sockets_of("crescent") == 4 and p.inventory.count_of(Supports.FLINT) == 0)
	check("5. gniazdo tylko Wielkim Krzesiwem", book.add_socket("crescent", p.inventory) != "")
	p.inventory.add_item(Supports.GREAT_FLINT, 1)
	check("5. gniazdo", book.add_socket("crescent", p.inventory) == "" and book.sockets_of("crescent") == 5
			and book.add_socket("crescent", p.inventory) != "")
	# osadzanie
	var area_before: float = p.stats.area_multiplier(Skills.tags("crescent"))
	var damage_before: float = p.stats.kind_multiplier(Skills.tags("crescent"))
	var area_gem: String = Supports.roll("area", 20)
	p.inventory.add_item(area_gem, 1)
	check("Rozległość w Półksiężycu", book.support_socket_from(p.inventory, "crescent", _index_of(p, area_gem)) == ""
			and p.inventory.count_of(area_gem) == 0 and not Items.generated.has(area_gem))
	check("premia obszaru tylko tej umiejętności", is_equal_approx(p.stats.area_multiplier(Skills.tags("crescent")), area_before + 0.45)
			and is_equal_approx(p.stats.area_multiplier(Skills.tags("whirlwind")), p.stats.area_multiplier()))
	var split: String = Supports.roll("split", 1)
	p.inventory.add_item(split, 1)
	check("Rozszczep nie pasuje do ciosu", book.support_socket_from(p.inventory, "crescent", _index_of(p, split)) != "")
	var second_area: String = Supports.roll("area", 1)
	p.inventory.add_item(second_area, 1)
	check("ten sam kamień raz", book.support_socket_from(p.inventory, "crescent", _index_of(p, second_area)) != "")
	var brutal: String = Supports.roll("brutal", 1)
	p.inventory.add_item(brutal, 1)
	book.support_socket_from(p.inventory, "crescent", _index_of(p, brutal))
	check("Okrutny Cios: więcej obrażeń, wolniej", is_equal_approx(p.stats.kind_multiplier(Skills.tags("crescent")), damage_before * 1.25)
			and p.stats.skill_speed(Skills.tags("crescent")) < p.stats.skill_speed(Skills.basic_tags("melee")))
	var fire: String = Supports.roll("fire_edge", 1)
	p.inventory.add_item(fire, 1)
	book.support_socket_from(p.inventory, "crescent", _index_of(p, fire))
	check("Żarowe Ostrze: dodany ogień i szansa na podpalenie", p.stats.support_elements(Skills.tags("crescent")) == ["fire"]
			and p.stats.ailment_chance("ignite", Skills.tags("crescent")) > p.stats.ailment_chance("ignite"))
	check("koszt many rośnie", is_equal_approx(p.skill_mana("crescent", 10.0), 10.0 * 1.2 * 1.3 * 1.2))
	# doświadczenie
	var level_before: int = int(book.support_gems("crescent")[1]["level"])
	p.stats.add_xp(Supports.xp_to_next(1) + 5)
	check("kamień awansuje z doświadczeniem postaci", int(book.support_gems("crescent")[1]["level"]) == level_before + 1
			and int(book.support_gems("crescent")[0]["level"]) == 20)
	# wyjmowanie
	check("wyjmowanie", book.support_unsocket_to(p.inventory, "crescent", 2) == "" and book.support_gems("crescent")[2].is_empty()
			and Supports.slots_of(p.inventory, "fire_edge").size() == 1)
	# łączenie 3 kamieni
	for i in 2:
		p.inventory.add_item(Supports.roll("fire_edge", 3), 1)
	check("łączenie 3 w 1 (+2 poziomy)", Supports.combine(p.inventory, "fire_edge") == ""
			and Supports.slots_of(p.inventory, "fire_edge").size() == 1
			and int(Items.get_data(p.inventory.slots[Supports.slots_of(p.inventory, "fire_edge")[0]]["id"])["support"]["level"]) == 5)
	# zapis
	var saved: Dictionary = JSON.parse_string(JSON.stringify(book.get_save_data()))
	var copy = load("res://scripts/skill_book.gd").new()
	copy.load_save_data(saved)
	check("zapis gniazd i kamieni", copy.sockets_of("crescent") == 5 and copy.support_gems("crescent")[0]["support"] == "area"
			and int(copy.support_gems("crescent")[0]["level"]) == 20 and copy.support_gems("crescent")[2].is_empty())
	copy.free()
	var item_save: Dictionary = JSON.parse_string(JSON.stringify(Loot.export_used([split])))
	Items.generated.erase(split)
	Loot.import(item_save)
	check("kamień w plecaku po wczytaniu", Supports.is_support(split) and Items.describe(split).contains(Supports.name_of("split")))
	# okno K
	var window = _world.find_child("HUD", true, false).skill_window
	window.toggle()
	var view = window._trees["melee"]["view"]
	view.selected_id = SkillTree.node_for_skill("crescent")
	window._refresh()
	check("gniazda w oknie K", window._trees["melee"]["supports"].visible and window._trees["melee"]["socket_row"].get_child_count() == 5)
	var herald: String = Supports.roll("herald", 1)
	p.inventory.add_item(herald, 1)
	var fury: String = Supports.roll("fury", 1)
	p.inventory.add_item(fury, 1)
	var at: Vector2 = view.node_position(SkillTree.node_for_skill("crescent"))
	check("przeciąganie: tylko pasujący kamień", view._can_drop_data(at, {"inventory": p.inventory, "index": _index_of(p, fury)})
			and not view._can_drop_data(at, {"inventory": p.inventory, "index": _index_of(p, herald)}))
	view._drop_data(at, {"inventory": p.inventory, "index": _index_of(p, fury)})
	check("Furia osadzona przeciąganiem", book.support_gems("crescent").any(func(gem: Dictionary) -> bool: return gem.get("support", "") == "fury"))
	window._support_unsocket("melee", 0)
	check("wyjęcie z okna K", book.support_gems("crescent")[0].is_empty())
	print("WYNIK: %s" % ("OK" if _fails == 0 else "FAIL (%d)" % _fails))
	quit(1 if _fails > 0 else 0)
	return true
