extends Node2D

const ppu: float = 64.0 # pixels per unit 
var raycast: RayCast2D
const GROUND_COLLISION_MASK: int = 1
var verbose: bool = false

var hud_scene: PackedScene = preload("res://Scenes/HUD.tscn")
var HUD: HUDcontroller


func _ready() -> void:
	raycast = RayCast2D.new()
	add_child(raycast)
	raycast.enabled = false
	raycast.collision_mask = GROUND_COLLISION_MASK
	raycast.hit_from_inside = true
	
	HUD = hud_scene.instantiate()
	add_child(HUD)

	# Await until the game is done loading
	await get_tree().process_frame

	game_begin()
	

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

func game_begin() -> void:
	pass

func game_completed() -> void:
	# Show win screen
	HUD.show_win_screen()
	Player.disable_input()
