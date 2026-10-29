"""Pozostałe utwory gry (obok tematu Ostoi z music.py): menu (świt), krainy (las, rozlewiska, góry, Prastary
Las) i walki z bossami. Te same instrumenty co temat Ostoi (harfa, smyczki, flet, bas) plus bęben ramowy,
burdon, dzwoneczki i ostre smyczki w walce. Każdy utwór: tonacja (skala i akordy po 2 takty), tempo i warstwy;
dwa przejścia progresji (A i B - w B gęściej), pętla bez szwu.
Zapisuje assets/music/<utwór>.ogg. Uruchom: python tools/music_tracks.py [utwór ...] (albo music.py)"""
import os
import random
import sys

import numpy as np

from music import OUT, RATE, add, flute, freq, pad, pluck, reverb, save, _leveling

# półtony względem A4 dla nazw spoza tematu Ostoi
EXTRA = {"Db": -8, "D#": -6, "Eb": -6, "F#": -3, "Gb": -3, "G#": -1, "Ab": -1, "A#": 1, "B#": 3}


def note(name, octave):
    """octave: 4 = oktawa A4 (440 Hz)."""
    if name in EXTRA:
        return 440.0 * 2 ** ((EXTRA[name] + 12 * (octave - 4)) / 12)
    return freq(name, octave)


def drum(kind, vel, rng):
    """Bęben ramowy / kocioł: "low" - głęboki, "mid" - tom, "hit" - krótki klik ręką o skórę."""
    dur = {"low": 0.9, "mid": 0.5, "hit": 0.18}[kind]
    t = np.arange(int(RATE * dur)) / RATE
    f0 = {"low": 62.0, "mid": 120.0, "hit": 260.0}[kind]
    f = f0 * (1 + 1.2 * np.exp(-t * 30))  # opadający ton uderzenia
    body = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t * {"low": 5.0, "mid": 9.0, "hit": 30.0}[kind])
    noise = rng.standard_normal(len(t)) * np.exp(-t * 60) * (0.5 if kind == "hit" else 0.25)
    return (body + noise) * vel


def drone(f, dur, vel):
    """Burdon (jak u liry korbowej): podstawa, kwinta i oktawa, powolne falowanie."""
    t = np.arange(int(RATE * dur)) / RATE
    out = np.zeros_like(t)
    for ratio, amp in ((1.0, 1.0), (1.5, 0.5), (2.0, 0.35)):
        ph = 2 * np.pi * f * ratio * t
        out += amp * (np.sin(ph) + 0.3 * np.sin(2 * ph) + 0.12 * np.sin(3 * ph))
    swell = 0.75 + 0.25 * np.sin(2 * np.pi * t / 7.0)
    env = np.minimum(t / 2.0, 1.0) * np.clip((dur - t) / 2.0, 0, 1)
    return out * swell * env * vel / 2.0


def bell(f, vel):
    """Dzwoneczek / kalimba: krótkie, metaliczne, nieharmoniczne alikwoty."""
    t = np.arange(int(RATE * 2.5)) / RATE
    out = np.zeros_like(t)
    for ratio, amp, decay in ((1.0, 1.0, 2.2), (2.76, 0.45, 4.0), (5.4, 0.25, 7.0)):
        out += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t * decay)
    return out * np.minimum(t / 0.002, 1.0) * vel


def lead(f, dur, vel):
    """Ostre smyczki w walce: piłokształtna fala złagodzona filtrem."""
    t = np.arange(int(RATE * (dur + 0.15))) / RATE
    saw = 2 * ((f * t) % 1.0) - 1
    saw = np.convolve(saw, np.ones(6) / 6, "same")
    env = np.minimum(t / 0.03, 1.0) * np.clip((dur + 0.15 - t) / 0.15, 0, 1)
    return saw * env * vel


def _chord(root, *tones):
    return (root, list(tones))


TRACKS = {
    # świt nad Ostoją: D-dur, ciepło i z nadzieją
    "menu": {"bpm": 70, "seed": 11, "scale": ["D", "E", "F#", "G", "A", "B", "C#"],
             "progression": [_chord("D", "D", "F#", "A"), _chord("G", "G", "B", "D"), _chord("B", "B", "D", "F#"),
                             _chord("A", "A", "C#", "E"), _chord("G", "G", "B", "D"), _chord("D", "D", "F#", "A"),
                             _chord("E", "E", "G", "B"), _chord("A", "A", "C#", "E")],
             "pad": 0.17, "harp": 0.18, "flute": 0.13, "bells": 0.05, "bass": 0.28},
    # Gobliński Las: a-moll dorycki, wędrowny rytm bębna
    "forest": {"bpm": 92, "seed": 23, "scale": ["A", "B", "C", "D", "E", "F#", "G"],
               "progression": [_chord("A", "A", "C", "E"), _chord("G", "G", "B", "D"), _chord("D", "D", "F#", "A"),
                               _chord("A", "A", "C", "E"), _chord("F", "F", "A", "C"), _chord("G", "G", "B", "D"),
                               _chord("E", "E", "G", "B"), _chord("A", "A", "C", "E")],
               "pad": 0.12, "harp": 0.2, "flute": 0.12, "drums": "travel", "bass": 0.3},
    # Rozlewiska: e frygijski, powoli, burdon, niski flet i dużo pogłosu
    "swamp": {"bpm": 60, "seed": 37, "scale": ["E", "F", "G", "A", "B", "C", "D"], "reverb": 0.42,
              "progression": [_chord("E", "E", "G", "B"), _chord("F", "F", "A", "C"), _chord("E", "E", "G", "B"),
                              _chord("D", "D", "F", "A"), _chord("C", "C", "E", "G"), _chord("F", "F", "A", "C"),
                              _chord("D", "D", "F", "A"), _chord("E", "E", "G", "B")],
              "pad": 0.13, "harp": 0.12, "harp_sparse": True, "flute": 0.1, "flute_octave": 3, "drone": ("E", 0.12),
              "bass": 0.22},
    # Wietrzne Turnie: puste kwinty, wysoki flet, dzwoneczki, rzadki bęben
    "mountains": {"bpm": 66, "seed": 51, "scale": ["D", "E", "F#", "G", "A", "B", "C"],
                  "progression": [_chord("D", "D", "A", "D"), _chord("C", "C", "G", "C"), _chord("G", "G", "D", "G"),
                                  _chord("D", "D", "A", "D"), _chord("Bb", "Bb", "F", "Bb"), _chord("C", "C", "G", "C"),
                                  _chord("A", "A", "E", "A"), _chord("D", "D", "A", "D")],
                  "pad": 0.16, "harp": 0.14, "flute": 0.14, "flute_octave": 5, "bells": 0.06, "drums": "slow", "bass": 0.26},
    # Prastary Las: cis-moll, tajemniczo - burdon, dzwoneczki, rzadka harfa
    "ancient": {"bpm": 56, "seed": 73, "scale": ["C#", "D#", "E", "F#", "G#", "A", "B"], "reverb": 0.4,
                "progression": [_chord("C#", "C#", "E", "G#"), _chord("A", "A", "C#", "E"), _chord("F#", "F#", "A", "C#"),
                                _chord("G#", "G#", "B", "D#"), _chord("C#", "C#", "E", "G#"), _chord("E", "E", "G#", "B"),
                                _chord("A", "A", "C#", "E"), _chord("G#", "G#", "B#", "D#")],
                "pad": 0.15, "harp": 0.1, "harp_sparse": True, "bells": 0.09, "drone": ("C#", 0.13), "bass": 0.2},
    # walka z bossem: d-moll, szybko - bębny, ostinato basu, ostre smyczki
    "boss": {"bpm": 128, "seed": 97, "scale": ["D", "E", "F", "G", "A", "Bb", "C"], "reverb": 0.2,
             "progression": [_chord("D", "D", "F", "A"), _chord("D", "D", "F", "A"), _chord("Bb", "Bb", "D", "F"),
                             _chord("C", "C", "E", "G"), _chord("D", "D", "F", "A"), _chord("G", "G", "Bb", "D"),
                             _chord("Bb", "Bb", "D", "F"), _chord("A", "A", "C#", "E")],
             "pad": 0.12, "ostinato": 0.24, "lead": 0.09, "drums": "battle", "bass": 0.3},
}


def compose_track(spec):
    rng = random.Random(spec["seed"])
    nrng = np.random.default_rng(spec["seed"])
    beat = 60.0 / spec["bpm"]
    bar_len = beat * 4
    prog = spec["progression"]
    scale = spec["scale"]
    bars = len(prog) * 2 * 2
    length = bars * bar_len
    left = np.zeros(int(RATE * (length + 6.0)))
    right = np.zeros_like(left)

    def put(sig, start, pan=0.5):
        add(left, sig * (1.2 - pan * 0.4) * 0.6, start)
        add(right, sig * (0.8 + pan * 0.4) * 0.6, start)

    if "drone" in spec:
        name, vel = spec["drone"]
        put(drone(note(name, 2), length + 4.0, vel), 0.0)
    prev = 4
    for bar in range(bars):
        root, tones = prog[(bar // 2) % len(prog)]
        t0 = bar * bar_len
        section_b = bar >= bars // 2
        if bar % 2 == 0 and spec.get("pad"):
            voices = [note(tones[0], 3), note(tones[1], 3), note(tones[2], 3), note(tones[0], 4)]
            put(pad(voices, bar_len * 2, spec["pad"]), t0)
        if spec.get("ostinato"):
            for i in range(8):
                f = note(root, 2) * (1.5 if i % 4 == 3 else 1.0)
                put(pluck(f, beat * 0.6, spec["ostinato"] * (1.0 if i % 2 == 0 else 0.75)), t0 + i * beat / 2)
        elif spec.get("bass"):
            for b in (0, 2):
                put(pluck(note(root, 2), beat * 2.2, spec["bass"]), t0 + b * beat)
        if spec.get("harp"):
            arp = [note(tones[0], 3), note(tones[1], 3), note(tones[2], 3), note(tones[0], 4), note(tones[1], 4)]
            pattern = [0, 1, 2, 3, 2, 1, 2, 3] if not section_b else [0, 2, 3, 4, 3, 2, 3, 1]
            for i, k in enumerate(pattern):
                if spec.get("harp_sparse") and i % 2 == 1:
                    continue
                vel = spec["harp"] * (1.0 if i % 2 == 0 else 0.7) * rng.uniform(0.85, 1.05)
                put(pluck(arp[k], 1.8, vel), t0 + i * beat / 2 + rng.uniform(-0.006, 0.006), 0.3 + 0.4 * k / 4)
        if spec.get("bells") and rng.random() < 0.6:
            for _k in range(rng.choice([1, 2])):
                put(bell(note(rng.choice(tones), 5), spec["bells"]), t0 + rng.choice([0, 1, 1.5, 2, 2.5, 3]) * beat,
                    rng.uniform(0.2, 0.8))
        drums = spec.get("drums")
        if drums == "travel":
            for b, kind, vel in ((0, "low", 0.5), (1.5, "hit", 0.2), (2, "mid", 0.3), (3, "hit", 0.18), (3.5, "hit", 0.14)):
                put(drum(kind, vel, nrng), t0 + b * beat)
        elif drums == "slow" and bar % 2 == 0:
            put(drum("low", 0.45, nrng), t0)
            put(drum("mid", 0.22, nrng), t0 + 2.5 * beat)
        elif drums == "battle":
            for b in range(4):
                put(drum("low", 0.6, nrng), t0 + b * beat)
                put(drum("hit", 0.25, nrng), t0 + (b + 0.5) * beat)
            if bar % 2 == 1:
                for k in range(4):
                    put(drum("mid", 0.35 + 0.08 * k, nrng), t0 + 3 * beat + k * beat / 4)
        melody = spec.get("flute") or spec.get("lead")
        if not melody or bar < 4 or (bar % 8 == 7 and not section_b):
            continue
        busy = section_b or spec.get("lead")
        rhythm = rng.choice([[2, 2], [3, 1], [1, 1, 2], [2, 1, 1]] if busy else [[4], [2, 2], [3, 1], [2, 2]])
        pos = 0.0
        octave = spec.get("flute_octave", 4)
        for j, beats in enumerate(rhythm):
            if j == 0:  # mocna część taktu - składnik akordu najbliżej poprzedniej nuty
                candidates = [scale.index(n) for n in tones if n in scale]
                target = min(candidates, key=lambda c: abs(c - prev % 7)) if candidates else prev % 7
                idx = (prev // 7) * 7 + target
            else:  # krok po skali
                idx = prev + rng.choice([-2, -1, -1, 1, 1, 2])
            idx = max(2, min(12, idx))
            f = note(scale[idx % 7], octave + idx // 7 - 1)
            sig = lead(f, beats * beat * 0.9, melody) if spec.get("lead") else flute(f, beats * beat * 0.95, melody, nrng)
            put(sig, t0 + pos * beat, 0.45)
            prev = idx
            pos += beats

    out = []
    for ch in (left, right):
        ch = reverb(ch, mix=spec.get("reverb", 0.28))
        n = int(RATE * length)
        ch[:len(ch) - n] += ch[n:]  # to, co wybrzmiewa po końcu, nakłada się na początek pętli
        out.append(ch[:n])
    stereo = np.stack(out, axis=1)
    stereo *= _leveling(stereo)[:, None]
    stereo *= 0.8 / np.abs(stereo).max()
    return stereo


def main(names=None):
    os.makedirs(OUT, exist_ok=True)
    for name, spec in TRACKS.items():
        if not names or name in names:
            save(compose_track(spec), name)


if __name__ == "__main__":
    main(sys.argv[1:])
