class_name RTTstarDisplay
extends Node2D

## Array of global positions to display markers at
@export var positions: Array[Vector2] = []

## Marker appearance settings
@export_group("Marker Appearance")
@export var marker_color: Color = Color.RED
@export var marker_radius: float = 8.0
@export var marker_outline_color: Color = Color.WHITE
@export var marker_outline_width: float = 2.0
@export var show_numbers: bool = true
@export var number_color: Color = Color.WHITE

## Arrow/connection settings
@export_group("Connections")
@export var show_connections: bool = true
@export var connection_color: Color = Color.WHITE
@export var connection_width: float = 2.0

# Internal array to store marker nodes
var _marker_nodes: Array[Node2D] = []
var _current_objective_index: int = -1


func _ready() -> void:
	# Create initial markers if positions are set
	if positions.size() > 0:
		create_markers()


## Set new positions and update markers
func set_positions(new_positions: Array[Vector2]) -> void:
	positions = new_positions
	create_markers()


## Add a single position to the array
func add_position(pos: Vector2) -> void:
	positions.append(pos)
	_create_single_marker(pos, positions.size() - 1)


## Clear all markers
func clear_markers() -> void:
	for marker in _marker_nodes:
		marker.queue_free()
	_marker_nodes.clear()
	positions.clear()
	queue_redraw()


## Create all markers from the positions array
func create_markers() -> void:
	# Clear existing markers first
	for marker in _marker_nodes:
		marker.queue_free()
	_marker_nodes.clear()
	
	# Create new markers
	for i in range(positions.size()):
		_create_single_marker(positions[i], i)
	
	# Reapply current objective highlighting
	if _current_objective_index >= 0 and _current_objective_index < _marker_nodes.size():
		var marker = _marker_nodes[_current_objective_index]
		if marker.has_method("set"):
			marker.set("color", Color.GREEN)
	
	# Redraw connections
	queue_redraw()


## Create a single marker at the given position
func _create_single_marker(pos: Vector2, index: int) -> void:
	var marker = PathDisplayMarker.new()
	marker.global_position = pos
	add_child(marker)
	_marker_nodes.append(marker)
	
	# If custom texture is provided, use it
	# Use custom drawing
	marker.color = marker_color
	marker.radius = marker_radius
	marker.outline_color = marker_outline_color
	marker.outline_width = marker_outline_width

	# Add number label if enabled
	if show_numbers:
		var label = Label.new()
		label.text = str(index)
		label.add_theme_color_override("font_color", number_color)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-10, -10)
		label.size = Vector2(20, 20)
		marker.add_child(label)


## Update marker at specific index
func update_marker_position(index: int, new_pos: Vector2) -> void:
	if index >= 0 and index < positions.size():
		positions[index] = new_pos
		if index < _marker_nodes.size():
			_marker_nodes[index].global_position = new_pos
		queue_redraw()


## Remove marker at specific index
func remove_marker(index: int) -> void:
	if index >= 0 and index < positions.size():
		positions.remove_at(index)
		if index < _marker_nodes.size():
			_marker_nodes[index].queue_free()
			_marker_nodes.remove_at(index)
			# Update numbers for remaining markers
			create_markers()


## Set the current objective marker (will be displayed in green)
func set_current_objective(index: int) -> void:
	if index >= 0 and index < _marker_nodes.size():
		# Reset previous objective color if it exists
		if _current_objective_index >= 0 and _current_objective_index < _marker_nodes.size():
			var prev_marker = _marker_nodes[_current_objective_index]
			if prev_marker.has_method("set"):
				prev_marker.set("color", marker_color)
		
		# Set new objective
		_current_objective_index = index
		var marker = _marker_nodes[index]
		if marker.has_method("set"):
			marker.set("color", Color.GREEN)


## Draw connections between consecutive positions
func _draw() -> void:
	if not show_connections or positions.size() < 2:
		return
	
	# Draw straight lines between consecutive positions
	for i in range(positions.size() - 1):
		var from_pos = to_local(positions[i])
		var to_pos = to_local(positions[i + 1])
		
		# Draw line
		draw_line(from_pos, to_pos, connection_color, connection_width, true)
