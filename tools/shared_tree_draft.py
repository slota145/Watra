"""Szkic wspólnego drzewka umiejętności (krok 1 z docs/plan_drzewek.md) - dane do akceptacji autora, jeszcze nie w grze.

Węzły są zebrane w skupiska (CLUSTERS: region, środek we współrzędnych biegunowych, lista węzłów), skupiska łączą
ścieżki małych węzłów (PATHS). Skrypt rozmieszcza węzły, liczy je i zapisuje:
- docs/drzewko_wspolne.png - rysunek układu,
- docs/drzewko_wspolne_wezly.md - pełna lista węzłów (opis układu i decyzje są w docs/drzewko_wspolne.md).
Po akceptacji dane posłużą do przebudowy scripts/skill_tree.gd (krok 2).

Uruchom: python tools/shared_tree_draft.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT_PNG = ROOT / "docs" / "drzewko_wspolne.png"
OUT_MD = ROOT / "docs" / "drzewko_wspolne_wezly.md"

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


def S(name, weapon, desc, new=False, tags=""):
	return {"kind": "skill", "name": name, "weapon": weapon, "desc": desc, "new": new, "tags": tags}


def A(name, desc, new=True):
	return {"kind": "aura", "name": name, "weapon": "any", "desc": desc, "new": new, "tags": "aura"}


def K(name, desc, new=False):
	return {"kind": "key", "name": name, "desc": desc, "new": new}


def N(name, desc, new=False):
	return {"kind": "notable", "name": name, "desc": desc, "new": new}


def P(desc):
	return {"kind": "small", "name": "", "desc": desc}


def G():
	return {"kind": "socket", "name": "Gniazdo", "desc": "kamień szlachetny (działa o połowę mocniej)"}


def L():
	return {"kind": "legend", "name": "Gniazdo legendarne", "desc": "kamień szlachetny, później esencja legendy"}


# Skupisko: id, region, nazwa, (kąt w stopniach, odległość od startu), węzły. Pierwszy węzeł to wejście (od strony
# startu), dalej węzły idą na zmianę po dwóch łukach pierścienia; węzeł kluczowy zamyka pierścień po przeciwnej
# stronie, a "tail" (np. gniazdo legendarne) wystaje za nim na zewnątrz.
CLUSTERS = [
	# ======================= SIŁA (miecz)
	("s_gate", "str", "Brama Siły", (210, 3.2), [
		S("Młynek", "melee", "zwykła umiejętność miecza (PPM)", tags="atak, obszar, fizyczne"),
	]),
	("s_wir", "str", "Wir", (204, 12.5), [
		S("Mgnienie", "melee", "skoki od wroga do wroga; combo po Młynku"),
		N("Szeroki zamach", "+20% zasięgu Młynka"),
		N("Wirujące ostrze", "+20% obrażeń Młynka"),
		P("+6% obrażeń fizycznych"),
		N("Cięcie z cienia", "+20% obrażeń Mgnienia, -25% many za skok"),
		N("Wciągający wir", "Młynek lekko przyciąga wrogów z bliska", new=True),
		K("Oko Cyklonu", "Młynek wciąga wrogów i rozkręca się do +100% obrażeń, zużywa 2x więcej many"),
	], [L()]),
	("s_ostrze", "str", "Ostrze i combo", (228, 7.5), [
		S("Szarża", "melee", "wypad z cięciem; Półksiężyc po niej"),
		S("Półksiężyc", "melee", "szerokie cięcie - teraz zwykła umiejętność, po Szarży mocniejsze (combo)"),
		N("Płynne przejścia", "+0,4 s okna combo"),
		N("Szybki wypad", "-25% odnowienia Szarży"),
		S("Rozłupanie Ziemi", "melee", "kolce z ziemi; combo po Półksiężycu"),
		N("Drżąca ziemia", "+50% ogłuszenia Rozłupania Ziemi"),
		N("Mistrz przejść", "+15% obrażeń ciosów combo"),
		K("Taniec Ostrzy", "każde combo daje +5% szybkości ataku na 4 s (do 5 razy)"),
	]),
	("s_szermierz", "str", "Szermierz", (232, 12.5), [
		S("Riposta", "melee", "zasłona i kontra wszystkich wokół; po niej Szarża za darmo"),
		N("Oko kata", "+4% szansy na cios krytyczny"),
		N("Mistrz szermierki", "+50% obrażeń kontry Riposty"),
		S("Wilczy Kieł", "melee", "seria 4 szybkich pchnięć w jednego wroga (na bossów); ostatnie przebija pancerz", new=True,
			tags="atak, cios, fizyczne"),
		N("Cios w serce", "+30% obrażeń krytycznych"),
		P("+8 siły"),
	]),
	("s_okrzyki", "str", "Okrzyki", (212, 17.5), [
		S("Zew Peruna", "melee", "okrzyk: strach i pewne krytyki"),
		N("Głos burzy", "+10% premii Zewu Peruna"),
		S("Ryk Tura", "melee", "okrzyk: wrogowie wokół rzucają się na ciebie, +30% pancerza na 6 s", new=True,
			tags="okrzyk, obszar"),
		N("Donośny głos", "+40% zasięgu okrzyków, -20% ich odnowienia", new=True),
		A("Postrach", "aura: wrogowie wokół zadają 10% mniej obrażeń i wolniej atakują"),
		P("+8 siły"),
	]),
	("s_krzepa", "str", "Krzepa (zdrowie)", (193, 7.5), [
		N("Twarda skóra", "+8% zdrowia"),
		N("Szybkie gojenie", "+2 regeneracji zdrowia/s"),
		A("Krzepa", "aura: +12% maksymalnego zdrowia"),
		N("Niezłomny", "+60 zdrowia"),
		N("Pełnia Sił", "+1% obrażeń za każde 5% zdrowia ponad połowę (najwyżej +10%)", new=True),
		K("Krew za Manę", "umiejętności kosztują zdrowie zamiast many (nie mogą zabić), +25% zdrowia - dawna Ofiara Krwi z księgi, teraz z każdą bronią"),
	]),
	("s_bastion", "str", "Bastion", (190, 17.5), [
		N("Kolczuga pod skórą", "+10 pancerza"),
		N("Pancerna postawa", "+12% pancerza"),
		N("Hart ducha", "+15% odporności na Nawię", new=True),
		N("Gniew rannego", "+1% obrażeń za każde 5% brakującego zdrowia", new=True),
		G(),
		K("Ostatni Bastion", "poniżej 30% zdrowia +50% obrażeń i +50% redukcji obrażeń", new=True),
	]),
	("s_ziemia", "str", "Ziemia", (233, 17.5), [
		S("Skok Niedźwiedzia", "melee", "skok na wskazane miejsce, lądowanie rani i odrzuca wrogów wokół", new=True,
			tags="atak, obszar, ruch, fizyczne"),
		N("Ciężka ręka", "+12% obrażeń obszarowych"),
		N("Wstrząs", "umiejętności obszarowe miecza ogłuszają na 0,3 s", new=True),
		P("+8 siły"),
		G(),
	]),
	("s_dym", "str", "Dym", (182, 12.5), [
		S("Dymne Wybuchy", "melee", "ładowane wybuchy dymu (siła i inteligencja)"),
		N("Gęsty dym", "+25% szybkości ładowania Dymnych Wybuchów"),
		S("Widmowe Ostrza", "melee", "krążące ostrza (siła i inteligencja)"),
		N("Duszący dym", "+20% obrażeń Dymnych Wybuchów"),
		N("Czwarte ostrze", "+1 Widmowe Ostrze"),
		K("Dym i Cień", "po Dymnych Wybuchach chmura na 5 s: +30% uniku, Mgnienie bez many"),
	]),
	# ======================= ZRĘCZNOŚĆ (łuk)
	("d_gate", "dex", "Brama Zręczności", (330, 3.2), [
		S("Salwa", "bow", "zwykła umiejętność łuku (PPM)", tags="atak, pocisk, fizyczne"),
	]),
	("d_grad", "dex", "Grad", (352, 12.5), [
		S("Deszcz Strzał", "bow", "deszcz strzał na obszar; combo po Salwie"),
		N("Wachlarz", "+1 strzała Salwy, strzały lecą wachlarzem", new=False),
		N("Szereg", "+1 pocisk umiejętności łuku, dodatkowe lecą równolegle obok siebie", new=True),
		N("Gęsty grad", "+25% kręgu Deszczu Strzał"),
		N("Ostre groty", "+20% obrażeń Salwy i Deszczu Strzał"),
		K("Grad", "Salwa +2 strzały, Deszcz o połowę gęstszy, każda strzała -20% obrażeń"),
	], [L()]),
	("d_trop", "dex", "Tropiciel", (312, 7.5), [
		S("Strzała tropiąca", "bow", "strzała sama szuka wrogów"),
		S("Szybka salwa", "bow", "seria strzał - teraz zwykła umiejętność, po Strzale tropiącej mocniejsza (combo)"),
		N("Wierny tropiciel", "Strzała tropiąca krąży przy tobie jak przywołanie i sama strzela, ale rezerwuje 15% many", new=True),
		S("Strzała Żmija", "bow", "strzała przeskakuje między 4 wrogami, każdy skok +10% obrażeń", new=True,
			tags="atak, pocisk, fizyczne"),
		N("Ostrzejszy trop", "+1 trafienie Strzały tropiącej"),
		K("Oko Sokoła", "trafienia z daleka (ponad 150) zawsze krytyczne, z bliska (do 70) -30% obrażeń"),
	]),
	("d_mysliwy", "dex", "Myśliwy", (308, 12.5), [
		S("Grot Swaroga", "bow", "napinany strzał z wybuchem"),
		N("Napięta cięciwa", "+25% szybkości napinania Grotu Swaroga"),
		S("Rozszczepiona Strzała", "bow", "strzała po trafieniu rozpada się na 3 mniejsze lecące dalej", new=True,
			tags="atak, pocisk, fizyczne"),
		N("Grot przebijający", "strzały przebijają 1 wroga"),
		N("Daleki strzał", "+20% zasięgu strzał, +15% obrażeń Grotu Swaroga"),
		K("Strzelanie w biegu", "strzelanie nie spowalnia, w biegu +15% szybkości ataku"),
	]),
	("d_wataha", "dex", "Wataha (przywołania)", (330, 12.5), [
		S("Sokół", "bow", "sokół atakuje wrogów"),
		N("Szpony", "+20% obrażeń Sokoła"),
		S("Balista", "bow", "stawiana balista"),
		N("Mocna balista", "+25% czasu i +15% obrażeń Balisty"),
		S("Wataha", "bow", "przywołuje 2 wilki na 15 s; wilki gryzą i powalają wrogów", new=True,
			tags="przywołanie, fizyczne"),
		N("Przewodnik stada", "+1 wilk, +15% obrażeń przywołań", new=True),
	]),
	("d_pulapki", "dex", "Pułapki i jad", (348, 17.5), [
		S("Sidła", "bow", "pułapki unieruchamiające"),
		N("Mocne sidła", "+50% unieruchomienia Sideł"),
		S("Jadowe Groty", "bow", "trujące strzały; combo po Sidłach"),
		N("Żmijowy jad", "+25% obrażeń Jadowych Grotów i trucizny"),
		S("Kolczatka", "bow", "rozsypane kolce spowalniają i ranią (krwawienie) wrogów na nich", new=True,
			tags="atak, obszar, fizyczne, w czasie"),
		G(),
	]),
	("d_cien", "dex", "Cień", (318, 17.5), [
		S("Odskok", "bow", "odskok z rozrzutem strzał"),
		N("Lekki krok", "-25% odnowienia Odskoku"),
		N("Unik łowcy", "+4% uniku"),
		N("Ciche kroki", "potwory w spoczynku zauważają cię z połowy odległości", new=True),
		K("Łowca w Cieniu", "wrogowie, którzy cię jeszcze nie zauważyli, dostają +60% obrażeń i pierwsze trafienie zawsze krytyczne; wrogowie w walce z tobą -10%", new=True),
	]),
	("d_szal", "dex", "Szał (szybkość)", (347, 7.5), [
		N("Szybkie ręce", "+6% szybkości ataku"),
		N("Wiatr w nogach", "+5% szybkości ruchu"),
		A("Wiatr Strzyboga", "aura: +8% szybkości ruchu i ataku"),
		N("Oddech w biegu", "+3 regeneracji zdrowia/s, gdy biegniesz", new=True),
		G(),
		K("Szał Bitewny", "zabójstwo daje ładunek +4% szybkości (do 10), ładunki znikają po 3 s bez zabójstwa", new=True),
	]),
	# ======================= INTELIGENCJA (księga)
	("i_gate", "int", "Brama Inteligencji", (90, 3.2), [
		S("Kula ognia", "spell", "zwykła umiejętność księgi (PPM)", tags="czar, pocisk, obszar, ogień"),
	]),
	("i_ogien", "int", "Ogień", (108, 7.5), [
		S("Spadająca Gwiazda", "spell", "meteoryt z podpaleniem"),
		N("Żar", "+20% obrażeń Kuli ognia"),
		N("Tlący się ogień", "+25% obrażeń podpalenia"),
		S("Ściana Ognia", "spell", "ściana płomieni w poprzek drogi; pociski przez nią lecące dostają obrażenia od ognia", new=True,
			tags="czar, obszar, ogień, w czasie"),
		N("Wielki wybuch", "+25% wybuchu Spadającej Gwiazdy"),
		N("Szybkie słowa", "+25% szybkości ładowania Kuli ognia"),
	]),
	("i_lod", "int", "Lód", (90, 12.5), [
		S("Włócznia Marzanny", "spell", "lodowa włócznia"),
		N("Przeszywający lód", "Włócznia przebija 1 wroga"),
		S("Zamieć", "spell", "śnieżyca na obszar"),
		N("Długa zima", "+25% czasu Zamieci i spowolnienia"),
		S("Lodowy Pancerz", "spell", "na 8 s: +redukcja obrażeń, wrogowie bijący cię z bliska zamarzają", new=True,
			tags="czar, lód"),
		N("Zimna krew", "+15% odporności na lód", new=True),
		A("Mroźny Oddech", "aura (jak Righteous Fire): lodowy wir rani co sekundę wrogów wokół i ciebie; więcej obrażeń lodu"),
		N("Mroźne serce", "+15% obrażeń od lodu"),
	]),
	("i_piorun", "int", "Piorun", (70, 7.5), [
		S("Łańcuch błyskawic", "spell", "piorun skacze między wrogami"),
		S("Fala piorunów", "spell", "fala - teraz zwykła umiejętność, po Łańcuchu mocniejsza (combo)"),
		N("Rozgałęzienie", "+1 cel Łańcucha błyskawic"),
		S("Burza Peruna", "spell", "burza bijąca piorunami"),
		N("Długa burza", "+25% czasu Burzy Peruna"),
		S("Kula Piorunów", "spell", "wolna kula rażąca wrogów"),
		A("Gniew Peruna", "aura: co 3 s piorun bije losowego wroga w pobliżu"),
	]),
	("i_runy", "int", "Runy", (68, 12.5), [
		S("Kamień Runiczny", "spell", "kamień wzmacniający czary obok"),
		N("Moc run", "+25% mocy Kamienia Runicznego"),
		N("Pieśń run", "+10% obrażeń czarów"),
		P("+8 inteligencji"),
		K("Echo Run", "czary drzewka w 30% wybrzmiewają drugi raz za darmo, ale rzucasz 10% wolniej"),
	], [L()]),
	("i_mana", "int", "Mana", (92, 17.5), [
		S("Tarcza Many", "spell", "część ciosów przyjmuje mana"),
		N("Głęboki oddech", "+10% many"),
		N("Źródło mocy", "+2 regeneracji many/s"),
		N("Przelana moc", "8% otrzymanych obrażeń zabiera manę zamiast zdrowia", new=True),
		N("Pełnia umysłu", "+1% obrażeń za każde 5% many ponad połowę (najwyżej +10%)", new=True),
		K("Pełnia Mocy", "ponad 90% many czary +40% obrażeń, wszystkie umiejętności +20% many"),
	]),
	("i_mgla", "int", "Mgła", (115, 17.5), [
		S("Krok przez Mgłę", "spell", "teleport"),
		N("Szybki krok", "-25% odnowienia Kroku przez Mgłę"),
		S("Błędne Ogniki", "spell", "przywołuje 3 ogniki krążące przy tobie i strzelające do wrogów (zalążek nekromancji)", new=True,
			tags="czar, przywołanie, ogień"),
		N("Wierne ogniki", "+1 ognik, +15% obrażeń przywołań", new=True),
		G(),
	]),
	("i_zywioly", "int", "Żywioły", (65, 17.5), [
		N("Żywiołowa moc", "+12% obrażeń od żywiołów"),
		K("Harmonia Żywiołów", "czar innego żywiołu niż poprzedni daje na 4 s +30% obrażeń magicznych"),
		N("Przebicie", "+8% przebicia odporności"),
		G(),
		K("Mistrz Żywiołów", "zadajesz tylko żywioł, który ostatnio cię trafił (zmienia go w ten żywioł), ale +40% obrażeń", new=True),
	]),
	("i_wola", "int", "Wola (rezerwacja)", (113, 12.5), [
		N("Skupiona wola", "aury rezerwują 10% many mniej", new=True),
		P("+5% many"),
		N("Żelazny umysł", "+10% many, +1 regeneracji many/s"),
		K("Krwawa Ofiara", "aury rezerwują zdrowie zamiast many", new=True),
	]),
	# ======================= STREFA SIŁA / ZRĘCZNOŚĆ (krwawienie, ciosy, szarże)
	("sz_krew", "sz", "Krwawienie", (256, 10.0), [
		S("Rozpłatanie", "melee", "cięcie z krwawieniem; combo po Mgnieniu"),
		N("Głębokie rany", "+25% obrażeń krwawienia"),
		N("Otwarte rany", "trafienia ciosami i strzałami mają 10% szansy na krwawienie (z każdą bronią)", new=True),
		P("+4 siły, +4 zręczności"),
		K("Krwawy Szał", "krwawienie wrogów leczy cię o 30% zadanych nim obrażeń - teraz z każdą bronią"),
	]),
	("sz_ciosy", "sz", "Ciosy i szarże", (284, 13.5), [
		S("Ciśnięte Noże", "melee/bow", "rzut 3 nożami wachlarzem, krwawienie (miecz albo łuk)", new=True,
			tags="atak, pocisk, fizyczne, w czasie"),
		N("Celny cios", "+12% obrażeń ciosów"),
		N("Rozpęd", "po umiejętności ruchu następny atak +30% obrażeń", new=True),
		N("Krew za krew", "+3 zdrowia za trafienie"),
		G(),
	]),
	# ======================= STREFA ZRĘCZNOŚĆ / INTELIGENCJA (pioruny, uniki, pociski czarów)
	("zi_burza", "zi", "Burza i pociski", (38, 10.0), [
		S("Strzała Wichru", "bow", "podmuch odpychający (zręczność i inteligencja)"),
		N("Gromowładny", "+15% obrażeń od piorunów"),
		S("Strzała Gromu", "bow/spell", "piorunowy pocisk przeskakujący na 2 wrogów (łuk albo księga)", new=True,
			tags="atak, czar, pocisk, piorun"),
		N("Porażenie", "+8% szansy na porażenie"),
		N("Uziemienie", "+15% odporności na pioruny", new=True),
	]),
	("zi_uniki", "zi", "Uniki", (18, 15.0), [
		N("Unik tancerza", "+4% uniku"),
		N("Zwiewność", "po uniku +10% szybkości na 2 s", new=True),
		P("+4 zręczności, +4 inteligencji"),
		G(),
		K("Myśliwy z Cienia", "po umiejętności ruchu (każdej, nie tylko Odskoku) wrogowie tracą cię z oczu na 2 s, pierwsze trafienie podwójne"),
	]),
	# ======================= STREFA SIŁA / INTELIGENCJA (ogień, aury, zaklęte ostrza)
	("si_aury", "si", "Aury", (142, 10.0), [
		A("Źródło Życia", "aura: +regeneracja zdrowia (zastępuje Krew wojownika, Oddech łowcy, Mistyczną odnowę)"),
		A("Żar Swaroga", "aura: ataki i czary dostają obrażenia od ognia i szansę na podpalenie"),
		A("Szron Marzanny", "aura: obrażenia od lodu i szansa na zamrożenie"),
		N("Oszczędne aury", "aury rezerwują 8% many mniej", new=True),
		A("Iskry Peruna", "aura: obrażenia od piorunów i szansa na porażenie"),
		A("Źródło Many", "aura: +regeneracja many (zastępuje Skupienie bitewne, Cierpliwość łowcy, Strumień many)"),
	]),
	("si_ostrza", "si", "Zaklęte ostrza", (160, 14.5), [
		S("Zaklęte Ostrze", "melee/spell", "ostrze z płomienia: cios mieczem albo czar z księgi wysyła płonącą falę", new=True,
			tags="atak, czar, obszar, ogień"),
		N("Płonąca stal", "+12% obrażeń od ognia dla ataków"),
		N("Ognioodporny", "+15% odporności na ogień", new=True),
		G(),
		K("Żelazna Wola", "obrażenia czarów rosną z siły zamiast z inteligencji", new=True),
	]),
]

# Ścieżki małych węzłów: (od, do, ile węzłów, motyw). "od"/"do" to "start" albo "<skupisko>" (wejście skupiska)
# albo "<skupisko>:<numer węzła>".
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
			nid = f"{cid}:{i}"
			a = inward + order[i]
			pos = (cx + math.cos(a) * ring, cy + math.sin(a) * ring)
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
			nid = f"{cid}:t{j}"
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
			nid = f"p:{a}-{b}:{k}"
			desc = THEMES[theme][k % len(THEMES[theme])]
			region = theme if theme in REGIONS else ""
			nodes[nid] = {"kind": "small", "name": "", "desc": desc, "pos": (ax + (bx - ax) * t, ay + (by - ay) * t),
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
			"[G] gniazdo; ✦ - nowe (dziś nie ma w grze).", ""]
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
			members = [nid for nid in nodes if nid.startswith(cid + ":")]
			lines.append(f"### {c['name']} ({len(members)})")
			lines.append("")
			for nid in members:
				n = nodes[nid]
				new = " ✦" if n.get("new") else ""
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


if __name__ == "__main__":
	nodes, links, clusters = build()
	draw(nodes, links, clusters)
	counts = write_md(nodes, clusters)
	print("węzły:", len(nodes), counts)
	for region in REGIONS:
		print(region, sum(1 for n in nodes.values() if n["region"] == region))
