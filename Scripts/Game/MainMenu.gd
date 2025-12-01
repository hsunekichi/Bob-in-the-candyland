extends Control

func _on_play_button_pressed() -> void:
	World.load_maze()
	$AudioStreamPlayer2.play()

func _on_play_debug() -> void:
	World.load_debug()
	$AudioStreamPlayer2.play()

func _on_play_controls() -> void:
	World.load_controls()
	$AudioStreamPlayer2.play()

func _on_mycontrol_mouse_entered():
	$AudioStreamPlayer.play()

func _on_nav_toggle_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_difficulty_options_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_difficulty_options_pressed() -> void:
	$AudioStreamPlayer2.play()
