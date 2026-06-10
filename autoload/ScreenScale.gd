extends Node

const DESIGN_SIZE := Vector2(1280.0, 720.0)


func apply(root: Control) -> void:
	if not root:
		return
	_apply(root)
	var viewport := root.get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_size_changed.bind(root)):
		viewport.size_changed.connect(_on_viewport_size_changed.bind(root))


func _on_viewport_size_changed(root: Control) -> void:
	if is_instance_valid(root):
		_apply(root)


func _apply(root: Control) -> void:
	var viewport_size := Vector2(root.get_viewport_rect().size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	root.size = DESIGN_SIZE
	root.scale = Vector2(scale_factor, scale_factor)
