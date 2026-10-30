extends Node2D
## Generuje leśną planszę: trawę, dekoracje, przeszkody (drzewa i głazy do zbierania, krzaki)
## oraz obozowiska goblinów i grupki goblinów w lesie. Brzegi mapy to gęsty las,
## a w środku stoi osada Ostoja (patrz Settlement), w której gracz startuje
## i odradza się po śmierci. Wokół osady jest szeroka łąka bez drzew. Przez osadę biegnie kręta droga z prawego górnego
## do lewego dolnego rogu mapy, po której co jakiś czas jedzie wóz z eskortą.
## W prawym dolnym rogu leży ciemne siedlisko wilków (nory i truchła jeleni).
## W skrajnych rogach czekają bossowie: wódz goblinów (lewy górny) i wilk alfa (prawy dolny).
## Z prawego górnego rogu droga prowadzi do drugiej krainy - rozlewisk (patrz Zones),
## a odkryte kapliczki odrodzenia pozwalają się między nimi teleportować z dużej mapy.
## W prawym górnym i lewym dolnym rogu są łowiska: polany z pasącymi się jeleniami,
## sarnami, dzikami i zającami, które nie atakują, tylko uciekają przed graczem.
## Pokonane potwory po pewnym czasie odradzają się na swoich miejscach.

@export var map_size := Vector2i(200, 150)
@export var border_thickness := 4
## Pas wolnego terenu wokół osady (w kafelkach) - łąka bez drzew.
@export var settlement_margin := 6
## 0 = za każdym razem inna mapa.
@export var map_seed := 0

@export_group("Obozowiska goblinów")
@export var camp_count := 5
@export var campfires_per_camp_min := 3
@export var campfires_per_camp_max := 4
@export var goblins_per_fire_min := 5
@export var goblins_per_fire_max := 8
## Promień polany obozu (w kafelkach).
@export var camp_radius := 12
## Obszar goblinów jako ułamek mapy - domyślnie lewy górny róg.
## Obozy i grupki pojawiają się tylko tutaj.
@export var goblin_area := Rect2(0.0, 0.0, 0.5, 0.62)
## Minimalny odstęp obozu i grupki od osady (w kafelkach, od palisady).
@export var settlement_clearance := 8.0

@export_group("Grupki goblinów")
@export var goblin_group_count := 26
@export var goblins_per_group_min := 3
@export var goblins_per_group_max := 6

@export_group("Siedlisko wilków")
## Obszar wilków jako ułamek mapy - domyślnie prawy dolny róg.
@export var wolf_area := Rect2(0.6, 0.58, 0.4, 0.42)
@export var den_count := 8
@export var wolves_per_den_min := 7
@export var wolves_per_den_max := 11
## Promień polany przy norze (w kafelkach).
@export var den_radius := 6
@export var carcass_count := 30
@export var wolves_per_carcass_min := 3
@export var wolves_per_carcass_max := 5
## Mrok w głębi siedliska: kolor i krycie nakładanej warstwy (alfa = jak bardzo ciemno).
@export var wolf_area_shadow := Color(0.03, 0.05, 0.12, 0.5)
## Na ilu kafelkach od krawędzi obszaru las stopniowo ciemnieje.
@export var wolf_area_fade := 9.0

@export_group("Łowiska")
## Obszary zwierzyny jako ułamki mapy - domyślnie prawy górny i lewy dolny róg.
@export var hunting_areas: Array[Rect2] = [Rect2(0.62, 0.03, 0.35, 0.3), Rect2(0.03, 0.64, 0.34, 0.33)]
## Ile stad (jeleni, saren, dzików) i ile zajęcy na jedno łowisko.
@export var herds_per_area := 9
@export var hares_per_area := 8
## Minimalna odległość pastwisk od osady (w kafelkach) - zwierzyna trzyma się z dala od ludzi.
@export var hunting_clearance := 22.0
## Po ilu sekundach upolowane zwierzę wraca na swoje pastwisko.
@export var animal_respawn_time := 90.0

@export_group("Rozlewiska")
## Zwierzyna w rozlewiskach - dużo rzadsza niż w lesie, w lewym górnym i prawym dolnym rogu.
@export var swamp_hunting_areas: Array[Rect2] = [Rect2(0.04, 0.12, 0.34, 0.34), Rect2(0.6, 0.62, 0.36, 0.33)]
@export var swamp_herds_per_area := 3
@export var swamp_hares_per_area := 3

@export_group("Droga i karawany")
## Po ilu sekundach od startu pojawia się pierwszy wóz i co ile (losowo) kolejne.
@export var first_caravan_delay := 20.0
@export var caravan_interval_min := 90.0
@export var caravan_interval_max := 150.0

@export_group("Bossowie")
## Promień polany leża bossa (w kafelkach).
@export var lair_radius := 10
## Po ilu sekundach pokonany boss wraca do swojego leża (odpoczynek w karczmie wskrzesza go od razu).
@export var boss_respawn_time := 300.0
const BOSS_TYPES := ["chief", "alpha", "frog_chief", "storm_eagle", "wodnik", "leshy", "spider_queen", "bies",
		"bombardier", "giant_worm", "necromancer", "colossal_ghoul", "hydra", "gryf", "satyr_king"]
## Jak blisko leża trzeba stać, żeby użyć przedmiotu przyzwania.
const SUMMON_RADIUS := 130.0
const LAIR_NAMES := {
	"chief": "w leżu wodza goblinów (lewy górny róg lasu)",
	"alpha": "w leżu wilka alfa (prawy dolny róg lasu)",
	"frog_chief": "na wyspie wodza w wiosce żaboludzi (Rozlewiska)",
	"storm_eagle": "w gnieździe wodza w wiosce ptakoludzi (Wietrzne Turnie)",
	"wodnik": "na wysepce w sercu Topielczego Uroczyska (Rozlewiska, lewy dolny róg)",
	"leshy": "w kamiennym kręgu Leszego (Prastary Las, północ)",
	"spider_queen": "przed wielką pajęczyną w leżu pająków (Prastary Las, północny zachód)",
	"bies": "w kręgu czaszek w leżu Biesa (Prastary Las, południowy zachód)",
	"bombardier": "za barykadą prochu na północy Pól Zbożowych",
	"giant_worm": "w kraterze Pożeracza (Pola Zbożowe, południowy zachód)",
	"necromancer": "przed mauzoleum na północnym zachodzie Leśnego Cmentarza",
	"colossal_ghoul": "w głębi trupowiska na wschodzie Leśnego Cmentarza",
	"hydra": "na bagnie Hydry (Rozlewiska, zachodni skraj pod drogą od wejścia)",
	"gryf": "na skalistym wzgórzu w lewym górnym rogu Pól Zbożowych",
	"satyr_king": "w królewskim gaju wioski satyrów (Wietrzne Turnie, południowy wschód)",
}
## id miejsc bossów, którzy właśnie są przyzywani (krąg jeszcze się ładuje).
var _summoning := {}

@export_group("Odradzanie goblinów")
## Po ilu sekundach pokonany goblin pojawia się ponownie.
@export var goblin_respawn_time := 30.0
## Goblin nie odrodzi się, jeśli gracz stoi bliżej niż tyle pikseli.
@export var respawn_min_player_distance := 200.0

const TILE := 16
const OAK := preload("res://scenes/props/tree_oak.tscn")
const PINE := preload("res://scenes/props/tree_pine.tscn")
const BOULDER := preload("res://scenes/props/boulder.tscn")
const BUSH := preload("res://scenes/props/bush.tscn")
const STUMP := preload("res://scenes/props/stump.tscn")
const CAMPFIRE := preload("res://scenes/props/campfire.tscn")
const GOBLIN := preload("res://scenes/goblin.tscn")
const WOLF := preload("res://scenes/wolf.tscn")
const GOBLIN_CHIEF := preload("res://scenes/goblin_chief.tscn")
const ALPHA_WOLF := preload("res://scenes/alpha_wolf.tscn")
const GOBLIN_ARCHER := preload("res://scenes/goblin_archer.tscn")
const GOBLIN_BRUTE := preload("res://scenes/goblin_brute.tscn")
const WARG := preload("res://scenes/warg.tscn")
const ANIMAL_SCENES := {
	"deer": preload("res://scenes/deer.tscn"),
	"roe": preload("res://scenes/roe.tscn"),
	"boar": preload("res://scenes/boar.tscn"),
	"hare": preload("res://scenes/hare.tscn"),
	"goat": preload("res://scenes/goat.tscn"),
}
## Wielkość stada: [od, do].
const HERD_SIZES := {"deer": [2, 4], "roe": [2, 4], "boar": [3, 5], "hare": [1, 1], "goat": [3, 5]}
const DECO_TEXTURE := preload("res://assets/forest/deco.png")
## Rekwizyty obozów i siedlisk z PixelLab (tools/forest_props.py).
const FOREST_PROPS := {
	"tent": preload("res://scenes/props/forest/tent.tscn"),
	"hide_tent": preload("res://scenes/props/forest/hide_tent.tscn"),
	"weapon_rack": preload("res://scenes/props/forest/weapon_rack.tscn"),
	"cage": preload("res://scenes/props/forest/cage.tscn"),
	"hide_rack": preload("res://scenes/props/forest/hide_rack.tscn"),
	"loot": preload("res://scenes/props/forest/loot.tscn"),
	"banner": preload("res://scenes/props/forest/banner.tscn"),
	"shields": preload("res://scenes/props/forest/shields.tscn"),
	"pots": preload("res://scenes/props/forest/pots.tscn"),
	"bedroll": preload("res://scenes/props/forest/bedroll.tscn"),
	"log_seat": preload("res://scenes/props/forest/log_seat.tscn"),
	"skull_totem": preload("res://scenes/props/forest/skull_totem.tscn"),
	"bone_pile": preload("res://scenes/props/forest/bone_pile.tscn"),
	"barrel": preload("res://scenes/props/forest/barrel.tscn"),
	"cauldron": preload("res://scenes/props/forest/cauldron.tscn"),
	"palisade": preload("res://scenes/props/forest/palisade.tscn"),
	"goblin_tent_0": preload("res://scenes/props/forest/goblin_tent_0.tscn"),
	"goblin_tent_1": preload("res://scenes/props/forest/goblin_tent_1.tscn"),
	"goblin_tent_2": preload("res://scenes/props/forest/goblin_tent_2.tscn"),
	"goblin_tent_3": preload("res://scenes/props/forest/goblin_tent_3.tscn"),
	"wolf_den": preload("res://scenes/props/forest/wolf_den.tscn"),
	"carcass": preload("res://scenes/props/forest/carcass.tscn"),
	"ribcage": preload("res://scenes/props/forest/ribcage.tscn"),
	"dead_tree": preload("res://scenes/props/forest/dead_tree.tscn"),
	"hollow_log": preload("res://scenes/props/forest/hollow_log.tscn"),
	"flat_rock": preload("res://scenes/props/forest/flat_rock.tscn"),
	"skull_pole": preload("res://scenes/props/forest/skull_pole.tscn"),
	"thorns": preload("res://scenes/props/forest/thorns.tscn"),
	"boulders": preload("res://scenes/props/forest/boulders.tscn"),
	"dead_stump": preload("res://scenes/props/forest/dead_stump.tscn"),
	"bone_throne": preload("res://scenes/props/forest/bone_throne.tscn"),
	"wolf_totem": preload("res://scenes/props/forest/wolf_totem.tscn"),
}
## Kości rozrzucone w siedlisku wilków (ozdoby bez kolizji).
const BONE_TEXTURES: Array[Texture2D] = [preload("res://assets/forest/props/bones.png"),
		preload("res://assets/forest/props/antlers.png"), preload("res://assets/forest/props/skull_bones.png")]
## Przeszkody w głębi siedliska wilków: martwe drzewa, ciernie, głazy, pale z czaszkami.
const WILD_PROPS := ["dead_tree", "dead_tree", "thorns", "thorns", "boulders", "hollow_log", "dead_stump", "flat_rock", "skull_pole"]
const CAMP_CLUTTER := ["weapon_rack", "hide_rack", "shields", "pots", "barrel"]
## Duże namioty obozu goblinów (każdy obóz dostaje różne), ich odległość od kręgu ognisk (kafelki),
## odstęp pali barykady i szerokość wyjść (piksele).
const CAMP_TENTS := ["goblin_tent_0", "goblin_tent_1", "goblin_tent_2", "goblin_tent_3"]
## Wejście do leża wodza (lewy górny róg mapy) - od strony środka lasu.
const CHIEF_LAIR_EXIT := Vector2(0.8, 0.6)
const CAMP_TENT_RING := 3.6
const CAMP_STAKE_SPACING := 34.0
const CAMP_GATE_WIDTH := 64.0
## Plac musztry goblinów między obozami: półosie udeptanego owalu (kafelki), liczba goblinów w szeregu,
## kukła strzelnicy (z osady).
const DRILL_RADII := Vector2(7.5, 5.5)
const DRILL_RANK := 5
const DRILL_DUMMY := preload("res://assets/village/dummy.png")
const DECO_FRAMES := 31

const GRASS_TILES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1)]
const FLOWER_TILE := Vector2i(0, 1)
const DARK_TILES: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1)]
## Runo Goblińskiego Lasu z PixelLab (tools/forest_sheets.py): zestawy przejść Wang łąka -> ciemna
## trawa / droga / kwiaty, po 4 rzędy od FOREST_WANG_ROW. Kafelek o masce narożników mask
## (NW<<3 | NE<<2 | SW<<1 | SE, bit = górny teren) leży w kolumnie mask % 4 i rzędzie
## FOREST_WANG_ROW + 4 * zestaw + mask / 4; maska 0 każdego zestawu to wariant czystej łąki.
const FOREST_WANG_ROW := 23
enum Lawn { GRASS, DARK, ROAD, FLOWERS }
## Rozlewiska: zestawy Wang łąka -> błoto, błoto -> płycizna, płycizna -> głębia (po 4 rzędy).
const SWAMP_WANG_ROW := 35
## Wietrzne Turnie: zestawy Wang hala -> skała, hala -> żwir (po 4 rzędy).
const ALPINE_WANG_ROW := 47
## Bruk placu osady: zestaw Wang łąka -> bruk.
const COBBLE_WANG_ROW := 55
const LAWN_PRIORITY := [Lawn.ROAD, Lawn.DARK, Lawn.FLOWERS]

# kolory na mapie / minimapie
const MAP_GRASS := Color("4a8236")
const MAP_DARK_GRASS := Color("3e7330")
const MAP_CAMP := Color("8a7a4a")
const MAP_TREE := Color("1f4d2a")
const MAP_PINE := Color("17402d")
const MAP_BUSH := Color("2f6b34")
const MAP_ROCK := Color("7d8192")
const MAP_STUMP := Color("6b4226")
const MAP_FIRE := Color("ff9a3c")
const MAP_TENT := Color("c8a46e")
const MAP_DIRT := Color("9c7b52")
const MAP_DEN := Color("2a1a10")
const MAP_CARCASS := Color("a8303c")
const MAP_BOSS := Color("c040ff")
const ROAD_TILES: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2)]
## Rozlewiska: woda głęboka (nurt rzeki), płycizna, błoto i podmokły brzeg.
const MAP_DEEP := Color("24476e")
const MAP_SHALLOW := Color("3f6f62")
const MAP_MUD := Color("5a4a32")
const MAP_MANGROVE := Color("1d4a30")
const MAP_BRIDGE := Color("a07848")
## Promienie nurtu rzeki (w kafelkach): głęboko, płytko przy brzegu, podmokły brzeg.
const SWAMP_RIVER_DEEP := 2.4
const SWAMP_RIVER_SHALLOW := 3.5
const SWAMP_RIVER_BANK := 4.6
## Warstwa fizyki głębokiej wody - zatrzymuje postać, ale nie pociski.
const WATER_LAYER := 8
const MANGROVE := preload("res://scenes/props/tree_mangrove.tscn")
const SHRINE := preload("res://scenes/props/shrine.tscn")
const CATTAIL_TEXTURE := preload("res://assets/swamp/v2_cattails.png")
const REEDS_TEXTURE := preload("res://assets/swamp/v2_reeds.png")
const LILY_TEXTURE := preload("res://assets/swamp/v2_lilies.png")
## Skarpy rzeki: kamienie, korzenie i kłody przy wodzie; most i kładki z desek (Rozlewiska po przeróbce).
const BANK_ROCKS := preload("res://assets/swamp/v2_rocks.png")
const DECK_TEXTURE := preload("res://assets/swamp/v2_deck48.png")
const WALK_H := preload("res://assets/swamp/v2_walk_h.png")
const WALK_V := preload("res://assets/swamp/v2_walk_v.png")
const BRIDGE_RAIL_V2 := preload("res://assets/swamp/v2_rail.png")
const BRIDGE_POST_V2 := preload("res://assets/swamp/v2_post.png")
const WATER_PILLAR := preload("res://assets/swamp/v2_pillar.png")
const SIGNPOST_TEXTURE := preload("res://assets/swamp/signpost.png")
## Wioska żaboludzi: ile chat i gromad na brzegach, mieszkańcy, wódz i wystrój.
const FROG_HUTS := 6
const FROG_GROUPS := 5
const FROGMAN := preload("res://scenes/frogman.tscn")
const FROG_SPITTER := preload("res://scenes/frog_spitter.tscn")
const FROG_CHIEF := preload("res://scenes/frog_chief.tscn")
const BIRDMAN := preload("res://scenes/birdman.tscn")
const SATYR := preload("res://scenes/satyr.tscn")
const SATYR_PIPER := preload("res://scenes/satyr_piper.tscn")
const SATYR_BRUTE := preload("res://scenes/satyr_brute.tscn")
const BIRDMAN_THROWER := preload("res://scenes/birdman_thrower.tscn")
const BIRDMAN_SHAMAN := preload("res://scenes/birdman_shaman.tscn")
const STORM_EAGLE := preload("res://scenes/storm_eagle.tscn")
const DROWNER := preload("res://scenes/drowner.tscn")
const WISP := preload("res://scenes/wisp.tscn")
const RUSALKA := preload("res://scenes/rusalka.tscn")
const WODNIK := preload("res://scenes/wodnik.tscn")
const ANCIENT_SCENES := {
	"treant": preload("res://scenes/treant.tscn"),
	"ancient_tree": preload("res://scenes/ancient_tree.tscn"),
	"spider": preload("res://scenes/spider.tscn"),
	"web_spider": preload("res://scenes/web_spider.tscn"),
	"spiderling": preload("res://scenes/spiderling.tscn"),
	"cocoon": preload("res://scenes/cocoon.tscn"),
	"beast_bear": preload("res://scenes/beast_bear.tscn"),
	"beast_werewolf": preload("res://scenes/beast_werewolf.tscn"),
	"leshy": preload("res://scenes/leshy.tscn"),
	"spider_queen": preload("res://scenes/spider_queen.tscn"),
	"bies": preload("res://scenes/bies.tscn"),
}
const FIELDS_SCENES := {
	"kobold": preload("res://scenes/kobold.tscn"),
	"kobold_slinger": preload("res://scenes/kobold_slinger.tscn"),
	"kobold_bomber": preload("res://scenes/kobold_bomber.tscn"),
	"field_worm": preload("res://scenes/field_worm.tscn"),
	"bombardier": preload("res://scenes/kobold_bombardier.tscn"),
	"giant_worm": preload("res://scenes/giant_worm.tscn"),
	"skeleton": preload("res://scenes/skeleton.tscn"),
	"skeleton_archer": preload("res://scenes/skeleton_archer.tscn"),
	"skeleton_knight": preload("res://scenes/skeleton_knight.tscn"),
	"ghoul": preload("res://scenes/ghoul.tscn"),
	"zombie": preload("res://scenes/zombie.tscn"),
	"necromancer": preload("res://scenes/necromancer.tscn"),
	"colossal_ghoul": preload("res://scenes/colossal_ghoul.tscn"),
	"hydra": preload("res://scenes/hydra.tscn"),
	"gryf": preload("res://scenes/gryf.tscn"),
	"satyr_king": preload("res://scenes/satyr_king.tscn"),
}
const HUT_TREES: Array[Texture2D] = [preload("res://assets/frogs/hut_tree_0.png"), preload("res://assets/frogs/hut_tree_1.png"),
		preload("res://assets/frogs/hut_tree_2.png")]
const FISH_RACK := preload("res://assets/frogs/fish_rack.png")
const FISH_NET := preload("res://assets/frogs/fish_net.png")
const FROG_TOTEM := preload("res://assets/frogs/frog_totem.png")
const BRAZIER := preload("res://assets/frogs/brazier.png")
const CANOE := preload("res://assets/frogs/canoe.png")
const CLAY_POTS := preload("res://assets/frogs/clay_pots.png")
const SHELL_THRONE := preload("res://assets/frogs/shell_throne.png")
const ROAD_EDGE_TILE := Vector2i(2, 2)

## Ziarno, z którego wygenerowano mapę (zapisywane w zapisie gry).
var _seed := 0
## Widoczne podłoże z miękkimi przejściami terenu (Ground jest pod nim ukryty).
var _soft_ground: SoftGround
## Teren narożników dla miękkiego podłoża podany wprost przez krainę (góry) - pusty = z kafelków Ground.
var _soft_corners := {}
## Góry: teren narożników na granicy poziomów od strony niższego terenu i wysokości komórek (null = płasko).
var _soft_low_corners := {}
var _soft_levels: Image
## Tekstury terenów 64 px z PixelLab zamiast kafelków atlasu (Gobliński Las - tools/forest_ground.py).
var _soft_textures := {}
const FOREST_GROUND := {
	"grass": preload("res://assets/forest/ground/grass.png"), "road": preload("res://assets/forest/ground/road.png"),
	"dark": preload("res://assets/forest/ground/dark.png"), "flowers": preload("res://assets/forest/ground/flowers.png"),
	# bruk osady kładziemy jako żwir (plac, główna droga, kuźnia)
	"cobble": preload("res://assets/forest/ground/gravel.png"),
}
const SWAMP_GROUND := {
	"grass": preload("res://assets/forest/ground/grass.png"), "road": preload("res://assets/forest/ground/road.png"),
	"dark": preload("res://assets/forest/ground/dark.png"), "flowers": preload("res://assets/forest/ground/flowers.png"),
	"w_deep": preload("res://assets/swamp/ground/water.png"), "w_shallow": preload("res://assets/swamp/ground/shallow.png"),
	"w_mud": preload("res://assets/swamp/ground/mud.png"),
}
const FIELDS_GROUND := {
	"grass": preload("res://assets/forest/ground/grass.png"), "road": preload("res://assets/forest/ground/road.png"),
	"dark": preload("res://assets/forest/ground/dark.png"), "flowers": preload("res://assets/forest/ground/flowers.png"),
	"f_soil": preload("res://assets/fields/ground/soil.png"), "f_stubble": preload("res://assets/fields/ground/stubble.png"),
}
const CEMETERY_GROUND := {
	"c_grass": preload("res://assets/cemetery/ground/grass.png"), "c_soil": preload("res://assets/cemetery/ground/soil.png"),
	"c_path": preload("res://assets/cemetery/ground/path.png"), "c_leaves": preload("res://assets/cemetery/ground/leaves.png"),
}
const ANCIENT_GROUND := {
	"soil": preload("res://assets/ancient/ground/soil.png"), "moss": preload("res://assets/ancient/ground/moss.png"),
	"leaves": preload("res://assets/ancient/ground/leaves.png"), "path": preload("res://assets/ancient/ground/path.png"),
}
var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()
## Komórki zajęte przez przeszkody (żeby drzewa na siebie nie wchodziły).
var _occupied := {}
## Komórki, na których nie stawiamy drzew (obozy, miejsca grupek goblinów).
var _reserved := {}
## Środki obozów i grupek (w kafelkach).
var _camp_tiles: Array[Vector2] = []
var _group_tiles: Array[Vector2] = []
## Gobliny czekające na odrodzenie: {"spawn": Dictionary, "time": float}.
var _respawn_queue: Array[Dictionary] = []
## Wszystkie miejsca goblinów w kolejności generowania (indeks = "id" goblina w zapisie).
var _goblin_spawns: Array[Dictionary] = []
## Żywe gobliny według id miejsca.
var _live_goblins := {}
var _camp_cells := {}
## Obozy goblinów zaplanowane przed ułożeniem podłoża (_plan_camp): ogniska, namioty i wyjścia (w kafelkach).
var _camp_layouts: Array[Dictionary] = []
## Udeptana ziemia obozów (place wokół ognisk, ścieżki) - podłoże jak droga.
var _camp_dirt := {}
## Cały teren obozów goblinów - bez drobiazgów runa (patyki, liście, grzyby).
var _goblin_camp_cells := {}
## Środek placu musztry (kafelki; INF - nie zmieścił się).
var _drill_tile := Vector2.INF
## Kolory przeszkód na mapie, według komórki.
var _map_props := {}
var _map_markers: Array[Dictionary] = []
var _settlement := Settlement.new()
## Osada wraz z pasem wolnego terenu dookoła (w kafelkach).
var _settlement_area := Rect2i()
## Droga (gęsto próbkowana, w kafelkach), jej nawierzchnia i pas bez drzew wzdłuż niej.
var _road := PackedVector2Array()
## Gdzie na drodze są bramy osady (indeksy punktów): od wschodniej w stronę prawego górnego rogu
## i od zachodniej w stronę lewego dolnego - po nich chodzą myśliwi.
var _road_east_index := 0
var _road_west_index := 0
var _road_cells := {}
## Ścieżka do Prastarego Lasu (w kafelkach); wychodzi górną krawędzią tyle kafelków od prawego rogu.
var _ancient_trail := PackedVector2Array()
const ANCIENT_EXIT_INSET := 20.0
var _road_clear := {}
var _settlement_lawn := {}
## Siedlisko wilków (w kafelkach) i miejsca nor oraz truchła.
var _wolf_rect := Rect2()
var _den_tiles: Array[Vector2] = []
var _carcass_tiles: Array[Vector2] = []
## Pastwiska zwierzyny: [rodzaj, środek (kafelki)].
var _herds: Array[Array] = []
var _caravan: Caravan
## Leża bossów (w kafelkach).
var _chief_lair := Vector2.ZERO
var _alpha_lair := Vector2.ZERO
var _caravan_timer := 0.0

## Kraina, w której jest gracz ("forest", "swamp") i zapamiętany stan pozostałych krain.
var zone := "forest"
## Loch w płomieniach Watry (gdy zone == Zones.DUNGEON) i jego ustawienia (Dungeons.config).
var _dungeon: Dungeon
var _dungeon_config := {}
var _zone_states := {}
## Odkryte kapliczki: id -> [x, y] (kafelki w swojej krainie).
var shrines := {}
## Kapliczki bieżącej krainy (piksele), przejścia do innych krain i miejsca pojawiania się.
var _zone_shrines := {}
var _exits: Array[Dictionary] = []
var _arrivals := {}
var _spawn_point := Vector2.ZERO
var _traveling := false
var _shrine_check := 0.0
## Rozlewiska: rodzaj wody na komórce, most, nurt rzeki i środek rozlewiska.
var _water := {}
var _bridge_cells := {}
var _river := PackedVector2Array()
var _swamp_center := Vector2.ZERO
var _swamp_radii := Vector2.ZERO
## Wioska żaboludzi: wyspa wodza, chaty, gromady na brzegach i kładki (komórka -> czy pozioma).
var _frog_lair := Vector2.ZERO
var _frog_huts: Array[Vector2] = []
var _frog_groups: Array[Vector2] = []
var _walk_cells := {}
## Topielcze Uroczysko w lewym dolnym rogu rozlewisk (null w innych krainach).
var _grove: DrownedGrove
var _hydra_bog: HydraBog

@onready var ground: TileMapLayer = $Ground
@onready var decor: Node2D = $Decor
@onready var floors: Node2D = $Floors
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var hud: Hud = $HUD


func _ready() -> void:
	Sfx.start_ambient()
	var save := Game.take_pending_load()
	if not save.is_empty():
		_seed = int(save["seed"])
	elif map_seed != 0:
		_seed = map_seed
	else:
		_seed = randi()
	zone = str(save.get("zone", "forest"))
	# loch w płomieniach Watry - tylko z ustawieniami wyprawy (zapis gry z lochu wraca do Ostoi, patrz get_save_data)
	if zone == Zones.DUNGEON and save.has("dungeon"):
		_dungeon_config = save["dungeon"]
	elif not Zones.DATA.has(zone):
		zone = "forest"
	_zone_states = (save.get("zones", {}) as Dictionary).duplicate(true)
	if not save.has("zones") and not save.is_empty():
		# starsze zapisy: stan lasu leży na wierzchu
		_zone_states["forest"] = {"dead_goblins": save.get("dead_goblins", []), "stumps": save.get("stumps", []),
				"settlement": save.get("settlement", {})}
	shrines = (save.get("shrines", {}) as Dictionary).duplicate(true)
	map_size = Zones.size_of(zone)
	# to samo ziarno = identyczny świat, także losowe warianty drzew (każda kraina ma własne)
	_rng.seed = _seed if zone == "forest" else hash([_seed, zone])
	Goblin.dungeon_mods = {}
	seed(_rng.seed)
	_noise.seed = _rng.randi()
	_noise.frequency = 0.07
	add_to_group("world")
	# interpolacja fizyki tylko dla tego, co rusza się w _physics_process (gracz, wrogowie, łup, pociski -
	# włączają ją sami); reszta świata (mieszkańcy, orły, tweeny) porusza się w _process
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	floors.add_to_group("floor_layer")
	ground.add_to_group("ground_layer")
	Sfx.set_ambient_zone(zone)
	if zone == Zones.DUNGEON:
		Sfx.stop_ambient()
	# potwory bez poziomu od świata (przywołane przez bossów) - środek zakresu krainy
	var levels: Array = Levels.ZONES.get(zone, [1, 1, 1])
	Levels.zone_default = roundi((levels[0] + levels[1]) / 2.0)

	if zone == "swamp":
		_generate_swamp()
	elif zone == "mountains":
		var mountains := MountainZone.new()
		add_child(mountains)
		mountains.generate(self)
	elif zone == "ancient":
		var ancient := AncientForest.new()
		add_child(ancient)
		ancient.generate(self)
	elif zone == "fields":
		var fields := GrainFields.new()
		add_child(fields)
		fields.generate(self)
	elif zone == "cemetery":
		var cemetery := ForestCemetery.new()
		add_child(cemetery)
		cemetery.generate(self)
	elif zone == Zones.DUNGEON:
		_dungeon = Dungeon.new()
		_dungeon.name = "Dungeon"
		add_child(_dungeon)
		_dungeon.generate(self, _dungeon_config)
	else:
		_generate_forest()
	if zone == "forest":
		_soft_textures = FOREST_GROUND
	elif zone == "swamp":
		_soft_textures = SWAMP_GROUND
	elif zone == "ancient":
		_soft_textures = ANCIENT_GROUND
	elif zone == "fields":
		_soft_textures = FIELDS_GROUND
	elif zone == "cemetery":
		_soft_textures = CEMETERY_GROUND
	_soft_ground = SoftGround.attach(ground, _soft_corners, _soft_low_corners, _soft_levels, _soft_textures)
	# wysokie rekwizyty znikają, gdy gracz wejdzie za nie
	var occlusion := Occlusion.new()
	occlusion.name = "Occlusion"
	add_child(occlusion)
	occlusion.setup(entities, player)

	var world_rect := Rect2i(Vector2i.ZERO, map_size * TILE)
	player.position = _spawn_point
	player.spawn_point = _spawn_point
	player.set_camera_limits(world_rect)
	hud.connect_player(player)

	var map_texture := _build_map_texture()
	Zones.save_map_cache(_seed, zone, map_texture.get_image())
	hud.setup_map(map_texture, map_size, TILE, player, _map_markers)
	hud.setup_world_map(self, _seed, zone, map_texture)
	# obszary zadań podświetlane na mapie (w kafelkach lasu)
	hud.setup_quest_areas(_forest_quest_areas())

	if not save.is_empty():
		_apply_save(save)
	elif zone == "forest":
		player.give_starting_items()
		hud.show_intro()
	if save.has("arrive"):
		player.global_position = _arrival_point(str(save["arrive"]))
		player.camera.reset_smoothing()
	if _dungeon != null:
		hud.show_banner(Dungeons.title(_dungeon_config), Color(1.0, 0.75, 0.45))
	if zone == "forest":
		_update_resource_piles()
	player.reset_physics_interpolation()  # gracz przeniesiony na start / przybycie, nie przeszedł tam
	Game.end_transition()


## Gobliński Las z osadą Ostoja (pierwsza kraina).
func _generate_forest() -> void:
	_settlement_lawn = {}
	var settlement_origin := map_size / 2 - Settlement.SIZE / 2
	_settlement_area = Rect2i(settlement_origin, Settlement.SIZE).grow(settlement_margin)

	_plan_lairs()
	_plan_goblin_sites()
	_plan_road()
	_plan_wolf_sites()
	_plan_hunting_grounds()
	_build_ground()
	_place_props()
	_build_bounds()

	add_child(_settlement)
	_settlement.build(settlement_origin, ground, floors, entities, player, _rng)
	_blend_settlement_ground()
	_setup_hunters()
	Goblin.safe_zone = _settlement.rect
	_map_props.merge(_settlement.map_cells, true)
	player.storage.changed.connect(_update_resource_piles)
	_map_markers.append_array(_settlement.map_markers)
	_spawn_point = _settlement.spawn_point
	_register_shrine("ostoja", _settlement.spawn_point - Vector2(0, 20))
	# powrót z lochu: przed Watrą
	_arrivals["watra"] = _settlement.watra_arrival()
	if not shrines.has("ostoja"):
		var pos := (_settlement.spawn_point - Vector2(0, 20)) / TILE
		shrines["ostoja"] = [pos.x, pos.y]

	for layout in _camp_layouts:
		_build_camp(layout)
	if _drill_tile.is_finite():
		_build_drill_ground(_drill_tile * TILE)
	for group_tile in _group_tiles:
		_build_group(group_tile * TILE)
	_build_chief_lair(_chief_lair * TILE)
	_build_alpha_lair(_alpha_lair * TILE)
	for den_tile in _den_tiles:
		_build_den(den_tile * TILE)
	for carcass_tile in _carcass_tiles:
		_build_carcass(carcass_tile * TILE)
	for herd in _herds:
		_build_herd(herd[0], herd[1] * TILE)
	_build_darkness()
	_caravan_timer = first_caravan_delay

	# przejście do rozlewisk na końcu drogi w prawym górnym rogu
	var exit_area := Rect2(map_size.x - 3.5, 0, 3.5, 9)
	_add_exit(exit_area, "swamp", "from:forest", _road_point_from_edge(true, 5.0) / TILE + Vector2(-1.5, -2.0))
	_arrivals["from:swamp"] = _road_point_from_edge(true, 9.0)
	# przejście do Prastarego Lasu na końcu ścieżki przy górnej krawędzi
	var trail_x := map_size.x - ANCIENT_EXIT_INSET
	_add_exit(Rect2(trail_x - 4.5, 0, 9, 3.5), "ancient", "from:forest", Vector2(trail_x + 3.0, 5.0))
	_arrivals["from:ancient"] = Vector2(trail_x, 8.0) * TILE
	# przejście do Pól Zbożowych na końcu drogi w lewym dolnym rogu
	_add_exit(Rect2(0, map_size.y - 9, 3.5, 9), "fields", "from:forest", _road_point_from_edge(false, 5.0) / TILE + Vector2(1.5, -2.0))
	_arrivals["from:fields"] = _road_point_from_edge(false, 9.0)


# ---------------------------------------------------------------- zapis gry
func get_save_data() -> Dictionary:
	var zones := _zone_states.duplicate(true)
	if zone != Zones.DUNGEON:
		zones[zone] = _zone_state()
	var data := {
		"seed": _seed,
		"zone": zone,
		"player": player.get_save_data(),
		"kills": hud.kills,
		"zones": zones,
		"shrines": shrines.duplicate(true),
	}
	# loch się nie zapisuje - wczytana gra zaczyna się przy Watrze w Ostoi
	if zone == Zones.DUNGEON:
		data["zone"] = "forest"
		data["arrive"] = "watra"
	return data


## Wejście w płomienie Watry: przejście do lochu o danych ustawieniach (Dungeons.config).
func enter_dungeon(settings: Dictionary) -> void:
	if _traveling:
		return
	_traveling = true
	var data := get_save_data()
	data["zone"] = Zones.DUNGEON
	data["arrive"] = "start"
	data["dungeon"] = settings
	Sfx.play("fireball_launch")
	Game.travel(data)


## Stan bieżącej krainy: pokonane potwory, ścięte drzewa / rozbite głazy, budowy w osadzie.
func _zone_state() -> Dictionary:
	var dead_goblins: Array[Dictionary] = []
	for entry in _respawn_queue:
		dead_goblins.append({"id": entry["spawn"]["id"], "time": entry["time"]})
	for id: int in _summoning:  # krąg jeszcze się ładował - boss pojawi się zaraz po wczytaniu
		dead_goblins.append({"id": id, "time": 0.0})
	var stumps := []
	for target: Harvestable in get_tree().get_nodes_in_group("harvestables"):
		if target.is_depleted:
			stumps.append([target.position.x, target.position.y, target.regrow_left])
	var state := {"dead_goblins": dead_goblins, "stumps": stumps}
	if zone == "forest":
		state["settlement"] = _settlement.get_save_data()
	return state


func _apply_save(save: Dictionary) -> void:
	player.load_save_data(save.get("player", {}))
	hud.set_kills(int(save.get("kills", 0)))
	var state: Dictionary = _zone_states.get(zone, {})
	var harvestables := {}
	for target: Harvestable in get_tree().get_nodes_in_group("harvestables"):
		harvestables[Vector2i(target.position.round())] = target
	for stump: Array in state.get("stumps", []):
		var target: Harvestable = harvestables.get(Vector2i(Vector2(stump[0], stump[1]).round()))
		if target != null:
			target.deplete(float(stump[2]))
	if zone == "forest":
		_settlement.load_save_data(state.get("settlement", {}))
	# gobliny pokonane przed zapisem czekają na odrodzenie (bossowie wskrzeszeni odpoczynkiem już nie)
	var bosses_reset: bool = state.get("bosses_reset", false)
	for entry: Dictionary in state.get("dead_goblins", []):
		var id := int(entry["id"])
		if id < 0 or id >= _goblin_spawns.size():
			continue
		if bosses_reset and _goblin_spawns[id].get("type", "") in BOSS_TYPES:
			continue
		var goblin: Goblin = _live_goblins.get(id)
		if goblin != null:
			_live_goblins.erase(id)
			goblin.remove_from_group("enemies")
			goblin.queue_free()
		_respawn_queue.append({"spawn": _goblin_spawns[id], "time": float(entry["time"])})


# ---------------------------------------------------------------- mapa
## Tekstura 1 piksel = 1 kafelek, używana przez minimapę i dużą mapę.
func _build_map_texture() -> ImageTexture:
	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			var color := MAP_GRASS
			if _map_props.has(cell):
				color = _map_props[cell]
			elif _road_cells.has(cell):
				color = MAP_DIRT
			elif _camp_cells.has(cell):
				color = MAP_CAMP
			elif ground.get_cell_atlas_coords(cell) in DARK_TILES:
				color = MAP_DARK_GRASS
			elif _water.has(cell):
				var kind: String = _water[cell]
				color = MAP_DEEP if kind == "deep" else MAP_SHALLOW if kind == "shallow" else MAP_MUD
			elif ground.get_cell_atlas_coords(cell).y >= COBBLE_WANG_ROW:
				color = Settlement.MAP_COBBLE
			elif ground.get_cell_atlas_coords(cell).y >= ALPINE_WANG_ROW:
				color = _mountain_map_color(ground.get_cell_atlas_coords(cell))
			elif ground.get_cell_atlas_coords(cell).y >= SWAMP_WANG_ROW:
				color = MAP_GRASS
			elif ground.get_cell_atlas_coords(cell).y >= FOREST_WANG_ROW:
				color = _lawn_map_color(ground.get_cell_atlas_coords(cell))
			elif ground.get_cell_atlas_coords(cell).y >= AncientForest.SOIL_ROW:
				color = AncientForest.map_color(ground.get_cell_atlas_coords(cell))
			elif ground.get_cell_atlas_coords(cell).y >= 5:
				color = _mountain_map_color(ground.get_cell_atlas_coords(cell))
			elif _settlement_area.has_point(cell) and ground.get_cell_atlas_coords(cell).y == 2:
				color = MAP_DIRT
			# siedlisko wilków jest ciemniejsze także na mapie
			color = color.lerp(Color(wolf_area_shadow, 1.0), wolf_area_shadow.a * _wolf_strength(cell))
			if _grove != null:
				color = color.lerp(DrownedGrove.MAP_SHADE, 0.5 * _grove.strength(cell))
			if _hydra_bog != null:
				color = color.lerp(DrownedGrove.MAP_SHADE, 0.5 * _hydra_bog.strength(cell))
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


## Kolor mapy kafelków gór: hala, skała, piarg.
func _mountain_map_color(atlas: Vector2i) -> Color:
	if atlas.y >= ALPINE_WANG_ROW:
		var mask := (atlas.y - ALPINE_WANG_ROW) % 4 * 4 + atlas.x
		var covered := 0
		for i in 4:
			covered += (mask >> i) & 1
		if covered < 2:
			return MountainZone.MAP_ALPINE
		return MountainZone.MAP_HIGH if atlas.y < ALPINE_WANG_ROW + 4 else MountainZone.MAP_GRAVEL
	if atlas in MountainZone.GRAVEL_TILES:
		return MountainZone.MAP_GRAVEL
	if atlas in MountainZone.ROCK_TILES or atlas in MountainZone.HIGH_ROCK_TILES:
		return MountainZone.MAP_HIGH
	if atlas == MountainZone.ALPINE_TILES[2]:  # jaśniejsza hala płaskowyżów
		return MountainZone.MAP_PLATEAU
	return MountainZone.MAP_ALPINE


func _update_resource_piles() -> void:
	_settlement.update_resource_piles(player.storage.count_of("wood"), player.storage.count_of("stone"))


func _process(delta: float) -> void:
	_process_respawns(delta)
	_process_music(delta)
	if zone == "forest":
		_process_caravans(delta)
	_process_exits()
	_process_shrines(delta)
	_process_warnings(delta)


## Ostrzeżenie przed bossem dużo silniejszym od gracza (miejsca z "warn": Hydra, Gryf): gdy gracz o zbyt niskim
## poziomie podejdzie, dostaje napis; jeśli pójdzie dalej, boss i tak zaatakuje.
var _warn_check := 0.0
var _warned := {}


func _process_warnings(delta: float) -> void:
	_warn_check -= delta
	if _warn_check > 0.0:
		return
	_warn_check = 0.5
	for spawn: Dictionary in _goblin_spawns:
		if not spawn.get("warn", false):
			continue
		var boss: Goblin = _live_goblins.get(spawn["id"])
		if boss == null or boss.state != Goblin.State.IDLE:
			continue
		var gap: int = boss.level - player.stats.level
		var near := boss.global_position.distance_to(player.global_position) < 300.0
		if near and gap >= 6 and Time.get_ticks_msec() > _warned.get(spawn["id"], 0):
			_warned[spawn["id"]] = Time.get_ticks_msec() + 30000
			Sfx.play("telegraph")
			hud.show_banner("Czujesz obecność czegoś potężnego (poziom %d).\nZawróć, zanim cię zauważy!" % boss.level, Color(1.0, 0.4, 0.3))


# ---------------------------------------------------------------- gobliny
## Wybiera miejsca obozów i grupek i rezerwuje tam teren (bez drzew).
func _plan_goblin_sites() -> void:
	var area := Rect2(goblin_area.position * Vector2(map_size), goblin_area.size * Vector2(map_size))
	var palisade := Rect2(Vector2(_settlement_area.position + Vector2i.ONE * settlement_margin), Vector2(Settlement.SIZE))

	# cały obóz (z polaną) mieści się w obszarze goblinów
	var camp_area := _shrink_to_map(area.grow(-camp_radius), border_thickness + camp_radius + 1)
	# obozy nie nachodzą na siebie (każdy ma barykadę na obrzeżu)
	var camp_ok := func(tile: Vector2) -> bool:
		return _distance_to_rect(tile, palisade) >= camp_radius + settlement_clearance \
				and tile.distance_to(_chief_lair) >= camp_radius + lair_radius + 3 \
				and _far_from(tile, _camp_tiles, camp_radius * 2.0 + 2.0)
	for i in camp_count:
		# także pierwszy obóz jak najdalej (od leża wodza) - zostaje miejsce na kolejne
		var taken: Array[Vector2] = _camp_tiles.duplicate()
		taken.append(_chief_lair)
		var tile := _pick_spread(camp_area, taken, camp_ok, 400)
		if tile.is_finite():
			_camp_tiles.append(tile)
			_reserve_area(tile, camp_radius)
			_mark_camp_area(tile, camp_radius - 2.0)
	for tile in _camp_tiles:
		_camp_layouts.append(_plan_camp(tile))
	_plan_drill_ground(area, palisade)

	# grupki kręcą się w lesie wokół obozów, w tym samym rogu mapy
	var group_area := _shrink_to_map(area, border_thickness + 4)
	var group_ok := func(tile: Vector2) -> bool:
		return _distance_to_rect(tile, palisade) >= settlement_clearance and _far_from(tile, _camp_tiles, camp_radius + 3.0) \
				and tile.distance_to(_chief_lair) >= lair_radius + 4 \
				and (not _drill_tile.is_finite() or tile.distance_to(_drill_tile) >= DRILL_RADII.x + 4.0)
	for i in goblin_group_count:
		var occupied: Array[Vector2] = _camp_tiles + _group_tiles
		var tile := _pick_spread(group_area, occupied, group_ok)
		if tile.is_finite():
			_group_tiles.append(tile)
			_reserve_area(tile, 2)


## Spośród losowych kandydatów wybiera ten najdalej od już zajętych miejsc,
## dzięki czemu obozy i grupki rozkładają się równo nawet na małym obszarze.
## Zwraca Vector2.INF, jeśli żaden kandydat nie spełnia warunku `valid`.
func _pick_spread(area: Rect2, taken: Array[Vector2], valid: Callable, candidates := 80) -> Vector2:
	var best := Vector2.INF
	var best_distance := -1.0
	for i in candidates:
		var tile := _random_point(area)
		if not valid.call(tile):
			continue
		var nearest := INF
		for other in taken:
			nearest = minf(nearest, tile.distance_to(other))
		if nearest > best_distance:
			best_distance = nearest
			best = tile
	return best


## Obszar zawężony o margines od krawędzi mapy (w kafelkach).
func _shrink_to_map(area: Rect2, margin: float) -> Rect2:
	var top_left := area.position.max(Vector2.ONE * margin)
	var bottom_right := area.end.min(Vector2(map_size) - Vector2.ONE * margin)
	return Rect2(top_left, (bottom_right - top_left).max(Vector2.ZERO))


func _random_point(area: Rect2) -> Vector2:
	return Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))


func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	return point.distance_to(point.clamp(rect.position, rect.end))


func _far_from(tile: Vector2, others: Array[Vector2], min_distance: float) -> bool:
	for other in others:
		if tile.distance_to(other) < min_distance:
			return false
	return true


func _reserve_area(center_tile: Vector2, radius: float) -> void:
	for cell in _cells_in_radius(center_tile, radius):
		_reserved[cell] = true


## Obóz jest widoczny na mapie jako wydeptana polana.
func _mark_camp_area(center_tile: Vector2, radius: float) -> void:
	for cell in _cells_in_radius(center_tile, radius):
		_camp_cells[cell] = true


func _cells_in_radius(center_tile: Vector2, radius: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(floori(center_tile.y - radius), ceili(center_tile.y + radius) + 1):
		for x in range(floori(center_tile.x - radius), ceili(center_tile.x + radius) + 1):
			if Vector2(x, y).distance_to(center_tile) <= radius:
				cells.append(Vector2i(x, y))
	return cells


## Układ obozu goblinów - planowany przed ułożeniem podłoża, żeby udeptana ziemia trafiła na podłoże:
## ogniska w kręgu wokół środka, duże namioty między nimi na obrzeżu (wejściem w dół), dwa wyjścia od
## ognisk naprzeciw siebie. Udeptane są place wokół ognisk i na środku oraz kręte ścieżki między sąsiednimi
## ogniskami, od ognisk do środka, od wejść namiotów do ognisk i od ognisk do wyjść (aż za obóz).
func _plan_camp(center_tile: Vector2) -> Dictionary:
	var fires := _rng.randi_range(campfires_per_camp_min, campfires_per_camp_max)
	var fire_distance := (84.0 if fires <= 3 else 100.0) / TILE
	var base_angle := _rng.randf() * TAU
	var layout := {"center": center_tile, "fires": [], "tents": [], "exits": []}
	for i in fires:
		layout["fires"].append(center_tile + Vector2.from_angle(base_angle + TAU * i / fires) * fire_distance)
		layout["tents"].append(center_tile + Vector2.from_angle(base_angle + TAU * (i + 0.5) / fires) * (fire_distance + CAMP_TENT_RING))
	@warning_ignore("integer_division")
	for i in [0, fires / 2]:
		layout["exits"].append(base_angle + TAU * i / fires)
	for cell in _cells_in_radius(center_tile, camp_radius):
		_goblin_camp_cells[cell] = true
	_trample_patch(center_tile, 2.6)
	for i in fires:
		var fire: Vector2 = layout["fires"][i]
		_trample_patch(fire, 3.0)
		_trample_path(fire, center_tile)
		_trample_path(fire, layout["fires"][(i + 1) % fires])
		_trample_path(layout["tents"][i] + Vector2(0, 0.6), fire)
	for angle: float in layout["exits"]:
		var path := _trample_path(center_tile + Vector2.from_angle(angle) * fire_distance,
				center_tile + Vector2.from_angle(angle) * (camp_radius + 5.0))
		for point in path:  # ścieżka za obozem - bez drzew na drodze
			for cell in _cells_in_radius(point, 1.2):
				_reserved[cell] = true
	return layout


## Plac musztry w wolnym miejscu pomiędzy obozami (najbliżej ich środka, z odstępem od obozów, leża wodza
## i osady): udeptany owal bez drobiazgów runa i ścieżki do wyjść dwóch najbliższych obozów.
func _plan_drill_ground(area: Rect2, palisade: Rect2) -> void:
	var ok := func(tile: Vector2) -> bool:
		return _distance_to_rect(tile, palisade) >= DRILL_RADII.x + settlement_clearance \
				and tile.distance_to(_chief_lair) >= lair_radius + DRILL_RADII.x + 3.0 \
				and _far_from(tile, _camp_tiles, camp_radius + DRILL_RADII.x + 3.0)
	if _camp_tiles.is_empty():
		return
	# pomiędzy obozami: wolne miejsce najbliżej ich środka
	var middle := Vector2.ZERO
	for camp in _camp_tiles:
		middle += camp / _camp_tiles.size()
	var search := _shrink_to_map(area, border_thickness + DRILL_RADII.x + 2.0)
	var tile := Vector2.INF
	for i in 600:
		var candidate := _random_point(search)
		if ok.call(candidate) and candidate.distance_to(middle) < tile.distance_to(middle):
			tile = candidate
	if not tile.is_finite():
		return
	_drill_tile = tile
	_reserve_area(tile, DRILL_RADII.x + 1.5)
	for cell in _cells_in_radius(tile, DRILL_RADII.x + 1.5):
		_goblin_camp_cells[cell] = true
	for cell in _cells_in_radius(tile, DRILL_RADII.x + 1.0):
		var p := (Vector2(cell) + Vector2(0.5, 0.5) - tile) / DRILL_RADII
		if p.length() + _noise.get_noise_2d(cell.x * 3.1, cell.y * 3.1) * 0.15 <= 1.0:
			_camp_dirt[cell] = true
	var gates: Array = []  # [odległość, koniec ścieżki wyjściowej obozu]
	for layout in _camp_layouts:
		for angle: float in layout["exits"]:
			var gate: Vector2 = layout["center"] + Vector2.from_angle(angle) * (camp_radius + 5.0)
			gates.append([gate.distance_to(tile), gate])
	gates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for gate: Array in gates.slice(0, 2):
		for point in _trample_path(tile, gate[1]):
			for cell in _cells_in_radius(point, 1.2):
				_reserved[cell] = true


## Nieregularny placyk udeptanej ziemi (brzeg poszarpany szumem).
func _trample_patch(center_tile: Vector2, radius: float) -> void:
	for cell in _cells_in_radius(center_tile, radius + 1.0):
		var wobble := _noise.get_noise_2d(cell.x * 3.1, cell.y * 3.1) * 0.9
		if (Vector2(cell) + Vector2(0.5, 0.5)).distance_to(center_tile) + wobble <= radius:
			_camp_dirt[cell] = true


## Kręta wydeptana ścieżka (punkty w kafelkach).
func _trample_path(from_tile: Vector2, to_tile: Vector2) -> PackedVector2Array:
	var path := Road.wiggle(from_tile, to_tile, _rng, 0.8, 3.0, 0.4)
	for point in path:
		for cell in _cells_in_radius(point, 0.75):
			_camp_dirt[cell] = true
	return path


## Obóz: ogniska z goblinami siedzącymi w kółku, duże namioty z posłaniami i gratami po bokach (przy
## jednym klatka z jeńcem), na środku kocioł, totem, sztandar i łupy z osiłkiem, przy wyjściach łucznicy
## i stojaki na broń, a wokół barykada z zaostrzonych pali - z przerwami na wyjścia i kilkoma wyłomami.
func _build_camp(layout: Dictionary) -> void:
	var center: Vector2 = layout["center"] * TILE
	var fires: Array = layout["fires"]
	for fire_tile: Vector2 in fires:
		var fire_pos := fire_tile * TILE
		_spawn(CAMPFIRE, fire_pos)
		_map_markers.append({"position": fire_pos, "color": MAP_FIRE, "size": 2.0})
		var n := _rng.randi_range(goblins_per_fire_min, goblins_per_fire_max)
		var offset := _rng.randf() * TAU
		for k in n:
			var a := offset + TAU * k / n + _rng.randf_range(-0.15, 0.15)
			var pos := fire_pos + Vector2.from_angle(a) * Vector2(22 + 2.2 * n, 16 + 1.7 * n)
			_add_goblin_spawn({"position": pos, "sitting": true, "look_at": fire_pos})

	var tents: Array = layout["tents"]
	var kinds: Array = CAMP_TENTS.duplicate()
	for i in range(kinds.size() - 1, 0, -1):  # tasowanie z _rng - ten sam świat z tego samego ziarna
		var j := _rng.randi_range(0, i)
		var swap: String = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = swap
	var cage_tent := _rng.randi_range(0, tents.size() - 1)
	for i in tents.size():
		var tent_pos: Vector2 = tents[i] * TILE
		_spawn(FOREST_PROPS[kinds[i % kinds.size()]], tent_pos)
		_map_markers.append({"position": tent_pos, "color": MAP_TENT, "size": 2.5})
		# namiot stoi wejściem w dół - posłanie po jednej stronie, graty (albo klatka) po drugiej
		var side := Vector2.RIGHT * (1.0 if _rng.randf() < 0.5 else -1.0)
		_spawn(FOREST_PROPS["bedroll"], tent_pos + side * 48.0 + Vector2(0, 6))
		var thing: String = "cage" if i == cage_tent else CAMP_CLUTTER[_rng.randi() % CAMP_CLUTTER.size()]
		_spawn(FOREST_PROPS[thing], tent_pos - side * 52.0 + Vector2(0, 4))

	# środek obozu: kocioł, totem z czaszką, sztandar i łupy, których pilnuje osiłek
	_spawn(FOREST_PROPS["cauldron"], center + Vector2(0, 4))
	_spawn(FOREST_PROPS["skull_totem"], center + Vector2(-26, -20))
	_spawn(FOREST_PROPS["banner"], center + Vector2(26, -22))
	var loot_pos := center + Vector2(_rng.randf_range(-6, 6), 30)
	_spawn(FOREST_PROPS["loot"], loot_pos)
	_add_goblin_spawn({"type": "brute", "position": loot_pos + Vector2(22, 6), "sitting": false, "look_at": center})

	# barykada z pali na obrzeżu, przerwy na wyjścia; przy każdym wyjściu łucznik i stojak na broń
	var ring := (camp_radius - 0.6) * TILE
	var exits: Array = layout["exits"]
	for angle: float in exits:
		var dir := Vector2.from_angle(angle)
		var gate := center + dir * (ring - 22.0)
		_add_goblin_spawn({"type": "archer", "position": gate + dir.orthogonal() * 20.0, "sitting": false, "look_at": gate + dir * 60.0})
		_spawn(FOREST_PROPS["weapon_rack"], gate - dir.orthogonal() * 30.0 - dir * 8.0)
	var step := CAMP_STAKE_SPACING / ring
	var phase := _rng.randf() * TAU
	var a := 0.0
	while a < TAU:
		var at_gate := false
		for angle: float in exits:
			if absf(angle_difference(a, angle)) < CAMP_GATE_WIDTH / 2.0 / ring + step / 2.0:
				at_gate = true
		# rząd pali widać od frontu - barykada tylko na górnym i dolnym łuku (na bokach układała się
		# w ukośne schodki), z kilkoma wyłomami (sinusoida po obwodzie)
		if not at_gate and absf(sin(a)) > 0.6 and sin(a * 3.0 + phase) > -0.6:
			_spawn(FOREST_PROPS["palisade"], center + Vector2.from_angle(a) * ring)
		a += step


## Plac musztry: sierżant (osiłek) z boku, przed nim dwuszereg goblinów zwróconych do niego - wszyscy na takt
## robią zamach (Goblin.drilling); po prawej łucznicy strzelają w takt do słomianych kukieł; za sierżantem
## sztandary, u góry stojak z bronią, tarcze i beczka. Gobliny mają grafiki tylko w lewo i w prawo, więc
## szeregi stoją pionowo, a sierżant przed nimi z boku.
func _build_drill_ground(center: Vector2) -> void:
	var sergeant := center + Vector2(-62, 0)
	_add_goblin_spawn({"type": "brute", "position": sergeant, "sitting": false, "look_at": center})
	for side in [-1.0, 1.0]:
		_spawn(FOREST_PROPS["banner"], sergeant + Vector2(-22, side * 30.0))
	for file in 2:
		for k in DRILL_RANK:
			var pos := center + Vector2(-14.0 + file * 26.0, (k - (DRILL_RANK - 1) / 2.0) * 27.0)
			_add_goblin_spawn({"type": "goblin", "position": pos, "sitting": false, "look_at": sergeant, "drill": true})
	for y in [-24.0, 24.0]:
		_add_goblin_spawn({"type": "archer", "position": center + Vector2(58, y), "sitting": false,
				"look_at": center + Vector2(200, y), "drill": true})
		_village_prop(DRILL_DUMMY, center + Vector2(98, y), Vector2(10, 4))
	_spawn(FOREST_PROPS["weapon_rack"], center + Vector2(-22, -70))
	_spawn(FOREST_PROPS["shields"], center + Vector2(16, -68))
	_spawn(FOREST_PROPS["barrel"], center + Vector2(48, -62))
	_map_markers.append({"position": center, "color": MAP_TENT, "size": 3.0})


func _build_group(group_center: Vector2) -> void:
	var n := _rng.randi_range(goblins_per_group_min, goblins_per_group_max)
	# część grupek prowadzi osiłek albo osłania łucznik
	var roll := _rng.randf()
	var leader := "brute" if roll < 0.3 else "archer" if roll < 0.65 else "goblin"
	for k in n:
		var pos := group_center + Vector2(_rng.randf_range(-14, 14), _rng.randf_range(-14, 14))
		_add_goblin_spawn({"type": leader if k == 0 else "goblin", "position": pos, "sitting": false, "look_at": group_center})


## Rejestruje nowe miejsce goblina (nadaje mu id do zapisu) i stawia na nim goblina.
func _add_goblin_spawn(spawn: Dictionary) -> void:
	spawn["id"] = _goblin_spawns.size()
	_goblin_spawns.append(spawn)
	_spawn_goblin(spawn)


## Poziom potwora (Levels): wg odległości od wejścia krainy (w lesie - od Ostoi) do najdalszego zakątka;
## bossowie mają poziom bossów krainy.
func _spawn_level(spawn: Dictionary, boss: bool) -> int:
	if boss:
		return Levels.boss_level(zone)
	var start := _level_origin()
	var tile: Vector2 = spawn["position"] / TILE
	var far := 0.0
	for corner in [Vector2.ZERO, Vector2(map_size.x, 0), Vector2(0, map_size.y), Vector2(map_size)]:
		far = maxf(far, start.distance_to(corner))
	# najbliższe siedliska zaczynają się ok. 40% drogi do najdalszego zakątka (wokół wejścia jest pusto),
	# więc skala biegnie od tego miejsca
	return Levels.level_at(zone, (tile.distance_to(start) / far - 0.4) / 0.42)


func _level_origin() -> Vector2:
	if zone == "forest":
		return Vector2(_settlement_area.position) + Vector2(Settlement.SIZE) / 2.0
	return _road[0] if not _road.is_empty() else Vector2(map_size) / 2.0


## `spawn` opisuje miejsce potwora (goblina albo wilka) - te same dane służą potem do odrodzenia.
func _spawn_goblin(spawn: Dictionary) -> Goblin:
	var kind: String = spawn.get("type", "goblin")
	var is_wolf := kind == "wolf" or kind == "warg"
	var scene: PackedScene = ANIMAL_SCENES[kind] if ANIMAL_SCENES.has(kind) \
			else ANCIENT_SCENES[kind] if ANCIENT_SCENES.has(kind) else FIELDS_SCENES[kind] if FIELDS_SCENES.has(kind) else {"goblin": GOBLIN, "wolf": WOLF, "chief": GOBLIN_CHIEF, "alpha": ALPHA_WOLF,
			"archer": GOBLIN_ARCHER, "brute": GOBLIN_BRUTE, "warg": WARG,
			"frogman": FROGMAN, "frog_spitter": FROG_SPITTER, "frog_chief": FROG_CHIEF,
			"birdman": BIRDMAN, "birdman_thrower": BIRDMAN_THROWER, "birdman_shaman": BIRDMAN_SHAMAN,
			"satyr": SATYR, "satyr_piper": SATYR_PIPER, "satyr_brute": SATYR_BRUTE,
			"storm_eagle": STORM_EAGLE, "drowner": DROWNER, "wisp": WISP, "rusalka": RUSALKA, "wodnik": WODNIK}[kind]
	var goblin: Goblin = scene.instantiate()
	if not spawn.has("level"):
		spawn["level"] = _spawn_level(spawn, goblin is Boss)
	goblin.level = spawn["level"]
	goblin.position = spawn["position"]
	goblin.sitting = spawn["sitting"]
	goblin.drilling = spawn.get("drill", false)
	goblin.look_at_point = spawn["look_at"]
	if is_wolf:
		(goblin as Wolf).pose = spawn.get("pose", "lie")
	# utopiec poza sadzawką (np. w lochu) nie czai się pod wodą
	if spawn.has("lurk") and goblin is Drowner:
		goblin.lurk = spawn["lurk"]
	goblin.died.connect(_on_goblin_died.bind(spawn))
	entities.add_child(goblin)
	_live_goblins[spawn["id"]] = goblin
	return goblin


func _on_goblin_died(goblin: Goblin, spawn: Dictionary) -> void:
	_live_goblins.erase(spawn["id"])
	# upolowana zwierzyna nie liczy się do pokonanych potworów
	if goblin.quest_kind != "animal":
		hud.on_enemy_killed(goblin)
	player.quests.on_enemy_killed(goblin.quest_kind)
	# w lochu nic się nie odradza
	if zone != Zones.DUNGEON:
		_respawn_queue.append({"spawn": spawn, "time": spawn.get("respawn", goblin_respawn_time)})


## Muzyka: walka z bossem w pobliżu, w Ostoi jej temat, a poza nią utwór krainy.
var _music_check := 0.0


func _process_music(delta: float) -> void:
	_music_check -= delta
	if _music_check > 0.0:
		return
	_music_check = 0.5
	var track: String = {"forest": "forest", "swamp": "swamp", "mountains": "mountains", "ancient": "ancient", "fields": "fields", "cemetery": "cemetery"}.get(zone, "forest")
	if zone == Zones.DUNGEON:
		track = {"catacombs": "cemetery", "mine": "fields", "flooded": "swamp", "roots": "ancient"}.get(_dungeon_config.get("climate", ""), "cemetery")
	if zone == "forest" and _settlement.is_inside_palisade(Vector2i((player.global_position / TILE).floor())):
		track = "ostoja"
	for boss in get_tree().get_nodes_in_group("bosses"):
		if boss.is_engaged() and boss.global_position.distance_to(player.global_position) < 500.0:
			track = "boss"
			break
	Sfx.play_music(track)


func _process_respawns(delta: float) -> void:
	for i in range(_respawn_queue.size() - 1, -1, -1):
		var entry := _respawn_queue[i]
		entry["time"] -= delta
		if entry["time"] > 0.0:
			continue
		var pos: Vector2 = entry["spawn"]["position"]
		# nie odradzamy goblina na oczach gracza - spróbujemy za chwilę
		# (boss wraca do leża zawsze, z płynnym pojawieniem się - inaczej czekanie przy tronie blokowałoby go)
		var is_boss: bool = entry["spawn"].get("type", "") in BOSS_TYPES
		if not is_boss and pos.distance_to(player.global_position) < respawn_min_player_distance:
			entry["time"] = 2.0
			continue
		_respawn_queue.remove_at(i)
		_spawn_goblin(entry["spawn"]).appear()


## Przyzwanie bossa przedmiotem: tylko w jego leżu i tylko gdy go tam nie ma.
## Zwraca "" przy sukcesie albo powód odmowy (do napisu nad głową gracza).
func summon_boss(type: String) -> String:
	for spawn: Dictionary in _goblin_spawns:
		if spawn.get("type", "") != type:
			continue
		var id: int = spawn["id"]
		var lair: Vector2 = spawn["position"]
		if player.global_position.distance_to(lair) > SUMMON_RADIUS:
			return "Użyj " + LAIR_NAMES[type]
		var boss: Goblin = _live_goblins.get(id)
		if (boss != null and boss.state != Goblin.State.DEAD) or _summoning.has(id):
			return "Boss już tu jest!"
		for i in range(_respawn_queue.size() - 1, -1, -1):
			if _respawn_queue[i]["spawn"]["id"] == id:
				_respawn_queue.remove_at(i)
		_summoning[id] = true
		var circle := SummonCircle.new()
		circle.position = lair
		entities.add_child(circle)
		circle.summoned.connect(_finish_summon.bind(spawn))
		Sfx.play_at("summon", lair)
		return ""
	return "Użyj " + LAIR_NAMES.get(type, "w leżu bossa")


func _finish_summon(spawn: Dictionary) -> void:
	_summoning.erase(spawn["id"])
	var boss := _spawn_goblin(spawn)
	boss.scale = Vector2(0.2, 1.8)
	boss.modulate = Color(2.0, 1.4, 2.4)
	var tween := boss.create_tween().set_parallel()
	tween.tween_property(boss, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(boss, "modulate", Color.WHITE, 0.6)
	player.add_shake(6.0)
	SkillEffects.shockwave(entities, spawn["position"], 46.0, SummonCircle.COLOR)
	hud.show_banner("Przyzwano: %s!" % boss.get("boss_name"), SummonCircle.SHINE)


## Odpoczynek w karczmie: wszyscy pokonani bossowie wracają do swoich leży - w tej krainie
## od razu, w pozostałych przy następnej wizycie.
func on_rest() -> void:
	for i in range(_respawn_queue.size() - 1, -1, -1):
		var spawn: Dictionary = _respawn_queue[i]["spawn"]
		if spawn.get("type", "") in BOSS_TYPES:
			_respawn_queue.remove_at(i)
			_spawn_goblin(spawn).appear()
	for other: String in _zone_states:
		if other != zone:
			_zone_states[other]["bosses_reset"] = true


func _spawn(scene: PackedScene, pos: Vector2) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = pos
	entities.add_child(node)
	return node


# ---------------------------------------------------------------- teren
func _build_ground() -> void:
	var corners := _lawn_corners()
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			ground.set_cell(cell, 0, _lawn_tile(cell, corners))


## Teren łąki wybieramy w narożnikach kafelków (droga, ciemna trawa, kwiaty), a kafelek dobiera
## przejście do swoich czterech narożników (_lawn_tile). Wspólne dla lasu i rozlewisk.
func _lawn_corners() -> Dictionary:
	var flowers := FastNoiseLite.new()
	flowers.seed = _rng.randi()
	flowers.frequency = 0.09
	var corners := {}
	for y in map_size.y + 1:
		for x in map_size.x + 1:
			var corner := Vector2i(x, y)
			var road := 0
			for cell in [corner - Vector2i(1, 1), corner - Vector2i(0, 1), corner - Vector2i(1, 0), corner]:
				if _road_cells.has(cell) or _camp_dirt.has(cell):
					road += 1
			# w mrocznym siedlisku wilków przeważa ciemna trawa
			var dark_threshold := lerpf(0.25, -0.35, _wolf_strength(corner))
			if road >= 2:
				corners[corner] = Lawn.ROAD
			elif _noise.get_noise_2d(x * 1.7, y * 1.7) > dark_threshold:
				corners[corner] = Lawn.DARK
			elif flowers.get_noise_2d(x, y) > 0.42:
				corners[corner] = Lawn.FLOWERS
	return corners


func _lawn_tile(cell: Vector2i, corners: Dictionary) -> Vector2i:
	var cell_corners: Array[int] = []
	for c in [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]:
		cell_corners.append(corners.get(c, Lawn.GRASS))
	var kind := Lawn.GRASS
	for candidate: int in LAWN_PRIORITY:
		if candidate in cell_corners:
			kind = candidate
			break
	if kind == Lawn.GRASS:
		return Vector2i(0, FOREST_WANG_ROW + 4 * (_rng.randi() % 3))
	return Vector2i(_corner_mask(cell_corners, kind) % 4, FOREST_WANG_ROW + 4 * (kind - 1) + _corner_mask(cell_corners, kind) / 4)


## Maska narożników (NW<<3 | NE<<2 | SW<<1 | SE) o wartości `value`.
static func _corner_mask(cell_corners: Array, value: int) -> int:
	var mask := 0
	for i in 4:
		if cell_corners[i] == value:
			mask |= 8 >> i
	return mask


## Ścieżki i bruk placu osady stawiane są pełnymi kafelkami - tu dobieramy przejścia Wang na ich brzegach
## (jak przy drodze przez las): narożnik jest drogą (brukiem), gdy stykają się w nim co najmniej dwie takie
## komórki. Reszta podwórek dostaje runo jak w lesie: płaty ciemniejszej trawy i kwiatów.
## Ziemia i bruk osady do dobierania przejść (narastająco - patrz _blend_settlement_ground).
var _blend_dirt := {}
var _blend_cobble := {}


func _blend_settlement_ground() -> void:
	var area := Rect2i(_settlement.origin_tile, Settlement.SIZE).grow(2)
	# komórki ziemi i bruku zbieramy narastająco: po pierwszym dobraniu przejść brzegi są już kafelkami
	# przejść (nie pełnymi), więc liczone od nowa kurczyłyby plac i ścieżki z każdą budową
	var dirt := _blend_dirt
	var cobble := _blend_cobble
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			var atlas := ground.get_cell_atlas_coords(cell)
			if atlas == Settlement.COBBLE_TILE:
				cobble[cell] = true
			elif _road_cells.has(cell) or atlas in Settlement.DIRT_TILES:
				dirt[cell] = true
	# runo podwórek losujemy raz (ten sam wygląd przy ponownym dobieraniu przejść po budowie)
	if _settlement_lawn.is_empty():
		_settlement_lawn = _lawn_corners()
	var lawn := _settlement_lawn
	for y in range(area.position.y + 1, area.end.y - 1):
		for x in range(area.position.x + 1, area.end.x - 1):
			var cell := Vector2i(x, y)
			var cobble_mask := _touch_mask(cell, cobble)
			var road_mask := _touch_mask(cell, dirt)
			if cobble_mask != 0:
				ground.set_cell(cell, 0, Vector2i(cobble_mask % 4, COBBLE_WANG_ROW + cobble_mask / 4))
			elif road_mask != 0:
				ground.set_cell(cell, 0, Vector2i(road_mask % 4, FOREST_WANG_ROW + 4 * (Lawn.ROAD - 1) + road_mask / 4))
			elif _settlement.has_cell(cell):
				ground.set_cell(cell, 0, _lawn_tile(cell, lawn))
	if _soft_ground != null:
		_soft_ground.queue_rebuild()


## Maska narożników komórki, w których stykają się co najmniej dwie komórki z `cells`.
func _touch_mask(cell: Vector2i, cells: Dictionary) -> int:
	var mask := 0
	var bit := 8
	for corner in [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]:
		var touching := 0
		for c in [corner - Vector2i(1, 1), corner - Vector2i(0, 1), corner - Vector2i(1, 0), corner]:
			if cells.has(c):
				touching += 1
		if touching >= 2:
			mask |= bit
		bit >>= 1
	return mask


## Kolor kafelka runa Goblińskiego Lasu na mapie (przewaga górnego terenu w narożnikach).
func _lawn_map_color(atlas: Vector2i) -> Color:
	var set_index := (atlas.y - FOREST_WANG_ROW) / 4
	var mask := (atlas.y - FOREST_WANG_ROW) % 4 * 4 + atlas.x
	var covered := 0
	for i in 4:
		covered += (mask >> i) & 1
	if covered < 2:
		return MAP_GRASS
	return [MAP_DARK_GRASS, MAP_DIRT, MAP_GRASS][set_index]


func _place_props() -> void:
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			var edge_dist := mini(mini(x, y), mini(map_size.x - 1 - x, map_size.y - 1 - y))

			# droga przecina las aż do krawędzi mapy
			if _road_clear.has(cell):
				# pobocza drogi w lesie bywają zarośnięte, ale nie ulica osady
				if not _road_cells.has(cell) and not _settlement_area.has_point(cell):
					_maybe_decor(cell, 0.04)
				continue
			if edge_dist < border_thickness:
				# gęsty las na brzegach - im bliżej krawędzi, tym gęściej
				if _rng.randf() < 0.6 - edge_dist * 0.08:
					_try_place(_random_tree(), cell, 1)
				continue
			if _settlement_area.has_point(cell):
				# osada i łąka wokół niej (bez drzew); poza palisadą trochę kwiatków
				var local := Vector2(cell - _settlement_area.position - Vector2i.ONE * settlement_margin) + Vector2(0.5, 0.5)
				if Settlement.outline_distance(local) > 1.05:
					_maybe_decor(cell, 0.06)
				continue
			if _reserved.has(cell):
				if not _goblin_camp_cells.has(cell):  # obóz goblinów bez patyków, liści i grzybów
					_maybe_decor(cell, 0.08)
				continue

			var density := _noise.get_noise_2d(x, y)
			var r := _rng.randf()
			# w siedlisku wilków las jest gęstszy i bardziej iglasty
			var wild := _wolf_strength(cell)
			if wild > 0.5 and _rng.randf() < 0.02:
				_bones(cell)
			if wild > 0.45 and _rng.randf() < 0.018 * wild:
				_try_place(FOREST_PROPS[WILD_PROPS[_rng.randi() % WILD_PROPS.size()]], cell, 2)
			elif density > lerpf(0.3, 0.05, wild) and r < lerpf(0.35, 0.42, wild):
				_try_place(_random_tree(wild), cell, 2)
			elif r < lerpf(0.02, 0.05, wild):
				_try_place(_random_tree(wild), cell, 2)
			elif r < 0.033:
				_try_place(BUSH, cell, 0)
			elif r < 0.046:
				_try_place(BOULDER, cell, 1)
			elif r < 0.05:
				_try_place(STUMP, cell, 0)
			else:
				_maybe_decor(cell, 0.07)


## `wild` 0..1 - im głębiej w siedlisku wilków, tym więcej sosen.
func _random_tree(wild := 0.0) -> PackedScene:
	return OAK if _rng.randf() < lerpf(0.7, 0.3, wild) else PINE


## Stawia przeszkodę, jeśli komórka (i jej otoczenie o promieniu `spacing`) jest wolna.
func _try_place(scene: PackedScene, cell: Vector2i, spacing: int) -> void:
	for dy in range(-spacing, spacing + 1):
		for dx in range(-spacing, spacing + 1):
			if _occupied.has(cell + Vector2i(dx, dy)):
				return
	_occupied[cell] = true
	_spawn(scene, _cell_to_world(cell) + Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3)))
	_map_props[cell] = _map_color_of(scene)


func _map_color_of(scene: PackedScene) -> Color:
	match scene:
		OAK:
			return MAP_TREE
		PINE:
			return MAP_PINE
		BUSH:
			return MAP_BUSH
		BOULDER:
			return MAP_ROCK
		MANGROVE:
			return MAP_MANGROVE
	return MAP_STUMP


func _maybe_decor(cell: Vector2i, chance: float) -> void:
	# drobiazgi rosną kępami tego samego rodzaju (wcześniej równe konfetti grzybów, liści i kwiatów)
	var clump := decor_clump(_seed, cell)
	if _rng.randf() >= chance * clump.x:
		return
	var sprite := Sprite2D.new()
	sprite.texture = DECO_TEXTURE
	sprite.hframes = DECO_FRAMES
	sprite.frame = (int(clump.y * DECO_FRAMES) + _rng.randi() % 5) % DECO_FRAMES
	sprite.flip_h = _rng.randf() < 0.5
	sprite.position = _cell_to_world(cell) + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-6, 2))
	decor.add_child(sprite)


## Kępy drobiazgów runa: x - mnożnik gęstości (0.15..1.8, średnio ok. 1), y - "rodzaj" kępy (0..1),
## z którego wybierane są sąsiednie klatki arkusza. Bez losowania z _rng, więc świat z danego ziarna
## się nie przesuwa.
static var _clump_noise: FastNoiseLite
static var _clump_seed := -1


static func decor_clump(world_seed: int, cell: Vector2i) -> Vector2:
	if _clump_noise == null or _clump_seed != world_seed:
		_clump_noise = FastNoiseLite.new()
		_clump_noise.seed = world_seed ^ 0x5eed
		_clump_noise.frequency = 0.11
		_clump_seed = world_seed
	var density := clampf(1.0 + _clump_noise.get_noise_2d(cell.x, cell.y) * 1.9, 0.15, 1.8)
	var kind := clampf(_clump_noise.get_noise_2d(cell.x * 0.6 + 500.0, cell.y * 0.6) * 0.75 + 0.5, 0.0, 0.999)
	return Vector2(density, kind)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2(TILE / 2.0, TILE * 0.75)


## Niewidzialne ściany wokół mapy, żeby nie dało się z niej wyjść.
func _build_bounds() -> void:
	var size := Vector2(map_size * TILE)
	var t := 32.0
	var walls: Array[Rect2] = [
		Rect2(-t, -t, size.x + 2 * t, t),
		Rect2(-t, size.y, size.x + 2 * t, t),
		Rect2(-t, 0, t, size.y),
		Rect2(size.x, 0, t, size.y),
	]
	for wall in walls:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall.size
		shape.shape = rect
		shape.position = wall.get_center()
		$Bounds.add_child(shape)


# ---------------------------------------------------------------- droga i karawany
## Kręta droga z prawego górnego rogu do wschodniej bramy, prosto przez plac osady
## do zachodniej bramy i dalej krętą drogą do lewego dolnego rogu.
func _plan_road() -> void:
	var palisade := Vector2(_settlement_area.position + Vector2i.ONE * settlement_margin)
	var lane_y := palisade.y + Settlement.ROAD_ROW * Settlement.SCALE
	var east_gate := Vector2(palisade.x + Settlement.SIZE.x, lane_y)
	var west_gate := Vector2(palisade.x, lane_y)
	var start := Vector2(map_size.x - 1.0, 2.0)
	var end := Vector2(1.0, map_size.y - 2.0)

	_road = Road.wiggle(start, east_gate + Vector2(7, 0), _rng)
	_road_east_index = _road.size() - 1
	_road.append_array(Road.straight(east_gate + Vector2(7, 0), west_gate - Vector2(7, 0)))
	_road_west_index = _road.size()
	_road.append_array(Road.wiggle(west_gate - Vector2(7, 0), end, _rng))
	# odnoga z drogi pod prawym górnym rogiem na północ - do Prastarego Lasu
	var fork := _road_point_from_edge(true, 22.0) / TILE
	var trail_rng := RandomNumberGenerator.new()  # osobne losowanie - reszta lasu zostaje taka jak była
	trail_rng.seed = hash([_seed, "ancient_trail"])
	_ancient_trail = Road.wiggle(fork, Vector2(map_size.x - ANCIENT_EXIT_INSET, 0.0), trail_rng, 3.0, 6.0)
	for point in _road + _ancient_trail:
		for cell in _cells_in_radius(point, 1.3):
			_road_cells[cell] = true
		for cell in _cells_in_radius(point, 2.8):
			_road_clear[cell] = true


func _process_caravans(delta: float) -> void:
	if _caravan != null:
		return
	_caravan_timer -= delta
	if _caravan_timer > 0.0:
		return
	var points := PackedVector2Array()
	for point in _road:
		points.append(point * TILE)
	if randf() < 0.5:
		points.reverse()
	_caravan = Caravan.new()
	add_child(_caravan)
	_caravan.setup(points, entities)
	_caravan.finished.connect(_on_caravan_finished)


func _on_caravan_finished() -> void:
	_caravan = null
	_caravan_timer = randf_range(caravan_interval_min, caravan_interval_max)


# ---------------------------------------------------------------- łowiska
## Pastwiska zwierzyny w łowiskach: małe polany z dala od osady, drogi, obozów i nor.
func _plan_hunting_grounds() -> void:
	var palisade := Rect2(Vector2(_settlement_area.position + Vector2i.ONE * settlement_margin), Vector2(Settlement.SIZE))
	var taken: Array[Vector2] = _camp_tiles + _group_tiles + _den_tiles + _carcass_tiles
	var ok := func(tile: Vector2) -> bool:
		return _distance_to_rect(tile, palisade) >= hunting_clearance and Road.distance_to(tile, _road) > 5.0 \
				and _far_from(tile, taken, 12.0) and tile.distance_to(_chief_lair) > lair_radius + 8 \
				and tile.distance_to(_alpha_lair) > lair_radius + 8
	for fraction in hunting_areas:
		var area := _shrink_to_map(Rect2(fraction.position * Vector2(map_size), fraction.size * Vector2(map_size)), border_thickness + 4)
		var kinds: Array[String] = []
		for i in herds_per_area:
			kinds.append(["deer", "roe", "boar"][i % 3])
		for i in hares_per_area:
			kinds.append("hare")
		var placed: Array[Vector2] = []
		for kind in kinds:
			var tile := _pick_spread(area, placed, ok)
			if not tile.is_finite():
				continue
			placed.append(tile)
			_herds.append([kind, tile])
			# stada mają małą polanę do pasienia, zające kicają między drzewami
			_reserve_area(tile, 2.0 if kind == "hare" else 4.0)


## Szlaki myśliwych z chatki: drogą od bram w głąb łowisk (co kilka punktów drogi, w pikselach).
func _setup_hunters() -> void:
	var to_top_right: Array[Vector2] = []
	for i in range(_road_east_index, -1, -3):
		to_top_right.append(_road[i] * TILE)
	var to_bottom_left: Array[Vector2] = []
	for i in range(_road_west_index, _road.size(), 3):
		to_bottom_left.append(_road[i] * TILE)
	_settlement.hunting_routes = [to_top_right, to_bottom_left]
	var areas: Array[Rect2] = []
	for fraction in hunting_areas:
		areas.append(Rect2(fraction.position * Vector2(map_size * TILE), fraction.size * Vector2(map_size * TILE)))
	_settlement.hunting_areas = areas


func _build_herd(kind: String, center: Vector2) -> void:
	var size: Array = HERD_SIZES[kind]
	for i in _rng.randi_range(size[0], size[1]):
		var pos := center + Vector2(_rng.randf_range(-18, 18), _rng.randf_range(-14, 14))
		_add_goblin_spawn({"type": kind, "position": pos, "sitting": false, "look_at": center, "respawn": animal_respawn_time})


# ---------------------------------------------------------------- siedlisko wilków
## Jak głęboko komórka leży w siedlisku wilków: 0 poza nim, 1 w środku
## (łagodne przejście na krawędziach od strony reszty lasu).
func _wolf_strength(cell: Vector2i) -> float:
	if not _wolf_rect.has_point(Vector2(cell)):
		return 0.0
	var inside := minf(cell.x - _wolf_rect.position.x, cell.y - _wolf_rect.position.y)
	return clampf(inside / wolf_area_fade, 0.0, 1.0)


func _plan_wolf_sites() -> void:
	_wolf_rect = Rect2(wolf_area.position * Vector2(map_size), wolf_area.size * Vector2(map_size))
	var palisade := Rect2(Vector2(_settlement_area.position + Vector2i.ONE * settlement_margin), Vector2(Settlement.SIZE))

	var den_area := _shrink_to_map(_wolf_rect.grow(-den_radius), border_thickness + den_radius + 1)
	var den_ok := func(tile: Vector2) -> bool:
		return _distance_to_rect(tile, palisade) >= den_radius + settlement_clearance \
				and Road.distance_to(tile, _road) > den_radius + 3.0 and tile.distance_to(_alpha_lair) >= den_radius + lair_radius + 3
	for i in den_count:
		var tile := _pick_spread(den_area, _den_tiles, den_ok)
		if tile.is_finite():
			_den_tiles.append(tile)
			_reserve_area(tile, den_radius)
			_mark_camp_area(tile, den_radius - 2.0)

	var carcass_area := _shrink_to_map(_wolf_rect, border_thickness + 3)
	var carcass_ok := func(tile: Vector2) -> bool:
		return _distance_to_rect(tile, palisade) >= settlement_clearance \
				and _far_from(tile, _den_tiles, den_radius + 3.0) and Road.distance_to(tile, _road) > 4.0 \
				and tile.distance_to(_alpha_lair) >= lair_radius + 4
	for i in carcass_count:
		var taken: Array[Vector2] = _den_tiles + _carcass_tiles
		var tile := _pick_spread(carcass_area, taken, carcass_ok)
		if tile.is_finite():
			_carcass_tiles.append(tile)
			_reserve_area(tile, 2.5)


## Nora: wilki leżą wokół wejścia, kilka pożera truchło jelenia obok.
func _build_den(center: Vector2) -> void:
	_spawn(FOREST_PROPS["wolf_den"], center)
	_map_markers.append({"position": center, "color": MAP_DEN, "size": 3.0})
	var carcass := center + Vector2(58.0 * (1 if _rng.randf() < 0.5 else -1), 34)
	_spawn_carcass(carcass)
	var total := _rng.randi_range(wolves_per_den_min, wolves_per_den_max)
	var eaters := mini(3, total)
	for k in eaters:
		var a := TAU * k / eaters + _rng.randf_range(-0.3, 0.3)
		_add_goblin_spawn({"type": "wolf", "pose": "eat", "position": carcass + Vector2.from_angle(a) * Vector2(28, 16),
				"sitting": true, "look_at": carcass})
	var resting := total - eaters
	_spawn(FOREST_PROPS["bone_pile"], center + Vector2(-40.0 * signf(carcass.x - center.x), 24))
	_spawn(FOREST_PROPS["skull_pole"], center + Vector2(-30.0 * signf(carcass.x - center.x), -18))
	# przy części nor wejścia pilnuje warg
	if resting > 0 and _rng.randf() < 0.6:
		resting -= 1
		_add_goblin_spawn({"type": "warg", "pose": "lie", "position": center + Vector2(0, 24), "sitting": true, "look_at": center + Vector2(0, 80)})
	var offset := _rng.randf() * TAU
	for k in resting:
		var a := offset + TAU * k / resting + _rng.randf_range(-0.2, 0.2)
		var pos := center + Vector2.from_angle(a) * Vector2(_rng.randf_range(42, 62), _rng.randf_range(30, 44))
		_add_goblin_spawn({"type": "wolf", "pose": "lie", "position": pos, "sitting": true, "look_at": center})


## Truchło jelenia w lesie z ucztującą watahą.
func _build_carcass(center: Vector2) -> void:
	_spawn_carcass(center)
	for i in 3:
		_bones(Vector2i(center / TILE) + Vector2i(_rng.randi_range(-2, 2), _rng.randi_range(-2, 2)))
	var n := _rng.randi_range(wolves_per_carcass_min, wolves_per_carcass_max)
	var offset := _rng.randf() * TAU
	for k in n:
		var a := offset + TAU * k / n + _rng.randf_range(-0.25, 0.25)
		_add_goblin_spawn({"type": "wolf", "pose": "eat", "position": center + Vector2.from_angle(a) * Vector2(30, 17),
				"sitting": true, "look_at": center})


func _spawn_carcass(pos: Vector2) -> void:
	_spawn(FOREST_PROPS["carcass"], pos)
	_map_markers.append({"position": pos, "color": MAP_CARCASS, "size": 1.5})


## Rozrzucone kości (ozdoba bez kolizji).
func _bones(cell: Vector2i) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = BONE_TEXTURES[_rng.randi() % BONE_TEXTURES.size()]
	sprite.flip_h = _rng.randf() < 0.5
	sprite.position = _cell_to_world(cell) + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 2))
	decor.add_child(sprite)


## Mrok nad siedliskiem wilków: półprzezroczysta warstwa (1 piksel = 1 kafelek)
## rozmyta filtrowaniem, dzięki czemu las ciemnieje płynnie w głąb siedliska.
func _build_darkness() -> void:
	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	for y in map_size.y:
		for x in map_size.x:
			var strength := _wolf_strength(Vector2i(x, y))
			image.set_pixel(x, y, Color(wolf_area_shadow, wolf_area_shadow.a * strength))
	var shade := Sprite2D.new()
	shade.texture = ImageTexture.create_from_image(image)
	shade.centered = false
	shade.scale = Vector2(TILE, TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.z_index = 20
	add_child(shade)


# ---------------------------------------------------------------- leża bossów
## Wódz goblinów w lewym górnym rogu, wilk alfa w prawym dolnym.
func _plan_lairs() -> void:
	var corner := float(border_thickness + lair_radius)
	_chief_lair = Vector2(corner + 4.0, corner + 2.0)
	_alpha_lair = Vector2(map_size) - Vector2(corner + 5.0, corner + 3.0)
	for lair in [_chief_lair, _alpha_lair]:
		_reserve_area(lair, lair_radius)
		_mark_camp_area(lair, lair_radius - 2.0)
	# leże wodza: cała arena udeptana i bez drobiazgów runa, wydeptana ścieżka wejścia w głąb lasu
	# (własny generator - nie zmienia reszty świata z tego samego ziarna)
	_trample_patch(_chief_lair, lair_radius + 0.5)
	_reserve_area(_chief_lair, lair_radius + 2.0)
	for cell in _cells_in_radius(_chief_lair, lair_radius + 1.0):
		_goblin_camp_cells[cell] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_chief_lair)
	var exit_from := _chief_lair + CHIEF_LAIR_EXIT * (lair_radius - 2.0)
	for point in Road.wiggle(exit_from, _chief_lair + CHIEF_LAIR_EXIT * (lair_radius + 7.0), rng, 0.8, 3.0, 0.4):
		for cell in _cells_in_radius(point, 0.9):
			_camp_dirt[cell] = true
			_reserved[cell] = true


## Leże wodza - obóz jego przybocznych na udeptanej arenie: kościany tron, za nim łukiem cztery duże namioty
## (z posłaniami, gratami i klatką z jeńcem), po bokach ogniska z siedzącymi goblinami i kotłem, łupy i tarcze
## przy tronie, wokół barykada z pali (przerwa na wejście od południowego wschodu, przy niej czaszki na palach
## i łucznik), na skraju stojaki z bronią i kości. Środek areny zostaje wolny do walki z wodzem.
func _build_chief_lair(center: Vector2) -> void:
	_spawn(FOREST_PROPS["bone_throne"], center + Vector2(0, -30))
	for side in [-1, 1]:
		_spawn(FOREST_PROPS["banner"], center + Vector2(34 * side, -46))
		_spawn(FOREST_PROPS["loot" if side < 0 else "shields"], center + Vector2(44 * side, -16))
		_add_goblin_spawn({"type": "brute", "position": center + Vector2(28 * side, 10), "sitting": false, "look_at": center + Vector2(0, 60)})
		_spawn(FOREST_PROPS["weapon_rack"], center + Vector2(146 * side, 12))

	# namioty łukiem za tronem, wejściem w dół; obok posłanie i graty, przy jednym klatka
	var tents: Array[Vector2] = [Vector2(-122, -60), Vector2(-48, -104), Vector2(50, -104), Vector2(126, -58)]
	for i in tents.size():
		var tent_pos := center + tents[i]
		_spawn(FOREST_PROPS[CAMP_TENTS[i % CAMP_TENTS.size()]], tent_pos)
		_map_markers.append({"position": tent_pos, "color": MAP_TENT, "size": 2.5})
		# skrajne namioty: posłanie przed wejściem od środka areny, graty od zewnątrz; środkowe: posłanie od
		# zewnątrz, a graty (albo klatka) w przerwie do skrajnego namiotu - nic nie wypada poza arenę
		var side := -1.0 if tents[i].x < 0.0 else 1.0
		var outer := i == 0 or i == tents.size() - 1
		var bed := tent_pos + (Vector2(-18 * side, 40) if outer else Vector2(20 * side, 40))
		_spawn(FOREST_PROPS["bedroll"], bed)
		var thing := tent_pos + (Vector2(26 * side, 38) if outer else Vector2(44 * side, 14))
		_spawn(FOREST_PROPS["cage" if i == 1 else CAMP_CLUTTER[i % CAMP_CLUTTER.size()]], thing)
		# przy posłaniu ktoś odpoczywa (przed nim - za posłaniem by go nie było widać)
		_add_goblin_spawn({"position": bed + Vector2(0, 12), "sitting": true, "look_at": center})

	# ogniska po bokach areny z siedzącymi w kółku, przy lewym kocioł, przy prawym beczki
	for side in [-1, 1]:
		var fire_pos := center + Vector2(90 * side, 42)
		_spawn(CAMPFIRE, fire_pos)
		_map_markers.append({"position": fire_pos, "color": MAP_FIRE, "size": 2.0})
		for k in 3:
			var a := TAU * k / 3 + _rng.randf_range(-0.2, 0.2)
			_add_goblin_spawn({"position": fire_pos + Vector2.from_angle(a) * Vector2(28, 21), "sitting": true, "look_at": fire_pos})
		_spawn(FOREST_PROPS["cauldron" if side < 0 else "barrel"], fire_pos + Vector2(34 * side, 22))
		_spawn(FOREST_PROPS["log_seat"], fire_pos + Vector2(-6 * side, -30))

	# barykada z pali na górnym i dolnym łuku (od frontu), przerwa na wejście; przy wejściu czaszki na palach
	var ring := Vector2(lair_radius - 0.8, (lair_radius - 0.8) * 0.82) * TILE
	var exit_angle := CHIEF_LAIR_EXIT.angle()
	var a := 0.0
	while a < TAU:
		var open := absf(angle_difference(a, exit_angle)) < 0.38
		if not open and absf(sin(a)) > 0.62:
			_spawn(FOREST_PROPS["palisade"], center + Vector2.from_angle(a) * ring)
		a += CAMP_STAKE_SPACING / ring.x
	var gate := center + Vector2.from_angle(exit_angle) * ring
	for side in [-1.0, 1.0]:
		_spawn(FOREST_PROPS["skull_pole"], gate + CHIEF_LAIR_EXIT.orthogonal() * 34.0 * side)
	_add_goblin_spawn({"type": "archer", "position": gate - CHIEF_LAIR_EXIT * 18.0 + CHIEF_LAIR_EXIT.orthogonal() * 22.0,
			"sitting": false, "look_at": gate + CHIEF_LAIR_EXIT * 80.0})
	_add_goblin_spawn({"type": "archer", "position": center + Vector2(-104, -18), "sitting": false, "look_at": center + Vector2(0, 80)})

	# totemy z czaszkami na skraju areny, kości
	for angle in [PI * 0.48, PI * 0.72, PI * 0.95, PI * 1.08]:
		_spawn(FOREST_PROPS["skull_totem"], center + Vector2.from_angle(angle) * ring * 0.88)
	for offset in [Vector2(-52, 82), Vector2(58, 92), Vector2(-150, -20), Vector2(0, -150)]:
		_spawn(FOREST_PROPS["bone_pile"], center + offset)
	_add_goblin_spawn({"type": "chief", "position": center, "sitting": false, "look_at": center, "respawn": boss_respawn_time})
	_map_markers.append({"position": center, "color": MAP_BOSS, "size": 4.0})


## Leże alfy: dwie nory, truchła, mnóstwo kości i najwierniejsza wataha.
func _build_alpha_lair(center: Vector2) -> void:
	for offset in [Vector2(-50, -30), Vector2(52, -24)]:
		_spawn(FOREST_PROPS["wolf_den"], center + offset)
	for offset in [Vector2(-60, 40), Vector2(64, 46)]:
		_spawn_carcass(center + offset)
	for i in 14:
		_bones(Vector2i(center / TILE) + Vector2i(_rng.randi_range(-8, 8), _rng.randi_range(-6, 6)))
	for k in 6:
		var a := TAU * k / 6 + _rng.randf_range(-0.2, 0.2)
		var pos := center + Vector2.from_angle(a) * Vector2(90, 62)
		_add_goblin_spawn({"type": "warg" if k % 3 == 0 else "wolf", "pose": "lie", "position": pos, "sitting": true, "look_at": center})
	for offset in [Vector2(-24, 60), Vector2(30, -62), Vector2(-100, -4), Vector2(104, 10)]:
		_spawn(FOREST_PROPS["bone_pile"], center + offset)
	for i in 6:
		var pos := center + Vector2.from_angle(TAU * i / 6 + 0.5) * Vector2(128, 92)
		_spawn(FOREST_PROPS["wolf_totem" if i % 2 == 0 else "skull_pole"], pos)
	_spawn(FOREST_PROPS["ribcage"], center + Vector2(4, 30))
	_add_goblin_spawn({"type": "alpha", "position": center, "sitting": false, "look_at": center, "respawn": boss_respawn_time})
	_map_markers.append({"position": center, "color": MAP_BOSS, "size": 4.0})


# ---------------------------------------------------------------- krainy, przejścia i kapliczki
## Gdzie postać pojawia się po przejściu z innej krainy albo teleporcie.
func _arrival_point(arrive: String) -> Vector2:
	if arrive.begins_with("shrine:"):
		var id := arrive.substr(7)
		if _zone_shrines.has(id):
			return _zone_shrines[id] + Vector2(0, 20)
	return _arrivals.get(arrive, _spawn_point)


## Punkt drogi `inset` kafelków od jej końca (początek albo koniec drogi), do pojawiania się po przejściu.
func _road_point_from_edge(from_start: bool, inset: float) -> Vector2:
	var edge := _road[0] if from_start else _road[_road.size() - 1]
	var indices := range(_road.size()) if from_start else range(_road.size() - 1, -1, -1)
	for i in indices:
		if _road[i].distance_to(edge) >= inset:
			return _road[i] * TILE
	return edge * TILE


## Przejście na krańcu drogi do innej krainy: obszar w pikselach, drogowskaz i napis.
func _add_exit(area_tiles: Rect2, target_zone: String, arrive: String, sign_tile: Vector2) -> void:
	_exits.append({"rect": Rect2(area_tiles.position * TILE, area_tiles.size * TILE), "zone": target_zone, "arrive": arrive})
	var sign := Sprite2D.new()
	sign.texture = SIGNPOST_TEXTURE
	sign.offset = Vector2(0, -14)
	sign.position = sign_tile * TILE
	entities.add_child(sign)
	var label := Label.new()
	label.text = Zones.zone_name(target_zone)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.11, 0.17))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 30
	label.position = sign_tile * TILE + Vector2(-30, -44)
	label.size = Vector2(60, 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	_map_markers.append({"position": sign_tile * TILE, "color": Color(1.0, 0.9, 0.6), "size": 2.0})


## Kapliczka odrodzenia w bieżącej krainie (do teleportu i odrodzenia).
func _register_shrine(id: String, pos: Vector2) -> void:
	_zone_shrines[id] = pos


func _process_exits() -> void:
	if _traveling or player.is_dead:
		return
	for exit: Dictionary in _exits:
		if exit["rect"].has_point(player.global_position):
			_travel(exit["zone"], exit["arrive"])
			return


## Gracz podszedł do kapliczki - od teraz można się do niej teleportować z dużej mapy.
func _process_shrines(delta: float) -> void:
	_shrine_check -= delta
	if _shrine_check > 0.0:
		return
	_shrine_check = 0.25
	for id: String in _zone_shrines:
		if shrines.has(id):
			continue
		if player.global_position.distance_to(_zone_shrines[id]) < 48.0:
			var pos: Vector2 = _zone_shrines[id] / TILE
			shrines[id] = [pos.x, pos.y]
			Sfx.play("quest_ready")
			hud.show_banner("Odkryto kapliczkę: %s\nTeleport z dużej mapy (M)" % Zones.SHRINES[id]["name"], Color(0.6, 0.9, 1.0))
			hud.refresh_world_map()


func _travel(target_zone: String, arrive: String) -> void:
	if _traveling:
		return
	_traveling = true
	var data := get_save_data()
	data["zone"] = target_zone
	data["arrive"] = arrive
	Game.travel(data)


## Teleport do odkrytej kapliczki (kliknięcie na dużej mapie).
func teleport_to(shrine_id: String) -> void:
	if not shrines.has(shrine_id) or player.is_dead or _traveling:
		return
	var target_zone: String = Zones.SHRINES[shrine_id]["zone"]
	Sfx.play("magic", 2.0, 0.7)
	if target_zone != zone:
		_travel(target_zone, "shrine:" + shrine_id)
		return
	player.global_position = _zone_shrines[shrine_id] + Vector2(0, 20)
	player.reset_physics_interpolation()
	player.camera.reset_smoothing()


## Obszary zadań w kafelkach lasu (żeby podświetlały się także, gdy gracz jest w innej krainie).
func _forest_quest_areas() -> Dictionary:
	var size := Vector2(Zones.size_of("forest"))
	var village := Vector2(Zones.size_of("forest") / 2 - Settlement.SIZE / 2)
	return {
		"goblins": Rect2(goblin_area.position * size, goblin_area.size * size),
		"wolves": Rect2(wolf_area.position * size, wolf_area.size * size),
		"village": Rect2(village, Vector2(Settlement.SIZE)),
	}


# ---------------------------------------------------------------- rozlewiska
## Kraina rozlewisk: wejście w lewym górnym rogu, kręta droga do prawego dolnego rogu,
## rzeka płynąca od dołu (z mostem na środku mapy) przez rozlewisko w prawym górnym rogu
## i dalej w górę, aż do krawędzi mapy.
## Rozlewisko to płycizna (da się po niej brodzić) pełna pałek wodnych i namorzynów, z wioską
## żaboludzi (chaty w olbrzymich namorzynach, kładki) i ich wodzem na wyspie pośrodku;
## w głębokim nurcie rzeki chodzić się nie da. Obok mostu stoi kapliczka odrodzenia.
func _generate_swamp() -> void:
	Goblin.safe_zone = Rect2()
	var w := float(map_size.x)
	var h := float(map_size.y)
	var cross := Vector2(roundf(w * 0.5) + 0.5, roundf(h * 0.52) + 0.5)
	_swamp_center = Vector2(w * 0.8, h * 0.2)
	_swamp_radii = Vector2(26, 20)
	# rzeka: od dołu mapy, przy moście prosto w pionie, potem do rozlewiska
	_river = Road.wiggle(Vector2(cross.x + _rng.randf_range(-12, 4), h + 3), cross + Vector2(0, 8), _rng, 6.0, 12.0)
	_river.append_array(Road.straight(cross + Vector2(0, 8), cross - Vector2(0, 8)))
	_river.append_array(Road.wiggle(cross - Vector2(0, 8), _swamp_center, _rng, 7.0, 12.0))
	# za rozlewiskiem rzeka płynie dalej na północ, poza mapę
	_river.append_array(Road.wiggle(_swamp_center, Vector2(_swamp_center.x + _rng.randf_range(-8, 8), -3), _rng, 4.0, 8.0))
	# droga: od wejścia przez most do prawego dolnego rogu
	_road = Road.wiggle(Vector2(1, 4), cross - Vector2(11, 0), _rng)
	_road.append_array(Road.straight(cross - Vector2(11, 0), cross + Vector2(11, 0)))
	_road.append_array(Road.wiggle(cross + Vector2(11, 0), Vector2(w - 1, h - 4), _rng))
	for point in _road:
		for cell in _cells_in_radius(point, 1.3):
			_road_cells[cell] = true
		for cell in _cells_in_radius(point, 2.8):
			_road_clear[cell] = true

	var shrine_tile := cross + Vector2(-7.5, -4.6)
	_reserve_area(shrine_tile, 3.0)
	_plan_swamp_water(cross)
	_plan_frog_village()
	_grove = DrownedGrove.new()
	add_child(_grove)
	_grove.plan(self)
	_hydra_bog = HydraBog.new()
	add_child(_hydra_bog)
	_hydra_bog.plan(self)
	_plan_swamp_herds()
	_build_swamp_ground()
	_place_swamp_props()
	_build_bounds()
	_build_bridge(cross)
	_build_water_collision()
	_build_river_sounds()
	for herd in _herds:
		_build_herd(herd[0], herd[1] * TILE)
	_build_frog_village()
	_grove.build()
	_hydra_bog.build()
	# kaczki, żurawie, ważki i ryby
	var wildlife := Wildlife.new()
	add_child(wildlife)
	wildlife.setup(self, entities)

	var shrine: Node2D = SHRINE.instantiate()
	shrine.position = shrine_tile * TILE
	entities.add_child(shrine)
	_register_shrine("swamp_ford", shrine.position)
	_map_markers.append({"position": shrine.position, "color": Color("5fd3ff"), "size": 3.0})
	_spawn_point = shrine.position + Vector2(0, 20)

	_add_exit(Rect2(0, 0, 3.5, 9), "forest", "from:swamp", _road_point_from_edge(true, 5.0) / TILE + Vector2(1.5, -2.0))
	_arrivals["from:forest"] = _road_point_from_edge(true, 9.0)
	# na końcu drogi (prawy dolny róg) - przejście w Wietrzne Turnie
	_add_exit(Rect2(w - 3.5, h - 9, 3.5, 9), "mountains", "from:swamp", _road_point_from_edge(false, 5.0) / TILE + Vector2(-1.5, -2.0))
	_arrivals["from:mountains"] = _road_point_from_edge(false, 9.0)


## Woda i błoto: nurt rzeki (głęboko pośrodku, płytko przy brzegach) i rozlewisko z wysepkami.
func _plan_swamp_water(cross: Vector2) -> void:
	# odległość od nurtu liczymy tylko blisko rzeki (rasteryzacja punktów nurtu)
	var river_distance := {}
	for point in _river:
		for cell in _cells_in_radius(point, SWAMP_RIVER_BANK + 1.0):
			var d := Vector2(cell) + Vector2(0.5, 0.5)
			var dist := d.distance_to(point)
			if dist < river_distance.get(cell, INF):
				river_distance[cell] = dist
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			var p := Vector2(x + 0.5, y + 0.5)
			var blob := ((p - _swamp_center) / _swamp_radii).length() + _noise.get_noise_2d(x * 2.0, y * 2.0) * 0.35
			var kind := ""
			if blob < 1.0:
				kind = "mud" if _noise.get_noise_2d(x * 1.4 + 300.0, y * 1.4) > 0.12 else "shallow"  # błotniste wysepki
			elif blob < 1.12:
				kind = "mud"
			elif blob < 1.25:
				kind = "bank"
			var rd: float = river_distance.get(cell, INF)
			if rd < SWAMP_RIVER_DEEP and blob > 1.05:  # w rozlewisku nurt rozlewa się w płyciznę
				kind = "deep"
			elif rd < SWAMP_RIVER_SHALLOW and kind != "deep":
				kind = "shallow"
			elif rd < SWAMP_RIVER_BANK and kind == "":
				kind = "bank"
			if kind != "" and not (_road_cells.has(cell) and kind in ["bank", "mud"]):
				_water[cell] = kind


## Pastwiska zwierzyny w rozlewiskach: na suchym lądzie, z dala od wody i drogi.
func _plan_swamp_herds() -> void:
	var ok := func(tile: Vector2) -> bool:
		if Road.distance_to(tile, _road) <= 5.0 or _reserved.has(Vector2i(tile)):
			return false
		for cell in _cells_in_radius(tile, 4.0):
			if _water.get(cell, "") in ["deep", "shallow"]:
				return false
		return true
	for fraction in swamp_hunting_areas:
		var area := _shrink_to_map(Rect2(fraction.position * Vector2(map_size), fraction.size * Vector2(map_size)), border_thickness + 4)
		var kinds: Array[String] = []
		for i in swamp_herds_per_area:
			kinds.append(["deer", "roe", "boar"][i % 3])
		for i in swamp_hares_per_area:
			kinds.append("hare")
		var placed: Array[Vector2] = []
		for kind in kinds:
			var tile := _pick_spread(area, placed, ok)
			if not tile.is_finite():
				continue
			placed.append(tile)
			_herds.append([kind, tile])
			_reserve_area(tile, 2.0 if kind == "hare" else 4.0)


## Czy w danym miejscu (piksele) jest woda, po której pływają kaczki ("deep" / "shallow").
func water_at(pos: Vector2) -> String:
	var kind: String = _water.get(Vector2i(pos / TILE), "")
	return kind if kind in ["deep", "shallow"] and not _bridge_cells.has(Vector2i(pos / TILE)) else ""


## Komórki wody (do losowania miejsc kaczek i ryb) oraz płycizny przy brzegu (dla żurawi).
func water_cells(kinds: Array[String]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _water:
		if _water[cell] in kinds and not _bridge_cells.has(cell):
			cells.append(cell)
	return cells


func shore_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _water:
		if _water[cell] != "shallow" or _bridge_cells.has(cell):
			continue
		for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not _water.get(cell + dir, "") in ["deep", "shallow"]:
				cells.append(cell)
				break
	return cells


func _build_swamp_ground() -> void:
	# poziom komórki: 0 łąka, 1 błoto i brzeg, 2 płycizna, 3 głębia; narożnik dostaje najwyższy
	# poziom ze stykających się komórek, więc woda zachowuje swój kształt, a brzegi są płynne
	var levels := {}
	for cell: Vector2i in _water:
		var kind: String = _water[cell]
		# dawny brzeg (pas błota wzdłuż rzeki) jest teraz trawiastą skarpą; pod kładkami i pomostami woda
		if kind != "bank":
			levels[cell] = 3 if kind == "deep" else 2 if kind in ["shallow", "walk"] else 1
	var corner_levels := {}
	for y in map_size.y + 1:
		for x in map_size.x + 1:
			var corner := Vector2i(x, y)
			var level := 0
			for cell in [corner - Vector2i(1, 1), corner - Vector2i(0, 1), corner - Vector2i(1, 0), corner]:
				level = maxi(level, levels.get(cell, 0))
			if level > 0:
				corner_levels[corner] = level
	var lawn := _lawn_corners()
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			var cell_corners: Array[int] = []
			for c in [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]:
				cell_corners.append(corner_levels.get(c, 0))
			var top: int = cell_corners.max()
			if top == 0 or _road_cells.has(cell) and top < 3 and not levels.has(cell):
				ground.set_cell(cell, 0, _lawn_tile(cell, lawn))
				continue
			# zestaw przejść (błoto/płycizna/głębia) - niższe narożniki rysuje dolny teren zestawu
			var mask := _corner_mask(cell_corners, top)
			ground.set_cell(cell, 0, Vector2i(mask % 4, SWAMP_WANG_ROW + 4 * (top - 1) + mask / 4))
	_swamp_soft_corners(corner_levels, lawn)


## Narożniki terenów rozlewisk dla SoftGround: rzeka (cała jednym kolorem wody - płycizna przy brzegu
## jest tylko do brodzenia), płycizna i błoto rozlewiska, a na lądzie łąka; przy wodzie zawsze zwykła
## trawa, żeby skarpa nad wodą była jednolita.
func _swamp_soft_corners(corner_levels: Dictionary, lawn: Dictionary) -> void:
	for y in map_size.y + 1:
		for x in map_size.x + 1:
			var corner := Vector2i(x, y)
			var level: int = corner_levels.get(corner, 0)
			var in_marsh := _in_marsh(corner)
			if in_marsh and level >= 2:
				_soft_corners[corner] = "w_shallow"
				continue
			if level == 3 or level == 2 and not in_marsh:
				_soft_corners[corner] = "w_deep"
				continue
			if level == 2:
				_soft_corners[corner] = "w_shallow"
				continue
			# błotniste wysepki rozlewiska są teraz trawiaste (skarpa jak przy rzece)
			var near_water := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if corner_levels.get(corner + Vector2i(dx, dy), 0) >= 2:
						near_water = true
			var kind: int = lawn.get(corner, Lawn.GRASS)
			if near_water or kind == Lawn.GRASS:
				_soft_corners[corner] = "road" if kind == Lawn.ROAD else "grass"
			else:
				_soft_corners[corner] = {Lawn.DARK: "dark", Lawn.FLOWERS: "flowers", Lawn.ROAD: "road"}[kind]


func _place_swamp_props() -> void:
	for y in map_size.y:
		for x in map_size.x:
			var cell := Vector2i(x, y)
			var edge_dist := mini(mini(x, y), mini(map_size.x - 1 - x, map_size.y - 1 - y))
			var kind: String = _water.get(cell, "")
			var r := _rng.randf()
			if kind == "deep" or kind == "walk":
				continue
			if _road_clear.has(cell):
				if kind == "" and not _road_cells.has(cell):
					_maybe_decor(cell, 0.04)
				continue
			if _reserved.has(cell):
				continue
			if kind == "shallow":
				# rozlewisko: namorzyny, kępy pałek wodnych, lilie i trzcina
				var in_swamp := ((Vector2(cell) - _swamp_center) / _swamp_radii).length() < 1.1
				if in_swamp and r < 0.035:
					_try_place(MANGROVE, cell, 1)
				elif r < (0.16 if in_swamp else 0.1):
					_water_plant(CATTAIL_TEXTURE, 3, cell, true)
				elif r < 0.22:
					_water_plant(LILY_TEXTURE, 3, cell, false)
				elif r < 0.25:
					_water_plant(REEDS_TEXTURE, 2, cell, true)
				continue
			if kind == "bank":
				# trawiasta skarpa: tuż przy wodzie nic (skarpa ma być czysta), dalej kamienie, kępy trzciny,
				# drzewa dopiero z dala od wody (korona nie wisi nad nią)
				if _near_water(cell, 1):
					continue
				if r < 0.03:
					_water_plant(BANK_ROCKS, 2, cell, false)
				elif r < 0.08:
					_water_plant(REEDS_TEXTURE, 2, cell, true)
				elif r < 0.11 and not _near_water(cell, 3):
					_try_place(_random_tree(), cell, 1)
				continue
			if kind == "mud":
				if r < 0.14:
					_water_plant(CATTAIL_TEXTURE if r < 0.07 else REEDS_TEXTURE, 3 if r < 0.07 else 2, cell, true)
				elif r < 0.17:
					_try_place(MANGROVE, cell, 1)
				continue
			if _near_water(cell, 3):
				_maybe_decor(cell, 0.05)
				continue
			if edge_dist < border_thickness:
				if _rng.randf() < 0.9 - edge_dist * 0.12:
					_try_place(_random_tree(), cell, 1)
				continue
			if _grove != null and (_grove.contains(cell) or _hydra_bog.contains(cell)):  # martwy las uroczyska i bagna Hydry
				_grove.place_land_prop(cell, r)
				continue
			var density := _noise.get_noise_2d(x, y)
			if density > 0.32 and r < 0.3:
				_try_place(_random_tree(0.3), cell, 1)
			elif r < 0.02:
				_try_place(_random_tree(0.3), cell, 1)
			elif r < 0.032:
				_try_place(BUSH, cell, 0)
			elif r < 0.042:
				_try_place(BOULDER, cell, 1)
			else:
				_maybe_decor(cell, 0.07)


## Czy w promieniu `radius` kafelków jest woda (rzeka, rozlewisko).
func _near_water(cell: Vector2i, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if _water.get(cell + Vector2i(dx, dy), "") in ["deep", "shallow"]:
				return true
	return false


## Roślina wodna bez kolizji: pałki i trzcina sortują się z postaciami, lilie leżą na wodzie.
func _water_plant(texture: Texture2D, frames: int, cell: Vector2i, upright: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = frames
	sprite.frame = _rng.randi() % frames
	sprite.flip_h = _rng.randf() < 0.5
	sprite.position = _cell_to_world(cell) + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-3, 3))
	if upright:
		sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 2.0)
		entities.add_child(sprite)
	else:
		decor.add_child(sprite)


## Drewniany most nad nurtem: pokład z desek w poprzek (pod postaciami), poręcze z obu stron, słupy na końcach
## i co kilka metrów i pale w wodzie pod przednią krawędzią.
func _build_bridge(cross: Vector2) -> void:
	var y0 := floori(cross.y) - 1
	var x_from := floori(cross.x - SWAMP_RIVER_SHALLOW) - 1
	var x_to := floori(cross.x + SWAMP_RIVER_SHALLOW) + 1
	for x in range(x_from, x_to + 1):
		for y in range(y0, y0 + 3):
			var cell := Vector2i(x, y)
			_bridge_cells[cell] = true
			_map_props[cell] = MAP_BRIDGE
	var left := Vector2(x_from * TILE, y0 * TILE)
	var length := float(x_to - x_from + 1) * TILE
	# pokład: odcinki 48 px (deski w poprzek mostu), ostatni przycięty
	var x := 0.0
	while x < length:
		var deck := Sprite2D.new()
		deck.texture = DECK_TEXTURE
		deck.centered = false
		deck.region_enabled = true
		deck.region_rect = Rect2(0, 0, minf(48.0, length - x), 48)
		deck.position = left + Vector2(x, 0)
		floors.add_child(deck)
		x += 48.0
	# cień pod mostem na wodzie
	var shade := ColorRect.new()
	shade.position = left + Vector2(0, 48)
	shade.size = Vector2(length, 4)
	shade.color = Color(0.02, 0.06, 0.1, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floors.add_child(shade)
	# poręcze: tylna stoi na górnej krawędzi pokładu, przednia na dolnej (przed postaciami)
	var rail_w := float(BRIDGE_RAIL_V2.get_width())
	for edge_y in [y0 * TILE + 3.0, (y0 + 3) * TILE + 2.0]:
		var rx := 0.0
		while rx < length - 2.0:
			var rail := Sprite2D.new()
			rail.texture = BRIDGE_RAIL_V2
			rail.centered = false
			rail.region_enabled = true
			rail.region_rect = Rect2(0, 0, minf(rail_w, length - rx), BRIDGE_RAIL_V2.get_height())
			rail.offset = Vector2(0, -BRIDGE_RAIL_V2.get_height())
			rail.position = Vector2(left.x + rx, edge_y)
			entities.add_child(rail)
			rx += rail_w - 2.0
		for px in [0.0, length * 0.5, length]:
			var post := Sprite2D.new()
			post.texture = BRIDGE_POST_V2
			post.offset = Vector2(0, -BRIDGE_POST_V2.get_height() / 2.0 + 1.0)
			post.position = Vector2(left.x + px, edge_y + 1.0)
			entities.add_child(post)
	# pale w wodzie pod przednią krawędzią
	var px := 24.0
	while px < length - 16.0:
		var pillar := Sprite2D.new()
		pillar.texture = WATER_PILLAR
		pillar.offset = Vector2(0, -WATER_PILLAR.get_height() / 2.0 + 2.0)
		pillar.position = left + Vector2(px, 56)
		decor.add_child(pillar)
		px += 40.0
	var body := StaticBody2D.new()
	entities.add_child(body)
	for wall_y in [y0 * TILE - 1, (y0 + 3) * TILE - 4]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(length, 5)
		shape.shape = box
		shape.position = Vector2(x_from * TILE + length / 2.0, wall_y + 2.5)
		body.add_child(shape)


## Woda, do której nie da się wejść: głębia i płycizna rzeki (poza mostem); bagno rozlewiska i uroczyska -
## można brodzić.
func _blocks_walking(cell: Vector2i) -> bool:
	var kind: String = _water.get(cell, "")
	if _bridge_cells.has(cell) or not kind in ["deep", "shallow"]:
		return false
	if kind == "deep":
		return true
	return not _in_marsh(cell)


func _in_marsh(cell: Vector2i) -> bool:
	if ((Vector2(cell) - _swamp_center) / _swamp_radii).length() < 1.15:
		return true
	if _hydra_bog != null and _hydra_bog.strength(cell) > 0.15:
		return true
	return _grove != null and _grove.contains(cell)


## Kolizja głębokiej wody (poza mostem) - na osobnej warstwie, żeby pociski leciały nad rzeką.
func _build_water_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = WATER_LAYER
	body.collision_mask = 0
	add_child(body)
	for y in map_size.y:
		var run_start := -1
		for x in map_size.x + 1:
			var deep: bool = x < map_size.x and _blocks_walking(Vector2i(x, y))
			if deep and run_start < 0:
				run_start = x
			elif not deep and run_start >= 0:
				var shape := CollisionShape2D.new()
				var box := RectangleShape2D.new()
				box.size = Vector2((x - run_start) * TILE, TILE)
				shape.shape = box
				shape.position = Vector2((run_start + x) * TILE / 2.0, y * TILE + TILE / 2.0)
				body.add_child(shape)
				run_start = -1


## Szum rzeki - słychać go tylko blisko nurtu.
func _build_river_sounds() -> void:
	var stream: AudioStreamOggVorbis = load("res://assets/sfx/river_loop.ogg").duplicate()
	stream.loop = true
	for i in range(0, _river.size(), 24):
		var cell := Vector2i(_river[i])
		if _water.get(cell, "") != "deep":
			continue
		var sound := AudioStreamPlayer2D.new()
		sound.stream = stream
		sound.bus = "Ambient"
		sound.volume_db = -9.0
		sound.max_distance = 240.0
		sound.attenuation = 1.6
		sound.position = _river[i] * TILE
		sound.autoplay = true
		add_child(sound)


# ---------------------------------------------------------------- wioska żaboludzi
## Wioska na rozlewisku: wyspa wodza pośrodku, chaty w olbrzymich namorzynach na wysepkach
## dookoła, połączone z wyspą wodza drewnianymi kładkami, oraz gromady żaboludzi na brzegach.
func _plan_frog_village() -> void:
	_frog_lair = _swamp_center
	_make_platform(_frog_lair, Vector2i(8, 6))
	var base := _rng.randf() * TAU
	for i in FROG_HUTS:
		var angle := base + TAU * i / FROG_HUTS + _rng.randf_range(-0.2, 0.2)
		var hut := _swamp_center + Vector2.from_angle(angle) * _swamp_radii * _rng.randf_range(0.62, 0.74)
		hut = hut.clamp(Vector2(8, 8), Vector2(map_size) - Vector2(8, 8))
		_frog_huts.append(hut)
		_make_platform(hut, Vector2i(4, 3))
		_plan_walkway(_frog_lair, hut)
	for i in FROG_GROUPS:
		var angle := base + TAU * (i + 0.5) / FROG_GROUPS
		var spot := _swamp_center + Vector2.from_angle(angle) * _swamp_radii * _rng.randf_range(1.2, 1.45)
		spot = spot.clamp(Vector2(9, 9), Vector2(map_size) - Vector2(9, 9))
		if _water.get(Vector2i(spot), "") == "deep":
			continue
		_frog_groups.append(spot)
		_reserve_area(spot, 2.5)


## Pomost na palach nad wodą rozlewiska (wioska żabołaków): prostokąt z desek o ściętych narożnikach,
## pod spodem woda (z cieniem i palami na brzegach - _build_frog_village), bez drzew.
func _make_platform(center: Vector2, half: Vector2i) -> void:
	var c := Vector2i(center.round())
	for dy in range(-half.y, half.y + 1):
		for dx in range(-half.x, half.x + 1):
			if absi(dx) + absi(dy) > half.x + half.y - 2:  # ścięte narożniki
				continue
			var cell := c + Vector2i(dx, dy)
			_water[cell] = "walk"
			_walk_cells[cell] = true
	_reserve_area(center, maxf(half.x, half.y) + 1.0)


## Kładka z desek nad płycizną (od brzegu wyspy wodza do wyspy z chatą). Biegnie w kształcie litery L
## (najpierw poziomo, potem pionowo) i ma dwa kafelki szerokości - ukośna kładka z kwadratowych desek
## układała się w schodki.
func _plan_walkway(from: Vector2, to: Vector2) -> void:
	var a := Vector2i(from.round())
	var b := Vector2i(to.round())
	var corner := Vector2i(b.x, a.y)
	var step_x := signi(b.x - a.x)
	var x := a.x
	while true:
		_walk_cell(Vector2i(x, a.y), true)
		_walk_cell(Vector2i(x, a.y + 1), true)
		if x == corner.x:
			break
		x += step_x
	var step_y := signi(b.y - a.y)
	var y := a.y
	while y != b.y:
		y += step_y
		_walk_cell(Vector2i(b.x, y), false)
		_walk_cell(Vector2i(b.x + 1, y), false)


func _walk_cell(cell: Vector2i, horizontal: bool) -> void:
	if _water.get(cell, "") in ["shallow", "deep"]:
		_water[cell] = "walk"
		_walk_cells[cell] = horizontal


func _build_frog_village() -> void:
	# kładki: deski, ciemny brzeg pod spodem (cień na wodzie) i pale co kilka kafelków
	for cell: Vector2i in _walk_cells:
		# deski z tekstury 64 px w przestrzeni świata - sąsiednie kafelki pomostu łączą się bez szwów
		var plank := Sprite2D.new()
		plank.texture = WALK_H if _walk_cells[cell] else WALK_V
		plank.centered = false
		plank.region_enabled = true
		plank.region_rect = Rect2(posmod(cell.x * TILE, 64), posmod(cell.y * TILE, 64), TILE, TILE)
		plank.position = Vector2(cell * TILE)
		floors.add_child(plank)
		_map_props[cell] = MAP_BRIDGE
	for cell: Vector2i in _walk_cells:
		var top_left := Vector2(cell * TILE)
		var edges := [[Vector2i.DOWN, Rect2(0, 16, 16, 3), Color(0.03, 0.06, 0.05, 0.55)],
				[Vector2i.UP, Rect2(0, 0, 16, 1), Color(0.18, 0.11, 0.06, 0.8)],
				[Vector2i.LEFT, Rect2(0, 0, 1, 16), Color(0.18, 0.11, 0.06, 0.8)],
				[Vector2i.RIGHT, Rect2(15, 0, 1, 16), Color(0.18, 0.11, 0.06, 0.8)]]
		for edge: Array in edges:
			var next: Vector2i = cell + edge[0]
			if _walk_cells.has(next) or not _water.get(next, "") in ["shallow", "deep"]:
				continue
			var rect := ColorRect.new()
			rect.position = top_left + (edge[1] as Rect2).position
			rect.size = (edge[1] as Rect2).size
			rect.color = edge[2]
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			floors.add_child(rect)
			if edge[0] == Vector2i.DOWN and (cell.x + cell.y) % 3 == 0:
				var post := Sprite2D.new()
				post.texture = WATER_PILLAR
				post.offset = Vector2(0, -WATER_PILLAR.get_height() / 2.0 + 2.0)
				post.position = top_left + Vector2(8, 20)
				decor.add_child(post)

	# wyspa wodza: tron z muszli, koksowniki z zielonym ogniem, totemy i straż
	var lair := _frog_lair * TILE
	_village_prop(SHELL_THRONE, lair + Vector2(0, -44), Vector2(30, 8))
	for i in 4:
		var angle := PI / 4.0 + TAU * i / 4.0
		var brazier := _village_prop(BRAZIER, lair + Vector2.from_angle(angle) * Vector2(80, 58), Vector2(8, 4), 2)
		_flicker(brazier)
		_glow_at(lair + Vector2.from_angle(angle) * Vector2(80, 58) + Vector2(0, -18), Color(0.4, 1.0, 0.3, 0.35))
		_village_prop(FROG_TOTEM, lair + Vector2.from_angle(angle + PI / 4.0) * Vector2(112, 80), Vector2(8, 4))
	_add_goblin_spawn({"type": "frog_chief", "position": lair, "sitting": false, "look_at": lair, "respawn": boss_respawn_time})
	for k in 6:
		var pos := lair + Vector2.from_angle(TAU * k / 6.0 + 0.3) * Vector2(66, 46)
		_add_goblin_spawn({"type": "frogman" if k % 3 else "frog_spitter", "position": pos, "sitting": false, "look_at": lair})
	_map_markers.append({"position": lair, "color": MAP_BOSS, "size": 4.0})

	# chaty w namorzynach z ogniskiem, suszarnią ryb, sieciami i gromadą żaboludzi
	for hut_tile in _frog_huts:
		var hut := hut_tile * TILE
		_village_prop(HUT_TREES.pick_random(), hut + Vector2(0, -10), Vector2(24, 10))
		var fire := hut + Vector2(_rng.randf_range(-8, 8), 46)
		_spawn(CAMPFIRE, fire)
		_map_markers.append({"position": fire, "color": MAP_FIRE, "size": 2.0})
		_map_markers.append({"position": hut, "color": MAP_TENT, "size": 2.5})
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		_village_prop(FISH_RACK, hut + Vector2(-48 * side, 34), Vector2(28, 4))
		_village_prop(FISH_NET, hut + Vector2(46 * side, 22), Vector2(30, 4))
		_village_prop(CLAY_POTS, hut + Vector2(-26 * side, 62))
		_village_prop(FROG_TOTEM, hut + Vector2(34 * side, 62), Vector2(8, 4))
		# dłubanka zacumowana na wodzie przy wyspie
		for k in 12:
			var spot := hut + Vector2.from_angle(_rng.randf() * TAU) * 5.6 * TILE
			if water_at(spot) == "shallow":
				_village_prop(CANOE, spot)
				break
		var count := _rng.randi_range(5, 7)
		var offset := _rng.randf() * TAU
		for k in count:
			var angle := offset + TAU * k / count + _rng.randf_range(-0.15, 0.15)
			var pos := fire + Vector2.from_angle(angle) * Vector2(24, 18)
			_add_goblin_spawn({"type": "frog_spitter" if k % 3 == 0 else "frogman", "position": pos, "sitting": true, "look_at": fire})

	# gromady na brzegach dookoła rozlewiska
	for group in _frog_groups:
		var center := group * TILE
		for k in _rng.randi_range(5, 7):
			var pos := center + Vector2(_rng.randf_range(-18, 18), _rng.randf_range(-14, 14))
			_add_goblin_spawn({"type": "frog_spitter" if k % 3 == 0 else "frogman", "position": pos, "sitting": false, "look_at": center})


## Rekwizyt wioski stojący na ziemi (punkt zaczepienia u podstawy), opcjonalnie z kolizją.
func _village_prop(texture: Texture2D, pos: Vector2, collision := Vector2.ZERO, frames := 1) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = frames
	sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 2.0)
	if collision == Vector2.ZERO:
		sprite.position = pos
		entities.add_child(sprite)
		return sprite
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = collision
	shape.shape = box
	shape.position = Vector2(0, -collision.y / 2.0)
	body.add_child(shape)
	body.add_child(sprite)
	entities.add_child(body)
	return sprite


## Migoczący zielony ogień koksownika.
func _flicker(sprite: Sprite2D) -> void:
	var timer := Timer.new()
	timer.wait_time = 0.18
	timer.autostart = true
	timer.timeout.connect(func() -> void: sprite.frame = (sprite.frame + 1) % 2)
	sprite.add_child(timer)


func _glow_at(pos: Vector2, color: Color) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 44
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.position = pos
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	floors.add_child(glow)
