class_name WatraTree
## Drzewko Watry (drzewko lochów) - końcówka gry jak drzewko atlasu w Path of Exile. Punkty Watry zdobywa się za
## oczyszczone węzły Mapy Nawii i bossów szczytowych (Boons.watra_points), a wydaje na węzły tego drzewka: każdy kosztuje
## 1 punkt i można go wybrać tylko obok węzła już wybranego (start - Watra w środku - jest wybrany zawsze). Węzłów jest
## ponad dwa razy więcej niż punktów z całej mapy, więc trzeba wybierać, w co iść.
## Drzewko ma 3 zakładki (Boons.watra_tabs): każda ma pełną, osobną pulę punktów, działa tylko wybrana. Zakładkę zmienia
## się za darmo poza lochem; loch zapamiętuje premie z chwili wejścia (Dungeons.config, klucz "tree").
## Wybrane węzły cofa się za złoto: pojedynczy węzeł z końca ścieżki (REFUND_GOLD_PER_LEVEL) albo całą zakładkę
## naraz, taniej w przeliczeniu na węzeł (RESET_GOLD_PER_LEVEL).
##
## Układ (krok 6 planu z docs/plan_drzewek.md, wersja VERSION): skupiska porozrzucane po całym drzewku. Każdy z 12
## tematów (SECTORS - 8 mechanik lochów z Dungeons.MECHANICS i 4 ogólne: Splot mechanik, Łup i skarbiec, Bożki,
## Błogosławieństwo Watry) ma 4 skupiska (CLUSTER_GROUPS "a"-"d": 6 małych węzłów w kółku i węzeł znaczący w środku)
## w 3 pierścieniach (CLUSTER_RINGS), mniej więcej co ćwierć obrotu od siebie - po drodze do swoich skupisk gracz
## przechodzi przez cudze, więc musi wybierać najlepszą ścieżkę. Za skupiskiem "d" (zewnętrzny pierścień) - węzeł
## kluczowy. Skupiska łączą ścieżki neutralnych węzłów (PATH_EFFECTS - drobne premie: łup, potwory, doświadczenie,
## złoto), a Watrę - pierścień Iskier (INNER).
## W skupiskach mechanik: "a" - mechanika częściej (waga w Dungeons.roll_mechanics) z węzłem „podwójna mechanika”
## ("dup:<mechanika>"), "b", "c", "d" - mechanika mocniej ("power:<mechanika>", Dungeon.mechanic_power) z węzłami, które
## zmieniają działanie mechaniki (MECHANIC_NOTABLES - np. elitarne zjawy w Uroczysku), a węzeł kluczowy wymusza
## mechanikę w każdym lochu za cenę: żadnej innej losowej mechaniki ("forced:" i "only:").
## Premie węzłów (effects): "weight:*" mnożą się, "forced:*" i "only:*" włączają się na stałe, reszta się sumuje.

const START := "start"
const TABS := 3
## Wersja układu drzewka w zapisie (Boons): starsza - wszystkie węzły wracają jako punkty (Boons.tree_refunded).
const VERSION := 2
## Ile złota kosztuje cofnięcie jednego węzła i każdego węzła przy czyszczeniu zakładki (za każdy poziom postaci).
const REFUND_GOLD_PER_LEVEL := 20
const RESET_GOLD_PER_LEVEL := 8
## Najwięcej dodatkowych slotów na bożki z drzewka (DungeonWindow trzyma tyle zapasowych pól).
const MAX_IDOL_SLOTS := 2

## Tematy drzewka; kolejność wyznacza miejsca skupisk w pierścieniach (CLUSTER_SPREAD).
const SECTORS: Array[String] = ["chests", "general", "shrine", "elites", "loot", "crystal",
		"uroczysko", "idols", "zertwa", "skarbnik", "mist", "bless"]
const NEUTRAL := "neutral"
## Kolory tematów - wyraźnie różne, żeby skupiska dało się rozpoznać na całym drzewku.
const BRANCH_COLORS := {
	"chests": Color(0.95, 0.7, 0.3), "skarbnik": Color(1.0, 0.95, 0.35), "crystal": Color(1.0, 0.45, 0.2),
	"zertwa": Color(0.9, 0.22, 0.3), "elites": Color(1.0, 0.5, 0.75), "uroczysko": Color(0.35, 0.95, 0.75),
	"loot": Color(0.5, 0.85, 0.3), "shrine": Color(0.45, 0.75, 1.0), "mist": Color(0.65, 0.55, 1.0),
	"general": Color(0.82, 0.82, 0.88), "idols": Color(0.72, 0.5, 0.35), "bless": Color(1.0, 0.8, 0.65),
	"neutral": Color(0.55, 0.5, 0.45),
}
## Nazwy tematów spoza mechanik (tematy mechanik biorą nazwę z Dungeons.MECHANICS).
const BRANCH_NAMES := {"general": "Splot mechanik", "idols": "Bożki", "loot": "Łup i skarbiec",
		"bless": "Błogosławieństwo Watry", "neutral": "Ścieżki Watry"}

## Skupiska: "a" w pierścieniu przy Watrze, "b" i "c" w środkowym, "d" w zewnętrznym. Pierścień: promień, liczba miejsc
## i przesunięcie kąta (w miejscach); temat nr t zajmuje miejsce SPREAD[grupa] + t * STEP[grupa] - skupiska jednego
## tematu leżą mniej więcej co ćwierć obrotu (0, 97, 202, 285 stopni od skupiska "a").
const CLUSTER_GROUPS: Array[String] = ["a", "b", "c", "d"]
const CLUSTER_RINGS := {"a": [6.5, 12, 0.0], "b": [12.5, 24, 0.5], "c": [12.5, 24, 0.5], "d": [17.5, 12, 0.5]}
const CLUSTER_SPREAD := {"a": 0, "b": 6, "c": 13, "d": 9}
const CLUSTER_STEP := {"a": 1, "b": 2, "c": 2, "d": 1}
## Małe węzły skupiska w kółku o tym promieniu (węzeł znaczący w środku, połączony z węzłem od strony zewnętrznej).
const CLUSTER_SMALLS := 6
const CLUSTER_RADIUS := 1.0
## Węzeł kluczowy tyle dalej od Watry niż środek skupiska "d".
const KEYSTONE_OFFSET := 2.7
## Pierścień Iskier wokół Watry (połączony ze startem i ze skupiskami "a").
const INNER_RADIUS := 2.4
## Odstęp węzłów na ścieżkach między skupiskami (najwyżej) i najdłuższe połączenie bez węzła pośrodku.
const PATH_STEP := 1.2
const DIRECT_LINK := 1.7
## Premie neutralnych węzłów: pierścień Iskier i ścieżki (kolejne węzły biorą kolejne pozycje listy).
const INNER_EFFECTS: Array = [{"loot": 0.02}, {"count": 0.02}, {"xp": 0.02}, {"gold": 0.04}]
const PATH_EFFECTS: Array = [{"loot": 0.01}, {"xp": 0.01}, {"count": 0.01}, {"gold": 0.02}, {"quality": 0.01},
		{"treasure": 0.02}]
const INNER_NAME := "Iskra Watry"
const PATH_NAME := "Ścieżka Watry"

## Skupiska mechanik: premie małych węzłów ("a" - waga, reszta - moc).
const MECH_WEIGHT_A := 1.1
const MECH_POWER := 0.05
const MECH_POWER_KEYSTONE := 0.25
## Szansa na drugą sztukę mechaniki z węzła „podwójna mechanika” (A).
const MECH_DUP := 0.3

## Tematy mechanik: węzły znaczące i kluczowe - {miejsce: {"name", "effects"}}. Bez wpisu "a_n" - „podwójna mechanika”.
## Klucze premii zmieniających mechaniki czytają skrypty mechanik (WatraTree.value / WatraTree.has_flag).
const MECHANIC_NOTABLES := {
	"chests": {
		"a_n": {"name": "Pełne Piwnice"},
		"b_n": {"name": "Skrzynia-Mimik", "effects": {"chest_mimic": 0.25}},
		"c_n": {"name": "Skrzynie Bogów", "effects": {"chest_special": 1.0}},
		"d_n": {"name": "Okute Wieka", "effects": {"chest_traits": 1.0}},
		"k": {"name": "Skarbiec Przodków"},
	},
	"shrine": {
		"a_n": {"name": "Para Kapliczek"},
		"b_n": {"name": "Trwała Łaska", "effects": {"shrine_long": 1.0}},
		"c_n": {"name": "Dwoista Łaska", "effects": {"shrine_stack": 1.0}},
		"d_n": {"name": "Łaska Bogów", "effects": {"shrine_power": 0.5}},
		"k": {"name": "Święty Gaj"},
	},
	"elites": {
		"a_n": {"name": "Zastępy Wybrańców"},
		"b_n": {"name": "Bożkowe Piętno", "effects": {"elite_idol": 1.0}},
		"c_n": {"name": "Czempion", "effects": {"elite_champion": 1.0}},
		"d_n": {"name": "Łowy na Wybrańców", "effects": {"elite_loot": 1.0}},
		"k": {"name": "Zew Wybrańców"},
	},
	"crystal": {
		"a_n": {"name": "Długa Obrona", "effects": {"crystal_waves": 1.0}},
		"b_n": {"name": "Czysty Żar", "effects": {"crystal_stones": 0.5}},
		"c_n": {"name": "Ciepło Kryształu", "effects": {"crystal_heal": 1.0}},
		"d_n": {"name": "Twardy Kryształ", "effects": {"crystal_health": 0.5}},
		"k": {"name": "Serce Kryształu"},
	},
	"uroczysko": {
		"a_n": {"name": "Bliźniacze Kręgi"},
		"b_n": {"name": "Zimne Runy", "effects": {"uro_elites": 0.08}},
		"c_n": {"name": "Strażnik Kręgu", "effects": {"uro_hold": 1.0}},
		"d_n": {"name": "Upiorny Książę", "effects": {"uro_prince": 1.0}},
		"k": {"name": "Brama Nawii"},
	},
	"zertwa": {
		"a_n": {"name": "Dwa Kręgi"},
		"b_n": {"name": "Hojna Żertwa", "effects": {"zer_offer": 1.0}},
		"c_n": {"name": "Krew Wybrańców", "effects": {"zer_elite": 1.0}},
		"d_n": {"name": "Dwoisty Talizman", "effects": {"zer_dual": 0.25}},
		"k": {"name": "Krwawa Danina"},
	},
	"skarbnik": {
		"a_n": {"name": "Bracia Skarbnicy"},
		"b_n": {"name": "Łaskawe Kości", "effects": {"ska_reroll": 1.0}},
		"c_n": {"name": "Chciwość Skarbnika", "effects": {"ska_again": 0.35}},
		"d_n": {"name": "Kościany Worek", "effects": {"ska_bones": 1.0}},
		"k": {"name": "Pakt ze Skarbnikiem"},
	},
	"mist": {
		"a_n": {"name": "Rwąca Mgła", "effects": {"mist_fast": 1.0}},
		"b_n": {"name": "Żyła Krzesiw", "effects": {"mist_level": 3.0, "mist_great": 2.0}},
		"c_n": {"name": "Zimna Pamięć", "effects": {"mist_keep": 0.2, "mist_step": 5.0}},
		"d_n": {"name": "Kamienie z Mgły", "effects": {"mist_supports": 0.3}},
		"k": {"name": "Bezdenna Mgła", "effects": {"mist_max": 5.0}},
	},
}
## Skupiska mechanik: premie małych węzłów skupisk "c" i "d" zamiast samej mocy - dla Mgły Nawii.
const MECHANIC_SMALLS := {
	"mist": {"c": {"mist_keep": 0.02}, "d": {"mist_supports": 0.05}},
}
## Tematy ogólne: {skupisko ("a"-"d" - małe węzły) albo węzeł ("a_n"… - znaczący, "k" - kluczowy): {"name", "effects"}}.
const SECTOR_PLANS := {
	"general": {
		"a": {"name": "Druga mechanika", "effects": {"extra2": 0.03}},
		"a_n": {"name": "Gęsty Splot", "effects": {"extra2": 0.08}},
		"b": {"name": "Trzecia mechanika", "effects": {"extra3": 0.02}},
		"b_n": {"name": "Potrójny Węzeł", "effects": {"extra3": 0.06}},
		"c": {"name": "Moc mechanik", "effects": {"all_power": 0.03}},
		"c_n": {"name": "Wspólny Splot", "effects": {"all_power": 0.1}},
		"d": {"name": "Czwarta mechanika", "effects": {"extra4": 0.03}},
		"d_n": {"name": "Poczwórny Węzeł", "effects": {"extra4": 0.1}},
		"k": {"name": "Wielki Splot", "effects": {"extra2": 1.0, "all_power": -0.25}},
	},
	"loot": {
		"a": {"name": "Łup lochów", "effects": {"loot": 0.04}},
		"a_n": {"name": "Dar Legend", "effects": {"legend": 0.5, "loot": 0.05}},
		"b": {"name": "Złoto i nauka", "effects": {"gold": 0.08, "xp": 0.03}},
		"b_n": {"name": "Kamienna Żyła", "effects": {"gems": 0.5}},
		"c": {"name": "Bogatszy skarbiec", "effects": {"treasure": 0.06}},
		"c_n": {"name": "Runiczny Skarbiec", "effects": {"vault_runes": 1.0}},
		"d": {"name": "Lepsze przedmioty", "effects": {"quality": 0.03}},
		"d_n": {"name": "Kunszt Przodków", "effects": {"item_level": 1.0}},
		"k": {"name": "Skarb Strażnika", "effects": {"treasure": 1.0, "vault_runes": 2.0, "loot": -0.2}},
	},
	"idols": {
		"a": {"name": "Częstsze bożki", "effects": {"idol_drop": 0.1}},
		"a_n": {"name": "Nowy Ołtarz", "effects": {"idol_slot": 1.0}},
		"b": {"name": "Rzadsze bożki", "effects": {"idol_rarity": 0.15}},
		"b_n": {"name": "Prastare Dłonie", "effects": {"idol_ancient": 1.0}},
		"c": {"name": "Częstsze bożki", "effects": {"idol_drop": 0.1}},
		"c_n": {"name": "Drugi Ołtarz", "effects": {"idol_slot": 1.0}},
		"d": {"name": "Rzadsze bożki", "effects": {"idol_rarity": 0.15}},
		"d_n": {"name": "Wieczny Bożek", "effects": {"idol_keep": 0.15}},
		"k": {"name": "Prastary Panteon", "effects": {"idol_ancient": 2.0, "idol_rarity": 0.6, "idol_drop": -0.35}},
	},
	"bless": {
		"a": {"name": "Ciepło węzłów", "effects": {"bless_node": 0.0025}},
		"a_n": {"name": "Płomień Krain", "effects": {"bless_flat": 0.06}},
		"b": {"name": "Złoto krain", "effects": {"bless_gold": 0.06}},
		"b_n": {"name": "Hojna Watra", "effects": {"bless_gold": 0.15, "bless_flat": 0.04}},
		"c": {"name": "Ciepło krain", "effects": {"bless_flat": 0.02}},
		"c_n": {"name": "Ognisko Pamięci", "effects": {"bless_node": 0.01}},
		"d": {"name": "Złoto krain", "effects": {"bless_gold": 0.05}},
		"d_n": {"name": "Złote Żniwa", "effects": {"bless_gold": 0.1, "bless_flat": 0.03}},
		"k": {"name": "Żywy Płomień", "effects": {"bless_flat": 0.25, "loot": -0.1}},
	},
}

## Klucze premii mnożących lochy (Dungeons.mult: 1 + suma) i dodawanych (Dungeons.added).
const MULT_KEYS: Array[String] = ["loot", "gold", "xp", "gems", "legend", "treasure", "count"]
const ADD_KEYS: Array[String] = ["item_level", "quality", "vault_runes"]
## Opisy premii; %d - liczba (procenty dla PERCENT_KEYS). Klucze z FLAG_KEYS mają opis bez liczby.
const EFFECT_TEXTS := {
	"extra2": "+%d%% szansy na drugą mechanikę w lochu", "extra3": "+%d%% szansy na trzecią mechanikę w lochu",
	"extra4": "+%d%% szansy na czwartą mechanikę w lochu",
	"all_power": "+%d%% mocy wszystkich mechanik lochów",
	"idol_drop": "Bożki wypadają o %d%% częściej", "idol_rarity": "+%d%% szansy na rzadkie i legendarne bożki",
	"idol_ancient": "Prastare bożki wypadają o %d%% częściej", "idol_slot": "+%d slot na bożki w oknie lochów",
	"idol_keep": "%d%% szansy, że bożek w slocie nie zużyje się przy wejściu do lochu",
	"loot": "+%d%% przedmiotów z potworów w lochach", "gold": "+%d%% złota w lochach", "xp": "+%d%% doświadczenia w lochach",
	"count": "+%d%% potworów w lochach",
	"gems": "+%d%% kamieni szlachetnych w lochach", "legend": "+%d%% szansy na legendy w lochach",
	"treasure": "+%d%% łupu ze skarbca strażnika", "quality": "+%d%% szansy na lepszą rzadkość przedmiotów z lochów",
	"item_level": "+%d do poziomu przedmiotów z lochów", "vault_runes": "+%d runy w skarbcu strażnika",
	"bless_flat": "Błogosławieństwo Watry: +%d%% łupu i doświadczenia",
	"bless_node": "Błogosławieństwo Watry: +%s%% łupu i doświadczenia za każdy oczyszczony węzeł obszaru",
	"bless_gold": "Błogosławieństwo Watry: +%d%% złota",
	"mist_step": "Mgła Nawii: każdy stopień gęstnieje o %d s dłużej",
	"mist_keep": "Mgła Nawii: po śmierci zostaje +%d%% puli",
	"mist_supports": "Mgła Nawii: +%d%% kamieni wsparcia i krzesiw",
	"mist_great": "Mgła Nawii: Wielkie Krzesiwa od gęstości niższej o %d",
	"mist_level": "Mgła Nawii: +%d do poziomu kamieni wsparcia",
	"mist_max": "Mgła Nawii: gęstość rośnie o %d stopni dalej",
	"mist_fast": "Mgła Nawii gęstnieje dwa razy szybciej - groźniej i hojniej",
	"chest_mimic": "Skrzynie: %d%% szansy na skrzynię-mimika - ożywa i walczy, a po pokonaniu sypie potrójny łup",
	"chest_special": "Skrzynie: nowe rodzaje - skrzynie pełne bożków, run albo talizmanów",
	"chest_traits": "Skrzynie: cechy (strzeżona, obfita, cenna) trafiają się %d%% częściej",
	"shrine_long": "Kapliczki: dar działa do końca lochu",
	"shrine_stack": "Kapliczki: nowy dar nie zabiera poprzedniego - działają naraz",
	"shrine_power": "Kapliczki: dary +%d%% silniejsze",
	"elite_idol": "Elity: +1 cecha, ale każda elita upuszcza bożka",
	"elite_champion": "Elity: w każdym lochu z elitami jeden Czempion - wszystkie cechy, dwa razy więcej zdrowia, pewna legenda",
	"elite_loot": "Elity: +%d%% dodatkowego łupu z elit",
	"crystal_waves": "Kryształ Watry: +%d fala obrony i hojniejsza nagroda",
	"crystal_stones": "Kryształ Watry: +%d%% kamieni zaklinania z nagrody",
	"crystal_heal": "Kryształ Watry leczy gracza w pobliżu podczas obrony",
	"crystal_health": "Kryształ Watry: +%d%% zdrowia kryształu",
	"uro_elites": "Uroczysko: %d%% upiorów to elitarne zjawy z cechami - każda upuszcza runę",
	"uro_hold": "Uroczysko: krąg nie maleje, gdy stoisz przy menhirze",
	"uro_prince": "Uroczysko: gdy krąg gaśnie, wychodzi Upiorny Książę - krąg trwa do jego śmierci, upuszcza 3 runy",
	"zer_offer": "Krąg Żertwy: +%d talizman do wyboru",
	"zer_elite": "Krąg Żertwy: elity dają podwójną daninę",
	"zer_dual": "Krąg Żertwy: %d%% szansy, że talizman w ofercie ma dwa efekty legend",
	"ska_reroll": "Skarbnik: %d darmowe przelosowanie oferty (bez Kości)",
	"ska_again": "Skarbnik: po wygranych falach %d%% szansy na kolejnego Skarbnika w lochu",
	"ska_bones": "Skarbnik: Kości Skarbnika wypadają o %d%% częściej",
}
const PERCENT_KEYS: Array[String] = ["extra2", "extra3", "extra4", "all_power", "idol_drop", "idol_rarity", "idol_ancient",
		"idol_keep", "loot", "gold", "xp", "count", "gems", "legend", "treasure", "quality", "bless_flat", "bless_gold",
		"mist_keep", "mist_supports", "chest_mimic", "chest_traits", "shrine_power", "elite_loot", "crystal_stones",
		"crystal_health", "uro_elites", "zer_dual", "ska_again", "ska_bones"]
## Opisy ujemnych premii (cena węzłów kluczowych); bez wpisu - znak „+” zamienia się na „-”.
const NEGATIVE_TEXTS := {"idol_drop": "Bożki wypadają o %d%% rzadziej"}
## Co daje moc danej mechaniki (opis w podpowiedzi węzła).
const POWER_TEXTS := {
	"chests": "więcej skrzyń", "shrine": "więcej kapliczek", "elites": "więcej elitarnych potworów",
	"crystal": "hojniejszy Kryształ Watry", "uroczysko": "więcej run z Uroczyska",
	"zertwa": "więcej talizmanów do wyboru", "skarbnik": "więcej Skarbników",
	"mist": "bogatsza Skrzynia Mgły",
}
const FLAG_KEYS: Array[String] = ["mist_fast", "chest_special", "shrine_long", "shrine_stack", "elite_idol",
		"elite_champion", "crystal_heal", "uro_hold", "uro_prince", "zer_elite"]

static var _nodes := {}


## Wszystkie węzły: id -> {"pos", "links", "kind" (start / small / notable / keystone), "branch", "name", "arg",
## "effects"}.
static func nodes() -> Dictionary:
	if _nodes.is_empty():
		_nodes = _build()
	return _nodes


static func _build() -> Dictionary:
	var result := {}
	result[START] = {"pos": Vector2.ZERO, "links": [] as Array[String], "kind": "start", "branch": "", "name": "Watra",
			"arg": "", "effects": {}}
	var count := SECTORS.size()
	# pierścień Iskier wokół Watry
	for i in count:
		_add(result, "inner_%d" % i, Vector2.from_angle(_angle(i, count, 0.0)) * INNER_RADIUS, "small", NEUTRAL,
				{"name": INNER_NAME, "effects": INNER_EFFECTS[i % INNER_EFFECTS.size()]})
		_link(result, START, "inner_%d" % i)
	for i in count:
		_link(result, "inner_%d" % i, "inner_%d" % ((i + 1) % count))
	# skupiska: miejsce w pierścieniu -> id skupiska
	var slots := {}
	for t in count:
		var sector := SECTORS[t]
		for group: String in CLUSTER_GROUPS:
			var ring: Array = CLUSTER_RINGS[group]
			var slot: int = (int(CLUSTER_SPREAD[group]) + t * int(CLUSTER_STEP[group])) % int(ring[1])
			var angle := _angle(slot, ring[1], ring[2])
			var center := Vector2.from_angle(angle) * float(ring[0])
			var cluster := "%s_%s" % [sector, group]
			slots["%d_%d" % [roundi(float(ring[0])), slot]] = cluster
			for k in CLUSTER_SMALLS:
				var at := center + Vector2.from_angle(angle + TAU * k / CLUSTER_SMALLS) * CLUSTER_RADIUS
				_add(result, "%s_%d" % [cluster, k + 1], at, "small", sector, _slot_data(sector, "%s%d" % [group, k + 1]))
			for k in CLUSTER_SMALLS:
				_link(result, "%s_%d" % [cluster, k + 1], "%s_%d" % [cluster, (k + 1) % CLUSTER_SMALLS + 1])
			_add(result, cluster + "_n", center, "notable", sector, _slot_data(sector, group + "_n"))
			_link(result, cluster + "_n", cluster + "_1")
			if group == "d":
				_add(result, sector + "_k", center + Vector2.from_angle(angle) * KEYSTONE_OFFSET, "keystone", sector,
						_slot_data(sector, "k"))
				_link(result, sector + "_k", cluster + "_1")
	# ścieżki: Iskra -> skupisko "a" za nią, sąsiednie skupiska w pierścieniu, środkowy pierścień -> najbliższe "a",
	# zewnętrzny -> dwa najbliższe w środkowym
	var serial := [0]
	for i in count:
		_path(result, "inner_%d" % i, slots["7_%d" % i], serial)
	for i in count:
		_path(result, slots["7_%d" % i], slots["7_%d" % ((i + 1) % count)], serial)
	for j in 24:
		_path(result, slots["13_%d" % j], slots["13_%d" % ((j + 1) % 24)], serial)
		@warning_ignore("integer_division")
		_path(result, slots["13_%d" % j], slots["7_%d" % ((j + 1) / 2 % count)], serial)
	for m in count:
		_path(result, slots["18_%d" % m], slots["13_%d" % (2 * m)], serial)
		_path(result, slots["18_%d" % m], slots["13_%d" % (2 * m + 1)], serial)
	return result


## Kąt miejsca `slot` z `slots` w pierścieniu (`phase` - przesunięcie w miejscach), pierwsze u góry, dalej zgodnie ze
## wskazówkami zegara.
static func _angle(slot: float, slots: int, phase: float) -> float:
	return -PI / 2.0 + (slot + phase) * TAU / slots


## Ścieżka neutralnych węzłów od węzła albo skupiska `from` do skupiska `to` (od najbliższych sobie małych węzłów).
static func _path(result: Dictionary, from: String, to: String, serial: Array) -> void:
	var a := _port(result, from, _center(result, to))
	var b := _port(result, to, result[a]["pos"])
	a = _port(result, from, result[b]["pos"])
	var start: Vector2 = result[a]["pos"]
	var end: Vector2 = result[b]["pos"]
	var steps := 0 if start.distance_to(end) <= DIRECT_LINK else ceili(start.distance_to(end) / PATH_STEP) - 1
	var previous := a
	for i in steps:
		var id := "path_%d" % serial[0]
		_add(result, id, start.lerp(end, float(i + 1) / (steps + 1)), "small", NEUTRAL,
				{"name": PATH_NAME, "effects": PATH_EFFECTS[serial[0] % PATH_EFFECTS.size()]})
		serial[0] += 1
		_link(result, previous, id)
		previous = id
	_link(result, previous, b)


## Środek skupiska (jego węzeł znaczący) albo pozycja pojedynczego węzła.
static func _center(result: Dictionary, id: String) -> Vector2:
	return result[id + "_n"]["pos"] if result.has(id + "_n") else result[id]["pos"]


## Mały węzeł skupiska najbliżej punktu `toward` (pojedynczy węzeł - on sam).
static func _port(result: Dictionary, id: String, toward: Vector2) -> String:
	if result.has(id):
		return id
	var best := ""
	for k in CLUSTER_SMALLS:
		var node := "%s_%d" % [id, k + 1]
		if best == "" or (result[node]["pos"] as Vector2).distance_to(toward) < (result[best]["pos"] as Vector2).distance_to(toward):
			best = node
	return best


static func _add(result: Dictionary, id: String, pos: Vector2, kind: String, branch: String, data: Dictionary) -> void:
	result[id] = {"pos": pos, "links": [] as Array[String], "kind": kind, "branch": branch, "name": data["name"],
			"arg": data.get("arg", ""), "effects": data.get("effects", {})}


## Skupiska do rysowania: [{"id", "branch", "group", "center"}].
static func clusters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for sector in SECTORS:
		for group: String in CLUSTER_GROUPS:
			var id := "%s_%s" % [sector, group]
			result.append({"id": id, "branch": sector, "group": group, "center": nodes()[id + "_n"]["pos"]})
	return result


## Nazwa i premie węzła `slot` tematu `sector` ("a1"… - mały węzeł skupiska, "a_n"… - znaczący, "k" - kluczowy).
static func _slot_data(sector: String, slot: String) -> Dictionary:
	if SECTOR_PLANS.has(sector):
		var plan: Dictionary = SECTOR_PLANS[sector]
		return plan[slot] if plan.has(slot) else plan[slot.left(1)]
	var mechanic: String = Dungeons.MECHANICS[sector]["name"]
	var notables: Dictionary = MECHANIC_NOTABLES[sector]
	if notables.has(slot):
		var entry: Dictionary = notables[slot].duplicate(true)
		var effects: Dictionary = entry.get("effects", {})
		if slot == "a_n" and effects.is_empty():
			effects["dup:" + sector] = MECH_DUP
		elif slot == "k":
			effects["forced:" + sector] = 1.0
			effects["only:" + sector] = 1.0
			effects["power:" + sector] = MECH_POWER_KEYSTONE
		elif slot != "a_n":
			effects["power:" + sector] = MECH_POWER
		entry["effects"] = effects
		return entry
	var smalls: Dictionary = MECHANIC_SMALLS.get(sector, {})
	var group := slot.left(1)
	if smalls.has(group):
		return {"name": "%s - mocniej", "arg": mechanic, "effects": smalls[group]}
	match group:
		"a":
			return {"name": "%s - częściej", "arg": mechanic, "effects": {"weight:" + sector: MECH_WEIGHT_A}}
	return {"name": "%s - mocniej", "arg": mechanic, "effects": {"power:" + sector: MECH_POWER}}


static func _link(result: Dictionary, a: String, b: String) -> void:
	if not (result[a]["links"] as Array[String]).has(b):
		(result[a]["links"] as Array[String]).append(b)
		(result[b]["links"] as Array[String]).append(a)


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
## Łączne premie wybranych węzłów: "weight:*" mnożą się, "forced:*" i "only:*" - 1, reszta się sumuje.
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
			elif key.begins_with("forced:") or key.begins_with("only:"):
				total[key] = 1.0
			else:
				total[key] = float(total.get(key, 0.0)) + value
	return total


## Premie mechanik dla Dungeons.roll_mechanics: {"weights", "extra", "forced", "power" (1 + suma premii),
## "dup" {mechanika: szansa na drugą sztukę}, "only" (true - bez losowych mechanik, tylko wymuszone)}.
## "all_power" dodaje moc każdej mechanice (także ujemną - Wielki Splot).
static func mechanic_bonus(tree: Dictionary) -> Dictionary:
	var weights := {}
	var forced: Array[String] = []
	var power := {}
	var dup := {}
	var only := false
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
			"dup":
				dup[parts[1]] = float(tree[key])
			"only":
				only = true
	var shared := float(tree.get("all_power", 0.0))
	if shared != 0.0:
		for id: String in Dungeons.MECHANICS:
			power[id] = float(power.get(id, 1.0)) + shared
	return {"weights": weights, "forced": forced, "power": power, "dup": dup, "only": only,
			"extra": [float(tree.get("extra2", 0.0)), float(tree.get("extra3", 0.0)), float(tree.get("extra4", 0.0))]}


## Wartość premii zmieniającej mechanikę (np. "uro_elites"; 0 - brak).
static func value(tree: Dictionary, key: String) -> float:
	return float(tree.get(key, 0.0))


static func has_flag(tree: Dictionary, key: String) -> bool:
	return value(tree, key) > 0.0


## Mnożnik lochu z drzewka (klucze MULT_KEYS; 1 - bez zmian, nie mniej niż 0,1).
static func mult(tree: Dictionary, key: String) -> float:
	return maxf(1.0 + float(tree.get(key, 0.0)), 0.1) if key in MULT_KEYS else 1.0


## Premia dodawana do lochu z drzewka (klucze ADD_KEYS; 0 - bez zmian).
static func added(tree: Dictionary, key: String) -> float:
	return float(tree.get(key, 0.0)) if key in ADD_KEYS else 0.0


static func idol_slots(tree: Dictionary) -> int:
	return mini(roundi(float(tree.get("idol_slot", 0.0))), MAX_IDOL_SLOTS)


## Premia Błogosławieństwa Watry do łupu i doświadczenia przy `cleared_in_area` oczyszczonych węzłach obszaru.
static func blessing_bonus(tree: Dictionary, cleared_in_area: int) -> float:
	return float(tree.get("bless_flat", 0.0)) + float(tree.get("bless_node", 0.0)) * cleared_in_area


## Premie aktywnej zakładki prosto z zapisu postaci (słownik Boons.get_save_data) - World czyta je, zanim postać
## wczyta swoje dane. Zapis ze starym układem drzewka - bez premii (punkty wróciły do rozdania).
static func effects_from_save(boons_data: Dictionary) -> Dictionary:
	if int(boons_data.get("watra_tree", 1)) < VERSION:
		return {}
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
		var amount := float(node_effects[key])
		var parts := key.split(":")
		if parts.size() == 2:
			var mechanic := Lang.t(Dungeons.MECHANICS[parts[1]]["name"]) if Dungeons.MECHANICS.has(parts[1]) else parts[1]
			match parts[0]:
				"weight":
					lines.append(Lang.t("%s: losowane %d%% częściej") % [mechanic, roundi((amount - 1.0) * 100.0)])
				"forced":
					lines.append(Lang.t("%s: w każdym lochu") % mechanic)
				"only":
					lines.append(Lang.t("Żadnych innych losowych mechanik w lochu"))
				"power":
					lines.append(Lang.t("%s: +%d%% mocy (%s)") % [mechanic, roundi(amount * 100.0),
							Lang.t(POWER_TEXTS.get(parts[1], ""))])
				"dup":
					lines.append(Lang.t("%s: %d%% szansy na podwójną mechanikę w lochu") % [mechanic, roundi(amount * 100.0)])
		elif key == "bless_node":
			lines.append(Lang.t(EFFECT_TEXTS[key]) % String.num(amount * 100.0, 2))
		elif key in FLAG_KEYS:
			lines.append(Lang.t(EFFECT_TEXTS[key]))
		elif EFFECT_TEXTS.has(key):
			var number := roundi(amount * 100.0) if key in PERCENT_KEYS else roundi(amount)
			if number < 0 and NEGATIVE_TEXTS.has(key):
				lines.append(Lang.t(NEGATIVE_TEXTS[key]) % -number)
			else:
				var text := Lang.t(EFFECT_TEXTS[key]) % absi(number)
				lines.append(text.replace("+", "-") if number < 0 else text)
	return lines


static func node_lines(id: String) -> Array[String]:
	if not has_node(id):
		return []
	if id == START:
		return [Lang.t("Środek drzewka. Wybieraj węzły połączone z już wybranymi.")]
	return effect_lines(nodes()[id]["effects"])
