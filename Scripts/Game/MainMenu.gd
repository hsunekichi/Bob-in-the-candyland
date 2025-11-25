extends Control

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$PlayDebug.pressed.connect(_on_play_debug)

func _on_play_button_pressed() -> void:
	World.load_maze()

func _on_play_debug() -> void:
	World.load_debug()
