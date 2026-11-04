# Plan: wspólne drzewko umiejętności, aury, combo i nowe drzewko lochów

Burza mózgów z autorem (listopad 2026). Decyzje autora są oznaczone **[ustalone]**, reszta to pomysły do wyboru.
Kolejne sesje: czytaj ten plik zamiast całej rozmowy; zrobione kroki przenoś do `docs/historia.md`.

## Decyzje

- **[ustalone] Jedno duże wspólne drzewko** zamiast 3 drzewek broni (miecz, łuk, księga), około **200-250 węzłów**.
- **[ustalone] Wariant A:** umiejętności nadal wymagają swojej broni - umiejętności miecza leżą po stronie siły,
  łuku po stronie zręczności, księgi po stronie inteligencji. Strefy pośrednie dają premie wspólne i kilka
  umiejętności „mieszanych”.
- **[ustalone] Klas nie ma.** Przebudzenia nie należą do klas - gracz wybiera konkretne przebudzenie (pomysły na
  przebudzenia z CLAUDE.md zostają: magia cieni z kosą, chainblade'y, bojowy mag z glewią / runicznym rapierem,
  tylko odklejone od wojownika, łucznika i maga).
- **[ustalone] Przełączania broni nadal nie ma** (wcześniejsza decyzja autora).
- **[ustalone] Drzewko lochów (drzewko Watry) robimy od nowa** - stare punkty wracają do rozdania.
- Pomysł „Wspólne drzewko z trzema zakładkami” z CLAUDE.md zastępuje ten plan.

## 1. Wspólne drzewko umiejętności

Układ:
- trzy strony: **Siła** (góra-lewo, miecz), **Zręczność** (góra-prawo, łuk), **Inteligencja** (dół, księga);
  start w środku;
- **umiejętności aktywne wyraźnie wyróżnione** (większy węzeł o innym kształcie);
- **skupiska** po 5-8 węzłów wokół jednego tematu: konkretny żywioł, odporności, mana, życie, wzmocnienia
  konkretnej umiejętności albo broni (np. „Młynek”, „Pociski”, „Krwawienie”, „Ogień”, „Odporność na lód”);
  między skupiskami ścieżki małych węzłów (+atrybut, +kilka % zdrowia);
- **strefy pośrednie**: siła/zręczność - krwawienie, ciosy, szarże; zręczność/inteligencja - pioruny, uniki,
  pociski czarów; siła/inteligencja - ogień, aury, zaklęte ostrza;
- **umiejętności „tylko po innym ciosie” stają się zwykłymi** (Półksiężyc, Szybka Salwa, Fala piorunów); ich combo
  zostaje jako premia.

Węzły (autor):
- większe obrażenia zależnie od tego, ile mamy zdrowia (%), analogiczny dla many;
- więcej pocisków (ustawiają się obok siebie - wachlarzem albo równolegle);
- Strzała tropiąca działa jak przywołanie i rezerwuje część many;
- mniejsza rezerwacja many (więcej aur naraz);
- % zdrowia, % many;
- część otrzymanych obrażeń idzie w manę;
- odporność na konkretny żywioł, obrażenia konkretnego żywiołu.

Węzły kluczowe (propozycje):
- **Szał Bitewny** - każde zabójstwo daje ładunek (+% szybkości), ładunki szybko znikają;
- **Żelazna Wola** - obrażenia czarów rosną z siły zamiast z inteligencji;
- **Krew za Manę** - umiejętności kosztują życie zamiast many;
- **Krwawa Ofiara** - aury rezerwują życie zamiast many;
- **Mistrz Żywiołów** - zadajesz tylko żywioł, który ostatnio cię trafił, ale dużo mocniej;
- **Łowca w Cieniu** - więcej obrażeń wrogom, które cię nie widzą albo są daleko;
- **Ostatni Bastion** - poniżej 30% zdrowia +50% obrażeń i redukcji.

## 2. Aury rezerwujące manę

Włączone działają bez końca i rezerwują część many (patrz punkt w CLAUDE.md).

| Aura | Działanie | Skąd |
|---|---|---|
| Regeneracja many | +regeneracja many | autor |
| Regeneracja życia | +regeneracja zdrowia | autor |
| Aury żywiołów (ogień, lód, piorun) | ataki dostają obrażenia żywiołu i szansę na podpalenie / zamrożenie / porażenie; własne animacje ataków z kreatora efektów PixelLab (darmowy) | autor |
| Max zdrowia | +% zdrowia | autor |
| **Mroźny Oddech** (jak Righteous Fire w PoE) | lodowa aura rani nas i wrogów wokół | autor |
| Aura Peruna | co kilka sekund piorun bije losowego wroga w pobliżu | propozycja |
| Aura Strachu | wrogowie wokół zadają mniej obrażeń | propozycja |
| Aura Pośpiechu | +szybkość ruchu i ataku | propozycja |

**Zrobione** (krok 3, szukaj „Aury rezerwujące manę - krok 3” w `docs/historia.md`): wszystkie 10 aur z drzewka
(propozycje też weszły: Gniew Peruna, Postrach, Wiatr Strzyboga), rezerwacja jak w PoE (30% / 20% / 15% / 25% / 35%,
Mroźny Oddech 0% - rani gracza), ikony i kręgi rysowane w kodzie. Własne animacje ataków aur żywiołów - później.

## 3. Combo

Autor:
- **Mgnienie -> Riposta**: 3-4 ostatnio trafieni przez Mgnienie wrogowie aktywują na sobie uderzenie Riposty
  i ranią wszystkich wokół;
- **Rozpłatanie -> Widmowe Ostrza**: ostrza lecą do różnych wrogów (jeśli są) i używają na nich Rozpłatania;
- **Widmowe Ostrza -> Młynek**: przez chwilę wokół nas krąży wirująca burza widmowych ostrzy;
- **Rozłupanie Ziemi -> Szarża**: kolce z Rozłupania wybuchają.

Propozycje - łuk:
- **Sidła -> Deszcz Strzał**: deszcz skupia się na unieruchomionych wrogach;
- **Odskok -> Grot Swaroga**: grot od razu w pełni napięty;
- **Sokół -> Strzała Wichru**: sokół też rzuca podmuch ze swojego miejsca.

Propozycje - księga:
- **Zamieć -> Kula ognia**: zamrożeni wrogowie pękają (wybuch lodu i ognia);
- **Kamień Runiczny -> Łańcuch błyskawic**: łańcuch odbija się też od kamienia i wzmacnia;
- **Krok przez Mgłę -> Spadająca Gwiazda**: gwiazda spada tam, skąd zniknęliśmy.

## 4. Nowe drzewko lochów (od nowa, jak atlas w PoE)

Zasady (autor):
- każda mechanika ma **kilka skupisk z lepszymi węzłami**;
- skupiska łączą **neutralne węzły** z drobnymi premiami (+mały % potworów w lochach, +% wypadających przedmiotów itp.);
- węzły, które **zmieniają mechanikę**, a nie tylko podnoszą liczby;
- węzły z szansą na **dodatkową mechanikę danego rodzaju** w lochu;
- na końcu skupiska - propozycja: węzeł kluczowy z ceną (np. „Uroczysko w każdym lochu, ale żadnej innej mechaniki”).

Pomysły na węzły znaczące:

| Mechanika | Pomysły |
|---|---|
| Uroczysko | elitarne zjawy z lepszymi nagrodami (autor); krąg nie maleje, gdy stoisz w środku; ostatnia fala to mini-boss z gwarantowaną rzadką runą |
| Krąg Żertwy | wybór 1 z 4 talizmanów; elity dają podwójną daninę; szansa na rzadki talizman z dwoma efektami |
| Skarbnik | jedno darmowe przelosowanie; po wygranej szansa na drugiego Skarbnika |
| Mgła Nawii | gęstość rośnie 2x szybciej (hojniej i groźniej); Skrzynia Mgły z kamieniem wsparcia o 3 poziomy wyższym |
| Kryształ Watry | fale częściej dają kamienie zaklinania; kryształ leczy gracza w pobliżu |
| Elity | +1 cecha, ale wypada bożek; „Czempion” z gwarantowaną legendą |
| Skrzynie | skrzynia-mimik (walka, potem dużo łupu); skrzynia pełna bożków / run / talizmanów |
| Kapliczki | kapliczka działa przez cały loch; dwie kapliczki naraz |

Wspólne okno: drzewko umiejętności i drzewko lochów mogą używać tego samego rysowania (skupiska + ścieżki).

## 5. Kolejność (propozycja, każdy krok osobny PR)

1. Lista węzłów i układ wspólnego drzewka (dane bez kodu, do akceptacji autora) - szkic gotowy, czeka na autora:
   `docs/drzewko_wspolne.md` (układ, decyzje), rysunek `docs/drzewko_wspolne.png`, lista `docs/drzewko_wspolne_wezly.md`,
   dane w `tools/shared_tree_draft.py`. Ustalone po szkicu: aury i premie z węzłów działają z każdą bronią na pasujące
   umiejętności (tagi); strefy wspólne dostaną więcej węzłów i umiejętności w osobnym etapie.
2. Wspólne drzewko z obecnymi umiejętnościami zamiast 3 drzewek; stare zapisy - zwrot punktów. **Zrobione**
   (szukaj „Wspólne drzewko umiejętności, krok 2” w `docs/historia.md`): nowe umiejętności, aury, nowe węzły kluczowe
   i węzły znaczące bez premii w grze są pustymi miejscami (`"soon"` w `tools/shared_tree_draft.py`) - kolejne kroki
   dają im działanie (usuń `new=True` / dopisz `stats`, uruchom `python tools/shared_tree_draft.py`).
3. Aury i rezerwacja many. **Zrobione** (szukaj „Aury rezerwujące manę - krok 3” w `docs/historia.md`).
4. Nowe combo; Półksiężyc, Szybka Salwa i Fala piorunów jako zwykłe umiejętności.
5. Nowe węzły kluczowe i nowe umiejętności.
6. Nowe drzewko lochów (od nowa, zwrot punktów Watry).
7. Przebudzenia do wyboru (bez klas).

## Do dopytania przy kolejnych krokach

- rozkład węzłów ustalony 4.11.2026 (obecne umiejętności + 5 nowych na stronę, 5 węzłów kluczowych na stronę + 1 na strefę,
  wszystkie 7 propozycji węzłów kluczowych wchodzi, regeneracje jako skupiska i 2 aury) - szczegóły w `docs/drzewko_wspolne.md`;
- czy wybór przebudzenia jest jednorazowy, czy można go zmienić (i za ile);
- liczby rezerwacji i siły aur po ograniu (`scripts/aura_data.gd`);
- które pomysły z tabel aur i combo (propozycje) wchodzą, a które odpadają.
