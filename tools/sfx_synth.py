"""Własne efekty dźwiękowe zaklinania, syntezowane w numpy (paczki Kenney takich nie mają):
- enchant_charge.ogg - narastające magiczne trzaskanie, jak iskrzący prąd w krysztale
  (3 s, tyle co ładowanie w oknie zaklinania),
- enchant_strike.ogg - bardzo mocne uderzenie młota w kowadło z magicznym, dzwoniącym pogłosem,
- explosion.ogg - potężny wybuch kuli ognia,
- fireball_charge / fireball_hold / fireball_full / fireball_launch.ogg - ładowanie kuli ognia
  w dłoniach (narastanie, pętla przy pełnej mocy, sygnał pełnej mocy i rzut),
- anvil_* / wood_hammer_* / dummy_hit_* / bow_shot_*.ogg - naturalne uderzenia: młot kowala,
  młotek cieśli, cios w kukłę treningową i strzał z łuku (po kilka wariantów),
- frogman_croak_* / frog_attack / frog_death / spit / spit_hit - żaboludzie,
- frog_boss_roar / tongue_lash / boss_splash - ich wódz,
- big_slash / seeker_whistle / lightning_zap_* / thunder - umiejętności dodatkowe broni,
- legendary_drop / legendary_pickup - legendarny łup, shockwave / tide_wave / stun - ich efekty,
- summon / craft - przyzwanie bossa magicznym kręgiem i wytworzenie przedmiotu,
- claw - rozdzierające cięcie pazurami,
- eagle_cry / goat_bleat / birdman_screech / birdman_death / storm_eagle_screech / wing_gust - Wietrzne Turnie,
- drowner_emerge / drowner_groan / wisp_charge / wisp_burst / rusalka_song / rusalka_death / wodnik_laugh /
  whirlpool - Topielcze Uroczysko,
- treant_groan / tree_rumble / roots_burst / leshy_whisper / spider_hiss / spider_death / queen_screech /
  cocoon_burst / bear_roar / werewolf_howl / bies_roar / shroom_chime - Prastary Las.
Wymaga numpy i scipy.
Zapisuje do assets/sfx (wymaga ffmpeg w PATH).

Uruchom: python tools/sfx_synth.py [nazwa ...]  (bez nazw - wszystkie)"""
import os
import subprocess
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")
RATE = 44100
CHARGE_TIME = 3.0  # = EnchantWindow.CHARGE_TIME


def lowpass(x, cutoff):
    """Jednobiegunowy filtr dolnoprzepustowy; `cutoff` może być tablicą (zmienny w czasie)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1.0 - np.exp(-2 * np.pi * cutoff / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def reverb(x, seconds, mix, seed):
    rng = np.random.default_rng(seed)
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    ir = rng.standard_normal(n) * np.exp(-t * 4.0 / seconds)
    ir /= np.sqrt((ir ** 2).sum())
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:len(x)]
    return x * (1 - mix) + wet * mix * 1.4


def ping(f, dur, decay):
    t = np.arange(int(RATE * dur)) / RATE
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2.01 * t)) * np.exp(-t * decay)


def charge():
    rng = np.random.default_rng(11)
    n = int(RATE * CHARGE_TIME)
    t = np.arange(n) / RATE
    p = t / CHARGE_TIME  # postęp 0..1
    left = np.zeros(n)
    right = np.zeros(n)

    # magiczny brzęczący ton wznoszący się o półtorej oktawy, z chórem i przyspieszającym pulsowaniem
    f = 180.0 * 2 ** (1.6 * p ** 1.3)
    tremolo_rate = 3.0 + 22.0 * p ** 2
    tremolo = 0.6 + 0.4 * np.sin(2 * np.pi * np.cumsum(tremolo_rate) / RATE)
    for ratio, amp in ((1.0, 1.0), (1.5, 0.55), (2.0, 0.45), (3.0, 0.2)):
        for detune, side in ((-0.004, 0), (0.004, 1)):
            phase = 2 * np.pi * np.cumsum(f * ratio * (1 + detune)) / RATE
            tone = np.sin(phase) * amp
            (left if side == 0 else right)[:] += tone
    env = (0.08 + 0.92 * p ** 1.6) * tremolo
    left *= env * 0.11
    right *= env * 0.11

    # elektryczne brzęczenie (zbocza piły) dochodzące pod koniec
    buzz_phase = np.cumsum(90.0 + 60.0 * p) / RATE
    buzz = (2 * (buzz_phase % 1.0) - 1) * (rng.random(n) < 0.6 + 0.4 * p)
    buzz = lowpass(buzz, 900.0 + 2500.0 * p) * p ** 2.5 * 0.12
    left += buzz
    right += buzz * 0.8

    # szum wznoszący się jak nabierająca mocy energia
    whoosh = lowpass(rng.standard_normal(n), 300.0 + 5000.0 * p ** 2) * p ** 2 * 0.25
    left += whoosh
    right += whoosh

    # trzaski - coraz gęstsze iskry; każda dzwoni krótko wysoką, "magiczną" nutą
    sparkle_notes = [880 * 2 ** (k / 12) for k in (0, 3, 5, 7, 10, 12, 15, 17, 19, 22, 24)]
    time = 0.05
    while time < CHARGE_TIME - 0.02:
        prog = time / CHARGE_TIME
        rate = 12.0 + 160.0 * prog ** 2
        start = int(time * RATE)
        length = rng.integers(40, 300)
        click = np.diff(rng.standard_normal(length + 1)) * np.exp(-np.arange(length) / (length / 4))
        amp = rng.uniform(0.15, 0.45) * (0.4 + 0.6 * prog)
        if rng.random() < 0.35 + 0.3 * prog:  # część iskier dzwoni jak kryształ
            note = ping(rng.choice(sparkle_notes) * (1 + 0.5 * prog), 0.12, 40.0) * 0.25
            click = np.concatenate([click, np.zeros(max(0, len(note) - len(click)))])
            click[:len(note)] += note
        pan = rng.random()
        end = min(n, start + len(click))
        left[start:end] += click[:end - start] * amp * (1 - pan)
        right[start:end] += click[:end - start] * amp * pan
        time += rng.exponential(1.0 / rate)

    stereo = np.stack([left, right], axis=1)
    stereo[:int(0.05 * RATE)] *= np.linspace(0, 1, int(0.05 * RATE))[:, None]
    stereo[-int(0.01 * RATE):] *= np.linspace(1, 0.6, int(0.01 * RATE))[:, None]
    return stereo


def strike():
    rng = np.random.default_rng(23)
    dur = 2.6
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    mono = np.zeros(n)

    # trzask uderzenia stali o stal
    k = int(0.006 * RATE)
    mono[:k] += np.diff(rng.standard_normal(k + 1)) * np.linspace(1, 0, k) * 1.4
    # głuche dudnienie ciężkiego kowadła (opadająca wysokość)
    thump_f = 45.0 + 50.0 * np.exp(-t * 18)
    mono += np.sin(2 * np.pi * np.cumsum(thump_f) / RATE) * np.exp(-t * 7) * 0.9
    # nieharmoniczne alikwoty kowadła - dzwonią i powoli gasną (z lekkim dudnieniem)
    for ratio, amp, decay in ((1.0, 1.0, 2.2), (2.31, 0.65, 2.8), (3.98, 0.45, 3.6), (5.47, 0.3, 4.5),
                              (7.12, 0.22, 6.0), (9.03, 0.15, 7.5)):
        f = 410.0 * ratio
        for detune in (0.0, 0.0035):
            mono += np.sin(2 * np.pi * f * (1 + detune) * t) * amp * 0.28 * np.exp(-t * decay)

    left = mono.copy()
    right = mono.copy()
    # magiczna warstwa: jasny akord dzwonków i wznosząca się kaskada iskier
    for i, semis in enumerate((14, 18, 21, 26, 30, 33)):
        f = 440.0 * 2 ** (semis / 12)
        delay = int((0.02 + i * 0.045) * RATE)
        bell = ping(f, dur, 2.2 + i * 0.3) * 0.14
        bell = bell[:n - delay]
        target = left if i % 2 == 0 else right
        target[delay:delay + len(bell)] += bell
        (right if i % 2 == 0 else left)[delay:delay + len(bell)] += bell * 0.5
    shimmer = lowpass(rng.standard_normal(n), 7000.0) - lowpass(rng.standard_normal(n), 2500.0)
    shimmer *= np.exp(-t * 3.0) * (1 - np.exp(-t * 30)) * 0.08
    left += shimmer
    right += shimmer * 0.9

    stereo = np.stack([reverb(left, 1.8, 0.3, 1), reverb(right, 1.8, 0.3, 2)], axis=1)
    stereo = np.tanh(stereo * 1.6) / np.tanh(1.6)  # dociśnięcie - mocniejsze uderzenie
    stereo[-int(0.2 * RATE):] *= np.linspace(1, 0, int(0.2 * RATE))[:, None]
    return stereo


# ---------------------------------------------------------------- kula ognia
FIREBALL_CHARGE_TIME = 1.5  # = Skills.FIREBALL_CHARGE_TIME


def fire_roar(n, rng, cutoff, flicker=0.35):
    """Szum płomieni: przytłumiony szum z migotaniem głośności."""
    roar = lowpass(rng.standard_normal(n), cutoff)
    wobble = lowpass(rng.standard_normal(n), 6.0)
    wobble /= np.abs(wobble).max() + 1e-9
    return roar * (1.0 + flicker * wobble)


def crackles(n, rng, rate_start, rate_end, amp=0.35, pitch_notes=None):
    """Trzaski palącego się drewna / iskier; gęstość rośnie od rate_start do rate_end na sekundę."""
    out = np.zeros(n)
    dur = n / RATE
    time = 0.0
    while time < dur:
        prog = time / dur
        start = int(time * RATE)
        length = int(rng.integers(30, 220))
        click = np.diff(rng.standard_normal(length + 1)) * np.exp(-np.arange(length) / (length / 5))
        if pitch_notes is not None and rng.random() < 0.3:
            note = ping(rng.choice(pitch_notes), 0.1, 45.0) * 0.2
            click = np.concatenate([click, np.zeros(max(0, len(note) - len(click)))])
            click[:len(note)] += note
        end = min(n, start + len(click))
        out[start:end] += click[:end - start] * amp * rng.uniform(0.4, 1.0)
        time += rng.exponential(1.0 / (rate_start + (rate_end - rate_start) * prog))
    return out


def explosion():
    """Potężny wybuch: trzask, głębokie tąpnięcie, rozrywany ogień, rumor i opadające odłamki."""
    rng = np.random.default_rng(31)
    dur = 2.8
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    ch = []
    for side in range(2):
        x = np.zeros(n)
        k = int(0.025 * RATE)
        x[:k] += rng.standard_normal(k) * np.linspace(1, 0, k) ** 2 * 1.5  # trzask
        boom_f = 28.0 + 70.0 * np.exp(-t * 9)  # tąpnięcie z opadającą wysokością
        x += np.sin(2 * np.pi * np.cumsum(boom_f) / RATE) * np.exp(-t * 3.2) * 1.3
        body = lowpass(rng.standard_normal(n), 900.0 * np.exp(-t * 2.5) + 120.0)  # kula ognia
        x += body * np.exp(-t * 2.2) * (1 - np.exp(-t * 80)) * 2.6
        crunch = rng.standard_normal(n) - lowpass(rng.standard_normal(n), 1500.0)  # rozrywanie
        x += lowpass(crunch, 5000.0) * np.exp(-t * 9) * 0.6
        rumble = lowpass(rng.standard_normal(n), 90.0)  # długi pomruk
        x += rumble * np.exp(-t * 1.3) * 4.0
        debris = crackles(n, rng, 60, 4, amp=0.25)  # opadające odłamki i trzaski żaru
        x += debris * np.clip((t - 0.08) * 10, 0, 1) * np.exp(-t * 1.6)
        ch.append(reverb(x, 2.2, 0.25, 7 + side))
    stereo = np.stack(ch, axis=1)
    stereo = np.tanh(stereo * 2.2) / np.tanh(2.2)
    stereo[-int(0.3 * RATE):] *= np.linspace(1, 0, int(0.3 * RATE))[:, None]
    return stereo


def fireball_charge():
    """Ładowanie kuli: narastający huk płomieni, wznoszący się ciepły ton i coraz gęstsze trzaski."""
    rng = np.random.default_rng(41)
    n = int(RATE * FIREBALL_CHARGE_TIME)
    t = np.arange(n) / RATE
    p = t / FIREBALL_CHARGE_TIME
    ch = []
    for side in range(2):
        x = fire_roar(n, rng, 250.0 + 2600.0 * p ** 1.5) * (0.15 + 0.85 * p ** 1.4) * 1.6
        f = 110.0 * 2 ** (1.5 * p)
        for ratio, amp in ((1.0, 1.0), (2.0, 0.5), (3.0, 0.25)):
            phase = 2 * np.pi * np.cumsum(f * ratio * (1 + (0.003 if side else -0.003))) / RATE
            x += np.sin(phase) * amp * 0.12 * p ** 1.2
        x += crackles(n, rng, 8, 70, amp=0.3)
        ch.append(x)
    stereo = np.stack(ch, axis=1)
    stereo[:int(0.04 * RATE)] *= np.linspace(0, 1, int(0.04 * RATE))[:, None]
    return stereo


def fireball_hold():
    """Pełna kula w dłoniach: równy, groźny pomruk ognia (pętla 2 s bez szwu)."""
    rng = np.random.default_rng(43)
    loop = int(RATE * 2.0)
    fade = int(RATE * 0.4)
    n = loop + fade
    t = np.arange(n) / RATE
    ch = []
    for side in range(2):
        x = fire_roar(n, rng, 2400.0, flicker=0.5) * 1.3
        f = 110.0 * 2 ** 1.5
        x += (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(4 * np.pi * f * t)) * 0.1 * (1 + 0.3 * np.sin(2 * np.pi * 7 * t))
        x += crackles(n, rng, 45, 45, amp=0.3)
        # pętla: koniec przenika się z początkiem
        ramp = np.linspace(0, 1, fade)
        x[:fade] = x[:fade] * ramp + x[loop:] * (1 - ramp)
        ch.append(x[:loop])
    return np.stack(ch, axis=1)


def fireball_full():
    """Pełna moc: nagłe "WHUMP" buchającego płomienia i jasny, magiczny akord."""
    rng = np.random.default_rng(47)
    dur = 1.4
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    ch = []
    for side in range(2):
        x = lowpass(rng.standard_normal(n), 300.0 + 3500.0 * np.exp(-t * 6)) * np.exp(-t * 5) * (1 - np.exp(-t * 200)) * 2.5
        thump_f = 60.0 + 90.0 * np.exp(-t * 20)
        x += np.sin(2 * np.pi * np.cumsum(thump_f) / RATE) * np.exp(-t * 8) * 0.9
        for i, semis in enumerate((7, 11, 14, 19)):
            delay = int((0.03 + i * 0.03) * RATE)
            bell = ping(440.0 * 2 ** (semis / 12), dur, 3.5)[:n - delay] * 0.13
            x[delay:delay + len(bell)] += bell * (1.0 if (i + side) % 2 else 0.6)
        ch.append(reverb(x, 1.2, 0.25, 11 + side))
    stereo = np.stack(ch, axis=1)
    return np.tanh(stereo * 1.5) / np.tanh(1.5)


def fireball_launch():
    """Rzut: płomień przelatujący ze świstem."""
    rng = np.random.default_rng(53)
    dur = 0.7
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    env = (1 - np.exp(-t * 60)) * np.exp(-t * 4.5)
    ch = []
    for side in range(2):
        whoosh = lowpass(rng.standard_normal(n), 3500.0 * np.exp(-t * 3) + 300.0)
        roar = fire_roar(n, rng, 700.0) * 0.8
        x = (whoosh * 1.6 + roar) * env * (1.0 + 0.25 * np.sin(2 * np.pi * (3 + side) * t))
        ch.append(x)
    return np.stack(ch, axis=1)


# ---------------------------------------------------------------- naturalne uderzenia (kowal, cieśle, kukły, łuk)
from scipy import signal  # noqa: E402 - filtry pasmowe do brzmień "z nagrania", nie 8-bitowych


def band(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], "band", fs=RATE, output="sos")
    return signal.sosfilt(sos, x)


def modes(n, spec, rng, jitter=0.03):
    """Synteza modalna: [(częstotliwość, głośność, szybkość gaśnięcia)], z lekkim rozstrojeniem."""
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for f, a, d in spec:
        f *= 1 + rng.uniform(-jitter, jitter)
        out += np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * a * np.exp(-t * d)
    return out


def room(x, seed, seconds=0.5, mix=0.18):
    rng = np.random.default_rng(seed)
    n = int(RATE * seconds)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / RATE * 9.0 / seconds)
    ir /= np.sqrt((ir ** 2).sum())
    wet = signal.fftconvolve(x, ir)[:len(x)]
    return x * (1 - mix) + wet * mix


def anvil(variant):
    """Młot kowala na kowadle: twardy trzask i dzwoniące, nieharmoniczne alikwoty stali."""
    rng = np.random.default_rng(100 + variant)
    n = int(RATE * 1.3)
    t = np.arange(n) / RATE
    f0 = 1150 * rng.uniform(0.94, 1.06)
    x = modes(n, [(f0, 1.0, 5.0), (f0 * 1.47, 0.7, 6.5), (f0 * 2.09, 0.55, 8.0), (f0 * 2.56, 0.45, 10.0),
                  (f0 * 3.18, 0.35, 13.0), (f0 * 3.95, 0.25, 17.0), (f0 * 4.68, 0.2, 22.0)], rng) * 0.35
    k = int(0.004 * RATE)
    click = np.zeros(n)
    click[:k] = band(rng.standard_normal(k), 2000, 12000) * np.linspace(1, 0, k) * 0.6
    x += click
    x += np.sin(2 * np.pi * 170 * t) * np.exp(-t * 60) * 0.35  # masa młota
    if variant % 2:  # odbicie młota od kowadła
        d = int(RATE * rng.uniform(0.06, 0.09))
        x[d:] += (modes(n - d, [(f0, 1.0, 9.0), (f0 * 2.09, 0.5, 14.0)], rng) * 0.12)
    return room(x, variant, 0.6, 0.2)


def wood_hammer(variant):
    """Młotek cieśli: głuche stuknięcie w deskę i krótkie dźwięknięcie gwoździa."""
    rng = np.random.default_rng(200 + variant)
    n = int(RATE * 0.45)
    t = np.arange(n) / RATE
    x = modes(n, [(230, 1.0, 28.0), (410, 0.8, 34.0), (690, 0.5, 45.0), (1150, 0.35, 60.0)], rng, 0.08) * 0.5
    x += np.sin(2 * np.pi * 95 * t) * np.exp(-t * 30) * 0.5  # deska ugina się pod uderzeniem
    k = int(0.003 * RATE)
    x[:k] += band(rng.standard_normal(k), 800, 9000) * np.linspace(1, 0, k) * 1.8
    x += modes(n, [(3300, 1.0, 14.0), (5100, 0.6, 20.0)], rng, 0.05) * 0.06  # gwóźdź
    return room(x, 10 + variant, 0.35, 0.15)


def dummy_hit(variant):
    """Cios w kukłę: świst ostrza, głuchy worek i szelest słomy."""
    rng = np.random.default_rng(300 + variant)
    pre = int(RATE * 0.07)
    n = pre + int(RATE * 0.45)
    x = np.zeros(n)
    tw = np.arange(pre) / RATE
    swish = band(rng.standard_normal(pre), 1200, 5000) * (tw / tw[-1]) ** 2 * 0.25
    x[:pre] += swish
    t = np.arange(n - pre) / RATE
    thud = band(rng.standard_normal(n - pre), 80, 900) * np.exp(-t * 26) * 1.2
    thud += np.sin(2 * np.pi * rng.uniform(100, 130) * t) * np.exp(-t * 20) * 0.6
    grains = (rng.random(n - pre) < 0.08) * rng.standard_normal(n - pre)  # łamiące się źdźbła
    straw = band(rng.standard_normal(n - pre) * 0.4 + grains, 2500, 9000) * np.exp(-t * 9) * 0.6
    x[pre:] += thud + straw
    return room(x, 20 + variant, 0.3, 0.12)


def bow_shot(variant):
    """Strzał z łuku: brzdęk cięciwy, uderzenie w majdan i świst odlatującej strzały."""
    rng = np.random.default_rng(400 + variant)
    n = int(RATE * 0.6)
    t = np.arange(n) / RATE
    f = rng.uniform(95, 125)
    twang = modes(n, [(f, 1.0, 16.0), (f * 2, 0.6, 20.0), (f * 3, 0.35, 26.0), (f * 4.02, 0.2, 34.0)], rng, 0.01)
    twang *= 1 + 0.15 * np.sin(2 * np.pi * 9 * t) * np.exp(-t * 10)  # drganie cięciwy
    k = int(0.015 * RATE)
    slap = np.zeros(n)
    slap[:k] = band(rng.standard_normal(k), 300, 2000) * np.exp(-np.arange(k) / RATE * 300) * 1.2
    whoosh = np.zeros(n)
    w = band(rng.standard_normal(n), 700, 4500)
    centre_env = np.exp(-((t - 0.09) / 0.07) ** 2)  # przelot tuż obok ucha
    whoosh += w * centre_env * 0.35
    x = twang * 0.45 + slap + whoosh
    return room(x, 30 + variant, 0.3, 0.1)


def water_step(variant):
    """Krok w płytkiej wodzie: chlupnięcie i dwa-trzy bąbelki."""
    rng = np.random.default_rng(500 + variant)
    n = int(RATE * 0.35)
    t = np.arange(n) / RATE
    x = band(rng.standard_normal(n), 400, 4500) * np.exp(-t * 22) * (1 - np.exp(-t * 400)) * 0.9
    for _ in range(rng.integers(2, 4)):
        start = int(RATE * rng.uniform(0.02, 0.12))
        d = rng.uniform(0.02, 0.045)
        m = int(RATE * d)
        tb = np.arange(m) / RATE
        f = rng.uniform(500, 1200) * (1 + 2.0 * tb / d)
        x[start:start + m] += np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-tb * (6 / d)) * 0.35
    return room(x, 40 + variant, 0.25, 0.1)


# ---------------------------------------------------------------- żaboludzie
def croak_voice(f, dur, rng, pulse_hz=30.0, formants=((300, 260, 1.0), (850, 500, 0.5)), noise=0.2):
    """Rechot: chrapliwy, pulsujący ton krtaniowy przepuszczony przez rezonans pyska."""
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    freq = np.broadcast_to(np.asarray(f, dtype=float), (n,))
    saw = 2 * ((np.cumsum(freq) / RATE) % 1.0) - 1
    pulses = 0.45 + 0.55 * np.maximum(0, np.sin(2 * np.pi * pulse_hz * t)) ** 0.5
    src = saw * pulses + rng.standard_normal(n) * noise
    out = np.zeros(n)
    for fc, bw, g in formants:
        out += band(src, max(40, fc - bw / 2), fc + bw / 2) * g
    return out * np.clip(np.minimum(t / 0.02, 1) * np.minimum((dur - t) / 0.08, 1), 0, 1)


def frogman_croak(variant):
    rng = np.random.default_rng(600 + variant)
    parts = []
    for k in range(2 + variant):
        dur = rng.uniform(0.18, 0.3)
        n = int(RATE * dur)
        t = np.arange(n) / RATE
        parts += [croak_voice(rng.uniform(95, 125) * (1 + 0.15 * np.sin(np.pi * t / dur)), dur, rng), np.zeros(int(RATE * rng.uniform(0.08, 0.16)))]
    return room(np.concatenate(parts), 60 + variant, 0.5, 0.2)


def frog_attack(_variant):
    """Pchnięcie oszczepem: świst i krótkie, wysilone stęknięcie."""
    rng = np.random.default_rng(610)
    n = int(RATE * 0.4)
    t = np.arange(n) / RATE
    swish = band(rng.standard_normal(n), 1200, 5000) * np.exp(-((t - 0.08) / 0.05) ** 2) * 0.5
    grunt = np.zeros(n)
    g = croak_voice(150, 0.14, rng, 40.0)
    grunt[int(RATE * 0.04):int(RATE * 0.04) + len(g)] += g * 0.8
    return room(swish + grunt, 61, 0.3, 0.15)


def frog_death(_variant):
    """Bulgoczące, opadające skrzeczenie."""
    rng = np.random.default_rng(620)
    dur = 0.8
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    x = croak_voice(170 * np.exp(-t * 1.2), dur, rng, 18.0, ((400, 300, 1.0), (1000, 500, 0.4)), 0.3)
    for _ in range(8):  # bąble
        start = int(RATE * rng.uniform(0.2, 0.7))
        d = rng.uniform(0.02, 0.05)
        m = int(RATE * d)
        tb = np.arange(m) / RATE
        f = rng.uniform(250, 600) * (1 + 2 * tb / d)
        x[start:start + m] += np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-tb * 6 / d) * 0.25
    return room(x, 62, 0.4, 0.2)


def spit(_variant):
    """Splunięcie jadem: mokre "ptfu" i szum lecącej kropli."""
    rng = np.random.default_rng(630)
    n = int(RATE * 0.45)
    t = np.arange(n) / RATE
    burst = band(rng.standard_normal(n), 600, 3500) * np.exp(-t * 30) * 1.2
    wet = band(rng.standard_normal(n), 2000, 7000) * (rng.random(n) < 0.05) * np.exp(-t * 12) * 1.5
    whoosh = band(rng.standard_normal(n), 800, 2500) * np.exp(-((t - 0.18) / 0.1) ** 2) * 0.3
    return room(burst + wet + whoosh, 63, 0.25, 0.1)


def spit_hit(_variant):
    """Plaśnięcie jadu o cel."""
    rng = np.random.default_rng(640)
    n = int(RATE * 0.35)
    t = np.arange(n) / RATE
    x = band(rng.standard_normal(n), 300, 2500) * np.exp(-t * 25) * 1.2
    x += band((rng.random(n) < 0.08) * rng.standard_normal(n), 2500, 8000) * np.exp(-t * 10)
    return room(x, 64, 0.2, 0.1)


def frog_boss_roar(_variant):
    """Ryk wodza: potężny, niski, przeciągły rechot z bulgotem."""
    rng = np.random.default_rng(650)
    dur = 1.6
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    f = 62 + 18 * np.sin(np.pi * t / dur)
    x = croak_voice(f, dur, rng, 22.0, ((200, 200, 1.0), (520, 400, 0.6), (1100, 600, 0.25)), 0.25)
    return room(np.tanh(x * 2.0), 65, 1.0, 0.3)


def tongue_lash(_variant):
    """Smagnięcie językiem: mokry trzask jak bicz i szybkie zwinięcie."""
    rng = np.random.default_rng(660)
    n = int(RATE * 0.5)
    t = np.arange(n) / RATE
    swish = band(rng.standard_normal(n), 700, 4000) * np.exp(-((t - 0.07) / 0.05) ** 2) * 0.6
    crack = np.zeros(n)
    k = int(0.006 * RATE)
    at = int(RATE * 0.12)
    crack[at:at + k] = band(rng.standard_normal(k), 1500, 9000) * np.linspace(1, 0, k) * 2.0
    slurp = band(rng.standard_normal(n), 300, 1500) * np.exp(-((t - 0.3) / 0.08) ** 2) * 0.5
    return room(swish + crack + slurp, 66, 0.3, 0.15)


def boss_splash(_variant):
    """Lądowanie wodza: ciężkie tąpnięcie i wielki plusk wody."""
    rng = np.random.default_rng(670)
    dur = 1.6
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    thump = np.sin(2 * np.pi * np.cumsum(45 + 60 * np.exp(-t * 14)) / RATE) * np.exp(-t * 5) * 1.2
    splash = band(rng.standard_normal(n), 400, 6000) * np.exp(-t * 4.5) * (1 - np.exp(-t * 60)) * 1.0
    drops = band((rng.random(n) < 0.02) * rng.standard_normal(n), 1500, 6000) * np.exp(-t * 2.0) * 1.5
    return room(np.tanh((thump + splash + drops) * 1.5), 67, 0.8, 0.25)


# ---------------------------------------------------------------- umiejętności dodatkowe
def big_slash(_variant):
    """Półksiężyc: ciężki, długi świst szerokiego cięcia."""
    rng = np.random.default_rng(700)
    n = int(RATE * 0.55)
    t = np.arange(n) / RATE
    centre = 900 + 2600 * np.exp(-((t - 0.18) / 0.12) ** 2)
    x = np.zeros(n)
    noise = rng.standard_normal(n)
    for lo, hi, g in ((300, 1200, 0.8), (1200, 4000, 0.6)):
        x += band(noise, lo, hi) * g
    x *= np.exp(-((t - 0.18) / 0.13) ** 2) * (centre / centre.max())
    return room(x * 1.4, 70, 0.4, 0.15)


def seeker_whistle(_variant):
    """Strzała tropiąca: brzdęk cięciwy i wznoszący się, magiczny gwizd."""
    rng = np.random.default_rng(710)
    n = int(RATE * 0.8)
    t = np.arange(n) / RATE
    whistle = np.sin(2 * np.pi * np.cumsum(1400 + 900 * t / 0.8 + 60 * np.sin(2 * np.pi * 9 * t)) / RATE)
    whistle *= np.minimum(t / 0.05, 1) * np.exp(-t * 2.5) * 0.35
    twang = modes(n, [(110, 1.0, 16.0), (220, 0.6, 20.0), (330, 0.3, 26.0)], rng, 0.01) * 0.4
    return room(whistle + twang, 71, 0.5, 0.2)


def lightning_zap(variant):
    """Błyskawica: ostry, elektryczny trzask z buczeniem."""
    rng = np.random.default_rng(720 + variant)
    n = int(RATE * 0.45)
    t = np.arange(n) / RATE
    crackle = band(rng.standard_normal(n) * (rng.random(n) < 0.35), 1500, 9000) * np.exp(-t * 9) * 1.4
    buzz_phase = np.cumsum(np.full(n, 120.0)) / RATE
    buzz = band(2 * (buzz_phase % 1.0) - 1, 200, 3000) * np.exp(-t * 7) * 0.5
    snap = np.zeros(n)
    k = int(0.004 * RATE)
    snap[:k] = rng.standard_normal(k) * np.linspace(1, 0, k) * 1.5
    return room(crackle + buzz + snap, 72 + variant, 0.4, 0.2)


def thunder(_variant):
    """Fala piorunów: trzask wyładowania przechodzący w toczący się grzmot."""
    rng = np.random.default_rng(730)
    dur = 1.8
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    crack = band(rng.standard_normal(n), 800, 8000) * np.exp(-t * 14) * 1.3
    rumble = band(rng.standard_normal(n), 30, 300) * np.exp(-t * 1.6) * (1 - np.exp(-t * 20)) * 3.0
    roll = band(rng.standard_normal(n), 120, 800) * np.exp(-t * 2.5) * (0.6 + 0.4 * np.sin(2 * np.pi * 3 * t)) * 0.8
    return room(np.tanh((crack + rumble + roll) * 1.6), 74, 1.2, 0.3)


# ---------------------------------------------------------------- legendarne przedmioty
def chime(freqs, t, decay, shimmer=0.0):
    x = np.zeros_like(t)
    for i, f in enumerate(freqs):
        env = np.exp(-t * decay)
        x += (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * decay * 2)) * env
        if shimmer:
            x *= 1 + shimmer * np.sin(2 * np.pi * (5 + i) * t) * 0.1
    return x / len(freqs)


def legendary_drop(_variant):
    """Legendarny łup spada: głębokie tąpnięcie i wznoszący się, migoczący dzwon."""
    rng = np.random.default_rng(800)
    dur = 2.6
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    thump = np.sin(2 * np.pi * np.cumsum(55 + 50 * np.exp(-t * 12)) / RATE) * np.exp(-t * 4) * 0.9
    x = thump
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.5, 1318.5)):  # C-dur w górę
        start = int(RATE * (0.08 + i * 0.09))
        tt = t[:n - start]
        x[start:] += chime([f], tt, 1.6, 1.0) * 0.55
    sparkle = band(rng.standard_normal(n) * (rng.random(n) < 0.004), 4000, 12000) * np.exp(-t * 1.2) * 1.2
    return reverb(np.tanh((x + sparkle) * 1.3), 1.6, 0.4, 801)


def legendary_pickup(_variant):
    """Podniesienie legendy: jasny, triumfalny akord z blaskiem."""
    rng = np.random.default_rng(810)
    dur = 2.2
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for i, chord in enumerate(((392.0, 493.88, 587.33), (523.25, 659.25, 783.99, 1046.5))):
        start = int(RATE * i * 0.16)
        tt = t[:n - start]
        swell = np.minimum(tt / 0.01, 1)
        x[start:] += chime(chord, tt, 1.4 if i else 6.0, 1.0) * swell * (1.0 if i else 0.7)
    sparkle = band(rng.standard_normal(n) * (rng.random(n) < 0.006), 5000, 14000) * np.exp(-t * 1.5)
    return reverb(x + sparkle, 1.4, 0.35, 811)


def shockwave(_variant):
    """Fala uderzeniowa: suche trzaśnięcie, głęboki, rozchodzący się huk i drżenie ziemi."""
    rng = np.random.default_rng(820)
    dur = 1.2
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    boom = np.sin(2 * np.pi * np.cumsum(38 + 90 * np.exp(-t * 18)) / RATE) * np.exp(-t * 4.5) * 1.4
    crack = band(rng.standard_normal(n), 900, 7000) * np.exp(-t * 30) * 1.2
    rumble = band(rng.standard_normal(n), 30, 220) * np.exp(-t * 3.0) * (1 - np.exp(-t * 30)) * 2.5
    whoosh = band(rng.standard_normal(n), 300, 2500) * np.exp(-((t - 0.12) / 0.1) ** 2) * 0.6
    return room(np.tanh((boom + crack + rumble + whoosh) * 1.5), 82, 0.7, 0.25)


def tide_wave(_variant):
    """Fala wody: narastający szum, uderzenie i rozbryzg kropel."""
    rng = np.random.default_rng(830)
    dur = 1.3
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    rush = band(rng.standard_normal(n), 200, 2500) * np.minimum(t / 0.15, 1) * np.exp(-np.maximum(t - 0.15, 0) * 4) * 1.2
    crash = band(rng.standard_normal(n), 600, 7000) * np.exp(-np.maximum(t - 0.18, 0) * 6) * (t > 0.17) * 1.1
    drops = band((rng.random(n) < 0.015) * rng.standard_normal(n), 1500, 6000) * np.exp(-t * 2.2) * (t > 0.2) * 1.5
    body = np.sin(2 * np.pi * np.cumsum(70 + 40 * np.exp(-np.maximum(t - 0.17, 0) * 10)) / RATE) *         np.exp(-np.maximum(t - 0.17, 0) * 6) * (t > 0.17) * 0.6
    return room(np.tanh((rush + crash + drops + body) * 1.3), 83, 0.6, 0.2)


def stun(_variant):
    """Ogłuszenie: krótkie, dzwoniące "dzyń" z wirującym ćwierkaniem."""
    n = int(RATE * 0.7)
    t = np.arange(n) / RATE
    ring = chime([1760.0, 2217.0], t, 6.0) * 0.6
    tweet = np.sin(2 * np.pi * np.cumsum(2600 + 500 * np.sin(2 * np.pi * 14 * t)) / RATE) * np.exp(-t * 7) * 0.25
    return room(ring + tweet, 84, 0.3, 0.15)


def summon(_variant):
    """Przyzwanie: narastający, mroczny chór i świst, a na szczycie potężne tąpnięcie."""
    rng = np.random.default_rng(840)
    dur = 2.6
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    rise = np.clip(t / 1.1, 0, 1)
    choir = np.zeros(n)
    for f in (110.0, 130.81, 164.81, 220.0):  # moll, lekko rozstrojony
        for det in (-0.6, 0.6):
            choir += np.sin(2 * np.pi * np.cumsum((f + det) * (1 + 0.5 * rise ** 2)) / RATE)
    choir *= rise ** 1.5 * np.exp(-np.maximum(t - 1.1, 0) * 2.5) * 0.12
    whoosh = band(rng.standard_normal(n), 300, 4000) * rise ** 3 * (t < 1.12) * 0.7
    boom_t = np.maximum(t - 1.1, 0)
    boom = np.sin(2 * np.pi * np.cumsum(40 + 80 * np.exp(-boom_t * 15)) / RATE) * np.exp(-boom_t * 3.5) * (t >= 1.1) * 1.4
    shimmer = band(rng.standard_normal(n) * (rng.random(n) < 0.01), 5000, 14000) * (t >= 1.1) * np.exp(-boom_t * 1.5) * 1.5
    return reverb(np.tanh((choir + whoosh + boom + shimmer) * 1.4), 1.8, 0.4, 841)


def craft(_variant):
    """Wytworzenie: dwa stuknięcia warsztatowe i krótki, magiczny dzwonek."""
    rng = np.random.default_rng(850)
    n = int(RATE * 1.0)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for start in (0.0, 0.16):
        k = int(start * RATE)
        x[k:] += modes(n - k, [(320, 1.0, 30.0), (870, 0.5, 40.0), (1650, 0.3, 50.0)], rng) * 0.8
    k = int(0.32 * RATE)
    x[k:] += chime([1318.5, 1975.5], t[:n - k], 4.0) * 0.6
    return room(x, 85, 0.4, 0.2)


def claw(_variant):
    """Pazury: trzy bardzo szybkie, ostre świsty jeden po drugim i mięsiste rozdarcie."""
    rng = np.random.default_rng(860)
    n = int(RATE * 0.4)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for i in range(3):
        start = 0.012 * i
        env = np.exp(-((t - start - 0.03) / 0.018) ** 2)
        x += band(rng.standard_normal(n), 2000 + 600 * i, 9000) * env * 0.8
    tear = band(rng.standard_normal(n), 300, 2500) * np.exp(-np.maximum(t - 0.05, 0) * 25) * (t > 0.04) * 0.9
    return room(x + tear, 86, 0.25, 0.12)


def screech(f0, f1, dur, rng, rough=0.25, vib=0.0):
    """Ptasi krzyk: opadający (albo wznoszący) ton z chrypką i szybkim drganiem."""
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    p = t / dur
    freq = f0 + (f1 - f0) * p ** 0.7 + vib * np.sin(2 * np.pi * 28 * t) * f0 * 0.02
    phase = np.cumsum(freq) / RATE
    tone = np.sin(2 * np.pi * phase) + 0.45 * np.sin(4 * np.pi * phase) + 0.2 * np.sin(6 * np.pi * phase)
    env = np.minimum(t / 0.03, 1) * np.exp(-np.maximum(p - 0.55, 0) * 6)
    noise = band(rng.standard_normal(n), 1500, 7000) * rough
    return (tone * 0.5 + noise) * env


def eagle_cry(_variant):
    """Orzeł: wysoki, przeciągły krzyk "kiiii-ja" z echem gór."""
    rng = np.random.default_rng(870)
    a = screech(2600, 2100, 0.55, rng, 0.18, 1.0)
    b = screech(2300, 1500, 0.35, rng, 0.2, 1.0)
    gap = np.zeros(int(RATE * 0.06))
    x = np.concatenate([a, gap, b * 0.8, np.zeros(int(RATE * 0.5))])
    return reverb(x, 1.4, 0.35, 871)


def goat_bleat(_variant):
    """Koza: drżące "meee" z nosowym brzmieniem."""
    rng = np.random.default_rng(880)
    dur = 0.7
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    f = 420 + 40 * np.sin(2 * np.pi * 9 * t) * (t > 0.08)
    phase = np.cumsum(f) / RATE
    saw = 2 * (phase % 1.0) - 1
    voice = band(saw, 500, 3200) * np.minimum(t / 0.04, 1) * np.exp(-np.maximum(t - 0.45, 0) * 8)
    breath = band(rng.standard_normal(n), 800, 3000) * 0.1 * np.exp(-t * 3)
    return room(voice + breath, 88, 0.3, 0.15)


def birdman_screech(_variant):
    """Ptakoczłek: chrapliwy, wojowniczy wrzask."""
    rng = np.random.default_rng(890)
    x = screech(1500, 900, 0.5, rng, 0.45, 2.0) + screech(760, 450, 0.5, rng, 0.2) * 0.6
    return room(np.tanh(x * 1.6), 89, 0.4, 0.2)


def birdman_death(_variant):
    """Ptakoczłek pada: urwany skrzek i szelest piór."""
    rng = np.random.default_rng(900)
    cry = screech(1300, 500, 0.35, rng, 0.4)
    n = int(RATE * 0.6)
    t = np.arange(n) / RATE
    rustle = band(rng.standard_normal(n), 2000, 8000) * np.exp(-t * 6) * 0.4
    x = np.zeros(n)
    x[:len(cry)] += cry
    return room(x + rustle, 90, 0.3, 0.15)


def storm_eagle_screech(_variant):
    """Gromoskrzydły: potężny krzyk orła zmieszany z trzaskiem wyładowania i pomrukiem grzmotu."""
    rng = np.random.default_rng(910)
    cry = screech(1500, 950, 1.0, rng, 0.35, 2.0) + screech(750, 480, 1.0, rng, 0.2) * 0.7
    n = int(RATE * 1.8)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    x[:len(cry)] += cry
    crackle = band(rng.standard_normal(n) * (rng.random(n) < 0.25), 2000, 9000) * np.exp(-t * 3) * 0.6
    rumble = band(rng.standard_normal(n), 30, 250) * np.exp(-t * 1.5) * (1 - np.exp(-t * 10)) * 1.8
    return reverb(np.tanh((x + crackle + rumble) * 1.4), 1.4, 0.35, 911)


def wing_gust(_variant):
    """Uderzenie wielkich skrzydeł: dwa ciężkie, wiejące "łup"."""
    rng = np.random.default_rng(920)
    n = int(RATE * 0.9)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for start in (0.0, 0.32):
        env = np.exp(-((t - start - 0.08) / 0.07) ** 2)
        x += band(rng.standard_normal(n), 120, 1500) * env * 1.3
        x += np.sin(2 * np.pi * 60 * t) * env * 0.5
    return room(np.tanh(x * 1.4), 92, 0.4, 0.2)



def drowner_emerge(_variant):
    """Utopiec wynurza się: chlupot, spływająca woda i bulgot."""
    rng = np.random.default_rng(940)
    n = int(RATE * 1.0)
    t = np.arange(n) / RATE
    splash = band(rng.standard_normal(n), 300, 5000) * np.exp(-t * 6) * (1 - np.exp(-t * 80)) * 1.2
    drip = band((rng.random(n) < 0.02) * rng.standard_normal(n), 1500, 6000) * np.exp(-t * 2.5) * 1.4
    gurgle = np.sin(2 * np.pi * np.cumsum(90 + 40 * np.sin(2 * np.pi * 7 * t)) / RATE) * np.exp(-t * 4) * 0.4
    return room(np.tanh((splash + drip + gurgle) * 1.3), 94, 0.5, 0.2)


def drowner_groan(_variant):
    """Utopiec: niski, bulgoczący jęk przez wodę."""
    rng = np.random.default_rng(950)
    n = int(RATE * 0.8)
    t = np.arange(n) / RATE
    f = 110 + 20 * np.sin(2 * np.pi * 3 * t) - 30 * t
    phase = np.cumsum(f) / RATE
    voice = band(2 * (phase % 1.0) - 1, 150, 1200) * (0.6 + 0.4 * np.sin(2 * np.pi * 18 * t))
    bubbles = band((rng.random(n) < 0.01) * rng.standard_normal(n), 300, 1500) * 2.0
    env = np.minimum(t / 0.06, 1) * np.exp(-np.maximum(t - 0.5, 0) * 8)
    return room((voice + bubbles) * env, 95, 0.5, 0.25)


def wisp_charge(_variant):
    """Ognik rozjarza się: wznoszący się, drżący ton."""
    n = int(RATE * 0.7)
    t = np.arange(n) / RATE
    f = 500 + 900 * (t / 0.7) ** 2
    tone = np.sin(2 * np.pi * np.cumsum(f) / RATE) * (0.6 + 0.4 * np.sin(2 * np.pi * 30 * t))
    return room(tone * np.minimum(t / 0.05, 1) * 0.5, 96, 0.3, 0.2)


def wisp_burst(_variant):
    """Ognik wybucha: miękki, szklisty trzask i syk."""
    rng = np.random.default_rng(970)
    n = int(RATE * 0.8)
    t = np.arange(n) / RATE
    pop = band(rng.standard_normal(n), 800, 7000) * np.exp(-t * 14) * 1.2
    shimmer = chime([1600.0, 2400.0], t, 7.0) * 0.5
    hiss = band(rng.standard_normal(n), 3000, 9000) * np.exp(-t * 5) * 0.3
    return room(pop + shimmer + hiss, 97, 0.4, 0.2)


def rusalka_song(_variant):
    """Topielica śpiewa: upiorna, wolna melodia na samogłoskach, z pogłosem nad wodą."""
    dur = 3.2
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    notes = [(0.0, 523.25), (0.7, 493.88), (1.3, 440.0), (2.0, 392.0), (2.5, 440.0)]
    f = np.full(n, notes[0][1])
    for start, freq in notes:
        f[t >= start] = freq
    f = f * (1 + 0.006 * np.sin(2 * np.pi * 5.5 * t))
    phase = np.cumsum(f) / RATE
    voice = np.sin(2 * np.pi * phase) + 0.35 * np.sin(4 * np.pi * phase) + 0.15 * np.sin(6 * np.pi * phase)
    env = np.minimum(t / 0.3, 1) * np.minimum((dur - t) / 0.6, 1)
    return reverb(voice * env * 0.4, 2.0, 0.55, 981)


def rusalka_death(_variant):
    """Topielica znika: opadający, rozmywający się jęk."""
    n = int(RATE * 1.4)
    t = np.arange(n) / RATE
    f = 600 * np.exp(-t * 0.9)
    tone = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t * 2.0)
    return reverb(tone * 0.5, 1.6, 0.6, 991)


def wodnik_laugh(_variant):
    """Wodnik: gulgoczący, basowy rechot staruszka - "ho-ho-ho" przez wodę."""
    rng = np.random.default_rng(1000)
    dur = 1.6
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for k, start in enumerate((0.0, 0.32, 0.64, 0.98)):
        tt = t - start
        env = np.exp(-np.maximum(tt, 0) * 7) * (tt > 0) * np.minimum(np.maximum(tt, 0) / 0.02, 1)
        f = 120 - k * 8 + 15 * np.exp(-np.maximum(tt, 0) * 10)
        phase = np.cumsum(f) / RATE
        x += band(2 * (phase % 1.0) - 1, 120, 1400) * env * (0.7 + 0.3 * np.sin(2 * np.pi * 22 * t))
    bubbles = band((rng.random(n) < 0.015) * rng.standard_normal(n), 200, 1200) * np.exp(-t * 1.5) * 2.0
    return room(np.tanh((x + bubbles) * 1.5), 101, 0.7, 0.3)


def whirlpool(_variant):
    """Wir: narastający, krążący szum wody."""
    rng = np.random.default_rng(1010)
    dur = 2.2
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    swirl = band(rng.standard_normal(n), 200, 2500) * (0.6 + 0.4 * np.sin(2 * np.pi * 2.5 * t))
    env = np.minimum(t / 0.4, 1) * np.minimum((dur - t) / 0.5, 1)
    gurgle = np.sin(2 * np.pi * np.cumsum(70 + 30 * np.sin(2 * np.pi * 4 * t)) / RATE) * 0.3
    return room((swirl + gurgle) * env, 102, 0.5, 0.2)


# ---------------------------------------------------------------- Prastary Las
def growl(f0, dur, seed, rough=0.6, lo=80, hi=1800, fall=0.3):
    """Zwierzęcy ryk: piłokształtny ton z chrypą (szum + modulacja), opadający pod koniec."""
    rng = np.random.default_rng(seed)
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    f = f0 * (1 + 0.15 * np.sin(np.pi * t / dur) - fall * (t / dur) ** 2) * (1 + 0.03 * rng.standard_normal(n).cumsum() / np.sqrt(n))
    phase = np.cumsum(f) / RATE
    saw = 2 * (phase % 1.0) - 1
    rasp = rng.standard_normal(n) * rough
    x = band(saw * (1 + 0.5 * np.sin(2 * np.pi * 31 * t)) + rasp * 0.5, lo, hi)
    env = np.minimum(t / 0.08, 1) * np.minimum((dur - t) / 0.25, 1)
    return np.tanh(x * env * 2.0)


def treant_groan(_variant):
    """Drzewiec: skrzypiący, drewniany jęk - jak pień gięty wiatrem."""
    rng = np.random.default_rng(1100)
    n = int(RATE * 1.4)
    t = np.arange(n) / RATE
    f = 70 + 25 * np.sin(2 * np.pi * 0.7 * t)
    creak = band((np.sin(2 * np.pi * np.cumsum(f) / RATE) > 0.95) * 1.0 + rng.standard_normal(n) * 0.05, 300, 2500)
    body = band(2 * ((np.cumsum(f * 0.5) / RATE) % 1.0) - 1, 50, 400) * 0.6
    env = np.minimum(t / 0.2, 1) * np.minimum((1.4 - t) / 0.4, 1)
    return room((creak * 2.0 + body) * env, 1101, 0.8, 0.3)


def tree_rumble(_variant):
    """Prastare drzewo się budzi: głuchy grzmot spod ziemi i trzask korzeni."""
    rng = np.random.default_rng(1110)
    n = int(RATE * 1.6)
    t = np.arange(n) / RATE
    rumble = band(rng.standard_normal(n), 25, 140) * np.minimum(t / 0.3, 1) * np.exp(-t * 1.5) * 3.0
    cracks = band((rng.random(n) < 0.002) * rng.standard_normal(n), 600, 4000) * 4.0 * np.exp(-t * 1.0)
    return room(np.tanh(rumble + cracks), 1111, 1.0, 0.3)


def roots_burst(_variant):
    """Korzenie wystrzeliwują z ziemi: trzask, chrzęst ziemi i drewna."""
    rng = np.random.default_rng(1120)
    n = int(RATE * 0.8)
    t = np.arange(n) / RATE
    crack = band(rng.standard_normal(n), 400, 5000) * np.exp(-t * 12) * 1.5
    earth = band(rng.standard_normal(n), 60, 400) * np.exp(-t * 5) * 1.5
    splinter = band((rng.random(n) < 0.004) * rng.standard_normal(n), 1500, 7000) * 3.0 * np.exp(-t * 4)
    return room(np.tanh(crack + earth + splinter), 1121, 0.5, 0.2)


def leshy_whisper(_variant):
    """Leszy: szeleszczący szept liści zlany z głębokim, ludzkim pomrukiem."""
    rng = np.random.default_rng(1130)
    dur = 2.0
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    rustle = band(rng.standard_normal(n), 2000, 8000) * (0.5 + 0.5 * np.sin(2 * np.pi * 3.3 * t) ** 2)
    f = 85 + 10 * np.sin(2 * np.pi * 0.8 * t)
    hum = band(2 * ((np.cumsum(f) / RATE) % 1.0) - 1, 60, 700) * 0.8
    env = np.minimum(t / 0.4, 1) * np.minimum((dur - t) / 0.6, 1)
    return reverb((rustle * 0.6 + hum) * env, 1.6, 0.5, 1131)


def spider_hiss(_variant):
    """Pająk: suchy syk i stukot odnóży."""
    rng = np.random.default_rng(1140)
    n = int(RATE * 0.6)
    t = np.arange(n) / RATE
    hiss = band(rng.standard_normal(n), 3000, 10000) * np.minimum(t / 0.04, 1) * np.exp(-t * 4)
    clicks = band((rng.random(n) < 0.003) * 1.0, 1500, 6000) * 4.0
    return room(hiss + clicks, 1141, 0.3, 0.15)


def spider_death(_variant):
    """Pająk ginie: mokre chrupnięcie pancerza i cichnący pisk."""
    rng = np.random.default_rng(1150)
    n = int(RATE * 0.6)
    t = np.arange(n) / RATE
    crunch = band(rng.standard_normal(n), 500, 4000) * np.exp(-t * 18) * 2.0
    f = 2200 * np.exp(-t * 3)
    squeal = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t * 6) * 0.3
    return room(np.tanh(crunch + squeal), 1151, 0.3, 0.15)


def queen_screech(_variant):
    """Królowa Pająków: przeszywający, wielogłosowy wrzask z sykiem."""
    rng = np.random.default_rng(1160)
    dur = 1.5
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    x = np.zeros(n)
    for f0 in (620.0, 910.0, 1350.0):
        f = f0 * (1 + 0.08 * np.sin(2 * np.pi * 7 * t) - 0.2 * t / dur)
        x += np.sign(np.sin(2 * np.pi * np.cumsum(f) / RATE)) * 0.3
    x = band(x, 400, 5000) + band(rng.standard_normal(n), 3000, 9000) * 0.5
    env = np.minimum(t / 0.05, 1) * np.minimum((dur - t) / 0.4, 1)
    return reverb(np.tanh(x * env * 1.5), 1.0, 0.35, 1161)


def cocoon_burst(_variant):
    """Kokon pęka: mlaszczące rozdarcie jedwabiu i chrobot małych odnóży."""
    rng = np.random.default_rng(1170)
    n = int(RATE * 0.9)
    t = np.arange(n) / RATE
    tear = band(rng.standard_normal(n), 800, 6000) * np.exp(-t * 9) * (1 + np.sin(2 * np.pi * 40 * t))
    squish = band(rng.standard_normal(n), 100, 800) * np.exp(-t * 12) * 1.5
    skitter = band((rng.random(n) < 0.006) * 1.0, 2000, 8000) * 3.0 * (t > 0.2)
    return room(tear + squish + skitter, 1171, 0.3, 0.15)


def bear_roar(_variant):
    """Bestia-niedźwiedź: głęboki, chrapliwy ryk."""
    return room(growl(95, 1.4, 1180, rough=0.9, lo=60, hi=1500), 1181, 0.8, 0.3)


def werewolf_howl(_variant):
    """Wilkołak: wycie wznoszące się i chrapliwie opadające."""
    rng = np.random.default_rng(1190)
    dur = 2.0
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    f = 300 + 280 * np.sin(np.pi * np.minimum(t / 1.6, 1)) ** 0.7
    phase = np.cumsum(f * (1 + 0.01 * np.sin(2 * np.pi * 5 * t))) / RATE
    voice = np.sin(2 * np.pi * phase) + 0.4 * np.sin(4 * np.pi * phase) + 0.2 * np.sin(6 * np.pi * phase)
    rasp = band(rng.standard_normal(n), 800, 3000) * 0.25
    env = np.minimum(t / 0.15, 1) * np.minimum((dur - t) / 0.5, 1)
    return reverb((voice * 0.5 + rasp) * env, 1.8, 0.45, 1191)


def bies_roar(_variant):
    """Bies: demoniczny ryk - dwa rozstrojone głosy, bardzo niski pomruk i syk."""
    a = growl(70, 1.8, 1200, rough=1.0, lo=40, hi=1200, fall=0.4)
    b = growl(104, 1.8, 1201, rough=0.7, lo=80, hi=2500, fall=0.5)
    n = len(a)
    t = np.arange(n) / RATE
    sub_ = np.sin(2 * np.pi * 38 * t) * np.minimum(t / 0.2, 1) * np.exp(-t * 1.2) * 0.8
    return reverb(np.tanh((a + b * 0.7 + sub_) * 1.3), 1.4, 0.35, 1202)


def shroom_chime(_variant):
    """Grzyby się rozświetlają: cichy, szklisty, magiczny dzwoneczek."""
    n = int(RATE * 1.2)
    t = np.arange(n) / RATE
    x = chime([1318.5, 1975.5], t, 5.0, shimmer=1.0) + chime([2637.0], np.maximum(t - 0.08, 0), 7.0) * (t > 0.08) * 0.6
    return reverb(x * np.minimum(t / 0.01, 1) * 0.5, 1.2, 0.5, 1210)


def save_set(fn, name, count):
    for v in range(count):
        save(np.repeat(fn(v).reshape(-1, 1), 2, axis=1), f"{name}_{v + 1}")


def save(audio, name):
    audio = audio * (0.95 / np.abs(audio).max())
    pcm = (audio * 32767).astype("<i2").tobytes()
    path = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", str(RATE), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "5", path], input=pcm, check=True)
    print("Zapisano", path, "%.2f s" % (len(audio) / RATE))


LEGENDARY = ((legendary_drop, "legendary_drop"), (legendary_pickup, "legendary_pickup"), (shockwave, "shockwave"),
             (tide_wave, "tide_wave"), (stun, "stun"), (summon, "summon"), (craft, "craft"), (claw, "claw"),
             (eagle_cry, "eagle_cry"), (goat_bleat, "goat_bleat"), (birdman_screech, "birdman_screech"),
             (birdman_death, "birdman_death"), (storm_eagle_screech, "storm_eagle_screech"), (wing_gust, "wing_gust"),
             (drowner_emerge, "drowner_emerge"), (drowner_groan, "drowner_groan"), (wisp_charge, "wisp_charge"),
             (wisp_burst, "wisp_burst"), (rusalka_song, "rusalka_song"), (rusalka_death, "rusalka_death"),
             (wodnik_laugh, "wodnik_laugh"), (whirlpool, "whirlpool"),
             (treant_groan, "treant_groan"), (tree_rumble, "tree_rumble"), (roots_burst, "roots_burst"),
             (leshy_whisper, "leshy_whisper"), (spider_hiss, "spider_hiss"), (spider_death, "spider_death"),
             (queen_screech, "queen_screech"), (cocoon_burst, "cocoon_burst"), (bear_roar, "bear_roar"),
             (werewolf_howl, "werewolf_howl"), (bies_roar, "bies_roar"), (shroom_chime, "shroom_chime"))


def main():
    os.makedirs(OUT, exist_ok=True)
    only = set(sys.argv[1:])
    if only:
        for fn, name in LEGENDARY:
            if name in only:
                save(np.repeat(fn(0).reshape(-1, 1), 2, axis=1), name)
        return
    save(charge(), "enchant_charge")
    save(strike(), "enchant_strike")
    save(explosion(), "explosion")
    save(fireball_charge(), "fireball_charge")
    save(fireball_hold(), "fireball_hold")
    save(fireball_full(), "fireball_full")
    save(fireball_launch(), "fireball_launch")
    save_set(anvil, "anvil", 4)
    save_set(wood_hammer, "wood_hammer", 4)
    save_set(dummy_hit, "dummy_hit", 4)
    save_set(bow_shot, "bow_shot", 3)
    save_set(water_step, "water_step", 3)
    save_set(frogman_croak, "frogman_croak", 2)
    save_set(lightning_zap, "lightning_zap", 2)
    for fn, name in ((frog_attack, "frog_attack"), (frog_death, "frog_death"), (spit, "spit"), (spit_hit, "spit_hit"),
                     (frog_boss_roar, "frog_boss_roar"), (tongue_lash, "tongue_lash"), (boss_splash, "boss_splash"),
                     (big_slash, "big_slash"), (seeker_whistle, "seeker_whistle"), (thunder, "thunder")) + LEGENDARY:
        save(np.repeat(fn(0).reshape(-1, 1), 2, axis=1), name)


if __name__ == "__main__":
    main()
