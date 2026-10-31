class_name HelpWindow
extends PanelContainer
## Okno pomocy (przycisk "?"): sterowanie i najważniejsze wskazówki do gry.

const CONTROLS := [
	["WASD / strzałki", "ruch"],
	["LPM / PPM / Q E R Z X", "pasek umiejętności (domyślnie: atak, umiejętność broni, uderzenie)"],
	["Atak po uderzeniu", "dodatkowy cios - combo (półksiężyc / salwa / fala piorunów)"],
	["1 - 0", "pasek przedmiotów (na start mikstury życia i many)"],
	["Spacja", "zryw (chwilowa nietykalność)"],
	["F", "rozmowa, handel, ścinanie drzew, rozbijanie głazów"],
	["I", "ekwipunek i zaklinanie"],
	["C", "postać i atrybuty"],
	["K", "umiejętności"],
	["J", "dziennik zadań"],
	["L", "encyklopedia (legendy, bossowie, potwory, zioła, przedmioty)"],
	["M", "mapa"],
	["Esc", "zamknij okna / menu gry"],
]

const TIPS := [
	"Osada Ostoja jest bezpieczna - potwory nie wchodzą za palisadę.",
	"Przedmioty przeciągniesz z plecaka na pasek 1-0, a umiejętności z okna K na pasek nad nim. PPM na slocie go opróżnia.",
	"Czerwona poświata na ziemi zapowiada atak bossa. Zejdź z niej albo użyj zrywu.",
	"Każdy poziom daje punkt atrybutu: siła wzmacnia broń białą, zręczność łuki, inteligencja magię.",
	"Umiejętności i regenerację kupisz za złoto - działają tylko z bronią swojego rodzaju.",
	"Zaklinaj ekwipunek kamieniami. Od +15 potrzebne są kamienie doskonałe.",
	"Uświęcone kamienie dają pewne zaklęcie, a kamienie miłosierdzia chronią przed spadkiem poziomu.",
	"Serca goblinów i skóry wilków sprzedasz u handlarzy za złoto.",
	"Drzewa zetniesz, a głazy rozbijesz klawiszem F - odrastają po kilku minutach albo od razu po odpoczynku w karczmie.",
	"W drewnie trafiają się uświęcone kamienie, a w głazach kamienie do zaklinania.",
	"W każdej krainie rośnie inne zioło (iskierki nad rośliną, F - zerwij). Zielarka z lecznicy uwarzy z nich mikstury wzmacniające.",
	"Łowiska są w prawym górnym i lewym dolnym rogu mapy. Zwierzyna ucieka - skóry i poroże sprzedasz, a mięso zjesz (PPM).",
	"Sołtys Mirosław zleca zbieranie surowców - liczy się to, co masz w plecaku i w magazynie.",
	"Magazynier przechowa twoje rzeczy. Im więcej drewna i kamienia złożysz, tym większe stosy przy magazynie.",
	"Wódz goblinów czeka w lewym górnym rogu mapy, Wilk Alfa - w prawym dolnym.",
	"Złote \"!\" nad głową oznacza zadanie do przyjęcia, złote \"?\" - nagrodę do odebrania.",
]


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Pomoc"))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	box.add_child(columns)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 1)
	columns.add_child(controls)
	controls.add_child(UiStyle.label("Sterowanie", 8, UiStyle.TITLE_COLOR))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 0)
	controls.add_child(grid)
	for entry: Array in CONTROLS:
		grid.add_child(UiStyle.label(entry[0], 7, UiStyle.TITLE_COLOR))
		grid.add_child(UiStyle.label(entry[1], 7, UiStyle.TEXT_COLOR))

	columns.add_child(VSeparator.new())

	var tips := VBoxContainer.new()
	tips.add_theme_constant_override("separation", 2)
	columns.add_child(tips)
	tips.add_child(UiStyle.label("Wskazówki", 8, UiStyle.TITLE_COLOR))
	for tip: String in TIPS:
		var label := UiStyle.label("• " + tip, 7, UiStyle.TEXT_COLOR)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 210
		tips.add_child(label)


func toggle() -> void:
	visible = not visible
	if visible:
		reset_size()
		position = ((get_viewport_rect().size - size) / 2.0).floor()
