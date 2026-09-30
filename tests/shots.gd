extends Node
## 画面キャプチャ（開発用）

func _ready() -> void:
	await get_tree().process_frame
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main._skip_splash()
	await get_tree().create_timer(main.SPLASH_FADE_OUT + 0.2).timeout
	await get_tree().create_timer(1.0).timeout
	await _shot("00_title")
	main._title_new(main.title_layer.get_child(1).get_child(0))
	await _wait(4)
	await _shot("01_newgame")
	Game.new_game("ミナ", "girl")
	main._close_title()
	Game.gold = 8800
	Game.farm_level = 3
	Game.farm_xp = 150
	var crops := ["turnip", "potato", "wheat", "strawberry", "flower", "herb", "turnip", "potato", "strawberry", "wheat", "flower", "herb"]
	for i in 12:
		Game.plots[i] = {"crop": crops[i], "growth": i % 6, "watered": i % 3 != 0}
	Game.inventory = {"turnip": 5, "strawberry": 4, "milk": 6, "egg": 5, "wood": 20, "wheat": 6, "flour": 2, "butter": 2, "wool": 3, "cotton": 4, "flower": 4, "pound_cake": 2, "dye": 2}
	Game.known_recipes.append_array(["pound_cake", "pancake", "strawberry_tart", "cream_stew"])
	Game.mastery = {"pound_cake": 13, "butter": 6}
	Game.animals.append(Game._new_animal("cow"))
	Game.animals.append(Game._new_animal("sheep"))
	for h in ["jungarian", "robo", "kinkuma"]:
		Game.hire(h)
	Game.furniture = {"stove": 1, "quilt": 1, "wood_table": 1, "dry_flower": 1, "rocking_chair": 1, "candle_lamp": 1, "knit_rug": 1}
	Game.wardrobe = {"straw_hat": 1, "apron": 1, "mini_straw": 1, "mini_overall": 1, "mini_chef": 1}
	Game.outfit = {"hat": "straw_hat", "top": "apron"}
	Game.cloth_colors = {"apron": 2}
	Game.hamsters["golden"]["outfit"] = {"hat": "mini_straw", "body": "mini_overall"}
	Game.hamsters["jungarian"]["outfit"] = {"hat": "mini_chef", "body": ""}
	Game.changed.emit()
	main.close_popup()
	await _wait(4)
	for t in main.TABS:
		main._switch_tab(t[0])
		await _wait(4)
		await _shot("tab_" + t[0])
	main._switch_tab("farm")
	main.scroll.scroll_vertical = 600
	await _wait(3)
	await _shot("tab_farm_2")
	Game.day = 14
	Game.bazaar_visitors_left = Game.bazaar_capacity()
	main._switch_tab("bazaar")
	await _wait(3)
	await _shot("bazaar_open")
	Game.season = 0
	Game.day = 20
	main._open_event()
	await _wait(4)
	main._egg_tap(0)
	main._egg_tap(5)
	await _wait(4)
	await _shot("event_egg")
	main.close_popup()
	Game.day = 7
	main._do_sleep()
	await _wait(4)
	await _shot("morning")
	main.close_popup()
	Game.season = 0
	Game.day = 13
	main._switch_tab("farm")
	await _wait(4)
	await _shot("badges_farm")
	main._on_sleep_pressed()
	await _wait(6)
	await _shot("sleep_todo")
	main.close_popup()
	for i in Game.plot_count():
		Game.plots[i] = {"crop": "", "growth": 0, "watered": false}
	Game.care_all()
	for h in Game.hamsters:
		Game.pet(h)
	Game.requests = []
	Game.day = 12
	main._refresh()
	await get_tree().create_timer(0.9).timeout
	await _shot("sleep_glow")
	main._on_sleep_pressed()
	await _wait(6)
	await _shot("sleep_done")
	main.close_popup()
	main._switch_tab("home")
	await _wait(8)
	main.scroll.scroll_vertical = 5000
	await _wait(6)
	await _shot("home_settings")
	get_tree().quit()


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/claude-0/shots/%s.png" % name)
