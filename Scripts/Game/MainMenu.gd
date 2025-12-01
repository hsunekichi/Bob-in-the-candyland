extends Control

@onready var difficulty_options: OptionButton = $DifficultyTexture/DifficultyOptions

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$PlayDebug.pressed.connect(_on_play_debug)
	$Controls.pressed.connect(_on_play_controls)

func _on_play_button_pressed() -> void:
	World.load_maze()

func _on_play_debug() -> void:
	World.load_debug()

func _on_play_controls() -> void:
	World.load_controls()
