class_name RTTstarNavigationGD
extends ActorNavigation



var MAX_NEIGHBORS: int = 5
var SAMPLE_DISTANCE_MULTIPLIER: float = 2.0
var RECOMPUTE_GOAL_DISTANCE: float = 2 * World.ppu

var MAX_TREE_SIZE: int = 1000
var TREE_BUILD_SAMPLES: int = 100
var TREE_REFINE_SAMPLES: int = 5

var _target_path: PackedVector2Array
var _current_path_node: int
var verbose: bool = true

func _on_ready() -> void:
	_path_display = RTTstarDisplay.new()
	_path_display.show_connections = true
	_path_display.marker_radius = 8.0
	_path_display.marker_outline_width = 1.0
	World.add_child(_path_display)
	
	_tree_display = RTTstarDisplay.new()
	_tree_display.marker_color = Color.BLUE
	_tree_display.marker_radius = 3.0
	_tree_display.show_numbers = false
	_tree_display.marker_outline_width = 1.0
	_tree_display.show_connections = false
	World.add_child(_tree_display)

	DISTANCE_EPSILON = World.ppu * 0.5

	#Engine.time_scale = 0.2

func travel_to(_target: Vector2) -> void:
	_disabled = false
	_current_goal = _target

func stop() -> void:
	actor.stop()
	_disabled = true
	_tree.clear()
	_target_path = []


func _clear_tree() -> void:
	_tree.clear()
	_tree.set_origin(actor.global_position)
	_current_path_node = 0

	if _tree_display:
		_tree_display.clear_markers()

func _build_new_tree(_origin: Vector2, target: Vector2):
	_clear_tree()

	# Generate many samples to favor a quick path, but stop as soon as the goal is reached
	_generate_samples(target, TREE_BUILD_SAMPLES, true)

	if verbose:
		print("Built new RTT* tree with ", _tree.size(), " nodes towards ", target)
	

func _generate_samples(target: Vector2, nSamples: int, stop_on_goal: bool) -> void:
	# Expand the tree until finished
	for i in range(nSamples):
		# Safety to prevent too large trees
		if _tree.size() >= MAX_TREE_SIZE:
			return

		# Generate a new point
		var sample_point := _sample_point(target)
		_insert_point(sample_point)

		if stop_on_goal and not World.ray_intersects_ground(sample_point, target):
			return

# Uniform disk sampling around the center between actor and target
func _sample_point(target: Vector2) -> Vector2:
	var l_center := (target - actor.global_position) * 0.5
	var center := actor.global_position + l_center

	var angle := randf_range(0, TAU)
	var d := l_center.length() * SAMPLE_DISTANCE_MULTIPLIER
	var r := sqrt(randf()) * d

	return center + r * Vector2.from_angle(angle)




## Insert a point into the RTT* tree and connect it appropriately
## Returns the accumulated distance of the new node, or INF if not connected
func _insert_point(point: Vector2) -> float:
	var nearest := _tree.get_k_nearest(point, MAX_NEIGHBORS)

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
		var total_distance: float = buff_parent_cost[i] + _tree.get_point(idx).distance_to(point)

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
	

## Returns the path index that the actor should head towards
func _follow_trajectory(new_path: PackedVector2Array) -> int:
	var pos = actor.global_position
	var min_dist = INF
	var best_segment = 0
	
	# Find closest point on path segments
	for i in range(new_path.size() - 1):
		var closest = Geometry2D.get_closest_point_to_segment(pos, new_path[i], new_path[i + 1])
		var dist = pos.distance_squared_to(closest)
		if dist < min_dist:
			min_dist = dist
			best_segment = i

	return best_segment + 1


## Refine and follow the generated trajectory towards the target
func _physics_process(_delta: float) -> void:
	if _disabled:
		return

	# Direct path to target is clear, go directly
	if not World.ray_intersects_ground(actor.global_position, _current_goal):
		# Direct path to target is clear
		actor.move_to(_current_goal)
		if is_at_target(_current_goal):
			target_reached.emit(_current_goal)
			_disabled = true
		return


	###################### Generate RTT trajectory #########################

	if _tree.isEmpty(): # Build or refine the tree
		_build_new_tree(actor.global_position, _current_goal)
	else:
		_generate_samples(_current_goal, TREE_REFINE_SAMPLES, false)

	var path := _tree.build_path(_current_goal, MAX_NEIGHBORS)
	if path.is_empty(): 
		if _tree.size() == MAX_TREE_SIZE:
			_tree.clear() # Tree is full but no path found, reset
			if verbose:
				print("The tree is full and no path was found, clearing tree")
		return  # No path found

	var target := _follow_trajectory(path) # Get target index on path
	if World.ray_intersects_ground(actor.global_position, path[target]):
		_tree.clear() # Cannot travel to the path, rebuild tree
		if verbose:
			print("Actor cannot travel to path node ", path[target], ", clearing tree")
		return

	# We are at the target itself
	if is_at_target(path[target]):
		if target < path.size() - 1:
			target += 1 # Move to the next target
		else:
			target_reached.emit(_current_goal)
			_disabled = true
			return

	if _path_display:
		_path_display.set_positions(path)
		_path_display.set_current_objective(target)

	# Compute direction to the next target
	actor.move_to(path[target])
	


var _disabled: bool = true
var _tree: RTTtreeGD = RTTtreeGD.new()
var _current_goal: Vector2

# RTTstarDisplay for debugging
var _path_display: RTTstarDisplay = null
var _tree_display: RTTstarDisplay = null

var buff_parent_cost: PackedFloat32Array = []
var buff_is_connected: PackedByteArray = []



#######################################################
################### RTT tree Class ####################
#######################################################

class RTTtreeGD:
	var points: PackedVector2Array
	var connections: PackedInt32Array # Index of the father of each node
	var origin: int = -1

	func clear() -> void:
		points = []
		connections = []
		origin = -1
	func isEmpty() -> bool:
		return points.size() == 0
	func size() -> int:
		return points.size()

	func set_origin(point: Vector2) -> int:
		origin = connect_point(point, -1)
		return origin
	func get_origin() -> Vector2:
		return points[origin]
	func connect_point(point: Vector2, father_idx: int) -> int:
		points.append(point)
		connections.append(father_idx)
		return points.size() - 1

	func reconnect_point(idx: int, new_father_idx: int) -> void:
		connections[idx] = new_father_idx

	func get_point(idx: int) -> Vector2:
		return points[idx]

	## Returns the total travel distance from this node to the tree root
	func compute_cost(idx: int) -> float:
		var total_distance := 0.0
		var current_idx := idx
		var father_idx := connections[current_idx]

		# Traverse up to the root
		while father_idx != -1:
			total_distance += points[current_idx].distance_to(points[father_idx])

			current_idx = father_idx
			father_idx = connections[current_idx]

		return total_distance

	## Get the k nearest neighbors to a point
	func get_k_nearest(point: Vector2, k: int) -> PackedInt32Array:
		var nearest_idx: PackedInt32Array = []
		var distances: PackedFloat32Array = []
		
		nearest_idx.resize(k)
		distances.resize(k)
		distances.fill(INF)

		for i in range(points.size()):
			var p := points[i]
			var dist := point.distance_squared_to(p) # Since we are only comparing, sqrt is not necessary
			var idx := distances.bsearch(dist)

			if idx != distances.size(): # The point is closer than some existant
				distances.insert(idx, dist)
				nearest_idx.insert(idx, i)
				distances.remove_at(distances.size()-1)
				nearest_idx.remove_at(nearest_idx.size()-1)

		# Remove INFs from the array
		for i in range(distances.size()-1, -1, -1):
			if distances[i] == INF:
				nearest_idx.remove_at(nearest_idx.size()-1)

		return nearest_idx

	## Get all neighbors within a certain radius
	func get_nearest(point: Vector2, radius: float) -> PackedInt32Array:
		var nearest_idx: PackedInt32Array = []
		var sqr_radius := radius * radius
		
		for i in range(points.size()):
			var p := points[i]
			var dist := point.distance_squared_to(p) # SInce we are only comparing, sqrt is not necessary

			if dist < sqr_radius: # The point is within the search radius
				nearest_idx.append(i)

		return nearest_idx

	## Computes the best known path from the tree origin to the goal,
	##  or an empty array if no path was found
	func build_path(goal: Vector2, max_neighbors: int) -> PackedVector2Array:
		# Find best goal parent
		var nearest := get_k_nearest(goal, max_neighbors)

		var parent: int = -1
		var min_distance := INF
		for i in range(nearest.size()):
			var p := points[nearest[i]]
			var d = compute_cost(nearest[i]) + p.distance_to(goal)
			
			# Find the best reachable neighbor
			if not World.ray_intersects_ground(p, goal) \
					and d < min_distance:
				parent = nearest[i]
				min_distance = d 

		if parent == -1:
			return PackedVector2Array() # No path found
				
		# Build path from goal parent to root
		var path: PackedVector2Array = []

		# Traverse up to the root
		while parent != -1:
			path.append(points[parent])
			parent = connections[parent]
		
		path.reverse()
		path.append(goal)
		
		return path
