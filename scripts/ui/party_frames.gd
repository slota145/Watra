class_name PartyFrames
extends VBoxContainer
## Ramki drużyny pod paskami zdrowia gracza (Travelers.party): nagłówek z premią do doświadczenia, a dla każdego
## członka imię, poziom i pasek zdrowia (z jego postaci w świecie). Przycisk "Opuść" rozwiązuje drużynę.

const BAR_SIZE := Vector2(90, 4)

var _player: Player
var _timer := 0.0


func setup(player: Player) -> void:
	_player = player
	add_theme_constant_override("separation", 1)
	mouse_filter = Control.MOUSE_FILTER_PASS
	player.travelers.changed.connect(_rebuild)
	_rebuild()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0 or _player == null:
		return
	_timer = 0.25
	var nodes := {}
	for node in get_tree().get_nodes_in_group("travelers"):
		if node.mode == "party":
			nodes[node.data["name"]] = node
	for row in get_children():
		if row.has_meta("member"):
			var node = nodes.get(row.get_meta("member"))
			var bar: ProgressBar = row.get_node("Bar")
			bar.value = node.health / node.max_health if node != null else 1.0


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var members := _player.travelers.party_members()
	visible = not members.is_empty()
	if members.is_empty():
		return
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	header.add_child(UiStyle.label("Drużyna (+%d%% exp)" % roundi((_player.travelers.party_xp_factor() - 1.0) * 100.0), 7, Traveler.PARTY_COLOR))
	var leave := Button.new()
	leave.text = "Opuść"
	leave.focus_mode = Control.FOCUS_NONE
	leave.add_theme_font_size_override("font_size", 6)
	leave.tooltip_text = "Rozwiąż drużynę - podróżnicy wrócą do Ostoi"
	leave.pressed.connect(func() -> void:
		for node in get_tree().get_nodes_in_group("travelers"):
			if node.mode == "party":
				node.say("Do zobaczenia w Ostoi!")
				node.recall()
		_player.travelers.disband()
		Sfx.play("ui_close"))
	header.add_child(leave)
	add_child(header)
	for traveler: Dictionary in members:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		row.set_meta("member", traveler["name"])
		row.add_child(UiStyle.label("%s [%d] - %s" % [traveler["name"], traveler["level"], Travelers.WEAPON_NAMES[traveler["weapon"]]], 6, UiStyle.TEXT_COLOR))
		var bar := ProgressBar.new()
		bar.name = "Bar"
		bar.show_percentage = false
		bar.custom_minimum_size = BAR_SIZE
		bar.max_value = 1.0
		bar.value = 1.0
		bar.add_theme_stylebox_override("background", UiStyle.panel(Color(0.12, 0.05, 0.05), Color(0, 0, 0, 0), 0))
		bar.add_theme_stylebox_override("fill", UiStyle.panel(Color(0.8, 0.25, 0.25), Color(0, 0, 0, 0), 0))
		row.add_child(bar)
		add_child(row)
