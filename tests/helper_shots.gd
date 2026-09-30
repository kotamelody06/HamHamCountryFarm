extends Node
## おすすめハムスターの画面キャプチャ（開発用）

func _ready() -> void:
	await get_tree().process_frame
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main._skip_splash()
	await get_tree().create_timer(main.SPLASH_FADE_OUT + 0.2).timeout
	await _wait(4)
	Game.new_game("ミナ", "girl")
	main._close_title()
	main.close_popup()
	Game.gold = 3000
	Game.hire("jungarian")
	Game.hire("robo")
	Game.wardrobe = {"mini_straw": 1, "mini_chef": 1, "mini_overall": 1}
	Game.hamsters["golden"]["outfit"] = {"hat": "mini_straw", "body": "mini_overall"}
	Game.hamsters["jungarian"]["outfit"] = {"hat": "mini_chef", "body": ""}
	# 1) 水やり
	for i in 5:
		Game.plots[i] = {"crop": ["turnip", "potato", "wheat", "turnip", "strawberry"][i], "growth": 1, "watered": false}
	Game.requests = []
	main._switch_tab("farm")
	await _wait(4)
	main._show_helper()
	await get_tree().create_timer(1.3).timeout
	await _shot("helper_water")
	main._hide_helper("")
	await get_tree().create_timer(0.4).timeout
	# 2) 料理
	for i in Game.plot_count():
		Game.plots[i] = {"crop": "", "growth": 0, "watered": false}
	Game.care_all()
	for h in Game.hamsters:
		Game.pet(h)
	Game.inventory = {"flour": 2, "butter": 2, "egg": 3, "milk": 2}
	Game.known_recipes.append("pound_cake")
	Game.mastery["pound_cake"] = 7
	Game.stamina = 80
	main._switch_tab("kitchen")
	await _wait(4)
	main._show_helper()
	await get_tree().create_timer(1.3).timeout
	await _shot("helper_kitchen")
	main._hide_helper("")
	await get_tree().create_timer(0.4).timeout
	# 3) ぜんぶ片づいた
	Game.inventory = {}
	Game.stamina = 10
	main._switch_tab("home")
	await _wait(4)
	main._show_helper()
	await get_tree().create_timer(1.3).timeout
	await _shot("helper_done")
	get_tree().quit()


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/shots/%s.png" % name)
