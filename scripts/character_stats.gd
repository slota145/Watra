class_name CharacterStats
extends Node
## Poziom, doświadczenie, atrybuty i złoto postaci.
## Każdy poziom daje punkt do rozdania na jeden z atrybutów.
## Wartości wynikowe (zdrowie, obrażenia, pancerz...) uwzględniają założony ekwipunek.

signal changed
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
signal gold_changed(gold: int)

const ATTRIBUTES := {
	"vitality": {"name": "Witalność", "description": "Za punkt: +5 do maks. zdrowia"},
	"strength": {"name": "Siła", "description": "Za punkt: +1 do obrażeń broni białej\ni 0,5% mniej otrzymywanych obrażeń (maks. 25%)"},
	"dexterity": {"name": "Zręczność", "description": "Za punkt: +2% szybkości ataku i umiejętności\ni +1 do obrażeń z łuków"},
	"intelligence": {"name": "Inteligencja", "description": "Za punkt: +5 do maks. many\ni +1 do obrażeń magicznych"},
}
const HEALTH_PER_VITALITY := 5
## Każdy poziom powyżej pierwszego dodaje tyle maksymalnego zdrowia.
const HEALTH_PER_LEVEL := 8
const MANA_PER_INTELLIGENCE := 5
const ATTACK_SPEED_PER_DEXTERITY := 0.02
## Szybkość rzucania czarów rośnie z inteligencją tak jak szybkość ataku ze zręcznością.
const CAST_SPEED_PER_INTELLIGENCE := 0.02
## Który atrybut zwiększa obrażenia danego rodzaju broni (o 1 za punkt).
const DAMAGE_ATTRIBUTE := {"melee": "strength", "bow": "dexterity", "spell": "intelligence"}
const DAMAGE_PER_ATTRIBUTE := 1
const REDUCTION_PER_STRENGTH := 0.005
const MAX_STRENGTH_REDUCTION := 0.25
const POINTS_PER_LEVEL := 1
## Obrażenia gołymi pięściami (bez broni).
const UNARMED_DAMAGE := [1, 3]
## Pancerz zmniejsza obrażenia: otrzymane = obrażenia * K / (K + pancerz).
const ARMOR_CONSTANT := 50.0
## Cios krytyczny bez premii zadaje +50% obrażeń; szansa na niego, unik i skrócenie odnowienia mają limity.
const BASE_CRIT_DAMAGE := 0.5
const MAX_CRIT_CHANCE := 0.75
const MAX_DODGE_CHANCE := 0.5
const MAX_COOLDOWN_REDUCTION := 0.5

@export var base_health := 100
@export var base_mana := 50
## Exp potrzebny na 2. poziom; kolejne progi rosną wykładniczo.
@export var xp_base := 40.0
@export var xp_exponent := 1.5

var level := 1
var xp := 0
var unspent_points := 0
var gold := 0
var attributes := {"vitality": 0, "strength": 0, "dexterity": 0, "intelligence": 0}
## Premie z osady (posiłki, błogosławieństwa) - ustawiane przez gracza.
var boons: Boons:
	set(value):
		boons = value
		boons.changed.connect(changed.emit)

## Założone przedmioty - ustawiane przez gracza.
var equipment: Equipment:
	set(value):
		equipment = value
		equipment.changed.connect(changed.emit)

## Chwilowe premie z umiejętności (Zew Peruna, Taniec Ostrzy, chmura Dymu i Cienia) - ustawia SwordSkills.
var temp_bonus := {}

## Umiejętności gracza - premie z wybranych węzłów drzewka założonej broni (ustawiane przez gracza).
var skill_book: SkillBook:
	set(value):
		skill_book = value
		skill_book.changed.connect(changed.emit)


func max_health() -> int:
	var flat := base_health + (level - 1) * HEALTH_PER_LEVEL + attribute("vitality") * HEALTH_PER_VITALITY + int(_bonus("health"))
	return roundi(flat * (1.0 + _bonus("health_percent")))


func max_mana() -> int:
	return base_mana + attribute("intelligence") * MANA_PER_INTELLIGENCE + int(_bonus("mana"))


func damage_min() -> int:
	return _weapon_damage()[0] + _flat_damage()


func damage_max() -> int:
	return _weapon_damage()[1] + _flat_damage()


## Mnożnik szybkości ataku (1.0 = bazowa), bez prędkości samej broni.
func attack_speed() -> float:
	return 1.0 + attribute("dexterity") * ATTACK_SPEED_PER_DEXTERITY + _bonus("attack_speed")


## Mnożnik szybkości rzucania czarów (1.0 = bazowa).
func cast_speed() -> float:
	return 1.0 + attribute("intelligence") * CAST_SPEED_PER_INTELLIGENCE + _bonus("cast_speed")


## Szybkość umiejętności z danymi rodzajami (Skills.tags): atak - szybkość ataku, czar - rzucania,
## atak i czar - średnia obu.
func skill_speed(tags: Array) -> float:
	var attack := "attack" in tags
	var spell := "spell" in tags
	if attack and spell:
		return (attack_speed() + cast_speed()) / 2.0
	return cast_speed() if spell else attack_speed()


## Mnożnik obrażeń z premii do rodzaju: obrażenia fizyczne dla ataków, magiczne dla czarów (atak i czar - obie).
func kind_multiplier(tags: Array) -> float:
	var total := 1.0
	if "attack" in tags:
		total += _bonus("physical_damage")
	if "spell" in tags:
		total += _bonus("spell_damage")
	return total


func move_speed() -> float:
	return 1.0 + _bonus("move_speed")


func armor() -> int:
	return int(_bonus("armor"))


## Ile procent obrażeń pochłania pancerz.
func armor_reduction() -> float:
	return 1.0 - ARMOR_CONSTANT / (ARMOR_CONSTANT + armor())


## Ile procent obrażeń pochłania siła.
func strength_reduction() -> float:
	return minf(attribute("strength") * REDUCTION_PER_STRENGTH, MAX_STRENGTH_REDUCTION)


## Łączna redukcja obrażeń (pancerz i siła działają po kolei, więc nie przekroczą 100%).
func damage_reduction() -> float:
	return 1.0 - (1.0 - armor_reduction()) * (1.0 - strength_reduction())


func reduce_damage(amount: int) -> int:
	return maxi(1, roundi(amount * (1.0 - damage_reduction())))


## Mnożnik wszystkich zadawanych obrażeń z premii "zwiększone obrażenia".
func damage_multiplier() -> float:
	return 1.0 + _bonus("damage_percent")


func crit_chance() -> float:
	return minf(_bonus("crit_chance"), MAX_CRIT_CHANCE)


## Mnożnik obrażeń ciosu krytycznego (bazowo 1,5).
func crit_multiplier() -> float:
	return 1.0 + BASE_CRIT_DAMAGE + _bonus("crit_damage")


## Zdrowie odzyskiwane za każde trafienie wroga.
func life_on_hit() -> int:
	return int(_bonus("life_on_hit"))


## Regeneracja zdrowia i many z przedmiotów (punkty na sekundę).
func health_regen() -> float:
	return _bonus("health_regen")


func mana_regen() -> float:
	return _bonus("mana_regen")


func dodge_chance() -> float:
	return minf(_bonus("dodge_chance"), MAX_DODGE_CHANCE)


## Mnożnik czasu odnowienia umiejętności (1,0 = bez skrócenia).
func cooldown_multiplier() -> float:
	return 1.0 - minf(_bonus("cooldown_reduction"), MAX_COOLDOWN_REDUCTION)


## Mnożniki złota z potworów i expa za zabicie wroga.
func gold_multiplier() -> float:
	return 1.0 + _bonus("gold_find")


func xp_multiplier() -> float:
	return 1.0 + _bonus("xp_gain")


## Rodzaj założonej broni: melee (także pięści), bow albo spell.
func weapon_type() -> String:
	if equipment == null:
		return "melee"
	return equipment.weapon().get("type", "melee")


## Zwraca wszystkie rozdane punkty atrybutów do puli.
func reset_attributes() -> void:
	var spent := 0
	for id: String in attributes:
		spent += attributes[id]
		attributes[id] = 0
	if spent == 0:
		return
	unspent_points += spent
	changed.emit()


func spent_points() -> int:
	var total := 0
	for id: String in attributes:
		total += attributes[id]
	return total


## Atrybut razem z premią z ekwipunku (np. legendarne pierścienie dają siłę albo zręczność).
func attribute(id: String) -> int:
	return attributes[id] + int(_bonus(id))


func _bonus(stat: String) -> float:
	var total := equipment.bonus(stat) if equipment != null else 0.0
	if skill_book != null:
		total += skill_book.tree_bonus(weapon_type(), stat)
	total += float(temp_bonus.get(stat, 0.0))
	return total + (boons.bonus(stat) if boons != null else 0.0)


## Premia do obrażeń z atrybutu pasującego do broni oraz z przedmiotów. Kieł Gruzłoga
## sprawia, że pozostałe dwa atrybuty bojowe (siła / zręczność / inteligencja) też dodają
## obrażenia (część premii głównego); witalność się nie liczy.
func _flat_damage() -> int:
	var main: String = DAMAGE_ATTRIBUTE[weapon_type()]
	var damage := float(attribute(main) * DAMAGE_PER_ATTRIBUTE)
	var might := equipment.effect_power("might") if equipment != null else 0.0
	if might > 0.0:
		for other: String in DAMAGE_ATTRIBUTE.values():
			if other != main:
				damage += attribute(other) * DAMAGE_PER_ATTRIBUTE * might
	return roundi(damage) + int(_bonus("damage"))


func _weapon_damage() -> Array:
	if equipment == null or equipment.weapon().is_empty():
		return UNARMED_DAMAGE
	return equipment.weapon_damage()


## Ile expa potrzeba, żeby z obecnego poziomu wejść na następny.
func xp_to_next_level() -> int:
	return int(round(xp_base * pow(level, xp_exponent)))


func add_xp(amount: int) -> void:
	xp += amount
	var leveled := false
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		unspent_points += POINTS_PER_LEVEL
		leveled = true
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next_level(), level)
	if leveled:
		changed.emit()


func spend_point(attribute: String) -> bool:
	if unspent_points <= 0 or not attributes.has(attribute):
		return false
	attributes[attribute] += 1
	unspent_points -= 1
	changed.emit()
	return true


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func get_save_data() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"unspent_points": unspent_points,
		"gold": gold,
		"attributes": attributes.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	unspent_points = int(data.get("unspent_points", 0))
	gold = int(data.get("gold", 0))
	var saved_attributes: Dictionary = data.get("attributes", {})
	for id: String in attributes:
		attributes[id] = int(saved_attributes.get(id, 0))
	changed.emit()
	xp_changed.emit(xp, xp_to_next_level(), level)
	gold_changed.emit(gold)
