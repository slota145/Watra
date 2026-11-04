# Historia zmian

Zrobione punkty przeniesione z CLAUDE.md (szczegóły: pliki, funkcje, liczby). Nowe zrobione punkty dopisuj na końcu
odpowiedniej sekcji.

## Postacie i narzędzia (Do poprawy)
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
- [x] Riposta z kreatora efektów (`assets/effects/riposte_guard.png`, `riposte_counter.png`): w czasie zasłony
  zapętlone złote łuki ostrzy krążące wokół postaci (`SwordSkills._ParryRing`, górna połowa za postacią), a kontra -
  ostry błysk zderzenia stali, pełne cięcie dookoła i fala.
- [x] Zew Peruna z kreatora efektów (`assets/effects/war_cry.png`, `war_cry_buff.png`): złoty piorun uderza z nieba
  w postać i powtarza uderzenie, po ziemi rozchodzi się fala z wyładowaniami na cały zasięg strachu; w czasie premii
  wokół postaci trzaskają złote wyładowania. `tools/vfx_art.py` przyjmuje siatkę klatek (`columns` w `ids.json`)
  dla efektów szerszych niż 1024 px w jednym rzędzie.
- [x] Widmowe Ostrza z kreatora efektów (`assets/effects/spectral_blade.png`, `spectral_burst.png`,
  `scripts/spectral_blades.gd`): migoczący widmowy miecz ze smugą drobinek zamiast przyciemnionej broni gracza
  (obracany w kierunku lotu), widmowy rozbłysk przy przywołaniu, dotknięciu i trafieniu wystrzelonym ostrzem.
- [x] Półksiężyc z kreatora efektów (`assets/effects/crescent.png`, `Player._start_crescent`): srebrny sierp
  księżycowego światła na 300 stopni (odbity przy zamachu w drugą stronę - `SkillEffects.sheet_once`, `mirror`),
  wyrzucony w stronę celowania półksiężyc i złoty pył zamiast powiększonego cięcia i biało-pomarańczowego łuku.
- [x] Szarża z kreatora efektów (`assets/effects/lunge.png`, `lunge_start.png`, `lunge_hit.png`,
  `Player._start_lunge`): w trakcie pędu przed mieczem fala powietrza z liniami pędu (zapętlona, obrócona w kierunku
  szarży), na starcie pył spod stóp, na każdym trafionym wrogu błysk przebicia. Niebieskie cienie postaci zostają.
- [x] Zwykły atak mieczem z kreatora efektów (`assets/effects/sword_slash.png` - 5 klatek 64x64 odtwarzanych
  w tempie zamachu, `scenes/player.tscn` - Pivot/Slash): stalowe cięcie z jaśniejszą krawędzią, śladem i błyskami
  zamiast jasnoniebieskiego łuku (`assets/slash.png` z `tools/generate_art.py` nie jest już używany); zwykły atak
  celuje przez `Player._aim_direction` (uwzględnia `aim_override`, jak umiejętności).
  Na każdym wrogu trafionym cięciem (zwykły atak, Półksiężyc - `Player._hit_enemies_in_arc`) błysk trafienia
  (`assets/effects/sword_hit.png`: ukośny ślad ostrza, gwiazdka, odpryski).
- [x] Łuk z kreatora efektów (`assets/effects/bow_*.png`, wpisy "bow_*" w `pixellab_src/vfx/ids.json`, stałe w
  `BowSkills`): każda strzała z łuku ma zapętloną smugę (`BowSkills.arrow_trail`, węzeł "Trail" pocisku - zielona
  w czasie Jadowych Grotów, złoto-zielona przy Strzale tropiącej, płonąca przy Grocie Swaroga) i błysk trafienia;
  wystrzał Salwy, Szybkiej salwy, Odskoku i Balisty (`BowSkills.release`); żar napinania i wybuch Grotu Swaroga;
  znacznik i uderzenia Deszczu Strzał; trawa i pył Odskoku; Sidła jako zapętlona pętla z pnączy (zamiast obrazków),
  zatrzaśnięcie - oplatające pnącza; smuga nurkowania i szpony Sokoła (sokół i balista zostają); jad Jadowych
  Grotów i bąble zatrucia; podmuch Strzały Wichru (w combo trzy wachlarzem). Zapętlone efekty -
  `SkillEffects.looping` (AnimatedSprite2D bez skryptu).
- [x] Efekty księgi magii z kreatora efektów (kolor żywiołu; wpisy w `pixellab_src/vfx/ids.json`, `scripts/fx_loop.gd` -
  zapętlony efekt): animowany magiczny pocisk z trafieniem, płonąca Kula ognia (w dłoniach i w locie) i nowy wybuch ognia
  (też Spadająca Gwiazda - `Projectile.FX`, `fx_kind`, `_explode`), złoto-niebieskie pioruny rozciągane między punktami
  (`SpellSkills.lightning` / `zap_flash`: Łańcuch błyskawic, Burza Peruna - piorun z nieba, Kula Piorunów), stożek Fali
  piorunów, lodowy grot Włóczni Marzanny z rozpryskiem, śnieżyca Zamieci, żywa Kula Piorunów z wybuchem, płonący kamień
  Spadającej Gwiazdy, fioletowa mgła Kroku, bańka z heksagonów Tarczy Many, Kamień Runiczny z kręgiem run. Grafiki
  `assets/spell/` (włócznia, kula, gwiazda, kamień) zastąpione animacjami (`frost_lance.png` i `meteor.png` zostają
  tylko jako obrazek zapasowy pocisku).
- [x] Wspólne efekty bossów (`scripts/boss.gd`, `assets/effects/boss_*.png`): ryk z falą przy wejściu do walki
  (`_fx_engage`), wybuch z dymem i duszami przy śmierci (`_fx_death`), wybuch mocy przy zmianie fazy (`_fx_phase`)
  i zapętlona aura wściekłości (`enraged` - polowanie na bossa, albo poniżej 30% zdrowia w walce; tylko wygląd);
  podklasy podmieniają je własnymi wersjami. Zapowiedzi ataków (`scripts/telegraph.gd`) mają znaki ruchu (kręgi
  zbiegające się do środka koła, strzałki na pasie, łuki w stożku) i błysk tuż przed uderzeniem.
- [x] Ataki bossów Goblińskiego Lasu, Pól Zbożowych i bestii Prastarego Lasu z kreatora efektów (`scripts/boss_fx.gd` -
  `BossFx`, wpisy `boss_slam`, `boss_claw`, `boss_cleave`, `bies_smoke`, `bies_roar`, `bomb_blast`, `acid_splash`,
  `worm_burrow` w `ids.json`): uderzenia w ziemię (Gruzłog, Szarokieł, bestie, Pożeracz Pól, lądowanie Bombardiera),
  krwawe pazury i cięcie pazurami w stożku, pył za szarżami, cienisty dym i ryk Biesa, wybuch każdej bomby kobolda
  i rozprysk kwasu (`KoboldBomb._explode` - także pociski kwasu Hydry), fontanna ziemi Pożeracza przy zakopywaniu,
  wynurzaniu, przywołaniu i wejściu do walki, kamienne kolce trzęsienia (efekt Rozłupania Ziemi).
- [x] Bossowie Rozlewisk i Turni z kreatora efektów (`assets/effects/bulgor_*`, `wodnik_*`, `hydra_*`, `eagle_*`,
  `gryf_*`, `satyr_*`): Bulgor - plusk wody i błota przy lądowaniu i trafieniu językiem; Wodnik - zapętlony wir
  (zamiast rysowanych kręgów), fala przetaczająca się pasem, plusk przy wynurzeniu (własne `_fx_engage`) i przy
  topielcach; Hydra - kłapnięcie szczęk na końcach pasów kąsania, trujący oddech (klin), fala bagiennej wody,
  przy odrastaniu `_fx_phase`; Gromoskrzydły - piorun z nieba (`storm_strike`) z trafieniem, smuga nurkowania,
  podmuch z piórami, piorun w orła przy wejściu do walki; Gryf - stożek wiatru (`bow_wind_cone`), złote szpony
  z pyłem, zapętlona trąba powietrzna (`GryfTornado`), krzyk - złote fale dźwięku; Faun-Król - fletnia (fale
  melodii z nutami), pnącza spod ziemi, tupnięcie z pęknięciami i pyłem.
- [x] Efekty ataków bossów z kreatora efektów PixelLab (`tools/vfx_art.py`): Leszy (korzenie, wir liści), Królowa Pająków
  (sieć, lądowanie z jadem, pękające jaja), Mortan (kościane kolce, promień duszy, krąg wezwania, dym mgnienia, słup dusz
  przy śmierci), Gnilec (zamach, miażdżenie i skok, żółć, ryk), Żmij (zionięcie, spadające kule ognia, lądowanie
  z ognistym kręgiem, ogniste słupy) i Wij (wzrok spod powiek, kłąb mroku, korzenie szponów); własne `_fx_engage` /
  `_fx_phase` / `_fx_death` tam, gdzie pasują.
- [x] Królowa Pająków nie stoi już do gracza tyłem (na obrotach z PixelLab patrzyła w lewo - `tools/pixellab_sheets.py`,
  `creature(..., mirror=True)` odbija klatki); mniejsze kokony z uwięzionymi ludźmi (`pair(..., scale=0.6)`, 33 zamiast
  55 px) i owinięte ofiary (`PROP_SCALE` - połowa, 30 zamiast 61 px) - człowiek mniej więcej wzrostu postaci.
- [x] Efekty legendarnych przedmiotów z kreatora efektów (`scripts/legend_vfx.gd` - `LegendVfx`, wpisy "legend_*"
  w `ids.json`): złota fala uderzeniowa (Sygnet Gruzłoga), fala wody (Oko Przypływu, Płaszcz Topielca) i złota fala
  dźwięku z nutami (Berło) w stożku, trująca chmura (Łuski Hydry), półksiężyc wiatru (Ostrze Gryfa), wachlarz piór,
  sieć, leczenie krwią i liśćmi, krążące i pękające kości (Kościana Korona); reszta legend używa efektów swoich
  bossów i umiejętności (piorun z nieba i łańcuch błyskawic, wir Wodnika, korzenie Leszego, dym i ryk Biesa, kwas,
  wybuch bomby, fontanna Czerwia, krąg dusz Mortana, uderzenie Gnilca, pnącza i fletnia Fauna, trąba Gryfa, kula
  ognia - `LegendFx`); echo (Kieł Alfy) barwi efekt na niebiesko. Pęknięcia ziemi (`ground_crack`) i język Bulgora zostają.
- [x] Efekty świata i interfejsu z kreatora efektów (`scripts/world_vfx.gd` - `WorldVfx`, wpisy `burning_*`, `boulder_break`,
  `firework_*`, `loot_*`, `enchant_*` w `ids.json`): płonąca ziemia i trujący opar jako zapętlone kręgi płomieni
  (`BurningPatch`, skalowane do promienia), odłamki i pył rozbitego głazu, fajerwerki na Święcie (kwiat iskier albo
  rakieta, białe rysunki barwione losowym kolorem), zapętlony błysk łupu na ziemi (niebieski - magiczny, złoty - rzadki;
  wspólne klatki, więc setki łupów mało kosztują) i iskry legendy w słupie światła, złoty błysk w powiadomieniu o łupie,
  w oknie zaklinania krążące złote runy w trakcie, złoty rozbłysk z gwiazdkami po sukcesie i czerwone pęknięcie z dymem
  po porażce. Mgła, muchy, zarodniki, dym z kominów, para i iskierki ziół zostają.
- [x] Efekty zwykłych potworów z kreatora efektów (`scripts/monster_fx.gd` - `MonsterFx`, wpisy "mob_*" w `ids.json`):
  przy śmierci każdego potwora jeden krótki obłoczek w jego kolorze (`map_color`, losowo odbity - bez cząsteczek,
  bo padają setkami), rozsypane kości szkieletu, drzazgi drzewca i prastarego drzewa; plucie żabołaków i kula wody
  topielicy jako zapętlona animacja, pociski z drzewcem ze smugą, rozpryski trafień; piorun szamana ptakoludzi
  (`storm_strike`), uderzenie osiłka (`BossFx.slam`), pył kopca i fontanna ziemi robaka, szkielet wygrzebujący się
  w pyle, plusk utopca, nuty rusałki, wybuch ognika.
- [x] Pozostałe stare efekty z kreatora efektów (`scripts/misc_vfx.gd` - `MiscVfx`, wpisy `misc_*`, `meteor_*`,
  `crystal_shatter`, `traveler_flame` w `ids.json`): iskry, kłąb dymu, odłamki i fala po ziemi narysowane w szarościach
  i barwione kolorem źródła (zamiast `SkillEffects.spark` / `shockwave` i cząsteczek) - sojusznicy i przywołańcy,
  `Boss._burst` / `_debris`, wydarzenia w świecie, Kryształ Watry, drobne iskry umiejętności; krąg przyzwania bossa
  (`SummonCircle`), ognisty ogon i uderzenie meteorytu, rozprysk Kryształu Watry, płomień Watry przy przybyciu
  i odejściu podróżnika, wirujący krąg dymu (ładowanie Dymnych Wybuchów, chmura Dym i Cień), trzask wyładowań
  Gromoskrzydłego; podróżnicy i rywale tną i trafiają efektami gracza (`sword_slash`, `sword_hit`, `spell_hit`).
- [x] Wędrowny kupiec Hasan (`Settlement.MERCHANT_POOL`, 4 z 10 towarów co 10 minut): poza wielkimi miksturami i rogiem
  straży sprzedaje kwiat paproci (150 zł), bieluń (70), eliksir z kwiatu paproci (250), wywar z bielunia (160),
  Wilczy Róg (250), Muszlę Bulgora (300) i Runę Zmiany (900); ceny w polu `price` w `Items`. Kamieni zaklinających
  nadal nie sprzedaje. Test `test_village` sprawdza, że każdy towar ma cenę.
- [x] `tests/test_party.gd`, „prośba przepada z drużyną” zawodziło losowo: drużyna bywa jednoosobowa, a test zabijał
  jej jedynego członka, więc późniejsza prośba nie miała drużyny do rozwiązania. Test dobiera wtedy nowego członka.
- [x] **Końcówka gry trudniejsza** (zgłoszenie autora z 3.11.2026: Nawia przechodzona ekwipunkiem z ~20. poziomu bez
  ryzyka śmierci). Pomiar zapisu autora (`docs/zapis_1793465464755.json`, Wojciech z buławą) narzędziem
  `tests/endgame_probe.gd` (wczytuje zapis, loch stopnia T, gromada 8 wrogów dociągana do postaci, bot z paskiem miecza;
  wypisuje obrażenia/s, zabójstwa, otrzymane obrażenia i leczenie): przed zmianami w stopniu 17 3000-4000 obrażeń/s,
  potwór pada w ~0,25 s, w walce otrzymane obrażenia ~20/s równoważone leczeniem, stojąc w gromadzie pada po 11 s.
  Postać 50. poziomu z tym samym ekwipunkiem bije tak samo (obrażenia nie zależą od poziomu). Przyczyny i zmiany
  (wszystkie poza limitem kradzieży życia działają tylko ponad `Levels.ENDGAME_LEVEL`, w pełni od `ENDGAME_FULL` = 65,
  udział liczy `Levels.endgame_share`; krainy bez zmian):
  - nietykalność po trafieniu i uniku 0,5 s pozwalała trafić najwyżej 2 ciosom na sekundę - w końcówce do 0,15 s
    (`Player.hurt_invulnerability`, `ENDGAME_INVULNERABILITY`), więc gromada bije mocniej niż jeden wróg;
  - kradzież życia bez limitu (talizman 2,1% z kilku tysięcy obrażeń/s) - najwyżej 4% maks. zdrowia na sekundę
    (`LegendaryEffects.LEECH_CAP`, `leech_heal`, też Krwawy Szał);
  - każde trafienie przerywało zamach, a Młynek odpychał co 0,26 s - w końcówce zamach przerywa tylko cios za co najmniej
    15% zdrowia potwora, a odrzut jest o połowę słabszy (`Goblin.ENDGAME_STAGGER`, `ENDGAME_KNOCKBACK_RESIST`);
  - stała pancerza 50 niezależnie od poziomu potworów - rośnie o 6% na poziom ponad 41 (`Levels.ENDGAME_ARMOR`,
    `Levels.armor_scale`, `CharacterStats.armor_reduction` z poziomem potworów okolicy `Levels.zone_default`);
    86 pancerza przy poziomie 90 daje 30% zamiast 63%;
  - zdrowie potworów +2,5% na poziom ponad 41 (`Levels.ENDGAME_HEALTH`, przy 90. poziomie 2,2x - także bossowie
    szczytowi i Władca Hordy).
  `tests/balance_sim.gd`: osobne widełki ciosów w końcówce (`TARGET_NORMAL_END`, `TARGET_STRONG_END` - gracz bije tam
  umiejętnościami), pancerz z `armor_scale` i gracz z ekwipunkiem z 40. poziomu (`STALE_LEVEL`) - przy 90. poziomie
  ma przeżywać mniej niż 6 ciosów (5,2). Pomiar po zmianach (stopień 17): potwór 2330 zdrowia, cios po redukcji 173,
  stojąc w gromadzie pada po 3-4 s, w walce otrzymuje 40-140/s przy leczeniu 40-85/s (bez mikstur pada po 10-35 s).
- [x] **Końcówka gry trudniejsza, etap 2** (autor: „dalej czyszczę lochy najwyższego stopnia takim ekwipunkiem - mam
  się odbić od ściany”, więcej paczek w najwyższych stopniach i płynne przejście): obrażenia potworów +16% na poziom
  ponad 41 (`Levels.ENDGAME_DAMAGE`, było 2,5%), zdrowie +7% (`ENDGAME_HEALTH`); liczba potworów w lochu rośnie płynnie
  z prawdziwym stopniem (`Dungeons.count_multiplier`: 1 + 0,06 (s-1) + 0,008 (s-1)², stopień 7 - 1,65x, 12 - 2,6x,
  17 - 4x; dawniej +7% na stopień do 7., wyżej bez zmian), stopień 17 ma ~655 potworów zamiast 231.
  `tests/endgame_probe.gd`: walka na środku największej komnaty (postać wraca po odskoku - koniec zacinania się bota),
  szósty argument - ekwipunek zastąpiony rzadkimi przedmiotami danego poziomu, czas klatki. Pomiar (gromada 8 wrogów,
  postać na poziomie potworów): ekwipunek autora - stopień 8 i 10 bez kłopotu, 12 traci zdrowie (~-60/s), 14 (~-100/s),
  17 - otrzymuje 425-540/s przy leczeniu ~85/s, pada co ~3 s; rzadki ekwipunek tego poziomu - 12 i 14 bez kłopotu,
  17 - otrzymuje ~210/s i tyle samo leczy, zabija 3x szybciej. Czas klatki w stopniu 17 (chmura, bez ekranu): w spoczynku
  ~8 ms zamiast ~6, w walce ~14 ms. `tests/balance_sim.gd` w końcówce tylko wypisuje etapy (bez widełek ciosów
  i przeżycia - symulacja nie liczy umiejętności, uniku ani leczenia) i sprawdza gracza z ekwipunkiem z 40. poziomu
  (rzadkim) - przy 90. poziomie przeżywa 1,4 ciosu.
- [x] **Portal do miasta** (zgłoszenie autora z 3.11.2026, jak portal w PoE): klawisz B (akcja `town_portal`) w lochu -
  przez 1,2 s rośnie niebieski płomień (`TownPortal`, `scripts/town_portal.gd`; trafienie przerywa -
  `Player.cancel_portal`), gotowy zabiera do Ostoi (`World.open_town_portal`). W Ostoi obok Watry
  (`World.town_portal_spot`, przybycie "town_portal") stoi portal do lochu (`World.return_through_portal`): loch
  generuje się od nowa z tego samego ziarna, a `Dungeon.restore_portal` przywraca stan z `Dungeon.portal_state` -
  pokonane potwory (numery miejsc), zużyte skrzynie / kapliczki / Uroczyska / Kręgi Żertwy / Skarbniki / Kryształ
  (znikają; trwające fale przepadają), otwarty skarbiec z płomieniami wyjścia, zużyty ołtarz, łup na ziemi (z
  wylosowanymi przedmiotami); postać staje przy płomieniu portalu do Ostoi w miejscu otwarcia (można przechodzić
  dowolnie wiele razy). Portal jest w zapisie gracza (`Player.town_portal`), gaśnie po wyjściu płomieniami Watry
  i przy nowej wyprawie. Nie działa w arenach bogów. Test `tests/test_town_portal.gd`.
- [x] **Gęstsze Uroczyska** (zgłoszenie autora z 3.11.2026 „za mała gęstość potworów w Uroczyskach”): upiorów naraz
  (`URO_ALIVE` 14 + promień / `URO_ALIVE_PER` 9) razy `Dungeons.uro_density` (count_multiplier stopnia do potęgi
  `URO_DENSITY_POWER` 0,25), najwyżej `URO_ALIVE_MAX` 50 (wydajność); wychodzą gromadami po `URO_PACK` 3-5 z jednego
  miejsca kręgu (`Uroczysko._ghost_spot`). Żeby krąg nie trwał bez końca przy 3x szybszym zabijaniu: `URO_GROW` 8 -> 2,5;
  nagrody bez zmian w sumie: `URO_KILLS_PER_RUNE` 14 -> 30, `URO_LORD_EVERY` 25 -> 80, `URO_GHOST_RUNE` 2% -> 0,6%.
  Pomiar `tests/endgame_probe.gd` w trybie `uro` (bot otwiera krąg i walczy, aż zgaśnie; łup sprzątany co sekundę):
  przed - stopień 7: 10 upiorów naraz, 651 zabitych w 161 s; po - stopnie 7 / 12 / 17: 31 / 34 / 39 upiorów naraz,
  2100-2350 zabitych w 166-176 s, klatka 8,8 / 12,4 / 18,2 ms (chmura; przed zmianą stopień 17 ~12 ms).
- [x] **Poprawki po testach autora (listopad 2026)**:
  - postać niewidzialna po odrodzeniu w lochu: zanikanie po śmierci (do 2,2 s) trwało dłużej niż czekanie na
    odrodzenie (2 s) - `Player._death_tween` przerywany w `_respawn`; test `tests/test_respawn.gd`;
  - strzała tropiąca sypała błędami, gdy jej cel znikał (`SeekerArrow._is_alive` / `_find_target` bez typu parametru);
  - legenda dużej mapy budowana z potworów bieżącej krainy (`BigMap._fill_legend` - grupy wg koloru kropki,
    nazwy z encyklopedii, najliczniejsze `LEGEND_GROUPS`) zamiast stałej listy z Goblińskiego Lasu;
  - **filtr łupu** (Ustawienia - Rozgrywka): „Sprzedaj od razu” (zwykłe / do magicznych / do rzadkich) i „Najlepsza
    premia słabsza niż T…” - odrzucony przedmiot zamienia się przy wypadnięciu w złoto za cenę skupu
    (`Loot.filtered_gold`, `Pickup._ready`, `Game.set_loot_filter`); legendy, talizmany, kamienie i runy zostają;
    test `tests/test_loot_filter.gd`; okno ustawień przewijane;
  - **ekran dla testerów** (`ui/tester_window.gd`, raz po uruchomieniu, do wyłączenia - `Game.tester_info`; przycisk
    „Dla testerów” w menu głównym): powitanie, sterowanie, tryb deweloperski i jego klawisze, wybór języka;
  - **zgłoś uwagę** (`ui/feedback_window.gd`, w ekranie testerów i w menu gry pod Esc): rodzaj, tytuł, opis + dane gry
    (wersja, system, język, kraina / loch, poziom, tryb deweloperski); „Wyślij na GitHub” otwiera gotowe zgłoszenie
    (issue) w przeglądarce (potrzebne konto GitHub, gra nie trzyma żadnego klucza), „Kopiuj” - do schowka.
- [x] **Pomiar łuku i księgi w końcówce** (`tests/endgame_probe.gd`, tryby `bow` / `spell`: pasek łuku / księgi z zapisu
  autora, broń - rzadki łuk / księga 51. poziomu, punkty siły przeniesione do zręczności / inteligencji; bot stoi
  w gromadzie, nie ucieka). Obrażenia/s (ekwipunek autora / rzadki z poziomu lochu): stopień 12 - miecz 7063 / 9202,
  łuk 4515 / 6442, księga 4886 / 7041; stopień 17 - miecz 13024 / 23559, łuk 12118 / 21860, księga 11190 / 19036.
  Łuk i księga trafiają więcej wrogów naraz (stopień 17: 9-13 zamiast 5), ale stojąc w gromadzie dostają 2-4x więcej
  obrażeń niż miecz (bez Młynka, który odpycha i przerywa zamachy, i z lżejszą zbroją).
  Z botem trzymającym dystans (tryby `bow_kite` / `spell_kite` - ucieka od wrogów bliżej niż 130 px, krąży po
  komnacie; dociągani wrogowie pojawiają się 170-230 px od postaci) - zabójstwa/s i otrzymane / leczenie na sekundę
  (ekwipunek autora | rzadki z poziomu lochu): stopień 12 - miecz 3,4 (165/103) | 4,9 (152/148), łuk 1,6 (94/54) |
  2,7 (76/76), księga 1,9 (115/110) | 2,7 (80/80); stopień 17 - miecz 2,7 (572/135) | 6,4 (247/108), łuk 1,6 (589/88) |
  3,2 (69/69), księga 1,8 (270/76) | 3,7 (196/197). Na dystansie łuk i księga są bezpieczniejsze od miecza (z dobrym
  ekwipunkiem nie tracą zdrowia), ale zabijają mniej więcej o połowę wolniej.
  Decyzja autora: **+25% wszystkich obrażeń z łukiem i księgą** (`CharacterStats.WEAPON_DAMAGE`, w
  `damage_multiplier`). Pomiar po zmianie (zabójstwa/s, ekwipunek autora | rzadki): stopień 12 - łuk 2,1 | 2,8,
  księga 2,2 | 3,4; stopień 17 - łuk 2,6 | 3,5, księga 1,8 | 3,8 (miecz 3,4 | 4,9 i 2,7 | 6,4) - łuk i księga
  zabijają w 55-95% tempa miecza (średnio ok. 2/3), z dobrym ekwipunkiem nadal bez utraty zdrowia.
- [x] **Żywioły, etap 1** (pomysł autora, listopad 2026: odporności i ich spadek w końcówce jak w PoE): rodzaje obrażeń
  zadawanych graczowi - fizyczne, ogień, lód, pioruny i Nawia (jak chaos) w `scripts/elements.gd`. Fizyczne osłabia
  pancerz, pozostałe odporność (`CharacterStats.resistance`, `taken_multiplier`; sufit 75%, dół -100%), siła wszystkie,
  a pancerz tylko w połowie (`Elements.ARMOR_SHARE`). Premie na przedmiotach (`Loot.TIER_VALUES`, `POOLS`): odporność na
  ogień / lód / pioruny (3-40%, zbroja i biżuteria), na żywioły (2-15%, pierścienie, kolczyki, naszyjnik), na Nawię
  (2-25%, tylko zbroja na tułów, pas i naszyjnik); talizmany - na żywioły i na Nawię. **Kara na Mapie Nawii**
  (`Elements.penalty`, ustawia `Dungeon.generate`): stopień 8 -20%, liniowo do -60% na stopniu 17 i w arenach bogów.
  Potwory biją swoim żywiołem (`Elements.MONSTERS` wg sceny -> `Goblin.element`, pociski `EnemySpit.element`,
  szczególne ataki podają żywioł same: bomby i meteory - ogień, wir wodnika i mroźne elity - lód, pioruny orła i burzowe
  elity - pioruny, kolce nekromanty - Nawia); liczby obrażeń w kolorze żywiołu. Okno postaci pokazuje odporności
  (na czerwono poniżej zera) i karę. `Levels.ENDGAME_DAMAGE` 0,16 -> 0,12. Pomiar (`tests/endgame_probe.gd`, nowe argumenty:
  siódmy - dodatkowa odporność, ósmy - klimat; Zatopione podziemia, stopień 17, gromada 8 wrogów, miecz): ekwipunek
  autora - otrzymuje 738/s przy leczeniu 68/s (pada co ~2 s); rzadki z 90. poziomu bez odporności 392/227; ten sam
  z odpornościami na sufit 95/95 (bez utraty zdrowia). Etap 2 (odporności i wrażliwości potworów, przebicie
  odporności) i 3 (żywioły w modyfikatorach lochów, bożkach, elitach) - do zrobienia.
- [x] **Żywioły, etap 2**: odporności i wrażliwości potworów na obrażenia gracza (`Elements.MONSTER_RESIST` wg sceny ->
  `Goblin.resistances`; najwyżej +50%, bez pełnej odporności; grupy: nieumarli +30% lód / +40% Nawia / -25% ogień,
  zgnili +40% Nawia / -30% ogień, drzewa -40% ogień / +20% lód, pająki +30% Nawia / -25% ogień, wodni +30% lód / -30%
  pioruny, ptakoludzie +30% pioruny / -20% lód, koboldy +20% ogień / -20% lód, ogniki i bies +50% ogień / -30% lód,
  bogowie i bossowie świata wg swojego żywiołu). Żywioł trafienia gracza wg odgłosu (`Elements.SOUND_ELEMENTS`:
  fire / ice / lightning; Dymne Wybuchy - ogień), mnożnik `Elements.hit_multiplier` w `Player.hit_enemy`. Nowe premie:
  obrażenia od ognia / lodu / piorunów (3-40%, broń, rękawice, pierścienie - dla umiejętności z tagiem żywiołu,
  `CharacterStats.kind_multiplier` przez `Elements.TAG_DAMAGE`), od żywiołów (2-25%, naszyjnik, talizmany), przebicie
  odporności (1-15%, broń, pierścienie, naszyjnik - `CharacterStats.penetration`). Encyklopedia (L) pokazuje żywioł
  ataku potwora i jego odporności (zielone - wrażliwość). Test `tests/test_elements.gd`. Pomiar (stopień 17, rzadki
  ekwipunek 90. poziomu z odpornościami na sufit, zabójstwa/s): księga (pioruny i lód) - Zatopione podziemia 3,7,
  Katakumby 2,6, Pajęcze korzenie 4,7; łuk 3,1-3,2; miecz 5,7-6,9 (obrażenia fizyczne - bez zmian).
- [x] **Żywioły, etap 3**: żywioły w mechanikach lochów. Premie lochu (`Dungeons.added` - bożki, drzewko Watry i teraz
  także modyfikatory za żar z kluczem "add"): `added_fire` / `added_cold` / `added_lightning` / `added_nawia` - każdy
  cios potwora zadaje dodatkowo taką część obrażeń jako żywioł (`Elements.added`, liczone w `Player.take_damage`, każda
  część osłabiana swoją odpornością), `elemental_curse` - niższe odporności gracza na żywioły (`Elements.curse`),
  `monster_resistance` - potwory odporniejsze na żywioły i Nawię (`Elements.monster_bonus`); ustawia
  `Elements.apply_dungeon` w `Dungeon.generate`. Nowe modyfikatory za żar (`Dungeons.MODIFIERS`): Pożoga (+30% ognia,
  +30% złota i przedmiotów), Mróz (+30% lodu, +40% doświadczenia), Burza (+30% piorunów, lepsza rzadkość łupu), Klątwa
  żywiołów (-25% odporności, łup +2 poziomu), Osłona żywiołów (potwory +30% odporności, +50% doświadczenia) - okno
  lochów ma modyfikatory w dwóch kolumnach i przewijaną treść. Nowe bożki ryzyka (`Idols.KINDS`, ikony z
  `tools/idol_art.py`): Pożogi, Szronu, Gromu (+20/30/40% obrażeń żywiołu za łup / doświadczenie / rzadkość) i Klątwy
  (-15/20/30% odporności za poziom łupu). Elity Mroźny / Płonący / Wybuchowy / Burzowy biją swoim żywiołem i mają +50%
  odporności na niego (`DungeonElite.TRAIT_ELEMENTS`). Pomiar (Zatopione podziemia, stopień 17, rzadki ekwipunek
  z odpornościami na sufit, miecz): bez modyfikatorów otrzymuje 104/s, z Pożogą 136/s, z Pożogą, Mrozem i Burzą 207/s.
- [x] **Krok 3 dopieszczenia walki** (nowe premie na tagach; obrażenia żywiołów i przebicie odporności były już
  w „Żywioły, etap 2”): obrażenia pocisków / ciosów / obszarowe (3-35%) i w czasie (3-40%) dla umiejętności z tagiem
  `projectile` / `hit` / `area` / `dot` (`CharacterStats.FORM_DAMAGE` w `kind_multiplier`); szanse na stany od
  żywiołów (`ignite_chance` 1-15%, `freeze_chance` 1-12%, `shock_chance` 1-15%, razem najwyżej 50% -
  `CharacterStats.ailment_chance`). Stany (`Elements.AILMENTS`, `Player._apply_ailment` po trafieniu swoim żywiołem):
  **podpalenie** - 80% obrażeń trafienia w 3 s co 0,5 s (`Goblin.ignite`, premia obrażeń w czasie je zwiększa),
  **zamrożenie** - wróg stoi 0,8 s i sinieje (`Goblin.freeze`: ogłuszenie + spowolnienie, bossowie krócej),
  **porażenie** - przez 4 s wróg dostaje od gracza +20% obrażeń (`Goblin.shock`, w `Player.hit_enemy`); stan, który
  już trwa, nie odpala się drugi raz, nad wrogiem napis stanu. Miejsca premii: broń (wszystkie), rękawice (pociski,
  ciosy, szanse), pierścienie (pociski, obszar, w czasie), naszyjnik (obszar, w czasie), talizmany (cztery premie
  formy). `tests/endgame_probe.gd`: dziewiąty argument "-" - bez modyfikatorów, dziesiąty - dodatkowe premie postaci
  ("shock_chance=0.3,..."). Pomiar (stopień 17, Zatopione podziemia, księga na dystansie): +30% szans na porażenie
  i zamrożenie - otrzymane obrażenia 186/s -> 113/s (zamrożeni wrogowie nie biją), zabójstw tyle samo.
  `tests/test_town_portal.gd`: krok 3 w lochu zbudowanym przez podróż z kroku 2 (wcześniej dwa światy naraz).
- [x] **Kamienie wsparcia, etap 1** (krok 4 dopieszczenia walki, jak w PoE; ustalenia z autorem: poziomy kamieni
  z własnego doświadczenia, 4 gniazda + 5. Wielkim Krzesiwem, bez rynku, bez zwykłego ataku, w Mgle po śmierci
  przepada połowa puli): `scripts/supports.gd` - 17 kamieni (`Supports.DATA`, `ORDER`): Rozległość (obszar +20-45%),
  Rozszczep (+2 pociski, -30..-15% obrażeń), Przeszycie (+2-4 przebicia), Łańcuch (1-2 odbicia, -15%), Żarowe / Mroźne
  / Burzowe Ostrze (fizyczne: 20-40% obrażeń dodane jako żywioł, +5% szansy na jego stan), Żar, Szron, Wyładowanie
  (szanse na stany i ich siła), Jad (w czasie +25-55%), Okrutny Cios (cios: +25-50%, -10% szybkości), Furia (atak:
  +15-30% szybkości, -10%), Echo Rusałki (czar powtarza się raz, -35..-20%), Rozpęd (ruch: przez 3 s +15% ruchu
  i +15-30% obrażeń), Watażka (przywołanie: +20-40%, +25-50% czasu), Donośny Głos (okrzyk: obszar i czas +25-50%).
  Każdy kamień mnoży koszt many (x1,1-1,4). Poziomy 1-20 (wartości liniowo), kamień w gnieździe dostaje całe
  doświadczenie postaci (`XP_SHARE`, próg `400 * poziom^1,6`, napis w HUD przy awansie), 3 takie same łączą się
  w 1 o 2 poziomy wyżej (`Supports.combine`, przycisk w oknie K). Kamień pasuje do umiejętności z jednym z jego
  tagów; `Supports.EXCEPT` wyklucza połączenia bez działania (np. Rozszczep w Deszczu Strzał, Echo w Teleporcie).
  Gniazda w `SkillBook.supports` (zapis przy umiejętności): 1.-4. Krzesiwem Nawii (1/2/4/8 szt., `nawia_flint`),
  5. Wielkim Krzesiwem (`great_flint`). Działanie: `Skills.tags(id)` ma na końcu znacznik umiejętności
  (`SKILL_MARK`, `Skills.skill_of`), więc `CharacterStats.kind_multiplier / skill_speed / area_multiplier /
  ailment_chance / dot_bonus` i `Player.hit_enemy(..., tags)` liczą kamienie tej umiejętności; pociski
  (`Projectile.tags / chain`, `Player.support_projectile`, `split_directions`), Echo (`Player.support_echo`),
  koszt many (`Player.skill_mana`), Rozpęd (`note_skill`). Okno K: rząd gniazd pod opisem umiejętności, pasujące
  kamienie z plecaka, dorabianie gniazda; przeciąganie kamienia na umiejętność w drzewku. Ikony z istniejących
  grafik (`tools/support_art.py`). Tryb deweloperski F6. Na razie kamienie i krzesiwa są tylko w trybie
  deweloperskim - źródłem będzie Mgła Nawii (etap 2). Testy: `tests/test_supports.gd`, `tests/test_supports_skills.gd`.
- [x] **Kamienie wsparcia, etap 2: Mgła Nawii** (nowa mechanika lochów, jak Delirium w PoE; ustalenia z autorem:
  waga 5 jak inne duże mechaniki, Wielkie Krzesiwo od gęstości 8 i ze skarbców bogów, Słup z gotowej grafiki):
  `scripts/nawia_mist.gd` (`NawiaMist`, stałe `MIST_*` i `mist_*` w `Dungeons`), `"mist"` w `Dungeons.MECHANICS`.
  Mglisty Słup (obelisk z Cmentarza przebarwiony na siny, kłęby mgły) w wolnej komnacie (`Dungeon._add_mist`);
  dotknięcie (F) jest dobrowolne. Gęstość od 1, co `MIST_STEP` (60 s) +1, do 10. Każdy stopień: wszystkie potwory
  lochu +8% zdrowia i obrażeń (`NawiaMist.empower` - statystyki sprzed Mgły w meta `mist_base`, przegląd co 1 s,
  po Mgle wracają do zwykłych), zjawy wokół gracza (potwory klimatu z `ghost.gdshader`, słabsze: zdrowie x0,7,
  obrażenia x0,8; naraz `6 + 3 x gęstość` razy `uro_density`, sufit 60, gromady po 3-5 w 240-420 px, zostawione
  dalej niż 950 px znikają), co 3 stopnie cecha elit (`ELITE_TRAITS`) - przewodnik gromady z szansą 25% staje się
  elitą ze wszystkimi cechami Mgły. Ekran zasnuwa mgła (`shaders/nawia_mist.gdshader`, pod oknami HUD-u), u góry pasek
  gęstości, czasu do kolejnego stopnia i puli. Pula za każdego zabitego wroga (`NawiaMist.add_kill`): przedmioty
  0,04 i złoto 0,5 x `Levels.gold` (razy `1 + 0,15 x gęstość`), kamienie wsparcia 0,004 i Krzesiwa Nawii 0,006
  (razy `1 + 0,5 x (gęstość - 1)`), od gęstości 8 Wielkie Krzesiwa 0,0015. Koniec: F przy Słupie, portal do miasta
  (`World.open_town_portal` -> `Dungeon.end_mists`, Skrzynia zostaje na ziemi w stanie lochu) albo śmierć (połowa
  puli przepada) - Słup wysypuje Skrzynię Mgły (ułamki zaokrąglane losowo, razy moc mechaniki). Poziom kamieni:
  `stopień x 0,7 + gęstość x 0,6` (+-1), najwyżej 16 (`Dungeons.mist_support_level`). Skarbiec boga i Władcy: 15%
  na Wielkie Krzesiwo (`Pinnacles.GREAT_FLINT_CHANCE`). Gałąź „Mgła Nawii” w drzewku Watry (13 gałęzi, dalej od
  środka; węzły Wieczna Mgła i Gęsta Mgła), opis legendarnego bożka (sam bożek Mgły - do zrobienia z ikonami).
  Kryształ Watry waga 7 -> 7,8, żeby nadal był w co piątym lochu. Test: `tests/test_mist.gd`.
  Do ustalenia po ograniu: tempo gęstnienia, siła na stopień, liczby puli i poziomy kamieni, bożek Mgły.
- [x] **Kamienie wsparcia, etap 3: węzły Mgły i Bożek Mgły** (ustalenia z autorem: tempo, siła na stopień i pula
  Mgły zostają bez zmian; węzły wszystkich czterech rodzajów; ikona bożka rysowana w kodzie). Drzewko Watry:
  przedłużenia gałęzi za węzłem końcowym ścieżki (`WatraTree.EXTENSIONS`, odstęp `EXT_STEP`, id `<gałąź>_<a|b>_x<n>`) -
  dziś tylko Mgła, 8 węzłów (152 węzły w drzewku). Za Wieczną Mgłą: Leniwa Mgła (+5 s na stopień), Pamięć Mgły (+5%
  puli zostaje po śmierci), Leniwa Mgła, Zimna Pamięć (znaczący: +20% puli po śmierci, +5 s) - razem 75 s na stopień
  i 75% puli po śmierci. Za Gęstą Mgłą: 2x Kamienie z Mgły (+15% kamieni wsparcia i krzesiw), Żyła Krzesiw
  (znaczący: Wielkie Krzesiwa od gęstości 6 zamiast 8, +2 do poziomu kamieni i sufitu poziomu, +10% kamieni), Bezdenna
  Mgła (kluczowy: gęstość do 15). Premie `mist_*` czyta `Dungeons.mist_rules(config["tree"])` (sufity
  `MIST_KEEP_CAP` 0,9 i `MIST_GREAT_MIN` 3), `NawiaMist.rules` ustawiane przy dotknięciu Słupa; ekran mgły przy
  gęstości ponad 10 już nie gęstnieje. Okno drzewka: tło pod przedłużeniem, nazwa gałęzi za najdalszym węzłem
  (`WatraTree.branch_reach`), widok szerszy (360 px) i przesunięty w prawo. Bożek Mgły (`Idols.KINDS["mist"]`, waga
  0,8, siny kamień w `tools/idol_art.py`). Testy: `tests/test_mist.gd`, `tests/test_watra_tree.gd`.

## Gobliński Las i Prastary Las (`scripts/world.gd`, `scripts/ancient_forest.gd`) (Do poprawy)
- [x] Gobliński Las: więcej grupek goblinów w lesie i większe siedlisko wilków - około 450 potworów (było około 340);
  to kraina startowa, więc zwiększenie jest umiarkowane.
- [x] Prastary Las: dwa pierścienie prastarych drzew wokół Leszego z drzewcami, wielkie leże pająków, wataha wargów
  przy każdej bestii, gniazda pająków i stada drzewców w gęstwinie - około 400 potworów (było 66).
- [x] Prastary Las: dużo potworów (579, było 409) - dzikie ostępy (`AncientForest._plan_wilds` / `_build_wilds`,
  własne ziarno `_wild_rng`, budowane na końcu): 6 zasnutych polan (wielka sieć, sieci na ziemi, kokony, jaja, ofiara,
  sieć-pułapka, dwie gromady pająków z sieciarzami), 5 kręgów drzewców na mchu (8-10 drzewców kręgiem wokół powalonego
  pnia, omszałe głazy, spróchniałe pnie, świecące grzyby), 8 legowisk wargów (kości, krew, ślady pazurów, 6-8 wargów,
  część leży). Z dala od szlaku, rozstajów, wejścia, kręgu Leszego, leża pająków i Biesa.
- [x] Gobliński Las: dużo potworów (około 590 wrogów bez zwierzyny, było około 380) - `scripts/goblin_posts.gd`
  (osobne ziarno, budowane na końcu): posterunki goblinów przy drogach dalej niż 20 kafelków od palisady (rząd pali
  od strony drogi z przejściem, łucznicy i osiłek, ognisko z siedzącą zgrają, dwa namioty; zwykle 3), psiarnie
  w południowej części (zagroda z pali z oswajanymi wilkami, klatka, kości, przed bramą poskramiacze, osiłek i dwa
  wargi; 3), zgraje zwiadowców na wolnych pasach wokół Ostoi (około 9), wilcze łowy przy truchłach jeleni
  na skraju siedliska wilków (około 4). Od palisady Ostoi co najmniej 10 kafelków, łowiska zwierzyny nietknięte.
- [x] Barykady z pali w lesie (obozy goblinów, leże wodza, posterunki, psiarnie) przez `World._spawn_palisade`:
  na odcinkach biegnących ukośnie „/" (lewy górny i prawy dolny łuk pierścienia) grafika pali jest odbita
  w poziomie, żeby pale szły wzdłuż barykady i nie zasłaniały obozu.

## Wietrzne Turnie (`scripts/mountain_zone.gd`) (Do poprawy)
- [x] Elektryczny orzeł (Gromoskrzydły, `scripts/storm_eagle.gd`) macha skrzydłami: 8 klatek pełnego uderzenia z PixelLab, także w spoczynku nad gniazdem.
- [x] Wioska ptakoludzi: wydeptane ścieżki (pętla wokół gniazda, do chat, z ramp), dolna osada u stóp skarpy z ulicą
  między rampami, 9 chat na płaskowyżu i 4 na dole, około 210 ptakoludzi (wcześniej 74).
- [x] Wioska satyrów: większa polana (promień 22 zamiast 17 kafelków, 12 namiotów), wydeptana ścieżka wokół ogniska,
  3-4 przysiółki dookoła połączone ścieżkami (ognisko, namioty, tłocznia/maj/posąg/bębny, gromady satyrów, osiłek),
  około 120 satyrów (wcześniej 52).
- [x] Dużo potworów (609 wrogów bez kóz, było 326): orle czaty na płaskowyżach dalej niż 40 kafelków od gniazda wodza
  (`_plan_outposts`, `_build_outpost` - chata na palach z ogniskiem i siedzącą gromadą, dwie stojące gromady po bokach;
  zwykle 7 czat po około 18 ptakoludzi), satyrowie pasterze przy stadach kóz (namiot, siano albo wino, grajek, czasem
  osiłek; 5-7 satyrów), 14 polujących gromad ptakoludzi na halach zachodniej części. Własne ziarno (`_outpost_rng`),
  budowane na końcu - kształt krainy i stare numery miejsc potworów w zapisach się nie zmieniają.
- [x] Wioska ptakoludzi wciśnięta w północno-wschodni róg (`lair` (0.785, 0.245) rozmiaru mapy, było (0.74, 0.3)):
  grań łukiem wokół narożnika (`RING_FROM`/`RING_TO`, od -150° do 48° przez północ), od zachodu wioska otwarta
  na hale; zewnętrzny krąg chat (`BACK_HUTS` - 7 kątów, mniejsze gromady po 4-5) z tyłu i na zachodzie płaskowyżu.
  Czaty na płaskowyżach z wolnym promieniem 4 (zwykle 8 czat). Razem około 650 wrogów bez kóz.
  Zmiana przestawia całą krainę, więc stan krainy w zapisie ma wersję układu (`World.ZONE_LAYOUTS`,
  `MountainZone.LAYOUT` = 2): postać zapisana w starym układzie pojawia się przy kapliczce, a pokonane potwory
  i ścięte drzewa ze starego układu się nie liczą. Walka w środku wioski ptakoludzi kosztuje ok. 15 ms na klatkę
  (dwa razy więcej niż gdzie indziej, tak było i przed przebudową - do sprawdzenia, co w niej tyle kosztuje).

- [x] Wioska satyrów przebudowana na **winne święto** (`MountainZone._plan_satyr_glade`, `_plan_satyr_plots`,
  `_plan_satyr_paths`, `_build_satyr_village`, `_build_feast_plaza`, `_build_satyr_houses`, `_build_vineyard`,
  `_build_orchard`, `_build_pen`; `LAYOUT` = 3). Jedna duża polana (promień 25 kafelków, środek w (0.7-0.75,
  0.72-0.76) rozmiaru mapy), w środku wydeptany plac biesiadny o nierównym brzegu: animowane wielkie ognisko,
  parkiet z desek (tekstura pomostów `WALK_H`, `_dance_floor`) z lampionami i girlandami, trzy ukośne stoły
  z ucztą i biesiadnikami (`_banquet`), podest grajków (w warstwie podłóg, grajkowie stoją na deskach), tron
  z beczek z posągami i osiłkami, Faun-Król przed tronem. Wokół placu kręta ścieżka (promień falujący, bez kół
  jak z cyrkla) i do 14 chat (dwie chaty z bali, winiarnia, altana; drobiazgi pod ścianami, po 3 satyry przed
  wejściem), lampiony między chatami. Zamiast przysiółków do 5 pól na elipsie wokół polany (`PLOT_DISTANCE`,
  w pionie bliżej, bo między drogą a skrajem mapy mało miejsca): winnice (rzędy winorośli, zbieracze, kosze,
  wózek), sad (jabłonie i grusze), zagroda (płoty z furtką, koryto, siano, kozy, pasterze z osiłkiem), połączone
  krętymi dróżkami. Winnice (`_plan_vineyards`, `_build_vineyard`, `_vine_run`) to duże działki jak pola zbożowe:
  postrzępiona elipsa (`VINEYARD_RADIUS` 16x11,5 kafelka, brzeg wygięty szumem) bez komórek przy drogach
  i ścieżkach (kształt idzie za nimi), z miedzą między sąsiednimi działkami; dróżka wchodzi w głąb i dzieli winnicę.
  Rzędy co 3 kafelki wypełniają każdy ciągły odcinek komórek (krzew co 40 px, przejście co 5-7 krzewów), na ziemi
  gęsta trawa (`m_dark`; naturalnych płatów gęstej trawy przy winnicach nie ma). Zbieracze w przejściach (1 na 14
  komórek, najwyżej 14), wózki, drabiny i kadzie przy ścieżkach. Szczegóły wioski losuje własne ziarno (`_satyr_rng`). Grafiki z PixelLab:
  `pixellab_src/regions/satyr_village/` (paczki houses, feast, vineyard, animacja bonfire), narzędzie
  `tools/satyr_village_art.py` -> `assets/mountains/satyr/`, sceny `scenes/props/mountains/satyr/`.
  Kraina: 637 wrogów (było 686), plac biesiadny to około 80 wrogów naraz, walka tam około 7 ms na klatkę.

## Rozlewiska (`scripts/drowned_grove.gd`, `scripts/hydra_bog.gd`) (Do poprawy)
- [x] Topielcze Uroczysko zajmuje cały obszar pod drogą i na zachód od rzeki: 16 sadzawek (było 7), mgła na całym obszarze,
  około 220 potworów (było 66): utopce, ogniki, topielice.
- [x] Bagno Hydry przeniesione na północny skraj krainy (najdalej od drogi, na zachód od rzeki, z dala od żabołaków), z 3-5 mniejszymi sadzawkami
  wokół głównej; w bagnie martwe drzewa zamiast zwykłych.
- [x] Dużo potworów (617 wrogów, było 323): Żabie stawy na wschodzie za rzeką (`scripts/frog_ponds.gd`, osobne ziarno,
  budowane po Bagnie Hydry - stare numery miejsc potworów w zapisach się nie zmieniają): do 14 stawów (zwykle 10)
  z płycizną, po której da się brodzić (`World._in_marsh`), po 2-3 gromady po 6-8 żaboludzi i plujek na błotnistym
  brzegu i 3-4 brodzących; przy 3 największych osada (chata w namorzynie, ognisko z siedzącą gromadą, suszarnia ryb,
  sieć, garnki, totem, dłubanka); łowiska nad rzeką (do 12 gromad z sieciami); 6 dodatkowych gromad wokół wioski.

## Pola Zbożowe (`scripts/grain_fields.gd`) (Do poprawy)
- [x] Wielki obóz koboldów (elipsa 48x30 kafelków) z barykadą Bombardiera w północnej części: 12 namiotów, 6 ognisk,
  stojące zgraje, straż bramy; zgraje także w łanach dookoła - około 190 koboldów (było około 65).
- [x] Pola pszenicy: działki o organicznych granicach (komórki Woronoja wygięte szumem) na brązowej glebie, wąskie miedze
  z żywopłotami (krzaki gęsto obok siebie jak pale palisady, ciągłe linie na granicach działek, przejścia co około
  11 kafelków), płotami z żerdzi, kamieniami i kwiatami; przeważają łany (około 2/3 działek), reszta to ścierniska z rzędami snopków
  i zaorane zagony; mało trawy (łąki tylko płatami, polany wokół gospodarstw); kępy drzew w jesiennych barwach
  (`shaders/autumn.gdshader`); zboże nie spowalnia.
  Wzór: `docs/referencje/pola_zbozowe.jpg`.
- [x] Dużo potworów (626 wrogów, było 224): 4 czaty koboldów (`OUTPOSTS`, `_build_outpost` - wianuszek 5 namiotów wokół
  ogniska z siedzącą zgrają, zgraje w lukach między namiotami, wóz z workami, skrzynie bomb, totemy, dróżka do drogi;
  po około 28 koboldów) w środku i na wschodzie krainy; 10 gospodarstw (na północy plądrują je dwie zgraje przy workach,
  na południu 4-6 czerwi z norami); 34 zgraje po 5-8 w łanach w całej krainie (poza ryjowiskiem); w ryjowisku 80 czerwi
  gromadkami po 2-4 wokół nory; 14 gniazd po 3-5 czerwi w zaoranych zagonach (`_build_soil_nests`). Główny obóz bez
  zmian (gęstszy podnosił czas klatki przy walce w jego środku).

## Leśny Cmentarz (`scripts/forest_cemetery.gd`) (Do poprawy)
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

## Testy (Do poprawy)
- [x] Przegląd całego zestawu testów (listopad 2026) - przedawnione albo losowe testy poprawione:
  - `test_world_events.gd` „meteoryt rani gracza”: gracz bywał chwilowo nietykalny po ciosie potwora z Rozlewisk
    (albo robił unik z przedmiotów); test zdejmuje nietykalność i próbuje do 5 meteorytów (kolejne bez miejsca wydarzenia);
  - `test_legends.gd` szukał napisu „Efekt:”, a na komputerze z angielskim systemem gra startuje po angielsku -
    test bierze napis z `Lang.t`;
  - `test_bow_skills.gd` „Balista strzela”: balista celuje w najbliższego potwora (czasem innego z gromady) -
    test liczy salwy (`_Ballista.shots`);
  - `test_market_growth.gd` „lepsze przedmioty na dużym rynku”: 3000 losowań zamiast 400, próg 2,5 punktu zamiast 5
    (różnica zmalała po zmianach losowania łupu i ginęła w szumie);
  - `test_pan.gd`: krok przesuwania tła przeliczony na 60 klatek na sekundę, próg 1,5 px (1 px wypadał na granicy);
  - błąd „previously freed instance” przy zabitych potworach w pętlach po słownikach (ostrza widmowe
    `spectral_blades.gd`, trucizna `bow_skills.gd`, podpalenie `spell_skills.gd`) - klucz bez typu, sprawdzony przed użyciem.
- [x] Wydajność wioski ptakoludzi: dawny pomiar 15 ms na klatkę jest nieaktualny - `bench_combat` daje w środku wioski
  (81 wrogów) średnio 7,3 ms, jak w innych krainach (7-8,5 ms).

- [x] **Przycięcia przy walce w wiosce ptakoludzi (listopad 2026).** Pomiar z rysowaniem i umiejętnościami
  (`tests/bench_village.gd`) pokazał pojedyncze klatki 30-60 ms przy czarach i Młynku z wirującym Mgnieniem.
  Przyczyny i poprawki:
  - podnoszenie łupu: każdy przedmiot zmieniał plecak, a na to odświeżało się kilkanaście okien, także zamkniętych
    (rzemiosło 0,5 ms, paski, ekwipunek, zaklinanie) - 0,9 ms na przedmiot; zamknięte okna (`CraftingWindow`,
    `InventoryWindow`, `EnchantWindow`, `CharacterWindow`) odświeżają się przy otwarciu (`visibility_changed`),
    `ActionBars` przelicza plecak raz na klatkę (`_queue_refresh`) - teraz 0,02 ms;
  - trafienie wroga 0,225 -> 0,055 ms: `Equipment.effect_power` i `bonus` pamiętają wynik na klatkę (efekty legend
    przy trafieniu pytały o kilkanaście rodzajów, każdy przeglądał cały ekwipunek), `DamageNumber` to Node2D z
    `draw_string` zamiast Label (wygląd ten sam);
  - Mgnienie: promień widoczności tylko do kolejnych kandydatów od najbliższego (wcześniej do każdego wroga w zasięgu
    228 px, kilka razy na sekundę w Młynku); siatka wrogów `Goblin.near` (komórki 64 px, budowana raz na klatkę)
    zamiast przeglądania całej grupy `enemies` w Mgnieniu, Młynku, cięciu, Łańcuchu błyskawic i alarmowaniu kompanów;
  - pierwsze zabicie nie wczytuje sceny łupu w walce (`Goblin.pickup_scene`, wczytywana w `World._ready`).
  Młynek z Mgnieniem: najgorsza klatka 37-45 -> 18 ms, średnio 173 -> 187 FPS (1920x1080, komputer autora).

## Postać i przedmioty (Pomysły i rzeczy do zrobienia)
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
  - **Łańcuch błyskawic bez odnowienia** (listopad 2026): zamiast odnowienia 2,4 s tylko czas rzucania
    `Skills.CHAIN_CAST_TIME` (0,6 s) dzielony przez szybkość rzucania; trzymany klawisz rzuca raz za razem
    (`Player._process_strikes`, uderzenia trafiają do `_held_ids`).
    Wygląd: błyskawica rysowana w kodzie (`scripts/lightning_arc.gd` - poszarpana, migocząca, ostro zakończona,
    bez rozciągania arkusza), trafieni wrogowie porażeni na 0,7 s (`scripts/shock_fx.gd` - łuki i poświata).
- [x] **Czerwone koła nie zostają na ziemi** (listopad 2026): koło pioruna ptakoczłowieka i Orła Burzy znika też,
  gdy potwór zniknął przed uderzeniem (np. zabity przez podróżników); bezpiecznik `Telegraph.LINGER` - każda
  poświata sama znika 3 s po wypełnieniu. Test `tests/test_telegraph.gd`.
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

- [x] **Etap 1 animacji postaci z bronią** (listopad 2026, Wojciech): ataki z ruchów szkieletowych PixelLab
  (`animate_character` w trybie `skeleton-v3`, ruchy `slash` 1.3, `shoot_bow` z `side: left` i `cast` z `side: left` -
  broń zawsze w prawej ręce), po 8 klatek na kierunek, opis „bare hands…, no weapon”, żeby model nie dorysował broni.
  Klatki pobiera `pixelart_workbench join … --as sheet --columns 8`, tnie `tools/hero_frames_cut.py`
  (`anim:kierunek` dla rzędu innej animacji). Chwyt i kąt broni: `edit_image` na adresach klatek z opisem pręta-znacznika
  (`mk_<anim>_<kierunek>_<i>.png`; tekst opisu dla cięcia - „rod… magenta end inside the fist… wind-up points up and back”);
  `tools/hero_sheets.py` dopasowuje przesunięcie przerysowanej klatki (`_align`, do 16 px) i przyciąga chwyt do sylwetki
  (`_snap`, `SNAP_MAX` 7), kierunek bez znacznika (strzał na północ) bierze chwyt spoczynku, a klatki z wtopionym łukiem
  poprawia `FRAME_FIX` (wymazanie kolorów albo kopia sąsiedniej klatki). `HeroRig.COUNTS` / `HeroRig.frames` - liczba
  klatek animacji (arkusz ma 8 kolumn, chód 4). W grze `Player._follow_hand`: w ataku broń w dłoni z klatki (cięcie -
  kąt z pręta, łuk celuje w cel, księga grzbietem w górę), pivot z efektem cięcia zostaje przy barku; pozostali bohaterowie
  bez chwytu w atakach - jak dawniej. Miecz i księga w dłoni mniejsze (`Player.HOLD_SCALE`). Szarża pokazuje klatkę
  trafienia (`_hit_frame`). Balans i działanie ataków bez zmian.
  Wybór postaci usunięty z menu: „Nowa gra” od razu pokazuje tryb świata, gracz zawsze gra Wojciechem
  (`Player.HERO`, `set_hero` ignoruje postać z zapisu); arkusze Bogdana, Miry i Jagi zostają na NPC.

- [x] **Etap 2 animacji postaci z bronią** (listopad 2026, Wojciech): nowe ruchy miecza tą samą metodą
  (`animate_character` w trybie `skeleton-v3`, `energy` 1.3 dla zamaszystego stylu, po 8 klatek na kierunek): `chop`, `sweep`,
  `stab`, `rising_cut`, `spin` (`spin_once`). Zwykłe ataki mieczem to seria `sweep` -> `chop` -> `rising_cut`
  (`Player.SWORD_CHAIN`, po 1,2 s przerwy od początku). Umiejętności: Rozpłatanie - `sweep`, Rozłupanie Ziemi - `chop`,
  Szarża - `stab` (klatki 3-5), Półksiężyc - `rising_cut`, Młynek - `spin`. Rozpłatanie i Rozłupanie Ziemi nie mają własnego
  czasu ataku, więc ruch włącza `Player.play_skill_anim` (tylko wygląd). Balans i działanie ataków bez zmian.
  W `tools/hero_sheets.py` ruchy miecza czytają pręt przez `_rod_ends` (także ciemny błękit), chwyt zbyt daleko od dłoni
  szuka sylwetki na przedłużeniu pręta (`_to_fist`), plamki usuwa `_drop_specks`, ręczne kąty są w `ANGLE_FIX`.
  Młynek nie ma znaczników: pręty w obrocie wychodziły niespójne, więc miecz krąży wokół postaci w kodzie jak dotąd.
  Limit `pixelart_workbench join` to 40 elementów (najwyżej 4 kierunki po 8 klatek), a PixelLab przyjmuje 10 zadań naraz.
  Poprawki po uruchomieniu w grze: (1) przy zmianie klatki postaci broń przeskakuje od razu (`pivot`/`sword`
  `reset_physics_interpolation` w `Player._update_animation`) - wygładzanie ruchu między krokami fizyki spóźniało ją
  i odrywało od dłoni; (2) Młynek: postać stoi w pozie z rozłożonymi rękami (klatka 0 ruchu `spin`) zwrócona 90 stopni
  przed mieczem, więc prawa ręka zawsze wskazuje miecz, a rękojeść krąży po spłaszczonej elipsie na wysokości rąk
  (`Player._whirl_hand`, `WHIRL_HAND_CENTER`, `WHIRL_HAND_SQUASH`), za postacią, gdy jest u góry; (3) przerwa w serii
  cięć liczona czasem gry (`_chain_timer`), nie zegarem. Szarża pokazuje klatki 3-5 pchnięcia, w których miecz jest
  w jednej dłoni (przeskok między rękami w kierunku południowym jest tylko w klatkach 0-2). W klatce trafienia ostrze
  zasłania biały łuk efektu cięcia - to zamierzone. Zrzuty klatek ataków w grze: `tools/anim_shots.gd`
  (opis w nagłówku; z `--fixed-fps 60`, bo programowe renderowanie w chmurze jest wolne i gubi klatki).
  Druga runda po uwagach autora (miecz obok dłoni, za płytko, przed palcami; Szarża i Mgnienie nie ostrzem do przodu):
  (A) pięść jako osobna warstwa - `tools/hero_sheets.py` wycina piksele dłoni wokół chwytu do
  `assets/heroes/wojciech_fist.png` (`_fist_sheet`, `FIST_*`), a gra rysuje je nad bronią (`Player._update_fist`,
  węzeł `Fist` tuż za postacią i bronią, z tym samym z_index), więc rękojeść chowa się w dłoni; chwyt dostaje czwartą
  liczbę - 1 to broń za postacią (kierunki "od kamery" albo zamach zza głowy: `_over_head`, `HEAD_ROWS`), używaną
  przez `Player._grip_behind`; (B) chwyt w cięciach liczy `_rod_contact`: PixelLab rysuje między pięścią a różowym
  końcem znacznika ciemny odcinek pręta, więc idziemy od różowego końca dalej wzdłuż pręta, dopóki klatka ze znacznikiem
  różni się od czystej (`ROD_DIFF`), i jeszcze `ROD_INTO_FIST` w głąb dłoni; po zmniejszeniu chwyt idzie do środka pięści
  (`_fist_center`), a pojedyncze odskakujące kąty wygładza `_smooth_angles`; (C) w Szarży i w krótkim pchnięciu po skoku
  Mgnienia (`Player.play_thrust`, `THRUST_POSE_TIME`, klatki 3-5 ruchu `stab`) kąt miecza to kierunek ruchu.
  Trzecia runda: klatki ze znacznikiem dla spoczynku i chodu PixelLab narysował w innej pozie (ręka uniesiona) niż
  czyste klatki (ręka przy biodrze), więc chwyt wypadał obok dłoni (w prawo nawet 6 px). Dłonie Wojciecha mają kolor
  skóry, a strój, włosy i buty nie (`_is_skin`), więc `_skin_hand` przyciąga środek pięści do plamy skóry: w spoczynku
  i chodzie - do dłoni z mieczem poniżej głowy (`HAND_ROWS`, strona z `SKIN_SIDE`), w atakach - najdalej `SKIN_SNAP`
  od chwytu i tylko w widokach od przodu (`SKIN_ATTACK_DIRS` - od tyłu kark udaje dłoń); plamy większe niż
  `HAND_MAX_PIXELS` to twarz. Ręczne poprawki pojedynczych klatek: `FIST_FIX`. W Młynku, Szarży i pchnięciu po Mgnieniu
  miecz celujący w stronę kamery albo od niej jest skrócony jak w perspektywie (`GROUND_SQUASH`, `MIN_FORESHORTEN`).

- [x] **Etap 3 animacji postaci z bronią** (listopad 2026, Wojciech): łuk i księga.
  Cięciwa rysowana w kodzie: `tools/bow_strings.py` wymazuje cięciwę z grafik łuków w ręku (`assets/weapons/*bow*.png`,
  przy okazji usuwa poziomą kreskę z `bow_t4*` i przesuwa ten łuk na chwyt - `FIX`) i zapisuje końce ramion do
  `scripts/bow_rig.gd` (`BowRig.TIPS`); po ponownym wygenerowaniu łuków (`pixellab_items.py`, `legend_held.py`) uruchom go
  znowu. Węzeł `BowString` (`scripts/bow_string.gd`, dziecko sprite'a broni) rysuje cięciwę od końca do końca, odciąga
  ją o naciąg (`pull`, w kolejnych klatkach z `Player.BOW_PULL`), przy naciągu kładzie strzałę, po puszczeniu drga
  (`TWANG_*`), a przy pełnym napięciu Grotu Swaroga drży (`tremble`). Grot Swaroga przy napinaniu pokazuje klatki
  `POWER_DRAW_FRAMES` ruchu `bow_power` (naciąg = napięcie), po puszczeniu - od `POWER_RELEASE_FRAME`.
  Nowe ruchy (PixelLab `skeleton-v3`, 8 klatek, opis bez słowa „bow” - inaczej model dorysowuje łuk):
  `bow_power` (własne pozy: rozkrok, naciąg za ucho, drżenie) - Grot Swaroga, Balista, Strzała Wichru; `bow_sky`
  (własne pozy, łuk celuje w górę - `BOW_SKY_TILT`) - Deszcz Strzał, Sokół; `bow_hop` (`hop_back` + `shoot_bow`) -
  Odskok, Sidła; Salwa i Szybka salwa to zwykły strzał dwa razy szybciej, raz za razem (osobny ruch wychodził
  z dorysowanymi łukami); Strzała tropiąca - zwykły strzał. Księga: `cast_push` (`shove`) - Kula ognia (też przy
  ładowaniu), Włócznia Marzanny, Łańcuch błyskawic, Kula Piorunów; `cast_self` (własne pozy: dłonie przy piersi,
  potem ramiona szeroko) - Tarcza Many, Krok przez Mgłę; `cast_down` - Fala piorunów, Kamień Runiczny; `cast_up`
  (`arms_overhead`) - Spadająca Gwiazda, Burza Peruna, Zamieć. Mapa umiejętność -> [ruch, czas, powtórzenia] to
  `Player.SKILL_MOVES`, a ruch włącza `Player.note_skill` (tylko wygląd, balans bez zmian).
  Chwyt w nowych ruchach: ten sam ruch szkieletowy puszczony na stanie „Znacznik” postaci w PixelLab (Wojciech
  z prętem w prawej dłoni, `e19cc73c-…`) daje klatki `mk_<ruch>_<kierunek>_<i>.png` (cięte `hero_frames_cut.py`
  jako ruch `mk_<ruch>`); `hero_sheets.py` czyta pręt przez `_rod_ends(…, sword=False)` (szerszy odcień błękitu, sam
  różowy koniec wystarczy), klatki bez pręta dostają chwyt w pół drogi, a pierwsza i ostatnia - chwyt spoczynku
  (`_fill_between`), chwyt obok sylwetki przyciąga `_nearest_opaque`. Śledzenie dłoni po samym kolorze skóry nie
  działało (myliło dłoń z twarzą i karkiem). Zrzuty w grze: `tools/anim_shots.gd` (ruchy shot, power, sky, hop, rapid,
  cast, push, self, down, up). Dalej (etap 4, na później): nowe pozy ciała.

- [x] **Etap 4 animacji postaci** (listopad 2026, Wojciech): nowe pozy ciała, wspólne dla wszystkich broni, bez
  animacji trafienia (żeby nie przerywała ataków). Spoczynek z oddechem (`idle`, ruch `idle`, 8 klatek, w grze
  `Player.IDLE_FPS`) i chód po 8 klatek (ruch `walk`; tempo `WALK_FPS` liczone na 4 klatki, `WALK_BASE_FRAMES`);
  inni bohaterowie zostają przy starym spoczynku z obrotu i 4 klatkach chodu. Zryw (`dash`, własne pozy: niski
  doskok, potem wyhamowanie) trwa czas zrywu i jeszcze `DASH_RECOVER` - zryw w grze trwa tylko 0,14 s, więc przewrót
  by się nie zmieścił. Upadek przy śmierci (`death`, ruch `fall_back`, `DEATH_ANIM_TIME`, potem postać leży i znika)
  zamiast przewrócenia sprite'a; martwa postać nie trzyma broni, więc upadek nie ma znaczników, a `_physics_process`
  martwej postaci odświeża już tylko animację. Ostatnia klatka upadku w dwóch kierunkach to kopia przedostatniej
  (`FRAME_FIX`). Chwyt jak w etapie 3 ze znaczników stanu „Znacznik” (`STAGE4_MOVES`, `_marker_state`); gdy widać
  tylko różowy koniec pręta, kąt z sąsiedniej klatki (`_fill_angles`, `_tipless`), a spoczynek i chód z prętem prawie
  stale za plecami (północ, mniej niż `MIN_RODS` klatek z prętem) biorą chwyt ze starego znacznika spoczynku
  `mk_idle_<kierunek>.png`. Zrzuty: `tools/anim_shots.gd` (ruchy idle, walk, dash, death).
- [x] **Dźwięki trafień zależne od broni** (listopad 2026): `tools/hit_sfx.py` składa je z nagrań CC0 w `sfx_src/hits`
  (źródła i licencje w `sfx_src/hits/ZRODLA.md`: Impact qubodupa, Medieval Weapon impacts, Basic Spell Impacts
  lentikuli) - przycina czary do początku uderzenia (`onset`, skok głośności), dokłada mięsiste plaśnięcie i niskie
  tąpnięcie (`thump`). Dźwięki w `Sfx.SOUNDS`: `hit_blade` (miecz), `hit_arrow` (strzały i pociski bez żywiołu),
  `hit_fire`, `hit_ice`, `hit_lightning`, `hit_magic` (pocisk księgi, z nagrań wody), `hit_crit` (warstwa przy ciosie
  krytycznym) i `enemy_die` (teraz `kill_*`: podwójne plaśnięcie z trzaskiem kości, przy każdej śmierci potwora).
  Wybór: `Player.hit_enemy(..., sound)` ustawia na czas ciosu `Goblin.hit_sound` (bez `sound` - według broni,
  `Player.HIT_SOUNDS`; pociski - według `fire`/`fx_kind`/`magic`, czary piorunów i Zamieć podają żywioł same);
  potwór gra go w `play_hit_sound` (w bossa o 2 dB głośniej; boss dotąd nie miał odgłosu trafienia). Ciosy
  sojuszników, pułapek itp. zostają przy zwykłym `hit`. Test: `tests/test_audio.gd`.
  Poprawka: trafienia czarów i strzał grają daleko od postaci, a `AudioStreamPlayer2D` ze zwykłym cichnięciem
  (`Sfx.ATTENUATION` 1,6) ściszał je o 10-15 dB względem miecza - trafienia gracza mają łagodne `HIT_ATTENUATION`
  (piąte pole w `Sfx.SOUNDS`). Widmowe Ostrza i strzały tropiące podają swój dźwięk same (po zmianie broni
  krążące ostrza grały `hit_magic`).
- [x] **Szersze okno tierów premii** (listopad 2026, `Loot.best_tier`, `tier_reach`, `top_tier`, `roll_tier`): zwykłe
  okno 10 tierów sięga tieru 1 już od poziomu przedmiotu 90 (`TIER_TOP_LEVEL`, wcześniej 100). Ponad oknem pasmo
  szczęścia: 3 + 15 x (poziom / 60)^2 tierów, pierwszy z szansą 3% (`TIER_LUCK`), każdy następny 0,8 razy rzadszy -
  razem 7-15% premii trafia ponad okno. Najlepszy możliwy tier: poziom 20 - 31, 40 - 16, od 60 - tier 1. Szansa na
  tier 1 (jedna premia rzadkiego): poziom 60 - 0,13%, 70 - 0,4%, 80 - 1,2%, 90 - 19%. Wzorem PoE najwyższe tiery są
  dostępne przed maksymalnym poziomem, a najsłabsze przedmioty nie dostaną najwyższych tierów. Test: `tests/test_loot.gd`.

- [x] **Pasek umiejętności - punkty umiejętności z osobnego paska doświadczenia** (listopad 2026, jak w BDO;
  odpowiedzi autora: 4 progi paska, koszty 1/2/3/5, stare zapisy - reset ze zwrotem, cofanie - złoto za punkt):
  - pasek (`SkillBook.skill_xp`, `earned_points`, `skill_xp_progress`) napełnia się całym zwykłym expem
    (`CharacterStats.add_xp` -> `SkillBook.add_skill_xp`, sygnał `skill_points_gained` - napis w HUD), bez końca;
    cena punktu stała między progami `Skills.SKILL_XP_BANDS`: punkty 1-20 po 2000 exp, 21-60 po 15 000, 61-120 po
    60 000, dalej po 200 000 (ok. 20 punktów na 14. poziomie, 60 na 43.); fioletowy pasek pod paskiem expa w HUD
    (`HUD.skill_xp_bar`, tworzony w kodzie), napis „+N pkt [K]” obok „+N pkt [C]”;
  - punkty umiejętności = pasek + `SkillTree.START_POINTS` (teraz 2, dawniej 1 + 1 za 1. poziom) + nagrody zadań;
    wydaje się je na węzły i poziomy umiejętności (`SkillBook.points_in` - węzły broni i poziomy jej umiejętności);
  - poziomy umiejętności 1-20 (`Skills.MAX_LEVEL`), koszt `Skills.LEVEL_POINTS`: 1-5 po 1, 6-10 po 2, 11-15 po 3,
    16-20 po 5 (poziom 1 umiejętności drzewka daje sam węzeł); wzory rozciągnięte przez `Skills.power` (1-5 pełny
    przyrost, dalej po pół - poziom 20 działa jak dawny 12,5) i `Skills.count` (skoki, przebicia, strzały: +1 co
    3 poziomy ponad 5. - poziom 20 daje +10); górne granice: stożek Fali piorunów 180°, prędkość Szarży 640;
  - cofanie za złoto `Skills.REFUND_GOLD_PER_LEVEL` (8) x poziom postaci za punkt: węzeł prawym przyciskiem
    (węzła umiejętności z poziomami ponad 1 nie da się cofnąć - najpierw poziomy), poziom przyciskiem „Cofnij poziom”
    (`SkillBook.downgrade`, `downgrade_gold` - za tyle punktów, ile kosztował poziom), całe drzewko u mędrca
    (`VillageServices._respec` - wszystkie punkty broni, także poziomy umiejętności);
  - awans daje 2 punkty statystyk (`CharacterStats.POINTS_PER_LEVEL`), `ATTRIBUTE_RULES` 3: stary zapis dostaje
    darmowy reset atrybutów i brakujące punkty;
  - stare zapisy (bez `skill_xp`): `SkillBook.migrate_old` po wczytaniu statystyk - złoto za poziomy 2+ (dawne ceny
    `Skills.OLD_*_GOLD`) wraca do sakwy, węzły i poziomy wracają jako punkty, kamienie z gniazd drzewek do plecaka,
    pasek dostaje cały exp postaci (`CharacterStats.total_xp`); okno K pokazuje informację o zwrocie;
  - testy w `tests/test_skill_tree.gd` (progi, koszty, cofanie, przeliczenie); testy, które dawały punkty poziomem
    postaci, dostają je w `bonus_points`;
  - do ustalenia po ograniu: progi paska, cena cofania, siła poziomów 6-20 (`Skills.power`), czy 2 punkty na start
    wystarczą (pierwszy punkt z paska ok. 5. poziomu postaci).
- [x] **Wspólne drzewko umiejętności, krok 2** (`docs/plan_drzewek.md`, listopad 2026): jedno drzewko zamiast drzewek
  miecza, łuku i księgi. Dane generuje `python tools/shared_tree_draft.py` (jedno źródło: rysunek
  `docs/drzewko_wspolne.png`, lista `docs/drzewko_wspolne_wezly.md` i `scripts/skill_tree_data.gd` - `SkillTreeData.NODES`,
  `CLUSTERS`, `REGIONS`); identyfikatory węzłów są w zapisach (umiejętności - id z `Skills.DATA`, dawne węzły kluczowe -
  stare id, gniazda `socket_<skupisko>`, legendarne `legend_<skupisko>`, ścieżki `p_<od>_<do>_<n>`). 235 węzłów, z tego
  47 **pustych miejsc** (`"soon"` - nowe umiejętności, aury, nowe węzły kluczowe i znaczące bez premii w grze): widać je
  przygaszone z kreskowaną obwódką, nie da się ich wybrać, a drzewko przechodzi przez nie za darmo
  (`SkillBook.reachable`). Gdy puste miejsce dostanie działanie, zapisy z węzłami za nim trzeba obsłużyć (np. dać je za darmo).
  `SkillTree` i `SkillBook` bez rodzaju broni (`take(id)`, `tree_bonus(stat)`, `has_keystone(id)`, `gem_in(id)`,
  `essences()` - esencje ze wszystkich gniazd legendarnych, `grant_node(id)` dla testów i narzędzi). Premie z węzłów
  i kamienie w gniazdach działają z każdą bronią (statystyki i tak idą po tagach - `CharacterStats.kind_multiplier`),
  węzły kluczowe też: Krwawy Szał z każdym krwawieniem, Krew za Manę (dawna Ofiara Krwi) i Pełnia Mocy / Harmonia
  z każdą bronią, Myśliwy z Cienia po każdej umiejętności ruchu (`Player.note_skill` -> `BowSkills.on_movement`), Oko
  Sokoła przy każdym trafieniu. Nowe statystyki `mana_percent` i `armor_percent`. 6 umiejętności regeneracji usunięte
  (zastępują je skupiska Krzepa / Mana i przyszłe aury). Okno K bez zakładek broni (`ui/skill_window.gd`), widok
  `ui/skill_tree_view.gd` z tłem stron, podpisami skupisk (przy przybliżeniu), obwódką umiejętności w kolorze broni
  i opisem „Działa tylko z bronią: …”. Mędrzec zapomina całe drzewko. Stare zapisy (bez `"tree": 2` w umiejętnościach):
  węzły i poziomy umiejętności przepadają - wszystkie punkty wracają (`SkillBook.tree_reset`, napis w oknie K), kamienie
  i esencje z gniazd wracają do plecaka (`take_reset_gems`). Zrzut okna: `SCRIPT=tools/skill_tree_shot.gd tools/screenshot.sh /tmp/drzewko`.
  Punkty w końcówce (pasek + 2 na start + ok. 10 z zadań): ok. 60 na 40. poziomie, 75 na 50., 93 na 70., 121 na 90.;
  drzewko ma 188 węzłów do wybrania (jedna strona ze strefami ok. 80, dawne drzewko broni 55), więc decyzją autora
  dochodzi **1 punkt co 2 poziomy postaci** (`SkillBook.LEVEL_POINT_EVERY`, `level_points`, `set_character_level` -
  napis „+1 punkt umiejętności” przy awansie): +25 na 50. poziomie, +45 na 90.
- [x] **Aury rezerwujące manę - krok 3 wspólnego drzewka** (`docs/plan_drzewek.md`, listopad 2026): 10 aur działających
  z każdą bronią (`Skills.DATA` type `"aura"`, weapon `"any"`, `Skills.works_with`). Dane i liczby w `scripts/aura_data.gd`
  (`AuraData` - bez odwołań do dźwięków, żeby `Skills` i `SkillBook` działały w testach bez okna), działanie w grze
  w `scripts/auras.gd` (`Player.auras`, dziecko gracza). Klawisz paska włącza i wyłącza aurę (`Auras.toggle`), włączone
  trzyma `SkillBook.auras` (zapis gry, pole `"auras"`), premie do statystyk `SkillBook.aura_bonus` (w `CharacterStats._bonus`).
  **Rezerwacja** (decyzja autora - „jak w PoE”, ułamek pełnej many, `AuraData.RESERVE`): Postrach, Krzepa, Wiatr Strzyboga
  30%, Źródło Życia 20%, Źródło Many 15%, Żar Swaroga / Szron Marzanny / Iskry Peruna po 25%, Gniew Peruna 35%, Mroźny
  Oddech 0% (zamiast many rani gracza 4% zdrowia/s, mniej z odpornością na lód, nie zabija). `CharacterStats.max_mana`
  zwraca manę bez rezerwacji (`full_max_mana`, `reserved_mana`), więc włączenie aury zabiera tyle many, a wyłączenie ją
  oddaje; aura nie włączy się bez wolnej many (`SkillBook.aura_block_reason`), suma rezerwacji najwyżej 100%.
  Węzły Skupiona wola (-10%) i Oszczędne aury (-8%) - statystyka drzewka `aura_reservation` (mnożnik rezerwacji);
  węzeł kluczowy **Krwawa Ofiara** (`blood_offering`) - aury rezerwują ten sam procent zdrowia (najwyżej 90%,
  `reserved_health`). Działanie (siła rośnie z poziomem aury - `Skills.power`): Postrach - wrogowie w promieniu 150 zadają
  10-21% mniej obrażeń (`Player.take_damage`) i atakują 8-16% wolniej (`Goblin._process_attack`); Krzepa +12-23% zdrowia;
  Wiatr Strzyboga +8-14% ruchu, ataku i rzucania; Źródło Życia 1-3,3% zdrowia/s i Źródło Many 1,25-4,1% many/s
  (`health_regen_percent`, `mana_regen_percent`); aury żywiołów +12-35% obrażeń dodanych jako żywioł do wszystkich ataków
  i czarów (`aura_added_<żywioł>`, `CharacterStats.added_element`) i +6-17% szansy na stan; Gniew Peruna - co 3 s piorun
  140-370% obrażeń w losowego wroga do 220 (efekt Burzy Peruna); Mroźny Oddech - wir w promieniu 70 co 0,5 s 36-105%
  obrażeń od lodu i +22-45% obrażeń od lodu. Wygląd rysowany w kodzie: ikony `tools/aura_icons.py`
  (`assets/skills/aura_<id>.png`), kręgi pod stopami w kolorze aury, zasięg Postrachu i wiru, na pasku włączona aura
  świeci ramką w swoim kolorze (`HotbarSlot.set_aura`), ikona pod paskami zdrowia i many (`Auras.statuses`), a pasek many
  (z Krwawą Ofiarą - zdrowia) liczy od pełnego maksimum i szary pas z prawej pokazuje część zarezerwowaną (`HUD._show_reserved`).
  Stare zapisy: węzły, przez które drzewko dotąd przechodziło za darmo (`SkillBook.FORMER_SOON`), dostaje się za darmo
  (+1 punkt za każdy), gdy inne wybrane węzły łączą się przez nie ze startem (`SkillBook.repair_paths`). Test `tests/test_auras.gd`.
  Do ustalenia po ograniu: liczby rezerwacji i siły, czy aury mają mieć gniazda na kamienie wsparcia, animacje ataków
  aur żywiołów z kreatora efektów PixelLab.
- [x] **Nowe combo - krok 4 wspólnego drzewka** (`docs/plan_drzewek.md`, listopad 2026). Autor wybrał wszystkie 10 combo
  z tabeli w planie. `Skills.COMBOS` pozwala mieć kilku poprzedników z różnym combo - `Player.combo_after(id)` mówi, po
  której umiejętności combo zadziała (`combo_with` to skrót „czy w ogóle”). Liczby w `Skills` (stałe pod `COMBOS`):
  - **Mgnienie -> Riposta**: Mgnienie pamięta 4 ostatnio trafione cele (`SwordSkills._flicker_marks`,
    `Skills.FLICKER_MARKS`); Riposta zaraz po nim (`_marked_ripostes`) - na każdym wybucha kontra Riposty (pełne
    obrażenia kontry razy premia combo, ogłuszenie 0,5 s, promień jak kontra), co 0,08 s; zasłona działa jak zwykle;
  - **Rozpłatanie -> Widmowe Ostrza**: ostrza od razu wylatują (każde do innego wroga), a w celu robią Rozpłatanie
    (`SpectralBlades.on_hit`, `SwordSkills._blade_rend`: cios i krwawienie Rozpłatania w promieniu 0,6 jego zasięgu);
  - **Widmowe Ostrza -> Młynek**: burza ostrzy (`SwordSkills.blade_storm`) - 2x więcej ostrzy, 2,2x szybciej,
    orbita 1,6x, trafienia co 0,27 s, przez 3 s (`BLADE_STORM_*`, `SpectralBlades.spin_speed`, `hit_interval`);
  - **Rozłupanie Ziemi -> Szarża**: Rozłupanie zapamiętuje miejsca kolców na 3 s (`_spikes`, `SPIKE_TIME`); Szarża zaraz
    potem (`SwordSkills.explode_spikes`) wysadza je jeden po drugim (promień 26, 100% obrażeń Rozłupania, każdy wróg raz);
    Szarża kosztuje wtedy manę jak zwykle (darmowa jest tylko po Ripoście);
  - **Sidła -> Deszcz Strzał**: `_Rain.focus` - strzały spadają też na unieruchomionych wrogów do 2,5 promienia deszczu
    od środka (`RAIN_FOCUS_REACH`, `BowSkills.is_snared`);
  - **Odskok -> Grot Swaroga**: napinanie zaczyna się od pełnego napięcia (`BowSkills._start_power`); wybuch ognia
    zostaje tylko po Strzale tropiącej;
  - **Sokół -> Strzała Wichru**: drugi podmuch z miejsca sokoła w stronę kursora (`_wind_gust` z `from`);
  - **Zamieć -> Kula ognia**: `Projectile.exploded` (nowy sygnał), `Player._fireball_shatter`, `SpellSkills.fire_shatter` -
    spowolnieni lodem wrogowie w wybuchu (do 1,5 promienia) pękają: lód i ogień po 50% obrażeń kuli w promieniu 30 wokół
    każdego (każdy wróg raz);
  - **Kamień Runiczny -> Łańcuch błyskawic**: po pierwszym celu błyskawica przeskakuje przez kamień (`SpellSkills.rune_at`,
    `Player._rune_zap`), dalej jest 1,5x mocniejsza i ma 2 przeskoki więcej (`RUNE_CHAIN_*`);
  - **Krok przez Mgłę -> Spadająca Gwiazda**: gwiazda spada tam, skąd zniknęła postać (`SpellSkills._blink_from`).
  **Półksiężyc, Szybka salwa i Fala piorunów** są zwykłymi umiejętnościami drzewka (type `"skill"`, bez `"requires"`):
  własny slot na pasku, odnowienie 2 / 2 / 1,5 s (`CRESCENT_COOLDOWN`, `VOLLEY_COOLDOWN`, `WAVE_COOLDOWN`), manę i combo
  liczy `Player.use_followup`. Zaraz po swoim uderzeniu (Szarża, Strzała tropiąca, Łańcuch błyskawic) są darmowe i zadają
  1,5x obrażeń (`FOLLOWUP_COMBO_DAMAGE`, razy premia combo z drzewka). Zniknęły typ `"combo"`, okno dodatkowego ciosu
  (`_combo_window`) i `SkillBook.combo_for`; atak po uderzeniu to zwykły atak. Stare zapisy: umiejętności zostają, ale
  trzeba je położyć na pasek z okna K. Test `tests/test_combos.gd`.
  Do ustalenia po ograniu: liczby combo, odnowienia trzech dawnych ciosów.
- [x] **Krok 5 wspólnego drzewka, strona siły** (`docs/plan_drzewek.md`, listopad 2026). Autor wybrał: najpierw strona
  siły, cała naraz; efekty z kreatora efektów PixelLab; przywołania (Wataha, Błędne Ogniki, Wierny tropiciel) na koniec,
  osobno. Wszystkie puste miejsca strony siły działają (`soon=False` / `stats` w `tools/shared_tree_draft.py`):
  - **Wilczy Kieł** (`SwordSkills._wolf_fang`): 4 pchnięcia co `FANG_INTERVAL` (szybsze z szybkością ataku) w wroga
    najbliższego kursora w zasięgu `FANG_REACH` (`_fang_target`), ostatnie x`FANG_FINAL` i ogłuszenie `FANG_FINAL_STUN`;
    „przebija pancerz” z planu zmienione na „rozdziera i ogłusza” (potwory nie mają pancerza). Obrażenia `Skills.fang_damage`;
  - **Ryk Tura** (`_bull_roar`): w zasięgu `ROAR_RADIUS` wrogowie tracą strach (`_fear_time`) i gonią postać (`aggro`),
    premia `armor_percent` `Skills.roar_armor` przez `ROAR_TIME` (`set_temp("sword")`, ikona w efektach);
  - **Skok Niedźwiedzia** (`_bear_leap`, `Player.start_leap` / `is_leaping`): lot pod kursor do `LEAP_RANGE` przez
    `LEAP_TIME`, ponad przeszkodami jak zryw (`JUMP_MASK`, `free_landing`), w locie nietykalność; po wylądowaniu
    `_leap_landed` - obrażenia `Skills.leap_damage` i odrzut `LEAP_KNOCKBACK` w promieniu `LEAP_RADIUS`;
  - węzły: **Wciągający wir** (`whirl_pull` - Młynek przyciąga do `Player.WHIRL_PULL_REACH` promienia z siłą `WHIRL_PULL`),
    **Donośny głos** (`cry_radius` +40%, `cry_cooldown` -20% - Zew Peruna i Ryk Tura, `SwordSkills.cry_radius_factor`),
    **Pełnia Sił** (`full_strength`: +1% za każde 5% zdrowia ponad połowę, do +10%), **Gniew rannego** (`wounded_wrath`:
    +1% za każde 5% brakującego, do +20%) - oba w `SwordSkills.health_damage_factor`, mnożnik w `Player.hit_enemy`;
    **Wstrząs** (`tremor_stun` 0,3 s: trafienie umiejętnością obszarową miecza ogłusza, każdego wroga najwyżej raz na
    `Skills.TREMOR_INTERVAL` - `SwordSkills.tremor`); węzły z opisem zamiast liczby mają w danych `description`
    (`N(..., game=...)`), okno pokazuje opis;
  - **Ostatni Bastion** (węzeł kluczowy): poniżej `BASTION_HEALTH` (30%) zdrowia +50% obrażeń i połowa otrzymanych
    (`bastion_active`, `bastion_taken` w `Player.take_damage`), ikona w efektach.
  Efekty z kreatora (`pixellab_src/vfx/ids.json`): `wolf_fang` (smuga pchnięcia), `bull_roar` (fala z pyłem, rysowana
  w 70% przezroczystości), `bear_leap` (pęknięcia, pył, odłamki). Ikony tymczasowe - przebarwienia (`tools/strength_icons.py`),
  docelowo paczka ikon z PixelLab. `SkillBook.FORMER_SOON` - nowe węzły przechodzą stare zapisy za darmo jak w kroku 3.
  `SkillEffects.sheet_once` zwraca węzeł efektu. Test `tests/test_strength_side.gd`.
  Do ustalenia po ograniu: liczby (stałe `FANG_*`, `ROAR_*`, `LEAP_*`, `BASTION_*`), czy Wstrząs ma działać z Młynkiem.
  Ikony tymczasowe zastąpiła paczka PixelLab ze strony zręczności (niżej).
- [x] **Krok 5 wspólnego drzewka, strona zręczności** (`docs/plan_drzewek.md`, listopad 2026). Autor wybrał: Strzała Żmija
  jadowa, Kolczatka rzucana pod kursor, Szał Bitewny przyspiesza atak i ruch, jedna paczka ikon na obie strony.
  Wszystkie puste miejsca strony zręczności poza przywołaniami (Wataha, Wierny tropiciel) działają:
  - **Strzała Żmija** (`BowSkills._viper_arrow` / `_launch_viper`): strzała przeskakuje `VIPER_JUMPS` razy
    (`Projectile.chain`, własny zasięg `Projectile.chain_range` = `VIPER_RANGE`), po każdym trafieniu obrażenia
    +`VIPER_GROWTH`, trafiony zatruty (`BowSkills.poison`, `VIPER_POISON` obrażeń trafienia, więcej z Żmijowym jadem);
  - **Rozszczepiona Strzała** (`_split_arrow`, `_split_shards`): po pierwszym trafieniu `SPLIT_SHARDS` mniejszych strzał
    wachlarzem `SPLIT_SPREAD_DEGREES` dalej, omijają trafionego (`Projectile.ignore`);
  - **Kolczatka** (`_scatter_caltrops`, klasa `_Caltrops` - kolce rysowane w kodzie na warstwie podłogi): pole pod kursorem
    (`CALTROPS_RANGE`), co `CALTROPS_TICK` s rani (`Skills.caltrops_damage`, więcej z węzłów krwawienia) i spowalnia
    (`CALTROPS_SLOW`), najwyżej `CALTROPS_MAX` naraz;
  - węzły: **Szereg** (`row_shot` - `Player.row_offsets`: główna strzała Salwy, Odskoku, Grotu Swaroga, Strzały
    tropiącej, Żmija i Rozszczepionej ma towarzyszkę obok, w odstępie `Player.ROW_GAP`; Szybka salwa +1 strzała),
    **Ciche kroki** (`silent_steps` - `Goblin.notice_factor` = `BowSkills.SILENT_NOTICE`, też ogniki i czerwie),
    **Oddech w biegu** (`running_breath` - premia `health_regen` w `set_temp("running_breath")`, ikona w efektach);
  - **Łowca w Cieniu** (węzeł kluczowy, z każdą bronią): wróg w spoczynku albo wracający (`BowSkills.unseen`) dostaje
    x`STALKER_UNSEEN` i zawsze krytyk, walczący x`STALKER_FIGHTING` (`damage_factor`, `forced_crit`);
  - **Szał Bitewny** (węzeł kluczowy, z każdą bronią): `Goblin._die` woła `BowSkills.on_kill` - ładunek (do `FRENZY_MAX`)
    +`FRENZY_ATTACK` szybkości ataku i +`FRENZY_MOVE` ruchu (`set_temp("frenzy")`), po `FRENZY_TIME` s bez zabójstwa
    wszystkie znikają; ikona z licznikiem w efektach.
  Efekty z kreatora (`pixellab_src/vfx/ids.json`): `viper_bite`, `split_burst`, `caltrops_scatter`, `battle_frenzy`.
  Ikony: paczka 16 ikon PixelLab (10 generacji, `pixellab_src/shared_tree/`, `tools/tree_step5_icons.py`) - nowe
  umiejętności i węzły obu stron, także zamiast przebarwień strony siły (dawne `tools/strength_icons.py` usunięte).
  Stare zapisy przechodzą przez nowe węzły za darmo (`SkillBook.FORMER_SOON`). Test `tests/test_dex_side.gd`.
- [x] **Krok 5 wspólnego drzewka, strona inteligencji** (`docs/plan_drzewek.md`, listopad 2026). Autor wybrał: Ściana Ognia
  pod kursorem, Lodowy Pancerz jako tarcza z lodu, Mistrz Żywiołów jak w opisie, paczka ikon także na zapas (strefy,
  przywołania). Wszystkie puste miejsca strony inteligencji poza przywołaniami (Błędne Ogniki, Wierne ogniki) działają:
  - **Ściana Ognia** (`SpellSkills._fire_wall`, klasa `_FireWall`): odcinek długości `WALL_LENGTH` w poprzek drogi od
    gracza do kursora (`WALL_RANGE`), płomienie z kreatora co `WALL_FLAME_GAP`; co `WALL_TICK` s rani (`Skills.wall_damage`,
    więcej z Tlącego się ognia) i podpala (`SpellSkills.burn`, `WALL_BURN`), najwyżej `WALL_MAX` ścian naraz; pocisk gracza
    (grupa `player_projectiles`, `Projectile`) lecący przez ścianę się zapala (`Projectile.ignite`) - każde jego trafienie
    dokłada `WALL_IGNITE` obrażeń jako ogień, smuga strzały robi się pomarańczowa;
  - **Lodowy Pancerz** (`_ice_armor`, `absorb_ice` - w `Player.take_damage` przed Tarczą Many): tarcza na `ICE_ARMOR_TIME` s
    z wytrzymałością `Skills.ice_armor_share` maksymalnego zdrowia (20% + 3% za poziom mocy, do 60%); gdy pęknie,
    `_ice_burst` rani (`Skills.ice_armor_damage`) i zamraża (`Goblin.freeze`, `ICE_ARMOR_FREEZE` s) wrogów w `ICE_ARMOR_RADIUS`;
    po czasie znika bez wybuchu; ikona z pozostałą wytrzymałością w efektach;
  - węzły: **Przelana moc** (`mana_flow` - `SpellSkills.mana_flow` po Tarczy Many: 8% ciosu zabiera mana, póki starcza),
    **Pełnia umysłu** (`full_mind` - `SpellSkills.full_mind_bonus`: +1% `damage_percent` za każde 5% many ponad połowę,
    do +10%, w `set_temp("spell")`, ikona w efektach);
  - **Mistrz Żywiołów** (węzeł kluczowy, z każdą bronią): `SpellSkills.on_hurt` zapamiętuje żywioł ciosu (ogień, lód,
    piorun; fizyczne i Nawia nie zmieniają), `Player.hit_enemy` zamienia odgłos trafienia na ten żywioł (`master_sound`
    - odporności, stany i dźwięk) i mnoży obrażenia x`1 + MASTER_BONUS` (`master_factor`); wir w kolorze żywiołu przy
    zmianie, ikona z bieżącym żywiołem w efektach.
  Efekty z kreatora (`pixellab_src/vfx/ids.json`): `fire_wall` (płomień, pętla), `ice_armor` (skorupa z heksów, pętla -
  półprzezroczyste wypełnienie odtworzone z alfą 0x26, bo arkusz z `join` je spłaszcza), `ice_armor_burst`, `elem_shift`
  (biały, barwiony w grze). Ikony: druga paczka 16 ikon PixelLab (10 generacji, `pixellab_src/shared_tree/icons_step5_int.png`,
  `tools/tree_step5_icons.py`) - 5 ikon strony inteligencji i na zapas: Ciśnięte Noże, Rozpęd, Otwarte rany, Strzała Gromu,
  Zwiewność, Zaklęte Ostrze, Żelazna Wola, Błędne Ogniki, Wierne ogniki, Wataha, Przewodnik stada (pliki w `assets/skills/`,
  jeszcze niepodpięte; Wierny tropiciel nie ma ikony). Stare zapisy - `SkillBook.FORMER_SOON`. Test `tests/test_int_side.gd`.
  Do ustalenia po ograniu: liczby (`VIPER_*`, `SPLIT_*`, `CALTROPS_*`, `STALKER_*`, `FRENZY_*`), czy Szał ma przyspieszać
  też rzucanie czarów, czy Szereg ma dawać towarzyszkę każdej strzale wachlarza.

- [x] **Krok 5 wspólnego drzewka, strefy pośrednie** (`docs/plan_drzewek.md`, listopad 2026). Autor wybrał: umiejętności
  działają z obiema broniami strefy i z każdą trochę inaczej, „Rozpęd” przemianowany na **Impet** (nazwa zajęta przez
  kamień wsparcia), Zwiewność - szybkość ruchu i ataku, Żelazna Wola bez kosztu. Nowy skrypt `scripts/zone_skills.gd`
  (dziecko gracza `Player.zone_skills`, jak `SwordSkills`); umiejętność z bronią `"a/b"` idzie tam z `Player._press_slot`
  i `cooldown_of`. `Skills.works_with` rozumie `"melee/bow"`, `Skills.weapon_name` daje „Broń biała albo łuk”,
  `Skills.tags(id, broń)` - tagi odmiany z `Skills.HYBRID_TAGS` (np. Strzała Gromu z łuku to atak, z księgi czar;
  `TAGS` trzyma wszystkie razem dla okna drzewka), `Player._make_projectile(..., tags)` przyjmuje tagi odmiany:
  - **Ciśnięte Noże** (miecz albo łuk; `KNIVES_*`): wachlarz 3 noży z krwawieniem (`SwordSkills.bleed_enemy` z tagami
    umiejętności). Z mieczem `ZoneSkills._Knife` - leci `KNIVES_MELEE_RANGE` i wraca do gracza, w każdą stronę trafia
    każdego wroga raz; z łukiem zwykły pocisk (rodzaj `"knife"` w `Projectile.FX`, `Projectile.sound`) na `KNIVES_BOW_RANGE`;
  - **Strzała Gromu** (łuk albo księga; `THUNDER_*`): pocisk `"thunder"`; z łuku trafienie przeskakuje piorunem
    (`SpellSkills.lightning`) na `THUNDER_JUMPS` najbliższych wrogów (więcej z kamieniem Łańcuch), z księgi w miejsce
    trafienia uderza piorun z nieba (`STORM_FX`) i rani wrogów w `THUNDER_STRIKE_RADIUS`;
  - **Zaklęte Ostrze** (miecz albo księga; `BLADE_*`): płonąca fala `ZoneSkills._FlameWave` podpala (`SpellSkills.burn`,
    `BLADE_BURN`); z mieczem najpierw cięcie przed sobą (`Traveler.SLASH_FX` w kolorze ognia) i krótka fala
    (`BLADE_WAVE_MELEE`), z księgą dłuższa i szersza (`BLADE_WAVE_SPELL`, mocniejsza);
  - węzły: **Otwarte rany** (`open_wounds` - `ZoneSkills.on_hit` z `Player.hit_enemy`: trafienie z tagiem cios / pocisk
    z szansą wywołuje krwawienie `OPEN_WOUNDS_BLEED` obrażeń - `SwordSkills.bleed_total`), **Impet** (id węzła `momentum`,
    premia `impetus` - po umiejętności ruchu następne trafienie w `IMPETUS_TIME` s +30%, `ZoneSkills.damage_factor`),
    **Zwiewność** (`lightness` - `ZoneSkills.on_dodge` z uniku w `Player.take_damage`: na 2 s szybkość ruchu, ataku
    i rzucania w `set_temp("lightness")`); Impet i Zwiewność mają ikony w efektach;
  - **Żelazna Wola** (węzeł kluczowy): `CharacterStats.attribute_damage` - czar liczy siłę zamiast inteligencji.
  Myśliwy z Cienia działał już wcześniej (po każdej umiejętności ruchu). Ikony z paczki `icons_step5_int` podpięte.
  Efekty z kreatora (`pixellab_src/vfx/ids.json`): `thrown_knife` (wirujący nóż, 4 klatki - kreator obraca tylko
  o ćwiartki), `flame_wave` (ognisty sierp), `thunder_arrow` (strzała-błyskawica). Stare zapisy - `SkillBook.FORMER_SOON`.
  Test `tests/test_zone_skills.gd`. Do ustalenia po ograniu: liczby (`KNIVES_*`, `THUNDER_*`, `BLADE_*`, szanse
  i siła węzłów w szkicu drzewka), czy noże z mieczem mają trafiać w powrocie z pełną siłą.
- [x] **Krok 5 wspólnego drzewka, przywołania** (`docs/plan_drzewek.md`, listopad 2026). Autor wybrał: przywołańcy
  **stali i rezerwują manę** (jak aury), **mają zdrowie i gonią wrogów** (potwory mogą ich zabić), z poziomem rośnie
  **wszystko** (obrażenia, zdrowie, liczba, mniejsza rezerwacja), grafiki **przebarwione z obecnych** (0 generacji).
  Ostatnie puste miejsca drzewka (`"soon"`) zniknęły. Dane i liczby w `scripts/summon_data.gd` (`SummonData` - bez
  dźwięków, jak `AuraData`), działanie w `scripts/summons.gd` (`Player.summons`, dziecko gracza). Klawisz paska
  przywołuje albo odsyła (`Summons.toggle`, rodzaj `"summon"` w `Skills.DATA`), przywołane trzyma `SkillBook.summons`
  (zapis gry, pole `"summons"`); rezerwację liczy `SkillBook.aura_reserve` razem z aurami (`reserved_total`, Skupiona
  wola, Oszczędne aury i Krwawa Ofiara też działają). Przywołanie działa tylko ze swoją bronią - po zmianie broni odchodzi.
  Liczba pilnowana co klatkę (`Summons._keep`): zabity wraca po `RESPAWN` (6 s), po zmianie krainy - od razu.
  - **Wataha** (łuk): wilki (`_Wolf`, `assets/forest/wolf.png` w widmowym błękicie - modulate) biegną do wroga najbliżej
    siebie w `WOLF_SEEK_RANGE` od gracza, gryzą co `WOLF_BITE_INTERVAL` s (`SummonData.damage` 55% + 10% za poziom mocy),
    z szansą `WOLF_STUN_CHANCE` powalają (`Goblin.stun`); bez wroga idą za graczem; 2 wilki, +1 na poziomach 10 i 20;
    rezerwacja 25% (-0,4% za poziom);
  - **Błędne Ogniki** (księga): ogniki (`_Wisp`, `assets/summons/wisp_fire.png` - turkusowy ognik z Cmentarza
    przebarwiony przez `tools/minion_art.py`) krążą wokół gracza i co `WISP_INTERVAL` s strzelają pociskiem `"fire"`
    (35% + 6% za poziom mocy, kamień Rozszczep - więcej pocisków); 3 ogniki, +1 na poziomach 10 i 20; rezerwacja 22%;
  - **Wierny tropiciel** (węzeł, id przywołania `"seeker"`): z tym węzłem klawisz Strzały tropiącej przywołuje widmową
    strzałę (`_Seeker`, rysowana w kodzie), która krąży przy graczu i co `SEEKER_INTERVAL` s wypuszcza Strzałę tropiącą
    (`Player.seeker_arrow` - wydzielone z `_cast_seeker`, z Szeregiem, Łukiem Hydry i Rozszczepem); stałe 15% many, bez zdrowia;
  - węzły **Przewodnik stada** i **Wierne ogniki**: +1 przywołaniec (`wolf_count`, `wisp_count`) i +15% obrażeń
    przywołań (`minion_damage`) - `SkillBook.summon_count`, `Summons.damage_of`.
  Zdrowie przywołańca: `health_share` maksymalnego zdrowia postaci (wilk 40% + 3% za poziom mocy, ognik 25% + 2%), kamień
  Watażka (`duration`) dokłada tyle procent zdrowia; cios potwora rani o `TAKEN` (60%). Trafiony przez wilka albo ognik
  wróg bierze go za cel (`Goblin.objective`, gdy gracz jest dalej niż 60 i wróg nie ma innego celu); przy odejściu
  przywołańca cel wraca na gracza. Obrażenia przez `Player._skill_damage` z tagami umiejętności - kamienie wsparcia
  w gniazdach przywołań (`Supports.has_sockets` przyjmuje rodzaj `"summon"`) i atrybuty działają. Wygląd: kłąb
  `MiscVfx.puff` w kolorze przywołania przy pojawieniu i odejściu, iskry ugryzienia `MiscVfx.spark`, pasek zdrowia nad
  rannym, na pasku przywołanie świeci ramką w kolorze (`ActionBars._summon_of`), ikona z liczbą przywołańców pod
  paskami zdrowia i many (`Summons.statuses`). Ikona węzła Wierny tropiciel złożona z ikon Strzały tropiącej i Wiernych
  ogników (`tools/loyal_seeker_icon.py`). Stare zapisy - `SkillBook.FORMER_SOON`. Test `tests/test_summons.gd`.
  Do ustalenia po ograniu: liczby (`SummonData`), czy kamienie wsparcia mają podnosić rezerwację (dziś nie), czy
  przywołańcy mają dostawać ciosy obszarowe potworów, własne grafiki z PixelLab (widmowy wilk, ognik).
- [x] **Bogatsze strefy pośrednie, autostrady i odporności we wspólnym drzewku** (pomysł autora, listopad 2026).
  Autor wybrał: +2 skupiska na strefę, autostrada wewnętrzna i zewnętrzna, na autostradach atrybuty i co kilka węzłów
  odporność albo zdrowie, maksymalna odporność +2% na węzeł z limitem 85%. Drzewko ma teraz 373 węzły (było 235),
  stare zapisy się nie zmieniają (tylko dochodzą węzły i połączenia, istniejące stoją w tych samych miejscach).
  - **Nowe skupiska stref** (`tools/shared_tree_draft.py`): siła/zręczność - Łowy (krwawienie, szybkość, krytyki,
    gniazdo) i Twarda skóra (pancerz, unik, regeneracja); zręczność/inteligencja - Wichura (pociski, szybkość, unik,
    gniazdo) i Gromochron (odporność na pioruny); siła/inteligencja - Kuźnia Swaroga (ogień, odporność na ogień)
    i Pieczęcie (rezerwacja aur, żywioły, zdrowie i mana, gniazdo). Skupiska odporności na stronach: Szron
    (inteligencja, lód) i Kurhan (siła, Nawia). Węzły znaczące tylko z premiami, które gra już znała.
  - **Maksymalna odporność**: premie `<żywioł>_max_resistance` (`CharacterStats.max_resistance`, sufit
    `Elements.MAX_RESISTANCE` 75% + premie, najwyżej `Elements.HARD_MAX_RESISTANCE` 85%); węzły Serce kuźni, Serce zimy,
    Serce burzy, Próg zaświatów (+2% każdy) na końcu skupisk odporności. Okno postaci pokazuje sufit, gdy jest wyższy niż 75%.
  - **Autostrady** (`RINGS` w szkicu): wewnętrzna (promień 14, stacje Burza i pociski, Aury, Krwawienie - przecina
    ścieżki stron w ich drobnych węzłach, więc działa jak skrót między stronami) i zewnętrzna (promień 31, stacje: nowe
    skupiska stref i odporności). Węzły `ring_<pierścień>_<stacja>_<n>`: +5 do atrybutu strony (w strefach +3/+3), co
    4. węzeł na zmianę +5% odporności na żywioły i +3% zdrowia. Łuk omija węzły skupisk (odsunięcie) i przechodzi przez
    drobne węzły ścieżek (skrzyżowanie) - `RING_CLEAR`. Wejścia tylko przez stacje (bez węzłów kluczowych).
  - Okno K: tło stron sięga dalej (`SkillTreeView.REGION_REACH` 34), można bardziej oddalić (najmniejsze przybliżenie 0,2).
  - **Wydajność**: `SkillBook.tree_bonus` zapamiętuje premie (`_bonus_cache`, czyszczone sygnałem `changed`) - przy
    kilkuset wybranych węzłach liczenie od nowa przy każdym zapytaniu statystyk wyraźnie spowalniało klatki.
  Testy: `test_elements` (sufit odporności, węzły i autostrady), liczby w `test_skill_tree` i `test_tree_sockets`.
  Do ustalenia po ograniu: liczby premii, czy autostrady nie są za tanim skrótem, podpisy stron nachodzące na węzły.

## Interfejs i walka (Pomysły i rzeczy do zrobienia)
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
  potwora - gdy zostanie pokonany. W trybie deweloperskim widać wszystko, a drugie kliknięcie w ten sam przedmiot daje jedną
  sztukę (legendę z poziomem postaci); pierwsze tylko pokazuje opis (`CodexWindow._clicked`, listopad 2026). Nowy potwór wymaga wpisu w `Codex.MONSTERS`.

- [x] **Szybkie poprawki z listopada 2026:**
  - węzeł kluczowy miecza **Oko Cyklonu** (`cyclone_eye`) zamiast Nieustającego Wiru: Młynek wciąga wrogów
    (ujemny odrzut trafionych, przyciąganie do 1,5 zasięgu) i rozkręca się o +25% obrażeń na sekundę, najwyżej +100%
    (`Player.whirl_spin_up`, `CYCLONE_*`), za dwa razy więcej many. Wirujące Mgnienie bez odnowienia zostało tylko
    na Amulecie Wiecznego Wiru; dawne zapisy z `endless_whirl` dostają Oko Cyklonu (`SkillBook.load_save_data`);
    ikona `ks_endless_whirl.png` przemianowana na `ks_cyclone_eye.png` (ta sama grafika);
  - cofanie punktów prawym przyciskiem: węzeł drzewka (`SkillBook.refund_reason` / `refund` - nie start, nie gniazdo
    z kamieniem i nie węzeł, przez który inne łączą się ze startem) i punkt atrybutu (`CharacterStats.refund_point`);
  - rzadsze legendy: bossowie 2% -> 1,2% za legendę, Gryf i Hydra 3% -> 2%, Żmij i Wij 25% -> 15%, skarbiec lochu
    12% -> 7%; zwykły potwór ma `Loot.WORLD_LEGEND_CHANCE` = 1/12000 na dowolną legendę z `Legends.DATA`
    (`Loot.world_legend`, bez zwierzyny i manekinów);
  - okna przesuwane za tło i skalowane Ctrl + kółkiem (`scripts/ui/window_drag.gd`, podpięte w `HUD._ready` do
    każdego `PanelContainer` poza dużą mapą; ustawienie w `Game.window_layouts` w `user://settings.cfg`, przycisk
    „Przywróć położenie okien”) i suwak „Skalowanie interfejsu” 75-150% (`Game.ui_scale`, `_apply_ui_scale`: rozciąganie
    ułamkowe z całkowitą krotnością razy skala, kamera gracza `zoom = 1 / ui_scale`, więc świat zostaje w całych
    pikselach). W trybie integer Godot ucina `content_scale_factor` do całości - dlatego rozciąganie ułamkowe.
    Test `tests/test_windows.gd` (z oknem).

## Watra i Ostoja (Pomysły i rzeczy do zrobienia)
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
- [x] **Wystrój lochów: Katakumby, Kopalnia goblinów, Zatopione podziemia i Pajęcze korzenie** (część punktu „Lochy ładne i bogate w środku”):
  - wspólna część w `scripts/dungeon_decor.gd` (`DungeonDecor`): rzędy mebli pod ścianami (`lines`, wzór na każdą
    stronę komnaty), światła w równych odstępach na licu ścian (`_wall_light`), nakładki na podłodze i cień u stóp
    ścian, siatki dużych rekwizytów na wierzchołkach z wolnym otoczeniem (`_isolated`, `Dungeon.solid`), snop światła
    z dziury w stropie (`_light_shaft`), pasy powtarzane wzdłuż komnaty (`_runner`: chodnik, tory, kładka);
  - każdy klimat ma własny skrypt `scripts/decor_<klimat>.gd` (`DungeonDecor.create`) z rodzajami komnat
    z `Dungeons.CLIMATES[...]["decor"]["themes"]`; rodzaj każdej komnaty zapisuje się w `Dungeon.room_themes`;
  - Katakumby (`decor_catacombs.gd`): krypta, sala kolumnowa, kostnica, kaplica, zawalona sala, kaźnia;
  - Kopalnia goblinów (`decor_mine.gd`, ustalenia z autorem: czynna kopalnia, gobliny same kopią): chodnik z torami
    (wózki, podpory z latarniami), skład prochu (siatka stosów beczek), kuźnia (palenisko z iskrami, kowadła, koryto),
    obóz (ognisko z rożnem w kręgu legowisk i tyczek z czaszkami), szyb z windą (platforma, kołowrót, słupy
    z kajdanami), zawał (połamane podpory, głazy, snop światła), żyła kruszcu (siatka świecących kryształów i kopców
    rudy); wejście - kładka z desek, sala wodza - tron z łupów za skarbcem, góry skarbów, aleja chorągwi, krąg czaszek;
  - Zatopione podziemia (`decor_flooded.gd`, ustalenia z autorem: podziemna świątynia dawnych bogów wody, zalana,
    gdy podniosła się woda; wodnik zrobił z niej królestwo; płytkie kałuże, wszędzie da się przejść): świątynia (posąg
    boga wody z ołtarzem, nawa z kolumn), kładki (mokre deski przez rozlewisko, kikuty kolumn), wraki (siatka wraków,
    łodzi i masztów w kałużach), gniazdo topielców (krąg gniazd wokół utopionych skarbów), grota z ognikami (świecące
    grzyby, unoszące się ogniki - `_motes`), obóz żabołaków (totem w kręgu suszarni ryb), sala rusałek (lustro wody
    w kręgu wianków, brzozowe gałązki), źródło (woda spada ze stropu do skalnego zbiornika - `_drips`); wejście - kładka
    przez rozlewisko, sala wodnika - tron z wyrzuconego drewna i muszli, aleja posągów, misy z wodą w narożnikach;
    na licu ścian kinkiety z zielonym płomieniem, płaskorzeźby fal, mech i sieci; rozlewiska (`pool`, `pool_small`)
    i kładkę (`planks`) rysuje `tools/dungeon_props.py`;
  - Pajęcze korzenie (`decor_roots.gd`, ustalenia z autorem: dzikie jaskinie pod Prastarym Lasem, bez śladów ludzi;
    zapuszczają się tu tylko łowcy): wylęgarnia (siatka kopców jaj i rozdartych kokonów), spiżarnia (siatka kokonów
    z ofiarami, kości i plecaki), korzenie (snop światła z dziury w stropie, krąg kolumn z korzeni), grzybnia (siatka
    wielkich świecących grzybów, zarodniki - `_motes`), sieciowa sala (pajęczy most z nici między rzędami oplecionych
    stalagmitów), kryjówka drzewców (wydrążony pień w kręgu głazów, żywica), obóz łowców (zgasłe ognisko, szałas,
    nad nim kokony - łowcy nie wrócili), pajęczy ołtarz (stos czaszek i poroży w sieci, rzędy kokonów); wejście -
    zejście po korzeniach, sala królowej - gniazdo z sieci i kości za skarbcem, aleja stalagmitów, kopce jaj
    w narożnikach; na licu ścian świecące huby (niebieskie światło), zwisające korzenie, sieci i jaja; most
    (`silk`) i zejście (`root_path`) rysuje `tools/dungeon_props.py`, a krotka rekwizytu może mieć skalę (czaszka,
    plecak, jajo zmniejszone). `_grid` i `_motes` są wspólne w `DungeonDecor`;
  - grafiki: paczki PixelLab po 16 sztuk (64 px) w `pixellab_src/dungeons/<klimat>_small|_tall|_furniture`,
    `tools/dungeon_props.py` (tory i kładkę rysuje sam). Gdy pobieranie z PixelLab jest zablokowane, klatki to podglądy
    kandydatów z `get_object` (zapisują się w katalogu `tool-results` sesji jako przezroczyste PNG 64x64);
  - zrzuty: `tools/dungeon_shots.gd` (każda komnata osobno, nazwa pliku z rodzajem komnaty), `tools/overview.gd`
    przyjmuje też loch (kraina `dungeon`, klimat i stopień po ziarnie).
- [x] **Wystrój lochów: Winnica satyrów - pierwszy loch na zewnątrz** (krok 5 punktu „Lochy ładne i bogate w środku”;
  ustalenia z autorem: dzika winnica, w której satyrowie upili się winem z płomieni Watry i świętują bez końca,
  strażnik - Król Satyrów, wariant 40 generacji PixelLab):
  - generator (`Dungeon.outdoor`, klucz `"outdoor"` klimatu): komnaty to polany - owal wpisany w prostokąt komnaty
    z brzegiem pofalowanym szumem (`_shape_glades`), korytarze to kręte ścieżki 2-3 wierzchołków (`_dig_path`,
    fala o losowej fazie; gładka linia w `_trails`); wierzchołki poza podłogą to klif, staw albo ściana drzew według
    szumu (`_plan_borders`, progi w `"terrain"` klimatu); klif bez pasującego kafelka Wang zamienia się w drzewa;
  - lico ściany (`"t"`) tylko pod klifem (`Dungeon._wall`, `_tile_label`), kafelki Wang (klify Wietrznych Turni,
    `pixellab_src/alpine/cliff.png` przez `tools/dungeon_tiles.py`) tylko przy klifach; resztę rysuje SoftGround
    z teksturami gór (`_build_ground`: łąka, kwiaty, gęsta trawa pod drzewami, ubita ścieżka `path_tiles`,
    woda bagien z brzegiem falującym szumem); kolizje, droga potworów i minimapa jak w podziemiach (kolory drzew,
    wody i ścieżek: `map_trees`, `map_water`, `map_path`);
  - `_dress_borders`: po dwa drzewa na wierzchołek ściany lasu, zagajnik na szczytach półek, trzciny przy brzegu
    i grążele na wodzie; wieczór (ciepły CanvasModulate, gracz bez własnego światła);
  - wystrój `scripts/decor_vineyard.gd` (`VineyardDecor`): winnica (rzędy winorośli, kosze, strach na wróble), tłocznia
    (wielka prasa albo kadź, kadzie, beczki z kranem, rozlane wino), biesiada (stół, animowane ognisko, stoliki, rożen,
    poduchy), tany (słup majowy, tyczki ze wstążkami, altana z lirą i bębnami), sad (drzewa co drugi wierzchołek),
    zagroda kóz (płot, koryto, paśnik, kozy z poziomem lochu), obóz (namioty i szałasy wokół rożna), źródło wina
    (fontanna z satyrem, pałki, brzozy, świetliki); wejście - łuk z winorośli i latarnie, strażnik - tron za skarbcem,
    totemy z kozią czaszką; latarnie wzdłuż ścieżek (`_trail_lights`);
    na licu klifów winorośl. Grafiki też z wioski satyrów (`assets/mountains/satyr/`, `assets/forest/props/satyr_*`);
    ścieżka bez rozszerzenia w `DungeonDecor._tex` dostaje `.png`;
  - poprawki po ocenie autora („winnica bez winnicy”, ozdoby bez sensu): pola winorośli także na terenie
    niedostępnym (`Dungeon.vines`, próg `vines_above`, nie przy klifach - lico zachodzi na sąsiednie komórki; mniej
    klifów: `cliff_below` -0,28; `_vine_fields`: rzędy co 3 kafelki, krzew co 40 px, przejście
    co 6-8 krzewów - jak w Turniach, `Dungeon.vine_run`); na polanach-winnicach (3 z 10 rodzajów w kolejce)
    i w szerokich miejscach przy ścieżkach pasy winorośli (`VineyardDecor._vine_strips`: co drugi rząd wierzchołków
    dwa rzędy krzewów z jedną kolizją, co 5 wierzchołków przejście); nic nie stoi na ścieżce (wierzchołki ścieżek
    zajęte od początku, kręgi ozdób omijają ścieżkę), latarnie na poboczu (na skraju sąsiedniego lasu lub pola);
    usunięte rozsypane drobiazgi, kiście i plamy wina poza scenkami; rzadziej poszerzane ścieżki (mniej pustych placów);
  - druga runda poprawek (drzewa na klifach, obiekty na klifach, proste odcięcia terenu): przy klifach
    (`Dungeon.near_cliff` - sąsiad także po skosie) nie rosną drzewa ani trzciny, a wystrój nie stawia tam niczego;
    na szczytach półek tylko krzewy i głazy w głębi; podłoże przy klifach to łąka w kolorze trawy kafelków klifu,
    a granice gęstej trawy i kwiatów wygina szum (przesunięcie punktu o ±26 px); poduchy tylko przy tronie;
  - trzecia runda: wokół klifów (sąsiedzi i rząd niżej) łąka do chodzenia zamiast drzew - klify stoją jak skały
    na trawie, bez niewidzialnych ścian; wysokie rekwizyty (`VineyardDecor._prop`, ponad 40 px) nie stają dwa rzędy
    pod klifem; więcej pól winorośli (`vines_above` -0,45), pojedyncze drzewa na łące (`_lone_trees`); zagroda kóz
    w miejscu bez ścieżki (`_pen_spot`), nic nie dotyka ścieżki (`_clear_of_path`); trzciny mają 2 klatki;
  - grafiki PixelLab: paczki `vineyard_small`, `vineyard_tall`, `vineyard_furniture` (po 16, 64 px) i `vineyard_big`
    (4 sztuki, 128 px) w `pixellab_src/dungeons/`; w paczce wysokich obiektów kandydatki wyszły przesunięte między
    klatkami, więc `tools/dungeon_props.py` tnie ją z pasa sklejonych klatek (`strip_part`, klatka `"s<nr>"`).

- [x] **Wystrój lochów: Oblężony gród - drugi loch na zewnątrz** (krok 6 punktu „Lochy ładne i bogate w środku”;
  ustalenia z autorem: gród zdobyty i spalony przez hordę koboldów, potwory - kobold, procarz, bombiarz, strażnik -
  Bombardier Kaszlak z Pól Zbożowych, polany: brama i wyłom, spalone zagrody, obóz koboldów, plac - majdan;
  0 generacji PixelLab - wszystko z gotowych grafik Ostoi, Kopalni goblinów i Pól Zbożowych):
  - klimat `"stronghold"` w `Dungeons.CLIMATES` (bez klifów: `cliff_below` -2; `palisade_below` 0,15 - wierzchołki
    poniżej progu szumu to teren za palisadą `Dungeon.palisades`, drobne kawałki poniżej 14 wierzchołków zostają lasem);
  - `Dungeon._build_palisade`: obrys terenu palisady metodą marching squares po wierzchołkach (odcinki między
    środkami krawędzi, siodła rozdzielone), łączony w linie i wygładzony dwa razy (`_chaikin`); pale jak w Ostoi
    (`Settlement.STAKE_WEIGHTS`, co 6 px, w pionie co 3,5 px), pasy złamanych pali według szumu, kolizja
    `ConcavePolygonShape2D` wzdłuż linii; pale tylko od strony polan, ścieżek i wody (zagroda przechodzi w las bez
    płotu); linie w `Dungeon.palisade_lines`; za palisadą podłoże ciemna trawa z płatami ubitej ziemi;
  - wystrój `scripts/decor_stronghold.gd` (`StrongholdDecor`): zagrody za palisadą (`_yards`) - gęsta zabudowa
    w siatce co około 88 px (chaty, a gdzie się zmieszczą - dwór, stodoła, stajnia, łaźnia, kuźnia, kaplica), część
    osmalona z dymem (`_smoke`, najwyżej 18) i żarem (`_embers` - `WorldVfx.burning`), ogródki pod chatami, drobiazgi
    co 40 px, zwęglone drzewa; wieże strażnicze na poziomych odcinkach palisady z terenem palisady za nimi (`_towers`);
    pochodnie przy ścieżkach (`_trail_torches`); scenki: brama i wyłom (łuk bramy, ocalały kawałek palisady z wieżą,
    wyłom ze złamanymi palami i rusztowaniem, taran z belek, leje po bombach), spalone zagrody, obóz koboldów (ognisko,
    namioty ze skór, skrzynie bomb, łupy, totemy), plac (studnia, kramy, manekiny, chorągwie); wejście - obóz obrońców,
    strażnik - spalony dwór i barykada z prochu; muzyka Pól Zbożowych.

- [x] **Skoki przez przeszkody** (prośba autora): zryw, odskok łuku (`Player.leap`), Mgnienie (też wirujące
  w Młynku) i Krok przez Mgłę przeskakują zwykłe przeszkody (płoty, klify, góry, drzewa, budynki, głęboką wodę),
  ale nie granicę - warstwa `BOUNDS_LAYER` (16, `world.gd`): brzegi mapy (`Bounds`) i ściany podziemnych lochów
  (`DungeonWalls`; w lochu na zewnątrz teren to zwykłe przeszkody). W skoku maska postaci to `Player.JUMP_MASK`,
  po nim `SOLID_MASK`; gdy postać wyląduje w przeszkodzie, `Player.free_landing` przesuwa ją na wolne miejsce
  dalej w kierunku skoku (do 96 px), a potem z powrotem po linii skoku (nigdy za granicą). Mgnienie widzi wrogów
  za przeszkodami, a miejsce lądowania za celem omija przeszkody i wodę. Test: `tests/test_jump.gd`.

- [x] **Mechaniki w lochach, etap 1** (listopad 2026): system losowania mechanik, skrzynie i kapliczki.
  - Losowanie: `Dungeons.MECHANICS` (id -> nazwa, waga, "size" small/large, "room" - własna komnata);
    `Dungeons.roll_mechanics(rng, bonus)` - pierwsza zawsze, druga 25%, trzecia 8% (`MECHANIC_EXTRA`), bez powtórzeń.
    Wagi: skrzynie 10, kapliczka 8, Kryształ Watry 5 - wychodzi: skrzynie ~54% lochów, kapliczka ~44%, Kryształ ~30%,
    średnio 1,27 mechaniki na loch (`Dungeons.mechanic_chance`). `bonus` na później (drzewko Watry, bożki):
    "weights" {id: mnożnik}, "extra" [premie do szans 2. i 3.], "forced" [zawsze obecne]; w ustawieniach wyprawy
    `"mechanic_bonus"`. `"mechanics"` w ustawieniach wymusza zestaw (testy), stare `"event"` wymusza Kryształ
    z wariantem; w trybie deweloperskim loch ma wszystkie mechaniki.
  - `Dungeon._pick_mechanics` (zastąpiło `_pick_event`) i `_build_mechanics` (po potworach); `Dungeon.mechanics`,
    `chests`, `shrines`. Obiekty stają w zwykłych komnatach (`_mechanic_rooms` - bez wejściowej, strażnika, Kryształu,
    ołtarza), w miejscu z najmniejszą ilością wystroju (`_mechanic_spot`). Napisy nad obiektami rozjaśnia
    `Dungeon.label_boost` (znosi mrok CanvasModulate). Nowa mechanika: wpis w `MECHANICS` i gałąź w `_build_mechanics`.
  - Kryształ Watry jest w puli (dawniej osobna szansa 25% - `EVENT_CHANCE` usunięte). Skarbiec strażnika daje
    kamienie zaklinające rzadko i po jednym (`Dungeons.VAULT_STONE_CHANCE` 0,15 + szansa z poziomu x1,5, doskonały
    x2; wcześniej 50%+ i 1-2 sztuki) - głównym źródłem ma być Kryształ.
  - **Skrzynie** (`scripts/dungeon_chest.gd`, `DungeonChest` - Harvestable, F, 1 s): 2-4 w lochu (`Dungeons.CHESTS`).
    Rodzaje `CHEST_KINDS`: Skrzynia (3-5 przedmiotów, złoto), Skrzynia kowala (2-4 bronie/zbroje, kamienie
    błogosławione), Szkatuła jubilera (biżuteria i kamienie szlachetne - bez zadania jubilera sama biżuteria),
    Skarbnica (25-40x złoto potwora, 25% rzadki przedmiot, 3% legenda ze skarbca). Cechy `CHEST_TRAITS` (każda
    losowana osobno): Strzeżona 30% (po otwarciu 5 + stopień/2 strażników o poziom wyżej, łup x1,4 po ich pokonaniu),
    Obfita 25% (x1,6), Cenna 20% (co najmniej magiczne, częściej rzadkie; Skarbnica - podwójne szanse).
    Grafika: skrzynia z Ostoi (`assets/village/chest.png`) w kolorze rodzaju, poświata i napis z cechami.
  - **Kapliczki** (`scripts/dungeon_shrine.gd`, `DungeonShrine`, F - modlitwa 0,8 s): 1-2 w lochu, każda inny dar
    na 60 s (`Boons`, grupa "shrine" - nowy dar zastępuje poprzedni; ikony w `StatusEffects.BOON_ICONS`):
    Moc Peruna (+50% obrażeń, +10% kryt.), Opieka Mokoszy (+40% zdrowia, +20% uniku, +10 zdrowia/s),
    Tchnienie Strzyboga (+30% ruchu, ataku, zaklęć), Hojność Dadźboga (x2 złoto i przedmioty - nowa statystyka
    `item_find`, `CharacterStats.item_find_multiplier`, liczona w `Goblin._drop_loot`), Oko Światowida
    (+100% doświadczenia), Blask Chorsa (+12 many/s, -30% odnowienia). Grafika: omszały kamień
    `assets/ancient/v2_shrine.png` z poświatą w kolorze daru (`DungeonShrine.COLORS`).
  - Zrzuty z bliska: `SCRIPT=tools/dungeon_shots.gd tools/screenshot.sh /tmp/m catacombs 7 3 2.0 mechaniki`.
    Test: `tests/test_dungeon.gd` (losowanie, skrzynia zwykła i strzeżona, kapliczka, ikona daru).
- [x] **Mechaniki w lochach, etap 2 - elitarne potwory** (listopad 2026): mechanika `"elites"` (waga 8, mała) - jak magiczne
  potwory w PoE. Ustalenia z autorem: wszystkie 4 grupy cech, 3-5 pojedynczych elit w lochu, większe z poświatą,
  łup - więcej i lepsze rzadkości.
  - Z czwartą mechaniką w puli: skrzynie ~41% lochów, kapliczka ~33%, elity ~32%, Kryształ ~20% (wcześniej ~30%).
  - Dane w `Dungeons`: `ELITE_TRAITS` (12 cech w 4 grupach, "power" - siła), `ELITES` (3-5), `ELITE_TRAIT_COUNT`
    (1 cecha 45%, 2 - 40%, 3 - 15%), `roll_elite_traits` (każda cecha z innej grupy), mnożniki `ELITE_*`.
  - `scripts/dungeon_elite.gd` (`DungeonElite`, dziecko potwora, `Goblin.elite`): `promote` - zdrowie x(3 + 0,75 za cechę),
    obrażenia x1,3, doświadczenie x(3 + liczba cech), złoto x3, skala 1,25, grupa "elites". Cechy:
    - aury (promień 120, odświeżane co 0,5 s, `Goblin.empower` / `_refresh_auras` - statystyki sprzed wzmocnienia
      w `_aura_base`, wracają po wygaśnięciu): Dowódczy +40% obrażeń, Poganiający +30% ruchu i tempa ataku,
      Osłaniający -35% otrzymywanych obrażeń (`Goblin._aura_guard`);
    - obrona: Tarczowy (tarcza 60% zdrowia, wraca po 6 s bez obrażeń, niebieski krąg), Uzdrawiający (3% zdrowia/s
      sobie, 4,2% sąsiadom), Kolczasty (odbija 20% obrażeń, najwyżej 1,5x cios elity, raz na 0,7 s);
    - żywioły: Wybuchowy (po śmierci krąg `Telegraph` 1,1 s i wybuch 2,5x - statyczne `DungeonElite._strike`, żeby
      odliczanie przetrwało zniknięcie potwora), Płonący (płonące plamy `FirePatch` za nim, 4 s), Mroźny (fala co 4 s
      w promieniu 80: spowolnienie i obrażenia), Burzowy (piorun w miejscu gracza co 3,5 s z zapowiedzią 0,9 s);
    - przywołanie: Przywołujący (co 8 s dwóch pomocników z puli klimatu, najwyżej 6; dają mniej łupu), Rozszczepialny
      (po śmierci 3 mniejsze potwory tego rodzaju z 20% zdrowia elity).
  - Wygląd: obrys w kolorze pierwszej cechy (`shaders/elite.gdshader` - z błyskiem trafienia, własny materiał elity),
    pulsująca poświata pod stopami, napis z cechami nad głową (`label_text`, rozjaśniany `Dungeon.label_boost`),
    złota kropka na mapie. Pasek bossa w HUD pokazuje najbliższą walczącą elitę („Elita: Dowódczy · Płonący”).
  - Łup (`DungeonElite.roll_loot`, oprócz zwykłego): 1 + liczba cech przedmiotów, pierwszy co najmniej magiczny,
    premia do rzadkości 0,1 za cechę, legenda 2% + 1,5% za cechę.
  - `Dungeon._add_elite`: w każdej z wylosowanych komnat (`_mechanic_rooms`) elitą zostaje losowy potwór gromady
    (nie strażnik, nie nieruchomy); w pustej komnacie elita staje sama. `Dungeon.elites`.
  - Zrzuty: `SCRIPT=tools/dungeon_shots.gd tools/screenshot.sh /tmp/m catacombs 7 3 2.0 mechaniki` (też elity).
    Test: `tests/test_dungeon.gd` (`_check_elites`: liczba i cechy, aura i jej koniec, Osłaniający, tarcza,
    rozszczepienie, łup).
- [x] **Mechaniki w lochach, etap 3 - Uroczysko i runy** (listopad 2026): mechanika `"uroczysko"` (waga 5, duża) -
  jak Breach w PoE. Ustalenia z autorem: krąg rośnie z zabójstwami (bez nich się kurczy), upiory tylko w kręgu (zwykłe
  potwory bez zmian), duchy z obecnych grafik (bez kosztu PixelLab), łup - runy, a warsztat kowala działa już tylko
  na runach (koniec działań za trofea).
  - Szanse z piątą mechaniką: skrzynie ~33% lochów, kapliczka ~28%, elity ~26%, Kryształ ~20% (waga podniesiona z 5
    na 6, żeby nie spadł), Uroczysko ~18%.
  - `scripts/uroczysko.gd` (`Uroczysko`, dziedziczy po `Harvestable`, `Uroczysko.create`): menhir `assets/ancient/menhir_1.png`
    (klatka 0 - zgaszona spirala, 1 - świecąca) na środku największej z 3 wolnych komnat (`Dungeon._add_uroczysko`,
    `Dungeon.uroczyska`), poświata i kropka na mapie. F (0,8 s) otwiera krąg: promień `URO_START` 110, najwyżej
    `URO_MAX` 430; po `URO_GRACE` 4 s kurczy się `URO_SHRINK` 7 px/s, coraz szybciej (x2 po `URO_SPEEDUP` 35 s);
    każdy zabity upiór dodaje `URO_GROW` 8 px (mniej przy dużym kręgu). Przy `URO_END` 36 krąg gaśnie.
  - Upiory (`Uroczysko.haunt`): potwory klimatu lochu (`Dungeon._spawn`, bez nieruchomych) co `URO_SPAWN_EVERY` 0,22 s
    w wolnym miejscu kręgu, tylu naraz, ile `URO_ALIVE` 5 + promień / 16; zdrowie x0,6, obrażenia x0,8, doświadczenie x0,6,
    mniej łupu; wygląd `shaders/ghost.gdshader` (sinozielona zjawa z migotaniem, obrysem i błyskiem trafienia).
    Co 0,1 s przytrzymywane w kręgu (`_keep_inside`); po zgaśnięciu znikają bez łupu (`_vanish`). Co 25 zabitych
    Upiorny Pan (fioletowy, x1,4, zdrowie x6, zawsze runa); zwykły upiór upuszcza runę z szansą 2%.
  - Krąg: `shaders/uroczysko.gdshader` na duszku w warstwie podłóg (mgła z szumu, świecący brzeg o stałej grubości,
    iskry; położenie z wierzchołków, bo UV w trybie zgodności dawało przesunięty krąg). Napis nad kamieniem liczy upiory.
  - Nagroda po zgaśnięciu: `Uroczysko.reward_runes` = 1 + zabici / 14, najwyżej 10.
  - **Runy zamiast warsztatu za trofea** (`ItemCraft.ACTIONS` - pole "rune", `ItemCraft.RUNES` z wagami i stopniem
    lochu, `ItemCraft.roll_rune`): Runa Szlifu (przerzut wartości), Przekucia, Zatarcia (usunięcie), Przydania (dodanie),
    Wyniesienia (rzadkość, od 2. stopnia), Zmiany, Pieczęci (od 4. stopnia, z Sercem Kryształu). Każde działanie: jedna
    runa i złoto jak dawniej (legendy 3x złota). Trofea zostają w bestiariuszu, kuźni i na rynku.
    Ikony nowych run to przebarwienia zapasowych ikon z `pixellab_src/runes/runes.png` (`tools/rune_art.py`).
    Runy wypadają też ze skarbca, z Kryształu, ze skrzyń wydarzeń (`roll_rune`), są na rynku i za Znaki Zwycięstwa
    (Szlifu, Przekucia, Wyniesienia).
  - Zrzuty: `SCRIPT=tools/dungeon_shots.gd tools/screenshot.sh /tmp/m catacombs 7 3 1.0 mechaniki` (`_uroczysko.png`
    i `_uroczysko_open.png`). Testy: `tests/test_dungeon.gd` (`_check_uroczysko`), `tests/test_workshop.gd`.
- [x] **Mechaniki w lochach, etap 4 - Krąg Żertwy i talizmany** (listopad 2026): mechanika `"zertwa"` (waga 5, duża) -
  jak Ritual w PoE, łup - nowy rodzaj przedmiotu, talizmany (jak idole w Last Epoch). Ustalenia z autorem: krąg
  w miejscu, danina na liczbę zabitych (bez limitu czasu), nagroda - wybór 1 z 3 talizmanów, siatka talizmanów
  z rozmiarami, premie do statystyk plus unikalne efekty w rzadkich.
  - Szanse z szóstą mechaniką (`Dungeons.mechanic_chance`, wagi bez zmian, Krąg - 5 jak Uroczysko): skrzynie ~29%
    lochów, kapliczka ~25%, elity ~23%, Kryształ ~19%, Krąg Żertwy ~16%, Uroczysko ~15%.
  - `scripts/zertwa.gd` (`Zertwa`, dziedziczy po `Harvestable`, `Zertwa.create`): pień ofiarny `assets/ancient/altar_stump.png`
    (x1,25) na środku największej z 4 wolnych komnat, ale nie w komnacie Uroczyska (`Dungeon._add_zertwa`,
    `Dungeon._room_of`, `Dungeon.zertwy`), poświata i kropka na mapie. F (0,8 s) zapala krąg `ZER_RADIUS` 170 px
    (shader Uroczyska w kolorze krwi). Spoza kręgu (`ZER_SPAWN_GAP` 30-150 px za brzegiem, gdy tam ściana - skraj
    kręgu) co `ZER_SPAWN_EVERY` 0,45 s nadciągają potwory klimatu, `ZER_ALIVE` 9 naraz, od razu na gracza
    (doświadczenie x0,7, przedmioty x0,3).
  - Danina: nowy sygnał `World.goblin_died` (potwór pokonany przez gracza); każdy wróg zabity w kręgu (także zwykły
    potwór lochu) daje `ZER_TRIBUTE` 1, elita, boss i Wybraniec - `ZER_ELITE_TRIBUTE` 5 (`Zertwa.tribute_of`). Co
    `ZER_CHOSEN_EVERY` 20 daniny nadciąga Wybraniec (x1,35, zdrowie x5, obrażenia x1,3, zwykły łup).
  - Po `ZER_GOAL` 60 daninie pień czeka na odebranie (F); kto walczy dalej, aż do `ZER_GOAL` x `ZER_OVERFLOW` (120),
    dostaje lepszą ofertę („Bogowie są syci” - fale ustają). Odbiór gasi krąg (żywi zostają jak zwykłe potwory)
    i losuje ofertę `Talismans.roll_offer` (poziom przedmiotu = poziom lochu + stopień): szansa na rzadki
    `ZER_RARE_CHANCE` 25% + do 50% za nadwyżkę, na wielki 2x2 10% + do 30%, pierwszy zawsze co najmniej 1x2.
    Okno `scripts/ui/talisman_offer.gd` (`TalismanOffer`, w HUD `talisman_offer`): 3 kolumny z ikoną, opisem
    i „Weź”; „Później” zamyka - wybór czeka przy pniu (F). Wybrany talizman trafia do plecaka (`Player._gain_item`).
  - **Talizmany** (`scripts/talismans.gd`, `Talismans`): wylosowany przedmiot (`Items.generated`, przepis z "talisman",
    zapis przez `Loot.export_used` / `Loot.import`, nazwa od nowa po zmianie języka - `Items._retranslate`).
    Kształty `SHAPES`: mały 1x1 (1 premia), podłużny 1x2 i szeroki 2x1 (2 premie, moc x1,15), wielki 2x2 (3, x1,35).
    Premie z puli `POOL` (bez płaskich obrażeń i pancerza), wartość z tierów łupu (`Loot.roll_tier` / `tier_range`)
    razy `VALUE_SCALE` 0,8 i moc kształtu. Rzadki (nie 1x1) ma efekt warunkowy - jeden z efektów legend (`EFFECTS`:
    żądza krwi, Pożeracz, nieśmiertelność, kościana zbroja, wysysanie życia, ciernie, zakopanie się, wybuch zabitych,
    oszczędna mikstura, tarcza wiatru) o około połowie siły legendy, z dopiskiem w nazwie („Wielki talizman Szału”).
    Ikony rysowane w kodzie (`tools/talisman_art.py`, bez PixelLab): kość z niebieskimi runami (magiczne), bursztyn
    w złotej oprawie (rzadkie); obrazek ma rozmiar kratek (64 px na kratkę).
  - Siatka `Talismans.GRID` 4x3 w `Equipment.talismans` ({"id", "cell"}; `can_place_talisman`, `place_talisman`,
    `move_talisman`, `remove_talisman`, `free_talisman_cell`, `talisman_at`); premie liczy `Equipment.bonus`, efekty -
    `Equipment.effect_power` (łączą się z legendami i esencjami). Zapis w `equipment.talismans` jako [id, x, y].
    Gracz: `Player.place_talisman` (PPM na talizmanie w plecaku - pierwsze wolne miejsce) i `Player.remove_talisman`.
  - Okno `scripts/ui/talisman_window.gd` (`TalismanWindow`, przycisk „Talizmany” w ekwipunku, otwiera się po lewej):
    siatka, przeciąganie z plecaka (środek talizmanu pod kursorem - `drop_cell`), przesuwanie w siatce, przeciąganie
    do plecaka (`{"talisman": nr}` w `InventoryWindow._drop_on_bag`), PPM - wyjmij; pod siatką suma premii i efektów.
  - Zrzuty: `SCRIPT=tools/dungeon_shots.gd tools/screenshot.sh /tmp/m catacombs 7 3 1.0 mechaniki` (`_zertwa.png`
    i `_zertwa_open.png`). Testy: `tests/test_dungeon.gd` (`_check_zertwa`), `tests/test_talismans.gd`.
- [x] **Bożki** (listopad 2026, jak skaraby w PoE). Ustalenia z autorem: 2 sloty na start (więcej z poziomem Watry),
  bożek zużywa się przy wejściu do lochu, 4 grupy rodzajów (mechaniki, potwory, łup, ryzyko), 3 rzadkości jak w łupie,
  węzły w drzewku Watry później (razem z drzewkiem).
  - `scripts/idols.gd` (`Idols`): przedmiot bożka to stały identyfikator `idol_<rodzaj>_<rzadkość>` (`Items.get_data`
    -> `Idols.data`, nazwa składana przy pokazywaniu: materiał Gliniany / Rzeźbiony / Złocony + rodzaj), więc bożki
    układają się w stosy. 16 rodzajów (`Idols.KINDS`): po jednym na każdą z 7 mechanik (zwykły - waga mechaniki x4,
    rzadki - mechanika zawsze, legendarny - zawsze i wzmocniona `MECHANIC_POWER` 1,5: +1-2 skrzynie, +1 kapliczka,
    +1-2 elity, +1 Skarbnik, Kryształ i Uroczysko x1,5 nagrody, Krąg Żertwy 4 talizmany do wyboru), Hordy i Gniewu
    (potwory), Złota, Łupu, Run (runy w skarbcu), Klejnotów, Legend (łup), Pychy (+obrażenia potworów, +poziom
    przedmiotu łupu) i Mroku (+zdrowie potworów, szansa na lepszą rzadkość). Wartości `[zwykły, rzadki, legendarny]`.
  - Wypadanie (`Goblin._drop_loot`): 0,35% z każdego potwora (bossowie x15) po otwarciu lochów Watry
    (`MainQuests.dungeons_unlocked`); rzadkości 70 / 25 / 5. Miejsce na drzewko: `Idols.slot_count(…, extra_slots)`,
    `Idols.drop_chance(…, chance_bonus)`.
  - Sloty (`Idols.SLOT_LEVELS`): 2, trzeci od 4. i czwarty od 6. poziomu Watry. Okno lochów (`DungeonWindow`) ma
    listy wyboru bożków z plecaka (każdy rodzaj raz), pod nimi zebrane działanie; „Wkrocz w płomienie” zabiera bożki
    z plecaka i zapisuje je w ustawieniach wyprawy (`Dungeons.config(…, idols)`).
  - W lochu: `Dungeons.mult(config, klucz)` łączy modyfikatory za żar z bożkami (zastąpiło `multiplier` w lochu,
    skrzyniach i Krysztale), `Dungeons.added` - premie dodawane (poziom przedmiotu, rzadkość, runy skarbca),
    `Dungeons.mechanic_bonus(config)` - premie mechanik z `config["mechanic_bonus"]` i bożków dla `roll_mechanics`,
    `Dungeon.mechanic_power(id)` - moc mechaniki. `Goblin.dungeon_mods` ma nowe klucze gems, legend, item_level, quality.
  - Ikony rysowane w kodzie (`tools/idol_art.py`, 48 plików w `assets/items/idols/`, 0 generacji PixelLab) - rzeźbiony
    słup z twarzą w trzech materiałach, kamień na piersi w kolorze rodzaju. Test: `tests/test_idols.gd`.
  - **Druga partia bożków** (listopad 2026, pomysły autora i propozycje do wyboru). Bożki potworów i łupu
    (`Idols.STACK_GROUPS`) można wkładać w kilka slotów - działanie się sumuje (szanse z górną granicą `ADD_CAPS`);
    reszta raz, prastary najwyżej jeden (`Idols.can_combine` / `fits`). Nowe rodzaje: Gromad (+3 / 5 / 5 gromad,
    złocony - w każdej elita; `Dungeon._apply_idols`), Nawii (10 / 20 / 30% szansy, że zabity wróg wstaje jako upiór -
    `Dungeon._on_nawia_death`), Zielarki (zioła krain do poziomu lochu, `Idols.herb_for_level`), Drwala, Kamieniarza,
    Górnika (drewno, kamień, ruda z potworów, `Goblin.IDOL_RESOURCES`; wszystkie 5 / 10 / 15%), Szlifierza (25 / 50 /
    100% szansy na lepszy szlif kamieni szlachetnych, `Idols.better_cut`), Strażnika (strażnik wściekły, +50-150%
    zdrowia, +20-40% obrażeń, skarbiec x1,5-2,5), Echa (1 / 1 / 2 bossów z innych klimatów lochów -
    `Idols.boss_pool`, rzadki i złocony +3 poziomy), Żaru (modyfikatory za żar -25 / 50 / 100% kosztu,
    `Dungeons.mods_cost(mods, idols)`). Rzadkość **prastara** (`Items.RARITY_COLORS["ancient"]`, czerwona, z promieniem
    łupu jak legendy), ~1% bożków (`Idols.ANCIENT_CHANCE`): Bożek Zastępów (połowa potworów, wszystkie elitami - test:
    76 elit) i Bożek Władców (w każdej komnacie boss zamiast gromady, korytarze bez zmian).
- [x] **Mechaniki w lochach, etap 6 - Kryształ Watry jedynym źródłem kamieni zaklinania** (listopad 2026). Ustalenia
  z autorem: obrona przed falami zostaje (warianty „crystal” i „miners”), fale liczniejsze na wyższych stopniach,
  kowadło na później.
  - `WatraCrystal.wave_count(fala, stopień, mnożnik)`: (5 + 3 x (fala - 1)) x (1 + `WAVE_TIER_BONUS` 0,25 x (stopień - 1))
    x modyfikator liczby potworów; stopień 1: fale 5-14 (razem 38), stopień 7: 13-35 (razem 95).
  - Skarbiec strażnika (`Dungeon._on_boss_died`) nie daje już kamieni zaklinających (usunięte `Dungeons.VAULT_STONE_*`),
    tylko kamienie uświęcone; Kryształ (waga 7, ~20% lochów) zostaje jedynym źródłem w lochach, rynek i zadanie główne
    jako drogie wyjście awaryjne. `tests/balance_sim.gd` liczy kamienie tylko z Kryształu, test w `tests/test_crystal.gd`.
- [x] **Mapa Nawii, etap 5 - Władca Hordy** (listopad 2026). Ustalenia z autorem: wejście za serce każdego z trzech
  bogów, 4 fazy z cieniami bogów, rogaty demon-król z PixelLab 160 px, nagrody: 2 legendy, pas dla Marzanny, tytuł
  i posąg w Ostoi, rosnące stopnie Pomroku.
  - Dane w `Pinnacles` (`LORD = "horde"` w `GODS` z kluczem `"lord"`, poza `ORDER`): poziom 98, arena w Kopalni goblinów,
    wejście za `LORD_COST` serca każdego boga (`can_challenge_lord`, `pay_lord`), pierwsze zwycięstwo `LORD_POINTS` (5)
    punktów Watry. Skarbiec Władcy 2x większy (`vault_rewards(level, rng, lord, pomrok)`).
  - Boss `scripts/horde_lord.gd` (`HordeLord` extends `PinnacleBoss`, scena `scenes/pinnacle_horde.tscn`): zdrowie x1,5
    względem boga (`LORD_HEALTH`), fazy przy 75/50/25% (`LORD_PHASES`, hak `PinnacleBoss._phase_marks` / `_on_phase`).
    Własne ataki: Rozpłatanie (stożek), Ogień Hordy (deszcz ognia z płonącymi plamami), Skok Władcy, Zew Hordy
    (przyzywa `CALL_COUNT` potworów). W fazach 2-4 cień Welesa, Marzanny i Czarnoboga (`PinnacleBoss.make_shade` -
    15% zdrowia boga, ciemny, bez łupu); dopóki cień żyje, Władca dostaje 30% obrażeń (`SHADE_SHIELD`). Faza 4:
    wściekłość i fale Hordy co `WAVE_TIME` s (`HORDE_KINDS` z różnych krain, najwyżej `MAX_MINIONS`). Śmierć zabija cień
    i Hordę.
  - **Pomrok** (`Pinnacles.POMROK_*`, `Boons.pomrok_unlocked` / `pomrok`, wybór „<” „>” w oknie Mapy Nawii): stopnie I-X
    dla wszystkich aren (bogów i Władcy) - poziom +2, zdrowie +20%, obrażenia +10%, skarbiec +25%, legendy i pasy +50% za
    stopień (`Dungeon.pomrok`, `Goblin.dungeon_mods`, `PinnacleBoss._pomrok`). Zwycięstwo nad Władcą na najwyższym
    odblokowanym stopniu odblokowuje następny (`Boons.defeat_pinnacle(god, pomrok)`).
  - Tytuł „Pogromca Hordy” (+ rzymska liczba najwyższego przebytego Pomroku): `Boons.title()`, okno postaci, opis zapisu
    (`Game.describe_save`, pola `title` i `pomrok` w `.meta.json`). Posąg Władcy przy Watrze (`Settlement.update_trophies`,
    `HORDE_STATUE`, grafika `assets/village/horde_statue.png`).
  - Legendy: Ostrze Władcy Hordy (`horde_rift` - ogień spod trafionego), Korona Trzech Bogów (`gods_echo` - w walce co
    ~4 s korzenie Welesa, lód Marzanny albo kolce Czarnoboga), serce Władcy (`pinnacle_heart_horde`, 3 serca - legenda).
    Pas Marzanny **Pas Zimowego Oddechu** (`legend_marzanna_belt`, `winter_breath`): zabity wróg pęka lodem, zabici przez lód
    pękają dalej (łańcuch, najwyżej `WINTER_CHAIN` wybuchów na sekundę); bez esencji (`Essences.UNIQUE_KINDS`).
    Przy okazji opisy efektów legend bogów w `Items.EFFECT_TEXTS` (naprawia `tests/test_legends.gd`).
  - Grafiki: `tools/pinnacle_art.py` (arkusz `pixellab_src/pinnacles/horde.png`, ikony, posąg z `pixellab_src/pinnacles/props/`);
    koszt: 15 (postać) + 8 (animacje) + 10 (ikony) = 33 generacje. W paczce ikon został niewykorzystany odłamek
    z okiem (`props/pomrok_shard.png`) - np. na ikonę Pomroku.
  - Test: `tests/test_horde_lord.gd`. Do ustalenia po ograniu: siła Władcy i cieni, liczebność fal, liczby Pomroku.
- [x] **Efekty i dźwięki bossów szczytowych, etap 1 - Weles** (listopad 2026). Ustalenia z autorem: każdy bóg ma
  własny zestaw z kreatora efektów PixelLab (Weles - bagienna zieleń i złoto, Marzanna - lód, biel i błękit,
  Czarnobóg - czerń i fiolet), najpierw Weles na próbę, potem reszta bogów, Władca Hordy i efekty 9 legend.
  Efekty Welesa (`pixellab_src/vfx/ids.json`, `assets/effects/weles_*.png`, stałe `FX_WELES_*` w `pinnacle_boss.gd`):
  `weles_roots` (krąg cierni ze złotymi pęknięciami - jeden efekt zamiast 12 korzeni Leszego, skala z promienia),
  `weles_venom` (plusk jadu ze złotymi iskrami, zamiast `BossFx.acid`), `weles_serpent` (uderzenie na końcu Wężowego
  Zrywu), `weles_engage` (szczelina Nawii, słup światła, pnącza), `weles_phase` (zielono-złoty wybuch z monetami,
  `_fx_phase`), `weles_death` (bagienny wybuch, pnącza, sypiące się złoto, `_fx_death`). Dźwięki z `tools/sfx_synth.py`
  (`WELES`): `weles_roar` (ryk niedźwiedzia przechodzący w wężowy syk - pojawienie się i fazy), `weles_roots`,
  `weles_venom`, `weles_hiss` (Wężowy Zryw), `weles_death` (ryk, syk i brzęk monet). Cień Welesa u Władcy Hordy
  używa tych samych efektów.
- [x] **Efekty i dźwięki bossów szczytowych, etap 2 - Marzanna** (listopad 2026; lód, biel i błękit). Efekty
  (`assets/effects/marzanna_*.png`, stałe `FX_MARZANNA_*` w `pinnacle_boss.gd`): `marzanna_nova` (Mroźny Wybuch - krąg
  8 kęp lodowych kolców i błysk), `marzanna_lance` (lecąca lodowa włócznia z rozpryskiem, jedna na linię, obrót
  i skala z `LANCE_LENGTH`), `marzanna_blizzard` (zamieć przez całą zapowiedź, puszczana z 10 kl./s, żeby kolce wyrosły
  na jej końcu), `marzanna_mist` (lodowa mgła zniknięcia i pojawienia się - `_marzanna_mist`), `marzanna_engage` (słup
  mroźnego światła, szron, kolce), `marzanna_phase` (zbieranie mrozu, błysk, pierścień odłamków), `marzanna_death`
  (wybuch lodu, mgła, śnieg). Dźwięki (`MARZANNA` w `tools/sfx_synth.py`, pomocnicy `icy_wind`, `ice_crack`):
  `marzanna_wail` (dwugłosowe zawodzenie nad wiatrem - pojawienie się i fazy), `marzanna_nova`, `marzanna_lance`,
  `marzanna_blizzard` (narastające wycie z trzaskiem lodu na końcu), `marzanna_mist`, `marzanna_death`.
- [x] **Efekty i dźwięki bossów szczytowych, etap 3 - Czarnobóg** (listopad 2026; czerń i fiolet). Efekty
  (`assets/effects/czarnobog_*.png`, stałe `FX_CZARNOBOG_*` w `pinnacle_boss.gd`): `czarnobog_cleave` (ciemny sierp
  z fioletowym brzegiem, obrót z kierunku ciosu, skala z `CLEAVE_RANGE`), `czarnobog_spike` (Kolec Cienia, po jednym
  na miejsce w szeregu), `czarnobog_step` (czarny dym znikania i pojawienia się - `_czarnobog_step`), `czarnobog_strike`
  (uderzenie po Kroku przez Cień - fioletowe pęknięcia i ciemny pył, skala z `STEP_RADIUS`), `czarnobog_engage`
  (czarna szczelina, kolumna ciemności, macki cienia), `czarnobog_phase` (zassanie, ciemny błysk, czaszki),
  `czarnobog_death` (otchłań, macki, czarny dym, czaszki). Dźwięki (`CZARNOBOG` w `tools/sfx_synth.py`, pomocnik
  `dark_whisper`): `czarnobog_roar` (trzy bardzo niskie pomruki z szeptami - pojawienie się i fazy),
  `czarnobog_cleave`, `czarnobog_spike` (seria chrzęstów), `czarnobog_step` (zassanie i trzask), `czarnobog_strike`,
  `czarnobog_death`.
- [x] **Efekty i dźwięki bossów szczytowych, etap 4 - Władca Hordy** (listopad 2026; ogień, czerwień i czerń). Efekty
  (`assets/effects/horde_*.png`, stałe `FX_HORDE_*` w `horde_lord.gd` i `pinnacle_boss.gd`): `horde_cleave` (ogniste
  cięcie), `horde_meteor` (kometa spadająca ukosem i wybuch - puszczana `1.1 - METEOR_FALL` s po zapowiedzi, żeby
  uderzyć z jej końcem; zamiast `BossFx.bomb`), `horde_leap` (lądowanie po skoku), `horde_call` (Zew Hordy),
  `horde_portal` (płonąca szczelina przy każdym przyzwanym potworze i fali), `horde_shade` (przyzwanie cienia boga),
  `horde_shield` (zapętlona kopuła osłony cienia - `FxLoop` z przezroczystością 0,45, `HordeLord._update_shield`),
  `horde_engage`, `horde_phase`, `horde_death`. W kreatorze pocisk obraca się tylko o ćwierćobroty - ukośny lot
  daje część `comet_trail`. Dźwięki (`HORDE` w `tools/sfx_synth.py`, pomocnik `flames`): `horde_roar` (pojawienie się,
  fazy, Zew, fale), `horde_cleave`, `horde_meteor`, `horde_leap`, `horde_portal`, `horde_shade`, `horde_death`.
  Wszyscy bossowie szczytowi mają już własne efekty; dalej efekty 9 legend.
- [x] **Efekty i dźwięki legend bossów szczytowych** (listopad 2026; wszystkie 9 naraz, w kolorach swoich bogów).
  Efekty z kreatora (`assets/effects/legend_<legenda>.png`, wpisy `legend_*` w `pixellab_src/vfx/ids.json`, funkcje
  w `LegendVfx`, krótsze niż u bossów - 10-12 klatek): `nawia_grasp` (krąg zielonych cierni, złoty błysk, plusk jadu -
  zamiast korzeni Leszego i kwasu), `serpent_skin` (zielono-złoty pierścień jadu wokół gracza), `winter_touch` (kępa
  lodowych kolców i 3 mniejsze dookoła), `frost_veil` (mroźny pierścień z kolcami wokół gracza), `winter_breath`
  (lodowy blok pęka w odłamki), `shadow_spikes` (czarno-fioletowe kolce mroku zamiast kolca Mortana), `dark_pact`
  (fioletowy błysk i kłąb mroku z czaszkami zamiast szarego dymu), `horde_rift` (rozżarzone pęknięcia i czerwony
  ogień z czarnym dymem zamiast wybuchu bomby), `gods_echo` (błysk w barwach trzech bogów nad głową, gdy Korona
  budzi moc). Pierścienie wokół gracza mają przezroczystość `LegendVfx.RING_ALPHA` (0,8). Promienie efektów w klatce
  (`*_RADIUS` w `LegendVfx`) skalują efekt do zasięgu legendy. Dźwięki (`LEGENDS` w `tools/sfx_synth.py`, wpisy
  `legend_*` w `Sfx.SOUNDS`, ciszej i z odstępem, bo grają często): `legend_roots`, `legend_venom`, `legend_frost`,
  `legend_veil`, `legend_shatter`, `legend_shadow_spike`, `legend_dark_pact`, `legend_horde_rift`, `legend_gods_echo`
  (trzy dzwony bogów). Do oceny po ograniu: wielkość i głośność przy dużych gromadach.
- [x] **Malejące zyski szybkości** (listopad 2026, krok 1 „Dopieszczenia walki”). Szybkość ataku i rzucania była bez
  limitu (2% za punkt zręczności / inteligencji plus premie przedmiotów, kamieni i drzewka). Teraz
  `CharacterStats.speed_gain`: do +60% (`SPEED_SOFT`) premia liczy się w całości, powyżej coraz słabiej, sufit +150%
  (`SPEED_CAP`; np. surowe +100% daje +92%, +500% daje +149%); 1% za punkt zręczności i inteligencji
  (`ATTACK_SPEED_PER_DEXTERITY`, `CAST_SPEED_PER_INTELLIGENCE`). Szybka Salwa (`Player._cast_volley`): odstęp
  `VOLLEY_INTERVAL` 0,07 s skracany szybkością, ale nie poniżej `VOLLEY_MIN_INTERVAL` 0,05 s, a strzały wylatują
  na zmianę z lewej i z prawej (`VOLLEY_SPREAD`), żeby nie chowały się jedna za drugą. Mgnienie: skoki nie częściej
  niż co `Skills.FLICKER_MIN_INTERVAL` (0,16 s), w Młynku co `WHIRL_FLICKER_MIN_INTERVAL` (0,07 s), a smuga i cięcie
  przyspieszają z szybkością ataku (najwyżej 2x). Test: `test_stats`.
- [x] **Tagi umiejętności i atrybuty jak w Last Epoch** (listopad 2026, kroki 2 i 2b „Dopieszczenia walki”).
  - Tagi (`Skills.TAGS`, grupy `TAG_GROUPS`, nazwy `TAG_NAMES`, kolory `TAG_COLORS`): rodzaj (atak, czar, okrzyk,
    aura - na razie bez umiejętności), forma (cios, pocisk, obszar, przywołanie, ruch), obrażenia (fizyczne, ogień, lód,
    piorun, trucizna, tajemne, w czasie) i atrybut (siła, zręczność, inteligencja). Zwykły atak bronią: `BASIC_TAGS`
    (magiczny pocisk księgi - czar, pocisk, tajemne). Widmowe Ostrza są tajemne, Mgnienie ma siłę i zręczność, Dymne
    Wybuchy i Widmowe Ostrza siłę i inteligencję, Strzała Wichru zręczność i inteligencję.
  - Ikonki tagów rysowane w kodzie: `tools/tag_icons.py` -> `assets/ui/tags/<tag>.png` (16 px x4). Linia tagów
    `Skills.tags_bbcode` w opisie węzła w oknie K (panel szczegółów to teraz `RichTextLabel`) i w dymkach drzewka
    i pasków (`RichTooltip.build` - dymek BBCode dla kontrolek z własnym skryptem: `SkillTreeView`, `HotbarSlot`).
    `RichTooltip` liczy szerokość obrazka `[img]` (wcześniej liczył ścieżkę pliku jak tekst).
  - Atrybuty (`CharacterStats`): +1% obrażeń za punkt atrybutu z tagu umiejętności (`attribute_damage`,
    `DAMAGE_PER_ATTRIBUTE`) zamiast płaskiego +1 obrażeń; bez tagu atrybutu (efekty legend, ogólne `["attack"]`)
    liczy się główny atrybut broni (`DAMAGE_ATTRIBUTE`). Premia dodaje się do premii fizycznych / magicznych
    w `kind_multiplier`. Kieł Gruzłoga (`might`) dokłada część pozostałych atrybutów. Siła: dalej 0,5% redukcji
    (maks. 25%). Zręczność: unik 0,4% za punkt (`dexterity_dodge`, w całości do 15%, dalej łagodnie do 35%, razem
    z przedmiotami najwyżej 50%) zamiast szybkości ataku. Inteligencja: +5 many (bez szybkości rzucania).
    Witalność: +5 zdrowia.
  - Szybkość ataku i rzucania tylko z przedmiotów, drzewek i premii; `skill_speed` mnoży ją przez prędkość
    broni (`weapon_speed`) - sztylet przyspiesza też umiejętności, topór je spowalnia.
  - Stare zapisy (`ATTRIBUTE_RULES` = 2 w zapisie): przy wczytaniu wszystkie punkty atrybutów wracają do rozdania,
    okno postaci mówi o tym przy punktach (`attributes_reset`). Okno postaci pokazuje premię z każdego atrybutu.
  - `tools/texts.py` widzi też wieloliniowe stałe `*_NAMES`. Symulacje (`balance_sim`, `tier_sim`) liczą siłę
    procentowo: na początku i w środku gry zwykły potwór pada od ok. 4-4,5 ciosu zamiast 3,5, przy poz. 90 od 3,1.
    Test: `test_attributes`.
- [x] **Mapa Nawii, etap 4 - bossowie szczytowi** (listopad 2026). Ustalenia z autorem: trzech słowiańskich bogów
  (Władca Hordy i obce bogi później), dostęp za fragmenty kluczy z węzłów, nagrody: punkty Watry, własne legendy, dużo
  łupu i serca boga jako waluta; grafiki PixelLab 160 px z 2 animacjami; do tego dwa pasy w stylu Mageblooda
  i Headhuntera jako superrzadkie legendy (10 serc).
  - `scripts/pinnacles.gd` (`Pinnacles`): Weles (poz. 92, klimat korzeni), Marzanna (93, zatopione podziemia),
    Czarnobóg (95, katakumby). Fragment klucza wypada ze strażnika węzła Nawii (`Dungeon._drop_fragment`, 10% na
    stopniu 8, +4% za stopień), bóg według obszaru węzła (`GODS["areas"]`). 4 fragmenty (`FRAGMENTS`) - „Wyzwij”
    w nowej kolumnie „Bogowie” okna Mapy Nawii (`NawiaWindow._build_gods`).
  - Arena: `Dungeons.config` z kluczem `"pinnacle"` (`Pinnacles.config`), `Dungeon._plan_arena` - komnata wejścia
    i arena 18x16 (`ARENA_START`, `ARENA`), bez mechanik, bożków, ołtarza i zwykłych potworów, premie drzewka Watry
    działają. `Dungeon._pinnacle_rewards`: złoto, 6 magicznych i 3 rzadkie przedmioty, runy, kamienie uświęcone, bożek,
    kamień szlachetny; `Boons.defeat_pinnacle` - pierwsze zwycięstwo +3 punkty Watry (`Boons.pinnacle_kills`).
  - Boss `scripts/pinnacle_boss.gd` (`PinnacleBoss`, sceny `scenes/pinnacle_<bóg>.tscn`): zdrowie x6 względem bossa
    (`HEALTH_MULT`), fazy przy 66% i 33% (komunikat), nie wraca do leża. Weles: Korzenie Nawii, Jad Welesa (kałuże
    i trujący opar), Wężowy Zryw; Marzanna: Lodowe Włócznie, Zamieć, Mroźny Wybuch (od fazy 2 znika we mgle); Czarnobóg:
    Cięcie Mroku, Kolce Cienia (w fazie 3 trzy linie), Krok przez Cień. Animacja: klatki 0-8 spoczynek, 9-17 atak.
  - Grafiki: `tools/pinnacle_art.py` (arkusze z `pixellab_src/pinnacles/<bóg>.png`, ikony z `pixellab_src/pinnacles/icons/`,
    identyfikatory w `pixellab_src/pinnacles/ids.json`); koszt: 45 (postacie) + 24 (animacje) + 20 (ikony) generacji.
  - Łup: serce boga zawsze (`pinnacle_heart_<bóg>`), 2 legendy na boga (15% każda): Laska Welesa (`nawia_grasp`),
    Skóra Welesa (`serpent_skin`), Wieniec Marzanny (`winter_touch`), Szata Pani Zimy (`frost_veil`), Miecz Czarnoboga
    (`shadow_spikes`), Hełm Czarnoboga (`dark_pact`) - efekty w `LegendaryEffects`. Wymiana w oknie Mapy Nawii:
    3 serca - legenda boga, 10 serc - pas (`Pinnacles.exchange_*`).
  - Pasy (2% z boga albo 10 serc, bez esencji - `Essences.UNIQUE_KINDS`): **Pas Wiecznych Ziół** (Weles,
    `eternal_herbs`) - mikstury zielarki działają bez końca, do 4 różnych naraz (`Boons.eternal`, `Boons.grant`,
    `Player._update_eternal_herbs`); **Pas Łowcy Dusz** (Czarnobóg, `soul_hunter`) - zabita elita oddaje cechy na 20 s
    (`Boons.souls`, `Boons.SOUL_STATS` - każda cecha elity to premia gracza; ikony pod paskami).
  - Encyklopedia: bogowie jako bossowie „świata”. Test: `tests/test_pinnacles.gd`.
- [x] **Nowe drzewko lochów - drzewko Watry od nowa** (krok 6 z `docs/plan_drzewek.md`, listopad 2026). Ustalenia
  z autorem: skupiska węzłów każdej mechaniki **porozrzucane po całym drzewku** (gracz szuka najlepszej drogi przez cudze
  skupiska, nie idzie jedną gałęzią), między nimi ścieżki małych neutralnych węzłów, dużo węzłów (~500), węzły zmieniające
  mechaniki, szansa na podwójną mechanikę, węzły kluczowe z ceną, zwrot punktów Watry, 3 zakładki zostają.
  - `scripts/watra_tree.gd` (`WatraTree.VERSION` = 2): 505 węzłów. 12 tematów (`SECTORS` - 8 mechanik i Splot mechanik,
    Łup i skarbiec, Bożki, Błogosławieństwo Watry), każdy ma 4 skupiska (`CLUSTER_GROUPS` "a"-"d": 6 małych węzłów
    w kółku, węzeł znaczący w środku) w 3 pierścieniach (`CLUSTER_RINGS`, rozrzut `CLUSTER_SPREAD` / `CLUSTER_STEP` -
    skupiska jednego tematu co ok. 90 stopni), za skupiskiem "d" węzeł kluczowy. Watrę otacza pierścień Iskier
    (`INNER_*`), skupiska łączą ścieżki neutralnych węzłów (`_path`, `PATH_EFFECTS` - łup, doświadczenie, liczba
    potworów "count", złoto, rzadkość, skarbiec). Droga do dalekiego skupiska to ok. 15-25 punktów.
  - Mechaniki: "a" - waga (`MECH_WEIGHT_A`) i węzeł „podwójna mechanika” (`dup:<mechanika>`, `MECH_DUP` 30% -
    `Dungeon.dup_extra`: drugie Uroczysko / Krąg Żertwy / Skarbnik, więcej skrzyń, kapliczek, elit); "b"-"d" - moc
    (`MECH_POWER`) i węzły zmieniające (`MECHANIC_NOTABLES`, czytane przez `Dungeon.tree_value`):
    - Skrzynie: mimik (`chest_mimic` - skrzynia ożywa jako elita, potrójny łup, `DungeonChest._wake_mimic`), Skrzynie
      Bogów (`chest_special` - rodzaje "idols", "runes", "talismans" w `Dungeons.CHEST_KINDS`), częstsze cechy;
    - Kapliczki: dar do końca lochu (`shrine_long`, `Boons.end_dungeon_gifts` przy wczytaniu świata poza lochem), dary
      naraz (`shrine_stack` - grupy "shrine_2"…), silniejsze dary (`shrine_power` - "power" w `Boons.active`);
      `Boons.grant(id, time, power, stack, dungeon_only)`;
    - Elity: Bożkowe Piętno (+1 cecha, pewny bożek), Czempion (wszystkie grupy cech, 2x zdrowie, pewna legenda -
      `DungeonElite.make_champion`), więcej łupu z elit; `Dungeons.roll_elite_traits(rng, extra)`;
    - Kryształ Watry: dodatkowa fala (`WatraCrystal.waves`, nagroda +25%), więcej kamieni zaklinania, leczenie gracza
      w pobliżu (`HEAL_*`), zdrowie kryształu i górników;
    - Uroczysko: elitarne zjawy z runą, Strażnik Kręgu (krąg nie maleje przy menhirze - `HOLD_RADIUS`), Upiorny Książę
      (gasnący krąg wypuszcza Księcia i trwa do jego śmierci, 3 runy - `PRINCE_*`);
    - Krąg Żertwy: 4 talizmany do wyboru, podwójna danina z elit, talizman z dwoma efektami (`Talismans.roll(…, dual)`,
      "effect2" w przedmiocie - działa w `Equipment._effect_power`, opis w `Items` i oknie talizmanów);
    - Skarbnik: darmowe przelosowanie (`Skarbnik.free_rerolls`), kolejny Skarbnik po wygranej (`Dungeon.add_extra_skarbnik`),
      częstsze Kości;
    - Mgła Nawii: Rwąca Mgła (`mist_fast` - dwa razy szybciej, `Dungeons.mist_rules`), Żyła Krzesiw, Zimna Pamięć,
      Kamienie z Mgły, Bezdenna Mgła (dawne przedłużenie gałęzi Mgły).
  - Węzły kluczowe: mechanika w każdym lochu i **żadnej innej losowej** (`forced:` + `only:` - `Dungeons.roll_mechanics`),
    +25% mocy; ogólne z ceną: Wielki Splot (zawsze 2. mechanika, -25% mocy wszystkich - `all_power`), Skarb Strażnika
    (skarbiec x2, +2 runy, -20% łupu z potworów), Prastary Panteon (rzadsze, ale lepsze bożki), Żywy Płomień
    (Błogosławieństwo +25%, -10% łupu w lochach). Nowe premie: `extra4` (czwarta mechanika), `idol_keep` (bożek może się
    nie zużyć - `DungeonWindow`), ujemne premie w opisach (`NEGATIVE_TEXTS`).
  - Zwrot punktów: zapis bez `"watra_tree"` w `Boons` (wersja starsza niż `WatraTree.VERSION`) - wszystkie zakładki
    czyszczone, `Boons.tree_refunded` pokazuje komunikat w oknie drzewka; `WatraTree.effects_from_save` nie daje premii
    ze starego zapisu.
  - Okno (`scripts/ui/watra_tree_window.gd`): całe drzewko na start (przybliżenie 0,5), tło skupisk w kolorze tematu,
    nazwy przy węzłach kluczowych; temat węzła pod myszą (albo zaznaczonego) podświetla wszystkie swoje skupiska.
    Zrzut: `SCRIPT=tools/watra_tree_shot.gd tools/screenshot.sh /tmp/watra`.
  - Testy: `tests/test_watra_tree.gd` (układ, rozrzut skupisk, droga przez cudze skupiska, premie, zwrot punktów, okno),
    nowy `tests/test_watra_mechanics.gd` (każdy węzeł zmieniający mechanikę w prawdziwym lochu), `tests/test_mist.gd`.
  - Do ustalenia po ograniu: liczby (premie małych węzłów, `MECH_*`, ceny węzłów kluczowych), czy skupiska mają mieć
    ikony z PixelLab.
  - **Więcej punktów Watry** (prośba autora po scaleniu): `NawiaMap.POINTS_PER_NODE` 1 -> 2, pierwsze pokonanie boga
    `Pinnacles.FIRST_KILL_POINTS` 3 -> 5, Władcy `LORD_POINTS` 5 -> 10. Razem ok. 205 punktów (było ok. 104) na ~500
    węzłów, czyli ok. 40% drzewka w jednej zakładce. Stare zapisy dostają nowe punkty od razu (liczone z oczyszczonych
    węzłów). Komunikat po oczyszczeniu węzła pokazuje liczbę punktów.
- [x] **Mapa Nawii, etap 3 - drzewko Watry** (listopad 2026). Ustalenia z autorem: siatka jak drzewko atlasu w PoE,
  więcej węzłów niż punktów z całej mapy (trzeba wybierać), wzmacnia mechaniki lochów, bożki, łup i Błogosławieństwo
  Watry; **3 zakładki** z osobnymi, pełnymi pulami punktów (3 wyspecjalizowane ustawienia), działa wybrana, zmiana za
  darmo poza lochem; cofanie za złoto - pojedynczy węzeł albo cała zakładka naraz (taniej).
  - `scripts/watra_tree.gd` (`WatraTree`): 12 gałęzi wokół Watry (`BRANCH_ORDER`), w każdej korzeń i dwie ścieżki po
    4 małe węzły z węzłem na końcu - 133 węzły (punktów z mapy jest 90). Gałęzie mechanik (7): ścieżka „częściej”
    (waga x1,2 za węzeł, `MECH_WEIGHT`) z węzłem kluczowym „mechanika w każdym lochu” (romb) i ścieżka „mocniej” (+10%
    mocy, węzeł znaczący +30% - `MECH_POWER*`). Pozostałe (`BRANCHES`): Splot mechanik (szansa na 2. i 3. mechanikę),
    Bożki (częściej, rzadsze odmiany, prastare, 2 sloty), Łup potworów (łup, złoto, doświadczenie, legendy, kamienie),
    Skarbiec (skarbiec strażnika, rzadkość, +1 poziom przedmiotów, runa), Błogosławieństwo Watry (stała premia, premia
    za węzeł obszaru, złoto). Premie: `effects` (wagi się mnożą, „forced” włącza, reszta sumuje), opisy `effect_lines`.
  - Zapis w `Boons`: `watra_tabs` (3 listy węzłów), `watra_tab`, `watra_tab_names`; `tree_allocate` / `tree_refund` /
    `tree_reset` / `set_tree_tab` / `tree_effects`. Przy wczytaniu nieznane i odcięte od Watry węzły wracają jako punkty.
    Ceny: `WatraTree.REFUND_GOLD_PER_LEVEL` (20 zł za poziom postaci za węzeł), `RESET_GOLD_PER_LEVEL` (8 za węzeł).
  - Lochy: okno lochów zapisuje premie działającej zakładki w ustawieniach wyprawy (`config["tree"]`), więc zmiana
    zakładki w lochu niczego nie rusza. `Dungeons.mult` / `added` mnożą i dodają premie drzewka, `Dungeons.mechanic_bonus`
    łączy drzewko z bożkami (moc ponad 1 się teraz **dodaje**, zamiast brać większą). `Dungeon.power_extra` (wcześniej
    `_power_extra`) liczy też talizmany do wyboru w Kręgu Żertwy.
  - Bożki: `Idols.drop_chance(boss, 1 + idol_drop)`, `Idols.roll(rng, rarity_bonus, ancient_bonus)` (w `Goblin`);
    sloty z drzewka to osobne pola w oknie lochów pod slotami z poziomu Watry (`DungeonWindow._slot_open`).
  - Błogosławieństwo: `World._apply_blessing` dolicza `WatraTree.blessing_bonus` i złoto (czyta zakładkę z zapisu przez
    `WatraTree.effects_from_save`), okno kapliczki pokazuje sumę.
  - Okno `scripts/ui/watra_tree_window.gd` (przycisk „Drzewko” w oknie Watry i na Mapie Nawii, od 40. poziomu jak mapa):
    sieć rysowana w kodzie (przeciąganie, kółko myszy), zakładki z nazwami, Wybierz / Cofnij / Wyczyść zakładkę
    (drugie kliknięcie potwierdza). Test: `tests/test_watra_tree.gd`.
- [x] **Mapa Nawii, etap 2 - Błogosławieństwo Watry** (listopad 2026). Ustalenia z autorem: zamiast spaczenia krain,
  które trzeba by usuwać, oczyszczone węzły dają **Błogosławieństwo Watry** - włączane przy kapliczce krainy, podnosi
  jej potwory do poziomu mapy (to jest „wariant endgame krainy”); dzisiejsze krainy bez zmian.
  - `NawiaMap.blessing_level` - poziom najtrudniejszego oczyszczonego węzła obszaru (działa od 1. węzła, rośnie
    z postępem do 90); `blessing_range` - poziomy krainy [poziom - 4, poziom, bossowie poziom + 2] (`BLESS_SPREAD`);
    `blessing_bonus` - premia do łupu i doświadczenia +2% za każdy oczyszczony węzeł obszaru (`BLESS_BONUS_PER_NODE`,
    15 węzłów = +30%), tylko z włączonym błogosławieństwem.
  - Przełącznik: `Boons.nawia_blessed` (zapis „blessed”), `Boons.set_blessing`. F przy kapliczce (`World.BLESSING_RANGE`,
    `World.blessing_shrine_near`, podpowiedź „[F] Watra” w `Player._scan_harvestables`) otwiera okno
    `scripts/ui/blessing_window.gd` (postęp obszaru, poziomy, premia, Rozpal / Wygaś). Zmiana przebudowuje krainę od razu
    (`World.toggle_blessing` - podróż do tej samej kapliczki). W lesie kapliczką jest Ostoja.
  - Świat: `World._apply_blessing` czyta przełącznik i postęp wprost z zapisu (potwory powstają przed wczytaniem postaci),
    ustawia `Levels.blessed_zone` / `blessed_range` (`Levels.zone_range` - z niego korzystają `level_at` i `boss_level`)
    i premię przez `Goblin.dungeon_mods` („loot”, „xp”). `World.blessing_bonus` trzyma premię bieżącej krainy.
  - Mapa świata (`WorldMapView._blessed`): błogosławiona kraina ma ciepłą poświatę, złotą obwódkę i podpis. Okno Mapy
    Nawii podpowiada, że oczyszczony węzeł pozwala rozpalić błogosławieństwo.
  - Miejsce na obóz odłożone do punktu „Budowa i rozbudowa obozów”. Test: `tests/test_blessing.gd`.
- [x] **Mapa Nawii, etap 1 - mapa, węzły i stopnie 8-17** (listopad 2026). Ustalenia z autorem: mapa duża, losowana
  z ziarna zapisu (ta sama w jednym zapisie), stopnie rosną od środka na zewnątrz, w obszarach przeważają klimaty
  pasujące do krainy, okno na razie rysowane w kodzie (ładna mapa z PixelLab, gdy systemy będą dopracowane).
  - `scripts/nawia_map.gd` (`NawiaMap`): koło z Watrą w środku, 6 obszarów (`AREAS`, po jednym na krainę), w każdym
    10 pierścieni (`RING_NODES` - 15 węzłów na obszar, 90 razem); pierścień = stopień 8-17. Klimat węzła: 75% klimat
    krainy (`AREA_CLIMATES`), reszta losowa. Drogi: do najbliższego węzła poprzedniego pierścienia (czasem drugiego),
    między sąsiadami w pierścieniu, czasem do sąsiedniego obszaru (`LINK_*`); każdy węzeł osiągalny. Na start widać
    pierwszy pierścień, oczyszczony węzeł odsłania sąsiadów (`revealed`). Mapa od 40. poziomu postaci (`UNLOCK_LEVEL`).
  - Postęp: `Boons.nawia_cleared` (zapis „nawia”), `Boons.clear_nawia_node`, punkty Watry `Boons.watra_points`
    (1 za każdy nowy węzeł - `NawiaMap.POINTS_PER_NODE`; drzewko Watry jeszcze ich nie wydaje).
  - Okno `scripts/ui/nawia_window.gd` (przycisk „Nawia” w oknie Watry): obszary jak kawałki tortu (oczyszczony
    jaśniejszy), mgła (blade punkty), świecące odsłonięte węzły, jasne oczyszczone; „Wyrusz” otwiera okno lochów
    w trybie węzła (`DungeonWindow.open_node` - klimat i stopień ustalone, modyfikatory i bożki jak zwykle).
    Wyprawa ma w ustawieniach `nawia_node`; pokonany strażnik (`Dungeon._on_boss_died`) oczyszcza węzeł.
  - Stopnie: `Dungeons.TIER_LEVELS` ma 17 pozycji (8-17: poziomy 45-90 co 5), zwykłe okno lochów do `BASE_TIERS` (7).
    Liczebność potworów i nagrody mechanik zależne od stopnia liczą się najwyżej jak stopień 7 (`Dungeons.power_tier`,
    `config_tier`) - trudność i łup rosną z poziomem potworów, a nie liczbą wrogów naraz (wydajność).
  - Balans końcówki (`Levels.ENDGAME_*`): ponad 41. poziomem obrażenia potworów +2,5% i doświadczenie +1,6% na poziom;
    krainy bez zmian. `tests/balance_sim.gd` liczy też poziomy 45-90 (w widełkach). Test: `tests/test_nawia.gd`.
- [x] **Mechaniki w lochach, etap 5 - Skarbnik i przegląd tierów T1** (listopad 2026): nagroda z ryzykiem jak Ultimatum
  w PoE. Ustalenia z autorem w opisie punktu w CLAUDE.md (historia: „Skarbnik”).
  - **Przegląd tierów T1** (krok 1, `tests/tier_sim.gd` - wojownik na 40. poziomie, 11 przedmiotów): T1 to przedmioty
    90.-100. poziomu, a najwyższy poziom przedmiotu w grze to ~43 (najlepszy możliwy dziś tier: T13). Przed zmianą pełne
    T1 dawało 55x obrażeń i 22x przeżywalności typowej postaci. Zmiany `Loot.TIER_VALUES` (zgoda autora): zdrowie
    200 -> 120, szansa na cios krytyczny 12% -> 7%, siła krytyka 60% -> 45%, szybkość ruchu 16% -> 20% (na tle PoE,
    Diablo 4 i Last Epoch: T1 życia to ~10% puli postaci, buty 20-35% ruchu, kryt prawie nigdy wprost). Zwykłe łupy
    prawie bez zmian (zdrowie z typowej premii 25 -> 20). Po zmianie: pełne T1 38x obrażeń, pełny sufit Skarbnika
    (T8) 11x obrażeń i 6,5x przeżywalności, najlepsze dziś (T13) 5x.
  - **Sufit Skarbnika** (`SkarbnikOffer.ceiling_tier`): wzmacnianie podnosi tiery najwyżej do `Loot.top_tier(poziom) -
    SKA_CEILING_EXTRA` (5) - przy poziomie 43 to T8; T1 dopiero dla przedmiotów 80.+ poziomu (przyszłe krainy).
  - Mechanika `"skarbnik"` (waga 5, duża); Kryształ Watry podniesiony z 6 na 7, żeby dalej był w ~20% lochów. Liczba
    Skarbników w lochu: `SKA_COUNT` (1), drzewko Watry i przedmioty w Watrze podniosą ją przez
    `config["mechanic_bonus"]["skarbnik_count"]`. Skarbnik staje w wolnej komnacie bez Uroczyska i Kręgu Żertwy
    (`Dungeon._add_skarbnik`).
  - `scripts/skarbnik_offer.gd` (`SkarbnikOffer`): oferta jako słownik do JSON (uid, poziom przedmiotów = poziom lochu
    + 2, stopień, liczba wzmocnień, nagrody). 3 nagrody (40% szans na 4), pierwsza zawsze przedmiot (rzadki z linii
    łupu); dalej runy (2-4), kamienie zaklinania (`SKA_STONES`: broni/zbroi/biżuterii 3-6, uświęcone 20-40,
    miłosierdzia 3-6) i kamień szlachetny (po zadaniu jubilera). Wzmocnienie (`strengthen`, najwyżej `SKA_MAX_STEPS`
    = 6): tiery premii +4 do sufitu (rodzaje bez zmian), runy i kamienie +50% sztuk bazy za wzmocnienie, szlif +1;
    6. wzmocnienie - wszystkie premie na sufit i przemiana w losową legendę tego samego miejsca (broń - ten sam rodzaj
    broni; `legend_bases`). Przelosowanie (`reroll`): nowe rodzaje premii z tymi samymi tierami, inny kamień
    szlachetny, inna runa, inny kamień zaklinania (ta sama część zakresu sztuk).
  - **Księga ofert** (zabezpieczenie przed wczytywaniem): plik `user://skarbnik.json` (`SkarbnikOffer.ledger_path`,
    testy - `user://test_skarbnik.json`). Zapis gry trzyma tylko identyfikator (`Player.skarbnik_uid`, klucz
    „skarbnik”), oferta jest w księdze. Wzmocnij / Przelosuj - oferta od razu w księdze jako zagrożona; wygrana -
    zabezpieczona i czeka u gracza (`Player.skarbnik_offer`) na następnego Skarbnika (także w kolejnym lochu); wzięta
    albo stracona - znika z księgi, więc starszy zapis jej nie przywróci. Wczytanie zapisu z zagrożoną ofertą (wyjście
    z lochu, wyłączenie gry w trakcie fal) - przepada (`SkarbnikOffer.restore`).
  - `scripts/skarbnik.gd` (`Skarbnik`, dziedziczy po `Harvestable`): krasnoludzki górnik z Kryształu Watry
    (`assets/crystal/miner_down.png`) jako złocista zjawa (`shaders/ghost.gdshader`, kolor `GHOST`) przy kupce skarbów
    (`assets/dungeons/mine/treasure.png`) - 0 generacji PixelLab. F - okno oferty. Fale: `SKA_WAVES` = 1, 2, 2, 3, 3, 4
    fal na kolejnych wzmocnieniach (przelosowanie - jak przy obecnym wzmocnieniu, bez wzrostu siły); w fali
    `SKA_WAVE_KILLS` wrogów (60-340), żywych naraz `SKA_ALIVE` (30-150), poziom potworów + 2 za wzmocnienie; wrogowie
    wychodzą z 3 bram 220-420 px od Skarbnika (nowe bramy co falę), od 4. wzmocnienia część dostaje cechy elit
    (`SKA_ELITE_CHANCE` 3% za wzmocnienie od 4.). Wrogowie fal: 60% doświadczenia, 25% szansy na przedmiot, bez serc.
    Kości Skarbnika (`skarbnik_bones`, ikona `tools/skarbnik_art.py`): pewna sztuka po wygranych falach i 0,4% z każdego
    wroga fal. Śmierć gracza w falach - oferta przepada, wrogowie fal się rozwiewają (`Skarbnik.lose`).
  - **Sufit wrogów żywych naraz** (`tests/bench_skarbnik.gd`, z oknem: scena `mgnienie` albo `miecz`, liczba żywych,
    sekundy; w chmurze obraz rysuje procesor, więc liczą się proporcje): Mgnienie - 60 żywych 43 ms/klatkę, 100 - 68 ms,
    150 - 83 ms, 200 - 153 ms, 300 - 224 ms; miecz - 150: 61 ms, 300: 134 ms. Dla porównania największa gromada Turni
    i Cmentarza z Mgnieniem (`bench_village`): 122 ms. Sufit 150 (przy 200 Mgnienie kosztuje więcej niż dziś w krainach).
  - Okno `scripts/ui/skarbnik_window.gd` (`SkarbnikWindow`): nagrody obok siebie (ikona, liczba sztuk, opis, „Weź”),
    pod nimi Wzmocnij (przed ostatnim - „Przemień w legendy”, w dymku fale i poziom potworów), Przelosuj (za Kości),
    Później. Testy: `tests/test_skarbnik.gd`.

## Zielarstwo (Pomysły i rzeczy do zrobienia)
- [x] **Zioła i mikstury zielarki** (`scripts/herbs.gd`, roślina `scripts/herb.gd`, grafiki z PixelLab przez `tools/herb_art.py`):
  w każdej krainie rośnie jej zioło (dziurawiec, rumianek, tatarak, arnika, kwiat paproci - rzadki, bieluń), zrywane klawiszem F
  (szybciej niż drzewo, iskierki nad rośliną, odrasta po kilku minutach). Zielarka Jadwiga z lecznicy („Mikstury”) warzy
  z 3 ziół i złota miksturę - przedmiot do wypicia (także z paska 1-0), premia z grupy „elixir” na 5 minut, mocniejsza niż posiłek.

## Gildia i świat jak w MMO (Pomysły i rzeczy do zrobienia)
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

## Tłumaczenie na angielski (Pomysły i rzeczy do zrobienia)
- [x] **Krok 1: przygotowanie gry do tłumaczeń** (`scripts/lang.gd` - `Lang.t`, `Lang.n`, `Lang.join`; plik
  `translations/teksty.csv` - kolumny keys (polski tekst), en, _gdzie; odświeża go `python tools/texts.py`, gotowe
  tłumaczenia zostają; `locale/fallback` = pl, więc brak tłumaczenia pokazuje polski tekst): wybór języka w Ustawieniach
  (`Game.language` w `user://settings.cfg`, menu główne przebudowuje się po zmianie), około 2640 napisów przechodzi przez
  tłumaczenie, zdania z liczbami i imionami jako całe wzory, odmiana liczebników, nazwy przedmiotów z łupu składane przy
  pokazywaniu (`Loot.compose_name`, `name_stats` w przepisie, starsze zapisy - `Loot.name_stats` z dawnej nazwy;
  po zmianie języka przedmiot rejestruje się od nowa - `Items._retranslate`), zlecenia i prośby drużyny zapisują wzory
  z danymi (`Quests.resolve`, `Quests.text`), tytuły wydarzeń - `WorldEvents.title_of`. Sprawdzanie pominiętych napisów:
  `TranslationServer.pseudolocalization_enabled = true` (przetłumaczony tekst ma nawiasy i akcenty). Testy:
  `tests/test_lang.gd`, `tests/test_item_names.gd`.
- [x] **Krok 2: tłumaczenie na angielski** - wszystkie napisy w `translations/teksty.csv` (około 2650), słowniczek nazw
  `translations/slowniczek.md` (Watra i Ostoja zostają po polsku, imiona postaci, bogów i bossów też; nazwy opisowe
  tłumaczone), `tools/texts.py --apply plik.json` i `--validate` (wzory %s/%d w tej samej kolejności, znaczniki, nowe
  linie). Po angielsku nazwy przedmiotów z dwoma dopiskami mają „of the” raz („Steel Sword of the Lynx and Owl” -
  `Loot.compose_name`). Odświeżone porady w oknie pomocy (zaklinanie u kowala, kamienie z lochów, punkty umiejętności).

## Świat (Pomysły i rzeczy do zrobienia)
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
