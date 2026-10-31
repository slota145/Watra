class_name StatusEffects
## Lista efektów działających na gracza - do rzędu ikon pod paskami zdrowia i many.
## Każdy efekt to słownik: "name", "description", "icon" (Texture2D), "left" (sekundy do końca, -1 = bez limitu),
## "total" (pełny czas, do mrugania i paska), "kind" (good - premia, bad - osłabienie, cooldown - efekt się odnawia),
## "stacks" (opcjonalnie, ile ładunków).
## Źródła: premie z osady i Dary Watry (Boons), poziom Watry, legendarne przedmioty (LegendaryEffects.statuses)
## oraz osłabienia od potworów (trucizna, spowolnienie, oszołomienie).

const WATRA_ICON := preload("res://assets/ui/status_watra.png")
const POISON_ICON := preload("res://assets/items/spider_venom.png")
const SLOW_ICON := preload("res://assets/items/drowned_algae.png")
const CONFUSE_ICON := preload("res://assets/items/satyr_horn.png")
## Ikony premii z osady (posiłki, błogosławieństwa, łaźnia); Dary Watry mają płomień.
const BOON_ICONS := {
	"stew": preload("res://assets/items/meal_stew.png"),
	"roast": preload("res://assets/items/meal_roast.png"),
	"broth": preload("res://assets/items/meal_broth.png"),
	"bless_wisdom": preload("res://assets/items/bless_wisdom.png"),
	"bless_might": preload("res://assets/items/bless_might.png"),
	"rested": preload("res://assets/items/rested.png"),
}


static func list(player: Player) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# osłabienia na początku - najważniejsze do zauważenia
	if player._poison_time > 0.0:
		result.append({"name": "Trucizna", "kind": "bad", "left": player._poison_time, "total": player._poison_time,
				"icon": POISON_ICON, "description": "Tracisz %d zdrowia na sekundę" % roundi(player._poison_dps)})
	if player._slow_time > 0.0:
		result.append({"name": "Spowolnienie", "kind": "bad", "left": player._slow_time, "total": player._slow_time,
				"icon": SLOW_ICON, "description": "Ruch wolniejszy o %d%%" % roundi((1.0 - player._slow_factor) * 100.0)})
	if player._confused_time > 0.0:
		result.append({"name": "Oszołomienie", "kind": "bad", "left": player._confused_time, "total": player._confused_time,
				"icon": CONFUSE_ICON, "description": "Sterowanie odwrócone - postać biegnie w przeciwną stronę"})
	for group: String in player.boons.active:
		var entry: Dictionary = player.boons.active[group]
		var data: Dictionary = Boons.DEFS[entry["id"]]
		result.append({"name": data["name"], "kind": "good", "left": float(entry["left"]), "total": float(data["time"]),
				"icon": _boon_icon(entry["id"]),
				"description": "%s: %s" % [Boons.GROUP_NAMES[group], data["description"]]})
	var level := player.boons.watra_level()
	if level > 1:
		var steps := level - 1
		result.append({"name": "Watra - poziom %d" % level, "kind": "good", "left": -1.0, "icon": WATRA_ICON,
				"description": "+%d%% złota, +%d%% doświadczenia, +%s zdrowia na sekundę" % [
					roundi(Boons.WATRA_PERKS["gold_find"] * steps * 100.0), roundi(Boons.WATRA_PERKS["xp_gain"] * steps * 100.0),
					String.num(Boons.WATRA_PERKS["health_regen"] * steps, 1).replace(".", ",")]})
	result.append_array(player.legendary.statuses())
	result.append_array(player.sword_skills.statuses())
	result.append_array(player.bow_skills.statuses())
	result.append_array(player.spell_skills.statuses())
	return result


## Ikona premii: posiłki, błogosławieństwa i łaźnia mają swoje, mikstury - ikonę przedmiotu, Dary Watry - płomień.
static func _boon_icon(id: String) -> Texture2D:
	if BOON_ICONS.has(id):
		return BOON_ICONS[id]
	if Items.get_data(id).has("icon"):
		return Items.get_data(id)["icon"]
	return WATRA_ICON


## Krótki zapis pozostałego czasu pod ikoną: "18m", "45s", "" (bez limitu).
static func time_text(left: float) -> String:
	if left < 0.0:
		return ""
	if left >= 60.0:
		return "%dm" % ceili(left / 60.0)
	return "%ds" % ceili(left)
