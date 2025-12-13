extends Control


func _ready() -> void:
	$RetryButton.pressed.connect(_on_retry_button_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

	_on_viewport_size_changed()
	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	$Background.size = get_viewport_rect().size
	
func _on_retry_button_pressed() -> void:
	World.load_maze()
	$AudioStreamPlayer2.play()

func _on_main_menu_button_pressed() -> void:
	World.load_menu()
	$AudioStreamPlayer2.play()


func _on_mycontrol_mouse_entered():
	$AudioStreamPlayer.play()
