extends SceneTree
## Talizmany (Talismans, siatka w Equipment, okno TalismanWindow): kształty i liczba premii, efekt rzadkich, poziom
## przedmiotu, oferta Kręgu Żertwy (nadwyżka daniny - więcej rzadkich i wielkich), siatka (miejsce, nachodzenie,
## granice, przesuwanie), premie i efekty postaci, wkładanie i wyjmowanie z plecaka (PPM i przeciąganie), zapis gry.

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
	_check_rolls()
	_check_grid()
	_check_player()
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _check_rolls() -> void:
	var T = load("res://scripts/talismans.gd")
	var Items = load("res://scripts/items.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var shapes_ok := true
	for shape: String in T.SHAPE_ORDER:
		var id: String = T.roll(20, "magic", shape, rng)
		var data: Dictionary = Items.get_data(id)
		shapes_ok = shapes_ok and T.is_talisman(id) and T.size_of(id) == T.SHAPES[shape]["size"] \
				and data["stats"].size() == T.SHAPES[shape]["affixes"] and not data.has("effect") and data["rarity"] == "magic" \
				and data["stats"].values().all(func(v) -> bool: return float(v) > 0.0) and not Items.is_equippable(id)
	check("kształty: rozmiar i liczba premii (więcej przy większym)", shapes_ok)
	var rare: String = T.roll(20, "rare", "small", rng)
	var effect: Dictionary = Items.get_data(rare).get("effect", {})
	check("rzadki: efekt warunkowy, nie mieści się w 1x1", T.size_of(rare) != Vector2i(1, 1) and T.EFFECTS.has(effect.get("kind", ""))
			and float(effect["chance"]) > 0.0 and Items.get_data(rare)["name"].contains(" "), Items.get_data(rare)["name"])
	var described: String = Items.describe(rare)
	check("opis: rzadkość, rozmiar, premie i efekt", described.contains("Talizman") and described.contains("Efekt:"), described)
	# wyższy poziom przedmiotu - mocniejsze premie
	var low := 0.0
	var high := 0.0
	for i in 60:
		low += _strength(Items, T.roll(5, "magic", "small", rng))
		high += _strength(Items, T.roll(80, "magic", "small", rng))
	check("wyższy poziom - mocniejsze premie", high > low * 2.0, "%.1f vs %.1f" % [low, high])
	var counts := {0.0: [0, 0], 1.0: [0, 0]}
	for bonus: float in counts:
		for i in 150:
			for id: String in T.roll_offer(30, bonus, 3, rng):
				counts[bonus][0] += 1 if Items.rarity_of(id) == "rare" else 0
				counts[bonus][1] += 1 if T.size_of(id) == Vector2i(2, 2) else 0
	check("oferta: nadwyżka daniny - więcej rzadkich i wielkich", counts[1.0][0] > counts[0.0][0] * 1.5
			and counts[1.0][1] > counts[0.0][1] * 1.5 and counts[0.0][0] > 0, str(counts))
	var offer: Array = T.roll_offer(30, 0.0, 3, rng)
	check("oferta: 3 talizmany, pierwszy większy niż 1x1", offer.size() == 3 and T.size_of(offer[0]) != Vector2i(1, 1))


## Siła premii względem jej zakresu na tierze 1 (porównanie poziomów bez względu na rodzaj premii).
func _strength(Items, id: String) -> float:
	var stats: Dictionary = Items.get_data(id)["stats"]
	var stat: String = stats.keys()[0]
	return float(stats[stat]) / float(load("res://scripts/loot.gd").TIER_VALUES[stat][1]) * 100.0


func _check_grid() -> void:
	var T = load("res://scripts/talismans.gd")
	var Items = load("res://scripts/items.gd")
	var eq = _world.player.equipment
	var small: String = T.roll(20, "magic", "small")
	var large: String = T.roll(20, "magic", "large")
	var wide: String = T.roll(20, "rare", "wide")
	check("siatka 4x3, pusta", T.GRID == Vector2i(4, 3) and eq.talismans.is_empty())
	check("granice siatki", not eq.can_place_talisman(large, Vector2i(3, 0)) and not eq.can_place_talisman(large, Vector2i(0, 2))
			and eq.can_place_talisman(large, Vector2i(2, 1)) and not eq.can_place_talisman("health_potion", Vector2i(0, 0)))
	check("wkładanie", eq.place_talisman(small, Vector2i(0, 0)) and eq.place_talisman(large, Vector2i(1, 0)))
	check("talizmany nie nachodzą na siebie", not eq.can_place_talisman(wide, Vector2i(0, 0)) and not eq.can_place_talisman(wide, Vector2i(2, 1))
			and eq.can_place_talisman(wide, Vector2i(0, 2)) and eq.talisman_at(Vector2i(2, 1)) == 1 and eq.talisman_at(Vector2i(3, 2)) == -1)
	check("pierwsze wolne miejsce", eq.free_talisman_cell(wide) == Vector2i(0, 2)
			and eq.free_talisman_cell(T.roll(20, "magic", "large")) == Vector2i(-1, -1), str(eq.free_talisman_cell(wide)))
	var stat: String = Items.get_data(small)["stats"].keys()[0]
	var expected := 0.0
	for id: String in [small, large]:
		expected += float(Items.get_data(id)["stats"].get(stat, 0.0))
	check("premie talizmanów liczą się do postaci", is_equal_approx(eq.bonus(stat), expected), "%s %.2f" % [stat, expected])
	eq.place_talisman(wide, Vector2i(0, 2))
	var kind: String = Items.get_data(wide)["effect"]["kind"]
	eq._power_cache.clear()
	check("efekt rzadkiego talizmanu działa (effect_power)", is_equal_approx(eq.effect_power(kind), float(Items.get_data(wide)["effect"]["chance"])), kind)
	check("przesuwanie w siatce", eq.move_talisman(1, Vector2i(2, 0)) and eq.talismans[1]["cell"] == Vector2i(2, 0)
			and not eq.move_talisman(1, Vector2i(0, 0)))
	var saved: Dictionary = eq.get_save_data()
	eq.talismans.clear()
	eq.load_save_data(saved)
	check("zapis siatki", eq.talismans.size() == 3 and eq.talismans[1]["cell"] == Vector2i(2, 0))
	check("wyjmowanie", eq.remove_talisman(0) == small and eq.talismans.size() == 2)
	eq.talismans.clear()
	eq.changed.emit()


func _check_player() -> void:
	var T = load("res://scripts/talismans.gd")
	var Loot = load("res://scripts/loot.gd")
	var Items = load("res://scripts/items.gd")
	var p = _world.player
	var hud = _world.find_child("HUD", true, false)
	var large: String = T.roll(25, "rare", "large")
	var small: String = T.roll(25, "magic", "small")
	p.inventory.add_item(large, 1)
	p.inventory.add_item(small, 1)
	var health_before: int = p.stats.max_health()
	check("PPM w plecaku - talizman do siatki", p.place_talisman(_index_of(p, large)) and _index_of(p, large) == -1
			and p.equipment.talismans[0]["cell"] == Vector2i(0, 0))
	# okno talizmanów i przeciąganie z plecaka
	hud.inventory_window.toggle()
	hud._open_talismans()
	var window = hud.talisman_window
	check("okno talizmanów obok ekwipunku", window.visible and window._pieces.size() == 1
			and window.position.x + window.size.x <= hud.inventory_window.position.x)
	var drag := {"inventory": p.inventory, "index": _index_of(p, small)}
	var on_large := Vector2(10, 10)
	var free_spot: Vector2 = Vector2(3.5, 0.5) * (window.CELL + window.GAP)
	check("przeciąganie: zajęte miejsce odrzucone, wolne przyjęte", not window._can_drop(on_large, drag, null)
			and window._can_drop(free_spot, drag, null))
	window._drop(free_spot, drag, null)
	check("przeciągnięty talizman w siatce", p.equipment.talismans.size() == 2 and p.equipment.talismans[1]["cell"] == Vector2i(3, 0)
			and window._pieces.size() == 2 and window._summary.text != "")
	# zapis gry: talizmany w siatce wracają po wczytaniu
	var data: Dictionary = p.get_save_data()
	check("zapis: przepisy talizmanów w zapisie", data["generated_items"].has(large) and data["generated_items"].has(small))
	var name: String = Items.get_data(large)["name"]
	Items.generated.erase(large)
	Items.generated.erase(small)
	p.equipment.talismans.clear()
	Loot.import(JSON.parse_string(JSON.stringify(data["generated_items"])))
	p.equipment.load_save_data(JSON.parse_string(JSON.stringify(data["equipment"])))
	check("wczytanie: talizmany w siatce, ta sama nazwa i efekt", p.equipment.talismans.size() == 2
			and Items.get_data(large)["name"] == name and Items.get_data(large).has("effect"))
	# wyjęcie przeciągnięciem do plecaka
	var empty := -1
	for i in p.inventory.slots.size():
		if p.inventory.slots[i].is_empty():
			empty = i
			break
	hud.inventory_window._drop_on_bag(Vector2.ZERO, {"talisman": 1}, empty)
	check("przeciągnięcie z siatki do plecaka", p.equipment.talismans.size() == 1 and p.inventory.slots[empty].get("id", "") == small)
	check("PPM w siatce - wyjmij", p.remove_talisman(0) and p.equipment.talismans.is_empty() and _index_of(p, large) >= 0
			and p.stats.max_health() == health_before)
	window.visible = false
