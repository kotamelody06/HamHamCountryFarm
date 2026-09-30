class_name Art
extends RefCounted
## 画像素材なしで遊べるよう、キャラクターや作物をコードで描画するヘルパー。
## 後から本物のイラストに差し替える場合は、各関数の中身を draw_texture に置き換えてください。

const LINE := Color("5a3d2b")
const SKIN := Color("f8d9bd")
const DENIM := Color("4d6fa3")


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, seg := 28) -> void:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func ellipse_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w := 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 29:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, w, true)


static func rrect(ci: CanvasItem, r: Rect2, col: Color, radius := 8.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), col)


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts: Array = []
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	poly(ci, pts, col)


static func heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-s * 0.25, -s * 0.1), s * 0.28, col)
	ci.draw_circle(c + Vector2(s * 0.25, -s * 0.1), s * 0.28, col)
	poly(ci, [c + Vector2(-s * 0.52, 0), c + Vector2(s * 0.52, 0), c + Vector2(0, s * 0.5)], col)


# ─────────────────────────────────────────────
# ハムスター
# ─────────────────────────────────────────────
static func hamster(ci: CanvasItem, c: Vector2, size: float, type: String, outfit := {}) -> void:
	var d: Dictionary = GameData.HAMSTERS[type]
	var s: float = size * float(d["scale"])
	var fur := Color(d["fur"])
	var belly := Color(d["belly"])
	ellipse(ci, c + Vector2(0, s * 0.6), s * 0.75, s * 0.12, Color(0, 0, 0, 0.12))
	# 耳
	for sx in [-1, 1]:
		ci.draw_circle(c + Vector2(sx * s * 0.46, -s * 0.48), s * 0.19, fur.darkened(0.12))
		ci.draw_circle(c + Vector2(sx * s * 0.46, -s * 0.48), s * 0.11, Color("f4b3b3"))
	# からだ
	ellipse(ci, c, s * 0.8, s * 0.62, fur)
	ellipse(ci, c + Vector2(0, s * 0.2), s * 0.56, s * 0.4, belly)
	if type == "jungarian":
		ci.draw_line(c + Vector2(0, -s * 0.6), c + Vector2(0, -s * 0.3), Color("6b645c"), s * 0.08)
	if type == "campbell":
		ellipse(ci, c + Vector2(0, -s * 0.42), s * 0.3, s * 0.12, fur.darkened(0.18))
	# 目・ほっぺ・鼻
	for sx in [-1, 1]:
		ci.draw_circle(c + Vector2(sx * s * 0.27, -s * 0.12), s * 0.085, Color("2b1d14"))
		ci.draw_circle(c + Vector2(sx * s * 0.27 + s * 0.03, -s * 0.15), s * 0.03, Color.WHITE)
		ellipse(ci, c + Vector2(sx * s * 0.45, s * 0.08), s * 0.13, s * 0.08, Color(1, 0.55, 0.55, 0.45))
	ci.draw_circle(c + Vector2(0, s * 0.01), s * 0.05, Color("e88a8a"))
	ci.draw_arc(c + Vector2(-s * 0.05, s * 0.07), s * 0.05, 0.2, PI - 0.2, 8, LINE, max(1.5, s * 0.025), true)
	ci.draw_arc(c + Vector2(s * 0.05, s * 0.07), s * 0.05, 0.2, PI - 0.2, 8, LINE, max(1.5, s * 0.025), true)
	# 服
	if outfit.get("body", "") == "mini_overall":
		poly(ci, [c + Vector2(-s * 0.42, s * 0.18), c + Vector2(s * 0.42, s * 0.18), c + Vector2(s * 0.62, s * 0.5), c + Vector2(-s * 0.62, s * 0.5)], DENIM)
		ci.draw_line(c + Vector2(-s * 0.36, s * 0.2), c + Vector2(-s * 0.5, -s * 0.2), DENIM, s * 0.07)
		ci.draw_line(c + Vector2(s * 0.36, s * 0.2), c + Vector2(s * 0.5, -s * 0.2), DENIM, s * 0.07)
		ci.draw_circle(c + Vector2(-s * 0.3, s * 0.24), s * 0.04, Color("f2c94c"))
		ci.draw_circle(c + Vector2(s * 0.3, s * 0.24), s * 0.04, Color("f2c94c"))
	# 手
	for sx in [-1, 1]:
		ci.draw_circle(c + Vector2(sx * s * 0.2, s * 0.42), s * 0.08, Color("f6c9b8"))
	# 帽子
	match outfit.get("hat", ""):
		"mini_straw":
			ellipse(ci, c + Vector2(0, -s * 0.55), s * 0.6, s * 0.13, Color("e9c46a"))
			ellipse(ci, c + Vector2(0, -s * 0.7), s * 0.33, s * 0.2, Color("f0d27f"))
			ci.draw_line(c + Vector2(-s * 0.31, -s * 0.6), c + Vector2(s * 0.31, -s * 0.6), Color("c0504d"), s * 0.07)
		"mini_chef":
			rrect(ci, Rect2(c + Vector2(-s * 0.26, -s * 0.8), Vector2(s * 0.52, s * 0.28)), Color.WHITE, 3)
			for k in 3:
				ci.draw_circle(c + Vector2((k - 1) * s * 0.2, -s * 0.9), s * 0.17, Color.WHITE)
			ellipse_line(ci, c + Vector2(0, -s * 0.9), s * 0.4, s * 0.16, Color("dddddd"), 1.5)
		"mini_knit":
			ellipse(ci, c + Vector2(0, -s * 0.58), s * 0.45, s * 0.3, Color("c0504d"))
			rrect(ci, Rect2(c + Vector2(-s * 0.45, -s * 0.6), Vector2(s * 0.9, s * 0.12)), Color("f3e6c8"), 3)
			ci.draw_circle(c + Vector2(0, -s * 0.9), s * 0.12, Color("f3e6c8"))


# ─────────────────────────────────────────────
# 主人公
# ─────────────────────────────────────────────
static func player(ci: CanvasItem, rect: Rect2, gender: String, outfit: Dictionary, colors: Dictionary) -> void:
	var u := rect.size.y / 10.0
	var cx := rect.position.x + rect.size.x / 2.0
	var top := rect.position.y
	var hat: String = outfit.get("hat", "")
	var topc: String = outfit.get("top", "")
	var hair := Color("7a4a2a")
	ellipse(ci, Vector2(cx, top + 9.7 * u), 1.8 * u, 0.3 * u, Color(0, 0, 0, 0.12))
	var shirt := Color("c0504d") if gender == "boy" else Color("f3e6c8")
	if topc == "knit":
		shirt = colors.get("knit", Color("f1e0b8"))
	# 髪（後ろ）
	if gender == "girl":
		ellipse(ci, Vector2(cx, top + 2.4 * u), 1.55 * u, 1.7 * u, hair)
		for sx in [-1, 1]:
			ellipse(ci, Vector2(cx + sx * 1.35 * u, top + 3.8 * u), 0.35 * u, 0.8 * u, hair)
			ci.draw_circle(Vector2(cx + sx * 1.35 * u, top + 4.5 * u), 0.2 * u, Color("c0504d"))
	# 脚
	if gender == "boy":
		rrect(ci, Rect2(cx - 1.0 * u, top + 6.5 * u, 0.9 * u, 2.7 * u), Color("7a5a3a"), 4)
		rrect(ci, Rect2(cx + 0.1 * u, top + 6.5 * u, 0.9 * u, 2.7 * u), Color("7a5a3a"), 4)
	else:
		rrect(ci, Rect2(cx - 0.8 * u, top + 7.5 * u, 0.6 * u, 1.7 * u), SKIN, 4)
		rrect(ci, Rect2(cx + 0.2 * u, top + 7.5 * u, 0.6 * u, 1.7 * u), SKIN, 4)
	for sx in [-1, 1]:
		ellipse(ci, Vector2(cx + sx * 0.55 * u, top + 9.3 * u), 0.6 * u, 0.3 * u, Color("5a3d2b"))
	# 腕
	for sx in [-1, 1]:
		poly(ci, [Vector2(cx + sx * 1.1 * u, top + 3.8 * u), Vector2(cx + sx * 1.7 * u, top + 4.2 * u), Vector2(cx + sx * 1.9 * u, top + 6.2 * u), Vector2(cx + sx * 1.4 * u, top + 6.3 * u)], shirt)
		ci.draw_circle(Vector2(cx + sx * 1.65 * u, top + 6.45 * u), 0.3 * u, SKIN)
	# 胴
	rrect(ci, Rect2(cx - 1.2 * u, top + 3.6 * u, 2.4 * u, 3.2 * u), shirt, 10)
	if gender == "boy" and topc != "knit":
		for k in 5:
			ci.draw_line(Vector2(cx - 1.2 * u + k * 0.6 * u, top + 3.7 * u), Vector2(cx - 1.2 * u + k * 0.6 * u, top + 6.7 * u), Color(0.5, 0.15, 0.15, 0.45), 2)
			ci.draw_line(Vector2(cx - 1.2 * u, top + 3.9 * u + k * 0.6 * u), Vector2(cx + 1.2 * u, top + 3.9 * u + k * 0.6 * u), Color(0.5, 0.15, 0.15, 0.45), 2)
	if topc == "knit":
		for k in 4:
			ci.draw_line(Vector2(cx - 1.1 * u, top + 4.2 * u + k * 0.6 * u), Vector2(cx + 1.1 * u, top + 4.2 * u + k * 0.6 * u), shirt.darkened(0.15), 3)
	if gender == "girl":
		poly(ci, [Vector2(cx - 1.2 * u, top + 6.0 * u), Vector2(cx + 1.2 * u, top + 6.0 * u), Vector2(cx + 1.9 * u, top + 7.9 * u), Vector2(cx - 1.9 * u, top + 7.9 * u)], Color("f3e6c8") if topc != "knit" else shirt)
		ci.draw_line(Vector2(cx - 1.85 * u, top + 7.75 * u), Vector2(cx + 1.85 * u, top + 7.75 * u), Color("d9c49a"), 3)
	# オーバーオール（共通の初期衣装）
	poly(ci, [Vector2(cx - 0.8 * u, top + 4.6 * u), Vector2(cx + 0.8 * u, top + 4.6 * u), Vector2(cx + 1.2 * u, top + 6.8 * u), Vector2(cx - 1.2 * u, top + 6.8 * u)], DENIM)
	if gender == "boy":
		rrect(ci, Rect2(cx - 1.2 * u, top + 6.3 * u, 2.4 * u, 1.0 * u), DENIM, 4)
	for sx in [-1, 1]:
		ci.draw_line(Vector2(cx + sx * 0.65 * u, top + 4.7 * u), Vector2(cx + sx * 0.9 * u, top + 3.7 * u), DENIM, 0.3 * u)
		ci.draw_circle(Vector2(cx + sx * 0.6 * u, top + 4.8 * u), 0.12 * u, Color("f2c94c"))
	rrect(ci, Rect2(cx - 0.4 * u, top + 5.1 * u, 0.8 * u, 0.6 * u), DENIM.darkened(0.15), 3)
	# エプロン
	if topc == "apron":
		var ac: Color = colors.get("apron", Color("f1e0b8"))
		poly(ci, [Vector2(cx - 0.9 * u, top + 4.3 * u), Vector2(cx + 0.9 * u, top + 4.3 * u), Vector2(cx + 1.3 * u, top + 7.4 * u), Vector2(cx - 1.3 * u, top + 7.4 * u)], ac)
		rrect(ci, Rect2(cx - 0.6 * u, top + 5.9 * u, 1.2 * u, 0.7 * u), ac.darkened(0.12), 3)
		ci.draw_line(Vector2(cx - 1.2 * u, top + 5.0 * u), Vector2(cx + 1.2 * u, top + 5.0 * u), ac.darkened(0.2), 3)
	# 頭
	ci.draw_circle(Vector2(cx, top + 2.3 * u), 1.3 * u, SKIN)
	# 前髪
	if gender == "boy":
		poly(ci, [Vector2(cx - 1.35 * u, top + 2.2 * u), Vector2(cx - 1.2 * u, top + 1.0 * u), Vector2(cx, top + 0.7 * u), Vector2(cx + 1.2 * u, top + 1.0 * u), Vector2(cx + 1.35 * u, top + 2.2 * u), Vector2(cx + 0.6 * u, top + 1.5 * u), Vector2(cx, top + 1.8 * u), Vector2(cx - 0.6 * u, top + 1.5 * u)], hair)
	else:
		poly(ci, [Vector2(cx - 1.4 * u, top + 2.6 * u), Vector2(cx - 1.2 * u, top + 1.0 * u), Vector2(cx, top + 0.7 * u), Vector2(cx + 1.2 * u, top + 1.0 * u), Vector2(cx + 1.4 * u, top + 2.6 * u), Vector2(cx + 0.9 * u, top + 1.6 * u), Vector2(cx, top + 1.7 * u), Vector2(cx - 0.9 * u, top + 1.6 * u)], hair)
	for sx in [-1, 1]:
		ci.draw_circle(Vector2(cx + sx * 0.5 * u, top + 2.4 * u), 0.14 * u, Color("2b1d14"))
		ellipse(ci, Vector2(cx + sx * 0.85 * u, top + 2.85 * u), 0.25 * u, 0.14 * u, Color(1, 0.55, 0.55, 0.4))
	ci.draw_arc(Vector2(cx, top + 2.8 * u), 0.3 * u, 0.3, PI - 0.3, 10, LINE, 2.5, true)
	# 帽子
	if hat == "straw_hat":
		var band: Color = colors.get("straw_hat", Color("c0504d"))
		ellipse(ci, Vector2(cx, top + 1.2 * u), 2.2 * u, 0.45 * u, Color("e9c46a"))
		ellipse(ci, Vector2(cx, top + 0.75 * u), 1.2 * u, 0.75 * u, Color("f0d27f"))
		rrect(ci, Rect2(cx - 1.18 * u, top + 0.85 * u, 2.36 * u, 0.3 * u), band, 3)


# ─────────────────────────────────────────────
# 動物
# ─────────────────────────────────────────────
static func animal(ci: CanvasItem, c: Vector2, s: float, type: String) -> void:
	ellipse(ci, c + Vector2(0, s * 0.62), s * 0.8, s * 0.12, Color(0, 0, 0, 0.12))
	match type:
		"chicken":
			for sx in [-0.15, 0.15]:
				ci.draw_line(c + Vector2(sx * s, s * 0.35), c + Vector2(sx * s, s * 0.6), Color("e0a030"), 3)
			ellipse(ci, c + Vector2(0, s * 0.1), s * 0.45, s * 0.35, Color.WHITE)
			ellipse(ci, c + Vector2(-s * 0.1, s * 0.12), s * 0.22, s * 0.14, Color("eeeeee"))
			ci.draw_circle(c + Vector2(s * 0.3, -s * 0.25), s * 0.22, Color.WHITE)
			for k in 3:
				ci.draw_circle(c + Vector2(s * (0.22 + k * 0.08), -s * 0.48), s * 0.07, Color("d8433b"))
			poly(ci, [c + Vector2(s * 0.5, -s * 0.28), c + Vector2(s * 0.66, -s * 0.22), c + Vector2(s * 0.5, -s * 0.16)], Color("f2a52c"))
			ci.draw_circle(c + Vector2(s * 0.36, -s * 0.3), s * 0.04, Color("2b1d14"))
			ellipse(ci, c + Vector2(s * 0.46, -s * 0.08), s * 0.05, s * 0.08, Color("d8433b"))
		"cow":
			for sx in [-0.45, -0.2, 0.2, 0.45]:
				rrect(ci, Rect2(c + Vector2(sx * s - s * 0.07, s * 0.2), Vector2(s * 0.14, s * 0.4)), Color("f5f0e8"), 4)
			ellipse(ci, c + Vector2(0, s * 0.05), s * 0.7, s * 0.38, Color("f7f3ea"))
			ellipse(ci, c + Vector2(-s * 0.25, -s * 0.05), s * 0.18, s * 0.14, Color("3a3230"))
			ellipse(ci, c + Vector2(s * 0.2, s * 0.15), s * 0.14, s * 0.1, Color("3a3230"))
			ellipse(ci, c + Vector2(s * 0.62, -s * 0.2), s * 0.26, s * 0.24, Color("f7f3ea"))
			ellipse(ci, c + Vector2(s * 0.7, -s * 0.08), s * 0.2, s * 0.13, Color("f2b7b0"))
			ci.draw_circle(c + Vector2(s * 0.58, -s * 0.28), s * 0.04, Color("2b1d14"))
			ci.draw_line(c + Vector2(s * 0.5, -s * 0.4), c + Vector2(s * 0.44, -s * 0.52), Color("e8dcc0"), 4)
			ci.draw_line(c + Vector2(s * 0.72, -s * 0.4), c + Vector2(s * 0.8, -s * 0.52), Color("e8dcc0"), 4)
		"sheep":
			for sx in [-0.3, 0.3]:
				rrect(ci, Rect2(c + Vector2(sx * s - s * 0.06, s * 0.25), Vector2(s * 0.12, s * 0.35)), Color("4a3b33"), 4)
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_circle(c + Vector2(cos(a) * s * 0.42, sin(a) * s * 0.26 + s * 0.02), s * 0.22, Color("f7f3e6"))
			ellipse(ci, c + Vector2(0, s * 0.02), s * 0.5, s * 0.32, Color("fbf8ee"))
			ellipse(ci, c + Vector2(s * 0.58, -s * 0.12), s * 0.18, s * 0.22, Color("4a3b33"))
			ci.draw_circle(c + Vector2(s * 0.62, -s * 0.18), s * 0.035, Color.WHITE)


# ─────────────────────────────────────────────
# 畑
# ─────────────────────────────────────────────
static func plot(ci: CanvasItem, rect: Rect2, crop: String, growth: int, watered: bool) -> void:
	var soil := Color("6e4b2f") if watered else Color("a5764a")
	rrect(ci, rect.grow(-4), Color("8b5e3c"), 14)
	rrect(ci, rect.grow(-9), soil, 10)
	for k in 3:
		var y := rect.position.y + rect.size.y * (0.3 + k * 0.22)
		ci.draw_line(Vector2(rect.position.x + 16, y), Vector2(rect.end.x - 16, y), soil.darkened(0.18), 3)
	var c := rect.get_center() + Vector2(0, rect.size.y * 0.06)
	var s := rect.size.y * 0.42
	if crop == "":
		return
	var d: Dictionary = GameData.CROPS[crop]
	var days := int(d["days"])
	var r := float(growth) / days
	var leaf := Color("5f9e3b")
	var col := Color(d["color"])
	if r <= 0.0:
		for k in 3:
			ci.draw_circle(c + Vector2((k - 1) * s * 0.3, s * 0.2), s * 0.06, Color("f3e0b0"))
	elif r < 1.0:
		var h := s * (0.3 + 0.5 * r)
		ci.draw_line(c + Vector2(0, s * 0.3), c + Vector2(0, s * 0.3 - h), leaf, 4)
		ellipse(ci, c + Vector2(-s * 0.18, s * 0.3 - h * 0.8), s * 0.2 * (0.6 + r), s * 0.09 * (0.6 + r), leaf)
		ellipse(ci, c + Vector2(s * 0.18, s * 0.3 - h * 0.95), s * 0.2 * (0.6 + r), s * 0.09 * (0.6 + r), leaf.lightened(0.1))
	else:
		match d["kind"]:
			"root":
				for sx in [-0.2, 0.0, 0.2]:
					ellipse(ci, c + Vector2(sx * s, -s * 0.25), s * 0.08, s * 0.3, leaf)
				ellipse(ci, c + Vector2(0, s * 0.18), s * 0.34, s * 0.26, col)
				ellipse_line(ci, c + Vector2(0, s * 0.18), s * 0.34, s * 0.26, col.darkened(0.3), 2)
			"grain":
				for sx in [-0.3, 0.0, 0.3]:
					ci.draw_line(c + Vector2(sx * s, s * 0.4), c + Vector2(sx * s, -s * 0.3), leaf, 4)
					ellipse(ci, c + Vector2(sx * s, -s * 0.4), s * 0.1, s * 0.25, col)
			"flower":
				for sx in [-0.3, 0.0, 0.3]:
					ci.draw_line(c + Vector2(sx * s, s * 0.4), c + Vector2(sx * s, -s * 0.2), leaf, 3)
					for k in 4:
						ci.draw_circle(c + Vector2(sx * s, -s * 0.25 - k * s * 0.12), s * 0.07, col)
			"cotton":
				ci.draw_line(c + Vector2(0, s * 0.4), c + Vector2(0, -s * 0.1), Color("7a5a3a"), 4)
				for p in [Vector2(-0.25, -0.2), Vector2(0.25, -0.15), Vector2(0, -0.4)]:
					ci.draw_circle(c + p * s, s * 0.17, col)
					ellipse_line(ci, c + p * s, s * 0.17, s * 0.17, Color("d9d2bd"), 1.5)
			"big":
				ellipse(ci, c + Vector2(0, s * 0.12), s * 0.5, s * 0.36, col)
				ellipse_line(ci, c + Vector2(0, s * 0.12), s * 0.5, s * 0.36, col.darkened(0.25), 2)
				if crop == "pumpkin":
					for sx in [-0.2, 0.2]:
						ci.draw_line(c + Vector2(sx * s, -s * 0.18), c + Vector2(sx * s, s * 0.42), col.darkened(0.2), 2)
				ci.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(s * 0.06, -s * 0.34), leaf, 5)
			_:
				ellipse(ci, c + Vector2(0, -s * 0.05), s * 0.5, s * 0.35, leaf)
				if crop != "herb":
					for p in [Vector2(-0.25, -0.05), Vector2(0.2, -0.15), Vector2(0.05, 0.15), Vector2(-0.05, -0.3)]:
						ci.draw_circle(c + p * s, s * 0.13, col)
						ci.draw_circle(c + p * s + Vector2(-s * 0.04, -s * 0.04), s * 0.035, Color(1, 1, 1, 0.6))
				else:
					for p in [Vector2(-0.25, -0.2), Vector2(0.25, -0.25), Vector2(0, -0.35)]:
						ellipse(ci, c + p * s, s * 0.12, s * 0.2, leaf.lightened(0.2))
		star(ci, rect.position + Vector2(rect.size.x - 26, 26), 12, Color("ffd84a"))
	if watered:
		var dp := rect.position + Vector2(24, 26)
		ci.draw_circle(dp + Vector2(0, 4), 8, Color("6fb7e8"))
		poly(ci, [dp + Vector2(-7, 2), dp + Vector2(7, 2), dp + Vector2(0, -10)], Color("6fb7e8"))


# ─────────────────────────────────────────────
# アイテムアイコン
# ─────────────────────────────────────────────
static func item_icon(ci: CanvasItem, rect: Rect2, id: String) -> void:
	var c := rect.get_center()
	var s: float = min(rect.size.x, rect.size.y) * 0.5
	var col := GameData.item_color(id)
	if GameData.is_dish(id):
		ellipse(ci, c + Vector2(0, s * 0.25), s * 0.9, s * 0.42, Color.WHITE)
		ellipse_line(ci, c + Vector2(0, s * 0.25), s * 0.9, s * 0.42, Color("d8c8a8"), 2)
		ellipse(ci, c + Vector2(0, s * 0.05), s * 0.58, s * 0.4, col)
		ellipse(ci, c + Vector2(-s * 0.18, -s * 0.08), s * 0.18, s * 0.08, Color(1, 1, 1, 0.45))
		return
	if GameData.is_crop(id):
		var kind: String = GameData.CROPS[id]["kind"]
		if kind == "grain":
			ellipse(ci, c, s * 0.3, s * 0.7, col)
			ci.draw_line(c + Vector2(0, s * 0.6), c + Vector2(0, s * 0.9), Color("5f9e3b"), 3)
			return
		if kind == "flower":
			ci.draw_line(c + Vector2(0, s * 0.9), c + Vector2(0, -s * 0.2), Color("5f9e3b"), 3)
			for k in 5:
				ci.draw_circle(c + Vector2(0, -s * 0.2 - k * s * 0.15), s * 0.16, col)
			return
		ellipse(ci, c + Vector2(0, s * 0.1), s * 0.62, s * 0.55, col)
		ellipse_line(ci, c + Vector2(0, s * 0.1), s * 0.62, s * 0.55, col.darkened(0.3), 2)
		ellipse(ci, c + Vector2(s * 0.12, -s * 0.5), s * 0.25, s * 0.1, Color("5f9e3b"))
		ci.draw_circle(c + Vector2(-s * 0.2, -s * 0.05), s * 0.1, Color(1, 1, 1, 0.5))
		return
	var kind2: String = GameData.ITEMS[id]["kind"] if GameData.ITEMS.has(id) else ""
	match kind2:
		"milk":
			rrect(ci, Rect2(c + Vector2(-s * 0.35, -s * 0.4), Vector2(s * 0.7, s * 1.25)), Color.WHITE, 8)
			rrect(ci, Rect2(c + Vector2(-s * 0.2, -s * 0.8), Vector2(s * 0.4, s * 0.45)), Color.WHITE, 4)
			rrect(ci, Rect2(c + Vector2(-s * 0.24, -s * 0.9), Vector2(s * 0.48, s * 0.18)), col if id == "milk_gold" else Color("6f9fd8"), 3)
			rrect(ci, Rect2(c + Vector2(-s * 0.35, 0), Vector2(s * 0.7, s * 0.3)), Color("6f9fd8") if id == "milk" else col, 0)
		"egg":
			ellipse(ci, c + Vector2(0, s * 0.1), s * 0.5, s * 0.66, col)
			ellipse_line(ci, c + Vector2(0, s * 0.1), s * 0.5, s * 0.66, col.darkened(0.25), 2)
			if id == "egg_gold":
				star(ci, c + Vector2(s * 0.3, -s * 0.4), s * 0.22, Color.WHITE)
		"fluff":
			for p in [Vector2(-0.35, 0.1), Vector2(0.35, 0.1), Vector2(0, -0.25), Vector2(0, 0.3)]:
				ci.draw_circle(c + p * s, s * 0.38, col)
			ellipse_line(ci, c, s * 0.75, s * 0.65, col.darkened(0.15), 1.5)
		"wood":
			rrect(ci, Rect2(c + Vector2(-s * 0.8, -s * 0.35), Vector2(s * 1.4, s * 0.7)), col, 6)
			ellipse(ci, c + Vector2(s * 0.6, 0), s * 0.25, s * 0.35, Color("e2b77a"))
			ellipse_line(ci, c + Vector2(s * 0.6, 0), s * 0.12, s * 0.18, col, 2)
		"dye":
			rrect(ci, Rect2(c + Vector2(-s * 0.45, -s * 0.4), Vector2(s * 0.9, s * 1.15)), Color("f2eadb"), 10)
			rrect(ci, Rect2(c + Vector2(-s * 0.45, 0), Vector2(s * 0.9, s * 0.75)), col, 8)
			rrect(ci, Rect2(c + Vector2(-s * 0.5, -s * 0.62), Vector2(s * 1.0, s * 0.25)), Color("a0703f"), 4)
		_:
			ci.draw_circle(c, s * 0.6, col)


# ─────────────────────────────────────────────
# おうちの中
# ─────────────────────────────────────────────
static func room(ci: CanvasItem, rect: Rect2, furniture: Dictionary, gender: String, outfit: Dictionary, colors: Dictionary) -> void:
	var p := rect.position
	var w := rect.size.x
	var h := rect.size.y
	var floor_y := p.y + h * 0.66
	rrect(ci, rect, Color("e9d3ab"), 16)
	for k in range(1, 12):
		ci.draw_line(Vector2(p.x + w * k / 12.0, p.y + 6), Vector2(p.x + w * k / 12.0, floor_y), Color("dcc295"), 2)
	ci.draw_rect(Rect2(p.x, floor_y, w, h * 0.34 - 6), Color("b5835a"))
	for k in range(1, 4):
		ci.draw_line(Vector2(p.x, floor_y + k * h * 0.085), Vector2(p.x + w, floor_y + k * h * 0.085), Color("9c6c46"), 2)
	ci.draw_rect(Rect2(p.x, floor_y - 6, w, 8), Color("8b5e3c"))
	# 窓
	var win := Rect2(p.x + w * 0.38, p.y + h * 0.1, w * 0.24, h * 0.3)
	rrect(ci, win.grow(6), Color("8b5e3c"), 6)
	ci.draw_rect(win, Color("bfe3f5"))
	ellipse(ci, win.position + Vector2(win.size.x * 0.3, win.size.y * 0.8), win.size.x * 0.4, win.size.y * 0.25, Color("9cd07a"))
	ci.draw_line(win.position + Vector2(win.size.x / 2, 0), win.position + Vector2(win.size.x / 2, win.size.y), Color("8b5e3c"), 4)
	ci.draw_line(win.position + Vector2(0, win.size.y / 2), win.position + Vector2(win.size.x, win.size.y / 2), Color("8b5e3c"), 4)
	for sx in [0, 1]:
		var cr := Rect2(win.position.x - 14 + sx * (win.size.x + 2), win.position.y - 6, 12 + 14 * 0, win.size.y + 16)
		ci.draw_rect(Rect2(cr.position.x - 8, cr.position.y, 20, cr.size.y), Color("c0504d"))
		for k in 6:
			ci.draw_line(Vector2(cr.position.x - 8, cr.position.y + k * cr.size.y / 6), Vector2(cr.position.x + 12, cr.position.y + k * cr.size.y / 6), Color(1, 1, 1, 0.5), 2)
	# ラグ
	if furniture.has("knit_rug"):
		ellipse(ci, Vector2(p.x + w * 0.5, floor_y + h * 0.2), w * 0.3, h * 0.08, Color("c0504d"))
		ellipse(ci, Vector2(p.x + w * 0.5, floor_y + h * 0.2), w * 0.24, h * 0.055, Color("f3e6c8"))
	# ドライフラワー
	if furniture.has("dry_flower"):
		var fp := Vector2(p.x + w * 0.72, p.y + h * 0.12)
		for k in 5:
			ci.draw_line(fp, fp + Vector2((k - 2) * 7, 50), Color("7a8b4a"), 2)
			ci.draw_circle(fp + Vector2((k - 2) * 8, 52), 7, [Color("a58ad8"), Color("e9c46a"), Color("d98c6a")][k % 3])
		ci.draw_line(fp + Vector2(-10, 8), fp + Vector2(10, 8), Color("c0504d"), 4)
	# キルトのベッド
	if furniture.has("quilt"):
		var br := Rect2(p.x + w * 0.66, floor_y - h * 0.12, w * 0.32, h * 0.22)
		rrect(ci, Rect2(br.position.x, br.position.y - h * 0.1, 12, br.size.y + h * 0.1), Color("8b5e3c"), 4)
		rrect(ci, br, Color("8b5e3c"), 6)
		var qc := [Color("c0504d"), Color("f1e0b8"), Color("7d8f3c"), Color("e9c46a")]
		var cs := br.size.x / 6.0
		for i in 6:
			for j in 2:
				ci.draw_rect(Rect2(br.position.x + i * cs, br.position.y + j * br.size.y * 0.35, cs - 2, br.size.y * 0.35 - 2), qc[(i + j) % 4])
	# ストーブ
	if furniture.has("stove"):
		var sr := Rect2(p.x + w * 0.04, floor_y - h * 0.26, w * 0.18, h * 0.3)
		ci.draw_rect(Rect2(sr.position.x + sr.size.x * 0.4, p.y, sr.size.x * 0.2, sr.position.y - p.y), Color("3a3230"))
		rrect(ci, sr, Color("3a3230"), 8)
		rrect(ci, Rect2(sr.position + sr.size * Vector2(0.2, 0.35), sr.size * Vector2(0.6, 0.4)), Color("f2a52c"), 6)
		ellipse(ci, sr.position + sr.size * Vector2(0.5, 0.6), sr.size.x * 0.15, sr.size.y * 0.12, Color("f7e27c"))
	# テーブル
	if furniture.has("wood_table"):
		var tx := p.x + w * 0.2
		ci.draw_rect(Rect2(tx + 10, floor_y - h * 0.02, 10, h * 0.16), Color("8b5e3c"))
		ci.draw_rect(Rect2(tx + w * 0.2 - 20, floor_y - h * 0.02, 10, h * 0.16), Color("8b5e3c"))
		rrect(ci, Rect2(tx, floor_y - h * 0.06, w * 0.2, h * 0.05), Color("a0703f"), 4)
		if furniture.has("candle_lamp"):
			rrect(ci, Rect2(tx + w * 0.08, floor_y - h * 0.13, 16, h * 0.07), Color("f7f0dc"), 3)
			ci.draw_circle(Vector2(tx + w * 0.08 + 8, floor_y - h * 0.15), 16, Color(1, 0.85, 0.4, 0.35))
			ellipse(ci, Vector2(tx + w * 0.08 + 8, floor_y - h * 0.15), 4, 8, Color("f2a52c"))
	elif furniture.has("candle_lamp"):
		ci.draw_circle(Vector2(p.x + w * 0.3, floor_y - 30), 18, Color(1, 0.85, 0.4, 0.35))
		ellipse(ci, Vector2(p.x + w * 0.3, floor_y - 30), 5, 10, Color("f2a52c"))
	# ロッキングチェア
	if furniture.has("rocking_chair"):
		var cx := p.x + w * 0.9
		ci.draw_line(Vector2(cx - 40, floor_y + h * 0.16), Vector2(cx + 30, floor_y + h * 0.16), Color("8b5e3c"), 6)
		ci.draw_rect(Rect2(cx - 30, floor_y + h * 0.04, 50, 10), Color("a0703f"))
		ci.draw_rect(Rect2(cx + 12, floor_y - h * 0.12, 10, h * 0.18), Color("a0703f"))
		ci.draw_rect(Rect2(cx - 28, floor_y + h * 0.05, 8, h * 0.1), Color("8b5e3c"))
	# 主人公
	var ph := h * 0.62
	player(ci, Rect2(p.x + w * 0.5 - ph * 0.25, floor_y + h * 0.3 - ph, ph * 0.5, ph), gender, outfit, colors)
