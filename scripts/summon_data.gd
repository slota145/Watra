class_name SummonData
## Dane przywołań rezerwujących manę (Summons - działanie w grze): rezerwacja, liczba, siła na poziomach i opisy.
## Jak AuraData - osobny plik bez odwołań do dźwięków i efektów, żeby Skills i SkillBook działały w testach bez okna.
## Przywołańcy są stali (jak aury): klawisz paska ich przywołuje albo odsyła, a póki są, rezerwują część pełnej many.
## Z poziomem umiejętności (Skills.power) rośnie ich siła, zdrowie i liczba (+1 na poziomach COUNT_LEVELS),
## a rezerwacja maleje (RESERVE_PER_LEVEL).
## - Wataha (łuk): widmowe wilki biegną do wrogów przy tobie, gryzą i czasem powalają (ogłuszenie).
## - Błędne Ogniki (księga): ogniki krążą przy tobie i strzelają do wrogów ognistymi pociskami.
## - Wierny tropiciel (węzeł Strzały tropiącej, łuk): widmowa strzała krąży przy tobie i sama strzela strzałami
##   tropiącymi; id przywołania to "seeker" (klawisz Strzały tropiącej z tym węzłem przywołuje ją zamiast strzelać).

## Ile pełnej many rezerwuje przywołanie na 1. poziomie.
const RESERVE := {"wolf_pack": 0.25, "wisps": 0.22, "seeker": 0.15}
## O ile rezerwacja maleje z każdym poziomem ponad 1. (Wierny tropiciel ma stałe 15% - opis węzła).
const RESERVE_PER_LEVEL := {"wolf_pack": 0.004, "wisps": 0.004, "seeker": 0.0}
## Kolory (podświetlenie slotu paska, kręgi, przebarwienie wilków i ogników).
const COLORS := {"wolf_pack": Color8(150, 200, 255), "wisps": Color8(255, 150, 60), "seeker": Color8(170, 255, 200)}
## Ilu przywołańców na 1. poziomie; +1 na każdym z COUNT_LEVELS; węzły Przewodnik stada i Wierne ogniki - COUNT_STAT.
const BASE_COUNT := {"wolf_pack": 2, "wisps": 3, "seeker": 1}
const COUNT_LEVELS: Array[int] = [10, 20]
const COUNT_STAT := {"wolf_pack": "wolf_count", "wisps": "wisp_count"}
## Broń, z którą działa przywołanie (Wierny tropiciel - łuk, jak Strzała tropiąca).
const WEAPON := {"wolf_pack": "bow", "wisps": "spell", "seeker": "bow"}
## Po ilu sekundach wraca zabity przywołaniec.
const RESPAWN := 6.0

## Wilki: odstęp ugryzień, szansa na powalenie (ogłuszenie na WOLF_STUN s), zasięg szukania wrogów (od gracza),
## prędkość, odległość ugryzienia, na jaką odległość od gracza mogą odbiec, zanim wrócą.
const WOLF_BITE_INTERVAL := 0.9
const WOLF_STUN_CHANCE := 0.2
const WOLF_STUN := 0.8
const WOLF_SEEK_RANGE := 170.0
const WOLF_SPEED := 120.0
const WOLF_REACH := 16.0
const WOLF_LEASH := 260.0
## Ogniki: odstęp strzałów, zasięg, prędkość pocisku, promień krążenia wokół gracza.
const WISP_INTERVAL := 1.3
const WISP_RANGE := 210.0
const WISP_SPEED := 210.0
const WISP_ORBIT := 24.0
## Wierny tropiciel: odstęp strzałów i zasięg szukania wroga.
const SEEKER_INTERVAL := 1.6
const SEEKER_RANGE := 230.0
## Ułamek ciosu potwora, jaki dostaje przywołaniec (widmowe ciała są twardsze niż liczba zdrowia sugeruje).
const TAKEN := 0.6


static func is_summon(id: String) -> bool:
	return RESERVE.has(id)


## Rezerwacja na danym poziomie (bez węzłów zmniejszających rezerwację - SkillBook.aura_reserve).
static func reserve(id: String, level: int) -> float:
	return maxf(float(RESERVE.get(id, 0.0)) - float(RESERVE_PER_LEVEL.get(id, 0.0)) * (maxi(level, 1) - 1), 0.05)


## Ilu przywołańców na danym poziomie (`extra` - z węzłów drzewka).
static func count(id: String, level: int, extra := 0) -> int:
	var total: int = BASE_COUNT.get(id, 1)
	if id != "seeker":
		for at in COUNT_LEVELS:
			if level >= at:
				total += 1
	return total + extra


## Procent obrażeń broni za ugryzienie wilka / pocisk ognika (Wierny tropiciel strzela zwykłą Strzałą tropiącą).
static func damage(id: String, level: int) -> float:
	var p := Skills.power(maxi(level, 1))
	match id:
		"wolf_pack":
			return 0.55 + 0.1 * p
		"wisps":
			return 0.35 + 0.06 * p
	return 1.0


## Zdrowie przywołańca jako ułamek maksymalnego zdrowia postaci.
static func health_share(id: String, level: int) -> float:
	var p := Skills.power(maxi(level, 1))
	match id:
		"wolf_pack":
			return 0.4 + 0.03 * p
		"wisps":
			return 0.25 + 0.02 * p
	return 0.0


## Opis działania na danym poziomie (okno umiejętności - Skills.effect_text).
static func effect_text(id: String, level: int, extra := 0) -> String:
	var number := count(id, level, extra)
	match id:
		"wolf_pack":
			return Lang.n(number, "%d wilk: %d%% obrażeń za ugryzienie, zdrowie %d%% twojego", "%d wilki: %d%% obrażeń za ugryzienie, zdrowie %d%% twojego",
					"%d wilków: %d%% obrażeń za ugryzienie, zdrowie %d%% twojego") % [number, roundi(damage(id, level) * 100),
					roundi(health_share(id, level) * 100)]
		"wisps":
			return Lang.n(number, "%d ognik: %d%% obrażeń za pocisk, zdrowie %d%% twojego", "%d ogniki: %d%% obrażeń za pocisk, zdrowie %d%% twojego",
					"%d ogników: %d%% obrażeń za pocisk, zdrowie %d%% twojego") % [number, roundi(damage(id, level) * 100),
					roundi(health_share(id, level) * 100)]
		"seeker":
			return Lang.t("Widmowa strzała co %s s wypuszcza Strzałę tropiącą") % Skills.decimal(SEEKER_INTERVAL, 1)
	return ""


## Napis kosztu (pasek, okno drzewka): "rezerwuje 25% many".
static func cost_text(id: String, level: int) -> String:
	return Lang.t("rezerwuje %d%% many") % roundi(reserve(id, level) * 100)
