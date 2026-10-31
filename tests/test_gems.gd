extends SceneTree
## Kamienie szlachetne i gniazda: jubiler w Orlej Przełęczy, zadanie "Pierwszy klejnot" (surowy klejnot z rudy),
## odblokowanie (pierwszy kamień, darmowe gniazdo), kamienie z 2 premiami (własna pula + wspólna), szlify,
## gniazdo w przedmiocie, osadzanie i wyjmowanie kamienia (premie w statystykach i opisie), łączenie 3 -> 1,
## gniazda w łupie dopiero po zadaniu, zapis przedmiotu z kamieniem, premia "obszar umiejętności".

var _world: Node
var _frame := 0
var _fails := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "mountains", "player": {}}
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
	var Loot = load("res://scripts/loot.gd")
	var Items = load("res://scripts/items.gd")
	var jeweler = null
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if npc.display_name == "Jubiler Dobromir":
			jeweler = npc
	check("jubiler w Orlej Przełęczy", jeweler != null and jeweler.quest_id == "jeweler_gem" and "jeweler" in jeweler.services)
	check("przed zadaniem zamknięte", not Gems.unlocked)
	var sockets := 0
	for i in 200:
		if not Items.get_data(Loot.generate("sword_t2", "rare", 20)).get("sockets", []).is_empty():
			sockets += 1
	check("bez zadania łup bez gniazd", sockets == 0)
	# zadanie: surowy klejnot z rudy żelaza
	p.quests.accept("jeweler_gem")
	var ore = null
	for node in _world.entities.get_children():
		if node.get_script() != null and node.get_script().get_global_name() == "IronOre":
			ore = node
			break
	check("złoże rudy w Turniach", ore != null)
	var loot: Array = ore.roll_loot() if ore != null else []
	check("z rudy surowy klejnot", loot.any(func(e: Array) -> bool: return e[0] == "rough_gem"))
	p.inventory.add_item("rough_gem", 1)
	check("zadanie do oddania", p.quests.state_of("jeweler_gem") == "ready", p.quests.state_of("jeweler_gem"))
	var gems_before := _count_gems(p)
	p.quests.turn_in("jeweler_gem", p.stats)
	check("odblokowanie: kamień i darmowe gniazdo", Gems.unlocked and p.free_sockets == 1 and _count_gems(p) == gems_before + 1)
	# kamień: 2 premie, jedna z puli rodzaju, druga wspólna; lepszy szlif - mocniej
	var ruby: String = Gems.roll("ruby", 0)
	var royal: String = Gems.roll("ruby", 4)
	var affixes: Dictionary = Items.get_data(ruby)["stats"]
	check("2 premie kamienia", affixes.size() == 2 and affixes.keys().any(func(s: String) -> bool: return s in Gems.KINDS["ruby"]["pool"])
			and affixes.keys().any(func(s: String) -> bool: return s in Gems.SHARED), str(affixes))
	check("szlif królewski mocniejszy", Items.get_data(royal)["stats"].values().max() > 0 and Items.get_data(royal)["name"].contains("królewski"))
	var better := 0
	for i in 60:
		if Items.get_data(Gems.roll("", 2, true))["stats"].size() == 3:
			better += 1
	check("lepsze kamienie z lochów: trzecia premia", better > 5 and better < 55, "%d/60" % better)
	# gniazdo w założonej broni (pierwsze za darmo)
	var window = _world.find_child("HUD", true, false).jeweler_window
	window.open()
	window._selected = {"equip": "weapon"}
	var weapon_before: String = p.equipment.get_item("weapon")
	window._add_socket(0)
	var weapon: String = p.equipment.get_item("weapon")
	check("gniazdo w broni", Gems.sockets_of(weapon).size() == 1 and p.free_sockets == 0 and weapon != "", "%s -> %s" % [weapon_before, weapon])
	# osadzenie kamienia: premie w statystykach i w opisie
	var gem := _gem_with(p, Gems, "health")
	var health_before: int = p.stats.max_health()
	var index: int = _index_of(p, gem)
	window._refresh()
	window._insert(0, index)
	check("kamień osadzony", not Gems.sockets_of(weapon)[0].is_empty() and p.inventory.count_of(gem) == 0)
	check("premia kamienia działa", p.stats.max_health() > health_before, "%d -> %d" % [health_before, p.stats.max_health()])
	check("opis gniazda", Items.describe(weapon).contains("Rubin"))
	# zapis: przedmiot z kamieniem przetrwa wczytanie
	var saved: Dictionary = JSON.parse_string(JSON.stringify(Loot.export_used([weapon])))
	Items.generated.erase(weapon)
	Loot.import(saved)
	check("zapis przedmiotu z kamieniem", not Gems.sockets_of(weapon)[0].is_empty() and p.stats.max_health() > health_before)
	# wyjęcie (za darmo, kamień wraca)
	window._remove(0)
	check("wyjęcie kamienia", Gems.sockets_of(weapon)[0].is_empty() and p.stats.max_health() == health_before and _count_gems(p) >= 1)
	# łączenie 3 okruchów w odłamek
	for i in 3:
		p.inventory.add_item(Gems.roll("", 0), 1)
	var shards := _count_cut(p, 1)
	window._refresh()
	p.stats.add_gold(1000)
	window._build_combine()
	var button = window._combine.get_children().filter(func(b) -> bool: return b is Button and not b.disabled)
	if not button.is_empty():
		button[0].pressed.emit()
	check("łączenie 3 -> 1 lepszy", _count_cut(p, 1) == shards + 1, "%d -> %d" % [shards, _count_cut(p, 1)])
	# po zadaniu łup czasem z gniazdem
	sockets = 0
	for i in 200:
		if not Items.get_data(Loot.generate("sword_t2", "rare", 20)).get("sockets", []).is_empty():
			sockets += 1
	check("łup z gniazdami po zadaniu", sockets > 10 and sockets < 60, "%d/200" % sockets)
	# premia "obszar umiejętności"
	var area: float = p.stats.area_multiplier()
	p.stats.set_temp("test", {"area": 0.2})
	check("obszar umiejętności", is_equal_approx(p.stats.area_multiplier(), area + 0.2) and p.whirl_radius() > 0.0)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _count_gems(p) -> int:
	var Items = load("res://scripts/items.gd")
	return p.inventory.slots.filter(func(s: Dictionary) -> bool: return not s.is_empty() and Items.get_data(s["id"]).has("gem")).size()


func _count_cut(p, cut: int) -> int:
	var Items = load("res://scripts/items.gd")
	return p.inventory.slots.filter(func(s: Dictionary) -> bool:
		return not s.is_empty() and Items.get_data(s["id"]).has("gem") and Items.get_data(s["id"])["gem"]["cut"] == cut).size()


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1


## Rubin ze zdrowiem w plecaku.
func _gem_with(p, Gems, stat: String) -> String:
	var Items = load("res://scripts/items.gd")
	for i in 50:
		var id: String = Gems.roll("ruby", 1)
		if Items.get_data(id)["stats"].has(stat):
			p.inventory.add_item(id, 1)
			return id
	return ""
