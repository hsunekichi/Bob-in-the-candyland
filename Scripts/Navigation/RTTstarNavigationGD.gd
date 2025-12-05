class_name RTTstarNavigationGD
extends Node



var MAX_NEIGHBORS: int = 5 ## Maximum number of neighbors to consider when connecting a new point, controls efficiency and optimality of paths
var SAMPLE_DISTANCE_MULTIPLIER: float = 3.5 ## Multiplier for the sampling disk around the actor and goal. 1 means the circle will pass through each of them
var MIN_SAMPLE_DISTANCE: float = 0.45 * World.ppu ## Minimum distance to consider a neighbor valid when connecting a new point
var MIN_SAMPLE_DISTANCE_PATH: float = 0.2 * World.ppu ## Minimum distance to consider a neighbor valid when connecting a new point sampled along the path
var PATH_SAMPLING_PROBABILITY: float = 0.3 ## Probability to sample along the current path instead of the global circle when a path exists
var PATH_SAMPLING_RADIUS: float = 1.0 * World.ppu ## Radius around path points for sampling

var MAX_TREE_SIZE: int = 2000 ## Maximum number of nodes in the RTT* tree when no path exists
var MAX_TREE_SIZE_WITH_PATH: int = 600 ## Maximum number of nodes when a path is already found
var TREE_BUILD_SAMPLES: int = 10 ## Maxumum number of samples to generate when building a new tree. If a path is found earlier, the process stops
var TREE_REFINE_SAMPLES: int = 3 ## Number of samples to generate when refining an existing tree

var _tree_limit: int = MAX_TREE_SIZE
var _tree_increased_limit: int = 0

## Returns a trajectory from the origin to the target, optimized for the current position.
##  The trajectory may not be reachable from the current position, in which case the caller 
##  should restart this navigation system.
func generate_trajectory(current_position: Vector2, goal: Vector2) -> PackedVector2Array:
	
	if _tree.isEmpty(): # Build or refine the tree
		_build_new_tree(current_position, goal)

	var path := build_path(goal, MAX_NEIGHBORS)
	
	# Update tree limit based on whether we have a path
	if path.is_empty():
		_tree_limit = MAX_TREE_SIZE  # Allow larger tree when searching for initial path
	else:
		_tree_limit = MAX_TREE_SIZE_WITH_PATH + _tree_increased_limit  # Use smaller tree when refining existing path
	
	# Tree is full but no path found, reset
	if path.is_empty() and _tree.size() == _tree_limit:
		restart(current_position)
		# We should now rebuild the tree, but we leave it for the next call
		#  to not overload the current frame

		World.log("The tree is full and no path was found, clearing tree")
	else:
		_generate_samples(current_position, goal, TREE_REFINE_SAMPLES, path)
	
	return path

func restart(origin: Vector2) -> void:
	_tree.clear()
	_tree.set_origin(origin)

	if _tree_display:
		_tree_display.clear_markers()	

func increase_tree_limit(amount: int) -> void:
	_tree_increased_limit = min(_tree_increased_limit + amount, MAX_TREE_SIZE - MAX_TREE_SIZE_WITH_PATH)


func _build_new_tree(origin: Vector2, goal: Vector2):
	restart(origin)

	# Generate many samples to favor a quick path, but stop as soon as the goal is reached
	_generate_samples(origin, goal, TREE_BUILD_SAMPLES, PackedVector2Array())
	World.log("Built new RTT* tree with ", _tree.size(), " nodes towards ", goal)


func _generate_samples(origin: Vector2, goal: Vector2, nSamples: int, current_path: PackedVector2Array) -> void:
	# Expand the tree until finished
	for i in range(nSamples):
		# Safety to prevent too large trees
		if _tree.size() >= _tree_limit:
			return

		# Generate a new point
		var samplePath = randf() < PATH_SAMPLING_PROBABILITY # Need to decide it here to pass it to both functions
		var sample_point := _sample_point(origin, goal, current_path, samplePath)
		var cost := _insert_point(sample_point, samplePath)

		# If there was no previous path, stop as soon as we have it 
		if cost != INF and current_path.is_empty() and not World.ray_intersects_ground(sample_point, goal):
			return


# Uniform disk sampling around the center between actor and target
# If a path exists, with a certain probability samples along the path instead
func _sample_point(origin: Vector2, goal: Vector2, current_path: PackedVector2Array, samplePath: bool) -> Vector2:
	# If we have a path and random chance says so, sample along the path
	if not current_path.is_empty() and samplePath:
		# Pick a random segment along the path
		var segment_idx := randi_range(0, current_path.size() - 2)
		var segment_start := current_path[segment_idx]
		var segment_end := current_path[segment_idx + 1]
		
		# Pick a random point along the segment
		var t := randf()
		var point_on_segment := segment_start.lerp(segment_end, t)
		
		# Sample around this point in a circle
		var angle := randf_range(0, TAU)
		var r := sqrt(randf()) * PATH_SAMPLING_RADIUS
		
		return point_on_segment + r * Vector2.from_angle(angle)
	else:
		# Default: uniform disk sampling around the center between actor and target
		var l_center := (goal - origin) * 0.5
		var center := origin + l_center

		var angle := randf_range(0, TAU)
		var d := l_center.length() * SAMPLE_DISTANCE_MULTIPLIER
		var r := sqrt(randf()) * d

		return center + r * Vector2.from_angle(angle)


## Insert a point into the RTT* tree and connect it appropriately
## Returns the total cost of the new node, or INF if not connected
func _insert_point(point: Vector2, isPathSampled: bool) -> float:
	var nearest := _tree.get_k_nearest(point, MAX_NEIGHBORS)

	var min_sample_distance = MIN_SAMPLE_DISTANCE if not isPathSampled else MIN_SAMPLE_DISTANCE_PATH
	if nearest.is_empty() or _tree.get_point(nearest[0]).distance_to(point) < min_sample_distance:
		return INF # Too close to existing point

	buff_parent_cost.resize(nearest.size())
	buff_is_connected.resize(nearest.size())

	var closest_idx: int =  -1
	var new_distance := INF

	# Find the best unobstructed neighbour to connect to
	for i in range(nearest.size()):												# Find best unobstructed neighbour				
		var idx := nearest[i]
		buff_is_connected[i] = int(not World.ray_intersects_ground(_tree.get_point(idx), point))
		if not buff_is_connected[i]: 
			continue

		# Connect the point to its closest neighbor based on accumulated distance
		buff_parent_cost[i] = _tree.compute_cost(idx) # Distance from root to point idx
		var distance := _tree.get_point(idx).distance_to(point)
		var total_distance: float = buff_parent_cost[i] + distance

		if total_distance < new_distance:
			new_distance = total_distance
			closest_idx = idx

	# Connect the new point
	if closest_idx == -1: return INF						
	var new_idx := _tree.connect_point(point, closest_idx)						# Connect best neighbour
	if _tree_display: _tree_display.add_position(point)
	
	# Rewire neighbors if this point provides a shorter path
	for i in range(nearest.size()):		
		if buff_is_connected[i]:														        				
			# Distance through the new point
			var idx := nearest[i]
			var total_distance: float = new_distance + _tree.get_point(idx).distance_to(point)

			if total_distance < buff_parent_cost[i]: # If the new path is shorter than its previous one
				_tree.reconnect_point(idx, new_idx)

	return new_distance

## Computes the best known path from the tree origin to the goal,
##  or an empty array if no path was found
func build_path(goal: Vector2, max_neighbors: int) -> PackedVector2Array:
	# Find best goal parent
	var nearest := _tree.get_k_nearest(goal, max_neighbors)

	var parent: int = -1
	var min_distance := INF
	for i in range(nearest.size()):
		var p := _tree.get_point(nearest[i])
		var d := _tree.compute_cost(nearest[i]) + p.distance_to(goal)
		
		# Find the best reachable neighbor
		if d < min_distance and not World.ray_intersects_ground(p, goal):
			parent = nearest[i]
			min_distance = d 

	if parent == -1:
		return PackedVector2Array() # No path found
			
	# Build path from goal parent to root
	var path: PackedVector2Array = []

	# Traverse up to the root
	while parent != -1:
		path.append(_tree.get_point(parent))
		parent = _tree.get_parent(parent)

	path.reverse()
	path.append(goal)

	return path



func _ready() -> void:
	if World.show_navigation:
		_tree_display = RTTstarDisplay.new()
		_tree_display.marker_color = Color.BLUE
		_tree_display.marker_radius = 3.0
		_tree_display.show_numbers = false
		_tree_display.marker_outline_width = 1.0
		_tree_display.show_connections = false
		World.add_child(_tree_display)

func _exit_tree() -> void:
	if _tree_display:
		_tree_display.queue_free()
	

var _tree: RTTtreeGD = RTTtreeGD.new()
var _tree_display: RTTstarDisplay = null

var buff_parent_cost: PackedFloat32Array = []
var buff_is_connected: PackedByteArray = []
