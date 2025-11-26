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
	var heap: Array = []
	
	if root == -1:
		return PackedInt32Array()
	
	# Stack for iterative traversal: [node_idx, depth, phase]
	# phase 0: process node, phase 1: check far child
	var stack: Array = [[root, 0, 0]]
	
	while stack.size() > 0:
		var frame = stack.pop_back()
		var node_idx = frame[0]
		var depth = frame[1]
		var phase = frame[2]
		
		if node_idx == -1:
			continue
		
		var node = nodes[node_idx]
		
		if phase == 0:
			# Process current node
			var dist = node.point.distance_squared_to(point)
			
			if heap.size() < k:
				heap.append([node.index, dist])
				if heap.size() == k:
					heap.sort_custom(func(a, b): return a[1] > b[1])
			elif dist < heap[0][1]:
				heap[0] = [node.index, dist]
				heap.sort_custom(func(a, b): return a[1] > b[1])
			
			# Determine near and far children
			var cd = depth % 2
			var diff = point[cd] - node.point[cd]
			var near = node.left if diff < 0 else node.right
			#var far = node.right if diff < 0 else node.left
			
			# Push far child check for later (phase 1)
			stack.append([node_idx, depth, 1])
			
			# Push near child for immediate exploration
			if near != -1:
				stack.append([near, depth + 1, 0])
		
		else:  # phase == 1
			# Check if we need to explore far child
			var cd = depth % 2
			var diff = point[cd] - node.point[cd]
			var far = node.right if diff < 0 else node.left
			
			if far != -1 and (heap.size() < k or diff * diff < heap[0][1]):
				stack.append([far, depth + 1, 0])
	
	# Sort heap by distance and extract indices
	heap.sort_custom(func(a, b): return a[1] < b[1])
	
	var result: PackedInt32Array = []
	for elem in heap:
		result.append(elem[0])
	return result

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



