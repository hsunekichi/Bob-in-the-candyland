extends Control


func _ready() -> void:
	$RetryButton.pressed.connect(_on_retry_button_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

func _on_retry_button_pressed() -> void:
	World.load_maze()

func _on_main_menu_button_pressed() -> void:
	World.load_menu()
