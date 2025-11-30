extends Control

@onready var difficulty_options: OptionButton = $DifficultyTexture/DifficultyOptions

func _ready() -> void:

	# Setup difficulty options
	difficulty_options.clear()
	difficulty_options.add_item("Easy", 0)
	difficulty_options.add_item("Medium", 1)
	difficulty_options.add_item("Hard", 2)
	difficulty_options.select(0)  # Default to Easy
	difficulty_options.item_selected.connect(_on_difficulty_selected)

func _on_difficulty_selected(index: int) -> void:
	$AudioStreamPlayer2.play()
	match index:
		0:
			World.set_difficulty("easy")
		1:
			World.set_difficulty("medium")
		2:
			World.set_difficulty("hard")


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
