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
	"strength": {"name": "Siła", "description": "Za punkt: +1% obrażeń umiejętności z tagiem siły\ni 0,5% mniej otrzymywanych obrażeń (maks. 25%)"},
	"dexterity": {"name": "Zręczność", "description": "Za punkt: +1% obrażeń umiejętności z tagiem zręczności\ni 0,4% szansy na unik (coraz mniej przy wysokich wartościach)"},
	"intelligence": {"name": "Inteligencja", "description": "Za punkt: +1% obrażeń umiejętności z tagiem inteligencji\ni +5 do maks. many"},
}
const HEALTH_PER_VITALITY := 5
## Każdy poziom powyżej pierwszego dodaje tyle maksymalnego zdrowia.
const HEALTH_PER_LEVEL := 8
const MANA_PER_INTELLIGENCE := 5
## Unik ze zręczności: DODGE_PER_DEXTERITY za punkt, do DODGE_SOFT w całości, powyżej coraz słabiej, najwyżej DODGE_CAP
## (razem z unikiem z przedmiotów i tak najwyżej MAX_DODGE_CHANCE).
const DODGE_PER_DEXTERITY := 0.004
const DODGE_SOFT := 0.15
const DODGE_CAP := 0.35
## Malejące zyski z szybkości ataku i rzucania (speed_gain): do SPEED_SOFT premia liczy się w całości, powyżej
## coraz słabiej i nigdy nie przekracza SPEED_CAP (+150%), żeby nie dało się uzyskać absurdalnej szybkości.
const SPEED_SOFT := 0.6
const SPEED_CAP := 1.5
## Główny atrybut rodzaju broni - liczy się dla obrażeń bez tagów atrybutu (efekty legend, stare wywołania).
const DAMAGE_ATTRIBUTE := {"melee": "strength", "bow": "dexterity", "spell": "intelligence"}
## Każdy punkt atrybutu z tagu umiejętności (Skills.TAGS: siła, zręczność, inteligencja) daje tyle obrażeń (+1%).
const DAMAGE_PER_ATTRIBUTE := 0.01
## Premie do obrażeń umiejętności z tagiem formy (Skills.TAGS) i najwyższa szansa na stan od żywiołu.
const FORM_DAMAGE := {"projectile": "projectile_damage", "hit": "hit_damage", "area": "area_damage", "dot": "dot_damage"}
const MAX_AILMENT_CHANCE := 0.5
## Żywioły, które kamienie wsparcia dodają do trafień (added_<żywioł>).
const SUPPORT_ELEMENTS: Array[String] = ["fire", "ice", "lightning"]
## Mnożnik wszystkich obrażeń według rodzaju broni: łuk i księga trzymają wrogów na dystansie (bezpieczniej), ale bez
## tego zabijały o połowę wolniej niż miecz (tests/endgame_probe.gd, tryby bow_kite / spell_kite, listopad 2026).
const WEAPON_DAMAGE := {"melee": 1.0, "bow": 1.25, "spell": 1.25}
## Wersja zasad atrybutów w zapisie: starsze zapisy (atrybuty dawały szybkość i płaskie obrażenia) dostają
## przy wczytaniu wszystkie punkty atrybutów z powrotem do rozdania.
const ATTRIBUTE_RULES := 2
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
## Exp potrzebny na 2. poziom; kolejne progi rosną wykładniczo. Około 30 zwykłych potworów na poziom na początku
## i 200 pod koniec (tests/balance_sim.gd) - przy siedliskach z dziesiątkami potworów mniej dawało awans za awansem.
@export var xp_base := 120.0
@export var xp_exponent := 1.5

var level := 1
var xp := 0
var unspent_points := 0
var gold := 0
var attributes := {"vitality": 0, "strength": 0, "dexterity": 0, "intelligence": 0}
## Czy przy wczytaniu starego zapisu punkty atrybutów wróciły do rozdania (gracz dostaje o tym wiadomość).
var attributes_reset := false
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

## Chwilowe premie z umiejętności (Zew Peruna, Taniec Ostrzy, chmura Dymu i Cienia, Strzelanie w biegu) - suma
## premii ze źródeł (set_temp: "sword" - SwordSkills, "bow" - BowSkills).
var temp_bonus := {}
var _temp_sources := {}

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
	return _weapon_damage()[0] + int(_bonus("damage"))


func damage_max() -> int:
	return _weapon_damage()[1] + int(_bonus("damage"))


## Mnożnik szybkości ataku (1.0 = bazowa) z przedmiotów, drzewek i premii, bez prędkości samej broni.
func attack_speed() -> float:
	return 1.0 + speed_gain(_bonus("attack_speed"))


## Mnożnik szybkości rzucania czarów (1.0 = bazowa) z przedmiotów, drzewek i premii.
func cast_speed() -> float:
	return 1.0 + speed_gain(_bonus("cast_speed"))


## Prędkość założonej broni (1.0 = zwykła, sztylet szybszy, topór wolniejszy).
func weapon_speed() -> float:
	if equipment == null or equipment.weapon().is_empty():
		return 1.0
	return float(equipment.weapon().get("speed", 1.0))


## Premia do szybkości po malejących zyskach: do SPEED_SOFT bez zmian, dalej łagodnie do sufitu SPEED_CAP
## (krzywa bez załamania - pierwszy punkt ponad próg wciąż liczy się prawie w całości). Spowolnienia (ujemne) bez zmian.
static func speed_gain(raw: float) -> float:
	if raw <= SPEED_SOFT:
		return raw
	var room := SPEED_CAP - SPEED_SOFT
	return SPEED_SOFT + room * (1.0 - exp(-(raw - SPEED_SOFT) / room))


## Szybkość umiejętności z danymi rodzajami (Skills.tags): atak - szybkość ataku, czar - rzucania,
## atak i czar - średnia obu; razy prędkość założonej broni.
func skill_speed(tags: Array) -> float:
	var attack := "attack" in tags
	var spell := "spell" in tags
	var speed := attack_speed()
	if attack and spell:
		speed = (attack_speed() + cast_speed()) / 2.0
	elif spell:
		speed = cast_speed()
	return speed * weapon_speed() * maxf(1.0 + support(tags, "speed"), 0.1)


## Mnożnik obrażeń z premii do rodzaju (obrażenia fizyczne dla ataków, magiczne dla czarów, atak i czar - obie)
## i z atrybutów z tagów umiejętności (attribute_damage) - wszystkie premie się dodają.
func kind_multiplier(tags: Array) -> float:
	var total := 1.0 + attribute_damage(tags)
	if "attack" in tags:
		total += _bonus("physical_damage")
	if "spell" in tags:
		total += _bonus("spell_damage")
	# żywioły (Elements.TAG_DAMAGE): premia do swojego żywiołu i "obrażenia od żywiołów" (raz, choćby tagów było kilka)
	var elemental := false
	for tag: String in Elements.TAG_DAMAGE:
		if tag in tags:
			total += _bonus(Elements.TAG_DAMAGE[tag])
			elemental = true
	if elemental:
		total += _bonus("elemental_damage")
	# forma umiejętności (krok 3 dopieszczenia walki): pociski, ciosy, obszar, obrażenia w czasie
	for tag: String in FORM_DAMAGE:
		if tag in tags:
			total += _bonus(FORM_DAMAGE[tag])
	# kamienie wsparcia umiejętności (Supports): obrażenia w czasie, dodane żywioły, mnożnik "more"
	var skill := Skills.skill_of(tags)
	if skill == "" or skill_book == null:
		return total
	if "dot" in tags:
		total += skill_book.support_value(skill, "dot_damage")
	var added := 0.0
	for element: String in SUPPORT_ELEMENTS:
		added += skill_book.support_value(skill, "added_" + element)
	return total * (1.0 + added) * skill_book.support_more(skill)


## Premia `stat` kamieni wsparcia umiejętności, do której należą tagi (Skills.skill_of); 0 bez znacznika.
func support(tags: Array, stat: String) -> float:
	var skill := Skills.skill_of(tags)
	return skill_book.support_value(skill, stat) if skill != "" and skill_book != null else 0.0


## Żywioły dodane do trafienia przez kamienie wsparcia (Żarowe / Mroźne / Burzowe Ostrze).
func support_elements(tags: Array) -> Array[String]:
	var found: Array[String] = []
	for element: String in SUPPORT_ELEMENTS:
		if support(tags, "added_" + element) > 0.0:
			found.append(element)
	return found


## Szansa na stan od żywiołu (Elements.AILMENTS: ignite / freeze / shock), najwyżej MAX_AILMENT_CHANCE.
## Kamienie wsparcia umiejętności (tagi ze znacznikiem) dokładają swoją szansę.
func ailment_chance(ailment: String, tags: Array = []) -> float:
	return minf(_bonus(ailment + "_chance") + support(tags, ailment + "_chance"), MAX_AILMENT_CHANCE)


## Premia do obrażeń w czasie (także podpalenia; z kamieniami wsparcia umiejętności - też ich premie).
func dot_bonus(tags: Array = []) -> float:
	return _bonus("dot_damage") + support(tags, "dot_damage") + support(tags, "ignite_damage")


## Przebicie odporności potworów (ułamek odejmowany od ich odporności na żywioły).
func penetration() -> float:
	return _bonus("resistance_penetration")


func move_speed() -> float:
	return 1.0 + _bonus("move_speed")


func armor() -> int:
	return int(_bonus("armor"))


## Ile procent obrażeń pochłania pancerz przy potworach poziomu `level` (domyślnie - poziom potworów w okolicy);
## w końcówce gry stała pancerza rośnie (Levels.armor_scale), więc pancerz chroni słabiej.
func armor_reduction(level := -1) -> float:
	var k := ARMOR_CONSTANT * Levels.armor_scale(Levels.zone_default if level < 0 else level)
	return 1.0 - k / (k + armor())


## Ile procent obrażeń pochłania siła.
func strength_reduction() -> float:
	return minf(attribute("strength") * REDUCTION_PER_STRENGTH, MAX_STRENGTH_REDUCTION)


## Łączna redukcja obrażeń (pancerz i siła działają po kolei, więc nie przekroczą 100%).
func damage_reduction() -> float:
	return 1.0 - (1.0 - armor_reduction()) * (1.0 - strength_reduction())


## Obrażenia po obronie: fizyczne - pancerz i siła; żywioły i Nawia - odporność (Elements), siła i część pancerza.
func reduce_damage(amount: int, element := Elements.PHYSICAL) -> int:
	return maxi(1, roundi(amount * taken_multiplier(element)))


## Jaka część obrażeń danego rodzaju dociera do gracza (po pancerzu, sile i odporności).
func taken_multiplier(element := Elements.PHYSICAL) -> float:
	if element == Elements.PHYSICAL or not element in Elements.RESISTED:
		return 1.0 - damage_reduction()
	return (1.0 - armor_reduction() * Elements.ARMOR_SHARE) * (1.0 - strength_reduction()) * (1.0 - resistance(element))


## Odporność na żywioł albo Nawię: premie z przedmiotów (żywioły także "all_resistances") minus kara w lochach Nawii,
## w granicach Elements.MIN_RESISTANCE - MAX_RESISTANCE.
func resistance(element: String) -> float:
	return clampf(raw_resistance(element), Elements.MIN_RESISTANCE, Elements.MAX_RESISTANCE)


## Odporność przed przycięciem do sufitu (do okna postaci - ile ponad sufit).
func raw_resistance(element: String) -> float:
	var total := _bonus(element + "_resistance") - Elements.penalty
	if element in Elements.ELEMENTAL:
		total += _bonus("all_resistances") - Elements.curse
	return total


## Mnożnik wszystkich zadawanych obrażeń z premii "zwiększone obrażenia".
func damage_multiplier() -> float:
	return (1.0 + _bonus("damage_percent")) * float(WEAPON_DAMAGE.get(weapon_type(), 1.0))


func crit_chance() -> float:
	return minf(_bonus("crit_chance"), MAX_CRIT_CHANCE)


## Mnożnik zasięgu umiejętności obszarowych (premia "Obszar umiejętności" z przedmiotów i kamieni szlachetnych).
## Mnożnik leczenia mikstur zdrowia i many (premia "siła mikstur" z pasów).
func potion_multiplier() -> float:
	return 1.0 + _bonus("potion_power")


## Z tagami umiejętności (Skills.tags) - także premie obszaru jej kamieni wsparcia.
func area_multiplier(tags: Array = []) -> float:
	return 1.0 + _bonus("area") + support(tags, "area")


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
	return minf(dexterity_dodge() + _bonus("dodge_chance"), MAX_DODGE_CHANCE)


## Unik ze zręczności po malejących zyskach (jak speed_gain): do DODGE_SOFT w całości, dalej łagodnie do DODGE_CAP.
func dexterity_dodge() -> float:
	var raw := attribute("dexterity") * DODGE_PER_DEXTERITY
	if raw <= DODGE_SOFT:
		return maxf(raw, 0.0)
	var room := DODGE_CAP - DODGE_SOFT
	return DODGE_SOFT + room * (1.0 - exp(-(raw - DODGE_SOFT) / room))


## Mnożnik czasu odnowienia umiejętności (1,0 = bez skrócenia).
func cooldown_multiplier() -> float:
	return 1.0 - minf(_bonus("cooldown_reduction"), MAX_COOLDOWN_REDUCTION)


## Mnożniki złota z potworów i expa za zabicie wroga.
func gold_multiplier() -> float:
	return 1.0 + _bonus("gold_find")


func xp_multiplier() -> float:
	return 1.0 + _bonus("xp_gain")


## Mnożnik szansy na przedmioty i kamienie szlachetne z potworów (dar kapliczki w lochu).
func item_find_multiplier() -> float:
	return 1.0 + _bonus("item_find")


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


## Ustawia chwilowe premie jednego źródła (zastępują poprzednie premie tego źródła).
func set_temp(source: String, bonus: Dictionary) -> void:
	if _temp_sources.get(source, {}) == bonus:
		return
	_temp_sources[source] = bonus
	temp_bonus = {}
	for entry: Dictionary in _temp_sources.values():
		for stat: String in entry:
			temp_bonus[stat] = float(temp_bonus.get(stat, 0.0)) + float(entry[stat])
	changed.emit()


func _bonus(stat: String) -> float:
	var total := equipment.bonus(stat) if equipment != null else 0.0
	if skill_book != null:
		total += skill_book.tree_bonus(weapon_type(), stat)
	total += float(temp_bonus.get(stat, 0.0))
	return total + (boons.bonus(stat) if boons != null else 0.0)


## Premia procentowa do obrażeń z atrybutów z tagów umiejętności (+1% za punkt, Skills.ATTRIBUTE_TAGS).
## Bez tagu atrybutu (efekty legend, zwykłe "attack" / "spell") liczy się główny atrybut założonej broni.
## Kieł Gruzłoga sprawia, że pozostałe atrybuty bojowe (siła / zręczność / inteligencja) też dodają obrażenia
## (część premii); witalność się nie liczy.
func attribute_damage(tags: Array) -> float:
	var own: Array[String] = []
	for tag: String in Skills.ATTRIBUTE_TAGS:
		if tag in tags:
			own.append(Skills.ATTRIBUTE_TAGS[tag])
	if own.is_empty():
		own.append(DAMAGE_ATTRIBUTE[weapon_type()])
	var points := 0.0
	for id in own:
		points += attribute(id)
	var might := equipment.effect_power("might") if equipment != null else 0.0
	if might > 0.0:
		for other: String in DAMAGE_ATTRIBUTE.values():
			if not other in own:
				points += attribute(other) * might
	return maxf(points, 0.0) * DAMAGE_PER_ATTRIBUTE


func _weapon_damage() -> Array:
	if equipment == null or equipment.weapon().is_empty():
		return UNARMED_DAMAGE
	return equipment.weapon_damage()


## Ile expa potrzeba, żeby z obecnego poziomu wejść na następny.
func xp_to_next_level() -> int:
	return int(round(xp_base * pow(level, xp_exponent)))


func add_xp(amount: int) -> void:
	xp += amount
	# kamienie wsparcia w gniazdach umiejętności rosną razem z postacią (Supports.XP_SHARE)
	if skill_book != null and amount > 0:
		skill_book.add_support_xp(amount)
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


## Cofa jeden punkt atrybutu (prawy przycisk w oknie postaci).
func refund_point(attribute: String) -> bool:
	if attributes.get(attribute, 0) <= 0:
		return false
	attributes[attribute] -= 1
	unspent_points += 1
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
		"attribute_rules": ATTRIBUTE_RULES,
	}


func load_save_data(data: Dictionary) -> void:
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	unspent_points = int(data.get("unspent_points", 0))
	gold = int(data.get("gold", 0))
	var saved_attributes: Dictionary = data.get("attributes", {})
	for id: String in attributes:
		attributes[id] = int(saved_attributes.get(id, 0))
	# starszy zapis: atrybuty działały inaczej - wszystkie punkty wracają do rozdania (darmowy reset)
	attributes_reset = false
	if int(data.get("attribute_rules", 1)) < ATTRIBUTE_RULES:
		for id: String in attributes:
			unspent_points += attributes[id]
			attributes_reset = attributes_reset or attributes[id] > 0
			attributes[id] = 0
	changed.emit()
	xp_changed.emit(xp, xp_to_next_level(), level)
	gold_changed.emit(gold)
