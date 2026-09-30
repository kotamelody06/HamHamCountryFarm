#!/usr/bin/env python3
"""タイトルロゴ「はむはむカントリーファーム」を SVG で生成するスクリプト。

  python3 tools/make_logo.py   → ui/title_logo.svg

文字はフォント（Noto Sans CJK JP Black）の輪郭をパスに変換して埋め込むので、
端末にフォントがなくても同じ見た目になります。太い丸みのあるフチ取りを重ねて、
ぽってり丸い文字に見せています。
"""
import os
from fontTools.ttLib import TTCollection
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc"
FONT_SUB = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
W, H = 1000, 660

BROWN = "#5a3a22"
CREAM = "#fff8e8"


class Font:
    def __init__(self, path):
        self.f = TTCollection(path).fonts[0]  # 0 = JP
        self.gs = self.f.getGlyphSet()
        self.cmap = self.f.getBestCmap()
        self.upm = self.f["head"].unitsPerEm

    def bounds(self, ch):
        bp = BoundsPen(self.gs)
        self.gs[self.cmap[ord(ch)]].draw(bp)
        return bp.bounds  # xMin, yMin, xMax, yMax (font units)

    def path(self, ch, x, y, size):
        """ch の左端を x、ベースラインを y に置いたパス文字列"""
        s = size / self.upm
        xmin = self.bounds(ch)[0]
        pen = SVGPathPen(self.gs)
        self.gs[self.cmap[ord(ch)]].draw(TransformPen(pen, (s, 0, 0, -s, x - xmin * s, y)))
        return pen.getCommands()

    def width(self, ch, size):
        b = self.bounds(ch)
        return (b[2] - b[0]) * size / self.upm

    def layout(self, text, cx, y, size, gap, bounce=None):
        """中央ぞろえで1文字ずつ並べる。bounce: [(dy, 回転角), ...]"""
        widths = [self.width(c, size) for c in text]
        total = sum(widths) + gap * (len(text) - 1)
        x = cx - total / 2
        out = []
        for i, c in enumerate(text):
            dy, rot = bounce[i] if bounce else (0, 0)
            d = self.path(c, x, y + dy, size)
            out.append((d, x + widths[i] / 2, y + dy - size * 0.38, rot))
            x += widths[i] + gap
        return out, total


def rotated(d, cx, cy, rot, attrs):
    t = f' transform="rotate({rot} {cx:.1f} {cy:.1f})"' if rot else ""
    return f'<path d="{d}"{t} {attrs}/>'


def lettering(glyphs, fill, outer=30, inner=14, shadow=9, outer_col=BROWN, inner_col=CREAM):
    """フチ取り文字：影 → 茶色の太フチ → クリームのフチ → 塗り"""
    rj = 'stroke-linejoin="round" stroke-linecap="round"'
    layers = []
    layers.append('<g transform="translate(0 %d)" opacity="0.35">' % shadow +
                  "".join(rotated(d, cx, cy, r, f'fill="{outer_col}" stroke="{outer_col}" stroke-width="{outer}" {rj}') for d, cx, cy, r in glyphs) + "</g>")
    layers.append("".join(rotated(d, cx, cy, r, f'fill="{outer_col}" stroke="{outer_col}" stroke-width="{outer}" {rj}') for d, cx, cy, r in glyphs))
    if inner:
        layers.append("".join(rotated(d, cx, cy, r, f'fill="{inner_col}" stroke="{inner_col}" stroke-width="{inner}" {rj}') for d, cx, cy, r in glyphs))
    layers.append("".join(rotated(d, cx, cy, r, f'fill="{fill}"') for d, cx, cy, r in glyphs))
    return "\n".join(layers)


def hamster(x, y, s):
    """文字のふちからのぞくゴールデンハムスター（ミニ麦わら帽子つき）"""
    return f'''
<g transform="translate({x} {y}) scale({s})">
  <circle cx="-34" cy="-40" r="15" fill="#d1913e" stroke="{BROWN}" stroke-width="5"/>
  <circle cx="-34" cy="-40" r="8" fill="#f4b3b3"/>
  <circle cx="34" cy="-40" r="15" fill="#d1913e" stroke="{BROWN}" stroke-width="5"/>
  <circle cx="34" cy="-40" r="8" fill="#f4b3b3"/>
  <ellipse cx="0" cy="0" rx="58" ry="46" fill="#e8a64a" stroke="{BROWN}" stroke-width="6"/>
  <ellipse cx="0" cy="16" rx="38" ry="28" fill="#fff3dc"/>
  <circle cx="-20" cy="-8" r="7" fill="#2b1d14"/><circle cx="-17.5" cy="-10.5" r="2.4" fill="#fff"/>
  <circle cx="20" cy="-8" r="7" fill="#2b1d14"/><circle cx="22.5" cy="-10.5" r="2.4" fill="#fff"/>
  <ellipse cx="-34" cy="8" rx="10" ry="6" fill="#ff8c8c" opacity="0.55"/>
  <ellipse cx="34" cy="8" rx="10" ry="6" fill="#ff8c8c" opacity="0.55"/>
  <circle cx="0" cy="1" r="4" fill="#e88a8a"/>
  <path d="M-8 7 q4 5 8 0 q4 5 8 0" fill="none" stroke="{BROWN}" stroke-width="2.6" stroke-linecap="round"/>
  <!-- 前足（文字のふちにかける） -->
  <ellipse cx="-22" cy="40" rx="11" ry="8" fill="#f6c9b8" stroke="{BROWN}" stroke-width="4"/>
  <ellipse cx="22" cy="40" rx="11" ry="8" fill="#f6c9b8" stroke="{BROWN}" stroke-width="4"/>
  <!-- ミニ麦わら帽子 -->
  <ellipse cx="0" cy="-42" rx="50" ry="11" fill="#e9c46a" stroke="{BROWN}" stroke-width="4.5"/>
  <path d="M-27 -44 Q-27 -74 0 -74 Q27 -74 27 -44Z" fill="#f0d27f" stroke="{BROWN}" stroke-width="4.5" stroke-linejoin="round"/>
  <rect x="-27" y="-54" width="54" height="9" fill="#c0504d"/>
</g>'''


def sprout(x, y, s, flip=False):
    sx = -s if flip else s
    return f'''
<g transform="translate({x} {y}) scale({sx} {s})">
  <path d="M0 0 Q-2 -26 2 -44" stroke="{BROWN}" stroke-width="11" fill="none" stroke-linecap="round"/>
  <path d="M0 0 Q-2 -26 2 -44" stroke="#5f9e3b" stroke-width="5" fill="none" stroke-linecap="round"/>
  <path d="M2 -40 Q-26 -40 -32 -66 Q-4 -68 2 -40Z" fill="#7cc04f" stroke="{BROWN}" stroke-width="4.5" stroke-linejoin="round"/>
  <path d="M2 -42 Q14 -72 40 -70 Q34 -42 2 -42Z" fill="#8fd05e" stroke="{BROWN}" stroke-width="4.5" stroke-linejoin="round"/>
</g>'''


def wheat(x, y, s, rot):
    grains = "".join(
        f'<ellipse cx="{dx}" cy="{-40 - i * 15}" rx="6" ry="11" transform="rotate({ang} {dx} {-40 - i * 15})"/>'
        for i in range(4) for dx, ang in ((-7, -25), (7, 25)))
    return f'''
<g transform="translate({x} {y}) rotate({rot}) scale({s})">
  <path d="M0 0 Q2 -50 0 -100" stroke="{BROWN}" stroke-width="10" fill="none" stroke-linecap="round"/>
  <path d="M0 0 Q2 -50 0 -100" stroke="#d1a843" stroke-width="4.5" fill="none" stroke-linecap="round"/>
  <g fill="#f0cc62" stroke="{BROWN}" stroke-width="3.5">{grains}<ellipse cx="0" cy="-104" rx="6" ry="11"/></g>
</g>'''


def sparkle(x, y, s, col="#ffd84a"):
    return (f'<path transform="translate({x} {y}) scale({s})" d="M0 -20 Q3 -3 20 0 Q3 3 0 20 Q-3 3 -20 0 Q-3 -3 0 -20Z" '
            f'fill="{col}" stroke="{BROWN}" stroke-width="3" stroke-linejoin="round"/>')


def board(cx, y, w, h):
    """木の看板（3枚の板＋くぎ）"""
    x0 = cx - w / 2
    plank_h = h / 3
    planks = []
    cols = ["#c69262", "#b9834f", "#c28c5a"]
    for i in range(3):
        py = y + i * plank_h
        planks.append(f'<rect x="{x0}" y="{py:.1f}" width="{w}" height="{plank_h:.1f}" fill="{cols[i]}"/>')
        planks.append(f'<path d="M{x0 + 40} {py + plank_h * 0.55:.1f} q{w * 0.2:.0f} -6 {w * 0.4:.0f} 0 M{x0 + w * 0.55:.0f} {py + plank_h * 0.35:.1f} q{w * 0.15:.0f} 5 {w * 0.35:.0f} 0" '
                      f'stroke="#9c6c46" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.6"/>')
        if i:
            planks.append(f'<line x1="{x0}" y1="{py:.1f}" x2="{x0 + w}" y2="{py:.1f}" stroke="#8b5e3c" stroke-width="4"/>')
    nails = "".join(f'<circle cx="{nx}" cy="{ny:.1f}" r="6" fill="#8a7a6a" stroke="{BROWN}" stroke-width="2.5"/>'
                    for nx in (x0 + 26, x0 + w - 26) for ny in (y + 24, y + h - 24))
    return f'''
<g>
  <rect x="{x0}" y="{y + 10}" width="{w}" height="{h}" rx="26" fill="{BROWN}" opacity="0.35"/>
  <clipPath id="boardclip"><rect x="{x0}" y="{y}" width="{w}" height="{h}" rx="26"/></clipPath>
  <g clip-path="url(#boardclip)">{"".join(planks)}</g>
  <rect x="{x0}" y="{y}" width="{w}" height="{h}" rx="26" fill="none" stroke="{BROWN}" stroke-width="9"/>
  <rect x="{x0 + 12}" y="{y + 12}" width="{w - 24}" height="{h - 24}" rx="18" fill="none" stroke="#e2b77a" stroke-width="3" stroke-dasharray="14 10" opacity="0.8"/>
  {nails}
</g>'''


def ribbon(cx, y, w, h, text_svg):
    x0, x1 = cx - w / 2, cx + w / 2
    t = 46  # しっぽ
    return f'''
<g>
  <path d="M{x0 + 10} {y + 14} h-{t + 20} l22 {h / 2:.1f} l-22 {h / 2:.1f} h{t + 20}Z" fill="#9c3b37" stroke="{BROWN}" stroke-width="6" stroke-linejoin="round"/>
  <path d="M{x1 - 10} {y + 14} h{t + 20} l-22 {h / 2:.1f} l22 {h / 2:.1f} h-{t + 20}Z" fill="#9c3b37" stroke="{BROWN}" stroke-width="6" stroke-linejoin="round"/>
  <path d="M{x0} {y} Q{cx} {y - 16} {x1} {y} V{y + h} Q{cx} {y + h - 16} {x0} {y + h}Z" fill="#c9534d" stroke="{BROWN}" stroke-width="6" stroke-linejoin="round"/>
  <path d="M{x0 + 14} {y + 9} Q{cx} {y - 6} {x1 - 14} {y + 9}" fill="none" stroke="#f3e6c8" stroke-width="3" stroke-dasharray="10 8" opacity="0.8"/>
  <path d="M{x0 + 14} {y + h - 9} Q{cx} {y + h - 24} {x1 - 14} {y + h - 9}" fill="none" stroke="#f3e6c8" stroke-width="3" stroke-dasharray="10 8" opacity="0.8"/>
  {text_svg}
</g>'''


def main():
    big = Font(FONT)
    sub = Font(FONT_SUB)

    # ── はむはむ ──
    bounce = [(0, -6), (-14, 4), (4, -3), (-10, 7)]
    hamu, hamu_w = big.layout("はむはむ", W / 2, 300, 218, 14, bounce)
    hamu_svg = lettering(hamu, "url(#gold)", outer=34, inner=16, shadow=10)

    # ── カントリーファーム（看板） ──
    board_y, board_h = 352, 150
    kana, kana_w = big.layout("カントリーファーム", W / 2, board_y + 112, 92, 4)
    board_w = kana_w + 110
    kana_svg = lettering(kana, "url(#cream)", outer=16, inner=0, shadow=5)

    # ── サブタイトル（リボン） ──
    sub_text = "小さなお手伝いさんとスローライフ"
    subg, sub_w = sub.layout(sub_text, W / 2, 606, 38, 1)
    sub_svg = "".join(f'<path d="{d}" fill="{CREAM}" stroke="#7a2e2a" stroke-width="7" stroke-linejoin="round" paint-order="stroke"/>' for d, _, _, _ in subg)
    sub_svg += "".join(f'<path d="{d}" fill="{CREAM}"/>' for d, _, _, _ in subg)

    top_of_hamu = 300 - 218 * 0.88
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<!-- タイトルロゴ（tools/make_logo.py で生成・背景は透過） -->
<defs>
  <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ffe08a"/><stop offset="0.5" stop-color="#f7b64c"/><stop offset="1" stop-color="#e98a2e"/>
  </linearGradient>
  <linearGradient id="cream" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#f6e2b4"/>
  </linearGradient>
</defs>
{wheat(W / 2 - board_w / 2 - 6, board_y + board_h - 10, 1.05, -24)}
{wheat(W / 2 - board_w / 2 + 22, board_y + board_h - 4, 0.85, -8)}
{wheat(W / 2 + board_w / 2 + 6, board_y + board_h - 10, 1.05, 24)}
{wheat(W / 2 + board_w / 2 - 22, board_y + board_h - 4, 0.85, 8)}
{board(W / 2, board_y, board_w, board_h)}
{kana_svg}
{hamu_svg}
{hamster(hamu[3][1] + 58, top_of_hamu + 4, 0.95)}
{sparkle(hamu[0][1] - 128, top_of_hamu + 40, 1.4)}
{sparkle(hamu[0][1] - 100, top_of_hamu - 8, 0.8, "#fff3b0")}
{sparkle(hamu[3][1] + 150, 270, 1.1)}
{ribbon(W / 2, 560, sub_w + 90, 64, sub_svg)}
{sprout(W / 2 - sub_w / 2 - 88, 582, 0.8)}
{sprout(W / 2 + sub_w / 2 + 88, 582, 0.8, flip=True)}
</svg>
'''
    out = os.path.join(ROOT, "ui", "title_logo.svg")
    with open(out, "w") as f:
        f.write(svg)
    print("wrote", out, f"({len(svg) // 1024} KB)")


if __name__ == "__main__":
    main()
