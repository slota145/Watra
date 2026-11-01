# Słowniczek tłumaczenia (polski -> angielski)

Wspólne nazwy, żeby całe tłumaczenie mówiło jednym językiem. Autor może tu poprawiać nazwy, a potem poprosić
o ujednolicenie tłumaczeń w `translations/teksty.csv`.

## Zasady

- **Zostają po polsku:** Watra, Ostoja, imiona postaci (Bronisław, Wszebor, Dobromir, Gniewko, Hasan, imiona
  podróżników) i imiona własne bossów (Gruzłog, Bies, Kaszlak, Bulgor, Wodnik, Leszy, Mortan, Gnilec), imiona bogów
  w polskiej pisowni (Perun, Weles, Marzanna, Swaróg, Mokosz, Strzybóg). Odmienione formy w zdaniach
  (Gruzłoga, Swaroga, Peruna, Ostoi) zamieniamy na formę podstawową (Gruzłog, Swaróg's, Perun's, Ostoja).
- **Tłumaczymy:** nazwy opisowe (krainy, kapliczki, umiejętności, przedmioty, budowle) i tytuły postaci
  („Kowal Bronisław” - „Blacksmith Bronisław”).
- **Wzory:** `%s`, `%d`, `%.1f`, `%%` zostają w tej samej liczbie i **w tej samej kolejności** (GDScript wstawia
  wartości po kolei, więc szyk zdania trzeba ułożyć tak, żeby kolejność się zgadzała). Znaczniki `[color=…]`, `[b]` itp.,
  `\n`, spacje na początku i końcu napisu - bez zmian.
- **Odmiana liczebników** (`Lang.n`): trzy polskie formy dostają angielską liczbę pojedynczą („%d ostrze” - „%d blade”)
  i mnogą („%d ostrza”, „%d ostrzy” - „%d blades”).
- **Wielkie litery:** nazwy własne Title Case (Fireball, Goblin Forest, Blacksmith Bronisław); przyciski i zdania
  jak w polskim - tylko pierwsza litera („New game”, „Accept bounty”).
- **Styl:** krótko (miejsca w oknach jest mało), lekko baśniowo w rozmowach i hasłach, prosto w opisach mechanik.
  Angielski amerykański (armor, color).
- **Jednostki:** „zł” - „g” (złoto), „exp” - „XP”, „poz.” - „Lv.”, „s” zostaje, „min” zostaje.

## Krainy i kapliczki

| Polski | Angielski |
|---|---|
| Gobliński Las | Goblin Forest |
| Pola Zbożowe | Grain Fields |
| Rozlewiska | Floodlands |
| Wietrzne Turnie | Windy Crags |
| Prastary Las | Ancient Forest |
| Leśny Cmentarz | Forest Cemetery |
| Stary Młyn / Bagienny Bród / Orla Przełęcz / Stary Dąb / Cmentarna Kaplica | Old Mill / Marsh Ford / Eagle Pass / Old Oak / Cemetery Chapel |
| Topielcze Uroczysko | Drowners' Hollow |
| kapliczka | shrine |
| Lochy Watry, loch | Watra Dungeons, dungeon |
| Katakumby / Kopalnia goblinów / Zatopione podziemia / Pajęcze korzenie | Catacombs / Goblin Mine / Sunken Depths / Spider Roots |

## Watra i Ostoja

| Polski | Angielski |
|---|---|
| Watra (ogień), poziom Watry | Watra, Watra level |
| żar | embers |
| Dar Watry, Dary Watry | Watra's Gift, Watra's Gifts |
| Kryształ Watry | Watra Crystal |
| płomienie Watry (powrót) | Watra's flames |
| ofiara (złożona w Watrze) | offering |
| Gildia poszukiwaczy przygód | Adventurers' Guild |
| tablica ogłoszeń, zlecenie | notice board, bounty |
| sława gildii, ranga gildii | guild fame, guild rank |
| Znak Zwycięstwa | Victory Mark |
| magazyn, karczma, kuźnia, lecznica, koszary, chata mędrca, targowisko, kaplica, warsztat płatnerza | storehouse, tavern, forge, infirmary, barracks, sage's hut, market square, chapel, armorer's workshop |
| sołtys, mędrzec, zielarka, kowal, kupiec, karczmarz, magazynier, pisarz gildii, jubiler, żerca, myśliwy, sierżant, ojciec (kapłan) | headman, sage, herbalist, blacksmith, merchant, innkeeper, storekeeper, guild scribe, jeweler, fire priest, hunter, sergeant, Father |
| Wędrowny kupiec Hasan | Wandering Merchant Hasan |
| Święto (w Ostoi) | Festival |

## Postać, walka, umiejętności

| Polski | Angielski |
|---|---|
| zdrowie, mana, pancerz | health, mana, armor |
| siła, zręczność, inteligencja, witalność | strength, dexterity, intelligence, vitality |
| obrażenia (fizyczne, magiczne), cios krytyczny, unik | damage (physical, spell), critical strike, dodge |
| szybkość ataku, szybkość rzucania, odnowienie | attack speed, cast speed, cooldown |
| atak, czar, okrzyk | attack, spell, warcry |
| zryw | dash |
| drzewko, węzeł, węzeł kluczowy, punkt umiejętności, gniazdo | tree, node, keystone, skill point, socket |
| zapomnienie drzewka | respec |
| krwawienie, trucizna, spowolnienie, oszołomienie, unieruchomienie, strach | bleed, poison, slow, stun, root, fear |
| Miecz / Łuk / Księga magii | Sword / Bow / Spellbook |
| Młynek, Mgnienie, wirujące Mgnienie, Półksiężyc, Szarża, Rozpłatanie, Rozłupanie Ziemi, Riposta, Zew Peruna, Widmowe Ostrza, Dymne Wybuchy | Whirlwind, Blink, Spinning Blink, Crescent, Charge, Rend, Earthsplitter, Riposte, Perun's Call, Spectral Blades, Smoke Bursts |
| Krew wojownika, Skupienie bitewne | Warrior's Blood, Battle Focus |
| Salwa, Szybka salwa, Strzała tropiąca, Grot Swaroga, Deszcz Strzał, Odskok, Sidła, Sokół, Jadowe Groty, Strzała Wichru, Balista | Volley, Rapid Volley, Seeker Arrow, Swaróg's Arrow, Arrow Rain, Disengage, Snare, Falcon, Venom Tips, Gale Arrow, Ballista |
| Oddech łowcy, Cierpliwość łowcy | Hunter's Breath, Hunter's Patience |
| Kula ognia, Łańcuch błyskawic, Fala piorunów, Włócznia Marzanny, Zamieć, Burza Peruna, Kula Piorunów, Spadająca Gwiazda, Krok przez Mgłę, Tarcza Many, Kamień Runiczny | Fireball, Chain Lightning, Lightning Wave, Marzanna's Spear, Blizzard, Perun's Storm, Thunder Orb, Falling Star, Mist Step, Mana Shield, Runestone |
| Mistyczna odnowa, Strumień many | Mystic Renewal, Mana Stream |
| Nieustający Wir, Taniec Ostrzy, Dym i Cień, Krwawy Szał | Endless Whirl, Blade Dance, Smoke and Shadow, Blood Frenzy |
| Oko Sokoła, Grad, Myśliwy z Cienia, Strzelanie w biegu | Falcon's Eye, Hail, Shadow Hunter, Running Shot |
| Harmonia Żywiołów, Ofiara Krwi, Pełnia Mocy, Echo Run | Elemental Harmony, Blood Sacrifice, Full Power, Rune Echo |
| combo | combo |
| encyklopedia, bestiariusz | encyclopedia, bestiary |

## Przedmioty

| Polski | Angielski |
|---|---|
| łup, plecak, torba, trofeum | loot, backpack, bag, trophy |
| Zwykły / Magiczny / Rzadki / Legendarny | Common / Magic / Rare / Legendary |
| premia (na przedmiocie), tier | modifier, tier |
| poziom przedmiotu | item level |
| przedmiot niezidentyfikowany | unidentified item |
| zaklinanie, poziom zaklęcia, kamień zaklinający, doskonały, uświęcony, kamień miłosierdzia | enchanting, enchant level, enchanting stone, perfect, blessed, mercy stone |
| kamień szlachetny, szlif: okruch, odłamek, kamień, szlifowany, królewski | gem, cut: chip, shard, stone, cut, royal |
| rubin, szafir, szmaragd, topaz, ametyst, onyks | ruby, sapphire, emerald, topaz, amethyst, onyx |
| Kamień Promienia | Radius Stone |
| esencja, gniazdo esencji, Serce Kryształu | essence, essence socket, Crystal Heart |
| Runa Zmiany, Runa Pieczęci | Rune of Change, Rune of Sealing |
| mikstura zdrowia / many | health potion / mana potion |
| dopiski w nazwach (Loot.SUFFIXES, dopełniacz): Rysia, Sowy, Tura... | of the Lynx, of the Owl, of the Aurochs... (zawsze z „of”) |
| zioła: dziurawiec, rumianek, tatarak, arnika, kwiat paproci, bieluń | St John's wort, chamomile, sweet flag, arnica, fern flower, thornapple |

## Potwory i bossowie

| Polski | Angielski |
|---|---|
| Goblin, goblin osiłek, goblin łucznik | Goblin, Goblin Brute, Goblin Archer |
| Kobold, kobold bombiarz, kobold procarz | Kobold, Kobold Bomber, Kobold Slinger |
| Żabołak, żabołak plujący | Frogman, Spitting Frogman |
| Ptakoczłek (oszczepnik, szaman), ptakoludzie | Birdman (Javelineer, Shaman), birdfolk |
| Utopiec, Topielica, Ognik, Rusałka | Drowner, Drowned Maiden, Wisp, Rusalka |
| Satyr (fletnista, osiłek) | Satyr (Piper, Brute) |
| Drzewiec, Prastare drzewo, Pająk (sieciarz), Pajączek, Kokon | Treant, Ancient Tree, Spider (Webspinner), Spiderling, Cocoon |
| Szkielet (rycerz, łucznik), Trupojad, Zombie | Skeleton (Knight, Archer), Ghoul, Zombie |
| Wilk, Warg, Czerw polny, Dzik, Sarna, Jeleń, Zając, Kozica | Wolf, Warg, Field Worm, Boar, Roe Deer, Stag, Hare, Chamois |
| Gruzłog, Wódz Goblinów | Gruzłog, Goblin Chieftain |
| Szarokieł, Wilk Alfa | Greyfang, Alpha Wolf |
| Bies, Władca Bestii | Bies, Lord of Beasts |
| Pożeracz Pól | Field Devourer |
| Bombardier Kaszlak | Bombardier Kaszlak |
| Bulgor, Wódz Żaboludzi | Bulgor, Frogfolk Chieftain |
| Wodnik, Pan Topieli | Wodnik, Lord of the Deep |
| Hydra z Bagien | Bog Hydra |
| Gromoskrzydły, Pan Burz | Thunderwing, Lord of Storms |
| Gryf, Władca Wzgórza | Griffin, Lord of the Hill |
| Faun-Król, Władca Satyrów | Faun King, Lord of the Satyrs |
| Leszy, Pan Puszczy | Leszy, Lord of the Wildwood |
| Królowa Pająków | Spider Queen |
| Mortan, Pan Kości | Mortan, Lord of Bones |
| Gnilec, Kolosalny Ghul | Gnilec, Colossal Ghoul |
| Wilkołak, Czarny Niedźwiedź-Bestia | Werewolf, Black Bear Beast |
| Żmij Gorynycz | Zmey Gorynych |
| Wij, Władca Powiek | Viy, Lord of Eyelids |
| czempion, world boss, strażnik lochu, skarbiec | champion, world boss, dungeon guardian, vault |

## Świat jak w MMO

| Polski | Angielski |
|---|---|
| podróżnik, łowca | traveler, hunter |
| drużyna, prośba o pomoc | party, call for help |
| pojedynek, pojedynkowicz, zbój | duel, duelist, brigand |
| przyjazny | friendly |
| tryb świata: Spokojny / Realistyczny / Hardcorowy | world mode: Peaceful / Realistic / Hardcore |
| wydarzenie, Najazd na kapliczkę, Wędrowny czempion, Deszcz meteorytów, Polowanie na bossa, Karawana kupiecka | event, Shrine Raid, Wandering Champion, Meteor Shower, Boss Hunt, Merchant Caravan |
| rynek, oferta, zamówienie, podatek, okazja | market, listing, order, tax, bargain |
| osłona (zbieracza) | escort |
| zadanie główne, zadanie poboczne, dziennik | main quest, side quest, journal |
