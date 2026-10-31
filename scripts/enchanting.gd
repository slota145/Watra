class_name Enchanting
## Zasady zaklinania przedmiotów kamieniami.
##
## Poziomy: 0 (brak), 1-15 (+1 ... +15) i 16-20 (I ... V).
## - Zwykły kamień: +1 ... +15, szansa maleje od 100% do 10%, porażka zabiera tylko kamień.
## - Doskonały kamień (od +15): I 60%, II 50%, III 40%, IV 30%, V 20%.
##   Porażka przy wbijaniu III i wyżej obniża poziom przedmiotu o 1
##   (chyba że chronią go kamienie miłosierdzia).
## - Uświęcone kamienie: 100 / 200 / 300 sztuk daje pewne wbicie III / IV / V.
## - Kamienie miłosierdzia: 10 / 20 / 30 sztuk chroni przed spadkiem poziomu przy wbijaniu III / IV / V.
## Każdy poziom +1...+15 dodaje 1 do statystyk bazowych przedmiotu (obrażenia broni, pancerz zbroi,
## premie liczbowe biżuterii), a każdy z I...V dodaje 5. Dolosowane premie (magiczne i rzadkie) nie rosną.
## Kamienie są osobne dla broni (czerwone), zbroi (niebieskie) i biżuterii (fioletowe).

const MAX_NORMAL := 15
const MAX_LEVEL := 20
const PERFECT_CHANCES: Array[int] = [60, 50, 40, 30, 20]
const ROMAN: Array[String] = ["I", "II", "III", "IV", "V"]
## Ile uświęconych kamieni daje pewne wbicie III, IV i V.
const BLESSED_COSTS: Array[int] = [100, 200, 300]
## Ile kamieni miłosierdzia chroni poziom przy wbijaniu III, IV i V.
const MERCY_COSTS: Array[int] = [10, 20, 30]
const BONUS_PER_NORMAL := 1
const BONUS_PER_PERFECT := 5

const CATEGORY_BY_SLOT := {
	"weapon": "weapon",
	"helmet": "armor", "chest": "armor", "gloves": "armor", "boots": "armor", "belt": "armor",
	"earring": "jewelry", "ring": "jewelry", "necklace": "jewelry",
}
## Odmiana do komunikatów: "kamień do zaklinania ...".
const CATEGORY_NAMES := {"weapon": "broni", "armor": "zbroi", "jewelry": "biżuterii"}


## Kategoria przedmiotu do zaklinania ("" jeśli nie da się go zaklinać).
static func category(item_id: String) -> String:
	return CATEGORY_BY_SLOT.get(Items.get_data(item_id).get("slot", ""), "")


static func stone_id(stone_category: String, perfect: bool) -> String:
	return "%s_stone%s" % [stone_category, "_perfect" if perfect else ""]


## Nazwa poziomu: "", "+7" albo "III".
static func level_name(level: int) -> String:
	if level <= 0:
		return ""
	if level <= MAX_NORMAL:
		return "+%d" % level
	return ROMAN[mini(level, MAX_LEVEL) - MAX_NORMAL - 1]


## O ile poziom zaklęcia zwiększa statystyki przedmiotu.
static func bonus(level: int) -> int:
	return mini(level, MAX_NORMAL) * BONUS_PER_NORMAL + maxi(level - MAX_NORMAL, 0) * BONUS_PER_PERFECT


## Szansa (w %) na wbicie następnego poziomu.
static func chance(level: int) -> int:
	var target := level + 1
	if target <= MAX_NORMAL:
		return roundi(100.0 - (target - 1) * 90.0 / (MAX_NORMAL - 1))
	return PERFECT_CHANCES[mini(target, MAX_LEVEL) - MAX_NORMAL - 1]


## Czy porażka obniża poziom (wbijanie III i wyżej).
static func failure_drops_level(level: int) -> bool:
	return level + 1 >= MAX_NORMAL + 3


## Ile uświęconych kamieni potrzeba na pewne wbicie następnego poziomu (0 = nie da się).
static func blessed_cost(level: int) -> int:
	var index := level + 1 - (MAX_NORMAL + 3)
	return BLESSED_COSTS[index] if index >= 0 and index < BLESSED_COSTS.size() else 0


## Ile kamieni miłosierdzia chroni poziom przy porażce (0 = poziom i tak nie spada).
static func mercy_cost(level: int) -> int:
	var index := level + 1 - (MAX_NORMAL + 3)
	return MERCY_COSTS[index] if index >= 0 and index < MERCY_COSTS.size() else 0


## Pusty napis, jeśli kamień pasuje do przedmiotu na danym poziomie, w przeciwnym razie powód.
static func check(stone: String, item_id: String, level: int) -> String:
	if item_id == "":
		return "Włóż przedmiot (PPM na przedmiocie)"
	if level >= MAX_LEVEL:
		return "Przedmiot ma już maksymalny poziom"
	if stone == "":
		return "Włóż kamień (PPM na kamieniu)"
	var stone_data: Dictionary = Items.get_data(stone).get("stone", {})
	if stone_data["category"] != category(item_id):
		return "Ten kamień służy do zaklinania %s" % CATEGORY_NAMES[stone_data["category"]]
	if stone_data["perfect"] and level < MAX_NORMAL:
		return "Kamień doskonały działa dopiero od +15"
	if not stone_data["perfect"] and level >= MAX_NORMAL:
		return "Od +15 potrzebny jest kamień doskonały"
	return ""
