class_name Market
extends Node
## Symulowany rynek w gildii (jak w Black Desert) - dziecko gracza, zapisywany. Dwie części:
## - Towary (rzeczy liczone w sztukach - COMMODITIES): cena każdego towaru błądzi w czasie wokół ceny bazowej, a arkusz
##   ofert (book) to kilka poziomów sprzedaży powyżej ceny i kupna poniżej, z ilościami i imionami podróżników.
##   Gracz kupuje od razu po najlepszej ofercie sprzedaży albo sprzedaje po najlepszej ofercie kupna (podatek TAX),
##   albo wystawia własne zamówienie po swojej cenie: towar (sprzedaż) albo złoto (kupno) zostaje na rynku, a podróżnicy
##   realizują zamówienie z czasem (tym szybciej, im lepsza cena). Duże zakupy i sprzedaże przesuwają cenę.
## - Przedmioty: pojedyncze oferty podróżników (broń, zbroje, biżuteria, kamienie szlachetne, czasem legendy) z ceną
##   i sprzedawcą, odświeżane co jakiś czas; gracz może kupić albo wystawić własny przedmiot.
## - Świeży towar (fresh): surowce zebrane przez podróżników (Traveler, Travelers.tick) trafiają do arkusza jako osobne,
##   tańsze oferty sprzedaży z imieniem zbieracza i lekko obniżają cenę; inni podróżnicy szybko je wykupują.
## Kupione rzeczy trafiają do plecaka, a gdy jest pełny - do magazynu (albo czekają w zamówieniu do odbioru).
## Rynek rośnie z liczbą aktywnych podróżników (Travelers.active_count, ranga gildii - size_factor): więcej ofert
## przedmiotów (listing_target), więcej poziomów cen i większe ilości towarów (book_depth, volume - duże transakcje mniej
## przesuwają cenę), lepsze przedmioty i więcej kupujących (przedmioty gracza schodzą szybciej). Okazje (oferty tańsze
## od uczciwej ceny - deal_of) inni podróżnicy wykupują w kilka minut, przepłacone wiszą długo.

signal changed

const TICK := 30.0
const TAX := 0.1
## Liczba ofert przedmiotów i poziomów cen w arkuszu: od najmniejszego rynku (4 podróżników) do największego (40).
const LISTINGS_RANGE := Vector2i(8, 60)
const DEPTH_RANGE := Vector2i(4, 10)
## Ile ofert przedmiotów najwyżej dochodzi w jednej chwili rynku (plus więcej przy dużym rynku).
const NEW_LISTINGS := 2
## Oferty przedmiotów: cena względem uczciwej (losowo) i po ilu chwilach rynku stara oferta może zniknąć.
const PRICE_SPREAD := Vector2(0.75, 1.4)
const STALE_TICKS := 40
## Towary i ich cena bazowa (złoto za sztukę).
const COMMODITIES := {
	"wood": 4, "stone": 5, "iron_ore": 14, "meat": 6, "wolf_pelt": 12, "deer_hide": 10, "boar_hide": 14, "goat_hide": 16,
	"fish": 5, "herb_wort": 12, "herb_chamomile": 16, "herb_calamus": 20, "herb_arnica": 28, "herb_fern": 90, "herb_datura": 40,
	"health_potion": 30, "mana_potion": 30, "greater_health_potion": 90, "greater_mana_potion": 90,
	"weapon_stone": 60, "armor_stone": 60, "jewelry_stone": 70, "weapon_stone_perfect": 400, "armor_stone_perfect": 400,
	"jewelry_stone_perfect": 450, "blessed_stone": 40, "mercy_stone": 180, "crystal_heart": 900,
	"spider_silk": 18, "bone_dust": 16, "hydra_scale": 60, "storm_feather": 45,
	"goblin_heart": 10, "kobold_fuse": 14, "frog_tongue": 16, "satyr_horn": 24, "rune_chaos": 500, "rune_seal": 2000,
}
## Kategorie towarów do listy w oknie rynku.
const CATEGORIES := {
	"Surowce": ["wood", "stone", "iron_ore", "meat", "fish", "wolf_pelt", "deer_hide", "boar_hide", "goat_hide",
			"spider_silk", "bone_dust", "hydra_scale", "storm_feather", "goblin_heart", "kobold_fuse", "frog_tongue", "satyr_horn"],
	"Zioła i mikstury": ["herb_wort", "herb_chamomile", "herb_calamus", "herb_arnica", "herb_fern", "herb_datura",
			"health_potion", "mana_potion", "greater_health_potion", "greater_mana_potion"],
	"Kamienie": ["weapon_stone", "armor_stone", "jewelry_stone", "weapon_stone_perfect", "armor_stone_perfect",
			"jewelry_stone_perfect", "blessed_stone", "mercy_stone", "crystal_heart", "rune_chaos", "rune_seal"],
}
const HISTORY := 24
## Najwyżej tyle świeżych ofert jednego towaru naraz i szansa, że inni podróżnicy wykupią świeżą ofertę w jednej chwili rynku.
const FRESH_MAX := 4
const FRESH_SOLD_CHANCE := 0.35

## towar -> aktualna cena (float) i ostatnie ceny (do wykresu / trendu)
var prices := {}
var history := {}
## Zamówienia gracza: [{kind: "sell"/"buy", id, qty, left, price, ready}] - ready: kupione, czekające na odbiór.
var orders: Array[Dictionary] = []
## Oferty przedmiotów: [{id (wylosowany przedmiot), price, seller, mine}] - mine: wystawione przez gracza.
var listings: Array[Dictionary] = []
## Świeży towar od zbieraczy: towar -> [[ilość, imię zbieracza]...].
var fresh := {}
var _player: Player
var _timer := TICK
var _book_seed := 0


func setup(player: Player) -> void:
	_player = player


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = TICK
		tick()


func ensure() -> void:
	for id: String in COMMODITIES:
		if not prices.has(id):
			prices[id] = float(COMMODITIES[id]) * randf_range(0.85, 1.15)
			history[id] = [prices[id]]


static func is_commodity(id: String) -> bool:
	return COMMODITIES.has(id)


func price_of(id: String) -> int:
	ensure()
	return maxi(1, roundi(prices[id]))


## Zmiana ceny od początku historii (ułamek, np. 0.12 = +12%).
func trend(id: String) -> float:
	ensure()
	var past: Array = history[id]
	return (prices[id] - float(past[0])) / float(past[0]) if not past.is_empty() else 0.0


## Arkusz ofert: {"sell": [[cena, ilość, sprzedawca]...] od najtańszej, "buy": [[cena, ilość, kupujący]...] od najdroższej}.
func book(id: String) -> Dictionary:
	ensure()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([id, _book_seed])
	var base: float = prices[id]
	var names := _names()
	var sells := []
	var buys := []
	var scale := maxf(1.0, 400.0 / maxf(base, 1.0)) * volume()
	for i in book_depth():
		# tanie towary też mają odstęp między kupnem a sprzedażą (co najmniej 1 zł na poziom)
		var sell_price := maxi(ceili(base * (1.02 + 0.03 * i)), roundi(base) + 1 + i)
		var buy_price := maxi(1, mini(floori(base * (0.97 - 0.03 * i)), roundi(base) - 1 - i))
		sells.append([sell_price, maxi(1, roundi(rng.randf_range(2.0, 12.0) * scale)), names[rng.randi() % names.size()]])
		buys.append([buy_price, maxi(1, roundi(rng.randf_range(2.0, 12.0) * scale)), names[rng.randi() % names.size()]])
	# świeży towar od zbieraczy - taniej niż najtańsza zwykła oferta (ale drożej niż najlepsza oferta kupna)
	var fresh_price := maxi(roundi(base), int(sells[0][0]) - maxi(1, roundi(base * 0.03)))
	for entry: Array in fresh.get(id, []):
		sells.append([fresh_price, int(entry[0]), str(entry[1]), true])
	for order: Dictionary in orders:
		# zamówienia gracza widać w arkuszu
		if order["id"] == id and order["left"] > 0:
			(sells if order["kind"] == "sell" else buys).append([order["price"], order["left"], "Ty"])
	sells.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	buys.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	return {"sell": sells, "buy": buys}


# ---------------------------------------------------------------- wielkość rynku
func traveler_count() -> int:
	return _player.travelers.active_count() if _player != null else Travelers.RANK_ACTIVE[0]


## Wielkość rynku 0..1 (4 podróżników - 0, 40 - 1).
func size_factor() -> float:
	var low := float(Travelers.RANK_ACTIVE[0])
	return clampf((traveler_count() - low) / (float(Travelers.SIZE) - low), 0.0, 1.0)


func listing_target() -> int:
	return roundi(lerpf(LISTINGS_RANGE.x, LISTINGS_RANGE.y, size_factor()))


func book_depth() -> int:
	return roundi(lerpf(DEPTH_RANGE.x, DEPTH_RANGE.y, size_factor()))


## Mnożnik ilości w arkuszu ofert (podaż i popyt towarów).
func volume() -> float:
	return lerpf(0.5, 2.5, size_factor())


## Ilu kupujących: mnożnik szansy, że oferta (okazja albo przedmiot gracza) zostanie kupiona w jednej chwili rynku.
func demand() -> float:
	return lerpf(0.6, 1.6, size_factor())


## Okazja oferty: o ile taniej od uczciwej ceny (0.2 = 20% taniej, ujemna - drożej).
static func deal_of(listing: Dictionary) -> float:
	var fair := float(fair_price(listing["id"]))
	return 1.0 - float(listing["price"]) / fair


func _names() -> Array:
	var names := []
	if _player != null:
		for traveler: Dictionary in _player.travelers.active():
			names.append(traveler["name"])
	if names.is_empty():
		names = ["Wędrowiec"]  # tłumaczone przy pokazywaniu (tr nazwy sprzedawcy)
	return names


# ---------------------------------------------------------------- handel od razu
## Kupno od razu: `qty` sztuk po kolejnych ofertach sprzedaży. Zwraca "" albo powód odmowy.
func buy_now(id: String, qty: int) -> String:
	var cost := quote_buy(id, qty)
	if cost < 0:
		return Lang.t("Za mało ofert sprzedaży.")
	if _player.stats.gold < cost:
		return Lang.t("Za mało złota (%d zł).") % cost
	_player.stats.add_gold(-cost)
	_deliver(id, qty)
	_take_fresh(id, qty)
	_push(id, qty, 1.0)
	changed.emit()
	return ""


## Sprzedaż od razu: `qty` sztuk z plecaka po kolejnych ofertach kupna, minus podatek.
func sell_now(id: String, qty: int) -> String:
	if _player.inventory.count_of(id) < qty:
		return Lang.t("Nie masz tyle w plecaku.")
	var gain := quote_sell(id, qty)
	if gain < 0:
		return Lang.t("Za mało ofert kupna.")
	_player.inventory.remove_item(id, qty)
	_player.stats.add_gold(gain)
	_push(id, qty, -1.0)
	changed.emit()
	return ""


## Świeże oferty są najtańsze, więc kupno zabiera je pierwsze.
func _take_fresh(id: String, qty: int) -> void:
	var list: Array = fresh.get(id, [])
	while qty > 0 and not list.is_empty():
		var take := mini(qty, int(list[0][0]))
		list[0][0] = int(list[0][0]) - take
		qty -= take
		if int(list[0][0]) <= 0:
			list.pop_front()
	if list.is_empty():
		fresh.erase(id)


## Podróżnik wystawia zebrany surowiec: świeża oferta w arkuszu i lekki spadek ceny.
func supply(id: String, qty: int, seller: String) -> void:
	if not COMMODITIES.has(id) or qty <= 0:
		return
	ensure()
	var list: Array = fresh.get(id, [])
	list.append([qty, seller])
	while list.size() > FRESH_MAX:
		list.pop_front()
	fresh[id] = list
	_push(id, qty, -0.5)
	changed.emit()


## Koszt kupna `qty` sztuk po arkuszu (-1 - za mało ofert).
func quote_buy(id: String, qty: int) -> int:
	return _walk(book(id)["sell"].filter(func(level: Array) -> bool: return level[2] != "Ty"), qty, 1.0)


## Zysk ze sprzedaży `qty` sztuk po arkuszu, po podatku (-1 - za mało ofert).
func quote_sell(id: String, qty: int) -> int:
	return _walk(book(id)["buy"].filter(func(level: Array) -> bool: return level[2] != "Ty"), qty, 1.0 - TAX)


func _walk(levels: Array, qty: int, factor: float) -> int:
	var total := 0.0
	var left := qty
	for level: Array in levels:
		var take := mini(left, int(level[1]))
		total += take * int(level[0])
		left -= take
		if left == 0:
			return roundi(total * factor)
	return -1


## Duże transakcje przesuwają cenę (kupno w górę, sprzedaż w dół).
func _push(id: String, qty: int, sign: float) -> void:
	var base := float(COMMODITIES[id])
	var depth := maxf(1.0, 400.0 / maxf(base, 1.0)) * 20.0 * volume()
	prices[id] = clampf(prices[id] * (1.0 + sign * 0.04 * minf(qty / depth, 3.0)), base * 0.4, base * 3.0)
	_book_seed += 1


# ---------------------------------------------------------------- zamówienia
## Wystawienie sprzedaży: towar z plecaka zostaje na rynku. "" albo powód odmowy.
func place_sell(id: String, qty: int, price: int) -> String:
	if qty <= 0 or price <= 0:
		return Lang.t("Podaj ilość i cenę.")
	if _player.inventory.count_of(id) < qty:
		return Lang.t("Nie masz tyle w plecaku.")
	_player.inventory.remove_item(id, qty)
	orders.append({"kind": "sell", "id": id, "qty": qty, "left": qty, "price": price, "ready": 0})
	changed.emit()
	return ""


## Zamówienie kupna: złoto za całość zostaje na rynku.
func place_buy(id: String, qty: int, price: int) -> String:
	if qty <= 0 or price <= 0:
		return Lang.t("Podaj ilość i cenę.")
	if _player.stats.gold < qty * price:
		return Lang.t("Za mało złota (%d zł).") % (qty * price)
	_player.stats.add_gold(-qty * price)
	orders.append({"kind": "buy", "id": id, "qty": qty, "left": qty, "price": price, "ready": 0})
	changed.emit()
	return ""


## Wycofanie zamówienia: niesprzedany towar albo niewydane złoto wraca, kupione rzeczy trafiają do plecaka.
func cancel(index: int) -> void:
	var order: Dictionary = orders[index]
	if order["kind"] == "sell":
		_deliver(order["id"], int(order["left"]))
	else:
		_player.stats.add_gold(int(order["left"]) * int(order["price"]))
		_deliver(order["id"], int(order["ready"]))
	orders.remove_at(index)
	changed.emit()


## Odbiór kupionych rzeczy, które nie zmieściły się wcześniej.
func collect(index: int) -> void:
	var order: Dictionary = orders[index]
	order["ready"] = _deliver(order["id"], int(order["ready"]))
	if order["left"] == 0 and order["ready"] == 0:
		orders.remove_at(index)
	changed.emit()


## Do plecaka, a nadmiar do magazynu; zwraca, ile się nie zmieściło.
func _deliver(id: String, qty: int) -> int:
	if qty <= 0:
		return 0
	var left := _player.inventory.add_item(id, qty)
	if left > 0:
		left = _player.storage.add_item(id, left)
	return left


# ---------------------------------------------------------------- przedmioty
## Oferty przedmiotów od podróżników: broń, zbroje, biżuteria i kamienie na ich poziomach, rzadko legendy.
## all - wszystkie oferty podróżników od nowa (do listing_target); inaczej dochodzi najwyżej `limit` nowych.
func refresh_listings(all := false, limit := 1000) -> void:
	if all:
		for listing: Dictionary in listings:
			if not listing.get("mine", false):
				Items.generated.erase(listing["id"])
		listings = listings.filter(func(l: Dictionary) -> bool: return l.get("mine", false))
	var names := _names()
	var travelers: Array[Dictionary] = _player.travelers.active() if _player != null else []
	var count := listings.filter(func(l: Dictionary) -> bool: return not l.get("mine", false)).size()
	var target := listing_target()
	while count < target and limit > 0:
		var level := int(travelers.pick_random()["level"]) if not travelers.is_empty() else 10
		var id := _roll_item(level)
		listings.append({"id": id, "price": roundi(fair_price(id) * randf_range(PRICE_SPREAD.x, PRICE_SPREAD.y)),
				"seller": names.pick_random(), "mine": false, "age": 0})
		count += 1
		limit -= 1
	changed.emit()


## Przedmiot od podróżnika: większy rynek (silniejsi podróżnicy) - częściej rzadkie i legendy.
func _roll_item(level: int) -> String:
	var f := size_factor()
	var roll := randf()
	if roll < 0.12 and Gems.unlocked:
		return Gems.roll("", Gems.cut_for_level(level + 6))
	if roll < 0.14 + 0.08 * f and level >= 20:
		return Loot.legendary_at_level(Dungeons.VAULT_LEGENDS.pick_random(), level)
	return Loot.drop_at_level(level, 0.6, Loot.RARE if randf() < 0.35 + 0.35 * f else Loot.MAGIC)


## Uczciwa cena przedmiotu na rynku: z ceny skupu (rzadkie i legendy dużo drożej).
static func fair_price(id: String) -> int:
	var item := Items.get_data(id)
	var factor: float = {"common": 3.0, "magic": 4.0, "rare": 6.0, "legendary": 10.0}.get(item.get("rarity", "common"), 3.0)
	return maxi(10, roundi(float(item.get("sell_price", 10)) * factor))


func buy_listing(index: int) -> String:
	var listing: Dictionary = listings[index]
	if listing.get("mine", false):
		return Lang.t("To twoja oferta.")
	if _player.stats.gold < int(listing["price"]):
		return Lang.t("Za mało złota.")
	if _player.inventory.add_item(listing["id"], 1) > 0:
		return Lang.t("Plecak jest pełny.")
	_player.stats.add_gold(-int(listing["price"]))
	listings.remove_at(index)
	changed.emit()
	return ""


## Wystawienie przedmiotu z plecaka (pole `index`) za `price` złota.
func list_item(index: int, price: int) -> String:
	var slot: Dictionary = _player.inventory.slots[index]
	if slot.is_empty() or price <= 0:
		return Lang.t("Wybierz przedmiot i cenę.")
	if not (Items.is_equippable(slot["id"]) or Gems.is_gem(slot["id"]) or Essences.is_essence(slot["id"])):
		return Lang.t("Tu wystawia się broń, zbroje, biżuterię i kamienie - towary sprzedasz w zakładce Towary.")
	_player.inventory.take_one(index)
	listings.append({"id": slot["id"], "enchant": int(slot.get("enchant", 0)), "price": price, "seller": "Ty", "mine": true})
	changed.emit()
	return ""


func unlist(index: int) -> String:
	var listing: Dictionary = listings[index]
	if _player.inventory.add_item(listing["id"], 1, int(listing.get("enchant", 0))) > 0:
		return Lang.t("Plecak jest pełny.")
	listings.remove_at(index)
	changed.emit()
	return ""


# ---------------------------------------------------------------- czas
## Ceny błądzą wokół bazowych, podróżnicy realizują zamówienia gracza i kupują jego przedmioty.
func tick() -> void:
	ensure()
	for id: String in COMMODITIES:
		var base := float(COMMODITIES[id])
		var price: float = prices[id]
		price += (base - price) * 0.06 + price * randf_range(-0.05, 0.05)
		prices[id] = clampf(price, base * 0.4, base * 3.0)
		var past: Array = history[id]
		past.append(prices[id])
		if past.size() > HISTORY:
			past.pop_front()
	_book_seed += 1
	# świeże oferty szybko znikają - wykupują je inni podróżnicy
	for id: String in fresh.keys():
		var list: Array = (fresh[id] as Array).filter(func(_e: Array) -> bool: return randf() >= FRESH_SOLD_CHANCE)
		if list.is_empty():
			fresh.erase(id)
		else:
			fresh[id] = list
	for order: Dictionary in orders:
		if order["left"] <= 0:
			continue
		var market: float = prices[order["id"]]
		var price := float(order["price"])
		# im lepsza cena dla podróżników, tym szybciej (sprzedaż taniej niż rynek, kupno drożej)
		var edge := (market - price) / market if order["kind"] == "sell" else (price - market) / market
		var chance := clampf(0.35 + edge * 3.0, 0.0, 0.95)
		if randf() >= chance:
			continue
		var filled := mini(int(order["left"]), maxi(1, roundi(int(order["qty"]) * randf_range(0.15, 0.5))))
		order["left"] = int(order["left"]) - filled
		if order["kind"] == "sell":
			_player.stats.add_gold(roundi(filled * price * (1.0 - TAX)))
		else:
			order["ready"] = int(order["ready"]) + filled
	# zakończone zamówienia: kupione rzeczy do plecaka, puste wpisy znikają
	for order: Dictionary in orders:
		if order["kind"] == "buy" and order["ready"] > 0:
			order["ready"] = _deliver(order["id"], int(order["ready"]))
	orders = orders.filter(func(o: Dictionary) -> bool: return o["left"] > 0 or o["ready"] > 0)
	# przedmioty gracza: im taniej względem uczciwej ceny i im więcej kupujących, tym szybciej się sprzedają
	var buyers := demand()
	for listing: Dictionary in listings.duplicate():
		if not listing.get("mine", false):
			continue
		var ratio := float(listing["price"]) / float(fair_price(listing["id"]))
		if randf() < clampf((0.5 - (ratio - 1.0) * 0.6) * buyers, 0.02, 0.95):
			_player.stats.add_gold(roundi(float(listing["price"]) * (1.0 - TAX)))
			Items.generated.erase(listing["id"])
			listings.erase(listing)
	# oferty podróżników: okazje szybko wykupują inni, przepłacone wiszą (stare w końcu znikają)
	for listing: Dictionary in listings.duplicate():
		if listing.get("mine", false):
			continue
		listing["age"] = int(listing.get("age", 0)) + 1
		var chance := clampf(0.02 + deal_of(listing) * 1.0, 0.005, 0.85) * buyers
		if int(listing["age"]) > STALE_TICKS:
			chance = maxf(chance, 0.15)
		if randf() < chance:
			Items.generated.erase(listing["id"])
			listings.erase(listing)
	refresh_listings(false, NEW_LISTINGS + roundi(size_factor() * 4.0))
	changed.emit()


func get_save_data() -> Dictionary:
	var ids: Array = listings.map(func(l: Dictionary) -> String: return l["id"])
	return {"prices": prices.duplicate(), "history": history.duplicate(true), "orders": orders.duplicate(true),
			"listings": listings.duplicate(true), "items": Loot.export_used(ids), "fresh": fresh.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	Loot.import(data.get("items", {}))
	prices.clear()
	history.clear()
	for id: String in data.get("prices", {}):
		if COMMODITIES.has(id):
			prices[id] = float(data["prices"][id])
			history[id] = (data.get("history", {}).get(id, [prices[id]]) as Array).map(func(v) -> float: return float(v))
	fresh.clear()
	for id: String in data.get("fresh", {}):
		if COMMODITIES.has(id):
			fresh[id] = (data["fresh"][id] as Array).map(func(e: Array) -> Array: return [int(e[0]), str(e[1])])
	orders.clear()
	for order: Dictionary in data.get("orders", []):
		for key in ["qty", "left", "price", "ready"]:
			order[key] = int(order[key])
		orders.append(order)
	listings.clear()
	for listing: Dictionary in data.get("listings", []):
		if not Items.get_data(listing["id"]).is_empty():
			listing["price"] = int(listing["price"])
			listing["enchant"] = int(listing.get("enchant", 0))
			listings.append(listing)
	changed.emit()
