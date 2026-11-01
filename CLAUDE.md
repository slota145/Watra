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
  - `world.gd` i skrypty krain (`grain_fields.gd`, `goblin_posts.gd`, `drowned_grove.gd`, `frog_ponds.gd`, `mountain_zone.gd`, `ancient_forest.gd`, `forest_cemetery.gd`, `hydra_bog.gd`),
  - `settlement.gd`: Ostoja,
  - `player.gd`, `character_stats.gd`, `items.gd`, `item_bases.gd`, `loot.gd`, `legends.gd`, `legendary_effects.gd`, `skills.gd`, `skill_effects.gd`, `levels.gd`, `quests.gd`, `bounties.gd`,
  - `hotbar.gd`: paski szybkiego wyboru (dane), `status_effects.gd`: lista efektów działających na gracza,
  - `skill_tree.gd`: drzewka umiejętności broni (dane), `sword_skills.gd`, `bow_skills.gd` i `spell_skills.gd`: umiejętności drzewek miecza, łuku i księgi,
  - `dungeons.gd`: dane lochów (klimaty, stopnie, modyfikatory), `dungeon.gd`: generator lochu, okno `scripts/ui/dungeon_window.gd`,
  - `herbs.gd`: zioła i mikstury zielarki, `herb.gd`: zioło do zerwania (sadzone w każdej krainie przez `World._place_herbs`),
  - `scripts/ui/`: okna interfejsu (`ui_style.gd` to wspólny styl).
- Sterowanie: WASD, spacja (zryw), F (interakcja), paski szybkiego wyboru na dole ekranu: umiejętności pod LPM, PPM, Q, E, R, Z, X
  (osobny układ dla każdej broni) i przedmioty pod 1-0 (`scripts/ui/action_bars.gd`, `scripts/ui/hotbar_slot.gd`).
  Pod paskami zdrowia i many ikony efektów (`scripts/ui/status_row.gd`). Tryb deweloperski: Ctrl+Shift+C, potem F1 złoto,
  F2 awans, F3 kamienie, F4 drewno i kamień, F5 wydarzenie w świecie w tej krainie.
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
Animowane efekty (cięcia, błyski, smugi) robi kreator efektów `mcp__PixelLab__vfx_workbench` (darmowy; zapisuje
efekt w „My effects” autora na pixellab.ai). Jego pliki też się nie pobierają: `pixelart_workbench` `join <image id z eksportu>
--as sheet --columns <liczba klatek>` daje jeden rząd klatek na tle (31, 37, 44). Utnij pasek podpisu, zapisz do
`pixellab_src/vfx/<nazwa>.png`, dopisz efekt do `pixellab_src/vfx/ids.json` i uruchom `python tools/vfx_art.py`
(wynik w `assets/effects/`, w grze `SkillEffects.sheet_once`). W kreatorze kolor części najpewniej zmienia łatka
`ramps.<nazwa>` (sam `colour` w `set_part` bywa pomijany).

## Konwencje

- Komentarze, nazwy w interfejsie i opisy commitów piszemy po polsku.
- Napisy dla gracza od razu gotowe do tłumaczenia (zasady w komentarzu `scripts/lang.gd`): `Lang.t("…")` albo `tr("…")`,
  zdanie z liczbą jako jeden wzór (`Lang.t("Poziom %d") % lvl`), odmiana - `Lang.n`, stałe po polsku tłumaczone
  przy pokazywaniu, zapis gry trzyma identyfikatory, a nie gotowe nazwy. Po dodaniu napisów: `python tools/texts.py`.
- Opisy skryptów i funkcji dajemy w komentarzach `##`, na początku pliku zwięźle wyjaśniamy, co skrypt robi.
- Wcięcia tabulatorami, typowanie statyczne (`var x := …`, `-> void`).
- Pliki `.uid` commitujemy razem ze skryptami.
- Część plików ma BOM UTF-8, więc przy edycji skryptem zachowuj kodowanie.
- Balans potworów idzie przez `Levels` (krzywe i mnożniki), a nie przez ręczne statystyki w scenach. Po zmianach balansu uruchom `tests/balance_sim.gd`.

## Git

- Zmiany idą na gałąź roboczą, potem pull request do `main`. Autor zwykle prosi o założenie PR i od razu scalenie.
- Gdy autor ma u siebie lokalne commity, `git pull` otwiera vima. Podpowiadaj wtedy `git pull --no-edit origin main`.

## Systemy w grze

Skrót; szczegóły każdego zrobionego punktu (pliki, funkcje, liczby) są w `docs/historia.md` - szukaj w nim grepem.

- **Walka i postać:** drzewka broni - miecz, łuk, księga magii (`skill_tree.gd`, `sword_skills.gd`, `bow_skills.gd`,
  `spell_skills.gd`, okno K), combo (`Skills.COMBOS`), paski szybkiego wyboru (`hotbar.gd`), ikony efektów (`status_effects.gd`).
- **Efekty:** animacje z kreatora efektów PixelLab (`pixellab_src/vfx/ids.json`, `tools/vfx_art.py`; pomocnicy `SkillEffects`,
  `FxLoop`, `BossFx`, `LegendVfx`, `WorldVfx`, `MonsterFx`, `MiscVfx`).
- **Bossowie:** `boss.gd` (wejście do walki, fazy, śmierć, aura wściekłości), zapowiedzi ataków `telegraph.gd`,
  world bossy `world_boss.gd` (Żmij, Wij).
- **Przedmioty:** łup z losowymi premiami (`loot.gd`, nazwy składane przy pokazywaniu - `Loot.compose_name`), legendy
  (`legends.gd`, `legendary_effects.gd`), zaklinanie u kowala (`enchanting.gd`), kamienie szlachetne i gniazda (`gems.gd`,
  jubiler Dobromir), esencje legend (`essences.gd`), rzemiosło premii (`item_craft.gd`), torby (`bags.gd`), pas,
  przedmioty niezidentyfikowane (`unidentified.gd`), encyklopedia (`codex.gd`, klawisz L).
- **Watra i Ostoja:** Watra z ofiarami, żarem i Darami (`boons.gd`, `ui/watra_window.gd`), budowy osady (`settlement.gd`),
  lochy Watry (`dungeon.gd`, `dungeons.gd`) z Kryształem Watry (`watra_crystal.gd`) i Ołtarzem Welesa, zielarstwo (`herbs.gd`).
- **Świat jak w MMO** (po zbudowaniu gildii): podróżnicy (`travelers.gd`, `traveler.gd`), drużyny i prośby o pomoc,
  tryby świata i rywale (`world_modes.gd`, `rival.gd`), rynek (`market.gd`), zlecenia (`bounties.gd`), zadania główne
  (`main_quests.gd`), wydarzenia w świecie (`world_events.gd`, `event_site.gd`).
- **Tłumaczenia:** `lang.gd`, `translations/teksty.csv` (pl/en), słowniczek `translations/slowniczek.md`.

## Oszczędzanie tokenów

- Nowy duży temat zaczynaj w nowej sesji - wszystko ważne jest w tym pliku i w `docs/historia.md`.
- `docs/historia.md` przeszukuj grepem, nie czytaj w całości.
- Duże pliki (`settlement.gd`, `world.gd`, `items.gd`, `player.gd` mają tysiące linii) czytaj fragmentami: grep, potem
  Read z offset/limit.
- Równoległe części (agenci, forki) tylko przy dużych zadaniach, które dają się podzielić, najwyżej 4. Każda dostaje kopię
  rozmowy i sama testuje, więc mniejsze zadania rób po kolei. Części dawaj krótki opis zadania i listę plików.
- Zrzuty ekranu i nagrania tylko przy zmianach wizualnych albo gdy autor chce coś zobaczyć; przycinaj do potrzebnego
  fragmentu i zestawiaj kilka klatek w jeden obraz.
- Testy: te z zakresu zmiany, cały zestaw przed PR przy dużych zmianach; wypisuj tylko linie FAIL / WYNIK.
- Odpowiedzi krótkie: bez powtarzania długich list, kodu i raportów części.

## Do poprawy

Konkretne poprawki istniejących krain i postaci, zgłoszone przez autora po graniu.

### Testy

- [ ] `tests/test_world_events.gd` - „meteoryt rani gracza” zawiódł raz na kilka uruchomień (Rozlewiska, losowo);
  do sprawdzenia, co losowego chroni gracza przed meteorytem (unik, nietykalność).

### Zasada ogólna: dużo potworów

- [ ] Domyślnie każde siedlisko potworów ma mieć **dziesiątki, a nawet setki potworów**, jak w miejscach farmienia w Black Desert albo w Path of Exile.
  Wyjątek: siedliska, których projekt wymaga inaczej (np. arena bossa).
  Przy zwiększaniu liczebności sprawdź wydajność (`tests/bench_combat.gd`, `tests/playtest_bot.gd`).
  Potwory w spoczynku, które się nie ruszają, pomijają `move_and_slide` (`scripts/goblin.gd`), żeby setki stojących potworów mało kosztowały.
  Plan uzgodniony z autorem: kraina po krainie (osobny PR), cel 600-800 wrogów na krainę, nowe siedliska z obecnych
  potworów na pustych terenach (z własnym wystrojem i sensem) i gęściej w istniejących. Liczy je `tests/bench_combat.gd`
  („spawns”); koszt rośnie z liczbą wrogów atakujących naraz (największa gromada), nie z liczbą w krainie.
  Zrobione: Pola Zbożowe (626), Rozlewiska (617), Wietrzne Turnie (~650, wioska ptakoludzi przeniesiona w róg),
  Gobliński Las (~590), Prastary Las (579); Leśny Cmentarz miał już 682 - wszystkie krainy zrobione, punkt do
  zamknięcia po ograniu przez autora. Nowe siedliska losuj osobnym ziarnem (jak `FrogPonds`)
  i buduj na końcu, żeby w starych zapisach reszta krainy się nie zmieniła. Przy przebudowie całej krainy podbij
  jej wersję układu (`World.ZONE_LAYOUTS`) - postać ze starego zapisu wróci do kapliczki.
  Do sprawdzenia: walka w środku wioski ptakoludzi kosztuje ok. 15 ms na klatkę (inne gromady 7-9 ms).

### Wietrzne Turnie

- [ ] Poprawić wizualnie wioskę satyrów i jej okolice (`MountainZone._plan_satyr_glade`, `_plan_satyr_hamlets`,
  `_build_satyr_village`, `_build_satyr_hamlet`, `_build_royal_grove`). Ustalenia z autorem:
  - klimat **winnego święta**: wiecznie trwająca uczta, wesoło, ale groźnie;
  - przeszkadza: małe, rozsypane domki (namioty i szałasy wielkości postaci, zlewają się z tłumem satyrów),
    sztuczne ścieżki (pierścienie jak z cyrkla, przysiółki jak kopie), nijaka okolica (zwykła hala);
  - układ: **jedna wyraźna, większa polana** z placem biesiadnym w środku i domami wokół; zamiast przysiółków
    **winnice (winorośl w rzędach), sady i zagrody** wokół, połączone krętymi ścieżkami;
  - domy: **większe chaty z winoroślą** (ok. 2-3 postacie wzrostu, drewno, dachy z trzciny, beczki pod ścianą)
    i 1-2 większe budowle (winiarnia / tłocznia, altana);
  - centrum: **plac biesiadny** - długi stół z ucztą, wielkie ognisko, parkiet do tańca w girlandach i lampionach,
    grajkowie na podwyższeniu, Król Faun na tronie z beczek obok;
  - **nowe grafiki z PixelLab** dozwolone (chaty, rzędy winorośli, stół biesiadny, girlandy, lampiony, tron z beczek,
    winiarnia); autor nie ma obrazu referencyjnego - zrobić w stylu gry i pokazać zrzuty do oceny;
  - liczba satyrów zostaje podobna (ok. 180 z pasterzami); nowe miejsca potworów na końcu albo osobne ziarno;
    przebudowa zmienia układ Turni, więc podbić `MountainZone.LAYOUT`.

## Pomysły i rzeczy do zrobienia

Aktualizuj tę listę, gdy autor rzuci nowy pomysł. Zrobiony punkt przenieś (ze szczegółami) do `docs/historia.md`,
a tu zostaw najwyżej linię w „Systemy w grze”.
Przed rozpoczęciem większego punktu dopytaj autora o szczegóły, bo to luźne pomysły, a nie gotowe projekty.

### Postać i przedmioty

- [ ] Nowe bronie: kosa, kostur (nekromanta), młoty, chainblade'y, sztylety, włócznie, rapier, hydrosfera.
  Każda broń to nowy rodzaj z własnym drzewkiem, a nie tylko nowy przedmiot, więc wymaga szczegółów od autora.
  Ustalenia z rozmowy z autorem (pomysły, nie decyzje):
  - nowa broń to koszt całego drzewka (około 12 umiejętności, 35 pasywnych, 4 kluczowe), broni w ręku 4 postaci,
    linii przedmiotów (5 poziomów x 3 rzadkości), legend i efektów - dodawać po jednej i taką, która gra inaczej
    niż miecz, łuk i księga;
  - **kostur nekromanty** - najmocniejszy kandydat: przywołańcy (upiory, strzygi walczące za gracza), czego gra nie ma;
  - **hydrosfera** - kontrola pola wodą: fale odpychające, wiry ściągające, kałuże spowalniające, lód z księgą
    (Wodnik, rusałki);
  - **chainblade'y** (dwa miecze na łańcuchach) - efektowne, ale bliskie mieczowi; potrzebują własnego pomysłu
    (przyciąganie łańcuchem, ataki na średni dystans). Próbka efektu „dwa szybkie obroty z czerwoną poświatą”
    w kreatorze PixelLab: efekt `70533e5e-74fc-4e0c-bcf5-842dde7d4d03`;
  - **kosa** (w stylu Sorceress z BDO) i **włócznia** - raczej jako odnogi (specjalizacje) istniejących drzewek
    z kilkoma własnymi umiejętnościami, jak wniebowstąpienia w PoE, niż osobne bronie;
  - **przełączania broni NIE będzie** - autor chce, żeby gracz przywiązał się do jednego stylu gry.
- [ ] **Drzewka klas i przebudzenia** (plan autora, inspirowany przebudzeniem z Black Desert; szczegóły do ustalenia):
  - drzewka broni stają się drzewkami klas: wojownik (miecz), łucznik (łuk), mag (księga); do ustalenia, czy klasa
    to wybór broni (bohaterowie Mira, Bogdan, Jaga, Wojciech zostają tylko wyglądem), czy wybór bohatera;
  - **nekromancja w podstawowym drzewku maga** - przywołańcy jako kolejna gałąź magii (obok ognia, lodu, piorunów);
  - **przebudzenie** dokłada klasie to, czego jej brakuje: wojownik - magia cieni w stylu Sorceress z BDO (kosa),
    łucznik - chainblade'y (szybkie, zwinne, walka wręcz), mag - broń do walki wręcz („bojowy mag”: glewia albo
    runiczny rapier);
  - pomysły na wykonanie: przebudzenie przez zadanie główne u żercy Wszebora przy Watrze (rytuał, poziom około
    30-35); broń przebudzenia jako jedna ulepszana broń (kowal / Watra, zaklinanie) zamiast linii łupu; przy
    umiejętnościach przebudzenia broń w ręku zmienia się sama (gracz niczego nie przełącza); combo między
    umiejętnościami podstawowymi i przebudzenia (np. Mgnienie, a zaraz po nim cień kosą);
  - proponowana kolejność: efekty łuku i księgi -> nekromancja w drzewku maga -> przebudzenia (jedna klasa naraz).

### Watra i Ostoja

- [ ] Pomysły do Kryształu Watry: komnata z kowadłem w lochu (jednorazowo wyższa szansa zaklinania), kolejne
  warianty zdarzenia.
- [ ] **Losowe mechaniki w lochach z własnymi drzewkami rozwoju** (jak atlas w Path of Exile): w lochu losowo pojawia się
  dodatkowa mechanika (np. wydarzenie, specjalny przeciwnik, ukryta komnata), a każda ma własne drzewko ulepszeń
  rozwijane postępami w lochach. Szczegóły do ustalenia z autorem.
- [ ] **Sloty w Watrze na przedmioty modyfikujące lochy** (jak skaraby w PoE): przedmioty z łupu wkładane w Watrę przed
  wejściem, które dodatkowo zmieniają loch (więcej danej mechaniki, inne potwory, więcej łupu danego rodzaju).
- [ ] Pomysły na rozwój lochów: kolejne klimaty (lodowe jaskinie, wulkaniczna kuźnia, krasnoludzkie ruiny), kilka pięter
  w dół z coraz lepszym łupem, elitarne potwory z własnymi cechami, pułapki i zagadki, własni strażnicy lochów
  zamiast bossów z krain, sekretne komnaty, zlecenia gildii na lochy.

### Zielarstwo

- [ ] Pomysły na rozwój zielarstwa: rzadsze odmiany ziół i mocniejsze mikstury na wyższe poziomy, mikstury łączące dwa zioła,
  zioła w lochach, ogródek ziołowy w Ostoi.

### Gildia i świat jak w MMO

Oba systemy zależą od gildii poszukiwaczy przygód w Ostoi (budowla `guild` w `scripts/settlement.gd`, tablica ogłoszeń w `scripts/bounties.gd` i `scripts/ui/board_window.gd`).

- [ ] **Druga Watra** (pomysł autora, późna gra): odnaleziona druga Watra i wielki system budowy nowego schronienia
  wokół niej - duże ujście surowców.

### Tłumaczenie na angielski

- [ ] Poprawki tłumaczenia przez autora (kolumna „en” w `translations/teksty.csv`, nazwy w `translations/slowniczek.md`).

### Świat

- [ ] Budowa i rozbudowa obozów w innych krainach, które pasywnie dają surowce albo inne korzyści.
- [ ] Wydarzenia w świecie - dalsze pomysły: kolejni world bossi (np. Baba Jaga w chacie na kurzych nogach), kolejni
  bossowie polowań, zawody na święcie (strzelanie do tarcz, manekiny na czas).
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

