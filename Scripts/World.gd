extends Node2D

const ppu: float = 64.0 # pixels per unit 
var raycast: RayCast2D
const GROUND_COLLISION_MASK: int = 1
var verbose: bool = false

func _ready() -> void:
    raycast = RayCast2D.new()
    add_child(raycast)
    raycast.enabled = false
    raycast.collision_mask = GROUND_COLLISION_MASK
    raycast.hit_from_inside = true

func ray_intersects_ground(from: Vector2, to: Vector2) -> bool:
    raycast.global_position = from
    raycast.target_position = to - from  # target_position is RELATIVE to the raycast position
    raycast.force_raycast_update()

    return raycast.is_colliding()

func log(...msg: Array) -> void:
    if verbose:
        print(msg)