class_name SkillBook
extends Node
## Umiejętności gracza: poziomy (0 = nieodblokowana) i wybrane węzły wspólnego drzewka (SkillTree), jedno i drugie
## za punkty umiejętności. Umiejętność, która ma węzeł w drzewku, jest dostępna tylko z wybranym węzłem (odblokowanie = poziom 1),
## a kolejne poziomy kosztują Skills.cost punktów (do Skills.MAX_LEVEL).
## Punkty umiejętności daje osobny pasek doświadczenia (skill_xp - napełnia się zwykłym expem, Skills.SKILL_XP_BANDS),
## plus SkillTree.START_POINTS, 1 punkt co LEVEL_POINT_EVERY poziomów postaci i nagrody zadań głównych. Cofnięcie wydanego punktu (węzeł, poziom, całe drzewko
## u mędrca) kosztuje złoto (refund_gold). Starsze zapisy (poziomy za złoto) przelicza migrate_old.
## Gniazda drzewka (węzły "socket") trzymają kamienie szlachetne (przepisy Gems): premie kamienia działają o połowę
## mocniej (TREE_GEM_POWER), a kamień promienia wzmacnia wybrane węzły pasywne w promieniu RADIUS_RANGE.
## Gniazdo legendarne przyjmuje też esencję legendy (Essences) - jej efekt działa z każdą bronią
## (Equipment.effect_power); wyjęcie esencji kosztuje złoto (Essences.save_gold), inaczej esencja przepada.
## Zapisy sprzed wspólnego drzewka (osobne drzewka broni) dostają zwrot wszystkich punktów (tree_reset).
## Gniazda umiejętności aktywnych (Supports): liczba gniazd i kamienie wsparcia w nich (supports), dorabiane krzesiwami.
## Aury (Auras): włączone aury (auras) i ich premie do statystyk (aura_bonus) oraz rezerwacja many albo zdrowia
## (reserved_mana / reserved_health - CharacterStats odejmuje ją od maksimum).

signal changed
## Kamienie wsparcia awansowały (nazwy z nowym poziomem) - HUD pokazuje napis.
signal supports_leveled(names: Array)
## Pasek doświadczenia umiejętności dał nowe punkty (ile) - HUD pokazuje napis.
signal skill_points_gained(count: int)

## id umiejętności -> kupiony poziom (umiejętność drzewka ma poziom 1 z samego węzła)
var levels := {}
## {id węzła: true} (start się nie liczy - jest wybrany zawsze)
var nodes := {}
## {id gniazda: przepis kamienia} (kamień w gnieździe nie istnieje jako przedmiot)
var tree_gems := {}
## Poziom postaci (do ceny cofania punktów i wyjmowania esencji) - ustawia gracz.
var character_level := 1
## Dodatkowe punkty umiejętności z zadań głównych (MainQuests - skill_points).
var bonus_points := 0
## id umiejętności -> {"sockets": liczba gniazd, "gems": [przepis kamienia wsparcia albo {} - puste gniazdo]}
var supports := {}
## Cały exp zebrany na pasek umiejętności (rośnie bez końca, punkty liczy earned_points).
var skill_xp := 0
## Wczytany zapis jest sprzed paska umiejętności - gracz przelicza go (migrate_old) po wczytaniu statystyk.
var needs_migration := false
## Ostatnie przeliczenie starego zapisu (zwrócone złoto) - okno umiejętności pokazuje informację.
var migrated_gold := -1
## Wczytany zapis miał osobne drzewka broni - wszystkie punkty wróciły do rozdania (okno umiejętności pokazuje
## informację), a kamienie z gniazd czekają w reset_gems, aż gracz odłoży je do plecaka (Player).
var tree_reset := false
var reset_gems: Array = []
## Włączone aury (id umiejętności w kolejności włączania).
var auras: Array[String] = []
## Premie włączonych aur (statystyka -> wartość), liczone od nowa przy każdej zmianie (_refresh_auras).
var _aura_stats := {}
## Węzły osiągalne od startu (reachable) i stan wybranych węzłów, z którego je policzono.
var _reach := {}
var _reach_key := -1

## Węzły, które do kroku 3 drzewka były pustymi miejscami (drzewko przechodziło przez nie za darmo). W zapisie,
## w którym wybrane węzły łączą się ze startem tylko przez nie, dostają się za darmo (repair_paths).
const FORMER_SOON: Array[String] = ["dread", "vigor", "strzybog_wind", "frost_breath", "perun_wrath", "life_spring",
		"swarog_ember", "marzanna_frost", "perun_sparks", "mana_spring", "focused_will", "thrifty_auras", "blood_offering"]

## Wersja drzewka w zapisie (2 - wspólne drzewko; bez niej - osobne drzewka broni).
const TREE_VERSION := 2

## Punkty umiejętności za awans postaci: 1 co tyle poziomów (wspólne drzewko ma więcej węzłów niż dawne drzewka broni).
const LEVEL_POINT_EVERY := 2
## Kamień w gnieździe drzewka działa mocniej niż w przedmiocie.
const TREE_GEM_POWER := 1.5
## Promień kamienia promienia (w jednostkach pozycji węzłów drzewka).
const RADIUS_RANGE := 2.6


func level_of(id: String) -> int:
	var node := SkillTree.node_for_skill(id)
	if node != "":
		return maxi(levels.get(id, 0), 1) if has_node_id(node) else 0
	return levels.get(id, 0)


## Koszt następnego poziomu w punktach albo -1, gdy umiejętność ma już maksymalny poziom (albo nie ma jeszcze węzła).
func next_cost(id: String) -> int:
	var level := level_of(id)
	if level == 0 and SkillTree.node_for_skill(id) != "":
		return -1
	return -1 if level >= Skills.MAX_LEVEL else Skills.cost(id, level + 1)


## Czy umiejętność da się już odblokować (umiejętność drzewka - węzła, inna - umiejętności z "requires").
func can_learn(id: String) -> bool:
	var node := SkillTree.node_for_skill(id)
	if node != "":
		return has_node_id(node)
	var required: String = Skills.get_data(id).get("requires", "")
	return required == "" or level_of(required) > 0


func upgrade(id: String) -> bool:
	var price := next_cost(id)
	if price < 0 or points_left() < price or not can_learn(id):
		return false
	levels[id] = level_of(id) + 1
	_refresh_auras()
	changed.emit()
	return true


## Najniższy poziom, do którego można cofnąć umiejętność (drzewka - 1, bo poziom 1 daje węzeł).
func _min_level(id: String) -> int:
	return 1 if SkillTree.node_for_skill(id) != "" else 0


## Złoto za cofnięcie jednego punktu umiejętności.
func refund_gold() -> int:
	return Skills.REFUND_GOLD_PER_LEVEL * maxi(character_level, 1)


## Ile złota kosztuje cofnięcie ostatniego poziomu (-1 - nie ma czego cofnąć).
func downgrade_gold(id: String) -> int:
	var level := level_of(id)
	if level <= _min_level(id):
		return -1
	return refund_gold() * Skills.cost(id, level)


## Cofa ostatni poziom umiejętności za złoto - punkty wracają.
func downgrade(id: String, stats: CharacterStats) -> bool:
	var price := downgrade_gold(id)
	if price < 0 or stats.gold < price:
		return false
	stats.add_gold(-price)
	levels[id] = level_of(id) - 1
	if levels[id] <= 0:
		levels.erase(id)
	_refresh_auras()
	changed.emit()
	return true


## Odblokowana aktywna umiejętność dla rodzaju broni ("" jeśli brak).
func active_for(weapon_type: String) -> String:
	var id: String = Skills.for_weapon(weapon_type)[0]
	return id if level_of(id) > 0 else ""


## Odblokowane uderzenie dla rodzaju broni ("" jeśli brak).
func strike_for(weapon_type: String) -> String:
	return _learned_of_type(weapon_type, "strike")


func _learned_of_type(weapon_type: String, kind: String) -> String:
	for id in Skills.for_weapon(weapon_type):
		if Skills.DATA[id]["type"] == kind:
			return id if level_of(id) > 0 else ""
	return ""


# ---------------------------------------------------------------- drzewko
func has_node_id(id: String) -> bool:
	return id == "start" or nodes.has(id)


func points_total() -> int:
	return earned_points() + SkillTree.START_POINTS + bonus_points + level_points()


## Punkty umiejętności za poziom postaci (1 co LEVEL_POINT_EVERY poziomów).
func level_points() -> int:
	return floori(maxi(character_level, 1) / float(LEVEL_POINT_EVERY))


## Awans postaci (Player): nowy poziom, a gdy daje punkt umiejętności - sygnał dla HUD.
func set_character_level(level: int) -> void:
	var before := level_points()
	character_level = level
	var gained := level_points() - before
	if gained > 0:
		skill_points_gained.emit(gained)
	changed.emit()


## Punkty wydane: węzły drzewka i poziomy umiejętności.
func points_spent() -> int:
	var total: int = nodes.size()
	for id: String in Skills.DATA:
		total += _level_points(id, level_of(id))
	return total


## Punkty umiejętności za poziomy umiejętności ponad to, co daje węzeł drzewka.
func _level_points(id: String, level: int) -> int:
	var total := 0
	for l in range(_min_level(id) + 1, level + 1):
		total += Skills.cost(id, l)
	return total


# ---------------------------------------------------------------- pasek doświadczenia umiejętności
## Punkty zdobyte na pasku (bez punktów startowych i z zadań).
func earned_points() -> int:
	var left := skill_xp
	var points := 0
	while true:
		var need := Skills.skill_point_xp(points + 1)
		if left < need:
			return points
		left -= need
		points += 1
	return points


## [exp na pasku od ostatniego punktu, exp potrzebny na następny punkt].
func skill_xp_progress() -> Array[int]:
	var left := skill_xp
	var point := 1
	while left >= Skills.skill_point_xp(point):
		left -= Skills.skill_point_xp(point)
		point += 1
	return [left, Skills.skill_point_xp(point)]


func add_skill_xp(amount: int) -> void:
	if amount <= 0:
		return
	var before := earned_points()
	skill_xp += amount
	var gained := earned_points() - before
	if gained > 0:
		skill_points_gained.emit(gained)
		changed.emit()


func points_left() -> int:
	return maxi(points_total() - points_spent(), 0)


## Węzły osiągalne od startu: wybrane i puste miejsca (SkillTree.is_soon) leżące obok osiągalnych - przez puste
## miejsca drzewko przechodzi za darmo. `without` - bez tego węzła (sprawdzanie cofania).
func reachable(without := "") -> Dictionary:
	var key := nodes.hash()
	if without == "" and key == _reach_key:
		return _reach
	var reached := {"start": true}
	var queue: Array[String] = ["start"]
	while not queue.is_empty():
		for other: String in SkillTree.neighbors(queue.pop_back()):
			if other != without and not reached.has(other) and (nodes.has(other) or SkillTree.is_soon(other)):
				reached[other] = true
				queue.append(other)
	if without == "":
		_reach = reached
		_reach_key = key
	return reached


## Czy węzeł leży obok osiągalnego (da się go wybrać, gdy będzie wolny punkt).
func is_open(id: String) -> bool:
	if has_node_id(id) or SkillTree.is_soon(id) or not SkillTree.has_node(id):
		return false
	var reached := reachable()
	return SkillTree.neighbors(id).any(func(other: String) -> bool: return reached.has(other))


## Czy węzeł można teraz wybrać: jeszcze niewybrany, nie jest pustym miejscem, obok wybranego i jest wolny punkt.
func can_take(id: String) -> bool:
	return points_left() > 0 and is_open(id)


func take(id: String) -> bool:
	if not can_take(id):
		return false
	nodes[id] = true
	changed.emit()
	return true


## Dlaczego węzła nie da się cofnąć ("" - da się): start, niewybrany, kamień w gnieździe albo węzeł, przez który
## inne wybrane węzły łączą się ze startem.
## Z `gold` (>= 0) sprawdza też, czy starczy złota na cofnięcie (refund_gold).
func refund_reason(id: String, gold := -1) -> String:
	if id == "start" or not nodes.has(id):
		return Lang.t("Ten węzeł nie jest wybrany.")
	if not gem_in(id).is_empty():
		return Lang.t("Wyjmij najpierw kamień z gniazda.")
	var skill: String = SkillTree.node(id).get("skill", "")
	if skill != "" and level_of(skill) > 1:
		return Lang.t("Cofnij najpierw poziomy umiejętności.")
	if gold >= 0 and gold < refund_gold():
		return Lang.t("Za mało złota: cofnięcie kosztuje %d zł.") % refund_gold()
	# każdy inny wybrany węzeł musi zostać osiągalny od startu
	var reached := reachable(id)
	for other: String in nodes:
		if other != id and not reached.has(other):
			return Lang.t("Inne wybrane węzły zależą od tego węzła.")
	return ""


## Wybiera węzeł razem z drogą od startu bez sprawdzania punktów - testy i narzędzia (zrzuty, pomiary).
func grant_node(id: String) -> void:
	for step in SkillTree.path_to(id):
		nodes[step] = true
	changed.emit()


## Cofa jeden węzeł (prawy przycisk w drzewku) - punkt wraca. Ze `stats` pobiera złoto (refund_gold).
func refund(id: String, stats: CharacterStats = null) -> bool:
	if refund_reason(id, stats.gold if stats != null else -1) != "":
		return false
	if stats != null:
		stats.add_gold(-refund_gold())
	nodes.erase(id)
	_refresh_auras()
	changed.emit()
	return true


## Zapomnienie drzewka (u mędrca): wszystkie węzły i poziomy umiejętności wracają jako punkty
## (złoto liczy VillageServices._respec - points_spent * refund_gold).
## Zwraca przepisy kamieni wyjętych z gniazd (wracają do plecaka - VillageServices._respec).
func reset_tree() -> Array:
	nodes.clear()
	levels.clear()
	var gems: Array = tree_gems.values()
	tree_gems.clear()
	_refresh_auras()
	changed.emit()
	return gems


# ---------------------------------------------------------------- gniazda drzewka
## Przepis kamienia w gnieździe drzewka ({} - puste).
func gem_in(id: String) -> Dictionary:
	return tree_gems.get(id, {})


## Esencje legend w wybranych gniazdach legendarnych drzewka (działają z każdą bronią).
func essences() -> Array:
	var found := []
	for id: String in tree_gems:
		if tree_gems[id].has("essence") and has_node_id(id):
			found.append(tree_gems[id])
	return found


func is_legendary_socket(id: String) -> bool:
	return SkillTree.node(id).get("legendary", false)


## Czy w węzeł da się włożyć kamień: wybrane gniazdo.
func can_socket(id: String) -> bool:
	return SkillTree.node(id).get("kind", "") == "socket" and has_node_id(id)


## Wkłada kamień (przepis); zwraca przepis kamienia, który był w gnieździe wcześniej ({} - nie było).
func set_gem(id: String, recipe: Dictionary) -> Dictionary:
	var old := gem_in(id)
	tree_gems[id] = recipe.duplicate(true)
	changed.emit()
	return old


## Wyjmuje kamień z gniazda; zwraca jego przepis ({} - gniazdo było puste).
func take_gem(id: String) -> Dictionary:
	var old := gem_in(id)
	if not old.is_empty():
		tree_gems.erase(id)
		changed.emit()
	return old


## Osadza kamień z pola `index` plecaka w gnieździe drzewka; kamień, który tam był, wraca do plecaka (zamiana).
## Zwraca "" albo powód, dla którego się nie da.
func socket_from(inventory: Inventory, id: String, index: int) -> String:
	if not can_socket(id):
		return Lang.t("Najpierw wybierz gniazdo w drzewku.")
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty() \
			or not (Gems.is_gem(inventory.slots[index]["id"]) or Essences.is_essence(inventory.slots[index]["id"])):
		return Lang.t("To nie jest kamień szlachetny ani esencja.")
	var gem_id: String = inventory.slots[index]["id"]
	if Essences.is_essence(gem_id) and not is_legendary_socket(id):
		return Lang.t("Esencja pasuje tylko do gniazda legendarnego.")
	if gem_in(id).has("essence"):
		return Lang.t("Najpierw wyjmij esencję z gniazda.")
	inventory.take_one(index)
	var old := set_gem(id, Items.generated[gem_id]["recipe"])
	Items.generated.erase(gem_id)
	if not old.is_empty():
		inventory.put(index, Gems.register(old.duplicate(true)))
	return ""


## Wyjmuje kamień z gniazda drzewka do plecaka (za darmo; esencję - za złoto z `stats`, Essences.save_gold).
## Zwraca "" albo powód, dla którego się nie da.
func unsocket_to(inventory: Inventory, id: String, stats: CharacterStats = null) -> String:
	var gem := gem_in(id)
	if gem.is_empty():
		return Lang.t("Gniazdo jest puste.")
	if not inventory.slots.any(func(slot: Dictionary) -> bool: return slot.is_empty()):
		return Lang.t("Plecak jest pełny.")
	if gem.has("essence"):
		var price := Essences.save_gold(character_level)
		if stats == null or stats.gold < price:
			return Lang.t("Wyjęcie esencji kosztuje %d zł.") % price
		stats.add_gold(-price)
		inventory.add_item(Essences.register(take_gem(id).duplicate(true)), 1)
		return ""
	inventory.add_item(Gems.register(take_gem(id).duplicate(true)), 1)
	return ""


## Niszczy esencję w gnieździe drzewka (za darmo).
func destroy_essence(id: String) -> void:
	if gem_in(id).has("essence"):
		take_gem(id)


## Kamienie promienia w wybranych gniazdach: [pozycja gniazda, moc].
func _radius_gems() -> Array:
	var found := []
	for id: String in tree_gems:
		if tree_gems[id].get("kind", "") == "radius" and has_node_id(id) and SkillTree.has_node(id):
			found.append([SkillTree.node(id)["pos"], float(tree_gems[id]["affixes"].get("radius_power", 0.0))])
	return found


## Mnożnik premii węzła pasywnego od kamieni promienia (1.0 - poza promieniem).
func radius_factor(id: String) -> float:
	var factor := 1.0
	if SkillTree.node(id).get("kind", "") != "passive":
		return factor
	for gem: Array in _radius_gems():
		if (gem[0] as Vector2).distance_to(SkillTree.node(id)["pos"]) <= RADIUS_RANGE:
			factor += gem[1]
	return factor


## Suma premii danego rodzaju z wybranych węzłów drzewka (statystyki postaci i premie umiejętności) - z każdą bronią.
func tree_bonus(stat: String) -> float:
	var total := 0.0
	var radius := _radius_gems()
	for id: String in nodes:
		var data := SkillTree.node(id)
		var value := float(data.get("stats", {}).get(stat, 0.0))
		if value != 0.0 and not radius.is_empty() and data["kind"] == "passive" and stat not in SkillTree.COUNT_STATS:
			var factor := 1.0
			for gem: Array in radius:
				if (gem[0] as Vector2).distance_to(data["pos"]) <= RADIUS_RANGE:
					factor += gem[1]
			value *= factor
		total += value
	for id: String in tree_gems:
		if has_node_id(id):
			total += float(tree_gems[id].get("affixes", {}).get(stat, 0.0)) * TREE_GEM_POWER
	return total


# ---------------------------------------------------------------- aury (Auras)
## Premia `stat` z włączonych aur (CharacterStats._bonus).
func aura_bonus(stat: String) -> float:
	return float(_aura_stats.get(stat, 0.0))


## Ułamek pełnej many (albo zdrowia - Krwawa Ofiara) rezerwowany przez aurę, z węzłami Skupiona wola i Oszczędne aury.
func aura_reserve(id: String) -> float:
	return float(AuraData.RESERVE.get(id, 0.0)) * maxf(1.0 + tree_bonus("aura_reservation"), 0.0)


## Łączna rezerwacja włączonych aur (ułamek), `extra` - z dodatkową aurą (sprawdzanie przed włączeniem).
func reserved_total(extra := "") -> float:
	var total := 0.0
	for id: String in auras:
		total += aura_reserve(id)
	if extra != "" and not auras.has(extra):
		total += aura_reserve(extra)
	return total


## Ułamek pełnej many zarezerwowany przez aury (0 z Krwawą Ofiarą - wtedy rezerwują zdrowie).
func reserved_mana() -> float:
	return 0.0 if has_keystone("blood_offering") else minf(reserved_total(), 1.0)


## Ułamek pełnego zdrowia zarezerwowany przez aury (tylko z Krwawą Ofiarą).
func reserved_health() -> float:
	return minf(reserved_total(), AuraData.MAX_HEALTH_RESERVE) if has_keystone("blood_offering") else 0.0


## Dlaczego aury nie da się teraz włączyć ("" - da się): za mało wolnej many / zdrowia na rezerwację.
func aura_block_reason(id: String, stats: CharacterStats, mana: float, health: int) -> String:
	var cost := aura_reserve(id)
	if cost <= 0.0:
		return ""
	if has_keystone("blood_offering"):
		if reserved_total(id) > AuraData.MAX_HEALTH_RESERVE:
			return Lang.t("Aury nie mogą zarezerwować więcej niż %d%% zdrowia") % roundi(AuraData.MAX_HEALTH_RESERVE * 100)
		if health <= roundi(stats.full_max_health() * cost):
			return Lang.t("Za mało zdrowia na tę aurę")
		return ""
	if reserved_total(id) > 1.0 + 0.0001:
		return Lang.t("Za mało wolnej many - wyłącz inną aurę")
	if mana < stats.full_max_mana() * cost:
		return Lang.t("Za mało many na tę aurę")
	return ""


## Włącza albo wyłącza aurę (bez sprawdzania - Auras.toggle sprawdza aura_block_reason).
func set_aura(id: String, on: bool) -> void:
	if on and not auras.has(id) and AuraData.is_aura(id):
		auras.append(id)
	elif not on:
		auras.erase(id)
	_refresh_auras()
	changed.emit()


## Aury bez wybranego węzła wyłączają się; premie liczą się od nowa (poziomy aur).
func _refresh_auras() -> void:
	for id: String in auras.duplicate():
		if level_of(id) <= 0:
			auras.erase(id)
	_aura_stats = {}
	for id: String in auras:
		var bonus := AuraData.stats_of(id, level_of(id))
		for stat: String in bonus:
			_aura_stats[stat] = float(_aura_stats.get(stat, 0.0)) + float(bonus[stat])


## Zapis, w którym wybrane węzły łączyły się ze startem przez dawne puste miejsca (FORMER_SOON): te węzły dostaje
## się za darmo (+1 punkt umiejętności za każdy), żeby reszta drzewka została osiągalna. Zwraca dodane węzły.
func repair_paths() -> Array[String]:
	var added: Array[String] = []
	while true:
		var reached := reachable()
		var lost := ""
		for id: String in nodes:
			if not reached.has(id):
				lost = id
				break
		if lost == "":
			break
		# szukanie wstecz od odciętego węzła przez dawne i obecne puste miejsca do osiągalnej części drzewka
		var previous := {lost: ""}
		var queue: Array[String] = [lost]
		var hit := ""
		while not queue.is_empty() and hit == "":
			var at: String = queue.pop_front()
			for next: String in SkillTree.neighbors(at):
				if previous.has(next):
					continue
				if reached.has(next):
					previous[next] = at
					hit = next
					break
				if (next in FORMER_SOON and not nodes.has(next)) or SkillTree.is_soon(next):
					previous[next] = at
					queue.append(next)
		if hit == "":
			nodes.erase(lost)  # nie da się połączyć - węzeł przepada, punkt wraca
			continue
		var at: String = previous[hit]
		while at != lost and at != "":
			if at in FORMER_SOON and not nodes.has(at):
				nodes[at] = true
				bonus_points += 1
				added.append(at)
			at = previous[at]
	return added


# ---------------------------------------------------------------- gniazda umiejętności (kamienie wsparcia)
func sockets_of(skill: String) -> int:
	return int(supports.get(skill, {}).get("sockets", 0))


## Kamienie wsparcia w gniazdach umiejętności (przepisy; {} - puste gniazdo), zawsze tyle, ile gniazd.
func support_gems(skill: String) -> Array:
	return supports.get(skill, {}).get("gems", [])


## Dorabia gniazdo umiejętności za krzesiwa z plecaka (Supports.socket_cost). Zwraca "" albo powód.
func add_socket(skill: String, inventory: Inventory) -> String:
	if not Supports.has_sockets(skill):
		return Lang.t("Ta umiejętność nie może mieć gniazd.")
	if level_of(skill) <= 0:
		return Lang.t("Najpierw odblokuj umiejętność.")
	var cost := Supports.socket_cost(sockets_of(skill))
	if cost.is_empty():
		return Lang.t("Umiejętność ma już wszystkie gniazda.")
	if inventory.count_of(cost[0]) < int(cost[1]):
		return Lang.t("Potrzeba: %s x%d.") % [Items.short_name(cost[0]), cost[1]]
	inventory.remove_item(cost[0], int(cost[1]))
	if not supports.has(skill):
		supports[skill] = {"sockets": 0, "gems": []}
	supports[skill]["sockets"] = sockets_of(skill) + 1
	supports[skill]["gems"].append({})
	changed.emit()
	return ""


## Osadza kamień wsparcia z pola `index` plecaka w gnieździe `slot` umiejętności (-1 - pierwsze wolne);
## kamień, który tam był, wraca do plecaka. Zwraca "" albo powód.
func support_socket_from(inventory: Inventory, skill: String, index: int, slot := -1) -> String:
	if index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty() \
			or not Supports.is_support(inventory.slots[index]["id"]):
		return Lang.t("To nie jest kamień wsparcia.")
	var item_id: String = inventory.slots[index]["id"]
	var recipe: Dictionary = Items.generated[item_id]["recipe"]
	var kind: String = recipe["support"]
	if not Supports.fits(kind, skill):
		return Lang.t("%s nie pasuje do tej umiejętności.") % Supports.name_of(kind)
	var gems := support_gems(skill)
	if gems.is_empty():
		return Lang.t("Umiejętność nie ma gniazd - dorób je krzesiwem.")
	if slot < 0:
		slot = gems.find({})
		if slot < 0:
			return Lang.t("Wszystkie gniazda są zajęte - wyjmij najpierw któryś kamień.")
	for i in gems.size():
		if i != slot and gems[i].get("support", "") == kind:
			return Lang.t("Ten kamień już jest w tej umiejętności.")
	inventory.take_one(index)
	Items.generated.erase(item_id)
	var old: Dictionary = gems[slot]
	gems[slot] = recipe.duplicate(true)
	if not old.is_empty():
		inventory.put(index, Supports.register(old.duplicate(true)))
	changed.emit()
	return ""


## Wyjmuje kamień wsparcia z gniazda do plecaka (za darmo). Zwraca "" albo powód.
func support_unsocket_to(inventory: Inventory, skill: String, slot: int) -> String:
	var gems := support_gems(skill)
	if slot < 0 or slot >= gems.size() or gems[slot].is_empty():
		return Lang.t("Gniazdo jest puste.")
	if not inventory.slots.any(func(entry: Dictionary) -> bool: return entry.is_empty()):
		return Lang.t("Plecak jest pełny.")
	inventory.add_item(Supports.register((gems[slot] as Dictionary).duplicate(true)), 1)
	gems[slot] = {}
	changed.emit()
	return ""


## Suma premii `stat` kamieni wsparcia umiejętności (more i mana - patrz support_more i support_mana).
func support_value(skill: String, stat: String) -> float:
	var total := 0.0
	for gem: Dictionary in support_gems(skill):
		if not gem.is_empty() and Supports.DATA[gem["support"]]["stats"].has(stat):
			total += Supports.value(gem["support"], stat, int(gem["level"]))
	return total


## Mnożnik obrażeń kamieni wsparcia (premie "more" się mnożą).
func support_more(skill: String) -> float:
	var total := 1.0
	for gem: Dictionary in support_gems(skill):
		if not gem.is_empty() and Supports.DATA[gem["support"]]["stats"].has("more"):
			total *= 1.0 + Supports.value(gem["support"], "more", int(gem["level"]))
	return total


## Mnożnik kosztu many umiejętności od kamieni wsparcia.
func support_mana(skill: String) -> float:
	var total := 1.0
	for gem: Dictionary in support_gems(skill):
		if not gem.is_empty():
			total *= float(Supports.DATA[gem["support"]]["mana"])
	return total


## Doświadczenie dla kamieni wsparcia we wszystkich gniazdach (Supports.XP_SHARE doświadczenia postaci).
## Zwraca nazwy kamieni, które awansowały.
func add_support_xp(amount: int) -> Array[String]:
	var leveled: Array[String] = []
	var share := roundi(amount * Supports.XP_SHARE)
	for skill: String in supports:
		for gem: Dictionary in supports[skill]["gems"]:
			if not gem.is_empty() and Supports.add_xp(gem, share):
				leveled.append(Lang.t("%s (poziom %d)") % [Supports.name_of(gem["support"]), int(gem["level"])])
	if not leveled.is_empty():
		changed.emit()
		supports_leveled.emit(leveled)
	return leveled


## Wybrany węzeł kluczowy (działa z każdą bronią - tam, gdzie pasuje).
func has_keystone(id: String) -> bool:
	return nodes.has(id) and SkillTree.node(id).get("kind", "") == "keystone"


func get_save_data() -> Dictionary:
	return {"tree": TREE_VERSION, "levels": levels.duplicate(), "nodes": nodes.keys(), "gems": tree_gems.duplicate(true),
			"bonus_points": bonus_points, "supports": supports.duplicate(true), "skill_xp": skill_xp, "auras": auras.duplicate()}


## Zapis sprzed wspólnego drzewka (bez "tree") miał osobne drzewka broni: węzły i poziomy umiejętności przepadają,
## czyli wszystkie punkty wracają do rozdania (tree_reset), a kamienie z gniazd czekają w reset_gems na plecak.
## Jeszcze starsze zapisy (sam słownik poziomów, bez paska umiejętności) przelicza migrate_old.
func load_save_data(data: Dictionary) -> void:
	levels.clear()
	nodes.clear()
	tree_gems.clear()
	supports.clear()
	reset_gems.clear()
	bonus_points = int(data.get("bonus_points", 0))
	skill_xp = int(data.get("skill_xp", 0))
	needs_migration = not data.has("skill_xp")
	migrated_gold = -1
	var old_tree := int(data.get("tree", 0)) < TREE_VERSION
	tree_reset = old_tree and not data.is_empty()
	var saved_supports: Dictionary = data.get("supports", {})
	for skill: String in saved_supports:
		if not Supports.has_sockets(skill):
			continue
		var count := clampi(int(saved_supports[skill].get("sockets", 0)), 0, Supports.MAX_SOCKETS)
		var gems := []
		for gem in saved_supports[skill].get("gems", []):
			if gems.size() >= count:
				break
			var recipe: Dictionary = gem if gem is Dictionary else {}
			if Supports.DATA.has(recipe.get("support", "")):
				recipe["level"] = clampi(int(recipe.get("level", 1)), 1, Supports.MAX_LEVEL)
				recipe["xp"] = int(recipe.get("xp", 0))
				gems.append(recipe)
			else:
				gems.append({})
		while gems.size() < count:
			gems.append({})
		supports[skill] = {"sockets": count, "gems": gems}
	var saved_gems: Dictionary = data.get("gems", {})
	if old_tree:
		# osobne drzewka broni: {broń: {gniazdo: przepis}} - kamienie wracają do plecaka
		for weapon_type: String in saved_gems:
			if saved_gems[weapon_type] is Dictionary:
				for id: String in saved_gems[weapon_type]:
					var recipe = saved_gems[weapon_type][id]
					if recipe is Dictionary and recipe.has("kind"):
						reset_gems.append(_clean_gem(recipe))
		# zapis sprzed paska umiejętności: poziomy potrzebne do zwrotu złota (migrate_old)
		if needs_migration:
			var old_levels: Dictionary = data.get("levels", {}) if data.has("levels") else data
			for id: String in old_levels:
				if Skills.DATA.has(id) and (old_levels[id] is int or old_levels[id] is float):
					levels[id] = clampi(int(old_levels[id]), 0, Skills.MAX_LEVEL)
	else:
		for id: String in saved_gems:
			var recipe = saved_gems[id]
			if SkillTree.node(id).get("kind", "") == "socket" and recipe is Dictionary and recipe.has("kind"):
				tree_gems[id] = _clean_gem(recipe)
		var saved_levels: Dictionary = data.get("levels", {})
		for id: String in saved_levels:
			if Skills.DATA.has(id):
				levels[id] = clampi(int(saved_levels[id]), 0, Skills.MAX_LEVEL)
		for id in data.get("nodes", []):
			if SkillTree.has_node(str(id)) and str(id) != "start" and not SkillTree.is_soon(str(id)):
				nodes[str(id)] = true
		repair_paths()
	auras.clear()
	for id in data.get("auras", []):
		if AuraData.is_aura(str(id)) and not auras.has(str(id)):
			auras.append(str(id))
	_refresh_auras()
	changed.emit()


func _clean_gem(recipe: Dictionary) -> Dictionary:
	if recipe.has("essence"):
		recipe["value"] = float(recipe["value"])
	else:
		recipe["cut"] = int(recipe.get("cut", 0))
	return recipe


## Kamienie z gniazd dawnych drzewek broni (zapis sprzed wspólnego drzewka) - gracz odkłada je do plecaka.
func take_reset_gems() -> Array:
	var gems := reset_gems.duplicate()
	reset_gems.clear()
	return gems


## Przelicza zapis sprzed paska umiejętności: złoto wydane na poziomy umiejętności wraca, węzły i poziomy wracają
## jako punkty, a pasek dostaje cały exp zdobyty przez postać (`total_xp`). Zwraca {"gold": zwrot złota,
## "gems": przepisy kamieni z gniazd drzewek - gracz odkłada je do plecaka}. Bez starego zapisu - {}.
func migrate_old(total_xp: int) -> Dictionary:
	if not needs_migration:
		return {}
	needs_migration = false
	var gold := 0
	for id: String in levels:
		var first := 2 if SkillTree.node_for_skill(id) != "" else 1
		for level in range(first, mini(levels[id], 5) + 1):
			gold += Skills.old_gold_cost(id, level)
	levels.clear()
	var gems: Array = tree_gems.values()
	tree_gems.clear()
	nodes.clear()
	skill_xp = maxi(total_xp, 0)
	migrated_gold = gold
	changed.emit()
	return {"gold": gold, "gems": gems}
