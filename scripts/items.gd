class_name Items
## Baza przedmiotów w grze. Złoto nie jest przedmiotem - trafia prosto do sakiewki.
##
## Pola przedmiotu:
## - price / sell_price - cena u kupca i ile kupiec za niego płaci,
## - use - efekt użycia (mikstury),
## - slot - typ miejsca na postaci (weapon, helmet, chest, gloves, boots, earring, ring, necklace),
## - stats - premie po założeniu: armor, health, mana, damage, atrybuty, attack_speed, move_speed i premie
##   z łupu (damage_percent, crit_chance, crit_damage, life_on_hit, health_regen, mana_regen, dodge_chance,
##   cooldown_reduction, gold_find, xp_gain - działanie w CharacterStats),
## - weapon - dane broni: type (melee / bow / spell), damage [min, max], speed, held (tekstura w ręku),
##   grip (chwyt w pikselach tej tekstury), hold (blade / bow / book), held_scale (skala rysowania - grafiki
##   z PixelLab mają 2x gęstszy piksel niż świat, więc 0,5), dla broni białej reach i arc,
##   dla dystansowej cooldown i projectile,
## - przedmioty do założenia (poza legendami) są w ItemBases (generowane z tools/item_catalog.py),
##   razem z looks - ikonami i bronią w ręku wersji magicznej i rzadkiej,
## - rarity - jakość: common (zwykły), magic, rare albo legendary (legendarny - unikalny łup z bossów,
##   z pomarańczowo-złotą ramką),
## - przedmioty z łupu (Loot) mają też item_level (1-100), base_stats (statystyki bazowe przeliczone
##   na poziom, bez premii), affixes (dolosowane premie) i tiers (tier każdej premii, 45-1),
## - effect - efekt legendarny: kind (shockwave / echo / tide / claws - szanse; might / fortune - moc),
##   wartość bazowa (chance) i przyrost za poziom zaklęcia (per_level),
## - stone - kamień zaklinający: category (weapon / armor / jewelry) i perfect,
## - enchant_aid - kamień wspierający zaklinanie: blessed (pewne wbicie) albo mercy (ochrona poziomu).
## Przedmioty do założenia mogą mieć poziom zaklęcia (patrz Enchanting).

const GOLD_ICON := preload("res://assets/items/coin.png")
const ARROW := preload("res://assets/projectiles/arrow.png")
const MAGIC_MISSILE := preload("res://assets/projectiles/magic_missile.png")

const RARITY_NAMES := {"common": "Zwykły", "magic": "Magiczny", "rare": "Rzadki", "legendary": "Legendarny"}
const RARITY_COLORS := {"common": Color(0.92, 0.92, 0.95), "magic": Color(0.45, 0.65, 1.0),
		"rare": Color(1.0, 0.86, 0.3), "legendary": Color(1.0, 0.62, 0.15)}
## Premie dolosowane do przedmiotu (Loot) są w opisie niebieskie.
const AFFIX_COLOR := "#8ab4ff"
const LEGENDARY_COLOR := Color(1.0, 0.62, 0.15)
## Opisy efektów legendarnych (%d - szansa w procentach).
## Wartość zmieniona przez inny założony przedmiot (np. Łzę Bulgora) - zielona w dymku.
const MODIFIED_COLOR := "#7cf07c"
## Efekty, których szanse zwiększa Łza Bulgora ("fortune").
## Efekty, których wartość to liczba sztuk (np. dodatkowe strzały), a nie procent.
const COUNT_EFFECTS := ["hydra_seekers", "seeker_split", "ballista_volley", "ballista_seeker", "blizzard_freeze", "endless_storm"]
const CHANCE_EFFECTS := ["shockwave", "tide", "claws", "echo", "thunder", "whirlpool", "roots", "thorns", "venom", "brood", "fear",
		"bomb", "blast_shot", "earth_arrow", "kaboom", "devour", "burrow", "raise_dead", "rend", "plunder", "pack_call", "tongue",
		"storm_arrows", "web_burst", "corpse_blast", "venom_chain", "feather_storm", "wind_shield",
		"dance", "vine_snare", "pan_echo", "potion_saver"]
const EFFECT_TEXTS := {
	"endless_whirl": "Wirujące Mgnienie (Mgnienie w trakcie Młynka) nie ma odnowienia, a Mgnienie zadaje +%s obrażeń",
	"shockwave": "%s szans przy trafieniu: fala uderzeniowa rani trafionego i wszystkich wokół, ogłuszając ich",
	"echo": "%s szans, że efekt przedmiotu (np. fala uderzeniowa) zadziała dwukrotnie",
	"tide": "%s szans przy trafieniu: fala wody uderza stożkiem za trafionym, raniąc i odpychając wrogów",
	"claws": "%s szans przy trafieniu: pazury tną zamaszyście dwoma łukami na krzyż, raniąc trafionego i wrogów obok",
	"might": "Siła, zręczność i inteligencja zwiększają obrażenia każdej broni - dwa atrybuty spoza broni dają %s premii głównego",
	"fortune": "+%s do wszystkich szans postaci (np. na efekty legendarnej biżuterii)",
	"thunder": "%s szans przy trafieniu: z nieba uderza piorun, który przeskakuje na dwóch pobliskich wrogów",
	"storm_dash": "Unik (spacja) zostawia ślad piorunów - rani wrogów na drodze za %s obrażeń broni",
	"whirlpool": "%s szans przy trafieniu: pod wrogiem otwiera się wir, który wciąga pobliskich wrogów i rani ich",
	"leech": "%s zadanych obrażeń wraca jako zdrowie",
	"roots": "%s szans przy trafieniu: spod wroga wystrzelają korzenie, które ranią i oplątują wszystkich wokół",
	"thorns": "%s szans, gdy ktoś cię zrani: wokół ciebie wybuchają ciernie, raniąc i odpychając wrogów",
	"venom": "%s szans przy trafieniu: jad zatruwa trafionego i wrogów obok (obrażenia przez 3 s)",
	"brood": "%s szans przy zabiciu wroga: wybiegają z niego dwa jadowite pajączki i rzucają się na wrogów",
	"fear": "%s szans przy trafieniu: mroczny ryk rani wrogów wokół i płoszy ich - uciekają w strachu",
	"bloodlust": "Każde zabójstwo daje +%s obrażeń na 5 s (kumuluje się do 5 razy)",
	"bomb": "%s szans przy trafieniu: rzucasz w trafionego bombą zapalającą (wybuch i płonąca plama)",
	"blast_shot": "Łuk, kostur i księga: %s szans, że pocisk wybuchnie przy trafieniu, raniąc wrogów obok",
	"earth_arrow": "Tylko łuk: %s szans przy trafieniu, że spod wroga wystrzeli kolec ziemi - rani i ogłusza",
	"kaboom": "%s szans, że pokonany wróg wybuchnie, raniąc wrogów obok",
	"devour": "%s szans, że pokonany wróg uleczy cię o 3%% maksymalnego zdrowia",
	"mine_trail": "Unik zostawia na drodze trzy bomby - każda rani za %s obrażeń broni",
	"burrow": "%s szans, że cios, po którym zostałoby ci mniej niż 35%% zdrowia, nie trafi - zakopujesz się i wystrzelasz z ziemi, raniąc wszystko wokół (raz na 25 s)",
	"tremor": "Co 4 s ziemia wokół ciebie drży, raniąc pobliskich wrogów za %s obrażeń broni",
	"raise_dead": "%s szans, że pokonany wróg wstanie jako twój szkielet sługa na 12 s",
	"soul_harvest": "Każdy pokonany wróg daje duszę - przy 10 duszach wyrywają się falą raniącą wrogów wokół za %s obrażeń broni",
	"bone_armor": "Co 8 s krążące kości pochłaniają następny cios (do %s maksymalnego zdrowia)",
	"undying": "Raz na 90 s cios śmiertelny zostawia cię przy życiu z %s zdrowia i wyzwala falę dusz",
	"rend": "%s szans przy trafieniu: rozdarta rana krwawi przez 3 s (łącznie 150%% obrażeń broni)",
	"corpse_leap": "Unik kończy się skokiem miażdżącym ziemię - rani wrogów wokół za %s obrażeń broni",
	"execute": "Ciosy w wrogów poniżej 25%% zdrowia zadają dodatkowo %s obrażeń broni (nie działa na bossów)",
	"corpse_blast": "%s szans, że wróg padający w pobliżu (także od efektów) wybuchnie trucizną, raniąc wrogów obok",
	"toxic_aura": "Trująca chmura wokół ciebie co pół sekundy rani wrogów za %s obrażeń broni",
	"hydra_seekers": "Strzała tropiąca wylatuje razem z %s dodatkowymi strzałami (wachlarzem)",
	"seeker_split": "Strzała tropiąca przy pierwszym trafieniu rozszczepia się na %s nowe strzały tropiące",
	"ballista_volley": "Balista (drzewko łuku) strzela salwą - wypuszcza naraz %s bełty więcej",
	"ballista_seeker": "Balista (drzewko łuku) strzela strzałami tropiącymi, a każda trafia do %s razy",
	"blizzard_freeze": "Zamieć (drzewko księgi) zawsze zamraża wrogów w kręgu na około %s s",
	"endless_storm": "Burza Peruna (drzewko księgi) trwa, dopóki trzymasz klawisz - za %s many na sekundę",
	"regrowth": "Gdy masz mniej niż 50%% zdrowia, odzyskujesz %s maksymalnego zdrowia na sekundę",
	"venom_chain": "%s szans przy trafieniu: jad zatruwa trafionego i przeskakuje na dwóch wrogów obok",
	"acid_trail": "Idąc, zostawiasz żrące kałuże - ranią wrogów za %s obrażeń broni co pół sekundy",
	"wind_crescent": "Cięcie mieczem (i każdą bronią do walki wręcz) wypuszcza półksiężyc wiatru za %s obrażeń broni",
	"gather": "Zamach bronią do walki wręcz ściąga wrogów przed ciebie (siła %s)",
	"fire_turret": "Kula ognia zawisa na 3 s i strzela płomieniami w wrogów (każdy za %s jej obrażeń), potem wybucha",
	"tornado_walk": "Biegnąc, co sekundę wypuszczasz trąbę powietrzną - wciąga i rani wrogów za %s obrażeń broni",
	"feather_storm": "%s szans przy trafieniu: wachlarz ostrych piór rani wrogów wokół trafionego",
	"wind_shield": "%s szans, że wiatr odbije wrogi pocisk lecący w ciebie",
	"dance": "%s szans przy trafieniu: wrogowie wokół trafionego zaczynają tańczyć do melodii fletni (ogłuszeni na 2 s)",
	"horn_charge": "Unik staje się szarżą z rogami - rani wrogów na drodze za %s obrażeń broni i odrzuca ich",
	"vine_snare": "%s szans, gdy ktoś cię zrani: pnącza oplątują wrogów wokół ciebie (nie mogą się ruszać przez 1,5 s)",
	"pan_echo": "%s szans przy trafieniu: dźwięk fletni bije falą przed tobą, raniąc i płosząc wrogów",
	"plunder": "%s szans, że pokonany wróg upuści dodatkowy przedmiot",
	"pack_call": "%s szans, gdy ktoś cię zrani: z mroku wyskakuje widmowy wilk i walczy u twego boku przez 12 s",
	"tongue": "%s szans przy trafieniu: język przyciąga najbliższego innego wroga i go rani",
	"storm_arrows": "Tylko łuk: %s szans przy trafieniu, że piorun przeskoczy z trafionego na dwóch pobliskich wrogów",
	"tidal_dodge": "Unik ciągnie za sobą falę, która odpycha wrogów i rani ich za %s obrażeń broni",
	"rooted_regen": "Stojąc w miejscu, odzyskujesz %s maksymalnego zdrowia na sekundę",
	"web_burst": "%s szans przy trafieniu: wrogów wokół trafionego oplątuje sieć (nie mogą się ruszać przez 1 s)",
	"berserk": "Gdy masz mniej niż 40%% zdrowia, zadajesz +%s obrażeń",
	"potion_saver": "%s szans, że wypita mikstura zdrowia albo many nie ubędzie z plecaka",
	"potion_fury": "Po wypiciu mikstury zdrowia albo many przez 6 s zadajesz +%s obrażeń",
	"bile_spit": "Co 5. trafienie plujesz żółcią przed siebie - trujące kałuże ranią wrogów za %s obrażeń broni co pół sekundy",
}
const SLOT_TYPE_NAMES := {
	"weapon": "Broń", "helmet": "Hełm", "chest": "Napierśnik", "gloves": "Rękawice", "boots": "Buty",
	"earring": "Kolczyk", "ring": "Pierścień", "necklace": "Naszyjnik", "belt": "Pas", "gem": "Kamień szlachetny",
}
const STAT_NAMES := {
	"armor": "Pancerz", "health": "Zdrowie", "mana": "Mana", "damage": "Obrażenia",
	"strength": "Siła", "dexterity": "Zręczność", "intelligence": "Inteligencja", "vitality": "Witalność",
	"attack_speed": "Szybkość ataku", "move_speed": "Szybkość ruchu", "cast_speed": "Szybkość rzucania czarów",
	"physical_damage": "Obrażenia fizyczne", "spell_damage": "Obrażenia magiczne",
	"damage_percent": "Zwiększone obrażenia", "crit_chance": "Szansa na cios krytyczny",
	"crit_damage": "Obrażenia krytyczne", "life_on_hit": "Zdrowie za trafienie",
	"health_regen": "Regeneracja zdrowia/s", "mana_regen": "Regeneracja many/s", "dodge_chance": "Szansa na unik",
	"cooldown_reduction": "Skrócenie odnowienia", "gold_find": "Więcej złota", "xp_gain": "Więcej doświadczenia",
	"area": "Obszar umiejętności", "potion_power": "Siła mikstur",
}
## Statystyki podawane w procentach.
const PERCENT_STATS: Array[String] = ["potion_power", "attack_speed", "move_speed", "damage_percent", "crit_chance", "crit_damage",
		"cast_speed", "physical_damage", "spell_damage",
		"dodge_chance", "cooldown_reduction", "gold_find", "xp_gain", "area"]
## Statystyki z częścią ułamkową (regeneracja na sekundę) - pokazywane z jednym miejscem po przecinku.
const DECIMAL_STATS: Array[String] = ["health_regen", "mana_regen"]
## Porównanie z założonym przedmiotem: lepsze / gorsze wartości, tier premii i nagłówek panelu założonego.
const BETTER_COLOR := "#7cf07c"
const WORSE_COLOR := "#ff6b6b"
const TIER_COLOR := "#8a8a9a"
const HEADER_COLOR := "#d8c890"
## Oddziela w dymku opis przedmiotu od opisu założonego, z którym go porównujemy (RichTooltip
## rysuje je obok siebie).
const COMPARE_SPLIT := "\u001f"

const DATA := {
	# ---------------------------------------------------------------- łupy i mikstury
	"rough_gem": {
		"name": "Surowy klejnot",
		"description": "Szara bryłka, w której coś kolorowo połyskuje. Jubiler Dobromir w Orlej Przełęczy będzie wiedział, co z tym zrobić.",
		"icon": preload("res://assets/items/rough_gem.png"),
		"sell_price": 5,
	},
	"goblin_heart": {
		"name": "Serce goblina",
		"description": "Jeszcze ciepłe. Ponoć alchemicy dobrze za nie płacą.",
		"icon": preload("res://assets/items/goblin_heart.png"),
		"sell_price": 8,
	},
	"iron_ore": {
		"name": "Ruda żelaza",
		"description": "Ciężka, rdzawa bryła. Najwięcej jej w złożach Wietrznych Turni, trochę kryją też zwykłe głazy. Kowal wykuwa z niej przedmioty.",
		"icon": preload("res://assets/items/iron_ore.png"),
		"sell_price": 4,
		"notable": true,
	},
	"goat_hide": {
		"name": "Skóra kozy",
		"description": "Biała, puszysta skóra górskiej kozy. Kupcy dobrze za nią płacą.",
		"icon": preload("res://assets/items/goat_hide.png"),
		"sell_price": 12,
	},
	"storm_feather": {
		"name": "Pióro burzy",
		"description": "Lotka ptakoczłeka - wciąż lekko iskrzy. Cenione przez kupców i szamanów.",
		"icon": preload("res://assets/items/storm_feather.png"),
		"sell_price": 14,
	},
	"wood": {
		"name": "Drewno",
		"description": "Świeżo porąbane kłody. Przyda się w osadzie - złóż je w magazynie.",
		"icon": preload("res://assets/items/wood.png"),
		"sell_price": 2,
		"notable": true,
	},
	"stone": {
		"name": "Kamień",
		"description": "Twardy łupany kamień. Przyda się w osadzie - złóż go w magazynie.",
		"icon": preload("res://assets/items/stone.png"),
		"sell_price": 2,
		"notable": true,
	},
	"wolf_pelt": {
		"name": "Skóra wilka",
		"description": "Gęste, szare futro. Kupcy i myśliwy chętnie ją kupią.",
		"icon": preload("res://assets/items/wolf_pelt.png"),
		"sell_price": 14,
	},
	"deer_hide": {
		"name": "Skóra jelenia",
		"description": "Gruba, brązowa skóra. Myśliwy i kupcy dobrze za nią zapłacą.",
		"icon": preload("res://assets/items/deer_hide.png"),
		"sell_price": 12,
	},
	"roe_hide": {
		"name": "Skóra sarny",
		"description": "Lekka, płowa skóra w jasne cętki.",
		"icon": preload("res://assets/items/roe_hide.png"),
		"sell_price": 8,
	},
	"boar_hide": {
		"name": "Skóra dzika",
		"description": "Twarda, szczeciniasta skóra. Świetna na pasy i buty.",
		"icon": preload("res://assets/items/boar_hide.png"),
		"sell_price": 10,
	},
	"hare_pelt": {
		"name": "Skórka zająca",
		"description": "Mała i puszysta. Na czapki i rękawice.",
		"icon": preload("res://assets/items/hare_pelt.png"),
		"sell_price": 4,
	},
	"meat": {
		"name": "Mięso",
		"description": "Świeża dziczyzna. Przywraca 15 punktów zdrowia - albo sprzedaj ją w osadzie.",
		"icon": preload("res://assets/items/meat.png"),
		"sell_price": 3,
		"use": {"health": 15},
	},
	"frog_tongue": {
		"name": "Żabi język",
		"description": "Długi, lepki język żaboczłeka. Alchemicy płacą za niego całkiem nieźle.",
		"icon": preload("res://assets/items/frog_tongue.png"),
		"sell_price": 9,
	},
	# ---------------------------------------------------------------- przyzwania bossów (rzemiosło)
	"summon_chief": {
		"name": "Krwawy Totem",
		"description": "Totem z sercem goblina, które wciąż bije. Wbity w leżu wodza goblinów (lewy górny róg lasu) natychmiast przyzywa Gruzłoga.",
		"icon": preload("res://assets/items/summon_chief.png"),
		"use": {"summon": "chief"}, "sell_price": 30, "notable": true,
	},
	"summon_alpha": {
		"name": "Wilczy Róg",
		"description": "Róg owinięty wilczym futrem. Zadęty w leżu wilka alfa (prawy dolny róg lasu) natychmiast przyzywa Szarokła.",
		"icon": preload("res://assets/items/summon_alpha.png"),
		"use": {"summon": "alpha"}, "sell_price": 30, "notable": true,
	},
	"summon_frog_chief": {
		"name": "Muszla Bulgora",
		"description": "Muszla wyłożona żabimi językami, szumiąca bagnem. Zadęta na wyspie wodza w wiosce żaboludzi (Rozlewiska) natychmiast przyzywa Bulgora.",
		"icon": preload("res://assets/items/summon_frog_chief.png"),
		"use": {"summon": "frog_chief"}, "sell_price": 30, "notable": true,
	},
	"summon_storm_eagle": {
		"name": "Burzowy Wabik",
		"description": "Pęk piór burzy z iskrzącym kryształem. Uniesiony w gnieździe wodza w wiosce ptakoludzi (Wietrzne Turnie) natychmiast przyzywa Gromoskrzydłego.",
		"icon": preload("res://assets/items/summon_storm_eagle.png"),
		"use": {"summon": "storm_eagle"}, "sell_price": 30, "notable": true,
	},
	"drowned_algae": {
		"name": "Wodorosty z topieli",
		"description": "Śliskie, czarnozielone wodorosty z sadzawek uroczyska. Zielarze i kupcy je skupują.",
		"icon": preload("res://assets/items/drowned_algae.png"),
		"sell_price": 6,
	},
	"drowned_pearl": {
		"name": "Perła topieli",
		"description": "Mętna perła z zielonym blaskiem w środku - ponoć dusza topielca. Bardzo cenna.",
		"icon": preload("res://assets/items/drowned_pearl.png"),
		"sell_price": 40,
		"notable": true,
	},
	"ancient_bark": {
		"name": "Prastara kora",
		"description": "Gruba, omszała kora drzewców z Prastarego Lasu. Wciąż ciepła i lekko pulsuje.",
		"icon": preload("res://assets/items/ancient_bark.png"),
		"sell_price": 8,
	},
	"kobold_fuse": {
		"name": "Lont kobolda",
		"description": "Pęk lontów z łuskowatym amuletem. Koboldy noszą je przy pasie jak trofea.",
		"icon": preload("res://assets/items/kobold_fuse.png"),
		"sell_price": 6,
	},
	"worm_tooth": {
		"name": "Ząb czerwia",
		"description": "Zakrzywiony, twardy jak kość ząb czerwia polnego. Rzemieślnicy robią z nich haczyki i grzebienie.",
		"icon": preload("res://assets/items/worm_tooth.png"),
		"sell_price": 6,
	},
	"bone_dust": {
		"name": "Proch z kości",
		"description": "Szary proch z rozsypanego szkieletu. Wciąż czuć w nim chłód nekromancji.",
		"icon": preload("res://assets/items/bone_dust.png"),
		"sell_price": 9,
	},
	"ghoul_claw": {
		"name": "Pazur trupojada",
		"description": "Czarny, zakrzywiony pazur ghula. Lepiej nie pytać, co ma za paznokciem.",
		"icon": preload("res://assets/items/ghoul_claw.png"),
		"sell_price": 9,
	},
	"hydra_scale": {
		"name": "Łuska Hydry",
		"description": "Twarda jak stal, ciemnozielona łuska, z której wciąż sączy się jad.",
		"icon": preload("res://assets/items/hydra_scale.png"),
		"sell_price": 40,
	},
	"gryf_feather": {
		"name": "Pióro Gryfa",
		"description": "Wielkie, złote pióro, lekkie jak wiatr. Mówią, że przynosi odwagę.",
		"icon": preload("res://assets/items/gryf_feather.png"),
		"sell_price": 40,
	},
	"satyr_horn": {
		"name": "Róg satyra",
		"description": "Zakręcony, wypolerowany róg satyra. Wciąż pachnie winem i dymem ogniska.",
		"icon": preload("res://assets/items/satyr_horn.png"),
		"sell_price": 12,
	},
	"spider_silk": {
		"name": "Pajęczy jedwab",
		"description": "Lśniący, niezwykle mocny jedwab z leża pająków. Tkacze płacą za niego dobrze.",
		"icon": preload("res://assets/items/spider_silk.png"),
		"sell_price": 7,
	},
	"spider_venom": {
		"name": "Pajęczy jad",
		"description": "Fiolka zielonego jadu z gruczołów pająka. Alchemicy i trucicielki ją skupują.",
		"icon": preload("res://assets/items/spider_venom.png"),
		"sell_price": 18,
	},
	"beast_fang": {
		"name": "Kieł bestii",
		"description": "Ogromny, zakrzywiony kieł bestii z Prastarego Lasu. Prawdziwe trofeum.",
		"icon": preload("res://assets/items/beast_fang.png"),
		"sell_price": 30,
		"notable": true,
	},
	"summon_bombardier": {
		"name": "Beczułka prochu",
		"description": "Beczułka z czaszką i tlącym się lontem. Postawiona za barykadą na północy Pól Zbożowych wywabia Bombardiera Kaszlaka.",
		"icon": preload("res://assets/items/summon_bombardier.png"),
		"use": {"summon": "bombardier"}, "sell_price": 30, "notable": true,
	},
	"summon_giant_worm": {
		"name": "Przynęta na czerwia",
		"description": "Gnijące mięso na wielkim haku. Rzucone do krateru na południowym zachodzie Pól Zbożowych przyzywa Pożeracza.",
		"icon": preload("res://assets/items/summon_giant_worm.png"),
		"use": {"summon": "giant_worm"}, "sell_price": 30, "notable": true,
	},
	"summon_necromancer": {
		"name": "Świeca Umarłych",
		"description": "Czarna świeca na czaszce, płonąca zielonym ogniem. Zapalona przed mauzoleum na Leśnym Cmentarzu wywołuje Mortana.",
		"icon": preload("res://assets/items/summon_necromancer.png"),
		"use": {"summon": "necromancer"}, "sell_price": 40, "notable": true,
	},
	"summon_colossal_ghoul": {
		"name": "Gnijący ochłap",
		"description": "Cuchnący kawał trupa. Rzucony w głąb trupowiska na Leśnym Cmentarzu zwabia Gnilca.",
		"icon": preload("res://assets/items/summon_colossal_ghoul.png"),
		"use": {"summon": "colossal_ghoul"}, "sell_price": 40, "notable": true,
	},
	"summon_hydra": {
		"name": "Bagienna Woda",
		"description": "Flaszka czarnej wody z okiem węża. Wylana na bagnie Hydry (Rozlewiska, zachodni skraj) budzi bestię.",
		"icon": preload("res://assets/items/summon_hydra.png"),
		"use": {"summon": "hydra"}, "sell_price": 60, "notable": true,
	},
	"summon_gryf": {
		"name": "Gryfi Róg",
		"description": "Złoty róg z piórami. Zadęty na wzgórzu na zachodzie Pól Zbożowych przywołuje Gryfa.",
		"icon": preload("res://assets/items/summon_gryf.png"),
		"use": {"summon": "gryf"}, "sell_price": 60, "notable": true,
	},
	"summon_satyr_king": {
		"name": "Złoty Kielich",
		"description": "Kielich wina z królewskiej tłoczni. Wzniesiony w królewskim gaju wioski satyrów (Wietrzne Turnie) przywołuje Faun-Króla.",
		"icon": preload("res://assets/items/summon_satyr_king.png"),
		"use": {"summon": "satyr_king"}, "sell_price": 40, "notable": true,
	},
	"summon_leshy": {
		"name": "Gałąź Leszego",
		"description": "Sękata gałąź z prastarej kory ze świecącą runą. Wbita w ziemię w kamiennym kręgu (Prastary Las) natychmiast przyzywa Leszego.",
		"icon": preload("res://assets/items/summon_leshy.png"),
		"use": {"summon": "leshy"}, "sell_price": 30, "notable": true,
	},
	"summon_spider_queen": {
		"name": "Jajo Królowej",
		"description": "Wielkie jajo oplecione jedwabiem i nasączone jadem. Rozbite przed wielką pajęczyną w leżu pająków (Prastary Las) natychmiast przyzywa Królową Pająków.",
		"icon": preload("res://assets/items/summon_spider_queen.png"),
		"use": {"summon": "spider_queen"}, "sell_price": 30, "notable": true,
	},
	"summon_bies": {
		"name": "Czaszka Biesa",
		"description": "Rogata czaszka nabita kłami bestii. Postawiona w kręgu czaszek w leżu Biesa (Prastary Las) natychmiast przyzywa Biesa.",
		"icon": preload("res://assets/items/summon_bies.png"),
		"use": {"summon": "bies"}, "sell_price": 30, "notable": true,
	},
	"summon_wodnik": {
		"name": "Fajka Wodnika",
		"description": "Wilgotna fajka owinięta wodorostami. Zapalona na wysepce w sercu Topielczego Uroczyska (Rozlewiska) natychmiast przyzywa Wodnika.",
		"icon": preload("res://assets/items/summon_wodnik.png"),
		"use": {"summon": "wodnik"}, "sell_price": 30, "notable": true,
	},
	"fish": {
		"name": "Ryba",
		"description": "Świeża ryba z rozlewisk. Przywraca 12 punktów zdrowia - albo sprzedaj ją w osadzie.",
		"icon": preload("res://assets/items/fish.png"),
		"sell_price": 5,
		"use": {"health": 12},
	},
	"antlers": {
		"name": "Poroże jelenia",
		"description": "Okazałe trofeum myśliwskie. Kupcy płacą za nie sporo.",
		"icon": preload("res://assets/items/antlers.png"),
		"sell_price": 30,
		"notable": true,
	},
	"pouch": {
		"name": "Sakwa",
		"description": "Skórzana sakwa przy pasie. Załóż ją (PPM), a plecak pomieści 10 rzeczy więcej.",
		"icon": preload("res://assets/items/pouch.png"),
		"bag": 10,
		"price": 400,
		"sell_price": 120,
	},
	"backpack": {
		"name": "Plecak",
		"description": "Pojemny plecak podróżny. Załóż go (PPM), a zmieścisz 20 rzeczy więcej.",
		"icon": preload("res://assets/items/backpack.png"),
		"bag": 20,
		"price": 1200,
		"sell_price": 350,
	},
	"health_potion": {
		"name": "Mikstura życia",
		"description": "Przywraca 40 punktów i 25% maksymalnego zdrowia.",
		"icon": preload("res://assets/items/health_potion.png"),
		"price": 25,
		"sell_price": 10,
		"use": {"health": 40, "health_percent": 0.25},
	},
	"mana_potion": {
		"name": "Mikstura many",
		"description": "Przywraca 30 punktów i 30% maksymalnej many.",
		"icon": preload("res://assets/items/mana_potion.png"),
		"price": 20,
		"sell_price": 8,
		"use": {"mana": 30, "mana_percent": 0.3},
	},
	"greater_health_potion": {
		"name": "Wielka mikstura życia",
		"description": "Warzona przez zielarkę z lecznicy Ostoi. Przywraca 80 punktów i 50% maksymalnego zdrowia.",
		"icon": preload("res://assets/items/greater_health_potion.png"),
		"price": 70,
		"sell_price": 25,
		"use": {"health": 80, "health_percent": 0.5},
	},
	"greater_mana_potion": {
		"name": "Wielka mikstura many",
		"description": "Warzona przez zielarkę z lecznicy Ostoi. Przywraca 60 punktów i 60% maksymalnej many.",
		"icon": preload("res://assets/items/greater_mana_potion.png"),
		"price": 60,
		"sell_price": 22,
		"use": {"mana": 60, "mana_percent": 0.6},
	},
	"guard_horn": {
		"name": "Róg straży",
		"description": "Mosiężny róg z herbem Ostoi. Zadęty przyzywa dwóch żołnierzy z koszar, którzy przez 30 sekund walczą u twojego boku.",
		"icon": preload("res://assets/items/guard_horn.png"),
		"price": 150,
		"sell_price": 40,
		"use": {"guards": 2},
	},

	# ---------------------------------------------------------------- zielarstwo (Herbs): zioła i mikstury zielarki
	"herb_wort": {
		"name": "Dziurawiec",
		"description": "Pęczek żółtego ziela z Goblińskiego Lasu. Zielarka zrobi z niego wywar wzmacniający zdrowie.",
		"icon": preload("res://assets/items/herb_wort.png"),
		"sell_price": 5,
	},
	"herb_chamomile": {
		"name": "Rumianek",
		"description": "Biały kwiat z miedz Pól Zbożowych. Zielarka zaparzy z niego napar, który goi rany.",
		"icon": preload("res://assets/items/herb_chamomile.png"),
		"sell_price": 5,
	},
	"herb_calamus": {
		"name": "Tatarak",
		"description": "Korzenne liście z brzegów Rozlewisk. Zielarka zrobi z nich nalewkę na manę.",
		"icon": preload("res://assets/items/herb_calamus.png"),
		"sell_price": 6,
	},
	"herb_arnica": {
		"name": "Arnika",
		"description": "Górski kwiat z Wietrznych Turni. Zielarka zrobi z niego eliksir siły.",
		"icon": preload("res://assets/items/herb_arnica.png"),
		"sell_price": 8,
	},
	"herb_fern": {
		"name": "Kwiat paproci",
		"description": "Legendarny kwiat, który zakwita w Prastarym Lesie. Rzadki - zielarka zrobi z niego eliksir szczęścia.",
		"icon": preload("res://assets/items/herb_fern.png"),
		"sell_price": 15,
	},
	"herb_datura": {
		"name": "Bieluń",
		"description": "Trujące ziele z Leśnego Cmentarza. W rękach zielarki - wywar przyspieszający ciosy.",
		"icon": preload("res://assets/items/herb_datura.png"),
		"sell_price": 10,
	},
	"elixir_wort": {
		"name": "Wywar z dziurawca",
		"description": "Gęsty, złoty wywar. Na 5 minut: +25% maks. zdrowia. Działa jedna mikstura naraz.",
		"icon": preload("res://assets/items/elixir_wort.png"),
		"sell_price": 15,
		"use": {"boon": "elixir_wort"},
	},
	"elixir_chamomile": {
		"name": "Napar z rumianku",
		"description": "Łagodny napar. Na 5 minut: +8 zdrowia na sekundę. Działa jedna mikstura naraz.",
		"icon": preload("res://assets/items/elixir_chamomile.png"),
		"sell_price": 15,
		"use": {"boon": "elixir_chamomile"},
	},
	"elixir_calamus": {
		"name": "Nalewka z tataraku",
		"description": "Zielona, korzenna nalewka. Na 5 minut: +5 many na sekundę i +8% szybkości ruchu. Działa jedna mikstura naraz.",
		"icon": preload("res://assets/items/elixir_calamus.png"),
		"sell_price": 18,
		"use": {"boon": "elixir_calamus"},
	},
	"elixir_arnica": {
		"name": "Eliksir z arniki",
		"description": "Ognisty eliksir. Na 5 minut: +15% zadawanych obrażeń. Działa jedna mikstura naraz.",
		"icon": preload("res://assets/items/elixir_arnica.png"),
		"sell_price": 24,
		"use": {"boon": "elixir_arnica"},
	},
	"elixir_fern": {
		"name": "Eliksir z kwiatu paproci",
		"description": "Mieni się złotymi iskrami. Na 5 minut: +8% szansy na trafienie krytyczne i +30% znajdowanego złota. Działa jedna mikstura naraz.",
		"icon": preload("res://assets/items/elixir_fern.png"),
		"sell_price": 45,
		"use": {"boon": "elixir_fern"},
	},
	"elixir_datura": {
		"name": "Wywar z bielunia",
		"description": "Ciemny, gorzki wywar. Na 5 minut: +20% szybkości ataku. Działa jedna mikstura naraz.",
		"icon": preload("res://assets/items/elixir_datura.png"),
		"sell_price": 30,
		"use": {"boon": "elixir_datura"},
	},

	# ---------------------------------------------------------------- kamienie zaklinające
	"weapon_stone": {
		"name": "Kamień zaklinania broni", "short_name": "Kamień broni", "description": "Czerwony kamień. Zaklina broń od +1 do +15.",
		"icon": preload("res://assets/items/weapon_stone.png"), "price": 250, "sell_price": 6, "stone": {"category": "weapon", "perfect": false},
	},
	"weapon_stone_perfect": {
		"name": "Doskonały kamień zaklinania broni", "short_name": "Doskonały kamień broni", "description": "Rzadki i jasny. Zaklina przedmioty z +15 na poziomy I-V.",
		"icon": preload("res://assets/items/weapon_stone_perfect.png"), "price": 3000, "sell_price": 40, "stone": {"category": "weapon", "perfect": true},
	},
	"armor_stone": {
		"name": "Kamień zaklinania zbroi", "short_name": "Kamień zbroi", "description": "Niebieski kamień. Zaklina zbroję od +1 do +15.",
		"icon": preload("res://assets/items/armor_stone.png"), "price": 250, "sell_price": 6, "stone": {"category": "armor", "perfect": false},
	},
	"armor_stone_perfect": {
		"name": "Doskonały kamień zaklinania zbroi", "short_name": "Doskonały kamień zbroi", "description": "Rzadki i jasny. Zaklina przedmioty z +15 na poziomy I-V.",
		"icon": preload("res://assets/items/armor_stone_perfect.png"), "price": 3000, "sell_price": 40, "stone": {"category": "armor", "perfect": true},
	},
	"jewelry_stone": {
		"name": "Kamień zaklinania biżuterii", "short_name": "Kamień biżuterii", "description": "Fioletowy kamień. Zaklina biżuterię od +1 do +15.",
		"icon": preload("res://assets/items/jewelry_stone.png"), "price": 250, "sell_price": 6, "stone": {"category": "jewelry", "perfect": false},
	},
	"jewelry_stone_perfect": {
		"name": "Doskonały kamień zaklinania biżuterii", "short_name": "Doskonały kamień biżuterii", "description": "Rzadki i jasny. Zaklina przedmioty z +15 na poziomy I-V.",
		"icon": preload("res://assets/items/jewelry_stone_perfect.png"), "price": 3000, "sell_price": 40, "stone": {"category": "jewelry", "perfect": true},
	},

	"blessed_stone": {
		"name": "Uświęcony kamień",
		"description": "Złoty i ciepły w dłoni. Zebrane razem gwarantują zaklęcie: 100 szt. na III, 200 na IV, 300 na V.",
		"icon": preload("res://assets/items/blessed_stone.png"), "price": 40, "sell_price": 2, "enchant_aid": "blessed",
	},
	"crystal_heart": {
		"name": "Serce Kryształu",
		"description": "Bijące żarem jądro Kryształu Watry (lochy od 3. stopnia). Kowal Bronisław wykuwa nim gniazdo na esencję legendy.",
		"icon": preload("res://assets/items/crystal_heart.png"), "sell_price": 40,
	},
	"mercy_stone": {
		"name": "Kamień miłosierdzia",
		"description": "Lazurowa kula. Zebrane razem chronią przed utratą poziomu przy nieudanym zaklęciu: 10 szt. przy III, 20 przy IV, 30 przy V.",
		"icon": preload("res://assets/items/mercy_stone.png"), "price": 60, "sell_price": 3, "enchant_aid": "mercy",
	},
	# ---------------------------------------------------------------- legendarne (łup z bossów)
	"ring_gruzlog": {
		"name": "Sygnet Gruzłoga", "description": "Ciężki złoty sygnet wodza goblinów. Każdy cios niesie się jak trzęsienie ziemi.",
		"icon": preload("res://assets/items/ring_gruzlog.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"strength": 6, "health": 25},
		"effect": {"kind": "shockwave", "chance": 0.10, "per_level": 0.006},
	},
	"ring_alpha": {
		"name": "Kieł Alfy", "description": "Srebrny pierścień z kłem wilka alfa. Echo jego wycia powtarza każdą moc.",
		"icon": preload("res://assets/items/ring_alpha.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"dexterity": 6, "health": 25},
		"effect": {"kind": "echo", "chance": 0.25, "per_level": 0.012},
	},
	"ring_bulgor": {
		"name": "Oko Przypływu", "description": "Pierścień Bulgora z morskim kamieniem, w którym wciąż szumi woda rozlewisk.",
		"icon": preload("res://assets/items/ring_bulgor.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"health": 20, "intelligence": 6},
		"effect": {"kind": "tide", "chance": 0.12, "per_level": 0.006},
	},
	"earring_gruzlog": {
		"name": "Kieł Gruzłoga", "description": "Kieł wodza goblinów w złotej oprawie. Każda cząstka siły zamienia się w cios.",
		"icon": preload("res://assets/items/earring_gruzlog.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"vitality": 5, "health": 15},
		"effect": {"kind": "might", "chance": 0.5, "per_level": 0.025},
	},
	"earring_alpha": {
		"name": "Pazur Szarokła", "description": "Trzy pazury wilka alfa na srebrnym kółku. Czasem same rzucają się na wroga.",
		"icon": preload("res://assets/items/earring_alpha.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"dexterity": 4, "attack_speed": 0.05},
		"effect": {"kind": "claws", "chance": 0.15, "per_level": 0.008},
	},
	"earring_bulgor": {
		"name": "Łza Bulgora", "description": "Kropla bagiennej wody, która nigdy nie wysycha. Przynosi szczęście temu, kto ją nosi.",
		"icon": preload("res://assets/items/earring_bulgor.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"intelligence": 4, "mana": 15},
		"effect": {"kind": "fortune", "chance": 0.3, "per_level": 0.015},
	},
	"ring_storm": {
		"name": "Pierścień Gromu", "description": "Stalowa obręcz z kryształem z gniazda Gromoskrzydłego. Pod palcami czuć mrowienie burzy.",
		"icon": preload("res://assets/items/ring_storm.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"intelligence": 4, "dexterity": 4, "health": 20},
		"effect": {"kind": "thunder", "chance": 0.12, "per_level": 0.006},
	},
	"earring_storm": {
		"name": "Lotka Burzy", "description": "Pióro z ogona Pana Burz. Kto je nosi, porusza się jak błyskawica.",
		"icon": preload("res://assets/items/earring_storm.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"dexterity": 4, "move_speed": 0.05},
		"effect": {"kind": "storm_dash", "chance": 0.8, "per_level": 0.04},
	},
	"ring_wodnik": {
		"name": "Pierścień Topieli", "description": "Zimna, srebrna obręcz z okiem, w którym wiruje czarna woda uroczyska.",
		"icon": preload("res://assets/items/ring_wodnik.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"vitality": 4, "health": 30},
		"effect": {"kind": "whirlpool", "chance": 0.1, "per_level": 0.005},
	},
	"earring_wodnik": {
		"name": "Perła Wodnika", "description": "Mętna perła, w której drga zielony ognik. Pije z każdej rany, którą zadasz.",
		"icon": preload("res://assets/items/earring_wodnik.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"strength": 3, "intelligence": 3, "health": 15},
		"effect": {"kind": "leech", "chance": 0.03, "per_level": 0.002},
	},
	"ring_leshy": {
		"name": "Obręcz Leszego", "description": "Pierścień z poskręcanego korzenia ze świętego kręgu. Ziemia odpowiada na każdy twój cios.",
		"icon": preload("res://assets/items/ring_leshy.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"vitality": 4, "strength": 3, "health": 25},
		"effect": {"kind": "roots", "chance": 0.12, "per_level": 0.006},
	},
	"earring_leshy": {
		"name": "Żołądź Leszego", "description": "Złoty żołądź oplątany cierniem. Kto podniesie rękę na jego właściciela, poczuje kolce puszczy.",
		"icon": preload("res://assets/items/earring_leshy.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"vitality": 4, "armor": 2},
		"effect": {"kind": "thorns", "chance": 0.35, "per_level": 0.02},
	},
	"ring_queen": {
		"name": "Pierścień Królowej", "description": "Czarna obręcz z czerwoną klepsydrą, oplątana pajęczym jedwabiem. Kapie z niej jad.",
		"icon": preload("res://assets/items/ring_queen.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"dexterity": 5, "intelligence": 3, "health": 15},
		"effect": {"kind": "venom", "chance": 0.2, "per_level": 0.01},
	},
	"earring_queen": {
		"name": "Jedwabny Kokon", "description": "Maleńki kokon z leża Królowej na srebrnym kółku. Czasem coś się w nim porusza.",
		"icon": preload("res://assets/items/earring_queen.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"dexterity": 3, "intelligence": 3, "mana": 10},
		"effect": {"kind": "brood", "chance": 0.25, "per_level": 0.012},
	},
	"ring_bies": {
		"name": "Róg Biesa", "description": "Obręcz z czarnego rogu demona puszczy, z żarzącym się okiem. Wrogowie czują w niej strach.",
		"icon": preload("res://assets/items/ring_bies.png"),
		"slot": "ring", "rarity": "legendary", "sell_price": 400, "stats": {"strength": 5, "health": 30},
		"effect": {"kind": "fear", "chance": 0.1, "per_level": 0.005},
	},
	"earring_bies": {
		"name": "Szpon Biesa", "description": "Zakrzywiony szpon Władcy Bestii w złotej oprawie. Każda krew rozpala go jeszcze bardziej.",
		"icon": preload("res://assets/items/earring_bies.png"),
		"slot": "earring", "rarity": "legendary", "sell_price": 400, "stats": {"strength": 3, "dexterity": 3, "attack_speed": 0.04},
		"effect": {"kind": "bloodlust", "chance": 0.05, "per_level": 0.003},
	},
}


const MAX_STACK := 9999


## Przedmioty magiczne i rzadkie wylosowane w trakcie gry (Loot): id -> dane.
static var generated := {}
static var generated_serial := 0


## Przedmiot z bazy: zwykłe przedmioty i legendy (DATA), przedmioty bazowe do założenia (ItemBases)
## albo wylosowane w trakcie gry (generated).
static func get_data(id: String) -> Dictionary:
	if DATA.has(id):
		return DATA[id]
	if ItemBases.DATA.has(id):
		return ItemBases.DATA[id]
	if Legends.has(id):
		return Legends.data(id)
	return generated.get(id, {})


static func rarity_of(id: String) -> String:
	return get_data(id).get("rarity", "common")


static func rarity_color(id: String) -> Color:
	return RARITY_COLORS.get(rarity_of(id), RARITY_COLORS["common"])


## Krótka nazwa do ciasnych miejsc (np. powiadomień o łupie).
static func short_name(id: String) -> String:
	var item := get_data(id)
	return item.get("short_name", item.get("name", ""))


static func is_usable(id: String) -> bool:
	return get_data(id).has("use")


static func is_equippable(id: String) -> bool:
	return get_data(id).has("slot")


## Ekwipunek gracza - opisy przedmiotów pokazują wartości już zmienione przez to, co ma na sobie.
static var worn: Equipment


static func is_legendary(id: String) -> bool:
	return get_data(id).get("rarity", "") == "legendary"


## Szansa (albo moc) efektu legendarnego (0..1) - zaklęcie ją zwiększa.
static func effect_chance(id: String, enchant := 0) -> float:
	var effect: Dictionary = get_data(id).get("effect", {})
	if effect.is_empty():
		return 0.0
	return float(effect["chance"]) + float(effect["per_level"]) * enchant


## Wartość efektu do opisu: szanse powiększone przez Łzę Bulgora są zielone, a w nawiasie
## widać, o ile wzrosły (np. "20% (+5%)"). Tekst w BBCode - dla dymków RichTooltip.
static func _effect_value_text(id: String, enchant: int) -> String:
	var base := effect_chance(id, enchant)
	var base_text := "%d%%" % roundi(base * 100.0)
	# efekty liczone w sztukach (dodatkowe strzały), nie w procentach
	if get_data(id)["effect"]["kind"] in COUNT_EFFECTS:
		return str(roundi(base))
	if worn == null or not get_data(id)["effect"]["kind"] in CHANCE_EFFECTS:
		return base_text
	var fortune := worn.effect_power("fortune")
	if fortune <= 0.0:
		return base_text
	var modified := minf(base * (1.0 + fortune), 1.0)
	var gain := roundi(modified * 100.0) - roundi(base * 100.0)
	if gain <= 0:
		return base_text
	return "[color=%s]%d%%[/color] (+%d%%)" % [MODIFIED_COLOR, roundi(modified * 100.0), gain]


## Sakwa albo plecak - zakładane w miejsca na torby, powiększają plecak.
static func is_bag(id: String) -> bool:
	return get_data(id).has("bag")


## Ile sztuk mieści się w jednym miejscu: wyposażenie i torby pojedynczo, cała reszta do 9999.
static func max_stack(id: String) -> int:
	return 1 if is_equippable(id) or is_bag(id) else MAX_STACK


## Nazwa z poziomem zaklęcia, np. "Żelazny miecz +7" albo "Kolczuga III".
static func display_name(id: String, enchant := 0) -> String:
	var item_name: String = get_data(id).get("name", "")
	return item_name if enchant <= 0 else "%s %s" % [item_name, Enchanting.level_name(enchant)]


## Poziom przedmiotu (przedmioty ze sklepu i dawne - 1).
static func item_level(id: String) -> int:
	return int(get_data(id).get("item_level", 1))


## Statystyki bazowe przedmiotu (z poziomem przedmiotu, bez premii i zaklęcia).
static func base_stats(id: String) -> Dictionary:
	var item := get_data(id)
	return item.get("base_stats", item.get("stats", {}))


## Premie przedmiotu po uwzględnieniu zaklęcia. Zaklęcie wzmacnia tylko statystyki bazowe przedmiotu,
## nie dolosowane premie: zbroja dostaje pancerz, biżuteria - premie liczbowe (bez procentowych),
## które ma przedmiot bazowy.
static func stats_of(id: String, enchant := 0) -> Dictionary:
	var stats: Dictionary = get_data(id).get("stats", {}).duplicate()
	# kamienie szlachetne w gniazdach (Gems)
	var socket_stats: Dictionary = get_data(id).get("socket_stats", {})
	for stat: String in socket_stats:
		stats[stat] = stats.get(stat, 0) + (socket_stats[stat] if Loot._step(stat) > 0.0 else int(socket_stats[stat]))
	var bonus := Enchanting.bonus(enchant)
	if bonus == 0:
		return stats
	match Enchanting.category(id):
		"armor":
			stats["armor"] = stats.get("armor", 0) + bonus
		"jewelry":
			for stat: String in base_stats(id):
				if not stat in PERCENT_STATS:
					stats[stat] = stats.get(stat, 0) + bonus
	return stats


## Obrażenia broni [min, max] po uwzględnieniu zaklęcia ([] jeśli to nie broń).
static func weapon_damage(id: String, enchant := 0) -> Array:
	var weapon: Dictionary = get_data(id).get("weapon", {})
	if weapon.is_empty():
		return []
	var bonus := Enchanting.bonus(enchant)
	return [weapon["damage"][0] + bonus, weapon["damage"][1] + bonus]


## Statystyki do wyświetlenia: [[nazwa, tekst, wartość liczbowa], ...].
static func stat_lines(id: String, enchant := 0) -> Array:
	var lines := []
	var damage := weapon_damage(id, enchant)
	if not damage.is_empty():
		lines.append(["Obrażenia", "%d-%d" % damage, damage[0]])
	var stats := stats_of(id, enchant)
	for stat: String in stats:
		var value: float = stats[stat]
		if stat in PERCENT_STATS:
			lines.append([STAT_NAMES[stat], "+%d%%" % roundi(value * 100.0), value])
		elif stat in DECIMAL_STATS:
			lines.append([STAT_NAMES[stat], "+%.1f" % value, value])
		else:
			lines.append([STAT_NAMES[stat], "+%d" % value, value])
	return lines


## Pełny opis przedmiotu do dymka podpowiedzi. `against` ({"id", "enchant"}) - założony przedmiot, z którym
## porównujemy: statystyki bazowe dostają znacznik lepszej / gorszej bazy (bez zaklęcia), premie - lepszej /
## gorszej sumy tej statystyki, a na końcu jest lista zmian po założeniu.
static func describe(id: String, enchant := 0, against := {}) -> String:
	var item := get_data(id)
	if item.is_empty():
		return ""
	var other: String = against.get("id", "")
	var other_enchant: int = against.get("enchant", 0)
	var lines: Array[String] = [display_name(id, enchant)]
	if rarity_of(id) != "common":
		lines[0] = "[color=#%s]%s[/color]" % [rarity_color(id).to_html(false), lines[0]]
	if item.has("slot"):
		lines.append("%s - %s" % [RARITY_NAMES.get(item.get("rarity", "common"), ""), SLOT_TYPE_NAMES[item["slot"]]])
		if item.has("item_level"):
			lines.append("Poziom przedmiotu: %d" % item["item_level"])
	if item.has("gem"):
		lines.append("%s - Kamień szlachetny" % RARITY_NAMES.get(item.get("rarity", "magic"), ""))
	var bonus := Enchanting.bonus(enchant)
	if item.has("weapon"):
		var weapon: Dictionary = item["weapon"]
		var damage := weapon_damage(id, enchant)
		var text := "Obrażenia: %d-%d%s" % [damage[0], damage[1], " (+%d)" % bonus if bonus > 0 else ""]
		if other != "":
			text += _marker(_average(weapon_damage(id)), _average(weapon_damage(other)), "baza")
		lines.append(text)
		var other_speed: float = get_data(other).get("weapon", {}).get("speed", 1.0) if other != "" else 1.0
		if weapon["speed"] != 1.0 or other_speed != weapon["speed"]:
			lines.append("Szybkość ataku: %d%%" % roundi(weapon["speed"] * 100.0)
					+ (_marker(weapon["speed"], other_speed) if other != "" else ""))
		lines.append({"melee": "Broń biała", "bow": "Broń dystansowa", "spell": "Magia (bez kosztu many)"}[weapon["type"]])
	# statystyki bazowe z zaklęciem (w nawiasie jego premia), potem niebieskie premie z tierem
	var base := base_stats(id)
	var affixes: Dictionary = item.get("affixes", {})
	var socket_stats: Dictionary = item.get("socket_stats", {})
	var stats := stats_of(id, enchant)
	for stat: String in stats:
		var value: float = float(stats[stat]) - float(affixes.get(stat, 0)) - float(socket_stats.get(stat, 0))
		if not base.has(stat) and value <= 0.0:
			continue
		var added := value - float(base.get(stat, 0))
		var text := _stat_text(stat, value) + (" (+%d)" % added if added > 0 and not stat in PERCENT_STATS else "")
		if other != "":
			text += _marker(float(base.get(stat, 0)), float(base_stats(other).get(stat, 0)), "baza")
		lines.append(text)
	var tiers: Dictionary = item.get("tiers", {})
	var other_stats := stats_of(other, other_enchant) if other != "" else {}
	for stat: String in affixes:
		var text := "[color=%s]%s[/color]" % [AFFIX_COLOR, _stat_text(stat, affixes[stat])]
		if tiers.has(stat):
			text += " [color=%s](T%d)[/color]" % [TIER_COLOR, tiers[stat]]
		if other != "":
			text += _marker(float(stats[stat]), float(other_stats.get(stat, 0)))
		lines.append(text)
	for gem: Dictionary in item.get("sockets", []):
		lines.append("[img=8x8]%s[/img] %s" % [Gems.SOCKET_ICON.resource_path, Gems.socket_text(gem)])
	if item.has("essence_socket"):
		lines.append("[img=8x8]%s[/img] %s" % [Essences.SOCKET_ICON.resource_path, Essences.socket_text(item["essence_socket"])])
	if item.get("use", {}).has("summon"):
		lines.append("Przedmiot przyzwania - PPM w leżu bossa")
	if item.has("effect"):
		lines.append("Efekt: " + EFFECT_TEXTS[item["effect"]["kind"]] % _effect_value_text(id, enchant))
	lines.append(item["description"])
	if other != "":
		lines.append_array(_changes(id, enchant, other, other_enchant))
	return "\n".join(lines)


## Dymek przedmiotu, który można założyć: obok jego opisu - opis założonego przedmiotu, który zastąpi
## (ten sam rodzaj miejsca; przy wolnym miejscu nie ma z czym porównać). `extra` - dopiski pod opisem
## (np. "PPM - załóż").
static func tooltip(id: String, enchant := 0, extra := "") -> String:
	var worn_id := ""
	var worn_enchant := 0
	if worn != null and is_equippable(id):
		var slot := worn.slot_for(id)
		worn_id = worn.get_item(slot)
		worn_enchant = worn.get_enchant(slot)
	if worn_id == "":
		return describe(id, enchant) + extra
	return describe(id, enchant, {"id": worn_id, "enchant": worn_enchant}) + extra + COMPARE_SPLIT \
			+ "[color=%s]Założony[/color]\n" % HEADER_COLOR + describe(worn_id, worn_enchant)


## "+12 zdrowie" albo "+5% szybkość ruchu".
static func _stat_text(stat: String, value: float) -> String:
	if stat in PERCENT_STATS:
		return "%+d%% %s" % [roundi(value * 100.0), STAT_NAMES[stat].to_lower()]
	if stat in DECIMAL_STATS:
		return "%+.1f %s" % [value, STAT_NAMES[stat].to_lower()]
	return "%+d %s" % [roundi(value), STAT_NAMES[stat].to_lower()]


## Czy różnica statystyki jest widoczna po zaokrągleniu do sposobu jej wyświetlania.
static func _visible_diff(stat: String, diff: float) -> bool:
	if stat in PERCENT_STATS:
		return roundi(diff * 100.0) != 0
	if stat in DECIMAL_STATS:
		return absf(diff) >= 0.05
	return roundi(diff) != 0


## Znacznik porównania: zielony ▲ (więcej niż w założonym), czerwony ▼ (mniej), nic przy równych.
## `what` - dopisek przy znaczniku (np. "baza").
static func _marker(value: float, other_value: float, what := "") -> String:
	if is_equal_approx(value, other_value):
		return ""
	var better := value > other_value
	return " [color=%s]%s%s[/color]" % [BETTER_COLOR if better else WORSE_COLOR, "▲" if better else "▼",
			" " + what if what != "" else ""]


static func _average(damage: Array) -> float:
	return 0.0 if damage.is_empty() else (damage[0] + damage[1]) / 2.0


## Zmiany statystyk po założeniu przedmiotu zamiast porównywanego (z zaklęciami obu).
static func _changes(id: String, enchant: int, other: String, other_enchant: int) -> Array[String]:
	var lines: Array[String] = ["[color=%s]Po założeniu:[/color]" % HEADER_COLOR]
	var damage := weapon_damage(id, enchant)
	var other_damage := weapon_damage(other, other_enchant)
	if not damage.is_empty() or not other_damage.is_empty():
		var low: int = (damage[0] if not damage.is_empty() else 0) - (other_damage[0] if not other_damage.is_empty() else 0)
		var high: int = (damage[1] if not damage.is_empty() else 0) - (other_damage[1] if not other_damage.is_empty() else 0)
		if low != 0 or high != 0:
			var color := BETTER_COLOR if low + high > 0 else WORSE_COLOR
			lines.append("[color=%s]Obrażenia broni %+d / %+d[/color]" % [color, low, high])
	var stats := stats_of(id, enchant)
	var other_stats := stats_of(other, other_enchant)
	for stat: String in STAT_NAMES:
		var diff := float(stats.get(stat, 0)) - float(other_stats.get(stat, 0))
		if not _visible_diff(stat, diff):
			continue
		lines.append("[color=%s]%s[/color]" % [BETTER_COLOR if diff > 0 else WORSE_COLOR, _stat_text(stat, diff)])
	if lines.size() == 1:
		lines.append("bez zmian")
	return lines
