"""Dźwięki trafień potworów składane z nagrań CC0 (sfx_src/hits, źródła w sfx_src/hits/ZRODLA.md):
- hit_blade_* - cięcie mieczem w ciało: mięsiste plaśnięcie, krótki metaliczny styk ostrza i niskie tąpnięcie,
- hit_arrow_* - strzała wbijająca się w ciało: suche stuknięcie grotu, plaśnięcie i drgnięcie drzewca,
- hit_fire_* / hit_ice_* / hit_lightning_* - trafienie czarem (ogień, lód, piorun) z głuchym uderzeniem pod spodem,
- hit_magic_* - magiczny pocisk księgi (rozprysk mocy i lekkie uderzenie),
- hit_crit_* - cios krytyczny: warstwa dokładana na zwykłe trafienie (ciężkie łupnięcie, chrupnięcie, dudnienie),
- kill_* - dobicie potwora (podwójne mokre plaśnięcie i trzask kości).
Z każdego nagrania czaru brany jest tylko początek właściwego uderzenia (szukany po skoku głośności),
bo trafienia grają setki razy w walce i muszą być krótkie.
Wymaga numpy i scipy.
Zapisuje do assets/sfx (wymaga ffmpeg w PATH).

Uruchom: python tools/hit_sfx.py [przedrostek ...]  (np. hit_blade; bez nazw - wszystkie)"""
import os
import subprocess
import sys

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "sfx_src", "hits")
OUT = os.path.join(ROOT, "assets", "sfx")
RATE = 44100
_cache = {}


def load(name):
    """Nagranie z sfx_src/hits jako mono 44,1 kHz (ffmpeg przelicza częstotliwość)."""
    if name not in _cache:
        raw = subprocess.run(["ffmpeg", "-v", "error", "-i", os.path.join(SRC, name + ".flac"), "-ac", "1",
                              "-ar", str(RATE), "-f", "f32le", "-"], capture_output=True, check=True).stdout
        x = np.frombuffer(raw, np.float32).astype(float)
        _cache[name] = x / (np.abs(x).max() + 1e-9)
    return _cache[name]


def onset(x, drop_db=10.0):
    """Początek głównego uderzenia: pierwsze okno 5 ms nie więcej niż `drop_db` ciszej od najgłośniejszego."""
    w = RATE // 200
    rms = np.sqrt(np.convolve(x ** 2, np.ones(w) / w, "valid") + 1e-12)
    first = int(np.argmax(rms >= rms.max() * 10 ** (-drop_db / 20)))
    return max(0, first - RATE // 100)


def cut(x, start, length, fade_in=0.002, fade_out=None):
    """Wycinek [start, start + length] (sekundy) z łagodnym wejściem i wybrzmieniem do zera."""
    a = int(start * RATE)
    y = x[a:a + int(length * RATE)].copy()
    y = np.pad(y, (0, int(length * RATE) - len(y)))
    n_in = int(fade_in * RATE)
    if n_in:
        y[:n_in] *= np.linspace(0, 1, n_in)
    n_out = int((fade_out if fade_out is not None else length * 0.6) * RATE)
    y[-n_out:] *= np.linspace(1, 0, n_out) ** 2
    return y


def impact(name, length, drop_db=10.0, lead=0.0):
    """Wycinek nagrania od głównego uderzenia (`lead` - ile sekund zostawić przed nim)."""
    x = load(name)
    return cut(x, max(0.0, onset(x, drop_db) / RATE - lead), length)


def pitch(x, factor):
    """Zmiana wysokości (i długości) przez przepróbkowanie - factor < 1 brzmi niżej i ciężej."""
    n = int(len(x) / factor)
    return np.interp(np.arange(n) * factor, np.arange(len(x)), x)


def hp(x, f):
    return signal.sosfilt(signal.butter(2, f, "high", fs=RATE, output="sos"), x)


def lp(x, f):
    return signal.sosfilt(signal.butter(2, f, "low", fs=RATE, output="sos"), x)


def thump(f, length, decay, drop=0.5):
    """Niskie tąpnięcie: sinus opadający z f do f*drop, gasnący wykładniczo (masa trafionego ciała)."""
    t = np.arange(int(length * RATE)) / RATE
    freq = f * (drop + (1 - drop) * np.exp(-t * 30))
    return np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t * decay) * np.minimum(1, t * 800)


def mix(length, *layers):
    """Suma warstw (dźwięk, przesunięcie w s, głośność) przycięta do `length` sekund."""
    out = np.zeros(int(length * RATE))
    for x, at, gain in layers:
        a = int(at * RATE)
        n = min(len(x), len(out) - a)
        if n > 0:
            out[a:a + n] += x[:n] * gain
    return out


def room(x, seed, seconds=0.25, mix_=0.15):
    rng = np.random.default_rng(seed)
    n = int(RATE * seconds)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / RATE * 9.0 / seconds)
    ir /= np.sqrt((ir ** 2).sum())
    return x * (1 - mix_) + signal.fftconvolve(x, ir)[:len(x)] * mix_


def blade(v):
    meat = ("qubodup_meat01", "qubodup_meat02")[v % 2]
    flesh = pitch(impact(meat, 0.4, lead=0.004), (0.92, 1.05, 0.85, 1.0)[v])
    edge = hp(impact(("medieval_metal_1", "medieval_metal_5", "qubodup_metal", "medieval_metal_1")[v], 0.12), 2500)
    return room(mix(0.38, (flesh, 0.0, 1.0), (edge, 0.0, 0.22), (thump(95, 0.25, 22), 0.0, 0.55)), v)


def arrow(v):
    tip = hp(impact(("medieval_hit", "qubodup_wood", "medieval_hit", "qubodup_wood")[v], 0.1), 900)
    flesh = lp(pitch(impact(("qubodup_meat02", "qubodup_meat01")[v % 2], 0.3), (1.15, 1.25, 1.1, 1.2)[v]), 5000)
    t = np.arange(int(0.18 * RATE)) / RATE
    quiver = np.sin(2 * np.pi * (180 + 25 * v) * t) * np.exp(-t * 28) * (1 + 0.5 * np.sin(2 * np.pi * 38 * t))
    return room(mix(0.3, (tip, 0.0, 0.8), (flesh, 0.006, 0.75), (quiver, 0.004, 0.18), (thump(120, 0.15, 30), 0.0, 0.35)),
                10 + v, 0.18, 0.1)


SPELLS = {"fire": (3, 4, 5), "ice": (2, 4, 5), "lightning": (1, 3, 4), "water": (1, 4, 2)}


def spell(element, v, length=0.6, body=0.45):
    src = impact(f"spell_{element}_{SPELLS[element][v]}", length, drop_db=6.0, lead=0.01)
    flesh = lp(impact(("qubodup_meat01", "qubodup_meat02", "qubodup_meat01")[v], 0.3), 2500)
    return mix(length, (src, 0.0, 1.0), (flesh, 0.0, body), (thump(85, 0.25, 18), 0.0, body))


def magic(v):
    return spell("water", v, 0.4, 0.55)


def crit(v):
    heavy = pitch(impact(("qubodup_meat02", "qubodup_meat01", "qubodup_meat02")[v], 0.4), (0.7, 0.75, 0.65)[v])
    crack = hp(impact(("qubodup_wood", "qubodup_stone", "qubodup_wood")[v], 0.12), 1500)
    slam = lp(impact(("medieval_hammer", "medieval_hard", "medieval_hammer")[v], 0.35), 1800)
    return room(mix(0.6, (heavy, 0.0, 1.0), (crack, 0.0, 0.45), (slam, 0.0, 0.5), (thump(60, 0.5, 9, 0.6), 0.0, 0.9)),
                20 + v, 0.4, 0.22)


def kill(v):
    a = pitch(impact(("qubodup_meat01", "qubodup_meat02", "qubodup_meat01")[v], 0.4), (0.85, 0.8, 0.9)[v])
    b = pitch(impact(("qubodup_meat02", "qubodup_meat01", "qubodup_meat02")[v], 0.4), (0.95, 1.0, 0.9)[v])
    bone = hp(pitch(impact("qubodup_wood", 0.12), (1.3, 1.15, 1.4)[v]), 2000)
    return room(mix(0.5, (a, 0.0, 1.0), (b, 0.05 + 0.015 * v, 0.7), (bone, 0.02, 0.4), (thump(70, 0.35, 12), 0.0, 0.6)),
                30 + v, 0.3, 0.15)


SETS = (
    ("hit_blade", blade, 4),
    ("hit_arrow", arrow, 4),
    ("hit_fire", lambda v: spell("fire", v), 3),
    ("hit_ice", lambda v: spell("ice", v), 3),
    ("hit_lightning", lambda v: spell("lightning", v), 3),
    ("hit_magic", magic, 3),
    ("hit_crit", crit, 3),
    ("kill", kill, 3),
)


def save(audio, name):
    audio = audio * (0.95 / np.abs(audio).max())
    pcm = (np.repeat(audio.reshape(-1, 1), 2, axis=1) * 32767).astype("<i2").tobytes()
    path = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", str(RATE), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "5", path], input=pcm, check=True)
    print("Zapisano", path, "%.2f s" % (len(audio) / RATE))


def main():
    os.makedirs(OUT, exist_ok=True)
    only = set(sys.argv[1:])
    for prefix, fn, count in SETS:
        if not only or prefix in only:
            for v in range(count):
                save(fn(v), f"{prefix}_{v + 1}")


if __name__ == "__main__":
    main()
