extends Node
## 自動テスト：ゲームロジック一通り＋全画面の表示を確認します。
## 実行: godot --headless --path . res://tests/test_runner.tscn

var fails := 0
var checks := 0


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("  FAIL: ", msg)


func _ready() -> void:
	await get_tree().process_frame
	await _logic_tests()
	_badge_tests()
	await _ui_tests()
	print("\n%d checks, %d failures" % [checks, fails])
	print("ALL TESTS PASSED" if fails == 0 else "TESTS FAILED")
	get_tree().quit(0 if fails == 0 else 1)


func _logic_tests() -> void:
	print("== logic ==")
	Game.new_game("テスト", "girl")
	ok(Game.started and Game.player_name == "テスト", "new game")
	ok(Game.hamsters.has("golden"), "free golden hamster")
	ok(Game.gold == 500 and Game.stamina == 100, "start gold/stamina")

	# 畑
	Game.select_seed("turnip")
	Game.tap_plot(0)
	ok(Game.plots[0]["crop"] == "turnip", "planted turnip")
	ok(Game.gold == 480, "seed cost")
	Game.tap_plot(0)
	ok(Game.plots[0]["watered"], "watered")
	for d in 3:
		Game.sleep()
	ok(Game.is_ripe(0), "turnip ripe after 3 nights (golden waters)")
	Game.tap_plot(0)
	ok(Game.count("turnip") >= 1, "harvest turnip")
	ok(Game.farm_xp > 0, "farm xp")
	Game.select_seed("tomato")
	var g := Game.gold
	Game.tap_plot(1)
	ok(Game.plots[1]["crop"] == "" and Game.gold == g, "cannot plant summer crop in spring")

	# 動物
	Game.care(0)
	ok(Game.animals[0]["fed"], "care chicken")
	var eggs := Game.count("egg") + Game.count("egg_gold")
	Game.sleep()
	ok(Game.count("egg") + Game.count("egg_gold") == eggs + 1, "egg produced")

	# 料理・ひらめき
	Game.inventory["milk"] = 6
	Game.inventory["wheat"] = 4
	Game.inventory["egg"] = 3
	Game.cook("butter")
	ok(Game.count("butter") == 1, "cook butter")
	ok("pound_cake" in Game.known_recipes, "flash pound cake from butter")
	Game.cook("flour")
	ok("pancake" in Game.known_recipes, "flash pancake from flour")
	Game.cook("pound_cake")
	ok(Game.count("pound_cake") == 1, "cook pound cake")
	Game.mastery["pound_cake"] = 12
	ok(Game.rank("pound_cake") == 2 and Game.item_value("pound_cake") == 860, "rank 3 price x2")

	# 出荷・相場
	var before_price := Game.market_price("turnip")
	Game.inventory["turnip"] = 10
	g = Game.gold
	Game.sell("turnip", 5)
	ok(Game.gold > g and Game.count("turnip") == 5, "sell")
	ok(Game.market_price("turnip") < before_price, "price drops after selling")

	# 倉庫
	Game.inventory = {}
	for i in 8:
		Game.inventory[GameData.CROPS.keys()[i]] = 1
	ok(Game.add_item("cabbage", 1) == 0, "storage slots full")
	Game.gold = 5000
	Game.inventory["wood"] = 12
	Game.inventory.erase(GameData.CROPS.keys()[0])
	Game.upgrade_storage()
	ok(Game.storage_level == 1, "storage upgrade")
	ok(Game.add_item("cabbage", 1) == 1, "space after upgrade")

	# バザー
	Game.day = 13
	Game.sleep()
	ok(Game.day == 14 and Game.is_bazaar_day(), "bazaar day 14")
	ok(Game.bazaar_visitors_left > 0, "bazaar visitors")
	Game.inventory["cabbage"] = 3
	g = Game.gold
	Game.bazaar_sell("cabbage", 1)
	ok(Game.gold - g == Game.bazaar_price("cabbage") and Game.bazaar_price("cabbage") > Game.item_value("cabbage"), "bazaar sell high")
	Game.buy_bazaar_recipe("apple_pie")
	ok("apple_pie" in Game.known_recipes, "buy bazaar recipe")

	# ハムスター
	Game.gold = 5000
	Game.hire("jungarian")
	ok(Game.hamsters.has("jungarian"), "hire jungarian")
	ok(Game.cook_cost() == Game.COST_COOK - 2, "jungarian lowers cook cost")
	for i in 3:
		Game.sleep()
	ok(Game.ham_level("jungarian") >= 2 and "cookie" in Game.known_recipes, "hamster level up teaches cookie")

	# クラフト
	Game.inventory["wood"] = 20
	Game.inventory["flower"] = 5
	Game.inventory["cotton"] = 5
	Game.stamina = 100
	Game.craft("wood_table")
	ok(Game.furniture.has("wood_table") and Game.rest_amount() == 65, "craft furniture")
	Game.craft("dye")
	ok(Game.count("dye") >= 1, "craft dye")
	Game.craft("apron")
	Game.equip("apron")
	ok(Game.outfit["top"] == "apron", "equip apron")
	Game.dye_cloth("apron")
	ok(int(Game.cloth_colors.get("apron", 0)) == 1, "dye apron")
	Game.craft("mini_chef")
	Game.ham_equip("golden", "mini_chef")
	ok(Game.hamsters["golden"]["outfit"]["hat"] == "mini_chef", "hamster outfit")
	Game.ham_equip("jungarian", "mini_chef")
	ok(Game.hamsters["jungarian"]["outfit"]["hat"] == "", "outfit not shared")

	# 村人
	Game.inventory["pound_cake"] = 3
	Game.gift("marie", "pound_cake")
	ok(int(Game.villagers["marie"]["friend"]) == 32, "gift favorite master dish = 32pts")
	Game.add_friend("marie", 10)
	ok("cream_stew" in Game.known_recipes, "friendship teaches recipe")
	ok(Game.requests.size() > 0, "requests exist")
	var q: Dictionary = Game.requests[0]
	Game.inventory[q["item"]] = int(q["qty"])
	g = Game.gold
	Game.fulfill(0)
	ok(Game.gold > g, "fulfill request")

	# イベント
	Game.season = 2
	Game.day = 8
	ok(Game.event_today() == "pie_contest", "pie contest day")
	Game.inventory["pumpkin_pie"] = 1
	Game.mastery["pumpkin_pie"] = 12
	var res := Game.contest_submit("pie_contest", "pumpkin_pie")
	ok(res.contains("位入賞") or res.contains("入賞ならず"), "contest result")
	ok(Game.event_done_today(), "event done")
	Game.season = 3
	Game.inventory["cream_stew"] = 2
	var f0 := int(Game.villagers["tom"]["friend"])
	ok(Game.soup_serve("cream_stew") != "" and int(Game.villagers["tom"]["friend"]) > f0, "soup fair")
	Game.season = 1
	Game.day = 20
	Game.events_done = {}
	Game.inventory["corn"] = 1
	Game.known_recipes.erase("veggie_skewer")
	Game.bbq_contribute("corn")
	ok("veggie_skewer" in Game.known_recipes, "bbq teaches skewer")
	Game.season = 0
	Game.day = 20
	ok(Game.egg_hunt_finish(3, true) != "" and Game.event_done_today(), "egg hunt")
	Game.season = 2
	Game.day = 21
	ok(Game.is_bazaar_day() and Game.bazaar_mult() >= 3.0, "craft market x3")

	# 季節の移り変わり
	Game.season = 0
	Game.day = 28
	Game.plots[2] = {"crop": "strawberry", "growth": 1, "watered": false}
	Game.sleep()
	ok(Game.season == 1 and Game.day == 1 and Game.plots[2]["crop"] == "", "season change withers")
	Game.season = 3
	Game.day = 28
	var y := Game.year
	Game.sleep()
	ok(Game.year == y + 1 and Game.season == 0, "new year")

	# セーブ・ロード
	Game.gold = 12345
	Game.save_game()
	var inv_before := Game.inventory.duplicate(true)
	Game.gold = 0
	ok(Game.load_game(), "load")
	ok(Game.gold == 12345, "gold restored")
	ok(typeof(Game.gold) == TYPE_INT and typeof(Game.plots[0]["growth"]) == TYPE_INT, "ints restored")
	var same := Game.inventory.size() == inv_before.size()
	for k in inv_before:
		if Game.count(k) != int(inv_before[k]):
			same = false
	ok(same, "inventory restored")
	ok(Game.hamsters["golden"]["outfit"]["hat"] == "mini_chef", "outfit restored")

	# ロングラン：100日ランダム操作でエラーが出ないこと
	Game.new_game("", "boy")
	for d in 120:
		for k in 6:
			var i := randi() % Game.plot_count()
			var seeds: Array = []
			for c in GameData.CROPS:
				if Game.crop_in_season(c) and Game.crop_unlocked(c):
					seeds.append(c)
			if seeds.size() > 0:
				Game.select_seed(seeds[randi() % seeds.size()])
			Game.tap_plot(i)
		Game.care_all()
		for r in Game.known_recipes:
			if Game.cook_error(r) == "":
				Game.cook(r)
		if Game.is_bazaar_day():
			for id in Game.inventory.keys():
				Game.bazaar_sell(id, 2)
		elif Game.slots_used() >= Game.storage_info()["slots"] - 1:
			for id in Game.inventory.keys():
				Game.sell(id, Game.count(id))
		Game.sleep()
	ok(Game.total_days == 121, "120 days simulated")
	print("  after 120 days: gold=%d farmLv=%d recipes=%d" % [Game.gold, Game.farm_level, Game.known_recipes.size()])


func _badge_tests() -> void:
	print("== badges ==")
	Game.new_game("B", "boy")
	var b := Game.tab_badges()
	ok(b.get("ranch", {}).get("kind") == "red" and b["ranch"]["text"] == "1", "ranch red: unfed chicken")
	ok(b.get("hamster", {}).get("kind") == "red", "hamster red: not petted")
	ok(not b.has("farm"), "farm: nothing to do on empty field")
	ok(Game.requests_new and b.get("village", {}).get("kind") in ["new", "green", "orange"], "village badge for fresh requests")
	Game.mark_seen("village")
	ok(not Game.tab_badges().has("village") or Game.tab_badges()["village"]["kind"] != "new", "village NEW cleared")
	# 畑：植えて水やり前 → 赤1、水やり後 → なし、実ったら → 赤1
	Game.select_seed("turnip")
	Game.tap_plot(0)
	ok(Game.tab_badges()["farm"] == {"kind": "red", "text": "1"}, "farm red after planting (needs water)")
	Game.tap_plot(0)
	ok(not Game.tab_badges().has("farm"), "farm clear after watering")
	Game.plots[0]["growth"] = 3
	ok(Game.tab_badges()["farm"]["text"] == "1", "farm red when ripe")
	# 優先度：赤 > 緑（ハムスター：なでてない赤 と 雇える緑）
	Game.gold = 99999
	ok(Game.tab_badges()["hamster"]["kind"] == "red", "red beats green")
	Game.pet("golden")
	ok(Game.tab_badges()["hamster"] == {"kind": "green", "text": "4"}, "green count of hireable hamsters")
	# 料理：作れる数 と NEW
	Game.inventory["milk"] = 2
	var cb: Dictionary = Game.tab_badges()["kitchen"]
	ok(cb["kind"] == "green" and int(cb["text"]) >= 2, "kitchen green count")
	Game.stamina = 100
	Game.cook("butter")
	ok("pound_cake" in Game.new_recipes, "flash recipe marked new")
	Game.mark_seen("kitchen")
	ok(Game.new_recipes.is_empty(), "kitchen NEW cleared")
	Game.inventory.erase("egg")
	Game.inventory.erase("butter")
	Game.inventory.erase("milk")
	ok(not Game.tab_badges().has("kitchen") or Game.tab_badges()["kitchen"]["kind"] != "new", "no stale NEW")
	# おうち NEW
	Game.inventory["wood"] = 6
	Game.craft("wood_table")
	ok(Game.tab_badges()["home"]["kind"] == "new", "home NEW after crafting furniture")
	Game.mark_seen("home")
	ok(not Game.tab_badges().has("home"), "home NEW cleared")
	# 倉庫いっぱい
	Game.inventory = {}
	for i in 7:
		Game.inventory[GameData.CROPS.keys()[i]] = 1
	ok(Game.tab_badges()["storage"]["kind"] == "orange", "storage almost full warning")
	# バザー前日・当日
	Game.inventory = {"turnip": 3}
	Game.day = 13
	ok(Game.tab_badges()["bazaar"] == {"kind": "orange", "text": "明日"}, "bazaar tomorrow")
	Game.day = 14
	Game.bazaar_visitors_left = 5
	ok(Game.tab_badges()["bazaar"]["kind"] == "gold", "bazaar day gold")
	# 村：イベント当日
	Game.season = 0
	Game.day = 8
	Game.events_done = {}
	ok(Game.tab_badges()["village"]["kind"] == "gold", "event day gold")
	# やり残しリスト
	Game.day = 3
	var todo := Game.todo_list()
	var tabs: Array = []
	for t in todo:
		tabs.append(t[1])
	ok("ranch" in tabs and "farm" in tabs, "todo list has farm & ranch " + str(tabs))
	Game.care_all()
	Game.harvest_all()
	for h in Game.hamsters:
		Game.pet(h)
	Game.requests = []
	ok(Game.todo_list().is_empty(), "todo cleared")
	# 設定の保存がほかの設定を消さない
	Sfx.set_setting("ui", "badges", false)
	Sfx.cycle_volume()
	ok(Sfx.get_setting("ui", "badges", true) == false, "settings keep ui key")
	Sfx.set_setting("ui", "badges", true)
	for i in 3:
		Sfx.cycle_volume()


func _ui_tests() -> void:
	print("== ui ==")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	# ブートスプラッシュ → 自動でタイトルへ
	ok(main.splash_layer != null and main.title_layer == null, "splash shown first")
	ok(not Sfx.bgm.playing, "no bgm during splash")
	await get_tree().create_timer(main.SPLASH_FADE_IN + main.SPLASH_HOLD + 0.5).timeout
	ok(main.title_layer != null, "title appears after splash")
	await get_tree().create_timer(main.SPLASH_FADE_OUT + 0.2).timeout
	ok(main.splash_layer == null, "splash removed after fade out")
	# タップでスキップ
	main._show_splash()
	main._skip_splash()
	ok(main.title_layer != null, "tap skips splash")
	await get_tree().create_timer(main.SPLASH_FADE_OUT + 0.2).timeout
	ok(main.splash_layer == null, "skipped splash removed")
	ok(main.title_layer != null, "title shown")
	ok(Sfx.bgm.playing and Sfx.bgm_name == "title", "title bgm playing")
	ok(Sfx.bgm.stream is AudioStreamOggVorbis and Sfx.bgm.stream.loop, "title bgm loops")
	ok(Sfx.bgm.stream.get_length() > 39.0, "bgm length")
	var lv0 := Sfx.bgm_level
	main._on_title_bgm_pressed()
	ok(Sfx.bgm_level == (lv0 + 1) % 4 and main._title_bgm_btn.text.begins_with("♪"), "bgm volume button")
	while Sfx.bgm_level != lv0:
		Sfx.cycle_bgm_volume()
	var has_cr := false
	for ch in main.title_layer.get_children():
		if ch is Label and ch.text == "🄫NekoDaifuku Software":
			has_cr = true
	ok(has_cr, "copyright label")
	Game.new_game("UI", "boy")
	main._close_title()
	await get_tree().create_timer(2.2).timeout
	ok(Sfx.bgm.playing and Sfx.bgm_name == "main", "main bgm after title")
	ok(Sfx.bgm.stream.get_length() > 57.0 and Sfx.bgm.stream.loop, "main bgm loops")
	var n_playing := 0
	for p in [Sfx._bgm_a, Sfx._bgm_b]:
		if p.playing:
			n_playing += 1
	ok(n_playing == 1, "title bgm faded out (crossfade done)")
	Game.gold = 99999
	for h in GameData.HAMSTER_ORDER:
		Game.hire(h)
	# 効果音
	ok(Sfx.streams.size() == Sfx.NAMES.size(), "all sfx loaded")
	var names_played: Array = []
	var rec := func(n): names_played.append(n)
	Game.sfx.connect(rec)
	Game.select_seed("turnip")
	Game.tap_plot(3)
	Game.tap_plot(3)
	Game.plots[4] = {"crop": "turnip", "growth": 3, "watered": false}
	Game.tap_plot(4)
	Game.inventory["milk"] = 4
	Game.cook("butter")
	Game.sell("butter", 1)
	Game.pet("golden")
	Game.stamina = 0
	Game.water(3)
	Game.chop_wood()
	Game.stamina = 50
	ok(names_played == ["plant", "water", "harvest", "cook", "coin", "hamster", "error"], "sfx order " + str(names_played))
	Game.sfx.disconnect(rec)
	var pc := Sfx.play_count
	main._guard(func(): pass)
	ok(Sfx.play_count == pc + 1, "button tap sound")
	pc = Sfx.play_count
	main._guard(Game.cook.bind("butter"))
	ok(Sfx.play_count == pc + 1, "no double sound on actions")
	for c in GameData.CROPS:
		ok(main._crop_icon(c) != null, "crop icon " + c)
	for t in main.TABS:
		main._switch_tab(t[0])
		await get_tree().process_frame
		ok(main.content.get_child_count() > 1, "tab " + t[0])
	for ev_key in GameData.EVENTS:
		var parts: PackedStringArray = ev_key.split("-")
		Game.season = int(parts[0])
		Game.day = int(parts[1])
		Game.events_done = {}
		main._open_event()
		await get_tree().process_frame
		ok(main.popup_layer != null, "event popup " + GameData.EVENTS[ev_key])
		if GameData.EVENTS[ev_key] == "egg_hunt":
			for i in 12:
				main._egg_tap(i)
			ok(Game.event_done_today(), "egg hunt finished via ui")
		main.close_popup()
	# バッジ表示とおやすみボタン
	Game.new_game("UI2", "girl")
	main._refresh()
	ok(main.badge_nodes["ranch"]["panel"].visible and main.badge_nodes["ranch"]["label"].text == "1", "ranch badge shown")
	ok(not main.badge_nodes["farm"]["panel"].visible, "farm badge hidden")
	ok(main.sleep_btn.text == "おやすみ", "sleep not glowing with todos")
	main._toggle_badges()
	ok(not main.badge_nodes["ranch"]["panel"].visible, "badges off")
	main._toggle_badges()
	ok(main.badge_nodes["ranch"]["panel"].visible, "badges back on")
	Game.care_all()
	for h in Game.hamsters:
		Game.pet(h)
	Game.requests = []
	main._refresh()
	ok(main.sleep_btn.text == "おやすみ ✓" and main._sleep_glow != null, "sleep glows when all done")
	Game.tap_plot(0)
	main._refresh()
	ok(main.sleep_btn.text == "おやすみ" and main.sleep_btn.modulate == Color.WHITE, "glow stops when new todo")
	# おすすめハムスター（放置で登場・さわると消える）
	main.close_popup()
	main.helper_on = true
	main._idle = 0.0
	main._tick_idle(30.0)
	ok(main.helper_layer == null, "helper not yet at 30s")
	main._tick_idle(31.0)
	ok(main.helper_layer != null, "helper appears after 60s idle")
	var rc := Game.recommend()
	ok(rc["text"] != "" and GameData.HAMSTERS.has(rc["hamster"]) and Game.hamsters.has(rc["hamster"]), "recommendation valid")
	main._tick_idle(100.0)
	ok(main.helper_layer != null, "only one helper at a time")
	main._hide_helper("")
	ok(main.helper_layer == null, "helper dismissed by touch")
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	main._idle = 59.0
	main._input(ev)
	ok(main._idle == 0.0, "touch resets idle timer")
	main._on_sleep_pressed()
	main._tick_idle(70.0)
	ok(main.helper_layer == null, "no helper while popup open")
	main.close_popup()
	main._toggle_helper()
	main._tick_idle(70.0)
	ok(main.helper_layer == null and Sfx.get_setting("ui", "helper", true) == false, "helper off setting")
	main._toggle_helper()
	main._tick_idle(70.0)
	ok(main.helper_layer != null, "helper back on")
	main._hide_helper("kitchen")
	ok(main.current_tab == "kitchen", "go button switches tab")
	# どんな状況でもおすすめが作れる（ランダムに120日）
	var ok_all := true
	for d in 40:
		Game.sleep()
		var r2 := Game.recommend()
		if r2["text"] == "" or not Game.hamsters.has(r2["hamster"]):
			ok_all = false
	ok(ok_all, "recommend always valid over many days")
	main._on_sleep_pressed()
	await get_tree().process_frame
	main._do_sleep()
	await get_tree().process_frame
	ok(main.popup_layer != null, "morning report")
	main.close_popup()
	main._open_gift("lily")
	main._open_ham_outfit("golden")
	await get_tree().process_frame
	main.close_popup()
	await get_tree().process_frame
	main.queue_free()
	await get_tree().process_frame
