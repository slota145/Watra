"""Odgłosy otoczenia lasu, syntezowane w numpy/scipy:
- gust_*.ogg - podmuchy wiatru w koronach drzew (szelest liści narasta i cichnie),
- bird_*.ogg - pojedyncze głosy ptaków (wróbel, zięba, kos, sikora, kukułka, dzięcioł, gołąb, gawia),
- frog_*.ogg - żaby z rozlewisk (rechot żaby i kumkanie rzekotki),
- river_loop.ogg - szemrząca rzeka (pętla 12 s bez szwu, grana przy wodzie),
- głosy zwierząt: deer_roar_* (odległy ryk jelenia na rykowisku), deer_grunt, roe_bark (szczekanie
  sarny), boar_grunt_*, boar_squeal, duck_quack_*, wing_flap (zrywające się ptaki), crane_call
  (klangor żurawia), dragonfly (brzęczenie skrzydeł ważki).
  które gra odtwarza losowo wokół postaci, żeby otoczenie się nie powtarzało.
Zapisuje do assets/sfx (wymaga ffmpeg w PATH).

Uruchom: python tools/ambient.py"""
import os
import subprocess

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")
RATE = 44100


def save(audio, name, peak=0.9):
    audio = np.atleast_2d(audio.T).T if audio.ndim == 1 else audio
    if audio.ndim == 1 or audio.shape[1] == 1:
        audio = np.repeat(audio.reshape(-1, 1), 2, axis=1)
    audio = audio * (peak / (np.abs(audio).max() + 1e-9))
    pcm = (audio * 32767).astype("<i2").tobytes()
    path = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", str(RATE), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "4", path], input=pcm, check=True)
    print("Zapisano", path, "%.1f s" % (len(audio) / RATE))


def shaped_noise(n, rng, shape):
    """Szum o zadanym widmie, liczony przez FFT - sam z siebie zapętla się bez szwu."""
    spectrum = np.fft.rfft(rng.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    out = np.fft.irfft(spectrum * shape(freqs), n)
    return out / (np.abs(out).max() + 1e-9)


def slow_envelope(n, rng, cutoff_hz):
    """Powolna, zapętlona obwiednia (porywy wiatru) w zakresie 0..1."""
    env = shaped_noise(n, rng, lambda f: (f < cutoff_hz) * 1.0)
    env -= env.min()
    return env / (env.max() + 1e-9)


# ---------------------------------------------------------------- podmuchy wiatru w liściach
def gust(variant):
    """Jeden podmuch: wiatr narasta, przewiewa przez korony drzew i cichnie (5-9 s).
    Same gładkie szumy, bez pojedynczych trzasków: miękkie "szszsz" powietrza o wolno
    zmieniającej się barwie i - przy silniejszym wietrze - gęsty, lekko trzepoczący szelest liści.
    Podmuch przesuwa się w stereo z jednej strony na drugą."""
    rng = np.random.default_rng(50 + variant)
    dur = rng.uniform(5.0, 9.0)
    n = int(RATE * dur)
    p = np.arange(n) / n
    peak = rng.uniform(0.35, 0.5)
    bell = np.where(p < peak, np.sin(np.pi / 2 * p / peak) ** 2, np.cos(np.pi / 2 * (p - peak) / (1 - peak)) ** 1.5)
    swell = shaped_noise(n, rng, lambda f: ((f > 0.15) & (f < 1.2)) * 1.0)  # wiatr faluje
    env = np.clip(bell * (0.82 + 0.18 * swell), 0, 1)
    pan = np.linspace(0.3, 0.7, n) if variant % 2 else np.linspace(0.7, 0.3, n)

    channels = []
    for side in range(2):
        r = np.random.default_rng(70 + variant * 2 + side)
        # powietrze: różowawy szum w dwóch pasmach, przenikających się powoli - barwa "płynie"
        low = shaped_noise(n, r, lambda f: np.exp(-((np.log(np.maximum(f, 20) / 450.0)) ** 2) / 0.5))
        mid = shaped_noise(n, r, lambda f: np.exp(-((np.log(np.maximum(f, 20) / 1100.0)) ** 2) / 0.5))
        drift = 0.5 + 0.5 * shaped_noise(n, r, lambda f: ((f > 0.1) & (f < 0.6)) * 1.0)
        air = low * (1 - drift * 0.6) + mid * drift * 0.6
        # liście: gładki szum 1,5-4,5 kHz, delikatnie trzepoczący, słyszalny przy silniejszym wietrze
        leaves = shaped_noise(n, r, lambda f: np.exp(-((np.log(np.maximum(f, 20) / 2600.0)) ** 2) / 0.35))
        flutter = 0.7 + 0.3 * shaped_noise(n, r, lambda f: ((f > 3.0) & (f < 9.0)) * 1.0)
        ch = air * env * 0.55 + leaves * flutter * env ** 2.2 * 0.32
        ch *= (1 - pan) if side == 0 else pan
        channels.append(ch)
    stereo = np.stack(channels, axis=1)
    # bez syczenia: łagodnie przycięte wysokie tony
    sos = signal.butter(2, 5500, "low", fs=RATE, output="sos")
    stereo = signal.sosfilt(sos, stereo, axis=0)
    fade = int(RATE * 0.08)
    stereo[:fade] *= np.linspace(0, 1, fade)[:, None]
    stereo[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return stereo


# ---------------------------------------------------------------- ptaki
def tone(freq_curve, amp_curve, harmonics=((1, 1.0), (2, 0.12))):
    """Ton o zmiennej wysokości (tablica Hz) i obwiedni."""
    phase = 2 * np.pi * np.cumsum(freq_curve) / RATE
    out = np.zeros_like(phase)
    for k, a in harmonics:
        out += np.sin(phase * k) * a
    return out * amp_curve


def note(f0, f1, dur, attack=0.004, release=0.02, vib=0.0, vib_rate=0.0, harmonics=((1, 1.0), (2, 0.12))):
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    f = np.geomspace(f0, f1, n) if f0 > 0 and f1 > 0 else np.full(n, f0)
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * vib_rate * t))
    env = np.minimum(t / attack, 1.0) * np.minimum((dur - t) / release, 1.0)
    return tone(f, np.clip(env, 0, 1), harmonics)


def sequence(parts, gap_fn):
    out = []
    for part in parts:
        out.append(part)
        out.append(np.zeros(int(RATE * gap_fn())))
    return np.concatenate(out)


def forest_space(x, seed, distance=0.3, reverb=0.7):
    """Odległość i las: przytłumienie wysokich tonów i pogłos (nad jeziorem dłuższy)."""
    sos = signal.butter(2, 9000 - 5000 * distance, "low", fs=RATE, output="sos")
    x = signal.sosfilt(sos, np.concatenate([x, np.zeros(int(RATE * (reverb + 0.1)))]))
    rng = np.random.default_rng(seed)
    ir_n = int(RATE * reverb)
    ir = rng.standard_normal(ir_n) * np.exp(-np.arange(ir_n) / RATE * 5.0 / reverb)
    ir /= np.sqrt((ir ** 2).sum())
    wet = signal.fftconvolve(x, ir)[:len(x)]
    out = x * (1 - 0.3 - 0.3 * distance) + wet * (0.3 + 0.3 * distance)
    fade = int(RATE * 0.05)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


def birds():
    rng = np.random.default_rng(17)
    calls = {}

    # wróbel - kilka szybkich ćwierknięć
    calls["bird_sparrow"] = sequence(
        [note(rng.uniform(4200, 5000), rng.uniform(3200, 3800), rng.uniform(0.05, 0.08), vib=0.04, vib_rate=60)
         for _ in range(rng.integers(4, 7))], lambda: rng.uniform(0.06, 0.14))

    # zięba - przyspieszający tryl zakończony zawijasem
    parts = []
    for i in range(14):
        d = 0.045 - i * 0.0015
        parts.append(note(5200 - i * 60, 4300 - i * 40, d))
    parts.append(note(3000, 5200, 0.18, vib=0.02, vib_rate=30))
    calls["bird_finch"] = sequence(parts, lambda: 0.018)

    # kos - melodyjne, fletowe frazy z glissandami
    phrase = []
    for f0, f1, d in ((1900, 2400, 0.22), (2400, 2100, 0.16), (2600, 3100, 0.12), (3100, 2200, 0.3)):
        phrase.append(note(f0, f1, d, attack=0.02, release=0.06, vib=0.01, vib_rate=7,
                           harmonics=((1, 1.0), (2, 0.25), (3, 0.06))))
    calls["bird_blackbird"] = sequence(phrase, lambda: rng.uniform(0.03, 0.08))

    # sikora - "ci-ta ci-ta ci-ta"
    parts = []
    for i in range(3):
        parts.append(note(6200, 6000, 0.07))
        parts.append(note(4400, 4300, 0.1))
    calls["bird_tit"] = sequence(parts, lambda: 0.05)

    # kukułka - daleko, miękkie "ku-ku" dwa razy
    cuckoo = []
    for _ in range(2):
        cuckoo.append(note(720, 700, 0.22, attack=0.03, release=0.08, harmonics=((1, 1.0), (2, 0.08))))
        cuckoo.append(np.zeros(int(RATE * 0.08)))
        cuckoo.append(note(590, 570, 0.34, attack=0.03, release=0.12, harmonics=((1, 1.0), (2, 0.08))))
        cuckoo.append(np.zeros(int(RATE * 0.55)))
    calls["bird_cuckoo"] = np.concatenate(cuckoo)

    # dzięcioł - szybkie bębnienie w pień
    knocks = []
    for i in range(18):
        n = int(RATE * 0.03)
        t = np.arange(n) / RATE
        k = (np.sin(2 * np.pi * 900 * t) * 0.6 + rng.standard_normal(n) * 0.4) * np.exp(-t * 180)
        knocks.append(k * (1 - i / 30))
        knocks.append(np.zeros(int(RATE * 0.032)))
    calls["bird_woodpecker"] = np.concatenate(knocks)

    # gołąb grzywacz - niskie, gruchające "hu-huu-hu"
    coo = []
    for f, d in ((420, 0.25), (440, 0.45), (410, 0.25)):
        coo.append(note(f, f * 0.92, d, attack=0.05, release=0.1, vib=0.015, vib_rate=12,
                        harmonics=((1, 1.0), (2, 0.3), (3, 0.1))))
        coo.append(np.zeros(int(RATE * 0.12)))
    calls["bird_dove"] = np.concatenate(coo)

    # gawia - żałosne zawodzenie niesione nad jeziorem i tremolo "śmiech"
    wail = []
    harm = ((1, 1.0), (2, 0.35), (3, 0.12))
    wail.append(note(560, 880, 0.7, attack=0.12, release=0.05, vib=0.004, vib_rate=5, harmonics=harm))
    wail.append(note(880, 900, 1.1, attack=0.01, release=0.08, vib=0.008, vib_rate=5, harmonics=harm))
    wail.append(note(1080, 1120, 1.2, attack=0.04, release=0.1, vib=0.01, vib_rate=5.5, harmonics=harm))
    wail.append(note(1120, 860, 0.9, attack=0.01, release=0.5, vib=0.008, vib_rate=5, harmonics=harm))
    calls["bird_loon"] = np.concatenate(wail)
    n = int(RATE * 2.2)
    t = np.arange(n) / RATE
    f = 980 + 130 * np.sign(np.sin(2 * np.pi * 8.5 * t)) * 0.5 + 60 * np.sin(2 * np.pi * 8.5 * t)
    amp = (0.55 + 0.45 * np.abs(np.sin(2 * np.pi * 8.5 * t))) * np.minimum(t / 0.1, 1) * np.minimum((2.2 - t) / 0.4, 1)
    calls["bird_loon_laugh"] = tone(f, amp, harm)

    distances = {"bird_cuckoo": 0.8, "bird_dove": 0.6, "bird_woodpecker": 0.7, "bird_loon": 0.85, "bird_loon_laugh": 0.85}
    reverbs = {"bird_loon": 2.2, "bird_loon_laugh": 2.0}
    for i, (name, call) in enumerate(calls.items()):
        save(forest_space(call, i, distances.get(name, 0.3), reverbs.get(name, 0.7)), name, peak=0.8)


# ---------------------------------------------------------------- rozlewiska: rzeka i żaby
def bubble(f0, dur, rng):
    """Bąbelek wody: krótki ton, którego wysokość rośnie, gasnący szybko."""
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    f = f0 * (1 + 2.5 * t / dur)
    return np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t * (6.0 / dur))


def river(seconds=12.0):
    """Szemrzący nurt: setki bąbelków na tle cichego szumu płynącej wody (pętla bez szwu)."""
    rng = np.random.default_rng(61)
    n = int(RATE * seconds)
    channels = []
    for side in range(2):
        x = shaped_noise(n, rng, lambda f: np.exp(-((np.log(np.maximum(f, 20) / 900.0)) ** 2) / 0.8)) * 0.18
        count = int(seconds * 45)
        for _ in range(count):
            b = bubble(rng.uniform(350, 1400), rng.uniform(0.015, 0.05), rng) * rng.uniform(0.05, 0.25)
            start = rng.integers(0, n)
            end = start + len(b)
            if end <= n:
                x[start:end] += b
            else:  # bąbelek na końcu pętli kończy się na jej początku
                x[start:] += b[:n - start]
                x[:end - n] += b[n - start:]
        channels.append(x)
    return np.stack(channels, axis=1)


def frogs():
    rng = np.random.default_rng(71)
    # żaba trawna: kilka chrapliwych "rech" - niski, szorstki ton pulsujący jak warkot
    parts = []
    for _ in range(rng.integers(3, 6)):
        dur = rng.uniform(0.1, 0.16)
        n = int(RATE * dur)
        t = np.arange(n) / RATE
        f = rng.uniform(170, 210) * (1 + 0.1 * t / dur)
        rough = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 34 * t))
        croak = tone(f, rough * np.minimum(t / 0.01, 1) * np.minimum((dur - t) / 0.03, 1),
                     ((1, 1.0), (2, 0.7), (3, 0.5), (4, 0.3), (5, 0.2)))
        parts.append(croak)
        parts.append(np.zeros(int(RATE * rng.uniform(0.08, 0.15))))
    save(forest_space(np.concatenate(parts), 80, 0.4, 0.9), "frog_croak", peak=0.75)
    # rzekotka: szybkie, wysokie "kre-kre-kre"
    parts = []
    for _ in range(rng.integers(6, 10)):
        dur = 0.05
        n = int(RATE * dur)
        t = np.arange(n) / RATE
        pulses = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 120 * t))
        parts.append(tone(np.full(n, 1900.0), pulses * np.sin(np.pi * t / dur), ((1, 1.0), (2, 0.3))))
        parts.append(np.zeros(int(RATE * 0.07)))
    save(forest_space(np.concatenate(parts), 81, 0.5, 0.9), "frog_tree", peak=0.6)


# ---------------------------------------------------------------- głosy zwierząt
def voiced(f_curve, amp, roughness, formants, rng, noise=0.0):
    """Głos zwierzęcia: ton krtaniowy (piła z drżeniem) przepuszczony przez formanty pyska."""
    n = len(f_curve)
    jitter = 1 + 0.02 * shaped_noise(n, rng, lambda f: ((f > 5) & (f < 40)) * 1.0)
    phase = np.cumsum(f_curve * jitter) / RATE
    saw = 2 * (phase % 1.0) - 1
    rough = 1 + roughness * shaped_noise(n, rng, lambda f: ((f > 20) & (f < 90)) * 1.0)
    src = saw * rough + rng.standard_normal(n) * noise
    out = np.zeros(n)
    for fc, bw, g in formants:
        sos = signal.butter(2, [max(30, fc - bw / 2), fc + bw / 2], "band", fs=RATE, output="sos")
        out += signal.sosfilt(sos, src) * g
    return out * amp


def env_curve(n, attack, release):
    t = np.arange(n) / RATE
    dur = n / RATE
    return np.clip(np.minimum(t / attack, 1) * np.minimum((dur - t) / release, 1), 0, 1)


def animal_voices():
    rng = np.random.default_rng(91)
    # ryk jelenia (rykowisko): narastający, chrapliwy bek, z oddali - 2 warianty
    for v in range(2):
        parts = []
        for k in range(2 + v):
            dur = rng.uniform(1.0, 1.6)
            n = int(RATE * dur)
            t = np.arange(n) / RATE
            f = 95 + 70 * np.sin(np.pi * t / dur) ** 0.7 + rng.uniform(-8, 8)
            roar = voiced(f, env_curve(n, 0.25, 0.4), 0.6, [(300, 250, 1.0), (750, 400, 0.6), (1400, 600, 0.25)], rng, 0.15)
            parts += [roar, np.zeros(int(RATE * rng.uniform(0.4, 0.8)))]
        save(forest_space(np.concatenate(parts), 110 + v, 0.85, 1.6), "deer_roar_%d" % (v + 1), peak=0.75)
    # jeleń z bliska: krótkie pochrząkiwanie
    n = int(RATE * 0.5)
    t = np.arange(n) / RATE
    save(forest_space(voiced(85 + 20 * np.exp(-t * 5), env_curve(n, 0.03, 0.2), 0.5, [(350, 300, 1.0), (900, 500, 0.4)], rng, 0.2),
                      112, 0.2, 0.4), "deer_grunt", peak=0.7)
    # sarna: ostre, chrapliwe "bö" - szczekanie
    parts = []
    for k in range(3):
        n = int(RATE * 0.22)
        t = np.arange(n) / RATE
        parts += [voiced(420 - 120 * t / 0.22, env_curve(n, 0.01, 0.12), 0.8, [(900, 700, 1.0), (2200, 900, 0.5)], rng, 0.5),
                  np.zeros(int(RATE * 0.35))]
    save(forest_space(np.concatenate(parts), 113, 0.3, 0.6), "roe_bark", peak=0.75)
    # dzik: chrząkanie (2 warianty) i kwik przy ucieczce
    for v in range(2):
        parts = []
        for k in range(rng.integers(2, 5)):
            n = int(RATE * rng.uniform(0.1, 0.18))
            t = np.arange(n) / RATE
            parts += [voiced(np.full(n, rng.uniform(70, 95)), env_curve(n, 0.01, 0.05), 1.2, [(250, 200, 1.0), (600, 300, 0.5)], rng, 0.35),
                      np.zeros(int(RATE * rng.uniform(0.06, 0.15)))]
        save(forest_space(np.concatenate(parts), 114 + v, 0.2, 0.4), "boar_grunt_%d" % (v + 1), peak=0.7)
    n = int(RATE * 0.6)
    t = np.arange(n) / RATE
    save(forest_space(voiced(700 + 300 * np.sin(np.pi * t / 0.6), env_curve(n, 0.02, 0.2), 0.7, [(1500, 900, 1.0), (3000, 1200, 0.5)], rng, 0.2),
                      116, 0.3, 0.4), "boar_squeal", peak=0.7)
    # kaczka: nosowe "kwa" (2 warianty)
    for v in range(2):
        parts = []
        for k in range(2 + v):
            n = int(RATE * 0.16)
            t = np.arange(n) / RATE
            parts += [voiced(np.full(n, rng.uniform(270, 320)) * (1 - 0.15 * t / 0.16), env_curve(n, 0.01, 0.06), 0.4,
                             [(1100, 500, 1.0), (2300, 700, 0.6), (3400, 800, 0.2)], rng, 0.1),
                      np.zeros(int(RATE * rng.uniform(0.1, 0.2)))]
        save(forest_space(np.concatenate(parts), 117 + v, 0.3, 0.6), "duck_quack_%d" % (v + 1), peak=0.75)
    # łopot skrzydeł zrywających się ptaków
    n = int(RATE * 0.9)
    t = np.arange(n) / RATE
    beat = np.maximum(0, np.sin(2 * np.pi * 9 * t)) ** 3
    flap = signal.sosfilt(signal.butter(2, [250, 2500], "band", fs=RATE, output="sos"), rng.standard_normal(n)) * beat
    save(forest_space(flap * np.exp(-t * 2.2), 119, 0.2, 0.3), "wing_flap", peak=0.6)
    # klangor żurawia: donośne, trąbiące "kruu-kruu"
    parts = []
    for k in range(3):
        n = int(RATE * 0.45)
        t = np.arange(n) / RATE
        f = 520 + 90 * np.sin(np.pi * t / 0.45) + 25 * np.sin(2 * np.pi * 28 * t)
        parts += [voiced(f, env_curve(n, 0.03, 0.12), 0.25, [(800, 400, 1.0), (1600, 600, 0.7), (2600, 800, 0.3)], rng, 0.05),
                  np.zeros(int(RATE * 0.12))]
    save(forest_space(np.concatenate(parts), 120, 0.6, 1.5), "crane_call", peak=0.75)
    # ważka: krótkie, suche brzęczenie skrzydeł
    n = int(RATE * 0.7)
    t = np.arange(n) / RATE
    buzz = signal.sosfilt(signal.butter(2, [600, 3000], "band", fs=RATE, output="sos"), rng.standard_normal(n))
    buzz *= (0.6 + 0.4 * np.sin(2 * np.pi * 32 * t)) * env_curve(n, 0.1, 0.3)
    save(buzz, "dragonfly", peak=0.5)


def main():
    os.makedirs(OUT, exist_ok=True)
    for v in range(5):
        save(gust(v), "gust_%d" % (v + 1), peak=0.7)
    birds()
    save(river(), "river_loop", peak=0.6)
    frogs()
    animal_voices()


if __name__ == "__main__":
    main()
