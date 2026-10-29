extends SceneTree
## Test plecaka: przenoszenie, łączenie stosów, wyrzucanie, sortowanie (z mapą przeniesień).

func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	var inv: Node = load("res://scripts/inventory.gd").new()
	inv.slot_count = 12
	root.add_child(inv)
	var moves := []
	inv.rearranged.connect(func(m): moves.append(m))
	inv.add_item("health_potion", 3)
	var sword: String = loot.generate("iron_sword", "rare", 30)
	var ring: String = loot.generate("copper_ring", "legendary" if false else "magic", 20)
	var helm: String = loot.generate("iron_helmet", "common", 10)
	inv.add_item("wood", 40)
	inv.add_item(ring, 1)
	inv.add_item(sword, 1, 5)
	inv.add_item(helm, 1)
	inv.slots[8] = {"id": "health_potion", "count": 2}
	inv.slots[9] = {"id": "weapon_stone", "count": 4}
	inv.slots[10] = {"id": "pouch", "count": 1}
	# zamiana miejscami
	inv.move(0, 5)
	_check(inv.slots[5]["id"] == "health_potion" and inv.slots[0].is_empty() and moves[-1] == {0: 5, 5: 0}, "przeniesienie na puste")
	inv.move(1, 2)
	_check(inv.slots[1]["id"] == ring and inv.slots[2]["id"] == "wood", "zamiana miejscami")
	# łączenie stosów
	inv.move(8, 5)
	_check(inv.slots[5]["count"] == 5 and inv.slots[8].is_empty(), "łączenie stosu mikstur")
	# wyrzucanie
	inv.discard(9)
	_check(inv.slots[9].is_empty(), "wyrzucenie stosu")
	# sortowanie
	inv.slots[11] = {"id": "health_potion", "count": 1}
	var sword_at := -1
	for i in inv.slots.size():
		if inv.slots[i].get("id") == sword:
			sword_at = i
	inv.sort()
	var order = inv.slots.map(func(s): return s.get("id", "-"))
	print("  po sortowaniu: ", order)
	_check(inv.slots[0]["id"] == sword and inv.slots[0]["enchant"] == 5, "broń pierwsza (z zaklęciem)")
	_check(inv.slots[1]["id"] == helm and inv.slots[2]["id"] == ring, "hełm, potem pierścień")
	_check(inv.slots[3]["id"] == "pouch" and inv.slots[4]["id"] == "health_potion" and inv.slots[4]["count"] == 6, "torba, mikstury złączone (6)")
	_check(inv.slots[5]["id"] == "wood" and inv.slots[6].is_empty(), "reszta na końcu, potem puste")
	_check(moves[-1].get(sword_at) == 0, "mapa przeniesień: miecz %d -> 0" % sword_at)
	quit()
