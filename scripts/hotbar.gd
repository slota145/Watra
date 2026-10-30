class_name Hotbar
extends RefCounted
## Paski szybkiego wyboru gracza.
## - Przedmioty: 10 slotów pod klawiszami 1-0. Slot pamięta rodzaj przedmiotu (id), a nie konkretną sztukę -
##   gdy przedmiot się skończy, slot zostaje (pokazuje 0) i sam się uzupełni po zakupie.
## - Umiejętności: 7 slotów (LPM, PPM, Q, E, R, Z, X), osobny układ dla każdego rodzaju broni - po zmianie broni
##   pasek podmienia się sam. Na slot trafia zwykły atak ("attack"), umiejętność aktywna albo uderzenie.
##   Dodatkowe ciosy (combo) nie mają własnego slotu - wychodzą z ataku użytego zaraz po uderzeniu.

signal changed

const ITEM_SLOTS := 10
const ITEM_KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
const SKILL_KEYS: Array[String] = ["LPM", "PPM", "Q", "E", "R", "Z", "X"]
## Akcje z project.godot dla slotów umiejętności (w kolejności SKILL_KEYS).
const SKILL_ACTIONS: Array[String] = ["attack", "skill", "skill_q", "skill_e", "skill_r", "skill_z", "skill_x"]
## Zwykły atak bronią - też da się go przełożyć na dowolny slot.
const ATTACK := "attack"
const ATTACK_NAME := "Atak bronią"
const ATTACK_ICON := preload("res://assets/skills/attack.png")
## Nowa postać (i starsze zapisy bez paska): mikstury pod 1 i 2.
const DEFAULT_ITEMS: Array[String] = ["health_potion", "mana_potion"]
## Mikstury na start nowej postaci.
const STARTING_POTIONS := 5

## id przedmiotu w slotach 1-0 ("" = pusty)
var items: Array[String] = []
## rodzaj broni -> Array[String] (7 slotów umiejętności)
var skills := {}


func _init() -> void:
	items.resize(ITEM_SLOTS)
	items.fill("")
	for i in DEFAULT_ITEMS.size():
		items[i] = DEFAULT_ITEMS[i]
	for weapon_type in Skills.WEAPON_TYPES:
		skills[weapon_type] = default_skills(weapon_type)


## Domyślny układ umiejętności: atak pod LPM, umiejętność aktywna pod PPM, uderzenie pod Q.
static func default_skills(weapon_type: String) -> Array[String]:
	var ids := Skills.for_weapon(weapon_type)
	var bar: Array[String] = [ATTACK, ids[0], ids[1]]
	bar.resize(SKILL_KEYS.size())
	for i in range(3, bar.size()):
		bar[i] = ""
	return bar


## Czy umiejętność można położyć na pasku (atak, aktywna, uderzenie, umiejętność drzewka - nie combo i nie regeneracje).
static func can_slot_skill(id: String) -> bool:
	return id == ATTACK or Skills.get_data(id).get("type", "") in ["active", "strike", "skill"]


static func skill_name(id: String) -> String:
	return ATTACK_NAME if id == ATTACK else str(Skills.get_data(id).get("name", ""))


static func skill_icon(id: String) -> Texture2D:
	return ATTACK_ICON if id == ATTACK else Skills.get_data(id).get("icon") as Texture2D


func skill_bar(weapon_type: String) -> Array[String]:
	if not skills.has(weapon_type):
		skills[weapon_type] = default_skills(weapon_type)
	return skills[weapon_type]


func set_item(index: int, id: String) -> void:
	items[index] = id
	changed.emit()


## Przenosi przedmiot między slotami (zamiana miejscami).
func swap_items(from: int, to: int) -> void:
	var moved := items[from]
	items[from] = items[to]
	items[to] = moved
	changed.emit()


## Kładzie umiejętność na slocie; jeśli była już na innym slocie tego paska, zamienia je miejscami.
func set_skill(weapon_type: String, index: int, id: String) -> void:
	var bar := skill_bar(weapon_type)
	var previous := bar.find(id) if id != "" else -1
	if previous >= 0 and previous != index:
		bar[previous] = bar[index]
	bar[index] = id
	changed.emit()


func get_save_data() -> Dictionary:
	return {"items": items.duplicate(), "skills": skills.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	var saved_items: Array = data.get("items", [])
	for i in ITEM_SLOTS:
		var id := str(saved_items[i]) if i < saved_items.size() else ""
		items[i] = id if id == "" or Items.is_usable(id) else ""
	var saved_skills: Dictionary = data.get("skills", {})
	for weapon_type in Skills.WEAPON_TYPES:
		if not saved_skills.has(weapon_type):
			continue
		var saved: Array = saved_skills[weapon_type]
		var bar: Array[String] = []
		for i in SKILL_KEYS.size():
			var id := str(saved[i]) if i < saved.size() else ""
			var fits: bool = id == ATTACK or (Skills.get_data(id).get("weapon", "") == weapon_type and can_slot_skill(id))
			bar.append(id if fits else "")
		skills[weapon_type] = bar
	changed.emit()
