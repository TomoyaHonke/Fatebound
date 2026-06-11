extends Node
## Attaches hover/press micro-animations to every Button added to the tree,
## so individual screens don't each reimplement button feel.
## Opt out per button with btn.set_meta("no_uifx", true) before add_child.

const HOVER_SCALE := 1.03
const PRESS_SCALE := 0.97
const HOVER_TIME := 0.12
const PRESS_TIME := 0.07

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Button and not node is CheckButton and not node is OptionButton:
		if node.has_meta("no_uifx"):
			return
		node.mouse_entered.connect(_on_hover.bind(node, true))
		node.mouse_exited.connect(_on_hover.bind(node, false))
		node.button_down.connect(_on_press.bind(node, true))
		node.button_up.connect(_on_press.bind(node, false))

func _on_hover(btn: Button, hovering: bool) -> void:
	if not is_instance_valid(btn) or btn.disabled:
		return
	btn.set_meta("uifx_hovered", hovering)
	_scale_to(btn, HOVER_SCALE if hovering else 1.0, HOVER_TIME)

func _on_press(btn: Button, pressed: bool) -> void:
	if not is_instance_valid(btn):
		return
	if pressed:
		_scale_to(btn, PRESS_SCALE, PRESS_TIME)
	else:
		var hovered: bool = btn.get_meta("uifx_hovered", false)
		_scale_to(btn, HOVER_SCALE if hovered else 1.0, HOVER_TIME)

func _scale_to(btn: Button, target: float, duration: float) -> void:
	if not btn.has_meta("uifx_base_scale"):
		btn.set_meta("uifx_base_scale", btn.scale)
	var base: Vector2 = btn.get_meta("uifx_base_scale")
	btn.pivot_offset = btn.size / 2.0
	if btn.has_meta("uifx_tween"):
		var prev: Tween = btn.get_meta("uifx_tween")
		if prev:
			prev.kill()
	var t = btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(btn, "scale", base * target, duration)
	btn.set_meta("uifx_tween", t)
