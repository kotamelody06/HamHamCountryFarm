#!/usr/bin/env python3
"""畑まわりのアイコン（SVG）を生成するスクリプト。

  python3 tools/make_icons.py
    ui/icon_seeds.svg  … 見出し「たねを選ぶ」（たね袋）
    ui/icon_field.svg  … 見出し「はたけ」（畝と芽と立て札）
    ui/crop_<作物ID>.svg … たねボタン用の作物アイコン（全14種）

どれも 96x96、クリーム色の丸い台座に描いた、ほかのボタンアイコンと同じタッチです。
"""
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "ui")
LEAF = "#6fae52"
LEAF_D = "#3f7a2a"


def badge(body, ring="#e7d3ad"):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <circle cx="48" cy="48" r="45" fill="#fff6dc" stroke="{ring}" stroke-width="3"/>
{body}
</svg>
'''


def leaf(x, y, rot, s=1.0, col=LEAF):
    return (f'<path transform="translate({x} {y}) rotate({rot}) scale({s})" d="M0 0 Q-9 -10 0 -24 Q9 -10 0 0Z" '
            f'fill="{col}" stroke="{LEAF_D}" stroke-width="2" stroke-linejoin="round"/>')


def shine(x, y, rx=5, ry=3.5, rot=-30):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" transform="rotate({rot} {x} {y})" fill="#ffffff" opacity="0.7"/>'


# ── 作物 ─────────────────────────────────────────
CROPS = {}

CROPS["turnip"] = badge(f'''
  {leaf(40, 36, -30, 1.1)}{leaf(48, 34, 0, 1.2)}{leaf(56, 36, 30, 1.1)}
  <path d="M48 36 C70 36 74 62 58 72 Q53 76 50 84 Q48 76 46 84 Q43 76 38 72 C22 62 26 36 48 36Z" fill="#fbfaf4" stroke="#b9ae98" stroke-width="2.5"/>
  <path d="M48 36 C66 36 71 48 70 54 Q48 46 26 54 C25 48 30 36 48 36Z" fill="#b57cc9" stroke="#8a5aa0" stroke-width="2.5" stroke-linejoin="round"/>
  {shine(38, 60)}''')

CROPS["potato"] = badge(f'''
  <path d="M22 58 C18 40 40 30 58 34 C76 38 80 56 70 66 C60 76 26 76 22 58Z" fill="#c9a26b" stroke="#8b6a3e" stroke-width="3"/>
  <g fill="#8b6a3e"><circle cx="38" cy="50" r="2.4"/><circle cx="58" cy="46" r="2.4"/><circle cx="50" cy="62" r="2.4"/><circle cx="66" cy="58" r="2"/></g>
  <path d="M34 60 Q40 64 46 62" stroke="#a8844f" stroke-width="2" fill="none" stroke-linecap="round"/>
  {shine(36, 42, 6, 3.5)}''')

CROPS["wheat"] = badge("".join(
    f'''<g transform="rotate({rot} 48 82)">
    <path d="M48 82 Q49 56 48 26" stroke="#c99a2e" stroke-width="3" fill="none" stroke-linecap="round"/>
    <g fill="#f0cc62" stroke="#b8862a" stroke-width="1.8">
      {''.join(f'<ellipse cx="{48 + dx}" cy="{36 + i * 9}" rx="4" ry="7" transform="rotate({a} {48 + dx} {36 + i * 9})"/>' for i in range(4) for dx, a in ((-5, -25), (5, 25)))}
      <ellipse cx="48" cy="27" rx="3.6" ry="6.5"/>
    </g></g>''' for rot in (-22, 0, 22)) + '<rect x="40" y="66" width="16" height="7" rx="3" fill="#c0504d"/>')

CROPS["flower"] = badge(
    "".join(f'''<g transform="rotate({rot} 48 84)">
    <path d="M48 84 L48 30" stroke="{LEAF_D}" stroke-width="3" stroke-linecap="round"/>
    {''.join(f'<ellipse cx="{48 + dx}" cy="{30 + i * 7}" rx="4.5" ry="5.5" fill="#a58ad8" stroke="#6f55a8" stroke-width="1.5"/>' for i in range(5) for dx in ((-3, 3) if i % 2 else (0,)))}
    </g>''' for rot in (-20, 0, 20))
    + '<path d="M38 70 Q48 76 58 70 L56 78 Q48 82 40 78Z" fill="#e9c46a" stroke="#b8862a" stroke-width="2"/>')

CROPS["strawberry"] = badge(f'''
  <path d="M48 84 C30 76 22 58 26 46 C30 36 42 36 48 40 C54 36 66 36 70 46 C74 58 66 76 48 84Z" fill="#e0434b" stroke="#a82a33" stroke-width="3"/>
  <g fill="#ffe8a0">{''.join(f'<ellipse cx="{x}" cy="{y}" rx="1.6" ry="2.4"/>' for x, y in ((38, 52), (48, 50), (58, 52), (34, 62), (44, 62), (54, 62), (62, 62), (40, 72), (50, 72), (57, 71)))}</g>
  <path d="M48 42 L36 34 L44 38 L40 28 L48 36 L56 28 L52 38 L60 34Z" fill="{LEAF}" stroke="{LEAF_D}" stroke-width="2" stroke-linejoin="round"/>
  <path d="M48 36 L48 22" stroke="{LEAF_D}" stroke-width="3" stroke-linecap="round"/>
  {shine(36, 48)}''')

CROPS["herb"] = badge(f'''
  <path d="M48 86 Q46 60 50 22" stroke="{LEAF_D}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  {leaf(48, 76, -60, 1.2, "#7cc04f")}{leaf(48, 76, 60, 1.2, "#7cc04f")}
  {leaf(48, 58, -55, 1.1)}{leaf(48, 58, 55, 1.1)}
  {leaf(49, 42, -45, 0.95, "#8fd05e")}{leaf(49, 42, 45, 0.95, "#8fd05e")}
  {leaf(50, 28, 0, 0.8, "#8fd05e")}''')

CROPS["tomato"] = badge(f'''
  <circle cx="48" cy="56" r="26" fill="#e5533d" stroke="#b83a28" stroke-width="3"/>
  <path d="M48 34 L38 30 L44 38 L34 42 L46 42 L48 50 L50 42 L62 42 L52 38 L58 30Z" fill="{LEAF}" stroke="{LEAF_D}" stroke-width="2" stroke-linejoin="round"/>
  <path d="M48 36 Q48 26 54 22" stroke="{LEAF_D}" stroke-width="3" fill="none" stroke-linecap="round"/>
  {shine(36, 48, 7, 4)}''')

CROPS["corn"] = badge(f'''
  <ellipse cx="50" cy="46" rx="13" ry="28" transform="rotate(20 50 46)" fill="#f2c94c" stroke="#c99a2e" stroke-width="2.5"/>
  <g stroke="#d8a830" stroke-width="1.6" transform="rotate(20 50 46)">
    <line x1="37" y1="36" x2="63" y2="36"/><line x1="37" y1="44" x2="63" y2="44"/><line x1="37" y1="52" x2="63" y2="52"/><line x1="39" y1="60" x2="61" y2="60"/><line x1="40" y1="28" x2="60" y2="28"/>
    <line x1="44" y1="20" x2="44" y2="72"/><line x1="50" y1="18" x2="50" y2="74"/><line x1="56" y1="20" x2="56" y2="72"/>
  </g>
  <path d="M34 84 Q30 60 40 46 Q44 64 42 84Z" fill="{LEAF}" stroke="{LEAF_D}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M42 84 Q58 70 66 56 Q70 72 52 86Z" fill="#7cc04f" stroke="{LEAF_D}" stroke-width="2.5" stroke-linejoin="round"/>''')

CROPS["cotton"] = badge(f'''
  <path d="M48 86 L48 62" stroke="#8b5e3c" stroke-width="4" stroke-linecap="round"/>
  <path d="M30 58 Q48 74 66 58 Q60 66 48 68 Q36 66 30 58Z" fill="#8b5e3c"/>
  {''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#ffffff" stroke="#d6cdb6" stroke-width="2"/>' for x, y, r in ((36, 50, 12), (60, 50, 12), (48, 40, 14), (48, 56, 12)))}
  <path d="M42 36 Q48 32 54 36" stroke="#e6dfcc" stroke-width="2" fill="none"/>''')

CROPS["blueberry"] = badge(f'''
  {leaf(62, 38, 50, 1.3)}
  {''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#4f5fb0" stroke="#2f3b7a" stroke-width="2.5"/><path d="M{x - 4} {y - r + 5} l4 3 4 -3" stroke="#2f3b7a" stroke-width="2" fill="none"/>' for x, y, r in ((36, 60, 14), (60, 62, 13), (47, 44, 13)))}
  {shine(32, 55, 4, 2.5)}{shine(56, 57, 4, 2.5)}{shine(43, 39, 4, 2.5)}''')

CROPS["pumpkin"] = badge(f'''
  <ellipse cx="48" cy="58" rx="32" ry="24" fill="#e98a2e" stroke="#b8621a" stroke-width="3"/>
  <ellipse cx="48" cy="58" rx="16" ry="24" fill="#f29b3d" stroke="#b8621a" stroke-width="2.5"/>
  <path d="M48 36 Q48 26 56 22" stroke="#5f7a2a" stroke-width="5" fill="none" stroke-linecap="round"/>
  {leaf(60, 30, 70, 0.9)}
  {shine(30, 52, 5, 3)}''')

CROPS["carrot"] = badge(f'''
  {leaf(56, 30, -20, 1.1)}{leaf(62, 32, 15, 1.2)}{leaf(66, 38, 45, 1.0)}
  <path d="M60 34 C68 40 66 48 60 54 L28 82 Q24 84 26 78 L50 38 C54 32 58 32 60 34Z" fill="#ee8a2a" stroke="#c46a1a" stroke-width="3" stroke-linejoin="round"/>
  <g stroke="#c46a1a" stroke-width="2" stroke-linecap="round"><path d="M46 50 l6 3"/><path d="M40 60 l6 3"/><path d="M34 70 l5 3"/></g>''')

CROPS["apple"] = badge(f'''
  <path d="M48 38 C36 28 18 36 22 58 C26 78 40 84 48 78 C56 84 70 78 74 58 C78 36 60 28 48 38Z" fill="#c9302c" stroke="#8f1f1c" stroke-width="3"/>
  <path d="M48 38 Q48 28 44 20" stroke="#6b4428" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  {leaf(50, 28, 60, 1.0)}
  {shine(34, 48, 7, 4)}''')

CROPS["cabbage"] = badge(f'''
  <circle cx="48" cy="54" r="28" fill="#9ccc65" stroke="#5f8f2f" stroke-width="3"/>
  <path d="M24 60 Q30 36 48 34 Q66 36 72 60 Q60 44 48 46 Q36 44 24 60Z" fill="#b5dd84" stroke="#5f8f2f" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M48 46 L48 76 M48 58 L38 50 M48 58 L58 50 M48 68 L36 62 M48 68 L60 62" stroke="#6f9f3f" stroke-width="2" fill="none" stroke-linecap="round"/>
  <path d="M22 62 Q18 74 30 80 Q24 70 30 62Z" fill="#7cb342" stroke="#5f8f2f" stroke-width="2"/>
  <path d="M74 62 Q78 74 66 80 Q72 70 66 62Z" fill="#7cb342" stroke="#5f8f2f" stroke-width="2"/>''')

# ── 見出しアイコン ──────────────────────────────
SEEDS = badge(f'''
  <!-- たね袋 -->
  <path d="M26 34 L70 34 L74 80 Q74 84 70 84 L26 84 Q22 84 22 80Z" fill="#d9b27c" stroke="#8b5e3c" stroke-width="3" stroke-linejoin="round"/>
  <path d="M24 34 L28 22 L68 22 L72 34Z" fill="#c69a60" stroke="#8b5e3c" stroke-width="3" stroke-linejoin="round"/>
  <path d="M30 28 H66" stroke="#8b5e3c" stroke-width="2" stroke-dasharray="4 3"/>
  <rect x="30" y="42" width="36" height="30" rx="6" fill="#fff8e8" stroke="#b5835a" stroke-width="2"/>
  <path d="M48 66 Q47 56 49 50" stroke="{LEAF_D}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
  <path d="M49 54 Q38 54 36 46 Q46 45 49 54Z" fill="{LEAF}" stroke="{LEAF_D}" stroke-width="1.8"/>
  <path d="M49 52 Q54 42 62 44 Q60 53 49 52Z" fill="#8fd05e" stroke="{LEAF_D}" stroke-width="1.8"/>
  <path d="M40 67 H56" stroke="#8b5e3c" stroke-width="2.5" stroke-linecap="round"/>
  <!-- こぼれたたね -->
  <g fill="#a0703f" stroke="#6b4428" stroke-width="1.2">
    <ellipse cx="78" cy="78" rx="3" ry="4.5" transform="rotate(30 78 78)"/><ellipse cx="84" cy="70" rx="2.6" ry="4" transform="rotate(-20 84 70)"/><ellipse cx="80" cy="62" rx="2.4" ry="3.6" transform="rotate(10 80 62)"/>
  </g>''')

FIELD = badge(f'''
  <clipPath id="c"><circle cx="48" cy="48" r="43.5"/></clipPath>
  <g clip-path="url(#c)">
    <rect x="0" y="0" width="96" height="96" fill="#dff0f7"/>
    <path d="M0 44 Q48 34 96 44 V96 H0Z" fill="#9fd67a"/>
    <path d="M-4 60 Q48 48 100 60 L100 96 L-4 96Z" fill="#a5764a"/>
    <g stroke="#7a522f" stroke-width="5" stroke-linecap="round" fill="none">
      <path d="M2 68 Q48 56 94 68"/><path d="M-2 80 Q48 68 98 80"/><path d="M-4 92 Q48 80 100 92"/>
    </g>
    <g>{''.join(f'<path transform="translate({x} {y})" d="M0 0 Q-7 -2 -9 -9 Q-2 -8 0 0Z M0 0 Q6 -3 9 -10 Q2 -9 0 0Z" fill="#7cc04f" stroke="{LEAF_D}" stroke-width="1.4"/>' for x, y in ((18, 63), (40, 59), (62, 59), (82, 63), (26, 75), (50, 71), (74, 74)))}</g>
  </g>
  <!-- 立て札 -->
  <rect x="64" y="22" width="5" height="30" fill="#8b5e3c"/>
  <rect x="54" y="18" width="26" height="16" rx="3" fill="#e2b77a" stroke="#8b5e3c" stroke-width="2.5"/>
  <path d="M60 26 H74" stroke="#8b5e3c" stroke-width="2" stroke-linecap="round"/>''')


def main():
    os.makedirs(OUT, exist_ok=True)
    files = {f"crop_{k}.svg": v for k, v in CROPS.items()}
    files["icon_seeds.svg"] = SEEDS
    files["icon_field.svg"] = FIELD
    for name, svg in files.items():
        with open(os.path.join(OUT, name), "w") as f:
            f.write(svg)
    print("wrote", len(files), "icons")


if __name__ == "__main__":
    main()
