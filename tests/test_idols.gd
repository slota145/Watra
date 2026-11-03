extends SceneTree
## Bożki (scripts/idols.gd): dane przedmiotów (nazwy, opisy, ikony, stosy), sloty według poziomu Watry, łączenie
## mnożników z modyfikatorami za żar, premie mechanik (zwykły - częściej, rzadki - zawsze, legendarny - wzmocniona),
## losowanie bożków; potem loch z bożkami (mechanika wymuszona i wzmocniona, mnożniki potworów, poziom łupu, runy
## w skarbcu) i pełna droga: bożki w plecaku -> sloty w oknie lochów -> wejście (bożki zużyte, zapisane w wyprawie).

var _world: Node
var _frame := 0
var _fails := 0
var _stage := 0
var _D
var _I


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_D = load("res://scripts/dungeons.gd")
	_I = load("res://scripts/idols.gd")
	_check_data()
	_check_effects()
	var config: Dictionary = _D.config("catacombs", 3, [], 777,
			["idol_chests_legendary", "idol_horde_rare", "idol_pride_legendary", "idol_runes_legendary"])
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _check_data() -> void:
	var Items = load("res://scripts/items.gd")
	var all_ok := true
	for kind: String in _I.KIND_ORDER:
		for rarity: String in _I.RARITIES:
			var id: String = _I.id_of(kind, rarity)
			var data: Dictionary = Items.get_data(id)
			if data.is_empty() or data.get("icon") == null or data["rarity"] != rarity or _I.parse(id) != [kind, rarity]:
				all_ok = false
	check("każdy bożek ma dane i ikonę", all_ok and _I.KIND_ORDER.size() == _I.KINDS.size())
	check("nazwa bożka", Items.display_name("idol_skarbnik_legendary") == "Złocony Bożek Skarbnika",
			Items.display_name("idol_skarbnik_legendary"))
	check("bożki w stosach", Items.max_stack("idol_gold_common") > 1 and not Items.is_equippable("idol_gold_common"))
	var text: String = Items.describe("idol_zertwa_legendary")
	check("opis legendarnego bożka mechaniki", text.contains("zawsze") and text.contains("talizman"), text)
	check("opis bożka ryzyka", Items.describe("idol_pride_rare").contains("+60% obrażeń"), Items.describe("idol_pride_rare"))
	check("nie-bożek", _I.parse("idol_nope_common").is_empty() and not _I.is_idol("rune_polish"))


func _check_effects() -> void:
	check("sloty: 2 na start, 3 od 4. poziomu Watry, 4 od 6.", _I.slot_count(1) == 2 and _I.slot_count(3) == 2
			and _I.slot_count(4) == 3 and _I.slot_count(7) == 4)
	check("ten sam rodzaj tylko raz", _I.can_combine(["idol_gold_common", "idol_items_rare"])
			and not _I.can_combine(["idol_gold_common", "idol_gold_legendary"]))
	var config: Dictionary = _D.config("catacombs", 1, ["fury"], 1, ["idol_fury_rare", "idol_pride_common"])
	check("mnożniki łączą się z modyfikatorami", is_equal_approx(_D.mult(config, "damage"), 1.25 * 1.2 * 1.4)
			and is_equal_approx(_D.mult(config, "count"), 1.0), "%f" % _D.mult(config, "damage"))
	check("premie dodawane", is_equal_approx(_D.added(config, "item_level"), 2.0) and _D.added(config, "quality") == 0.0)
	var bonus: Dictionary = _D.mechanic_bonus(_D.config("mine", 1, [], 1,
			["idol_chests_common", "idol_zertwa_rare", "idol_skarbnik_legendary"]))
	check("premie mechanik z bożków", bonus["weights"].get("chests", 1.0) == _I.MECHANIC_WEIGHT
			and bonus["forced"].has("zertwa") and bonus["forced"].has("skarbnik") and not bonus["forced"].has("chests")
			and bonus["power"].get("skarbnik", 1.0) > 1.0 and not bonus["power"].has("zertwa"), str(bonus))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var with_chests := 0
	var forced_ok := true
	for i in 2000:
		if _D.roll_mechanics(rng, _I.mechanic_bonus(["idol_chests_common"])).has("chests"):
			with_chests += 1
		if not _D.roll_mechanics(rng, _I.mechanic_bonus(["idol_uroczysko_rare"])).has("uroczysko"):
			forced_ok = false
	var base: float = _D.mechanic_chance("chests")
	check("zwykły bożek - mechanika dużo częściej", with_chests / 2000.0 > base * 1.8, "%.2f vs %.2f" % [with_chests / 2000.0, base])
	check("rzadki bożek - mechanika zawsze", forced_ok)
	var rarities := {}
	var valid := true
	for i in 3000:
		var id: String = _I.roll(rng)
		if _I.parse(id).is_empty():
			valid = false
		rarities[_I.parse(id)[1]] = int(rarities.get(_I.parse(id)[1], 0)) + 1
	check("losowanie bożków: zwykłe najczęściej, legendarne rzadko", valid and rarities["common"] > rarities["rare"]
			and rarities["rare"] > rarities["legendary"] and rarities["legendary"] > 30, str(rarities))
	check("szansa z bossa większa", _I.drop_chance(true) > _I.drop_chance(false) * 10.0)


func _process(_d: float) -> bool:
	_frame += 1
	if _stage == 0 and _frame == 6:
		_check_dungeon()
	elif _stage == 0 and _frame == 10:
		_world.queue_free()
		_world = null
		root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
		_world = load("res://scenes/world.tscn").instantiate()
		root.add_child(_world)
		current_scene = _world
		_stage = 1
		_frame = 0
	elif _stage == 1 and _frame == 10:
		_check_window()
	elif _stage == 2 and _frame == 60:
		var w = get_first_node_in_group("world")
		check("loch z bożkami z okna", w.zone == "dungeon" and w._dungeon_config.get("idols", []) == ["idol_gold_rare", "idol_fury_legendary"],
				str(w._dungeon_config.get("idols")))
		check("bożek działa w lochu", is_equal_approx(load("res://scripts/goblin.gd").dungeon_mods["gold"], 1.6))
		print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
		quit()
	return false


func _check_dungeon() -> void:
	var d = _world._dungeon
	var mods: Dictionary = load("res://scripts/goblin.gd").dungeon_mods
	check("legendarny bożek: mechanika zawsze i wzmocniona", d.mechanics.has("chests") and d.mechanic_power("chests") > 1.0
			and d.chests.size() >= _D.CHESTS.x + 1, "%s, %d skrzyń" % [d.mechanics, d.chests.size()])
	check("bożki ryzyka w potworach", is_equal_approx(mods["damage"], 1.8) and int(mods["item_level"]) == 6, str(mods))
	var pickup = load("res://scripts/pickup.gd")
	var runes_before := _count_runes(pickup)
	d._boss.take_damage(999999, d._boss.global_position)
	var runes := _count_runes(pickup) - runes_before
	check("Bożek Run: runy w skarbcu", runes >= 4, "%d run" % runes)


func _count_runes(pickup) -> int:
	return _world.entities.get_children().filter(func(n: Node) -> bool:
		return n.get_script() == pickup and str(n.item_id).begins_with("rune_")).size()


func _check_window() -> void:
	var w = _world
	var player = w.player
	player.boons.ember = 5000
	player.inventory.add_item("idol_gold_rare", 2)
	player.inventory.add_item("idol_gold_common", 1)
	player.inventory.add_item("idol_fury_legendary", 1)
	var win = w.hud.dungeon_window
	win.open()
	var pickers: Array = win._idol_pickers
	check("okno: sloty według poziomu Watry", not pickers[0].disabled and not pickers[2].disabled and pickers[3].disabled)
	win._choose_idol(_index_of(pickers[0], "idol_gold_rare"), 0)
	check("okno: ten sam rodzaj znika z innych slotów", _index_of(pickers[1], "idol_gold_common") < 0
			and _index_of(pickers[1], "idol_fury_legendary") > 0)
	win._choose_idol(_index_of(pickers[1], "idol_fury_legendary"), 1)
	check("okno: opis działania bożków", win._idol_text.text.contains("złota"), win._idol_text.text)
	win._on_enter()
	check("bożki zużyte przy wejściu", player.inventory.count_of("idol_gold_rare") == 1
			and player.inventory.count_of("idol_fury_legendary") == 0 and player.inventory.count_of("idol_gold_common") == 1)
	_stage = 2
	_frame = 0


func _index_of(picker: OptionButton, id: String) -> int:
	for i in picker.item_count:
		if str(picker.get_item_metadata(i)) == id:
			return i
	return -1
