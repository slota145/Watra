class_name QuestLog
extends Node
## Zadania gracza: stan, postęp i lista śledzonych (pokazywanych pod minimapą).

signal changed
## Zadanie zostało wykonane - można wrócić po nagrodę.
signal quest_ready(id: String)
## Nagroda odebrana - zadanie zakończone.
signal quest_done(id: String)

## id -> stan (brak wpisu = do przyjęcia)
var states := {}
var progress := {}
var tracked: Array[String] = []
## Zlecenia z tablicy ogłoszeń: definicje przyjętych (id -> dane) i liczba wykonanych.
var bounty_defs := {}
var bounties_done := 0
var _bounty_serial := 0


func state_of(id: String) -> String:
	return states.get(id, Quests.STATE_AVAILABLE)


func progress_of(id: String) -> int:
	return progress.get(id, 0)


func accept(id: String) -> void:
	if state_of(id) != Quests.STATE_AVAILABLE:
		return
	states[id] = Quests.STATE_ACTIVE
	progress[id] = 0
	if tracked.size() < Quests.MAX_TRACKED:
		tracked.append(id)
	changed.emit()


## Zadania zbierackie: postęp = ile sztuk gracz ma (plecak + magazyn); `count_item(id) -> int`.
## Jeśli gracz pozbędzie się surowców, zadanie wraca z "do odebrania" do "w toku".
func update_gathered(count_item: Callable) -> void:
	var updated := false
	for id: String in states:
		if not Quests.is_gather(id) or states[id] not in [Quests.STATE_ACTIVE, Quests.STATE_READY]:
			continue
		var quest := Quests.get_data(id)
		var have := 0
		var needed: Dictionary = Quests.requirements(id)
		for item: String in needed:
			have += mini(int(count_item.call(item)), int(needed[item]))
		var state: String = Quests.STATE_READY if have >= quest["count"] else Quests.STATE_ACTIVE
		if have == progress_of(id) and state == states[id]:
			continue
		progress[id] = have
		updated = true
		if state != states[id]:
			states[id] = state
			if state == Quests.STATE_READY:
				quest_ready.emit(id)
	if updated:
		changed.emit()


## Wywoływane po pokonaniu potwora danego rodzaju (Goblin.quest_kind).
func on_enemy_killed(kind: String) -> void:
	var updated := false
	for id: String in states:
		if states[id] != Quests.STATE_ACTIVE or Quests.is_gather(id) or Quests.get_data(id)["target"] != kind:
			continue
		progress[id] = progress_of(id) + 1
		updated = true
		if progress[id] >= Quests.get_data(id)["count"]:
			states[id] = Quests.STATE_READY
			quest_ready.emit(id)
	if updated:
		changed.emit()


## Odbiór nagrody u zleceniodawcy.
func turn_in(id: String, stats: CharacterStats) -> bool:
	if state_of(id) != Quests.STATE_READY:
		return false
	var quest := Quests.get_data(id)
	states[id] = Quests.STATE_DONE
	tracked.erase(id)
	stats.add_gold(quest["gold"])
	stats.add_xp(quest["xp"])
	changed.emit()
	quest_done.emit(id)
	return true


func is_tracked(id: String) -> bool:
	return id in tracked


## Włącza/wyłącza śledzenie (zwraca false, gdy limit śledzonych jest pełny).
func toggle_track(id: String) -> bool:
	if is_tracked(id):
		tracked.erase(id)
	elif tracked.size() < Quests.MAX_TRACKED and state_of(id) in [Quests.STATE_ACTIVE, Quests.STATE_READY]:
		tracked.append(id)
	else:
		return false
	changed.emit()
	return true


func get_save_data() -> Dictionary:
	return {"states": states.duplicate(), "progress": progress.duplicate(), "tracked": tracked.duplicate(),
			"bounties": {"defs": bounty_defs.duplicate(true), "done": bounties_done, "serial": _bounty_serial}}


# ---------------------------------------------------------------- zlecenia z tablicy
## Przyjęte (w toku albo do odebrania) zlecenie - "" gdy żadnego.
func active_bounty() -> String:
	for id: String in bounty_defs:
		if state_of(id) in [Quests.STATE_ACTIVE, Quests.STATE_READY]:
			return id
	return ""


func take_bounty(definition: Dictionary) -> String:
	if active_bounty() != "":
		return ""
	_bounty_serial += 1
	var id := "bounty_%d" % _bounty_serial
	bounty_defs[id] = definition
	Quests.dynamic[id] = definition
	accept(id)
	return id


## Odbiór nagrody za zlecenie: złoto i exp (turn_in), przedmioty do plecaka (nadmiar do magazynu).
func finish_bounty(id: String, player: Player) -> bool:
	var definition: Dictionary = bounty_defs.get(id, {})
	if definition.is_empty() or not turn_in(id, player.stats):
		return false
	for item: String in definition["reward_items"]:
		var left := player.inventory.add_item(item, int(definition["reward_items"][item]))
		if left > 0:
			player.storage.add_item(item, left)
	bounties_done += 1
	_forget_bounty(id)
	changed.emit()
	return true


func abandon_bounty(id: String) -> void:
	_forget_bounty(id)
	changed.emit()


func _forget_bounty(id: String) -> void:
	bounty_defs.erase(id)
	Quests.dynamic.erase(id)
	states.erase(id)
	progress.erase(id)
	tracked.erase(id)


func load_save_data(data: Dictionary) -> void:
	states.clear()
	progress.clear()
	tracked.clear()
	# zlecenia z tablicy trzeba zarejestrować, zanim wczytamy ich stan
	var bounties: Dictionary = data.get("bounties", {})
	bounty_defs = (bounties.get("defs", {}) as Dictionary).duplicate(true)
	bounties_done = int(bounties.get("done", 0))
	_bounty_serial = int(bounties.get("serial", 0))
	for id: String in bounty_defs:
		# JSON wczytuje liczby jako float - przywracamy całkowite
		var definition: Dictionary = bounty_defs[id]
		for key in ["count", "gold", "xp"]:
			definition[key] = int(definition[key])
		var items: Dictionary = definition["reward_items"]
		for item: String in items:
			items[item] = int(items[item])
		Quests.dynamic[id] = definition
	for id: String in data.get("states", {}):
		if not Quests.get_data(id).is_empty():
			states[id] = str(data["states"][id])
			progress[id] = int(data.get("progress", {}).get(id, 0))
	for id in data.get("tracked", []):
		if states.has(str(id)):
			tracked.append(str(id))
	changed.emit()
