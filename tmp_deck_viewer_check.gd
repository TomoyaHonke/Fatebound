extends Control


func _ready() -> void:
	var viewer_scene: PackedScene = load("res://scenes/ui/DeckViewer.tscn")
	var viewer = viewer_scene.instantiate()
	add_child(viewer)
	viewer.show_deck(GameState.current_deck)
	await get_tree().process_frame
	if not viewer.visible:
		push_error("DeckViewer did not become visible.")
		get_tree().quit(1)
		return
	get_tree().quit()
