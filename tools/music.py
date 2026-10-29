"""Muzyka w tle: spokojna pętla dla Ostoi (ok. 100 s), skomponowana i zsyntezowana w numpy.
Harfa/lutnia gra arpeggia, pod spodem miękkie smyczki i bas, a flet prowadzi melodię.
Zapisuje assets/music/ostoja_theme.ogg (wymaga ffmpeg w PATH); pozostałe utwory - tools/music_tracks.py.

Uruchom: python tools/music.py"""
import os
import random
import subprocess

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "music")
RATE = 44100
BPM = 76
BEAT = 60.0 / BPM
BAR = BEAT * 4

# d-moll z nutą h (dorycko) i akordem A-dur jako dominantą; nuty w półtonach względem A4 = 0
NOTE = {"C": -9, "C#": -8, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "Bb": 1, "B": 2}
CHORDS = {  # podstawa i składniki akordu
    "Dm": ("D", ["D", "F", "A"]),
    "Bb": ("Bb", ["Bb", "D", "F"]),
    "F": ("F", ["F", "A", "C"]),
    "C": ("C", ["C", "E", "G"]),
    "Gm": ("G", ["G", "Bb", "D"]),
    "A": ("A", ["A", "C#", "E"]),
}
PROGRESSION = ["Dm", "Bb", "F", "C", "Dm", "Gm", "Bb", "A"]  # po 2 takty na akord
SCALE = ["D", "E", "F", "G", "A", "Bb", "C"]


def freq(name, octave):
    """octave: 4 = oktawa A4 (440 Hz)."""
    return 440.0 * 2 ** ((NOTE[name] + 12 * (octave - 4)) / 12)


def pluck(f, dur, vel):
    """Harfa / lutnia: harmoniczne gasnące tym szybciej, im są wyższe."""
    t = np.arange(int(RATE * dur)) / RATE
    out = np.zeros_like(t)
    for k in range(1, 9):
        fk = f * k * (1 + 0.0004 * k * k)  # lekka nieharmoniczność struny
        if fk > RATE / 2.2:
            break
        out += np.sin(2 * np.pi * fk * t) * np.exp(-t * (1.2 + 0.9 * k)) / k ** 1.3
    attack = np.minimum(t / 0.004, 1.0)
    return out * attack * vel


def flute(f, dur, vel, rng):
    t = np.arange(int(RATE * (dur + 0.35))) / RATE
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(t / 0.4, 1.0)
    phase = 2 * np.pi * np.cumsum(f * vib) / RATE
    tone = np.sin(phase) + 0.28 * np.sin(2 * phase) + 0.08 * np.sin(3 * phase)
    breath = np.convolve(rng.standard_normal(len(t)), np.ones(30) / 30, "same") * 0.05
    env = np.minimum(t / 0.09, 1.0) * np.clip((dur + 0.35 - t) / 0.35, 0, 1)
    return (tone + breath) * env * vel


def pad(freqs, dur, vel):
    t = np.arange(int(RATE * (dur + 1.6))) / RATE
    out = np.zeros_like(t)
    for f in freqs:
        for detune in (-0.0025, 0.0, 0.0025):
            ph = 2 * np.pi * f * (1 + detune) * t
            out += np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.1 * np.sin(3 * ph)
    env = np.minimum(t / 1.1, 1.0) * np.clip((dur + 1.6 - t) / 1.6, 0, 1)
    return out * env * vel / (len(freqs) * 3)


def add(buf, sig, start):
    i = max(0, int(start * RATE))
    n = min(len(sig), len(buf) - i)
    buf[i:i + n] += sig[:n]


def reverb(x, seconds=2.6, mix=0.28, seed=1):
    """Pogłos: splot z gasnącym szumem (jak sala karczmy... albo pusty las)."""
    rng = np.random.default_rng(seed)
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    ir = rng.standard_normal(n) * np.exp(-t * 3.2)
    ir = np.convolve(ir, np.ones(8) / 8, "same")  # ciemniejszy pogłos
    ir /= np.sqrt((ir ** 2).sum())
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:len(x)]
    return x * (1 - mix) + wet * mix * 1.6


def _leveling(stereo, window=3.0):
    """Łagodne wyrównanie głośności (spokojna muzyka nie powinna nagle skakać).
    Obwiednia liczona w kółko, żeby wzmocnienie na końcu pasowało do początku pętli."""
    power = (stereo ** 2).mean(axis=1)
    hop = 1024
    frames = power[:len(power) // hop * hop].reshape(-1, hop).mean(axis=1)
    k = int(window * RATE / hop)
    padded = np.concatenate([frames[-k:], frames, frames[:k]])
    smooth = np.convolve(padded, np.ones(2 * k + 1) / (2 * k + 1), "same")[k:-k]
    rms = np.sqrt(smooth)
    gain = np.clip((np.median(rms) / np.maximum(rms, 1e-6)) ** 0.7, 0.5, 1.6)
    x = np.arange(len(power)) / hop
    return np.interp(x, np.arange(len(gain)), gain, period=len(gain))


def compose():
    rng = random.Random(1945)
    nrng = np.random.default_rng(7)
    bars = len(PROGRESSION) * 2 * 2  # dwa przejścia progresji (A i B)
    length = bars * BAR
    tail = 6.0
    left = np.zeros(int(RATE * (length + tail)))
    right = np.zeros_like(left)

    prev_note = 4  # indeks w skali (A)
    for bar in range(bars):
        chord = CHORDS[PROGRESSION[(bar // 2) % len(PROGRESSION)]]
        root, tones = chord
        t0 = bar * BAR
        section_b = bar >= bars // 2

        # smyczki - co dwa takty nowy akord
        if bar % 2 == 0:
            voices = [freq(tones[0], 3), freq(tones[1], 3), freq(tones[2], 3), freq(tones[0], 4)]
            s = pad(voices, BAR * 2, 0.16)
            add(left, s * 0.9, t0)
            add(right, s, t0)

        # bas - podstawa na raz i trzy
        for beat in (0, 2):
            b = pluck(freq(root, 2), BEAT * 2.2, 0.32)
            add(left, b, t0 + beat * BEAT)
            add(right, b, t0 + beat * BEAT)

        # harfa - arpeggio ósemkami (w części B gęściej i wyżej)
        pattern = [0, 1, 2, 3, 2, 1, 2, 3] if not section_b else [0, 2, 3, 4, 3, 2, 3, 1]
        arp = [freq(tones[0], 3), freq(tones[1], 3), freq(tones[2], 3), freq(tones[0], 4), freq(tones[1], 4)]
        for i, k in enumerate(pattern):
            vel = 0.2 if i % 2 == 0 else 0.14
            h = pluck(arp[k], 1.8, vel * rng.uniform(0.85, 1.05))
            pan = 0.35 + 0.3 * (k / 4)
            start = t0 + i * BEAT / 2 + rng.uniform(-0.006, 0.006)
            add(left, h * (1 - pan), start)
            add(right, h * pan, start)

        # flet - melodia od piątego taktu, w części B bardziej ruchliwa
        if bar < 4 or (bar % 8 == 7 and not section_b):
            continue
        rhythm = rng.choice([[2, 2], [3, 1], [1, 1, 2], [2, 1, 1]] if section_b else [[4], [2, 2], [3, 1], [2, 2]])
        pos = 0.0
        for j, beats in enumerate(rhythm):
            if j == 0:  # mocna część taktu - składnik akordu najbliżej poprzedniej nuty
                candidates = [SCALE.index(n) for n in tones if n in SCALE]
                target = min(candidates, key=lambda c: abs(c - prev_note % 7))
                idx = (prev_note // 7) * 7 + target
            else:  # krok po skali
                idx = prev_note + rng.choice([-2, -1, -1, 1, 1, 2])
            idx = max(2, min(12, idx))
            name = SCALE[idx % 7]
            if name not in NOTE:
                name = "A"
            if tones[0] == "A" and name == "C":
                name = "C#"  # nad dominantą wznosząca się nuta prowadząca
            octave = 4 + idx // 7
            fl = flute(freq(name, octave), beats * BEAT * 0.95, 0.13, nrng)
            add(left, fl * 0.55, t0 + pos * BEAT)
            add(right, fl * 0.45, t0 + pos * BEAT)
            prev_note = idx
            pos += beats

    # pętla bez szwu: to, co wybrzmiewa po końcu, nakłada się na początek
    out = []
    for ch in (left, right):
        ch = reverb(ch)
        n = int(RATE * length)
        ch[:len(ch) - n] += ch[n:]
        out.append(ch[:n])
    stereo = np.stack(out, axis=1)
    stereo *= _leveling(stereo)[:, None]
    stereo *= 0.8 / np.abs(stereo).max()
    return stereo


def save(audio, name):
    """Zapis stereo [-1, 1] do assets/music/<name>.ogg przez ffmpeg."""
    pcm = (audio * 32767).astype("<i2").tobytes()
    path = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", str(RATE), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "4", path], input=pcm, check=True)
    print("Zapisano", path, "%.1f s" % (len(audio) / RATE))


def main():
    os.makedirs(OUT, exist_ok=True)
    save(compose(), "ostoja_theme")
    import music_tracks  # menu, krainy i walki z bossami
    music_tracks.main()


if __name__ == "__main__":
    main()
