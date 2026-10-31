extends SceneTree
## Rynek rośnie z liczbą podróżników: liczba ofert przedmiotów, głębokość i ilości arkusza towarów, mniejszy wpływ
## dużych transakcji na cenę, lepsze przedmioty, szybsza sprzedaż przedmiotów gracza; okazje znikają szybciej niż
## przepłacone oferty; filtry, sortowanie i „Dla mnie” w oknie rynku; zapis wieku ofert.

var _world: Node
var _frame := 0
var _fails := 0
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


func _count(m) -> int:
	return m.listings.filter(func(l: Dictionary) -> bool: return not l.get("mine", false)).size()


func _quantity(book: Dictionary) -> int:
	var total := 0
	for level: Array in book["sell"]:
		total += int(level[1])
	return total


## Ułamek rzadkich i legendarnych wśród 400 wylosowanych przedmiotów (bez kamieni).
func _roll_share(m) -> float:
	var rare := 0
	var all := 0
	for i in 400:
		var id: String = m._roll_item(30)
		var rarity: String = I.get_data(id).get("rarity", "")
		I.generated.erase(id)
		if rarity in ["magic", "rare", "legendary"]:
			all += 1
			if rarity != "magic":
				rare += 1
	return float(rare) / maxf(1.0, float(all))


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if I == null:
		I = load("res://scripts/items.gd")
	if _frame != 6:
		return false
	var p = _world.player
	var m = p.market
	var t = p.travelers
	t.ensure_roster()
	load("res://scripts/gems.gd").unlocked = true
	for r: Dictionary in t.roster:
		r["level"] = 30
	# mały rynek: bez gildii
	t.guild_rank = 0
	m.refresh_listings(true)
	var small_count := _count(m)
	var small_depth: int = m.book("wood")["sell"].size()
	var small_qty := _quantity(m.book("wood"))
	var small_rare := _roll_share(m)
	m.prices["iron_ore"] = 14.0
	m._push("iron_ore", 200, 1.0)
	var small_push: float = m.prices["iron_ore"] - 14.0
	check("mały rynek: kilka ofert", small_count == 8 and m.listing_target() == 8, str(small_count))
	# duży rynek: pełna gildia
	t.guild_rank = 6
	m.refresh_listings(true)
	var big_count := _count(m)
	check("duży rynek: dużo ofert", big_count == 60, str(big_count))
	check("więcej poziomów cen", m.book("wood")["sell"].size() > small_depth, "%d -> %d" % [small_depth, m.book("wood")["sell"].size()])
	check("większe ilości towarów", _quantity(m.book("wood")) > small_qty * 2)
	m.prices["iron_ore"] = 14.0
	m._push("iron_ore", 200, 1.0)
	check("duże transakcje mniej przesuwają cenę", m.prices["iron_ore"] - 14.0 < small_push,
			"%.2f < %.2f" % [m.prices["iron_ore"] - 14.0, small_push])
	var big_rare := _roll_share(m)
	check("lepsze przedmioty na dużym rynku", big_rare > small_rare + 0.05, "%.2f > %.2f" % [big_rare, small_rare])
	check("więcej kupujących", m.demand() > 1.0)
	# okazje znikają szybciej niż przepłacone oferty
	var deals := 0
	var pricey := 0
	for round in 20:
		m.refresh_listings(true)
		var cheap: Array = []
		var dear: Array = []
		for l: Dictionary in m.listings:
			if l.get("mine", false):
				continue
			l["age"] = 0
			if m.deal_of(l) >= 0.15:
				cheap.append(l)
			elif m.deal_of(l) <= -0.25:
				dear.append(l)
		m.tick()
		deals += cheap.filter(func(l: Dictionary) -> bool: return not m.listings.has(l)).size() * 1000 / maxi(1, cheap.size())
		pricey += dear.filter(func(l: Dictionary) -> bool: return not m.listings.has(l)).size() * 1000 / maxi(1, dear.size())
	check("okazje znikają szybko", deals > pricey * 4, "%d vs %d" % [deals, pricey])
	check("nowe oferty dochodzą", _count(m) >= 50)
	# zapis wieku ofert
	m.listings[0]["age"] = 7
	var saved: Dictionary = JSON.parse_string(JSON.stringify(m.get_save_data()))
	var copy = load("res://scripts/market.gd").new()
	copy.load_save_data(saved)
	check("zapis ofert", copy.listings.size() == m.listings.size() and int(copy.listings[0].get("age", 0)) == 7)
	copy.free()
	# okno: filtry, sortowanie, „Dla mnie”
	var hud = _world.find_child("HUD", true, false)
	var w = hud.market_window
	w.open()
	w._show("items")
	w._filter = "weapon"
	var weapons: Array = w.shown_listings()
	check("filtr broni", not weapons.is_empty() and weapons.all(func(l: Dictionary) -> bool: return I.get_data(l["id"])["slot"] == "weapon"))
	w._filter = "legendary"
	check("filtr legend", w.shown_listings().all(func(l: Dictionary) -> bool: return I.get_data(l["id"])["rarity"] == "legendary"))
	w._filter = "all"
	w._sort = "price"
	var by_price: Array = w.shown_listings()
	var sorted_ok := true
	for i in by_price.size() - 1:
		sorted_ok = sorted_ok and int(by_price[i]["price"]) <= int(by_price[i + 1]["price"])
	check("sortowanie po cenie", sorted_ok and by_price.size() == _count(m))
	w._sort = "deal"
	var by_deal: Array = w.shown_listings()
	check("sortowanie po okazji", m.deal_of(by_deal[0]) >= m.deal_of(by_deal[-1]))
	w._for_me = true
	p.stats.level = 30
	var mine: Array = w.shown_listings()
	var fits := func(l: Dictionary) -> bool:
		var data: Dictionary = I.get_data(l["id"])
		return I.is_equippable(l["id"]) and I.item_level(l["id"]) <= 30 \
				and (data["slot"] != "weapon" or data["weapon"]["type"] == p.stats.weapon_type())
	check("dla mnie", mine.all(fits) and mine.size() < _count(m), str(mine.size()))
	w._refresh()
	check("okno rynku z filtrami", w._list.get_child_count() >= 3)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false
