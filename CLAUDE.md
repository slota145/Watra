# Watra

Dwuwymiarowy ARPG w pixel-arcie (Godot 4.7, GDScript), osadzony w słowiańskim klimacie. Horda potworów
zalała świat, ostatni ludzie bronią się w osadzie **Ostoja**. Hasło gry: „Dopóki płonie ogień, Ostoja trwa”.
Gracz rozwija postać, zdobywa łup i przemierza krainy w rosnącym zakresie poziomów.

Osoba tworząca grę pracuje na Windowsie (`C:\Users\slota\Documents\claude-game`) i rozmawia po polsku.
Nie programuje na co dzień, więc wyjaśniaj prosto, bez żargonu, i podawaj gotowe komendy do skopiowania.
W odpowiedziach używaj form neutralnych płciowo (np. „możesz”, „wpisz”, zamiast „zrobiłeś/zrobiłaś”).
Poniżej „autor” oznacza tę osobę.

## Styl współpracy

- Bądź miły i entuzjastyczny. Ciesz się razem z autorem postępami w grze.
- Traktuj autora jak partnera w tworzeniu gry. Proponuj kreatywne pomysły na mechaniki, klimat, animacje i drobne
  detale budujące immersję.
- Wyraźnie oddzielaj swoje pomysły od tego, co już ustaliliście. Nie dodawaj nowych funkcji do gry bez zgody autora.
- Bądź przy tym szczery: jeśli pomysł, także autora, jest ryzykowny, zbyt pracochłonny lub nie pasuje do gry, powiedz
  o tym i zaproponuj lepszą opcję.

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
  - `supports.gd`: kamienie wsparcia i gniazda umiejętności (dane; gniazda trzyma `skill_book.gd`), źródło kamieni i krzesiw -
    Mgła Nawii w lochach (`nawia_mist.gd`),
  - `skill_tree.gd`: wspólne drzewko umiejętności (dane w `skill_tree_data.gd` generuje `python tools/shared_tree_draft.py`), `sword_skills.gd`, `bow_skills.gd` i `spell_skills.gd`: umiejętności miecza, łuku i księgi,
    `zone_skills.gd`: umiejętności i węzły stref pośrednich (z dwiema broniami, np. `"melee/bow"`, tagi odmiany - `Skills.HYBRID_TAGS`),
  - `nawia_map.gd`: Mapa Nawii (endgame - węzły-lochy stopni 8-17), okno `scripts/ui/nawia_window.gd`,
    Błogosławieństwo Watry przy kapliczkach `scripts/ui/blessing_window.gd`, drzewko Watry (lochów) `watra_tree.gd`
    (skupiska mechanik porozrzucane po drzewku, 3 zakładki, okno `scripts/ui/watra_tree_window.gd`), bossowie szczytowi `pinnacles.gd` i `pinnacle_boss.gd`,
    Władca Hordy `horde_lord.gd` (Pomrok - stopnie aren),
  - `dungeons.gd`: dane lochów (klimaty, stopnie, modyfikatory, mechaniki), `dungeon.gd`: generator lochu (też lochy na zewnątrz), wystrój `dungeon_decor.gd`
    i `decor_<klimat>.gd`, okno `scripts/ui/dungeon_window.gd`,
  - `herbs.gd`: zioła i mikstury zielarki, `herb.gd`: zioło do zerwania (sadzone w każdej krainie przez `World._place_herbs`),
  - `scripts/ui/`: okna interfejsu (`ui_style.gd` to wspólny styl).
- Sterowanie: WASD, spacja (zryw), F (interakcja), B (portal do miasta w lochu), paski szybkiego wyboru na dole ekranu: umiejętności pod LPM, PPM, Q, E, R, Z, X
  (osobny układ dla każdej broni) i przedmioty pod 1-0 (`scripts/ui/action_bars.gd`, `scripts/ui/hotbar_slot.gd`).
  Pod paskami zdrowia i many ikony efektów (`scripts/ui/status_row.gd`). Tryb deweloperski: Ctrl+Shift+C, potem F1 złoto,
  F2 awans, F3 kamienie, F4 drewno i kamień, F5 wydarzenie w świecie w tej krainie, F6 kamienie wsparcia i krzesiwa.
- `scenes/`: sceny (`main_menu.tscn` startowa, `world.tscn` rozgrywka, potwory, `hud.tscn`).
- `assets/`: grafiki, muzyka, dźwięki.
- `pixellab_src/`: surowe grafiki z PixelLab, `sfx_src/`: surowe nagrania dźwięków (Godot je pomija).
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
Argumenty: plik, kraina, kafelek x i y środka kadru, przybliżenie (0.32 to około 160x90 kafelków), opcjonalnie ziarno
(dla krainy `dungeon` po ziarnie klimat i stopień). Zrzut każdej komnaty lochu osobno:
`SCRIPT=tools/dungeon_shots.gd tools/screenshot.sh /tmp/kopalnia mine 7 3 0.8` (prefiks, klimat, ziarno, stopień, przybliżenie).
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

Zanim wydasz generacje (autor ma ograniczony limit miesięczny):
- najpierw sprawdź, co już jest: grafiki w `assets/` (także z innych krain - np. Winnica satyrów wzięła wioskę satyrów
  z Turni, klify gór i drzewa lasu), niewykorzystane paczki na PixelLabie (`list_objects`, `list_topdown_tilesets`;
  identyfikatory użytych są w `pixellab_src/**/ids.json`) i saldo (`get_balance`); policz koszt i pokaż go autorowi;
- ceny: paczka 16 obiektów 64 px (`create_1_direction_object`) - 10 generacji, paczka 4 obiektów 128 px - 10,
  zestaw kafelków Wang 64 px (tryb pro) - 25, animacja obiektu 8 klatek - 2; przy wątpliwościach pytaj `search_help`
  (darmowe) zamiast czytać całą dokumentację API;
- kandydatki w paczce bywają przesunięte między klatkami (obiekt zaczyna się w jednej, kończy w następnej) - wtedy
  tnij z pasa sklejonych klatek (`strip_part` w `tools/dungeon_props.py`).

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
- U autora po samym `git pull` gra się nie uruchamia (nieaktualny folder `.godot`: brak nowych klas i grafik).
  Polecaj `powershell -ExecutionPolicy Bypass -File aktualizuj.ps1` (pull + import zasobów; Godot autora:
  `C:\Godot_v4.7.2-stable_win64.exe\` - to folder z plikami `.exe` w środku).

## Systemy w grze

Skrót; szczegóły każdego zrobionego punktu (pliki, funkcje, liczby) są w `docs/historia.md` - szukaj w nim grepem.

- **Żywioły:** rodzaje obrażeń zadawanych graczowi (fizyczne, ogień, lód, pioruny, Nawia - `scripts/elements.gd`),
  odporności gracza z przedmiotów i drzewka (`CharacterStats.resistance`, sufit 75%, z węzłów maksymalnej odporności do 85%), kara odporności na Mapie Nawii (`Elements.penalty`),
  żywioł ataku potwora wg sceny (`Elements.MONSTERS`, `Goblin.element`), odporności i wrażliwości potworów
  (`Elements.MONSTER_RESIST`, `Goblin.resistances`), premie obrażeń żywiołów i przebicie odporności, żywioły
  w modyfikatorach lochów, bożkach i elitach (`Elements.apply_dungeon`, `Elements.added`).
- **Walka i postać:** wspólne drzewko umiejętności wszystkich broni ze strefami pośrednimi i dwiema autostradami dookoła
  (`skill_tree.gd`, `skill_tree_data.gd`, `sword_skills.gd`, `bow_skills.gd`, `spell_skills.gd`, okno K), punkty umiejętności z paska umiejętności i poziomy 1-20 (`SkillBook.skill_xp`,
  `Skills.LEVEL_POINTS`), tagi umiejętności (`Skills.TAGS`) i atrybuty dające % obrażeń umiejętnościom z ich tagiem
  (`CharacterStats.attribute_damage`), kamienie wsparcia w gniazdach umiejętności (`supports.gd`, znacznik umiejętności
  w `Skills.tags` - `Skills.skill_of`), combo (`Skills.COMBOS`, kilku poprzedników - `Player.combo_after`), paski szybkiego wyboru (`hotbar.gd`), ikony efektów (`status_effects.gd`);
  zryw, Mgnienie i teleport przeskakują przeszkody, zatrzymuje je tylko granica (`BOUNDS_LAYER`, `Player.free_landing`);
  aury rezerwujące manę z każdą bronią (`aura_data.gd` - liczby, `auras.gd` - działanie, `SkillBook.auras`),
  stali przywołańcy rezerwujący manę - Wataha, Błędne Ogniki, Wierny tropiciel (`summon_data.gd`, `summons.gd`, `SkillBook.summons`).
- **Efekty:** animacje z kreatora efektów PixelLab (`pixellab_src/vfx/ids.json`, `tools/vfx_art.py`; pomocnicy `SkillEffects`,
  `FxLoop`, `BossFx`, `LegendVfx`, `WorldVfx`, `MonsterFx`, `MiscVfx`).
- **Dźwięki:** `sfx.gd` (`Sfx.SOUNDS`), generatory `tools/sfx_synth.py` i `tools/hit_sfx.py` (trafienia według broni
  i żywiołu z nagrań CC0 w `sfx_src/hits`, wybór w `Player.hit_enemy`).
- **Bossowie:** `boss.gd` (wejście do walki, fazy, śmierć, aura wściekłości), zapowiedzi ataków `telegraph.gd`,
  world bossy `world_boss.gd` (Żmij, Wij).
- **Przedmioty:** łup z losowymi premiami (`loot.gd`, okno tierów z pasmem szczęścia - `Loot.roll_tier`, nazwy składane przy pokazywaniu - `Loot.compose_name`), legendy
  (`legends.gd`, `legendary_effects.gd`), zaklinanie u kowala (`enchanting.gd`), kamienie szlachetne i gniazda (`gems.gd`,
  jubiler Dobromir), esencje legend (`essences.gd`), rzemiosło premii runami (`item_craft.gd`, `ItemCraft.RUNES`), torby (`bags.gd`), pas,
  przedmioty niezidentyfikowane (`unidentified.gd`), filtr łupu w ustawieniach (`Loot.filtered_gold`), encyklopedia (`codex.gd`, klawisz L), talizmany w siatce 4x3
  (`talismans.gd`, `Equipment.talismans`, okno `ui/talisman_window.gd`, wybór nagrody `ui/talisman_offer.gd`).
- **Watra i Ostoja:** Watra z ofiarami, żarem i Darami (`boons.gd`, `ui/watra_window.gd`), budowle osady stawiane za kroki
  zadania głównego (`builds` w `main_quests.gd`, `Settlement.sync_story` - bez okna budowy i kosztów),
  lochy Watry (`dungeon.gd`, `dungeons.gd`) z mechanikami (`Dungeons.MECHANICS`: skrzynie `dungeon_chest.gd`, kapliczki
  `dungeon_shrine.gd`, Kryształ Watry `watra_crystal.gd`, elity `dungeon_elite.gd`, Uroczysko `uroczysko.gd`, Krąg Żertwy
  `zertwa.gd`, Skarbnik `skarbnik.gd`, Mgła Nawii `nawia_mist.gd`) i Ołtarzem Welesa, bożki zmieniające loch (`idols.gd`), portal do miasta (klawisz B, `town_portal.gd`, `Dungeon.portal_state`), zielarstwo (`herbs.gd`).
- **Świat jak w MMO** (po zbudowaniu gildii): podróżnicy (`travelers.gd`, `traveler.gd`), drużyny i prośby o pomoc,
  tryby świata i rywale (`world_modes.gd`, `rival.gd`), rynek (`market.gd`), zlecenia (`bounties.gd`), zadania główne
  (`main_quests.gd`), wydarzenia w świecie (`world_events.gd`, `event_site.gd`).
- **Interfejs:** okna przesuwane za tło i skalowane Ctrl + kółkiem (`ui/window_drag.gd`, ustawienie w `Game.window_layouts`),
  skalowanie interfejsu w ustawieniach (`Game.ui_scale` - obraz rośnie, kamera gracza oddala się o tyle samo).
- **Testy u znajomych:** ekran dla testerów (`ui/tester_window.gd`), zgłoszenia na GitHub (`ui/feedback_window.gd`), numer wersji
  (`application/config/version` w `project.godot`, róg menu), ustawienia eksportu „Windows - testy” (`export_presets.cfg`),
  okno „Twórcy” (`ui/credits_window.gd` - autorzy, źródła dźwięków CC0, licencja Godota; nowe źródło grafik lub dźwięków dopisz tam).
- **Tłumaczenia:** `lang.gd`, `translations/teksty.csv` (pl/en), słowniczek `translations/slowniczek.md`.

## Oszczędzanie tokenów

- Nowy duży temat zaczynaj w nowej sesji - wszystko ważne jest w tym pliku i w `docs/historia.md`.
  Po zakończeniu większego tematu od razu daj autorowi gotowy prompt do nowej sesji na kolejny punkt
  (cel, co już wiadomo, pliki, co dopytać), bez czekania na prośbę.
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

### Zasada ogólna: dużo potworów

- [ ] Domyślnie każde siedlisko potworów ma mieć **dziesiątki, a nawet setki potworów**, jak w miejscach farmienia w Black Desert albo w Path of Exile.
  Wyjątek: siedliska, których projekt wymaga inaczej (np. arena bossa).
  Przy zwiększaniu liczebności sprawdź wydajność (`tests/bench_combat.gd`, `tests/playtest_bot.gd`).
  Potwory w spoczynku, które się nie ruszają, pomijają `move_and_slide` (`scripts/goblin.gd`), żeby setki stojących potworów mało kosztowały.
  Plan uzgodniony z autorem: kraina po krainie (osobny PR), cel 600-800 wrogów na krainę, nowe siedliska z obecnych
  potworów na pustych terenach (z własnym wystrojem i sensem) i gęściej w istniejących. Liczy je `tests/bench_combat.gd`
  („spawns”); koszt rośnie z liczbą wrogów atakujących naraz (największa gromada), nie z liczbą w krainie.
  Zrobione (pomiar z listopada 2026): Gobliński Las 672, Pola Zbożowe 626, Rozlewiska 617, Wietrzne Turnie 637,
  Prastary Las 579, Leśny Cmentarz 682 - wszystkie krainy zrobione, punkt do zamknięcia po ograniu przez autora. Nowe siedliska losuj osobnym ziarnem (jak `FrogPonds`)
  i buduj na końcu, żeby w starych zapisach reszta krainy się nie zmieniła. Przy przebudowie całej krainy podbij
  jej wersję układu (`World.ZONE_LAYOUTS`) - postać ze starego zapisu wróci do kapliczki.
  Walka w największej gromadzie każdej krainy kosztuje średnio 7-8,5 ms na klatkę.
  Walkę z rysowaniem i umiejętnościami mierzy `tests/bench_village.gd` (z oknem, scena na uruchomienie:
  stoi / miecz / ksiega / mgnienie) - wypisuje najwolniejsze klatki z liczbą zabitych i zmianą liczby węzłów.
  Szukając, co kosztuje, mierz kawałki kodu stoperem (`Time.get_ticks_usec`) - profiler Godota działa tylko w edytorze.

### Zgłoszenia z listopada 2026

- [ ] **Gra za łatwa w końcówce** (autor, 3.11.2026): poprawione, czeka na ocenę autora (szczegóły w `docs/historia.md`,
  szukaj „Końcówka gry trudniejsza”): krótsza nietykalność, limit kradzieży życia, odporność potworów na przerwanie
  zamachu i odrzut, słabszy pancerz, dużo mocniejsze potwory ponad 41. poziomem i do 4x więcej potworów w lochach
  najwyższych stopni (etap 2). Pomiar siły postaci z zapisu:
  `godot --headless --path . -s res://tests/endgame_probe.gd -- <zapis.json> <stopień> <sekundy> [full|whirl|flicker|bow|spell|idle|uro] [poziom] [poziom ekwipunku]`. Do ustalenia po ograniu: liczby (`Levels.ENDGAME_*`,
  `LEECH_CAP`), czy umiejętności łuku i księgi też trzeba sprawdzić tym pomiarem.
- [ ] **Za mała gęstość potworów w Uroczyskach** i ogólnie za mało potworów (autor, 3.11.2026): poprawione, czeka na
  ocenę autora - lochy do 4x więcej potworów w najwyższych stopniach, Uroczysko ok. 3x więcej upiorów naraz, gromadami
  (szczegóły w `docs/historia.md`, szukaj „Gęstsze Uroczyska”).


## Pomysły i rzeczy do zrobienia

Aktualizuj tę listę, gdy autor rzuci nowy pomysł. Zrobiony punkt przenieś (ze szczegółami) do `docs/historia.md`,
a tu zostaw najwyżej linię w „Systemy w grze”.
Przed rozpoczęciem większego punktu dopytaj autora o szczegóły, bo to luźne pomysły, a nie gotowe projekty.

### Postać i przedmioty

- [ ] **Dopieszczenie i usystematyzowanie walki** (plan z autorem, listopad 2026; każdy krok osobny PR):
  1. prędkość ataku - zrobione (szukaj „Malejące zyski szybkości” w `docs/historia.md`): malejące zyski i sufit
     +150% (`CharacterStats.speed_gain`), 1% za punkt zręczności / inteligencji, Salwa i Mgnienie z najkrótszym
     odstępem (umiejętności liczą tylko szybkość postaci, bez szybkości broni - do przemyślenia przy statystykach);
  2. tagi umiejętności - zrobione razem z 2b (szukaj „Tagi umiejętności i atrybuty” w `docs/historia.md`):
     `Skills.TAGS` w 4 grupach (rodzaj, forma, obrażenia z „tajemnymi”, atrybut), ikonki z `tools/tag_icons.py`
     w oknie K i na paskach;
  3. nowe premie na tagach - zrobione (szukaj „Krok 3 dopieszczenia walki” i „Żywioły, etap 2” w `docs/historia.md`):
     obrażenia żywiołów, pocisków / ciosów / obszarowe, w czasie, szanse na podpalenie / zamrożenie / porażenie,
     przebicie odporności. Czeka na ocenę autora;
  2b. statystyki jak w Last Epoch - zrobione: +1% obrażeń za punkt atrybutu z tagu (zamiast płaskiego +1), siła -
     redukcja, zręczność - unik 0,4% za punkt (malejące zyski, do 35%), inteligencja - mana, witalność - zdrowie;
     szybkość tylko z broni, przedmiotów i drzewek, umiejętności liczą prędkość broni; darmowy reset w starych zapisach.
     Czeka na ocenę autora;
  4. **gniazda i kamienie wsparcia** (jak w PoE) - etapy 1 i 2 zrobione, czekają na ocenę autora (szukaj „Kamienie wsparcia,
     etap” w `docs/historia.md`): `scripts/supports.gd`, 17 kamieni z poziomami 1-20 (rosną z doświadczeniem postaci
     w gnieździe, 3 takie same łączą się w 1 o 2 poziomy wyższy), gniazda w `SkillBook.supports` (1-4 Krzesiwem Nawii
     za 1/2/4/8, 5. Wielkim Krzesiwem), bez zwykłego ataku, bez rynku; okno K, tryb deweloperski F6.
     Etap 2: **Mgła Nawii** (`scripts/nawia_mist.gd`, stałe `MIST_*` w `Dungeons`) - mechanika lochów, jedyne źródło
     kamieni i krzesiw (Wielkie Krzesiwo od gęstości 8 i ze skarbców bogów); zwykła gałąź mechaniki w drzewku Watry
     już jest. Etap 3 zrobiony (szukaj „Kamienie wsparcia, etap 3”): własne węzły Mgły w drzewku Watry
     (`WatraTree.EXTENSIONS`, `Dungeons.mist_rules`) i Bożek Mgły. Liczby Mgły autor po ograniu zostawił bez zmian.
     Czeka na ocenę autora.
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
- [ ] **Wspólne drzewko umiejętności, aury, combo i przebudzenia** (burza mózgów z autorem, listopad 2026) - pełny
  plan w `docs/plan_drzewek.md`. Ustalone: jedno wspólne drzewko 200-250 węzłów (strony siła / zręczność /
  inteligencja, strefy pośrednie, skupiska tematyczne, wyróżnione umiejętności aktywne), umiejętności nadal wymagają
  swojej broni, klas nie ma - gracz wybiera konkretne przebudzenie (pomysły: magia cieni z kosą, chainblade'y,
  bojowy mag z glewią / runicznym rapierem; przebudzenie przez zadanie u żercy Wszebora, jedna ulepszana broń
  przebudzenia, broń w ręku zmienia się sama), nekromancja jako gałąź magii, nowe combo, drzewko lochów od nowa.
  Krok 2 zrobiony, czeka na ocenę autora (szukaj „Wspólne drzewko umiejętności, krok 2” w `docs/historia.md`): drzewko
  w grze z obecnymi umiejętnościami, nowe umiejętności i nowe węzły kluczowe to puste miejsca; stare zapisy -
  zwrot wszystkich punktów, dodatkowo 1 punkt umiejętności co 2 poziomy postaci. Krok 3 (aury i rezerwacja many) zrobiony,
  czeka na ocenę autora (szukaj „Aury rezerwujące manę - krok 3”). Krok 4 (nowe combo; Półksiężyc, Szybka salwa
  i Fala piorunów jako zwykłe umiejętności) zrobiony, czeka na ocenę autora (szukaj „Nowe combo - krok 4”).
  Krok 5 (nowe węzły kluczowe i nowe umiejętności) idzie strona po stronie: strony siły, zręczności i inteligencji
  oraz strefy pośrednie zrobione, czekają na ocenę autora (szukaj „Krok 5 wspólnego drzewka, strona siły”, „…, strona
  zręczności”, „…, strona inteligencji” i „…, strefy pośrednie”) - Wilczy Kieł, Ryk Tura, Skok Niedźwiedzia, Ostatni
  Bastion, Strzała Żmija, Rozszczepiona Strzała, Kolczatka, Łowca w Cieniu, Szał Bitewny, Ściana Ognia, Lodowy Pancerz,
  Mistrz Żywiołów, umiejętności z dwiema broniami (Ciśnięte Noże, Strzała Gromu, Zaklęte Ostrze - `scripts/zone_skills.gd`),
  Żelazna Wola i węzły znaczące; ikony z PixelLab (`tools/tree_step5_icons.py`). Przywołania (Wataha, Błędne Ogniki,
  Wierny tropiciel, Przewodnik stada, Wierne ogniki) też zrobione, czekają na ocenę autora (szukaj „…, przywołania”) -
  krok 5 skończony, w drzewku nie ma już pustych miejsc. Krok 6 (nowe drzewko lochów) zrobiony, czeka na ocenę autora
  (szukaj „Nowe drzewko lochów” w `docs/historia.md`). Dalej krok 7 (przebudzenia).
- [ ] **Modyfikacja premii tylko runami** (decyzja autora, listopad 2026): wszystkie sposoby zmiany premii
  (afiksów) przedmiotów mają działać przez runy - przedmioty-waluty jak orby w Path of Exile. Zrobione razem
  z Uroczyskiem (szukaj „Mechaniki w lochach, etap 3”): każde działanie warsztatu kowala zużywa swoją runę
  (`ItemCraft.ACTIONS`, `ItemCraft.RUNES`), trofea już tam nie idą. Do ustalenia: kolejne runy (np. jak orby
  wyższego poziomu), czy runy mają wypadać też poza lochami, ewentualne grafiki run z PixelLab zamiast przebarwień.
- [ ] **Animacje postaci z bronią** (listopad 2026): broń nie leży stabilnie w dłoni, za mało animacji ataków.
  Ustalenia z autorem: porządnie animowany tylko **Wojciech** (reszta może zostać NPC), styl **zamaszysty jak w BDO**,
  nowe pozy ciała (etap 4) na później. Etap 1 zrobiony (szczegóły w `docs/historia.md`, szukaj „Etap 1 animacji”):
  ataki Wojciecha po 8 klatek z ruchów szkieletowych PixelLab, broń w dłoni w każdej klatce ataku. Etap 2 zrobiony
  (szukaj „Etap 2 animacji”): seria 3 cięć w zwykłych atakach i własne ruchy Rozpłatania, Rozłupania Ziemi, Szarży,
  Półksiężyca i Młynka; zrzuty klatek ataków w grze robi `tools/anim_shots.gd`. Etap 3 zrobiony (szukaj „Etap 3 animacji”):
  cięciwa łuku rysowana w kodzie (`BowString`, `tools/bow_strings.py`) i własne ruchy umiejętności łuku i księgi
  (`Player.SKILL_MOVES`, chwyt ze znaczników stanu „Znacznik” w PixelLab). Etap 4 zrobiony (szukaj „Etap 4 animacji”):
  oddech w spoczynku, chód po 8 klatek, zryw i upadek przy śmierci. Punkt do zamknięcia po ograniu przez autora.
- [ ] **Aury rezerwujące manę**: zrobione, czekają na ocenę autora (szukaj „Aury rezerwujące manę - krok 3”
  w `docs/historia.md`). Do ustalenia po ograniu: liczby (`scripts/aura_data.gd`), gniazda na kamienie wsparcia
  dla aur, animacje ataków aur żywiołów z kreatora efektów PixelLab.
- [ ] **Bogatsze strefy pośrednie, autostrady i odporności we wspólnym drzewku** (pomysł autora, listopad 2026): zrobione,
  czeka na ocenę autora (szukaj „Bogatsze strefy pośrednie” w `docs/historia.md`): po 2 nowe skupiska w każdej strefie,
  skupiska odporności, autostrada wewnętrzna i zewnętrzna (`RINGS` w `tools/shared_tree_draft.py`), maksymalna odporność
  z węzłów (+2%, limit 85% - `CharacterStats.max_resistance`). Do zrobienia później: więcej umiejętności łączonych
  w strefach, maksymalna odporność także z legend albo talizmanów.
- [ ] **Przebudowa rozwoju postaci**: zastąpiona planem wspólnego drzewka (`docs/plan_drzewek.md`). Osobne punkty
  statystyk (2 za awans) i umiejętności (pasek) już są - punkt niżej.
- [ ] **Punkty umiejętności z osobnego paska doświadczenia** (pomysł autora, listopad 2026; jak w BDO): zrobione,
  czeka na ocenę autora (szukaj „Pasek umiejętności” w `docs/historia.md`): pasek `SkillBook.skill_xp` z progami
  `Skills.SKILL_XP_BANDS`, poziomy umiejętności 1-20 za punkty (`Skills.LEVEL_POINTS` 1/2/3/5, wzory przez
  `Skills.power` i `Skills.count`), 2 punkty statystyk za awans, cofanie za złoto (`Skills.REFUND_GOLD_PER_LEVEL`),
  stare zapisy przelicza `SkillBook.migrate_old` (zwrot złota i punktów). Do ustalenia po ograniu: progi paska,
  cena cofania, siła poziomów 6-20, punkty na start.

### Watra i Ostoja

- [ ] **Kryształ Watry** (autor, listopad 2026): na razie zostaje obrona przed falami (etap 6 - fale rosną ze stopniem
  lochu); nowy sposób działania do ustalenia z autorem później.
- [ ] Pomysły do Kryształu Watry: komnata z kowadłem w lochu (jednorazowo wyższa szansa zaklinania), kolejne
  warianty zdarzenia.
- [ ] **Mechaniki w lochach - powód, żeby robić lochy** (plan z autorem, listopad 2026; najpierw mechaniki, potem
  atlas, nowe klimaty lochów odłożone). W każdym lochu co najmniej 1 mechanika, z małą szansą druga i trzecia; proste
  częściej, duże rzadziej; drzewko rozwoju Watry podnosi szanse (aż do 100% na wybraną mechanikę) i wzmacnia
  mechaniki. Każda większa mechanika ma własny, unikalny łup:
  - **Skrzynki** (jak strongboxy) - zwykły łup, czasem z cechami (pułapka, więcej przedmiotów);
  - **Kapliczki** - buff na czas lochu;
  - **Elitarne potwory** z cechami (wzmacniają wrogów wokół) - więcej i lepszego łupu;
  - **Uroczysko** - dotknięty kamień otwiera rosnący krąg innego świata pełen upiorów, na czas - łup: **runy**
    (patrz „Modyfikacja premii tylko runami”);
  - **Krąg Żertwy** (nie „Ołtarz Welesa” - ta nazwa jest już zajęta przez esencje) - zabici wrogowie w kręgu dają
    daninę, za nią wybór nagrody - łup: **talizmany**;
  - **Skarbnik** - nagroda z ryzykiem (jak Ultimatum w PoE): zrobiony (etap 5), szczegóły w `docs/historia.md`;
  - **Kryształ Watry** - jedyne źródło **kamieni zaklinania** w lochach (etap 6; skarbiec daje już tylko kamienie
    uświęcone), rynek i nagroda zadania głównego zostają jako drogie wyjście awaryjne; Kryształ wypada często;
  - **Mgła Nawii** - loch coraz trudniejszy i hojniejszy z każdą minutą - łup: **kamienie wsparcia i krzesiwa**
    (etap 7, szukaj „Kamienie wsparcia, etap 2” w `docs/historia.md`);
  - pomysły na później: **Kurhan** (wysadzanie kurhanów prochem, artefakty wymieniane u handlarza w Ostoi), **Łowy** (chwytanie
    rzadkich bestii do zagrody w Ostoi - składniki rzemiosła).
  Odrzucone przez autora: zbłąkany wędrowiec, Noc Kupały, Zakład z biesem, Licho, Dziady.
  Etap 1 zrobiony, czeka na ocenę autora (szczegóły w `docs/historia.md`, szukaj „Mechaniki w lochach, etap 1”):
  losowanie mechanik (`Dungeons.MECHANICS`, `roll_mechanics` z miejscem na premie drzewka Watry), skrzynie
  (`dungeon_chest.gd`), kapliczki (`dungeon_shrine.gd`), Kryształ w puli, mniej kamieni zaklinania ze skarbca.
  Etap 2 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 2”): elitarne potwory z cechami
  (`dungeon_elite.gd`, `Dungeons.ELITE_TRAITS` - aury, obrona, żywioły, przywołanie).
  Etap 3 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 3”): Uroczysko (`uroczysko.gd`, stałe
  `URO_*` w `Dungeons`) - krąg upiorów rosnący z zabójstwami, nagroda - runy.
  Etap 4 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 4”): Krąg Żertwy (`zertwa.gd`, stałe
  `ZER_*` w `Dungeons`) - danina za wrogów zabitych w kręgu, nagroda - wybór 1 z 3 talizmanów.
  Etap 5 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 5”): Skarbnik (`skarbnik.gd`,
  `skarbnik_offer.gd`, stałe `SKA_*` w `Dungeons`) - oferta, Wzmocnij / Przelosuj z falami, księga ofert przeciw
  wczytywaniu zapisu, sufit tierów; przy okazji przegląd tierów T1 (`tests/tier_sim.gd`, nowe `Loot.TIER_VALUES`).
  Do ustalenia po ograniu: liczby fal i wrogów, szansa na Kości, czy Skarbnik ma mieć własną grafikę.
  Etap 6 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 6”): obrona Kryształu zostaje, fale rosną
  ze stopniem lochu (`WatraCrystal.wave_count`), skarbiec strażnika bez kamieni zaklinających.
  Etap 7 zrobiony, czeka na ocenę autora: Mgła Nawii (`nawia_mist.gd`) - Mglisty Słup, gęstość co minutę do 10,
  Skrzynia Mgły; Kryształ Watry dostał wagę 7,8 (był 7), żeby po dojściu Mgły trafiał się tak samo często.
- [ ] **Bożki** (jak skaraby w PoE): zrobione, czekają na ocenę autora (szczegóły w `docs/historia.md`, szukaj „Bożki”):
  `scripts/idols.gd`, 33 rodzaje (3 rzadkości, 2 prastare), sloty w oknie lochów (2, więcej z poziomem Watry), zużywają
  się przy wejściu, bożki potworów i łupu mogą być w kilku slotach. Węzły bożków w drzewku Watry zrobione (gałąź „Bożki”).
  Do ustalenia po ograniu: szansa wypadania, siła rodzajów,
  czy ikony mają być z PixelLab (paczka 16 obiektów - 10 generacji).
- [ ] **Talizmany** (jak idole w Last Epoch): zrobione razem z Kręgiem Żertwy (szukaj „Mechaniki w lochach, etap 4”) -
  siatka 4x3, kształty 1x1, 1x2, 2x1, 2x2, magiczne z premiami, rzadkie z efektem legendy. Do ustalenia: rosnąca
  siatka (poziom, drzewko Watry), własne efekty talizmanów zamiast efektów legend (np. ognista tarcza przy niskim
  zdrowiu), grafiki z PixelLab zamiast rysowanych w kodzie, rzemiosło talizmanów runami.
- [ ] **Mapa Nawii - endgame jak atlas w PoE** (ustalenia z autorem, listopad 2026; przed drzewkiem Watry albo razem
  z nim). Z PoE bierzemy szkielet (mapa węzłów-lochów, przejście odsłania sąsiednie, rosnące stopnie, punkty do
  drzewka, bossowie szczytowi), wygląd i nazwy własne, słowiańskie:
  - osobna **Mapa Nawii** (zaświaty wylane na świat przez Hordę) w oknie Watry; węzły to lochy z klimatem i stopniem;
  - **wpływ na świat**: oczyszczone obszary mapy zdejmują spaczenie z prawdziwych krain (premie, obozy - łączy się
    z punktem „Budowa i rozbudowa obozów” w „Świat”);
  - **wejście bez kosztów** (ograniczeniem jest tylko trudność); bożki nadal wkładane przed wejściem;
  - **dzisiejsze lochy zostają do ~40. poziomu** (nauka mechanik, rozwój postaci); po 40. poziomie / Cmentarzu
    otwiera się mapa z wyższymi stopniami;
  - **bossowie szczytowi**: słowiańscy bogowie (np. Weles, Marzanna, Czarnobóg), obce bogi (grecki, nordycki,
    egipski - patrz „Obce mitologie”) i Władca Hordy jako ostateczny boss;
  - **ustalone (listopad 2026)**: mapa **duża, 80+ węzłów** jak pełny atlas PoE, 6 obszarów (po jednym na krainę
    świata), węzeł przejdziony po pokonaniu strażnika, wtedy odsłania sąsiednie (mgła); **10 nowych stopni 8-17,
    poziomy potworów 45-90 co 5** (bossowie szczytowi ~92-95, pełny zakres łupu); oczyszczony obszar daje w swojej
    krainie **premię** (łup, doświadczenie, kraina bez spaczenia na mapie świata), **miejsce na obóz** i **wariant
    endgame krainy** (potwory na poziomie mapy - stare krainy znów do farmienia); **1 punkt drzewka Watry za każdy
    nowy węzeł** (bossowie szczytowi więcej; punkty zbierane, zanim drzewko powstanie);
  - kolejność: 1) okno mapy, węzły, odsłanianie, stopnie 8-17 z balansem (`tests/balance_sim.gd`), 2) oczyszczanie
    krain (Błogosławieństwo Watry), 3) drzewko Watry (razem z węzłami bożków), 4) bossowie szczytowi po jednym;
  - etap 1 zrobiony, czeka na ocenę autora (szczegóły w `docs/historia.md`, szukaj „Mapa Nawii, etap 1”): mapa
    losowana z ziarna zapisu (`scripts/nawia_map.gd`, 90 węzłów), okno `ui/nawia_window.gd` (przycisk „Nawia” w oknie
    Watry, rysowane w kodzie - ładna mapa z PixelLab później), stopnie 8-17 (`Dungeons.TIER_LEVELS`, `BASE_TIERS`,
    `power_tier`), balans końcówki `Levels.ENDGAME_*`, postęp i punkty Watry w `Boons.nawia_cleared`;
  - etap 2 zrobiony, czeka na ocenę autora (szukaj „Mapa Nawii, etap 2”): zamiast spaczenia **Błogosławieństwo Watry**
    - F przy kapliczce krainy (od 1. oczyszczonego węzła jej obszaru) podnosi potwory do poziomu najtrudniejszego
    oczyszczonego węzła, łup i doświadczenie +2% za węzeł (`NawiaMap.blessing_*`, `Boons.nawia_blessed`,
    `ui/blessing_window.gd`, `Levels.zone_range`); miejsce na obóz odłożone do punktu o obozach;
  - etap 3 zrobiony (szukaj „Mapa Nawii, etap 3”): **drzewko Watry** (`scripts/watra_tree.gd`, okno
    `ui/watra_tree_window.gd`), 3 zakładki z osobnymi pulami punktów, cofanie za złoto; premie idą do lochu
    w `config["tree"]`;
  - etap 4 zrobiony, czeka na ocenę autora (szukaj „Mapa Nawii, etap 4”): **bossowie szczytowi** Weles, Marzanna,
    Czarnobóg (`scripts/pinnacles.gd`, `scripts/pinnacle_boss.gd`) - areny za 4 fragmenty kluczy z węzłów, serca
    na legendy, pasy w stylu Mageblooda i Headhuntera (Pas Wiecznych Ziół, Pas Łowcy Dusz, 10 serc);
  - etap 5 zrobiony, czeka na ocenę autora (szukaj „Mapa Nawii, etap 5”): **Władca Hordy** (`scripts/horde_lord.gd`) -
    wejście za serce każdego boga, 4 fazy z cieniami bogów i falami Hordy, legendy Władcy, Pas Zimowego Oddechu
    (Marzanna), tytuł „Pogromca Hordy”, posąg w Ostoi i stopnie **Pomroku** I-X dla wszystkich aren;
  - **drzewko Watry od nowa** zrobione, czeka na ocenę autora (szukaj „Nowe drzewko lochów” w `docs/historia.md`):
    ok. 500 węzłów, 4 skupiska każdej mechaniki porozrzucane po drzewku, ścieżki neutralnych węzłów, węzły zmieniające
    mechaniki (`Dungeon.tree_value`), podwójne mechaniki, węzły kluczowe z ceną, zwrot punktów Watry;
  - do zrobienia: obce bogi; do ustalenia po ograniu: siła bogów i Władcy, szanse na fragmenty i pasy, liczby
    Pomroku, liczby w drzewku Watry, ewentualne ikony węzłów z PixelLab. Punkty Watry podniesione (szukaj „Więcej punktów
    Watry” w `docs/historia.md`): 2 za węzeł, 5 za boga, 10 za Władcę - ok. 205 na ~500 węzłów drzewka.
- [ ] **Obce mitologie jako odległe królestwa** (luźny pomysł autora): świat zostaje słowiański, a królestwa grecki,
  nordycki, egipski tylko w końcówce gry (np. wrota w atlasie, najeźdźcy przez płomienie Watry), każde jako mały
  obszar z bossem szczytowym - obcym bogiem; tłumaczy hydrę i satyry. Na pinnacle nadają się też słowiańscy bogowie.
- [ ] Pomysły na rozwój lochów: kolejne klimaty (lodowe jaskinie, wulkaniczna kuźnia, krasnoludzkie ruiny), kilka pięter
  w dół z coraz lepszym łupem, elitarne potwory z własnymi cechami, pułapki i zagadki, własni strażnicy lochów
  zamiast bossów z krain, sekretne komnaty, zlecenia gildii na lochy.
- [ ] **Lochy ładne i bogate w środku** (listopad 2026): dokładniej przyjrzeć się wystrojowi lochów.
  Ustalenia z autorem po zrzutach (2026-11-02): razi wszystko - mało rodzajów lochów, monotonne ściany, jednolite
  podłogi, komnaty jako gołe prostokąty, ozdoby sypane losowo zamiast scenek, płaskie światło. Grafiki: PixelLab
  (duże ozdoby, płytki) + kod (nakładki, światło, rozmieszczenie); gdzie pasuje, używać gotowych grafik z krain.
  Kolejność: najpierw odnowić **Katakumby** na próbę, potem resztę podziemnych klimatów, potem nowe lochy
  **na zewnątrz** (granicą woda, drzewa, skarpy, palisada, góry; polany połączone ścieżkami o organicznych
  kształtach): Winnica satyrów (półki skalne i drzewa; grafiki `assets/forest/props/satyr_*`), Oblężony gród
  (palisada, chaty), Wyspy na bagnie (kępy, kładki, brody), Przesmyk w Turniach (wąwozy, półki), Święty gaj / uręba
  (ściana drzew, kręgi kamieni). Każdy klimat może mieć też wariant **otwarty** (połać terenu) z innym bossem niż
  wersja zamknięta.
  Krok 1 (Katakumby) i krok 2 (Kopalnia goblinów: tory, skład prochu, kuźnia, obóz, szyb z windą, zawał, żyła
  kruszcu, tron wodza) i krok 3 (Zatopione podziemia - zalana świątynia bogów wody: świątynia, kładki, wraki,
  gniazdo topielców, grota z ognikami, obóz żabołaków, sala rusałek, źródło, tron wodnika) i krok 4 (Pajęcze
  korzenie - dzikie jaskinie: wylęgarnia, spiżarnia, korzenie, grzybnia, sieciowa sala, kryjówka drzewców, obóz
  łowców, pajęczy ołtarz, gniazdo królowej) zrobione, czekają na ocenę autora - szczegóły w `docs/historia.md`
  (szukaj „Wystrój lochów”). Wszystkie podziemne klimaty mają wystrój. Krok 5 (Winnica satyrów - pierwszy loch na
  zewnątrz: polany, kręte ścieżki, granicą klify, ściana drzew i stawy - `Dungeon.outdoor`, `decor_vineyard.gd`) zrobiony,
  czeka na ocenę autora. Krok 6 (Oblężony gród - granicą palisada po gładkim obrysie, `Dungeon._build_palisade`, za nią
  spalone zagrody; `decor_stronghold.gd`) zrobiony, czeka na ocenę autora; dalej Wyspy na bagnie, Przesmyk w Turniach,
  Święty gaj.
  Kolejny klimat: "decor" w `Dungeons.CLIMATES`, skrypt `scripts/decor_<klimat>.gd` (dziedziczy po `DungeonDecor`),
  paczki PixelLab w `pixellab_src/dungeons/` i wpis w `tools/dungeon_props.py`; zrzuty sal: `tools/dungeon_shots.gd`.
- [ ] **Podział lochów na zwykłe i endgame'owe** (listopad 2026): zwykłe jak dziś; endgame'owe z przedmiotami w Watrze
  (skaraby), drzewkami lochów i mechanik, losowymi mechanikami i bossami szczytowymi (pinnacle), plus system jak
  atlas w PoE dający namacalny postęp. Wymaga projektu z autorem przed pracą.

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

- [ ] Budowa i rozbudowa obozów w innych krainach, które pasywnie dają surowce albo inne korzyści. Decyzja autora
  (4.11.2026): drewna i kamienia gracz nie musi już zbierać ręcznie - mają je zbierać robotnicy w obozach (jak w BDO),
  a ich ujściem będą np. rangi gildii i Druga Watra.
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

