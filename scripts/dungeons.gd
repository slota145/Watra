class_name Dungeons
## Lochy w płomieniach Watry - dane: klimaty (zestaw kafelków z PixelLab, potwory, strażnik, wystrój, kolory),
## stopnie trudności i modyfikatory kupowane za żar. Generator lochu to scripts/dungeon.gd, okno wyboru -
## scripts/ui/dungeon_window.gd. Poziom Watry odblokowuje kolejne stopnie (stopień <= poziom Watry) i modyfikatory.

## Rozmiar lochu w kafelkach gry (siatka lochu: 40x30 wierzchołków co 64 px = 39x29 kafelków Wang).
const SIZE := Vector2i(156, 116)
const NAME := "Lochy Watry"

## klimat: nazwa, opis, arkusz Wang (assets/dungeons/<klimat>.png, tools/dungeon_tiles.py), potwory z wagami,
## strażnik (boss), przyciemnienie świata, kolor światła, lampa (pochodnia, koksownik, grzyby - liczba klatek),
## wystrój (porozrzucany i pod ścianami) i kolory minimapy.
const CLIMATES := {
	"catacombs": {
		"name": "Katakumby", "description": "Kamienne krypty pełne kości. Szkielety, trupojady i zombie; strzeże ich nekromanta.",
		"tiles": preload("res://assets/dungeons/catacombs.png"),
		"monsters": {"skeleton": 5, "skeleton_archer": 3, "zombie": 2, "ghoul": 1.5, "skeleton_knight": 1},
		"boss": "necromancer", "tint": Color(0.62, 0.62, 0.74), "light": Color(1.0, 0.62, 0.3, 0.6),
		"lamp": "res://assets/village/torch_stand.png", "lamp_frames": 2,
		"props": ["res://assets/cemetery/skulls.png", "res://assets/cemetery/sarcophagus.png", "res://assets/forest/props/bones.png",
				"res://assets/wild/bones.png", "res://assets/cemetery/fallen_stone.png", "res://assets/cemetery/corpses.png",
				"res://assets/cemetery/open_grave.png", "res://assets/forest/props/ribcage.png", "res://assets/forest/props/bone_pile.png",
				"res://assets/forest/props/skull_bones.png", "res://assets/forest/props/cage.png"],
		"wall_props": ["res://assets/cemetery/candle.png", "res://assets/cemetery/sarcophagus.png", "res://assets/forest/props/cage.png",
				"res://assets/cemetery/skulls.png"],
		"map_floor": Color("5c5650"), "map_wall": Color("16151a"),
		# wystrój komnat (scripts/decor_<klimat>.gd): rodzaje komnat i grafiki z tools/dungeon_props.py
		"decor": {"dir": "res://assets/dungeons/catacombs/", "tint": Color(0.6, 0.6, 0.72),
				"themes": ["crypt", "pillars", "ossuary", "chapel", "collapsed", "prison"]},
	},
	"mine": {
		"name": "Kopalnia goblinów", "description": "Chodniki z belkami, porzucone wózki i beczki prochu. Gobliny i koboldy; rządzi nimi wódz.",
		"tiles": preload("res://assets/dungeons/mine.png"),
		"monsters": {"goblin": 4, "archer": 2, "kobold": 3, "kobold_slinger": 2, "kobold_bomber": 1, "brute": 1},
		"boss": "chief", "tint": Color(0.74, 0.66, 0.56), "light": Color(1.0, 0.66, 0.3, 0.6),
		"lamp": "res://assets/village/torch_stand.png", "lamp_frames": 2,
		"props": ["res://assets/forest/props/barrel.png", "res://assets/fields/powder_barrel.png", "res://assets/village/handcart.png",
				"res://assets/fields/cart.png", "res://assets/fields/rubble.png", "res://assets/forest/props/boulders.png",
				"res://assets/village/deco_wheelbarrow.png", "res://assets/fields/sacks.png", "res://assets/forest/props/pots.png"],
		"wall_props": ["res://assets/village/crate.png", "res://assets/village/coal_sack.png", "res://assets/village/deco_tools.png",
				"res://assets/fields/bomb_crate.png", "res://assets/forest/props/weapon_rack.png", "res://assets/village/barrel.png"],
		"map_floor": Color("755433"), "map_wall": Color("1b1613"),
		"decor": {"dir": "res://assets/dungeons/mine/", "tint": Color(0.68, 0.6, 0.52),
				"themes": ["tracks", "powder", "forge", "camp", "shaft", "cavein", "vein"]},
	},
	"flooded": {
		"name": "Zatopione podziemia", "description": "Zalane, omszałe ruiny. Topielce, żabołaki, ogniki i topielice; w głębi czeka wodnik.",
		"tiles": preload("res://assets/dungeons/flooded.png"),
		"monsters": {"drowner": 4, "frogman": 3, "frog_spitter": 2, "wisp": 1.5, "rusalka": 1},
		"boss": "wodnik", "tint": Color(0.56, 0.68, 0.64), "light": Color(0.45, 1.0, 0.7, 0.55),
		"lamp": "res://assets/frogs/brazier.png", "lamp_frames": 2,
		"props": ["res://assets/swamp/v2_rocks.png", "res://assets/drowned/sunken_cross.png", "res://assets/drowned/soul_jars.png",
				"res://assets/swamp/v2_lilies.png", "res://assets/drowned/rotten_stump.png", "res://assets/drowned/sunken_boat.png",
				"res://assets/swamp/v2_reeds.png", "res://assets/ancient/v2_mossy_rocks.png"],
		"wall_props": ["res://assets/frogs/clay_pots.png", "res://assets/frogs/fish_net.png", "res://assets/swamp/v2_pillar.png",
				"res://assets/drowned/soul_jars.png"],
		"map_floor": Color("455844"), "map_wall": Color("0c120b"),
		"decor": {"dir": "res://assets/dungeons/flooded/", "tint": Color(0.6, 0.7, 0.68),
				"themes": ["temple", "boardwalk", "wrecks", "nest", "wisps", "frogs", "rusalka", "spring"]},
	},
	"roots": {
		"name": "Pajęcze korzenie", "description": "Podziemia pod Prastarym Lasem, oplecione korzeniami i siecią. Pająki i drzewce; w gnieździe królowa pająków.",
		"tiles": preload("res://assets/dungeons/roots.png"),
		"monsters": {"spider": 4, "web_spider": 2, "spiderling": 3, "treant": 1},
		"boss": "spider_queen", "tint": Color(0.6, 0.64, 0.56), "light": Color(0.45, 0.75, 1.0, 0.55),
		"lamp": "res://assets/ancient/v2_mushroom_ring.png", "lamp_frames": 1,
		"props": ["res://assets/ancient/web_small.png", "res://assets/ancient/web_big.png", "res://assets/forest/props/bones.png",
				"res://assets/ancient/v2_mushroom_ring.png", "res://assets/ancient/v2_roots.png", "res://assets/ancient/glow_shroom.png",
				"res://assets/ancient/bone_pile.png", "res://assets/ancient/v2_mossy_rocks.png", "res://assets/ancient/wrapped_victim.png"],
		"wall_props": ["res://assets/ancient/egg_sac.png", "res://assets/ancient/web_small.png", "res://assets/ancient/v2_roots.png",
				"res://assets/ancient/glow_shroom.png"],
		"map_floor": Color("47492c"), "map_wall": Color("1a130f"),
		"decor": {"dir": "res://assets/dungeons/roots/", "tint": Color(0.58, 0.64, 0.6),
				"themes": ["hatchery", "larder", "roots", "mycelium", "webhall", "treants", "camp", "altar"]},
	},
	# loch na zewnątrz (Dungeon.outdoor): polany i kręte ścieżki, granicą klify, ściana drzew i stawy (progi szumu
	# w "terrain"); kafelki to klify Wietrznych Turni (tools/dungeon_tiles.py), podłoże - tekstury gór (SoftGround)
	"vineyard": {
		"name": "Winnica satyrów", "description": "Dzika winnica na skalnych tarasach. Satyrowie upili się winem z płomieni Watry i świętują bez końca; ucztą rządzi Król Satyrów.",
		"tiles": preload("res://assets/dungeons/vineyard.png"), "outdoor": true,
		"monsters": {"satyr": 5, "satyr_piper": 2, "satyr_brute": 1.5},
		"boss": "satyr_king", "tint": Color(0.9, 0.78, 0.72), "light": Color(1.0, 0.7, 0.35, 0.55),
		"terrain": {"cliff_below": -0.28, "water_above": 0.32,
				"trees": ["res://assets/forest/trees/oak_0.png", "res://assets/forest/trees/oak_1.png", "res://assets/forest/trees/oak_2.png",
						"res://assets/forest/trees/oak_3.png", "res://assets/forest/trees/oak_4.png", "res://assets/forest/trees/oak_5.png",
						"res://assets/forest/trees/oak_6.png", "res://assets/forest/trees/oak_7.png", "res://assets/forest/trees/pine_0.png",
						"res://assets/forest/trees/pine_1.png", "res://assets/forest/trees/pine_2.png"],
				"plateau": ["res://assets/forest/trees/bush_0.png", "res://assets/forest/trees/bush_1.png", "res://assets/forest/trees/bush_2.png",
						"res://assets/forest/trees/rock_0.png", "res://assets/forest/trees/rock_1.png"],
				"reeds": "res://assets/swamp/v2_reeds.png", "lilies": "res://assets/swamp/v2_lilies.png",
				# pola winorośli na terenie niedostępnym (Dungeon._vine_fields)
				"vines": ["res://assets/mountains/satyr/vine_row.png", "res://assets/mountains/satyr/vine_row_2.png"], "vines_above": -0.45},
		"map_floor": Color("4f8a2c"), "map_wall": Color("6e6652"), "map_trees": Color("1f3a17"), "map_water": Color("2f5f6e"),
		"map_path": Color("8a7048"), "map_vines": Color("3e5a26"),
		"decor": {"dir": "res://assets/dungeons/vineyard/", "tint": Color(0.92, 0.8, 0.74),
				"themes": ["vines", "vines", "press", "feast", "dance", "vines", "orchard", "goats", "camp", "pond"]},
	},
	# drugi loch na zewnątrz: granicą palisada (Dungeon.palisades - pale wzdłuż gładkiego obrysu, za nią spalone
	# zagrody), las i stawy; bez klifów (kafelki Wang nieużywane)
	"stronghold": {
		"name": "Oblężony gród", "description": "Gród zdobyty i spalony przez hordę koboldów. Za połamaną palisadą dymią zgliszcza zagród, na majdanie stoi obóz najeźdźców, a z ruin dworu rządzi nimi Bombardier Kaszlak.",
		"tiles": preload("res://assets/dungeons/vineyard.png"), "outdoor": true,
		"monsters": {"kobold": 5, "kobold_slinger": 3, "kobold_bomber": 2},
		"boss": "bombardier", "tint": Color(0.86, 0.74, 0.7), "light": Color(1.0, 0.6, 0.3, 0.55),
		"terrain": {"cliff_below": -2.0, "water_above": 0.45, "palisade_below": 0.15,
				"trees": ["res://assets/forest/trees/oak_0.png", "res://assets/forest/trees/oak_1.png", "res://assets/forest/trees/oak_2.png",
						"res://assets/forest/trees/oak_3.png", "res://assets/forest/trees/pine_0.png", "res://assets/forest/trees/pine_1.png",
						"res://assets/forest/trees/pine_2.png"],
				"plateau": [], "reeds": "res://assets/swamp/v2_reeds.png", "lilies": "res://assets/swamp/v2_lilies.png",
				# pale palisady (klatki jak w Ostoi - Settlement.STAKE_WEIGHTS) i pale złamane
				"stakes": "res://assets/village/palisade_stake.png", "stakes_broken": "res://assets/village/palisade_stake_broken.png"},
		"map_floor": Color("5a7a34"), "map_wall": Color("5c4632"), "map_trees": Color("1f3a17"), "map_water": Color("2f5f6e"),
		"map_path": Color("8a7048"), "map_yard": Color("4a3a2c"),
		"decor": {"dir": "res://assets/village/", "tint": Color(0.86, 0.74, 0.7),
				"themes": ["burned", "camp", "gate", "square", "burned", "camp", "burned", "gate", "square", "camp"]},
	},
}
const CLIMATE_ORDER: Array[String] = ["catacombs", "mine", "flooded", "roots", "vineyard", "stronghold"]

## Mechaniki lochu - powód, żeby robić lochy. Każdy loch ma co najmniej jedną, z małą szansą drugą i trzecią
## (bez powtórzeń); proste ("small") mają większą wagę niż duże ("large"). "room" - mechanika zajmuje własną
## komnatę (bez zwykłych potworów). Losuje je Dungeons.roll_mechanics, buduje Dungeon._build_mechanics.
## Nowa mechanika: wpis tutaj i gałąź w Dungeon._build_mechanics.
const MECHANICS := {
	"chests": {"name": "Skrzynie", "weight": 10.0, "size": "small"},
	"shrine": {"name": "Kapliczka", "weight": 8.0, "size": "small"},
	"crystal": {"name": "Kryształ Watry", "weight": 7.0, "size": "large", "room": true},
	"elites": {"name": "Elitarne potwory", "weight": 8.0, "size": "small"},
	"uroczysko": {"name": "Uroczysko", "weight": 5.0, "size": "large"},
	"zertwa": {"name": "Krąg Żertwy", "weight": 5.0, "size": "large"},
	"skarbnik": {"name": "Skarbnik", "weight": 5.0, "size": "large"},
}
## Szansa na drugą i trzecią mechanikę.
const MECHANIC_EXTRA: Array[float] = [0.25, 0.08]
## Kryształ Watry (scripts/watra_crystal.gd): warianty zdarzenia (obrona kryształu albo górników).
const EVENTS: Array[String] = ["crystal", "miners"]

## Skrzynie (scripts/dungeon_chest.gd) - jak strongboxy w PoE: rodzaj mówi, jaki łup jest w środku.
## "weight" - jak często, "tint" - kolor skrzyni, "glow" - poświata.
const CHEST_KINDS := {
	"common": {"name": "Skrzynia", "weight": 5.0, "tint": Color(1.0, 1.0, 1.0), "glow": Color(1.0, 0.85, 0.5, 0.35)},
	"smith": {"name": "Skrzynia kowala", "weight": 3.0, "tint": Color(0.75, 0.82, 0.95), "glow": Color(0.6, 0.75, 1.0, 0.4)},
	"jeweler": {"name": "Szkatuła jubilera", "weight": 2.0, "tint": Color(0.9, 0.7, 1.0), "glow": Color(0.85, 0.5, 1.0, 0.4)},
	"gold": {"name": "Skarbnica", "weight": 2.0, "tint": Color(1.0, 0.88, 0.45), "glow": Color(1.0, 0.8, 0.25, 0.45)},
}
## Cechy skrzyń: strzeżona (po otwarciu wyskakują strażnicy, skrzynia otwiera się po ich pokonaniu, łupu więcej),
## obfita (więcej łupu), cenna (lepsze rzadkości). "chance" - szansa na cechę, "loot" - mnożnik ilości łupu.
const CHEST_TRAITS := {
	"guarded": {"name": "Strzeżona", "chance": 0.3, "loot": 1.4},
	"rich": {"name": "Obfita", "chance": 0.25, "loot": 1.6},
	"rare": {"name": "Cenna", "chance": 0.2, "loot": 1.0},
}
## Ile skrzyń w lochu z tą mechaniką.
const CHESTS := Vector2i(2, 4)

## Kapliczki (scripts/dungeon_shrine.gd): krótki, mocny dar (Boons, grupa "shrine") po modlitwie.
const SHRINES: Array[String] = ["shrine_might", "shrine_ward", "shrine_haste", "shrine_fortune", "shrine_wisdom", "shrine_moon"]
## Ile kapliczek w lochu z tą mechaniką (każda daje inny dar).
const SHRINE_COUNT := Vector2i(1, 2)
## Uroczysko (scripts/uroczysko.gd) - jak Breach w PoE: dotknięty kamień otwiera krąg innego świata pełen upiorów.
## Każdy zabity upiór poszerza krąg (URO_GROW px, mniej przy dużym kręgu), a krąg ciągle się kurczy (URO_SHRINK px/s,
## coraz szybciej - URO_SPEEDUP s do podwojenia); gdy zmaleje do URO_END, gaśnie - upiory znikają, a kamień sypie runy
## (1 + zabici / URO_KILLS_PER_RUNE, najwyżej URO_RUNES_MAX). Upiory to potwory klimatu lochu jako zjawy
## (shaders/ghost.gdshader) - słabsze, ale liczne: (URO_ALIVE + promień / URO_ALIVE_PER) razy uro_density (rośnie ze
## stopniem lochu), wychodzą gromadami po URO_PACK z jednego miejsca; żyją tylko w kręgu.
## Co URO_LORD_EVERY zabitych pojawia się Upiorny Pan (mocniejszy, zawsze daje runę).
const URO_START := 110.0
const URO_MAX := 430.0
const URO_END := 36.0
const URO_GROW := 2.5
const URO_SHRINK := 7.0
const URO_SPEEDUP := 35.0
## Grace: przez tyle sekund po otwarciu krąg się nie kurczy.
const URO_GRACE := 4.0
const URO_ALIVE := 14
const URO_ALIVE_PER := 9.0
const URO_SPAWN_EVERY := 0.22
## Gromada upiorów wychodząca naraz z jednego miejsca kręgu [od, do].
const URO_PACK := Vector2i(3, 5)
## Gęstość upiorów rośnie ze stopniem lochu jak liczba potworów (count_multiplier), ale łagodniej (do tej potęgi).
const URO_DENSITY_POWER := 0.25
## Najwięcej upiorów naraz (wydajność: walka z setką zjaw naraz kosztuje dwa razy więcej niż w gromadzie krainy).
const URO_ALIVE_MAX := 50
const URO_KILLS_PER_RUNE := 30
const URO_RUNES_MAX := 10
## Upiór: mnożniki zdrowia, obrażeń i nagród zwykłego potwora klimatu.
const URO_HEALTH := 0.6
const URO_DAMAGE := 0.8
const URO_XP := 0.6
## Szansa, że zwykły upiór upuści runę.
const URO_GHOST_RUNE := 0.006
const URO_LORD_EVERY := 80
const URO_LORD_HEALTH := 6.0
const URO_LORD_DAMAGE := 1.4

## Krąg Żertwy (scripts/zertwa.gd) - jak Ritual w PoE: pień ofiarny dotknięty (F) otwiera krąg o promieniu ZER_RADIUS;
## spoza kręgu nadciągają fale potworów klimatu (ZER_ALIVE naraz, co ZER_SPAWN_EVERY s, ZER_SPAWN_GAP px za brzegiem).
## Każdy wróg zabity w kręgu (także zwykły potwór lochu) to danina: ZER_TRIBUTE, elita i Wybraniec - ZER_ELITE_TRIBUTE;
## co ZER_CHOSEN_EVERY daniny nadciąga Wybraniec (większy, zdrowie x ZER_CHOSEN_HEALTH). Po ZER_GOAL daninie pień
## czeka na odebranie nagrody (F) - kto składa dalej (do ZER_GOAL * ZER_OVERFLOW), dostaje lepszą ofertę.
## Nagroda: wybór 1 z ZER_OFFER talizmanów (Talismans.roll_offer) - szanse na rzadki i wielki rosną z nadwyżką daniny.
const ZER_RADIUS := 170.0
const ZER_GOAL := 60
const ZER_OVERFLOW := 2.0
const ZER_TRIBUTE := 1
const ZER_ELITE_TRIBUTE := 5
const ZER_ALIVE := 9
const ZER_SPAWN_EVERY := 0.45
const ZER_SPAWN_GAP := Vector2(30.0, 150.0)
const ZER_CHOSEN_EVERY := 20
const ZER_CHOSEN_HEALTH := 5.0
const ZER_CHOSEN_DAMAGE := 1.3
## Fale: mnożniki nagród zwykłego potwora (doświadczenie, szansa na przedmiot).
const ZER_XP := 0.7
const ZER_ITEMS := 0.3
const ZER_OFFER := 3
## Oferta talizmanów: szansa na rzadki i na wielki (2x2) bez nadwyżki daniny i dodatek przy pełnej nadwyżce.
const ZER_RARE_CHANCE := 0.25
const ZER_RARE_BONUS := 0.5
const ZER_LARGE_CHANCE := 0.1
const ZER_LARGE_BONUS := 0.3
## Poziom przedmiotu talizmanów: poziom lochu plus tyle za stopień.
const ZER_LEVEL_PER_TIER := 1

## Skarbnik (scripts/skarbnik.gd, oferta - scripts/skarbnik_offer.gd) - jak Ultimatum w PoE: duch starego górnika
## pokazuje ofertę SKA_OFFER (czasem o 1 więcej) nagród. Weź - jedna nagroda i koniec. Wzmocnij - fale potworów
## (SKA_WAVES fal na kolejnym wzmocnieniu), po wygranej oferta (silniejsza) czeka u następnego Skarbnika, także
## w kolejnym lochu. Przelosuj - za Kości Skarbnika (SKA_BONES): rodzaje premii, kamieni i run od nowa, fale bez
## wzrostu siły. Śmierć, wyjście z lochu albo wczytanie gry w trakcie fal - oferta przepada.
## Ilu Skarbników w lochu z tą mechaniką (więcej dadzą drzewko Watry i przedmioty w Watrze: "skarbnik_count"
## w premiach mechanik - Dungeons.roll_mechanics, config["mechanic_bonus"]).
const SKA_COUNT := 1
const SKA_OFFER := 3
const SKA_OFFER_EXTRA := 0.4
## Rodzaje nagród w ofercie (pierwsza to zawsze przedmiot; kamień szlachetny dopiero po zadaniu jubilera).
const SKA_REWARDS := {"item": 2.0, "rune": 2.0, "stone": 2.0, "gem": 1.5}
## Kamienie zaklinania w ofercie: [najmniej, najwięcej] sztuk i waga.
const SKA_STONES := {"weapon_stone": [3, 6, 3.0], "armor_stone": [3, 6, 3.0], "jewelry_stone": [3, 6, 3.0],
		"blessed_stone": [20, 40, 1.0], "mercy_stone": [3, 6, 1.0]}
const SKA_RUNES := Vector2i(2, 4)
## Najwięcej wzmocnień; ostatnie podnosi premie przedmiotów na sufit i przemienia je w legendy.
const SKA_MAX_STEPS := 6
## Fale na kolejnych wzmocnieniach (1-6) i przy przelosowaniu (jak przy obecnym wzmocnieniu, co najmniej pierwszym).
const SKA_WAVES: Array[int] = [1, 2, 2, 3, 3, 4]
## Wrogowie do pokonania w jednej fali i żywi naraz na kolejnych wzmocnieniach. Sufit 150 żywych - pomiar
## tests/bench_skarbnik.gd (listopad 2026): Mgnienie wśród 150 wrogów kosztuje mniej niż walka w największej gromadzie
## Turni i Cmentarza (bench_village), przy 200 już więcej. Na 6. wzmocnieniu 4 fale po 340 = 1360 zabitych.
const SKA_WAVE_KILLS: Array[int] = [60, 100, 140, 200, 260, 340]
const SKA_ALIVE: Array[int] = [30, 50, 70, 95, 120, 150]
## Poziom potworów fal: poziom lochu plus tyle za każde wzmocnienie.
const SKA_LEVEL_PER_STEP := 2
## Cechy elit w falach od tego wzmocnienia: szansa na elitę rośnie o SKA_ELITE_CHANCE za każde wzmocnienie wyżej.
const SKA_ELITE_FROM := 4
const SKA_ELITE_CHANCE := 0.03
## Wrogowie wychodzą z kilku stron: tyle bram w odległości SKA_GATE_DISTANCE od Skarbnika, nowe bramy co falę.
const SKA_GATES := 3
const SKA_GATE_DISTANCE := Vector2(220.0, 420.0)
const SKA_SPAWN_EVERY := 0.12
const SKA_WAVE_PAUSE := 3.0
## O ile tierów rośnie każda premia przy jednym wzmocnieniu; sufit - najlepszy tier z pasma szczęścia dla poziomu
## przedmiotu minus SKA_CEILING_EXTRA (poziom 43: T8; T1 dopiero dla przedmiotów 80.+ poziomu).
const SKA_TIER_STEP := 4
## Poziom przedmiotów w ofercie: poziom lochu plus tyle (stopień 7: 43).
const SKA_ITEM_LEVEL_BONUS := 2
const SKA_CEILING_EXTRA := 5
## Runy i kamienie zaklinania: +50% sztuk za wzmocnienie; kamień szlachetny: szlif +1.
const SKA_COUNT_GROWTH := 0.5
## Kości Skarbnika (przelosowanie): pewna sztuka po wygranych falach i szansa z każdego wroga fal.
const SKA_BONES := "skarbnik_bones"
const SKA_BONES_CHANCE := 0.004
## Fale: mnożniki nagród zwykłego potwora (doświadczenie, szansa na przedmiot).
const SKA_XP := 0.6
const SKA_ITEMS := 0.25

## Elitarne potwory (scripts/dungeon_elite.gd): zwykły potwór lochu wzmocniony 1-3 cechami, każda z innej grupy
## (aura, obrona, żywioł, przywołanie). "name" - przymiotnik w napisie nad głową, "color" - poświata (od pierwszej cechy),
## "power" - siła cechy (znaczenie w opisie każdej grupy w DungeonElite).
const ELITE_TRAITS := {
	# aury: wrogowie w promieniu ELITE_AURA_RADIUS (i sama elita)
	"commander": {"name": "Dowódczy", "group": "aura", "color": Color(1.0, 0.35, 0.25), "power": 0.4},  # +40% obrażeń
	"hastening": {"name": "Poganiający", "group": "aura", "color": Color(0.5, 1.0, 0.9), "power": 0.3},  # +30% ruchu i ataku
	"warding": {"name": "Osłaniający", "group": "aura", "color": Color(0.55, 0.7, 1.0), "power": 0.35},  # -35% obrażeń
	# obrona
	"shielded": {"name": "Tarczowy", "group": "defense", "color": Color(0.45, 0.75, 1.0), "power": 0.6},  # tarcza 60% zdrowia
	"healer": {"name": "Uzdrawiający", "group": "defense", "color": Color(0.45, 1.0, 0.45), "power": 0.03},  # 3% zdrowia/s
	"thorns": {"name": "Kolczasty", "group": "defense", "color": Color(0.85, 0.85, 0.5), "power": 0.2},  # 20% odbija
	# żywioły
	"volatile": {"name": "Wybuchowy", "group": "element", "color": Color(1.0, 0.55, 0.15), "power": 2.5},  # wybuch po śmierci
	"burning": {"name": "Płonący", "group": "element", "color": Color(1.0, 0.45, 0.1), "power": 0.35},  # płonący ślad
	"frost": {"name": "Mroźny", "group": "element", "color": Color(0.6, 0.9, 1.0), "power": 0.7},  # mroźne fale
	"storm": {"name": "Burzowy", "group": "element", "color": Color(0.8, 0.75, 1.0), "power": 1.3},  # pioruny z nieba
	# przywołanie
	"summoner": {"name": "Przywołujący", "group": "summon", "color": Color(0.8, 0.45, 1.0), "power": 2.0},  # pomocnicy
	"splitting": {"name": "Rozszczepialny", "group": "summon", "color": Color(0.95, 0.5, 0.8), "power": 3.0},  # dzieli się
}
## Ile elit w lochu z tą mechaniką i szanse na 1, 2 i 3 cechy.
const ELITES := Vector2i(3, 5)
const ELITE_TRAIT_COUNT: Array[float] = [0.45, 0.4, 0.15]
## Statystyki elity: zdrowie x(3 + 0,75 za cechę), obrażenia x1,3, doświadczenie x(3 + 1 za cechę), złoto x3.
const ELITE_HEALTH := 3.0
const ELITE_HEALTH_PER_TRAIT := 0.75
const ELITE_DAMAGE := 1.3
const ELITE_XP := 3.0
const ELITE_GOLD := 3.0
## Łup elity (oprócz zwykłego łupu potwora): 1 + liczba cech przedmiotów, pierwszy co najmniej magiczny; każda cecha
## podnosi szansę na lepszą rzadkość (Loot.roll_quality) i na legendę.
const ELITE_QUALITY_PER_TRAIT := 0.1
const ELITE_LEGEND_CHANCE := 0.02
const ELITE_LEGEND_PER_TRAIT := 0.015


## Cechy elity: 1-3 (ELITE_TRAIT_COUNT), każda z innej grupy.
static func roll_elite_traits(rng: RandomNumberGenerator) -> Array[String]:
	var count := 1
	var roll := rng.randf()
	for i in ELITE_TRAIT_COUNT.size():
		roll -= ELITE_TRAIT_COUNT[i]
		if roll <= 0.0:
			count = i + 1
			break
	var groups := {}
	for id: String in ELITE_TRAITS:
		var group: String = ELITE_TRAITS[id]["group"]
		if not groups.has(group):
			groups[group] = []
		(groups[group] as Array).append(id)
	var names: Array = groups.keys()
	var result: Array[String] = []
	while result.size() < count and not names.is_empty():
		var group: String = names.pop_at(rng.randi_range(0, names.size() - 1))
		var options: Array = groups[group]
		result.append(options[rng.randi_range(0, options.size() - 1)])
	return result


## Poziom potworów na stopniach: 1-7 w oknie lochów (stopień wybiera gracz, najwyżej poziom Watry), 8-17 tylko
## z węzłów Mapy Nawii (NawiaMap, poziomy 45-90); strażnik ma o 2 więcej.
const TIER_LEVELS: Array[int] = [5, 11, 17, 23, 29, 35, 41, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90]
## Stopnie dostępne w zwykłym oknie lochów (wyższe są na Mapie Nawii).
const BASE_TIERS := 7
const BOSS_BONUS := 2
## Liczba potworów rośnie płynnie z prawdziwym stopniem (także na Mapie Nawii): 1 + LINEAR * (stopień - 1)
## + SQUARE * (stopień - 1)^2 - stopień 7 około 1,65 raza, 12 - 2,6, najwyższy (17) 4 razy tyle co stopień 1.
const TIER_COUNT_LINEAR := 0.06
const TIER_COUNT_SQUARE := 0.008

## Modyfikatory za żar (dostępny żar = zebrany minus wydany - wydawanie nie obniża poziomu Watry).
## "unlock" - od którego poziomu Watry; reszta to mnożniki dla potworów (Goblin.dungeon_mods) i skarbca.
const MODIFIERS := {
	"horde": {"name": "Hordy", "description": "+60% potworów", "cost": 40, "unlock": 1, "count": 1.6},
	"wealth": {"name": "Bogactwo", "description": "+50% złota, dwa razy częściej przedmioty", "cost": 60, "unlock": 2,
			"gold": 1.5, "loot": 2.0},
	"fury": {"name": "Wściekłość", "description": "Potwory +25% zdrowia i obrażeń, +50% doświadczenia", "cost": 50, "unlock": 3,
			"health": 1.25, "damage": 1.25, "xp": 1.5},
	"treasure": {"name": "Pełny skarbiec", "description": "Skarbiec strażnika: dwa razy więcej łupu, w tym rzadkie przedmioty",
			"cost": 80, "unlock": 4, "treasure": 2.0},
}
const MODIFIER_ORDER: Array[String] = ["horde", "wealth", "fury", "treasure"]
## Legendarne przedmioty ze skarbca strażnika (tylko z lochów) i szansa na jeden z nich (Pełny skarbiec ją podwaja).
const VAULT_LEGENDS: Array[String] = ["legend_endless_amulet", "legend_swarog_bow", "legend_engineer_gloves", "legend_tracker_talisman",
		"legend_marzanna_book", "legend_perun_crown", "legend_mokosh_belt", "legend_bogatyr_girdle"]
const VAULT_LEGEND_CHANCE := 0.07


## Losuje mechaniki lochu: pierwsza zawsze, druga i trzecia z szansą MECHANIC_EXTRA (bez powtórzeń).
## `bonus` - na później (drzewko Watry, bożki): "weights" {id: mnożnik wagi}, "extra" [premia do szansy drugiej,
## trzeciej], "forced" [mechaniki zawsze obecne - nie liczą się do limitu].
static func roll_mechanics(rng: RandomNumberGenerator, bonus := {}) -> Array[String]:
	var result: Array[String] = []
	for id: String in bonus.get("forced", []):
		if MECHANICS.has(id) and not result.has(id):
			result.append(id)
	var weights: Dictionary = bonus.get("weights", {})
	var extra: Array = bonus.get("extra", [])
	for i in 1 + MECHANIC_EXTRA.size():
		if i > 0:
			var chance: float = MECHANIC_EXTRA[i - 1] + float(extra[i - 1] if extra.size() >= i else 0.0)
			if rng.randf() >= chance:
				break
		var pool := {}
		for id: String in MECHANICS:
			if not result.has(id):
				pool[id] = float(MECHANICS[id]["weight"]) * float(weights.get(id, 1.0))
		var id := weighted(rng, pool)
		if id == "":
			break
		result.append(id)
	return result


## Jak często loch ma daną mechanikę (próba wielu losowań - do symulacji balansu i testów).
static func mechanic_chance(id: String, samples := 4000) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var hits := 0
	for i in samples:
		if roll_mechanics(rng).has(id):
			hits += 1
	return float(hits) / samples


## Losowy klucz słownika {klucz: waga} ("" - pusty albo same zera).
static func weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for key: String in weights:
		total += maxf(float(weights[key]), 0.0)
	if total <= 0.0:
		return ""
	var roll := rng.randf() * total
	for key: String in weights:
		roll -= maxf(float(weights[key]), 0.0)
		if roll <= 0.0 and float(weights[key]) > 0.0:
			return key
	return weights.keys().back()


static func tier_level(tier: int) -> int:
	return TIER_LEVELS[clampi(tier, 1, TIER_LEVELS.size()) - 1]


## Stopień do liczebności i nagród mechanik (liczba potworów, fale, strażnicy skrzyń, runy, kamienie): na Mapie Nawii
## stopnie 8-17 liczą się jak 7 - trudność i łup rosną tam z poziomem potworów, a nie z liczbą wrogów naraz.
static func power_tier(tier: int) -> int:
	return clampi(tier, 1, BASE_TIERS)


## Mnożnik liczby upiorów naraz w Uroczysku na danym stopniu lochu.
static func uro_density(tier: int) -> float:
	return pow(count_multiplier(tier), URO_DENSITY_POWER)


## Mnożnik liczby potworów w lochu danego stopnia (bez modyfikatorów i bożków).
static func count_multiplier(tier: int) -> float:
	var t := clampi(tier, 1, TIER_LEVELS.size()) - 1
	return 1.0 + TIER_COUNT_LINEAR * t + TIER_COUNT_SQUARE * t * t


## power_tier dla ustawień wyprawy (config).
static func config_tier(config_data: Dictionary) -> int:
	return power_tier(int(config_data.get("tier", 1)))


## Koszt modyfikatorów w żarze; `idols` - bożki w slotach (Bożek Żaru obniża koszt).
static func mods_cost(mods: Array, idols: Array = []) -> int:
	var total := 0
	for id: String in mods:
		total += int(MODIFIERS[id]["cost"])
	return roundi(total * Idols.multiplier(idols, "ember_cost"))


## Łączny mnożnik danego rodzaju z wybranych modyfikatorów (1 - bez zmian).
static func multiplier(mods: Array, key: String) -> float:
	var total := 1.0
	for id: String in mods:
		total *= float(MODIFIERS[id].get(key, 1.0))
	return total


## Ustawienia wyprawy: {"climate", "tier", "mods", "seed", "idols"} - zapisywane przy przejściu do lochu.
## `idols` - bożki włożone w sloty (Idols), zużyte przy wejściu. Okno lochów dokłada "tree" - premie działającej
## zakładki drzewka Watry z chwili wejścia (WatraTree.effects).
static func config(climate: String, tier: int, mods: Array, seed_value: int, idols: Array = []) -> Dictionary:
	return {"climate": climate, "tier": tier, "mods": mods.duplicate(), "seed": seed_value, "idols": idols.duplicate()}


## Łączny mnożnik wyprawy: modyfikatory za żar razy bożki razy drzewko Watry (1 - bez zmian).
static func mult(config_data: Dictionary, key: String) -> float:
	return multiplier(config_data.get("mods", []), key) * Idols.multiplier(config_data.get("idols", []), key) \
			* WatraTree.mult(config_data.get("tree", {}), key)


## Premia dodawana z bożków i drzewka Watry (item_level, quality, vault_runes; 0 - bez zmian).
static func added(config_data: Dictionary, key: String) -> float:
	return Idols.added(config_data.get("idols", []), key) + WatraTree.added(config_data.get("tree", {}), key)


## Premie mechanik wyprawy (dla roll_mechanics): z config["mechanic_bonus"] (testy), z drzewka Watry (config["tree"])
## i z bożków - wagi się mnożą, wymuszone mechaniki i szanse na drugą i trzecią sumują, a moc ponad 1 się dodaje.
static func mechanic_bonus(config_data: Dictionary) -> Dictionary:
	var result: Dictionary = config_data.get("mechanic_bonus", {}).duplicate(true)
	for extra: Dictionary in [WatraTree.mechanic_bonus(config_data.get("tree", {})),
			Idols.mechanic_bonus(config_data.get("idols", []))]:
		var weights: Dictionary = result.get("weights", {})
		for id: String in extra["weights"]:
			weights[id] = float(weights.get(id, 1.0)) * float(extra["weights"][id])
		result["weights"] = weights
		var forced: Array = result.get("forced", [])
		for id: String in extra["forced"]:
			if not forced.has(id):
				forced.append(id)
		result["forced"] = forced
		var power: Dictionary = result.get("power", {})
		for id: String in extra["power"]:
			power[id] = float(power.get(id, 1.0)) + float(extra["power"][id]) - 1.0
		result["power"] = power
		var chances: Array = result.get("extra", [])
		var more: Array = extra.get("extra", [])
		for i in more.size():
			if chances.size() <= i:
				chances.append(0.0)
			chances[i] = float(chances[i]) + float(more[i])
		result["extra"] = chances
	return result


static func title(config_data: Dictionary) -> String:
	if Pinnacles.GODS.has(str(config_data.get("pinnacle", ""))):
		var pomrok := int(config_data.get("pomrok", 0))
		var text := Lang.t("Arena: %s (poz. %d)") % [Pinnacles.god_name(config_data["pinnacle"]),
				Pinnacles.arena_level(config_data["pinnacle"], pomrok)]
		return text + (" - " + Lang.t("Pomrok %s") % Pinnacles.roman(pomrok) if pomrok > 0 else "")
	return Lang.t("%s - stopień %d (poz. %d)") % [Lang.t(CLIMATES[config_data["climate"]]["name"]), config_data["tier"], tier_level(config_data["tier"])]
