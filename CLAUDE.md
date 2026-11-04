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
choć wszystko jest symulowane (patrz „Świat jak w MMO” w „Systemy w grze” i `docs/GDD.md`).

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
- `docs/`: wizja gry (`GDD.md`), zasady grafiki (`ART_SPEC.md`), lista zadań (`ROADMAP.md`), historia zmian
  (`historia.md`), plany drzewek i obrazy referencyjne od autora (`docs/referencje/`). Godot je pomija (plik `.gdignore`).

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

Styl, rozmiary i ustawienia generacji opisuje `docs/ART_SPEC.md`.

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

## Lista zadań, wizja gry i grafika

- `docs/ROADMAP.md` - zgłoszone poprawki („Do poprawy”) i pomysły do zrobienia. Aktualizuj go, gdy autor rzuci nowy
  pomysł albo zgłosi błąd. Zrobiony punkt przenieś (ze szczegółami) do `docs/historia.md`, a tu zostaw najwyżej linię
  w „Systemy w grze”. Przed rozpoczęciem większego punktu dopytaj autora o szczegóły, bo to luźne pomysły, a nie
  gotowe projekty. Szukaj w nim grepem, nie czytaj w całości.
- `docs/GDD.md` - krótka wizja gry: filary, pętla rozgrywki, rozwój postaci, czego w grze nie będzie. Sprawdzaj
  w nim, czy nowy pomysł pasuje do gry; zmieniaj tylko po decyzji autora.
- `docs/ART_SPEC.md` - zasady grafiki (rozmiary, perspektywa, styl, ustawienia PixelLab). Przeczytaj przed
  generowaniem albo rysowaniem nowych grafik.
