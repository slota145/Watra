class_name NpcDialog
extends PanelContainer
## Rozmowa z NPC: zadanie (przyjęcie, postęp, odbiór nagrody) i usługi -
## odpoczynek w karczmie albo magazyn. Handlarze mają dodatkowo przycisk "Handel".
## Zamyka się, gdy gracz odejdzie.

signal rest_requested
signal storage_requested(npc: Npc)
signal build_requested
signal board_requested
signal sage_requested
signal forge_requested
signal enchant_requested
signal jeweler_requested(npc: Npc)
signal watra_requested
signal market_requested
signal world_mode_requested
signal workshop_requested
signal travelers_requested
## Okno esencji: "smith" (kowal) albo "altar" (Ołtarz Welesa w lochu).
signal essence_requested(mode: String)
## Usługi z listą ofert (OfferWindow): "meals", "blessing", "bestiary".
signal offers_requested(kind: String, npc: Npc)
const OFFER_SERVICES := {"meals": "Kuchnia", "blessing": "Błogosławieństwo", "bestiary": "Bestiariusz", "reforge": "Przekuwanie",
		"elixirs": "Mikstury", "respec": "Zapomnienie umiejętności", "marks": "Znaki Zwycięstwa"}

## Odpoczynek w karczmie: 20 zł + 3 zł za poziom postaci.
static func rest_price(level: int) -> int:
	return 20 + 3 * level

const CLOSE_DISTANCE := 60.0
const WIDTH := 230.0

var _player: Player
var _npc: Npc
## Zadanie pokazane w rozmowie (główne ma pierwszeństwo przed zadaniem postaci).
var _shown_quest := ""
var _title: Label
var _text: Label
var _quest_box: VBoxContainer
var _buttons: HBoxContainer


func _ready() -> void:
	visible = false
	theme = UiStyle.make_menu_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	custom_minimum_size.x = WIDTH

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	add_child(box)
	_title = UiStyle.title("")
	box.add_child(_title)
	_text = _wrapped("", 8, UiStyle.TEXT_COLOR)
	box.add_child(_text)
	_quest_box = VBoxContainer.new()
	_quest_box.add_theme_constant_override("separation", 1)
	box.add_child(_quest_box)
	box.add_child(HSeparator.new())
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 6)
	box.add_child(_buttons)


func setup(player: Player) -> void:
	_player = player
	player.dialog_requested.connect(open)
	player.quests.changed.connect(_refresh)


func open(npc: Npc) -> void:
	# tablica ogłoszeń od razu pokazuje zlecenia
	if "bounties" in npc.services:
		board_requested.emit()
		return
	# Watra od razu pokazuje ofiary
	if "watra" in npc.services:
		watra_requested.emit()
		return
	# Ołtarz Welesa od razu pokazuje legendy do złożenia
	if "altar" in npc.services:
		essence_requested.emit("altar")
		return
	_npc = npc
	visible = true
	_refresh()


func close() -> void:
	visible = false
	_npc = null


func toggle() -> void:
	close()


func _process(_delta: float) -> void:
	if visible and (_npc == null or _player.is_dead
			or _player.global_position.distance_to(_npc.global_position) > CLOSE_DISTANCE):
		close()


func _refresh() -> void:
	if not visible or _npc == null:
		return
	for child in _quest_box.get_children() + _buttons.get_children():
		child.get_parent().remove_child(child)  # od razu znika z układu
		child.queue_free()

	_title.text = Quests.person(_npc.display_name)
	var main := MainQuests.step_for(_player.quests, _npc.display_name)
	_shown_quest = main if main != "" else _npc.quest_id
	# krok czeka na zadanie poboczne tej postaci - pokazujemy je, żeby dało się je oddać
	var linked := MainQuests.linked_quest(main)
	if linked != "" and _player.quests.state_of(main) == Quests.STATE_ACTIVE and Quests.get_data(linked)["giver"] == _npc.display_name \
			and _player.quests.state_of(linked) in [Quests.STATE_AVAILABLE, Quests.STATE_READY]:
		_shown_quest = linked
	if _shown_quest != "":
		_quest_section(_shown_quest)
	else:
		_text.text = tr(_npc.dialog_greeting)
	for service in _npc.services:
		match service:
			"rest":
				_buttons.add_child(_button(tr("Odpocznij (%d zł)") % _player.boons.discounted(rest_price(_player.stats.level)), _rest))
			"forge":
				_buttons.add_child(_button(tr("Wykuwanie"), _forge))
			"jeweler":
				# klejnoty dopiero po zadaniu "Pierwszy klejnot"
				if Gems.unlocked:
					_buttons.add_child(_button(tr("Klejnoty"), _jeweler))
			"enchant":
				var enchant := _button(tr("Zaklinanie"), _enchant)
				enchant.tooltip_text = tr("Kowal wbija kamienie z Kryształów Watry (lochy) w broń, zbroję i biżuterię")
				_buttons.add_child(enchant)
				var essences := _button(tr("Esencje"), func() -> void:
					close()
					essence_requested.emit("smith"))
				essences.tooltip_text = tr("Gniazdo na esencję legendy (Serce Kryształu z lochów) - osadzanie i wyjmowanie esencji")
				_buttons.add_child(essences)
			"disenchant":
				_buttons.add_child(_button(tr("Odczarowanie"), _sage))
			"world_mode":
				var mode_button := _button(tr("Tryb świata"), func() -> void:
					close()
					world_mode_requested.emit())
				mode_button.tooltip_text = tr("Jak zachowują się inni podróżnicy: spokojnie, z pojedynkami albo ze zbójami (PK)")
				_buttons.add_child(mode_button)
			"market":
				_buttons.add_child(_button(tr("Rynek"), func() -> void:
					close()
					market_requested.emit()))
			"travelers":
				_buttons.add_child(_button(tr("Podróżnicy"), func() -> void:
					close()
					travelers_requested.emit()))
			"reforge":
				var workshop := _button(tr("Warsztat"), func() -> void:
					close()
					workshop_requested.emit())
				workshop.tooltip_text = tr("Rzemiosło premii: przerzut, przekucie, usuwanie i dodawanie premii, ulepszanie rzadkości, runy z lochów")
				_buttons.add_child(workshop)
			"meals", "blessing", "bestiary", "elixirs", "respec", "marks":
				_buttons.add_child(_button(tr(OFFER_SERVICES[service]), _offers.bind(service)))
			"build":
				# plany budowy dopiero po zadaniu sołtysa z prośbą o pomoc
				var settlement := get_tree().get_first_node_in_group("settlement") as Settlement
				if settlement != null and settlement.building_unlocked(_player):
					_buttons.add_child(_button(tr("Budowa"), _build))
			"storage":
				_buttons.add_child(_button(tr("Magazyn"), _storage))
				if StorageWindow.can_upgrade(_player.storage):
					var cost := StorageWindow.upgrade_cost(StorageWindow.upgrades_done(_player.storage))
					var upgrade := _button(tr("Rozbuduj +%d (%d zł)") % [StorageWindow.SLOTS_PER_UPGRADE, cost], _upgrade_storage)
					upgrade.tooltip_text = tr("Magazynier dobuduje regał: %d -> %d miejsc") % [_player.storage.slots.size(),
							_player.storage.slots.size() + StorageWindow.SLOTS_PER_UPGRADE]
					_buttons.add_child(upgrade)
	if _npc.is_trader():
		_buttons.add_child(_button(tr("Handel"), _trade))
	_buttons.add_child(_button(tr("Do widzenia"), close))
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0 + Vector2(0, 40)).floor()


func _quest_section(id: String) -> void:
	var quest := Quests.get_data(id)
	var state := _player.quests.state_of(id)
	match state:
		Quests.STATE_AVAILABLE:
			_text.text = Quests.text(quest, "description")
			_quest_info(id, false)
			_buttons.add_child(_button(tr("Przyjmij zadanie"), _accept))
		Quests.STATE_ACTIVE:
			_text.text = Quests.text(quest, "progress_text")
			_quest_info(id, true)
		Quests.STATE_READY when Quests.receiver(id) != _npc.display_name:
			# zadanie główne oddaje się innej postaci
			_text.text = Quests.text(quest, "progress_text")
			_quest_info(id, true)
		Quests.STATE_READY:
			_text.text = Quests.text(quest, "complete_text")
			_quest_info(id, true)
			_buttons.add_child(_button(tr("Odbierz nagrodę"), _turn_in))
		_:
			_text.text = Quests.text(quest, "done_text")


func _quest_info(id: String, show_progress: bool) -> void:
	var quest := Quests.get_data(id)
	var main := MainQuests.is_main(id)
	var title := Quests.text(quest, "title")
	_quest_box.add_child(UiStyle.label(tr("Zadanie główne: %s") % title if main else title, 9, MainQuests.COLOR if main else UiStyle.TITLE_COLOR))
	var target := Quests.text(quest, "target_name")
	var goal := ""
	if main:
		goal = tr("Cel: %s") % (MainQuests.progress_text(_player, id) if show_progress else target)
		if Quests.receiver(id) != quest["giver"]:
			goal += tr("  (nagroda u: %s)") % Quests.person(Quests.receiver(id))
	elif show_progress:
		goal = tr("Cel: %s %d/%d") % [target, _player.quests.progress_of(id), quest["count"]]
	elif Quests.is_gather(id):
		goal = tr("Cel: zbierz %d (%s)") % [quest["count"], target.to_lower()]
	else:
		goal = tr("Cel: pokonaj %d (%s)") % [quest["count"], target.to_lower()]
	if Quests.requirements(id).size() > 1:
		# kilka surowców - każdy w osobnej linii
		var parts: Array[String] = []
		var needed: Dictionary = Quests.requirements(id)
		for item: String in needed:
			parts.append("%s %d/%d" % [tr(Items.get_data(item)["name"]), mini(_player.count_owned(item), needed[item]), needed[item]])
		goal = tr("Cel: zbierz %s") % ", ".join(parts)
	_quest_box.add_child(UiStyle.label(goal, 7, UiStyle.TEXT_COLOR))
	_quest_box.add_child(_wrapped(tr("Gdzie: %s") % Quests.text(quest, "area_name"), 7, UiStyle.DIM_COLOR))
	_quest_box.add_child(UiStyle.label(tr("Nagroda: %s") % Quests.reward_text(id), 7, Color(1.0, 0.85, 0.3)))


func _accept() -> void:
	_player.quests.accept(_shown_quest)
	_player.quests.update_main(_player)
	Sfx.play("ui_confirm")
	_npc.say(tr("Liczę na ciebie!"))


func _turn_in() -> void:
	var id := _shown_quest
	if _player.quests.turn_in(id, _player.stats):
		var quest := Quests.get_data(id)
		if Quests.is_gather(id):
			var needed: Dictionary = Quests.requirements(id)
			for item: String in needed:
				_player.take_owned(item, needed[item])
		Sfx.play("quest_done")
		DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -14),
				tr("+%d zł  +%d exp") % [quest["gold"], quest["xp"]], Color(1.0, 0.85, 0.3), 10)


func _offers(kind: String) -> void:
	var npc := _npc
	close()
	offers_requested.emit(kind, npc)


func _rest() -> void:
	var price := _player.boons.discounted(rest_price(_player.stats.level))
	if _player.stats.gold < price:
		_npc.say(tr("Najpierw zapłać, przyjacielu. %d złota.") % price)
		Sfx.play("ui_error")
		return
	Sfx.play("coins")
	_player.stats.add_gold(-price)
	close()
	rest_requested.emit()


## Rozbudowa magazynu o kolejny regał.
func _upgrade_storage() -> void:
	if not StorageWindow.can_upgrade(_player.storage):
		return
	var cost := StorageWindow.upgrade_cost(StorageWindow.upgrades_done(_player.storage))
	if _player.stats.gold < cost:
		_npc.say(tr("Regały same się nie zbudują. Potrzebuję %d złota.") % cost)
		Sfx.play("ui_error")
		return
	_player.stats.add_gold(-cost)
	_player.storage.resize(_player.storage.slots.size() + StorageWindow.SLOTS_PER_UPGRADE)
	Sfx.play("coins")
	Sfx.play_at("hammer", _npc.global_position)
	_npc.say(tr(["Nowy regał stoi!", "Zmieści się jeszcze więcej. Dziękuję!", "Dobudowane. Porządek musi być!"].pick_random()))
	_refresh()


func _forge() -> void:
	close()
	forge_requested.emit()


func _enchant() -> void:
	close()
	enchant_requested.emit()


func _jeweler() -> void:
	var npc := _npc
	close()
	jeweler_requested.emit(npc)


func _sage() -> void:
	close()
	sage_requested.emit()


func _build() -> void:
	close()
	build_requested.emit()


func _storage() -> void:
	var npc := _npc
	close()
	storage_requested.emit(npc)


func _trade() -> void:
	var npc := _npc
	close()
	npc.open_trade(_player)


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.custom_minimum_size = Vector2(0, 16)
	button.pressed.connect(on_pressed)
	return button


func _wrapped(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = WIDTH - 12.0
	return label
