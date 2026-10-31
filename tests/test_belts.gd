extends SceneTree
## Pasy: nowe miejsce na postaci (okno plecaka), dwie linie w 5 poziomach (skórzany i okuty), premie z puli pasa
## z nową "siłą mikstur" (mikstury leczą mocniej), pas w sklepie kowala, zaklinanie jak zbroja, esencja zbroi,
## legendy ze skarbca lochu: Pas Mokoszy (mikstura może nie ubyć) i Pas Bogatyra (premia do obrażeń po miksturze).

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
	var Items = load("res://scripts/items.gd")
	var Loot = load("res://scripts/loot.gd")
	var Bases = load("res://scripts/item_bases.gd")
	var Ess = load("res://scripts/essences.gd")
	var Ench = load("res://scripts/enchanting.gd")
	var Dungeons = load("res://scripts/dungeons.gd")
	check("linie pasów w 5 poziomach", Bases.LINES.get("belt", []).size() == 5 and Bases.LINES.get("girdle", []).size() == 5
			and Items.get_data("girdle_t4")["slot"] == "belt")
	check("miejsce na pas", p.equipment.items.has("belt") and _world.find_child("HUD", true, false).inventory_window._gear.has("belt"))
	# rzadki pas: premie z puli pasa, założenie trafia na pas
	var belt: String = Loot.generate("belt_t2", "rare", 40)
	var pool: Array = Loot.POOLS["belt"]
	check("premie z puli pasa", Items.get_data(belt)["affixes"].keys().all(func(s: String) -> bool: return s in pool))
	p.inventory.add_item(belt, 1)
	p.equip_from_inventory(_index_of(p, belt))
	check("pas założony", p.equipment.get_item("belt") == belt)
	check("zaklinanie i esencje jak zbroja", Ench.category(belt) == "armor" and Ess.group_of(belt) == "armor")
	var found := false
	for i in 300:
		if Items.get_data(Loot.generate("girdle_t3", "rare", 50))["affixes"].has("potion_power"):
			found = true
			break
	check("siła mikstur na pasach", found and Items.describe(Loot.generate("belt_t1", "common", 5)).contains("Pas"))
	# siła mikstur: mikstura leczy mocniej (bez pasa - rzadki pas mógł wylosować własną siłę mikstur)
	p.equipment.items["belt"] = {}
	p.equipment.changed.emit()
	p.inventory.add_item("health_potion", 20)
	p.health = 1
	p.use_item("health_potion")
	var plain: int = p.health - 1
	p.stats.set_temp("test", {"potion_power": 0.5})
	p.health = 1
	p.use_item("health_potion")
	var strong: int = p.health - 1
	p.stats.set_temp("test", {})
	check("siła mikstur leczy mocniej", strong >= roundi(plain * 1.5) - 1 and strong > plain, "%d -> %d" % [plain, strong])
	# Pas Mokoszy: część mikstur nie ubywa
	var mokosh: String = Loot.legendary_at_level("legend_mokosh_belt", 30)
	p.equipment.items["belt"] = {"id": mokosh, "enchant": 0}
	p.equipment.changed.emit()
	var before: int = p.inventory.count_of("health_potion")
	p.inventory.add_item("health_potion", 60)
	before = p.inventory.count_of("health_potion")
	for i in 40:
		p.health = 1
		p.use_item("health_potion")
	var used: int = before - p.inventory.count_of("health_potion")
	check("Pas Mokoszy oszczędza mikstury", used < 38 and used > 15, "zużyto %d/40" % used)
	# Pas Bogatyra: premia do obrażeń po miksturze
	var girdle: String = Loot.legendary_at_level("legend_bogatyr_girdle", 30)
	p.equipment.items["belt"] = {"id": girdle, "enchant": 0}
	p.equipment.changed.emit()
	p.health = 1
	p.use_item("health_potion")
	var statuses: Array = p.legendary.statuses()
	check("Pas Bogatyra: gniew po miksturze", p.stats.temp_bonus.get("damage_percent", 0.0) > 0.2
			and statuses.any(func(s: Dictionary) -> bool: return s["name"] == "Gniew Bogatyra"))
	p.legendary._process(10.0)
	check("gniew mija", p.stats.temp_bonus.get("damage_percent", 0.0) == 0.0)
	check("legendy pasów w skarbcu lochu", "legend_mokosh_belt" in Dungeons.VAULT_LEGENDS and "legend_bogatyr_girdle" in Dungeons.VAULT_LEGENDS
			and Items.get_data(mokosh)["slot"] == "belt" and Items.get_data(mokosh)["icon"].resource_path.contains("legend_mokosh_belt"))
	# zapis założonego pasa
	var saved: Dictionary = JSON.parse_string(JSON.stringify(p.equipment.get_save_data()))
	p.equipment.items["belt"] = {}
	p.equipment.load_save_data(saved)
	check("zapis pasa", p.equipment.get_item("belt") == girdle)
	# sklep kowala
	var smith = null
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if npc.display_name == "Kowal Bronisław":
			smith = npc
	check("pasy u kowala", smith != null and "belt_t1" in smith.shop_sells and "girdle_t1" in smith.shop_sells
			and Items.get_data("belt_t1").has("price"))
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1
