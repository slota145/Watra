"""Wspólne drzewko umiejętności (docs/plan_drzewek.md, krok 1 - szkic, krok 2 - w grze): jedyne źródło danych drzewka.

Węzły są zebrane w skupiska (CLUSTERS: region, środek we współrzędnych biegunowych, lista węzłów), skupiska łączą
ścieżki małych węzłów (PATHS). Skrypt rozmieszcza węzły, liczy je i zapisuje:
- docs/drzewko_wspolne.png - rysunek układu,
- docs/drzewko_wspolne_wezly.md - pełna lista węzłów (opis układu i decyzje są w docs/drzewko_wspolne.md).
- scripts/skill_tree_data.gd - dane dla gry (SkillTreeData: węzły z premiami, skupiska, strony), czyta je SkillTree.
Węzły z "soon" (nowe umiejętności, aury, nowe węzły kluczowe i znaczące bez premii w grze) są w grze pustymi
miejscami: widać je, ale nie da się ich wybrać, a drzewko można przez nie przejść (SkillBook).

Uruchom: python tools/shared_tree_draft.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT_PNG = ROOT / "docs" / "drzewko_wspolne.png"
OUT_MD = ROOT / "docs" / "drzewko_wspolne_wezly.md"
OUT_GD = ROOT / "scripts" / "skill_tree_data.gd"

# Rodzaje węzłów: start, skill (umiejętność aktywna), aura (umiejętność-aura), key (węzeł kluczowy),
# notable (węzeł znaczący), small (drobny), socket (gniazdo), legend (gniazdo legendarne).
# Broń umiejętności: melee, bow, spell, "melee/bow" itd. (mieszana - działa z jedną z dwóch), any (każda broń).
# Pole "new": nowa umiejętność / węzeł (nie ma jej dziś w grze).

REGIONS = {
	"str": {"name": "Siła (miecz)", "angle": 210, "color": (200, 70, 60)},
	"dex": {"name": "Zręczność (łuk)", "angle": 330, "color": (70, 170, 80)},
	"int": {"name": "Inteligencja (księga)", "angle": 90, "color": (70, 110, 210)},
	"sz": {"name": "Strefa siła / zręczność", "angle": 270, "color": (185, 140, 50)},
	"zi": {"name": "Strefa zręczność / inteligencja", "angle": 30, "color": (60, 160, 170)},
	"si": {"name": "Strefa siła / inteligencja", "angle": 150, "color": (150, 80, 170)},
}


def S(id, name, weapon, desc, new=False, tags=""):
	"""Umiejętność. Obecna: id to klucz w Skills.DATA. Nowa (new=True): puste miejsce na później (soon)."""
	return {"id": id, "kind": "skill", "name": name, "weapon": weapon, "desc": desc, "new": new, "tags": tags, "soon": new}


def A(id, name, desc, new=True):
	"""Aura - na razie puste miejsce (krok 3: aury i rezerwacja many)."""
	return {"id": id, "kind": "aura", "name": name, "weapon": "any", "desc": desc, "new": new, "tags": "aura", "soon": True}


def K(id, name, desc, new=False, game=None, stats=None):
	"""Węzeł kluczowy. `game` - opis w grze (gdy inny niż skrót w `desc`); nowe (new=True) - puste miejsce."""
	return {"id": id, "kind": "key", "name": name, "desc": desc, "new": new, "soon": new, "game": game or desc,
			"stats": stats or {}}


def N(id, name, desc, stats=None, new=False):
	"""Węzeł znaczący. Bez `stats` (premia, której gra jeszcze nie zna) - puste miejsce na później."""
	return {"id": id, "kind": "notable", "name": name, "desc": desc, "new": new, "soon": stats is None, "stats": stats or {}}


def P(desc):
	return {"kind": "small", "name": "", "desc": desc, "stats": SMALL_STATS[desc]}


def G():
	return {"kind": "socket", "name": "Gniazdo", "desc": "kamień szlachetny (działa o połowę mocniej)"}


def L():
	return {"kind": "legend", "name": "Gniazdo legendarne", "desc": "kamień szlachetny albo esencja legendy"}


# Premie drobnych węzłów (P w skupiskach i ścieżki - THEMES): opis -> statystyki jak w grze.
SMALL_STATS = {
	"+8 siły": {"strength": 8}, "+8 zręczności": {"dexterity": 8}, "+8 inteligencji": {"intelligence": 8},
	"+4% zdrowia": {"health_percent": 0.04}, "+4% many": {"mana_percent": 0.04}, "+5% many": {"mana_percent": 0.05},
	"+3% szybkości ataku": {"attack_speed": 0.03}, "+6% obrażeń fizycznych": {"physical_damage": 0.06},
	"+4 siły, +4 zręczności": {"strength": 4, "dexterity": 4},
	"+4 zręczności, +4 inteligencji": {"dexterity": 4, "intelligence": 4},
	"+4 siły, +4 inteligencji": {"strength": 4, "intelligence": 4},
	"+4% obrażeń ciosów": {"hit_damage": 0.04}, "+4% obrażeń pocisków": {"projectile_damage": 0.04},
	"+4% obrażeń od ognia": {"fire_damage": 0.04}, "+6% odporności na żywioły": {"all_resistances": 0.06},
}


# Skupisko: id, region, nazwa, (kąt w stopniach, odległość od startu), węzły. Pierwszy węzeł to wejście (od strony
# startu), dalej węzły idą na zmianę po dwóch łukach pierścienia; węzeł kluczowy zamyka pierścień po przeciwnej
# stronie, a "tail" (np. gniazdo legendarne) wystaje za nim na zewnątrz.
# Identyfikatory węzłów trafiają do zapisów gry - nie zmieniaj ich (umiejętności mają id z Skills.DATA,
# węzły kluczowe - id z dawnych drzewek broni).
CLUSTERS = [
	# ======================= SIŁA (miecz)
	("s_gate", "str", "Brama Siły", (210, 3.2), [
		S("whirlwind", "Młynek", "melee", "zwykła umiejętność miecza (PPM)", tags="atak, obszar, fizyczne"),
	]),
	("s_wir", "str", "Wir", (204, 12.5), [
		S("flicker", "Mgnienie", "melee", "skoki od wroga do wroga; combo po Młynku"),
		N("whirl_reach", "Szeroki zamach", "+20% zasięgu Młynka", {"whirl_radius": 0.2}),
		N("whirl_dmg", "Wirujące ostrze", "+20% obrażeń Młynka", {"whirl_damage": 0.2}),
		P("+6% obrażeń fizycznych"),
		N("flicker_dmg", "Cięcie z cienia", "+20% obrażeń Mgnienia, -25% many za skok",
			{"flicker_damage": 0.2, "flicker_mana": -0.25}),
		N("whirl_pull", "Wciągający wir", "Młynek lekko przyciąga wrogów z bliska", new=True),
		K("cyclone_eye", "Oko Cyklonu", "Młynek wciąga wrogów i rozkręca się do +100% obrażeń, zużywa 2x więcej many",
			game="Młynek wciąga wrogów do środka i rozkręca się: każda sekunda kręcenia to +25% jego obrażeń (najwyżej +100%). Młynek zużywa dwa razy więcej many."),
	], [L()]),
	("s_ostrze", "str", "Ostrze i combo", (228, 7.5), [
		S("lunge", "Szarża", "melee", "wypad z cięciem; Półksiężyc po niej"),
		S("crescent", "Półksiężyc", "melee", "szerokie cięcie - teraz zwykła umiejętność, po Szarży mocniejsze (combo)"),
		N("combo_1", "Płynne przejścia", "+0,4 s okna combo", {"combo_window": 0.4}),
		N("lunge_cd", "Szybki wypad", "-25% odnowienia Szarży", {"lunge_cooldown": -0.25}),
		S("ground_slam", "Rozłupanie Ziemi", "melee", "kolce z ziemi; combo po Półksiężycu"),
		N("slam_stun", "Drżąca ziemia", "+50% ogłuszenia Rozłupania Ziemi", {"slam_stun": 0.5}),
		N("combo_2", "Mistrz przejść", "+15% obrażeń ciosów combo", {"combo_damage": 0.15}),
		K("blade_dance", "Taniec Ostrzy", "każde combo daje +5% szybkości ataku na 4 s (do 5 razy)",
			game="Każde combo daje +5% szybkości ataku na 4 s (do 5 razy naraz)."),
	]),
	("s_szermierz", "str", "Szermierz", (232, 12.5), [
		S("riposte", "Riposta", "melee", "zasłona i kontra wszystkich wokół; po niej Szarża za darmo"),
		N("crit_1", "Oko kata", "+4% szansy na cios krytyczny", {"crit_chance": 0.04}),
		N("riposte_power", "Mistrz szermierki", "+50% obrażeń kontry Riposty", {"riposte_damage": 0.5}),
		S("wolf_fang", "Wilczy Kieł", "melee", "seria 4 szybkich pchnięć w jednego wroga (na bossów); ostatnie przebija pancerz", new=True,
			tags="atak, cios, fizyczne"),
		N("crit_2", "Cios w serce", "+30% obrażeń krytycznych", {"crit_damage": 0.3}),
		P("+8 siły"),
	]),
	("s_okrzyki", "str", "Okrzyki", (212, 17.5), [
		S("war_cry", "Zew Peruna", "melee", "okrzyk: strach i pewne krytyki"),
		N("cry_power", "Głos burzy", "+10% premii Zewu Peruna", {"cry_power": 0.1}),
		S("bull_roar", "Ryk Tura", "melee", "okrzyk: wrogowie wokół rzucają się na ciebie, +30% pancerza na 6 s", new=True,
			tags="okrzyk, obszar"),
		N("loud_voice", "Donośny głos", "+40% zasięgu okrzyków, -20% ich odnowienia", new=True),
		A("dread", "Postrach", "aura: wrogowie wokół zadają 10% mniej obrażeń i wolniej atakują"),
		P("+8 siły"),
	]),
	("s_krzepa", "str", "Krzepa (zdrowie)", (193, 7.5), [
		N("hp_1", "Twarda skóra", "+8% zdrowia", {"health_percent": 0.08}),
		N("regen_1", "Szybkie gojenie", "+2 regeneracji zdrowia/s", {"health_regen": 2.0}),
		A("vigor", "Krzepa", "aura: +12% maksymalnego zdrowia"),
		N("hp_2", "Niezłomny", "+60 zdrowia", {"health": 60.0}),
		N("full_strength", "Pełnia Sił", "+1% obrażeń za każde 5% zdrowia ponad połowę (najwyżej +10%)", new=True),
		K("blood_sacrifice", "Krew za Manę", "umiejętności kosztują zdrowie zamiast many (nie mogą zabić), +25% zdrowia - dawna Ofiara Krwi z księgi, teraz z każdą bronią",
			game="Umiejętności kosztują zdrowie zamiast many (nie mogą cię zabić), a maksymalne zdrowie rośnie o 25%. Działa z każdą bronią.",
			stats={"health_percent": 0.25}),
	]),
	("s_bastion", "str", "Bastion", (190, 17.5), [
		N("armor_1", "Kolczuga pod skórą", "+10 pancerza", {"armor": 10.0}),
		N("armor_2", "Pancerna postawa", "+12% pancerza", {"armor_percent": 0.12}),
		N("nawia_res", "Hart ducha", "+15% odporności na Nawię", {"nawia_resistance": 0.15}, new=True),
		N("wounded_wrath", "Gniew rannego", "+1% obrażeń za każde 5% brakującego zdrowia", new=True),
		G(),
		K("last_bastion", "Ostatni Bastion", "poniżej 30% zdrowia +50% obrażeń i +50% redukcji obrażeń", new=True),
	]),
	("s_ziemia", "str", "Ziemia", (233, 17.5), [
		S("bear_leap", "Skok Niedźwiedzia", "melee", "skok na wskazane miejsce, lądowanie rani i odrzuca wrogów wokół", new=True,
			tags="atak, obszar, ruch, fizyczne"),
		N("area_1", "Ciężka ręka", "+12% obrażeń obszarowych", {"area_damage": 0.12}),
		N("tremor", "Wstrząs", "umiejętności obszarowe miecza ogłuszają na 0,3 s", new=True),
		P("+8 siły"),
		G(),
	]),
	("s_dym", "str", "Dym", (182, 12.5), [
		S("smoke_burst", "Dymne Wybuchy", "melee", "ładowane wybuchy dymu (siła i inteligencja)"),
		N("smoke_charge", "Gęsty dym", "+25% szybkości ładowania Dymnych Wybuchów", {"smoke_charge": 0.25}),
		S("spectral_blades", "Widmowe Ostrza", "melee", "krążące ostrza (siła i inteligencja)"),
		N("smoke_dmg", "Duszący dym", "+20% obrażeń Dymnych Wybuchów", {"smoke_damage": 0.2}),
		N("blades_count", "Czwarte ostrze", "+1 Widmowe Ostrze", {"blade_count": 1.0}),
		K("smoke_shadow", "Dym i Cień", "po Dymnych Wybuchach chmura na 5 s: +30% uniku, Mgnienie bez many",
			game="Po Dymnych Wybuchach zostaje chmura dymu na 5 s: w niej masz +30% szansy na unik, a Mgnienie nie zużywa many."),
	]),
	# ======================= ZRĘCZNOŚĆ (łuk)
	("d_gate", "dex", "Brama Zręczności", (330, 3.2), [
		S("multishot", "Salwa", "bow", "zwykła umiejętność łuku (PPM)", tags="atak, pocisk, fizyczne"),
	]),
	("d_grad", "dex", "Grad", (352, 12.5), [
		S("arrow_rain", "Deszcz Strzał", "bow", "deszcz strzał na obszar; combo po Salwie"),
		N("multi_arrows", "Wachlarz", "+1 strzała Salwy, strzały lecą wachlarzem", {"multishot_arrows": 1.0}),
		N("row_shot", "Szereg", "+1 pocisk umiejętności łuku, dodatkowe lecą równolegle obok siebie", new=True),
		N("rain_area", "Gęsty grad", "+25% kręgu Deszczu Strzał", {"rain_area": 0.25}),
		N("volley_dmg", "Ostre groty", "+20% obrażeń Salwy i Deszczu Strzał", {"multishot_damage": 0.2, "rain_damage": 0.2}),
		K("hail", "Grad", "Salwa +2 strzały, Deszcz o połowę gęstszy, każda strzała -20% obrażeń",
			game="Salwa wypuszcza 2 strzały więcej, a Deszcz Strzał pada o połowę gęściej, ale każda strzała zadaje 20% mniej obrażeń."),
	], [L()]),
	("d_trop", "dex", "Tropiciel", (312, 7.5), [
		S("seeker", "Strzała tropiąca", "bow", "strzała sama szuka wrogów"),
		S("rapid_volley", "Szybka salwa", "bow", "seria strzał - teraz zwykła umiejętność, po Strzale tropiącej mocniejsza (combo)"),
		N("loyal_seeker", "Wierny tropiciel", "Strzała tropiąca krąży przy tobie jak przywołanie i sama strzela, ale rezerwuje 15% many", new=True),
		S("viper_arrow", "Strzała Żmija", "bow", "strzała przeskakuje między 4 wrogami, każdy skok +10% obrażeń", new=True,
			tags="atak, pocisk, fizyczne"),
		N("seeker_hits", "Ostrzejszy trop", "+1 trafienie Strzały tropiącej", {"seeker_hits": 1.0}),
		K("falcon_eye", "Oko Sokoła", "trafienia z daleka (ponad 150) zawsze krytyczne, z bliska (do 70) -30% obrażeń",
			game="Trafienia wrogów daleko od ciebie (ponad 150) są zawsze krytyczne, ale bliskie (do 70) zadają 30% mniej obrażeń."),
	]),
	("d_mysliwy", "dex", "Myśliwy", (308, 12.5), [
		S("power_shot", "Grot Swaroga", "bow", "napinany strzał z wybuchem"),
		N("power_charge", "Napięta cięciwa", "+25% szybkości napinania Grotu Swaroga", {"power_charge": 0.25}),
		S("split_arrow", "Rozszczepiona Strzała", "bow", "strzała po trafieniu rozpada się na 3 mniejsze lecące dalej", new=True,
			tags="atak, pocisk, fizyczne"),
		N("pierce_1", "Grot przebijający", "strzały przebijają 1 wroga", {"arrow_pierce": 1.0}),
		N("range_1", "Daleki strzał", "+20% zasięgu strzał, +15% obrażeń Grotu Swaroga", {"arrow_range": 0.2, "power_damage": 0.15}),
		K("running_fire", "Strzelanie w biegu", "strzelanie nie spowalnia, w biegu +15% szybkości ataku",
			game="Strzelanie nie spowalnia ruchu, a gdy biegniesz, masz +15% szybkości ataku."),
	]),
	("d_wataha", "dex", "Wataha (przywołania)", (330, 12.5), [
		S("falcon", "Sokół", "bow", "sokół atakuje wrogów"),
		N("falcon_power", "Szpony", "+20% obrażeń Sokoła", {"falcon_damage": 0.2}),
		S("ballista", "Balista", "bow", "stawiana balista"),
		N("ballista_power", "Mocna balista", "+25% czasu i +15% obrażeń Balisty", {"ballista_time": 0.25, "ballista_damage": 0.15}),
		S("wolf_pack", "Wataha", "bow", "przywołuje 2 wilki na 15 s; wilki gryzą i powalają wrogów", new=True,
			tags="przywołanie, fizyczne"),
		N("pack_leader", "Przewodnik stada", "+1 wilk, +15% obrażeń przywołań", new=True),
	]),
	("d_pulapki", "dex", "Pułapki i jad", (348, 17.5), [
		S("snare", "Sidła", "bow", "pułapki unieruchamiające"),
		N("snare_time", "Mocne sidła", "+50% unieruchomienia Sideł", {"snare_time": 0.5}),
		S("venom_arrows", "Jadowe Groty", "bow", "trujące strzały; combo po Sidłach"),
		N("venom_dmg", "Żmijowy jad", "+25% obrażeń Jadowych Grotów", {"venom_damage": 0.25}),
		S("caltrops", "Kolczatka", "bow", "rozsypane kolce spowalniają i ranią (krwawienie) wrogów na nich", new=True,
			tags="atak, obszar, fizyczne, w czasie"),
		G(),
	]),
	("d_cien", "dex", "Cień", (318, 17.5), [
		S("vault", "Odskok", "bow", "odskok z rozrzutem strzał"),
		N("vault_cd", "Lekki krok", "-25% odnowienia Odskoku", {"vault_cooldown": -0.25}),
		N("dodge_1", "Unik łowcy", "+4% uniku", {"dodge_chance": 0.04}),
		N("silent_steps", "Ciche kroki", "potwory w spoczynku zauważają cię z połowy odległości", new=True),
		K("shadow_stalker", "Łowca w Cieniu", "wrogowie, którzy cię jeszcze nie zauważyli, dostają +60% obrażeń i pierwsze trafienie zawsze krytyczne; wrogowie w walce z tobą -10%", new=True),
	]),
	("d_szal", "dex", "Szał (szybkość)", (347, 7.5), [
		N("speed_1", "Szybkie ręce", "+6% szybkości ataku", {"attack_speed": 0.06}),
		N("move_1", "Wiatr w nogach", "+5% szybkości ruchu", {"move_speed": 0.05}),
		A("strzybog_wind", "Wiatr Strzyboga", "aura: +8% szybkości ruchu i ataku"),
		N("running_breath", "Oddech w biegu", "+3 regeneracji zdrowia/s, gdy biegniesz", new=True),
		G(),
		K("battle_frenzy", "Szał Bitewny", "zabójstwo daje ładunek +4% szybkości (do 10), ładunki znikają po 3 s bez zabójstwa", new=True),
	]),
	# ======================= INTELIGENCJA (księga)
	("i_gate", "int", "Brama Inteligencji", (90, 3.2), [
		S("fireball", "Kula ognia", "spell", "zwykła umiejętność księgi (PPM)", tags="czar, pocisk, obszar, ogień"),
	]),
	("i_ogien", "int", "Ogień", (108, 7.5), [
		S("meteor", "Spadająca Gwiazda", "spell", "meteoryt z podpaleniem"),
		N("fire_dmg", "Żar", "+20% obrażeń Kuli ognia", {"fireball_damage": 0.2}),
		N("burn_dmg", "Tlący się ogień", "+25% obrażeń podpalenia", {"burn_damage": 0.25}),
		S("fire_wall", "Ściana Ognia", "spell", "ściana płomieni w poprzek drogi; pociski przez nią lecące dostają obrażenia od ognia", new=True,
			tags="czar, obszar, ogień, w czasie"),
		N("meteor_area", "Wielki wybuch", "+25% wybuchu Spadającej Gwiazdy", {"meteor_radius": 0.25}),
		N("fire_charge", "Szybkie słowa", "+25% szybkości ładowania Kuli ognia", {"fireball_charge": 0.25}),
	]),
	("i_lod", "int", "Lód", (90, 12.5), [
		S("frost_lance", "Włócznia Marzanny", "spell", "lodowa włócznia"),
		N("lance_pierce", "Przeszywający lód", "Włócznia przebija 1 wroga", {"lance_pierce": 1.0}),
		S("blizzard", "Zamieć", "spell", "śnieżyca na obszar"),
		N("blizzard_time", "Długa zima", "+25% czasu Zamieci i spowolnienia", {"blizzard_time": 0.25, "chill_time": 0.25}),
		S("ice_armor", "Lodowy Pancerz", "spell", "na 8 s: +redukcja obrażeń, wrogowie bijący cię z bliska zamarzają", new=True,
			tags="czar, lód"),
		N("cold_res", "Zimna krew", "+15% odporności na lód", {"cold_resistance": 0.15}, new=True),
		A("frost_breath", "Mroźny Oddech", "aura (jak Righteous Fire): lodowy wir rani co sekundę wrogów wokół i ciebie; więcej obrażeń lodu"),
		N("cold_dmg", "Mroźne serce", "+15% obrażeń od lodu", {"cold_damage": 0.15}),
	]),
	("i_piorun", "int", "Piorun", (70, 7.5), [
		S("chain_lightning", "Łańcuch błyskawic", "spell", "piorun skacze między wrogami"),
		S("thunder_wave", "Fala piorunów", "spell", "fala - teraz zwykła umiejętność, po Łańcuchu mocniejsza (combo)"),
		N("chain_more", "Rozgałęzienie", "+1 cel Łańcucha błyskawic", {"chain_targets": 1.0}),
		S("storm_call", "Burza Peruna", "spell", "burza bijąca piorunami"),
		N("storm_time", "Długa burza", "+25% czasu Burzy Peruna", {"storm_time": 0.25}),
		S("ball_lightning", "Kula Piorunów", "spell", "wolna kula rażąca wrogów"),
		A("perun_wrath", "Gniew Peruna", "aura: co 3 s piorun bije losowego wroga w pobliżu"),
	]),
	("i_runy", "int", "Runy", (68, 12.5), [
		S("rune_stone", "Kamień Runiczny", "spell", "kamień wzmacniający czary obok"),
		N("rune_power", "Moc run", "+25% mocy Kamienia Runicznego", {"rune_bonus": 0.25}),
		N("spell_1", "Pieśń run", "+10% obrażeń czarów", {"spell_damage": 0.1}),
		P("+8 inteligencji"),
		K("echo_runes", "Echo Run", "czary drzewka w 30% wybrzmiewają drugi raz za darmo, ale rzucasz 10% wolniej",
			game="Czary Włócznia Marzanny, Zamieć, Burza Peruna, Kula Piorunów i Spadająca Gwiazda w 30% przypadków wybrzmiewają drugi raz za darmo, ale rzucasz o 10% wolniej.",
			stats={"cast_speed": -0.1}),
	], [L()]),
	("i_mana", "int", "Mana", (92, 17.5), [
		S("mana_shield", "Tarcza Many", "spell", "część ciosów przyjmuje mana"),
		N("mana_1", "Głęboki oddech", "+10% many", {"mana_percent": 0.1}),
		N("mana_regen_1", "Źródło mocy", "+2 regeneracji many/s", {"mana_regen": 2.0}),
		N("mana_flow", "Przelana moc", "8% otrzymanych obrażeń zabiera manę zamiast zdrowia", new=True),
		N("full_mind", "Pełnia umysłu", "+1% obrażeń za każde 5% many ponad połowę (najwyżej +10%)", new=True),
		K("full_power", "Pełnia Mocy", "ponad 90% many czary +40% obrażeń, wszystkie umiejętności +20% many",
			game="Gdy masz ponad 90% many, czary zadają 40% więcej obrażeń, ale wszystkie umiejętności kosztują 20% więcej many."),
	]),
	("i_mgla", "int", "Mgła", (115, 17.5), [
		S("blink", "Krok przez Mgłę", "spell", "teleport"),
		N("blink_cd", "Szybki krok", "-25% odnowienia Kroku przez Mgłę", {"blink_cooldown": -0.25}),
		S("wisps", "Błędne Ogniki", "spell", "przywołuje 3 ogniki krążące przy tobie i strzelające do wrogów (zalążek nekromancji)", new=True,
			tags="czar, przywołanie, ogień"),
		N("loyal_wisps", "Wierne ogniki", "+1 ognik, +15% obrażeń przywołań", new=True),
		G(),
	]),
	("i_zywioly", "int", "Żywioły", (65, 17.5), [
		N("elem_dmg", "Żywiołowa moc", "+12% obrażeń od żywiołów", {"elemental_damage": 0.12}),
		K("harmony", "Harmonia Żywiołów", "czar innego żywiołu niż poprzedni daje na 4 s +30% obrażeń magicznych",
			game="Czar innego żywiołu (ogień, lód, piorun) niż poprzedni daje na 4 s +30% obrażeń magicznych."),
		N("pen_1", "Przebicie", "+8% przebicia odporności", {"resistance_penetration": 0.08}),
		G(),
		K("elem_master", "Mistrz Żywiołów", "zadajesz tylko żywioł, który ostatnio cię trafił (zmienia go w ten żywioł), ale +40% obrażeń", new=True),
	]),
	("i_wola", "int", "Wola (rezerwacja)", (113, 12.5), [
		N("focused_will", "Skupiona wola", "aury rezerwują 10% many mniej", new=True),
		P("+5% many"),
		N("iron_mind", "Żelazny umysł", "+10% many, +1 regeneracji many/s", {"mana_percent": 0.1, "mana_regen": 1.0}),
		K("blood_offering", "Krwawa Ofiara", "aury rezerwują zdrowie zamiast many", new=True),
	]),
	# ======================= STREFA SIŁA / ZRĘCZNOŚĆ (krwawienie, ciosy, szarże)
	("sz_krew", "sz", "Krwawienie", (256, 10.0), [
		S("rend", "Rozpłatanie", "melee", "cięcie z krwawieniem; combo po Mgnieniu"),
		N("bleed_1", "Głębokie rany", "+25% obrażeń krwawienia", {"bleed_damage": 0.25}),
		N("open_wounds", "Otwarte rany", "trafienia ciosami i strzałami mają 10% szansy na krwawienie (z każdą bronią)", new=True),
		P("+4 siły, +4 zręczności"),
		K("blood_frenzy", "Krwawy Szał", "krwawienie wrogów leczy cię o 30% zadanych nim obrażeń - teraz z każdą bronią",
			game="Krwawienie wrogów cię leczy: wracasz do zdrowia o 30% zadanych nim obrażeń."),
	]),
	("sz_ciosy", "sz", "Ciosy i szarże", (284, 13.5), [
		S("thrown_knives", "Ciśnięte Noże", "melee/bow", "rzut 3 nożami wachlarzem, krwawienie (miecz albo łuk)", new=True,
			tags="atak, pocisk, fizyczne, w czasie"),
		N("hit_1", "Celny cios", "+12% obrażeń ciosów", {"hit_damage": 0.12}),
		N("momentum", "Rozpęd", "po umiejętności ruchu następny atak +30% obrażeń", new=True),
		N("life_hit", "Krew za krew", "+3 zdrowia za trafienie", {"life_on_hit": 3.0}),
		G(),
	]),
	# ======================= STREFA ZRĘCZNOŚĆ / INTELIGENCJA (pioruny, uniki, pociski czarów)
	("zi_burza", "zi", "Burza i pociski", (38, 10.0), [
		S("wind_arrow", "Strzała Wichru", "bow", "podmuch odpychający (zręczność i inteligencja)"),
		N("lightning_1", "Gromowładny", "+15% obrażeń od piorunów", {"lightning_damage": 0.15}),
		S("thunder_arrow", "Strzała Gromu", "bow/spell", "piorunowy pocisk przeskakujący na 2 wrogów (łuk albo księga)", new=True,
			tags="atak, czar, pocisk, piorun"),
		N("shock_1", "Porażenie", "+8% szansy na porażenie", {"shock_chance": 0.08}),
		N("lightning_res", "Uziemienie", "+15% odporności na pioruny", {"lightning_resistance": 0.15}, new=True),
	]),
	("zi_uniki", "zi", "Uniki", (18, 15.0), [
		N("dodge_2", "Unik tancerza", "+4% uniku", {"dodge_chance": 0.04}),
		N("lightness", "Zwiewność", "po uniku +10% szybkości na 2 s", new=True),
		P("+4 zręczności, +4 inteligencji"),
		G(),
		K("shadow_hunter", "Myśliwy z Cienia", "po umiejętności ruchu (każdej, nie tylko Odskoku) wrogowie tracą cię z oczu na 2 s, pierwsze trafienie podwójne",
			game="Po umiejętności ruchu (Szarża, Mgnienie, Odskok, Krok przez Mgłę) wrogowie na 2 s tracą cię z oczu, a pierwsze trafienie zadaje podwójne obrażenia."),
	]),
	# ======================= STREFA SIŁA / INTELIGENCJA (ogień, aury, zaklęte ostrza)
	("si_aury", "si", "Aury", (142, 10.0), [
		A("life_spring", "Źródło Życia", "aura: +regeneracja zdrowia (zastępuje Krew wojownika, Oddech łowcy, Mistyczną odnowę)"),
		A("swarog_ember", "Żar Swaroga", "aura: ataki i czary dostają obrażenia od ognia i szansę na podpalenie"),
		A("marzanna_frost", "Szron Marzanny", "aura: obrażenia od lodu i szansa na zamrożenie"),
		N("thrifty_auras", "Oszczędne aury", "aury rezerwują 8% many mniej", new=True),
		A("perun_sparks", "Iskry Peruna", "aura: obrażenia od piorunów i szansa na porażenie"),
		A("mana_spring", "Źródło Many", "aura: +regeneracja many (zastępuje Skupienie bitewne, Cierpliwość łowcy, Strumień many)"),
	]),
	("si_ostrza", "si", "Zaklęte ostrza", (160, 14.5), [
		S("enchanted_blade", "Zaklęte Ostrze", "melee/spell", "ostrze z płomienia: cios mieczem albo czar z księgi wysyła płonącą falę", new=True,
			tags="atak, czar, obszar, ogień"),
		N("fire_1", "Płonąca stal", "+12% obrażeń od ognia", {"fire_damage": 0.12}),
		N("fire_res", "Ognioodporny", "+15% odporności na ogień", {"fire_resistance": 0.15}, new=True),
		G(),
		K("iron_will", "Żelazna Wola", "obrażenia czarów rosną z siły zamiast z inteligencji", new=True),
	]),
]

# Ścieżki małych węzłów: (od, do, ile węzłów, motyw). "od"/"do" to "start" albo "<skupisko>" (wejście skupiska)
# albo "<skupisko>:<numer węzła>". Motyw to dwa rodzaje drobnych węzłów na zmianę (premie - SMALL_STATS).
THEMES = {
	"str": ["+8 siły", "+4% zdrowia"],
	"dex": ["+8 zręczności", "+3% szybkości ataku"],
	"int": ["+8 inteligencji", "+4% many"],
	"sz": ["+4 siły, +4 zręczności", "+4% obrażeń ciosów"],
	"zi": ["+4 zręczności, +4 inteligencji", "+4% obrażeń pocisków"],
	"si": ["+4 siły, +4 inteligencji", "+4% obrażeń od ognia"],
	"res": ["+6% odporności na żywioły", "+4% zdrowia"],
}
PATHS = [
	# start - bramy i pierścień wokół startu (strefy osiągalne od razu)
	("start", "s_gate", 0, "str"), ("start", "d_gate", 0, "dex"), ("start", "i_gate", 0, "int"),
	("s_gate", "d_gate", 2, "res"), ("d_gate", "i_gate", 2, "res"), ("i_gate", "s_gate", 2, "res"),
	# Siła
	("s_gate", "s_krzepa", 1, "str"), ("s_gate", "s_ostrze", 1, "str"), ("s_krzepa", "s_dym", 1, "str"),
	("s_krzepa", "s_wir", 1, "str"), ("s_ostrze", "s_wir", 1, "str"), ("s_ostrze", "s_szermierz", 1, "str"),
	("s_wir", "s_okrzyki", 1, "str"), ("s_dym", "s_bastion", 2, "str"), ("s_wir", "s_bastion", 1, "str"),
	("s_szermierz", "s_ziemia", 1, "str"), ("s_okrzyki", "s_ziemia", 1, "str"), ("s_okrzyki", "s_bastion", 1, "str"),
	# Zręczność
	("d_gate", "d_szal", 1, "dex"), ("d_gate", "d_trop", 1, "dex"), ("d_szal", "d_grad", 1, "dex"),
	("d_szal", "d_wataha", 1, "dex"), ("d_trop", "d_wataha", 1, "dex"), ("d_trop", "d_mysliwy", 1, "dex"),
	("d_grad", "d_pulapki", 1, "dex"), ("d_wataha", "d_cien", 1, "dex"), ("d_mysliwy", "d_cien", 1, "dex"),
	("d_wataha", "d_pulapki", 1, "dex"),
	# Inteligencja
	("i_gate", "i_ogien", 1, "int"), ("i_gate", "i_piorun", 1, "int"), ("i_ogien", "i_lod", 1, "int"),
	("i_piorun", "i_lod", 1, "int"), ("i_ogien", "i_wola", 1, "int"), ("i_piorun", "i_runy", 1, "int"),
	("i_lod", "i_mana", 1, "int"), ("i_runy", "i_zywioly", 1, "int"), ("i_wola", "i_mgla", 1, "int"),
	("i_mana", "i_mgla", 1, "int"), ("i_mana", "i_zywioly", 2, "int"),
	# strefy
	("s_ostrze", "sz_krew", 1, "sz"), ("d_trop", "sz_krew", 2, "sz"), ("sz_krew", "sz_ciosy", 1, "sz"),
	("s_szermierz", "sz_ciosy", 1, "sz"), ("d_mysliwy", "sz_ciosy", 1, "sz"),
	("d_szal", "zi_burza", 2, "zi"), ("i_piorun", "zi_burza", 1, "zi"), ("zi_burza", "zi_uniki", 1, "zi"),
	("d_grad", "zi_uniki", 1, "zi"), ("i_runy", "zi_uniki", 2, "zi"),
	("s_krzepa", "si_aury", 2, "si"), ("i_ogien", "si_aury", 1, "si"), ("si_aury", "si_ostrza", 1, "si"),
	("s_dym", "si_ostrza", 1, "si"), ("i_wola", "si_ostrza", 1, "si"),
]


SPREAD = 1.4  # rozsunięcie skupisk od startu
KEY_PUSH = 0.9  # o ile dalej od środka skupiska stoi zamykający je węzeł kluczowy


def polar(angle, r):
	a = math.radians(angle)
	return (math.cos(a) * r, math.sin(a) * r)


def build():
	nodes = {"start": {"kind": "start", "name": "Start", "desc": "środek drzewka - zwykły atak każdej broni", "pos": (0.0, 0.0),
			"region": "", "cluster": ""}}
	links = []
	clusters = {}
	for entry in CLUSTERS:
		cid, region, cname, (ang, rad), items = entry[:5]
		tail = entry[5] if len(entry) > 5 else []
		cx, cy = polar(ang, rad * SPREAD)
		ids = []
		n = len(items)
		ring = 0.0 if n == 1 else min(2.3, max(1.2, 0.32 * n))
		inward = math.atan2(-cy, -cx)
		# pozycje na pierścieniu: wejście w stronę startu, dalej na zmianę po obu stronach
		order = []
		for i in range(n):
			k = (i + 1) // 2
			off = (2 * math.pi / n) * k * (1 if i % 2 else -1)
			if items[i]["kind"] == "key" and i == n - 1:
				off = math.pi
			order.append(off)
		for i, it in enumerate(items):
			nid = it.get("id") or (f"socket_{cid}" if it["kind"] == "socket" else f"{cid}_{i}")
			a = inward + order[i]
			# węzeł kluczowy zamykający skupisko odsunięty na zewnątrz, żeby nie nachodził na sąsiadów
			r = ring + (KEY_PUSH if it["kind"] == "key" and i == n - 1 and n > 1 else 0.0)
			pos = (cx + math.cos(a) * r, cy + math.sin(a) * r)
			assert nid not in nodes, nid
			nodes[nid] = dict(it, pos=pos, region=region, cluster=cname)
			ids.append(nid)
		# połączenia w skupisku: dwa łuki od wejścia zamknięte w pierścień; węzeł kluczowy to ślepy koniec
		plain = [i for i in range(1, n) if items[i]["kind"] != "key"]
		left = [ids[i] for i in plain if i % 2 == 1]
		right = [ids[i] for i in plain if i % 2 == 0]
		for arm in (left, right):
			prev = ids[0]
			for nid in arm:
				links.append((prev, nid))
				prev = nid
		if left and right:
			links.append((left[-1], right[-1]))
		# węzeł kluczowy w środku skupiska (np. Harmonia Żywiołów) - ślepy koniec przy najbliższym zwykłym węźle
		for i in range(1, n - 1):
			if items[i]["kind"] == "key":
				best = min((ids[x] for x in range(n) if items[x]["kind"] != "key"),
						key=lambda e: math.dist(nodes[e]["pos"], nodes[ids[i]]["pos"]))
				links.append((best, ids[i]))
		if items[-1]["kind"] == "key" and n > 1:
			ends = [e for e in (left[-1:] + right[-1:])] or [ids[0]]
			kp = (cx + math.cos(inward + order[-1]) * ring, cy + math.sin(inward + order[-1]) * ring)
			best = min(ends, key=lambda e: math.dist(nodes[e]["pos"], kp))
			links.append((best, ids[-1]))
		far = ids[-1]
		fx, fy = nodes[far]["pos"]
		dirx, diry = (fx - cx, fy - cy)
		ln = math.hypot(dirx, diry) or 1.0
		prev = far
		for j, t in enumerate(tail):
			nid = f"legend_{cid}" if t["kind"] == "legend" else f"{cid}_t{j}"
			pos = (fx + dirx / ln * 1.4 * (j + 1), fy + diry / ln * 1.4 * (j + 1))
			nodes[nid] = dict(t, pos=pos, region=region, cluster=cname)
			links.append((prev, nid))
			prev = nid
		clusters[cid] = {"name": cname, "region": region, "center": (cx, cy), "ids": ids}

	def passable(cid):
		return [nid for nid in clusters[cid]["ids"] if nodes[nid]["kind"] != "key"]

	def resolve(a, b):
		la = ["start"] if a == "start" else passable(a)
		lb = ["start"] if b == "start" else passable(b)
		return min(((x, y) for x in la for y in lb), key=lambda xy: math.dist(nodes[xy[0]]["pos"], nodes[xy[1]]["pos"]))

	for a, b, count, theme in PATHS:
		na, nb = resolve(a, b)
		if count == 0:
			links.append((na, nb))
			continue
		(ax, ay), (bx, by) = nodes[na]["pos"], nodes[nb]["pos"]
		prev = na
		for k in range(count):
			t = (k + 1) / (count + 1)
			nid = f"p_{a}_{b}_{k}"
			desc = THEMES[theme][k % len(THEMES[theme])]
			region = theme if theme in REGIONS else ""
			nodes[nid] = {"kind": "small", "name": "", "desc": desc, "stats": SMALL_STATS[desc],
					"pos": (ax + (bx - ax) * t, ay + (by - ay) * t),
					"region": region, "cluster": "ścieżka"}
			links.append((prev, nid))
			prev = nid
		links.append((prev, nb))
	return nodes, links, clusters


# ----------------------------------------------------------------------------------------------- rysunek
SCALE = 46
W, H = 3000, 2950
CX, CY = W // 2, H // 2 - 40
BG = (22, 22, 30)
KIND_NAMES = {"start": "start", "skill": "umiejętność", "aura": "aura", "key": "węzeł kluczowy", "notable": "węzeł znaczący",
		"small": "drobny", "socket": "gniazdo", "legend": "gniazdo legendarne"}
WEAPON_COLORS = {"melee": (225, 85, 70), "bow": (90, 200, 100), "spell": (90, 140, 240), "melee/bow": (220, 170, 60),
		"bow/spell": (70, 200, 200), "melee/spell": (180, 100, 220), "any": (240, 240, 240)}


def to_px(p):
	return (CX + p[0] * SCALE, CY + p[1] * SCALE)


def font(size, bold=False):
	name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
	return ImageFont.truetype(f"/usr/share/fonts/truetype/dejavu/{name}", size)


def hexagon(d, x, y, r, fill, outline):
	pts = [(x + math.cos(math.radians(60 * i + 30)) * r, y + math.sin(math.radians(60 * i + 30)) * r) for i in range(6)]
	d.polygon(pts, fill=fill, outline=outline, width=3)


def draw(nodes, links, clusters):
	img = Image.new("RGB", (W, H), BG)
	d = ImageDraw.Draw(img, "RGBA")
	# tła regionów
	for key, reg in REGIONS.items():
		half = 30
		pts = [(CX, CY)]
		for a in range(reg["angle"] - half, reg["angle"] + half + 1, 3):
			pts.append(to_px(polar(a, 31)))
		col = reg["color"]
		d.polygon(pts, fill=col + (28,))
		lx, ly = to_px(polar(reg["angle"], 29.8))
		f = font(36, True)
		tw = d.textlength(reg["name"], font=f)
		d.text((lx - tw / 2, ly - 16), reg["name"], font=f, fill=col + (255,))
	for a, b in links:
		d.line([to_px(nodes[a]["pos"]), to_px(nodes[b]["pos"])], fill=(120, 115, 100, 255), width=3)
	for cid, c in clusters.items():
		if len(c["ids"]) < 2:
			continue
		x, y = to_px(c["center"])
		f = font(17, True)
		tw = d.textlength(c["name"], font=f)
		d.text((x - tw / 2, y - 10), c["name"], font=f, fill=(235, 220, 170, 255))
	small_f = font(13)
	for nid, n in nodes.items():
		x, y = to_px(n["pos"])
		k = n["kind"]
		if k == "start":
			d.ellipse([x - 26, y - 26, x + 26, y + 26], fill=(240, 190, 80), outline=(255, 240, 200), width=4)
			continue
		if k == "small":
			col = REGIONS[n["region"]]["color"] if n["region"] else (160, 160, 160)
			d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=col, outline=(30, 30, 30), width=2)
			continue
		if k in ("skill", "aura"):
			col = WEAPON_COLORS[n["weapon"]]
			hexagon(d, x, y, 21, (40, 40, 52), col)
			if k == "aura":
				d.ellipse([x - 27, y - 27, x + 27, y + 27], outline=col, width=2)
			if n.get("new"):
				d.ellipse([x + 12, y - 24, x + 22, y - 14], fill=(255, 230, 90), outline=(40, 30, 0))
		elif k == "key":
			d.ellipse([x - 22, y - 22, x + 22, y + 22], fill=(60, 45, 30), outline=(240, 200, 110), width=4)
			d.ellipse([x - 13, y - 13, x + 13, y + 13], outline=(240, 200, 110), width=2)
			if n.get("new"):
				d.ellipse([x + 14, y - 24, x + 24, y - 14], fill=(255, 230, 90), outline=(40, 30, 0))
		elif k == "notable":
			col = REGIONS[n["region"]]["color"]
			d.ellipse([x - 12, y - 12, x + 12, y + 12], fill=col, outline=(235, 225, 190), width=3)
			if n.get("new"):
				d.ellipse([x + 7, y - 15, x + 15, y - 7], fill=(255, 230, 90), outline=(40, 30, 0))
		elif k in ("socket", "legend"):
			col = (240, 200, 110) if k == "legend" else (170, 170, 190)
			d.polygon([(x, y - 14), (x + 14, y), (x, y + 14), (x - 14, y)], fill=(30, 30, 40), outline=col, width=3)
		if n["name"] and k not in ("socket",):
			f = font(15, True) if k in ("skill", "aura", "key") else small_f
			tw = d.textlength(n["name"], font=f)
			off = 28 if k in ("skill", "aura", "key") else 15
			col = (255, 255, 255) if k in ("skill", "aura") else ((250, 215, 130) if k == "key" else (205, 205, 210))
			d.text((x - tw / 2, y + off), n["name"], font=f, fill=col, stroke_width=3, stroke_fill=BG)
	# legenda
	lx, ly = 40, H - 300
	f = font(18)
	d.rectangle([lx - 15, ly - 15, lx + 560, H - 20], fill=(30, 30, 40, 230), outline=(90, 90, 100))
	rows = [("skill", "umiejętność (obwódka = broń: czerwona miecz, zielona łuk, niebieska księga)"),
			("mixed", "umiejętność mieszana (jedna z dwóch broni)"),
			("aura", "aura (dowolna broń)"), ("key", "węzeł kluczowy"), ("notable", "węzeł znaczący"),
			("small", "drobny węzeł (+atrybut, +zdrowie...)"), ("socket", "gniazdo / gniazdo legendarne"),
			("new", "żółta kropka - nowe (dziś nie ma w grze)")]
	for i, (k, text) in enumerate(rows):
		y = ly + 12 + i * 34
		x = lx + 18
		if k == "skill":
			hexagon(d, x, y, 13, (40, 40, 52), WEAPON_COLORS["melee"])
		elif k == "mixed":
			hexagon(d, x, y, 13, (40, 40, 52), WEAPON_COLORS["melee/spell"])
		elif k == "aura":
			hexagon(d, x, y, 13, (40, 40, 52), WEAPON_COLORS["any"])
			d.ellipse([x - 17, y - 17, x + 17, y + 17], outline=WEAPON_COLORS["any"], width=2)
		elif k == "key":
			d.ellipse([x - 14, y - 14, x + 14, y + 14], fill=(60, 45, 30), outline=(240, 200, 110), width=3)
		elif k == "notable":
			d.ellipse([x - 10, y - 10, x + 10, y + 10], fill=(150, 150, 150), outline=(235, 225, 190), width=3)
		elif k == "small":
			d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(150, 150, 150))
		elif k == "socket":
			d.polygon([(x, y - 12), (x + 12, y), (x, y + 12), (x - 12, y)], fill=(30, 30, 40), outline=(240, 200, 110), width=3)
		else:
			d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(255, 230, 90))
		d.text((x + 28, y - 11), text, font=font(16), fill=(220, 220, 225))
	img.save(OUT_PNG)


# ----------------------------------------------------------------------------------------------- lista
def write_md(nodes, clusters):
	counts = {}
	for n in nodes.values():
		counts[n["kind"]] = counts.get(n["kind"], 0) + 1
	lines = ["# Wspólne drzewko - pełna lista węzłów (szkic)", "",
			"Plik generuje `python tools/shared_tree_draft.py` (razem z rysunkiem `docs/drzewko_wspolne.png`).",
			"Opis układu i decyzje: `docs/drzewko_wspolne.md`. Liczby w premiach to propozycje do balansu.", "",
			"Legenda: **[U]** umiejętność, **[A]** aura, **[K]** węzeł kluczowy, **[Z]** węzeł znaczący, [d] drobny, "
			"[G] gniazdo; ✦ - nowe, ⌛ - na razie puste miejsce w grze (przyjdzie w kolejnych krokach).", ""]
	per_region = {}
	for cid, c in clusters.items():
		per_region.setdefault(c["region"], []).append(cid)
	tag = {"skill": "**[U]**", "aura": "**[A]**", "key": "**[K]**", "notable": "**[Z]**", "small": "[d]", "socket": "[G]",
			"legend": "[G]"}
	wname = {"melee": "miecz", "bow": "łuk", "spell": "księga", "melee/bow": "miecz albo łuk", "bow/spell": "łuk albo księga",
			"melee/spell": "miecz albo księga", "any": "każda broń"}
	for region, reg in REGIONS.items():
		cids = per_region.get(region, [])
		total = sum(1 for n in nodes.values() if n["region"] == region)
		lines += [f"## {reg['name']} ({total} węzłów ze ścieżkami)", ""]
		for cid in cids:
			c = clusters[cid]
			members = [nid for nid in nodes if nodes[nid]["cluster"] == c["name"] and nodes[nid]["region"] == c["region"]]
			lines.append(f"### {c['name']} ({len(members)})")
			lines.append("")
			for nid in members:
				n = nodes[nid]
				new = (" ✦" if n.get("new") else "") + (" ⌛" if n.get("soon") else "")
				name = n["name"] or ""
				extra = ""
				if n["kind"] in ("skill", "aura"):
					extra = f" ({wname[n['weapon']]}{'; ' + n['tags'] if n.get('tags') else ''})"
				head = f"{tag[n['kind']]} {name}{new}{extra}".strip()
				lines.append(f"- {head} - {n['desc']}" if name else f"- {head} {n['desc']}")
			lines.append("")
		small = [n for n in nodes.values() if n["cluster"] == "ścieżka" and n["region"] == region]
		if small:
			lines.append(f"Ścieżki: {len(small)} drobnych węzłów ({', '.join(sorted(set(n['desc'] for n in small)))}).")
			lines.append("")
	ring = [n for n in nodes.values() if n["cluster"] == "ścieżka" and not n["region"]]
	lines += ["## Pierścień wokół startu", "",
			f"{len(ring)} drobnych węzłów między bramami ({', '.join(sorted(set(n['desc'] for n in ring)))}) - "
			"pozwalają przejść do sąsiedniej strony bez okrążania.", ""]
	lines += ["## Liczby", "", "| Rodzaj | Ile |", "|---|---|"]
	for k in ["start", "skill", "aura", "key", "notable", "small", "socket", "legend"]:
		lines.append(f"| {KIND_NAMES[k]} | {counts.get(k, 0)} |")
	lines.append(f"| **razem** | **{len(nodes)}** |")
	OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
	return counts


# ----------------------------------------------------------------------------------------------- dane dla gry
def gd_value(v):
	if isinstance(v, bool):
		return "true" if v else "false"
	if isinstance(v, (int, float)):
		return repr(round(float(v), 3))
	if isinstance(v, str):
		return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
	if isinstance(v, tuple):
		return "Vector2(%s, %s)" % (round(v[0], 2), round(v[1], 2))
	if isinstance(v, list):
		return "[" + ", ".join(gd_value(x) for x in v) + "]"
	if isinstance(v, dict):
		return "{" + ", ".join(f"{gd_value(k)}: {gd_value(x)}" for k, x in v.items()) + "}"
	raise TypeError(v)


def cap(text):
	return text[:1].upper() + text[1:]


def write_gd(nodes, links, clusters):
	cluster_of = {}
	for cid, c in clusters.items():
		for nid in nodes:
			if nodes[nid]["cluster"] == c["name"] and nodes[nid]["region"] == c["region"]:
				cluster_of[nid] = cid
	out_links = {nid: [] for nid in nodes}
	for a, b in links:
		out_links[a].append(b)
	lines = ["class_name SkillTreeData",
			"## Dane wspólnego drzewka umiejętności - PLIK GENEROWANY przez `python tools/shared_tree_draft.py`, nie edytuj ręcznie.",
			"## Opis pól węzła w SkillTree. Identyfikatory węzłów są w zapisach gry.", "",
			"const NODES := {"]
	for nid, n in nodes.items():
		k = n["kind"]
		d = {"pos": n["pos"]}
		if k == "start":
			d.update(kind="start", name="Początek drzewka",
					description="Środek wspólnego drzewka - zwykły atak każdej broni. Wybieraj węzły połączone z już wybranymi.")
		elif k in ("skill", "aura"):
			d["kind"] = "skill"
			if k == "aura":
				d["aura"] = True
			if n.get("soon"):
				d.update(soon=True, name=n["name"], description=cap(n["desc"]), weapon=n["weapon"])
			else:
				d["skill"] = nid
		elif k == "key":
			d.update(kind="keystone", name=n["name"], description=cap(n["game"]))
			if n["stats"]:
				d["stats"] = n["stats"]
			if n.get("soon"):
				d["soon"] = True
		elif k in ("notable", "small"):
			d["kind"] = "passive"
			if k == "notable":
				d.update(notable=True, name=n["name"])
			if n.get("soon"):
				d.update(soon=True, description=cap(n["desc"]))
			else:
				d["stats"] = n["stats"]
		elif k in ("socket", "legend"):
			d.update(kind="socket", name=n["name"])
			if k == "legend":
				d["legendary"] = True
		d["region"] = n["region"]
		d["cluster"] = cluster_of.get(nid, "")
		d["links"] = out_links[nid]
		lines.append(f"\t{gd_value(nid)}: {gd_value(d)},")
	lines += ["}", "", "## Skupiska: nazwa, strona (REGIONS) i środek (do podpisów w oknie drzewka).", "const CLUSTERS := {"]
	for cid, c in clusters.items():
		if len(c["ids"]) > 1:
			lines.append(f"\t{gd_value(cid)}: {gd_value({'name': c['name'], 'region': c['region'], 'center': c['center']})},")
	lines += ["}", "", "## Strony i strefy drzewka: nazwa, kierunek od startu (stopnie, oś y w dół) i kolor.", "const REGIONS := {"]
	for rid, r in REGIONS.items():
		col = "Color8(%d, %d, %d)" % r["color"]
		lines.append(f"\t{gd_value(rid)}: {{\"name\": {gd_value(r['name'])}, \"angle\": {r['angle']}.0, \"color\": {col}}},")
	lines.append("}")
	OUT_GD.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
	nodes, links, clusters = build()
	draw(nodes, links, clusters)
	counts = write_md(nodes, clusters)
	write_gd(nodes, links, clusters)
	print("węzły:", len(nodes), counts)
	for region in REGIONS:
		print(region, sum(1 for n in nodes.values() if n["region"] == region))
