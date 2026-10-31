class_name TravelersWindow
extends PanelContainer
## Lista podróżników gildii (Travelers) - u pisarza gildii: imię, poziom, broń, ekwipunek, gdzie są teraz, zabójstwa,
## śmierci i sława (ranking jak w MMO, od najsławniejszych). Na dole ranga gildii i jej ulepszenie - wyższa ranga
## ściąga więcej i silniejszych podróżników (więcej ofert na rynku, więcej towarzystwa w krainach).

const WIDTH := 420.0
const LIST_HEIGHT := 190.0

var _player: Player
var _list: GridContainer
var _rank: Label
var _upgrade: Button
var _status: Label


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Podróżnicy gildii"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(WIDTH, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = GridContainer.new()
	_list.columns = 7
	_list.add_theme_constant_override("h_separation", 8)
	_list.add_theme_constant_override("v_separation", 1)
	scroll.add_child(_list)
	_rank = UiStyle.label("", 8, UiStyle.TITLE_COLOR)
	_rank.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rank.custom_minimum_size.x = WIDTH
	box.add_child(_rank)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 4)
	_upgrade = Button.new()
	_upgrade.focus_mode = Control.FOCUS_NONE
	_upgrade.add_theme_font_size_override("font_size", 8)
	_upgrade.pressed.connect(_on_upgrade)
	bottom.add_child(_upgrade)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status)
	var close := Button.new()
	close.text = "Zamknij"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 8)
	close.pressed.connect(func() -> void:
		visible = false
		Sfx.play("ui_close"))
	bottom.add_child(close)
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.travelers.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var travelers := _player.travelers
	for header in ["Imię", "Poz.", "Broń", "Ekwipunek", "Gdzie", "Zabójstwa", "Śmierci"]:
		_list.add_child(UiStyle.label(header, 7, UiStyle.TITLE_COLOR))
	var list := travelers.active()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["fame"]) > int(b["fame"]))
	for traveler: Dictionary in list:
		var name := UiStyle.label(traveler["name"], 7, Traveler.NAME_COLOR)
		name.custom_minimum_size.x = 100
		name.clip_text = true
		_list.add_child(name)
		_list.add_child(UiStyle.label(str(traveler["level"]), 7))
		_list.add_child(UiStyle.label(Travelers.WEAPON_NAMES[traveler["weapon"]], 7))
		var gear: String = traveler["gear"]
		var rarity: String = {"zwykły": "common", "magiczny": "magic", "rzadki": "rare", "legendarny": "legendary"}.get(gear, "common")
		_list.add_child(UiStyle.label(gear, 7, Items.RARITY_COLORS[rarity]))
		_list.add_child(UiStyle.label(Travelers.place_text(traveler), 7, UiStyle.DIM_COLOR))
		_list.add_child(UiStyle.label(str(traveler["kills"]), 7))
		_list.add_child(UiStyle.label(str(traveler["deaths"]), 7))
	var rank := travelers.guild_rank
	_rank.text = "Ranga gildii: %d/%d - sława: %d - aktywnych podróżników: %d, najwyższy poziom: %d" % [rank, Travelers.MAX_RANK,
			travelers.guild_fame, travelers.active_count(), travelers.level_cap()]
	_upgrade.visible = rank >= 1 and rank < Travelers.MAX_RANK
	if _upgrade.visible:
		var cost: Dictionary = Travelers.RANK_COSTS[rank + 1]
		var parts: Array[String] = []
		for id: String in cost:
			if id == "fame":
				parts.append("sława %d" % cost[id])
			else:
				parts.append("%d %s" % [cost[id], "zł" if id == "gold" else Items.get_data(id)["name"].to_lower()])
		_upgrade.text = "Ulepsz gildię: " + ", ".join(parts)


func _on_upgrade() -> void:
	var message := _player.travelers.upgrade_rank(_player)
	_status.text = message if message != "" else "Gildia rośnie w siłę! Zjeżdżają nowi podróżnicy."
	_status.add_theme_color_override("font_color", Color(1, 0.5, 0.45) if message != "" else Color(0.55, 1.0, 0.55))
	Sfx.play("ui_error" if message != "" else "quest_done")
	_refresh()
