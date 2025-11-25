extends Node2D

const ppu: float = 64.0 # pixels per unit 
var raycast: RayCast2D
const GROUND_COLLISION_MASK: int = 1
var verbose: bool = false

var hud_scene: PackedScene = preload("res://Scenes/HUD.tscn")
var main_menu_scene: PackedScene = preload("res://Scenes/MainMenu.tscn")
var maze_scene: PackedScene = preload("res://Scenes/Maze.tscn")
var debug_scene: PackedScene = preload("res://Scenes/Debug.tscn")
var HUD: HUDcontroller


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

	# Await until the game is done loading
	await get_tree().process_frame

	Player.disable_input()
	Player.visible = false

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
	await HUD.enable_transition()

	var main_menu_instance: Node = main_menu_scene.instantiate()
	main_menu_instance.name = "MainMenu"
	HUD.add_child(main_menu_instance)

	await HUD.disable_transition()

func load_maze() -> void:
	await HUD.enable_transition()

	# Remove menu
	HUD.get_node("MainMenu").queue_free()

	# Load maze
	var maze: Node = maze_scene.instantiate()
	add_child(maze)

	# Enable player input and make visible
	Player.enable_input()
	Player.visible = true

	await HUD.disable_transition()

func load_debug() -> void:
	await HUD.enable_transition()

	# Remove menu
	HUD.get_node("MainMenu").queue_free()

	# Load demo maze
	var scene: Node = debug_scene.instantiate()
	add_child(scene)

	# Enable player input and make visible
	Player.enable_input()
	Player.visible = true

	await HUD.disable_transition()

func game_completed() -> void:
	# Show win screen
	HUD.show_win_screen()
	Player.disable_input()
