extends Control

var controls_scene := preload("res://Scenes/controlsScreen.tscn")

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$PlayDebug.pressed.connect(_on_play_debug)
	$Controls.pressed.connect(_on_play_controls)

func _on_play_button_pressed() -> void:
	World.load_maze()

func _on_play_debug() -> void:
	World.load_debug()

func _on_play_controls() -> void:
	var controls = controls_scene.instantiate()
	add_child(controls)
