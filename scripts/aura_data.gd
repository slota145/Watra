class_name AuraData
## Dane aur rezerwujących manę (Auras - działanie w grze): rezerwacja, kolory, siła na poziomach i opisy.
## Osobny plik bez odwołań do dźwięków i efektów, żeby Skills i SkillBook mogły z niego korzystać także w testach
## bez okna (skrypty ładowane przed autoloadami).

## Ile pełnej many rezerwuje aura (0 - nic: Mroźny Oddech zamiast many rani gracza).
const RESERVE := {
	"dread": 0.30, "vigor": 0.30, "strzybog_wind": 0.30, "life_spring": 0.20, "mana_spring": 0.15,
	"swarog_ember": 0.25, "marzanna_frost": 0.25, "perun_sparks": 0.25, "perun_wrath": 0.35, "frost_breath": 0.0,
}
## Kolory kręgów pod postacią i ikon (tools/aura_icons.py).
const COLORS := {
	"dread": Color8(170, 70, 200), "vigor": Color8(220, 70, 60), "strzybog_wind": Color8(120, 230, 200),
	"life_spring": Color8(240, 110, 120), "mana_spring": Color8(90, 150, 255), "swarog_ember": Color8(255, 140, 50),
	"marzanna_frost": Color8(150, 220, 255), "perun_sparks": Color8(255, 225, 80), "perun_wrath": Color8(230, 230, 120),
	"frost_breath": Color8(110, 200, 255),
}
## Żywioły aur żywiołów: premia do dodanych obrażeń (CharacterStats SUPPORT_ELEMENTS) i stan.
const ELEMENTS := {"swarog_ember": "fire", "marzanna_frost": "ice", "perun_sparks": "lightning"}
const AILMENTS := {"fire": "ignite", "ice": "freeze", "lightning": "shock"}
## Krwawa Ofiara: aury nie mogą zarezerwować więcej zdrowia niż tyle.
const MAX_HEALTH_RESERVE := 0.9
## Postrach: promień.
const DREAD_RADIUS := 150.0
## Gniew Peruna: odstęp piorunów, zasięg szukania wroga.
const WRATH_INTERVAL := 3.0
const WRATH_RANGE := 220.0
## Mroźny Oddech: odstęp ran, promień wiru, ile maksymalnego zdrowia na sekundę traci gracz (mniej z odpornością
## na lód; nie zabija - zostawia 1 punkt zdrowia).
const BREATH_TICK := 0.5
const BREATH_RADIUS := 70.0
const BREATH_SELF := 0.04


static func is_aura(id: String) -> bool:
	return RESERVE.has(id)


## Siła aury na danym poziomie: (premie do statystyk - SkillBook.aura_bonus).
static func stats_of(id: String, level: int) -> Dictionary:
	var p := Skills.power(maxi(level, 1))
	match id:
		"vigor":
			return {"health_percent": 0.11 + 0.01 * p}
		"strzybog_wind":
			var speed := 0.075 + 0.005 * p
			return {"move_speed": speed, "attack_speed": speed, "cast_speed": speed}
		"life_spring":
			return {"health_regen_percent": 0.008 + 0.002 * p}
		"mana_spring":
			return {"mana_regen_percent": 0.01 + 0.0025 * p}
		"swarog_ember", "marzanna_frost", "perun_sparks":
			var element: String = ELEMENTS[id]
			return {"aura_added_" + element: 0.1 + 0.02 * p, AILMENTS[element] + "_chance": 0.05 + 0.01 * p}
		"frost_breath":
			return {"cold_damage": 0.2 + 0.02 * p}
	return {}


## Postrach: o ile mniej obrażeń zadają wrogowie w kręgu i o ile wolniej atakują.
static func dread_damage(level: int) -> float:
	return minf(0.09 + 0.01 * Skills.power(maxi(level, 1)), 0.3)


static func dread_slow(level: int) -> float:
	return minf(0.08 + 0.006 * Skills.power(maxi(level, 1)), 0.25)


## Gniew Peruna: procent obrażeń broni za piorun.
static func wrath_damage(level: int) -> float:
	return 1.2 + 0.2 * Skills.power(maxi(level, 1))


## Mroźny Oddech: procent obrażeń broni za każdą ranę wiru (co BREATH_TICK s).
static func breath_damage(level: int) -> float:
	return 0.3 + 0.06 * Skills.power(maxi(level, 1))


## Opis działania na danym poziomie (okno umiejętności - Skills.effect_text).
static func effect_text(id: String, level: int) -> String:
	var bonus := stats_of(id, level)
	match id:
		"dread":
			return Lang.t("Wrogowie w promieniu %d: -%d%% obrażeń, ataki %d%% wolniej") % [DREAD_RADIUS,
					roundi(dread_damage(level) * 100), roundi(dread_slow(level) * 100)]
		"vigor":
			return Lang.t("+%d%% maksymalnego zdrowia") % roundi(bonus["health_percent"] * 100)
		"strzybog_wind":
			return Lang.t("+%s%% szybkości ruchu, ataku i rzucania") % Skills.decimal(bonus["move_speed"] * 100, 1)
		"life_spring":
			return Lang.t("Odnawia %s%% maksymalnego zdrowia na sekundę") % Skills.decimal(bonus["health_regen_percent"] * 100, 1)
		"mana_spring":
			return Lang.t("Odnawia %s%% maksymalnej many na sekundę") % Skills.decimal(bonus["mana_regen_percent"] * 100, 2)
		"swarog_ember":
			return Lang.t("+%d%% obrażeń dodane jako ogień, +%d%% szansy na podpalenie") % [roundi(bonus["aura_added_fire"] * 100),
					roundi(bonus["ignite_chance"] * 100)]
		"marzanna_frost":
			return Lang.t("+%d%% obrażeń dodane jako lód, +%d%% szansy na zamrożenie") % [roundi(bonus["aura_added_ice"] * 100),
					roundi(bonus["freeze_chance"] * 100)]
		"perun_sparks":
			return Lang.t("+%d%% obrażeń dodane jako piorun, +%d%% szansy na porażenie") % [roundi(bonus["aura_added_lightning"] * 100),
					roundi(bonus["shock_chance"] * 100)]
		"perun_wrath":
			return Lang.t("Co %s s piorun: %d%% obrażeń w losowego wroga do %d") % [Skills.decimal(WRATH_INTERVAL, 0),
					roundi(wrath_damage(level) * 100), WRATH_RANGE]
		"frost_breath":
			return Lang.t("Wir %d%% obrażeń co %s s w promieniu %d, +%d%% obrażeń od lodu; tracisz %d%% zdrowia na sekundę") % [
					roundi(breath_damage(level) * 100), Skills.decimal(BREATH_TICK, 1), BREATH_RADIUS,
					roundi(bonus["cold_damage"] * 100), roundi(BREATH_SELF * 100)]
	return ""


## Napis kosztu (pasek, okno drzewka): "rezerwuje 30% many".
static func cost_text(id: String) -> String:
	if RESERVE.get(id, 0.0) <= 0.0:
		return Lang.t("bez rezerwacji - rani ciebie")
	return Lang.t("rezerwuje %d%% many") % roundi(RESERVE[id] * 100)
