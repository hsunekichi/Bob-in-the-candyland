extends Node2D

const ppu: float = 64.0 # pixels per unit 
var raycast: RayCast2D
const GROUND_COLLISION_MASK: int = 1
var verbose: bool = false

var hud_scene: PackedScene = preload("res://Scenes/MainScenes/HUD.tscn")
var main_menu_scene: PackedScene = preload("res://Scenes/MainScenes/MainMenu.tscn")
var lose_menu_scene: PackedScene = preload("res://Scenes/MainScenes/LoseScene.tscn")
var win_scene: PackedScene = preload("res://Scenes/MainScenes/WinScene.tscn")
var maze_scene: PackedScene = preload("res://Scenes/MainScenes/Maze.tscn")
var debug_scene: PackedScene = preload("res://Scenes/MainScenes/Debug.tscn")

var scene_changing: bool = false

@export var main_menu_scene_path: StringName = "res://Scenes/MainScenes/MainMenu.tscn"

var pulse_scene: PackedScene = preload("res://Scenes/GameAssets/BatPulse.tscn")
var pulse_instance: Node2D = null

var config: Dictionary = {}
var HUD: HUDcontroller

var current_scene: Node = null
var show_navigation: bool = false

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

	# Finish the HUD a bit before the actual effect
	var sugar_rush = World.config_value("sugar_rush_duration", 2.0)
	HUD.get_node("SugarRushEffect").set_duration(sugar_rush - 0.5)

	var pulse_speed: float = 2.0  # Scale units per second
	var pulse_size: float = 8.0  # max scale
	var pulse_duration: float = pulse_size / pulse_speed  # Compute duration from speed and size

	pulse_instance.set_parameters(pulse_size, pulse_duration, 1.0)

	load_maze()	

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

func change_scene(scene: PackedScene, scene_name: String = "", parent: Node = null, setup_callback: Callable = Callable()) -> void:
	"""Generic scene change function with transition and optional setup callback."""
	if scene_changing:
		return
	scene_changing = true

	await HUD.enable_transition()

	# Clean up current scene
	if current_scene:
		current_scene.queue_free()

	# Execute setup callback if provided (for pre-scene setup)
	if setup_callback.is_valid():
		setup_callback.call()

	# Instantiate new scene
	current_scene = scene.instantiate()
	if scene_name != "":
		current_scene.name = scene_name
	
	# Add to appropriate parent (HUD or World)
	if parent == null:
		parent = self
	parent.add_child(current_scene)

	await HUD.disable_transition()

	scene_changing = false

func load_menu() -> void:
	change_scene(main_menu_scene, "", HUD)

func load_maze() -> void:
	var initialize_player = func():
		HUD.show_hud()
		Player.initialize()
	change_scene(maze_scene, "Game", self, initialize_player)

func get_maze() -> Node:
	var game = get_node_or_null("Game")
	return game.get_node_or_null("Maze") if game else null

func load_debug() -> void:
	var initialize_player = func():
		HUD.show_hud()
		Player.initialize()
		Player.increase_sugar(100)
	change_scene(debug_scene, "Game", self, initialize_player)
func game_completed() -> void:
	game_finished.emit()
	change_scene(win_scene, "", HUD)

func activate_sugar_rush_effect() -> void:
	HUD.get_node("SugarRushEffect").enable()
func activate_sugar_eat_effect() -> void:
	HUD.get_node("EatSugarEffect").enable()

func emit_pulse(location: Vector2) -> void:
	if pulse_instance:
		pulse_instance.start_pulse(location)

func game_over() -> void:
	game_finished.emit()
	change_scene(lose_menu_scene, "", HUD)

func health_changed(new_health: int) -> void:
	HUD.update_health(new_health)
func sugar_level_changed(new_value: int) -> void:
	HUD.update_sugar_level(new_value)

func config_value(key: String, default_value: Variant) -> Variant:
	if key in config:
		return config[key]
	return default_value
