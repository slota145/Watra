class_name Skills
## Baza umiejętności. Każdy rodzaj broni (melee / bow / spell) ma swoje drzewko:
## aktywną umiejętność (domyślnie pod PPM), uderzenie (type "strike", domyślnie pod Q), dodatkowy cios
## - atak zaraz po uderzeniu (type "combo", wymaga uderzenia) - i dwie pasywne regeneracje.
## Aktywną umiejętność i uderzenie gracz kładzie na dowolny slot paska (Hotbar).
## Wszystkie działają tylko z założoną bronią swojego rodzaju.
## Umiejętności odblokowuje się i ulepsza za złoto (koszty rosną z poziomem). Broń, która ma drzewko (SkillTree,
## na razie miecz), odblokowuje je węzłem za punkt umiejętności, a złoto kupuje kolejne poziomy.
## Umiejętności drzewka (type "skill") mają własną obsługę (SwordSkills) i własne combo (COMBOS).
## Każda umiejętność to atak, czar albo jedno i drugie (TAGS): ataki wzmacniają szybkość ataku i obrażenia fizyczne,
## czary - szybkość rzucania i obrażenia magiczne.

const MAX_LEVEL := 5
const WEAPON_TYPES: Array[String] = ["melee", "bow", "spell"]
const WEAPON_NAMES := {"melee": "Broń biała", "bow": "Łuk", "spell": "Księga magii"}

const ACTIVE_COSTS: Array[int] = [150, 300, 600, 1200, 2400]
const PASSIVE_COSTS: Array[int] = [80, 160, 320, 640, 1280]

const ICON_HEALTH := preload("res://assets/skills/health_regen.png")
const ICON_MANA := preload("res://assets/skills/mana_regen.png")

## type: active / strike / combo / skill / health_regen / mana_regen
const DATA := {
	"flicker": {
		"name": "Mgnienie", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/flicker.png"),
		"description": "Przytrzymaj klawisz - doskakujesz do najbliższego wroga i tniesz, potem do kolejnego, dopóki starcza many. Combo: w trakcie Młynka wirujesz od wroga do wroga (odnowienie).",
	},
	"smoke_burst": {
		"name": "Dymne Wybuchy", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/smoke_burst.png"),
		"description": "Przytrzymaj klawisz, by ładować: 3 wybuchy dymu przed tobą, dłuższe ładowanie dokłada drugi i trzeci rząd - 9 wybuchów w stożku. Atak i czar. Combo: zaraz po innej umiejętności - wszystkie 9 od razu, bez ładowania.",
	},
	"lunge": {
		"name": "Szarża", "weapon": "melee", "type": "strike",
		"icon": preload("res://assets/skills/lunge.png"),
		"description": "Błyskawiczne pchnięcie mieczem w stronę kursora, raniące wszystkich na drodze. Combo: atak zaraz potem to Półksiężyc.",
	},
	"crescent": {
		"name": "Półksiężyc", "weapon": "melee", "type": "combo", "requires": "lunge",
		"icon": preload("res://assets/skills/crescent.png"),
		"description": "Combo: atak zaraz po Szarży - potężne cięcie po półksiężycu, dużo szersze niż zwykły atak.",
	},
	"seeker": {
		"name": "Strzała tropiąca", "weapon": "bow", "type": "strike",
		"icon": preload("res://assets/skills/seeker.png"),
		"description": "Strzała sama szuka wrogów: przebija ich na wylot i nawraca po łuku do kolejnego celu. Combo: atak zaraz potem to Szybka salwa.",
	},
	"rapid_volley": {
		"name": "Szybka salwa", "weapon": "bow", "type": "combo", "requires": "seeker",
		"icon": preload("res://assets/skills/rapid_volley.png"),
		"description": "Combo: atak zaraz po Strzale tropiącej - seria szybkich strzał w stronę kursora.",
	},
	"chain_lightning": {
		"name": "Łańcuch błyskawic", "weapon": "spell", "type": "strike",
		"icon": preload("res://assets/skills/chain_lightning.png"),
		"description": "Błyskawica przeskakuje błyskawicznie od wroga do wroga. Combo: atak zaraz potem to Fala piorunów.",
	},
	"thunder_wave": {
		"name": "Fala piorunów", "weapon": "spell", "type": "combo", "requires": "chain_lightning",
		"icon": preload("res://assets/skills/thunder_wave.png"),
		"description": "LPM zaraz po łańcuchu błyskawic - fala piorunów w szerokim stożku przed tobą.",
	},
	"whirlwind": {
		"name": "Młynek", "weapon": "melee", "type": "active",
		"icon": preload("res://assets/skills/whirlwind.png"),
		"description": "Przytrzymaj klawisz - wirujesz z bronią, raniąc wszystkich wokół. Zużywa manę co sekundę.",
	},
	"warrior_blood": {
		"name": "Krew wojownika", "weapon": "melee", "type": "health_regen", "icon": ICON_HEALTH,
		"description": "Rany goją się same, póki trzymasz broń białą.",
	},
	"battle_focus": {
		"name": "Skupienie bitewne", "weapon": "melee", "type": "mana_regen", "icon": ICON_MANA,
		"description": "Szybsza odnowa many z bronią białą.",
	},
	"multishot": {
		"name": "Salwa", "weapon": "bow", "type": "active",
		"icon": preload("res://assets/skills/multishot.png"),
		"description": "Wystrzeliwujesz 3 strzały naraz w wąskim stożku.",
	},
	"hunter_breath": {
		"name": "Oddech łowcy", "weapon": "bow", "type": "health_regen", "icon": ICON_HEALTH,
		"description": "Rany goją się same, póki trzymasz łuk.",
	},
	"hunter_patience": {
		"name": "Cierpliwość łowcy", "weapon": "bow", "type": "mana_regen", "icon": ICON_MANA,
		"description": "Szybsza odnowa many z łukiem.",
	},
	"fireball": {
		"name": "Kula ognia", "weapon": "spell", "type": "active",
		"icon": preload("res://assets/skills/fireball.png"),
		"description": "Przytrzymaj klawisz, by ładować kulę ognia w dłoniach (zjada manę) - im dłużej, tym mocniejszy i większy wybuch. Puść, by rzucić.",
	},
	"mystic_renewal": {
		"name": "Mistyczna odnowa", "weapon": "spell", "type": "health_regen", "icon": ICON_HEALTH,
		"description": "Rany goją się same, póki trzymasz księgę.",
	},
	"mana_stream": {
		"name": "Strumień many", "weapon": "spell", "type": "mana_regen", "icon": ICON_MANA,
		"description": "Szybsza odnowa many z księgą.",
	},
}

## Parametry aktywnych umiejętności niezależne od poziomu.
const WHIRLWIND_MANA_PER_SECOND := 10.0
const WHIRLWIND_TICK := 0.25
const MULTISHOT_MANA := 8.0
const MULTISHOT_COOLDOWN := 0.7
const MULTISHOT_ARROWS := 3
const MULTISHOT_SPREAD_DEGREES := 16.0
const FIREBALL_MANA := 14.0
const FIREBALL_COOLDOWN := 0.9
## Uderzenia i dodatkowe ciosy (atak w ciągu COMBO_WINDOW s po uderzeniu).
const COMBO_WINDOW := 1.2
const LUNGE_MANA := 10.0
const LUNGE_COOLDOWN := 2.5
const LUNGE_DISTANCE := 120.0
const CRESCENT_MANA := 6.0
const CRESCENT_ARC_DEGREES := 300.0
const CRESCENT_DAMAGE := 1.5
const SEEKER_MANA := 12.0
const SEEKER_COOLDOWN := 2.2
const SEEKER_DAMAGE := 0.9
const VOLLEY_MANA := 6.0
const VOLLEY_DAMAGE := 0.7
const CHAIN_MANA := 14.0
const CHAIN_COOLDOWN := 2.4
const CHAIN_DAMAGE := 1.6
## Każdy kolejny przeskok błyskawicy jest o tyle słabszy.
const CHAIN_FALLOFF := 0.9
const WAVE_MANA := 8.0
const WAVE_DAMAGE := 1.4
## Mgnienie: mana za skok, odstęp między skokami (s, krótszy z szybkością ataku), zasięg szukania wroga,
## wirujące Mgnienie (combo z Młynkiem): odnowienie i odstęp skoków.
const FLICKER_MANA := 7.0
const FLICKER_INTERVAL := 0.32
const FLICKER_RANGE := 190.0
const WHIRL_FLICKER_COOLDOWN := 8.0
const WHIRL_FLICKER_INTERVAL := 0.11
## Dymne Wybuchy: mana, czas ładowania jednego rzędu, odległość, promień i rozstaw kątowy wybuchów w rzędach 1-3.
const SMOKE_MANA := 14.0
const SMOKE_CHARGE_TIME := 0.45
const SMOKE_DISTANCE: Array[float] = [36.0, 74.0, 114.0]
const SMOKE_RADIUS: Array[float] = [22.0, 28.0, 34.0]
const SMOKE_SPREAD_DEGREES: Array[float] = [22.0, 20.0, 18.0]
## Ładowanie kuli ognia: czas do pełnej mocy, dodatkowa mana zjadana w trakcie
## i ile razy więcej obrażeń / większy promień daje pełne naładowanie.
const FIREBALL_CHARGE_TIME := 1.5
const FIREBALL_CHARGE_MANA := 30.0
const FIREBALL_FULL_DAMAGE := 2.5
const FIREBALL_FULL_RADIUS := 1.8


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, {})


## Ataki i czary (zwykły atak bronią: atak, a magiczny pocisk księgi - czar).
const TAGS := {
	"lunge": ["attack"], "crescent": ["attack"], "whirlwind": ["attack"], "flicker": ["attack"], "smoke_burst": ["attack", "spell"],
	"seeker": ["attack"], "rapid_volley": ["attack"], "multishot": ["attack"],
	"chain_lightning": ["spell"], "thunder_wave": ["spell"], "fireball": ["spell"],
}


static func tags(id: String) -> Array:
	return TAGS.get(id, [])


static func tags_text(id: String) -> String:
	var names: Array[String] = []
	for tag: String in tags(id):
		names.append({"attack": "atak", "spell": "czar"}[tag])
	return " i ".join(names).capitalize() if not names.is_empty() else ""


## Combo umiejętności drzewka: po jakich umiejętnościach (użytych w oknie COMBO_WINDOW) zachowują się inaczej;
## "any" - po każdej innej. Mgnienie w trakcie Młynka obsługuje SwordSkills osobno (wirujące Mgnienie).
const COMBOS := {"smoke_burst": ["any"], "flicker": ["whirlwind"]}


## Umiejętności danego rodzaju broni w kolejności: aktywna, uderzenie, dodatkowy cios, życie, mana.
static func for_weapon(weapon_type: String) -> Array[String]:
	var result: Array[String] = []
	for kind in ["active", "strike", "combo", "skill", "health_regen", "mana_regen"]:
		for id: String in DATA:
			if DATA[id]["weapon"] == weapon_type and DATA[id]["type"] == kind:
				result.append(id)
	return result


## Koszt kupna poziomu `level` (1 = odblokowanie).
static func cost(id: String, level: int) -> int:
	var costs := PASSIVE_COSTS if DATA[id]["type"] in ["health_regen", "mana_regen"] else ACTIVE_COSTS
	return costs[level - 1]


# ---------------------------------------------------------------- wartości zależne od poziomu
## Młynek: procent obrażeń broni za każde uderzenie (co WHIRLWIND_TICK s).
static func whirlwind_damage(level: int) -> float:
	return 0.35 + 0.08 * level


static func whirlwind_radius(level: int) -> float:
	return 30.0 + 3.0 * level


## Salwa: procent obrażeń broni na strzałę.
static func multishot_damage(level: int) -> float:
	return 0.75 + 0.12 * level


## Kula ognia: procent obrażeń broni w wybuchu i jego promień.
static func fireball_damage(level: int) -> float:
	return 1.0 + 0.2 * level


static func fireball_radius(level: int) -> float:
	return 28.0 + 4.0 * level


## Mnożniki za naładowanie (charge 0..1).
static func fireball_charge_damage(charge: float) -> float:
	return lerpf(1.0, FIREBALL_FULL_DAMAGE, charge)


static func fireball_charge_radius(charge: float) -> float:
	return lerpf(1.0, FIREBALL_FULL_RADIUS, charge)


## Szarża: prędkość (px/s) i procent obrażeń broni.
## Mgnienie: procent obrażeń broni za cięcie po skoku; ile skoków ma wirujące Mgnienie.
static func flicker_damage(level: int) -> float:
	return 1.1 + 0.15 * level


static func whirl_flicker_jumps(level: int) -> int:
	return 3 + level


## Dymne Wybuchy: procent obrażeń broni wybuchu w rzędzie `ring` (0-2).
static func smoke_damage(level: int, ring: int) -> float:
	return (0.7 + 0.1 * level) * (1.0 + 0.2 * ring)


static func lunge_speed(level: int) -> float:
	return 380.0 + 40.0 * level


static func lunge_damage(level: int) -> float:
	return 1.2 + 0.25 * level


## Półksiężyc: zasięg cięcia (zwykły atak ma około 30).
static func crescent_radius(level: int) -> float:
	return 44.0 + 6.0 * level


## Strzała tropiąca: ile razy trafia, zanim zniknie.
static func seeker_hits(level: int) -> int:
	return 3 + level


## Szybka salwa: ile strzał.
static func volley_arrows(level: int) -> int:
	return 2 + level


## Łańcuch błyskawic: ilu wrogów trafia.
static func chain_targets(level: int) -> int:
	return 2 + level


## Fala piorunów: połowa kąta stożka (stopnie) i jego zasięg.
static func wave_half_angle(level: int) -> float:
	return 30.0 + 6.0 * level


static func wave_radius(level: int) -> float:
	return 120.0 + 12.0 * level


static func health_regen(level: int, maximum := 0.0) -> float:
	return 0.4 * level + 0.003 * level * maximum


static func mana_regen(level: int, maximum := 0.0) -> float:
	return 0.5 * level + 0.004 * level * maximum


## Ile many trzeba, żeby użyć umiejętności (młynek: na ułamek sekundy, jak przy starcie).
static func mana_cost(id: String) -> float:
	return {"whirlwind": WHIRLWIND_MANA_PER_SECOND * 0.3, "multishot": MULTISHOT_MANA, "fireball": FIREBALL_MANA,
			"flicker": FLICKER_MANA, "smoke_burst": SMOKE_MANA,
			"lunge": LUNGE_MANA, "crescent": CRESCENT_MANA, "seeker": SEEKER_MANA, "rapid_volley": VOLLEY_MANA,
			"chain_lightning": CHAIN_MANA, "thunder_wave": WAVE_MANA}.get(id, 0.0)


static func mana_cost_text(id: String) -> String:
	match id:
		"whirlwind":
			return "%d many/s" % WHIRLWIND_MANA_PER_SECOND
		"multishot":
			return "%d many" % MULTISHOT_MANA
		"fireball":
			return "%d many (+%d przy ładowaniu)" % [FIREBALL_MANA, FIREBALL_CHARGE_MANA]
		"lunge":
			return "%d many" % LUNGE_MANA
		"crescent":
			return "%d many" % CRESCENT_MANA
		"seeker":
			return "%d many" % SEEKER_MANA
		"rapid_volley":
			return "%d many" % VOLLEY_MANA
		"chain_lightning":
			return "%d many" % CHAIN_MANA
		"thunder_wave":
			return "%d many" % WAVE_MANA
		"flicker":
			return "%d many za skok" % FLICKER_MANA
		"smoke_burst":
			return "%d many" % SMOKE_MANA
	return ""


## Opis działania na danym poziomie (np. do okna umiejętności).
static func effect_text(id: String, level: int) -> String:
	if level <= 0:
		return "-"
	match id:
		"whirlwind":
			return "%d%% obrażeń co %s s, zasięg %d" % [roundi(whirlwind_damage(level) * 100), _decimal(WHIRLWIND_TICK, 2), whirlwind_radius(level)]
		"multishot":
			return "3 strzały po %d%% obrażeń" % roundi(multishot_damage(level) * 100)
		"fireball":
			return "Wybuch: %d%% obrażeń, promień %d (naładowana: %d%%, %d)" % [roundi(fireball_damage(level) * 100),
					fireball_radius(level), roundi(fireball_damage(level) * FIREBALL_FULL_DAMAGE * 100),
					roundi(fireball_radius(level) * FIREBALL_FULL_RADIUS)]
		"lunge":
			return "%d%% obrażeń, prędkość %d" % [roundi(lunge_damage(level) * 100), lunge_speed(level)]
		"crescent":
			return "Cięcie %d° o zasięgu %d, %d%% obrażeń" % [CRESCENT_ARC_DEGREES, crescent_radius(level), CRESCENT_DAMAGE * 100]
		"seeker":
			return "%d trafień po %d%% obrażeń" % [seeker_hits(level), roundi(SEEKER_DAMAGE * 100)]
		"rapid_volley":
			return "%d strzał po %d%% obrażeń" % [volley_arrows(level), roundi(VOLLEY_DAMAGE * 100)]
		"chain_lightning":
			return "%d celów, %d%% obrażeń (każdy przeskok słabszy)" % [chain_targets(level), roundi(CHAIN_DAMAGE * 100)]
		"thunder_wave":
			return "Stożek %d°, zasięg %d, %d%% obrażeń" % [wave_half_angle(level) * 2, wave_radius(level), roundi(WAVE_DAMAGE * 100)]
		"flicker":
			return "Skok i cięcie: %d%% obrażeń; wirujące Mgnienie: %d skoków (odnowienie %s s)" % [roundi(flicker_damage(level) * 100),
					whirl_flicker_jumps(level), _decimal(WHIRL_FLICKER_COOLDOWN, 0)]
		"smoke_burst":
			return "Wybuchy: %d%% / %d%% / %d%% obrażeń (rzędy 1-3), pełne ładowanie %s s" % [roundi(smoke_damage(level, 0) * 100),
					roundi(smoke_damage(level, 1) * 100), roundi(smoke_damage(level, 2) * 100), _decimal(SMOKE_CHARGE_TIME * 3, 1)]
	match DATA[id]["type"]:
		"health_regen":
			return "+%s zdrowia/s i %s%% maks. zdrowia/s" % [_decimal(0.4 * level, 1), _decimal(0.3 * level, 1)]
		"mana_regen":
			return "+%s many/s i %s%% maks. many/s" % [_decimal(0.5 * level, 1), _decimal(0.4 * level, 1)]
	return ""


## Liczba z polskim przecinkiem dziesiętnym, np. 0,25.
static func _decimal(value: float, decimals: int) -> String:
	return String.num(value, decimals).replace(".", ",") if decimals > 0 else str(roundi(value))
