class_name Skills
## Baza umiejętności. Każdy rodzaj broni (melee / bow / spell) ma swoje drzewko:
## aktywną umiejętność (domyślnie pod PPM), uderzenie (type "strike", domyślnie pod Q), dodatkowy cios
## - atak zaraz po uderzeniu (type "combo", wymaga uderzenia) - i dwie pasywne regeneracje.
## Aktywną umiejętność i uderzenie gracz kładzie na dowolny slot paska (Hotbar).
## Wszystkie działają tylko z założoną bronią swojego rodzaju.
## Umiejętności odblokowuje się i ulepsza za złoto (koszty rosną z poziomem). Broń, która ma drzewko (SkillTree,
## miecz i łuk), odblokowuje je węzłem za punkt umiejętności, a złoto kupuje kolejne poziomy.
## Umiejętności drzewka (type "skill") mają własną obsługę (SwordSkills - miecz, BowSkills - łuk) i własne combo (COMBOS).
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
	"rend": {
		"name": "Rozpłatanie", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/rend.png"),
		"description": "Szerokie cięcie przed tobą - trafieni krwawią przez 3 s. Combo: zaraz po Mgnieniu krwawienie jest podwójne.",
	},
	"ground_slam": {
		"name": "Rozłupanie Ziemi", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/ground_slam.png"),
		"description": "Uderzasz mieczem w ziemię - fala pęknięć biegnie przed tobą, raniąc i ogłuszając. Combo: zaraz po Półksiężycu fala rozchodzi się we wszystkie strony.",
	},
	"riposte": {
		"name": "Riposta", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/riposte.png"),
		"description": "Na chwilę unosisz ostrze w zasłonie. Gdy ktoś cię wtedy uderzy, nie zrani cię, a ty kontratakujesz wszystkich wokół. Combo: Szarża zaraz po udanej Ripoście nic nie kosztuje i nie ma odnowienia.",
	},
	"war_cry": {
		"name": "Zew Peruna", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/war_cry.png"),
		"description": "Okrzyk bojowy: na kilka sekund zadajesz więcej obrażeń, a wrogowie wokół uciekają w strachu. Zaraz potem 3 kolejne ciosy są krytyczne.",
	},
	"spectral_blades": {
		"name": "Widmowe Ostrza", "weapon": "melee", "type": "skill",
		"icon": preload("res://assets/skills/spectral_blades.png"),
		"description": "Czar: wokół ciebie krążą widmowe miecze, raniąc wrogów, których dotkną. Combo: zaraz po Młynku ostrza od razu wylatują we wrogów.",
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
	"power_shot": {
		"name": "Grot Swaroga", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/power_shot.png"),
		"description": "Przytrzymaj klawisz, by napiąć łuk - puść, a płonąca strzała przebija wszystkich na drodze. Im dłużej napinasz, tym mocniej. Combo: zaraz po Strzale tropiącej grot wybucha ogniem przy każdym trafieniu.",
	},
	"arrow_rain": {
		"name": "Deszcz Strzał", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/arrow_rain.png"),
		"description": "Strzały spadają z nieba na miejsce pod kursorem przez 2 s, raniąc wszystkich w kręgu. Combo: zaraz po Salwie pada dwa razy gęściej.",
	},
	"vault": {
		"name": "Odskok", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/vault.png"),
		"description": "Odskakujesz do tyłu i w locie wypuszczasz trzy strzały w stronę kursora. Combo: następna Salwa po Odskoku nic nie kosztuje i ma 5 strzał.",
	},
	"snare": {
		"name": "Sidła", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/snare.png"),
		"description": "Zastawiasz sidła pod kursorem. Wróg, który na nie wejdzie, zostaje unieruchomiony razem z tymi obok, a każde trafienie unieruchomionego wroga jest krytyczne.",
	},
	"falcon": {
		"name": "Sokół", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/falcon.png"),
		"description": "Przywołujesz sokoła, który krąży nad tobą i spada szponami na pobliskich wrogów. Combo: zaraz po Strzale tropiącej od razu nurkuje z potrójną siłą.",
	},
	"venom_arrows": {
		"name": "Jadowe Groty", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/venom_arrows.png"),
		"description": "Na kilka sekund twoje strzały zatruwają wrogów. Combo: zaraz po Sidłach jad przeskakuje z trafionego na wrogów obok.",
	},
	"wind_arrow": {
		"name": "Strzała Wichru", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/wind_arrow.png"),
		"description": "Podmuch wichru w stożku przed tobą rani i odrzuca wrogów. Atak i czar. Combo: zaraz po Odskoku stożek jest dwa razy szerszy.",
	},
	"ballista": {
		"name": "Balista", "weapon": "bow", "type": "skill",
		"icon": preload("res://assets/skills/ballista.png"),
		"description": "Stawiasz pod kursorem balistę, która sama strzela w najbliższych wrogów. Naraz stoi tylko jedna.",
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
## Rozpłatanie: mana, zasięg i szerokość cięcia, ile ran krwawienia (co pół sekundy).
const REND_MANA := 8.0
const REND_REACH := 38.0
const REND_ARC_DEGREES := 140.0
const BLEED_TICKS := 6
## Rozłupanie Ziemi: mana, odnowienie, długość fali, promień pęknięć wzdłuż fali i fali dookoła (combo).
const SLAM_MANA := 16.0
const SLAM_COOLDOWN := 4.0
const SLAM_LENGTH := 120.0
const SLAM_WIDTH := 22.0
const SLAM_RING := 95.0
## Riposta: mana, czas zasłony, odnowienie, zasięg kontry.
const RIPOSTE_MANA := 6.0
const RIPOSTE_TIME := 0.7
const RIPOSTE_COOLDOWN := 5.0
const RIPOSTE_RADIUS := 60.0
## Zew Peruna: mana, odnowienie, czas premii, zasięg i czas strachu, ile ciosów krytycznych po okrzyku.
const CRY_MANA := 15.0
const CRY_COOLDOWN := 14.0
const CRY_TIME := 6.0
const CRY_RADIUS := 110.0
const CRY_FEAR := 1.6
const CRY_CRITS := 3
## Widmowe Ostrza: mana, odnowienie, liczba ostrzy, czas krążenia, promień orbity, mnożnik obrażeń wylotu.
const BLADES_MANA := 18.0
const BLADES_COOLDOWN := 8.0
const BLADES_COUNT := 3
const BLADES_TIME := 8.0
const BLADES_ORBIT := 30.0
const BLADES_LAUNCH := 2.5
## Grot Swaroga: mana, odnowienie, czas pełnego napięcia, mnożnik obrażeń pełnego napięcia, promień wybuchu (combo).
const POWER_MANA := 12.0
const POWER_COOLDOWN := 1.2
const POWER_CHARGE_TIME := 1.0
const POWER_FULL_DAMAGE := 2.5
const POWER_EXPLOSION := 40.0
## Deszcz Strzał: mana, odnowienie, czas trwania, promień kręgu, odstęp między falami strzał (combo - o połowę).
const RAIN_MANA := 20.0
const RAIN_COOLDOWN := 6.0
const RAIN_TIME := 2.0
const RAIN_RADIUS := 56.0
const RAIN_TICK := 0.25
const RAIN_RANGE := 260.0
## Odskok: mana, odnowienie, czas lotu, strzały w locie i ich rozrzut; Salwa po Odskoku ma tyle strzał.
const VAULT_MANA := 8.0
const VAULT_COOLDOWN := 4.0
const VAULT_TIME := 0.3
const VAULT_ARROWS := 3
const VAULT_SPREAD_DEGREES := 20.0
const VAULT_VOLLEY_ARROWS := 5
## Sidła: mana, odnowienie, ile stoją, promień zatrzaśnięcia i unieruchomienia, zasięg rzutu, ile sideł naraz.
const SNARE_MANA := 10.0
const SNARE_COOLDOWN := 4.0
const SNARE_LIFETIME := 20.0
const SNARE_TRIGGER := 14.0
const SNARE_RADIUS := 36.0
const SNARE_RANGE := 160.0
const SNARE_MAX := 3
## Sokół: mana, odnowienie, czas, odstęp między atakami, zasięg szukania wroga.
const FALCON_MANA := 16.0
const FALCON_COOLDOWN := 10.0
const FALCON_TIME := 12.0
const FALCON_INTERVAL := 0.9
const FALCON_RANGE := 220.0
## Jadowe Groty: mana, odnowienie, czas, zasięg przeskoku jadu (combo).
const VENOM_MANA := 14.0
const VENOM_COOLDOWN := 12.0
const VENOM_TIME := 8.0
const VENOM_SPREAD := 55.0
## Strzała Wichru: mana, odnowienie, zasięg, połowa kąta stożka (combo - dwa razy szerszy), odrzut.
const WIND_MANA := 10.0
const WIND_COOLDOWN := 3.0
const WIND_RANGE := 110.0
const WIND_HALF_ANGLE := 30.0
const WIND_KNOCKBACK := 260.0
## Balista: mana, odnowienie, czas, odstęp strzałów, zasięg, zasięg postawienia.
const BALLISTA_MANA := 25.0
const BALLISTA_COOLDOWN := 12.0
const BALLISTA_TIME := 15.0
const BALLISTA_INTERVAL := 1.1
const BALLISTA_RANGE := 260.0
const BALLISTA_PLACE := 120.0
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
	"rend": ["attack"], "ground_slam": ["attack"], "riposte": ["attack"], "war_cry": ["cry"], "spectral_blades": ["spell"],
	"seeker": ["attack"], "rapid_volley": ["attack"], "multishot": ["attack"], "power_shot": ["attack"], "arrow_rain": ["attack"],
	"vault": ["attack"], "snare": ["attack"], "falcon": ["attack"], "venom_arrows": ["attack"], "wind_arrow": ["attack", "spell"],
	"ballista": ["attack"],
	"chain_lightning": ["spell"], "thunder_wave": ["spell"], "fireball": ["spell"],
}


static func tags(id: String) -> Array:
	return TAGS.get(id, [])


static func tags_text(id: String) -> String:
	var names: Array[String] = []
	for tag: String in tags(id):
		names.append({"attack": "atak", "spell": "czar", "cry": "okrzyk"}[tag])
	return " i ".join(names).capitalize() if not names.is_empty() else ""


## Combo umiejętności drzewka: po jakich umiejętnościach (użytych w oknie COMBO_WINDOW) zachowują się inaczej;
## "any" - po każdej innej. Mgnienie w trakcie Młynka obsługuje SwordSkills osobno (wirujące Mgnienie).
## Łuk (BowSkills): Salwa po Odskoku jest darmowa i ma więcej strzał.
const COMBOS := {"smoke_burst": ["any"], "flicker": ["whirlwind"], "rend": ["flicker"], "ground_slam": ["crescent"],
		"lunge": ["riposte"], "spectral_blades": ["whirlwind"],
		"power_shot": ["seeker"], "arrow_rain": ["multishot"], "multishot": ["vault"], "falcon": ["seeker"],
		"venom_arrows": ["snare"], "wind_arrow": ["vault"]}


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


static func rend_damage(level: int) -> float:
	return 0.9 + 0.1 * level


## Rozpłatanie: łączne obrażenia krwawienia (procent obrażeń broni przez 3 s).
static func rend_bleed(level: int) -> float:
	return 1.0 + 0.2 * level


static func slam_damage(level: int) -> float:
	return 1.2 + 0.15 * level


static func slam_stun(level: int) -> float:
	return 0.8 + 0.1 * level


static func riposte_damage(level: int) -> float:
	return 2.0 + 0.3 * level


## Zew Peruna: premia do zadawanych obrażeń.
static func cry_bonus(level: int) -> float:
	return 0.1 + 0.03 * level


## Widmowe Ostrza: procent obrażeń broni za dotknięcie wroga.
static func blades_damage(level: int) -> float:
	return 0.5 + 0.08 * level


## Dymne Wybuchy: procent obrażeń broni wybuchu w rzędzie `ring` (0-2).
static func smoke_damage(level: int, ring: int) -> float:
	return (0.7 + 0.1 * level) * (1.0 + 0.2 * ring)


## Grot Swaroga: procent obrażeń broni (bez napięcia; pełne - razy POWER_FULL_DAMAGE) i ilu wrogów przebija.
static func power_damage(level: int) -> float:
	return 1.3 + 0.2 * level


static func power_pierce(level: int) -> int:
	return 3 + level


## Deszcz Strzał: procent obrażeń broni na falę strzał (co RAIN_TICK s).
static func rain_damage(level: int) -> float:
	return 0.35 + 0.06 * level


static func vault_damage(level: int) -> float:
	return 0.8 + 0.1 * level


## Sidła: procent obrażeń broni przy zatrzaśnięciu i czas unieruchomienia (s).
static func snare_damage(level: int) -> float:
	return 1.0 + 0.15 * level


static func snare_time(level: int) -> float:
	return 2.0 + 0.3 * level


## Sokół: procent obrażeń broni za atak szponami.
static func falcon_damage(level: int) -> float:
	return 0.7 + 0.12 * level


## Jadowe Groty: obrażenia trucizny (procent trafienia, rozłożony na 3 s).
static func venom_damage(level: int) -> float:
	return 0.4 + 0.08 * level


static func wind_damage(level: int) -> float:
	return 1.1 + 0.15 * level


## Balista: procent obrażeń broni na bełt.
static func ballista_damage(level: int) -> float:
	return 0.7 + 0.12 * level


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
			"flicker": FLICKER_MANA, "smoke_burst": SMOKE_MANA, "rend": REND_MANA, "ground_slam": SLAM_MANA,
			"riposte": RIPOSTE_MANA, "war_cry": CRY_MANA, "spectral_blades": BLADES_MANA,
			"lunge": LUNGE_MANA, "crescent": CRESCENT_MANA, "seeker": SEEKER_MANA, "rapid_volley": VOLLEY_MANA,
			"chain_lightning": CHAIN_MANA, "thunder_wave": WAVE_MANA, "power_shot": POWER_MANA, "arrow_rain": RAIN_MANA,
			"vault": VAULT_MANA, "snare": SNARE_MANA, "falcon": FALCON_MANA, "venom_arrows": VENOM_MANA, "wind_arrow": WIND_MANA,
			"ballista": BALLISTA_MANA}.get(id, 0.0)


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
		"rend":
			return "%d many" % REND_MANA
		"ground_slam":
			return "%d many" % SLAM_MANA
		"riposte":
			return "%d many" % RIPOSTE_MANA
		"war_cry":
			return "%d many" % CRY_MANA
		"spectral_blades":
			return "%d many" % BLADES_MANA
	if mana_cost(id) > 0.0:
		return "%d many" % mana_cost(id)
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
		"rend":
			return "Cięcie %d%% obrażeń, krwawienie %d%% przez 3 s" % [roundi(rend_damage(level) * 100), roundi(rend_bleed(level) * 100)]
		"ground_slam":
			return "Fala %d%% obrażeń, ogłuszenie %s s, odnowienie %s s" % [roundi(slam_damage(level) * 100),
					_decimal(slam_stun(level), 1), _decimal(SLAM_COOLDOWN, 0)]
		"riposte":
			return "Zasłona %s s, kontra %d%% obrażeń, odnowienie %s s" % [_decimal(RIPOSTE_TIME, 1),
					roundi(riposte_damage(level) * 100), _decimal(RIPOSTE_COOLDOWN, 0)]
		"war_cry":
			return "+%d%% obrażeń przez %s s, strach %s s, odnowienie %s s" % [roundi(cry_bonus(level) * 100),
					_decimal(CRY_TIME, 0), _decimal(CRY_FEAR, 1), _decimal(CRY_COOLDOWN, 0)]
		"spectral_blades":
			return "%d ostrza po %d%% obrażeń przez %s s (wylot: %d%%)" % [BLADES_COUNT, roundi(blades_damage(level) * 100),
					_decimal(BLADES_TIME, 0), roundi(blades_damage(level) * BLADES_LAUNCH * 100)]
		"smoke_burst":
			return "Wybuchy: %d%% / %d%% / %d%% obrażeń (rzędy 1-3), pełne ładowanie %s s" % [roundi(smoke_damage(level, 0) * 100),
					roundi(smoke_damage(level, 1) * 100), roundi(smoke_damage(level, 2) * 100), _decimal(SMOKE_CHARGE_TIME * 3, 1)]
		"power_shot":
			return "%d%% obrażeń (napięta: %d%%), przebija %d wrogów" % [roundi(power_damage(level) * 100),
					roundi(power_damage(level) * POWER_FULL_DAMAGE * 100), power_pierce(level)]
		"arrow_rain":
			return "%d%% obrażeń co %s s przez %s s, krąg %d" % [roundi(rain_damage(level) * 100), _decimal(RAIN_TICK, 2),
					_decimal(RAIN_TIME, 0), RAIN_RADIUS]
		"vault":
			return "%d strzały po %d%% obrażeń, odnowienie %s s" % [VAULT_ARROWS, roundi(vault_damage(level) * 100), _decimal(VAULT_COOLDOWN, 0)]
		"snare":
			return "%d%% obrażeń, unieruchomienie %s s, do %d sideł naraz" % [roundi(snare_damage(level) * 100),
					_decimal(snare_time(level), 1), SNARE_MAX]
		"falcon":
			return "%d%% obrażeń co %s s przez %s s" % [roundi(falcon_damage(level) * 100), _decimal(FALCON_INTERVAL, 1), _decimal(FALCON_TIME, 0)]
		"venom_arrows":
			return "Trucizna: %d%% obrażeń strzały przez 3 s, działa %s s" % [roundi(venom_damage(level) * 100), _decimal(VENOM_TIME, 0)]
		"wind_arrow":
			return "Stożek %d°, zasięg %d, %d%% obrażeń" % [WIND_HALF_ANGLE * 2, WIND_RANGE, roundi(wind_damage(level) * 100)]
		"ballista":
			return "%d%% obrażeń co %s s przez %s s" % [roundi(ballista_damage(level) * 100), _decimal(BALLISTA_INTERVAL, 1),
					_decimal(BALLISTA_TIME, 0)]
	match DATA[id]["type"]:
		"health_regen":
			return "+%s zdrowia/s i %s%% maks. zdrowia/s" % [_decimal(0.4 * level, 1), _decimal(0.3 * level, 1)]
		"mana_regen":
			return "+%s many/s i %s%% maks. many/s" % [_decimal(0.5 * level, 1), _decimal(0.4 * level, 1)]
	return ""


## Liczba z polskim przecinkiem dziesiętnym, np. 0,25.
static func _decimal(value: float, decimals: int) -> String:
	return String.num(value, decimals).replace(".", ",") if decimals > 0 else str(roundi(value))
