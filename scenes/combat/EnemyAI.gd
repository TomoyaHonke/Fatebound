extends RefCounted
## 敵の行動パターン決定ロジック。
## 敵の種類ごとにターン数(と必要ならHP状況)から次の行動を返す。

static func decide_next_action(enemy_data: Dictionary, enemy_node: Node, turn: int) -> Dictionary:
	var enemy_type = String(enemy_data.get("enemy_id", enemy_data.get("enemy_type", enemy_data.get("id", ""))))
	match enemy_type:
		"holy_soldier":
			return _holy_soldier_action(turn)
		"temple_archer":
			return _temple_archer_action(turn)
		"inquisitor":
			return _inquisitor_action(turn)
		"paladin_captain":
			return _paladin_captain_action(enemy_node, turn)
		"young_swordsman":
			return _young_swordsman_action(turn)
		"novice_cleric":
			return _novice_cleric_action(turn)
		"bounty_hunter":
			return _bounty_hunter_action(turn)
		"chain_jailer":
			return _chain_jailer_action(turn)
		"sun_priest":
			return _sun_priest_action(turn)
		"white_shield_knight":
			return _white_shield_knight_action(turn)
		"fallen_saint":
			return _fallen_saint_action(turn)
		"sage_of_the_party":
			return _sage_of_the_party_action(turn)
		"hunter_companion":
			return _hunter_companion_action(turn)
		"hero":
			return _hero_action(enemy_node, turn)
		"forest_hunter":
			return _forest_hunter_action(turn)
		"mercenary_axeman":
			return _mercenary_axeman_action(turn)
		"poison_rogue":
			return _poison_rogue_action(turn)
		"war_mage":
			return _war_mage_action(turn)
		"battle_scavenger":
			return _battle_scavenger_action(turn)
		"war_wolf":
			return _war_wolf_action(turn)
		"wyvern_dragon":
			return _wyvern_dragon_action(turn)
		"stone_golem":
			return _stone_golem_action(turn)
		"dark_fairy":
			return _dark_fairy_action(turn)
		"royal_guard":
			return _royal_guard_action(turn)
		"alley_duelist":
			return _alley_duelist_action(turn)
		"royal_mage":
			return _royal_mage_action(turn)
		"prison_guard":
			return _prison_guard_action(turn)
		"hired_knight":
			return _hired_knight_action(turn)
		"beastman_mercenary":
			return _beastman_mercenary_action(turn)
		"elven_city_archer":
			return _elven_city_archer_action(turn)
		"foxkin_spy":
			return _foxkin_spy_action(turn)
		"elven_court_mage":
			return _elven_court_mage_action(turn)
		"wolfkin_guard":
			return _wolfkin_guard_action(turn)
		_:
			return _default_enemy_action(turn)

static func _attack_action(value: int, desc: String = "") -> Dictionary:
	return {"type": "attack", "value": value, "desc": desc if not desc.is_empty() else "攻撃 %d" % value}

static func _holy_soldier_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "strength", "buff": 2, "desc": "号令", "log": "聖都兵は号令で攻撃力を上げた。"}

static func _temple_archer_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack", "value": 6, "desc": "射撃 6"}
		2: return {"type": "block", "value": 5, "desc": "防御 5"}
		_: return {"type": "add_temp_draw", "card_id": "arrow_wound", "amount": 1, "desc": "矢傷", "log": "神殿弓兵は矢傷を山札に混ぜた。"}

static func _inquisitor_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(8)
		2: return {"type": "block", "value": 8, "desc": "防御 8"}
		_:
			var card_id = "brand_of_sin" if turn % 2 == 0 else "restraint"
			var desc = "罪の烙印" if card_id == "brand_of_sin" else "拘束"
			return {"type": "add_temp_draw", "card_id": card_id, "amount": 1, "desc": desc, "log": "異端審問官は%sを山札に混ぜた。" % desc}

static func _paladin_captain_action(enemy_node: Node, turn: int) -> Dictionary:
	var half_hp = enemy_node and enemy_node.current_hp <= int(enemy_node.max_hp * 0.5)
	if half_hp and turn % 3 == 0:
		return {"type": "block_strength", "value": 12, "buff": 2, "desc": "聖騎士の意地", "log": "聖騎士隊長は守りを固め、攻撃力を上げた。"}
	match turn % 3:
		1: return _attack_action(10)
		2: return {"type": "block", "value": 11, "desc": "防御 11"}
		_: return {"type": "add_temp_draw", "card_id": "judgement", "amount": 1, "desc": "裁き", "log": "聖騎士隊長は裁きを山札に混ぜた。"}

static func _young_swordsman_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 5, "desc": "防御 5"}
		_: return {"type": "strength", "buff": 2, "desc": "気合い", "log": "若き剣士は気合いを入れた。"}

static func _novice_cleric_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(5)
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "heal", "value": 8, "desc": "回復 8"}

static func _bounty_hunter_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(11)
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "strength", "buff": 3, "desc": "狙いを定める", "log": "賞金稼ぎは狙いを定めた。"}

static func _chain_jailer_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(8)
		2: return {"type": "block", "value": 10, "desc": "防御 10"}
		_: return {"type": "add_temp_discard", "card_id": "restraint", "amount": 1, "desc": "拘束", "log": "鎖の看守は拘束を捨て札に混ぜた。"}

static func _sun_priest_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 8, "desc": "防御 8"}
		_: return {"type": "heal_strength", "value": 7, "buff": 1, "desc": "祝福", "log": "太陽司祭は祝福で回復し、攻撃力を上げた。"}

static func _white_shield_knight_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(11)
		2: return {"type": "block", "value": 15, "desc": "防御 15"}
		_: return {"type": "block_strength", "value": 12, "buff": 2, "desc": "反撃態勢", "log": "白盾の騎士は反撃態勢を取った。"}

static func _fallen_saint_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(9)
		2: return {"type": "block", "value": 10, "desc": "防御 10"}
		3: return {"type": "heal", "value": 10, "desc": "回復 10"}
		_: return {"type": "add_temp_draw", "card_id": "guilt", "amount": 1, "desc": "罪悪感", "log": "偽りの聖女は罪悪感を山札に混ぜた。"}

static func _sage_of_the_party_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(12, "魔弾 12")
		2: return {"type": "block", "value": 8, "desc": "防御 8"}
		_: return {"type": "add_temp_draw", "card_id": "magic_disruption", "amount": 1, "desc": "魔力乱れ", "log": "叡智の賢者は魔力乱れを山札に混ぜた。"}

static func _hunter_companion_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 6, "times": 2, "desc": "連射 6x2"}
		2: return {"type": "block", "value": 9, "desc": "防御 9"}
		_: return {"type": "add_temp_draw", "card_id": "arrow_wound", "amount": 2, "desc": "矢傷 2", "log": "かつての狩人は矢傷を2枚山札に混ぜた。"}

static func _hero_action(enemy_node: Node, turn: int) -> Dictionary:
	var second_phase = enemy_node and enemy_node.current_hp <= int(enemy_node.max_hp * 0.5)
	if second_phase:
		match turn % 4:
			1: return _attack_action(18, "勇者の強撃 18")
			2: return {"type": "block_strength", "value": 16, "buff": 2, "desc": "第二形態", "log": "勇者は光を解き放ち第二形態の力を高めた。"}
			3: return {"type": "add_temp_draw", "card_id": "judgement", "amount": 2, "desc": "断罪 2", "log": "勇者は断罪を2枚山札に混ぜた。"}
			_: return {"type": "attack_multi", "value": 8, "times": 3, "desc": "光刃 8x3"}
	match turn % 4:
		1: return _attack_action(13)
		2: return {"type": "block", "value": 14, "desc": "防御 14"}
		3: return {"type": "strength", "buff": 3, "desc": "号令", "log": "勇者は号令で攻撃力を上げた。"}
		_: return {"type": "add_temp_draw", "card_id": "judgement", "amount": 1, "desc": "断罪", "log": "勇者は断罪を山札に混ぜた。"}

static func _forest_hunter_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "連射 5x2"}
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "add_temp_draw", "card_id": "arrow_wound", "amount": 1, "desc": "矢傷", "log": "森の追跡者は矢傷を山札に混ぜた。"}

static func _mercenary_axeman_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(12, "斧撃 12")
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "strength", "buff": 4, "desc": "力を溜める", "log": "傭兵斧使いは力を溜めた。"}

static func _poison_rogue_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 4, "times": 2, "desc": "毒刃連撃 4x2"}
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "add_temp_draw", "card_id": "poison_blade", "amount": 1, "desc": "毒刃", "log": "毒刃の盗賊は毒刃を山札に混ぜた。"}

static func _war_mage_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(10, "魔撃 10")
		2: return {"type": "block", "value": 7, "desc": "防御 7"}
		_: return {"type": "add_temp_draw", "card_id": "magic_disruption", "amount": 1, "desc": "魔力乱れ", "log": "戦場魔術師は魔力乱れを山札に混ぜた。"}

static func _battle_scavenger_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "add_temp_discard", "card_id": "junk", "amount": 2, "desc": "ガラクタ 2", "log": "戦場漁りはガラクタを2枚捨て札に混ぜた。"}

static func _war_wolf_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "連撃 5x2"}
		2: return {"type": "block", "value": 5, "desc": "防御 5"}
		_: return {"type": "add_temp_discard", "card_id": "bleeding", "amount": 1, "desc": "出血", "log": "戦狼は出血を捨て札に混ぜた。"}

static func _wyvern_dragon_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(13, "爪撃 13")
		2: return {"type": "block", "value": 10, "desc": "防御 10"}
		3: return {"type": "add_temp_draw", "card_id": "dragon_burn", "amount": 1, "desc": "竜の火傷", "log": "飛竜は竜の火傷を山札に混ぜた。"}
		_: return _attack_action(20, "急降下 20")

static func _stone_golem_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(12, "岩拳 12")
		2: return {"type": "block", "value": 18, "desc": "防御 18"}
		_: return {"type": "add_temp_draw", "card_id": "petrified_shard", "amount": 1, "desc": "石化の欠片", "log": "石像ゴーレムは石化の欠片を山札に混ぜた。"}

static func _dark_fairy_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(8, "闇弾 8")
		2: return {"type": "block", "value": 9, "desc": "防御 9"}
		_: return {"type": "add_temp_draw", "card_id": "fairy_mischief", "amount": 1, "desc": "妖精の悪戯", "log": "闇妖精は妖精の悪戯を山札に混ぜた。"}

static func _royal_guard_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7, "槍突き 7")
		2: return {"type": "block", "value": 8, "desc": "盾を構える"}
		_: return {"type": "attack_status", "value": 5, "status": "weak", "amount": 1, "desc": "制圧命令", "log": "王都衛兵は制圧命令を下した。"}

static func _alley_duelist_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return {"type": "attack_multi", "value": 4, "times": 2, "desc": "素早い刺突 4x2"}
		2: return {"type": "strength", "buff": 1, "desc": "間合いを測る", "log": "路地裏の決闘者は間合いを測った。"}
		_: return _attack_action(10, "決闘の一閃 10")

static func _royal_mage_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(8, "魔弾 8")
		2: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "思考干渉", "log": "王宮魔術師は重圧を捨て札に混ぜた。"}
		3: return {"type": "block", "value": 14, "desc": "王宮結界"}
		_: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "魔力封じ", "log": "王宮魔術師は魔力封じで重圧を捨て札に混ぜた。"}

static func _prison_guard_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7, "鎖打ち 7")
		2: return {"type": "add_temp_discard", "card_id": "restraint", "amount": 1, "desc": "拘束具", "log": "牢獄番は拘束を捨て札に混ぜた。"}
		_: return _attack_action(11, "鉄棍殴打 11")

static func _hired_knight_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(12, "大剣斬り 12")
		2: return {"type": "block", "value": 16, "desc": "鎧を固める"}
		3: return {"type": "block_strength", "value": 8, "buff": 1, "desc": "傭兵の構え", "log": "雇われ騎士は構えを取り、攻撃力を上げた。"}
		_: return {"type": "attack_multi", "value": 7, "times": 2, "desc": "踏み込み斬り 7x2"}

static func _beastman_mercenary_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(9, "斧撃 9")
		2: return {"type": "strength", "buff": 1, "desc": "咆哮", "log": "獣人傭兵は咆哮で攻撃力を上げた。"}
		_: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "獣の連撃 5x2"}

static func _elven_city_archer_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7, "精密射撃 7")
		2: return {"type": "strength", "buff": 1, "desc": "狙い澄ます", "log": "エルフの王都射手は狙いを澄ませた。"}
		_: return {"type": "attack_add_temp_discard", "value": 5, "card_id": "arrow_wound", "amount": 1, "desc": "裂傷の矢", "log": "エルフの王都射手は裂傷の矢を放ち、矢傷を捨て札に混ぜた。"}

static func _foxkin_spy_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(6, "袖刃 6")
		2: return {"type": "attack_status", "value": 4, "status": "weak", "amount": 1, "desc": "毒針", "log": "狐獣人の密偵は毒針を放った。"}
		3: return {"type": "block", "value": 8, "desc": "身を翻す"}
		_: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "攪乱", "log": "狐獣人の密偵は重圧を捨て札に混ぜた。"}

static func _elven_court_mage_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(9, "宮廷魔弾 9")
		2: return {"type": "block", "value": 6, "desc": "結界術"}
		3: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "記憶の撹乱", "log": "エルフの宮廷術師は重圧を捨て札に混ぜた。"}
		_: return {"type": "add_temp_discard", "card_id": "pressure", "amount": 1, "desc": "魔力封じ", "log": "エルフの宮廷術師は魔力封じで重圧を捨て札に混ぜた。"}

static func _wolfkin_guard_action(turn: int) -> Dictionary:
	match turn % 4:
		1: return _attack_action(10, "近衛剣 10")
		2: return {"type": "block", "value": 14, "desc": "守護本能"}
		3: return {"type": "strength", "buff": 2, "desc": "低い唸り", "log": "狼獣人の近衛は低く唸り、攻撃力を上げた。"}
		_: return {"type": "attack_multi", "value": 5, "times": 2, "desc": "双爪追撃 5x2"}

static func _default_enemy_action(turn: int) -> Dictionary:
	match turn % 3:
		1: return _attack_action(7)
		2: return {"type": "block", "value": 6, "desc": "防御 6"}
		_: return {"type": "add_temp_draw", "card_id": "junk", "amount": 1, "desc": "ガラクタ", "log": "敵はガラクタを山札に混ぜた。"}
