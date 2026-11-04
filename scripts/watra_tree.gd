class_name WatraTree
## Drzewko Watry - końcówka gry jak drzewko atlasu w Path of Exile. Punkty Watry zdobywa się za oczyszczone węzły Mapy
## Nawii (Boons.watra_points), a wydaje na węzły tego drzewka: każdy kosztuje 1 punkt i można go wybrać tylko obok węzła
## już wybranego (start - Watra w środku - jest wybrany zawsze). Węzłów jest więcej niż punktów z całej mapy,
## więc trzeba wybierać, w co iść.
## Drzewko ma 3 zakładki (Boons.watra_tabs): każda ma pełną, osobną pulę punktów, działa tylko wybrana. Dzięki temu
## można trzymać 3 wyspecjalizowane ustawienia (np. pod Uroczysko, pod Skarbnika, pod bożki). Zakładkę zmienia się
## za darmo poza lochem; loch zapamiętuje premie z chwili wejścia (Dungeons.config, klucz "tree").
## Wybrane węzły cofa się za złoto: pojedynczy węzeł z końca ścieżki (REFUND_GOLD_PER_LEVEL) albo całą zakładkę
## naraz, taniej w przeliczeniu na węzeł (RESET_GOLD_PER_LEVEL).
## Układ: 13 gałęzi rozchodzących się promieniście od Watry (BRANCHES). Gałąź ma węzeł-korzeń i dwie ścieżki po 4 małe
## węzły zakończone węzłem znaczącym albo kluczowym. Gałęzie mechanik (Dungeons.MECHANICS): ścieżka „częściej”
## (waga mechaniki w Dungeons.roll_mechanics) z węzłem kluczowym „mechanika zawsze”, i ścieżka „mocniej” (moc mechaniki
## jak z legendarnego bożka - Dungeon.mechanic_power: więcej skrzyń, run, talizmanów do wyboru…).
## Pozostałe gałęzie: Splot mechanik (szansa na drugą i trzecią mechanikę), Bożki (wypadanie, rzadkość, sloty -
## Idols.drop_chance, Idols.roll, Idols.slot_count), Łup potworów i Skarbiec (mnożniki i premie lochów - Dungeons.mult,
## Dungeons.added) oraz Błogosławieństwo Watry (premie oczyszczonych krain - World._apply_blessing).
## Premie węzłów (EFFECTS): klucze "weight:<mechanika>" mnożą się, "forced:<mechanika>" włączają mechanikę na stałe,
## reszta się sumuje (effects).

const START := "start"
const TABS := 3
## Ile złota kosztuje cofnięcie jednego węzła i każdego węzła przy czyszczeniu zakładki (za każdy poziom postaci).
const REFUND_GOLD_PER_LEVEL := 20
const RESET_GOLD_PER_LEVEL := 8
## Najwięcej dodatkowych slotów na bożki z drzewka (DungeonWindow trzyma tyle zapasowych pól).
const MAX_IDOL_SLOTS := 2

## Gałęzie w kolejności wokół Watry (od góry, zgodnie ze wskazówkami zegara).
const BRANCH_ORDER: Array[String] = ["chests", "general", "shrine", "elites", "loot", "crystal",
		"uroczysko", "vault", "zertwa", "skarbnik", "mist", "idols", "bless"]
const BRANCH_COLORS := {
	"chests": Color(0.95, 0.75, 0.35), "shrine": Color(0.55, 0.85, 1.0), "elites": Color(0.95, 0.45, 0.4),
	"crystal": Color(1.0, 0.55, 0.25), "uroczysko": Color(0.6, 0.55, 1.0), "zertwa": Color(0.85, 0.3, 0.35),
	"skarbnik": Color(0.95, 0.85, 0.3), "mist": Color(0.68, 0.7, 1.0), "general": Color(0.75, 0.75, 0.85), "idols": Color(0.75, 0.6, 0.45),
	"loot": Color(0.5, 0.9, 0.5), "vault": Color(1.0, 0.7, 0.55), "bless": Color(1.0, 0.9, 0.55),
}
## Nazwy gałęzi spoza mechanik (gałęzie mechanik biorą nazwę z Dungeons.MECHANICS).
const BRANCH_NAMES := {"general": "Splot mechanik", "idols": "Bożki", "loot": "Łup potworów", "vault": "Skarbiec",
		"bless": "Błogosławieństwo Watry"}
## Gałęzie mechanik: nazwa węzła kluczowego (mechanika zawsze) i znaczącego (dużo mocy).
const MECHANIC_KEYSTONES := {
	"chests": "Skarbiec Przodków", "shrine": "Święty Gaj", "elites": "Zew Wybrańców", "crystal": "Serce Kryształu",
	"uroczysko": "Brama Nawii", "zertwa": "Krwawa Danina", "skarbnik": "Pakt ze Skarbnikiem",
	"mist": "Wieczna Mgła",
}
const MECHANIC_NOTABLES := {
	"chests": "Okute Wieka", "shrine": "Łaska Bogów", "elites": "Łowy na Wybrańców", "crystal": "Czysty Żar",
	"uroczysko": "Zimne Runy", "zertwa": "Hojna Żertwa", "skarbnik": "Chciwość Skarbnika",
	"mist": "Gęsta Mgła",
}
## Co daje moc danej mechaniki (opis w podpowiedzi węzła).
const POWER_TEXTS := {
	"chests": "więcej skrzyń", "shrine": "więcej kapliczek", "elites": "więcej elitarnych potworów",
	"crystal": "hojniejszy Kryształ Watry", "uroczysko": "więcej run z Uroczyska",
	"zertwa": "więcej talizmanów do wyboru", "skarbnik": "więcej Skarbników",
	"mist": "bogatsza Skrzynia Mgły",
}
## Gałęzie mechanik: mnożnik wagi z korzenia i ze ścieżki „częściej”, moc ze ścieżki „mocniej” i z węzła znaczącego.
const MECH_WEIGHT := 1.2
const MECH_POWER := 0.1
const MECH_POWER_NOTABLE := 0.3
## Pozostałe gałęzie: premie korzenia, ścieżek ("a", "b" - po 4 małe węzły; tablica to premie kolejnych węzłów)
## i węzłów na końcu ścieżek ("a_end", "b_end"), nazwy węzłów.
const BRANCHES := {
	"general": {
		"root": {"name": "Splot mechanik", "effects": {"extra2": 0.03}},
		"a": {"name": "Druga mechanika", "effects": [{"extra2": 0.03}]},
		"a_end": {"name": "Gęsty Splot", "effects": {"extra2": 0.08}},
		"b": {"name": "Trzecia mechanika", "effects": [{"extra3": 0.02}]},
		"b_end": {"name": "Potrójny Węzeł", "effects": {"extra3": 0.06}},
	},
	"idols": {
		"root": {"name": "Ołtarzyk", "effects": {"idol_drop": 0.1}},
		"a": {"name": "Częstsze bożki", "effects": [{"idol_drop": 0.1}]},
		"a_end": {"name": "Nowy Ołtarz", "effects": {"idol_slot": 1.0}},
		"b": {"name": "Rzadsze bożki", "effects": [{"idol_rarity": 0.15}]},
		"b_end": {"name": "Prastare Dłonie", "effects": {"idol_ancient": 1.0, "idol_slot": 1.0}},
	},
	"loot": {
		"root": {"name": "Łup lochów", "effects": {"loot": 0.04}},
		"a": {"name": "Łup lochów", "effects": [{"loot": 0.04}]},
		"a_end": {"name": "Dar Legend", "effects": {"legend": 0.5, "loot": 0.05}},
		"b": {"name": "Złoto i nauka", "effects": [{"gold": 0.08}, {"xp": 0.04}]},
		"b_end": {"name": "Kamienna Żyła", "effects": {"gems": 0.5}},
	},
	"vault": {
		"root": {"name": "Skarbiec strażnika", "effects": {"treasure": 0.05}},
		"a": {"name": "Lepsze przedmioty", "effects": [{"quality": 0.03}]},
		"a_end": {"name": "Kunszt Przodków", "effects": {"item_level": 1.0}},
		"b": {"name": "Bogatszy skarbiec", "effects": [{"treasure": 0.06}]},
		"b_end": {"name": "Runiczny Skarbiec", "effects": {"vault_runes": 1.0}},
	},
	"bless": {
		"root": {"name": "Ciepło krain", "effects": {"bless_flat": 0.02}},
		"a": {"name": "Ciepło węzłów", "effects": [{"bless_node": 0.0025}]},
		"a_end": {"name": "Płomień Krain", "effects": {"bless_flat": 0.08}},
		"b": {"name": "Złoto krain", "effects": [{"bless_gold": 0.06}]},
		"b_end": {"name": "Hojna Watra", "effects": {"bless_gold": 0.15, "bless_flat": 0.04}},
	},
}
## Położenie węzłów gałęzi: [wzdłuż promienia, w bok] w jednostkach drzewka (WatraTreeWindow rysuje je w pikselach).
const ROOT_POS := Vector2(2.65, 0.0)
const PATH_POS: Array[Vector2] = [Vector2(3.85, 0.5), Vector2(5.05, 0.7), Vector2(6.25, 0.75), Vector2(7.45, 0.7)]
const END_POS := Vector2(8.75, 0.55)
## Klucze premii mnożących lochy (Dungeons.mult: 1 + suma) i dodawanych (Dungeons.added).
const MULT_KEYS: Array[String] = ["loot", "gold", "xp", "gems", "legend", "treasure"]
const ADD_KEYS: Array[String] = ["item_level", "quality", "vault_runes"]
## Opisy premii; %d - liczba (procenty dla PERCENT_KEYS).
const EFFECT_TEXTS := {
	"extra2": "+%d%% szansy na drugą mechanikę w lochu", "extra3": "+%d%% szansy na trzecią mechanikę w lochu",
	"idol_drop": "Bożki wypadają o %d%% częściej", "idol_rarity": "+%d%% szansy na rzadkie i legendarne bożki",
	"idol_ancient": "Prastare bożki wypadają o %d%% częściej", "idol_slot": "+%d slot na bożki w oknie lochów",
	"loot": "+%d%% przedmiotów z potworów w lochach", "gold": "+%d%% złota w lochach", "xp": "+%d%% doświadczenia w lochach",
	"gems": "+%d%% kamieni szlachetnych w lochach", "legend": "+%d%% szansy na legendy w lochach",
	"treasure": "+%d%% łupu ze skarbca strażnika", "quality": "+%d%% szansy na lepszą rzadkość przedmiotów z lochów",
	"item_level": "+%d do poziomu przedmiotów z lochów", "vault_runes": "+%d runa w skarbcu strażnika",
	"bless_flat": "Błogosławieństwo Watry: +%d%% łupu i doświadczenia",
	"bless_node": "Błogosławieństwo Watry: +%s%% łupu i doświadczenia za każdy oczyszczony węzeł obszaru",
	"bless_gold": "Błogosławieństwo Watry: +%d%% złota",
}
const PERCENT_KEYS: Array[String] = ["extra2", "extra3", "idol_drop", "idol_rarity", "idol_ancient", "loot", "gold", "xp",
		"gems", "legend", "treasure", "quality", "bless_flat", "bless_gold"]

static var _nodes := {}


## Wszystkie węzły: id -> {"pos", "links", "kind" (start / small / notable / keystone), "branch", "name", "effects"}.
static func nodes() -> Dictionary:
	if _nodes.is_empty():
		_nodes = _build()
	return _nodes


static func _build() -> Dictionary:
	var result := {}
	result[START] = {"pos": Vector2.ZERO, "links": [] as Array[String], "kind": "start", "branch": "", "name": "Watra", "arg": "",
			"effects": {}}
	var sector := TAU / BRANCH_ORDER.size()
	for i in BRANCH_ORDER.size():
		var branch := BRANCH_ORDER[i]
		var angle := -PI / 2.0 + i * sector
		var plan := _plan(branch)
		var root := "%s_root" % branch
		_add(result, root, branch, plan["root"], _place(ROOT_POS, angle), START)
		for side: String in ["a", "b"]:
			var sign := -1.0 if side == "a" else 1.0
			var previous := root
			for step in PATH_POS.size():
				var id := "%s_%s%d" % [branch, side, step + 1]
				var pos := Vector2(PATH_POS[step].x, PATH_POS[step].y * sign)
				var entry: Dictionary = plan[side]
				var list: Array = entry["effects"]
				_add(result, id, branch, {"name": entry["name"], "arg": entry.get("arg", ""), "effects": list[step % list.size()]}, _place(pos, angle), previous)
				previous = id
			var end_id := "%s_%s_end" % [branch, side]
			var end: Dictionary = plan[side + "_end"]
			_add(result, end_id, branch, end, _place(Vector2(END_POS.x, END_POS.y * sign), angle), previous,
					end.get("kind", "notable"))
	return result


## Plan gałęzi: z BRANCHES albo (mechaniki) złożony z MECH_* i nazw mechanik.
static func _plan(branch: String) -> Dictionary:
	if BRANCHES.has(branch):
		return BRANCHES[branch]
	var mechanic: String = Dungeons.MECHANICS[branch]["name"]
	return {
		"root": {"name": mechanic, "effects": {"weight:" + branch: MECH_WEIGHT}},
		"a": {"name": "%s - częściej", "arg": mechanic, "effects": [{"weight:" + branch: MECH_WEIGHT}]},
		"a_end": {"name": MECHANIC_KEYSTONES[branch], "effects": {"forced:" + branch: 1.0}, "kind": "keystone"},
		"b": {"name": "%s - mocniej", "arg": mechanic, "effects": [{"power:" + branch: MECH_POWER}]},
		"b_end": {"name": MECHANIC_NOTABLES[branch], "effects": {"power:" + branch: MECH_POWER_NOTABLE}},
	}


static func _place(local: Vector2, angle: float) -> Vector2:
	return Vector2.from_angle(angle) * local.x + Vector2.from_angle(angle + PI / 2.0) * local.y


static func _add(result: Dictionary, id: String, branch: String, data: Dictionary, pos: Vector2, link: String,
		kind := "small") -> void:
	result[id] = {"pos": pos, "links": [link] as Array[String], "kind": kind,
			"branch": branch, "name": data["name"], "arg": data.get("arg", ""), "effects": data["effects"]}
	(result[link]["links"] as Array[String]).append(id)


static func has_node(id: String) -> bool:
	return nodes().has(id)


## Nazwa węzła do pokazania (wzór z "arg" - np. „%s - częściej” z nazwą mechaniki).
static func node_name(id: String) -> String:
	if not has_node(id):
		return ""
	var node: Dictionary = nodes()[id]
	return Lang.t(node["name"]) % Lang.t(node["arg"]) if node["arg"] != "" else Lang.t(node["name"])


static func branch_name(branch: String) -> String:
	if BRANCH_NAMES.has(branch):
		return Lang.t(BRANCH_NAMES[branch])
	return Lang.t(Dungeons.MECHANICS[branch]["name"]) if Dungeons.MECHANICS.has(branch) else ""


# ---------------------------------------------------------------- wybieranie i cofanie
## Czy węzeł można wybrać: jeszcze niewybrany i połączony z wybranym (albo ze startem).
static func can_allocate(chosen: Array, id: String) -> bool:
	if not has_node(id) or id == START or chosen.has(id):
		return false
	for other: String in nodes()[id]["links"]:
		if other == START or chosen.has(other):
			return true
	return false


## Czy węzeł można cofnąć: wybrany, a bez niego reszta wybranych nadal łączy się ze startem.
static func can_refund(chosen: Array, id: String) -> bool:
	if not chosen.has(id):
		return false
	var rest := chosen.duplicate()
	rest.erase(id)
	return connected(rest).size() == rest.size()


## Wybrane węzły, do których da się dojść od startu przez inne wybrane (pozostałe - odcięte).
static func connected(chosen: Array) -> Array[String]:
	var seen: Array[String] = []
	var queue: Array[String] = [START]
	while not queue.is_empty():
		var id: String = queue.pop_back()
		for other: String in nodes()[id]["links"]:
			if chosen.has(other) and not seen.has(other):
				seen.append(other)
				queue.append(other)
	return seen


static func refund_cost(player_level: int) -> int:
	return REFUND_GOLD_PER_LEVEL * maxi(player_level, 1)


static func reset_cost(player_level: int, spent: int) -> int:
	return RESET_GOLD_PER_LEVEL * maxi(player_level, 1) * spent


# ---------------------------------------------------------------- premie
## Łączne premie wybranych węzłów: "weight:*" mnożą się, "forced:*" - 1, reszta się sumuje.
static func effects(chosen: Array) -> Dictionary:
	var total := {}
	for id: String in chosen:
		if not has_node(id):
			continue
		var node_effects: Dictionary = nodes()[id]["effects"]
		for key: String in node_effects:
			var value := float(node_effects[key])
			if key.begins_with("weight:"):
				total[key] = float(total.get(key, 1.0)) * value
			elif key.begins_with("forced:"):
				total[key] = 1.0
			else:
				total[key] = float(total.get(key, 0.0)) + value
	return total


## Premie mechanik dla Dungeons.roll_mechanics: {"weights", "extra", "forced", "power"} (moc - 1 + suma premii).
static func mechanic_bonus(tree: Dictionary) -> Dictionary:
	var weights := {}
	var forced: Array[String] = []
	var power := {}
	for key: String in tree:
		var parts := key.split(":")
		if parts.size() != 2:
			continue
		match parts[0]:
			"weight":
				weights[parts[1]] = float(tree[key])
			"forced":
				forced.append(parts[1])
			"power":
				power[parts[1]] = 1.0 + float(tree[key])
	return {"weights": weights, "forced": forced, "power": power,
			"extra": [float(tree.get("extra2", 0.0)), float(tree.get("extra3", 0.0))]}


## Mnożnik lochu z drzewka (klucze MULT_KEYS; 1 - bez zmian).
static func mult(tree: Dictionary, key: String) -> float:
	return 1.0 + float(tree.get(key, 0.0)) if key in MULT_KEYS else 1.0


## Premia dodawana do lochu z drzewka (klucze ADD_KEYS; 0 - bez zmian).
static func added(tree: Dictionary, key: String) -> float:
	return float(tree.get(key, 0.0)) if key in ADD_KEYS else 0.0


static func idol_slots(tree: Dictionary) -> int:
	return mini(roundi(float(tree.get("idol_slot", 0.0))), MAX_IDOL_SLOTS)


## Premia Błogosławieństwa Watry do łupu i doświadczenia przy `cleared_in_area` oczyszczonych węzłach obszaru.
static func blessing_bonus(tree: Dictionary, cleared_in_area: int) -> float:
	return float(tree.get("bless_flat", 0.0)) + float(tree.get("bless_node", 0.0)) * cleared_in_area


## Premie aktywnej zakładki prosto z zapisu postaci (słownik Boons.get_save_data) - World czyta je, zanim postać
## wczyta swoje dane.
static func effects_from_save(boons_data: Dictionary) -> Dictionary:
	var tabs: Array = boons_data.get("watra_tabs", [])
	var tab := int(boons_data.get("watra_tab", 0))
	if tab < 0 or tab >= tabs.size():
		return {}
	return effects(tabs[tab] as Array)


# ---------------------------------------------------------------- opisy
static func effect_lines(node_effects: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var keys := node_effects.keys()
	keys.sort()
	for key: String in keys:
		var value := float(node_effects[key])
		var parts := key.split(":")
		if parts.size() == 2:
			var mechanic := Lang.t(Dungeons.MECHANICS[parts[1]]["name"]) if Dungeons.MECHANICS.has(parts[1]) else parts[1]
			match parts[0]:
				"weight":
					lines.append(Lang.t("%s: losowane %d%% częściej") % [mechanic, roundi((value - 1.0) * 100.0)])
				"forced":
					lines.append(Lang.t("%s: w każdym lochu") % mechanic)
				"power":
					lines.append(Lang.t("%s: +%d%% mocy (%s)") % [mechanic, roundi(value * 100.0),
							Lang.t(POWER_TEXTS.get(parts[1], ""))])
		elif key == "bless_node":
			lines.append(Lang.t(EFFECT_TEXTS[key]) % String.num(value * 100.0, 2))
		elif EFFECT_TEXTS.has(key):
			lines.append(Lang.t(EFFECT_TEXTS[key]) % (roundi(value * 100.0) if key in PERCENT_KEYS else roundi(value)))
	return lines


static func node_lines(id: String) -> Array[String]:
	if not has_node(id):
		return []
	if id == START:
		return [Lang.t("Środek drzewka. Wybieraj węzły połączone z już wybranymi.")]
	return effect_lines(nodes()[id]["effects"])
