extends Control

func _ready() -> void:
	$MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

func _on_main_menu_button_pressed() -> void:
	World.load_menu()
	$AudioStreamPlayer2.play()

func _on_mycontrol_mouse_entered():
	$AudioStreamPlayer.play()
