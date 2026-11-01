class_name Settlement
extends Node
## Osada Ostoja - ostatnie schronienie ludzi przed hordami potworów, które zalały świat.
## Otoczona owalną palisadą z trzema bramami (zachód, wschód, południe), z karczmą
## (z dwoma pokojami gościnnymi i stolikami przed wejściem), domem sołtysa, magazynem,
## kuźnią z daszkiem nad kowadłem i sklepem ze stajnią. Mieszkańcy pracują: tragarze noszą
## deski do naprawianej palisady, beczki do karczmy i towar z wozu do sklepu, kowal kuje,
## myśliwy oprawia skóry, a goście karczmy wychodzą czasem na piwo.
## Przy magazynie rosną stosy drewna i kamienia - im więcej ich złożono, tym są większe.
## Za południową bramą jest miejsce na koszary: po zadaniach sołtysa powstaje tam plac budowy,
## a potem koszary z żołnierzami ćwiczącymi na kukłach (na udeptanym placu obok) i musztrą przed budynkiem.
## Na północnym wschodzie, za palisadą, powstaje chatka myśliwych: trzej myśliwi chodzą na
## polowania do łowisk (po jednym na róg mapy), znoszą zwierzynę, oprawiają ją, wędzą mięso,
## wyrabiają strzały, ćwiczą strzelanie do tarczy i odnoszą skóry i mięso do magazynu.
## Na północnym zachodzie, na uboczu za palisadą, może stanąć chata mędrca: izba pełna ksiąg,
## mędrzec czytający przy pulpicie, a wokół kocioł z wywarem, luneta, grządka ziół i runy.
## Na południowym zachodzie, przy drodze od południowej bramy, gildia poszukiwaczy przygód:
## przed nią tablica ogłoszeń (czytają ją poszukiwacze), proporce, pochodnie i ława.
## Obok placu ćwiczeń stoi nieśmiertelna kukła treningowa (TrainingDummy) z licznikiem obrażeń.
## Potwory nie wchodzą na teren osady (bezpieczna strefa).
##
## Wszystkie pozycje w układzie poniżej są w kafelkach układu względem lewego górnego rogu osady.
## Osada urosła razem z postaciami: kafelek układu ma w świecie SCALE kafelków (i SCALE razy
## większe budynki), dlatego wszystko przeliczamy przez _px() (piksele) albo _cell() (kafelki świata).

const SCALE := 1.375
## Rozmiar osady w kafelkach układu i w kafelkach świata (LAYOUT_SIZE * SCALE w górę).
const LAYOUT_SIZE := Vector2i(66, 56)
const SIZE := Vector2i(91, 77)
const TILE := 16
## Palisada to zaokrąglony owal (superelipsa) z lekkim falowaniem: środek i półosie w kafelkach.
const CENTER := Vector2(33.0, 23.0)
const RADII := Vector2(25.0, 18.0)
const ROUNDNESS := 3.0
## Wiersz, którym droga przecina osadę (środek bramy zachodniej i wschodniej).
const ROAD_ROW := 22.8
## Bramy: zachodnia/wschodnia zajmują wiersze 21-24, południowa kolumny 31-34.
const GATE_ROWS := Vector2i(21, 24)
const GATE_COLUMNS := Vector2i(31, 34)
## Fragment wschodniej palisady w naprawie (wiersze).
const BROKEN_ROWS := Vector2i(27, 30)
## Pale palisady stoją co STAKE_STEP pikseli wzdłuż owalu (na bokach gęściej - widać je jeden za drugim),
## warianty z wagami (klatki palisade_stake.png). Wieże stoją na łukach owalu (kąty w przestrzeni półosi).
const STAKE_STEP := Vector2(6.0, 3.5)
const STAKE_WEIGHTS: Array[float] = [5, 4, 0.4, 0.4, 2, 2, 0.4, 1, 1]
const TOWER_ANGLES: Array[float] = [-PI * 0.75, -PI * 0.25, PI * 0.25, PI * 0.75]
const TOWER_CLEARANCE := 22.0
## Szerokość pasa ubitej ziemi pod palisadą (w "promieniach" owalu, po obu stronach).
const WALL_DIRT := 0.022

const NPC_SCENE := preload("res://scenes/npc.tscn")
const CAMPFIRE := preload("res://scenes/props/campfire.tscn")
const SHRINE := preload("res://scenes/props/shrine.tscn")
const OAK := preload("res://scenes/props/tree_oak.tscn")
const BUSH := preload("res://scenes/props/bush.tscn")

## Runo Goblińskiego Lasu (World.FOREST_WANG_ROW): pełny kafelek drogi i warianty czystej łąki.
## Brzegi ścieżek wygładza potem World._blend_settlement_ground (przejścia Wang).
const DIRT_TILES: Array[Vector2i] = [Vector2i(3, 30)]
const YARD_TILES: Array[Vector2i] = [Vector2i(0, 23), Vector2i(0, 27), Vector2i(0, 31)]
## Bruk placu przed domem sołtysa (pełny kafelek zestawu World.COBBLE_WANG_ROW); brzegi jak ścieżki.
const COBBLE_TILE := Vector2i(3, 58)
const MAP_COBBLE := Color("8a8a86")

const MAP_DIRT := Color("9c7b52")
const MAP_YARD := Color("6f8a40")
const MAP_PALISADE := Color("3a2215")
const MAP_MERCHANT := Color("f2c94c")
const MAP_CHIEF := Color("ffd86b")

## nazwa: [pozycja (kafelki), rozmiar (kafelki), kolor na mapie, komin (piksele) albo null]
const BUILDINGS := {
	"tavern": [Vector2i(13, 11), Vector2i(12, 7), Color("a83e30"), Vector2(148, 6)],
	"chief_house": [Vector2i(28, 6), Vector2i(8, 6), Color("43608a"), Vector2(100, 6)],
	"warehouse": [Vector2i(41, 7), Vector2i(8, 6), Color("86603a"), null],
	"smithy": [Vector2i(12, 27), Vector2i(7, 6), Color("4b4f63"), Vector2(88, 6)],
	"shop": [Vector2i(40, 27), Vector2i(8, 6), Color("2f6f73"), null],
}
## Wylot komina na grafice dachu (piksele od lewego górnego rogu).
const CHIMNEYS := {"tavern": Vector2(193, 4), "chief_house": Vector2(27, 4), "smithy": Vector2(129, 4),
		"lodge": Vector2(136, 4), "sage_hut": Vector2(17, 6), "guild": Vector2(168, 4)}
const BUILDING_NAMES := {"tavern": "Karczma", "chief_house": "Dom sołtysa", "warehouse": "Magazyn",
		"smithy": "Kuźnia", "shop": "Sklep", "barracks": "Koszary", "lodge": "Chatka myśliwych",
		"sage_hut": "Chata mędrca", "guild": "Gildia poszukiwaczy przygód", "infirmary": "Lecznica zielarki",
		"chapel": "Kaplica", "houses": "Chaty osadników", "market": "Targowisko", "bathhouse": "Łaźnia",
		"armory": "Warsztat płatnerza", "jeweler": "Chata jubilera"}
## Koszary za południową bramą i chatka myśliwych za palisadą na północnym wschodzie.
const BARRACKS_POS := Vector2i(38, 43)
const BARRACKS_SIZE := Vector2i(12, 7)
const BARRACKS_COLOR := Color("6e5640")
const LODGE_POS := Vector2i(56, 2)
const LODGE_SIZE := Vector2i(8, 6)
const LODGE_COLOR := Color("5d6b34")
## Chata mędrca na uboczu (północny zachód) i gildia przy drodze od południowej bramy.
const SAGE_POS := Vector2i(1, 2)
const SAGE_SIZE := Vector2i(8, 6)
const SAGE_COLOR := Color("54407a")
const GUILD_POS := Vector2i(18, 43)
const GUILD_SIZE := Vector2i(12, 7)
const GUILD_COLOR := Color("a82e40")
const CONSTRUCTION_STAGES := 4
const INFIRMARY_REGEN := 0.03
## Wysokość platformy wieży palisady nad jej podstawą (piksele) - tam stoi łucznik.
const TOWER_PLATFORM := -44.0
## Zadanie sołtysa, po którym można u niego zlecać budowy.
const UNLOCK_QUEST := "village_help"
## Budowy zlecane u sołtysa (okno budowy): miejsce, koszt w surowcach (z plecaka i magazynu),
## czas budowy (odpoczynek w karczmie kończy ją od razu).
const PROJECTS := {
	"barracks": {"pos": BARRACKS_POS, "size": BARRACKS_SIZE, "color": BARRACKS_COLOR,
			"time": 180.0, "art": "construction", "cost": {"wood": 80, "stone": 80},
			"description": "Za południową bramą. Ostoja dostanie własnych żołnierzy - ćwiczą na placu, a łucznicy obsadzą wieże palisady i strzelają do potworów pod osadą.",
			"start_line": "Zaczynamy budowę koszar! Zajrzyj za południową bramę.",
			"done_line": "Koszary gotowe! Ostoja ma wreszcie własne wojsko!",
			"banner": "Koszary zbudowane!
Ostoja ma własne wojsko"},
	"lodge": {"pos": LODGE_POS, "size": LODGE_SIZE, "color": LODGE_COLOR,
			"time": 150.0, "art": "construction_lodge", "cost": {"wood": 50, "stone": 20},
			"description": "Za palisadą na północnym wschodzie. Trzech myśliwych poluje i znosi do magazynu skóry i mięso.",
			"start_line": "Budujemy chatkę myśliwych! Za palisadą, na północnym wschodzie.",
			"done_line": "Chatka myśliwych gotowa! Będzie co jeść i czym handlować.",
			"banner": "Chatka myśliwych zbudowana!
Trzech myśliwych rusza na łowy"},
	"sage_hut": {"pos": SAGE_POS, "size": SAGE_SIZE, "color": SAGE_COLOR,
			"time": 160.0, "art": "construction_sage", "cost": {"wood": 60, "stone": 30},
			"description": "Na uboczu za palisadą, na północnym zachodzie. Zamieszka w niej mędrzec ze swoimi księgami.",
			"start_line": "Stawiamy chatę dla mędrca! Na uboczu, za palisadą od północnego zachodu.",
			"done_line": "Chata mędrca gotowa. Ponoć już ślęczy nad księgami.",
			"banner": "Chata mędrca zbudowana!\nMędrzec zgłębia swoje księgi"},
	"guild": {"pos": GUILD_POS, "size": GUILD_SIZE, "color": GUILD_COLOR,
			"time": 220.0, "art": "construction_guild", "cost": {"wood": 100, "stone": 100},
			"description": "Przy drodze od południowej bramy. Siedziba poszukiwaczy przygód z tablicą ogłoszeń przed wejściem.",
			"start_line": "Budujemy gildię poszukiwaczy przygód! Przy drodze od południowej bramy.",
			"done_line": "Gildia otwarta! Poszukiwacze przygód już oblegają tablicę ogłoszeń.",
			"banner": "Gildia poszukiwaczy przygód zbudowana!\nTablica ogłoszeń czeka na zlecenia"},
	# budowle bez wnętrza (grafika z zewnątrz) - "fit": plac budowy dopasowany do ich rozmiaru
	"infirmary": {"pos": Vector2i(19, 35), "size": Vector2i(5, 4), "color": Color("4f8a4a"), "fit": true,
			"time": 150.0, "art": "construction_lodge", "cost": {"wood": 60, "stone": 40},
			"description": "W południowo-zachodnim kącie osady, za kuźnią. Za palisadą szybciej odzyskasz zdrowie i manę (3% na sekundę), a zielarka sprzeda wielkie mikstury i uwarzy z dzikich ziół mikstury wzmacniające.",
			"start_line": "Budujemy lecznicę! W kącie za kuźnią.",
			"done_line": "Lecznica gotowa. Ranni wreszcie mają gdzie leżeć.",
			"banner": "Lecznica zielarki zbudowana!\nW osadzie szybciej wracasz do sił"},
	"chapel": {"pos": Vector2i(35, 27), "size": Vector2i(5, 4), "color": Color("b8a46a"), "fit": true,
			"time": 180.0, "art": "construction_lodge", "cost": {"wood": 50, "stone": 80},
			"description": "Przy drodze do bramy południowej, obok sklepu. Kapłan za datek udzieli błogosławieństwa: +10% doświadczenia albo +5% obrażeń na 20 minut.",
			"start_line": "Stawiamy kaplicę! Przy drodze do południowej bramy.",
			"done_line": "Kaplica stoi. Ludzie znów mają gdzie się modlić.",
			"banner": "Kaplica zbudowana!\nKapłan udziela błogosławieństw"},
	"houses": {"pos": Vector2i(38, 34), "size": Vector2i(8, 4), "color": Color("9a7a4a"), "fit": true,
			"time": 200.0, "art": "construction_lodge", "cost": {"wood": 100, "stone": 50},
			"description": "W obozie uchodźców. Namioty zamienią się w chaty, a wdzięczni osadnicy co 5 minut wpłacą trochę złota.",
			"start_line": "Budujemy chaty dla uchodźców! Koniec spania pod płótnem.",
			"done_line": "Chaty gotowe! Uchodźcy mają wreszcie dach nad głową.",
			"banner": "Chaty osadników zbudowane!\nOsadnicy dzielą się zarobkiem"},
	"market": {"pos": Vector2i(45, 17), "size": Vector2i(5, 4), "color": Color("c28a3a"), "fit": true,
			"time": 140.0, "art": "construction_lodge", "cost": {"wood": 80, "stone": 20},
			"description": "Przy rynku, obok magazynu. Zjedzie się wędrowny kupiec z rzadkim towarem - doskonałymi kamieniami, wielkimi miksturami - zmienianym co 10 minut.",
			"start_line": "Szykujemy miejsce na targowisko! Przy rynku, obok magazynu.",
			"done_line": "Targowisko gotowe! Już ktoś zajechał wozem.",
			"banner": "Targowisko zbudowane!\nWędrowny kupiec rozłożył towar"},
	"bathhouse": {"pos": Vector2i(49, 29), "size": Vector2i(5, 4), "color": Color("6a8aa8"), "fit": true,
			"time": 140.0, "art": "construction_lodge", "cost": {"wood": 60, "stone": 30},
			"description": "Na wschodzie osady, obok sklepu. Po odpoczynku w karczmie będziesz Wypoczęty: +2 zdrowia i +1 many na sekundę, +5% szybkości ruchu przez 10 minut.",
			"start_line": "Budujemy łaźnię! Na wschodzie, obok sklepu.",
			"done_line": "Łaźnia gotowa. Gorąca woda czeka!",
			"banner": "Łaźnia zbudowana!\nPo odpoczynku jesteś Wypoczęty"},
	"armory": {"pos": Vector2i(23, 25), "size": Vector2i(4, 3), "color": Color("5a5f75"), "fit": true,
			"time": 160.0, "art": "construction_lodge", "cost": {"wood": 40, "stone": 60, "iron_ore": 10},
			"description": "Obok kuźni. Kowal otworzy warsztat rzemiosła premii: przerzut wartości, przekucie, usuwanie i dodawanie premii, ulepszanie rzadkości (za złoto i trofea potworów) oraz runy z lochów.",
			"start_line": "Rozbudowujemy kuźnię o warsztat płatnerza!",
			"done_line": "Warsztat gotowy. Kowal już ostrzy narzędzia.",
			"banner": "Warsztat płatnerza zbudowany!\nKowal przekuwa przedmioty"},
	# po zadaniu "Pierwszy klejnot" (Gems) jubiler Dobromir przeprowadza się z Orlej Przełęczy
	"jeweler": {"pos": Vector2i(26, 31), "size": Vector2i(5, 4), "color": Color("3f8f9a"), "fit": true,
			"time": 170.0, "art": "construction_lodge", "cost": {"wood": 60, "stone": 80, "iron_ore": 15},
			"requires_quest": "jeweler_gem",
			"description": "Między kuźnią a drogą do bramy południowej. Jubiler Dobromir przeprowadzi się tu z Orlej Przełęczy - osadzi i połączy kamienie, a w nowym warsztacie także przeszlifuje kamień (nowe premie za złoto).",
			"start_line": "Stawiamy chatę dla jubilera! Dobromir już pakuje narzędzia.",
			"done_line": "Chata jubilera gotowa! Dobromir zjechał z gór z całym warsztatem.",
			"banner": "Chata jubilera zbudowana!\nDobromir przeprowadził się do Ostoi"},
}
## Podatek osadników (gdy stoją chaty): co tyle sekund i ile złota (rośnie z poziomem postaci).
const TAX_TIME := 300.0
const TAX_GOLD := 15
const TAX_PER_LEVEL := 4
## Wędrowny kupiec: co tyle sekund nowy towar, ile pozycji i z czego losuje.
const MERCHANT_ROTATION := 600.0
## (kamienie zaklinające są tylko w lochach Watry - kupiec ich nie sprzedaje).
const MERCHANT_STOCK := 4
const MERCHANT_POOL: Array[String] = ["greater_health_potion", "greater_mana_potion", "guard_horn"]
const LINES_ZERCA: Array[String] = ["Dopóki płonie ogień, Ostoja trwa.", "Perunie, czuwaj nad nami.",
		"Watra słyszy każdą ofiarę.", "Ogień pamięta tych, którzy go strzegli."]
const LINES_JEWELER: Array[String] = ["Każdy kamień ma swoją duszę.", "Szlif to cierpliwość, nie siła.",
		"W górach wiało, tu przynajmniej ciepło od Watry.", "Rubin do zdrowia, szafir do many - pamiętaj!"]
const LINES_HERBALIST: Array[String] = ["Rana się goi, gdy się ją czyści.", "Rumianek, babka, krwawnik - na wszystko coś rośnie.",
		"Leż spokojnie, zaraz zmienię opatrunek."]
const LINES_PRIEST: Array[String] = ["Światło nie opuściło Ostoi.", "Módlmy się za tych, którzy nie dotarli.",
		"Każdy, kto tu przychodzi, jest bezpieczny."]
const LINES_TRAVELER: Array[String] = ["Towary z dalekich krain!", "Takie kamienie tylko u mnie!",
		"Za tydzień ruszam dalej - kupuj, póki jestem!"]
## Plac ćwiczeń (kukły) tuż obok koszar i plac musztry przed nimi - środki w kafelkach.
const TRAINING_YARD := Vector2(55.4, 46.4)
const DRILL_SQUARE := Vector2(45.0, 53.6)
## Nieśmiertelna kukła do ćwiczeń i testów - obok placu ćwiczeń (stoi od początku gry).
const PRACTICE_DUMMY := Vector2(55.0, 51.6)
const TRAINING_DUMMY := preload("res://scenes/training_dummy.tscn")
## Miejsca przy chatce myśliwych (kafelki osady).
const LODGE_SPOTS := {
	"door": Vector2(60.0, 8.9),
	"butcher_rack": Vector2(62.4, 10.9), "butcher": Vector2(61.2, 11.1),
	"hide_rack": Vector2(57.6, 11.6), "hide": Vector2(58.8, 11.8),
	"bench_table": Vector2(63.4, 13.6), "bench": Vector2(62.2, 13.8),
	"shoot": Vector2(60.8, 16.3), "target": Vector2(65.0, 16.3),
	"smokehouse": Vector2(54.4, 7.6), "smoke": Vector2(55.8, 7.9),
	"warehouse": Vector2(45.1, 13.9),
}
## Ścieżka od drzwi chatki do wschodniej bramy (kafelki osady).
const LODGE_PATH: Array[Vector2] = [Vector2(60.0, 8.9), Vector2(60.2, 14.0), Vector2(59.2, 19.0), Vector2(58.4, 22.8)]
const HUNTER_SCENE := preload("res://scenes/hunter.tscn")
const HUNTER_SHEETS := ["hunter_b", "hunter_c", "hunter_d"]

## Pokoje gościnne w karczmie - ściany działowe w pikselach dawnej karczmy 192x112 (TAVERN_BASE);
## w grze skalowane do rozmiaru podłogi. Te same liczby rysuje tools/village_art.py (ROOM_*).
## Te same liczby rysuje tools/village_art.py (ROOM_X, ROOM_SPLIT_Y, ROOM_DOORS).
const TAVERN_ROOM_WALLS: Array[Rect2] = [
	Rect2(136, 0, 4, 40), Rect2(136, 58, 4, 26), Rect2(136, 102, 4, 5), Rect2(140, 64, 48, 10),
]
const TAVERN_BASE := Vector2(192, 112)

## Ścieżki z ubitej ziemi: [punkty (kafelki), promień, czy także poza palisadą].
const PATHS := [
	[[Vector2(-2, 23.5), Vector2(68, 23.5)], 1.5, false, true],  # droga przez osadę
	[[Vector2(33, 24), Vector2(33.5, 29), Vector2(32.6, 35), Vector2(33, 41)], 1.2, false, true],
	[[Vector2(33, 40), Vector2(33.2, 46), Vector2(35.5, 50.9), Vector2(45, 50.9)], 1.1, true],  # do koszar
	[[Vector2(15.5, 34.0), Vector2(22, 34.1), Vector2(28, 34.0), Vector2(33, 34.4), Vector2(39, 34.3), Vector2(44.5, 34.6)], 1.0, false],
	[[Vector2(19, 18), Vector2(19.2, 22)], 1.0, false],
	[[Vector2(32, 12), Vector2(32, 22.5)], 1.2, false, true],  # plac -> droga
	[[Vector2(45, 13), Vector2(45, 18), Vector2(44.5, 22)], 1.0, false],
	[[Vector2(51.5, 24), Vector2(54.6, 26.5), Vector2(55.3, 29.5)], 0.9, false],
	# udeptane place stref: rynek, obóz uchodźców, skład drewna, zagroda; pod kuźnią żwir
	[[Vector2(36.4, 19.6), Vector2(42.6, 19.6)], 1.6, false],
	[[Vector2(36.6, 37.6), Vector2(44.6, 37.9)], 1.7, false],
	[[Vector2(10.6, 15.4), Vector2(12.4, 18.0)], 1.3, false],
	[[Vector2(51.6, 16.0), Vector2(54.4, 17.9)], 1.3, false],
	[[Vector2(20.4, 32.0), Vector2(25.8, 32.4)], 1.5, false, true],
]
## Podwórza za palisadą: ubita ziemia, a trawa tylko kępami (szum) i pod samą palisadą.
const YARD_GRASS_NOISE := 0.18
const YARD_GRASS_EDGE := 0.87
## Placyk przed domem sołtysa z kapliczką odrodzenia.
const PLAZA := Vector2(32.0, 15.4)
const PLAZA_RADIUS := 3.2
## Watra: wielki ogień na środku placu (od niej nazwa gry), kapliczka odrodzenia stoi obok. Tragarze znoszą
## do Watry drewno z magazynu; po każdym naręczu i po każdej ofierze gracza (Boons.ember) ogień buchnie.
## Im wyższy poziom Watry, tym jaśniej i szerzej świeci.
const WATRA_POS := Vector2(32.0, 16.6)
const WATRA_SHRINE := Vector2(38.0, 16.6)
const WATRA_FPS := 7.0
const LINES_FIREWOOD: Array[String] = [
	"Dopóki płonie ogień, Ostoja trwa.",
	"Drewno dla Watry! Nie może przygasnąć.",
	"Ogień trzyma potwory z dala. Noszę dalej.",
]

const LINES_GUARD: Array[String] = [
	"Trzymaj się blisko palisady, wędrowcze.",
	"Z wieży widać ich ogniska. Coraz bliżej...",
	"Póki stoją te mury, jest nadzieja.",
	"Wczoraj odparliśmy trzy szturmy.",
	"Gobliny to dopiero przednia straż. Za nimi idzie coś gorszego.",
	"Karawana powinna niedługo przejechać. Pilnuj drogi.",
]
const LINES_PLANKS: Array[String] = [
	"Te deski same się nie przyniosą!",
	"Wschodnia ściana znów puszcza...",
	"Jeszcze jedna i odpocznę. Chyba.",
]
const LINES_BARRELS: Array[String] = [
	"Ludzie muszą mieć co pić. I w co wierzyć.",
	"Ciężka ta beczka jak goblińskie grzechy.",
	"Karczmarz krzyczy, że piwo się kończy.",
]
const LINES_UNLOADER: Array[String] = [
	"Wóz pełny, a sklep pusty. Do roboty!",
	"Worki z mąką, skrzynie z mieczami... co jeszcze?",
	"Kupiec mówi, że to ostatni wóz z południa.",
]
const LINES_SMITH: Array[String] = [
	"Każdy miecz to jedno życie więcej.",
	"Żelaza mało, a potworów coraz więcej.",
	"Nie przeszkadzaj, ostrze stygnie!",
	"Dobrze, że mam wreszcie dach nad kowadłem.",
]
const LINES_HUNTER: Array[String] = [
	"Potwory wypłoszyły całą zwierzynę.",
	"Widziałem w lesie ślady większe niż goblińskie. Dużo większe.",
	"Na południowym wschodzie wyją wilki. Las jest tam ciemny jak noc.",
	"Przynieś mi wilcze skóry, a dobrze zapłacę.",
	"Ze skór będą płaszcze na zimę. Jeśli dożyjemy.",
	"Na północnym wschodzie i południowym zachodzie pasą się jelenie, sarny i dziki. Podchodź cicho!",
	"Skóry jeleni i dzików skupię od ręki. A poroże to dopiero trofeum!",
]
const LINES_BUILDER: Array[String] = [
	"Ta dziura sama się nie załata.",
	"Dawajcie te deski, szybciej!",
]
const LINES_MERCHANT: Array[String] = [
	"Mikstury! Kto dziś walczy, ten jutro żyje!",
	"Serca goblinów? Alchemicy zapłacą krocie.",
	"Złoto nic nie znaczy, gdy świat płonie... ale biorę.",
]
const LINES_BARKEEP: Array[String] = [
	"Siadaj, zjedz coś. Las nigdzie nie ucieknie.",
	"Dawniej grali tu bardowie. Teraz tylko wiatr.",
	"Pokoje na górze... znaczy z tyłu. Czyste, prawie.",
]
const LINES_PATRON: Array[String] = [
	"Za Ostoję! Hep!",
	"Jeszcze jeden kufelek i idę na gobliny.",
	"Dobre to piwo. Lepsze niż wczorajsze.",
	"Słyszałeś, co wyje nocą w lesie?",
]
const LINES_STOREKEEPER: Array[String] = [
	"Każda kłoda się przyda. Palisada sama się nie załata.",
	"Policzyłem wszystko dwa razy. Niczego nie brakuje.",
	"Kamień trzymam z lewej, drewno z prawej. Porządek musi być.",
]
const LINES_CHIEF: Array[String] = [
	"Ostoja przetrwa, jeśli każdy dołoży swoją cegiełkę.",
	"Potrzebujemy żołnierzy, nie tylko murów.",
	"Spójrz na tych ludzi. Dla nich warto walczyć.",
]
const LINES_CHIEF_BUILT: Array[String] = [
	"Koszary stoją! Wreszcie mamy własne wojsko.",
	"Słyszysz musztrę? Najpiękniejszy dźwięk od lat.",
]
const LINES_CONSTRUCTION: Array[String] = [
	"Jeszcze trochę i będzie gotowe!",
	"Podaj młotek! Nie ten, ten drugi!",
	"Krzywo? Nie krzywo, tylko po góralsku.",
]
const LINES_TRAINER: Array[String] = [
	"Raz! Dwa! Raz! Dwa!",
	"Ta kukła wygląda jak mój teść.",
	"Jeszcze sto cięć i odpoczynek.",
]
const LINES_SERGEANT: Array[String] = ["Baczność!", "W lewo zwrot!", "Naprzód marsz!", "W tył zwrot!", "Naprzód marsz!", "W lewo zwrot!"]
const LINES_SAGE: Array[String] = [
	"Hmm... ciekawe, bardzo ciekawe...",
	"Gwiazdy mówią o nadchodzącej burzy.",
	"Ta księga ma trzysta lat. Albo czterysta.",
	"Cisza, proszę. Myśli lubią spokój.",
	"Gdzie ja położyłem okulary...",
]
const LINES_CLERK: Array[String] = [
	"Gildia przyjmuje każdego, kto ma odwagę.",
	"Nowe zlecenia wiszą na tablicy przed wejściem.",
	"Nazwisko? Miejsce urodzenia? Ulubiona broń?",
]
const LINES_ADVENTURER: Array[String] = [
	"Patrz, nagroda za łeb wodza goblinów!",
	"Ktoś widział żaboludzi bliżej mostu?",
	"Ja biorę to z wilkami. Ty bierz bagna.",
	"Kiedyś to ja będę na liście gończym... jako łowca!",
	"Tu piszą, że płacą w złocie. Prawdziwym złocie!",
]
const LINES_LODGE_HUNTER: Array[String] = [
	"Ciii... zwierzyna ma lepszy słuch niż ty.",
	"Dziś na kolację będzie dziczyzna!",
	"Strzała musi lecieć prosto jak myśl.",
	"Dym z wędzarni czuć aż w karczmie.",
	"Jeleń z północnego wschodu? Taki okaz trafia się raz na rok.",
]
const LINES_ARMS: Array[String] = [
	"Nowe miecze dla koszar, prosto z kuźni!",
	"Kolczugi ciężkie, ale chłopaki się ucieszą.",
]
const LINES_VILLAGER: Array[String] = [
	"Słyszałeś? Upadło kolejne miasto na południu.",
	"Mówią, że na północy z ziemi wstają umarli.",
	"Wilkołaki porwały kupców z Brzeziny...",
	"Dzieci boją się zasnąć.",
	"Musimy się trzymać razem, inaczej zginiemy.",
	"Pamiętam, jak ten las był bezpieczny...",
	"Dziękujemy, że walczysz za nas.",
]

const LINES_REFUGEE: Array[String] = [
	"Spalili nam wieś... Uciekliśmy tylko z tym, co na grzbiecie.",
	"Tu przynajmniej jest palisada. I ludzie z bronią.",
	"Mój syn został w Brzezinie. Może jeszcze dotrze...",
	"Każdej nocy ktoś nowy przychodzi bramą.",
	"Ciepła strawa i dach nad głową - więcej nie trzeba.",
]
const LINES_BARD: Array[String] = [
	"Zaśpiewam o tobie, wędrowcze - jeśli przeżyjesz!",
	"Muzyka to jedyne, czego potwory nam nie odbiorą.",
	"Hej, w Ostoi ogień płonie, nikt nie zginie w naszej stronie...",
]
const LINES_CHILD: Array[String] = ["Złap mnie!", "Nie dogonisz!", "Hihi!", "Jak dorosnę, będę rycerzem!"]
const LINES_GARDENER: Array[String] = [
	"Rzepa w tym roku obrodzi. Byle gobliny nie wydeptały.",
	"Ludzi coraz więcej, a ziemi tyle samo...",
	"Kapusta, marchew, rzepa - wszystko się przyda.",
]
const LINES_WOODCUTTER: Array[String] = [
	"Drewno na opał, deski na palisadę - roboty nie brakuje.",
	"Do lasu już nie chodzę sam. Za dużo tam oczu.",
]
const LINES_MARKET: Array[String] = [
	"Świeże jabłka! Prosto z sadu!",
	"Chleb! Ciepły chleb!",
	"Garnki, płótno, narzędzia - wszystko, co potrzebne!",
	"Za dwa miedziaki oddam taniej, bo dla uchodźców.",
]
const LINES_WATER: Array[String] = ["Woda dla obozu...", "Ciężkie to wiadro.", "Studnia nas wszystkich żywi."]
const LINES_SWEEPER: Array[String] = ["Błoto i błoto... Kto to wszystko naniósł?", "Wycieraj buty, wędrowcze!"]
const LINES_DRUNK: Array[String] = ["Hik!", "Jeszcze jeden kufelek... hik!", "Gdzie ja mieszkam?",
		"Ja nie piłem, ja tylko... hik!", "Gobliny? Dawać je tu! Hik!"]
const LINES_CHEER: Array[String] = ["Hurra!", "Niech żyje bohater!", "Wiwat!", "Pokonany! Słyszeliście?!", "Chwała!"]
## Święto po pokonaniu bossa: jak długo wiszą girlandy (s).
const CELEBRATION_TIME := 600.0

## Kuźnia pod wiatą (kafelki układu): podstawa wiaty i stanowiska kowala.
const FORGE_ROOF_BASE := Vector2(22.4, 33.6)
const FORGE := {"furnace": Vector2(23.4, 31.8), "anvil": Vector2(24.6, 33.45), "quench": Vector2(20.8, 32.3),
		"crate": Vector2(19.6, 33.0)}
## Słupy wiaty (osobne grafiki - każdy zasłania tylko to, co stoi za nim): podstawa względem FORGE_ROOF_BASE.
const FORGE_POSTS := {"forge_post_l": Vector2(-2.136, -1.091), "forge_post_m": Vector2(0.045, 0.0),
		"forge_post_r": Vector2(2.205, -1.091)}
## Pod dachem (kafelki układu) - gdy gracz tam wejdzie, dach robi się przezroczysty.
const FORGE_UNDER := Rect2(20.0, 28.6, 5.8, 5.2)

## Zagroda ze świniami (kafelki układu): prostokąt ogrodzenia, w nim szałas, koryto i błoto.
const PIG_PEN := Rect2(50.8, 13.8, 4.4, 5.6)
const PIG_SCENE := preload("res://scripts/livestock.gd")
## Obszar zabawy dzieci w berka (obóz uchodźców i okolice południowej drogi).
const PLAY_AREA := Rect2(26.0, 35.6, 19.0, 3.8)

## Stosy surowców przy magazynie (drewno w lewej kolumnie, kamień w prawej)
## i ile surowca przypada na jeden poziom stosu.
const WOOD_PILE_SPOTS: Array[Vector2] = [Vector2(37.2, 13.0), Vector2(37.2, 11.2), Vector2(37.2, 9.4)]
const STONE_PILE_SPOTS: Array[Vector2] = [Vector2(39.3, 13.0), Vector2(39.3, 11.2), Vector2(39.3, 9.4)]
const PILE_PER_STAGE := 10
const PILE_STAGES := 4

var origin_tile := Vector2i.ZERO
## Obszar osady (z miejscem na koszary) w pikselach świata.
var rect := Rect2()
var spawn_point := Vector2.ZERO
## Kolory komórek na mapie i znaczniki (ołtarz, kupiec, sołtys).
var map_cells := {}
var map_markers: Array[Dictionary] = []
var buildings := {}
## Stan koszar: "none" (puste pole), "building" (plac budowy) albo "built".
## Budowy: id -> {"state": "building"/"built", "left": sekundy, "nodes": węzły do usunięcia, "sprite": rusztowanie}.
var _projects := {}
## Tablica ogłoszeń przed gildią (później dostanie zlecenia).
var notice_board: Sprite2D
## Szlaki z bram do łowisk (piksele świata; 0 - prawy górny róg, 1 - lewy dolny) i obszary łowisk.
var hunting_routes: Array = [[], []]
var hunting_areas: Array[Rect2] = []

var _ground: TileMapLayer
var _floors: Node2D
var _entities: Node2D
var _player: Player
var _rng: RandomNumberGenerator
var _inside := {}
## Szum kęp trawy na podwórzach (stały - osada wygląda tak samo przy każdym wczytaniu).
var yard_noise := FastNoiseLite.new()
var _plank_pile: Sprite2D
var _wood_piles: Array[Sprite2D] = []
var _stone_piles: Array[Sprite2D] = []
var _planks := 1
var _textures := {}
## Miejsca zajęte przez rekwizyty (kafelki układu) - ozdoby omijają je, ścieżki, budynki i drzwi.
var _spots: Array[Vector2] = []
## Namioty obozu uchodźców (znikają, gdy staną chaty), kowal (przekuwanie z warsztatem płatnerza),
## wędrowny kupiec targowiska i liczniki podatku i nowego towaru.
var _refugee_tents: Array[Node] = []
var _smith: Npc
var _traveler: Npc
var _tax_timer := TAX_TIME
var _watra: Sprite2D
var _watra_glow: Sprite2D
var _watra_sparks: CPUParticles2D
var _watra_time := 0.0
var _watra_flare := 0.0
var _watra_ember := -1
var _forge_roof: Sprite2D
var _celebration: Array[Node] = []
var _celebration_left := 0.0
var _fireworks := 0
## Święto (wydarzenie w świecie - EventSite "festival"): ozdoby, kolorowe światła, tańce, fajerwerki; podróżnicy przy Watrze.
var _festival: Array[Node] = []
var _festival_left := 0.0
var _festival_dance := 0.0
var _festival_fire := 0.0
const LINES_FESTIVAL: Array[String] = ["Hej, hej, do tańca!", "Niech Watra płonie!", "Zagrajcie coś skocznego!",
		"Dziś świętujemy!", "Kto mnie zaprosi do tańca?", "Miodu! Więcej miodu!", "Dopóki płonie ogień, Ostoja trwa!"]
var _firework_timer := 0.0
var _rotation_timer := MERCHANT_ROTATION
## Wieże palisady (na platformach stają łucznicy z koszar).
var _tower_sprites: Array[Sprite2D] = []
var _chief: Npc
## Węzły placu budowy i koszar (usuwane / dodawane przy zmianie stanu).
var _butcher_rack: Sprite2D
var _archery_target: Sprite2D
var _hunters: Array[Npc] = []
var _corner_taken: Array[bool] = [false, false]
var _drill: Array[Npc] = []
var _drill_home: Array[Vector2] = []
var _sergeant: Npc
var _drill_step := 0
var _drill_timer := 0.0


func build(origin: Vector2i, ground: TileMapLayer, floors: Node2D, entities: Node2D, player: Player, rng: RandomNumberGenerator) -> void:
	origin_tile = origin
	rect = Rect2(Vector2(origin * TILE), Vector2(SIZE * TILE))
	_ground = ground
	_floors = floors
	_entities = entities
	_player = player
	_rng = rng
	add_to_group("settlement")
	set_process(false)

	_build_ground()
	_build_palisade()
	_build_buildings()
	_build_interiors()
	_build_yard()
	_build_training_dummy()
	_build_decorations()
	_build_npcs()
	set_process(true)
	if Engine.has_meta("celebrate"):
		Engine.remove_meta("celebrate")
		celebrate.call_deferred()


## Czy komórka (w kafelkach świata) należy do terenu osady (z polem pod koszary).
func has_cell(cell: Vector2i) -> bool:
	return Rect2i(origin_tile, SIZE).has_point(cell)


## Lecznica: za palisadą zdrowie i mana wracają o INFIRMARY_REGEN maksimum na sekundę.
func regen_bonus(world_pos: Vector2) -> float:
	if project_state("infirmary") != "built":
		return 0.0
	return INFIRMARY_REGEN if is_inside_palisade(Vector2i((world_pos / TILE).floor())) else 0.0


## Czy komórka (w kafelkach świata) leży za palisadą.
## Miejsca w Ostoi, między którymi spacerują inni podróżnicy (plac, Watra, karczma, sklep, gildia), w pikselach.
func traveler_points() -> Array[Vector2]:
	# święto - wszyscy tańczą wokół Watry
	if is_festival():
		var ring: Array[Vector2] = []
		for i in 10:
			ring.append(_px(WATRA_POS + Vector2.from_angle(TAU * i / 10.0) * Vector2(4.2, 3.0)))
		return ring
	var spots: Array[Vector2] = [WATRA_POS + Vector2(3.5, 2.5), WATRA_POS + Vector2(-2.0, 3.6), Vector2(19.0, 19.6),
			Vector2(30.0, 22.5), Vector2(36.0, 22.0), Vector2(44.0, 34.4), Vector2(42.0, 21.0)]
	if project_state("guild") == "built":
		spots.append_array([Vector2(21.4, 53.8), Vector2(25.0, 52.6)])
	var result: Array[Vector2] = []
	for spot in spots:
		result.append(_px(spot))
	return result


func is_inside_palisade(cell: Vector2i) -> bool:
	return _inside.has(cell - origin_tile)


# ---------------------------------------------------------------- teren i palisada
## Odległość od środka w "promieniach" palisady: < 1 w środku, > 1 na zewnątrz.
## `tile_pos` w kafelkach świata względem lewego górnego rogu osady.
static func outline_distance(tile_pos: Vector2) -> float:
	var d := (tile_pos / SCALE - CENTER) / RADII
	var r := pow(pow(absf(d.x), ROUNDNESS) + pow(absf(d.y), ROUNDNESS), 1.0 / ROUNDNESS)
	var angle := atan2(d.y, d.x)
	# lekkie falowanie, żeby owal nie był idealny
	return r / (1.0 + 0.025 * sin(3.0 * angle + 0.7) + 0.015 * sin(5.0 * angle + 2.1))


func _build_ground() -> void:
	yard_noise.seed = 4242
	yard_noise.frequency = 0.09
	for y in SIZE.y:
		for x in SIZE.x:
			if outline_distance(Vector2(x + 0.5, y + 0.5)) < 1.0:
				_inside[Vector2i(x, y)] = true
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var inside := _inside.has(cell)
			var kind := _path_kind(Vector2(x + 0.5, y + 0.5) / SCALE, inside)
			var edge := outline_distance(Vector2(x + 0.5, y + 0.5))
			# pod palisadą pas ubitej ziemi, żeby pale stały na gruncie, a nie wyrastały z trawy
			var on_path := kind != 0 or absf(edge - 1.0) < WALL_DIRT
			if not inside and not on_path:
				continue
			# podwórza: ubita ziemia, trawa kępami i pod palisadą
			var grassy := inside and not on_path and (yard_noise.get_noise_2d(x, y) > YARD_GRASS_NOISE or edge > YARD_GRASS_EDGE)
			on_path = on_path or inside and not grassy
			var tile: Vector2i = DIRT_TILES.pick_random() if on_path else YARD_TILES.pick_random()
			var cobble := inside and (kind == 2 or (Vector2(x + 0.5, y + 0.5) / SCALE).distance_to(PLAZA) <= PLAZA_RADIUS + 0.9)
			if cobble:
				tile = COBBLE_TILE
			_ground.set_cell(origin_tile + cell, 0, tile)
			map_cells[origin_tile + cell] = MAP_COBBLE if cobble else MAP_DIRT if on_path else MAP_YARD


func _on_path(point: Vector2, inside: bool) -> bool:
	if inside and point.distance_to(PLAZA) <= PLAZA_RADIUS:
		return true
	return _path_kind(point, inside) != 0


## 0 - poza ścieżkami, 1 - ubita ziemia, 2 - żwir (główna droga, plac, kuźnia).
func _path_kind(point: Vector2, inside: bool) -> int:
	var kind := 0
	for path: Array in PATHS:
		if not inside and not path[2]:
			continue
		var points: Array = path[0]
		for i in points.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(point, points[i], points[i + 1])
			if closest.distance_to(point) <= path[1]:
				if path.size() > 3 and path[3]:
					return 2
				kind = 1
	return kind


func _is_gate(cell: Vector2i) -> bool:
	return _is_gate_point(_layout(cell))


## Czy punkt układu leży w którejś bramie.
func _is_gate_point(p: Vector2) -> bool:
	if p.y >= GATE_ROWS.x and p.y < GATE_ROWS.y + 1:
		return true
	return p.y > CENTER.y and p.x >= GATE_COLUMNS.x and p.x < GATE_COLUMNS.y + 1


## Środek komórki świata (względem osady) w kafelkach układu.
func _layout(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) / SCALE


## Punkt owalu palisady (kafelki układu) pod kątem `angle` w przestrzeni półosi.
func _outline_point(angle: float) -> Vector2:
	var q := CENTER + Vector2.from_angle(angle) * RADII
	return CENTER + (q - CENTER) / outline_distance(q * SCALE)


## Palisada z osobnych pali stojących gęsto wzdłuż gładkiego owalu (nie po kafelkach - bez schodków na łukach,
## a na bokach pale stoją jeden za drugim). Na łukach wieże strażnicze, przy bramach zachodniej i wschodniej
## słupy z latarnią/pochodnią, nad południową łuk z belką; fragment w naprawie ma wyłamane pale i rusztowanie.
## Kolizja to łamana wzdłuż podstawy pali (przerwana w bramach). Własny generator - nie zużywa _rng świata.
func _build_palisade() -> void:
	for cell: Vector2i in _inside:
		for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not _inside.has(cell + dir) and not _is_gate(cell):
				map_cells[origin_tile + cell] = MAP_PALISADE
				break
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(origin_tile)
	var towers: Array[Vector2] = []
	for angle in TOWER_ANGLES:
		towers.append(_px(_outline_point(angle)))
	var body := StaticBody2D.new()
	_entities.add_child(body)
	var run := PackedVector2Array()
	var gate_ends: Array[Vector2] = []  # punkty, w których palisada urywa się przy bramie
	var broken_points: Array[Vector2] = []
	var samples := 2400
	var previous := _outline_point(-PI)
	var walked := 0.0
	# start na zachodzie, w środku bramy - łamane kolizji zaczynają się i kończą na bramach
	for i in samples + 1:
		var point := _outline_point(-PI + TAU * i / samples)
		var px := _px(point)
		var delta := px - _px(previous)
		previous = point
		if _is_gate_point(point):
			if run.size() > 0:
				gate_ends.append(run[run.size() - 1])
				_palisade_collision(body, run)
				run = PackedVector2Array()
			continue
		if run.is_empty():
			gate_ends.append(px)
			run.append(px)
			walked = 0.0
		walked += delta.length()
		var step := lerpf(STAKE_STEP.x, STAKE_STEP.y, absf(delta.normalized().y))
		if walked < step:
			continue
		walked -= step
		run.append(px)
		if towers.any(func(t: Vector2) -> bool: return t.distance_to(px) < TOWER_CLEARANCE):
			continue
		var broken := point.x > CENTER.x and point.y >= BROKEN_ROWS.x and point.y < BROKEN_ROWS.y + 1
		if broken:
			broken_points.append(point)
			if rng.randf() < 0.6:
				continue
		_stake(rng, "palisade_stake_broken" if broken else "palisade_stake", px)
	if run.size() > 1:
		_palisade_collision(body, run)
	for tower in towers:
		var sprite := _prop("palisade_tower", (tower / TILE - Vector2(origin_tile)) / SCALE, Vector2(44, 10), 2)
		sprite.frame = rng.randi() % 2
		sprite.flip_h = tower.x > rect.get_center().x
		_tower_sprites.append(sprite)
		var lookout := TowerArcher.new()
		lookout.sheet = _npc_sheet("guard")
		lookout.position = Vector2(0, TOWER_PLATFORM)
		sprite.add_child(lookout)
	_build_gates(gate_ends)
	if not broken_points.is_empty():
		var middle: Vector2 = broken_points[broken_points.size() / 2]
		_prop("palisade_scaffold", middle + Vector2(-1.3, 0.2), Vector2(20, 6))
		_prop("stake_pile", middle + Vector2(-2.6, 2.2), Vector2(18, 5))
		_prop("stake_fallen", middle + Vector2(1.6, -1.4))


func _stake(rng: RandomNumberGenerator, texture_name: String, px: Vector2) -> void:
	var texture := _tex(texture_name)
	var frames := texture.get_width() / texture.get_height() if texture_name == "palisade_stake_broken" else STAKE_WEIGHTS.size()
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = frames
	sprite.frame = rng.rand_weighted(PackedFloat32Array(STAKE_WEIGHTS)) if frames == STAKE_WEIGHTS.size() else rng.randi() % frames
	sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 1.0)
	sprite.position = (px + Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.6, 0.6))).round()
	sprite.flip_h = rng.randf() < 0.5
	var shade := rng.randf_range(0.9, 1.0)
	sprite.modulate = Color(shade, shade, shade)
	_entities.add_child(sprite)


func _palisade_collision(body: StaticBody2D, run: PackedVector2Array) -> void:
	if run.size() < 2:
		return
	var segments := PackedVector2Array()
	for i in run.size() - 1:
		segments.append_array([run[i], run[i + 1]])
	var shape := CollisionShape2D.new()
	var concave := ConcavePolygonShape2D.new()
	concave.segments = segments
	shape.shape = concave
	body.add_child(shape)


## Bramy: `ends` to piksele, w których palisada urywa się przy bramie. Zachodnia i wschodnia (pionowe przerwy)
## dostają po dwa słupy z latarnią albo pochodnią, południowa - łuk z belką nad przejściem.
func _build_gates(ends: Array[Vector2]) -> void:
	var south: Array[Vector2] = []
	for end in ends:
		var p := (end / TILE - Vector2(origin_tile)) / SCALE
		if p.y > GATE_ROWS.y + 2:
			south.append(p)
			continue
		var below := p.y > ROAD_ROW
		var post := _prop("gate_post", p + Vector2(0, 0.15), Vector2(10, 5), 3)
		post.frame = 1 if below else 0
		post.flip_h = p.x > CENTER.x
		var light := _px(p) + Vector2(5.0 * (-1.0 if post.flip_h else 1.0), -22)
		_glow(light, Color(1.0, 0.65, 0.25, 0.35), Vector2(44, 36))
	if south.size() == 2:
		var middle := (south[0] + south[1]) / 2.0 + Vector2(0, 0.15)
		_prop("gate_arch", middle)
		# słupy łuku mają kolizję, przejście nie
		var half := _tex("gate_arch").get_width() / 2.0 - 12.0
		var body := StaticBody2D.new()
		body.position = _px(middle)
		for side in [-1.0, 1.0]:
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(16, 8)
			shape.shape = box
			shape.position = Vector2(side * half, -4)
			body.add_child(shape)
			_glow(_px(middle) + Vector2(side * (half - 14.0), -32), Color(1.0, 0.65, 0.25, 0.35), Vector2(40, 34))
		_entities.add_child(body)


# ---------------------------------------------------------------- budynki
func _build_buildings() -> void:
	for id: String in BUILDINGS:
		var data: Array = BUILDINGS[id]
		_add_building(id, data[0], data[1], data[2], data[3])
	var tavern: Building = buildings["tavern"]
	var room_scale := tavern.size_px / TAVERN_BASE
	for wall in TAVERN_ROOM_WALLS:
		tavern.add_wall(Rect2(wall.position * room_scale, wall.size * room_scale))


func _add_building(id: String, pos: Vector2i, size: Vector2i, map_color: Color, chimney: Variant) -> Building:
	# budynek ma rozmiar swojej grafiki: stoi pośrodku przydzielonego pola, frontem na jego dolnej krawędzi
	var floor_texture := _tex(id + "_floor")
	var footprint := Vector2(size) * TILE * SCALE
	var building := Building.new()
	building.position = _px(Vector2(pos)) + Vector2(roundf((footprint.x - floor_texture.get_width()) / 2.0),
			footprint.y - floor_texture.get_height())
	_floors.add_child(building)
	building.setup(Lang.t(BUILDING_NAMES[id]), floor_texture, _tex(id + "_roof"), _entities, _player)
	# komin na grafice dachu z PixelLab (CHIMNEYS); `chimney` mówi tylko, czy budynek dymi
	if chimney != null and CHIMNEYS.has(id):
		building.add_chimney_smoke(CHIMNEYS[id])
	buildings[id] = building
	var first := _cell(Vector2(pos))
	var last := _cell(Vector2(pos + size) - Vector2(0.01, 0.01))
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			map_cells[Vector2i(x, y)] = map_color
	return building


## Pozycja w kafelkach osady względem lewego górnego rogu budynku. `local` jest w kafelkach dawnego
## budynku (rozmiar z BUILDINGS / PROJECTS) - przeliczamy ją proporcjonalnie na podłogę obecnej grafiki.
func _in(id: String, local: Vector2) -> Vector2:
	var data: Array = [PROJECTS[id]["pos"], PROJECTS[id]["size"]] if PROJECTS.has(id) else BUILDINGS[id]
	if not buildings.has(id):
		return Vector2(data[0]) + local
	var building: Building = buildings[id]
	var px := building.position + local / Vector2(data[1]) * building.size_px
	return (px / TILE - Vector2(origin_tile)) / SCALE


## Wyposażenie wnętrz.
func _build_interiors() -> void:
	# karczma: sala z ladą i stołami, z tyłu dwa pokoje gościnne
	_prop("counter", _in("tavern", Vector2(2.6, 3.1)), Vector2(48, 6))
	for p in [Vector2(0.9, 2.0), Vector2(7.6, 2.0), Vector2(7.6, 2.9)]:
		_prop("barrel", _in("tavern", p), Vector2(10, 5))
	for p in [Vector2(2.0, 6.2), Vector2(6.6, 4.4)]:
		_prop("table", _in("tavern", p), Vector2(24, 6))
		_prop("stool", _in("tavern", p + Vector2(-1.1, 0.3)))
		_prop("stool", _in("tavern", p + Vector2(1.1, 0.3)))
	for room_bottom in [3.85, 6.62]:
		_prop("bed", _in("tavern", Vector2(11.05, room_bottom)), Vector2(18, 22))
		_prop("chest", _in("tavern", Vector2(9.5, room_bottom)), Vector2(14, 5))

	# dom sołtysa
	_prop("table", _in("chief_house", Vector2(2.4, 4.2)), Vector2(24, 6))
	_prop("stool", _in("chief_house", Vector2(1.3, 4.5)))
	_prop("shelf", _in("chief_house", Vector2(5.9, 2.4)))
	_prop("chest", _in("chief_house", Vector2(6.4, 5.4)), Vector2(14, 5))

	# magazyn
	for p in [Vector2(0.9, 2.0), Vector2(1.8, 2.0), Vector2(0.9, 3.0), Vector2(0.9, 5.4)]:
		_prop("crate", _in("warehouse", p), Vector2(12, 5))
	for p in [Vector2(6.9, 2.0), Vector2(6.0, 2.0), Vector2(6.9, 3.0), Vector2(6.9, 5.4)]:
		_prop("barrel", _in("warehouse", p), Vector2(10, 5))
	var stock := _prop("plank_pile", _in("warehouse", Vector2(2.2, 5.5)), Vector2(24, 5), 4)
	stock.frame = 3

	# kuźnia
	_prop("forge", _in("smithy", Vector2(1.8, 2.7)), Vector2(24, 8))
	_glow(_px(_in("smithy", Vector2(1.8, 2.1))), Color(1, 0.5, 0.15, 0.4), Vector2(60, 40))
	_prop("weapon_rack", _in("smithy", Vector2(5.3, 2.5)), Vector2(20, 5))
	_prop("barrel", _in("smithy", Vector2(5.6, 5.4)), Vector2(10, 5))

	# sklep
	_prop("shelf", _in("shop", Vector2(1.9, 2.4)))
	_prop("shelf", _in("shop", Vector2(6.1, 2.4)))
	_prop("counter", _in("shop", Vector2(4.0, 3.9)), Vector2(48, 6))
	_prop("barrel", _in("shop", Vector2(0.9, 5.4)), Vector2(10, 5))
	_prop("crate", _in("shop", Vector2(7.0, 5.4)), Vector2(12, 5))


# ---------------------------------------------------------------- ozdoby
## Życie osady: latarnie przy drogach, skrzynki z kwiatami i doniczki przy drzwiach, ławki i rabaty przy
## placu, kram przy sklepie, strachy na wróble, płotki i ule przy ogródkach, beczki na deszczówkę,
## pranie i buda z psem przy domu sołtysa, koty i drobiazgi na podwórkach. Każda ozdoba szuka
## wolnego miejsca w pobliżu swojego punktu (poza ścieżkami, budynkami, drzwiami i innymi rekwizytami).
const GARDENS: Array[Vector2] = [Vector2(17.4, 9.4), Vector2(20.2, 9.4), Vector2(23.0, 9.4)]


func _build_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng.randi()
	# latarnie wzdłuż drogi przez osadę, po obu stronach na zmianę
	var lamp_side := 1.0
	for x in range(6, 62, 6):
		var spot := _free_spot(Vector2(x, ROAD_ROW + 0.7 + 2.3 * lamp_side), 1.4, 1.0, rng)
		if spot.is_finite():
			_deco("deco_lamp_post", spot, Vector2(4, 3))
			_glow(_px(spot) + Vector2(4, -30), Color(1.0, 0.8, 0.45, 0.25), Vector2(48, 40))
		lamp_side = -lamp_side
	# przy drzwiach budynków: skrzynki z kwiatami, doniczki, beczka na deszczówkę za rogiem
	for id: String in BUILDINGS:
		var building: Building = buildings[id]
		var door := (building.door_outside() / TILE - Vector2(origin_tile)) / SCALE
		for side in [-1.0, 1.0]:
			var box := _free_spot(door + Vector2(2.4 * side, -0.1), 0.6, 0.9, rng, true)
			if box.is_finite():
				_deco("deco_flower_box", box, Vector2(22, 4))
		var pot := _free_spot(door + Vector2(1.3 * (1 if rng.randf() < 0.5 else -1), 0.1), 0.4, 0.5, rng, true)
		if pot.is_finite():
			_deco("deco_flower_pot", pot)
		var corner := (building.position + Vector2(building.size_px.x if rng.randf() < 0.5 else 0.0, building.size_px.y)) / TILE
		var barrel := _free_spot((corner - Vector2(origin_tile)) / SCALE + Vector2(0, 0.3), 1.2, 0.8, rng)
		if barrel.is_finite():
			_deco("deco_rain_barrel", barrel, Vector2(12, 5))
	# plac: rabaty, kamienne ławki i drogowskaz
	for i in 3:
		var bed := _free_spot(PLAZA + Vector2.from_angle(TAU * i / 3.0 + 0.6) * (PLAZA_RADIUS + 1.6), 1.0, 1.2, rng)
		if bed.is_finite():
			_deco("deco_flower_bed", bed, Vector2(28, 8))
	for side in [-1.0, 1.0]:
		var bench := _free_spot(PLAZA + Vector2(3.6 * side, 1.4), 1.0, 1.0, rng)
		if bench.is_finite():
			_deco("deco_stone_bench", bench, Vector2(22, 5))
	var sign_spot := _free_spot(PLAZA + Vector2(2.8, 3.6), 1.0, 0.8, rng)
	if sign_spot.is_finite():
		_deco("deco_signpost", sign_spot, Vector2(4, 3))
	# kram przy sklepie, drewutnia przy karczmie, pranie i buda przy domu sołtysa
	# pranie i buda (z psem) przy domu sołtysa, drewutnia przy karczmie
	for item: Array in [["deco_wood_shelter", "tavern", Vector2(-1.8, 3.4), Vector2(28, 6)],
			["deco_washing_line", "chief_house", Vector2(-2.8, 6.0), Vector2(40, 4)],
			["deco_kennel", "chief_house", Vector2(-1.8, 4.6), Vector2(20, 6)]]:
		var spot := _free_spot(Vector2(BUILDINGS[item[1]][0]) + item[2], 2.0, 1.6, rng)
		if spot.is_finite():
			_deco(item[0], spot, item[3])
			if item[0] == "deco_kennel":
				_deco("resting_dog", spot + Vector2(1.1, 0.5))
			elif item[0] == "deco_washing_line":
				_deco("laundry_basket", spot + Vector2(-1.4, 0.8))
				_deco("wash_tub", spot + Vector2(1.6, 0.9), Vector2(14, 4))
	# pole warzywne: jeden strach na wróble, ule na skraju, narzędzia ogrodnika
	_deco("deco_scarecrow", GARDENS[1] + Vector2(0, -1.9), Vector2(6, 3))
	for p in [Vector2(25.0, 8.0), Vector2(25.1, 9.5)]:
		_deco("deco_beehive", p, Vector2(12, 5))
	_deco("pitchfork", GARDENS[2] + Vector2(1.7, 0.4))
	_deco("water_bucket", GARDENS[0] + Vector2(-1.7, 0.3))
	for p in [Vector2(15.4, 10.0), Vector2(24.6, 10.4)]:
		_deco("deco_fence", p, Vector2(26, 4))
	# drobiazgi przy swoich miejscach: kot na beczce przy karczmie, wiadro przy studni, taczka i narzędzia
	# przy naprawianej palisadzie
	_deco("sleeping_cat", Vector2(12.6, 19.9))
	_deco("water_bucket", Vector2(27.9, 20.9))
	_deco("deco_tools", Vector2(54.6, 27.6))


func _deco(texture_name: String, tile_pos: Vector2, collision := Vector2.ZERO) -> void:
	var sprite := _prop(texture_name, tile_pos, collision)
	sprite.flip_h = _rng.randf() < 0.5 and not texture_name in ["deco_signpost", "deco_lamp_post"]


## Wolne miejsce na ozdobę w promieniu `search` od `near` (kafelki układu): za palisadą, poza ścieżkami,
## budynkami (z zapasem przed fasadą, chyba że `at_facade` - skrzynki z kwiatami i doniczki) i dalej niż
## `gap` od innych rekwizytów. Vector2.INF - brak.
func _free_spot(near: Vector2, search: float, gap: float, rng: RandomNumberGenerator, at_facade := false) -> Vector2:
	for attempt in 24:
		var p := near if attempt == 0 else near + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.3, search)
		if outline_distance(p * SCALE) > 0.9 or _on_path(p, true):
			continue
		var blocked := false
		for id: String in buildings:
			var building: Building = buildings[id]
			var area := Rect2(building.position / TILE, building.size_px / TILE).grow(0.4)
			if not at_facade:
				area.size.y += 1.2  # przed drzwiami i fasadą
			else:
				area.size.y -= 0.4
			if area.has_point(_px(p) / TILE):
				blocked = true
				break
		if blocked or p.distance_to(PLAZA) < PLAZA_RADIUS + 0.6:
			continue
		for other in _spots:
			if other.distance_to(p) < gap:
				blocked = true
				break
		if not blocked:
			return p
	return Vector2.INF


# ---------------------------------------------------------------- plac
func _build_training_dummy() -> void:
	_trample(PRACTICE_DUMMY + Vector2(-0.6, 0.6), Vector2(2.6, 1.8))
	_spawn_scene(TRAINING_DUMMY, PRACTICE_DUMMY)
	map_markers.append({"position": _px(PRACTICE_DUMMY), "color": TrainingDummy.DUMMY_COLOR, "size": 2.0})


func _build_yard() -> void:
	# kapliczka odrodzenia na placyku przed domem sołtysa
	_build_watra()
	var shrine: Node2D = SHRINE.instantiate()
	shrine.position = _px(WATRA_SHRINE)
	_entities.add_child(shrine)
	spawn_point = shrine.position + Vector2(0, 20)
	map_markers.append({"position": shrine.position, "color": Color("5fd3ff"), "size": 3.0})
	_prop("banner", Vector2(29.2, 12.9), Vector2(4, 3))
	_prop("banner", Vector2(34.9, 12.9), Vector2(4, 3))

	# stoliki przed karczmą
	for table in [Vector2(15.6, 20.4), Vector2(22.4, 20.4)]:
		_prop("table", table, Vector2(24, 6))
		_prop("stool", table + Vector2(-1.1, 0.3))
		_prop("stool", table + Vector2(1.1, 0.3))
	_prop("barrel", Vector2(12.4, 19.2), Vector2(10, 5))
	_prop("well", Vector2(26.8, 20.4), Vector2(22, 8))

	# kuźnia pod wiatą obok szopy: piec z miechem, kowadło, beczka do hartowania i skrzynia na gotową broń;
	# dach znika, gdy gracz wejdzie pod wiatę (_process_forge_roof)
	_forge_roof = _prop("forge_shed", FORGE_ROOF_BASE)
	_forge_roof.set_meta("no_occlusion", true)  # dach wiaty gaśnie sam (_process_forge_roof)
	for post: String in FORGE_POSTS:
		_prop(post, FORGE_ROOF_BASE + FORGE_POSTS[post], Vector2(8, 4))
	_prop("forge_furnace", FORGE["furnace"], Vector2(24, 8))
	_glow(_px(FORGE["furnace"]) + Vector2(0, -12), Color(1, 0.5, 0.15, 0.5), Vector2(60, 44))
	_prop("bellows", FORGE["furnace"] + Vector2(-1.2, 0.1), Vector2(12, 4))
	_prop("anvil", FORGE["anvil"], Vector2(14, 4))
	_prop("quench_barrel", FORGE["quench"], Vector2(10, 4))
	_prop("weapon_crate", FORGE["crate"], Vector2(12, 4))
	_prop("charcoal", Vector2(25.9, 33.0))
	_prop("ingots", FORGE["anvil"] + Vector2(1.1, 0.7))
	_prop("tool_table", Vector2(25.6, 30.2), Vector2(18, 4))

	# miejsce myśliwego
	_prop("hide_rack", Vector2(29.0, 28.4), Vector2(20, 4))
	_prop("hide_rack", Vector2(27.3, 28.4), Vector2(20, 4))
	_prop("pelt", Vector2(28.9, 30.3))

	# stajnia z koniem i wóz z towarem przy sklepie
	_prop("stable", Vector2(49.5, 37.4), Vector2(60, 8))
	var horse := _prop("horse", Vector2(52.6, 36.2), Vector2(24, 5), 2)
	_animate(horse, 2, 1.2, 3.5)
	_prop("hay", Vector2(54.0, 34.6), Vector2(18, 5))
	_prop("cart", Vector2(46.2, 34.9), Vector2(40, 6))

	var fire: Node2D = CAMPFIRE.instantiate()
	fire.position = _px(Vector2(37.4, 37.4))
	_entities.add_child(fire)
	map_markers.append({"position": fire.position, "color": Color("ff9a3c"), "size": 2.0})

	# ogródki, drzewa i krzaki - żeby osada nie wyglądała jak z linijki
	for garden in GARDENS:
		_garden(garden)
	for p in [Vector2(10.8, 26.4)]:
		_spawn_scene(OAK, p)
	for p in [Vector2(12.2, 31.6), Vector2(56.4, 20.6)]:
		_spawn_scene(BUSH, p)
	_build_life()

	# naprawa palisady - stos desek przynoszonych z magazynu
	_plank_pile = _prop("plank_pile", Vector2(55.4, 32.4), Vector2(28, 6), 4)
	_plank_pile.frame = 0

	for p in [Vector2(30.0, 39.7), Vector2(36.2, 39.7)]:
		_prop("crate", p, Vector2(12, 5))
	_prop("barrel", Vector2(10.8, 24.9), Vector2(10, 5))


## Strefy życia osady: rynek przy sklepie, obóz uchodźców przy ognisku za południową drogą, skład drewna
## z drwalem obok kuźni, pole warzywne z ogrodnikiem, zagroda ze świniami przy magazynie, kąciki pracy
## przy kuźni i studni, dzieci bawiące się w berka i nosiwoda (studnia -> kociołek obozu).
func _build_life() -> void:
	# rynek: trzy kramy z przekupkami za ladą, skrzynie z towarem i kupujący
	# rynek przy placu: kramy w rzędzie przed magazynem
	_prop("stall_veg", Vector2(36.6, 19.8), Vector2(40, 6))
	_prop("stall_bread", Vector2(39.4, 19.8), Vector2(40, 6))
	_prop("stall_goods", Vector2(42.2, 19.8), Vector2(40, 6))
	_prop("apple_crate", Vector2(35.4, 21.0), Vector2(12, 4))
	_prop("cabbage_crate", Vector2(43.3, 21.0), Vector2(12, 4))
	_prop("grain_sacks", Vector2(38.0, 21.2), Vector2(16, 4))
	_prop("deco_basket", Vector2(41.0, 21.1))
	for spot: Array in [["villager_red", Vector2(36.6, 18.9)], ["villager_green", Vector2(39.4, 18.9)],
			["villager_red", Vector2(42.2, 18.9)]]:
		var vendor := _npc(spot[0], spot[1], Npc.Role.IDLE, LINES_MARKET, Vector2.DOWN)
		vendor.looks_around = false
		_entities.add_child(vendor)
	var shopper := _npc("villager_brown", Vector2(39.9, 21.5), Npc.Role.IDLE, LINES_VILLAGER, Vector2.UP)
	shopper.looks_around = false
	_entities.add_child(shopper)

	# obóz uchodźców przy ognisku: namioty, szałas, wóz z dobytkiem, posłania, kociołek
	for tent: Array in [["refugee_tent_0", Vector2(40.2, 36.6)], ["refugee_tent_1", Vector2(44.0, 36.9)]]:
		_refugee_tents.append(_body_of(_prop(tent[0], tent[1], Vector2(36, 8))))
	_prop("lean_to", Vector2(42.0, 39.4), Vector2(30, 6))
	_prop("covered_wagon", Vector2(45.4, 39.7), Vector2(44, 8))
	_prop("bedroll_open", Vector2(36.0, 36.3))
	_prop("bedroll", Vector2(39.0, 38.2))
	_prop("bundle", Vector2(41.7, 37.6))
	_prop("bundle", Vector2(45.6, 37.8))
	_prop("deco_lantern", Vector2(42.6, 37.0))
	var pot := _prop("cook_pot", Vector2(39.6, 39.0), Vector2(14, 4))
	_glow(_px(Vector2(39.6, 38.8)), Color(1.0, 0.55, 0.2, 0.3), Vector2(36, 28))
	pot.flip_h = false
	var cook := _npc("refugee_woman", Vector2(38.5, 39.0), Npc.Role.WORKER, LINES_REFUGEE, Vector2.RIGHT)
	cook.work_gentle = true
	cook.work_period = 1.2
	_entities.add_child(cook)
	for spot: Array in [["refugee_old", Vector2(37.4, 36.4), Vector2.DOWN], ["villager_brown", Vector2(38.7, 37.6), Vector2.LEFT]]:
		var refugee := _npc(spot[0], spot[1], Npc.Role.IDLE, LINES_REFUGEE, spot[2])
		refugee.seated = true
		refugee.looks_around = false
		_entities.add_child(refugee)
	var bard := _npc("bard", Vector2(35.6, 37.6), Npc.Role.WORKER, LINES_BARD, Vector2.RIGHT)
	bard.work_gentle = true
	bard.work_period = 0.55
	bard.work_effect = "notes"
	_entities.add_child(bard)
	# dzieci bawią się w berka
	var play := Rect2(_px(PLAY_AREA.position), PLAY_AREA.size * SCALE * TILE)
	var kids: Array[Npc] = []
	for spot: Array in [["child_a", Vector2(30.0, 37.0)], ["child_b", Vector2(34.0, 38.0)]]:
		var kid := _npc(spot[0], spot[1], Npc.Role.WANDER, LINES_CHILD)
		kid.wander_area = play
		kids.append(kid)
	kids[0].chase = kids[1]
	kids[1].chase = kids[0]
	kids[0].chasing = true
	for kid in kids:
		_entities.add_child(kid)
	# nosiwoda: od studni do kociołka obozu i z powrotem
	var water := _npc("villager_green", Vector2.ZERO, Npc.Role.CARRIER, LINES_WATER)
	water.path = _path([Vector2(27.6, 21.2), Vector2(28.4, 22.9), Vector2(32.8, 23.4), Vector2(33.3, 29.0),
			Vector2(32.8, 34.6), Vector2(35.0, 35.4), Vector2(37.4, 38.9)])
	water.carried_texture = _tex("water_bucket")
	water.carried_offset = Vector2(7, -9)
	water.wait_time = 2.5
	_entities.add_child(water)

	# skład drewna przy drewutni karczmy: drwal rąbie na pieńku, obok stosy polan
	_prop("firewood", Vector2(10.4, 15.8), Vector2(20, 5))
	_prop("firewood", Vector2(10.6, 17.4), Vector2(20, 5))
	_prop("chop_block", Vector2(12.9, 16.8), Vector2(10, 4))
	var woodcutter := _npc("woodcutter", Vector2(11.9, 16.8), Npc.Role.WORKER, LINES_WOODCUTTER, Vector2.RIGHT)
	woodcutter.work_effect = "dust"
	woodcutter.work_effect_offset = Vector2(16, -4)
	woodcutter.work_period = 1.1
	woodcutter.work_sound = "chop"
	_entities.add_child(woodcutter)

	# pole warzywne - ogrodnik okopuje grządki
	var gardener := _npc("gardener", Vector2(21.6, 10.6), Npc.Role.WORKER, LINES_GARDENER, Vector2.LEFT)
	gardener.work_effect = "dust"
	gardener.work_effect_offset = Vector2(14, -2)
	gardener.work_period = 1.3
	_entities.add_child(gardener)

	# przed karczmą zamiata gospodyni, a z karczmy zatacza się pijak
	var sweeper := _npc("sweeper", Vector2(17.4, 21.4), Npc.Role.WORKER, LINES_SWEEPER, Vector2.RIGHT)
	sweeper.work_gentle = true
	sweeper.work_effect = "dust"
	sweeper.work_effect_offset = Vector2(12, -2)
	sweeper.work_period = 0.9
	_entities.add_child(sweeper)
	var drunk := _npc("villager_brown", Vector2.ZERO, Npc.Role.CARRIER, LINES_DRUNK)
	drunk.path = _path([Vector2(19.3, 19.2), Vector2(21.0, 21.6), Vector2(24.2, 22.3), Vector2(23.0, 21.0),
			Vector2(25.6, 21.9), Vector2(20.6, 20.6), Vector2(19.3, 19.2)])
	drunk.drunk = true
	drunk.wait_time = 4.0
	_entities.add_child(drunk)


	_build_pig_pen()


## Zagroda: płot dookoła (z kolizją), szałas, koryto, błoto, siano i tabliczka - i trzy świnie.
func _build_pig_pen() -> void:
	var pen := PIG_PEN
	var fence_w := _tex("pen_fence_h").get_width() / (SCALE * TILE)
	var count := int(ceil(pen.size.x / fence_w))
	for k in count:
		var x := pen.position.x + fence_w * (k + 0.5)
		_prop("pen_fence_h", Vector2(x, pen.position.y))
		_prop("pen_fence_h", Vector2(x, pen.end.y))
	var post_h := _tex("pen_fence_v").get_height() / (SCALE * TILE)
	var rows := int(ceil(pen.size.y / post_h))
	for k in rows:
		var y := pen.position.y + pen.size.y * (k + 1) / rows
		_prop("pen_fence_v", Vector2(pen.position.x, y))
		_prop("pen_fence_v", Vector2(pen.end.x, y))
	var body := StaticBody2D.new()
	var corner := _px(pen.position)
	var size := pen.size * SCALE * TILE
	for edge: Rect2 in [Rect2(0, -4, size.x, 6), Rect2(0, size.y - 4, size.x, 6), Rect2(-3, 0, 6, size.y), Rect2(size.x - 3, 0, 6, size.y)]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = edge.size
		shape.shape = box
		shape.position = corner + edge.get_center()
		body.add_child(shape)
	_entities.add_child(body)
	_prop("pig_shelter", Vector2(51.9, 15.6))
	var trough := Vector2(53.8, 15.2)
	var mud := Vector2(53.4, 18.1)
	_prop("trough", trough)
	var puddle := _prop("mud", mud)
	puddle.reparent(_floors)
	_prop("hay_pile", Vector2(49.7, 18.9), Vector2(20, 5))
	_prop("slops_bucket", Vector2(52.3, 20.5))
	_prop("pig_sign", Vector2(51.4, 20.6), Vector2(4, 3))
	var inside := Rect2(_px(pen.position + Vector2(0.6, 0.9)), (pen.size - Vector2(1.2, 1.3)) * SCALE * TILE)
	for sheet in ["pig_pink", "pig_spotted", "pig_pink"]:
		var pig: Livestock = PIG_SCENE.new()
		pig.sheet = _tex(sheet)
		pig.sprite_offset = Vector2(0, -10)
		pig.pen = inside
		pig.feeding_spots.assign([_px(trough) + Vector2(0, 6), _px(mud)])
		pig.position = Vector2(randf_range(inside.position.x, inside.end.x), randf_range(inside.position.y, inside.end.y))
		_entities.add_child(pig)
	map_markers.append({"position": _px(pen.get_center()), "color": Color("e8a0a0"), "size": 2.0})


## Dach wiaty kuźni znika (prawie), gdy gracz wejdzie pod niego - widać kowala przy pracy.
func _process_forge_roof(delta: float) -> void:
	if _forge_roof == null or _player == null:
		return
	var under := Rect2(_px(FORGE_UNDER.position), FORGE_UNDER.size * SCALE * TILE).has_point(_player.global_position)
	_forge_roof.modulate.a = move_toward(_forge_roof.modulate.a, 0.3 if under else 1.0, delta * 3.0)


# ---------------------------------------------------------------- święto
## Boss pokonany: na placu zawisają girlandy, mieszkańcy wiwatują i podskakują, nad placem strzelają
## iskry. Pokonany w innej krainie - świętujemy po powrocie (Engine meta "celebrate").
func celebrate() -> void:
	for node in _celebration:
		if is_instance_valid(node):
			node.queue_free()
	_celebration.clear()
	for i in 4:
		var spot := PLAZA + Vector2.from_angle(TAU * i / 4.0 + 0.4) * (PLAZA_RADIUS + 1.4)
		var flags := _prop(["bunting", "garland"][i % 2], spot)
		_celebration.append(_body_of(flags))
	_celebration_left = CELEBRATION_TIME
	for node in _entities.get_children():
		var npc := node as Npc
		if npc == null or npc.role == Npc.Role.WANDER:
			continue
		var delay := randf_range(0.0, 1.5)
		var tween := npc.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if randf() < 0.5:
				npc.say(Lang.t(LINES_CHEER.pick_random())))
		for hop in 3:
			tween.tween_property(npc.sprite, "position:y", npc.sprite.position.y - 4.0, 0.12)
			tween.tween_property(npc.sprite, "position:y", npc.sprite.position.y, 0.12)
	_fireworks = 14


# ---------------------------------------------------------------- święto (wydarzenie w świecie)
func is_festival() -> bool:
	return _festival_left > 0.0


## Święto na `seconds` sekund: girlandy i chorągiewki wokół placu i Watry, kolorowe światła, tańce i fajerwerki.
func start_festival(seconds: float) -> void:
	stop_festival()
	_festival_left = seconds
	for i in 8:
		var spot := PLAZA + Vector2.from_angle(TAU * i / 8.0 + 0.2) * (PLAZA_RADIUS + 2.4)
		_festival.append(_body_of(_prop(["bunting", "garland"][i % 2], spot)))
	for i in 6:
		var spot := WATRA_POS + Vector2.from_angle(TAU * i / 6.0 + 0.5) * Vector2(5.2, 3.8)
		_festival.append(_body_of(_prop(["garland", "bunting"][i % 2], spot)))
	for i in 10:
		var at := _px(WATRA_POS + Vector2.from_angle(TAU * i / 10.0) * Vector2(6.0, 4.4))
		_festival.append(_glow_node(at, Color.from_hsv(float(i) / 10.0, 0.6, 1.0, 0.5), Vector2(60, 46)))
	for node in _entities.get_children():
		var npc := node as Npc
		if npc != null and randf() < 0.4:
			npc.say(Lang.t(LINES_FESTIVAL.pick_random()))
	_festival_fire = 1.0


func stop_festival() -> void:
	_festival_left = 0.0
	for node in _festival:
		if is_instance_valid(node):
			node.queue_free()
	_festival.clear()


func _process_festival(delta: float) -> void:
	if _festival_left <= 0.0:
		return
	_festival_left -= delta
	if _festival_left <= 0.0:
		stop_festival()
		return
	# tańce: co chwilę ktoś podskakuje i kręci się w miejscu
	_festival_dance -= delta
	if _festival_dance <= 0.0:
		_festival_dance = randf_range(0.4, 1.0)
		var dancers: Array = _entities.get_children().filter(func(n: Node) -> bool: return n is Npc and n.role != Npc.Role.WANDER)
		if not dancers.is_empty():
			var npc: Npc = dancers.pick_random()
			var tween := npc.create_tween()
			for hop in 4:
				tween.tween_property(npc.sprite, "position:y", npc.sprite.position.y - 5.0, 0.14)
				tween.tween_callback(func() -> void: npc.sprite.flip_h = not npc.sprite.flip_h)
				tween.tween_property(npc.sprite, "position:y", npc.sprite.position.y, 0.14)
			if randf() < 0.3:
				npc.say(Lang.t(LINES_FESTIVAL.pick_random()))
	_festival_fire -= delta
	if _festival_fire <= 0.0:
		_festival_fire = randf_range(2.5, 5.0)
		var at := _px(WATRA_POS) + Vector2(randf_range(-90, 90), randf_range(-110, -60))
		WorldVfx.firework(_entities, at)
		Sfx.play_at("explosion", at, -20.0)


func _process_celebration(delta: float) -> void:
	if _celebration_left <= 0.0:
		return
	_celebration_left -= delta
	if _fireworks > 0:
		_firework_timer -= delta
		if _firework_timer <= 0.0:
			_firework_timer = randf_range(0.6, 1.4)
			_fireworks -= 1
			var at := _px(PLAZA) + Vector2(randf_range(-60, 60), randf_range(-90, -50))
			WorldVfx.firework(_entities, at)
			Sfx.play_at("explosion", at, -18.0)
	if _celebration_left <= 0.0:
		for node in _celebration:
			if is_instance_valid(node):
				node.queue_free()
		_celebration.clear()


# ---------------------------------------------------------------- budowle bez wnętrza
## Budowla z zewnątrz: grafika stoi na środku dolnej krawędzi miejsca budowy, z kolizją ścian.
func _exterior(project: String, texture_name: String, collision: Vector2) -> Vector2:
	var data: Dictionary = PROJECTS[project]
	var base := Vector2(data["pos"]) + Vector2(data["size"].x / 2.0, data["size"].y)
	var nodes: Array[Node] = _projects[project]["nodes"]
	nodes.append(_body_of(_prop(texture_name, base, collision)))
	_trample(base + Vector2(0, 0.9), Vector2(data["size"].x / 2.0 + 0.6, 1.2))
	map_cells.erase(_marker_cell(project))
	return base


func _extra(project: String, texture_name: String, tile_pos: Vector2, collision := Vector2.ZERO) -> Sprite2D:
	var sprite := _prop(texture_name, tile_pos, collision)
	_projects[project]["nodes"].append(_body_of(sprite))
	return sprite


func _extra_npc(project: String, npc: Npc) -> Npc:
	_entities.add_child(npc)
	_projects[project]["nodes"].append(npc)
	return npc


## Lecznica: ranni na pryczach przed wejściem, suszarnia ziół, zielarka z wielkimi miksturami.
func _build_infirmary() -> void:
	var base := _exterior("infirmary", "infirmary", Vector2(88, 14))
	# lecznica stoi tyłem do palisady - ranni i suszarnia ziół po bokach
	_extra("infirmary", "cot_wounded_0", base + Vector2(3.3, -1.8), Vector2(26, 6))
	_extra("infirmary", "cot_wounded_1", base + Vector2(3.7, -0.3), Vector2(26, 6))
	_extra("infirmary", "herb_rack", base + Vector2(-3.3, -1.4), Vector2(24, 5))
	_extra("infirmary", "mortar_table", base + Vector2(4.2, -3.1), Vector2(18, 5))
	var herbalist := _npc("herbalist", base + Vector2(2.5, -2.6), Npc.Role.IDLE, LINES_HERBALIST, Vector2.RIGHT)
	herbalist.display_name = "Zielarka Jadwiga"
	herbalist.trade_greeting = Lang.t("Mikstury z ziół zbieranych o świcie. Pomogą, gdy zrobi się gorąco.")
	herbalist.shop_sells.assign(["greater_health_potion", "greater_mana_potion", "health_potion", "mana_potion"])
	herbalist.services.assign(["elixirs"])
	_extra_npc("infirmary", herbalist)
	map_markers.append({"position": _px(base), "color": Color("6fdc7a"), "size": 2.0})


## Kaplica: kapłan z błogosławieństwami przed wejściem, świeczniki, skrzynka na datki, modlący się.
func _build_chapel() -> void:
	var base := _exterior("chapel", "chapel", Vector2(88, 14))
	for side in [-1.0, 1.0]:
		_extra("chapel", "candle_stand", base + Vector2(2.3 * side, 0.6), Vector2(6, 3))
		_glow(_px(base + Vector2(2.3 * side, 0.0)), Color(1.0, 0.85, 0.5, 0.3), Vector2(30, 26))
	_extra("chapel", "offering_box", base + Vector2(1.2, 1.1), Vector2(8, 4))
	var priest := _npc("priest", base + Vector2(0, 1.3), Npc.Role.IDLE, LINES_PRIEST, Vector2.DOWN)
	priest.display_name = "Ojciec Bogumił"
	priest.services.assign(["blessing"])
	priest.dialog_greeting = Lang.t("Witaj, dziecko. Za skromny datek pomodlę się za twoją drogę.")
	priest.looks_around = false
	_extra_npc("chapel", priest)
	for spot: Array in [["villager_red", base + Vector2(-0.8, 2.7)], ["refugee_old", base + Vector2(0.9, 2.8)]]:
		var praying := _npc(spot[0], spot[1], Npc.Role.IDLE, LINES_PRIEST, Vector2.UP)
		praying.seated = true
		praying.looks_around = false
		_extra_npc("chapel", praying)
	map_markers.append({"position": _px(base), "color": Color("ffe9a0"), "size": 2.0})


## Chaty osadników w miejscu namiotów obozu uchodźców (i podatek co TAX_TIME).
func _build_houses() -> void:
	for tent in _refugee_tents:
		if is_instance_valid(tent):
			tent.queue_free()
	_refugee_tents.clear()
	_extra("houses", "cottage_0", Vector2(40.3, 36.8), Vector2(48, 10))
	_extra("houses", "cottage_1", Vector2(44.2, 37.1), Vector2(48, 10))
	_tax_timer = TAX_TIME


func _collect_tax() -> void:
	var gold := TAX_GOLD + TAX_PER_LEVEL * (_player.stats.level - 1)
	gold = roundi(gold * (1.0 + Boons.WATRA_TAX * (_player.boons.watra_level() - 1)))
	_player.stats.add_gold(gold)
	Sfx.play("coins")
	DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -16),
			Lang.t("+%d zł od osadników") % gold, Color(1.0, 0.85, 0.3), 8)


## Targowisko: wóz wędrownego kupca, skrzynie z egzotycznym towarem i dywany - towar zmienia się co 10 minut.
func _build_market() -> void:
	map_cells.erase(_marker_cell("market"))
	_extra("market", "covered_wagon", Vector2(47.8, 20.6), Vector2(44, 8))
	_extra("market", "exotic_crate", Vector2(46.3, 21.3), Vector2(14, 4))
	_extra("market", "carpets", Vector2(49.6, 21.1), Vector2(14, 4))
	_trample(Vector2(47.8, 20.6), Vector2(2.6, 1.0))
	_traveler = _npc("traveling_merchant", Vector2(48.4, 21.5), Npc.Role.IDLE, LINES_TRAVELER, Vector2.DOWN)
	_traveler.display_name = "Wędrowny kupiec Hasan"
	_traveler.trade_greeting = Lang.t("Najlepszy towar po tej stronie gór! Co dziesięć minut coś nowego.")
	_extra_npc("market", _traveler)
	_restock_traveler()
	map_markers.append({"position": _px(Vector2(47.8, 20.6)), "color": MAP_MERCHANT, "size": 2.0})


func _restock_traveler() -> void:
	var pool := MERCHANT_POOL.duplicate()
	pool.shuffle()
	_traveler.shop_sells.assign(pool.slice(0, MERCHANT_STOCK))
	_traveler.say(Lang.t("Nowy towar! Podejdź, obejrzyj!"))


## Chata jubilera: warsztat przed wejściem (stół, szlifierka, gablota, skrzynia surowych kryształów) i Dobromir -
## klejnoty i przeszlifowanie kamieni (usługa "reshape"). Z Orlej Przełęczy znika (MountainZone).
func _build_jeweler() -> void:
	var base := _exterior("jeweler", "jeweler_hut", Vector2(80, 14))
	_extra("jeweler", "gem_bench", base + Vector2(-2.0, 1.5), Vector2(22, 5))
	_extra("jeweler", "gem_wheel", base + Vector2(-3.4, 0.4), Vector2(14, 4))
	_extra("jeweler", "gem_case", base + Vector2(2.3, 1.6), Vector2(18, 4))
	_extra("jeweler", "crystal_crate", base + Vector2(3.0, 0.3), Vector2(14, 4))
	var jeweler := _npc("jeweler", base + Vector2(-0.6, 2.2), Npc.Role.IDLE, LINES_JEWELER, Vector2.DOWN)
	jeweler.display_name = "Jubiler Dobromir"
	jeweler.services.assign(["jeweler", "reshape"])
	jeweler.dialog_greeting = Lang.t("W Ostoi lepiej się szlifuje niż na wietrznej przełęczy! Osadzę, połączę, a teraz i przeszlifuję kamień.")
	_extra_npc("jeweler", jeweler)
	map_markers.append({"position": _px(base), "color": Color("6fe0e8"), "size": 2.0})


## Łaźnia: balia i ręczniki przed wejściem, para nad dachem. Wypoczynek po odpoczynku w karczmie (on_rest).
func _build_bathhouse() -> void:
	var base := _exterior("bathhouse", "bathhouse", Vector2(82, 14))
	_extra("bathhouse", "bath_tub", base + Vector2(-2.6, 0.9), Vector2(24, 6))
	_extra("bathhouse", "towel_rack", base + Vector2(2.6, 0.6), Vector2(22, 4))
	var steam := CPUParticles2D.new()
	steam.position = _px(base) + Vector2(4, -84)
	steam.amount = 10
	steam.lifetime = 2.6
	steam.direction = Vector2.UP
	steam.spread = 20.0
	steam.initial_velocity_min = 6.0
	steam.initial_velocity_max = 12.0
	steam.gravity = Vector2(2, -3)
	steam.scale_amount_min = 2.0
	steam.scale_amount_max = 4.0
	steam.color = Color(1, 1, 1, 0.35)
	steam.z_index = 30
	_entities.add_child(steam)
	_projects["bathhouse"]["nodes"].append(steam)


## Warsztat płatnerza obok kuźni: stojaki z bronią i zbrojami, kowal uczy się przekuwania.
func _build_armory() -> void:
	map_cells.erase(_marker_cell("armory"))
	_extra("armory", "weapon_rack", Vector2(23.8, 27.4), Vector2(20, 5))
	_extra("armory", "arms_bundle", Vector2(25.4, 27.6), Vector2(14, 4))
	_extra("armory", "mail_bundle", Vector2(26.5, 27.7))
	_trample(Vector2(25.0, 27.4), Vector2(2.2, 1.0))
	if _smith != null and not "reforge" in _smith.services:
		_smith.services.append("reforge")


# ---------------------------------------------------------------- Watra
## Watra na placu: animowany ogień w kręgu kamieni runicznych (z kolizją), wielka poświata, iskry, miejsce rozmowy
## (niewidoczna postać - [F] otwiera okno ofiar) i dwóch tragarzy noszących drewno z magazynu.
func _build_watra() -> void:
	var texture := _tex("watra")
	_watra = _prop("watra", WATRA_POS, Vector2(70, 22), texture.get_width() / texture.get_height())
	_watra.offset.y += 8.0
	_watra_glow = _glow_node(_px(WATRA_POS) + Vector2(0, -20), Color(1.0, 0.55, 0.2, 0.55), Vector2(220, 160))
	_watra_sparks = CPUParticles2D.new()
	_watra_sparks.position = _px(WATRA_POS) + Vector2(0, -40)
	_watra_sparks.amount = 22
	_watra_sparks.lifetime = 1.6
	_watra_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_watra_sparks.emission_rect_extents = Vector2(14, 6)
	_watra_sparks.direction = Vector2.UP
	_watra_sparks.spread = 25.0
	_watra_sparks.gravity = Vector2(0, -12)
	_watra_sparks.initial_velocity_min = 20.0
	_watra_sparks.initial_velocity_max = 45.0
	_watra_sparks.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.45, 0.15, 0.8), Color(0.6, 0.2, 0.1, 0.0)])
	_watra_sparks.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_watra_sparks.material = additive
	_watra_sparks.z_index = 30
	_floors.get_parent().add_child(_watra_sparks)
	map_markers.append({"position": _px(WATRA_POS), "color": Color(1.0, 0.5, 0.15), "size": 4.0})
	# miejsce rozmowy: niewidoczna postać przed ogniem
	var spot := _npc("villager_brown", WATRA_POS + Vector2(0, 1.6), Npc.Role.IDLE, [] as Array[String])
	spot.looks_around = false
	spot.display_name = "Watra"
	spot.services.assign(["watra"])
	_entities.add_child(spot)
	spot.get_node("Sprite").visible = false
	spot.get_node("Shadow").visible = false
	spot.prompt.text = Lang.t("[F] Watra")
	# żerca Wszebor - strażnik ognia, prowadzi zadania główne (MainQuests)
	var zerca := _npc("zerca", WATRA_POS + Vector2(-3.4, 1.4), Npc.Role.IDLE, LINES_ZERCA, Vector2.RIGHT)
	zerca.display_name = MainQuests.ZERCA
	# zmiana trybu świata (WorldModes) - tylko tu, w Ostoi
	zerca.services.assign(["world_mode"])
	zerca.looks_around = false
	zerca.dialog_greeting = Lang.t("Póki płonie ogień, Ostoja trwa. Pilnuję go, odkąd pamiętam - i będę pilnował, póki starczy mi sił.")
	# dopiero po wygenerowaniu świata - postać losuje przy starcie, a świat z tego samego ziarna ma zostać taki sam
	_entities.add_child.call_deferred(zerca)
	# tragarze drewna: magazyn -> Watra
	var wood_path := _path([Vector2(42.6, 13.9), Vector2(42.4, 17.6), Vector2(38.0, 18.6), Vector2(34.6, 18.2)])
	for sheet in ["villager_green", "worker_gray"]:
		var npc := _npc(sheet, Vector2.ZERO, Npc.Role.CARRIER, LINES_FIREWOOD)
		npc.path = wood_path
		npc.carried_texture = _tex("firewood")
		npc.carried_offset = Vector2(0, -24)
		npc.on_delivered = _flare_watra.bind(0.6)
		npc.wait_time = 2.5
		_entities.add_child(npc)
	_watra_ember = _player.boons.ember


## Gdzie staje gracz po powrocie z lochu w płomieniach Watry: tuż przed ogniem.
func watra_arrival() -> Vector2:
	return _px(WATRA_POS) + Vector2(0, 40)


## Ogień buchnie (więcej iskier, jaśniejsza poświata na chwilę).
func _flare_watra(strength: float) -> void:
	_watra_flare = maxf(_watra_flare, strength)
	Sfx.play_at("fireball_launch", _px(WATRA_POS), -14.0 + strength * 6.0)


## Klatki płomienia, pulsowanie poświaty (szersza z poziomem Watry), buchnięcie po ofierze.
func _process_watra(delta: float) -> void:
	if _watra == null:
		return
	_watra_time += delta
	_watra.frame = int(_watra_time * WATRA_FPS) % _watra.hframes
	if _player.boons.ember != _watra_ember:
		if _watra_ember >= 0 and _player.boons.ember > _watra_ember:
			_flare_watra(1.5)
		_watra_ember = _player.boons.ember
	_watra_flare = maxf(_watra_flare - delta * 0.8, 0.0)
	var level := _player.boons.watra_level()
	var pulse := 1.0 + sin(_watra_time * 5.3) * 0.04 + sin(_watra_time * 9.1) * 0.03
	_watra_glow.scale = Vector2.ONE * (0.85 + level * 0.12 + _watra_flare * 0.35) * pulse
	_watra_glow.modulate.a = clampf(0.75 + level * 0.05 + _watra_flare * 0.3, 0.0, 1.0)
	_watra_sparks.speed_scale = 0.8 + level * 0.08 + _watra_flare * 0.6


# ---------------------------------------------------------------- mieszkańcy
func _build_npcs() -> void:
	# tragarze desek: magazyn -> naprawiana palisada
	var plank_path := _path([Vector2(45.1, 13.9), Vector2(45.2, 17.2), Vector2(45.6, 20.0), Vector2(51.5, 23.2),
			Vector2(54.6, 26.0), Vector2(55.0, 30.6)])
	for sheet in ["worker_gray", "worker_ochre"]:
		var npc := _npc(sheet, Vector2.ZERO, Npc.Role.CARRIER, LINES_PLANKS)
		npc.path = plank_path
		npc.carried_texture = _tex("plank")
		npc.carried_offset = Vector2(0, -30)
		npc.on_delivered = _add_plank
		_entities.add_child(npc)

	# tragarze beczek: magazyn -> karczma
	var barrel_path := _path([Vector2(43.6, 13.9), Vector2(43.6, 17.2), Vector2(43.4, 22.6), Vector2(19.6, 22.6),
			Vector2(19.3, 18.6), Vector2(19.3, 15.8)])
	for sheet in ["villager_brown", "villager_red"]:
		var npc := _npc(sheet, Vector2.ZERO, Npc.Role.CARRIER, LINES_BARRELS)
		npc.path = barrel_path
		npc.carried_texture = _tex("barrel")
		npc.carried_offset = Vector2(0, -17)
		_entities.add_child(npc)

	# tragarz rozładowuje wóz: skrzynie, beczki i worki do sklepu
	var unloader := _npc("worker_ochre", Vector2.ZERO, Npc.Role.CARRIER, LINES_UNLOADER)
	unloader.path = _path([Vector2(45.4, 35.4), Vector2(44.6, 34.8), Vector2(44.1, 33.4), Vector2(44.1, 31.4)])
	unloader.carried_textures.assign([_tex("crate"), _tex("barrel"), _tex("sack")])
	unloader.carried_offset = Vector2(0, -17)
	_entities.add_child(unloader)

	# goście karczmy wychodzą na piwo do stolików przed wejściem
	var seats := [[Vector2(14.5, 20.75), Vector2.RIGHT], [Vector2(23.5, 20.75), Vector2.LEFT], [Vector2(16.7, 20.75), Vector2.LEFT]]
	var patrons := ["villager_green", "worker_gray", "villager_brown"]
	for i in seats.size():
		var seat: Vector2 = seats[i][0]
		var npc := _npc(patrons[i], Vector2.ZERO, Npc.Role.PATRON, LINES_PATRON)
		npc.path = _path([Vector2(16.6 + i * 1.3, 15.4), Vector2(18.8, 17.6), Vector2(18.8, 19.3), Vector2(seat.x, 19.3), seat])
		npc.seat_facing = seats[i][1]
		npc.carried_texture = _tex("mug")
		_entities.add_child(npc)

	# kowal w kółko: rozgrzewa pręt w piecu, kuje na kowadle, hartuje w beczce, odkłada broń do skrzyni
	var smith := _npc("smith", Vector2.ZERO, Npc.Role.CYCLE, LINES_SMITH, Vector2.RIGHT)
	smith.stations = [
		{"pos": _px(FORGE["furnace"] + Vector2(0.0, 0.8)), "facing": Vector2.UP, "time": 3.0, "effect": "fire",
				"sound": "", "carry": _tex("hot_bar")},
		{"pos": _px(FORGE["anvil"] + Vector2(-1.0, 0.05)), "facing": Vector2.RIGHT, "time": 5.2, "work": true,
				"effect": "sparks", "sound": "anvil", "carry": _tex("hot_bar")},
		{"pos": _px(FORGE["quench"] + Vector2(0.7, 0.4)), "facing": Vector2.LEFT, "time": 1.6, "effect": "steam",
				"sound": "step_water", "carry": _tex("blade")},
		{"pos": _px(FORGE["crate"] + Vector2(0.9, 0.3)), "facing": Vector2.LEFT, "time": 1.0, "carry": null},
	]
	smith.carried_offset = Vector2(6, -14)
	_smith = smith
	smith.work_effect = "sparks"
	smith.work_effect_offset = Vector2(20, -14)
	smith.work_period = 0.65
	smith.display_name = "Kowal Bronisław"
	smith.services.assign(["forge", "enchant"])
	smith.dialog_greeting = Lang.t("Zwykłe żelazo każdy wykuje. Ale przynieś mi kamień, drewno i coś z tych potworów, a wykuję ci rzecz z charakterem! A kamienie z Kryształów Watry wbiję ci w oręż - jeśli się odważysz zejść po nie do lochów.")
	smith.work_sound = "anvil"
	smith.display_name = "Kowal Bronisław"
	smith.trade_greeting = Lang.t("Broń i zbroja, prosto z kowadła!")
	smith.shop_sells.assign(["iron_sword", "war_axe", "leather_cap", "iron_helmet", "leather_armor",
			"chainmail", "leather_gloves", "leather_boots", "belt_t1", "girdle_t1"])
	_entities.add_child(smith)

	var hunter := _npc("hunter", Vector2(27.9, 30.4), Npc.Role.WORKER, LINES_HUNTER, Vector2.RIGHT)
	hunter.work_gentle = true
	hunter.work_period = 1.1
	hunter.display_name = "Myśliwy Radek"
	hunter.trade_greeting = Lang.t("Łuk? Mam jeden zapasowy.")
	hunter.shop_sells.assign(["short_bow"])
	hunter.quest_id = "wolf_hunt"
	_entities.add_child(hunter)

	var builder := _npc("builder", Vector2(55.9, 28.6), Npc.Role.WORKER, LINES_BUILDER, Vector2.RIGHT)
	builder.work_effect = "dust"
	builder.work_effect_offset = Vector2(20, -8)
	builder.work_period = 0.8
	builder.work_sound = "hammer"
	_entities.add_child(builder)

	var merchant := _npc("merchant", _in("shop", Vector2(4.0, 3.1)), Npc.Role.MERCHANT, LINES_MERCHANT)
	merchant.display_name = "Kupiec Bogdan"
	merchant.looks_around = false
	merchant.quest_id = "goblin_purge"
	merchant.shop_sells.assign(["health_potion", "mana_potion", "spellbook", "copper_ring",
			"ring_of_strength", "silver_earring", "fang_earring", "amber_necklace"])
	_entities.add_child(merchant)
	map_markers.append({"position": merchant.position, "color": MAP_MERCHANT, "size": 2.0})

	var barkeep := _npc("barkeep", _in("tavern", Vector2(2.6, 2.3)), Npc.Role.IDLE, LINES_BARKEEP)
	barkeep.looks_around = false
	barkeep.display_name = "Karczmarz Wacław"
	barkeep.services.assign(["rest", "meals"])
	barkeep.dialog_greeting = Lang.t("Witaj w Ostoi! Zmęczony? Za 25 złota przenocujesz w jednym z moich pokoi - wyśpisz się, a rano las wokół osady będzie jak nowy.")
	_entities.add_child(barkeep)

	var storekeeper := _npc("storekeeper", _in("warehouse", Vector2(2.3, 4.0)), Npc.Role.IDLE, LINES_STOREKEEPER)
	storekeeper.looks_around = false
	storekeeper.display_name = "Magazynier Zenon"
	storekeeper.services.assign(["storage"])
	storekeeper.dialog_greeting = Lang.t("Magazyn osady do twoich usług. Zostaw, co chcesz - przypilnuję. Drewno i kamień zawsze się przydadzą!")
	_entities.add_child(storekeeper)

	_chief = _npc("chief", Vector2(34.4, 13.6), Npc.Role.IDLE, LINES_CHIEF)
	_chief.display_name = "Sołtys Mirosław"
	_chief.quest_chain.assign([UNLOCK_QUEST])
	_chief.services.assign(["build"])
	_chief.dialog_greeting = Lang.t("Ostoja rośnie dzięki tobie! Przynieś drewno i kamień - z plecaka albo z magazynu - a cieśle postawią, co zechcesz.")

	_entities.add_child(_chief)
	map_markers.append({"position": _chief.position, "color": MAP_CHIEF, "size": 2.0})

	for spot: Array in [[Vector2(9.9, 20.3), Vector2.LEFT], [Vector2(56.2, 20.3), Vector2.RIGHT],
			[Vector2(29.5, 39.2), Vector2.DOWN], [Vector2(36.5, 39.2), Vector2.DOWN]]:
		var guard := _npc("guard", spot[0], Npc.Role.IDLE, LINES_GUARD, spot[1])
		guard.looks_around = false
		_entities.add_child(guard)

	for spot: Array in [
		["villager_red", Vector2(25.3, 20.9), Vector2.RIGHT],
	]:
		_entities.add_child(_npc(spot[0], spot[1], Npc.Role.IDLE, LINES_VILLAGER, spot[2]))


# ---------------------------------------------------------------- stosy surowców
## Stosy kłód i kamieni przy magazynie rosną razem z ilością surowca w magazynie.
func update_resource_piles(wood: int, stone: int) -> void:
	if _wood_piles.is_empty():
		for spot in WOOD_PILE_SPOTS:
			_wood_piles.append(_hidden_pile("wood_pile", spot))
		for spot in STONE_PILE_SPOTS:
			_stone_piles.append(_hidden_pile("stone_pile", spot))
	_update_piles(_wood_piles, wood)
	_update_piles(_stone_piles, stone)


func _hidden_pile(texture_name: String, spot: Vector2) -> Sprite2D:
	@warning_ignore("integer_division")
	var width := _tex(texture_name).get_width() / PILE_STAGES
	var pile := _prop(texture_name, spot, Vector2(width * 0.75, 8), PILE_STAGES)
	pile.visible = false
	_set_solid(pile, false)
	return pile


## Kolizja rekwizytu tylko wtedy, gdy go widać (stosy przy magazynie pojawiają się z pierwszym surowcem).
func _set_solid(sprite: Sprite2D, solid: bool) -> void:
	for shape in _body_of(sprite).get_children():
		if shape is CollisionShape2D:
			shape.set_deferred("disabled", not solid)


func _update_piles(piles: Array[Sprite2D], amount: int) -> void:
	@warning_ignore("integer_division")
	var stages := amount / PILE_PER_STAGE
	for i in piles.size():
		var stage := clampi(stages - i * PILE_STAGES, 0, PILE_STAGES)
		# pierwszy stosik pojawia się od razu przy pierwszej sztuce
		if i == 0 and amount > 0:
			stage = maxi(stage, 1)
		var pile := piles[i]
		var was_visible := pile.visible
		pile.visible = stage > 0
		if was_visible != pile.visible:
			_set_solid(pile, pile.visible)
		if stage > 0:
			if not was_visible or pile.frame != stage - 1:
				pile.scale = Vector2(1.15, 0.85)
				pile.create_tween().tween_property(pile, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
			pile.frame = stage - 1


## Tragarz odłożył deskę - stos rośnie, a gdy jest pełny, cieśla zużywa deski.
func _add_plank() -> void:
	_planks = mini(_planks + 1, 4)
	_plank_pile.frame = _planks - 1
	if _planks == 4:
		var tween := _plank_pile.create_tween()
		tween.tween_interval(5.0)
		tween.tween_callback(_use_planks)


func _use_planks() -> void:
	_planks = 1
	_plank_pile.frame = 0


# ---------------------------------------------------------------- budowy (koszary, chatka myśliwych)
## Zlecenie budowy u sołtysa: zabiera surowce (najpierw z plecaka, potem z magazynu)
## i w wyznaczonym miejscu rusza plac budowy. Zwraca false, gdy czegoś brakuje.
func start_project(project: String, player: Player) -> bool:
	if project_state(project) != "none" or not building_unlocked(player) or not can_afford(project, player) \
			or project_locked(project, player) != "":
		return false
	var cost: Dictionary = PROJECTS[project]["cost"]
	for id: String in cost:
		player.take_owned(id, cost[id])
	set_project(project, "building", PROJECTS[project]["time"])
	_chief.say(Lang.t(PROJECTS[project]["start_line"]))
	return true


## Budowanie odblokowuje zadanie sołtysa (w starszych zapisach - już rozpoczęta budowa).
func building_unlocked(player: Player) -> bool:
	return player.quests.state_of(UNLOCK_QUEST) == Quests.STATE_DONE or not _projects.is_empty()


## Powód, dla którego budowy nie da się jeszcze zlecić ("" - można), np. zadanie, które trzeba najpierw wykonać.
func project_locked(project: String, player: Player) -> String:
	var quest: String = PROJECTS[project].get("requires_quest", "")
	if quest != "" and player.quests.state_of(quest) != Quests.STATE_DONE:
		return Lang.t("Najpierw zadanie: %s") % Quests.get_data(quest)["title"]
	return ""


func can_afford(project: String, player: Player) -> bool:
	var cost: Dictionary = PROJECTS[project]["cost"]
	for id: String in cost:
		if player.count_owned(id) < int(cost[id]):
			return false
	return true


## Postęp trwającej budowy (0..1).
func project_progress(project: String) -> float:
	if project_state(project) != "building":
		return 1.0 if project_state(project) == "built" else 0.0
	return clampf(1.0 - _projects[project]["left"] / PROJECTS[project]["time"], 0.0, 1.0)


## Odpoczynek w karczmie - przez noc cieśle kończą budowy.
func on_rest() -> void:
	if project_state("bathhouse") == "built":
		_player.boons.grant("rested")
	for project: String in _projects:
		if _projects[project]["state"] == "building":
			_projects[project]["left"] = 0.0


func project_state(project: String) -> String:
	return _projects[project]["state"] if _projects.has(project) else "none"


func get_save_data() -> Dictionary:
	var data := {}
	for project: String in _projects:
		data[project] = [_projects[project]["state"], _projects[project]["left"]]
	return {"projects": data}


func load_save_data(data: Dictionary) -> void:
	var saved: Dictionary = data.get("projects", {})
	# starsze zapisy znały tylko koszary
	if data.has("barracks"):
		saved = {"barracks": [data["barracks"], data.get("construction_left", 0.0)]}
	for project: String in saved:
		var entry: Array = saved[project]
		if PROJECTS.has(project) and str(entry[0]) in ["building", "built"]:
			set_project(project, str(entry[0]), float(entry[1]))
	# starsze zapisy: osada już się budowała, więc prośba o pomoc jest dawno spełniona
	if not _projects.is_empty() and _player.quests.state_of(UNLOCK_QUEST) != Quests.STATE_DONE:
		_player.quests.states[UNLOCK_QUEST] = Quests.STATE_DONE
		_player.quests.changed.emit()


func set_project(project: String, state: String, time_left := 0.0) -> void:
	if _projects.has(project):
		for node: Node in _projects[project]["nodes"]:
			node.queue_free()
	var nodes: Array[Node] = []
	_projects[project] = {"state": state, "left": time_left, "nodes": nodes, "sprite": null}
	if state == "building":
		_build_construction_site(project)
	elif state == "built":
		map_cells.erase(_marker_cell(project))
		call("_build_" + project)
	# nowo udeptana ziemia przy budowie dostaje przejścia do trawy (jak ścieżki osady)
	if get_parent() != null and get_parent().has_method("_blend_settlement_ground"):
		get_parent()._blend_settlement_ground()
	set_process(true)


func _process(delta: float) -> void:
	for project: String in _projects:
		var entry: Dictionary = _projects[project]
		if entry["state"] != "building":
			continue
		entry["left"] -= delta * (1.0 + Boons.WATRA_BUILD_SPEED * (_player.boons.watra_level() - 1))
		var done: float = 1.0 - entry["left"] / PROJECTS[project]["time"]
		entry["sprite"].frame = clampi(int(done * CONSTRUCTION_STAGES), 0, CONSTRUCTION_STAGES - 1)
		if entry["left"] <= 0.0:
			_finish_construction(project)
			break  # słownik budów właśnie się zmienił
	if project_state("barracks") == "built":
		_process_drill(delta)
	_process_celebration(delta)
	_process_festival(delta)
	_process_watra(delta)
	_process_forge_roof(delta)
	if project_state("houses") == "built":
		_tax_timer -= delta
		if _tax_timer <= 0.0:
			_tax_timer = TAX_TIME
			_collect_tax()
	if project_state("market") == "built" and _traveler != null:
		_rotation_timer -= delta
		if _rotation_timer <= 0.0:
			_rotation_timer = MERCHANT_ROTATION
			_restock_traveler()


## Plac budowy: rusztowanie w 4 etapach, stos desek i kamieni, cieśle i tragarz desek.
func _build_construction_site(project: String) -> void:
	var data: Dictionary = PROJECTS[project]
	var pos: Vector2i = data["pos"]
	var size: Vector2i = data["size"]
	var nodes: Array[Node] = _projects[project]["nodes"]
	var site := Sprite2D.new()
	site.texture = _tex(data["art"])
	site.hframes = CONSTRUCTION_STAGES
	site.centered = false
	# plac budowy ma grafikę w dawnej skali - rozciągamy go do rozmiaru budynku
	site.scale = Vector2.ONE * SCALE
	if data.get("fit", false):
		var frame := Vector2(site.texture.get_width() / float(CONSTRUCTION_STAGES), site.texture.get_height())
		site.scale = Vector2(size) * SCALE * TILE / frame
	site.offset = Vector2(0, -size.y * TILE)
	site.position = _px(Vector2(pos + Vector2i(0, size.y)))
	_entities.add_child(site)
	_projects[project]["sprite"] = site
	nodes.append(site)
	var rect_tiles := Rect2(Vector2(pos), Vector2(size))
	var planks_at := Vector2(rect_tiles.position.x - 1.6, rect_tiles.end.y - 1.8)
	var planks := _prop("plank_pile", planks_at, Vector2(24, 5), 4)
	planks.frame = 3
	var stones := _prop("stone_pile", Vector2(rect_tiles.end.x + 1.8, rect_tiles.end.y - 2.6), Vector2(28, 6), PILE_STAGES)
	stones.frame = 2
	nodes.append_array([_body_of(planks), _body_of(stones)])

	for spot: Array in [["builder", Vector2(rect_tiles.position.x - 0.4, rect_tiles.end.y - 0.4), Vector2.RIGHT],
			["worker_ochre", Vector2(rect_tiles.end.x + 0.6, rect_tiles.end.y - 1.4), Vector2.LEFT],
			["builder", Vector2(rect_tiles.get_center().x + 0.6, rect_tiles.end.y + 1.4), Vector2.RIGHT]]:
		var worker := _npc(spot[0], spot[1], Npc.Role.WORKER, LINES_CONSTRUCTION, spot[2])
		worker.work_effect = "dust"
		worker.work_effect_offset = Vector2(20, -8)
		worker.work_period = randf_range(0.7, 0.9)
		worker.work_sound = "hammer"
		_entities.add_child(worker)
		nodes.append(worker)
	var carrier := _npc("worker_gray", Vector2.ZERO, Npc.Role.CARRIER, LINES_CONSTRUCTION)
	var front := rect_tiles.end.y + 0.6
	carrier.path = _path([planks_at + Vector2(0.2, 1.2), Vector2(planks_at.x + 1.2, front), Vector2(rect_tiles.get_center().x - 2.5, front),
			Vector2(rect_tiles.get_center().x - 2.5, front - 1.2)])
	carrier.carried_texture = _tex("plank")
	carrier.carried_offset = Vector2(0, -30)
	_entities.add_child(carrier)
	nodes.append(carrier)
	map_cells[_marker_cell(project)] = data["color"]


func _finish_construction(project: String) -> void:
	var data: Dictionary = PROJECTS[project]
	var pos: Vector2i = data["pos"]
	var size: Vector2i = data["size"]
	var dust := CPUParticles2D.new()
	dust.position = _px(Vector2(pos) + Vector2(size) * Vector2(0.5, 0.7))
	dust.one_shot = true
	dust.explosiveness = 0.9
	dust.amount = 40
	dust.lifetime = 1.2
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(size * TILE) * SCALE * Vector2(0.5, 0.3)
	dust.direction = Vector2.UP
	dust.spread = 60.0
	dust.initial_velocity_min = 10.0
	dust.initial_velocity_max = 30.0
	dust.gravity = Vector2(0, -10)
	dust.scale_amount_min = 3.0
	dust.scale_amount_max = 6.0
	dust.color = Color(0.8, 0.7, 0.55, 0.7)
	dust.emitting = true
	dust.z_index = 30
	_entities.get_parent().add_child(dust)
	dust.finished.connect(dust.queue_free)
	set_project(project, "built")
	Sfx.play("barracks")
	_chief.say(Lang.t(data["done_line"]))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_banner(Lang.t(data["banner"]), Color(1.0, 0.85, 0.4))


func _marker_cell(project: String) -> Vector2i:
	return _cell(Vector2(PROJECTS[project]["pos"]) + Vector2(PROJECTS[project]["size"]) / 2.0)


## Udeptana ziemia (w kafelkach osady): elipsa o środku `center` i półosiach `radii`.
func _trample(center: Vector2, radii: Vector2) -> void:
	center *= SCALE
	radii *= SCALE
	for y in range(floori(center.y - radii.y), ceili(center.y + radii.y) + 1):
		for x in range(floori(center.x - radii.x), ceili(center.x + radii.x) + 1):
			var d := (Vector2(x + 0.5, y + 0.5) - center) / radii
			if d.length() <= 1.0 + randf_range(-0.12, 0.08):
				_dirt(Vector2i(x, y))


## Udeptana ścieżka wzdłuż punktów (w kafelkach osady).
func _trample_path(points: Array[Vector2], radius: float) -> void:
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var steps := ceili(a.distance_to(b) * 2.0)
		for k in steps + 1:
			_trample(a.lerp(b, float(k) / steps), Vector2(radius, radius))


func _dirt(cell: Vector2i) -> void:
	if not Rect2i(Vector2i.ZERO, SIZE).has_point(cell):
		return
	_ground.set_cell(origin_tile + cell, 0, DIRT_TILES.pick_random())
	map_cells[origin_tile + cell] = MAP_DIRT


func _build_barracks() -> void:
	var nodes: Array[Node] = _projects["barracks"]["nodes"]
	# wartownicy na wieżach palisady zamieniają się w łuczników z koszar
	for i in _tower_sprites.size():
		for archer in _tower_sprites[i].get_children():
			if archer is TowerArcher:
				archer.can_shoot = true
				archer.sheet = _npc_sheet(["soldier_a", "soldier_b", "soldier_c", "soldier_a"][i % 4])
				if archer.is_node_ready():
					archer.get_child(0).texture = archer.sheet
	if not buildings.has("barracks"):
		_add_building("barracks", BARRACKS_POS, BARRACKS_SIZE, BARRACKS_COLOR, null)
		# wnętrze: prycze i stojaki na broń
		for x in [1.2, 2.6, 4.0]:
			_prop("bed", _in("barracks", Vector2(x, 4.0)), Vector2(16, 8))
		for x in [8.4, 10.4]:
			_prop("weapon_rack", _in("barracks", Vector2(x, 2.5)), Vector2(20, 5))
		_prop("chest", _in("barracks", Vector2(7.0, 6.2)), Vector2(14, 5))
		_prop("table", _in("barracks", Vector2(9.4, 5.6)), Vector2(24, 6))
		# plac ćwiczeń tuż obok koszar i plac musztry przed nimi - udeptane
		_trample(TRAINING_YARD, Vector2(5.2, 3.4))
		_trample(DRILL_SQUARE, Vector2(6.2, 2.6))
		_trample_path([Vector2(50.2, 49.6), Vector2(52.0, 48.6)], 0.9)
	_chief.lines = translated_lines(LINES_CHIEF_BUILT)

	# na zewnątrz: sztandary, tarcza, stojak i trzy kukły z ćwiczącymi żołnierzami
	for p in [Vector2(41.6, 50.6), Vector2(46.4, 50.6)]:
		nodes.append(_body_of(_prop("banner", p, Vector2(4, 3))))
	nodes.append(_prop("shield", Vector2(37.0, 50.2)))
	nodes.append(_body_of(_prop("weapon_rack", TRAINING_YARD + Vector2(-3.6, -2.0), Vector2(20, 5))))
	var trainers := ["soldier_a", "soldier_b", "soldier_c"]
	for i in 3:
		var dummy_pos := TRAINING_YARD + Vector2(-1.4 + i * 2.7, 0.3 + (i % 2) * 0.6)
		var dummy := _prop("dummy", dummy_pos, Vector2(8, 4))
		nodes.append(_body_of(dummy))
		var fighter := _npc(trainers[i], dummy_pos + Vector2(-1.1, 0.15), Npc.Role.WORKER, LINES_TRAINER, Vector2.RIGHT)
		fighter.work_effect = "straw"
		fighter.work_effect_offset = Vector2(21, -14)
		fighter.work_period = randf_range(0.6, 0.8)
		fighter.on_work_hit = _wobble.bind(dummy)
		fighter.work_sound = "dummy"
		_entities.add_child(fighter)
		nodes.append(fighter)

	# musztra przed koszarami: dwa szeregi i sierżant
	_drill.clear()
	_drill_home.clear()
	var sheets := ["soldier_a", "soldier_b", "soldier_c", "soldier_c", "soldier_a", "soldier_b"]
	for row in 2:
		for col in 3:
			var pos := Vector2(41.4 + col * 1.8, 52.6 + row * 1.7)
			var soldier := _npc(sheets[row * 3 + col], pos, Npc.Role.IDLE, [], Vector2.RIGHT)
			soldier.looks_around = false
			_entities.add_child(soldier)
			nodes.append(soldier)
			_drill.append(soldier)
			_drill_home.append(soldier.position)
	_sergeant = _npc("sergeant", Vector2(48.8, 53.4), Npc.Role.IDLE, [], Vector2.LEFT)
	_sergeant.looks_around = false
	_sergeant.display_name = "Sierżant Bolko"
	_sergeant.shop_sells.assign(["guard_horn"])
	_sergeant.trade_greeting = Lang.t("Zadmij w róg, a moi chłopcy przybiegną. Tylko nie nadużywaj!")
	_entities.add_child(_sergeant)
	nodes.append(_sergeant)
	_drill_step = 0
	_drill_timer = 1.0

	# tragarz nosi broń i zbroje z kuźni do koszar
	var porter := _npc("worker_gray", Vector2.ZERO, Npc.Role.CARRIER, LINES_ARMS)
	porter.path = _path([Vector2(23.4, 32.6), Vector2(24.5, 34.8), Vector2(32.6, 35.4), Vector2(33.1, 41.5),
			Vector2(33.3, 46.5), Vector2(36.0, 50.9), Vector2(44.0, 50.9), Vector2(44.0, 48.6)])
	porter.carried_textures.assign([_tex("arms_bundle"), _tex("mail_bundle")])
	porter.carried_offset = Vector2(0, -20)
	_entities.add_child(porter)
	nodes.append(porter)


## Komendy sierżanta i reakcja szeregów (zwroty i marsz kilka kroków w przód i z powrotem).
func _process_drill(delta: float) -> void:
	if _sergeant == null:
		return
	_drill_timer -= delta
	if _drill_timer > 0.0:
		return
	_drill_timer = 3.0
	var command: String = LINES_SERGEANT[_drill_step]
	_sergeant.say(Lang.t(command))
	var facing: Vector2 = [Vector2.RIGHT, Vector2.UP, Vector2.UP, Vector2.DOWN, Vector2.DOWN, Vector2.RIGHT][_drill_step]
	for i in _drill.size():
		var soldier := _drill[i]
		soldier.facing = facing
		if command == "Naprzód marsz!":
			var target := _drill_home[i] + (Vector2(0, -14) if facing == Vector2.UP else Vector2.ZERO)
			soldier.march_to(target, 1.4)
	_drill_step = (_drill_step + 1) % LINES_SERGEANT.size()


# ---------------------------------------------------------------- chatka myśliwych
func _build_lodge() -> void:
	var nodes: Array[Node] = _projects["lodge"]["nodes"]
	if not buildings.has("lodge"):
		_add_building("lodge", LODGE_POS, LODGE_SIZE, LODGE_COLOR, Vector2(96, 6))
		# wnętrze: stół ze strzałami, skóry, beczka i prycza
		_prop("table", _in("lodge", Vector2(2.2, 4.4)), Vector2(24, 6))
		_prop("stool", _in("lodge", Vector2(1.1, 4.7)))
		_prop("barrel", _in("lodge", Vector2(0.9, 2.1)), Vector2(10, 5))
		_prop("bed", _in("lodge", Vector2(6.9, 4.2)), Vector2(16, 8))
		_prop("pelt", _in("lodge", Vector2(4.6, 5.4)))
		# udeptane podwórko i ścieżka do wschodniej bramy
		_trample_path(LODGE_PATH, 0.9)
		_trample(Vector2(60.6, 12.4), Vector2(4.6, 2.8))
		_trample(Vector2(63.2, 16.3), Vector2(2.6, 1.2))
	for p in [LODGE_SPOTS["hide_rack"]]:
		nodes.append(_body_of(_prop("hide_rack", p, Vector2(20, 4))))
	nodes.append(_body_of(_prop("hide_rack", Vector2(64.4, 10.8), Vector2(20, 4))))
	_butcher_rack = _prop("butcher_rack", LODGE_SPOTS["butcher_rack"], Vector2(24, 4), 2)
	nodes.append(_body_of(_butcher_rack))
	nodes.append(_body_of(_prop("table", LODGE_SPOTS["bench_table"], Vector2(24, 6))))
	nodes.append(_prop("quiver", LODGE_SPOTS["bench_table"] + Vector2(1.6, 0.2)))
	_archery_target = _prop("archery_target", LODGE_SPOTS["target"], Vector2(14, 4))
	nodes.append(_body_of(_archery_target))
	var smokehouse := _prop("smokehouse", LODGE_SPOTS["smokehouse"], Vector2(22, 6))
	nodes.append(_body_of(smokehouse))
	nodes.append(_smoke(smokehouse))

	_hunters.clear()
	_corner_taken = [false, false]
	for i in HUNTER_SHEETS.size():
		var hunter := HUNTER_SCENE.instantiate() as Npc
		hunter.position = _px(LODGE_SPOTS["door"] + Vector2(i * 1.2 - 1.2, 0.8))
		hunter.lines = translated_lines(LINES_LODGE_HUNTER)
		hunter.get_node("Sprite").texture = load("res://assets/npc/%s.png" % HUNTER_SHEETS[i])
		hunter.set("lodge", self)
		_entities.add_child(hunter)
		nodes.append(hunter)
		_hunters.append(hunter)


# ---------------------------------------------------------------- chata mędrca
func _build_sage_hut() -> void:
	var nodes: Array[Node] = _projects["sage_hut"]["nodes"]
	if not buildings.has("sage_hut"):
		_add_building("sage_hut", SAGE_POS, SAGE_SIZE, SAGE_COLOR, Vector2(96, 6))
		# izba: regały z księgami pod ścianami, stolik ze stołkiem i skrzynia
		for spot: Array in [[0.95, 0], [2.25, 1], [5.75, 1], [7.05, 0]]:
			_prop("bookshelf_%d" % spot[1], _in("sage_hut", Vector2(spot[0], 2.0)), Vector2(20, 5))
		_prop("table", _in("sage_hut", Vector2(1.6, 5.2)), Vector2(24, 6))
		_prop("stool", _in("sage_hut", Vector2(2.7, 5.5)))
		_prop("chest", _in("sage_hut", Vector2(7.0, 5.5)), Vector2(14, 5))
		# ścieżka do drogi przy zachodniej bramie i udeptane podwórko
		_trample_path([Vector2(5.0, 8.6), Vector2(5.2, 13.0), Vector2(5.8, 18.0), Vector2(6.8, 22.8)], 0.8)
		_trample(Vector2(5.0, 9.4), Vector2(3.2, 1.4))
	# pulpit na gwiaździstym dywanie - mędrzec przewraca kartki - i sowa na żerdzi
	var lectern := _prop("lectern", _in("sage_hut", Vector2(4.0, 4.1)), Vector2(18, 5), 2)
	_animate(lectern, 2, 2.5, 6.0)
	nodes.append(_body_of(lectern))
	var owl := _prop("owl_perch", _in("sage_hut", Vector2(7.2, 4.3)), Vector2(6, 3), 2)
	_animate(owl, 2, 0.15, 4.0)
	nodes.append(_body_of(owl))
	nodes.append(_glow_node(_px(_in("sage_hut", Vector2(4.6, 3.6))), Color(1.0, 0.8, 0.4, 0.35), Vector2(40, 30)))
	nodes.append(_magic_motes(_px(_in("sage_hut", Vector2(4.0, 3.5)))))

	var sage := _npc("sage", _in("sage_hut", Vector2(4.0, 3.55)), Npc.Role.IDLE, LINES_SAGE, Vector2.DOWN)
	sage.looks_around = false
	sage.display_name = "Mędrzec Teodor"
	sage.services.assign(["disenchant", "bestiary", "respec"])
	sage.dialog_greeting = Lang.t("Zaklęcia to nie wieczność, młody wędrowcze. Za drobną opłatą zdejmę czar z twojego oręża i oddam ci kamienie, które go utrzymywały.")
	_entities.add_child(sage)
	nodes.append(sage)

	# wokół chaty: kocioł z wywarem, luneta, grządka ziół, kamienie runiczne i latarenka
	var cauldron := _prop("cauldron", Vector2(2.0, 9.8), Vector2(14, 5), 2)
	_animate(cauldron, 2, 0.35, 0.6)
	nodes.append(_body_of(cauldron))
	nodes.append(_glow_node(_px(Vector2(2.0, 9.4)), Color(0.3, 1.0, 0.45, 0.3), Vector2(40, 30)))
	nodes.append(_body_of(_prop("herb_garden", Vector2(8.0, 10.4), Vector2(34, 6))))
	nodes.append(_body_of(_prop("telescope", Vector2(9.9, 7.4), Vector2(8, 4))))
	for spot: Vector2 in [Vector2(-0.4, 6.2), Vector2(0.3, 11.6), Vector2(10.4, 4.0)]:
		nodes.append(_body_of(_prop("rune_stone", spot, Vector2(10, 4))))
		nodes.append(_glow_node(_px(spot + Vector2(0, -0.5)), Color(0.45, 0.75, 1.0, 0.25), Vector2(24, 24)))
	nodes.append(_glow_node(_px(_in("sage_hut", Vector2(4.95, 4.9))), Color(1.0, 0.8, 0.4, 0.35), Vector2(36, 30)))


## Unoszące się, migoczące drobinki magii (nad pulpitem mędrca).
func _magic_motes(pos: Vector2) -> CPUParticles2D:
	var motes := CPUParticles2D.new()
	motes.position = pos
	motes.amount = 8
	motes.lifetime = 2.5
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 10.0
	motes.direction = Vector2.UP
	motes.spread = 40.0
	motes.gravity = Vector2(0, -4)
	motes.initial_velocity_min = 2.0
	motes.initial_velocity_max = 6.0
	motes.scale_amount_max = 1.5
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.7, 0.85, 1.0, 0.0), Color(0.8, 0.9, 1.0, 0.9), Color(0.6, 0.5, 1.0, 0.0)])
	motes.color_ramp = fade
	motes.z_index = 20
	_entities.add_child(motes)
	return motes


# ---------------------------------------------------------------- gildia poszukiwaczy przygód
func _build_guild() -> void:
	var nodes: Array[Node] = _projects["guild"]["nodes"]
	if not buildings.has("guild"):
		_add_building("guild", GUILD_POS, GUILD_SIZE, GUILD_COLOR, Vector2(144, 6))
		# sala: lada pisarza, stół z mapą, trofeum na ścianie, stojak z bronią, skrzynie
		_prop("counter", _in("guild", Vector2(3.2, 3.1)), Vector2(48, 6))
		_prop("bookshelf_0", _in("guild", Vector2(0.95, 2.0)), Vector2(20, 5))
		_prop("trophy", _in("guild", Vector2(6.0, 1.6)))
		_prop("weapon_rack", _in("guild", Vector2(10.6, 2.5)), Vector2(20, 5))
		_prop("map_table", _in("guild", Vector2(8.4, 4.6)), Vector2(32, 6))
		for p in [Vector2(7.0, 4.95), Vector2(9.8, 4.95)]:
			_prop("stool", _in("guild", p))
		_prop("chest", _in("guild", Vector2(1.0, 6.4)), Vector2(14, 5))
		_prop("barrel", _in("guild", Vector2(11.1, 6.3)), Vector2(10, 5))
		# podwórko przed wejściem i ścieżka do drogi od południowej bramy
		_trample(Vector2(24.0, 52.4), Vector2(5.6, 2.2))
		_trample_path([Vector2(24.0, 51.0), Vector2(28.5, 52.8), Vector2(32.6, 52.6)], 0.8)

	var clerk := _npc("guild_clerk", _in("guild", Vector2(3.2, 2.6)), Npc.Role.IDLE, LINES_CLERK, Vector2.DOWN)
	clerk.looks_around = false
	# rynek gildii i lista podróżników (Market, Travelers)
	clerk.display_name = "Pisarz gildii Gniewko"
	clerk.services.assign(["market", "travelers", "marks"])
	clerk.dialog_greeting = Lang.t("Witaj w gildii! Tu spisuję każdego poszukiwacza przygód, a na rynku kupisz i sprzedasz, co dusza zapragnie - podróżnicy handlują dzień i noc.")
	_entities.add_child(clerk)
	nodes.append(clerk)

	# tablica ogłoszeń przed wejściem (zlecenia - Bounties) i poszukiwacze, którzy ją czytają
	notice_board = _prop("notice_board", Vector2(20.6, 52.0), Vector2(36, 5))
	nodes.append(_body_of(notice_board))
	# niewidoczny "rozmówca" przed tablicą - E otwiera okno zleceń
	var no_lines: Array[String] = []
	var board := _npc("villager_brown", Vector2(20.6, 52.7), Npc.Role.IDLE, no_lines)
	board.looks_around = false
	board.display_name = "Tablica ogłoszeń"
	board.services.assign(["bounties"])
	board.add_to_group("notice_board")
	_entities.add_child(board)
	board.get_node("Sprite").visible = false
	board.get_node("Shadow").visible = false
	board.prompt.text = Lang.t("[F] Tablica ogłoszeń")
	nodes.append(board)
	for spot: Array in [["adventurer_a", Vector2(20.0, 53.3)], ["adventurer_b", Vector2(21.4, 53.4)]]:
		var adventurer := _npc(spot[0], spot[1], Npc.Role.IDLE, LINES_ADVENTURER, Vector2.UP)
		adventurer.looks_around = false
		_entities.add_child(adventurer)
		nodes.append(adventurer)

	# proporce na masztach, pochodnie przy drzwiach, ława i skrzynie
	for spot: Vector2 in [Vector2(18.3, 51.4), Vector2(29.9, 51.4)]:
		var banner := _prop("banner_pole", spot, Vector2(6, 3), 2)
		_animate(banner, 2, 0.4, 0.8)
		nodes.append(_body_of(banner))
	for spot: Vector2 in [Vector2(22.7, 50.7), Vector2(25.3, 50.7)]:
		var torch := _prop("torch_stand", spot, Vector2(6, 3), 2)
		_animate(torch, 2, 0.12, 0.25)
		nodes.append(_body_of(torch))
		nodes.append(_glow_node(_px(spot + Vector2(0, -1.2)), Color(1.0, 0.6, 0.2, 0.4), Vector2(48, 40)))
	nodes.append(_body_of(_prop("bench", Vector2(27.4, 52.9), Vector2(28, 5))))
	for spot: Array in [["crate", Vector2(30.6, 49.6), Vector2(12, 5)], ["crate", Vector2(30.9, 48.8), Vector2.ZERO],
			["barrel", Vector2(17.4, 49.7), Vector2(10, 5)], ["barrel", Vector2(17.3, 48.4), Vector2(10, 5)]]:
		nodes.append(_body_of(_prop(spot[0], spot[1], spot[2])))


## Pozycja tablicy ogłoszeń w świecie (dla przyszłych zleceń); Vector2.INF, gdy gildii nie ma.
func notice_board_position() -> Vector2:
	return notice_board.global_position if is_instance_valid(notice_board) else Vector2.INF


## Poświata do usunięcia razem z budową (_glow dodaje ją na stałe).
func _glow_node(pos: Vector2, color: Color, size: Vector2) -> Sprite2D:
	_glow(pos, color, size)
	return _floors.get_child(_floors.get_child_count() - 1) as Sprite2D


## Dym z komina wędzarni.
func _smoke(sprite: Sprite2D) -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.amount = 14
	smoke.lifetime = 3.0
	smoke.direction = Vector2(0.2, -1)
	smoke.spread = 15.0
	smoke.gravity = Vector2(3, -6)
	smoke.initial_velocity_min = 5.0
	smoke.initial_velocity_max = 9.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 5.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.6, 0.58, 0.55, 0.7), Color(0.75, 0.75, 0.78, 0.0)])
	smoke.color_ramp = fade
	smoke.position = sprite.global_position + Vector2(5, -30)
	_entities.add_child(smoke)
	return smoke


## Pozycja miejsca przy chatce w pikselach świata (dla myśliwych).
func lodge_spot(name: String) -> Vector2:
	return _px(LODGE_SPOTS[name])


## Droga z chatki do bramy, za którą zaczyna się szlak do łowiska (0 - wschód, 1 - zachód).
func town_route(corner: int) -> Array[Vector2]:
	var points: Array[Vector2] = LODGE_PATH.duplicate()
	if corner == 1:
		points.append_array([Vector2(52.0, 23.3), Vector2(33.0, 23.4), Vector2(9.0, 23.3), Vector2(4.0, 23.3)])
	else:
		points.append(Vector2(62.0, 23.3))
	return _path(points)


## Myśliwy rezerwuje łowisko - w każdym rogu poluje najwyżej jeden naraz.
func reserve_corner() -> int:
	var free: Array[int] = []
	for corner in _corner_taken.size():
		if not _corner_taken[corner] and not hunting_routes[corner].is_empty():
			free.append(corner)
	if free.is_empty():
		return -1
	var corner: int = free.pick_random()
	_corner_taken[corner] = true
	return corner


func release_corner(corner: int) -> void:
	if corner >= 0 and corner < _corner_taken.size():
		_corner_taken[corner] = false


## Stelaż z zawieszoną zwierzyną podczas oprawiania.
func show_carcass(on: bool) -> void:
	if _butcher_rack != null:
		_butcher_rack.frame = 1 if on else 0


## Strzała myśliwego trafia w tarczę (czasem w sam środek).
func hit_target() -> void:
	if _archery_target != null:
		_wobble_small(_archery_target)


func _wobble_small(sprite: Sprite2D) -> void:
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "rotation", 0.06, 0.05)
	tween.tween_property(sprite, "rotation", 0.0, 0.15)


## Myśliwi zanoszą skóry i mięso do magazynu osady.
func deliver_goods(goods: Dictionary) -> void:
	for id: String in goods:
		_player.storage.add_item(id, goods[id])


## Kukła odchyla się po ciosie.
func _wobble(dummy: Sprite2D) -> void:
	var tween := dummy.create_tween()
	tween.tween_property(dummy, "rotation", 0.18, 0.06)
	tween.tween_property(dummy, "rotation", -0.08, 0.12)
	tween.tween_property(dummy, "rotation", 0.0, 0.12)


# ---------------------------------------------------------------- pomocnicze
func _px(tile_pos: Vector2) -> Vector2:
	return (Vector2(origin_tile) + tile_pos * SCALE) * TILE


## Komórka świata, w której leży punkt układu.
func _cell(tile_pos: Vector2) -> Vector2i:
	return origin_tile + Vector2i((tile_pos * SCALE).floor())


func _path(points: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for p in points:
		result.append(_px(p))
	return result


func _tex(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = load("res://assets/village/%s.png" % name)
	return _textures[name]


## Rekwizyt stojący na ziemi (punkt zaczepienia u podstawy), opcjonalnie z kolizją.
func _prop(texture_name: String, tile_pos: Vector2, collision := Vector2.ZERO, frames := 1) -> Sprite2D:
	_spots.append(tile_pos)
	var texture := _tex(texture_name)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = frames
	sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 1.0)
	if collision == Vector2.ZERO:
		sprite.position = _px(tile_pos)
		_entities.add_child(sprite)
		return sprite
	var body := StaticBody2D.new()
	body.position = _px(tile_pos)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = collision
	shape.shape = box
	shape.position = Vector2(0, -collision.y / 2.0)
	body.add_child(shape)
	body.add_child(sprite)
	_entities.add_child(body)
	return sprite


## Ogródek leży na ziemi (pod postaciami, nie zasłania ich), a każda roślina ma małą kolizję u podstawy -
## grządek nie da się przejść na wprost, ale między rzędami można wejść. Rośliny to osobne kępki pikseli
## grafiki, więc kolizje dopasowują się do niej same.
func _garden(tile_pos: Vector2) -> void:
	_spots.append(tile_pos)
	# pod roślinami zaorana grządka z bruzdami
	var soil := Sprite2D.new()
	soil.texture = _tex("tilled_bed")
	soil.offset = Vector2(0, -soil.texture.get_height() / 2.0 + 3.0)
	soil.position = _px(tile_pos)
	_floors.add_child(soil)
	var texture := _tex("garden")
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 1.0)
	sprite.position = _px(tile_pos)
	_floors.add_child(sprite)
	var body := StaticBody2D.new()
	body.position = sprite.position
	var top_left := Vector2(-texture.get_width() / 2.0, -texture.get_height() + 1.0)
	for plant: Rect2 in _plants(texture):
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(maxf(plant.size.x * 0.4, 3.0), 3.0)
		shape.shape = box
		shape.position = top_left + Vector2(plant.get_center().x, plant.end.y - 1.5)
		body.add_child(shape)
	_entities.add_child(body)


## Obrysy roślin w grafice ogródka: spójne kępki nieprzezroczystych pikseli (pomijamy okruchy).
func _plants(texture: Texture2D) -> Array[Rect2]:
	var image := texture.get_image()
	var size := image.get_size()
	var seen := {}
	var plants: Array[Rect2] = []
	for y in size.y:
		for x in size.x:
			var start := Vector2i(x, y)
			if seen.has(start) or image.get_pixelv(start).a < 0.5:
				continue
			seen[start] = true
			var stack: Array[Vector2i] = [start]
			var box := Rect2(Vector2(start), Vector2.ONE)
			var count := 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				box = box.expand(Vector2(p)).expand(Vector2(p) + Vector2.ONE)
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n := p + d
					if n.x >= 0 and n.y >= 0 and n.x < size.x and n.y < size.y and not seen.has(n) 							and image.get_pixelv(n).a >= 0.5:
						seen[n] = true
						stack.append(n)
			if count >= 20:
				plants.append(box)
	return plants


## Węzeł do usunięcia razem z rekwizytem (ciało z kolizją albo sam sprite).
func _body_of(sprite: Sprite2D) -> Node:
	return sprite.get_parent() if sprite.get_parent() is StaticBody2D else sprite


func _spawn_scene(scene: PackedScene, tile_pos: Vector2) -> void:
	var node: Node2D = scene.instantiate()
	node.position = _px(tile_pos)
	_entities.add_child(node)


## Prosta animacja klatek w losowym rytmie (koń, żar paleniska).
func _animate(sprite: Sprite2D, frames: int, period_min: float, period_max: float) -> void:
	var timer := Timer.new()
	timer.wait_time = randf_range(period_min, period_max)
	timer.autostart = true
	timer.timeout.connect(_next_frame.bind(sprite, frames, timer, period_min, period_max))
	sprite.add_child(timer)


func _next_frame(sprite: Sprite2D, frames: int, timer: Timer, period_min: float, period_max: float) -> void:
	sprite.frame = (sprite.frame + 1) % frames
	timer.wait_time = randf_range(period_min, period_max)


func _glow(pos: Vector2, color: Color, size: Vector2) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = int(size.x)
	texture.height = int(size.y)
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.position = pos
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	_floors.add_child(glow)


## Hasła mieszkańców w obecnym języku (stałe LINES_* są po polsku).
static func translated_lines(lines: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for line in lines:
		out.append(Lang.t(line))
	return out


func _npc_sheet(sheet: String) -> Texture2D:
	return load("res://assets/npc/%s.png" % sheet)


func _npc(sheet: String, tile_pos: Vector2, role: Npc.Role, lines: Array[String], facing := Vector2.DOWN) -> Npc:
	var npc: Npc = NPC_SCENE.instantiate()
	npc.position = _px(tile_pos)
	npc.role = role
	npc.lines = translated_lines(lines)
	npc.facing = facing
	npc.get_node("Sprite").texture = load("res://assets/npc/%s.png" % sheet)
	return npc
