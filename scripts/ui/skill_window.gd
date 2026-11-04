class_name SkillWindow
extends PanelContainer
## Okno umiejętności (klawisz K): wspólne drzewko umiejętności wszystkich broni (SkillTree, widok SkillTreeView),
## punkty umiejętności i obok szczegóły zaznaczonego węzła z przyciskami "Wybierz" (1 punkt), "Ulepsz" (punkty
## umiejętności, umiejętności z wybranym węzłem) i "Cofnij poziom" (złoto). Umiejętności działają tylko ze swoją
## bronią (widać to w opisie), premie z węzłów - z każdą. Umiejętność z wybranego węzła (start - zwykły atak)
## przeciąga się na pasek umiejętności na dole ekranu (Hotbar); w opisie widać, pod jakim jest klawiszem.
## Umiejętność aktywna z wybranym węzłem ma gniazda na kamienie wsparcia (Supports): rząd gniazd (klik - wyjmij kamień),
## pasujące kamienie z plecaka (klik - osadź), dorabianie gniazda krzesiwem i łączenie 3 takich samych kamieni.

## Miejsce na paski szybkiego wyboru na dole ekranu, którego okno nie zasłania.
const BOTTOM_RESERVE := 52.0
## Wielkość widoku drzewka i szerokość kolumny szczegółów obok.
const TREE_SIZE := Vector2(416, 236)
const DETAILS_WIDTH := 150.0

var _player: Player
var _gold_label: Label
var _status: Label
## {"view": SkillTreeView, "points": Label, "info": RichTextLabel, "take": Button, "upgrade": Button, "downgrade": Button, ...}
var _tree := {}


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title(tr("Umiejętności")))
	var hint := UiStyle.label(tr("Jedno drzewko dla wszystkich broni: umiejętności działają ze swoją bronią, premie z węzłów - z każdą. Przeciągnij umiejętność (start - zwykły atak) na pasek."), 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = TREE_SIZE.x + DETAILS_WIDTH
	box.add_child(hint)
	box.add_child(_make_tree_page())

	var bottom := HBoxContainer.new()
	var coin := TextureRect.new()
	coin.texture = Items.GOLD_ICON
	UiStyle.fit_icon(coin, 10)
	bottom.add_child(coin)
	_gold_label = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_gold_label)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	bottom.add_child(_status)
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	_tree["view"].setup(player)
	player.hotbar.changed.connect(_refresh)
	player.skills.changed.connect(_refresh)
	player.inventory.changed.connect(func() -> void: if visible: _refresh())
	player.equipment.changed.connect(_refresh)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh())
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_status.text = ""
		_refresh()
		_place()


## Na środku ekranu, ale nad paskami szybkiego wyboru - żeby dało się na nie przeciągać umiejętności.
func _place() -> void:
	reset_size()
	var screen := get_viewport_rect().size
	position = ((screen - size) / 2.0).floor()
	position.y = maxf(2.0, minf(position.y, screen.y - size.y - BOTTOM_RESERVE))


## Drzewko: punkty, a pod nimi sieć węzłów i obok kolumna ze szczegółami zaznaczonego węzła i przyciskami.
func _make_tree_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 3)
	var points := UiStyle.label("", 8, UiStyle.TITLE_COLOR)
	points.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(points)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	page.add_child(row)
	var view := SkillTreeView.new()
	view.custom_minimum_size = TREE_SIZE
	view.theme = UiStyle.make_theme()
	row.add_child(view)
	var details := PanelContainer.new()
	details.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 3))
	details.custom_minimum_size = Vector2(DETAILS_WIDTH, TREE_SIZE.y)
	row.add_child(details)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	details.add_child(column)
	# opis w BBCode: linia tagów umiejętności z ikonkami (Skills.tags_bbcode)
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.scroll_active = false
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("normal_font_size", 7)
	info.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	info.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	info.add_theme_constant_override("outline_size", 3)
	info.text = tr("Kliknij węzeł, żeby zobaczyć szczegóły. Przeciągaj puste miejsce, żeby przesunąć drzewko; kółko myszy przybliża.")
	info.custom_minimum_size.x = DETAILS_WIDTH - 8.0
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(info)
	var take := Button.new()
	take.focus_mode = Control.FOCUS_NONE
	take.add_theme_font_size_override("font_size", 8)
	take.pressed.connect(_take_node)
	column.add_child(take)
	var upgrade := Button.new()
	upgrade.focus_mode = Control.FOCUS_NONE
	upgrade.add_theme_font_size_override("font_size", 8)
	upgrade.pressed.connect(_upgrade_node)
	column.add_child(upgrade)
	var downgrade := Button.new()
	downgrade.focus_mode = Control.FOCUS_NONE
	downgrade.add_theme_font_size_override("font_size", 8)
	downgrade.pressed.connect(func() -> void:
		var node: Dictionary = SkillTree.node(_tree["view"].selected_id)
		if node.has("skill"):
			_downgrade(node["skill"]))
	column.add_child(downgrade)
	# gniazdo: kamienie z plecaka do osadzenia i wyjmowanie
	var gems := GridContainer.new()
	gems.columns = 6
	gems.add_theme_constant_override("h_separation", 2)
	gems.add_theme_constant_override("v_separation", 2)
	column.add_child(gems)
	var unsocket := Button.new()
	unsocket.focus_mode = Control.FOCUS_NONE
	unsocket.add_theme_font_size_override("font_size", 8)
	unsocket.text = tr("Wyjmij kamień")
	unsocket.pressed.connect(_unsocket)
	column.add_child(unsocket)
	var destroy := Button.new()
	destroy.focus_mode = Control.FOCUS_NONE
	destroy.add_theme_font_size_override("font_size", 8)
	destroy.text = tr("Zniszcz esencję")
	destroy.pressed.connect(func() -> void:
		_player.skills.destroy_essence(_tree["view"].selected_id)
		Sfx.play("ui_click")
		_show_socket_result("", tr("Esencja rozwiała się.")))
	column.add_child(destroy)
	# gniazda umiejętności na kamienie wsparcia (Supports)
	var support_box := VBoxContainer.new()
	support_box.add_theme_constant_override("separation", 2)
	column.add_child(support_box)
	var socket_row := HBoxContainer.new()
	socket_row.add_theme_constant_override("separation", 2)
	support_box.add_child(socket_row)
	var support_list := GridContainer.new()
	support_list.columns = 6
	support_list.add_theme_constant_override("h_separation", 2)
	support_list.add_theme_constant_override("v_separation", 2)
	support_box.add_child(support_list)
	var add_socket := Button.new()
	add_socket.focus_mode = Control.FOCUS_NONE
	add_socket.add_theme_font_size_override("font_size", 8)
	add_socket.pressed.connect(_add_support_socket)
	support_box.add_child(add_socket)
	var combine := Button.new()
	combine.focus_mode = Control.FOCUS_NONE
	combine.add_theme_font_size_override("font_size", 8)
	support_box.add_child(combine)
	view.selected.connect(func(_id: String) -> void: _refresh())
	view.refund_requested.connect(_refund_node)
	view.gem_dropped.connect(_show_socket_result)
	_tree = {"view": view, "points": points, "info": info, "take": take, "upgrade": upgrade, "downgrade": downgrade,
			"gems": gems, "unsocket": unsocket, "destroy": destroy, "supports": support_box, "socket_row": socket_row,
			"support_list": support_list, "add_socket": add_socket, "combine": combine}
	return page


func _take_node() -> void:
	var view: SkillTreeView = _tree["view"]
	if _player.skills.take(view.selected_id):
		Sfx.play("ui_confirm")
		_status.text = tr("Wybrano: %s") % SkillTree.node_name(view.selected_id)
		_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))


## Cofa węzeł kliknięty prawym przyciskiem (albo mówi, czemu się nie da).
func _refund_node(id: String) -> void:
	var reason := _player.skills.refund_reason(id, _player.stats.gold)
	if reason == "":
		var gold := _player.skills.refund_gold()
		_player.skills.refund(id, _player.stats)
		Sfx.play("ui_click")
		_status.text = tr("Cofnięto: %s (-%d zł)") % [SkillTree.node_name(id), gold]
		_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))
	else:
		Sfx.play("ui_error")
		_status.text = reason
		_status.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
	_refresh()


## Osadza kamień z pola `index` plecaka w zaznaczonym gnieździe (kamień, który tam był, wraca do plecaka).
func _socket(index: int) -> void:
	var view: SkillTreeView = _tree["view"]
	var message := _player.skills.socket_from(_player.inventory, view.selected_id, index)
	Sfx.play("ui_error" if message != "" else "pickup")
	_show_socket_result(message)


func _unsocket() -> void:
	var view: SkillTreeView = _tree["view"]
	var essence := _player.skills.gem_in(view.selected_id).has("essence")
	var message := _player.skills.unsocket_to(_player.inventory, view.selected_id, _player.stats)
	Sfx.play("ui_error" if message != "" else "pickup")
	_show_socket_result(message, tr("Esencja wróciła do plecaka.") if essence else tr("Kamień wrócił do plecaka."))


func _show_socket_result(message: String, done := "Kamień osadzony w gnieździe.") -> void:
	_status.text = Lang.t(message) if message != "" else tr(done)
	_status.add_theme_color_override("font_color", Color(1, 0.5, 0.45) if message != "" else Color(0.6, 1, 0.55))
	_refresh()


## Umiejętność zaznaczonego węzła ("" - węzeł nie jest umiejętnością).
func _selected_skill() -> String:
	return SkillTree.node(_tree["view"].selected_id).get("skill", "")


func _add_support_socket() -> void:
	var message := _player.skills.add_socket(_selected_skill(), _player.inventory)
	Sfx.play("ui_error" if message != "" else "ui_confirm")
	_show_socket_result(message, tr("Gniazdo dorobione."))


func _support_socket(index: int) -> void:
	var message := _player.skills.support_socket_from(_player.inventory, _selected_skill(), index)
	Sfx.play("ui_error" if message != "" else "pickup")
	_show_socket_result(message, tr("Kamień wsparcia osadzony."))


func _support_unsocket(slot: int) -> void:
	var message := _player.skills.support_unsocket_to(_player.inventory, _selected_skill(), slot)
	Sfx.play("ui_error" if message != "" else "pickup")
	_show_socket_result(message, tr("Kamień wrócił do plecaka."))


func _support_combine(kind: String) -> void:
	var message := Supports.combine(_player.inventory, kind)
	Sfx.play("ui_error" if message != "" else "ui_confirm")
	_show_socket_result(message, tr("Kamienie połączone w jeden, silniejszy."))


## Gniazda umiejętności zaznaczonego węzła: rząd gniazd, pasujące kamienie z plecaka, dorabianie gniazda, łączenie.
## Zwraca linię do opisu ("" - umiejętność bez gniazd).
func _refresh_supports() -> String:
	var parts: Dictionary = _tree
	var box: VBoxContainer = parts["supports"]
	var skill := _selected_skill()
	var book := _player.skills
	box.visible = skill != "" and Supports.has_sockets(skill) and book.level_of(skill) > 0
	if not box.visible:
		return ""
	for key in ["socket_row", "support_list"]:
		for child in (parts[key] as Node).get_children():
			child.get_parent().remove_child(child)
			child.queue_free()
	var gems := book.support_gems(skill)
	for slot in gems.size():
		var gem: Dictionary = gems[slot]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(20, 20)
		button.expand_icon = true
		button.icon = Gems.SOCKET_ICON if gem.is_empty() else Supports.icon(gem["support"])
		button.tooltip_text = tr("Puste gniazdo - kliknij pasujący kamień poniżej albo upuść go na umiejętność w drzewku.") if gem.is_empty() \
				else Supports.describe(gem) + "\n" + tr("Kliknij, żeby wyjąć kamień.")
		UiStyle.rich_tooltip(button)
		if not gem.is_empty():
			button.pressed.connect(_support_unsocket.bind(slot))
		parts["socket_row"].add_child(button)
	# pasujące kamienie z plecaka i rodzaje, których są co najmniej 3 (łączenie)
	var counts := {}
	for index in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[index]
		if slot.is_empty() or not Supports.is_support(slot["id"]):
			continue
		var kind: String = Items.get_data(slot["id"])["support"]["kind"]
		counts[kind] = int(counts.get(kind, 0)) + 1
		if not Supports.fits(kind, skill) or gems.is_empty():
			continue
		var put := Button.new()
		put.focus_mode = Control.FOCUS_NONE
		put.custom_minimum_size = Vector2(20, 20)
		put.icon = Items.get_data(slot["id"])["icon"]
		put.expand_icon = true
		put.tooltip_text = tr("Osadź: %s") % Items.describe(slot["id"])
		UiStyle.rich_tooltip(put)
		put.pressed.connect(_support_socket.bind(index))
		parts["support_list"].add_child(put)
	var add: Button = parts["add_socket"]
	var cost := Supports.socket_cost(book.sockets_of(skill))
	add.visible = not cost.is_empty()
	if add.visible:
		var have := _player.inventory.count_of(cost[0])
		add.text = tr("Dorób gniazdo: %s x%d (masz %d)") % [Items.short_name(cost[0]), cost[1], have]
		add.disabled = have < int(cost[1])
	var combine: Button = parts["combine"]
	combine.visible = false
	for connection in combine.pressed.get_connections():
		combine.pressed.disconnect(connection["callable"])
	for kind: String in Supports.ORDER:
		if int(counts.get(kind, 0)) >= Supports.COMBINE_COUNT:
			combine.visible = true
			combine.text = tr("Połącz 3: %s (+%d poz.)") % [Supports.name_of(kind), Supports.COMBINE_LEVELS]
			combine.pressed.connect(_support_combine.bind(kind))
			break
	var line := tr("Gniazda: %d/%d") % [gems.size(), Supports.MAX_SOCKETS]
	var mana := book.support_mana(skill)
	if mana > 1.0:
		line += "  " + tr("koszt many x%s") % Skills.decimal(mana, 2)
	if gems.is_empty():
		line += "\n" + tr("Dorób gniazdo krzesiwem, żeby osadzić kamień wsparcia.")
	elif parts["support_list"].get_child_count() == 0:
		line += "\n" + tr("Nie masz pasujących kamieni wsparcia.")
	return line


func _upgrade_node() -> void:
	var skill := _selected_skill()
	if skill != "":
		_upgrade(skill)


func _refresh_tree() -> void:
	var parts: Dictionary = _tree
	var view: SkillTreeView = parts["view"]
	var book := _player.skills
	var progress := book.skill_xp_progress()
	parts["points"].text = tr("Punkty umiejętności: %d   Pasek umiejętności: %d / %d exp   (cofnięcie punktu: %d zł)") % [
			book.points_left(), progress[0], progress[1], book.refund_gold()]
	if book.tree_reset:
		parts["points"].text += "\n" + tr("Nowe wspólne drzewko: wszystkie punkty umiejętności wróciły do rozdania, a kamienie z gniazd - do plecaka.")
	if book.migrated_gold >= 0:
		parts["points"].text += "\n" + tr("Nowe zasady umiejętności: wszystkie punkty wróciły do rozdania, a złoto za kupione poziomy (%d zł) do sakwy.") % book.migrated_gold
	view.queue_redraw()
	var take: Button = parts["take"]
	var upgrade: Button = parts["upgrade"]
	var downgrade: Button = parts["downgrade"]
	var gems: GridContainer = parts["gems"]
	var unsocket: Button = parts["unsocket"]
	var destroy: Button = parts["destroy"]
	for child in gems.get_children():
		gems.remove_child(child)
		child.queue_free()
	var id := view.selected_id
	var held := book.gem_in(id) if id != "" else {}
	unsocket.visible = not held.is_empty()
	destroy.visible = held.has("essence")
	if held.has("essence"):
		unsocket.text = tr("Wyjmij esencję (%d zł)") % Essences.save_gold(book.character_level)
	else:
		unsocket.text = tr("Wyjmij kamień")
	gems.visible = id != "" and book.can_socket(id)
	if id == "":
		take.visible = false
		upgrade.visible = false
		downgrade.visible = false
		parts["supports"].visible = false
		return
	if gems.visible:
		for index in _player.inventory.slots.size():
			var slot: Dictionary = _player.inventory.slots[index]
			var essence := not slot.is_empty() and Essences.is_essence(slot["id"])
			if slot.is_empty() or not (Gems.is_gem(slot["id"]) or (essence and book.is_legendary_socket(id))):
				continue
			var put := Button.new()
			put.focus_mode = Control.FOCUS_NONE
			put.custom_minimum_size = Vector2(20, 20)
			put.icon = Items.get_data(slot["id"])["icon"]
			put.expand_icon = true
			put.tooltip_text = tr("Osadź: %s") % Items.describe(slot["id"])
			UiStyle.rich_tooltip(put)
			put.pressed.connect(_socket.bind(index))
			gems.add_child(put)
	var text := view.describe(id)
	var node := SkillTree.node(id)
	take.visible = not book.has_node_id(id) and not SkillTree.is_soon(id)
	take.text = tr("Wybierz (1 pkt)")
	take.disabled = not book.can_take(id)
	upgrade.visible = node.has("skill") and book.has_node_id(id)
	downgrade.visible = false
	if upgrade.visible:
		var skill: String = node["skill"]
		var level := book.level_of(skill)
		var cost := book.next_cost(skill)
		text += "\n" + tr("Poz. %d/%d: %s") % [level, Skills.MAX_LEVEL, Skills.effect_text(skill, level)]
		if cost >= 0:
			upgrade.tooltip_text = tr("Następny poziom: %s") % Skills.effect_text(skill, level + 1)
		upgrade.text = tr("Poziom maksymalny") if cost < 0 else tr("Ulepsz - %d pkt") % cost
		upgrade.disabled = cost < 0 or book.points_left() < cost
		var back := book.downgrade_gold(skill)
		downgrade.visible = back >= 0
		downgrade.text = tr("Cofnij poziom - %d zł") % back
		downgrade.disabled = _player.stats.gold < back
		var key := _key_of(skill, _player.stats.weapon_type() if Skills.works_with(skill, _player.stats.weapon_type())
				else str(Skills.get_data(skill)["weapon"]).split("/")[0]) if Hotbar.can_slot_skill(skill) else ""
		if key != "":
			text += "\n" + tr("Na pasku:") + key
	var supports_line := _refresh_supports()
	if supports_line != "":
		text += "\n" + supports_line
	if gems.visible:
		text += "\n" + (tr("Kliknij kamień z plecaka, żeby go osadzić:") if gems.get_child_count() > 0 else tr("Nie masz kamieni szlachetnych w plecaku."))
	parts["info"].text = text


## " [Q]" - pod jakim klawiszem paska leży umiejętność dla danej broni ("" - nie ma jej na pasku).
func _key_of(id: String, weapon_type: String) -> String:
	var index := _player.hotbar.find(weapon_type, id)
	return "  [%s]" % Hotbar.key_name(index) if index >= 0 else ""


func _upgrade(id: String) -> void:
	if not _player.skills.can_learn(id):
		_status.text = tr("Najpierw odblokuj: %s") % Skills.name_of(Skills.get_data(id)["requires"])
		_status.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	elif _player.skills.upgrade(id):
		var level := _player.skills.level_of(id)
		var pattern := tr("Odblokowano: %s (poz. %d)") if level == 1 else tr("Ulepszono: %s (poz. %d)")
		_status.text = pattern % [Skills.name_of(id), level]
		_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))
	else:
		_status.text = tr("Za mało punktów umiejętności!")
		_status.add_theme_color_override("font_color", Color(1, 0.4, 0.4))


## Cofa ostatni poziom umiejętności za złoto (punkty wracają).
func _downgrade(id: String) -> void:
	var gold := _player.skills.downgrade_gold(id)
	if _player.skills.downgrade(id, _player.stats):
		Sfx.play("ui_click")
		_status.text = tr("Cofnięto poziom: %s (poz. %d, -%d zł)") % [Skills.name_of(id), _player.skills.level_of(id), gold]
		_status.add_theme_color_override("font_color", Color(0.6, 1, 0.55))
	else:
		Sfx.play("ui_error")
		_status.text = tr("Za mało złota!")
		_status.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	_refresh()


func _refresh() -> void:
	if _player == null:
		return
	_refresh_tree()
	_gold_label.text = tr("%d złota") % _player.stats.gold
