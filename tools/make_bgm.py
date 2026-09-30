#!/usr/bin/env python3
"""BGMをオリジナル作曲・合成するスクリプト。

  python3 tools/make_bgm.py          → 全曲を作り直す
  python3 tools/make_bgm.py main     → メイン画面の曲だけ
    sounds/bgm_title.ogg … タイトル「はむはむの朝」（約40秒ループ）
    sounds/bgm_main.ogg  … メイン画面「ひだまりのはたけ」（約58秒ループ・下のほうに曲データ）

以下はタイトル曲の設計

曲の設計
  テンポ 96 / ハ長調 / 16小節ループ
  A（1〜8小節）: 木琴（マリンバ）が主旋律。効果音と同じ木の音色でそろえています
  B（9〜16小節）: やわらかいリコーダーが主旋律、木琴は分散和音で伴奏
  伴奏: アコースティックギター（Karplus-Strong 合成）の刻み、ウッドベース、
        シェイカー、ブラシのような小さなキック、フレーズの終わりにグロッケン
メロディやコードを書きかえれば、そのまま曲を作り直せます。
要: Python3 + numpy + scipy、ffmpeg（libvorbis）
"""
import os
import subprocess
import wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve, lfilter

SR = 44100
BPM = 96
BEAT = 60.0 / BPM
BARS = 16
LOOP_LEN = BARS * 4 * BEAT
RNG = np.random.default_rng(2026)
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def n(name):
    """'C5' 'F#4' などを MIDI 番号へ"""
    acc = 1 if "#" in name else (-1 if name[1] == "b" else 0)
    return 12 * (int(name[-1]) + 1) + NOTE[name[0]] + acc


def env(t, a, tau):
    return np.clip(t / a, 0, 1) * np.exp(-np.maximum(t - a, 0) / tau)


def lp(x, f):
    return sosfilt(butter(2, f, btype="low", fs=SR, output="sos"), x)


def bp(x, lo, hi):
    return sosfilt(butter(2, [lo, hi], btype="band", fs=SR, output="sos"), x)


# ── 楽器 ──────────────────────────────────────────
def marimba(m, dur, vel=1.0):
    f = midi_hz(m)
    t = np.arange(int(SR * max(dur, 0.9))) / SR
    tau = 0.55 * (440 / f) ** 0.35
    x = np.sin(2 * np.pi * f * t) * env(t, 0.002, tau)
    x += 0.28 * np.sin(2 * np.pi * f * 3.93 * t) * env(t, 0.001, tau * 0.15)
    x += 0.06 * np.sin(2 * np.pi * f * 9.2 * t) * env(t, 0.001, tau * 0.05)
    x += bp(RNG.standard_normal(len(t)), 1500, 5000) * env(t, 0.0005, 0.003) * 0.12
    return x * vel


def recorder(m, dur, vel=1.0):
    """やわらかい縦笛：基音＋弱い倍音＋息のノイズ＋遅れて入るビブラート"""
    f = midi_hz(m)
    L = dur + 0.12
    t = np.arange(int(SR * L)) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.18) / 0.25, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.07 * np.sin(3 * ph)
    breath = bp(RNG.standard_normal(len(t)), f * 0.9, f * 3) * 0.05
    a = np.clip(t / 0.04, 0, 1)
    r = np.clip((L - t) / 0.12, 0, 1)
    return (x + breath) * a * r * vel * 0.55


_KS_CACHE = {}


def ks_guitar(m, dur, vel=1.0, bright=0.5):
    """Karplus-Strong 撥弦（アコースティックギター風）。y[n] = x[n] + d/2·(y[n-N] + y[n-N-1])"""
    key = (m, bright, dur)
    if key not in _KS_CACHE:
        f = midi_hz(m)
        N = int(round(SR / f))
        total = int(SR * dur)
        x = np.zeros(total)
        x[:N] = lp(RNG.uniform(-1, 1, N), 1500 + 5000 * bright)
        d = 0.996
        a = np.zeros(N + 2)
        a[0] = 1
        a[N] = -d / 2
        a[N + 1] = -d / 2
        y = lfilter([1.0], a, x)
        _KS_CACHE[key] = lp(y, 5500) / (np.max(np.abs(y)) + 1e-9)
    return _KS_CACHE[key] * vel


def bass(m, dur, vel=1.0):
    f = midi_hz(m)
    t = np.arange(int(SR * (dur + 0.1))) / SR
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) * env(t, 0.003, 0.08)
    x *= env(t, 0.006, 0.55) * np.clip((dur + 0.1 - t) / 0.08, 0, 1)
    return x * vel


def glock(m, vel=1.0):
    f = midi_hz(m)
    t = np.arange(int(SR * 1.6)) / SR
    x = np.sin(2 * np.pi * f * t) * env(t, 0.001, 0.6) + 0.3 * np.sin(2 * np.pi * f * 2.76 * t) * env(t, 0.001, 0.15)
    return x * vel


def shaker(vel=1.0):
    t = np.arange(int(SR * 0.07)) / SR
    return bp(RNG.standard_normal(len(t)), 5000, 11000) * env(t, 0.012, 0.018) * vel


def kick(vel=1.0):
    t = np.arange(int(SR * 0.25)) / SR
    f = 48 + 40 * np.exp(-t / 0.03)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(t, 0.002, 0.09) * vel


# ── 曲データ ──────────────────────────────────────
CHORDS = ["C", "G", "Am", "Em", "F", "C", "Dm", "G",
          "F", "G", "Em", "Am", "Dm", "G", "C", "G7"]
# (ルート, 5度, ギターの上4音)
VOICING = {
    "C":  ("C3", "G2", ["C4", "E4", "G4", "C5"]),
    "G":  ("G2", "D3", ["B3", "D4", "G4", "B4"]),
    "Am": ("A2", "E3", ["A3", "C4", "E4", "A4"]),
    "Em": ("E2", "B2", ["B3", "E4", "G4", "B4"]),
    "F":  ("F2", "C3", ["A3", "C4", "F4", "A4"]),
    "Dm": ("D3", "A2", ["A3", "D4", "F4", "A4"]),
    "G7": ("G2", "D3", ["B3", "D4", "F4", "G4"]),
}
# 主旋律：小節ごとに (音, 拍位置, 長さ)
MELODY = [
    [("G4", 0, .5), ("C5", .5, .5), ("E5", 1, 1), ("D5", 2, .5), ("E5", 2.5, .5), ("G5", 3, 1)],
    [("D5", 0, 1.5), ("B4", 1.5, .5), ("D5", 2, 1), ("G4", 3, 1)],
    [("C5", 0, .5), ("E5", .5, .5), ("A5", 1, 1), ("G5", 2, .5), ("E5", 2.5, .5), ("C5", 3, 1)],
    [("B4", 0, 1.5), ("G4", 1.5, .5), ("B4", 2, 1), ("E5", 3, 1)],
    [("F5", 0, .5), ("E5", .5, .5), ("F5", 1, 1), ("A5", 2, 1), ("G5", 3, .5), ("F5", 3.5, .5)],
    [("E5", 0, 1.5), ("C5", 1.5, .5), ("E5", 2, .5), ("G5", 2.5, .5), ("C6", 3, 1)],
    [("A5", 0, .5), ("G5", .5, .5), ("F5", 1, 1), ("D5", 2, .5), ("E5", 2.5, .5), ("F5", 3, 1)],
    [("G5", 0, 2), ("B4", 2, 1), ("D5", 3, 1)],
    [("C6", 0, 1), ("A5", 1, 1), ("F5", 2, 1), ("A5", 3, 1)],
    [("B5", 0, 1), ("G5", 1, 1), ("D5", 2, 1), ("G5", 3, 1)],
    [("G5", 0, .5), ("A5", .5, .5), ("G5", 1, 1), ("E5", 2, 1), ("B4", 3, 1)],
    [("C5", 0, .5), ("D5", .5, .5), ("E5", 1, 1), ("A5", 2, 1.5), ("G5", 3.5, .5)],
    [("F5", 0, 1), ("E5", 1, .5), ("D5", 1.5, .5), ("F5", 2, 1), ("A5", 3, 1)],
    [("G5", 0, 1), ("F5", 1, .5), ("E5", 1.5, .5), ("D5", 2, 1), ("B4", 3, 1)],
    [("C5", 0, .5), ("E5", .5, .5), ("G5", 1, .5), ("C6", 1.5, 1.5), ("G5", 3, 1)],
    [("F5", 0, 1), ("D5", 1, 1), ("B4", 2, 1), ("G4", 3, 1)],
]


def render_title():
    global RNG
    RNG = np.random.default_rng(2026)
    _KS_CACHE.clear()
    tail = 3.0
    L = int(SR * (LOOP_LEN + tail))
    tracks = {k: np.zeros(L) for k in ("lead", "guitar", "bass", "perc", "arp", "glock")}

    def put(track, t_sec, sig):
        s = max(0, int(SR * t_sec))
        e = min(L, s + len(sig))
        tracks[track][s:e] += sig[: e - s]

    for bar in range(BARS):
        t0 = bar * 4 * BEAT
        chord = CHORDS[bar]
        root, fifth, upper = VOICING[chord]
        # 主旋律
        for name, pos, ln in MELODY[bar]:
            human = RNG.uniform(-0.006, 0.006)
            if bar < 8:
                put("lead", t0 + pos * BEAT + human, marimba(n(name), ln * BEAT, 0.9))
            else:
                put("lead", t0 + pos * BEAT + human, recorder(n(name), ln * BEAT * 0.95, 0.85))
        # B では木琴が分散和音
        if bar >= 8:
            for k, pos in enumerate([0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5]):
                m = n(upper[[0, 1, 2, 3, 2, 1, 2, 3][k]]) + 12
                put("arp", t0 + pos * BEAT, marimba(m, 0.4, 0.28 if k % 2 else 0.36))
        # ギター（ダウン＝4本を少しずらして、アップ＝上3本）
        for pos, vel, up in [(0, .7, False), (1, .9, False), (1.5, .45, True), (2, .7, False), (3, .9, False), (3.5, .45, True)]:
            strings = upper[1:][::-1] if up else upper
            for k, s in enumerate(strings):
                put("guitar", t0 + pos * BEAT + k * 0.011 + RNG.uniform(0, 0.004),
                    ks_guitar(n(s), 1.2, vel * (0.9 - 0.08 * k), bright=0.35 if up else 0.5))
        # ベース（1拍目ルート、3拍目5度、最後の小節は歩くように）
        put("bass", t0, bass(n(root) - 12 if n(root) > 45 else n(root), BEAT * 1.8, 0.95))
        put("bass", t0 + 2 * BEAT, bass(n(fifth) - 12 if n(fifth) > 45 else n(fifth), BEAT * 1.8, 0.8))
        # パーカッション
        for i in range(8):
            put("perc", t0 + i * BEAT / 2 + RNG.uniform(0, 0.005), shaker(0.55 if i % 2 else 0.3))
        put("perc", t0, kick(0.9))
        put("perc", t0 + 2 * BEAT, kick(0.6))
        # フレーズの終わりにキラリ
        if bar in (7, 15):
            for k, g in enumerate(["G6", "C7", "E7"]):
                put("glock", t0 + (2 + k * 0.33) * BEAT, glock(n(g), 0.45))

    # ミックス（音量・定位）
    mixdef = {  # (音量, パン -1左〜+1右)
        "lead": (0.62, 0.05), "arp": (0.6, 0.35), "guitar": (0.62, -0.35),
        "bass": (0.7, 0.0), "perc": (0.45, 0.25), "glock": (0.55, 0.2),
    }
    return finalize(tracks, mixdef, L, LOOP_LEN)


def finalize(tracks, mixdef, L, loop_len, wet=0.22, level=0.7):
    """ミックス → リバーブ → ループのつなぎ目処理"""
    left = np.zeros(L)
    right = np.zeros(L)
    for k, (vol, pan) in mixdef.items():
        x = tracks[k] * vol
        left += x * np.sqrt((1 - pan) / 2) * 1.414
        right += x * np.sqrt((1 + pan) / 2) * 1.414

    # やわらかいルームリバーブ（合成インパルス応答）
    ir_t = np.arange(int(SR * 1.2)) / SR
    irl = RNG.standard_normal(len(ir_t)) * np.exp(-ir_t / 0.32)
    irr = RNG.standard_normal(len(ir_t)) * np.exp(-ir_t / 0.32)
    irl, irr = lp(irl, 6000), lp(irr, 6000)
    irl /= np.sqrt(np.sum(irl ** 2))
    irr /= np.sqrt(np.sum(irr ** 2))
    left = left + wet * fftconvolve(left, irl)[:L]
    right = right + wet * fftconvolve(right, irr)[:L]

    # ループのつなぎ目：はみ出した余韻を先頭に重ねる
    n_loop = int(SR * loop_len)
    out = np.stack([left, right], axis=1)
    loop = out[:n_loop].copy()
    loop[: L - n_loop] += out[n_loop:]
    loop /= np.max(np.abs(loop)) + 1e-9
    loop *= level
    return loop


# ═════════════════════════════════════════════════
# メイン画面の曲「ひだまりのはたけ」
#   テンポ 100 / ヘ長調 / 3拍子（ワルツ）/ 32小節ループ（約58秒）
#   A : リコーダーの主旋律＋ギターの指弾き（アルペジオ）
#   A': 木琴が合いの手で加わる
#   B : 木琴が主旋律、シェイカーとグロッケンで少しにぎやかに
#   A'': リコーダーと木琴のユニゾンで締めて、また最初へ
# 作業中ずっと流れるので、タイトルより静かで起伏をおさえています。
# ═════════════════════════════════════════════════
MAIN_BPM = 100
MAIN_BEAT = 60.0 / MAIN_BPM
MAIN_VOICING = {
    "F":  ("F2", ["A3", "C4", "F4", "A4"]),
    "C":  ("C3", ["G3", "C4", "E4", "G4"]),
    "Dm": ("D3", ["A3", "D4", "F4", "A4"]),
    "Bb": ("Bb2", ["Bb3", "D4", "F4", "Bb4"]),
    "Gm": ("G2", ["Bb3", "D4", "G4", "Bb4"]),
    "C7": ("C3", ["Bb3", "C4", "E4", "G4"]),
}
_A = ["F", "C", "Dm", "Bb", "F", "Gm", "C", "C7"]
_A2 = ["F", "C", "Dm", "Bb", "F", "C", "F", "F"]
_B = ["Bb", "F", "Gm", "Dm", "Bb", "F", "Gm", "C7"]
MAIN_CHORDS = _A + _A2 + _B + _A2
_MA = [
    [("A4", 0, 1), ("C5", 1, 1), ("F5", 2, 1)],
    [("E5", 0, 2), ("C5", 2, 1)],
    [("D5", 0, 1), ("F5", 1, 1), ("A5", 2, 1)],
    [("G5", 0, 2), ("F5", 2, 1)],
    [("A5", 0, 1), ("G5", 1, .5), ("F5", 1.5, .5), ("C5", 2, 1)],
    [("D5", 0, 1), ("G5", 1, 1), ("Bb5", 2, 1)],
    [("A5", 0, 1), ("G5", 1, 1), ("E5", 2, 1)],
    [("G5", 0, 2), ("C5", 2, 1)],
]
_MA2 = _MA[:4] + [
    [("A5", 0, 1), ("C6", 1, 1), ("A5", 2, 1)],
    [("G5", 0, 1), ("E5", 1, 1), ("C5", 2, 1)],
    [("F5", 0, 1.5), ("G5", 1.5, .5), ("A5", 2, 1)],
    [("F5", 0, 3)],
]
_MB = [
    [("D6", 0, 1.5), ("C6", 1.5, .5), ("Bb5", 2, 1)],
    [("A5", 0, 2), ("F5", 2, 1)],
    [("G5", 0, 1), ("A5", 1, 1), ("Bb5", 2, 1)],
    [("A5", 0, 2), ("D5", 2, 1)],
    [("Bb5", 0, 1), ("A5", 1, 1), ("G5", 2, 1)],
    [("A5", 0, 1), ("F5", 1, 1), ("C5", 2, 1)],
    [("D5", 0, 1), ("E5", 1, 1), ("G5", 2, 1)],
    [("E5", 0, 1.5), ("D5", 1.5, .5), ("C5", 2, 1)],
]
MAIN_MELODY = _MA + _MA2 + _MB + _MA2


def render_main():
    global RNG
    RNG = np.random.default_rng(7)
    _KS_CACHE.clear()
    B = MAIN_BEAT
    bars = len(MAIN_CHORDS)
    loop_len = bars * 3 * B
    L = int(SR * (loop_len + 3.0))
    tracks = {k: np.zeros(L) for k in ("lead", "lead2", "guitar", "bass", "perc", "arp", "glock")}

    def put(track, t_sec, sig):
        s = max(0, int(SR * t_sec))
        e = min(L, s + len(sig))
        tracks[track][s:e] += sig[: e - s]

    for bar in range(bars):
        t0 = bar * 3 * B
        sec = bar // 8  # 0=A 1=A' 2=B 3=A''
        root, upper = MAIN_VOICING[MAIN_CHORDS[bar]]
        for name, pos, ln in MAIN_MELODY[bar]:
            t = t0 + pos * B + RNG.uniform(-0.006, 0.006)
            if sec == 2:
                put("lead", t, marimba(n(name), ln * B, 0.85))
            else:
                put("lead", t, recorder(n(name), ln * B * 0.92, 0.8))
                if sec == 3:
                    put("lead2", t, marimba(n(name) - 12, ln * B, 0.55))
        # A' では木琴の合いの手（小節の3拍目に和音の上2音）
        if sec == 1 and bar % 2 == 1:
            for k, s_ in enumerate(upper[2:]):
                put("arp", t0 + 2 * B + k * 0.09, marimba(n(s_) + 12, 0.5, 0.4))
        # ギターの指弾き：8分音符で ベース→上の弦を往復
        pattern = [root, upper[1], upper[2], upper[3], upper[2], upper[1]]
        for k, s_ in enumerate(pattern):
            m = n(s_)
            if k == 0 and m > 52:
                m -= 12
            put("guitar", t0 + k * B / 2 + RNG.uniform(0, 0.006),
                ks_guitar(m, 1.4, (0.85 if k == 0 else 0.55) * (1 if k % 2 == 0 else 0.85), bright=0.4))
        # ベース（1拍目のみ・ワルツ）
        rm = n(root)
        put("bass", t0, bass(rm - 12 if rm > 45 else rm, B * 2.6, 0.8))
        # B と A'' はシェイカーで少しだけ弾む
        if sec >= 2:
            for i in range(6):
                put("perc", t0 + i * B / 2 + RNG.uniform(0, 0.005), shaker(0.45 if i % 2 else 0.22))
        # 区切りのキラリ
        if bar in (7, 15, 23, 31):
            for k, g in enumerate(["C6", "F6", "A6", "C7"]):
                put("glock", t0 + (1 + k * 0.25) * B, glock(n(g), 0.35))

    mixdef = {
        "lead": (0.55, 0.05), "lead2": (0.45, -0.1), "arp": (0.5, 0.35), "guitar": (0.7, -0.3),
        "bass": (0.6, 0.0), "perc": (0.4, 0.3), "glock": (0.5, 0.2),
    }
    return finalize(tracks, mixdef, L, loop_len, wet=0.26, level=0.62)


SONGS = {"title": render_title, "main": render_main}


def write_ogg(name, loop):
    os.makedirs(os.path.join(ROOT, "sounds"), exist_ok=True)
    tmp = os.path.join(ROOT, "sounds", f"_bgm_{name}.wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((loop * 32767).astype("<i2").tobytes())
    out = os.path.join(ROOT, "sounds", f"bgm_{name}.ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", out], check=True)
    os.remove(tmp)
    print("wrote", out, f"{len(loop) / SR:.2f}s", f"{os.path.getsize(out) // 1024} KB")


def main():
    import sys
    names = sys.argv[1:] or list(SONGS)
    for name in names:
        write_ogg(name, SONGS[name]())


if __name__ == "__main__":
    main()
