extends Control

const MAP_SCENE = "res://scenes/MapScreen.tscn"
const CARD_SCENE = "res://scenes/ui/CardNode.tscn"
const CARD_SELECT_OVERLAY = "res://scenes/ui/CardSelectionOverlay.gd"

const C_BG   = Color(0.018, 0.014, 0.026)
const C_GOLD = Color(0.86, 0.72, 0.34)
const C_TEXT = Color(0.84, 0.78, 0.96)

# 幕ごとのイベントプール。袋方式(GameState.event_bag)で1ラン内の重複を避ける。
# 背景は assets/backgrounds/events/<id>.png があれば自動で使う(無ければ共通背景)。
const EVENT_POOLS: Dictionary = {
	"common": ["altar", "soldier_book", "tainted_water", "sealed_coffin", "shadow_pact"],
	"act1": ["ruined_forge", "forgotten_graves", "quiet_camp"],
	"act2": ["wanted_poster", "back_alley_bar", "confession_booth"],
	"act3": ["five_portraits", "kings_cellar", "shadow_pact_final"],
}

const EVENTS: Array = [
	{
		"id": "altar",
		"title": "薄暗い祭壇",
		"desc": "薄暗い石の祭壇が脈打っている。触れれば、何かを捧げる代わりに力を得られそうだ。",
		"choices": [
			{"label": "血を捧げる", "description": "HP -8 / カードを1枚強化", "effect": "altar_blood", "result": "血と引き換えに、力が宿った。"},
			{"label": "祈る", "description": "HP +15", "effect": "altar_pray", "result": "祈りが届いた。HPが15回復した。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "あなたは静かに立ち去った。"},
		]
	},
	{
		"id": "soldier_book",
		"title": "倒れた兵士と書物",
		"desc": "倒れた兵士のそばに、血で汚れた戦術書が落ちている。まだ読めそうだ。",
		"choices": [
			{"label": "読む", "description": "ランダムなカードを1枚獲得", "effect": "book_draw", "result": "知識が流れ込んだ。カードを1枚獲得した。"},
			{"label": "研究する", "description": "HP -5 / カードを1枚強化", "effect": "book_research", "result": "書物の内容を掘り下げ、カードを強化した。"},
			{"label": "無視する", "description": "何もしない", "effect": "none", "result": "あなたは足を止めなかった。"},
		]
	},
	{
		"id": "shadow_pact",
		"title": "影の契約",
		"desc": "足元の影が揺れ、声が聞こえる。「守りが欲しいなら、痛みを差し出せ。」",
		"choices": [
			{"label": "契約する", "description": "HP -10 / レリック『強化された守り』を得る", "effect": "shadow_contract", "result": "影との契約が結ばれた。レリック『強化された守り』を得た。"},
			{"label": "深く契約する", "description": "HP -18 / ランダムなレリックを得る", "effect": "shadow_deep_contract", "result": "さらに深い契約を結び、隠された力を得た。"},
			{"label": "拒否する", "description": "何もしない", "effect": "none", "result": "あなたは囁きを拒んだ。"},
		]
	},
	{
		"id": "ruined_forge",
		"title": "朽ちた鍛冶場",
		"desc": "廃墟の奥に、まだ熱を残した鍛冶場がある。──見覚えがある。あの頃、五人分の剣をここで打ち直した。",
		"choices": [
			{"label": "鍛える", "description": "HP -6 / カードを1枚強化", "effect": "forge_upgrade", "result": "道具の火花がカードに宿った。"},
			{"label": "無理に使う", "description": "HP -6 / カードを2枚強化", "effect": "forge_double_upgrade", "result": "無理を押し通し、2枚のカードを鍛え上げた。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "あなたは鍛冶場を後にした。"},
		]
	},
	{
		"id": "forgotten_graves",
		"title": "忘れられた墓標",
		"desc": "名もなき墓標が並んでいる。ひとつだけ、あなたの名を刻むための空白がある。",
		"choices": [
			{"label": "記憶を埋める", "description": "カードを1枚削除", "effect": "grave_remove", "result": "ひとつの記憶を手放した。カードを1枚削除した。"},
			{"label": "血を捧げる", "description": "HP -10 / カードを1枚削除", "effect": "grave_blood", "result": "血を捧げ、代償として力を得た。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "あなたは墓標を背にした。"},
		]
	},
	{
		"id": "tainted_water",
		"title": "汚れた聖水",
		"desc": "割れた器に、黒く濁った水が残っている。飲めば体は癒えるが、何かを失う気がする。",
		"choices": [
			{"label": "飲む", "description": "HP全回復 / 最大HP -5", "effect": "holy_water_drink", "result": "身体は満たされたが、限界は少し削られた。"},
			{"label": "手を浸す", "description": "HP +12", "effect": "holy_water_touch", "result": "聖水が傷をやわらげた。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "あなたは器を見捨てた。"},
		]
	},
	{
		"id": "sealed_coffin",
		"title": "封印された棺",
		"desc": "黒い鎖で封じられた棺がある。中から、微かな鼓動が聞こえる。",
		"choices": [
			{"label": "開ける", "description": "ランダムなレリックを得る / 呪いカードが加わる", "effect": "coffin_open", "result": "棺の封印は破られ、遺物と呪いが手に入った。"},
			{"label": "鎖を壊す", "description": "HP -12 / ランダムなカードを1枚獲得", "effect": "coffin_break", "result": "鎖を砕き、奥から何かを引き出した。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "あなたは棺を残したまま進んだ。"},
		]
	},
	{
		"id": "quiet_camp",
		"title": "静かな野営跡",
		"desc": "焚き火の跡が残る窪地。──見覚えがある。五人で星を数えた、最初の夜の場所だ。",
		"choices": [
			{"label": "火を熾して休む", "description": "HP +12", "effect": "camp_rest", "result": "ひとりの火は小さい。それでも、温かかった。"},
			{"label": "灰を漁る", "description": "ランダムなカードを1枚獲得", "effect": "camp_scavenge", "result": "灰の中に、置き忘れられたものがあった。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "思い出は、灰の中に置いていく。"},
		]
	},
	{
		"id": "wanted_poster",
		"title": "自分の手配書",
		"desc": "壁に古びた手配書が貼られている。「名もなき裏切り者」──描かれた顔は、間違いなくあなただ。",
		"choices": [
			{"label": "破り捨てる", "description": "カードを1枚削除", "effect": "wanted_remove", "result": "紙切れひとつ。けれど、少しだけ軽くなった。"},
			{"label": "見つめる", "description": "最大HP +4", "effect": "wanted_resolve", "result": "もう、誰の物語でもない。自分の足で立つ。"},
			{"label": "立ち去る", "description": "何もしない", "effect": "none", "result": "風が手配書を揺らしていた。"},
		]
	},
	{
		"id": "back_alley_bar",
		"title": "裏路地の酒場",
		"desc": "扉の隙間から灯りと喧噪が漏れる。カウンターの奥の老主人は、あなたの顔を見ても何も言わなかった。",
		"choices": [
			{"label": "酒を呑む", "description": "HP +12", "effect": "bar_drink", "result": "安酒が喉を焼く。生きている味がした。"},
			{"label": "噂を集める", "description": "カードを1枚強化", "effect": "bar_rumor", "result": "酔客の噂話に、王宮の弱みが混ざっていた。"},
			{"label": "昔を語る", "description": "HP -5 / ランダムなレリックを得る", "effect": "bar_memory", "result": "語り終えると、老主人は黙って何かを差し出した。"},
		]
	},
	{
		"id": "confession_booth",
		"title": "教会の懺悔室",
		"desc": "誰もいない懺悔室。仕切りの向こうは暗い。それでも、何かが聞いている気がする。",
		"choices": [
			{"label": "懺悔する", "description": "呪いカードをすべて削除 / HP +5", "effect": "confess", "result": "誰も赦しはしない。それでも、重荷は下りた。"},
			{"label": "沈黙を破る", "description": "HP -8 / カードを2枚強化", "effect": "confess_threaten", "result": "「赦しはいらない。力をよこせ。」暗がりは、応えた。"},
			{"label": "黙って出る", "description": "何もしない", "effect": "none", "result": "懺悔する罪は、まだ終わっていない。"},
		]
	},
	{
		"id": "five_portraits",
		"title": "五人の肖像画",
		"desc": "回廊に勇者一行の肖像画が飾られている。五人目の場所だけ、黒く塗り潰されている。",
		"choices": [
			{"label": "切り裂く", "description": "HP -8 / カードを2枚強化", "effect": "portrait_slash", "result": "布の裂ける音が、回廊に長く響いた。"},
			{"label": "見つめる", "description": "最大HP +5", "effect": "portrait_accept", "result": "塗り潰されたのは絵だけだ。お前は、ここにいる。"},
			{"label": "通り過ぎる", "description": "何もしない", "effect": "none", "result": "絵の中の四人は、笑ったままだった。"},
		]
	},
	{
		"id": "kings_cellar",
		"title": "王の酒蔵",
		"desc": "祝勝の夜に開けられたものと同じ酒が眠っている。──あの夜、あなたの杯にだけ、何かが混ぜられていた。",
		"choices": [
			{"label": "呑み干す", "description": "HP全回復 / 「強欲の代償」がデッキに混ざる", "effect": "cellar_drink", "result": "うまい。だからこそ、許せない。"},
			{"label": "瓶を叩き割る", "description": "ランダムなカードを1枚獲得", "effect": "cellar_smash", "result": "砕けた瓶の奥に、隠されていたものが見えた。"},
			{"label": "触れない", "description": "何もしない", "effect": "none", "result": "酒の香りだけが、あの夜を覚えている。"},
		]
	},
	{
		"id": "shadow_pact_final",
		"title": "影の契約・終章",
		"desc": "玉座の間が近い。影が囁く。「最後の名を消す前に──すべてを差し出す覚悟はあるか。」",
		"choices": [
			{"label": "すべてを差し出す", "description": "最大HP -7 / エピックレリックを得る", "effect": "pact_final_give", "result": "影は満足げに揺れた。身体の芯が、少し軽くなった気がした。"},
			{"label": "真意を問う", "description": "HP +5", "effect": "pact_final_ask", "result": "影は笑った。「復讐が終わった後のお前を、見てみたいだけだ。」"},
			{"label": "拒む", "description": "何もしない", "effect": "none", "result": "「……いいだろう。その意地ごと、見届けてやる。」"},
		]
	},
]

var _current_event: Dictionary = {}
var _result_label: Label
var _choice_container: VBoxContainer
var _continue_btn: Button
var _panel: Panel
var _card_scene: PackedScene
var _card_picker_panel: Control
var _card_picker_remaining_label: Label
var _pending_card_mode: String = ""
var _pending_card_result: String = ""
var _pending_card_picks: int = 0
var _choice_locked: bool = false
var _card_picker_locked: bool = false


func _ready() -> void:
	_apply_screen_scale()
	_card_scene = load(CARD_SCENE)
	GameState.complete_map_node(GameState.map_current_node_id)
	_current_event = _draw_event()
	_build_ui()

## 現在の幕のプール(共通+act専用)から袋方式で1つ引く
func _draw_event() -> Dictionary:
	var act = clampi(GameState.current_act, 1, 3)
	var pool: Array = []
	pool.append_array(EVENT_POOLS["common"])
	pool.append_array(EVENT_POOLS.get("act%d" % act, []))
	if GameState.event_bag.is_empty():
		var refill: Array = pool.duplicate()
		refill.shuffle()
		GameState.event_bag.assign(refill)
	var event_id: String = GameState.event_bag.pop_back()
	for event in EVENTS:
		if event.get("id", "") == event_id:
			return event
	return EVENTS[randi() % EVENTS.size()]

func _apply_screen_scale() -> void:
	var scaler = get_node_or_null("/root/ScreenScale")
	if scaler and scaler.has_method("apply"):
		scaler.apply(self)


func _build_ui() -> void:
	# イベント専用背景があれば使う(assets/backgrounds/events/<id>.png)
	var custom_bg = "res://assets/backgrounds/events/%s.png" % _current_event.get("id", "")
	if GameState.load_background_texture(custom_bg) != null:
		_add_background_path(custom_bg)
	else:
		_add_background("shared_event")

	var canvas = _AtmosphereCanvas.new()
	add_child(canvas)

	# Central panel
	var panel = Panel.new()
	_panel = panel
	panel.position = Vector2(320, 120)
	panel.size = Vector2(640, 460)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.032, 0.026, 0.060, 0.0)
	ps.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.0)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	# "イベント" header
	var header = Label.new()
	header.text = "イベント"
	header.position = Vector2(0, 16)
	header.size = Vector2(640, 28)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.55, 0.20, 0.90, 0.80))
	panel.add_child(header)

	# Event title
	var title = Label.new()
	title.text = _current_event.get("title", "")
	title.position = Vector2(20, 48)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title)

	# Divider
	var div = _Divider.new()
	div.position = Vector2(60, 96)
	div.size = Vector2(520, 8)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# Description
	var desc = Label.new()
	desc.text = _current_event.get("desc", "")
	desc.position = Vector2(40, 110)
	desc.size = Vector2(560, 80)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", C_TEXT)
	panel.add_child(desc)

	# Result label (hidden until choice made)
	_result_label = Label.new()
	_result_label.position = Vector2(40, 198)
	_result_label.size = Vector2(560, 50)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 15)
	_result_label.add_theme_color_override("font_color", Color(0.70, 0.88, 0.72))
	_result_label.visible = false
	panel.add_child(_result_label)

	# Choices
	# 選択肢は画面下部に寄せて、中央の背景アートを見せる
	_choice_container = VBoxContainer.new()
	_choice_container.position = Vector2(120, 340)
	_choice_container.size = Vector2(400, 280)
	_choice_container.add_theme_constant_override("separation", 12)
	panel.add_child(_choice_container)

	var choices: Array = _current_event.get("choices", [])
	for choice in choices:
		_choice_container.add_child(_make_choice_panel(choice, _choice_blocked_text(choice)))

	# Continue button (hidden until choice made)
	_continue_btn = _make_action_btn("マップに戻る", Vector2(640, 668))
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue)
	add_child(_continue_btn)

	# Entrance fade
	modulate.a = 0.0
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 1.0, 0.45)


func _on_choice(choice: Dictionary) -> void:
	if _choice_locked:
		return
	_choice_locked = true
	var effect: String = choice.get("effect", "none")

	match effect:
		"altar_blood":
			GameState.player_hp = maxi(1, GameState.player_hp - 8)
			_begin_card_selection("upgrade", 1, choice.get("result", ""), "強化するカードを選択")
		"altar_pray":
			GameState.heal(15)
			_finish_event(choice.get("result", ""))
		"book_draw":
			_grant_random_card()
			_finish_event(choice.get("result", ""))
		"book_research":
			GameState.player_hp = maxi(1, GameState.player_hp - 5)
			_begin_card_selection("upgrade", 1, choice.get("result", ""), "強化するカードを選択")
		"shadow_contract":
			GameState.player_hp = maxi(1, GameState.player_hp - 10)
			GameState.add_relic("cracked_amulet")
			_finish_event(choice.get("result", ""))
		"shadow_deep_contract":
			GameState.player_hp = maxi(1, GameState.player_hp - 18)
			var relic_id = GameState.roll_relic_reward("normal")
			if not relic_id.is_empty():
				GameState.add_relic(relic_id)
			_finish_event(choice.get("result", ""))
		"forge_upgrade":
			GameState.player_hp = maxi(1, GameState.player_hp - 6)
			_begin_card_selection("upgrade", 1, choice.get("result", ""), "鍛えるカードを選択")
		"forge_double_upgrade":
			GameState.player_hp = maxi(1, GameState.player_hp - 6)
			_begin_card_selection("upgrade", 2, choice.get("result", ""), "2枚のカードを選択")
		"grave_remove":
			_begin_card_selection("remove", 1, choice.get("result", ""), "削除するカードを選択")
		"grave_blood":
			GameState.player_hp = maxi(1, GameState.player_hp - 10)
			_begin_card_selection("remove", 1, choice.get("result", ""), "削除するカードを選択")
		"holy_water_drink":
			GameState.heal(GameState.player_max_hp)
			GameState.player_max_hp = maxi(1, GameState.player_max_hp - 5)
			GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
			_finish_event(choice.get("result", ""))
		"holy_water_touch":
			GameState.heal(12)
			_finish_event(choice.get("result", ""))
		"coffin_open":
			var open_relic_id = GameState.roll_relic_reward("normal")
			if not open_relic_id.is_empty():
				GameState.add_relic(open_relic_id)
			var curse_card = GameState.create_status_card("brand_of_sin")
			curse_card["name"] = "呪われた鎖"
			curse_card["description"] = "使用できない。\n手札に残るとHPを2失う。\n休憩で除去できる。"
			curse_card["temporary"] = false  # デッキに残る永続呪い(休憩・懺悔で除去可)
			GameState.deck.append(curse_card)
			_finish_event(choice.get("result", ""))
		"coffin_break":
			GameState.player_hp = maxi(1, GameState.player_hp - 12)
			_grant_random_card()
			_finish_event(choice.get("result", ""))
		"camp_rest", "bar_drink":
			GameState.heal(12)
			_finish_event(choice.get("result", ""))
		"camp_scavenge", "cellar_smash":
			_grant_random_card()
			_finish_event(choice.get("result", ""))
		"wanted_remove":
			_begin_card_selection("remove", 1, choice.get("result", ""), "削除するカードを選択")
		"wanted_resolve":
			GameState.player_max_hp += 4
			GameState.player_hp += 4
			_finish_event(choice.get("result", ""))
		"bar_rumor":
			_begin_card_selection("upgrade", 1, choice.get("result", ""), "強化するカードを選択")
		"bar_memory":
			GameState.player_hp = maxi(1, GameState.player_hp - 5)
			var bar_relic_id = GameState.roll_relic_reward("normal")
			if not bar_relic_id.is_empty():
				GameState.add_relic(bar_relic_id)
			_finish_event(choice.get("result", ""))
		"confess":
			var removed = GameState.remove_curse_cards_from_deck()
			GameState.heal(5)
			var confess_text = choice.get("result", "")
			if removed > 0:
				confess_text += "(呪い%d枚を除去)" % removed
			_finish_event(confess_text)
		"confess_threaten", "portrait_slash":
			GameState.player_hp = maxi(1, GameState.player_hp - 8)
			_begin_card_selection("upgrade", 2, choice.get("result", ""), "強化するカードを選択")
		"portrait_accept":
			GameState.player_max_hp += 5
			GameState.player_hp += 5
			_finish_event(choice.get("result", ""))
		"cellar_drink":
			GameState.heal(GameState.player_max_hp)
			GameState.add_card_to_deck("greed_price")
			_finish_event(choice.get("result", ""))
		"pact_final_give":
			GameState.player_max_hp = maxi(10, GameState.player_max_hp - 7)
			GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
			var pact_relic_id = GameState.roll_relic_reward_of_rarity("epic")
			if pact_relic_id.is_empty():
				pact_relic_id = GameState.roll_relic_reward("elite")
			if not pact_relic_id.is_empty():
				GameState.add_relic(pact_relic_id)
			_finish_event(choice.get("result", ""))
		"pact_final_ask":
			GameState.heal(5)
			_finish_event(choice.get("result", ""))
		_:
			_finish_event(choice.get("result", ""))

func _begin_card_selection(mode: String, picks: int, result_text: String, title_text: String) -> void:
	_pending_card_mode = mode
	_pending_card_picks = picks
	_pending_card_result = result_text
	_choice_container.visible = false
	_result_label.visible = true
	_result_label.text = "カードを選んでください。"
	_continue_btn.visible = false
	_show_card_picker(title_text)

func _show_card_picker(title_text: String) -> void:
	if _card_picker_panel and is_instance_valid(_card_picker_panel):
		_card_picker_panel.queue_free()
	var overlay_script = load(CARD_SELECT_OVERLAY)
	var overlay = overlay_script.new()
	_card_picker_panel = overlay
	add_child(overlay)
	overlay.card_selected.connect(_on_card_picker_selected)
	overlay.show_selection(_pending_card_mode, title_text, _pending_card_picks, false)

func _on_card_picker_selected(deck_index: int) -> void:
	if _card_picker_locked:
		return
	_card_picker_locked = true
	var ok := false
	if _pending_card_mode == "upgrade":
		ok = GameState.upgrade_deck_card(deck_index)
	else:
		ok = GameState.remove_deck_card(deck_index)

	if not ok:
		_result_label.text = "このカードは選べない。"
		_result_label.visible = true
		_card_picker_locked = false
		return

	_pending_card_picks -= 1
	if _pending_card_picks > 0:
		_result_label.text = "あと %d 枚選んでください。" % _pending_card_picks
		_result_label.visible = true
		if _card_picker_panel and is_instance_valid(_card_picker_panel):
			_card_picker_panel.set_remaining_picks(_pending_card_picks)
			_card_picker_panel.refresh()
		_card_picker_locked = false
		return

	_result_label.text = _pending_card_result
	_result_label.visible = true
	if _card_picker_panel and is_instance_valid(_card_picker_panel):
		_card_picker_panel.queue_free()
	_card_picker_panel = null
	_continue_btn.visible = true
	_card_picker_locked = false

func _finish_event(result_text: String) -> void:
	_result_label.text = result_text
	_result_label.visible = true
	_choice_container.visible = false
	if _card_picker_panel and is_instance_valid(_card_picker_panel):
		_card_picker_panel.queue_free()
	_card_picker_panel = null
	_continue_btn.visible = true

func _grant_random_card() -> void:
	var pool = GameState.get_reward_options()
	if pool.is_empty():
		var fallback = GameState.CARD_REWARD_POOL.pick_random()
		GameState.add_card_to_deck(fallback)
		return
	GameState.add_card_to_deck(pool.pick_random())

func _choice_blocked_text(choice: Dictionary) -> String:
	match choice.get("effect", ""):
		"altar_blood":
			return "HPが足りない" if GameState.player_hp <= 8 else ""
		"book_research":
			if GameState.player_hp <= 5:
				return "HPが足りない"
			return "強化対象なし" if GameState.get_upgradeable_deck_indices().is_empty() else ""
		"shadow_contract":
			return "HPが足りない" if GameState.player_hp <= 10 else ""
		"shadow_deep_contract":
			if GameState.player_hp <= 18:
				return "HPが足りない"
			return "得られるレリックがない" if GameState.roll_relic_reward("normal").is_empty() else ""
		"forge_upgrade":
			if GameState.player_hp <= 6:
				return "HPが足りない"
			return "強化対象なし" if GameState.get_upgradeable_deck_indices().is_empty() else ""
		"forge_double_upgrade":
			if GameState.player_hp <= 6:
				return "HPが足りない"
			return "強化対象が2枚ない" if GameState.get_upgradeable_deck_indices().size() < 2 else ""
		"grave_remove":
			return "削除対象なし" if GameState.get_removable_deck_indices().is_empty() else ""
		"grave_blood":
			if GameState.player_hp <= 10:
				return "HPが足りない"
			return "削除対象なし" if GameState.get_removable_deck_indices().is_empty() else ""
		"holy_water_drink":
			return "最大HPが低すぎる" if GameState.player_max_hp <= 5 else ""
		"coffin_open":
			return "得られるレリックがない" if GameState.roll_relic_reward("normal").is_empty() else ""
		"coffin_break":
			return "HPが足りない" if GameState.player_hp <= 12 else ""
		"wanted_remove":
			return "削除対象なし" if GameState.get_removable_deck_indices().is_empty() else ""
		"bar_rumor":
			return "強化対象なし" if GameState.get_upgradeable_deck_indices().is_empty() else ""
		"bar_memory":
			if GameState.player_hp <= 5:
				return "HPが足りない"
			return "得られるレリックがない" if GameState.roll_relic_reward("normal").is_empty() else ""
		"confess":
			return "呪いを抱えていない" if GameState.count_curse_cards_in_deck() == 0 else ""
		"confess_threaten", "portrait_slash":
			if GameState.player_hp <= 8:
				return "HPが足りない"
			return "強化対象なし" if GameState.get_upgradeable_deck_indices().is_empty() else ""
		"pact_final_give":
			return "最大HPが低すぎる" if GameState.player_max_hp <= 17 else ""
		_:
			return ""

func _card_type_label(type: String) -> String:
	match type:
		"attack":
			return "攻撃"
		"defense":
			return "防御"
		"skill":
			return "スキル"
		"power":
			return "特殊"
		"status":
			return "状態"
		"curse":
			return "呪い"
		_:
			return "その他"


func _on_continue() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): get_tree().change_scene_to_file(MAP_SCENE))


func _make_choice_panel(choice: Dictionary, blocked_text: String) -> PanelContainer:
	var is_blocked := not blocked_text.is_empty()

	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.085, 0.040, 0.175, 0.97)
	sn.border_color = Color(0.46, 0.26, 0.70, 0.62)
	sn.set_border_width_all(1)
	sn.set_corner_radius_all(5)
	sn.shadow_color = Color(0.40, 0.14, 0.72, 0.22)
	sn.shadow_size = 5
	sn.content_margin_left = 12
	sn.content_margin_right = 12
	sn.content_margin_top = 8
	sn.content_margin_bottom = 8

	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.155, 0.070, 0.32, 0.98)
	sh.border_color = Color(0.74, 0.46, 0.98, 0.85)
	sh.set_border_width_all(1)
	sh.set_corner_radius_all(5)
	sh.shadow_color = Color(0.56, 0.24, 0.92, 0.40)
	sh.shadow_size = 9
	sh.content_margin_left = 12
	sh.content_margin_right = 12
	sh.content_margin_top = 8
	sh.content_margin_bottom = 8

	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(0.055, 0.045, 0.115, 0.92)
	sd.border_color = Color(0.22, 0.16, 0.34, 0.50)
	sd.set_border_width_all(1)
	sd.set_corner_radius_all(5)
	sd.content_margin_left = 12
	sd.content_margin_right = 12
	sd.content_margin_top = 8
	sd.content_margin_bottom = 8

	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(400, 0)
	pc.add_theme_stylebox_override("panel", sd if is_blocked else sn)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_blocked else Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(vbox)

	var name_label := Label.new()
	name_label.text = choice.get("label", "")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color",
		Color(0.55, 0.50, 0.68) if is_blocked else Color(0.90, 0.84, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var desc_text: String = choice.get("description", "")
	if not desc_text.is_empty():
		var desc_label := Label.new()
		desc_label.text = desc_text
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color",
			Color(0.42, 0.38, 0.55) if is_blocked else Color(0.65, 0.60, 0.80))
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(desc_label)

	if is_blocked:
		var block_label := Label.new()
		block_label.text = "※ " + blocked_text
		block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		block_label.add_theme_font_size_override("font_size", 12)
		block_label.add_theme_color_override("font_color", Color(0.85, 0.38, 0.38))
		block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(block_label)
	else:
		pc.mouse_entered.connect(func(): pc.add_theme_stylebox_override("panel", sh))
		pc.mouse_exited.connect(func(): pc.add_theme_stylebox_override("panel", sn))
		pc.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_on_choice(choice)
		)

	return pc


func _add_background(background_key: String) -> void:
	_add_background_path(GameState.get_background_path(background_key))

func _add_background_path(path: String) -> void:
	var bg = TextureRect.new()
	bg.name = "EventBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = -42
	bg.offset_top = -24
	bg.offset_right = 42
	bg.offset_bottom = 24
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = GameState.load_background_texture(path)
	if bg.texture == null:
		bg.modulate = C_BG
	add_child(bg)


func _make_action_btn(text: String, center: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	var sz = Vector2(220, 52)
	btn.position = center - sz / 2.0
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 18)
	preload("res://scenes/ui/UIStyle.gd").style_button(btn, 5.0, true)
	return btn


class _AtmosphereCanvas extends Node2D:
	var _phase: float = 0.0
	func _process(delta: float) -> void:
		_phase += delta
		queue_redraw()
	func _draw() -> void:
		for i in 5:
			var y = 100.0 + i * 110.0
			var drift = fmod(_phase * (7.0 + i * 2.5) + i * 120.0, 1400.0) - 700.0
			var pts = PackedVector2Array()
			for j in 8:
				pts.append(Vector2(j * 170.0 + drift, y + sin(_phase * 0.4 + j) * 18.0))
			for j in range(7, -1, -1):
				pts.append(Vector2(j * 170.0 + drift, y + 40.0 + cos(_phase * 0.35 + j) * 20.0))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.12, 0.10, 0.20, 0.025))


class _Divider extends Control:
	func _draw() -> void:
		var w = size.x
		var gold = Color(0.78, 0.62, 0.26, 0.50)
		draw_line(Vector2(0, 4), Vector2(w, 4), gold, 1.0)
		draw_circle(Vector2(w * 0.5, 4), 3.0, gold)
		draw_circle(Vector2(0, 4), 2.0, Color(gold, 0.60))
		draw_circle(Vector2(w, 4), 2.0, Color(gold, 0.60))
