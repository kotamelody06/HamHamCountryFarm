extends Control
## メイン画面：ヘッダー・タブ・ポップアップ・タイトル画面をすべてコードで構築します。
## 縦画面（720x1280基準）・タッチ操作向け。

const COL_BG := Color("f6ecd6")
const COL_TEXT := Color("4a3423")
const COL_SUB := Color("8a6d52")
const COL_WOOD := Color("8b5e3c")
const COL_WOOD_D := Color("6b4428")
const COL_CARD := Color("fffaf0")
const COL_BORDER := Color("dcc19b")
const COL_GREEN := Color("6f9e4c")
const COL_RED := Color("c0504d")
const COL_CREAM := Color("fff8e8")
const COL_GOLD := Color("ffe08a")
const COL_DISABLED := Color("cdbfa9")

const TABS := [
	["farm", "畑"], ["ranch", "牧場"], ["kitchen", "料理"], ["storage", "倉庫"], ["ship", "出荷"],
	["bazaar", "バザー"], ["craft", "工房"], ["home", "おうち"], ["village", "村"], ["hamster", "ハムスター"],
]
const COPYRIGHT := "🄫NekoDaifuku Software"
const TITLE_LOGO := preload("res://ui/title_logo.svg")
const FARM_ICON := preload("res://ui/farm_level_icon.svg")
const FARM_BG := preload("res://ui/farm_level_bg.svg")
const ICON_WATER_ALL := preload("res://ui/icon_water_all.svg")
const ICON_HARVEST_ALL := preload("res://ui/icon_harvest_all.svg")
const ICON_CHOP_WOOD := preload("res://ui/icon_chop_wood.svg")
const ICON_SEEDS := preload("res://ui/icon_seeds.svg")
const ICON_FIELD := preload("res://ui/icon_field.svg")
var _crop_icons := {}
const BAZAAR_GOODS := [["wood", 10, 150], ["dye", 1, 180], ["egg", 3, 120], ["milk", 2, 150]]

var font_regular: Font
var font_bold: Font
var header_date: Label
var header_gold: Label
var header_bar: ProgressBar
var header_stamina: Label
var scroll: ScrollContainer
var content: VBoxContainer
var tab_buttons := {}
var current_tab := "farm"
var overlay: Control
var toast_panel: PanelContainer
var toast_label: Label
var toast_lines: Array = []
var toast_time := 0.0
var title_layer: Control = null

var popup_layer: Control = null
var popup_scroll: ScrollContainer = null
var popup_box: VBoxContainer = null
var popup_title: Label = null
var popup_builder: Callable = Callable()
var popup_on_close: Callable = Callable()

var _refresh_queued := false
var _pressing := false
var _drag_moved := false
var _press_pos := Vector2.ZERO
var _drag_scroll: ScrollContainer = null
var _drag_start := 0
var _last_y := 0.0
var _last_t := 0
var _fling := 0.0
var _fling_scroll: ScrollContainer = null

var _event_result := ""
var _event_shown_key := ""
var _egg_cells: Array = []
var _egg_open: Array = []
var _egg_tries := 0
var _new_gender := "boy"
var _name_edit: LineEdit = null
var _title_bgm_btn: Button = null
var sleep_btn: Button
var badge_nodes := {}
var badges_on := true
var _sleep_glow: Tween
var helper_layer: Control = null
var splash_layer: Control = null
var _splash_tween: Tween
const SPLASH_LOGO := preload("res://ui/splash_logo.png")
const SPLASH_FADE_IN := 0.9
const SPLASH_HOLD := 1.6
const SPLASH_FADE_OUT := 0.8
const HELPER_IDLE_SEC := 60.0  ## この秒数さわらないと、おすすめハムスターが出てくる
var helper_on := true
var _idle := 0.0
const BADGE_COLORS := {"red": Color("d64840"), "gold": Color("f2b228"), "orange": Color("e88028"), "green": Color("62a040"), "new": Color("e2608c")}


# ═════════════════════════════════════════════════════
# 起動
# ═════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	theme = _make_theme()
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	_build_layout()
	Game.changed.connect(_queue_refresh)
	Game.toast.connect(_show_toast)
	Game.sfx.connect(Sfx.play)
	_show_splash()


func _make_theme() -> Theme:
	var t := Theme.new()
	var ff = load("res://fonts/NotoSansJP-Medium-subset.otf")
	if ff is Font:
		font_regular = ff
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Noto Sans CJK JP", "Noto Sans JP", "Hiragino Sans", "Yu Gothic", "sans-serif"])
		font_regular = sf
	var fb := FontVariation.new()
	fb.base_font = font_regular
	fb.variation_embolden = 0.7
	font_bold = fb
	t.default_font = font_regular
	t.default_font_size = 26
	t.set_color("font_color", "Label", COL_TEXT)
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "Button", _btn_style(COL_WOOD, st))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", COL_CREAM)
	t.set_color("font_disabled_color", "Button", Color("8f7f6a"))
	t.set_stylebox("panel", "PanelContainer", _sb(COL_CARD, COL_BORDER, 3, 18, 16))
	t.set_stylebox("background", "ProgressBar", _sb(Color("eadcc2"), Color.TRANSPARENT, 0, 10, 0))
	t.set_stylebox("fill", "ProgressBar", _sb(COL_GREEN, Color.TRANSPARENT, 0, 10, 0))
	t.set_stylebox("normal", "LineEdit", _sb(Color.WHITE, COL_WOOD, 3, 12, 12))
	t.set_stylebox("focus", "LineEdit", _sb(Color.WHITE, COL_GREEN, 3, 12, 12))
	t.set_color("font_color", "LineEdit", COL_TEXT)
	t.set_color("font_placeholder_color", "LineEdit", COL_SUB)
	var grab := _sb(Color(0.55, 0.37, 0.24, 0.45), Color.TRANSPARENT, 0, 6, 0)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0, 0, 0, 0)
	sbg.content_margin_left = 6
	t.set_stylebox("scroll", "VScrollBar", sbg)
	return t


func _sb(bg: Color, border: Color, bw := 0, radius := 14, pad := 10, bottom := -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	if bottom >= 0:
		s.border_width_bottom = bottom
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.anti_aliasing = true
	return s


func _btn_style(col: Color, state: String) -> StyleBoxFlat:
	match state:
		"hover":
			return _sb(col.lightened(0.08), col.darkened(0.3), 0, 16, 10, 5)
		"pressed":
			var s := _sb(col.darkened(0.12), col.darkened(0.3), 0, 16, 10, 1)
			s.content_margin_top = 14
			return s
		"disabled":
			return _sb(COL_DISABLED, COL_DISABLED.darkened(0.15), 0, 16, 10, 5)
	return _sb(col, col.darkened(0.3), 0, 16, 10, 5)


# ═════════════════════════════════════════════════════
# 画面の骨組み
# ═════════════════════════════════════════════════════
func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	var deco := DrawBox.new(_paint_bg_pattern, Vector2.ZERO)
	deco.set_anchors_preset(PRESET_FULL_RECT)
	add_child(deco)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	var top_pad := 10 + _safe_top()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", top_pad)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	# ヘッダー
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", _sb(COL_WOOD, COL_WOOD_D, 0, 18, 12, 6))
	v.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	head.add_child(hv)
	var r1 := HBoxContainer.new()
	hv.add_child(r1)
	header_date = _label("", 25, COL_CREAM, false)
	header_date.size_flags_horizontal = SIZE_EXPAND_FILL
	r1.add_child(header_date)
	header_gold = _label("", 28, COL_GOLD, false)
	header_gold.add_theme_font_override("font", font_bold)
	r1.add_child(header_gold)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 10)
	hv.add_child(r2)
	r2.add_child(_label("体力", 22, COL_CREAM, false))
	header_bar = ProgressBar.new()
	header_bar.show_percentage = false
	header_bar.custom_minimum_size = Vector2(100, 24)
	header_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	header_bar.size_flags_vertical = SIZE_SHRINK_CENTER
	header_bar.add_theme_stylebox_override("fill", _sb(Color("f2c94c"), Color.TRANSPARENT, 0, 10, 0))
	header_bar.add_theme_stylebox_override("background", _sb(COL_WOOD_D, Color.TRANSPARENT, 0, 10, 0))
	r2.add_child(header_bar)
	header_stamina = _label("", 22, COL_CREAM, false)
	r2.add_child(header_stamina)
	sleep_btn = _button("おやすみ", _on_sleep_pressed, true, Color("5d7f3f"), 22)
	sleep_btn.custom_minimum_size = Vector2(130, 56)
	r2.add_child(sleep_btn)

	# 本文
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	# タブ
	var tabs := GridContainer.new()
	tabs.columns = 5
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	v.add_child(tabs)
	for t in TABS:
		var b := _button(t[1], _switch_tab.bind(t[0]), true, COL_WOOD, 21 if t[0] == "hamster" else 23)
		b.custom_minimum_size = Vector2(0, 66)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		tabs.add_child(b)
		tab_buttons[t[0]] = b
		badge_nodes[t[0]] = _make_badge(b)
	badges_on = bool(Sfx.get_setting("ui", "badges", true))
	helper_on = bool(Sfx.get_setting("ui", "helper", true))

	# 最前面レイヤー（ポップアップ・トースト）
	overlay = Control.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)
	toast_panel = PanelContainer.new()
	toast_panel.add_theme_stylebox_override("panel", _sb(Color(0.29, 0.2, 0.14, 0.92), Color.TRANSPARENT, 0, 20, 16))
	toast_panel.mouse_filter = MOUSE_FILTER_IGNORE
	toast_panel.anchor_left = 0.04
	toast_panel.anchor_right = 0.96
	toast_panel.anchor_top = 1.0
	toast_panel.anchor_bottom = 1.0
	toast_panel.offset_top = -330
	toast_panel.offset_bottom = -170
	toast_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_panel.visible = false
	add_child(toast_panel)
	toast_label = _label("", 23, COL_CREAM)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)


func _safe_top() -> int:
	if not OS.has_feature("mobile"):
		return 0
	var sa := DisplayServer.get_display_safe_area()
	var ws := DisplayServer.window_get_size()
	if ws.y <= 0:
		return 0
	return int(sa.position.y * get_viewport_rect().size.y / ws.y)


func _paint_bg_pattern(ci: CanvasItem) -> void:
	var s: Vector2 = ci.size
	var col := Color(0.55, 0.37, 0.24, 0.05)
	var step := 48.0
	var x := 0.0
	while x < s.x:
		ci.draw_line(Vector2(x, 0), Vector2(x, s.y), col, 10)
		x += step
	var y := 0.0
	while y < s.y:
		ci.draw_line(Vector2(0, y), Vector2(s.x, y), col, 10)
		y += step


# ═════════════════════════════════════════════════════
# UI 部品
# ═════════════════════════════════════════════════════
func _label(t: String, size := 26, col := COL_TEXT, wrap := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = SIZE_EXPAND_FILL
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l


func _title(t: String, size := 30, col := COL_WOOD) -> Label:
	var l := _label(t, size, col)
	l.add_theme_font_override("font", font_bold)
	return l


func _button(t: String, cb: Callable, enabled := true, col := COL_WOOD, size := 24) -> Button:
	var b := Button.new()
	b.text = t
	b.disabled = not enabled
	b.focus_mode = FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", size)
	if col != COL_WOOD:
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, _btn_style(col, st))
	b.pressed.connect(_guard.bind(cb))
	return b


func _small_button(t: String, cb: Callable, enabled := true, col := COL_WOOD) -> Button:
	var b := _button(t, cb, enabled, col, 22)
	b.custom_minimum_size = Vector2(96, 60)
	return b


func _guard(cb: Callable) -> void:
	if _drag_moved:
		return
	var before := Sfx.play_count
	cb.call()
	if Sfx.play_count == before:
		Sfx.play("tap")  # 木をやさしく叩く「コッ」


func _card(parent: Control, bg := COL_CARD) -> VBoxContainer:
	var p := PanelContainer.new()
	if bg != COL_CARD:
		p.add_theme_stylebox_override("panel", _sb(bg, COL_BORDER, 3, 18, 16))
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	return v


## 画像を背景にしたカード（背景は枠いっぱいに引き伸ばし）
func _card_bg(parent: Control, tex: Texture2D) -> VBoxContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_content_margin_all(16)
	sb.content_margin_bottom = 20
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	return v


func _tex_icon(tex: Texture2D, s := 60) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(s, s)
	t.size_flags_vertical = SIZE_SHRINK_CENTER
	t.mouse_filter = MOUSE_FILTER_IGNORE
	return t


## アイコン付きの見出し
func _icon_title(parent: Control, tex: Texture2D, text: String, size := 26) -> void:
	var r := _hbox(parent, 8)
	r.add_child(_tex_icon(tex, 52))
	var t := _title(text, size)
	t.size_flags_vertical = SIZE_SHRINK_CENTER
	r.add_child(t)


## 作物アイコン（ui/crop_<ID>.svg）
func _crop_icon(id: String) -> Texture2D:
	if not _crop_icons.has(id):
		var path := "res://ui/crop_%s.svg" % id
		_crop_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _crop_icons[id]


func _hbox(parent: Control, sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	parent.add_child(h)
	return h


func _vbox(parent: Control, sep := 4) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(v)
	return v


func _icon(id: String, s := 60) -> DrawBox:
	var db := DrawBox.new(func(ci): Art.item_icon(ci, Rect2(Vector2.ZERO, ci.size), id), Vector2(s, s))
	db.size_flags_vertical = SIZE_SHRINK_CENTER
	return db


func _bar(val: float, maxv: float, col := COL_GREEN) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = max(1.0, maxv)
	b.value = val
	b.show_percentage = false
	b.custom_minimum_size = Vector2(120, 20)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.size_flags_vertical = SIZE_SHRINK_CENTER
	if col != COL_GREEN:
		b.add_theme_stylebox_override("fill", _sb(col, Color.TRANSPARENT, 0, 10, 0))
	return b


func _sep(parent: Control) -> void:
	var s := ColorRect.new()
	s.color = Color(COL_BORDER, 0.7)
	s.custom_minimum_size = Vector2(0, 2)
	s.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(s)


func _stars(k: int, n := 3) -> String:
	return "★".repeat(k) + "☆".repeat(n - k)


func _mats_text(mats: Dictionary) -> Array:
	var parts: Array = []
	var ok := true
	for k in mats:
		var have := Game.count(k)
		parts.append("%s %d/%d" % [GameData.item_name(k), have, int(mats[k])])
		if have < int(mats[k]):
			ok = false
	return ["・".join(parts), ok]


func _cloth_colors() -> Dictionary:
	return {"straw_hat": Game.cloth_color("straw_hat"), "apron": Game.cloth_color("apron"), "knit": Game.cloth_color("knit")}


# ═════════════════════════════════════════════════════
# 入力（タッチスクロール・慣性・戻るボタン）
# ═════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	# さわったら放置タイマーをリセット
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey \
			or event is InputEventScreenDrag or (event is InputEventMouseMotion and event.button_mask != 0):
		_idle = 0.0
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_drag_moved = false
				_fling = 0.0
				_press_pos = mb.position
				_drag_scroll = _scroll_at(mb.position)
				_drag_start = _drag_scroll.scroll_vertical if _drag_scroll else 0
				_last_y = mb.position.y
				_last_t = Time.get_ticks_msec()
			else:
				_pressing = false
				if _drag_moved and _drag_scroll and Time.get_ticks_msec() - _last_t < 90:
					_fling_scroll = _drag_scroll
				else:
					_fling = 0.0
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var sc := _scroll_at(mb.position)
			if sc:
				sc.scroll_vertical += -90 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 90
	elif event is InputEventMouseMotion and _pressing and _drag_scroll:
		var mm := event as InputEventMouseMotion
		var dy := mm.position.y - _press_pos.y
		if not _drag_moved and absf(dy) > 16:
			_drag_moved = true
		if _drag_moved:
			_drag_scroll.scroll_vertical = int(_drag_start - dy)
			var now := Time.get_ticks_msec()
			var dt: float = max(1, now - _last_t) / 1000.0
			_fling = lerp(_fling, -(mm.position.y - _last_y) / dt, 0.5)
			_last_y = mm.position.y
			_last_t = now


func _process(delta: float) -> void:
	_tick_idle(delta)
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_panel.visible = false
			toast_lines.clear()
		elif toast_time < 0.3:
			toast_panel.modulate.a = toast_time / 0.3
	if not _pressing and _fling_scroll and absf(_fling) > 30.0:
		if is_instance_valid(_fling_scroll):
			_fling_scroll.scroll_vertical += int(_fling * delta)
		_fling *= pow(0.04, delta)
	elif not _pressing:
		_fling = 0.0


func _scroll_at(pos: Vector2) -> ScrollContainer:
	if popup_layer != null:
		if popup_scroll and popup_scroll.get_global_rect().has_point(pos):
			return popup_scroll
		return null
	if title_layer != null:
		return null
	if scroll.get_global_rect().has_point(pos):
		return scroll
	return null


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_idle = 0.0
			if splash_layer != null:
				_skip_splash()
			elif helper_layer != null:
				_hide_helper("")
			elif popup_layer != null:
				close_popup()
			elif title_layer != null:
				get_tree().quit()
			elif current_tab != "farm":
				_switch_tab("farm")
			else:
				_confirm_quit()
		NOTIFICATION_WM_CLOSE_REQUEST:
			Game.save_game()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			Game.save_game()


func _confirm_quit() -> void:
	open_popup("ゲームを終了しますか？", func(v: VBoxContainer):
		v.add_child(_label("セーブしてから終了します。"))
		var r := _hbox(v)
		var b1 := _button("終了する", func():
			Game.save_game()
			get_tree().quit(), true, COL_RED)
		b1.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(b1)
		var b2 := _button("もどる", close_popup)
		b2.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(b2))


# ═════════════════════════════════════════════════════
# トースト
# ═════════════════════════════════════════════════════
func _show_toast(msg: String) -> void:
	toast_lines.append(msg)
	while toast_lines.size() > 3:
		toast_lines.pop_front()
	toast_label.text = "\n".join(toast_lines)
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	toast_time = 2.6


# ═════════════════════════════════════════════════════
# 再描画
# ═════════════════════════════════════════════════════
func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false
	if not Game.started:
		return
	Game.mark_seen(current_tab)  # 今見ているタブの NEW は出さない
	_update_header()
	_rebuild_tab(false)
	if popup_layer != null and popup_builder.is_valid():
		_fill_popup(true)


func _update_header() -> void:
	var w: String = GameData.WEATHER_NAMES.get(Game.weather, "")
	header_date.text = "%d年目 %sの月 %d日・%s" % [Game.year, Game.season_name(), Game.day, w]
	header_gold.text = "%s G" % _fmt(Game.gold)
	header_bar.max_value = Game.max_stamina()
	header_bar.value = Game.stamina
	header_stamina.text = "%d/%d" % [Game.stamina, Game.max_stamina()]
	var badges := Game.tab_badges() if badges_on else {}
	for t in TABS:
		var b: Button = tab_buttons[t[0]]
		var label: String = t[1]
		# バッジをオフにしているときだけ、文字の★で最低限お知らせ
		if not badges_on and t[0] == "bazaar" and Game.is_bazaar_day():
			label = "バザー★"
		if not badges_on and t[0] == "village" and Game.event_today() != "":
			label = "村★"
		_set_badge(t[0], badges.get(t[0], {}))
		b.text = label
		var col := COL_GREEN if t[0] == current_tab else COL_WOOD
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, _btn_style(col, st))
	_update_sleep_glow()


# ═════════════════════════════════════════════════════
# タブのバッジ
# ═════════════════════════════════════════════════════
func _make_badge(btn: Button) -> Dictionary:
	var p := PanelContainer.new()
	p.mouse_filter = MOUSE_FILTER_IGNORE
	p.set_anchors_preset(PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.offset_left = 8
	p.offset_right = 8
	p.offset_top = -14
	p.offset_bottom = -14
	p.custom_minimum_size = Vector2(36, 36)
	p.visible = false
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_bold)
	l.add_theme_font_size_override("font_size", 19)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.resized.connect(func(): p.pivot_offset = p.size / 2.0)
	btn.add_child(p)
	return {"panel": p, "label": l, "kind": "", "text": "", "tween": null}


func _set_badge(tab: String, info: Dictionary) -> void:
	var bd: Dictionary = badge_nodes[tab]
	var p: PanelContainer = bd["panel"]
	var kind: String = info.get("kind", "")
	var text: String = info.get("text", "")
	if kind == bd["kind"] and text == bd["text"]:
		return
	bd["kind"] = kind
	bd["text"] = text
	if bd["tween"] and bd["tween"].is_valid():
		bd["tween"].kill()
	p.scale = Vector2.ONE
	if kind == "":
		p.visible = false
		return
	var col: Color = BADGE_COLORS[kind]
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(3)
	sb.shadow_color = Color(COL_WOOD_D, 0.9)
	sb.shadow_size = 2
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	var l: Label = bd["label"]
	l.text = text
	l.add_theme_color_override("font_outline_color", col.darkened(0.35))
	p.visible = true
	# ★ と NEW だけ、ゆっくりぷくっと弾ませる
	if kind == "gold" or kind == "new":
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "scale", Vector2(1.18, 1.18), 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_property(p, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(1.1)
		bd["tween"] = tw


func _toggle_badges() -> void:
	badges_on = not badges_on
	Sfx.set_setting("ui", "badges", badges_on)
	_update_header()
	_rebuild_tab(false)


## やり残しゼロで「おやすみ」ボタンがほんのり光る
func _update_sleep_glow() -> void:
	var done := Game.started and Game.todo_list().is_empty()
	var glowing := _sleep_glow != null and _sleep_glow.is_valid()
	if done == glowing:
		return
	if done:
		sleep_btn.text = "おやすみ ✓"
		_sleep_glow = sleep_btn.create_tween().set_loops()
		_sleep_glow.tween_property(sleep_btn, "modulate", Color(1.45, 1.45, 1.2), 0.9).set_trans(Tween.TRANS_SINE)
		_sleep_glow.tween_property(sleep_btn, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
	else:
		_sleep_glow.kill()
		_sleep_glow = null
		sleep_btn.modulate = Color.WHITE
		sleep_btn.text = "おやすみ"


func _fmt(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _switch_tab(t: String) -> void:
	Sfx.play("page")  # 画用紙をめくる「サクッ」
	if t == "hamster":
		Sfx.play("steps", 0.12)
	current_tab = t
	Game.mark_seen(t)
	_update_header()
	_rebuild_tab(true)


func _rebuild_tab(reset_scroll: bool) -> void:
	var sv := 0 if reset_scroll else scroll.scroll_vertical
	for ch in content.get_children():
		content.remove_child(ch)
		ch.queue_free()
	match current_tab:
		"farm": _build_farm(content)
		"ranch": _build_ranch(content)
		"kitchen": _build_kitchen(content)
		"storage": _build_storage(content)
		"ship": _build_ship(content)
		"bazaar": _build_bazaar(content)
		"craft": _build_craft(content)
		"home": _build_home(content)
		"village": _build_village(content)
		"hamster": _build_hamster(content)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	content.add_child(spacer)
	_restore_scroll(scroll, sv)


func _restore_scroll(sc: ScrollContainer, v: int) -> void:
	sc.scroll_vertical = v
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_vertical = v


# ═════════════════════════════════════════════════════
# 畑
# ═════════════════════════════════════════════════════
func _build_farm(c: Control) -> void:
	var top := _card_bg(c, FARM_BG)
	var r := _hbox(top, 10)
	r.add_child(_tex_icon(FARM_ICON, 64))
	var lv := _title("農業レベル %d" % Game.farm_level, 28)
	lv.size_flags_horizontal = SIZE_FILL
	lv.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_child(lv)
	var p := Game.farm_xp_progress()
	r.add_child(_bar(p[0], p[1]))
	var wtext := ""
	if Game.weather == "rain":
		wtext = "今日は雨。畑は水やりいらず！"
	elif Game.hamsters.has("golden"):
		wtext = "きなこ（ゴールデン）が毎朝まとめて水やりしてくれます。"
	else:
		wtext = "空いた畑をタップで種まき、もう一度タップで水やり。"
	top.add_child(_label(wtext, 21, Color("5e4430")))
	var br := _hbox(top, 8)
	for spec in [["まとめて水やり", Game.water_all, ICON_WATER_ALL], ["まとめて収穫", Game.harvest_all, ICON_HARVEST_ALL], ["森で木を切る", Game.chop_wood, ICON_CHOP_WOOD]]:
		var b := _button(spec[0], spec[1], true, COL_WOOD, 20)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.icon = spec[2]
		b.add_theme_constant_override("icon_max_width", 46)
		b.add_theme_constant_override("h_separation", 6)
		b.custom_minimum_size.y = 66
		br.add_child(b)

	# 種
	var sc := _card(c)
	_icon_title(sc, ICON_SEEDS, "たねを選ぶ（%sの作物）" % Game.season_name())
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	sc.add_child(g)
	for id in GameData.CROPS:
		if not Game.crop_in_season(id):
			continue
		var d: Dictionary = GameData.CROPS[id]
		var unlocked := Game.crop_unlocked(id)
		var t := "%s\n%dG・%d日" % [d["name"], d["seed"], d["days"]] if unlocked else "%s\nLv%dで解放" % [d["name"], d["lv"]]
		var col := COL_GREEN if id == Game.selected_seed else COL_WOOD
		var b := _button(t, Game.select_seed.bind(id), unlocked, col, 20)
		b.custom_minimum_size = Vector2(0, 86)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.icon = _crop_icon(id)
		b.add_theme_constant_override("icon_max_width", 50)
		b.add_theme_constant_override("h_separation", 4)
		g.add_child(b)

	# 畑
	var pc := _card(c, Color("f3e3c3"))
	_icon_title(pc, ICON_FIELD, "はたけ（%dマス）" % Game.plot_count())
	var pg := GridContainer.new()
	pg.columns = 3
	pg.add_theme_constant_override("h_separation", 8)
	pg.add_theme_constant_override("v_separation", 10)
	pc.add_child(pg)
	for i in Game.plot_count():
		var pl: Dictionary = Game.plots[i]
		var cell := _vbox(pg, 2)
		var b := Button.new()
		b.focus_mode = FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 170)
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		b.pressed.connect(_guard.bind(Game.tap_plot.bind(i)))
		var crop: String = pl["crop"]
		var growth := int(pl["growth"])
		var watered := bool(pl["watered"])
		var db := DrawBox.new(func(ci): Art.plot(ci, Rect2(Vector2.ZERO, ci.size), crop, growth, watered), Vector2.ZERO)
		db.set_anchors_preset(PRESET_FULL_RECT)
		b.add_child(db)
		cell.add_child(b)
		var st := "空き・タップで植える"
		var stc := COL_SUB
		if crop != "":
			var cd: Dictionary = GameData.CROPS[crop]
			if Game.is_ripe(i):
				st = "%s 収穫OK！" % cd["name"]
				stc = COL_GREEN
			else:
				st = "%s あと%d日%s" % [cd["name"], int(cd["days"]) - growth, "" if watered else "・水やり"]
				if not watered:
					stc = COL_RED
		var l := _label(st, 18, stc)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(l)


# ═════════════════════════════════════════════════════
# 牧場
# ═════════════════════════════════════════════════════
func _build_ranch(c: Control) -> void:
	var top := _card(c)
	top.add_child(_title("のんびり牧場"))
	top.add_child(_label("毎日お世話（体力%d）すると、翌朝ミルク・たまご・ウールがとれます。ご機嫌が高いほど特選品に！" % Game.COST_CARE, 21, COL_SUB))
	if Game.hamsters.has("kinkuma"):
		top.add_child(_label("キンクマのくるみが、動物たちのご機嫌をなだめてくれています。", 21, COL_GREEN))
	top.add_child(_button("みんなをお世話する", Game.care_all, true, COL_GREEN))

	for i in Game.animals.size():
		var a: Dictionary = Game.animals[i]
		var d: Dictionary = GameData.ANIMALS[a["type"]]
		var card := _card(c)
		var r := _hbox(card)
		var atype: String = a["type"]
		var pic := DrawBox.new(func(ci): Art.animal(ci, ci.size / 2.0 + Vector2(-6, -4), ci.size.y * 0.5, atype), Vector2(130, 110))
		r.add_child(pic)
		var info := _vbox(r)
		info.add_child(_label("%s（%s）" % [a["name"], d["name"]], 25, COL_TEXT))
		info.add_child(_label("ごきげん %s" % _stars(int(ceil(int(a["mood"]) / 2.0)), 5), 21, Color("d9822b")))
		var prod := GameData.item_name(d["product"])
		var every := int(d["every"])
		var ptxt := "とれるもの：%s（毎日）" % prod if every == 1 else "とれるもの：%s（%d日ごと・あと%d日）" % [prod, every, every - int(a["timer"])]
		info.add_child(_label(ptxt, 19, COL_SUB))
		var fed: bool = a["fed"]
		var b := _small_button("お世話ずみ" if fed else "お世話", Game.care.bind(i), not fed, COL_GREEN)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		r.add_child(b)

	var shop := _card(c)
	shop.add_child(_title("動物をむかえる（%d/%d）" % [Game.animals.size(), Game.MAX_ANIMALS], 26))
	for t in GameData.ANIMALS:
		var d: Dictionary = GameData.ANIMALS[t]
		var r := _hbox(shop)
		var tt: String = t
		r.add_child(DrawBox.new(func(ci): Art.animal(ci, ci.size / 2.0, ci.size.y * 0.42, tt), Vector2(90, 76)))
		r.add_child(_label("%s\n%s がとれる" % [d["name"], GameData.item_name(d["product"])], 22))
		r.add_child(_small_button("%dG" % d["price"], Game.buy_animal.bind(t), Game.gold >= int(d["price"]) and Game.animals.size() < Game.MAX_ANIMALS))


# ═════════════════════════════════════════════════════
# キッチン
# ═════════════════════════════════════════════════════
func _build_kitchen(c: Control) -> void:
	var top := _card(c)
	top.add_child(_title("カントリーキッチン"))
	top.add_child(_label("料理1回の体力：%d　レシピ %d/%d" % [Game.cook_cost(), Game.known_recipes.size(), GameData.RECIPES.size()], 22, COL_SUB))
	top.add_child(_label("同じ料理を作るほど熟練度ランクUP（★1→★2→★3マスター）。ランクが高いほど品質・売値が大幅UP！", 20, COL_SUB))
	if Game.hamsters.has("jungarian"):
		top.add_child(_label("ジャンガリアンのゴマがお手伝い中（体力軽減・熟練度UP補助）", 20, COL_GREEN))

	var list: Array = Game.known_recipes.duplicate()
	list.sort_custom(func(a, b):
		var ea := Game.cook_error(a) == ""
		var eb := Game.cook_error(b) == ""
		if ea != eb:
			return ea
		return GameData.base_price(a) < GameData.base_price(b))
	for r in list:
		var d: Dictionary = GameData.RECIPES[r]
		var card := _card(c)
		var row := _hbox(card)
		row.add_child(_icon(r, 68))
		var info := _vbox(row)
		var k := Game.rank(r)
		var name_l := _label("%s  %s" % [d["name"], _stars(k + 1)], 25)
		name_l.add_theme_font_override("font", font_bold)
		info.add_child(name_l)
		var mt := _mats_text(d["ing"])
		info.add_child(_label(mt[0], 20, COL_SUB if mt[1] else COL_RED))
		var pr := Game.rank_progress(r)
		var rank_t := "マスター！" if k == 2 else "次のランクまで %d/%d回" % [pr[0], pr[1]]
		info.add_child(_label("売値 %dG・%s" % [Game.item_value(r), rank_t], 19, Color("a0703f")))
		var err := Game.cook_error(r)
		var b := _small_button("作る", Game.cook.bind(r), err == "", COL_GREEN)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(b)

	var unk := _card(c, Color("f3e9d6"))
	unk.add_child(_title("まだ知らないレシピ", 24, COL_SUB))
	var n := 0
	for r in GameData.RECIPES:
		if r in Game.known_recipes:
			continue
		n += 1
		unk.add_child(_label("？？？ ─ 入手：%s" % GameData.recipe_source(r), 20, COL_SUB))
	if n == 0:
		unk.add_child(_label("すべてのレシピを集めました！ すごい！", 22, COL_GREEN))


# ═════════════════════════════════════════════════════
# 倉庫
# ═════════════════════════════════════════════════════
func _build_storage(c: Control) -> void:
	var st := Game.storage_info()
	var top := _card(c)
	top.add_child(_title("倉庫：%s" % st["name"]))
	top.add_child(_label("使用 %d/%d種類・1種類あたり最大%d個" % [Game.slots_used(), st["slots"], st["stack"]], 22, COL_SUB))
	top.add_child(_bar(Game.slots_used(), st["slots"], Color("d9a55c")))
	if Game.storage_level < GameData.STORAGE.size() - 1:
		var nx: Dictionary = GameData.STORAGE[Game.storage_level + 1]
		top.add_child(_label("次：%s（%d種類・最大%d個）" % [nx["name"], nx["slots"], nx["stack"]], 21))
		var ok := Game.gold >= int(nx["cost"]) and Game.count("wood") >= int(nx["wood"])
		top.add_child(_button("広げる（%sG・木材%d）" % [_fmt(nx["cost"]), nx["wood"]], Game.upgrade_storage, ok, COL_GREEN))
	else:
		top.add_child(_label("最大まで広げました！", 22, COL_GREEN))

	var items := _card(c)
	items.add_child(_title("なかみ", 26))
	if Game.inventory.is_empty():
		items.add_child(_label("からっぽです。畑で収穫しよう！", 22, COL_SUB))
	for id in Game.sorted_inventory():
		var r := _hbox(items)
		r.add_child(_icon(id, 54))
		var name_t: String = GameData.item_name(id)
		if GameData.is_dish(id):
			name_t += " " + _stars(Game.rank(id) + 1)
		r.add_child(_label("%s\n×%d　（%dG）" % [name_t, Game.count(id), Game.item_value(id)], 21))
		if GameData.is_dish(id):
			r.add_child(_small_button("食べる", Game.eat.bind(id), Game.stamina < Game.max_stamina()))


# ═════════════════════════════════════════════════════
# 出荷（変動相場）
# ═════════════════════════════════════════════════════
func _build_ship(c: Control) -> void:
	var top := _card(c)
	top.add_child(_title("出荷箱（毎日の変動相場）"))
	top.add_child(_label("売りすぎた品は値下がり、しばらく出荷していない品は値上がりします。本当の稼ぎどきは2週間に1度のバザー！", 20, COL_SUB))
	if Game.hot_item != "":
		top.add_child(_label("今日の注目：%s（いつもより高値！）" % GameData.item_name(Game.hot_item), 22, COL_RED))
	if Game.inventory.is_empty():
		top.add_child(_label("出荷できるものがありません。", 22, COL_SUB))
		return
	var list := _card(c)
	for id in Game.sorted_inventory():
		var r := _hbox(list, 8)
		r.add_child(_icon(id, 50))
		var tr := Game.market_trend(id)
		var arrow := "↑高値" if tr > 0 else ("↓安値" if tr < 0 else "→ふつう")
		var info := _vbox(r, 0)
		info.add_child(_label("%s ×%d" % [GameData.item_name(id), Game.count(id)], 21))
		info.add_child(_label("%dG %s" % [Game.market_price(id), arrow], 20, COL_RED if tr > 0 else (Color("4d6fa3") if tr < 0 else COL_SUB)))
		var b1 := _small_button("1個", Game.sell.bind(id, 1))
		b1.custom_minimum_size.x = 80
		r.add_child(b1)
		r.add_child(_small_button("全部", Game.sell.bind(id, Game.count(id)), true, COL_GREEN))


# ═════════════════════════════════════════════════════
# バザー
# ═════════════════════════════════════════════════════
func _build_bazaar(c: Control) -> void:
	if not Game.is_bazaar_day():
		var top := _card(c)
		top.add_child(_title("次のバザーまで あと%d日" % Game.days_to_bazaar()))
		top.add_child(DrawBox.new(_paint_bazaar, Vector2(0, 170)))
		top.add_child(_label("バザーは2週間に1度（14日・28日）開かれる特別な催し。日常の出荷よりもかなり高く売れます。マスターした料理や高品質な作物をストックしておこう！", 21, COL_SUB))
		top.add_child(_label("露店では限定レシピも手に入ります。", 21, COL_SUB))
		if Game.hamsters.has("campbell"):
			top.add_child(_label("キャンベルのモカが呼び込みしてくれるので、お客さんが増えます。", 21, COL_GREEN))
		return
	var ev := Game.event_today()
	var head := _card(c, Color("fff0d2"))
	head.add_child(_title("カントリー・クラフト＆マーケット開催中！" if ev == "craft_market" else "隔週バザー開催中！"))
	head.add_child(DrawBox.new(_paint_bazaar, Vector2(0, 170)))
	var vis := "たくさん" if Game.bazaar_visitors_left > 500 else "あと%d人" % Game.bazaar_visitors_left
	head.add_child(_label("お客さん：%s　売値：通常の約%.1f倍" % [vis, Game.bazaar_mult()], 22, COL_RED))

	var sell := _card(c)
	sell.add_child(_title("出品する", 26))
	if Game.inventory.is_empty():
		sell.add_child(_label("売るものがありません。", 22, COL_SUB))
	for id in Game.sorted_inventory():
		var r := _hbox(sell, 8)
		r.add_child(_icon(id, 50))
		r.add_child(_label("%s ×%d\n%dG" % [GameData.item_name(id), Game.count(id), Game.bazaar_price(id)], 21))
		var can := Game.bazaar_visitors_left > 0
		var b1 := _small_button("1個", Game.bazaar_sell.bind(id, 1), can)
		b1.custom_minimum_size.x = 80
		r.add_child(b1)
		r.add_child(_small_button("全部", Game.bazaar_sell.bind(id, Game.count(id)), can, COL_GREEN))

	var stall := _card(c, Color("f3e9d6"))
	stall.add_child(_title("露店", 26))
	for rid in GameData.BAZAAR_RECIPES:
		var r := _hbox(stall)
		var known: bool = rid in Game.known_recipes
		r.add_child(_label("限定レシピ「%s」%s" % [GameData.item_name(rid), "（習得ずみ）" if known else ""], 21))
		var price: int = GameData.BAZAAR_RECIPES[rid]
		r.add_child(_small_button("%dG" % price, Game.buy_bazaar_recipe.bind(rid), not known and Game.gold >= price))
	for g in BAZAAR_GOODS:
		var r := _hbox(stall)
		r.add_child(_icon(g[0], 44))
		r.add_child(_label("%s ×%d" % [GameData.item_name(g[0]), g[1]], 21))
		r.add_child(_small_button("%dG" % g[2], Game.buy_bazaar_goods.bind(g[0], g[1], g[2]), Game.gold >= int(g[2])))


func _paint_bazaar(ci: CanvasItem) -> void:
	var s: Vector2 = ci.size
	var w := minf(s.x, 560.0)
	var x0 := (s.x - w) / 2.0
	for i in 3:
		var bx := x0 + i * w / 3.0 + 10
		var bw := w / 3.0 - 20
		Art.rrect(ci, Rect2(bx, s.y * 0.45, bw, s.y * 0.45), Color("a0703f"), 6)
		for k in 6:
			var col := COL_RED if k % 2 == 0 else Color("fff8e8")
			Art.poly(ci, [Vector2(bx + k * bw / 6.0, s.y * 0.2), Vector2(bx + (k + 1) * bw / 6.0, s.y * 0.2), Vector2(bx + (k + 1) * bw / 6.0, s.y * 0.42), Vector2(bx + k * bw / 6.0, s.y * 0.42)], col)
		var items: Array = [["apple", "pumpkin_pie", "jam"], ["bread", "cheese", "wool"], ["strawberry", "pound_cake", "corn"]][i]
		for k in 3:
			Art.item_icon(ci, Rect2(bx + k * bw / 3.0 + 4, s.y * 0.48, bw / 3.0 - 8, s.y * 0.2), items[k])
	Art.hamster(ci, Vector2(x0 + w * 0.5, s.y * 0.8), 26, "campbell" if Game.hamsters.has("campbell") else "golden", {"hat": "mini_straw"})


# ═════════════════════════════════════════════════════
# 工房
# ═════════════════════════════════════════════════════
func _build_craft(c: Control) -> void:
	var top := _card(c)
	top.add_child(_title("手作り工房"))
	top.add_child(_label("木材・ウール・わた・ナチュラル染料などを集めてクラフト（体力%d）。木材は畑タブの「森で木を切る」で集められます。" % Game.COST_CRAFT, 20, COL_SUB))
	for cat in GameData.CRAFT_CATS:
		var card := _card(c)
		card.add_child(_title(cat[1], 26))
		for id in GameData.CRAFTS:
			var d: Dictionary = GameData.CRAFTS[id]
			if d["cat"] != cat[0]:
				continue
			_sep(card)
			var r := _hbox(card)
			if cat[0] == "hamster":
				var slot: String = d["slot"]
				var oid: String = id
				r.add_child(DrawBox.new(func(ci): Art.hamster(ci, ci.size / 2.0 + Vector2(0, 6), ci.size.y * 0.42, "golden", {slot: oid}), Vector2(84, 84)))
			elif cat[0] == "material":
				r.add_child(_icon(id, 60))
			var info := _vbox(r, 2)
			var own := Game.owned(id)
			var nm := _label("%s%s" % [d["name"], ("（%d個）" % own) if own > 0 and cat[0] != "cloth" and cat[0] != "furniture" else ("（持っている）" if own > 0 else "")], 23)
			nm.add_theme_font_override("font", font_bold)
			info.add_child(nm)
			info.add_child(_label(d["desc"], 19, COL_SUB))
			if d.has("shop"):
				info.add_child(_label("冬のキャンドルナイト＆ウール市で販売", 19, Color("4d6fa3")))
				continue
			var mt := _mats_text(d["mats"])
			var need: String = mt[0]
			if int(d["gold"]) > 0:
				need += "・%dG" % d["gold"]
			info.add_child(_label(need, 19, COL_SUB if mt[1] else COL_RED))
			var err := Game.craft_error(id)
			var b := _small_button("作る" if err != "もう持っている" else "作成ずみ", Game.craft.bind(id), err == "", COL_GREEN)
			b.size_flags_vertical = SIZE_SHRINK_CENTER
			r.add_child(b)


# ═════════════════════════════════════════════════════
# おうち（インテリア・着せ替え）
# ═════════════════════════════════════════════════════
func _build_home(c: Control) -> void:
	var rc := _card(c)
	rc.add_child(_title("%sのおうち" % Game.player_name))
	var colors := _cloth_colors()
	rc.add_child(DrawBox.new(func(ci): Art.room(ci, Rect2(Vector2.ZERO, ci.size), Game.furniture, Game.gender, Game.outfit, colors), Vector2(0, 430)))
	rc.add_child(_label("最大体力 %d・おやすみでの回復量 %d" % [Game.max_stamina(), Game.rest_amount()], 22, COL_GREEN))

	var wc := _card(c)
	wc.add_child(_title("クローゼット", 26))
	var any := false
	for id in GameData.CRAFTS:
		var d: Dictionary = GameData.CRAFTS[id]
		if d["cat"] != "cloth" or Game.owned(id) <= 0:
			continue
		any = true
		var r := _hbox(wc, 8)
		var cc := Game.cloth_color(id)
		r.add_child(DrawBox.new(func(ci): Art.rrect(ci, Rect2(Vector2(6, 6), ci.size - Vector2(12, 12)), cc, 10), Vector2(50, 50)))
		var wearing: bool = Game.outfit.get(d["slot"], "") == id
		r.add_child(_label("%s（%s）%s\n%s" % [d["name"], GameData.CLOTH_COLOR_NAMES[int(Game.cloth_colors.get(id, 0))], "・着ている" if wearing else "", d["desc"]], 20))
		r.add_child(_small_button("ぬぐ" if wearing else "着る", Game.equip.bind(id), true, COL_GREEN))
		r.add_child(_small_button("染める", Game.dye_cloth.bind(id), Game.count("dye") > 0))
	if not any:
		wc.add_child(_label("工房で麦わら帽子・エプロン・ニットを作ると着替えられます。ナチュラル染料でアースカラーにも染められます。", 21, COL_SUB))
	wc.add_child(_label("いつもの服：%s" % ("デニムのオーバーオール＋チェック柄シャツ＋ワークパンツ" if Game.gender == "boy" else "デニムのオーバーオール＋ナチュラルコットンのカントリーワンピース"), 19, COL_SUB))

	var fc := _card(c)
	fc.add_child(_title("家具", 26))
	if Game.furniture.is_empty():
		fc.add_child(_label("工房で家具を作ると、お部屋に飾られて体力の回復量がUPします。", 21, COL_SUB))
	for id in Game.furniture:
		fc.add_child(_label("・%s ─ %s" % [GameData.CRAFTS[id]["name"], GameData.CRAFTS[id]["desc"]], 21))

	var sc := _card(c)
	var sr := _hbox(sc)
	sr.add_child(_label("効果音の音量", 22))
	sr.add_child(_small_button(Sfx.volume_name(), func():
		Sfx.cycle_volume()
		_rebuild_tab(false)))
	var br2 := _hbox(sc)
	br2.add_child(_label("BGMの音量", 22))
	br2.add_child(_small_button(Sfx.bgm_volume_name(), func():
		Sfx.cycle_bgm_volume()
		_rebuild_tab(false)))
	var br3 := _hbox(sc)
	br3.add_child(_label("タブのバッジ表示", 22))
	br3.add_child(_small_button("オン" if badges_on else "オフ", _toggle_badges, true, COL_GREEN if badges_on else COL_WOOD))
	var br4 := _hbox(sc)
	br4.add_child(_label("ハムスターのおすすめ（1分さわらないと登場）", 22))
	br4.add_child(_small_button("オン" if helper_on else "オフ", _toggle_helper, true, COL_GREEN if helper_on else COL_WOOD))
	var r2 := _hbox(sc)
	var b1 := _button("セーブする", func():
		Game.save_game()
		_show_toast("セーブしました"))
	b1.size_flags_horizontal = SIZE_EXPAND_FILL
	r2.add_child(b1)
	var b2 := _button("タイトルへ", func():
		Game.save_game()
		_show_title(), true, COL_SUB)
	b2.size_flags_horizontal = SIZE_EXPAND_FILL
	r2.add_child(b2)


# ═════════════════════════════════════════════════════
# 村（イベント・掲示板・村人）
# ═════════════════════════════════════════════════════
func _build_village(c: Control) -> void:
	var ev := Game.event_today()
	if ev != "":
		var info: Dictionary = GameData.EVENT_INFO[ev]
		var ec := _card(c, Color("fff0d2"))
		ec.add_child(_title("今日のイベント"))
		ec.add_child(_label(info["name"], 26, COL_RED))
		ec.add_child(_label(info["desc"], 20, COL_SUB))
		var done: bool = Game.event_done_today() and info["type"] in ["contest", "egg_hunt", "bbq"]
		ec.add_child(_button("参加ずみ" if done else "イベントに参加する", _open_event, not done, COL_GREEN))

	var up := _card(c)
	up.add_child(_title("%sの行事カレンダー" % Game.season_name(), 26))
	var evs := Game.upcoming_events()
	if evs.is_empty():
		up.add_child(_label("この季節の行事はおしまい。", 21, COL_SUB))
	for e in evs:
		up.add_child(_label("%d日　%s" % [e["day"], GameData.EVENT_INFO[e["id"]]["name"]], 21))
	up.add_child(_label("バザー：14日・28日", 21, COL_SUB))

	var rq := _card(c)
	rq.add_child(_title("掲示板のリクエスト", 26))
	if Game.requests.is_empty():
		rq.add_child(_label("いまはリクエストがありません。", 21, COL_SUB))
	for i in Game.requests.size():
		var q: Dictionary = Game.requests[i]
		_sep(rq)
		var r := _hbox(rq)
		r.add_child(_icon(q["item"], 56))
		var vn: String = GameData.VILLAGERS[q["villager"]]["name"]
		var info2 := _vbox(r, 2)
		info2.add_child(_label("%s「%sが%d個ほしいな」" % [vn, GameData.item_name(q["item"]), q["qty"]], 21))
		info2.add_child(_label("お礼：%dG＋%s×%d・あと%d日（持っている：%d）" % [q["gold"], GameData.item_name(q["reward"]), q["reward_qty"], q["days"], Game.count(q["item"])], 18, COL_SUB))
		r.add_child(_small_button("わたす", Game.fulfill.bind(i), Game.count(q["item"]) >= int(q["qty"]), COL_GREEN))

	for v in GameData.VILLAGERS:
		var d: Dictionary = GameData.VILLAGERS[v]
		var st: Dictionary = Game.villagers[v]
		var card := _card(c)
		var r := _hbox(card)
		var vc := Color(d["color"])
		r.add_child(DrawBox.new(func(ci): _paint_villager(ci, vc), Vector2(92, 92)))
		var info3 := _vbox(r, 2)
		var nl := _label("%s（%s）" % [d["name"], d["job"]], 23)
		nl.add_theme_font_override("font", font_bold)
		info3.add_child(nl)
		info3.add_child(_label("なかよし %s" % _stars(Game.hearts(v), 5), 20, Color("d9822b")))
		info3.add_child(_label("「%s」" % d["line"], 19, COL_SUB))
		var teach := "得意料理「%s」を教わった" % GameData.item_name(d["teach"]) if st["taught"] else "友情度%dで得意料理を教えてくれる（いま%d）" % [GameData.TEACH_FRIENDSHIP, st["friend"]]
		info3.add_child(_label(teach, 18, COL_GREEN if st["taught"] else COL_SUB))
		var b := _small_button("あげた" if st["gifted"] else "贈る", _open_gift.bind(v), not st["gifted"] and not Game.inventory.is_empty(), COL_GREEN)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		r.add_child(b)


func _paint_villager(ci: CanvasItem, hair: Color) -> void:
	var s: Vector2 = ci.size
	var c := s / 2.0 + Vector2(0, 4)
	var u := s.y * 0.4
	Art.rrect(ci, Rect2(c + Vector2(-u * 0.9, u * 0.55), Vector2(u * 1.8, u * 0.55)), hair.lightened(0.3), 12)
	ci.draw_circle(c, u * 0.7, Art.SKIN)
	Art.poly(ci, [c + Vector2(-u * 0.75, 0), c + Vector2(-u * 0.6, -u * 0.6), c + Vector2(0, -u * 0.8), c + Vector2(u * 0.6, -u * 0.6), c + Vector2(u * 0.75, 0), c + Vector2(u * 0.3, -u * 0.35), c + Vector2(-u * 0.3, -u * 0.35)], hair)
	for sx in [-1, 1]:
		ci.draw_circle(c + Vector2(sx * u * 0.28, u * 0.05), u * 0.08, Color("2b1d14"))
		Art.ellipse(ci, c + Vector2(sx * u * 0.45, u * 0.25), u * 0.12, u * 0.07, Color(1, 0.55, 0.55, 0.4))
	ci.draw_arc(c + Vector2(0, u * 0.25), u * 0.15, 0.3, PI - 0.3, 8, Art.LINE, 2, true)


func _open_gift(v: String) -> void:
	var d: Dictionary = GameData.VILLAGERS[v]
	open_popup("%sに贈りもの" % d["name"], func(box: VBoxContainer):
		box.add_child(_label("料理のランクが高いほど、好物ほど友情度が大きくUP！ 1日1回まで。", 20, COL_SUB))
		for id in Game.sorted_inventory():
			var r := _hbox(box)
			r.add_child(_icon(id, 50))
			r.add_child(_label("%s ×%d\n友情度+%d" % [GameData.item_name(id), Game.count(id), Game.gift_points(v, id)], 21))
			r.add_child(_small_button("贈る", func():
				Game.gift(v, id)
				close_popup(), true, COL_GREEN)))


# ═════════════════════════════════════════════════════
# ハムスター
# ═════════════════════════════════════════════════════
func _build_hamster(c: Control) -> void:
	var top := _card(c)
	top.add_child(_title("お手伝いハムスター"))
	top.add_child(_label("毎日いっしょに働く・なでるとレベルUP。Lv2とLv4になると、お礼に限定レシピを教えてくれます。", 20, COL_SUB))
	for h in GameData.HAMSTER_ORDER:
		if not Game.hamsters.has(h):
			continue
		var d: Dictionary = GameData.HAMSTERS[h]
		var hs: Dictionary = Game.hamsters[h]
		var card := _card(c)
		var r := _hbox(card)
		var o: Dictionary = hs["outfit"]
		var hh: String = h
		r.add_child(DrawBox.new(func(ci): Art.hamster(ci, ci.size / 2.0 + Vector2(0, 8), ci.size.y * 0.4, hh, o), Vector2(140, 140)))
		var info := _vbox(r, 2)
		var nl := _label("%s（%s）Lv%d" % [d["name"], d["type"], hs["level"]], 24)
		nl.add_theme_font_override("font", font_bold)
		info.add_child(nl)
		info.add_child(_label("得意：%s／特技：%s" % [d["field"], d["skill"]], 19, Color("a0703f")))
		info.add_child(_label(d["desc"], 19, COL_SUB))
		var p := Game.ham_xp_progress(h)
		info.add_child(_bar(p[0], p[1], Color("e9a64a")))
		var next := ""
		for lv in ["2", "4"]:
			if int(lv) > int(hs["level"]):
				next = "Lv%sで「%s」を伝授" % [lv, GameData.item_name(d["teach"][lv])]
				break
		if next == "":
			next = "レシピをぜんぶ教えてくれた！"
		info.add_child(_label(next, 18, COL_GREEN))
		var br := _hbox(card, 8)
		var b1 := _button("なでなでした" if hs["petted"] else "なでる", Game.pet.bind(h), not hs["petted"], COL_GREEN, 22)
		b1.size_flags_horizontal = SIZE_EXPAND_FILL
		br.add_child(b1)
		var b2 := _button("お着替え", _open_ham_outfit.bind(h), true, COL_WOOD, 22)
		b2.size_flags_horizontal = SIZE_EXPAND_FILL
		br.add_child(b2)

	var hire := _card(c, Color("f3e9d6"))
	hire.add_child(_title("お手伝いを募集中", 26))
	var any := false
	for h in GameData.HAMSTER_ORDER:
		if Game.hamsters.has(h):
			continue
		any = true
		var d: Dictionary = GameData.HAMSTERS[h]
		_sep(hire)
		var r := _hbox(hire)
		var hh: String = h
		r.add_child(DrawBox.new(func(ci): Art.hamster(ci, ci.size / 2.0 + Vector2(0, 6), ci.size.y * 0.4, hh, {}), Vector2(100, 100)))
		r.add_child(_label("%s\n得意：%s\n%s" % [d["type"], d["field"], d["desc"]], 19))
		var b := _small_button("%dG" % d["hire"], Game.hire.bind(h), Game.gold >= int(d["hire"]), COL_GREEN)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		r.add_child(b)
	if not any:
		hire.add_child(_label("5匹ぜんぶがお手伝いしてくれています！", 21, COL_GREEN))


func _open_ham_outfit(h: String) -> void:
	var d: Dictionary = GameData.HAMSTERS[h]
	open_popup("%sのお着替え" % d["name"], func(box: VBoxContainer):
		var o: Dictionary = Game.hamsters[h]["outfit"]
		box.add_child(DrawBox.new(func(ci): Art.hamster(ci, ci.size / 2.0 + Vector2(0, 10), ci.size.y * 0.38, h, o), Vector2(0, 170)))
		var any := false
		for id in GameData.CRAFTS:
			var cd: Dictionary = GameData.CRAFTS[id]
			if cd["cat"] != "hamster" or Game.owned(id) <= 0:
				continue
			any = true
			var wearing: bool = o.get(cd["slot"], "") == id
			var r := _hbox(box)
			r.add_child(_label("%s（%d着）" % [cd["name"], Game.owned(id)], 22))
			r.add_child(_small_button("ぬがせる" if wearing else "着せる", Game.ham_equip.bind(h, id), wearing or Game.outfit_free(id, h), COL_GREEN))
		if not any:
			box.add_child(_label("工房の「ハムスターのお着替え」で、ミニ麦わら帽子やミニオーバーオールを作ろう。主人公とおそろいコーデもできます！", 21, COL_SUB)))


# ═════════════════════════════════════════════════════
# 季節イベント
# ═════════════════════════════════════════════════════
func _open_event() -> void:
	var ev := Game.event_today()
	if ev == "":
		return
	_event_shown_key = Game.event_key()
	_event_result = ""
	if GameData.EVENT_INFO[ev]["type"] == "egg_hunt" and not Game.event_done_today():
		_egg_cells = []
		for i in 12:
			_egg_cells.append(0)
		var idx := range(12)
		idx.shuffle()
		for k in 5:
			_egg_cells[idx[k]] = 2 if k == 0 else 1
		_egg_open = []
		for i in 12:
			_egg_open.append(false)
		_egg_tries = Game.egg_hunt_tries()
	open_popup(GameData.EVENT_INFO[ev]["name"], _build_event.bind(ev))


func _build_event(box: VBoxContainer, ev: String) -> void:
	var info: Dictionary = GameData.EVENT_INFO[ev]
	box.add_child(DrawBox.new(_paint_event.bind(ev), Vector2(0, 150)))
	box.add_child(_label(info["desc"], 21, COL_SUB))
	if _event_result != "":
		var rc := _card(box, Color("fff0d2"))
		rc.add_child(_label(_event_result, 22, COL_RED))
	match info["type"]:
		"contest", "bbq", "soup":
			if Game.event_done_today() and info["type"] != "soup":
				if _event_result == "":
					box.add_child(_label("今日はもう参加しました。", 22))
				return
			var entries := Game.event_entries(ev)
			if entries.is_empty():
				box.add_child(_label("出せるものを持っていません…（対象：%s）" % _event_target_text(info), 21, COL_RED))
				return
			box.add_child(_title("どれを%s？" % ("出品する" if info["type"] == "contest" else ("持っていく" if info["type"] == "bbq" else "ふるまう")), 24))
			for id in entries:
				var r := _hbox(box)
				r.add_child(_icon(id, 50))
				var nm: String = GameData.item_name(id)
				if GameData.is_dish(id):
					nm += " " + _stars(Game.rank(id) + 1)
				r.add_child(_label("%s ×%d（価値%dG）" % [nm, Game.count(id), Game.item_value(id)], 21))
				r.add_child(_small_button("えらぶ", _event_pick.bind(ev, id), true, COL_GREEN))
		"egg_hunt":
			if Game.event_done_today():
				if _event_result == "":
					box.add_child(_label("今日はもう参加しました。", 22))
				return
			box.add_child(_label("のこり %d回 さがせる（ハムスター%d匹がお手伝い）" % [_egg_tries, Game.hamsters.size()], 22, COL_GREEN))
			var g := GridContainer.new()
			g.columns = 4
			g.add_theme_constant_override("h_separation", 8)
			g.add_theme_constant_override("v_separation", 8)
			box.add_child(g)
			for i in 12:
				var t := "？"
				var col := COL_GREEN
				if _egg_open[i]:
					t = ["はずれ", "たまご！", "金のたまご！"][_egg_cells[i]]
					col = [COL_DISABLED, Color("e9a64a"), Color("d4a017")][_egg_cells[i]]
				var b := _button(t, _egg_tap.bind(i), not _egg_open[i] and _egg_tries > 0, col, 19)
				b.custom_minimum_size = Vector2(0, 90)
				b.size_flags_horizontal = SIZE_EXPAND_FILL
				if _egg_open[i]:
					b.add_theme_stylebox_override("disabled", _btn_style(col, "normal"))
					b.add_theme_color_override("font_disabled_color", COL_CREAM)
				g.add_child(b)
		"market":
			box.add_child(_button("バザーへ行く", func():
				close_popup()
				_switch_tab("bazaar"), true, COL_GREEN))
		"shop":
			for id in info["shop"]:
				var d: Dictionary = GameData.CRAFTS[id]
				var r := _hbox(box)
				r.add_child(_label("%s\n%s" % [d["name"], d["desc"]], 20))
				var p := Game.shop_price(id)
				var once: bool = d["cat"] == "furniture" or d["cat"] == "cloth"
				var own := once and Game.owned(id) > 0
				r.add_child(_small_button("購入ずみ" if own else "%dG" % p, Game.buy_shop.bind(id), not own and Game.gold >= p, COL_GREEN))


func _event_target_text(info: Dictionary) -> String:
	if info.has("items"):
		var names: Array = []
		for id in info["items"]:
			names.append(GameData.item_name(id))
		return "・".join(names)
	match info.get("tag", ""):
		"pie":
			return "パイ・タルト系の料理"
		"warm":
			return "スープやシチューなど、あったかい料理"
	return ""


func _event_pick(ev: String, id: String) -> void:
	var t: String = GameData.EVENT_INFO[ev]["type"]
	var res := ""
	match t:
		"contest":
			res = Game.contest_submit(ev, id)
		"bbq":
			res = Game.bbq_contribute(id)
		"soup":
			res = Game.soup_serve(id)
	if res != "":
		_event_result = res
		Sfx.play("jingle")
	_fill_popup(false)


func _egg_tap(i: int) -> void:
	if _egg_open[i] or _egg_tries <= 0:
		return
	_egg_open[i] = true
	_egg_tries -= 1
	Sfx.play(["error", "harvest", "jingle"][_egg_cells[i]])
	if _egg_tries <= 0:
		var eggs := 0
		var golden := false
		for k in 12:
			if _egg_open[k] and _egg_cells[k] > 0:
				eggs += 1
				if _egg_cells[k] == 2:
					golden = true
		_event_result = Game.egg_hunt_finish(eggs, golden)
	_fill_popup(true)


func _paint_event(ci: CanvasItem, ev: String) -> void:
	var s: Vector2 = ci.size
	var night := ev in ["bbq", "candle_night"]
	Art.rrect(ci, Rect2(Vector2.ZERO, s), Color("2f3b66") if night else Color(GameData.SEASON_COLORS[Game.season]).lightened(0.45), 14)
	if night:
		for k in 14:
			Art.star(ci, Vector2(fmod(k * 97.0, s.x), fmod(k * 37.0, s.y * 0.6) + 10), 5, Color("fff3b0"))
	Art.ellipse(ci, Vector2(s.x / 2, s.y * 1.05), s.x * 0.7, s.y * 0.35, Color("7fb35a") if Game.season != 3 else Color("f4f8fb"))
	var hs: Array = Game.hamsters.keys()
	for i in hs.size():
		var x := s.x / 2 + (i - (hs.size() - 1) / 2.0) * 70
		var o: Dictionary = Game.hamsters[hs[i]]["outfit"]
		Art.hamster(ci, Vector2(x, s.y * 0.72), 26, hs[i], o)
	match ev:
		"flower_fest":
			for k in 8:
				ci.draw_circle(Vector2(30 + k * (s.x - 60) / 7.0, s.y * 0.9), 10, [Color("a58ad8"), Color("f4b8c5"), Color("f2c94c")][k % 3])
		"egg_hunt":
			for k in 5:
				Art.ellipse(ci, Vector2(40 + k * (s.x - 80) / 4.0, s.y * 0.9), 10, 13, [Color("f4b8c5"), Color("a9cbe0"), Color("f2c94c"), Color("9ccc65"), Color("d8b4e8")][k])
		"bbq", "candle_night":
			for k in 3:
				var x := s.x * (0.15 + k * 0.35)
				ci.draw_circle(Vector2(x, s.y * 0.35), 18, Color(1, 0.8, 0.3, 0.3))
				Art.ellipse(ci, Vector2(x, s.y * 0.35), 5, 10, Color("f2a52c"))
		"pie_contest":
			Art.item_icon(ci, Rect2(20, s.y * 0.5, 80, 60), "apple_pie")
			Art.item_icon(ci, Rect2(s.x - 100, s.y * 0.5, 80, 60), "pumpkin_pie")
		"veg_contest":
			Art.item_icon(ci, Rect2(20, s.y * 0.5, 60, 60), "tomato")
			Art.item_icon(ci, Rect2(s.x - 80, s.y * 0.5, 60, 60), "corn")
		"soup_fair":
			Art.item_icon(ci, Rect2(20, s.y * 0.5, 80, 60), "cream_stew")
			Art.item_icon(ci, Rect2(s.x - 100, s.y * 0.5, 80, 60), "pumpkin_soup")


# ═════════════════════════════════════════════════════
# おやすみ・朝のレポート
# ═════════════════════════════════════════════════════
func _on_sleep_pressed() -> void:
	var todo := Game.todo_list()
	open_popup("おやすみしますか？", func(box: VBoxContainer):
		if todo.is_empty():
			box.add_child(_label("今日のやることは全部できました！ おつかれさま♪", 22, COL_GREEN))
		else:
			box.add_child(_title("まだやり残しがあります", 24, COL_RED))
			for item in todo:
				var r0 := _hbox(box, 8)
				r0.add_child(_label("・" + item[0], 20))
				var go := _small_button("行く", func():
					close_popup()
					_switch_tab(item[1]))
				go.custom_minimum_size = Vector2(84, 52)
				go.size_flags_vertical = SIZE_SHRINK_CENTER
				r0.add_child(go)
			box.add_child(_label("このままおやすみしても大丈夫です。", 19, COL_SUB))
		_sep(box)
		box.add_child(_label("体力が%d回復して、次の日になります。\n（自動でセーブされます）" % Game.rest_amount(), 21))
		var r := _hbox(box)
		var b1 := _button("おやすみなさい" if todo.is_empty() else "それでもおやすみ", _do_sleep, true, COL_GREEN if todo.is_empty() else COL_WOOD)
		b1.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(b1)
		var b2 := _button("まだ起きてる", close_popup, true, COL_WOOD if todo.is_empty() else COL_GREEN)
		b2.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(b2))


func _do_sleep() -> void:
	close_popup(false)
	Sfx.play("sleep")
	Game.sleep()
	_show_morning()


func _show_morning() -> void:
	var lines: Array = Game.last_report.duplicate()
	open_popup("%sの月 %d日 の朝" % [Game.season_name(), Game.day], func(box: VBoxContainer):
		box.add_child(DrawBox.new(_paint_morning, Vector2(0, 150)))
		box.add_child(_label("おはよう、%s！ 天気は%s。" % [Game.player_name, GameData.WEATHER_NAMES.get(Game.weather, "")], 23))
		if lines.is_empty():
			box.add_child(_label("おだやかな朝です。", 21, COL_SUB))
		for l in lines:
			box.add_child(_label("・" + l, 21))
		box.add_child(_button("今日もがんばろう！", close_popup, true, COL_GREEN)), _check_event_popup, "")
	if not Game.hamsters.is_empty():
		Sfx.play("steps", 1.2)
		Sfx.play("hamster", 1.6)


func _paint_morning(ci: CanvasItem) -> void:
	var s: Vector2 = ci.size
	Art.rrect(ci, Rect2(Vector2.ZERO, s), Color("cfe8f5") if Game.weather == "sunny" else Color("b8c4cf"), 14)
	if Game.weather == "sunny":
		ci.draw_circle(Vector2(s.x - 70, 50), 30, Color("f7d358"))
	else:
		for k in 20:
			var p := Vector2(fmod(k * 61.0, s.x), fmod(k * 29.0, s.y * 0.7))
			if Game.weather == "snow":
				ci.draw_circle(p, 4, Color.WHITE)
			else:
				ci.draw_line(p, p + Vector2(-4, 12), Color("6f9fd8"), 2)
	Art.ellipse(ci, Vector2(s.x * 0.3, s.y * 1.1), s.x * 0.5, s.y * 0.45, Color(GameData.SEASON_COLORS[Game.season]).darkened(0.05))
	Art.ellipse(ci, Vector2(s.x * 0.8, s.y * 1.15), s.x * 0.5, s.y * 0.45, Color(GameData.SEASON_COLORS[Game.season]))
	Art.player(ci, Rect2(s.x * 0.3 - 30, s.y * 0.2, 60, s.y * 0.78), Game.gender, Game.outfit, _cloth_colors())
	var i := 0
	for h in Game.hamsters:
		Art.hamster(ci, Vector2(s.x * 0.45 + i * 56, s.y * 0.8), 22, h, Game.hamsters[h]["outfit"])
		i += 1


func _check_event_popup() -> void:
	var ev := Game.event_today()
	if ev == "" or _event_shown_key == Game.event_key():
		return
	if Game.event_done_today() and GameData.EVENT_INFO[ev]["type"] in ["contest", "egg_hunt", "bbq"]:
		return
	_open_event.call_deferred()


# ═════════════════════════════════════════════════════
# おすすめハムスター（放置すると真ん中に出てきて教えてくれる）
# ═════════════════════════════════════════════════════
## メイン画面を放置していたら、おすすめハムスターを出す
## （タイトル・ポップアップ・イベント中は数えない。閉じたら、また1分から数え直す）
func _tick_idle(delta: float) -> void:
	if not helper_on or not Game.started or title_layer != null or popup_layer != null or helper_layer != null or splash_layer != null:
		_idle = 0.0
		return
	_idle += delta
	if _idle >= HELPER_IDLE_SEC:
		_idle = 0.0
		_show_helper()


func _toggle_helper() -> void:
	helper_on = not helper_on
	_idle = 0.0
	Sfx.set_setting("ui", "helper", helper_on)
	_rebuild_tab(false)


func _show_helper() -> void:
	if helper_layer != null or not Game.started:
		return
	var rec := Game.recommend()
	toast_panel.visible = false
	toast_lines.clear()
	toast_time = 0.0
	var h: String = rec["hamster"]
	var hd: Dictionary = GameData.HAMSTERS[h]
	var outfit: Dictionary = Game.hamsters[h]["outfit"] if Game.hamsters.has(h) else {}
	helper_layer = Control.new()
	helper_layer.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(helper_layer)

	# 画面のどこをタッチしても閉じる
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.15, 0.06, 0.0)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_hide_helper(""))
	helper_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	helper_layer.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	center.add_child(col)

	# 吹き出し
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _sb(Color("fffaf0"), COL_WOOD, 5, 28, 22))
	bubble.custom_minimum_size = Vector2(640, 0)
	bubble.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(bubble)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 12)
	bv.mouse_filter = MOUSE_FILTER_IGNORE
	bubble.add_child(bv)
	var chip_row := HBoxContainer.new()
	chip_row.mouse_filter = MOUSE_FILTER_IGNORE
	bv.add_child(chip_row)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _sb(Color(hd["fur"]).darkened(0.1), Color.TRANSPARENT, 0, 16, 6))
	chip.mouse_filter = MOUSE_FILTER_IGNORE
	chip_row.add_child(chip)
	var chip_l := _label("%s（%s）" % [hd["name"], hd["type"]], 20, Color.WHITE, false)
	chip_l.add_theme_font_override("font", font_bold)
	chip_l.add_theme_color_override("font_outline_color", Color(hd["fur"]).darkened(0.45))
	chip_l.add_theme_constant_override("outline_size", 5)
	chip.add_child(chip_l)
	var msg := _label(rec["text"], 26, COL_TEXT)
	msg.add_theme_constant_override("line_spacing", 4)
	bv.add_child(msg)
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 10)
	br.mouse_filter = MOUSE_FILTER_IGNORE
	bv.add_child(br)
	var hint := _label("画面をタップでとじる", 18, COL_SUB)
	hint.size_flags_vertical = SIZE_SHRINK_CENTER
	br.add_child(hint)
	if rec["tab"] != "":
		var go := _button(rec["go"] + " →", _hide_helper.bind(rec["tab"]), true, COL_GREEN, 22)
		go.custom_minimum_size = Vector2(190, 60)
		br.add_child(go)

	# しっぽ（ハムスターを指す）
	var tail := DrawBox.new(func(ci: CanvasItem):
		var cx: float = ci.size.x / 2.0
		Art.poly(ci, [Vector2(cx - 28, -7), Vector2(cx + 28, -7), Vector2(cx + 4, 34)], Color("fffaf0"))
		ci.draw_line(Vector2(cx - 28, -2), Vector2(cx + 4, 34), COL_WOOD, 5, true)
		ci.draw_line(Vector2(cx + 28, -2), Vector2(cx + 4, 34), COL_WOOD, 5, true), Vector2(0, 34))
	tail.clip_contents = false
	col.add_child(tail)

	# ハムスター（ぽんっと登場して、ゆらゆら）
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(640, 300)
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(holder)
	var ham := DrawBox.new(func(ci: CanvasItem):
		var c: Vector2 = ci.size / 2.0 + Vector2(0, 20)
		Art.ellipse(ci, c + Vector2(0, 112), 104, 18, Color(0, 0, 0, 0.2))
		Art.hamster(ci, c, 125, h, outfit)
		Art.star(ci, c + Vector2(-145, -70), 15, Color("ffd84a"))
		Art.star(ci, c + Vector2(140, -95), 10, Color("fff3b0"))
		Art.star(ci, c + Vector2(160, 10), 7, Color("ffd84a")), Vector2(340, 300))
	ham.clip_contents = false
	ham.position = Vector2(150, 0)
	ham.pivot_offset = Vector2(170, 280)
	holder.add_child(ham)

	# 登場アニメーション
	var t := helper_layer.create_tween().set_parallel(true)
	t.tween_property(dim, "color:a", 0.45, 0.3)
	ham.scale = Vector2(0.2, 0.2)
	ham.position.y = 120
	t.tween_property(ham, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(ham, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bubble.modulate.a = 0.0
	bubble.scale = Vector2(0.7, 0.7)
	bubble.resized.connect(func(): bubble.pivot_offset = Vector2(bubble.size.x / 2.0, bubble.size.y))
	t.tween_property(bubble, "modulate:a", 1.0, 0.25).set_delay(0.3)
	t.tween_property(bubble, "scale", Vector2.ONE, 0.35).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tail.modulate.a = 0.0
	t.tween_property(tail, "modulate:a", 1.0, 0.2).set_delay(0.4)
	# ゆらゆら（ずっと）
	var bob := ham.create_tween().set_loops()
	bob.tween_interval(0.5)
	bob.tween_property(ham, "rotation", 0.06, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(ham, "rotation", -0.06, 1.2).set_trans(Tween.TRANS_SINE)
	bob.tween_property(ham, "rotation", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	Sfx.play("steps")
	Sfx.play("hamster", 0.3)


func _hide_helper(go_tab: String) -> void:
	if helper_layer == null:
		return
	var layer := helper_layer
	helper_layer = null
	var t := layer.create_tween()
	t.tween_property(layer, "modulate:a", 0.0, 0.18)
	t.tween_callback(layer.queue_free)
	if go_tab == "sleep":
		_on_sleep_pressed()
	elif go_tab != "":
		_switch_tab(go_tab)


# ═════════════════════════════════════════════════════
# ポップアップ
# ═════════════════════════════════════════════════════
func open_popup(title: String, builder: Callable, on_close := Callable(), sound := "page") -> void:
	close_popup(false)
	if sound != "":
		Sfx.play(sound)
	popup_layer = Control.new()
	popup_layer.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(popup_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.12, 0.05, 0.55)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	popup_layer.add_child(dim)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(PRESET_FULL_RECT)
	mc.mouse_filter = MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 24)
	mc.add_theme_constant_override("margin_right", 24)
	mc.add_theme_constant_override("margin_top", 80 + _safe_top())
	mc.add_theme_constant_override("margin_bottom", 80)
	popup_layer.add_child(mc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _sb(COL_CARD, COL_WOOD, 5, 22, 20))
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	mc.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	popup_title = _title(title, 28)
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(popup_title)
	popup_scroll = ScrollContainer.new()
	popup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(popup_scroll)
	popup_box = VBoxContainer.new()
	popup_box.size_flags_horizontal = SIZE_EXPAND_FILL
	popup_box.add_theme_constant_override("separation", 10)
	popup_scroll.add_child(popup_box)
	var close := _button("とじる", close_popup, true, COL_SUB, 22)
	v.add_child(close)
	popup_builder = builder
	popup_on_close = on_close
	_fill_popup(false)


func _fill_popup(keep_scroll: bool) -> void:
	if popup_box == null:
		return
	var sv := popup_scroll.scroll_vertical if keep_scroll else 0
	for ch in popup_box.get_children():
		popup_box.remove_child(ch)
		ch.queue_free()
	popup_builder.call(popup_box)
	_fit_popup(sv)


func _fit_popup(sv: int) -> void:
	var sc := popup_scroll
	var bx := popup_box
	await get_tree().process_frame
	if not is_instance_valid(sc) or not is_instance_valid(bx):
		return
	var max_h := get_viewport_rect().size.y - 420 - _safe_top()
	sc.custom_minimum_size.y = min(bx.get_combined_minimum_size().y, max_h)
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_vertical = sv


func close_popup(run_callback := true) -> void:
	if popup_layer == null:
		return
	var cb := popup_on_close
	popup_layer.queue_free()
	popup_layer = null
	popup_scroll = null
	popup_box = null
	popup_builder = Callable()
	popup_on_close = Callable()
	if run_callback and cb.is_valid():
		cb.call()


# ═════════════════════════════════════════════════════
# ブートスプラッシュ（猫だいふく SOFTWARE）
#   白い画面 → ロゴがふわっとフェードイン → 少し待つ → フェードアウトしてタイトルへ
#   画面をタップするとスキップ
# ═════════════════════════════════════════════════════
func _show_splash() -> void:
	splash_layer = Control.new()
	splash_layer.set_anchors_preset(PRESET_FULL_RECT)
	add_child(splash_layer)  # いちばん手前
	var bg := ColorRect.new()
	bg.color = Color.WHITE  # 起動時の画面（boot_splash/bg_color）と同じ白
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_skip_splash())
	splash_layer.add_child(bg)
	var logo := TextureRect.new()
	logo.texture = SPLASH_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_preset(PRESET_FULL_RECT)
	logo.offset_left = 24
	logo.offset_right = -24
	logo.mouse_filter = MOUSE_FILTER_IGNORE
	logo.modulate.a = 0.0
	logo.pivot_offset = get_viewport_rect().size / 2.0
	logo.scale = Vector2(0.96, 0.96)
	splash_layer.add_child(logo)
	# 0.25秒 白 → フェードイン（ほんの少しズーム）→ 表示したまま待つ → フェードアウト
	_splash_tween = splash_layer.create_tween()
	_splash_tween.tween_interval(0.25)
	_splash_tween.tween_property(logo, "modulate:a", 1.0, SPLASH_FADE_IN).set_trans(Tween.TRANS_SINE)
	_splash_tween.parallel().tween_property(logo, "scale", Vector2.ONE, SPLASH_FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_splash_tween.tween_interval(SPLASH_HOLD)
	_splash_tween.tween_callback(_end_splash)


func _skip_splash() -> void:
	if splash_layer == null or splash_layer.has_meta("ending"):
		return
	if _splash_tween and _splash_tween.is_valid():
		_splash_tween.kill()
	_end_splash()


func _end_splash() -> void:
	if splash_layer == null or splash_layer.has_meta("ending"):
		return
	splash_layer.set_meta("ending", true)
	_show_title()  # スプラッシュの下にタイトルを用意して、スプラッシュだけ消す
	var layer := splash_layer
	var t := layer.create_tween()
	t.tween_property(layer, "modulate:a", 0.0, SPLASH_FADE_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func():
		layer.queue_free()
		if splash_layer == layer:
			splash_layer = null)


# ═════════════════════════════════════════════════════
# タイトル画面
# ═════════════════════════════════════════════════════
func _show_title() -> void:
	close_popup(false)
	if title_layer != null:
		title_layer.queue_free()
	title_layer = Control.new()
	title_layer.set_anchors_preset(PRESET_FULL_RECT)
	overlay.add_child(title_layer)
	var bg := DrawBox.new(_paint_title, Vector2.ZERO)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_STOP
	title_layer.add_child(bg)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]:
		mc.add_theme_constant_override("margin_" + side, 24)
	mc.add_theme_constant_override("margin_top", 40 + _safe_top())
	mc.add_theme_constant_override("margin_bottom", 70)
	mc.mouse_filter = MOUSE_FILTER_IGNORE
	title_layer.add_child(mc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	mc.add_child(v)
	# BGM（右上の♪ボタンで音量切り替え）
	Sfx.play_bgm("title")
	var bgm_btn := _small_button("♪ " + Sfx.bgm_volume_name(), _on_title_bgm_pressed, true, COL_WOOD)
	_title_bgm_btn = bgm_btn
	bgm_btn.custom_minimum_size = Vector2(110, 56)
	bgm_btn.set_anchors_preset(PRESET_TOP_RIGHT)
	bgm_btn.offset_left = -130
	bgm_btn.offset_right = -18
	bgm_btn.offset_top = 16 + _safe_top()
	bgm_btn.offset_bottom = 72 + _safe_top()
	title_layer.add_child(bgm_btn)
	# 最下部中央のコピーライト表記
	var cr := _label(COPYRIGHT, 22, COL_CREAM, false)
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr.add_theme_color_override("font_outline_color", COL_WOOD_D)
	cr.add_theme_constant_override("outline_size", 8)
	cr.set_anchors_preset(PRESET_BOTTOM_WIDE)
	cr.offset_top = -52
	cr.offset_bottom = -16
	title_layer.add_child(cr)
	_title_main(v)


func _title_main(v: VBoxContainer) -> void:
	for ch in v.get_children():
		ch.queue_free()
	# タイトルロゴ（ui/title_logo.svg）を画面の真ん中あたりに
	var top_sp := Control.new()
	top_sp.custom_minimum_size = Vector2(0, 150)
	top_sp.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(top_sp)
	var logo := TextureRect.new()
	logo.texture = TITLE_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 450)
	logo.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(logo)
	_pop_in(logo)
	var sp := Control.new()
	sp.size_flags_vertical = SIZE_EXPAND_FILL
	sp.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(sp)
	if Game.has_save():
		v.add_child(_button("つづきから", func():
			if Game.load_game():
				Sfx.play("hamster")
				_close_title()
			else:
				_show_toast("セーブデータを読み込めませんでした"), true, COL_GREEN, 30))
	v.add_child(_button("はじめから", _title_new.bind(v), true, COL_WOOD, 30))


## ロゴがふわっと弾んで現れる演出
func _pop_in(node: Control) -> void:
	node.modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(0.85, 0.85)
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "modulate:a", 1.0, 0.35)
	tw.tween_property(node, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _title_new(v: VBoxContainer) -> void:
	for ch in v.get_children():
		ch.queue_free()
	var card := _card(v)
	card.add_child(_title("あたらしい牧場主", 30))
	card.add_child(_label("なまえ", 22, COL_SUB))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "なまえを入力（空欄でおまかせ）"
	_name_edit.max_length = 8
	_name_edit.custom_minimum_size = Vector2(0, 64)
	_name_edit.add_theme_font_size_override("font_size", 26)
	card.add_child(_name_edit)
	card.add_child(_label("主人公", 22, COL_SUB))
	var preview := DrawBox.new(func(ci):
		var s: Vector2 = ci.size
		Art.player(ci, Rect2(s.x / 2 - 60, 0, 120, s.y), _new_gender, {}, {})
		Art.hamster(ci, Vector2(s.x / 2 + 110, s.y * 0.85), 30, "golden", {"hat": "mini_straw"}), Vector2(0, 250))
	card.add_child(preview)
	var r := _hbox(card)
	for gspec in [["boy", "男の子"], ["girl", "女の子"]]:
		var b := _button(gspec[1], func():
			_new_gender = gspec[0]
			_title_new(v), true, COL_GREEN if _new_gender == gspec[0] else COL_WOOD)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		r.add_child(b)
	card.add_child(_label("男の子：チェック柄シャツ＋ワークパンツ／女の子：ナチュラルコットンのカントリーワンピース（共通：デニムのオーバーオール）", 18, COL_SUB))
	var start := _button("はじめる", func():
		if Game.has_save():
			Game.delete_save()
		Game.new_game(_name_edit.text, _new_gender)
		Sfx.play("hamster")
		_close_title()
		_show_intro(), true, COL_GREEN, 30)
	v.add_child(start)
	v.add_child(_button("もどる", _title_main.bind(v), true, COL_SUB, 24))


func _on_title_bgm_pressed() -> void:
	Sfx.cycle_bgm_volume()
	if is_instance_valid(_title_bgm_btn):
		_title_bgm_btn.text = "♪ " + Sfx.bgm_volume_name()


func _close_title() -> void:
	Sfx.play_bgm("main", 1.8)
	if title_layer != null:
		title_layer.queue_free()
		title_layer = null
	current_tab = "farm"
	_refresh()
	_rebuild_tab(true)
	_check_event_popup()


func _show_intro() -> void:
	open_popup("ようこそ、%s！" % Game.player_name, func(box: VBoxContainer):
		box.add_child(DrawBox.new(_paint_morning, Vector2(0, 150)))
		box.add_child(_label("ゴールデンハムスターの「きなこ」がお手伝いに来てくれました！", 22))
		box.add_child(_label("・畑：たねを選んで空いたマスをタップ → 水やり → 収穫\n・料理：収穫物を料理して熟練度ランクを上げよう\n・出荷：毎日売れるけど相場は変動\n・バザー：2週間に1度、高値で売れる大チャンス！\n・おやすみ：体力回復＆次の日へ（自動セーブ）", 21, COL_SUB))
		box.add_child(_button("スローライフをはじめる", close_popup, true, COL_GREEN)))


func _paint_title(ci: CanvasItem) -> void:
	var s: Vector2 = ci.size
	ci.draw_rect(Rect2(Vector2.ZERO, s), Color("fdf1d8"))
	ci.draw_rect(Rect2(0, 0, s.x, s.y * 0.55), Color("cfe8f5"))
	ci.draw_circle(Vector2(s.x * 0.82, s.y * 0.08), 60, Color("f7d358"))
	for k in 3:
		var cx := s.x * (0.15 + k * 0.32)
		for j in 3:
			ci.draw_circle(Vector2(cx + j * 34, s.y * (0.05 + 0.03 * k)), 26, Color(1, 1, 1, 0.9))
	Art.ellipse(ci, Vector2(s.x * 0.2, s.y * 0.62), s.x * 0.7, s.y * 0.16, Color("9fd67a"))
	Art.ellipse(ci, Vector2(s.x * 0.9, s.y * 0.64), s.x * 0.6, s.y * 0.15, Color("8cc56a"))
	ci.draw_rect(Rect2(0, s.y * 0.6, s.x, s.y * 0.4), Color("7fb35a"))
	# 納屋
	var bx := s.x * 0.64
	var by := s.y * 0.5
	Art.poly(ci, [Vector2(bx, by + 60), Vector2(bx + 100, by), Vector2(bx + 200, by + 60)], Color("8b3a2f"))
	ci.draw_rect(Rect2(bx + 15, by + 58, 170, 110), Color("c0504d"))
	ci.draw_rect(Rect2(bx + 70, by + 100, 60, 68), Color("f3e6c8"))
	ci.draw_line(Vector2(bx + 70, by + 100), Vector2(bx + 130, by + 168), Color("c0504d"), 5)
	ci.draw_line(Vector2(bx + 130, by + 100), Vector2(bx + 70, by + 168), Color("c0504d"), 5)
	# 柵
	var fy := s.y * 0.66
	ci.draw_line(Vector2(0, fy), Vector2(s.x, fy), Color("a0703f"), 8)
	ci.draw_line(Vector2(0, fy + 26), Vector2(s.x, fy + 26), Color("a0703f"), 8)
	var x := 10.0
	while x < s.x:
		Art.rrect(ci, Rect2(x, fy - 22, 16, 64), Color("b5835a"), 4)
		x += 70
	# ハムスターたち
	var ks := GameData.HAMSTER_ORDER
	var outfits := [{"hat": "mini_straw"}, {"hat": "mini_chef"}, {}, {"body": "mini_overall"}, {"hat": "mini_knit"}]
	for i in ks.size():
		Art.hamster(ci, Vector2(s.x * (0.12 + i * 0.19), s.y * 0.73 + (i % 2) * 18), 40, ks[i], outfits[i])
