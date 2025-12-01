extends Control

func _ready() -> void:
	$MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

func _on_main_menu_button_pressed() -> void:
	World.load_menu()
	$AudioStreamPlayer2.play()

func _on_main_menu_button_mouse_entered() -> void:
	$AudioStreamPlayer.play()
