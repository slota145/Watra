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

### Postacie i narzędzia

- [x] Broń w ręku bokiem celuje przed postać (`tools/hero_sheets.py` odbija kąt znacznika trzymanego za plecami - Mira),
  pojedyncze klatki z bronią obróconą w drugą stronę dostają kąt pozostałych (Bogdan idący na północ).
- [x] Drzewa ścina mała siekiera (`assets/weapons/hatchet.png`, `tools/settlement_art.py`) zamiast topora bojowego;
  kilof ma szpice zagięte w stronę trzonka.
- [x] Łuki legendarne (Hydry, Burzy, Swaroga) cięciwą do postaci - `tools/pixellab_items.py` (`_bow_reversed`) odbija odwrócone.
- [x] Kapliczka Ostoi przesunięta na północ (`Settlement.WATRA_SHRINE`) - zasłaniał ją stragan; ucięta sosna
  (`pine_3`) zastąpiona smukłą sosną z PixelLab (`tools/forest_props.py`); sarna w skali 1:1 (`tools/forest_sheets.py`
  - `SIZE["roe"]`), bo po zmniejszeniu była rozmazana.
- [x] Dach budynku nie wraca półprzezroczysty po wejściu (`Building` - dach z meta `no_occlusion`).
- [x] Zwykłe Mgnienie bez zegara odnowienia na slocie (odnowienie ma tylko wirujące Mgnienie w trakcie Młynka).
- [x] Zadania na start: mniej doświadczenia za pierwsze kroki zbierackie, kolejność gobliny (Gruzłog) przed wilkami
  (Szarokieł), „Pierwsza budowla” wymaga lecznicy (warunek ["project", id]), budowle Ostoi o połowę tańsze;
  niewykonana prośba drużyny przepada, gdy drużyna odejdzie albo zginie proszący (`Travelers._fail_party_help`).
- [x] Miecz Miry w chodzie w dłoni (`tools/hero_sheets.py` - `STEADY_WALK`, `IDLE_GRIP_FROM`), dąb bez okruchu sąsiedniej
  klatki (`tools/forest_props.py` odcina okruchy z boków), 3x wyższy próg doświadczenia (`CharacterStats.xp_base`);
  `tests/balance_sim.gd` liczy kamienie zaklinające tylko z lochów (skarbiec strażnika, Kryształ Watry).
- [x] Mgnienie (i wirujące Mgnienie) przeskakuje na wylot przez wroga i tnie wszystkich na drodze (`SwordSkills._jump`,
  `_landing_spot`); kolejny cel inny niż poprzedni, a jednego wroga przebija tam i z powrotem.
- [x] Lochy: duża mapa (M) pokazuje loch (bez zakładki „Świat”); potwory nie rodzą się w ścianach (`Dungeon._free_spot`,
  `_blocked`); Kryształ Watry w co czwartym lochu (`Dungeons.EVENT_CHANCE` 0,25); więcej wystroju - pod ścianami
  (`wall_props` klimatu), w komnatach i korytarzach (`Dungeon._scatter_prop`); +7% potworów na stopień
  (`Dungeons.TIER_COUNT_BONUS`).
- [x] Dymek przedmiotu z ikoną (`Items.ICON_MARK`, `RichTooltip._panel`), przy kolczykach i pierścieniach porównanie
  z obiema założonymi sztukami; kamienie i esencja osadzone w przedmiocie widać w rogu kratki (`SocketBadges`,
  znikają pod kursorem); okno zaklinania ma u góry pasek założonych przedmiotów (kliknięcie - do zaklęcia).
- [x] Spokojniejszy dźwięk Strzały tropiącej (równy szum bez gwizdu, `tools/sfx_synth.py`); strzały tropiące znikają
  najpóźniej po czasie życia także wtedy, gdy lot stanie (`SeekerArrow._process`); Łuk Burzy i Łuk Swaroga w ręku
  bez ciemnego wypełnienia między łukiem a cięciwą (`pixellab_src/legend_held/`).
- [x] Palenie stosu w Watrze naraz (`Inventory.take`) - bez zacinania gry; w Młynku rękojeść krąży w wyciągniętej
  dłoni (`Player.WHIRL_HAND_REACH`), bazowy promień 40 zamiast 30.
- [x] Wydarzenia w świecie, pojedynki, zbóje, osłona zbieraczy i prośby drużyny (sława gildii, Znaki Zwycięstwa)
  dopiero po zbudowaniu gildii (`WorldEvents.guild_ready`); zadanie główne „Pan topielców” (id `main_hydra`) wysyła
  do Wodnika zamiast za trudnej Hydry.
- [x] Mgnienie z efektami z kreatora efektów PixelLab (`tools/vfx_art.py`, `SkillEffects.sheet_once`): smuga za postacią
  z błyskiem w miejscu startu (rozciągana wzdłuż skoku) i proste cięcie z błyskiem na celu, ukośnie do drogi skoku.
- [x] Młynek z zapętlonym wirem z kreatora efektów (`Player._update_whirl_fx`, `assets/effects/whirl.png`: dwa łuki ostrzy,
  górna połowa za postacią, dolna przed nią, skalowany do zasięgu Młynka); w trakcie wirującego Mgnienia szybszy wir
  (`whirl_fast.png`: trzy ostrza z rozmyciem i odrzucane iskry, `SwordSkills.is_spin_flickering`) i mocniejsza smuga
  skoku ze spiralą ostrza (`flicker_spin_trail.png`).
- [x] Smugi Mgnienia i wirującego Mgnienia bez równego ucięcia na końcu: własny kształt igły (zamiast pasa z części
  `thrust_streak`) - cienki ogon pogrubia się w stronę postaci, a gasnąc, ogon przesuwa się ku postaci.
- [x] Dymne Wybuchy z kreatora efektów (`assets/effects/smoke_burst.png`, `SwordSkills._burst`): zamiast kółka i chmury
  kropek - klin dymu i smug buchający z punktu do przodu (wg szkicu autora), obrócony w kierunku lotu każdego wybuchu
  i skalowany do jego promienia; `SkillEffects.sheet_once` ma `size` (skala) i `lean` (korekta pochylonego rysunku).
  Poszarpany rozbłysk na starcie (bez okrągłej kuli); krótki klin, a kolejne rzędy buchają zygzakiem
  (`SwordSkills.SMOKE_FX_ZIGZAG`, mały losowy rozrzut), żeby 9 wybuchów nie zlewało się w 3 strumienie.
- [x] Rozpłatanie z kreatora efektów (`assets/effects/rend.png`, `rend_wound.png`): szeroki łuk stali z krwawym śladem
  i kroplami krwi zamiast półksiężyca, a na zranionym wrogu rozprysk krwi zamiast iskier (`SwordSkills.bleed_enemy`).
- [x] Rozłupanie Ziemi z kreatora efektów (`assets/effects/ground_slam.png`): w każdym kroku fali pęknięć erupcja
  kamiennych kolców, odłamków i pyłu (nieobracana, coraz większa); w combo po Półksiężycu erupcje w dwóch kręgach
  wokół postaci (9 i 14). Pęknięcia w ziemi (`SkillEffects.ground_crack`) zostają.
- [ ] Wędrowny kupiec Hasan ma w puli tylko 3 towary (`Settlement.MERCHANT_POOL`) od usunięcia kamieni zaklinających,
  więc jego oferta się nie zmienia - do uzupełnienia nowymi towarami.

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

- [x] **Drzewko miecza, etap 1** (`scripts/skill_tree.gd`, widok `scripts/ui/skill_tree_view.gd` w oknie K, `scripts/skill_book.gd`):
  sieć węzłów jak drzewko pasywne w PoE (umiejętności, pasywne, kluczowe), punkt umiejętności za każdy poziom postaci
  (+1 na start), węzeł tylko obok wybranego; umiejętność odblokowuje węzeł, kolejne poziomy 2-5 dalej za złoto; zapomnienie
  drzewka u mędrca za złoto (kupione poziomy zostają); starsze zapisy dostają węzły za kupione umiejętności miecza.
  Ataki i czary (`Skills.TAGS`): ataki przyspiesza szybkość ataku i wzmacniają obrażenia fizyczne, czary - szybkość rzucania
  (rośnie z inteligencją) i obrażenia magiczne; nowe statystyki są na przedmiotach. Ogólne combo (`Skills.COMBOS`,
  `Player.note_skill` / `combo_with`) ze świecącym slotem i kurczącym się pierścieniem. Nowe umiejętności (`scripts/sword_skills.gd`,
  ikony z PixelLab przez `tools/sword_tree_art.py`):
  - **Mgnienie**: dopóki trzymasz klawisz, skoki od wroga do wroga z cięciem (mana za skok); w trakcie Młynka wirujące Mgnienie -
    seria szybkich skoków z odnowieniem, węzeł kluczowy **Nieustający Wir** znosi odnowienie (Młynek zużywa 2x many);
  - **Dymne Wybuchy** (atak i czar): ładowane, 1-3 rzędy po 3 wybuchy dymu w stożku; zaraz po innej umiejętności - wszystkie 9 od razu.
- [x] **Drzewko miecza, etap 2**: pełne drzewko - 12 umiejętności, 35 węzłów pasywnych, 4 kluczowe, pięć gałęzi (Wir, Krew
  i okrzyk, Ostrze, Dym, obrona); widok drzewka przesuwa się przeciąganiem, kółko myszy przybliża, szczegóły węzła w kolumnie obok.
  Nowe umiejętności (`scripts/sword_skills.gd`, Widmowe Ostrza w `scripts/spectral_blades.gd`):
  - **Rozpłatanie**: szerokie cięcie z krwawieniem (combo po Mgnieniu - podwójne),
  - **Rozłupanie Ziemi**: fala pęknięć przed postacią, rani i ogłusza (combo po Półksiężycu - pierścień dookoła),
  - **Riposta**: zasłona - cios nie rani, kontra wokół (combo: potem Szarża za darmo i bez odnowienia),
  - **Zew Peruna** (okrzyk): premia do obrażeń, strach wrogów, 3 kolejne ciosy krytyczne,
  - **Widmowe Ostrza** (czar): krążące miecze (combo po Młynku - od razu wylatują we wrogów).
  Węzły kluczowe: Nieustający Wir, **Taniec Ostrzy** (combo przyspiesza ataki), **Dym i Cień** (chmura po Dymnych Wybuchach:
  unik i darmowe Mgnienie), **Krwawy Szał** (krwawienie leczy). Chwilowe premie w `CharacterStats.temp_bonus` i w ikonach efektów.
  **Amulet Wiecznego Wiru** (legendarny, tylko ze skarbca strażnika w lochach): wirujące Mgnienie bez odnowienia.
- [x] **Drzewko łuku, etap 3** (`SkillTree.TREES["bow"]`, `scripts/bow_skills.gd`, grafiki z PixelLab przez `tools/bow_tree_art.py`):
  13 umiejętności (Salwa, Strzała tropiąca, Szybka salwa i regeneracje przeszły do drzewka), 35 węzłów pasywnych, 4 kluczowe.
  Umiejętności łuku kupione wcześniej za złoto dostają węzły przy wczytaniu. Nowe umiejętności (z combo):
  - **Grot Swaroga**: napinanie i przebijająca strzała (po Strzale tropiącej - wybuch ognia przy każdym trafieniu),
  - **Deszcz Strzał**: krąg pod kursorem (po Salwie - dwa razy gęściej),
  - **Odskok**: skok do tyłu i 3 strzały (potem Salwa darmowa, 5 strzał),
  - **Sidła**: pułapka unieruchamia, trafienia unieruchomionych są krytyczne,
  - **Sokół**: krąży i nurkuje na wrogów (po Strzale tropiącej - od razu, potrójnie),
  - **Jadowe Groty**: strzały zatruwają (po Sidłach - jad przeskakuje),
  - **Strzała Wichru** (atak i czar): odrzucający stożek (po Odskoku - dwa razy szerszy),
  - **Balista**: wieżyczka strzelająca w najbliższych wrogów.
  Węzły kluczowe: **Oko Sokoła**, **Grad**, **Myśliwy z Cienia** (`Goblin.hidden_until`), **Strzelanie w biegu**.
  Chwilowe premie źródeł łączy `CharacterStats.set_temp`. Legendy ze skarbca lochów: **Łuk Swaroga** (strzała tropiąca
  się rozszczepia), **Rękawice Cieśli Wojennego** (balista strzela salwą), **Talizman Tropiciela** (balista strzela
  strzałami tropiącymi).
- [x] **Drzewko księgi magii, etap 4** (`SkillTree.TREES["spell"]`, `scripts/spell_skills.gd`, grafiki z PixelLab przez
  `tools/spell_tree_art.py`): 13 umiejętności (Kula ognia, Łańcuch błyskawic, Fala piorunów i regeneracje przeszły do drzewka),
  35 węzłów pasywnych, 4 kluczowe. Nowe czary (z combo):
  - **Włócznia Marzanny**: przebija i spowalnia (`Goblin.chill`; po Kuli ognia - lodowe odłamki),
  - **Zamieć**: śnieżyca pod kursorem (po Włóczni - od razu zamraża),
  - **Burza Peruna**: pioruny w wrogów wokół (po Łańcuchu błyskawic - przeskakują dalej),
  - **Kula Piorunów**: powolna kula razi wrogów obok (po Fali piorunów - wybuch na końcu),
  - **Spadająca Gwiazda**: wybuch i podpalenie (po Zamieci - podwójne obrażenia),
  - **Krok przez Mgłę**: teleport (potem Kula ognia od razu naładowana),
  - **Tarcza Many**: część ciosów zabiera mana (po Kroku - przez chwilę całe ciosy),
  - **Kamień Runiczny**: w jego kręgu czary mocniejsze i szybsze.
  Węzły kluczowe: **Harmonia Żywiołów** (`Skills.ELEMENTS`), **Ofiara Krwi** (koszt zdrowiem w `Player.spend_mana`),
  **Pełnia Mocy**, **Echo Run**. Legendy ze skarbca lochów: **Księga Marzanny** (Zamieć zawsze zamraża),
  **Korona Peruna** (Burza trwa, dopóki trzymasz klawisz).
- [x] Broń w ręku: łuki we właściwym rozmiarze (`tools/pixellab_items.py` sam dobiera obrót ikony), legendarne bronie
  trzymają w ręku siebie (`tools/legend_held.py`, `scripts/legend_held.gd`; Łuk Swaroga, Łuk Burzy i Księga
  Marzanny z osobnych rysunków PixelLab w `pixellab_src/legend_held/`).
- [x] **Esencje legend i gniazda** (`scripts/essences.gd`, okno `scripts/ui/essence_window.gd`, grafiki z PixelLab przez
  `tools/essence_art.py`):
  - **Wyciąganie w Watrze** (przycisk „Esencje” w oknie Watry): legenda z plecaka przepada za żar (rośnie z poziomem
    przedmiotu i zaklęciem, `Essences.ember_cost`), a w jej miejscu pojawia się Esencja z jej efektem - losowo 40-80%
    siły legendy z jej poziomem zaklęcia; esencje w trzech rodzajach: broń, zbroja, biżuteria.
  - **Ołtarz Welesa** (`Dungeon._plan_altar`, `Essences.ALTAR_CHANCE`, w trybie deweloperskim zawsze): ukryta komnata
    w lochu bez potworów i pochodni; jedna legenda za darmo i mocniej (60-100%), potem ołtarz gaśnie.
  - **Gniazda u kowala** (Bronisław, usługa „Esencje”): gniazdo esencji w rzadkim przedmiocie (1 Serce Kryształu
    i złoto) albo w legendzie (3 Serca, więcej złota - wtedy dwa efekty legendarne); esencja tylko tego samego rodzaju;
    wyjęcie za złoto, inaczej esencja przepada. **Serce Kryształu** (`crystal_heart`) z Kryształu Watry od 3. stopnia
    lochu i ze skarbca strażnika.
  - Esencja w **gnieździe legendarnym drzewka** broni (tylko tam, działa z bronią drzewka; wyjęcie za złoto albo zniszczenie).
  - Kilka źródeł jednego efektu (legendy, esencje w przedmiotach i w drzewku) łączy `Essences.combine`
    (w `Equipment.effect_power`): szanse jak niezależne losowania, efekty w sztukach - najsilniejszy plus połowa reszty.
  - Dawne kamienie (zwykłe, doskonałe, uświęcone, miłosierdzia) zostają do zaklinania (`scripts/enchanting.gd`).
  - [x] **Kamienie szlachetne i gniazda w przedmiotach** (`scripts/gems.gd`, okno `scripts/ui/jeweler_window.gd`, ikony
    z PixelLab przez `tools/gem_art.py`, jubiler przez `tools/npc_sheets.py`):
    - jubiler Dobromir przy kapliczce w Orlej Przełęczy daje zadanie-samouczek „Pierwszy klejnot” (`jeweler_gem`):
      surowy klejnot wyskakuje na pewno z rudy żelaza w Turniach; po zadaniu (`Gems.unlocked`) kamienie wypadają
      z potworów (w lochach - lepsze, z szansą na trzecią premię; bossowie zawsze), magiczne i rzadkie przedmioty
      czasem mają gniazdo, a pierwsze gniazdo u jubilera jest darmowe i gracz dostaje pierwszy kamień;
    - 6 rodzajów (rubin, szafir, szmaragd, topaz, ametyst, onyks) i 5 szlifów (okruch, odłamek, kamień, szlifowany,
      królewski - szlif rośnie z poziomem); 2 premie: z puli rodzaju i ze wspólnej (szybkość ataku i rzucania,
      krytyki, nowy „obszar umiejętności” - `CharacterStats.area_multiplier`, regeneracja);
    - u jubilera: wydrążenie gniazda (za złoto, jedno na przedmiot, bez legend), osadzenie, darmowe wyjęcie
      (kamień wraca), łączenie 3 kamieni jednego szlifu w lepszy; gniazda i kamienie siedzą w przepisie
      wylosowanego przedmiotu (`Loot.register`, `sockets`), premie w `Items.stats_of`.
  - [x] **Gniazda w drzewkach broni** (jak „jewel sockets” w PoE; `SkillTree` - węzły „socket”, `SkillBook.tree_gems`):
    w każdym drzewku 2 zwykłe gniazda i 1 legendarne przy węźle kluczowym, wybierane za punkt umiejętności; kamień
    działa tylko z bronią drzewka, a jego premie są o 50% mocniejsze (`SkillBook.TREE_GEM_POWER`). Osadzanie w oknie K
    (zaznacz gniazdo - kamienie z plecaka w kolumnie szczegółów, „Wyjmij kamień” za darmo) albo przeciągnięciem kamienia
    z plecaka na gniazdo (zamiana, gdy gniazdo zajęte). Zapomnienie drzewka u mędrca zwraca kamienie.
    **Kamień Promienia** (`Gems.roll_radius`, tylko do drzewka, ikona z PixelLab przez `tools/gem_art.py`) wzmacnia
    wybrane węzły pasywne w promieniu `SkillBook.RADIUS_RANGE` (turkusowy krąg w drzewku); wypada z Kryształu Watry
    i ze skarbca strażnika lochu.
- [x] **Po kamieniach i esencjach** (pomysły autora, zrobione po systemach kamieni i esencji):
  - [x] **Chata jubilera w Ostoi** (`Settlement.PROJECTS["jeweler"]`, `_build_jeweler`, grafiki z PixelLab przez
    `tools/village_life.py`): w menu budowy dopiero po zadaniu „Pierwszy klejnot” (`requires_quest`,
    `Settlement.project_locked`), koszt: drewno, kamień, ruda żelaza; Dobromir przeprowadza się do chaty między kuźnią
    a bramą południową (z Orlej Przełęczy znika - `World.village_built`), a w Ostoi także przeszlifowuje kamienie
    (usługa „reshape”, `Gems.reshape`: nowe premie, rodzaj, szlif i liczba premii zostają).
  - [x] **Zakładanie kamienia przeciąganiem** (`Gems.drag_target` / `drag_insert`, okno plecaka): kamień z plecaka
    przeciągnięty na przedmiot z pustym gniazdem (w plecaku albo założony) się osadza; zajęte gniazdo odmawia (kamień
    wyjmuje jubiler), Kamień Promienia nie pasuje; esencja - do pustego gniazda esencji tego samego rodzaju (wyjmuje
    kowal); przedmiot bez gniazda - zwykła zamiana miejsc.
  - [x] **Miejsce na pas** (`Equipment.SLOTS` - „belt”, okno plecaka): dwie linie w `tools/item_catalog.py` - pas
    skórzany i okuty, po 5 poziomów i 3 rzadkości (ikony z PixelLab, `tools/pixellab_items.py`); własna pula premii
    (`Loot.POOLS["belt"]`) z nową „siłą mikstur” (`CharacterStats.potion_multiplier` - mikstury zdrowia i many leczą
    mocniej); zaklinanie i esencje jak zbroja; pierwszy poziom u kowala. Legendy ze skarbca lochów: **Pas Mokoszy**
    (szansa, że mikstura nie ubędzie) i **Pas Bogatyra** (po miksturze premia do obrażeń - `LegendaryEffects.on_potion`).
  - [x] **Ładniejszy widok ekwipunku** (okno plecaka, `InventoryWindow.DOLL`, grafiki z PixelLab przez
    `tools/paperdoll_art.py`): sylwetka wojownika, a wokół niej miejsca na przedmioty (hełm przy głowie, buty przy
    stopach), ramki 28 px, broń i napierśnik w wysokich ramkach; pusty slot pokazuje zarys pasującego przedmiotu,
    ramka - kolor rzadkości (`LegendaryFrame`).
- [x] **Przedmioty niezidentyfikowane** (`scripts/unidentified.gd`, ikony z PixelLab przez `tools/unidentified_art.py`):
  opcja „Łup niezidentyfikowany” w Ustawieniach (`Game.unidentified_loot` w `user://settings.cfg`, domyślnie wyłączona).
  Magiczna i rzadka broń, zbroja i biżuteria z łupu (`Pickup`) wypada zawinięta w płótno - id
  „unid_<rodzaj>_<rzadkość>_<poziom>” (dane z id - `Items.get_data`), stosy w plecaku, tańszy skup; zwykłe przedmioty
  i legendy - zawsze zidentyfikowane. Identyfikacja (`Player.identify`): PPM - jeden, Shift+PPM - cały stos, przycisk
  „Zidentyfikuj wszystko” w plecaku (`identify_all`) - losuje przedmiot tego rodzaju, rzadkości i poziomu.
- [x] **Torby z łupu** (`scripts/bags.gd`, ikony z PixelLab przez `tools/bag_art.py`): 6 rodzajów o stałej pojemności -
  Mieszek 5, Skórzana sakwa 8, Torba wędrowca 12, Plecak łowcy 18, Plecak wyprawowy 24 i Legendarny tobół 35
  (`Items` - pole „bag”); 5 miejsc na torby (`Player.bags`). Wypadają z potworów (`Goblin._drop_bag`, rodzaj wg poziomu
  - `Bags.for_level`, rzadko), częściej z bossów (czasem tobół), ze skarbca lochów i najlepszej skrzyni wydarzenia;
  szyte w oknie Rzemiosła (zakładka „Torby”, `Crafting.RECIPES` z grupą „bags”) ze skór i surowców kolejnych krain.
  Sakwa i Plecak zniknęły ze sklepu (działają w starszych zapisach); wymiana Znaków Zwycięstwa daje Plecak wyprawowy.
- [ ] Nowe bronie: kosa, kostur (nekromanta), młoty, chainblade'y, sztylety, włócznie, rapier, hydrosfera.
  Każda broń to nowy rodzaj z własnym drzewkiem, a nie tylko nowy przedmiot, więc wymaga szczegółów od autora.

### Interfejs i walka

- [x] Paski szybkiego wyboru: 10 slotów przedmiotów (1-0, nowa postać dostaje po 5 mikstur życia i many pod 1 i 2)
  i 7 slotów umiejętności (LPM, PPM, Q, E, R, Z, X) z osobnym układem dla każdej broni. Każdy slot przyjmuje
  umiejętność albo przedmiot (`Hotbar.entry` / `put` / `move`, wspólna numeracja slotów); umiejętność innej broni
  czeka na wspólnym pasku 1-0 przygaszona. Na slot umiejętności trafia też
  zwykły atak, więc gracz nie jest przywiązany do LPM. Przeciąganie z plecaka i z okna umiejętności, PPM albo przeciągnięcie
  poza pasek opróżnia slot. Odnowienie widać na slocie (wskazówka zegara i sekundy), brak many - niebieskawy slot.
  Shift+LPM zniknął (uderzenie leży domyślnie pod Q), interakcja przeszła z E na F.
- [x] Ikony efektów pod paskami zdrowia i many: premie z osady, Dary i poziom Watry, efekty legendarnych przedmiotów,
  trucizna, spowolnienie, oszołomienie; ramka złota/czerwona/szara, czas pod ikoną, opis w dymku.
- [x] **System combo**: umiejętność użyta zaraz po innej zachowuje się inaczej (`Skills.COMBOS`); combo zależy od umiejętności,
  nie od klawisza; slot umiejętności gotowej do combo świeci z kurczącym się pierścieniem czasu (`ActionBars._process`).
  Kolejne combo przychodzą z etapem 2 drzewka miecza.

- [x] **Encyklopedia** (klawisz L, okno `scripts/ui/codex_window.gd`, dane i odkrycia w `scripts/codex.gd` - dziecko gracza,
  zapisywane; ikona z PixelLab przez `tools/codex_art.py`): zakładki Legendy (ze źródłem: boss albo skarbiec lochów),
  Bossowie, Potwory (kraina i poziomy, liczba pokonanych, stopień w bestiariuszu, trofeum, legendy bossa, opis),
  Zioła i mikstury, Przedmioty (linie po 5 tierów). Nieodkryte wpisy to ciemne sylwetki z „???” i licznik „Odkryto”;
  przedmiot odkrywa się, gdy trafi do plecaka, na postać albo do magazynu (wylosowany liczy się jako jego baza),
  potwora - gdy zostanie pokonany. W trybie deweloperskim widać wszystko, a kliknięcie przedmiotu daje jedną sztukę
  (legendę z poziomem postaci). Nowy potwór wymaga wpisu w `Codex.MONSTERS`.

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
  - potwory idą do gracza drogą omijającą ściany (`Dungeon.steer`, `Goblin.pathing`);
  - cel: gromady potworów (150-250), w najdalszej komnacie strażnik; po jego pokonaniu skarbiec wysypuje łup i pojawiają się
    płomienie powrotu do Ostoi (te same są w komnacie wejściowej);
  - stopień 1-7 (potwory poz. 5-41) najwyżej równy poziomowi Watry; modyfikatory za żar (Hordy, Bogactwo, Wściekłość,
    Pełny skarbiec) odblokowywane kolejnymi poziomami Watry; wydany żar nie obniża poziomu Watry (`Boons.ember_spent`).
- [x] **Kryształ Watry** (`scripts/watra_crystal.gd`, grafiki z PixelLab przez `tools/crystal_art.py`): zaklinanie
  przeniesione do końcówki gry. Kamienie zaklinające nie wypadają już w krainach (potwory, bossowie, drzewa, głazy,
  zlecenia, wędrowny kupiec) - tylko z Kryształu Watry i ze skarbca strażnika lochu; zaklina kowal Bronisław w Ostoi
  (usługa „Zaklinanie”, nie ma już przycisku w plecaku). W co czwartym lochu (`Dungeons.EVENT_CHANCE`, w trybie
  deweloperskim zawsze) największa komnata jest pusta i rośnie w niej kryształ; gdy gracz podejdzie, nadchodzą
  4 fale potworów idących na cel (`Goblin.objective`). Warianty: obrona kryształu albo dwóch górników kujących
  kryształ (im więcej przeżyje, tym większa nagroda); po porażce tylko część nagrody. Nagroda rośnie ze stopniem
  lochu (`WatraCrystal.reward`). Tryb deweloperski trwa po przejściu do innej krainy (`Game.dev_mode`).
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

- [x] **Zioła i mikstury zielarki** (`scripts/herbs.gd`, roślina `scripts/herb.gd`, grafiki z PixelLab przez `tools/herb_art.py`):
  w każdej krainie rośnie jej zioło (dziurawiec, rumianek, tatarak, arnika, kwiat paproci - rzadki, bieluń), zrywane klawiszem F
  (szybciej niż drzewo, iskierki nad rośliną, odrasta po kilku minutach). Zielarka Jadwiga z lecznicy („Mikstury”) warzy
  z 3 ziół i złota miksturę - przedmiot do wypicia (także z paska 1-0), premia z grupy „elixir” na 5 minut, mocniejsza niż posiłek.
- [ ] Pomysły na rozwój zielarstwa: rzadsze odmiany ziół i mocniejsze mikstury na wyższe poziomy, mikstury łączące dwa zioła,
  zioła w lochach, ogródek ziołowy w Ostoi.

### Gildia i świat jak w MMO

Oba systemy zależą od gildii poszukiwaczy przygód w Ostoi (budowla `guild` w `scripts/settlement.gd`, tablica ogłoszeń w `scripts/bounties.gd` i `scripts/ui/board_window.gd`).

- [x] **Inni podróżnicy** (`scripts/travelers.gd` - spis i życie w czasie, dziecko gracza; `scripts/traveler.gd` - postać
  w świecie, `World._sync_travelers`): 40 poszukiwaczy przygód ze słowiańskimi imionami, wyglądem (arkusze NPC), bronią,
  poziomem, ekwipunkiem i sławą; aktywnych tylu, ile pozwala ranga gildii (4 bez gildii, potem 14/26/40, ulepszenie
  u pisarza gildii za surowce i złoto). Co minutę ruszają z Ostoi na łowy do krainy pasującej do poziomu, awansują,
  wracają albo giną. W krainie widać łowców przy siedliskach (imię i poziom nad głową, pasek zdrowia): walczą
  z potworami (bossów zostawiają graczowi), potwór odpowiada (`Goblin.objective`), a zabity głównie przez nich nie daje
  graczowi łupu ani doświadczenia (`Goblin.traveler_damage`); w Ostoi spacerują po placu, przy Watrze i gildii
  i rzucają hasła jak gracze w MMO. Lista podróżników (ranking) u pisarza gildii (`scripts/ui/travelers_window.gd`).
- [x] **Symulowany rynek** (`scripts/market.gd`, okno `scripts/ui/market_window.gd`, pisarz gildii Gniewko - po zbudowaniu
  gildii): towary (surowce, zioła, mikstury, kamienie) z cenami błądzącymi w czasie i arkuszem ofert sprzedaży i kupna
  z imionami podróżników; kupno i sprzedaż od razu (podatek 10%, duże transakcje przesuwają cenę) albo własne
  zamówienia po swojej cenie realizowane z czasem; oferty przedmiotów od podróżników (broń, zbroje, biżuteria,
  kamienie szlachetne, czasem legendy) i wystawianie własnych.
- [x] **Zadania główne** (`scripts/main_quests.gd`, żerca Wszebor przy Watrze - postać z PixelLab przez `tools/npc_sheets.py`):
  łańcuch 23 kroków przez wszystkie krainy (bossowie, kapliczki) i mechaniki (budowa, zielarstwo, drzewka,
  encyklopedia, Watra, lochy, Kryształ Watry, klejnoty, zaklinanie, esencje); złote „!” i „?” nad postaciami,
  złoty tytuł w rozmowie, dzienniku i pod minimapą (zawsze śledzone); zadania poboczne mają znaczniki niebieskie.
  Krok daje `giver`, nagrodę wydaje `receiver`; warunek `check` sprawdzany co pół sekundy (`QuestLog.update_main`),
  zdarzenia przez `QuestLog.note_event`. Krok z warunkiem ["quest", id] (np. „Ręce do pracy”, „Szlachetny kamień”)
  sam przyjmuje zadanie poboczne (`MainQuests.linked_quest`), pokazuje jego postęp (`MainQuests.progress_text`),
  a postać daje je do oddania przed krokiem. Nagrody: złoto, doświadczenie, przedmioty i punkty umiejętności (`SkillBook.bonus_points`).
  Lochy Watry otwiera krok „Płomień Watry” (`MainQuests.dungeons_unlocked`); starsze zapisy zaliczają po wczytaniu
  kroki z już spełnionym warunkiem (`QuestLog.catch_up_main`, bez nagród).
- [x] **Więcej zleceń na tablicy** (`scripts/bounties.gd`, okno `scripts/ui/board_window.gd`): oferty wystawiają
  podróżnicy i mieszkańcy - potwory, bossowie (cel „boss:<nazwa sceny>”) i surowce/trofea (oddawane przy odbiorze)
  w odkrytych krainach (kapliczki) niewiele powyżej poziomu gracza; 4-8 ofert (wg rangi gildii), odświeżane co 10 minut,
  najwyżej 3 przyjęte. Nagrody: złoto, doświadczenie, przedmioty, kamień szlachetny i **sława gildii**
  (`Travelers.guild_fame`). Gildia ma **6 rang** (14, 21, 27, 32, 36, 40 aktywnych podróżników) - kolejne wymagają sławy
  oraz złota i surowców.
- [x] **Drużyny z podróżnikami** (`Travelers.party`, `Traveler` w trybie „party”, `World._process_party_offers`,
  okienko `scripts/ui/party_offer.gd`, ramki `scripts/ui/party_frames.gd`): gdy gracz wejdzie między łowców (najwyżej
  co 2 minuty, bez drużyny), dostaje zaproszenie „Dołącz / Odmów”; odmowa - łowcy przenoszą się na inny spot, zgoda -
  1-3 podróżników idzie za graczem przez krainy i lochy (dobiegają, gdy zostaną w tyle), bije wrogów przy graczu
  (bossów słabiej), a ich zabójstwa dają graczowi łup i doświadczenie z premią +10% za członka
  (`Travelers.party_xp_factor`). Odchodzą po 15-30 minutach, po powrocie do Ostoi albo przyciskiem „Opuść”.
  Czasem zamiast zaproszenia **prośba o pomoc** - zadanie z drużyną w tej krainie (potwory, boss albo surowce,
  `QuestLog.take_help`), po wykonaniu nagroda i podziękowanie same. Łowcy pozdrawiają przechodzącego gracza i dają
  wskazówki o krainie (`Travelers.GREETINGS` / `HINTS`).
- [x] **Tryby świata** (`scripts/world_modes.gd`, wybór `scripts/ui/world_mode_picker.gd` - w menu nowej gry po wyborze
  bohatera i u żercy Wszebora w Ostoi; `Travelers.world_mode`, starsze zapisy - spokojny) i **charaktery podróżników**
  (`temper`: 60% przyjaznych, 28% pojedynkowiczów, 12% zbójów; kolor imienia: zielone / żółte / czerwone):
  spokojny - wszyscy życzliwi; realistyczny - pojedynkowicze (i zbóje) wyzywają na **pojedynek do 10% zdrowia**
  (nikt nie ginie; wygrana: złoto i sława, odmowa - „Tchórz!”, polują dalej); hardcorowy - dodatkowo **zbóje (PK)**
  napadają bez ostrzeżenia: pokonany zbój zostawia złoto, doświadczenie i czasem przedmiot, a gdy wygra - zabiera
  10% złota. W walce podróżnika zastępuje **rywal** (`scripts/rival.gd` - potwór z jego wyglądem, więc działają na niego
  wszystkie umiejętności gracza).
- [x] **Łowcy zbierają surowce** (`Traveler.find_gather_target` / `_process_gather`, `Travelers.GATHER`): przy okazji łowów
  (po walce) ścinają drzewa, kują głazy i rudę, zrywają zioła przy siedlisku - nie bliżej gracza niż `PLAYER_SAFE`,
  nie w Ostoi i tylko dopóki zebranych surowców w krainie jest mniej niż 20% (`MAX_DEPLETED`); napadnięci rzucają
  pracę i walczą. Urobek (także łowców poza oczami gracza) trafia na rynek jako **świeży towar** (`Market.supply`,
  `fresh`): tańsza oferta z imieniem zbieracza, którą inni szybko wykupują. Łowcy rzucają hasła przy pracy
  (`Travelers.LINES_GATHER`), a czasem proszą o **osłonę** (`World.start_guard`): 40 s, co 8 s kilka pobliskich
  potworów rusza na zbieracza; nagroda - złoto, doświadczenie, część urobku i sława gildii.
- [x] **Rynek rośnie z liczbą podróżników** (`Market.size_factor` z `Travelers.active_count`): oferty przedmiotów
  od 8 (bez gildii) do 60 (pełna gildia, `listing_target`), 4-10 poziomów cen i większe ilości towarów (`book_depth`,
  `volume` - duże transakcje mniej przesuwają cenę), częściej rzadkie i legendarne przedmioty, więcej kupujących
  (`demand` - przedmioty gracza schodzą szybciej). Okazje (`Market.deal_of` - taniej od uczciwej ceny) inni wykupują
  w kilka minut, przepłacone wiszą, a nowe oferty dochodzą stopniowo. Okno rynku: filtr rodzaju, sortowanie (okazja,
  cena, poziom), przełącznik „Dla mnie” i znaczek okazji (np. „-20%”) przy każdej ofercie.
- [x] **Rzemiosło statystyk przedmiotów** (`scripts/item_craft.gd`, okno `scripts/ui/workshop_window.gd` - przycisk
  „Warsztat” u kowala po zbudowaniu warsztatu płatnerza; ikony run z PixelLab przez `tools/rune_art.py`): przerzut
  wartości wybranej premii (ten sam tier), przekucie premii, usunięcie, dodanie losowej (do limitu rzadkości),
  ulepszenie rzadkości (także zwykłych przedmiotów ze sklepu) - za złoto i trofea potworów z krainy pasującej do poziomu
  przedmiotu (ujście trofeów); runy z lochów (skarbiec, Kryształ Watry, rynek): **Runa Zmiany** (wszystkie premie od
  nowa) i **Runa Pieczęci** (z Sercem Kryształu: wybrana premia zostaje, reszta od nowa). Działa też na legendach - 3 razy drożej.
- [ ] **Druga Watra** (pomysł autora, późna gra): odnaleziona druga Watra i wielki system budowy nowego schronienia
  wokół niej - duże ujście surowców.

### Świat

- [ ] Budowa i rozbudowa obozów w innych krainach, które pasywnie dają surowce albo inne korzyści.
- [x] **Losowe wydarzenia w świecie, etap 1** (`scripts/world_events.gd` - harmonogram, ranking i nagrody, dziecko gracza;
  `scripts/event_site.gd` - wydarzenie w krainie gracza; meteoryty `scripts/meteor.gd`, `scripts/meteor_rock.gd`;
  panele `scripts/ui/event_tracker.gd` i `scripts/ui/event_result.gd`; grafiki z PixelLab przez `tools/event_art.py`):
  co 10-15 minut w losowej odkrytej krainie (kapliczka) - komunikat także w innej krainie, znacznik na minimapie
  i dużej mapie, panel z czasem i celem. Poziom: górny krainy albo gracza, jeśli wyższy. Rodzaje:
  - **Najazd na kapliczkę** (poza Goblińskim Lasem): 5 fal potworów krainy idzie na kapliczkę (`Goblin.objective`,
    miejsca z wolną drogą - `EventSite._clear_spot`); porażka gasi kapliczkę na 10 minut (bez teleportu),
  - **Wędrowny czempion**: elitarny potwór z cechą (`WorldEvents.TRAITS`: Płomienny, Wampiryczny, Rączy, Kamienny,
    Przywoływacz) krąży po krainie,
  - **Deszcz meteorytów**: krąg ostrzegawczy, uderzenie rani, skała do rozbicia (ruda, kamienie, czasem klejnot),
    potwory z kraterów,
  - **Polowanie na bossa** (Hydra, Gryf - `WorldEvents.HUNT_BOSSES`): boss rozwścieczony (3x zdrowie).
  Przybywa gromada podróżników (`Traveler` w trybie „event”, polegli są zastępowani): walczą i rywalizują o wkład
  (obrażenia potworom wydarzenia, rozbite skały); bez gracza wydarzenie rozstrzyga się samo. Na koniec ranking
  i nagrody wg miejsca: skrzynia z łupem na miejscu, sława gildii, **Znaki Zwycięstwa** (`victory_mark`) - wymiana
  u pisarza gildii (`VillageServices.MARK_OFFERS`: kamień, runy, kamień miłosierdzia, plecak, Serce Kryształu, legenda).
- [x] **Wydarzenia w świecie, etap 2** (`WorldEvents.WEIGHTS` - losowanie z wagami):
  - **World bossy** (`scripts/world_boss.gd`, sceny `scenes/world_boss_*.tscn`, grafiki z PixelLab przez
    `tools/world_boss_art.py`): **Żmij Gorynycz** w wyższych krainach (zionięcie ogniem, trzy kule ognia, skok
    z wstrząsem) i **Wij** w niższych (wzrok spod powiek - stożek, szpony korzeni, wezwanie upiorów); ogłaszane minutę
    wcześniej, rzadkie, 8x zdrowia, 3 fazy (66% i 33%), 10-15 podróżników (słabe ciosy - `Traveler.WORLD_BOSS_FACTOR`),
    po porażce gracza nie leczą ran; podwójne Znaki Zwycięstwa, legendy: Kieł Gorynycza, Łuski Żmija, Powieki Wija,
    Korzeń Wija.
  - **Karawana kupiecka**: wóz (`Caravan.waiting`) jedzie odcinkiem drogi krainy i czeka, gdy gracz zostaje w tyle;
    fale potworów idą na wóz; dojazd - skrzynia i premia „Towar z karawany” (kupcy i usługi 15% taniej -
    `Boons.discounted`).
  - **Święto w Ostoi** (`Settlement.start_festival`): girlandy, kolorowe światła, tańce, fajerwerki, podróżnicy przy
    Watrze; premia „Święto” w całym świecie (+20% doświadczenia, +25% złota, 20% taniej); zniżki łączą się do 35%.
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

