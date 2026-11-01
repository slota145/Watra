class_name Hotbar
extends RefCounted
## Paski szybkiego wyboru gracza. Każdy slot przyjmuje umiejętność albo przedmiot do użycia (mikstura, posiłek).
## - Pasek umiejętności: 7 slotów (LPM, PPM, Q, E, R, Z, X), osobny układ dla każdego rodzaju broni - po zmianie
##   broni pasek podmienia się sam. Umiejętności tylko założonej broni (i zwykły atak "attack").
## - Pasek przedmiotów: 10 slotów pod klawiszami 1-0, wspólny dla wszystkich broni - umiejętność innej broni czeka
##   tam przygaszona, aż ją założysz.
## Slot z przedmiotem pamięta rodzaj przedmiotu (id), a nie konkretną sztukę - gdy przedmiot się skończy, slot
## zostaje (pokazuje 0) i sam się uzupełni po zakupie. Dodatkowe ciosy (combo) nie mają własnego slotu - wychodzą
## z ataku użytego zaraz po uderzeniu. Sloty liczy się wspólnie (slot_count): najpierw 7 umiejętności, potem 1-0.

signal changed

const ITEM_SLOTS := 10
const ITEM_KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
const SKILL_KEYS: Array[String] = ["LPM", "PPM", "Q", "E", "R", "Z", "X"]
## Akcje z project.godot dla slotów umiejętności (w kolejności SKILL_KEYS).
const SKILL_ACTIONS: Array[String] = ["attack", "skill", "skill_q", "skill_e", "skill_r", "skill_z", "skill_x"]
## Akcje wszystkich slotów (umiejętności, potem 1-0) i ich klawisze.
const SLOT_ACTIONS: Array[String] = ["attack", "skill", "skill_q", "skill_e", "skill_r", "skill_z", "skill_x",
		"item_1", "item_2", "item_3", "item_4", "item_5", "item_6", "item_7", "item_8", "item_9", "item_10"]
const SLOT_KEYS: Array[String] = ["LPM", "PPM", "Q", "E", "R", "Z", "X", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
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


## Czy wpis slotu to przedmiot (a nie umiejętność).
static func is_item(id: String) -> bool:
	return id != "" and id != ATTACK and not Skills.DATA.has(id) and Items.is_usable(id)


## Czy wpis może leżeć w slocie `index` (wspólna numeracja) przy broni `weapon_type`: przedmiot do użycia - wszędzie,
## umiejętność - na pasku umiejętności tylko tej broni, na pasku 1-0 każda.
static func fits(id: String, index: int, weapon_type: String) -> bool:
	if id == "" or is_item(id):
		return true
	if not can_slot_skill(id):
		return false
	return id == ATTACK or index >= SKILL_KEYS.size() or Skills.get_data(id).get("weapon", "") == weapon_type


static func slot_count() -> int:
	return SKILL_KEYS.size() + ITEM_SLOTS


## Nazwa wpisu paska (umiejętność albo zwykły atak) w obecnym języku.
static func skill_name(id: String) -> String:
	return attack_name() if id == ATTACK else Skills.name_of(id)


static func attack_name() -> String:
	return Lang.t(ATTACK_NAME)


## Nazwa klawisza slotu `index` (wspólna numeracja) w obecnym języku - przyciski myszy mają skróty ("LPM", "PPM").
static func key_name(index: int) -> String:
	var key := SLOT_KEYS[index]
	match key:
		"LPM":
			return Lang.t("LPM")
		"PPM":
			return Lang.t("PPM")
	return key


static func skill_icon(id: String) -> Texture2D:
	return ATTACK_ICON if id == ATTACK else Skills.get_data(id).get("icon") as Texture2D


func skill_bar(weapon_type: String) -> Array[String]:
	if not skills.has(weapon_type):
		skills[weapon_type] = default_skills(weapon_type)
	return skills[weapon_type]


## Wpis slotu `index` (wspólna numeracja: 0-6 pasek umiejętności broni, 7-16 pasek 1-0).
func entry(weapon_type: String, index: int) -> String:
	return skill_bar(weapon_type)[index] if index < SKILL_KEYS.size() else items[index - SKILL_KEYS.size()]


## Kładzie wpis na slot; jeśli ten sam wpis leży już na innym slocie (obu pasków), zamienia je miejscami
## (gdy wypierany wpis tam nie pasuje - tamten slot się opróżnia).
func put(weapon_type: String, index: int, id: String) -> void:
	var previous := find(weapon_type, id) if id != "" else -1
	if previous >= 0 and previous != index:
		var displaced := entry(weapon_type, index)
		_store(weapon_type, previous, displaced if fits(displaced, previous, weapon_type) else "")
	_store(weapon_type, index, id)
	changed.emit()


## Zamiana miejscami dwóch slotów (wspólna numeracja).
func move(weapon_type: String, from: int, to: int) -> void:
	var moved := entry(weapon_type, from)
	var other := entry(weapon_type, to)
	if not fits(moved, to, weapon_type):
		return
	_store(weapon_type, to, moved)
	_store(weapon_type, from, other if fits(other, from, weapon_type) else "")
	changed.emit()


## Slot z danym wpisem (-1 - brak).
func find(weapon_type: String, id: String) -> int:
	for i in slot_count():
		if entry(weapon_type, i) == id:
			return i
	return -1


func _store(weapon_type: String, index: int, id: String) -> void:
	if index < SKILL_KEYS.size():
		skill_bar(weapon_type)[index] = id
	else:
		items[index - SKILL_KEYS.size()] = id


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
	put(weapon_type, index, id)


func get_save_data() -> Dictionary:
	return {"items": items.duplicate(), "skills": skills.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	var saved_items: Array = data.get("items", [])
	for i in ITEM_SLOTS:
		var id := str(saved_items[i]) if i < saved_items.size() else ""
		items[i] = id if id == "" or is_item(id) or can_slot_skill(id) else ""
	var saved_skills: Dictionary = data.get("skills", {})
	for weapon_type in Skills.WEAPON_TYPES:
		if not saved_skills.has(weapon_type):
			continue
		var saved: Array = saved_skills[weapon_type]
		var bar: Array[String] = []
		for i in SKILL_KEYS.size():
			var id := str(saved[i]) if i < saved.size() else ""
			bar.append(id if id != "" and fits(id, i, weapon_type) else "")
		skills[weapon_type] = bar
	changed.emit()
