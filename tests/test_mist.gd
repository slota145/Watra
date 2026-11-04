extends SceneTree
## Mgła Nawii w lochach Watry (mechanika "mist", scripts/nawia_mist.gd): Mglisty Słup w lochu, dotknięcie wypuszcza
## Mgłę (gęstość 1, potwory silniejsze, zjawy wokół gracza), gęstnienie co minutę (siła, cechy elit co 3 stopnie),
## pula za zabitych, koniec przy Słupie (Skrzynia Mgły: przedmioty, kamienie wsparcia, krzesiwa), śmierć (połowa
## puli), wyjście portalem (Skrzynia zostaje w stanie lochu), Wielkie Krzesiwo dopiero od gęstości 8, poziom kamieni.

var _world: Node
var _frame := 0
var _fails := 0
var _D
var _M
var _S


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_D = load("res://scripts/dungeons.gd")
	var config: Dictionary = _D.config("catacombs", 7, [], 4242)
	config["mechanics"] = ["mist"]
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _check_data() -> void:
	check("Mgła w puli mechanik (waga jak inne duże)", _D.MECHANICS.has("mist") and _D.MECHANICS["mist"]["weight"] == 5.0)
	check("siła i łup rosną z gęstością", is_equal_approx(_D.mist_power(10), 1.8) and is_equal_approx(_D.mist_loot(10), 2.5))
	check("więcej zjaw przy większej gęstości, sufit", _D.mist_wraiths(10, 7) > _D.mist_wraiths(1, 7)
			and _D.mist_wraiths(10, 17) <= _D.MIST_WRAITHS_MAX)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var low := 0
	var high := 0
	for i in 50:
		low = maxi(low, _D.mist_support_level(1, 1, rng))
		high = maxi(high, _D.mist_support_level(17, 10, rng))
	check("poziom kamieni ze stopnia lochu i gęstości", low <= 3 and high == _D.MIST_LEVEL_MAX, "%d / %d" % [low, high])
	var pool := {"items": 0.0, "gold": 0.0, "supports": 0.0, "flints": 0.0, "great": 0.0}
	for i in 100:
		_M.add_kill(pool, 7, 40)
	check("Wielkie Krzesiwa dopiero od gęstości %d" % _D.MIST_GREAT_FROM, pool["great"] == 0.0 and pool["flints"] > 0.0)
	var dense := {"items": 0.0, "gold": 0.0, "supports": 0.0, "flints": 0.0, "great": 0.0}
	for i in 100:
		_M.add_kill(dense, 10, 40)
	check("gęstsza Mgła - większa pula", dense["items"] > pool["items"] and dense["supports"] > pool["supports"]
			and dense["great"] > 0.0)


func _process(_d: float) -> bool:
	if _world == null or not _world.is_inside_tree():
		return false
	_frame += 1
	if _frame == 5:
		# skrypt Słupa dopiero teraz - korzysta z autoloadów (Sfx), których w _initialize jeszcze nie ma
		_M = load("res://scripts/nawia_mist.gd")
		_S = load("res://scripts/supports.gd")
		_check_data()
		_check_dungeon()
		print("WYNIK: %s" % ("wszystko OK" if _fails == 0 else "%d FAIL" % _fails))
		quit(1 if _fails > 0 else 0)
	return false


func _count(prefix: String) -> int:
	var total := 0
	for pickup in _world.get_tree().get_nodes_in_group("pickups"):
		if "item_id" in pickup and not pickup.is_queued_for_deletion() and str(pickup.item_id).begins_with(prefix):
			total += pickup.amount
	return total


func _supports() -> int:
	var total := 0
	for pickup in _world.get_tree().get_nodes_in_group("pickups"):
		if "item_id" in pickup and not pickup.is_queued_for_deletion() and _S.is_support(pickup.item_id):
			total += 1
	return total


func _check_dungeon() -> void:
	var d = _world._dungeon
	var pillar = d.mists[0] if d.mists.size() > 0 else null
	check("Mglisty Słup w lochu", pillar != null and pillar.state == "idle" and pillar.can_harvest())
	if pillar == null:
		return
	# siła zwykłego potwora przed i po Mgle
	var monster = null
	for value in _world._live_goblins.values():
		if not value.is_in_group("bosses"):
			monster = value
			break
	var health_before: int = monster.max_health
	pillar.harvest(pillar.global_position)
	check("dotknięcie: Mgła, gęstość 1, pasek na ekranie", pillar.state == "open" and pillar.density == 1
			and pillar._bar != null and pillar._fog != null)
	check("potwory silniejsze o %d%%" % roundi(_D.MIST_POWER * 100), monster.max_health == roundi(health_before * _D.mist_power(1)),
			"%d -> %d" % [health_before, monster.max_health])
	# gęstnienie
	pillar._elapsed = _D.MIST_STEP * 3.0 + 0.1
	pillar._process(0.0)
	check("po 3 minutach gęstość 4 i cecha elit", pillar.density == 4 and pillar.traits.size() == 1, "%d, %s" % [pillar.density, pillar.traits])
	check("siła potworów rośnie z gęstością", monster.max_health == roundi(health_before * _D.mist_power(4)),
			"%d" % monster.max_health)
	# zjawy wokół gracza
	for i in 20:
		pillar._spawn_timer = 0.0
		pillar._process(0.0)
	check("zjawy wokół gracza", pillar.wraiths.size() > 0, "%d" % pillar.wraiths.size())
	var wraith = pillar.wraiths[0][0] if pillar.wraiths.size() > 0 else null
	check("zjawa ma siłę Mgły", wraith != null and is_equal_approx(float(wraith.get_meta("mist", 1.0)), _D.mist_power(4)))
	# pula za zabitych
	var before: float = pillar.pool["items"]
	if monster != null:
		_world.goblin_died.emit(monster)
	check("zabity wróg dokłada do puli", pillar.pool["items"] > before and pillar.kills == 1)
	# koniec przy Słupie: Skrzynia Mgły
	pillar.pool = {"items": 5.0, "gold": 1000.0, "supports": 3.0, "flints": 4.0, "great": 1.0}
	var gold_before := _count("gold")
	pillar.harvest(pillar.global_position)
	check("Słup: koniec Mgły, zjawy znikają, pasek znika", pillar.state == "closed" and pillar.wraiths.is_empty()
			and pillar._bar == null and not pillar.can_harvest())
	check("potwory wracają do zwykłej siły", monster.max_health == health_before, "%d / %d" % [monster.max_health, health_before])
	check("Skrzynia Mgły: kamienie wsparcia, krzesiwa, wielkie krzesiwo, złoto", _supports() == 3 and _count(_S.FLINT) == 4
			and _count(_S.GREAT_FLINT) == 1 and _count("gold") > gold_before,
			"%d kamieni, %d krzesiw, %d wielkich" % [_supports(), _count(_S.FLINT), _count(_S.GREAT_FLINT)])
	# śmierć: połowa puli
	var second = d._add_mist(d.rooms[1])
	second.open()
	second.pool = {"items": 0.0, "gold": 0.0, "supports": 0.0, "flints": 10.0, "great": 0.0}
	var flints_before := _count(_S.FLINT)
	_world.player.died.emit()
	check("śmierć: Mgła się kończy, połowa puli", second.state == "closed" and _count(_S.FLINT) - flints_before == 5,
			"%d" % (_count(_S.FLINT) - flints_before))
	# portal do miasta: Skrzynia Mgły na ziemi w stanie lochu
	var third = d._add_mist(d.rooms[2])
	third.open()
	third.pool = {"items": 0.0, "gold": 0.0, "supports": 0.0, "flints": 7.0, "great": 0.0}
	d.end_mists("portal")
	var state: Dictionary = d.portal_state(_world.player.global_position)
	var saved := 0
	for entry: Array in state["items"]:
		if entry[0] == _S.FLINT:
			saved += int(entry[1])
	check("portal: Mgła kończy się, łup zostaje w stanie lochu", third.state == "closed" and saved >= 7
			and (state["spent"]["mists"] as Array).size() == 3, "%d krzesiw, %s" % [saved, state["spent"]["mists"]])
	# Wielkie Krzesiwo z bogów
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var found := 0
	for i in 200:
		for reward: Array in load("res://scripts/pinnacles.gd").vault_rewards(80, rng):
			if reward[0] == _S.GREAT_FLINT:
				found += 1
	check("Wielkie Krzesiwo czasem w skarbcu boga", found > 10 and found < 60, "%d / 200" % found)
