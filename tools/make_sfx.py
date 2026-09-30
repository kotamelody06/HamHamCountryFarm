#!/usr/bin/env python3
"""はむはむカントリーファームの効果音（SE）をすべてオリジナル合成するスクリプト。

  python3 tools/make_sfx.py      → sounds/*.wav を生成（44.1kHz / 16bit / mono）

音色の方針（企画のSEイメージより）
  農作業      … 木琴やコルクを抜くような「ぽこっ」「すっぽん」
  ハムスター  … ちいさな木琴のスケール「コロロロン♪」、柔らかい歩行音「てちてち」
  料理完成    … レトロなオーブンの「チーン！」＋色鉛筆でまるを描くような「ポロロン♪」
  メニュー    … 画用紙をめくる「サクッ」、木を優しく叩く「コッ」
数値をいじれば音色を簡単に調整できます。
"""
import os
import wave
import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
RNG = np.random.default_rng(7)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sounds")


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def note_hz(name):
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    n, o = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[n] + (o - 4) * 12 - 9) / 12)


def env(t, attack=0.002, tau=0.2):
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-np.maximum(t - attack, 0) / tau)


def band(x, lo, hi, order=2):
    sos = butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return sosfilt(sos, x)


def hp(x, f):
    return sosfilt(butter(2, f, btype="high", fs=SR, output="sos"), x)


def lp(x, f):
    return sosfilt(butter(2, f, btype="low", fs=SR, output="sos"), x)


def mix(total, parts):
    out = np.zeros(int(SR * total))
    for start, sig in parts:
        sig = np.array(sig, dtype=float)
        fl = min(len(sig), int(SR * 0.012))
        sig[-fl:] *= np.linspace(1, 0, fl) ** 2  # 切れ目のプチッを防ぐ
        s = int(SR * start)
        e = min(len(out), s + len(sig))
        out[s:e] += sig[: e - s]
    return out


def sweep(t, f0, f1, curve=0.03):
    """周波数を f0→f1 へ指数的に動かしたサイン波（位相を積分）"""
    f = f1 + (f0 - f1) * np.exp(-t / curve)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


# ── 楽器 ──────────────────────────────────────────
def marimba(f, dur=0.6, tau=0.28, bright=0.35):
    """木琴（マリンバ風）：基音＋木の鍵盤らしい非整数倍音＋マレットのコツ"""
    t = t_axis(dur)
    x = np.sin(2 * np.pi * f * t) * env(t, 0.002, tau)
    x += bright * np.sin(2 * np.pi * f * 3.93 * t) * env(t, 0.001, tau * 0.18)
    x += bright * 0.3 * np.sin(2 * np.pi * f * 9.2 * t) * env(t, 0.001, tau * 0.06)
    click = band(RNG.standard_normal(len(t)), 1500, 6000) * env(t, 0.0005, 0.004) * 0.25
    return x + click


def xylo(f, dur=0.35, tau=0.12):
    """ちいさな木琴：短く明るい"""
    return marimba(f, dur, tau, bright=0.5)


def celesta(f, dur=1.0, tau=0.45):
    """色鉛筆のような、やわらかいきらきら音"""
    t = t_axis(dur)
    x = np.sin(2 * np.pi * f * t) * env(t, 0.004, tau)
    x += 0.25 * np.sin(2 * np.pi * f * 2 * t) * env(t, 0.003, tau * 0.5)
    x += 0.08 * np.sin(2 * np.pi * f * 3 * t) * env(t, 0.002, tau * 0.25)
    return x


def woodblock(f=900, dur=0.12, tau=0.022):
    t = t_axis(dur)
    x = np.sin(2 * np.pi * f * t) * env(t, 0.0008, tau)
    x += 0.4 * np.sin(2 * np.pi * f * 2.57 * t) * env(t, 0.0005, tau * 0.5)
    x += band(RNG.standard_normal(len(t)), 800, 4000) * env(t, 0.0004, 0.003) * 0.35
    return x


# ── 効果音 ────────────────────────────────────────
def sfx_water():
    """ぽこっ：水が土にしみる、木の泡のようなポップ2つ"""
    def pop(f0, f1, dur, tau):
        t = t_axis(dur)
        return sweep(t, f0, f1, 0.018) * env(t, 0.001, tau)
    return mix(0.3, [(0.0, pop(380, 760, 0.18, 0.045)), (0.065, 0.7 * pop(620, 1100, 0.15, 0.035)),
                     (0.0, 0.25 * xylo(note_hz("G5"), 0.25, 0.05))])


def sfx_harvest():
    """すっぽん：「す」とやわらかく引き抜き、「ぽん」とコルクが抜ける"""
    t = t_axis(0.12)
    swish = band(RNG.standard_normal(len(t)), 2500, 7000) * (t / t[-1]) ** 2 * 0.35
    t2 = t_axis(0.35)
    click = band(RNG.standard_normal(len(t2)), 1000, 5000) * env(t2, 0.0005, 0.004) * 0.6
    pon = sweep(t2, 820, 540, 0.02) * env(t2, 0.001, 0.09)
    pon += 0.35 * sweep(t2, 1640, 1080, 0.02) * env(t2, 0.001, 0.04)
    return mix(0.5, [(0.0, swish), (0.12, click + pon), (0.13, 0.3 * marimba(note_hz("C6"), 0.35, 0.12))])


def sfx_plant():
    """ぽふっ：種をやさしく土に埋める"""
    t = t_axis(0.2)
    x = sweep(t, 330, 210, 0.03) * env(t, 0.002, 0.05)
    x += lp(RNG.standard_normal(len(t)), 1200) * env(t, 0.003, 0.03) * 0.5
    return x


def sfx_hamster():
    """コロロロン♪：ちいさな木琴の駆け上がり"""
    notes = ["C6", "D6", "E6", "G6", "C7"]
    parts = []
    for i, n in enumerate(notes):
        last = i == len(notes) - 1
        parts.append((i * 0.055, (0.9 if last else 0.6) * xylo(note_hz(n), 0.6 if last else 0.25, 0.22 if last else 0.07)))
    return mix(0.85, parts)


def sfx_steps():
    """てちてち：ちいさな足でぱたぱた歩く、柔らかい音"""
    def tip(f):
        t = t_axis(0.05)
        x = band(RNG.standard_normal(len(t)), f * 0.7, f * 1.3) * env(t, 0.001, 0.008)
        x += 0.5 * np.sin(2 * np.pi * f * 0.5 * t) * env(t, 0.001, 0.01)
        return lp(x, 3500)
    return mix(0.5, [(0.0, tip(2200)), (0.085, 0.8 * tip(1800)), (0.23, tip(2200)), (0.315, 0.8 * tip(1800))])


def sfx_ding():
    """チーン！：レトロなオーブンのベル（前にちいさなカチッ）"""
    t = t_axis(1.4)
    f = 1780
    x = np.sin(2 * np.pi * f * t) * env(t, 0.001, 0.55)
    x += 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * env(t, 0.001, 0.22)
    x += 0.25 * np.sin(2 * np.pi * f * 5.4 * t) * env(t, 0.001, 0.08)
    x *= 1 + 0.08 * np.sin(2 * np.pi * 5.5 * t)  # ベルのゆらぎ
    click = woodblock(2600, 0.05, 0.006) * 0.4
    return mix(1.5, [(0.0, click), (0.06, x)])


def sfx_jingle():
    """ポロロン♪：色鉛筆でくるっとまるを描くような、上がって下りるアルペジオ"""
    notes = ["G5", "C6", "E6", "G6", "E6", "C7"]
    parts = []
    for i, n in enumerate(notes):
        last = i == len(notes) - 1
        parts.append((i * 0.07, (0.9 if last else 0.55) * celesta(note_hz(n), 1.1 if last else 0.4, 0.5 if last else 0.12)))
    return mix(1.6, parts)


def sfx_cook():
    """料理完成：チーン！ → ポロロン♪"""
    d = sfx_ding()
    j = sfx_jingle()
    return mix(2.2, [(0.0, d), (0.42, 0.75 * j)])


def sfx_page():
    """サクッ：画用紙をめくる"""
    t = t_axis(0.09)
    n = RNG.standard_normal(len(t))
    swell = (t / t[-1]) ** 1.5
    x = hp(band(n, 1800, 7500), 1500) * swell * 0.6
    x[-int(SR * 0.004):] *= np.linspace(1, 0, int(SR * 0.004))
    t2 = t_axis(0.04)
    crisp = band(RNG.standard_normal(len(t2)), 3000, 9000) * env(t2, 0.0005, 0.006) * 0.9
    return mix(0.16, [(0.0, x), (0.085, crisp)])


def sfx_tap():
    """コッ：木をやさしく叩く"""
    return lp(woodblock(880, 0.1, 0.02), 5000)


def sfx_coin():
    """出荷・販売：木琴の「ぽろん」2音"""
    return mix(0.6, [(0.0, 0.8 * marimba(note_hz("G5"), 0.3, 0.1)), (0.08, marimba(note_hz("D6"), 0.5, 0.2))])


def sfx_sleep():
    """おやすみ：木琴でゆっくり下りる子守歌"""
    notes = ["G5", "E5", "C5", "G4"]
    return mix(1.8, [(i * 0.22, 0.8 * marimba(note_hz(n), 0.9, 0.35)) for i, n in enumerate(notes)])


def sfx_error():
    """できないとき：低めの「こつん」"""
    return mix(0.25, [(0.0, woodblock(420, 0.12, 0.03)), (0.07, 0.6 * woodblock(330, 0.12, 0.03))])


SOUNDS = {
    "water": (sfx_water, 0.75), "harvest": (sfx_harvest, 0.8), "plant": (sfx_plant, 0.7),
    "hamster": (sfx_hamster, 0.75), "steps": (sfx_steps, 0.6),
    "cook": (sfx_cook, 0.8), "jingle": (sfx_jingle, 0.75),
    "page": (sfx_page, 0.55), "tap": (sfx_tap, 0.55),
    "coin": (sfx_coin, 0.7), "sleep": (sfx_sleep, 0.7), "error": (sfx_error, 0.55),
}


def write(name, x, peak):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = int(SR * 0.01)
    x[-fade:] *= np.linspace(1, 0, fade)
    data = (x * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, (fn, peak) in SOUNDS.items():
        write(name, fn(), peak)
        print("wrote", name)
