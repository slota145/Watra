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
## Zdarzenia dla zadań głównych (MainQuests - warunek ["event", nazwa, n]): nazwa -> ile razy.
var events := {}
var bounties_done := 0
var _bounty_serial := 0
## Oferty wiszące na tablicy ogłoszeń (Bounties.generate) i czas (unix) ostatniego odświeżenia.
var board_offers: Array[Dictionary] = []
var board_time := 0


func state_of(id: String) -> String:
	return states.get(id, Quests.STATE_AVAILABLE)


func progress_of(id: String) -> int:
	return progress.get(id, 0)


func accept(id: String) -> void:
	if state_of(id) != Quests.STATE_AVAILABLE:
		return
	states[id] = Quests.STATE_ACTIVE
	progress[id] = 0
	if MainQuests.is_main(id):
		# zadanie główne zawsze śledzone, na górze listy
		tracked.push_front(id)
		if tracked.size() > Quests.MAX_TRACKED:
			tracked.pop_back()
	elif tracked.size() < Quests.MAX_TRACKED:
		tracked.append(id)
	changed.emit()


## Zdarzenie dla zadań głównych (np. pokonany strażnik lochu, otwarta encyklopedia).
func note_event(key: String, amount := 1) -> void:
	events[key] = int(events.get(key, 0)) + amount
	changed.emit()


## Zadania główne w toku: postęp i wykonanie wg warunku kroku (MainQuests.progress) - sprawdza gracz co chwilę.
func update_main(player: Player) -> void:
	var id := MainQuests.current(self)
	if id == "" or state_of(id) not in [Quests.STATE_ACTIVE, Quests.STATE_READY]:
		return
	var have: Array = MainQuests.progress(player, id)
	var state: String = Quests.STATE_READY if have[0] >= have[1] else Quests.STATE_ACTIVE
	if have[0] == progress_of(id) and state == states[id]:
		return
	progress[id] = have[0]
	if state != states[id]:
		states[id] = state
		if state == Quests.STATE_READY:
			quest_ready.emit(id)
	changed.emit()


## Starszy zapis bez zadań głównych: kroki do ostatniego, którego warunek jest już spełniony, zaliczają się same
## (bez nagród) - doświadczony gracz nie zaczyna od rozmowy z sołtysem, a lochy zostają otwarte.
func catch_up_main(player: Player) -> void:
	if MainQuests.CHAIN.any(func(id: String) -> bool: return states.has(id)):
		return
	var last := -1
	for i in MainQuests.CHAIN.size():
		var id: String = MainQuests.CHAIN[i]
		if MainQuests.DATA[id]["check"][0] != "talk" and MainQuests.satisfied(player, id):
			last = i
	for i in last + 1:
		states[MainQuests.CHAIN[i]] = Quests.STATE_DONE
	if last >= 0:
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
		if states[id] != Quests.STATE_ACTIVE or Quests.is_gather(id) or Quests.get_data(id).get("target", "") != kind:
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
	return {"states": states.duplicate(), "progress": progress.duplicate(), "tracked": tracked.duplicate(), "events": events.duplicate(),
			"bounties": {"defs": bounty_defs.duplicate(true), "done": bounties_done, "serial": _bounty_serial,
					"offers": board_offers.duplicate(true), "time": board_time}}


# ---------------------------------------------------------------- zlecenia z tablicy
## Przyjęte (w toku albo do odebrania) zlecenia.
func active_bounties() -> Array[String]:
	var result: Array[String] = []
	for id: String in bounty_defs:
		if state_of(id) in [Quests.STATE_ACTIVE, Quests.STATE_READY] and not bounty_defs[id].get("help", false):
			result.append(id)
	return result


## Pierwsze przyjęte zlecenie ("" - brak).
func active_bounty() -> String:
	var list := active_bounties()
	return list[0] if not list.is_empty() else ""


## Oferty na tablicy: nowe, gdy minęło Bounties.REFRESH sekund albo tablica jest pusta (liczba wg rangi gildii).
func refresh_board(player: Player, force := false) -> void:
	var now := int(Time.get_unix_time_from_system())
	if not force and not board_offers.is_empty() and now - board_time < Bounties.REFRESH:
		return
	board_offers = Bounties.generate(player, Bounties.offer_count(maxi(player.travelers.guild_rank, 1)), bounties_done)
	board_time = now
	changed.emit()


func take_bounty(definition: Dictionary) -> String:
	if active_bounties().size() >= Bounties.MAX_ACTIVE:
		return ""
	board_offers.erase(definition)
	_bounty_serial += 1
	var id := "bounty_%d" % _bounty_serial
	bounty_defs[id] = definition
	Quests.dynamic[id] = definition
	accept(id)
	return id


## Prośba drużyny o pomoc (zadanie z drużyną - World._process_party_offers): zapisana jak zlecenie, ale poza tablicą;
## po wykonaniu nagroda wypłaca się sama (Player._on_quest_ready).
func take_help(definition: Dictionary) -> String:
	definition["help"] = true
	_bounty_serial += 1
	var id := "bounty_help_%d" % _bounty_serial
	bounty_defs[id] = definition
	Quests.dynamic[id] = definition
	accept(id)
	return id


func active_help() -> String:
	for id: String in bounty_defs:
		if bounty_defs[id].get("help", false) and state_of(id) in [Quests.STATE_ACTIVE, Quests.STATE_READY]:
			return id
	return ""


## Odbiór nagrody za zlecenie: złoto i exp (turn_in), przedmioty do plecaka (nadmiar do magazynu).
func finish_bounty(id: String, player: Player) -> bool:
	var definition: Dictionary = bounty_defs.get(id, {})
	if definition.is_empty() or state_of(id) != Quests.STATE_READY:
		return false
	# zamówienie surowców: oddajemy je zleceniodawcy (po wypłacie - zabranie surowców cofnęłoby stan zlecenia)
	var needed: Dictionary = Quests.requirements(id) if definition.get("type", "") == "gather" else {}
	for item: String in needed:
		if player.count_owned(item) < int(needed[item]):
			return false
	if not turn_in(id, player.stats):
		return false
	for item: String in needed:
		player.take_owned(item, int(needed[item]))
	player.travelers.guild_fame += int(definition.get("fame", 0))
	if Bounties.gem_bonus(definition):
		var gem := Gems.roll("", Gems.cut_for_level(Levels.ZONES.get(definition.get("zone", "forest"), [1, 7])[1] + 4))
		if player.inventory.add_item(gem, 1) > 0:
			player.storage.add_item(gem, 1)
	for item: String in definition["reward_items"]:
		var left := player.inventory.add_item(item, int(definition["reward_items"][item]))
		if left > 0:
			player.storage.add_item(item, left)
	if not definition.get("help", false):
		bounties_done += 1
	_forget_bounty(id)
	changed.emit()
	return true


func abandon_bounty(id: String) -> void:
	_forget_bounty(id)
	changed.emit()


func _fix_bounty(definition: Dictionary) -> void:
	for key in ["count", "gold", "xp", "fame"]:
		if definition.has(key):
			definition[key] = int(definition[key])
	var items: Dictionary = definition.get("reward_items", {})
	for item: String in items:
		items[item] = int(items[item])


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
	events.clear()
	var saved_events: Dictionary = data.get("events", {})
	for key: String in saved_events:
		events[key] = int(saved_events[key])
	# zlecenia z tablicy trzeba zarejestrować, zanim wczytamy ich stan
	var bounties: Dictionary = data.get("bounties", {})
	bounty_defs = (bounties.get("defs", {}) as Dictionary).duplicate(true)
	bounties_done = int(bounties.get("done", 0))
	_bounty_serial = int(bounties.get("serial", 0))
	for id: String in bounty_defs:
		# JSON wczytuje liczby jako float - przywracamy całkowite
		_fix_bounty(bounty_defs[id])
		Quests.dynamic[id] = bounty_defs[id]
	board_offers.clear()
	for offer: Dictionary in bounties.get("offers", []):
		_fix_bounty(offer)
		board_offers.append(offer)
	board_time = int(bounties.get("time", 0))
	for id: String in data.get("states", {}):
		if not Quests.get_data(id).is_empty():
			states[id] = str(data["states"][id])
			progress[id] = int(data.get("progress", {}).get(id, 0))
	for id in data.get("tracked", []):
		if states.has(str(id)):
			tracked.append(str(id))
	changed.emit()
