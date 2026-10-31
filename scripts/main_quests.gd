class_name MainQuests
## Zadania główne: fabularny łańcuch prowadzony przez żercę Wszebora od Watry w Ostoi przez wszystkie krainy
## i mechaniki gry. Znaczniki "!" i "?" nad postaciami są złote (Npc; poboczne - niebieskie), w dzienniku
## i pod minimapą - złoty tytuł. Każdy krok (CHAIN, kolejno) daje `giver`, a nagrodę wydaje `receiver` (domyślnie ten sam). Krok jest
## wykonany, gdy spełni się jego warunek `check` (sprawdzany co chwilę - QuestLog.update_main), np.:
## ["talk"] - od razu (rozmowa z `receiver`), ["level", 5], ["quest", id] (inne zadanie oddane), ["built", n],
## ["herb"], ["project", id] (budowla Ostoi), ["nodes", n] (węzły drzewek), ["boss", nazwa sceny] (Codex.kills), ["watra", poziom], ["shrine", id],
## ["event", nazwa, n] (QuestLog.note_event: dungeon_clear, crystal_done, codex), ["enchant", n], ["essence"].
## Nagrody: złoto, doświadczenie, przedmioty (reward_items) i punkty umiejętności (skill_points - SkillBook).
## Lochy Watry odblokowuje krok DUNGEON_STEP. Starsze zapisy (bez zadań głównych) zaliczają po wczytaniu kroki,
## których warunek już spełniły (catch_up - bez nagród).

const ZERCA := "Żerca Wszebor"
const COLOR := Color(1.0, 0.82, 0.25)
const COLOR_DIM := Color(0.62, 0.55, 0.36)
## Krok, po którego wykonaniu (albo w trakcie oddawania) działają lochy w płomieniach Watry.
const DUNGEON_STEP := "main_watra"

const CHAIN: Array[String] = [
	"main_ember", "main_village", "main_build", "main_herbs", "main_tree", "main_codex", "main_gruzlog", "main_wolves",
	"main_watra", "main_dungeon", "main_fields", "main_bombardier", "main_swamp", "main_hydra", "main_pass",
	"main_gem", "main_eagle", "main_ancient", "main_crystal", "main_enchant", "main_cemetery", "main_essence", "main_finale",
]

const DATA := {
	# ---------------------------------------------------------------- Akt I: Ostoja i Gobliński Las
	"main_ember": {"title": "Iskra w popiele", "giver": ZERCA, "receiver": "Sołtys Mirosław", "check": ["talk"],
		"target_name": "Rozmowa z sołtysem", "area_name": "Ostoja - dom sołtysa przy placu", "gold": 50, "xp": 25,
		"description": "Podejdź bliżej, wędrowcze. Jestem Wszebor, żerca tej Watry. Póki ogień płonie, horda nie wejdzie za palisadę - ale płomień słabnie z każdą nocą, a ludzi przybywa. Potrzebujemy kogoś, kto stanie między Ostoją a ciemnością. Idź do sołtysa Mirosława, powiedz, że przysyła cię Wszebor.",
		"progress_text": "Sołtys mieszka w domu przy placu, na północ od Watry.",
		"complete_text": "Wszebor cię przysłał? To dobrze, bardzo dobrze. Ostoja potrzebuje rąk do pracy i miecza do obrony.",
		"done_text": "Ogień płonie, póki ktoś go pilnuje."},
	"main_village": {"title": "Ręce do pracy", "giver": "Sołtys Mirosław", "check": ["quest", "village_help"],
		"target_name": "Zadanie „Ostoja prosi o pomoc”", "area_name": "las wokół Ostoi", "gold": 120, "xp": 60,
		"reward_items": {"health_potion": 5},
		"description": "Zanim pomyślimy o walce, musimy przetrwać. Palisada się sypie, a cieśle siedzą bezczynnie. Pomóż mi z drewnem i kamieniem - przyjmij moją prośbę i zbierz, co trzeba.",
		"progress_text": "Trzydzieści kłód i dwadzieścia kamieni. Przyjmij ode mnie zadanie „Ostoja prosi o pomoc”, jeśli jeszcze go nie masz.",
		"complete_text": "Cieśle już ostrzą siekiery! Masz tu mikstury na drogę - las nie jest łaskawy.",
		"done_text": "Ostoja rośnie dzięki tobie."},
	"main_build": {"title": "Pierwsza budowla", "giver": "Sołtys Mirosław", "check": ["project", "infirmary"],
		"target_name": "Lecznica", "area_name": "Ostoja - plany budowy u sołtysa", "gold": 200, "xp": 120,
		"skill_points": 1,
		"description": "Mamy surowce, mamy ludzi. Najpierw postawmy lecznicę - ranni nie mają gdzie się podziać, a zielarka Jadwiga od dawna prosi o własny kąt. Z ziół uwarzy mikstury, jakich nie zrobi nikt inny.",
		"progress_text": "Lecznicę wybierzesz z planów budowy - przycisk „Budowa” w rozmowie ze mną. Odpoczynek w karczmie kończy budowę od razu.",
		"complete_text": "Lecznica stoi, a Jadwiga już rozkłada zioła! Ludzie patrzą na to z nadzieją, jakiej dawno nie widziałem. Wszebor chciał cię widzieć - wróć do Watry.",
		"done_text": "Każda nowa budowla to jeden powód więcej, by nie uciekać."},
	"main_herbs": {"title": "Zioła na rany", "giver": ZERCA, "check": ["herb"],
		"target_name": "Zerwane zioło", "area_name": "każda kraina - świecące rośliny (klawisz F)", "gold": 100, "xp": 80,
		"reward_items": {"herb_wort": 3},
		"description": "Ogień nie leczy ran - robią to zioła. W lesie rosną rośliny, nad którymi tańczą iskierki. Zerwij choć jedno zioło - zielarka uwarzy z nich mikstury silniejsze niż posiłek z karczmy.",
		"progress_text": "Szukaj roślin z iskierkami nad liśćmi i zerwij je klawiszem F.",
		"complete_text": "Dziurawiec... dobry początek. Zanieś zioła Jadwidze do lecznicy - z trzech ziół uwarzy miksturę.",
		"done_text": "Las daje, gdy umiesz brać."},
	"main_tree": {"title": "Ścieżka oręża", "giver": ZERCA, "check": ["nodes", 3],
		"target_name": "Wybrane węzły drzewka", "area_name": "okno umiejętności (klawisz K)", "gold": 150, "xp": 100,
		"skill_points": 1,
		"description": "Każda broń ma swoją ścieżkę - miecz, łuk i księga. Za każdy zdobyty poziom dostajesz punkt, którym otwierasz kolejne węzły. Wybierz trzy węzły na ścieżce swojego oręża.",
		"progress_text": "Klawisz K - drzewko umiejętności. Węzeł wybierasz obok już wybranego.",
		"complete_text": "Czuję to w tobie - oręż słucha twojej ręki. Masz, jeszcze jeden punkt ode mnie.",
		"done_text": "Ścieżka oręża nie ma końca."},
	"main_codex": {"title": "Księga świata", "giver": ZERCA, "check": ["event", "codex", 1],
		"target_name": "Otwarta encyklopedia", "area_name": "encyklopedia (klawisz L)", "gold": 60, "xp": 40,
		"description": "Mądry wojownik zna wroga, zanim go spotka. Spisuję wszystko, co wiemy o potworach, legendach i ziołach. Zajrzyj do tej księgi - każdy pokonany wróg i znaleziony przedmiot ją uzupełnia.",
		"progress_text": "Encyklopedię otwiera klawisz L.",
		"complete_text": "Pusta jeszcze, co? Zapełnisz ją. Każdy wpis to dowód, że ktoś tu przeszedł i przeżył.",
		"done_text": "Wiedza to też broń."},
	"main_gruzlog": {"title": "Wódz goblinów", "giver": "Kupiec Bogdan", "check": ["boss", "goblin_chief"],
		"target_name": "Gruzłog, Wódz Goblinów", "area_name": "obóz wodza goblinów (Gobliński Las)", "gold": 300, "xp": 1500,
		"reward_items": {"greater_health_potion": 3},
		"description": "Żerca mówi, że horda ma przewodników. U goblinów to Gruzłog - ich wódz siedzi w sercu obozu, otoczony strażą. Dopóki żyje, gobliny będą napadać na moje wozy. Pokonaj go.",
		"progress_text": "Gruzłog siedzi w największym obozie goblinów. Uważaj na jego straż.",
		"complete_text": "Gruzłog padł? Ha! Wozy znów dojadą całe. Należy ci się porządna nagroda - a myśliwy Radek pytał o ciebie, wilki nie dają mu spokoju.",
		"done_text": "Gobliński Las znów należy do ludzi."},
	"main_wolves": {"title": "Wilcze wycie", "giver": "Myśliwy Radek", "receiver": ZERCA, "check": ["boss", "alpha_wolf"],
		"target_name": "Szarokieł, Wilk Alfa", "area_name": "siedlisko wilków (południowy wschód Goblińskiego Lasu)", "gold": 350, "xp": 1800,
		"skill_points": 1,
		"description": "Gobliny bez wodza się rozpierzchły, ale wilki nie. Prowadzi je Szarokieł - wielki basior z siedliska na południowym wschodzie. Ubij go, a potem powiedz o tym Wszeborowi. Coś mi mówi, że on już wie więcej.",
		"progress_text": "Szarokieł prowadzi watahę z serca siedliska. Uważaj na jego wycie - zwołuje resztę. Po zwycięstwie idź prosto do Watry.",
		"complete_text": "Szarokieł padł... A jednak horda nie słabnie. Bo to nie wodzowie ją ślą - coś się budzi głębiej. Płomień musi być silniejszy.",
		"done_text": "W lesie wreszcie cicho po nocach."},
	"main_watra": {"title": "Płomień Watry", "giver": ZERCA, "check": ["watra", 2],
		"target_name": "Poziom Watry", "area_name": "Watra na placu Ostoi - ofiary ze złota i przedmiotów", "gold": 250, "xp": 1500,
		"reward_items": {"blessed_stone": 5},
		"description": "Watra karmi się ofiarą. Złóż w niej złoto albo przedmioty, których nie potrzebujesz - żar podniesie płomień. Gdy Watra urośnie, otworzę przed tobą jej najgłębszy sekret: lochy w samym ogniu.",
		"progress_text": "Podejdź do Watry (F) i złóż ofiarę. Drugi poziom Watry otworzy lochy.",
		"complete_text": "Słyszysz, jak huczy? Teraz możesz wejść w płomienie - Watra zaprowadzi cię do lochów, gdzie horda gnieździ się w ciemności. Przycisk „Lochy” w oknie Watry.",
		"done_text": "Każda ofiara to rok życia dla Ostoi."},
	"main_dungeon": {"title": "W płomienie", "giver": ZERCA, "check": ["event", "dungeon_clear", 1],
		"target_name": "Pokonani strażnicy lochów", "area_name": "lochy w płomieniach Watry (okno Watry - „Lochy”)", "gold": 400, "xp": 2500,
		"reward_items": {"weapon_stone": 3, "armor_stone": 3},
		"description": "W każdym lochu czeka strażnik, a za nim skarbiec. Zejdź w płomienie, pokonaj strażnika i wróć żywy. Pamiętaj: płomienie powrotu pojawią się dopiero po jego śmierci - albo przy wejściu.",
		"progress_text": "Okno Watry - przycisk „Lochy”. Strażnik czeka w najdalszej komnacie.",
		"complete_text": "Wróciłeś z ognia. Mało kto może to o sobie powiedzieć. Kowal Bronisław wbije ci te kamienie w oręż - spróbuj szczęścia.",
		"done_text": "Lochy Watry nigdy nie są takie same."},
	# ---------------------------------------------------------------- Akt II: krainy
	"main_fields": {"title": "Stary Młyn", "giver": ZERCA, "check": ["shrine", "old_mill"],
		"target_name": "Kapliczka Stary Młyn", "area_name": "Pola Zbożowe (zachód, za drogą z Goblińskiego Lasu)", "gold": 200, "xp": 1200,
		"description": "Horda przyszła z zachodu, przez pola. Idź drogą na zachód, do Pól Zbożowych, i odnajdź kapliczkę przy Starym Młynie. Z kapliczek możesz potem wracać przez wielką mapę.",
		"progress_text": "Droga na zachód z Goblińskiego Lasu prowadzi do Pól Zbożowych. Kapliczkę odkrywasz, podchodząc do niej.",
		"complete_text": "Młyn jeszcze stoi? To dobrze. Ludzie z pól mówią o koboldach i ich szalonym wodzu z beczkami prochu.",
		"done_text": "Kapliczki to latarnie w ciemności."},
	"main_bombardier": {"title": "Barykada Bombardiera", "giver": ZERCA, "check": ["boss", "kobold_bombardier"],
		"target_name": "Bombardier Kaszlak", "area_name": "wielki obóz koboldów (północ Pól Zbożowych)", "gold": 500, "xp": 3000,
		"skill_points": 1,
		"description": "Koboldy z pól mają wodza - Bombardiera Kaszlaka, który siedzi za barykadą w wielkim obozie na północy. Jego beczki prochu podpalają łany. Skończ z nim.",
		"progress_text": "Barykada Bombardiera jest w północnej części obozu koboldów. Uważaj na beczki.",
		"complete_text": "Kaszlak wyleciał w powietrze? Pola odetchną. Ale wieści z rozlewisk są gorsze.",
		"done_text": "Łany znów falują spokojnie."},
	"main_swamp": {"title": "Bagienny Bród", "giver": ZERCA, "check": ["boss", "frog_chief"],
		"target_name": "Bulgor, Wódz Żaboludzi", "area_name": "Rozlewiska - wioska żabołaków", "gold": 550, "xp": 3500,
		"reward_items": {"greater_mana_potion": 5},
		"description": "Na rozlewiskach żabołaki zbierają się w wiosce wokół Bulgora, swojego wodza. Odnajdź Bagienny Bród, a potem rozpędź jego wioskę.",
		"progress_text": "Rozlewiska leżą na wschód od Goblińskiego Lasu. Bulgor mieszka w wiosce żabołaków.",
		"complete_text": "Bulgor pokonany... Ale żabołaki mówiły coś o panu topielców. Siedzi w sercu Topielczego Uroczyska.",
		"done_text": "Rozlewiska są mniej groźne niż wczoraj."},
	# id zostaje po dawnym celu (Hydrze), żeby zapisy w trakcie tego kroku działały; Hydra (poz. 32-40) była za trudna
	"main_hydra": {"title": "Pan topielców", "giver": ZERCA, "check": ["boss", "wodnik"],
		"target_name": "Wodnik", "area_name": "Topielcze Uroczysko (Rozlewiska, lewy dolny róg)", "gold": 650, "xp": 4500,
		"skill_points": 1,
		"description": "Na rozlewiskach topielce wychodzą z sadzawek coraz śmielej. Prowadzi je Wodnik z najgłębszej sadzawki Topielczego Uroczyska - to jeden z tych, które budzą hordę. Zatop go we własnym bagnie.",
		"progress_text": "Topielcze Uroczysko leży w lewym dolnym rogu Rozlewisk, pod drogą. Wodnik siedzi na wysepce w jego sercu.",
		"complete_text": "Wodnik martwy? Watra zapłonęła jaśniej, gdy to się stało - widziałem. Jesteśmy na dobrym tropie.",
		"done_text": "Bestie padają jedna po drugiej."},
	"main_pass": {"title": "Orla Przełęcz", "giver": ZERCA, "receiver": "Jubiler Dobromir", "check": ["shrine", "eagle_pass"],
		"target_name": "Kapliczka Orla Przełęcz", "area_name": "Wietrzne Turnie (na wschód od Rozlewisk)", "gold": 400, "xp": 3000,
		"description": "W górach, w Wietrznych Turniach, mieszka jubiler Dobromir - stary przyjaciel. Odnajdź kapliczkę na Orlej Przełęczy i porozmawiaj z nim. Jeśli zbudowaliście mu chatę, znajdziesz go w Ostoi.",
		"progress_text": "Wietrzne Turnie leżą na wschód od Rozlewisk. Kapliczka stoi na przełęczy.",
		"complete_text": "Wszebor cię przysłał? Stary lis! Siadaj. Mam dla ciebie coś, co wzmocni twój oręż bardziej niż kowalski młot.",
		"done_text": "Góry mają swoje tajemnice."},
	"main_gem": {"title": "Szlachetny kamień", "giver": "Jubiler Dobromir", "check": ["quest", "jeweler_gem"],
		"target_name": "Zadanie „Pierwszy klejnot”", "area_name": "złoża rudy żelaza w Wietrznych Turniach", "gold": 300, "xp": 2500,
		"description": "Przyjmij ode mnie zadanie „Pierwszy klejnot” - przynieś surowy klejnot z rudy żelaza. Pokażę ci, co potrafią kamienie szlachetne w gniazdach.",
		"progress_text": "Rozbij kilofem złoże rudy żelaza w Turniach.",
		"complete_text": "Teraz już wiesz, jak działają klejnoty. Ale nad przełęczą krąży coś groźniejszego - wróć z tym do Wszebora.",
		"done_text": "Kamień w gnieździe to drugi przedmiot w jednym."},
	"main_eagle": {"title": "Pan Burz", "giver": ZERCA, "check": ["boss", "storm_eagle"],
		"target_name": "Gromoskrzydły, Pan Burz", "area_name": "gniazdo nad wioską ptakoludzi (Wietrzne Turnie)", "gold": 800, "xp": 6000,
		"skill_points": 1,
		"description": "Nad wioską ptakoludzi gnieździ się Gromoskrzydły - orzeł, który niesie burzę na skrzydłach. Ptakoludzie oddają mu cześć i ruszają na nasze ziemie. Strąć go z nieba.",
		"progress_text": "Gniazdo Gromoskrzydłego jest nad wioską ptakoludzi w Turniach.",
		"complete_text": "Burze nad górami ucichły. Teraz zostały najstarsze lasy - i to, co w nich śpi.",
		"done_text": "Niebo znów należy do ptaków."},
	# ---------------------------------------------------------------- Akt III: Prastary Las, lochy i Cmentarz
	"main_ancient": {"title": "Pan Puszczy", "giver": ZERCA, "check": ["boss", "leshy"],
		"target_name": "Leszy, Pan Puszczy", "area_name": "serce Prastarego Lasu (na północ od Goblińskiego Lasu)", "gold": 1000, "xp": 9000,
		"reward_items": {"mercy_stone": 3},
		"description": "Prastary Las na północy był zawsze święty. Teraz Leszy, jego pan, oszalał - otacza się pierścieniami prastarych drzew i zamyka drogi. Odnajdź kapliczkę przy Starym Dębie i uwolnij las od Leszego.",
		"progress_text": "Prastary Las leży na północ od Goblińskiego Lasu. Leszy czeka w sercu puszczy.",
		"complete_text": "Leszy padł... Las płakał, ale odetchnął. Został już tylko cmentarz - i ten, kto wskrzesza tam umarłych.",
		"done_text": "Puszcza znów szumi spokojnie."},
	"main_crystal": {"title": "Kryształ Watry", "giver": ZERCA, "check": ["event", "crystal_done", 1],
		"target_name": "Obronione Kryształy Watry", "area_name": "lochy w płomieniach Watry (co drugi loch)", "gold": 700, "xp": 6000,
		"reward_items": {"crystal_heart": 1},
		"description": "W lochach rośnie czasem Kryształ Watry - zamarznięty płomień. Gdy podejdziesz, horda rzuci się, by go rozbić. Obroń go do końca, a da ci kamienie, dzięki którym kowal zaklnie twój oręż.",
		"progress_text": "Kryształ rośnie w największej komnacie co drugiego lochu. Podejdź do niego i przetrwaj fale.",
		"complete_text": "Kryształ ocalał. Weź to Serce Kryształu - kowal wykuje nim gniazdo na esencję legendy. A teraz idź do Bronisława.",
		"done_text": "Kryształy to łzy Watry."},
	"main_enchant": {"title": "Kowalska próba", "giver": "Kowal Bronisław", "check": ["enchant", 1],
		"target_name": "Zaklęty przedmiot na postaci", "area_name": "kuźnia w Ostoi - usługa „Zaklinanie”", "gold": 500, "xp": 4000,
		"reward_items": {"blessed_stone": 20},
		"description": "Wszebor mówił, że przyniesiesz kamienie z Kryształów. Dobrze! Daj mi coś ze swojego ekwipunku, a spróbuję go zakląć. Uprzedzam - czasem się nie udaje.",
		"progress_text": "Usługa „Zaklinanie” u mnie. Załóż zaklęty przedmiot, żebym widział efekt.",
		"complete_text": "Patrz, jak lśni! To moja najlepsza robota od lat. Masz tu uświęcone kamienie - zbierzesz ich więcej, a zaklęcie się nie wymknie.",
		"done_text": "Żelazo pamięta każde uderzenie młota."},
	"main_cemetery": {"title": "Pan Kości", "giver": ZERCA, "check": ["boss", "necromancer"],
		"target_name": "Mortan, Pan Kości", "area_name": "mauzoleum Leśnego Cmentarza (za Prastarym Lasem)", "gold": 1500, "xp": 14000,
		"skill_points": 2,
		"description": "Teraz wiem, kto budzi hordę. Mortan, Pan Kości, nekromanta z mauzoleum na Leśnym Cmentarzu. To on wskrzesza umarłych i zsyła bestie na żywych. Idź przez Prastary Las na Cmentarz i zakończ to.",
		"progress_text": "Leśny Cmentarz leży za Prastarym Lasem. Mortan czeka w mauzoleum, otoczony szkieletami.",
		"complete_text": "Mortan nie żyje... Czuję, jak ciężar spada z Watry. Horda nie zniknie od razu - ale nikt już nią nie kieruje.",
		"done_text": "Umarli śpią spokojnie."},
	"main_essence": {"title": "Dusza legendy", "giver": ZERCA, "check": ["essence"],
		"target_name": "Esencja legendy", "area_name": "Watra - okno Watry, przycisk „Esencje” (albo Ołtarz Welesa w lochu)", "gold": 1000, "xp": 8000,
		"reward_items": {"crystal_heart": 2},
		"description": "Legendy, które zdobywasz, mają w sobie duszę - efekt, który można wyciągnąć. Wrzuć niepotrzebną legendę w Watrę, a odda ci jej esencję. Można ją osadzić w innym przedmiocie albo w drzewku oręża.",
		"progress_text": "Okno Watry - przycisk „Esencje”. W lochach trafisz czasem na Ołtarz Welesa, który robi to za darmo.",
		"complete_text": "Czujesz to ciepło? To dusza legendy. Weź te Serca Kryształu - kowal wykuje gniazda na kolejne esencje.",
		"done_text": "Nic nie ginie w Watrze na zawsze."},
	"main_finale": {"title": "Dopóki płonie ogień", "giver": ZERCA, "check": ["watra", 5],
		"target_name": "Poziom Watry", "area_name": "Watra na placu Ostoi", "gold": 3000, "xp": 20000,
		"skill_points": 2, "reward_items": {"crystal_heart": 3},
		"description": "Horda bez wodza błądzi, ale wciąż jej pełno. Ostoja musi stać się twierdzą, której nikt nie złamie. Rozpal Watrę do piątego poziomu - niech jej blask widać z każdej krainy.",
		"progress_text": "Ofiary w Watrze: złoto, przedmioty, a w lochach - żar z modyfikatorów. Piąty poziom Watry.",
		"complete_text": "Patrz... Watra płonie tak, jak za czasów mojego dziada. Dopóki płonie ogień, Ostoja trwa. A ty - ty jesteś jej ogniem.",
		"done_text": "Dopóki płonie ogień, Ostoja trwa."},
}


static func is_main(id: String) -> bool:
	return DATA.has(id)


static func receiver_of(id: String) -> String:
	var data: Dictionary = Quests.get_data(id)
	return data.get("receiver", data.get("giver", ""))


## Pierwszy niewykonany krok łańcucha ("" - cały łańcuch zakończony).
static func current(log: QuestLog) -> String:
	for id in CHAIN:
		if log.state_of(id) != Quests.STATE_DONE:
			return id
	return ""


## Czy postać bierze udział w łańcuchu (pokazuje złote znaczniki i ma rozmowę).
static func involves(npc_name: String) -> bool:
	for id: String in DATA:
		if DATA[id]["giver"] == npc_name or DATA[id].get("receiver", "") == npc_name:
			return true
	return false


## Krok, który dotyczy tej postaci teraz: do przyjęcia u niej albo do oddania u niej ("" - nic).
static func step_for(log: QuestLog, npc_name: String) -> String:
	var id := current(log)
	if id == "":
		return ""
	var state := log.state_of(id)
	if state == Quests.STATE_AVAILABLE and DATA[id]["giver"] == npc_name:
		return id
	if state in [Quests.STATE_ACTIVE, Quests.STATE_READY] and (receiver_of(id) == npc_name or DATA[id]["giver"] == npc_name):
		return id
	return ""


## Lochy Watry: po kroku DUNGEON_STEP (wykonany albo czeka na odbiór).
static func dungeons_unlocked(log: QuestLog) -> bool:
	return log.state_of(DUNGEON_STEP) in [Quests.STATE_READY, Quests.STATE_DONE]


## Zadanie poboczne, od którego oddania zależy krok (warunek ["quest", id]); "" - krok zależy od czegoś innego.
## Przyjmuje się je razem z krokiem (QuestLog.update_main), a oddaje u jego zleceniodawcy przed krokiem.
static func linked_quest(id: String) -> String:
	var check: Array = DATA.get(id, {}).get("check", [])
	return check[1] if not check.is_empty() and check[0] == "quest" else ""


## Postęp kroku w toku słowami (lista pod minimapą, rozmowa), np. "Drewno 12/30, Kamień 5/20".
static func progress_text(player: Player, id: String) -> String:
	var linked := linked_quest(id)
	if linked != "" and player.quests.state_of(linked) != Quests.STATE_DONE:
		match player.quests.state_of(linked):
			Quests.STATE_AVAILABLE:
				return "Przyjmij zadanie u: %s" % Quests.get_data(linked)["giver"]
			Quests.STATE_READY:
				return "Wróć do: %s" % Quests.receiver(linked)
		var needed: Dictionary = Quests.requirements(linked)
		if needed.is_empty():
			return "%s: %d/%d" % [Quests.get_data(linked)["target_name"], player.quests.progress_of(linked), Quests.get_data(linked)["count"]]
		var parts: Array[String] = []
		for item: String in needed:
			parts.append("%s %d/%d" % [Items.get_data(item)["name"], mini(player.count_owned(item), needed[item]), needed[item]])
		return ", ".join(parts)
	var have: Array = progress(player, id)
	return "%s: %d/%d" % [DATA[id]["target_name"], have[0], have[1]] if have[1] > 1 else DATA[id]["target_name"]


## Postęp kroku: [ile jest, ile trzeba].
static func progress(player: Player, id: String) -> Array:
	var check: Array = DATA[id]["check"]
	match check[0]:
		"talk":
			return [1, 1]
		"level":
			return [mini(player.stats.level, check[1]), check[1]]
		"quest":
			return [1 if player.quests.state_of(check[1]) == Quests.STATE_DONE else 0, 1]
		"built":
			return [mini(_built_count(player), check[1]), check[1]]
		"project":
			var world := player.get_tree().get_first_node_in_group("world") if player.is_inside_tree() else null
			return [1 if world != null and world.village_built(check[1]) else 0, 1]
		"herb":
			return [1 if player.codex.discovered.keys().any(func(item: String) -> bool: return item.begins_with("herb_")) else 0, 1]
		"nodes":
			return [mini(player.skills.points_spent(), check[1]), check[1]]
		"boss":
			return [mini(int(player.codex.kills.get(check[1], 0)), 1), 1]
		"watra":
			return [mini(player.boons.watra_level(), check[1]), check[1]]
		"shrine":
			var world := player.get_tree().get_first_node_in_group("world") if player.is_inside_tree() else null
			return [1 if world != null and world.shrines.has(check[1]) else 0, 1]
		"event":
			return [mini(int(player.quests.events.get(check[1], 0)), check[2]), check[2]]
		"enchant":
			var best := 0
			for slot in Equipment.SLOTS:
				best = maxi(best, player.equipment.get_enchant(slot))
			return [mini(best, check[1]), check[1]]
		"essence":
			return [1 if _has_essence(player) else 0, 1]
	return [0, 1]


static func satisfied(player: Player, id: String) -> bool:
	var have: Array = progress(player, id)
	return have[0] >= have[1]


static func _built_count(player: Player) -> int:
	var world := player.get_tree().get_first_node_in_group("world") if player.is_inside_tree() else null
	if world == null:
		return 0
	var count := 0
	for project: String in Settlement.PROJECTS:
		if world.village_built(project):
			count += 1
	return count


static func _has_essence(player: Player) -> bool:
	for slot: Dictionary in player.inventory.slots + player.storage.slots:
		if not slot.is_empty() and Essences.is_essence(slot["id"]):
			return true
	for slot in Equipment.SLOTS:
		var socket: Variant = Items.get_data(player.equipment.get_item(slot)).get("essence_socket")
		if socket is Dictionary and not socket.is_empty():
			return true
	for weapon_type: String in player.skills.tree_gems:
		if not player.skills.essence_in(weapon_type).is_empty():
			return true
	return false
