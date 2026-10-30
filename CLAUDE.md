# Watra

Dwuwymiarowy ARPG w pixel-arcie (Godot 4.7, GDScript), osadzony w słowiańskim klimacie. Horda potworów
zalała świat, ostatni ludzie bronią się w osadzie **Ostoja**. Hasło gry: „Dopóki płonie ogień, Ostoja trwa”.
Gracz rozwija postać, zdobywa łup i przemierza krainy w rosnącym zakresie poziomów.

Osoba tworząca grę pracuje na Windowsie (`C:\Users\slota\Documents\claude-game`) i rozmawia po polsku.
Nie programuje na co dzień, więc wyjaśniaj prosto, bez żargonu, i podawaj gotowe komendy do skopiowania.
W odpowiedziach używaj form neutralnych płciowo (np. „możesz”, „wpisz”, zamiast „zrobiłeś/zrobiłaś”).
Poniżej „autor” oznacza tę osobę.

## Inspiracje i klimat

Gra mocno czerpie z dwóch tytułów. Warto podpatrywać, co w nich dobrze działa:
- **Path of Exile**: łup z losowymi cechami i rzadkościami, kamienie w gniazdach przedmiotów,
  rozbudowane drzewka pasywne, waluta-surowce do ulepszania, proceduralne mapy i lochy jako końcówka gry
  (ulepszane ofiarami jak „atlas”), sezonowe i losowe wydarzenia.
- **Black Desert Online**: zaklinanie z ryzykiem porażki (już jest w grze, kamienie miłosierdzia chronią poziom),
  sieć obozów i robotników pasywnie zbierających surowce, rynek z setkami ofert kupna i sprzedaży,
  żywy, otwarty świat.

Docelowy klimat to **offline MMO**: świat ma sprawiać wrażenie zamieszkanego przez innych graczy,
choć wszystko jest symulowane (patrz „Gildia i świat jak w MMO” niżej).

## Krainy (`scripts/zones.gd`, poziomy w `scripts/levels.gd`)

| Kraina | Klucz | Poziomy | Kapliczka |
|---|---|---|---|
| Gobliński Las (z Ostoją) | `forest` | 1-7 | Ostoja |
| Pola Zbożowe | `fields` | 7-14 | Stary Młyn |
| Rozlewiska | `swamp` | 9-16 | Bagienny Bród |
| Wietrzne Turnie | `mountains` | 16-24 | Orla Przełęcz |
| Prastary Las | `ancient` | 23-32 | Stary Dąb |
| Leśny Cmentarz | `cemetery` | 32-40 | Cmentarna Kaplica |

Wszystkie krainy mają 200x150 kafelków i układają się w mozaikę na mapie świata. Generują się z ziarna zapisu.
Osobno są **lochy w płomieniach Watry** (kraina `dungeon`, 156x116 kafelków, poza mapą świata): generowane od nowa
przy każdym wejściu, nie zapisują się (wczytana gra wraca przed Watrę).

## Struktura

- `scripts/`: cała logika. Najważniejsze pliki:
  - `game.gd` (autoload `Game`): zapisy (`user://saves/`) i przełączanie scen,
  - `sfx.gd` (autoload `Sfx`): dźwięki,
  - `world.gd` i skrypty krain (`grain_fields.gd`, `drowned_grove.gd`, `mountain_zone.gd`, `ancient_forest.gd`, `forest_cemetery.gd`, `hydra_bog.gd`),
  - `settlement.gd`: Ostoja,
  - `player.gd`, `character_stats.gd`, `items.gd`, `item_bases.gd`, `loot.gd`, `legends.gd`, `legendary_effects.gd`, `skills.gd`, `skill_effects.gd`, `levels.gd`, `quests.gd`, `bounties.gd`,
  - `hotbar.gd`: paski szybkiego wyboru (dane), `status_effects.gd`: lista efektów działających na gracza,
  - `dungeons.gd`: dane lochów (klimaty, stopnie, modyfikatory), `dungeon.gd`: generator lochu, okno `scripts/ui/dungeon_window.gd`,
  - `scripts/ui/`: okna interfejsu (`ui_style.gd` to wspólny styl).
- Sterowanie: WASD, spacja (zryw), F (interakcja), paski szybkiego wyboru na dole ekranu: umiejętności pod LPM, PPM, Q, E, R, Z, X
  (osobny układ dla każdej broni) i przedmioty pod 1-0 (`scripts/ui/action_bars.gd`, `scripts/ui/hotbar_slot.gd`).
  Pod paskami zdrowia i many ikony efektów (`scripts/ui/status_row.gd`). Tryb deweloperski: Ctrl+Shift+C, potem F1 złoto,
  F2 awans, F3 kamienie, F4 drewno i kamień.
- `scenes/`: sceny (`main_menu.tscn` startowa, `world.tscn` rozgrywka, potwory, `hud.tscn`).
- `assets/`: grafiki, muzyka, dźwięki.
- `pixellab_src/`: surowe grafiki z PixelLab.
- `tools/*.py`: generatory grafik i dźwięków (Pillow, numpy/scipy, ffmpeg). Uruchamia się je `python tools/<plik>.py`, a każdy plik ma opis w docstringu.
- `shaders/`: shadery.
- `tests/`: testy i symulacje.
- `docs/`: obrazy referencyjne od autora (`docs/referencje/`). Godot je pomija (plik `.gdignore`).

## Uruchamianie i testy w chmurze (Linux, bez monitora)

Godot 4.7.2 jest dostępny jako `godot`. W świeżym klonie zaimportuj najpierw zasoby. Bez tego klasy globalne
(`UiStyle`, `SaveBrowser`…) nie są widoczne i pojawiają się fałszywe błędy parsowania:
```bash
godot --headless --path . --import
```

Testy bez okna wypisują linie `OK …` / `FAIL …`:
```bash
godot --headless --path . -s res://tests/test_loot.gd
```

Testy z oknem (`test_ui`, `test_village`, `test_pan`) i zrzuty ekranu uruchamia się na wirtualnym ekranie (Xvfb + programowy OpenGL):
```bash
tools/screenshot.sh /tmp/menu.png
tools/screenshot.sh /tmp/wioska.png res://scenes/world.tscn 4 1920x1080
SCRIPT=tests/test_ui.gd tools/screenshot.sh /tmp/ui.png
```
Widok z góry na fragment krainy (kamera odpięta od gracza, bez interfejsu), np. całą wioskę:
```bash
SCRIPT=tools/overview.gd tools/screenshot.sh /tmp/wioska.png mountains 148 57 0.32
```
Argumenty: plik, kraina, kafelek x i y środka kadru, przybliżenie (0.32 to około 160x90 kafelków), opcjonalnie ziarno.
Obejrzyj zrzut narzędziem Read, żeby sprawdzić zmiany wizualne. `tools/screenshot.sh` za każdym razem importuje zasoby,
bo bez tego po podmianie grafiki gra rysowałaby starą wersję (np. pocięte klatki przy zmienionym rozmiarze arkusza). Uwagi:
- Renderer w chmurze to tryb zgodności, a nie Forward+, więc niektóre shadery mogą wyglądać nieco inaczej niż u autora.
- Komunikaty o wyciekach tekstur i `ERR_CANT_OPEN` przy zamykaniu są niegroźne.

U autora na Windowsie wszystkie testy uruchamia `tests/run_tests.ps1`. Nowy test dopisz też do listy `$tests` w tym pliku.
Testy zapisują do `user://test_savegame.json`, nigdy do zapisów gracza.

## PixelLab w chmurze

Serwer PixelLab (narzędzia `mcp__PixelLab__*`) działa, ale sieć kontenera blokuje pobieranie plików z `backblaze.pixellab.ai`
i `api.pixellab.ai`. Obejście: złóż klatki w arkusz poleceniem `pixelart_workbench` `join <adresy klatek> --as sheet --columns 4`.
Wynik zapisuje się lokalnie w katalogu `tool-results` sesji jako PNG w skali 1:1, z paskiem podpisu u góry i ciemnym tłem bez przezroczystości.
Utnij pasek, a tło usuń wypełnianiem od krawędzi każdej klatki (tak powstały klatki w `pixellab_src/regions/storm_eagle_obj/animations/powerful_full_wingbeat…`).
Surowe klatki zapisuj w `pixellab_src/…` i buduj arkusze narzędziami z `tools/`.
Po uruchomieniu takiego narzędzia przywróć pliki, które zmieniły się tylko kodowaniem PNG (te same piksele).

## Konwencje

- Komentarze, nazwy w interfejsie i opisy commitów piszemy po polsku.
- Opisy skryptów i funkcji dajemy w komentarzach `##`, na początku pliku zwięźle wyjaśniamy, co skrypt robi.
- Wcięcia tabulatorami, typowanie statyczne (`var x := …`, `-> void`).
- Pliki `.uid` commitujemy razem ze skryptami.
- Część plików ma BOM UTF-8, więc przy edycji skryptem zachowuj kodowanie.
- Balans potworów idzie przez `Levels` (krzywe i mnożniki), a nie przez ręczne statystyki w scenach. Po zmianach balansu uruchom `tests/balance_sim.gd`.

## Git

- Zmiany idą na gałąź roboczą, potem pull request do `main`. Autor zwykle prosi o założenie PR i od razu scalenie.
- Gdy autor ma u siebie lokalne commity, `git pull` otwiera vima. Podpowiadaj wtedy `git pull --no-edit origin main`.

## Do poprawy

Konkretne poprawki istniejących krain i postaci, zgłoszone przez autora po graniu.

### Zasada ogólna: dużo potworów

- [ ] Domyślnie każde siedlisko potworów ma mieć **dziesiątki, a nawet setki potworów**, jak w miejscach farmienia w Black Desert albo w Path of Exile.
  Wyjątek: siedliska, których projekt wymaga inaczej (np. arena bossa).
  Przy zwiększaniu liczebności sprawdź wydajność (`tests/bench_combat.gd`, `tests/playtest_bot.gd`).
  Potwory w spoczynku, które się nie ruszają, pomijają `move_and_slide` (`scripts/goblin.gd`), żeby setki stojących potworów mało kosztowały.

### Gobliński Las i Prastary Las (`scripts/world.gd`, `scripts/ancient_forest.gd`)

- [x] Gobliński Las: więcej grupek goblinów w lesie i większe siedlisko wilków - około 450 potworów (było około 340);
  to kraina startowa, więc zwiększenie jest umiarkowane.
- [x] Prastary Las: dwa pierścienie prastarych drzew wokół Leszego z drzewcami, wielkie leże pająków, wataha wargów
  przy każdej bestii, gniazda pająków i stada drzewców w gęstwinie - około 400 potworów (było 66).

### Wietrzne Turnie (`scripts/mountain_zone.gd`)

- [x] Elektryczny orzeł (Gromoskrzydły, `scripts/storm_eagle.gd`) macha skrzydłami: 8 klatek pełnego uderzenia z PixelLab, także w spoczynku nad gniazdem.
- [x] Wioska ptakoludzi: wydeptane ścieżki (pętla wokół gniazda, do chat, z ramp), dolna osada u stóp skarpy z ulicą
  między rampami, 9 chat na płaskowyżu i 4 na dole, około 210 ptakoludzi (wcześniej 74).
- [x] Wioska satyrów: większa polana (promień 22 zamiast 17 kafelków, 12 namiotów), wydeptana ścieżka wokół ogniska,
  3-4 przysiółki dookoła połączone ścieżkami (ognisko, namioty, tłocznia/maj/posąg/bębny, gromady satyrów, osiłek),
  około 120 satyrów (wcześniej 52).

### Rozlewiska (`scripts/drowned_grove.gd`, `scripts/hydra_bog.gd`)

- [x] Topielcze Uroczysko zajmuje cały obszar pod drogą i na zachód od rzeki: 16 sadzawek (było 7), mgła na całym obszarze,
  około 220 potworów (było 66): utopce, ogniki, topielice.
- [x] Bagno Hydry przeniesione na północny skraj krainy (najdalej od drogi, na zachód od rzeki, z dala od żabołaków), z 3-5 mniejszymi sadzawkami
  wokół głównej; w bagnie martwe drzewa zamiast zwykłych.

### Pola Zbożowe (`scripts/grain_fields.gd`)

- [x] Wielki obóz koboldów (elipsa 48x30 kafelków) z barykadą Bombardiera w północnej części: 12 namiotów, 6 ognisk,
  stojące zgraje, straż bramy; zgraje także w łanach dookoła - około 190 koboldów (było około 65).
- [x] Pola pszenicy: działki o organicznych granicach (komórki Woronoja wygięte szumem) na brązowej glebie, wąskie miedze
  z żywopłotami (krzaki gęsto obok siebie jak pale palisady, ciągłe linie na granicach działek, przejścia co około
  11 kafelków), płotami z żerdzi, kamieniami i kwiatami; przeważają łany (około 2/3 działek), reszta to ścierniska z rzędami snopków
  i zaorane zagony; mało trawy (łąki tylko płatami, polany wokół gospodarstw); kępy drzew w jesiennych barwach
  (`shaders/autumn.gdshader`); zboże nie spowalnia.
  Wzór: `docs/referencje/pola_zbozowe.jpg`.

### Leśny Cmentarz (`scripts/forest_cemetery.gd`)

- [x] Kwatery na całym cmentarzu (komórki Woronoja w normie L4 - zaokrąglone prostokąty), między nimi żwirowe alejki,
  kwatery przycięte przez drogę i część pozostałych to zagajniki; większość kwater otacza kuty płot z kamiennymi
  słupkami (autotile `assets/cemetery/iron_fence.png` z `tools/cemetery_art.py`), co czwartą - żywopłot z cisów;
  po dwie furtki na kwaterę; gęste rzędy grobów, znicze (`assets/cemetery/candle.png`) przy co trzecim grobie,
  pomniki w większych kwaterach; lżejszy mrok, gęsty tylko przy nekromancie i w trupowisku.
- [x] Życie cmentarza (`scripts/cemetery_life.gd`, grafiki z PixelLab przez `tools/cemetery_creatures.py`): stada kruków
  krążą nad mauzoleum, trupowiskiem, kurhanami i przelatują między nimi, grupki kruków dziobią przy grobach i zrywają
  się z krakaniem przed graczem; zjawy wyłaniają się nad grobami w pobliżu gracza, przepływają kawałek i rozwiewają się.
  Do tego aleja krypt przy drodze do mauzoleum, chata grabarza przy kaplicy i rdzawe modrzewie.
- [x] Wielkie gromady szkieletów w kwaterach (im bliżej nekromanty, tym większe) - około 700 szkieletów (było około 180).
  Rozpychanie potworów liczone w siatce sąsiadów, a odległe potwory w spoczynku sprawdzają gracza co kilka klatek
  (`scripts/goblin.gd`).

## Pomysły i rzeczy do zrobienia

Aktualizuj tę listę, gdy coś zostanie zrobione albo autor rzuci nowy pomysł.
Przed rozpoczęciem większego punktu dopytaj autora o szczegóły, bo to luźne pomysły, a nie gotowe projekty.

### Postać i przedmioty

- [ ] Drzewko umiejętności przypisane do broni, z unikalnymi perkami dla każdego drzewka.
  Dziś każdy rodzaj broni (`melee` / `bow` / `spell`) ma w `scripts/skills.gd` aktywną umiejętność, uderzenie, combo i dwie pasywne regeneracje.
  Pomysł to rozbudowa tego w prawdziwe drzewko.
- [ ] System kamieni wkładanych w przedmioty (gniazda).
  Istniejące kamienie (zwykłe, doskonałe, uświęcone, miłosierdzia) służą tylko do zaklinania (`scripts/enchanting.gd`, `scripts/ui/enchant_window.gd`), więc to byłby nowy system.
- [ ] Nowe bronie: kosa, kostur (nekromanta), młoty, chainblade'y, sztylety, włócznie, rapier, hydrosfera.
  Każda broń to nowy rodzaj z własnym drzewkiem, a nie tylko nowy przedmiot, więc wymaga szczegółów od autora.

### Interfejs i walka

- [x] Paski szybkiego wyboru: 10 slotów przedmiotów (1-0, nowa postać dostaje po 5 mikstur życia i many pod 1 i 2)
  i 7 slotów umiejętności (LPM, PPM, Q, E, R, Z, X) z osobnym układem dla każdej broni. Na slot umiejętności trafia też
  zwykły atak, więc gracz nie jest przywiązany do LPM. Przeciąganie z plecaka i z okna umiejętności, PPM albo przeciągnięcie
  poza pasek opróżnia slot. Odnowienie widać na slocie (wskazówka zegara i sekundy), brak many - niebieskawy slot.
  Shift+LPM zniknął (uderzenie leży domyślnie pod Q), interakcja przeszła z E na F.
- [x] Ikony efektów pod paskami zdrowia i many: premie z osady, Dary i poziom Watry, efekty legendarnych przedmiotów,
  trucizna, spowolnienie, oszołomienie; ramka złota/czerwona/szara, czas pod ikoną, opis w dymku.
- [ ] **System combo** (razem z drzewkiem umiejętności): umiejętność użyta zaraz po innej zachowuje się inaczej.
  Combo zależy od umiejętności, a nie od klawisza, więc gracz dowolnie układa pasek, a opis umiejętności mówi, z czym tworzy combo.
  Podpowiedź na pasku: po umiejętności otwierającej combo przez chwilę świecą sloty umiejętności, które zadziałają inaczej,
  z kurczącym się pierścieniem czasu (dziś świeci tylko slot ataku w oknie dodatkowego ciosu, `ActionBars._process`).
- [ ] Nowe umiejętności z drzewka wypełnią wolne sloty Q, E, R, Z, X (dziś każda broń ma do przypisania tylko atak,
  umiejętność aktywną i uderzenie).

### Watra i Ostoja

- [x] **Watra**: wielki, zawsze płonący ogień na placu Ostoi (`scripts/settlement.gd`, okno `scripts/ui/watra_window.gd`,
  grafika z PixelLab przez `tools/watra_art.py`). Dwóch mieszkańców donosi drewno, a ogień wtedy buchnie.
  Gracz składa ofiary ze złota i przedmiotów, które dają żar (`Boons.ember`), a od żaru zależy poziom Watry (1-7).
  Każdy poziom daje stałe premie postaci (złoto, doświadczenie, regeneracja) i rozwój Ostoi (większy podatek, szybsze budowy).
  Za złoto można też przyjąć jeden z trzech czasowych Darów Watry. Autorowi podoba się, że Watra jest dużym ujściem
  dla złota - kolejne systemy mogą to rozwijać.
- [x] **Lochy w płomieniach Watry** (`scripts/dungeon.gd`, dane w `scripts/dungeons.gd`, okno `scripts/ui/dungeon_window.gd`,
  przycisk „Lochy” w oknie Watry):
  - 4 klimaty z tilesetami z PixelLab (tryb pro, 64 px, ściany pełnej wysokości; `pixellab_src/dungeons/`, `tools/dungeon_tiles.py`):
    Katakumby (szkielety, nekromanta), Kopalnia goblinów (gobliny i koboldy, wódz), Zatopione podziemia (topielce,
    żabołaki, wodnik), Pajęcze korzenie (pająki, drzewce, królowa pająków);
  - układ: komnaty i korytarze na siatce wierzchołków co 64 px, kafelki Wang dobierane do narożników (układ arkusza jak
    w `pixellab_src/alpine/cliff.json`); mrok w kolorze klimatu, pochodnie, światło wokół gracza;
  - cel: gromady potworów (150-250), w najdalszej komnacie strażnik; po jego pokonaniu skarbiec wysypuje łup i pojawiają się
    płomienie powrotu do Ostoi (te same są w komnacie wejściowej);
  - stopień 1-7 (potwory poz. 5-41) najwyżej równy poziomowi Watry; modyfikatory za żar (Hordy, Bogactwo, Wściekłość,
    Pełny skarbiec) odblokowywane kolejnymi poziomami Watry; wydany żar nie obniża poziomu Watry (`Boons.ember_spent`).
- [ ] **Losowe mechaniki w lochach z własnymi drzewkami rozwoju** (jak atlas w Path of Exile): w lochu losowo pojawia się
  dodatkowa mechanika (np. wydarzenie, specjalny przeciwnik, ukryta komnata), a każda ma własne drzewko ulepszeń
  rozwijane postępami w lochach. Szczegóły do ustalenia z autorem.
- [ ] **Sloty w Watrze na przedmioty modyfikujące lochy** (jak skaraby w PoE): przedmioty z łupu wkładane w Watrę przed
  wejściem, które dodatkowo zmieniają loch (więcej danej mechaniki, inne potwory, więcej łupu danego rodzaju).
- [ ] Pomysły na rozwój lochów: kolejne klimaty (lodowe jaskinie, wulkaniczna kuźnia, krasnoludzkie ruiny), kilka pięter
  w dół z coraz lepszym łupem, elitarne potwory z własnymi cechami, pułapki i zagadki, własni strażnicy lochów
  zamiast bossów z krain, sekretne komnaty, zlecenia gildii na lochy.

### Zielarstwo

- [ ] **Rośliny w świecie gry** zbierane jak drewno i kamień (różne gatunki w różnych krainach), z których **zielarka**
  w Ostoi robi **mikstury wzmacniające**: działają krócej niż posiłki, ale dają większą premię (osobna grupa premii w `scripts/boons.gd`).

### Gildia i świat jak w MMO

Oba systemy zależą od gildii poszukiwaczy przygód w Ostoi (budowla `guild` w `scripts/settlement.gd`, tablica ogłoszeń w `scripts/bounties.gd` i `scripts/ui/board_window.gd`).
Dziś tablica ma tylko zlecenia na wilki i gobliny w Goblińskim Lesie (komentarze w `settlement.gd` mówiące, że tablica „funkcje dostanie później”, są już nieaktualne).

- [ ] **Inni podróżnicy**: symulowani poszukiwacze przygód z imionami, poziomami i ekwipunkiem.
  Pojawiają się w krainach, walczą z potworami i zbierają łup, wracają do Ostoi.
  Ich liczba i siła zależą od rozwoju gildii.
- [ ] **Symulowany rynek**: setki ofert kupna i sprzedaży wystawianych przez podróżników, z cenami zmieniającymi się w czasie, w stylu rynku z BDO.
  Gracz może kupować, sprzedawać i składać zamówienia.
  Rynek działa przez gildię.
- [ ] Więcej rodzajów zleceń na tablicy (inne krainy, bossowie, zbieranie surowców), powiązanych z podróżnikami.

### Świat

- [ ] Budowa i rozbudowa obozów w innych krainach, które pasywnie dają surowce albo inne korzyści.
- [ ] Losowe wydarzenia w świecie gry.
- [ ] Uzupełnienie siatki mapy świata (dziś krainy stoją w kształcie krzyża) o 6 krain:
  - 2 nad Polami Zbożowymi (`map_offset` (-200,-150) i (-200,-300)),
  - 2 nad Rozlewiskami ((200,-150) i (200,-300)),
  - 2 nad Wietrznymi Turniami ((400,-150) i (400,-300)).
  Po tym mapa jest pełnym prostokątem 4x3.
- [ ] Duża mapa świata ma wyglądać jak prawdziwa, ładna mapa, a nie jak siatka kafelków (`scripts/ui/world_map_view.gd`, `scripts/ui/big_map.gd`).

### Nowe krainy

- [ ] **Wysokie góry**:
  - harpie, bardzo liczne, z Królową Harpii jako bossem,
  - kryształowe pająki z Kamienną Królową jako bossem,
  - górskie wiwerny,
  - kamienne golemy,
  - górskie gryfy.
- [ ] **Lodowe góry**: żywiołaki lodu, lodowe bestie.
- [ ] **Drugie Rozlewiska**: pijawki, owady bagienne, utopieni mieszkańcy wioski, mięsożerne rośliny.
- [ ] Ruiny miasta.
- [ ] Las grzybów.
- [ ] Spaczone równiny.
- [ ] Piaszczysta pustynia.
- [ ] Skalista pustynia.
- [ ] Wulkaniczne pola.
- [ ] Stare krasnoludzkie podziemne miasto.

