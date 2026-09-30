extends Node
## ゲーム全体の状態とルール（オートロード "Game"）。
## UI はこのノードの関数を呼び、changed シグナルで再描画します。

signal changed
signal toast(msg: String)
signal sfx(name: String)  ## 効果音（main.gd が Sfx に中継）

const SAVE_PATH := "user://hamuhamu_save.json"
const COST_WATER := 2
const COST_PLANT := 1
const COST_HARVEST := 1
const COST_CARE := 4
const COST_CHOP := 8
const COST_COOK := 5
const COST_CRAFT := 6
const RANK_AT := [0, 5, 12]          # 熟練度ランクに必要な作成回数
const RANK_MULT := [1.0, 1.4, 2.0]   # ランクごとの品質・価格倍率
const FARM_XP := [0, 40, 120, 260, 480]
const HAMSTER_XP := [0, 3, 7, 12, 18]
const MAX_PLOTS := 15
const MAX_ANIMALS := 6
const MAX_REQUESTS := 3

var started := false
var player_name := ""
var gender := "boy"
var year := 1
var season := 0
var day := 1
var total_days := 1
var gold := 500
var stamina := 100
var weather := "sunny"
var farm_level := 1
var farm_xp := 0
var selected_seed := "turnip"
var plots: Array = []
var storage_level := 0
var inventory: Dictionary = {}
var known_recipes: Array = []
var mastery: Dictionary = {}
var market: Dictionary = {}
var sold_today: Dictionary = {}
var hot_item := ""
var animals: Array = []
var hamsters: Dictionary = {}
var villagers: Dictionary = {}
var requests: Array = []
var furniture: Dictionary = {}
var wardrobe: Dictionary = {}
var outfit: Dictionary = {"hat": "", "top": ""}
var cloth_colors: Dictionary = {}
var bazaar_visitors_left := 0
var events_done: Dictionary = {}
var last_report: Array = []
# NEW バッジ用（タブを開くと既読になる）
var new_recipes: Array = []
var new_home: Array = []
var new_hamster: Array = []
var requests_new := false
var event_seen_key := ""


# ═════════════════════════════════════════════════════
# はじまり
# ═════════════════════════════════════════════════════
func new_game(p_name: String, p_gender: String) -> void:
	gender = p_gender
	player_name = p_name.strip_edges()
	if player_name == "":
		player_name = "ハル" if gender == "boy" else "ミナ"
	year = 1
	season = 0
	day = 1
	total_days = 1
	gold = 500
	weather = "sunny"
	farm_level = 1
	farm_xp = 0
	selected_seed = "turnip"
	plots = []
	for i in MAX_PLOTS:
		plots.append({"crop": "", "growth": 0, "watered": false})
	storage_level = 0
	inventory = {"wood": 4, "egg": 2}
	known_recipes = GameData.START_RECIPES.duplicate()
	mastery = {}
	market = {}
	for id in GameData.all_sellables():
		market[id] = 1.0
	sold_today = {}
	animals = [_new_animal("chicken")]
	hamsters = {"golden": _new_hamster()}
	villagers = {}
	for v in GameData.VILLAGERS:
		villagers[v] = {"friend": 0, "gifted": false, "taught": false}
	requests = []
	furniture = {}
	wardrobe = {}
	outfit = {"hat": "", "top": ""}
	cloth_colors = {}
	events_done = {}
	last_report = []
	new_recipes = []
	new_home = []
	new_hamster = []
	requests_new = false
	event_seen_key = ""
	_pick_hot_item()
	_gen_requests()
	stamina = max_stamina()
	bazaar_visitors_left = bazaar_capacity() if is_bazaar_day() else 0
	started = true
	save_game()
	changed.emit()


func _new_hamster() -> Dictionary:
	return {"xp": 0, "level": 1, "petted": false, "outfit": {"hat": "", "body": ""}}


func _new_animal(t: String) -> Dictionary:
	var names: Array = GameData.ANIMALS[t]["names"]
	var n: String = names[animals.size() % names.size()]
	return {"type": t, "name": n, "mood": 5, "fed": false, "timer": 0}


# ═════════════════════════════════════════════════════
# 日付・季節・イベント
# ═════════════════════════════════════════════════════
func season_name() -> String:
	return GameData.SEASONS[season]


func event_today() -> String:
	return GameData.EVENTS.get("%d-%d" % [season, day], "")


func event_key() -> String:
	return "%d-%d-%d" % [year, season, day]


func event_done_today() -> bool:
	return events_done.has(event_key())


func is_bazaar_day() -> bool:
	return day % 14 == 0 or event_today() == "craft_market"


func days_to_bazaar() -> int:
	return 14 - (day % 14)


func bazaar_mult() -> float:
	var m := 1.8
	if event_today() == "craft_market":
		m = 3.0
	if hamsters.has("campbell"):
		m += 0.2 + 0.05 * ham_level("campbell")
	return m


func bazaar_capacity() -> int:
	if event_today() == "craft_market":
		return 999
	var c := 12
	if hamsters.has("campbell"):
		c += 4 + 2 * ham_level("campbell")
	return c


func upcoming_events() -> Array:
	var out: Array = []
	for k in GameData.EVENTS:
		var parts: PackedStringArray = k.split("-")
		if int(parts[0]) == season and int(parts[1]) >= day:
			out.append({"day": int(parts[1]), "id": GameData.EVENTS[k]})
	out.sort_custom(func(a, b): return a["day"] < b["day"])
	return out


# ═════════════════════════════════════════════════════
# 体力
# ═════════════════════════════════════════════════════
func max_stamina() -> int:
	var m := 100
	for f in furniture:
		if int(furniture[f]) > 0:
			m += int(GameData.CRAFTS[f].get("max", 0))
	for slot in outfit:
		var c: String = outfit[slot]
		if c != "":
			m += int(GameData.CRAFTS[c].get("max", 0))
	return m


func rest_amount() -> int:
	var r := 60
	for f in furniture:
		if int(furniture[f]) > 0:
			r += int(GameData.CRAFTS[f].get("rest", 0))
	return r


func _fail(msg: String) -> void:
	toast.emit(msg)
	sfx.emit("error")


func use_stamina(n: int) -> bool:
	if stamina < n:
		_fail("体力が足りない…「おやすみ」で休もう")
		return false
	stamina -= n
	return true


# ═════════════════════════════════════════════════════
# 倉庫
# ═════════════════════════════════════════════════════
func storage_info() -> Dictionary:
	return GameData.STORAGE[storage_level]


func slots_used() -> int:
	var n := 0
	for k in inventory:
		if int(inventory[k]) > 0:
			n += 1
	return n


func count(id: String) -> int:
	return int(inventory.get(id, 0))


func space_for(id: String) -> int:
	var st := storage_info()
	var have := count(id)
	if have > 0:
		return max(0, int(st["stack"]) - have)
	if slots_used() >= int(st["slots"]):
		return 0
	return int(st["stack"])


func add_item(id: String, n: int) -> int:
	var k: int = min(n, space_for(id))
	if k <= 0:
		return 0
	inventory[id] = count(id) + k
	return k


func remove_item(id: String, n: int) -> bool:
	if count(id) < n:
		return false
	inventory[id] = count(id) - n
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	return true


func has_all(ing: Dictionary) -> bool:
	for k in ing:
		if count(k) < int(ing[k]):
			return false
	return true


func upgrade_storage() -> void:
	if storage_level >= GameData.STORAGE.size() - 1:
		return
	var nx: Dictionary = GameData.STORAGE[storage_level + 1]
	if gold < int(nx["cost"]) or count("wood") < int(nx["wood"]):
		_fail("お金か木材が足りません")
		return
	gold -= int(nx["cost"])
	remove_item("wood", int(nx["wood"]))
	storage_level += 1
	toast.emit("倉庫が「%s」になった！" % nx["name"])
	sfx.emit("jingle")
	changed.emit()


func sorted_inventory() -> Array:
	var ids: Array = inventory.keys()
	ids.sort_custom(func(a, b): return _cat_order(a) * 1000 + GameData.base_price(a) < _cat_order(b) * 1000 + GameData.base_price(b))
	return ids


func _cat_order(id: String) -> int:
	if GameData.is_crop(id):
		return 0
	if GameData.ITEMS.has(id):
		return 1
	return 2


# ═════════════════════════════════════════════════════
# 値段・熟練度
# ═════════════════════════════════════════════════════
func rank(r: String) -> int:
	var c := int(mastery.get(r, 0))
	var k := 0
	for i in RANK_AT.size():
		if c >= RANK_AT[i]:
			k = i
	return k


func item_value(id: String) -> int:
	var p := float(GameData.base_price(id))
	if GameData.is_dish(id):
		p *= RANK_MULT[rank(id)]
	return int(round(p))


func market_price(id: String) -> int:
	var f := float(market.get(id, 1.0))
	if id == hot_item:
		f *= 1.3
	return max(1, int(round(item_value(id) * f)))


func market_trend(id: String) -> int:
	var f := float(market.get(id, 1.0))
	if id == hot_item or f >= 1.12:
		return 1
	if f <= 0.88:
		return -1
	return 0


func bazaar_price(id: String) -> int:
	return int(round(item_value(id) * bazaar_mult()))


# ═════════════════════════════════════════════════════
# 農業
# ═════════════════════════════════════════════════════
func plot_count() -> int:
	var n := 9
	if farm_level >= 3:
		n += 3
	if farm_level >= 5:
		n += 3
	return n


func crop_in_season(c: String) -> bool:
	return season in GameData.CROPS[c]["seasons"]


func crop_unlocked(c: String) -> bool:
	return farm_level >= int(GameData.CROPS[c]["lv"])


func select_seed(c: String) -> void:
	selected_seed = c
	changed.emit()


func tap_plot(i: int) -> void:
	var p: Dictionary = plots[i]
	if p["crop"] == "":
		plant(i)
	elif is_ripe(i):
		harvest(i)
	elif not p["watered"]:
		water(i)
	else:
		var c: Dictionary = GameData.CROPS[p["crop"]]
		toast.emit("%sはすくすく育っています（あと%d日）" % [c["name"], int(c["days"]) - int(p["growth"])])


func is_ripe(i: int) -> bool:
	var p: Dictionary = plots[i]
	return p["crop"] != "" and int(p["growth"]) >= int(GameData.CROPS[p["crop"]]["days"])


func plant(i: int) -> void:
	var c := selected_seed
	if not GameData.CROPS.has(c):
		return
	var d: Dictionary = GameData.CROPS[c]
	if not crop_in_season(c):
		_fail("%sは今の季節には植えられません" % d["name"])
		return
	if not crop_unlocked(c):
		_fail("農業レベル%dで植えられるようになります" % d["lv"])
		return
	if gold < int(d["seed"]):
		_fail("たね代が足りません")
		return
	if not use_stamina(COST_PLANT):
		return
	gold -= int(d["seed"])
	plots[i] = {"crop": c, "growth": 0, "watered": weather == "rain"}
	sfx.emit("plant")
	changed.emit()


func water(i: int) -> void:
	var p: Dictionary = plots[i]
	if p["crop"] == "" or p["watered"] or is_ripe(i):
		return
	if not use_stamina(COST_WATER):
		return
	p["watered"] = true
	sfx.emit("water")
	changed.emit()


func water_all() -> void:
	var n := 0
	for i in plot_count():
		var p: Dictionary = plots[i]
		if p["crop"] != "" and not p["watered"] and not is_ripe(i):
			if stamina < COST_WATER:
				_fail("体力が足りない…")
				break
			stamina -= COST_WATER
			p["watered"] = true
			n += 1
	if n > 0:
		toast.emit("%dマスに水をやった" % n)
		sfx.emit("water")
	else:
		_fail("水やりが必要な畑はありません")
	changed.emit()


func harvest(i: int, by_hamster := false) -> bool:
	var p: Dictionary = plots[i]
	var c: String = p["crop"]
	if c == "" or not is_ripe(i):
		return false
	var amt := 1
	if randf() < 0.08 * farm_level:
		amt += 1
	if space_for(c) <= 0:
		if not by_hamster:
			_fail("倉庫がいっぱい！ 倉庫を広げるか出荷しよう")
		return false
	if not by_hamster and not use_stamina(COST_HARVEST):
		return false
	var got := add_item(c, amt)
	plots[i] = {"crop": "", "growth": 0, "watered": false}
	var xp := int(GameData.CROPS[c]["days"]) * 3
	if outfit.get("hat", "") == "straw_hat":
		xp = int(xp * 1.2)
	_add_farm_xp(xp)
	if not by_hamster:
		toast.emit("%sを%d個収穫！" % [GameData.CROPS[c]["name"], got])
		sfx.emit("harvest")
		changed.emit()
	return true


func harvest_all() -> void:
	var n := 0
	for i in plot_count():
		if is_ripe(i):
			if stamina < COST_HARVEST or space_for(plots[i]["crop"]) <= 0:
				break
			stamina -= COST_HARVEST
			if harvest(i, true):
				n += 1
	if n > 0:
		toast.emit("%dマス収穫した" % n)
		sfx.emit("harvest")
	else:
		_fail("収穫できる作物はありません")
	changed.emit()


func _add_farm_xp(n: int) -> void:
	farm_xp += n
	var lv := 1
	for i in FARM_XP.size():
		if farm_xp >= FARM_XP[i]:
			lv = i + 1
	if lv > farm_level:
		farm_level = lv
		var msg := "農業レベル%dにアップ！" % lv
		var news: Array = []
		for c in GameData.CROPS:
			if int(GameData.CROPS[c]["lv"]) == lv:
				news.append(GameData.CROPS[c]["name"])
		if news.size() > 0:
			msg += " 新しい作物：" + "・".join(news)
		if lv == 3 or lv == 5:
			msg += " 畑が3マス広がった！"
		toast.emit(msg)
		last_report.append(msg)


func farm_xp_progress() -> Array:
	if farm_level >= FARM_XP.size():
		return [1, 1]
	var a: int = FARM_XP[farm_level - 1]
	var b: int = FARM_XP[farm_level]
	return [farm_xp - a, b - a]


func chop_wood() -> void:
	if space_for("wood") <= 0:
		_fail("倉庫がいっぱい！")
		return
	if not use_stamina(COST_CHOP):
		return
	var got := add_item("wood", randi_range(2, 3))
	toast.emit("森で木材を%d個集めた" % got)
	sfx.emit("tap")
	changed.emit()


# ═════════════════════════════════════════════════════
# 牧場
# ═════════════════════════════════════════════════════
func buy_animal(t: String) -> void:
	var d: Dictionary = GameData.ANIMALS[t]
	if animals.size() >= MAX_ANIMALS:
		_fail("牧場がいっぱいです")
		return
	if gold < int(d["price"]):
		_fail("お金が足りません")
		return
	gold -= int(d["price"])
	var a := _new_animal(t)
	animals.append(a)
	toast.emit("%sの「%s」がやってきた！" % [d["name"], a["name"]])
	sfx.emit("jingle")
	changed.emit()


func care(i: int) -> void:
	var a: Dictionary = animals[i]
	if a["fed"]:
		toast.emit("%sは満足そう" % a["name"])
		return
	if not use_stamina(COST_CARE):
		return
	a["fed"] = true
	a["mood"] = min(10, int(a["mood"]) + 2)
	toast.emit("%sをブラッシングしてエサをあげた" % a["name"])
	sfx.emit("plant")
	changed.emit()


func care_all() -> void:
	var n := 0
	for a in animals:
		if not a["fed"]:
			if stamina < COST_CARE:
				_fail("体力が足りない…")
				break
			stamina -= COST_CARE
			a["fed"] = true
			a["mood"] = min(10, int(a["mood"]) + 2)
			n += 1
	if n > 0:
		toast.emit("%d頭のお世話をした" % n)
		sfx.emit("plant")
	changed.emit()


# ═════════════════════════════════════════════════════
# 料理
# ═════════════════════════════════════════════════════
func cook_cost() -> int:
	var c := COST_COOK
	if hamsters.has("jungarian"):
		c -= 2
	if outfit.get("top", "") == "apron":
		c -= 1
	return max(1, c)


func cook_error(r: String) -> String:
	if not r in known_recipes:
		return "レシピを知らない"
	if not has_all(GameData.RECIPES[r]["ing"]):
		return "材料が足りない"
	if stamina < cook_cost():
		return "体力が足りない"
	return ""


func cook(r: String) -> void:
	var err := cook_error(r)
	if err != "":
		_fail(err)
		return
	var ing: Dictionary = GameData.RECIPES[r]["ing"]
	for k in ing:
		remove_item(k, int(ing[k]))
	if add_item(r, 1) == 0:
		for k in ing:
			inventory[k] = count(k) + int(ing[k])
		_fail("倉庫がいっぱいで作れません")
		return
	stamina -= cook_cost()
	var before := rank(r)
	var gain := 1
	if hamsters.has("jungarian") and randf() < 0.4 + 0.1 * ham_level("jungarian"):
		gain += 1
	mastery[r] = int(mastery.get(r, 0)) + gain
	var msg := "%sができた！" % GameData.RECIPES[r]["name"]
	var after := rank(r)
	if after > before:
		msg += (" 熟練度ランク%dにUP！" % (after + 1)) + (" マスター！" if after == 2 else "")
	toast.emit(msg)
	sfx.emit("cook")
	if GameData.FLASH.has(r):
		learn(GameData.FLASH[r], "ひらめいた！")
	changed.emit()


func learn(r: String, how: String) -> bool:
	if r in known_recipes:
		return false
	known_recipes.append(r)
	if not r in new_recipes:
		new_recipes.append(r)
	var msg := "%s 新レシピ「%s」" % [how, GameData.RECIPES[r]["name"]]
	toast.emit(msg)
	last_report.append(msg)
	return true


func rank_progress(r: String) -> Array:
	var k := rank(r)
	if k >= RANK_AT.size() - 1:
		return [1, 1]
	var c := int(mastery.get(r, 0))
	return [c - int(RANK_AT[k]), int(RANK_AT[k + 1]) - int(RANK_AT[k])]


func eat(id: String) -> void:
	if not GameData.is_dish(id) or count(id) <= 0:
		return
	if stamina >= max_stamina():
		_fail("おなかいっぱい")
		return
	var heal := 10 + 10 * rank(id) + int(GameData.base_price(id) / 40.0)
	remove_item(id, 1)
	stamina = min(max_stamina(), stamina + heal)
	toast.emit("%sを食べて体力が%d回復！" % [GameData.item_name(id), heal])
	sfx.emit("coin")
	changed.emit()


# ═════════════════════════════════════════════════════
# 出荷・バザー
# ═════════════════════════════════════════════════════
func sell(id: String, n: int) -> void:
	var total := 0
	var sold := 0
	for k in n:
		if count(id) <= 0:
			break
		var p := market_price(id)
		total += p
		sold += 1
		remove_item(id, 1)
		market[id] = max(0.5, float(market.get(id, 1.0)) - 0.03)
	if sold == 0:
		return
	sold_today[id] = int(sold_today.get(id, 0)) + sold
	gold += total
	toast.emit("%s×%d を %dG で出荷した" % [GameData.item_name(id), sold, total])
	sfx.emit("coin")
	changed.emit()


func bazaar_sell(id: String, n: int) -> void:
	if not is_bazaar_day():
		return
	var total := 0
	var sold := 0
	for k in n:
		if count(id) <= 0 or bazaar_visitors_left <= 0:
			break
		total += bazaar_price(id)
		sold += 1
		remove_item(id, 1)
		bazaar_visitors_left -= 1
	if sold == 0:
		_fail("お客さんがもういません")
		return
	gold += total
	toast.emit("バザーで %s×%d が %dG で売れた！" % [GameData.item_name(id), sold, total])
	sfx.emit("coin")
	changed.emit()


func buy_bazaar_recipe(r: String) -> void:
	if not is_bazaar_day() or r in known_recipes:
		return
	var p: int = GameData.BAZAAR_RECIPES[r]
	if gold < p:
		_fail("お金が足りません")
		return
	gold -= p
	learn(r, "露店で購入！")
	sfx.emit("jingle")
	changed.emit()


func buy_bazaar_goods(id: String, qty: int, price: int) -> void:
	if not is_bazaar_day():
		return
	if gold < price:
		_fail("お金が足りません")
		return
	if space_for(id) < qty:
		_fail("倉庫がいっぱいです")
		return
	gold -= price
	add_item(id, qty)
	toast.emit("%s×%dを買った" % [GameData.item_name(id), qty])
	sfx.emit("coin")
	changed.emit()


func _pick_hot_item() -> void:
	var pool: Array = []
	for c in GameData.CROPS:
		if crop_in_season(c):
			pool.append(c)
	for r in known_recipes:
		pool.append(r)
	hot_item = pool[randi() % pool.size()] if pool.size() > 0 else ""


# ═════════════════════════════════════════════════════
# 工房（クラフト）・おうち
# ═════════════════════════════════════════════════════
func owned(id: String) -> int:
	var cat: String = GameData.CRAFTS[id]["cat"]
	if cat == "furniture":
		return int(furniture.get(id, 0))
	if cat == "material":
		return count(id)
	return int(wardrobe.get(id, 0))


func craft_error(id: String) -> String:
	var d: Dictionary = GameData.CRAFTS[id]
	if d.has("shop"):
		return "冬の市で販売"
	if (d["cat"] == "furniture" or d["cat"] == "cloth") and owned(id) > 0:
		return "もう持っている"
	if not has_all(d["mats"]):
		return "素材が足りない"
	if gold < int(d["gold"]):
		return "お金が足りない"
	if stamina < COST_CRAFT:
		return "体力が足りない"
	if d["cat"] == "material" and space_for(id) <= 0:
		return "倉庫がいっぱい"
	return ""


func craft(id: String) -> void:
	var err := craft_error(id)
	if err != "":
		_fail(err)
		return
	var d: Dictionary = GameData.CRAFTS[id]
	for k in d["mats"]:
		remove_item(k, int(d["mats"][k]))
	gold -= int(d["gold"])
	stamina -= COST_CRAFT
	_give_craft(id)
	toast.emit("工房で「%s」を作った！" % d["name"])
	sfx.emit("jingle")
	changed.emit()


func _give_craft(id: String) -> void:
	var cat: String = GameData.CRAFTS[id]["cat"]
	match cat:
		"material":
			add_item(id, 1)
		"furniture":
			furniture[id] = int(furniture.get(id, 0)) + 1
			new_home.append(id)
		"hamster":
			wardrobe[id] = int(wardrobe.get(id, 0)) + 1
			new_hamster.append(id)
		_:
			wardrobe[id] = int(wardrobe.get(id, 0)) + 1
			new_home.append(id)


func shop_price(id: String) -> int:
	if id == "knit":
		return GameData.KNIT_SHOP_PRICE
	return int(GameData.CRAFTS[id].get("shop", 0))


func buy_shop(id: String) -> void:
	var p := shop_price(id)
	var cat: String = GameData.CRAFTS[id]["cat"]
	if (cat == "furniture" or cat == "cloth") and owned(id) > 0:
		_fail("もう持っています")
		return
	if gold < p:
		_fail("お金が足りません")
		return
	gold -= p
	_give_craft(id)
	toast.emit("「%s」を買った！" % GameData.CRAFTS[id]["name"])
	sfx.emit("jingle")
	changed.emit()


func equip(id: String) -> void:
	if owned(id) <= 0:
		return
	var slot: String = GameData.CRAFTS[id]["slot"]
	if outfit.get(slot, "") == id:
		outfit[slot] = ""
		toast.emit("%sをぬいだ" % GameData.CRAFTS[id]["name"])
		sfx.emit("page")
	else:
		outfit[slot] = id
		toast.emit("%sを着た！" % GameData.CRAFTS[id]["name"])
		sfx.emit("page")
	stamina = min(stamina, max_stamina())
	changed.emit()


func cloth_color(id: String) -> Color:
	return Color(GameData.CLOTH_COLORS[int(cloth_colors.get(id, 0))])


func dye_cloth(id: String) -> void:
	if count("dye") <= 0:
		_fail("ナチュラル染料が必要です（工房で作れます）")
		return
	remove_item("dye", 1)
	var ci := (int(cloth_colors.get(id, 0)) + 1) % GameData.CLOTH_COLORS.size()
	cloth_colors[id] = ci
	toast.emit("%sを%s色に染めた" % [GameData.CRAFTS[id]["name"], GameData.CLOTH_COLOR_NAMES[ci]])
	sfx.emit("jingle")
	changed.emit()


# ═════════════════════════════════════════════════════
# ハムスター
# ═════════════════════════════════════════════════════
func ham_level(h: String) -> int:
	if not hamsters.has(h):
		return 0
	return int(hamsters[h]["level"])


func hire(h: String) -> void:
	if hamsters.has(h):
		return
	var cost := int(GameData.HAMSTERS[h]["hire"])
	if gold < cost:
		_fail("お金が足りません")
		return
	gold -= cost
	hamsters[h] = _new_hamster()
	sfx.emit("steps")
	sfx.emit("hamster")
	toast.emit("%sの「%s」がお手伝いに来てくれた！" % [GameData.HAMSTERS[h]["type"], GameData.HAMSTERS[h]["name"]])
	changed.emit()


func pet(h: String) -> void:
	if not hamsters.has(h) or hamsters[h]["petted"]:
		return
	hamsters[h]["petted"] = true
	toast.emit("%sをなでなで… うれしそう！" % GameData.HAMSTERS[h]["name"])
	sfx.emit("hamster")
	_ham_xp(h, 1)
	changed.emit()


func _ham_xp(h: String, n: int) -> void:
	var hs: Dictionary = hamsters[h]
	hs["xp"] = int(hs["xp"]) + n
	var lv := 1
	for i in HAMSTER_XP.size():
		if int(hs["xp"]) >= HAMSTER_XP[i]:
			lv = i + 1
	while int(hs["level"]) < lv:
		hs["level"] = int(hs["level"]) + 1
		var d: Dictionary = GameData.HAMSTERS[h]
		var msg := "%sがLv%dになった！" % [d["name"], hs["level"]]
		toast.emit(msg)
		last_report.append(msg)
		var key := str(hs["level"])
		if d["teach"].has(key):
			learn(d["teach"][key], "%sのお礼！" % d["name"])


func ham_xp_progress(h: String) -> Array:
	var lv := ham_level(h)
	if lv >= HAMSTER_XP.size():
		return [1, 1]
	var xp := int(hamsters[h]["xp"])
	return [xp - int(HAMSTER_XP[lv - 1]), int(HAMSTER_XP[lv]) - int(HAMSTER_XP[lv - 1])]


func outfit_free(id: String, for_h: String) -> bool:
	var used := 0
	for h in hamsters:
		if h == for_h:
			continue
		for s in hamsters[h]["outfit"]:
			if hamsters[h]["outfit"][s] == id:
				used += 1
	return int(wardrobe.get(id, 0)) - used > 0


func ham_equip(h: String, id: String) -> void:
	if not hamsters.has(h):
		return
	var slot: String = GameData.CRAFTS[id]["slot"]
	var o: Dictionary = hamsters[h]["outfit"]
	if o.get(slot, "") == id:
		o[slot] = ""
	else:
		if not outfit_free(id, h):
			_fail("ほかの子が着ています（もう1着作ろう）")
			return
		o[slot] = id
		toast.emit("%sが%sを着た！ かわいい！" % [GameData.HAMSTERS[h]["name"], GameData.CRAFTS[id]["name"]])
		sfx.emit("hamster")
	changed.emit()


# ═════════════════════════════════════════════════════
# 村人・掲示板
# ═════════════════════════════════════════════════════
func hearts(v: String) -> int:
	return int(int(villagers[v]["friend"]) / 20)


func gift_points(v: String, id: String) -> int:
	var d: Dictionary = GameData.VILLAGERS[v]
	var pts := 2
	if GameData.is_dish(id):
		pts = 4 + 4 * (rank(id) + 1)
	var fav: bool = id in d["fav_items"]
	for t in GameData.tags(id):
		if t in d["fav_tags"]:
			fav = true
	if fav:
		pts *= 2
	return pts


func gift(v: String, id: String) -> void:
	var st: Dictionary = villagers[v]
	if st["gifted"] or count(id) <= 0:
		return
	var pts := gift_points(v, id)
	remove_item(id, 1)
	st["gifted"] = true
	var d: Dictionary = GameData.VILLAGERS[v]
	var reaction := "大好物！ ありがとう！" if pts >= 16 else ("わあ、うれしい！" if pts >= 8 else "ありがとう。")
	toast.emit("%s「%s」 友情度+%d" % [d["name"], reaction, pts])
	sfx.emit("jingle")
	add_friend(v, pts)
	changed.emit()


func add_friend(v: String, n: int) -> void:
	var st: Dictionary = villagers[v]
	st["friend"] = min(100, int(st["friend"]) + n)
	if int(st["friend"]) >= GameData.TEACH_FRIENDSHIP and not st["taught"]:
		st["taught"] = true
		learn(GameData.VILLAGERS[v]["teach"], "%sが得意料理を教えてくれた！" % GameData.VILLAGERS[v]["name"])


func _gen_requests() -> void:
	var keep: Array = []
	for r in requests:
		if int(r["days"]) > 0:
			keep.append(r)
	requests = keep
	var pool: Array = []
	for c in GameData.CROPS:
		if crop_in_season(c) and crop_unlocked(c):
			pool.append(c)
	var types := {}
	for a in animals:
		types[a["type"]] = true
	for t in types:
		pool.append(GameData.ANIMALS[t]["product"])
	for r in known_recipes:
		pool.append(r)
	if pool.is_empty():
		return
	var vs: Array = GameData.VILLAGERS.keys()
	var guard := 0
	while requests.size() < MAX_REQUESTS and guard < 20:
		guard += 1
		var id: String = pool[randi() % pool.size()]
		var dup := false
		for r in requests:
			if r["item"] == id:
				dup = true
		if dup:
			continue
		var qty := 1
		if GameData.is_crop(id):
			qty = randi_range(2, 5)
		elif GameData.ITEMS.has(id):
			qty = randi_range(1, 3)
		else:
			qty = randi_range(1, 2)
		var mats := ["wood", "wool", "cotton", "dye"]
		requests.append({
			"villager": vs[randi() % vs.size()],
			"item": id,
			"qty": qty,
			"gold": int(GameData.base_price(id) * qty * 1.5) + 50,
			"reward": mats[randi() % mats.size()],
			"reward_qty": randi_range(1, 3),
			"days": 3,
		})
		requests_new = true


func fulfill(i: int) -> void:
	if i < 0 or i >= requests.size():
		return
	var r: Dictionary = requests[i]
	if count(r["item"]) < int(r["qty"]):
		_fail("まだ数が足りません")
		return
	remove_item(r["item"], int(r["qty"]))
	gold += int(r["gold"])
	var got := add_item(r["reward"], int(r["reward_qty"]))
	requests.remove_at(i)
	var vn: String = GameData.VILLAGERS[r["villager"]]["name"]
	var extra := "・%s×%d" % [GameData.item_name(r["reward"]), got] if got > 0 else ""
	toast.emit("%sの依頼を達成！ %dG%s 友情度+8" % [vn, r["gold"], extra])
	sfx.emit("coin")
	add_friend(r["villager"], 8)
	changed.emit()


# ═════════════════════════════════════════════════════
# 季節イベント
# ═════════════════════════════════════════════════════
func event_entries(ev: String) -> Array:
	var info: Dictionary = GameData.EVENT_INFO[ev]
	var out: Array = []
	for id in sorted_inventory():
		var ok := false
		if info.has("items") and id in info["items"]:
			ok = true
		if info.has("tag") and info["tag"] in GameData.tags(id):
			ok = true
		if ok:
			out.append(id)
	return out


func contest_submit(ev: String, id: String) -> String:
	if event_done_today() or count(id) <= 0:
		return ""
	var info: Dictionary = GameData.EVENT_INFO[ev]
	var target := float(info["target"])
	var score := item_value(id) * randf_range(0.92, 1.08)
	if GameData.is_crop(id):
		score *= 1.0 + 0.08 * farm_level
	var rivals := [target * randf_range(0.95, 1.05), target * randf_range(0.75, 0.85), target * randf_range(0.55, 0.65)]
	var place := 1
	for rv in rivals:
		if rv > score:
			place += 1
	remove_item(id, 1)
	events_done[event_key()] = true
	var prizes := [1500, 700, 300]
	var text := ""
	if place <= 3:
		gold += prizes[place - 1]
		text = "%d位入賞！ 賞金%dG" % [place, prizes[place - 1]]
		if place == 1:
			for v in villagers:
				add_friend(v, 6)
			var got := add_item("dye", 2)
			text += "\n優勝トロフィーと染料×%dをもらった！ 村のみんなの友情度+6" % got
	else:
		gold += 100
		text = "今回は入賞ならず… 参加賞100G"
	text = "「%s」を出品！ 審査点 %d\n%s" % [GameData.item_name(id), int(score), text]
	last_report.append(text)
	changed.emit()
	return text


func egg_hunt_tries() -> int:
	return 3 + hamsters.size()


func egg_hunt_finish(eggs: int, golden: bool) -> String:
	if event_done_today():
		return ""
	events_done[event_key()] = true
	var got := add_item("egg", eggs)
	var g := eggs * 80 + (500 if golden else 0)
	gold += g
	for h in hamsters:
		_ham_xp(h, 1)
	var t := "タマゴを%d個見つけた！ %dG%s" % [eggs, g, "（金のタマゴも！）" if golden else ""]
	if got < eggs:
		t += "\n倉庫がいっぱいで一部のタマゴは持ち帰れなかった"
	changed.emit()
	return t


func bbq_contribute(id: String) -> String:
	if event_done_today() or count(id) <= 0:
		return ""
	remove_item(id, 1)
	events_done[event_key()] = true
	var bonus := 10 if GameData.is_crop(id) else 20
	for v in villagers:
		add_friend(v, bonus)
	var learned := learn("veggie_skewer", "バーベキューで")
	changed.emit()
	return "「%s」をみんなで焼いて大盛り上がり！ 村のみんなの友情度+%d%s" % [GameData.item_name(id), bonus, "\n限定グリルレシピ「野菜の串焼き」を教わった！" if learned else ""]


func soup_serve(id: String) -> String:
	if count(id) <= 0 or event_today() != "soup_fair":
		return ""
	remove_item(id, 1)
	events_done[event_key()] = true
	var pts := 8 + 4 * rank(id)
	for v in villagers:
		add_friend(v, pts)
	for h in hamsters:
		_ham_xp(h, 1)
	gold += int(item_value(id) * 0.5)
	changed.emit()
	return "「%s」をふるまった！ 村人の友情度+%d・ハムスターたちもにっこり" % [GameData.item_name(id), pts]


# ═════════════════════════════════════════════════════
# おやすみ → 次の日
# ═════════════════════════════════════════════════════
func sleep() -> void:
	last_report = []
	# 作物の成長
	for i in plot_count():
		var p: Dictionary = plots[i]
		if p["crop"] != "" and p["watered"]:
			p["growth"] = min(int(p["growth"]) + 1, int(GameData.CROPS[p["crop"]]["days"]))
		p["watered"] = false

	# 日付
	day += 1
	total_days += 1
	if day > GameData.DAYS_PER_SEASON:
		day = 1
		season += 1
		if season > 3:
			season = 0
			year += 1
			last_report.append("%d年目がはじまりました！" % year)
		last_report.append("%sになりました。" % season_name())
		var withered := 0
		for i in plot_count():
			var p: Dictionary = plots[i]
			if p["crop"] != "" and not crop_in_season(p["crop"]):
				plots[i] = {"crop": "", "growth": 0, "watered": false}
				withered += 1
		if withered > 0:
			last_report.append("季節が変わり、%dマスの作物が枯れてしまった…" % withered)

	# 天気
	var r := randf()
	if season == 3:
		weather = "snow" if r < 0.25 else "sunny"
	else:
		weather = "rain" if r < 0.2 else "sunny"
	if weather == "rain":
		_water_everything()
		last_report.append("雨が畑をうるおしてくれた。")

	# ハムスターのお仕事
	for h in hamsters:
		hamsters[h]["petted"] = false
		_ham_xp(h, 1)
	if hamsters.has("golden") and weather != "rain":
		var n := _water_everything()
		if n > 0:
			last_report.append("きなこ（ゴールデン）が%dマスにまとめて水やりしてくれた。" % n)
	if hamsters.has("robo"):
		var got := 0
		for i in plot_count():
			if is_ripe(i) and harvest(i, true):
				got += 1
		if got > 0:
			last_report.append("ちび（ロボロフスキー）が%dマスを高速ダッシュ収穫！" % got)

	# 動物
	var produced := {}
	for a in animals:
		if hamsters.has("kinkuma"):
			a["mood"] = min(10, int(a["mood"]) + 1)
		var d: Dictionary = GameData.ANIMALS[a["type"]]
		if a["fed"]:
			a["timer"] = int(a["timer"]) + 1
			if int(a["timer"]) >= int(d["every"]):
				a["timer"] = 0
				var chance := (int(a["mood"]) - 5) * 0.08 + (0.25 if hamsters.has("kinkuma") else 0.0)
				var item: String = d["premium"] if randf() < chance else d["product"]
				var qty := 1
				if a["type"] == "sheep" and randf() < chance:
					qty = 2
				var got := add_item(item, qty)
				if got > 0:
					produced[item] = int(produced.get(item, 0)) + got
				else:
					last_report.append("倉庫がいっぱいで%sを受け取れなかった…" % GameData.item_name(item))
		else:
			a["mood"] = max(0, int(a["mood"]) - 2)
		a["fed"] = false
	if produced.size() > 0:
		var parts: Array = []
		for k in produced:
			parts.append("%s×%d" % [GameData.item_name(k), produced[k]])
		last_report.append("牧場でとれたもの：" + "・".join(parts))

	# 相場
	for id in market:
		var f := float(market[id])
		if not sold_today.has(id):
			f += 0.04
		f += randf_range(-0.07, 0.07)
		f = lerp(f, 1.0, 0.1)
		market[id] = clamp(f, 0.5, 1.5)
	sold_today = {}
	_pick_hot_item()

	# 掲示板・村人
	for q in requests:
		q["days"] = int(q["days"]) - 1
	_gen_requests()
	for v in villagers:
		villagers[v]["gifted"] = false

	stamina = min(max_stamina(), stamina + rest_amount())
	bazaar_visitors_left = bazaar_capacity() if is_bazaar_day() else 0
	if is_bazaar_day():
		last_report.append("今日はバザーの日！ 高値で売るチャンス。")
	var ev := event_today()
	if ev != "":
		last_report.append("今日は「%s」の日！" % GameData.EVENT_INFO[ev]["name"])
	save_game()
	changed.emit()


func _water_everything() -> int:
	var n := 0
	for i in plot_count():
		var p: Dictionary = plots[i]
		if p["crop"] != "" and not p["watered"] and not is_ripe(i):
			p["watered"] = true
			n += 1
	return n


# ═════════════════════════════════════════════════════
# タブのバッジ・やり残し
# ═════════════════════════════════════════════════════
## バッジの種類（優先度の高い順）
const BADGE_ORDER := ["red", "gold", "orange", "green", "new"]


func unwatered_count() -> int:
	var n := 0
	for i in plot_count():
		var p: Dictionary = plots[i]
		if p["crop"] != "" and not p["watered"] and not is_ripe(i):
			n += 1
	return n


func ripe_count() -> int:
	var n := 0
	for i in plot_count():
		if is_ripe(i):
			n += 1
	return n


func unfed_count() -> int:
	var n := 0
	for a in animals:
		if not a["fed"]:
			n += 1
	return n


func unpetted_count() -> int:
	var n := 0
	for h in hamsters:
		if not hamsters[h]["petted"]:
			n += 1
	return n


## 今日のイベントにまだ参加していない（参加の概念がない市は、村タブを見るまで）
func event_pending() -> bool:
	var ev := event_today()
	if ev == "":
		return false
	var t: String = GameData.EVENT_INFO[ev]["type"]
	if t in ["shop", "market"]:
		return event_seen_key != event_key()
	return not event_done_today()


func due_requests() -> int:
	var n := 0
	for r in requests:
		if int(r["days"]) <= 1:
			n += 1
	return n


func fulfillable_requests() -> int:
	var n := 0
	for r in requests:
		if count(r["item"]) >= int(r["qty"]):
			n += 1
	return n


func cookable_count() -> int:
	var n := 0
	for r in known_recipes:
		if cook_error(r) == "":
			n += 1
	return n


func craftable_count() -> int:
	var n := 0
	for id in GameData.CRAFTS:
		var cat: String = GameData.CRAFTS[id]["cat"]
		if cat == "material":
			continue
		if cat == "hamster" and owned(id) > 0:
			continue
		if craft_error(id) == "":
			n += 1
	return n


func hireable_count() -> int:
	var n := 0
	for h in GameData.HAMSTERS:
		if not hamsters.has(h) and gold >= int(GameData.HAMSTERS[h]["hire"]):
			n += 1
	return n


func has_good_price_item() -> bool:
	for id in inventory:
		if id == hot_item or market_trend(id) > 0:
			return true
	return false


func _is_bazaar_on(d: int, s: int) -> bool:
	return d % 14 == 0 or GameData.EVENTS.get("%d-%d" % [s, d], "") == "craft_market"


func bazaar_tomorrow() -> bool:
	var d := day + 1
	var s := season
	if d > GameData.DAYS_PER_SEASON:
		d = 1
		s = (season + 1) % 4
	return _is_bazaar_on(d, s)


func can_upgrade_storage() -> bool:
	if storage_level >= GameData.STORAGE.size() - 1:
		return false
	var nx: Dictionary = GameData.STORAGE[storage_level + 1]
	return gold >= int(nx["cost"]) and count("wood") >= int(nx["wood"])


## タブごとの候補バッジを集め、いちばん優先度の高い1つを返す。
## 戻り値 { タブ名: {"kind": 種類, "text": 表示文字} }（バッジなしのタブは入らない）
func tab_badges() -> Dictionary:
	var c := {}
	for t in ["farm", "ranch", "kitchen", "storage", "ship", "bazaar", "craft", "home", "village", "hamster"]:
		c[t] = []
	var n := unwatered_count() + ripe_count()
	if n > 0:
		c["farm"].append(["red", str(n)])
	n = unfed_count()
	if n > 0:
		c["ranch"].append(["red", str(n)])
	n = cookable_count()
	if n > 0:
		c["kitchen"].append(["green", str(n)])
	if not new_recipes.is_empty():
		c["kitchen"].append(["new", "NEW"])
	var st := storage_info()
	if slots_used() >= int(st["slots"]) - 1:
		c["storage"].append(["orange", "!"])
	if can_upgrade_storage():
		c["storage"].append(["green", "↑"])
	if not inventory.is_empty() and has_good_price_item() and not is_bazaar_day():
		c["ship"].append(["green", "↑"])
	if is_bazaar_day():
		var can_sell := bazaar_visitors_left > 0 and not inventory.is_empty()
		var can_buy := false
		for r in GameData.BAZAAR_RECIPES:
			if not r in known_recipes and gold >= int(GameData.BAZAAR_RECIPES[r]):
				can_buy = true
		if can_sell or can_buy:
			c["bazaar"].append(["gold", "★"])
	elif bazaar_tomorrow():
		c["bazaar"].append(["orange", "明日"])
	n = craftable_count()
	if n > 0:
		c["craft"].append(["green", str(n)])
	if not new_home.is_empty():
		c["home"].append(["new", "NEW"])
	if event_pending():
		c["village"].append(["gold", "★"])
	if due_requests() > 0:
		c["village"].append(["orange", "!"])
	n = fulfillable_requests()
	if n > 0:
		c["village"].append(["green", str(n)])
	if requests_new:
		c["village"].append(["new", "NEW"])
	n = unpetted_count()
	if n > 0:
		c["hamster"].append(["red", str(n)])
	n = hireable_count()
	if n > 0:
		c["hamster"].append(["green", str(n)])
	if not new_hamster.is_empty():
		c["hamster"].append(["new", "NEW"])
	var out := {}
	for t in c:
		var best: Array = []
		for cand in c[t]:
			if best.is_empty() or BADGE_ORDER.find(cand[0]) < BADGE_ORDER.find(best[0]):
				best = cand
		if not best.is_empty():
			out[t] = {"kind": best[0], "text": best[1]}
	return out


## タブを開いたら、そのタブの NEW を既読にする
func mark_seen(tab: String) -> void:
	match tab:
		"kitchen":
			new_recipes.clear()
		"home":
			new_home.clear()
		"hamster":
			new_hamster.clear()
		"village":
			requests_new = false
			if event_today() != "":
				event_seen_key = event_key()


## 放置したときにハムスターが教えてくれる「今のおすすめ」
## 戻り値 {"hamster": 話すハムスター, "text": セリフ, "tab": 行き先タブ（"sleep"はおやすみ）, "go": ボタン文言}
func recommend() -> Dictionary:
	var ev := event_today()
	if event_pending():
		return _rec("golden", "今日は「%s」の日だよ！\n村へ行ってみよう♪" % GameData.EVENT_INFO[ev]["name"], "village", "村へ行く")
	if is_bazaar_day() and bazaar_visitors_left > 0 and not inventory.is_empty():
		return _rec("campbell", "今日はバザーの日！\nいつもよりずっと高く売れるよ。\nお客さんを呼びこむね♪", "bazaar", "バザーへ行く")
	var n := unwatered_count()
	if n > 0:
		return _rec("golden", "水やりがまだの畑が%dマスあるよ。\n「まとめて水やり」が便利だよ！" % n, "farm", "畑へ行く")
	n = ripe_count()
	if n > 0:
		var crop := ""
		for i in plot_count():
			if is_ripe(i):
				crop = GameData.CROPS[plots[i]["crop"]]["name"]
				break
		return _rec("robo", "%sが実ってるよ！\nはやく収穫しよう〜！" % crop, "farm", "畑へ行く")
	for a in animals:
		if not a["fed"]:
			return _rec("kinkuma", "%sがおなかをすかせてるみたい。\nお世話してあげよう♪" % a["name"], "ranch", "牧場へ行く")
	for h in GameData.HAMSTER_ORDER:
		if hamsters.has(h) and not hamsters[h]["petted"]:
			return _rec(h, "ねえねえ…\nなでなでしてほしいな♪", "hamster", "なでに行く")
	for r in requests:
		if int(r["days"]) <= 1:
			var vn: String = GameData.VILLAGERS[r["villager"]]["name"]
			return _rec("golden", "%sさんの依頼、今日までだよ！\n%sを%d個ほしいんだって。" % [vn, GameData.item_name(r["item"]), r["qty"]], "village", "村へ行く")
	for r in requests:
		if count(r["item"]) >= int(r["qty"]):
			var vn: String = GameData.VILLAGERS[r["villager"]]["name"]
			return _rec("golden", "%sさんのほしがってる%s、\nもう持ってるよ！ わたしに行こう♪" % [vn, GameData.item_name(r["item"])], "village", "村へ行く")
	var best := ""
	for r in known_recipes:
		if cook_error(r) == "" and (best == "" or item_value(r) > item_value(best)):
			best = r
	if best != "":
		var extra := "マスターまであと少し！" if rank(best) == 1 else "作るほど腕が上がるよ。"
		return _rec("jungarian", "いまの材料で「%s」が作れるよ！\n%s" % [GameData.item_name(best), extra], "kitchen", "キッチンへ")
	if slots_used() >= int(storage_info()["slots"]) - 1:
		return _rec("robo", "倉庫がいっぱいになりそう…\n出荷するか、倉庫を広げよう！", "storage", "倉庫へ行く")
	if craftable_count() > 0:
		return _rec("golden", "工房で作れるものがあるよ。\nお部屋がもっとすてきになるかも♪", "craft", "工房へ行く")
	if bazaar_tomorrow():
		return _rec("campbell", "明日はバザーだよ！\nマスターした料理をためておくと\nがっぽり売れるよ♪", "kitchen", "キッチンへ")
	if stamina < 15:
		return _rec("golden", "体力が少なくなってきたね。\n今日はそろそろおやすみしよう♪", "sleep", "おやすみする")
	var empty := 0
	for i in plot_count():
		if plots[i]["crop"] == "":
			empty += 1
	if empty > 0 and stamina >= 5:
		var seed := ""
		for c in GameData.CROPS:
			if crop_in_season(c) and crop_unlocked(c) and gold >= int(GameData.CROPS[c]["seed"]):
				if seed == "" or int(GameData.CROPS[c]["sell"]) > int(GameData.CROPS[seed]["sell"]):
					seed = c
		if seed != "":
			return _rec("golden", "空いてる畑が%dマスあるよ。\n%sを植えてみない？" % [empty, GameData.CROPS[seed]["name"]], "farm", "畑へ行く")
	return _rec("golden", "今日もいっぱいがんばったね！\nゆっくりおやすみしよう♪", "sleep", "おやすみする")


func _rec(h: String, text: String, tab: String, go: String) -> Dictionary:
	# やとっていない子の出番なら、きなこ（最初からいる子）が代わりに話す
	if not hamsters.has(h):
		h = "golden" if hamsters.has("golden") else (hamsters.keys()[0] if not hamsters.is_empty() else "golden")
	return {"hamster": h, "text": text, "tab": tab, "go": go}


## おやすみ前に知らせる「やり残し」
func todo_list() -> Array:
	## 戻り値: [[文言, 行き先タブ], ...]
	var out: Array = []
	var n := unwatered_count()
	if n > 0:
		out.append(["水やりしていない畑が%dマスあります（今夜は育ちません）" % n, "farm"])
	n = ripe_count()
	if n > 0:
		out.append(["収穫できる作物が%dマスあります" % n, "farm"])
	n = unfed_count()
	if n > 0:
		out.append(["お世話していない動物が%d頭います（明日の収穫なし・ごきげんダウン）" % n, "ranch"])
	n = unpetted_count()
	if n > 0:
		out.append(["なでていないハムスターが%d匹います" % n, "hamster"])
	var ev := event_today()
	if ev != "" and not event_done_today() and not GameData.EVENT_INFO[ev]["type"] in ["shop", "market"]:
		out.append(["今日の「%s」にまだ参加していません" % GameData.EVENT_INFO[ev]["name"], "village"])
	if is_bazaar_day() and bazaar_visitors_left > 0 and not inventory.is_empty():
		out.append(["バザーにまだお客さんがいます（高値で売れるのは今日だけ）", "bazaar"])
	n = due_requests()
	if n > 0:
		out.append(["今日が期限の依頼が%d件あります" % n, "village"])
	return out


# ═════════════════════════════════════════════════════
# セーブ / ロード
# ═════════════════════════════════════════════════════
const SAVE_KEYS := ["player_name", "gender", "year", "season", "day", "total_days", "gold", "stamina",
	"weather", "farm_level", "farm_xp", "selected_seed", "plots", "storage_level", "inventory",
	"known_recipes", "mastery", "market", "sold_today", "hot_item", "animals", "hamsters", "villagers",
	"requests", "furniture", "wardrobe", "outfit", "cloth_colors", "bazaar_visitors_left", "events_done",
	"new_recipes", "new_home", "new_hamster", "requests_new", "event_seen_key"]


func to_dict() -> Dictionary:
	var d := {"version": 1}
	for k in SAVE_KEYS:
		d[k] = get(k)
	return d


func save_game() -> void:
	if not started:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict()))
		f.close()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	data = _intify(data)
	# 古いセーブデータにない項目の初期値
	new_recipes = []
	new_home = []
	new_hamster = []
	requests_new = false
	event_seen_key = ""
	for k in SAVE_KEYS:
		if data.has(k):
			if k == "market":
				var m := {}
				for id in data[k]:
					m[id] = float(data[k][id])
				market = m
			else:
				set(k, data[k])
	# 新しく追加されたデータへの対応
	for id in GameData.all_sellables():
		if not market.has(id):
			market[id] = 1.0
	while plots.size() < MAX_PLOTS:
		plots.append({"crop": "", "growth": 0, "watered": false})
	for v in GameData.VILLAGERS:
		if not villagers.has(v):
			villagers[v] = {"friend": 0, "gifted": false, "taught": false}
	started = true
	changed.emit()
	return true


func _intify(v):
	match typeof(v):
		TYPE_FLOAT:
			if v == floor(v):
				return int(v)
			return v
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = _intify(v[k])
			return d
		TYPE_ARRAY:
			var a: Array = []
			for x in v:
				a.append(_intify(x))
			return a
	return v


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
