extends Control

@onready var background: TextureRect = $Background

func _ready() -> void:
	background.size = get_viewport_rect().size

	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	background.size = get_viewport_rect().size

func _on_play_button_pressed() -> void:
	World.load_maze()
	$AudioStreamPlayer2.play()

func _on_play_debug() -> void:
	World.load_debug()
	$AudioStreamPlayer2.play()

func _on_play_controls() -> void:
	World.load_controls()
	$AudioStreamPlayer2.play()
	
func _on_play_quit() -> void:
	$AudioStreamPlayer2.play()
	await $AudioStreamPlayer2.finished
	get_tree().quit()

func _on_mycontrol_mouse_entered():
	$AudioStreamPlayer.play()
	
func _on_quit_mouse_entered():
	$AudioStreamPlayer.play()

func _on_nav_toggle_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_difficulty_options_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_difficulty_options_pressed() -> void:
	$AudioStreamPlayer2.play()
