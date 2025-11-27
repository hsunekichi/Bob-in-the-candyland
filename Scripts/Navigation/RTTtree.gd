## KD-Tree structure for efficient spatial queries in RTT*
class_name RTTtreeGD

class _RTTtreeNode:
	var point: Vector2
	var index: int
	var left: int = -1
	var right: int = -1
	func _init(pt: Vector2, idx: int):
		point = pt
		index = idx

var nodes: Array = []
var root: int = -1
var points: PackedVector2Array = []
var connections: PackedInt32Array = []
var origin: int = -1

func clear() -> void:
	nodes.clear()
	root = -1
	points.clear()
	connections.clear()
	origin = -1
func isEmpty() -> bool:
	return root == -1
func size() -> int:
	return nodes.size()
func set_origin(point: Vector2) -> int:
	origin = connect_point(point, -1)
	return origin
func get_origin() -> Vector2:
	return points[origin]
func get_point(idx: int) -> Vector2:
	return points[idx]
func get_parent(idx: int) -> int:
	return connections[idx]


func connect_point(point: Vector2, father_idx: int) -> int:
	var idx = points.size()
	points.append(point)
	connections.append(father_idx)
	root = _insert_recursive(root, point, idx, 0)
	return idx
func reconnect_point(idx: int, new_father_idx: int) -> void:
	connections[idx] = new_father_idx


func compute_cost(idx: int) -> float:
	var total := 0.0
	var current := idx
	while connections[current] != -1:
		total += points[current].distance_to(points[connections[current]])
		current = connections[current]
	return total

func get_k_nearest(point: Vector2, k: int) -> PackedInt32Array:
	if root == -1:
		return PackedInt32Array()
	
	# Use separate arrays instead of nested arrays for better cache performance
	var heap_indices: PackedInt32Array = []
	var heap_dists: PackedFloat32Array = []
	var worst_dist := INF
	
	# Stack for iterative traversal - use flat arrays
	var stack_nodes: PackedInt32Array = []
	var stack_depths: PackedInt32Array = []
	var stack_phases: PackedInt32Array = []  # phase 0: process node, phase 1: check far child
	
	# Pre-allocate stack with reasonable size
	stack_nodes.resize(32)
	stack_depths.resize(32)
	stack_phases.resize(32)
	
	stack_nodes[0] = root
	stack_depths[0] = 0
	stack_phases[0] = 0
	var stack_size := 1
	
	while stack_size > 0:
		stack_size -= 1
		var node_idx = stack_nodes[stack_size]
		var depth = stack_depths[stack_size]
		var phase = stack_phases[stack_size]
		
		if node_idx == -1:
			continue
		
		var node = nodes[node_idx]
		
		if phase == 0:
			# Process current node
			var dist = node.point.distance_squared_to(point)
			
			var heap_size = heap_indices.size()
			if heap_size < k:
				heap_indices.append(node.index)
				heap_dists.append(dist)
				if dist > worst_dist:
					worst_dist = dist
			elif dist < worst_dist:
				# Find and replace worst element (simple linear search for small k)
				var worst_idx := 0
				worst_dist = heap_dists[0]
				for i in range(1, k):
					if heap_dists[i] > worst_dist:
						worst_dist = heap_dists[i]
						worst_idx = i
				heap_indices[worst_idx] = node.index
				heap_dists[worst_idx] = dist
			
			# Determine near and far children
			var cd = depth % 2
			var diff = point[cd] - node.point[cd]
			var near = node.left if diff < 0 else node.right
			
			# Push far child check for later (phase 1)
			if stack_size >= stack_nodes.size():
				var new_size = stack_nodes.size() * 2
				stack_nodes.resize(new_size)
				stack_depths.resize(new_size)
				stack_phases.resize(new_size)
			stack_nodes[stack_size] = node_idx
			stack_depths[stack_size] = depth
			stack_phases[stack_size] = 1
			stack_size += 1
			
			# Push near child for immediate exploration
			if near != -1:
				if stack_size >= stack_nodes.size():
					var new_size = stack_nodes.size() * 2
					stack_nodes.resize(new_size)
					stack_depths.resize(new_size)
					stack_phases.resize(new_size)
				stack_nodes[stack_size] = near
				stack_depths[stack_size] = depth + 1
				stack_phases[stack_size] = 0
				stack_size += 1
		
		else:  # phase == 1
			# Check if we need to explore far child
			var cd = depth % 2
			var diff = point[cd] - node.point[cd]
			var far = node.right if diff < 0 else node.left
			
			if far != -1 and (heap_indices.size() < k or diff * diff < worst_dist):
				if stack_size >= stack_nodes.size():
					var new_size = stack_nodes.size() * 2
					stack_nodes.resize(new_size)
					stack_depths.resize(new_size)
					stack_phases.resize(new_size)
				stack_nodes[stack_size] = far
				stack_depths[stack_size] = depth + 1
				stack_phases[stack_size] = 0
				stack_size += 1
	
	# Sort by distance using insertion sort (efficient for small k)
	for i in range(1, heap_indices.size()):
		var key_idx = heap_indices[i]
		var key_dist = heap_dists[i]
		var j = i - 1
		while j >= 0 and heap_dists[j] > key_dist:
			heap_indices[j + 1] = heap_indices[j]
			heap_dists[j + 1] = heap_dists[j]
			j -= 1
		heap_indices[j + 1] = key_idx
		heap_dists[j + 1] = key_dist
	
	return heap_indices

func get_nearest(point: Vector2, radius: float) -> PackedInt32Array:
	var result: PackedInt32Array = []
	var sqr_radius = radius * radius
	for i in range(points.size()):
		if points[i].distance_squared_to(point) < sqr_radius:
			result.append(i)
	return result
	


func _insert_recursive(node_idx: int, point: Vector2, index: int, depth: int) -> int:
	if node_idx == -1:
		var new_idx = nodes.size()
		nodes.append(_RTTtreeNode.new(point, index))
		return new_idx
	
	var cd = depth % 2
	if point[cd] < nodes[node_idx].point[cd]:
		nodes[node_idx].left = _insert_recursive(nodes[node_idx].left, point, index, depth + 1)
	else:
		nodes[node_idx].right = _insert_recursive(nodes[node_idx].right, point, index, depth + 1)
	return node_idx
