class_name Hud
extends CanvasLayer
## Interfejs: paski zdrowia, many i expa, poziom, złoto, licznik pokonanych goblinów,
## minimapa, komunikaty (śmierć, nowy poziom) oraz okna: postać (C), ekwipunek (I),
## mapa (M), umiejętności (K), handel z kupcem i menu pauzy (Esc, gdy żadne inne okno nie jest otwarte).
## Na dole ekranu paski szybkiego wyboru (ActionBars: umiejętności LPM, PPM, Q, E, R, Z, X i przedmioty 1-0),
## pod paskami zdrowia i many ikony działających efektów (StatusRow).
## W prawym dolnym rogu pasek ikon otwierających okna (ekwipunek, postać, umiejętności,
## dziennik zadań, mapa, pomoc), nad nim powiadomienia o łupie. Pod minimapą lista
## śledzonych zadań - kliknięcie pokazuje obszar zadania na mapie.
## Ctrl+Shift+C włącza/wyłącza tryb deweloperski: F1 daje złoto, F2 awansuje postać,
## F3 daje kamienie zaklinające, F4 drewno i kamień.

const DEV_GOLD := 1000
## Ile kamieni każdego rodzaju daje klawisz F3 w trybie deweloperskim.
const DEV_STONES := 5
const DEV_PERFECT_STONES := 3
const DEV_BLESSED_STONES := 100
const DEV_MERCY_STONES := 30
## Ile drewna i kamienia daje klawisz F4 w trybie deweloperskim.
const DEV_RESOURCES := 50
const DEV_COLOR := Color(0.55, 0.9, 1.0)
const INTRO_TEXT := "Hordy potworów zalały świat.\nOstatni ludzie schronili się w osadzie Ostoja.\nPomóż im przetrwać."

var kills := 0
## Tryb deweloperski do testowania (nie zapisuje się).
var dev_mode := Game.dev_mode
var _banner_tween: Tween
## Okno rzemiosła - budowane w kodzie, otwierane przyciskiem pod "Zaklinaniem".
var crafting_window: CraftingWindow
## Okno budowy u sołtysa - też budowane w kodzie.
var build_window: BuildWindow
## Tablica ogłoszeń (zlecenia gildii) i odczarowanie u mędrca.
var board_window: BoardWindow
var sage_window: SageWindow
## Wykuwanie magicznych i rzadkich przedmiotów u kowala.
var forge_window: ForgeWindow
var offer_window: OfferWindow
var watra_window: WatraWindow
var dungeon_window: DungeonWindow
var codex_window: CodexWindow
var jeweler_window: JewelerWindow
var essence_window: EssenceWindow
var market_window: MarketWindow
var travelers_window: TravelersWindow
## Paski szybkiego wyboru na dole ekranu i ikony działających efektów pod paskami zdrowia i many.
var action_bars: ActionBars
var status_row: StatusRow
var party_frames: PartyFrames
var party_offer: PartyOffer
var _player: Player
## [przycisk, okno] - przyciski paska ikon w prawym dolnym rogu
var _icon_buttons: Array[Array] = []

@onready var health_bar: ProgressBar = $Bars/HealthBar
@onready var health_label: Label = $Bars/HealthBar/Value
@onready var mana_bar: ProgressBar = $Bars/ManaBar
@onready var mana_label: Label = $Bars/ManaBar/Value
@onready var xp_bar: ProgressBar = $Bars/XpBar
@onready var xp_value: Label = $Bars/XpValue
@onready var level_label: Label = $Level
@onready var points_label: Label = $Points
@onready var kills_label: Label = $Kills
@onready var gold_label: Label = $Gold
@onready var death_label: Label = $DeathMessage
@onready var level_up_label: Label = $LevelUpMessage
@onready var character_window: CharacterWindow = $CharacterWindow
@onready var inventory_window: InventoryWindow = $InventoryWindow
@onready var minimap: MapView = $Minimap
@onready var big_map: BigMap = $BigMap
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var shop_window: ShopWindow = $ShopWindow
@onready var skill_window: SkillWindow = $SkillWindow
@onready var enchant_window: EnchantWindow = $EnchantWindow
@onready var intro_label: Label = $IntroMessage
@onready var dev_message: Label = $DevMessage
@onready var dev_badge: Label = $DevBadge
@onready var boss_bar: VBoxContainer = $BossBar
@onready var loot_feed: LootFeed = $LootFeed
@onready var icon_bar: HBoxContainer = $IconBar
@onready var help_window: HelpWindow = $HelpWindow
@onready var quest_tracker: QuestTracker = $QuestTracker
@onready var quest_journal: QuestJournal = $QuestJournal
@onready var npc_dialog: NpcDialog = $NpcDialog
@onready var storage_window: StorageWindow = $StorageWindow
@onready var rest_fade: ColorRect = $RestFade

## Obszary zadań na mapie (w kafelkach), ustawiane przez świat.
var _quest_areas := {}
@onready var boss_name_label: Label = $BossBar/Name
@onready var boss_health: ProgressBar = $BossBar/Health


func _ready() -> void:
	add_to_group("hud")
	dev_badge.visible = dev_mode
	crafting_window = CraftingWindow.new()
	crafting_window.name = "CraftingWindow"
	add_child(crafting_window)
	move_child(crafting_window, enchant_window.get_index() + 1)
	build_window = BuildWindow.new()
	build_window.name = "BuildWindow"
	add_child(build_window)
	move_child(build_window, crafting_window.get_index() + 1)
	board_window = BoardWindow.new()
	board_window.name = "BoardWindow"
	add_child(board_window)
	move_child(board_window, build_window.get_index() + 1)
	sage_window = SageWindow.new()
	sage_window.name = "SageWindow"
	add_child(sage_window)
	move_child(sage_window, board_window.get_index() + 1)
	forge_window = ForgeWindow.new()
	forge_window.name = "ForgeWindow"
	add_child(forge_window)
	move_child(forge_window, sage_window.get_index() + 1)
	offer_window = OfferWindow.new()
	offer_window.name = "OfferWindow"
	add_child(offer_window)
	move_child(offer_window, forge_window.get_index() + 1)
	watra_window = WatraWindow.new()
	watra_window.name = "WatraWindow"
	add_child(watra_window)
	move_child(watra_window, offer_window.get_index() + 1)
	dungeon_window = DungeonWindow.new()
	dungeon_window.name = "DungeonWindow"
	add_child(dungeon_window)
	move_child(dungeon_window, watra_window.get_index() + 1)
	codex_window = CodexWindow.new()
	codex_window.name = "CodexWindow"
	add_child(codex_window)
	move_child(codex_window, dungeon_window.get_index() + 1)
	jeweler_window = JewelerWindow.new()
	jeweler_window.name = "JewelerWindow"
	add_child(jeweler_window)
	move_child(jeweler_window, codex_window.get_index() + 1)
	essence_window = EssenceWindow.new()
	essence_window.name = "EssenceWindow"
	add_child(essence_window)
	move_child(essence_window, jeweler_window.get_index() + 1)
	market_window = MarketWindow.new()
	market_window.name = "MarketWindow"
	add_child(market_window)
	move_child(market_window, essence_window.get_index() + 1)
	travelers_window = TravelersWindow.new()
	travelers_window.name = "TravelersWindow"
	add_child(travelers_window)
	move_child(travelers_window, market_window.get_index() + 1)
	status_row = StatusRow.new()
	status_row.name = "StatusRow"
	status_row.position = Vector2(6, 52)
	status_row.size = Vector2(150, 0)
	add_child(status_row)
	move_child(status_row, $Bars.get_index() + 1)
	# drużyna z podróżnikami: ramki pod efektami i okienko zaproszeń
	party_frames = PartyFrames.new()
	party_frames.name = "PartyFrames"
	party_frames.position = Vector2(6, 92)
	add_child(party_frames)
	party_offer = PartyOffer.new()
	party_offer.name = "PartyOffer"
	add_child(party_offer)
	action_bars = ActionBars.new()
	action_bars.name = "ActionBars"
	add_child(action_bars)
	move_child(action_bars, status_row.get_index() + 1)
	action_bars.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 4)
	action_bars.grow_horizontal = Control.GROW_DIRECTION_BOTH
	action_bars.grow_vertical = Control.GROW_DIRECTION_BEGIN
	death_label.visible = false
	level_up_label.visible = false
	intro_label.visible = false
	dev_message.visible = false
	dev_badge.visible = false
	boss_bar.visible = false
	rest_fade.visible = false
	_update_kills()
	_build_icon_bar()


func connect_player(player: Player) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.died.connect(func() -> void: death_label.visible = true)
	player.respawned.connect(func() -> void: death_label.visible = false)
	player.stats.xp_changed.connect(_on_xp_changed)
	player.stats.leveled_up.connect(_on_leveled_up)
	player.stats.changed.connect(_update_points)
	player.stats.gold_changed.connect(_on_gold_changed)
	character_window.setup(player)
	inventory_window.setup(player)
	shop_window.setup(player)
	skill_window.setup(player)
	enchant_window.setup(player)
	inventory_window.enchant_window = enchant_window
	crafting_window.setup(player)
	inventory_window.crafting_requested.connect(_open_crafting)
	player.item_picked.connect(loot_feed.show_item)
	quest_tracker.setup(player)
	# dymek z opisem i porównaniem łupu leżącego na ziemi - na wierzchu HUD (nad oknami się chowa)
	var ground_tooltip := GroundTooltip.new()
	add_child(ground_tooltip)
	ground_tooltip.setup(player)
	# ekwipunek otwiera się pod minimapą, dokładnie na śledzonych zadaniach - chowamy je na ten czas
	# (w drzewie HUD tracker i tak leży pod oknami, więc nie przechwyci myszy)
	inventory_window.visibility_changed.connect(func() -> void: quest_tracker.visible = not inventory_window.visible)
	quest_journal.setup(player)
	npc_dialog.setup(player)
	storage_window.setup(player)
	codex_window.setup(player)
	jeweler_window.setup(player)
	essence_window.setup(player)
	market_window.setup(player)
	travelers_window.setup(player)
	npc_dialog.market_requested.connect(market_window.open)
	npc_dialog.travelers_requested.connect(travelers_window.open)
	npc_dialog.essence_requested.connect(essence_window.open)
	npc_dialog.rest_requested.connect(_on_rest)
	npc_dialog.storage_requested.connect(storage_window.open)
	build_window.setup(player)
	npc_dialog.build_requested.connect(build_window.open)
	board_window.setup(player)
	npc_dialog.board_requested.connect(board_window.open)
	sage_window.setup(player)
	npc_dialog.sage_requested.connect(sage_window.open)
	forge_window.setup(player)
	npc_dialog.forge_requested.connect(forge_window.open)
	npc_dialog.enchant_requested.connect(_open_enchanting)
	npc_dialog.jeweler_requested.connect(jeweler_window.open)
	offer_window.setup(player)
	npc_dialog.offers_requested.connect(offer_window.open)
	watra_window.setup(player)
	npc_dialog.watra_requested.connect(watra_window.open)
	dungeon_window.setup(player)
	watra_window.dungeon_requested.connect(dungeon_window.open)
	watra_window.essence_requested.connect(essence_window.open.bind("watra"))
	status_row.setup(player)
	party_frames.setup(player)
	action_bars.setup(player)
	quest_tracker.area_requested.connect(show_quest_area)
	quest_journal.area_requested.connect(show_quest_area)
	player.quests.quest_ready.connect(_on_quest_ready)

	var s := player.stats
	_on_xp_changed(s.xp, s.xp_to_next_level(), s.level)
	_on_gold_changed(s.gold)
	_update_points()


func setup_map(texture: Texture2D, map_size: Vector2i, tile_size: float, player: Player, markers: Array[Dictionary]) -> void:
	minimap.setup(texture, map_size, tile_size, player, markers)
	big_map.setup(texture, map_size, tile_size, player, markers)


## Duża mapa wszystkich krain i teleport do odkrytych kapliczek.
func setup_world_map(world: Node, world_seed: int, zone: String, texture: Texture2D) -> void:
	big_map.setup_world(world_seed, zone, texture, world.shrines)
	if not big_map.teleport_requested.is_connected(world.teleport_to):
		big_map.teleport_requested.connect(world.teleport_to)


func refresh_world_map() -> void:
	big_map.refresh()


func on_enemy_killed(_enemy: Node = null) -> void:
	kills += 1
	_update_kills()


func set_kills(value: int) -> void:
	kills = value
	_update_kills()


## Fabularne wprowadzenie na początku nowej gry.
func show_intro() -> void:
	intro_label.text = INTRO_TEXT
	intro_label.visible = true
	intro_label.modulate.a = 0.0
	var tween := intro_label.create_tween()
	tween.tween_property(intro_label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(5.0)
	tween.tween_property(intro_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func() -> void: intro_label.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	# skróty deweloperskie najpierw - Ctrl+Shift+C nie może otwierać okna postaci (C)
	if _handle_dev_keys(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("character"):
		_toggle_window(character_window)
	elif event.is_action_pressed("inventory"):
		_toggle_window(inventory_window)
	elif event.is_action_pressed("map"):
		_toggle_window(big_map)
	elif event.is_action_pressed("skills"):
		_toggle_window(skill_window, "ui_book")
	elif event.is_action_pressed("journal"):
		_toggle_window(quest_journal, "ui_book")
	elif event.is_action_pressed("codex"):
		_toggle_window(codex_window, "ui_book")
	elif event.is_action_pressed("ui_cancel"):
		# Esc najpierw zamyka otwarte okna, a dopiero potem otwiera menu pauzy
		var windows: Array[Control] = [character_window, inventory_window, big_map, shop_window, skill_window, enchant_window, crafting_window, build_window, board_window, sage_window, forge_window, watra_window, dungeon_window, help_window, quest_journal, npc_dialog, storage_window, codex_window, jeweler_window, essence_window, market_window, travelers_window]
		if windows.any(func(w: Control) -> bool: return w.visible):
			Sfx.play("ui_close")
			for w in windows:
				w.visible = false
		else:
			pause_menu.open()
	else:
		return
	get_viewport().set_input_as_handled()


## Otwiera / zamyka okno z dźwiękiem (księgi szeleszczą kartkami).
func _toggle_window(window: Control, open_sound := "ui_open") -> void:
	window.toggle()
	Sfx.play(open_sound if window.visible else "ui_close")


## Okno zaklinania obok otwartego ekwipunku (z którego wkłada się przedmioty PPM).
func _open_enchanting() -> void:
	if enchant_window.visible:
		enchant_window.visible = false
		return
	character_window.visible = false
	crafting_window.visible = false
	if not inventory_window.visible:
		inventory_window.toggle()
	enchant_window.open()
	var x := maxf(4.0, inventory_window.position.x - enchant_window.size.x - 4.0)
	var y := minf(inventory_window.position.y, get_viewport().get_visible_rect().size.y - enchant_window.size.y - 4.0)
	enchant_window.position = Vector2(x, y).floor()


## Okno rzemiosła obok otwartego ekwipunku (zamiast zaklinania - zajmują to samo miejsce).
func _open_crafting() -> void:
	if crafting_window.visible:
		crafting_window.visible = false
		Sfx.play("ui_close")
		return
	if enchant_window.is_busy():
		return
	character_window.visible = false
	enchant_window.visible = false
	if not inventory_window.visible:
		inventory_window.toggle()
	crafting_window.open()
	Sfx.play("ui_open")
	var x := maxf(4.0, inventory_window.position.x - crafting_window.size.x - 4.0)
	var y := minf(inventory_window.position.y, get_viewport().get_visible_rect().size.y - crafting_window.size.y - 4.0)
	crafting_window.position = Vector2(x, y).floor()


# ---------------------------------------------------------------- tryb deweloperski
func _handle_dev_keys(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	if key.physical_keycode == KEY_C and key.ctrl_pressed and key.shift_pressed:
		set_dev_mode(not dev_mode)
		return true
	if not dev_mode or _player == null:
		return false
	match key.physical_keycode:
		KEY_F1:
			_player.stats.add_gold(DEV_GOLD)
			_dev_feedback("+%d zł" % DEV_GOLD, Color(1.0, 0.85, 0.3))
		KEY_F2:
			var stats := _player.stats
			stats.add_xp(stats.xp_to_next_level() - stats.xp)
		KEY_F3:
			_give_dev_stones()
		KEY_F4:
			_give_dev_resources()
		_:
			return false
	return true


func _give_dev_stones() -> void:
	var missing := 0
	for category in ["weapon", "armor", "jewelry"]:
		missing += _player.inventory.add_item(Enchanting.stone_id(category, false), DEV_STONES)
		missing += _player.inventory.add_item(Enchanting.stone_id(category, true), DEV_PERFECT_STONES)
	missing += _player.inventory.add_item("blessed_stone", DEV_BLESSED_STONES)
	missing += _player.inventory.add_item("mercy_stone", DEV_MERCY_STONES)
	if missing > 0:
		_dev_feedback("Ekwipunek pełny! Brakło %d kamieni" % missing, Color(1, 0.4, 0.4))
	else:
		_dev_feedback("Kamienie: +%d zwykłych, +%d doskonałych, +%d uświęconych, +%d miłosierdzia" % [
			DEV_STONES, DEV_PERFECT_STONES, DEV_BLESSED_STONES, DEV_MERCY_STONES], Color(0.8, 0.6, 1.0))


func _give_dev_resources() -> void:
	var missing := _player.inventory.add_item("wood", DEV_RESOURCES) + _player.inventory.add_item("stone", DEV_RESOURCES)
	if missing > 0:
		_dev_feedback("Ekwipunek pełny! Brakło %d sztuk" % missing, Color(1, 0.4, 0.4))
	else:
		_dev_feedback("+%d drewna, +%d kamienia" % [DEV_RESOURCES, DEV_RESOURCES], Color(0.85, 0.7, 0.45))


func set_dev_mode(enabled: bool) -> void:
	dev_mode = enabled
	Game.dev_mode = enabled
	dev_badge.visible = enabled
	if enabled:
		_show_banner("Tryb deweloperski WŁĄCZONY\n[F1] 1000 złota    [F2] awans    [F3] kamienie zaklinające    [F4] drewno i kamień", DEV_COLOR)
	else:
		_show_banner("Tryb deweloperski WYŁĄCZONY", Color(0.85, 0.85, 0.9))


## Duży komunikat na środku ekranu (np. ukończona budowa).
func show_banner(text: String, color: Color) -> void:
	_show_banner(text, color)


func _show_banner(text: String, color: Color) -> void:
	dev_message.text = text
	dev_message.add_theme_color_override("font_color", color)
	dev_message.visible = true
	dev_message.modulate.a = 1.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = dev_message.create_tween()
	_banner_tween.tween_interval(2.5)
	_banner_tween.tween_property(dev_message, "modulate:a", 0.0, 0.6)
	_banner_tween.tween_callback(func() -> void: dev_message.visible = false)


func _dev_feedback(text: String, color: Color) -> void:
	DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -12), text, color)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


func _on_mana_changed(current: int, maximum: int) -> void:
	mana_bar.max_value = maximum
	mana_bar.value = current
	mana_label.text = "%d / %d" % [current, maximum]


func _on_xp_changed(xp: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = xp
	xp_bar.tooltip_text = "Exp: %d / %d" % [xp, needed]
	xp_value.text = "%d / %d exp" % [xp, needed]
	level_label.text = "Poz. %d" % level


func _on_leveled_up(level: int) -> void:
	level_up_label.text = "Nowy poziom: %d!\nNaciśnij C, aby rozdać punkt" % level
	level_up_label.visible = true
	level_up_label.modulate.a = 1.0
	var tween := level_up_label.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(level_up_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void: level_up_label.visible = false)


func _on_gold_changed(gold: int) -> void:
	gold_label.text = "Złoto: %d" % gold


func _update_points() -> void:
	var points := _player.stats.unspent_points
	points_label.visible = points > 0
	points_label.text = "+%d pkt [C]" % points


func setup_quest_areas(areas: Dictionary) -> void:
	_quest_areas = areas


## Otwiera mapę z podświetlonym obszarem zadania.
func show_quest_area(id: String) -> void:
	var quest := Quests.get_data(id)
	if _quest_areas.has(quest.get("area", "")):
		quest_journal.visible = false
		big_map.show_area(_quest_areas[quest["area"]], quest["title"])


## Odpoczynek w karczmie: ekran gaśnie, drzewa odrastają, bossowie wracają do leży, zdrowie i mana wracają.
func _on_rest() -> void:
	Sfx.play("rest")
	rest_fade.visible = true
	rest_fade.modulate.a = 0.0
	var tween := rest_fade.create_tween()
	tween.tween_property(rest_fade, "modulate:a", 1.0, 0.6)
	tween.tween_callback(_rest_peak)
	tween.tween_interval(1.2)
	tween.tween_property(rest_fade, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func() -> void: rest_fade.visible = false)


## Najciemniejszy moment odpoczynku - wtedy las odrasta.
func _rest_peak() -> void:
	get_tree().call_group("harvestables", "regrow")
	get_tree().call_group("settlement", "on_rest")
	get_tree().call_group("world", "on_rest")
	_player.rest()


func _on_quest_ready(id: String) -> void:
	Sfx.play("quest_ready")
	var quest := Quests.get_data(id)
	_show_banner("Zadanie wykonane: %s\nWróć do: %s" % [quest["title"], quest["giver"]], Color(0.6, 1.0, 0.5))


## Pasek ikon w prawym dolnym rogu: każda otwiera/zamyka swoje okno.
func _build_icon_bar() -> void:
	var buttons := [
		["bag", "Ekwipunek", "I", inventory_window],
		["character", "Postać", "C", character_window],
		["skills", "Umiejętności", "K", skill_window],
		["journal", "Dziennik zadań", "J", quest_journal],
		["codex", "Encyklopedia", "L", codex_window],
		["map", "Mapa", "M", big_map],
		["help", "Pomoc i sterowanie", "?", help_window],
	]
	var normal := UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 2)
	var hover := UiStyle.panel(Color(0.25, 0.26, 0.36), UiStyle.TITLE_COLOR, 2)
	var pressed := UiStyle.panel(Color(0.3, 0.25, 0.15), UiStyle.TITLE_COLOR, 2)
	for entry: Array in buttons:
		var button := Button.new()
		button.icon = load("res://assets/ui/%s.png" % entry[0])
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(22, 22)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.fit_button_icon(button)
		button.tooltip_text = "%s [%s]" % [entry[1], entry[2]]
		button.theme = UiStyle.make_theme()
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("hover_pressed", pressed)
		var key := UiStyle.label(entry[2], 6, UiStyle.TITLE_COLOR)
		key.position = Vector2(15, 11)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(key)
		var window: Control = entry[3]
		button.pressed.connect(_toggle_window.bind(window))
		icon_bar.add_child(button)
		_icon_buttons.append([button, window])


## Odległość, z której pasek zdrowia walczącego bossa jest widoczny.
const BOSS_BAR_DISTANCE := 450.0


func _process(_delta: float) -> void:
	if _player == null:
		return
	_update_boss_bar()
	# podświetlenie ikon otwartych okien
	for entry: Array in _icon_buttons:
		entry[0].set_pressed_no_signal(entry[1].visible)


## Pasek zdrowia bossa, z którym gracz właśnie walczy.
func _update_boss_bar() -> void:
	var fighting: Boss = null
	for boss: Boss in get_tree().get_nodes_in_group("bosses"):
		if boss.is_engaged() and boss.global_position.distance_to(_player.global_position) < BOSS_BAR_DISTANCE:
			fighting = boss
			break
	boss_bar.visible = fighting != null
	if fighting:
		boss_name_label.text = "%s  (poz. %d)" % [fighting.boss_name, fighting.level]
		boss_health.max_value = fighting.max_health
		boss_health.value = maxi(fighting.health, 0)


func _update_kills() -> void:
	kills_label.text = "Pokonane potwory: %d" % kills
