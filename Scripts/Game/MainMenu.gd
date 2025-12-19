extends Control

@onready var background: TextureRect = $Background

@onready var warning_menu: Control = $WarningMenu
@onready var confirm_warning_btn: BaseButton = $WarningMenu/ConfirmButton

var warning_menu_visible := false

func _ready() -> void:
	background.size = get_viewport_rect().size

	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)
		
	warning_menu_visible = false
	warning_menu.visible = false
	


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
	await get_tree().create_timer(0.3).timeout
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
	
func _on_confirm_warning_menu_pressed() -> void:
	_hide_warning_menu()
	$AudioStreamPlayer2.play()
	
func _on_confirm_warning_menu_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _show_warning_menu() -> void:
	warning_menu_visible = true
	warning_menu.visible = true
	$Background/DifficultyTexture.visible = false
	_set_main_menu_inputs_enabled(false)

func _hide_warning_menu() -> void:
	warning_menu_visible = false
	warning_menu.visible = false
	$Background/DifficultyTexture.visible = true
	_set_main_menu_inputs_enabled(true)

func _set_main_menu_inputs_enabled(enabled: bool) -> void:
	$Background/PlayButton.disabled = not enabled
	$Background/PlayDebug.disabled = not enabled
	$Background/Controls.disabled = not enabled
	$Background/Quit.disabled = not enabled
	$Background/DifficultyTexture/DifficultyOptions.disabled = not enabled
	$Background/NavToggle.disabled = not enabled
