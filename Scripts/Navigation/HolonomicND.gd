class_name HolonomicND
extends Node2D

var VALLEY_HYSTERESIS: float = PI * 0.75 ## Minimum angle improvement to switch to a non-consecutive target valley
var RAY_DISTANCE: float = 1.0 * World.ppu
var PATHFINDER_SHAPE_RADIUS: float = 28


func _ready() -> void:
	_cast_shape.radius = PATHFINDER_SHAPE_RADIUS

	# Setup valley debug line
	_valley_line = Line2D.new()
	_valley_line.width = 10.0
	_valley_line.default_color = Color.YELLOW
	World.add_child(_valley_line)

	# This area will enable the rays in a low safety zone (obstacles close)
	_safety_zone = Area2D.new()
	add_child(_safety_zone)

	var safe_shape = CollisionShape2D.new()
	safe_shape.shape = CircleShape2D.new()
	safe_shape.shape.radius = RAY_DISTANCE
	safe_shape.name = "SafeShape"
	_safety_zone.add_child(safe_shape)

	_safety_zone.monitoring = false
	_safety_zone.collision_mask = World.GROUND_COLLISION_MASK
	_safety_zone.collision_layer = 0

	_safety_zone.body_entered.connect(_safety_zone_enter)
	_safety_zone.body_exited.connect(_safety_zone_exit)

	# Setup proximity rays
	for i in range(8):
		var ray: RayCast2D = RayCast2D.new()
		ray.target_position = Vector2(1, 0).rotated(i * (PI / 4)) * RAY_DISTANCE
		ray.collision_mask = World.GROUND_COLLISION_MASK
		ray.enabled = false

		add_child(ray)
		_proximity_rays.append(ray)
		_ray_angles.append(i * (PI / 4))

func set_shape(ray_distance: float, cast_radius: float) -> void:
	PATHFINDER_SHAPE_RADIUS = cast_radius
	_cast_shape.radius = PATHFINDER_SHAPE_RADIUS

	RAY_DISTANCE = ray_distance
	_safety_zone.get_node("SafeShape").shape.radius = RAY_DISTANCE

	for i in range(8):
		_proximity_rays[i].target_position = Vector2(1, 0).rotated(i * (PI / 4)) * RAY_DISTANCE

func _safety_zone_enter(_body: Node) -> void: # Ground detected
	if nSafetyObstacles == 0:
		_enable_rays()
	nSafetyObstacles += 1
func _safety_zone_exit(_body: Node) -> void: # Ground lost
	nSafetyObstacles -= 1
	if nSafetyObstacles == 0:
		_disable_rays()

func compute_direction(actor: Vector2, target: Vector2) -> Vector2:
	var to_target := target - actor
	var direction: Vector2 = to_target
	var ray_end: Vector2 = actor + to_target.normalized() * minf(to_target.length(), RAY_DISTANCE * 2.0)

	# Path is occluded, we need to change the direction
	if World.ray_intersects_ground(actor, ray_end) or _circle_intersects(actor, ray_end):

		var valley = _select_valley(actor, to_target.angle())

		# Combine fleeing from walls with going to a valley
		if valley != INF:
			direction = _repel_walls() + Vector2(1, 0).rotated(valley)

	return direction.normalized()


func _isValley(actor: Vector2, ray: RayCast2D) -> bool:
	# If the ray is not colliding, refine with a shape cast
	return not ray.is_colliding() and not _circle_intersects(actor, actor + ray.target_position)

## Receives angle in -pi to pi radians
func _select_valley(actor: Vector2, goal: float) -> float:
	# Sort by proximity to goal angle to optimize the search
	var sorted_rays: Array = range(_proximity_rays.size())
	sorted_rays.sort_custom(func(a: int, b: int) -> bool:
		return absf(angle_difference(_ray_angles[a], goal)) < absf(angle_difference(_ray_angles[b], goal))
	)
	
	# Find closest free valley
	var closest_free_idx: int = -1
	var closest_distance: float = INF
	for i in sorted_rays:
		var ray = _proximity_rays[i]
		var distance = absf(angle_difference(_ray_angles[i], goal))

		# Closer to goal and is a valley
		if distance < closest_distance and _isValley(actor, ray):
			closest_free_idx = i
			closest_distance = distance

	if closest_free_idx == -1: # No free valley found
		_previous_valley = -1
		return INF


	# Compare the previous and new valley to apply hysteresis
	if _previous_valley != -1:
		if (
			absi(closest_free_idx - _previous_valley) == 1 or 								# Consecutive indexes
			(closest_free_idx == 0 and _previous_valley == _proximity_rays.size() - 1) or    # Wrap around valleys
			(closest_free_idx == _proximity_rays.size() - 1 and _previous_valley == 0)
		):
			# Always switch if the valleys are consecutive
			_previous_valley = closest_free_idx
			_previous_valley_angle = _ray_angles[closest_free_idx]
		else:
			# Not consecutive, apply hysteresis
			var new_angle = _ray_angles[closest_free_idx]
			var improvement = absf(angle_difference(_previous_valley_angle, goal)) - absf(angle_difference(new_angle, goal))
			if improvement > VALLEY_HYSTERESIS:
				_previous_valley_angle = new_angle
				_previous_valley = closest_free_idx
	# If we have no previous valley, just use the new one
	else: 
		_previous_valley = closest_free_idx
		_previous_valley_angle = _ray_angles[closest_free_idx]

	return _previous_valley_angle

## Returns a force vector to flee from nearby walls
func _repel_walls() -> Vector2:
	return _proximity_rays.reduce(
	func(accum: Vector2, ray: RayCast2D) -> Vector2:
		if ray.is_colliding():
			# Flee faster from closer walls
			var p_collision := ray.get_collision_point() - ray.global_position
			var fleeSpeed = (RAY_DISTANCE - p_collision.length()) / RAY_DISTANCE

			accum += fleeSpeed * (-p_collision.normalized())
		return accum
	, Vector2.ZERO)

func _circle_intersects(from: Vector2, to: Vector2) -> bool:

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = _cast_shape
	query.collision_mask = World.GROUND_COLLISION_MASK

	query.transform = Transform2D.IDENTITY
	query.transform.origin = from
	query.motion = to - from

	var physics := World.get_world_2d().direct_space_state
	var result = physics.intersect_shape(query)

	return not result.is_empty()

func _enable_rays() -> void:
	for ray in _proximity_rays:
		ray.enabled = true

func _disable_rays() -> void:
	for ray in _proximity_rays:
		ray.enabled = false

var _proximity_rays: Array[RayCast2D] = [] ## Rays used to detect nearby walls
var _ray_angles: PackedFloat32Array
var _previous_valley_angle: float = INF
var _previous_valley: int = -1
var nSafetyObstacles: int = 0 ## Number of obstacles in the safety zone

var _cast_shape: CircleShape2D = CircleShape2D.new()
var _safety_zone: Area2D = null
var _valley_line: Line2D = null  # Debug line for valley angle
