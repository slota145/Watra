extends SceneTree
## Skarbnik w lochach Watry (mechanika "skarbnik", scripts/skarbnik.gd i scripts/skarbnik_offer.gd): oferta (rodzaje
## nagród), wzmocnienie (tiery w górę do sufitu, więcej run i kamieni, lepszy szlif, ostatnie - legendy), przelosowanie
## (te same tiery, nowe rodzaje), księga ofert (zagrożona przepada), a w lochu: okno oferty, Weź, fale z bram,
## wygrana (oferta czeka u gracza i w zapisie), śmierć w falach (oferta przepada), Przelosuj za Kości Skarbnika.

var _world: Node
var _frame := 0
var _fails := 0
var _D
var _O
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_D = load("res://scripts/dungeons.gd")
	_O = load("res://scripts/skarbnik_offer.gd")
	_O.ledger_path = "user://test_skarbnik.json"
	if FileAccess.file_exists(_O.ledger_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_O.ledger_path))
	_rng.seed = 7
	_check_offer()
	var config: Dictionary = _D.config("catacombs", 7, [], 4242)
	config["mechanics"] = ["skarbnik"]
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _items(offer: Dictionary) -> Array:
	return (offer["rewards"] as Array).filter(func(r: Dictionary) -> bool: return r["kind"] == "item")


func _first(offer: Dictionary, kind: String) -> Dictionary:
	for r: Dictionary in offer["rewards"]:
		if r["kind"] == kind:
			return r
	return {}


func _check_offer() -> void:
	var Gems = load("res://scripts/gems.gd")
	Gems.unlocked = true
	var offer: Dictionary = _O.roll(41, 7, _rng)
	var rewards: Array = offer["rewards"]
	check("oferta: 3-4 nagrody, pierwsza to przedmiot", rewards.size() >= _D.SKA_OFFER and rewards.size() <= _D.SKA_OFFER + 1
			and rewards[0]["kind"] == "item" and offer["step"] == 0, str(rewards.map(func(r: Dictionary) -> String: return r["kind"])))
	check("sufit tierów: poziom 43 - T%d, poziom 95 - T1" % _O.ceiling_tier(43), _O.ceiling_tier(43) > 1 and _O.ceiling_tier(95) == 1)
	# wszystkie rodzaje nagród naraz
	offer["rewards"] = [rewards[0], _O._roll_reward("rune", offer, _rng), _O._roll_reward("stone", offer, _rng),
			_O._roll_reward("gem", offer, _rng)]
	var item: Dictionary = offer["rewards"][0]["recipe"]
	var before_tiers: Dictionary = item["tiers"].duplicate()
	var rune: Dictionary = _first(offer, "rune")
	var gem: Dictionary = _first(offer, "gem")
	var cut := int(gem["recipe"]["cut"])
	var runes_before: int = _O.count_of(rune, 0)
	_O.strengthen(offer, _rng)
	var ceiling: int = _O.ceiling_tier(int(item["level"]))
	var tiers_ok := true
	for stat: String in before_tiers:
		if int(item["tiers"][stat]) != maxi(ceiling, int(before_tiers[stat]) - _D.SKA_TIER_STEP):
			tiers_ok = false
	check("wzmocnienie: tiery premii +%d (do sufitu), te same rodzaje" % _D.SKA_TIER_STEP, tiers_ok
			and item["tiers"].keys() == before_tiers.keys() and offer["step"] == 1, "%s -> %s" % [before_tiers, item["tiers"]])
	check("wzmocnienie: więcej run i lepszy szlif", _O.count_of(rune, 1) > runes_before
			and int(gem["recipe"]["cut"]) == mini(cut + 1, 4), "%d -> %d" % [runes_before, _O.count_of(rune, 1)])
	# przelosowanie
	var tiers_sorted: Array = item["tiers"].values()
	tiers_sorted.sort()
	var old_rune: String = rune["id"]
	var old_kind: String = gem["recipe"]["kind"]
	_O.reroll(offer, _rng)
	item = offer["rewards"][0]["recipe"]
	var after_sorted: Array = item["tiers"].values()
	after_sorted.sort()
	check("przelosowanie: te same tiery, inny kamień szlachetny i runa", after_sorted == tiers_sorted
			and _first(offer, "gem")["recipe"]["kind"] != old_kind and _first(offer, "rune")["id"] != old_rune)
	# aż do szczytu
	for i in _D.SKA_MAX_STEPS:
		_O.strengthen(offer, _rng)
	item = offer["rewards"][0]["recipe"]
	var Items = load("res://scripts/items.gd")
	var all_top: bool = item["tiers"].values().all(func(t) -> bool: return int(t) == _O.ceiling_tier(int(item["level"])))
	var shown: Array = _O.shown(offer["rewards"][0], offer["step"])
	check("ostatnie wzmocnienie: premie na suficie i legenda tego samego rodzaju", offer["step"] == _D.SKA_MAX_STEPS
			and not _O.can_strengthen(offer) and item["quality"] == "legendary" and all_top
			and Items.get_data(shown[0])["rarity"] == "legendary", "%s %s" % [item["base"], item["tiers"]])
	# księga ofert
	_O.persist(offer, true)
	check("zagrożona oferta przepada przy wczytaniu", _O.restore(offer["uid"]).is_empty() and not _O._read().has(offer["uid"]))
	_O.persist(offer, false)
	var back: Dictionary = _O.restore(offer["uid"])
	check("zabezpieczona oferta wraca z księgi", back.get("uid", "") == offer["uid"] and int(back["step"]) == _D.SKA_MAX_STEPS)
	_O.forget(offer["uid"])
	check("wzięta oferta znika z księgi", _O.restore(offer["uid"]).is_empty())


func _process(_d: float) -> bool:
	if _world == null or not _world.is_inside_tree():
		return false
	_frame += 1
	if _frame == 5:
		_check_dungeon()
		print("WYNIK: %s" % ("wszystko OK" if _fails == 0 else "%d FAIL" % _fails))
		quit(1 if _fails > 0 else 0)
	return false


func _check_dungeon() -> void:
	var d = _world._dungeon
	var player = _world.player
	var spirit = d.skarbniki[0] if d.skarbniki.size() > 0 else null
	check("Skarbnik w lochu", spirit != null and spirit.state == "idle" and spirit.can_harvest())
	if spirit == null:
		return
	spirit.harvest(spirit.global_position)
	check("F - okno oferty", _world.hud.skarbnik_window.visible and not spirit.offer.is_empty())
	# Weź
	spirit.take(0)
	check("Weź: nagroda w plecaku, Skarbnik znika", spirit.state == "gone"
			and player.inventory.slots.any(func(s: Dictionary) -> bool: return not s.is_empty() and s["id"].begins_with("gen_")))
	# drugi Skarbnik: wzmocnienie i fale
	spirit = d._add_skarbnik(d.rooms[1])
	spirit.harvest(spirit.global_position)
	var uid: String = spirit.offer["uid"]
	spirit.strengthen()
	check("Wzmocnij: fale, oferta zagrożona w księdze", spirit.state == "waves" and spirit.waves == _D.SKA_WAVES[0]
			and _O._read()[uid]["risk"] == true and player.skarbnik_uid == uid and player.skarbnik_offer.is_empty())
	for i in 40:
		spirit._spawn_timer = 0.0
		spirit._process(0.0)
	var marked: bool = spirit.attackers.all(func(e: Array) -> bool: return e[0].has_meta("skarbnik"))
	check("wrogowie z bram, najwyżej %d naraz, poziom wyższy" % spirit.alive_cap(), spirit.attackers.size() == spirit.alive_cap()
			and marked and spirit.gates.size() >= 2 and spirit.attackers[0][0].level == d.level + _D.SKA_LEVEL_PER_STEP,
			"%d żywych, %d bram" % [spirit.attackers.size(), spirit.gates.size()])
	# wybij całą falę
	for round in 20:
		for entry: Array in spirit.attackers:
			entry[0].take_damage(99999999, spirit.global_position)
		spirit._spawn_timer = 0.0
		spirit._process(0.0)
		if spirit.state != "waves":
			break
	check("wygrana: oferta zabezpieczona, czeka u gracza", spirit.state == "gone" and _O._read()[uid]["risk"] == false
			and player.skarbnik_offer.get("uid", "") == uid and int(player.skarbnik_offer["step"]) == 1, "zabici %d" % spirit.kills)
	var saved: Dictionary = player.get_save_data()
	check("zapis gry trzyma identyfikator oferty", saved.get("skarbnik", "") == uid)
	# następny Skarbnik pokazuje czekającą ofertę; Przelosuj za Kości
	var third = d._add_skarbnik(d.rooms[2])
	check("następny Skarbnik ma czekającą ofertę", third.current_offer()["uid"] == uid)
	check("Przelosuj bez Kości - nie", not third.reroll())
	player.inventory.add_item(_D.SKA_BONES, 1)
	check("Przelosuj za Kości Skarbnika", third.reroll() and third.state == "waves" and player.inventory.count_of(_D.SKA_BONES) == 0
			and int(third.offer["step"]) == 1)
	# śmierć w falach
	third._on_player_died()
	check("śmierć w falach: oferta przepada", third.state == "gone" and not _O._read().has(uid) and player.skarbnik_offer.is_empty()
			and third.attackers.is_empty())
	player.load_save_data(saved)
	check("wczytanie starszego zapisu nie przywraca straconej oferty", player.skarbnik_offer.is_empty() and player.skarbnik_uid == "")
