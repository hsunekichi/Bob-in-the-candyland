extends Node2D

const ppu: float = 64.0 # pixels per unit 
var raycast: RayCast2D
const GROUND_COLLISION_MASK: int = 1
var verbose: bool = false

var hud_scene: PackedScene = preload("res://Scenes/HUD.tscn")
var main_menu_scene: PackedScene = preload("res://Scenes/MainMenu.tscn")
var lose_menu_scene: PackedScene = preload("res://Scenes/LoseScene.tscn")
var maze_scene: PackedScene = preload("res://Scenes/Maze.tscn")
var debug_scene: PackedScene = preload("res://Scenes/Debug.tscn")

var scene_changing: bool = false

@export var win_screen_path: StringName = "res://Art/Screens/WinScreen.png"
@export var main_menu_scene_path: StringName = "res://Scenes/MainMenu.tscn"
var win_node: TextureRect

var pulse_scene: PackedScene = preload("res://Scripts/SFX/BatPulse.tscn")
var pulse_instance: Node2D = null

var config: Dictionary = {}
var HUD: HUDcontroller

var current_scene: Node = null

signal game_finished


func _ready() -> void:
	# Set clear color
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))

	raycast = RayCast2D.new()
	add_child(raycast)
	raycast.enabled = false
	raycast.collision_mask = GROUND_COLLISION_MASK
	raycast.hit_from_inside = true
	
	HUD = hud_scene.instantiate()
	add_child(HUD)

	win_node = TextureRect.new()
	win_node.texture = load(win_screen_path)
	win_node.visible = false
	HUD.add_child(win_node)

	# Load config from JSON file
	var config_path = "res://config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				config = json.data
			else:
				print("Error parsing config.json: ", json.get_error_message())
	else:
		print("Config file not found: ", config_path)

	# Await until the game is done loading
	await get_tree().process_frame

	Player.disable_input()
	Player.visible = false

	pulse_instance = pulse_scene.instantiate()
	add_child(pulse_instance)

	var pulse_speed: float = 2.0  # Scale units per second
	var pulse_size: float = 8.0  # max scale
	var pulse_duration: float = pulse_size / pulse_speed  # Compute duration from speed and size

	pulse_instance.set_parameters(pulse_size, pulse_duration, 1.0)

	load_menu()	

func ray_intersects_ground(from: Vector2, to: Vector2) -> bool:
	raycast.global_position = from
	raycast.target_position = to - from  # target_position is RELATIVE to the raycast position
	raycast.force_raycast_update()

	return raycast.is_colliding()

func log(...msg: Array) -> void:
	if verbose:
		print(msg)

func teleport_player(p: Vector2) -> void:
	Player.global_position = p

	# Move the camera immediately to the spawn point
	var mainCamera = get_viewport().get_camera_2d()
	mainCamera.global_position = Player.global_position
	mainCamera.reset_smoothing()

func load_menu() -> void:
	if scene_changing:
		return
	scene_changing = true

	await HUD.enable_transition()

	if current_scene:
		current_scene.queue_free()

	current_scene = main_menu_scene.instantiate()
	HUD.add_child(current_scene)

	await HUD.disable_transition()

	scene_changing = false

func load_maze() -> void:
	if scene_changing:
		return
	scene_changing = true

	await HUD.enable_transition()

	if current_scene:
		current_scene.queue_free()

	HUD.show_hud()
	Player.initialize()

	# Load maze
	current_scene = maze_scene.instantiate()
	current_scene.name = "Maze"
	add_child(current_scene)

	await HUD.disable_transition()

	scene_changing = false

func get_maze() -> Node:
	return get_node_or_null("Maze")

func load_debug() -> void:
	if not scene_changing:
		return
	scene_changing = false

	await HUD.enable_transition()

	# Remove menu
	HUD.remove_menu()
	HUD.show_hud()

	if current_scene:
		current_scene.queue_free()

	Player.initialize()

	# Load demo maze
	current_scene = debug_scene.instantiate()
	add_child(current_scene)


	await HUD.disable_transition()

func game_completed() -> void:
	# Show win screen
	game_finished.emit()
	scene_changing = true

	await HUD.enable_transition()
	win_node.visible = true

	if current_scene:
		current_scene.queue_free()

	await HUD.disable_transition()

	scene_changing = false

func activate_sugar_rush_effect() -> void:
	HUD.get_node("SugarRushEffect").enable()
func activate_sugar_eat_effect() -> void:
	HUD.get_node("EatSugarEffect").enable()

func emit_pulse(location: Vector2) -> void:
	if pulse_instance:
		pulse_instance.start_pulse(location)

func game_over() -> void:
	game_finished.emit()
	scene_changing = true

	# Show game over screen
	await HUD.enable_transition()
	
	if current_scene:
		current_scene.queue_free()

	current_scene = lose_menu_scene.instantiate()
	HUD.add_child(current_scene)

	await HUD.disable_transition()

	scene_changing = false

func health_changed(new_health: int) -> void:
	HUD.update_health(new_health)
func sugar_level_changed(new_value: int) -> void:
	HUD.update_sugar_level(new_value)

func config_value(key: String, default_value: Variant) -> Variant:
	if key in config:
		return config[key]
	return default_value
