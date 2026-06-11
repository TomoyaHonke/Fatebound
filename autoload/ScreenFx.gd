extends Node
## Full-screen atmosphere overlays shared by every scene:
## - vignette (subtle edge darkening, below PauseOverlay)
## - black fade-in on every scene change (above PauseOverlay)

const VIGNETTE_LAYER := 60
const FADE_LAYER := 95
const FADE_IN_DURATION := 0.45

const VIGNETTE_SHADER_CODE := """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.30;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv * vec2(1.0, 1.18));
	float v = smoothstep(0.42, 0.92, dist);
	COLOR = vec4(0.010, 0.008, 0.022, v * strength);
}
"""

var _fade_rect: ColorRect
var _last_scene: Node = null
var _fade_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_vignette()
	_build_fade()

func _build_vignette() -> void:
	var layer = CanvasLayer.new()
	layer.name = "VignetteLayer"
	layer.layer = VIGNETTE_LAYER
	add_child(layer)

	var rect = ColorRect.new()
	rect.name = "Vignette"
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = Shader.new()
	shader.code = VIGNETTE_SHADER_CODE
	var mat = ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	layer.add_child(rect)

func _build_fade() -> void:
	var layer = CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = FADE_LAYER
	add_child(layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "Fade"
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	layer.add_child(_fade_rect)

func _process(_delta: float) -> void:
	var scene = get_tree().current_scene
	if scene != _last_scene:
		_last_scene = scene
		if scene:
			_fade_in()

func _fade_in() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_rect.color.a = 1.0
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_fade_tween.tween_property(_fade_rect, "color:a", 0.0, FADE_IN_DURATION)
