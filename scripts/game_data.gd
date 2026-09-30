class_name GameData
extends RefCounted
## ゲームの固定データ（作物・料理・ハムスター・村人・クラフト・イベントなど）。
## バランス調整はこのファイルの数値を変更するだけで行えます。

const SEASONS := ["春", "夏", "秋", "冬"]
const SEASON_COLORS := ["f4b8c5", "8cc56a", "e39a4f", "a9cbe0"]
const DAYS_PER_SEASON := 28
const WEATHER_NAMES := {"sunny": "はれ", "rain": "あめ", "snow": "ゆき"}

# ── 作物 ─────────────────────────────────────────────
# seasons: 植えられる季節 (0春 1夏 2秋 3冬) / days: 収穫までの日数 / lv: 必要な農業レベル
const CROPS := {
	"turnip":     {"name": "かぶ",         "seasons": [0],       "days": 3, "seed": 20, "sell": 45,  "lv": 1, "color": "f3efe3", "kind": "root"},
	"potato":     {"name": "じゃがいも",   "seasons": [0],       "days": 4, "seed": 30, "sell": 70,  "lv": 1, "color": "c9a26b", "kind": "root"},
	"wheat":      {"name": "小麦",         "seasons": [0, 2],    "days": 4, "seed": 25, "sell": 55,  "lv": 1, "color": "e6c15a", "kind": "grain"},
	"flower":     {"name": "ラベンダー",   "seasons": [0, 1],    "days": 3, "seed": 25, "sell": 60,  "lv": 1, "color": "a58ad8", "kind": "flower"},
	"strawberry": {"name": "いちご",       "seasons": [0],       "days": 5, "seed": 60, "sell": 125, "lv": 2, "color": "e0434b", "kind": "fruit"},
	"herb":       {"name": "ハーブ",       "seasons": [0, 1, 2], "days": 3, "seed": 30, "sell": 60,  "lv": 2, "color": "6fae52", "kind": "leaf"},
	"tomato":     {"name": "トマト",       "seasons": [1],       "days": 4, "seed": 40, "sell": 90,  "lv": 1, "color": "e5533d", "kind": "fruit"},
	"corn":       {"name": "とうもろこし", "seasons": [1],       "days": 5, "seed": 50, "sell": 110, "lv": 2, "color": "f2c94c", "kind": "grain"},
	"cotton":     {"name": "わた",         "seasons": [1, 2],    "days": 5, "seed": 40, "sell": 85,  "lv": 2, "color": "fbfaf2", "kind": "cotton"},
	"blueberry":  {"name": "ブルーベリー", "seasons": [1],       "days": 6, "seed": 80, "sell": 170, "lv": 3, "color": "4f5fb0", "kind": "fruit"},
	"pumpkin":    {"name": "かぼちゃ",     "seasons": [2],       "days": 6, "seed": 70, "sell": 160, "lv": 2, "color": "e98a2e", "kind": "big"},
	"carrot":     {"name": "にんじん",     "seasons": [2, 3],    "days": 3, "seed": 25, "sell": 55,  "lv": 1, "color": "ee8a2a", "kind": "root"},
	"apple":      {"name": "りんご",       "seasons": [2],       "days": 6, "seed": 90, "sell": 185, "lv": 3, "color": "c9302c", "kind": "fruit"},
	"cabbage":    {"name": "キャベツ",     "seasons": [3],       "days": 5, "seed": 45, "sell": 100, "lv": 1, "color": "9ccc65", "kind": "big"},
}

# ── 畜産物・素材 ─────────────────────────────────────
const ITEMS := {
	"milk":      {"name": "ミルク",         "price": 60,  "color": "fffaf0", "kind": "milk"},
	"milk_gold": {"name": "特選ミルク",     "price": 150, "color": "f5d76e", "kind": "milk"},
	"egg":       {"name": "たまご",         "price": 35,  "color": "f7e3c0", "kind": "egg"},
	"egg_gold":  {"name": "特選たまご",     "price": 95,  "color": "f2c94c", "kind": "egg"},
	"wool":      {"name": "ウール",         "price": 110, "color": "f2ede0", "kind": "fluff"},
	"wood":      {"name": "木材",           "price": 15,  "color": "a0703f", "kind": "wood"},
	"dye":       {"name": "ナチュラル染料", "price": 90,  "color": "7a8b4a", "kind": "dye"},
}

# ── 料理・加工品 ─────────────────────────────────────
# tags: sweets / warm(あったか) / soup / pie / grill
const RECIPES := {
	"flour":           {"name": "小麦粉",               "ing": {"wheat": 2},                                       "price": 140, "tags": [],                 "color": "f7f1e1"},
	"butter":          {"name": "バター",               "ing": {"milk": 2},                                        "price": 150, "tags": [],                 "color": "f7dd7c"},
	"baked_potato":    {"name": "ベイクドポテト",       "ing": {"potato": 1},                                      "price": 110, "tags": ["grill", "warm"],  "color": "d4a55c"},
	"fried_egg":       {"name": "目玉焼き",             "ing": {"egg": 1},                                         "price": 60,  "tags": [],                 "color": "f6c945"},
	"pancake":         {"name": "パンケーキ",           "ing": {"flour": 1, "milk": 1, "egg": 1},                  "price": 320, "tags": ["sweets"],         "color": "d9a05b"},
	"pound_cake":      {"name": "パウンドケーキ",       "ing": {"flour": 1, "butter": 1, "egg": 1},                "price": 430, "tags": ["sweets"],         "color": "e0b060"},
	"bread":           {"name": "焼きたてパン",         "ing": {"flour": 1, "milk": 1},                            "price": 260, "tags": [],                 "color": "c98a45"},
	"pumpkin_soup":    {"name": "カボチャスープ",       "ing": {"pumpkin": 1, "milk": 1},                          "price": 320, "tags": ["warm", "soup"],   "color": "f0a040"},
	"cookie":          {"name": "バタークッキー",       "ing": {"flour": 1, "butter": 1},                          "price": 330, "tags": ["sweets"],         "color": "d8a868"},
	"strawberry_tart": {"name": "いちごタルト",         "ing": {"strawberry": 2, "flour": 1, "butter": 1},         "price": 640, "tags": ["sweets", "pie"],  "color": "e2505a"},
	"jam":             {"name": "いちごジャム",         "ing": {"strawberry": 2},                                  "price": 300, "tags": ["sweets"],         "color": "c6283a"},
	"juice":           {"name": "フレッシュジュース",   "ing": {"blueberry": 1, "apple": 1},                       "price": 440, "tags": [],                 "color": "8a4fa8"},
	"cheese":          {"name": "チーズ",               "ing": {"milk": 3},                                        "price": 260, "tags": [],                 "color": "f3cf55"},
	"dressing":        {"name": "ハーブドレッシング",   "ing": {"herb": 1, "egg": 1},                              "price": 160, "tags": [],                 "color": "a8c46a"},
	"potofeu":         {"name": "ポトフ",               "ing": {"potato": 1, "carrot": 1, "turnip": 1},            "price": 300, "tags": ["warm", "soup"],   "color": "e6b57a"},
	"pot_pie":         {"name": "ポットパイ",           "ing": {"flour": 1, "butter": 1, "milk": 1, "potato": 1},  "price": 660, "tags": ["warm", "pie"],    "color": "c7883e"},
	"sandwich":        {"name": "サンドイッチ",         "ing": {"bread": 1, "tomato": 1, "egg": 1},                "price": 490, "tags": [],                 "color": "e8c77a"},
	"cheese_omelet":   {"name": "チーズオムレツ",       "ing": {"egg": 2, "cheese": 1},                            "price": 390, "tags": ["warm"],           "color": "f5c63c"},
	"pumpkin_pie":     {"name": "パンプキンパイ",       "ing": {"pumpkin": 1, "flour": 1, "butter": 1},            "price": 580, "tags": ["sweets", "pie"],  "color": "de7f2a"},
	"apple_pie":       {"name": "アップルパイ",         "ing": {"apple": 2, "flour": 1, "butter": 1},              "price": 720, "tags": ["sweets", "pie"],  "color": "cf8b3b"},
	"corn_soup":       {"name": "コーンスープ",         "ing": {"corn": 1, "milk": 1},                             "price": 270, "tags": ["warm", "soup"],   "color": "f4d35e"},
	"blueberry_muffin":{"name": "ブルーベリーマフィン", "ing": {"blueberry": 1, "flour": 1, "egg": 1},             "price": 490, "tags": ["sweets"],         "color": "6a5aa8"},
	"cream_stew":      {"name": "クリームシチュー",     "ing": {"potato": 1, "carrot": 1, "milk": 1, "butter": 1}, "price": 540, "tags": ["warm", "soup"],   "color": "f4ead0"},
	"grilled_corn":    {"name": "焼きとうもろこし",     "ing": {"corn": 1, "butter": 1},                           "price": 310, "tags": ["grill"],          "color": "e2a83a"},
	"herb_tea":        {"name": "ハーブティー",         "ing": {"herb": 2},                                        "price": 200, "tags": ["warm"],           "color": "9fbf5a"},
	"cabbage_roll":    {"name": "ロールキャベツ",       "ing": {"cabbage": 1, "potato": 1},                        "price": 340, "tags": ["warm", "soup"],   "color": "8fbf5a"},
	"veggie_skewer":   {"name": "野菜の串焼き",         "ing": {"tomato": 1, "corn": 1, "potato": 1},              "price": 400, "tags": ["grill"],          "color": "d86a3a"},
}

const START_RECIPES := ["flour", "butter", "baked_potato", "fried_egg"]

# ひらめき：キーとなる料理を作ると新しいレシピを発見
const FLASH := {
	"butter": "pound_cake",
	"flour": "pancake",
	"bread": "sandwich",
	"cheese": "cheese_omelet",
	"pumpkin_soup": "pumpkin_pie",
}

# バザー露店限定レシピ（価格）
const BAZAAR_RECIPES := {"apple_pie": 800, "corn_soup": 400, "blueberry_muffin": 600}

# ── ハムスター ───────────────────────────────────────
const HAMSTERS := {
	"golden":    {"type": "ゴールデン",     "name": "きなこ", "field": "農業全般",   "skill": "まとめ水やり",       "desc": "毎朝、畑ぜんぶに水をやってくれる",               "hire": 0,   "fur": "e8a64a", "belly": "fff3dc", "scale": 1.0,  "teach": {"2": "bread", "4": "pumpkin_soup"}},
	"jungarian": {"type": "ジャンガリアン", "name": "ゴマ",   "field": "料理・加工", "skill": "キッチンのお手伝い", "desc": "料理の体力が少なくすみ、熟練度がたまりやすい",   "hire": 400, "fur": "a9a39b", "belly": "fbf8f2", "scale": 0.9,  "teach": {"2": "cookie", "4": "strawberry_tart"}},
	"robo":      {"type": "ロボロフスキー", "name": "ちび",   "field": "収穫・運搬", "skill": "高速ダッシュ収穫",   "desc": "毎朝、熟した作物を一瞬で収穫して倉庫へ運ぶ",     "hire": 450, "fur": "e9bf82", "belly": "fffaf0", "scale": 0.78, "teach": {"2": "jam", "4": "juice"}},
	"kinkuma":   {"type": "キンクマ",       "name": "くるみ", "field": "畜産・癒やし", "skill": "動物のなだめ",     "desc": "動物たちのご機嫌UP。特選ミルク・特選たまごが出やすい", "hire": 500, "fur": "d9974a", "belly": "f6d3a0", "scale": 1.05, "teach": {"2": "cheese", "4": "dressing"}},
	"campbell":  {"type": "キャンベル",     "name": "モカ",   "field": "バザー・商売", "skill": "呼び込み名人",     "desc": "バザーの来客数が増え、さらに高値で売れる",       "hire": 600, "fur": "9c8a70", "belly": "f3ecdd", "scale": 0.92, "teach": {"2": "potofeu", "4": "pot_pie"}},
}
const HAMSTER_ORDER := ["golden", "jungarian", "robo", "kinkuma", "campbell"]

# ── 動物 ─────────────────────────────────────────────
const ANIMALS := {
	"chicken": {"name": "ニワトリ", "price": 400,  "product": "egg",  "premium": "egg_gold",  "every": 1, "names": ["コッコ", "ピヨ", "たまこ", "ココ"]},
	"cow":     {"name": "ウシ",     "price": 1200, "product": "milk", "premium": "milk_gold", "every": 1, "names": ["ミルク", "モーモ", "ハナ", "ベル"]},
	"sheep":   {"name": "ヒツジ",   "price": 1000, "product": "wool", "premium": "wool",      "every": 3, "names": ["メリー", "もこ", "ふわり", "ラム"]},
}

# ── 村人 ─────────────────────────────────────────────
const VILLAGERS := {
	"marie": {"name": "マリー",   "job": "パン屋さん",   "color": "d98c6a", "fav_tags": ["sweets"], "fav_items": ["strawberry"], "teach": "cream_stew",   "line": "焼き菓子の甘い香りって、しあわせよね。"},
	"tom":   {"name": "トム",     "job": "牧場のおじさん", "color": "8a6a4a", "fav_tags": ["grill"],  "fav_items": ["corn"],       "teach": "grilled_corn", "line": "炭火でジュッと焼くのが一番うまいんだ。"},
	"lily":  {"name": "リリー",   "job": "お花屋さん",   "color": "b48ad0", "fav_tags": [],         "fav_items": ["flower", "herb", "herb_tea"], "teach": "herb_tea", "line": "ラベンダーの香りで、ぐっすり眠れるの。"},
	"jack":  {"name": "ジャック", "job": "木こり",       "color": "6f8f4a", "fav_tags": ["warm"],   "fav_items": ["potato"],     "teach": "cabbage_roll", "line": "寒い日は、あったかい煮込みに限るな。"},
}
const TEACH_FRIENDSHIP := 40

# ── クラフト（工房） ─────────────────────────────────
# cat: material / furniture / cloth / hamster   slot: 装備枠
# rest: 睡眠時の体力回復量UP / max: 最大体力UP / shop: キャンドルナイト限定販売価格
const CRAFTS := {
	"dye":          {"name": "ナチュラル染料",       "cat": "material",  "mats": {"flower": 2},             "gold": 0,   "desc": "服を アースカラーに染められる"},
	"wood_table":   {"name": "木のテーブル",         "cat": "furniture", "mats": {"wood": 6},               "gold": 0,   "rest": 5,  "desc": "木育のぬくもり。回復量+5"},
	"rocking_chair":{"name": "ロッキングチェア",     "cat": "furniture", "mats": {"wood": 10},              "gold": 0,   "rest": 10, "desc": "ゆらゆら休憩。回復量+10"},
	"dry_flower":   {"name": "ドライフラワー",       "cat": "furniture", "mats": {"flower": 3},             "gold": 0,   "rest": 5,  "desc": "壁にかける花束。回復量+5"},
	"stove":        {"name": "薪ストーブ",           "cat": "furniture", "mats": {"wood": 15},              "gold": 500, "rest": 20, "desc": "ぽかぽか。回復量+20"},
	"quilt":        {"name": "パッチワークキルト",   "cat": "furniture", "mats": {"cotton": 3, "wool": 2},  "gold": 0,   "rest": 10, "max": 20, "desc": "最大体力+20・回復量+10"},
	"candle_lamp":  {"name": "キャンドルランプ",     "cat": "furniture", "mats": {},                        "gold": 0,   "rest": 15, "shop": 700, "desc": "冬限定。回復量+15"},
	"knit_rug":     {"name": "ニットのラグ",         "cat": "furniture", "mats": {},                        "gold": 0,   "rest": 10, "max": 10, "shop": 600, "desc": "冬限定。最大体力+10・回復量+10"},
	"straw_hat":    {"name": "麦わら帽子",           "cat": "cloth", "slot": "hat", "mats": {"wheat": 3},   "gold": 0,   "desc": "農業の経験値+20%"},
	"apron":        {"name": "ガーデニングエプロン", "cat": "cloth", "slot": "top", "mats": {"cotton": 2},  "gold": 0,   "desc": "料理の体力-1"},
	"knit":         {"name": "ローゲージニット",     "cat": "cloth", "slot": "top", "mats": {"wool": 3},    "gold": 0,   "max": 10, "desc": "最大体力+10"},
	"mini_straw":   {"name": "ミニ麦わら帽子",       "cat": "hamster", "slot": "hat",  "mats": {"wheat": 1},              "gold": 0, "desc": "主人公とおそろい！"},
	"mini_chef":    {"name": "小さなコック帽",       "cat": "hamster", "slot": "hat",  "mats": {"cotton": 1},             "gold": 0, "desc": "キッチンが似合う"},
	"mini_overall": {"name": "ミニオーバーオール",   "cat": "hamster", "slot": "body", "mats": {"cotton": 1, "dye": 1},   "gold": 0, "desc": "主人公とおそろい！"},
	"mini_knit":    {"name": "ミニニット帽",         "cat": "hamster", "slot": "hat",  "mats": {},                        "gold": 0, "shop": 400, "desc": "冬限定のあったか帽子"},
}
const CRAFT_CATS := [["material", "素材"], ["furniture", "カントリーインテリア"], ["cloth", "ファッション"], ["hamster", "ハムスターのお着替え"]]
const CLOTH_COLORS := ["f1e0b8", "b5653a", "7d8f3c", "8c7b6a", "c9a06a"]
const CLOTH_COLOR_NAMES := ["きなり", "テラコッタ", "オリーブ", "トープ", "キャメル"]

# ── 倉庫 ─────────────────────────────────────────────
const STORAGE := [
	{"name": "小さな木箱",       "slots": 8,  "stack": 20,  "cost": 0,     "wood": 0},
	{"name": "木の収納棚",       "slots": 12, "stack": 40,  "cost": 800,   "wood": 10},
	{"name": "納屋の倉庫",       "slots": 18, "stack": 60,  "cost": 2000,  "wood": 25},
	{"name": "大きな納屋",       "slots": 24, "stack": 99,  "cost": 5000,  "wood": 40},
	{"name": "カントリーサイロ", "slots": 34, "stack": 999, "cost": 10000, "wood": 60},
]

# ── 季節のイベント ───────────────────────────────────
# キー: "季節-日"
const EVENTS := {
	"0-8": "flower_fest", "0-20": "egg_hunt",
	"1-8": "veg_contest", "1-20": "bbq",
	"2-8": "pie_contest", "2-21": "craft_market",
	"3-8": "soup_fair",   "3-20": "candle_night",
}
const EVENT_INFO := {
	"flower_fest":  {"name": "カントリーフラワーフェスティバル", "type": "contest", "target": 80,  "items": ["flower", "herb", "herb_tea"], "desc": "育てたお花やハーブのコンテスト。いちばん素敵なものを出品しよう。"},
	"egg_hunt":     {"name": "イースター・エッグハント",       "type": "egg_hunt", "desc": "ハムスターたちとタマゴ探し！ やとっているハムスターが多いほど探せる回数が増える。"},
	"veg_contest":  {"name": "大収穫！ベジタブルコンテスト",   "type": "contest", "target": 150, "items": ["tomato", "corn", "blueberry"], "desc": "夏野菜の品質対決。自慢の夏野菜を出品しよう。"},
	"bbq":          {"name": "スターライト・バーベキューナイト", "type": "bbq", "items": ["tomato", "corn", "potato", "baked_potato", "grilled_corn", "veggie_skewer"], "desc": "星空の下で食材を持ち寄るお祭り。1品持っていくと限定グリルレシピがもらえる。"},
	"pie_contest":  {"name": "アップル＆パンプキンパイコンテスト", "type": "contest", "target": 1000, "tag": "pie", "desc": "秋の味覚コンテスト。料理ランク3（マスター）のパイなら優勝も夢じゃない！"},
	"craft_market": {"name": "カントリー・クラフト＆マーケット", "type": "market", "desc": "年に一度の特大感謝祭！ 今日はバザーで何でも通常の3倍の値段で売れる。"},
	"soup_fair":    {"name": "ほっこりスープ＆シチューフェア", "type": "soup", "tag": "warm", "desc": "あったかい料理を振る舞おう。1品ごとに村人とハムスターの友情度が大きくUP。"},
	"candle_night": {"name": "キャンドルナイト＆あったかウール市", "type": "shop", "shop": ["knit", "candle_lamp", "knit_rug", "mini_knit"], "desc": "ニット衣装や限定家具が並ぶ、冬の夜の市。"},
}
const KNIT_SHOP_PRICE := 900


static func is_dish(id: String) -> bool:
	return RECIPES.has(id)


static func is_crop(id: String) -> bool:
	return CROPS.has(id)


static func item_name(id: String) -> String:
	if CROPS.has(id):
		return CROPS[id]["name"]
	if ITEMS.has(id):
		return ITEMS[id]["name"]
	if RECIPES.has(id):
		return RECIPES[id]["name"]
	if CRAFTS.has(id):
		return CRAFTS[id]["name"]
	return id


static func base_price(id: String) -> int:
	if CROPS.has(id):
		return int(CROPS[id]["sell"])
	if ITEMS.has(id):
		return int(ITEMS[id]["price"])
	if RECIPES.has(id):
		return int(RECIPES[id]["price"])
	return 10


static func item_color(id: String) -> Color:
	if CROPS.has(id):
		return Color(CROPS[id]["color"])
	if ITEMS.has(id):
		return Color(ITEMS[id]["color"])
	if RECIPES.has(id):
		return Color(RECIPES[id]["color"])
	return Color("cccccc")


static func tags(id: String) -> Array:
	if RECIPES.has(id):
		return RECIPES[id]["tags"]
	return []


static func all_sellables() -> Array:
	var out: Array = []
	out.append_array(CROPS.keys())
	out.append_array(ITEMS.keys())
	out.append_array(RECIPES.keys())
	return out


static func recipe_source(id: String) -> String:
	if id in START_RECIPES:
		return "はじめから"
	for k in FLASH:
		if FLASH[k] == id:
			return "「%s」を作るとひらめく" % item_name(k)
	for h in HAMSTERS:
		var t: Dictionary = HAMSTERS[h]["teach"]
		for lv in t:
			if t[lv] == id:
				return "%s Lv%sのお礼" % [HAMSTERS[h]["type"], lv]
	if BAZAAR_RECIPES.has(id):
		return "バザーの露店"
	for v in VILLAGERS:
		if VILLAGERS[v]["teach"] == id:
			return "%sと仲良くなる" % VILLAGERS[v]["name"]
	if id == "veggie_skewer":
		return "夏のバーベキューナイト"
	return "？"
