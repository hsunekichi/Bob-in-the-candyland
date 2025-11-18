@abstract class_name ActorNavigation
extends Node

var actor: CharacterBody2D
var global_position: Vector2:
	get: return actor.global_position
	set(value): actor.global_position = value
var DISTANCE_EPSILON: float = 20

@warning_ignore("UNUSED_SIGNAL")
signal target_reached(target: Vector2) ## Emitted when the actor enters the zone within DISTANCE_EPSILON of the target

func _ready() -> void:
	actor = get_parent() as CharacterBody2D
	assert(actor != null, "ActorKinematics must be a child of a CharacterBody2D node.")

	_on_ready()

func _on_ready() -> void: pass # To be overridden by subclasses

@abstract func travel_to(_target: Vector2) -> void
@abstract func stop() -> void

## Checks if the actor is at the target within a given tolerance. 
##  Returns true the first time the actor reaches the target, false otherwise.
func is_at_target(target: Vector2, tolerance: float = DISTANCE_EPSILON) -> bool:
	var reached: bool = actor.global_position.distance_to(target) < tolerance
	return reached and (not _target_already_reached or _target_reach_position != target)


## Checks if the actor has reached the target and notifies listeners. 
##  Returns true if within the target, false otherwise.
func _check_target_reached(target: Vector2) -> bool:
	var reached: bool = actor.global_position.distance_to(target) < DISTANCE_EPSILON
	if reached and (not _target_already_reached or _target_reach_position != target):
		_target_already_reached = true
		_target_reach_position = target
		target_reached.emit(target)
	elif not reached:
		_target_already_reached = false

	return reached

var _target_already_reached: bool = false
var _target_reach_position: Vector2 ## Prevents multiple emissions for the same target