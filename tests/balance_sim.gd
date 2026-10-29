extends SceneTree
## Symulacja balansu: typowy gracz na kolejnych etapach gry (poziom potworów L) - z ekwipunkiem z łupu
## tego etapu (generator Loot, średnia z wielu przedmiotów), zaklęciem broni z kamieni zebranych po drodze
## (Levels.stone_chances i szanse Enchanting) i punktami atrybutów w sile - kontra potwory danej krainy
## przeskalowane do poziomu L (krzywe Levels razy siła typu względem zwykłego potwora krainy). Liczy: ile ciosów zabija zwykłego i silnego potwora, ile ciosów
## zwykłego potwora zabija gracza, ile zabójstw na poziom postaci i złoto. Sprawdza docelowe widełki.

## Potwory wzorcowe krain (statystyki sceny i poziom, na który jest dostrojona): [nazwa, zdrowie, obrażenia, xp, złoto średnio]
const ENEMIES := {
	"forest": {"normal": ["goblin", 40, 12, 11, 2.5], "strong": ["goblin_brute", 160, 22, 40, 2.5]},
	"swamp": {"normal": ["frogman", 100, 17, 55, 7.0], "strong": ["drowner", 180, 22, 80, 8.0]},
	"mountains": {"normal": ["birdman", 230, 26, 120, 12.0], "strong": ["satyr_brute", 750, 60, 300, 30.0]},
	"ancient": {"normal": ["spider", 120, 18, 85, 9.0], "strong": ["treant", 260, 28, 110, 12.0]},
}
const STAGES := [1, 3, 5, 7, 9, 12, 14, 16, 18, 21, 24, 26, 29, 32]
## Docelowe widełki: ciosy na zwykłego, ciosy na silnego, ciosy zwykłego potwora do śmierci gracza, zabójstwa na poziom.
const TARGET_NORMAL := Vector2(2.5, 6.0)
const TARGET_STRONG := Vector2(6.0, 18.0)
const TARGET_SURVIVE := Vector2(6.0, 20.0)
const TARGET_KILLS := Vector2(8.0, 90.0)
const SAMPLES := 40

var loot
var items
var levels
var enchanting
var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _zone(level: int) -> String:
	for zone in ["ancient", "mountains", "swamp", "forest"]:
		if level >= levels.ZONES[zone][0]:
			return zone
	return "forest"


func _avg_items(line: String, item_level: int, quality: String) -> Dictionary:
	var total := {}
	var damage := 0.0
	for i in SAMPLES:
		var id: String = loot.generate(loot.base_for(line, item_level), quality, item_level)
		var data: Dictionary = items.get_data(id)
		if data.has("weapon"):
			damage += (data["weapon"]["damage"][0] + data["weapon"]["damage"][1]) / 2.0
		for stat in data.get("stats", {}):
			total[stat] = total.get(stat, 0.0) + float(data["stats"][stat])
		items.generated.erase(id)
	for stat in total:
		total[stat] /= SAMPLES
	total["weapon_damage"] = damage / SAMPLES
	return total


## Zaklęcie broni osiągnięte z `stones` zwykłych kamieni (oczekiwanie przez symulację prób).
func _enchant_from(stones: float) -> float:
	var sum := 0.0
	for run in 200:
		var lvl := 0
		var left := int(stones) + (1 if randf() < stones - int(stones) else 0)
		while left > 0 and lvl < enchanting.MAX_NORMAL:
			left -= 1
			if randf() * 100.0 < enchanting.chance(lvl):
				lvl += 1
		sum += lvl
	return sum / 200.0


func _run() -> void:
	loot = load("res://scripts/loot.gd")
	items = load("res://scripts/items.gd")
	levels = load("res://scripts/levels.gd")
	enchanting = load("res://scripts/enchanting.gd")
	print("  L  kraina    gracz  broń(zakl) ciosy:zwykły silny  przeżywa  zabójstw/poz  złoto/100")
	var weapon_stones := 0.0
	var last_level := 0
	for L: int in STAGES:
		var zone := _zone(L)
		var player_level := L + 1
		# kamienie zebrane od ostatniego etapu: zabójstwa na każdy poziom postaci po drodze
		var normal: Array = ENEMIES[zone]["normal"]
		var ref: Array = levels.REFERENCE[zone]
		var xp_kill: float = levels.xp(L) * normal[3] / ref[2]
		var kills_per_level: float = 40.0 * pow(player_level, 1.5) / xp_kill
		for l in range(last_level + 1, L + 1):
			weapon_stones += kills_per_level * levels.stone_chances(l)[0] / 3.0
		last_level = L
		var enchant := _enchant_from(weapon_stones)
		var weapon := _avg_items("sword", L, "magic")
		var armor := 0.0
		var health := 0.0
		for line in ["plate", "helm", "gauntlets", "greaves"]:
			var piece := _avg_items(line, L, "common")
			armor += piece.get("armor", 0.0)
			health += piece.get("health", 0.0)
		var strength := player_level - 1
		var hit: float = (weapon["weapon_damage"] + enchant + strength + weapon.get("damage", 0.0)) \
				* (1.0 + weapon.get("damage_percent", 0.0)) * (1.0 + weapon.get("crit_chance", 0.0) * 0.5)
		var hp: float = 100.0 + 8.0 * (player_level - 1) + health
		var reduction := (50.0 / (50.0 + armor)) * (1.0 - minf(strength * 0.005, 0.25))
		var strong: Array = ENEMIES[zone]["strong"]
		var normal_hp: float = levels.health(L) * normal[1] / ref[0]
		var strong_hp: float = levels.health(L) * strong[1] / ref[0]
		var normal_dmg: float = levels.damage(L) * normal[2] / ref[1] * reduction
		var hits_normal := normal_hp / hit
		var hits_strong := strong_hp / hit
		var survive := hp / maxf(normal_dmg, 1.0)
		var gold: float = levels.gold(L) * normal[4] / ref[3] * 100.0
		print("%3d  %-9s %3d   %5.1f(+%.1f)   %5.1f  %6.1f    %6.1f      %6.1f      %6.0f" % [L, zone, player_level,
				hit, enchant, hits_normal, hits_strong, survive, kills_per_level, gold])
		_check(hits_normal, TARGET_NORMAL, "L%d: ciosy na zwykłego" % L)
		_check(hits_strong, TARGET_STRONG, "L%d: ciosy na silnego" % L)
		_check(survive, TARGET_SURVIVE, "L%d: przeżywa ciosów" % L)
		_check(kills_per_level, TARGET_KILLS, "L%d: zabójstw na poziom" % L)
	print("WYNIK: ", "OK" if _fails == 0 else "%d poza widełkami" % _fails)
	quit()


func _check(value: float, window: Vector2, what: String) -> void:
	if value < window.x or value > window.y:
		_fails += 1
		print("FAIL %s: %.1f poza [%.1f, %.1f]" % [what, value, window.x, window.y])
