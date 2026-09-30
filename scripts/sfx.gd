extends Node
## サウンドマネージャー（オートロード "Sfx"）。
## 効果音：Sfx.play("water") のように名前で鳴らします。音は res://sounds/<名前>.wav。
## BGM：Sfx.play_bgm("title") / ("main") で res://sounds/bgm_<名前>.ogg をループ再生（切り替えはクロスフェード）。
## 効果音・BGMそれぞれの音量は user://settings.cfg に保存されます。

const SETTINGS_PATH := "user://settings.cfg"
const NAMES := ["water", "harvest", "plant", "hamster", "steps", "cook", "jingle", "page", "tap", "coin", "sleep", "error"]
# 連打で機械的に聞こえないよう、ピッチを少しだけゆらす音
const VARY := {"water": 0.06, "harvest": 0.04, "plant": 0.06, "tap": 0.05, "page": 0.08, "steps": 0.05, "coin": 0.02}
const VOLUMES := [0.0, 0.35, 0.7, 1.0]
const VOLUME_NAMES := ["オフ", "小", "中", "大"]
const BGM_VOLUMES := [0.0, 0.3, 0.55, 0.85]

var streams := {}
var players: Array[AudioStreamPlayer] = []
var volume_level := 2
var play_count := 0
var _last_play := {}
var bgm_level := 2
var bgm: AudioStreamPlayer
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var bgm_name := ""
var _bgm_tween: Tween


func _ready() -> void:
	for n in NAMES:
		var s = load("res://sounds/%s.wav" % n)
		if s:
			streams[n] = s
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	_bgm_a = AudioStreamPlayer.new()
	_bgm_b = AudioStreamPlayer.new()
	add_child(_bgm_a)
	add_child(_bgm_b)
	bgm = _bgm_a
	_load_settings()


func play(name: String, delay := 0.0) -> void:
	play_count += 1
	if volume_level <= 0 or not streams.has(name):
		return
	# 同じ音の同時多重再生を防ぐ（まとめて水やり等）
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(name, -1000)) < 45 and delay == 0.0:
		return
	_last_play[name] = now
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(_start.bind(name))
	else:
		_start(name)


func _start(name: String) -> void:
	var p := _free_player()
	p.stream = streams[name]
	p.volume_db = linear_to_db(VOLUMES[volume_level])
	var v: float = VARY.get(name, 0.0)
	p.pitch_scale = 1.0 + randf_range(-v, v)
	p.play()


func _free_player() -> AudioStreamPlayer:
	for p in players:
		if not p.playing:
			return p
	return players[0]


func cycle_volume() -> void:
	volume_level = (volume_level + 1) % VOLUMES.size()
	_save_settings()
	play("tap")


func volume_name() -> String:
	return VOLUME_NAMES[volume_level]


# ── BGM ──────────────────────────────────────────
# 2台のプレイヤーを交互に使い、曲の切り替えはクロスフェードします。
func bgm_target_db() -> float:
	return linear_to_db(max(0.0001, BGM_VOLUMES[bgm_level]))


func play_bgm(name: String, fade := 1.0) -> void:
	if bgm_name == name and bgm.playing:
		return
	var s = load("res://sounds/bgm_%s.ogg" % name)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	bgm_name = name
	_kill_tween()
	var old := bgm
	bgm = _bgm_b if bgm == _bgm_a else _bgm_a
	bgm.stream = s
	bgm.volume_db = -40.0
	bgm.play()
	_bgm_tween = create_tween().set_parallel(true)
	_bgm_tween.tween_property(bgm, "volume_db", bgm_target_db(), fade).set_trans(Tween.TRANS_SINE)
	if old.playing:
		_bgm_tween.tween_property(old, "volume_db", -50.0, fade * 0.9).set_trans(Tween.TRANS_SINE)
		_bgm_tween.chain().tween_callback(old.stop)


func stop_bgm(fade := 1.2) -> void:
	bgm_name = ""
	if not bgm.playing:
		return
	_kill_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(bgm, "volume_db", -50.0, fade).set_trans(Tween.TRANS_SINE)
	_bgm_tween.tween_callback(bgm.stop)


func _kill_tween() -> void:
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	# 途中で止めたフェードアウト側は止めておく
	for p in [_bgm_a, _bgm_b]:
		if p != bgm and p.playing:
			p.stop()


func cycle_bgm_volume() -> void:
	bgm_level = (bgm_level + 1) % BGM_VOLUMES.size()
	_save_settings()
	if bgm.playing and bgm_name != "":
		_kill_tween()
		bgm.volume_db = bgm_target_db()
	play("tap")


func bgm_volume_name() -> String:
	return VOLUME_NAMES[bgm_level]


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		volume_level = clampi(int(cf.get_value("audio", "sfx_level", 2)), 0, VOLUMES.size() - 1)
		bgm_level = clampi(int(cf.get_value("audio", "bgm_level", 2)), 0, BGM_VOLUMES.size() - 1)


func _save_settings() -> void:
	set_setting("audio", "sfx_level", volume_level)
	set_setting("audio", "bgm_level", bgm_level)


## 汎用の設定読み書き（user://settings.cfg。ほかの設定を消さないよう読み込んでから書く）
func get_setting(section: String, key: String, default):
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		return cf.get_value(section, key, default)
	return default


func set_setting(section: String, key: String, value) -> void:
	var cf := ConfigFile.new()
	cf.load(SETTINGS_PATH)
	cf.set_value(section, key, value)
	cf.save(SETTINGS_PATH)
