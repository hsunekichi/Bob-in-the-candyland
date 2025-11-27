class_name MazeGenerator
extends Node2D


signal maze_changed

# Maze configuration
@export var procedural_generation: bool = true

@export_group("Scenes and initialization")
@export var donut_scene: PackedScene
@export var enemy_scene: PackedScene
@export var enemy_count: int = 3

@export var maze_width: int = 10
@export var maze_height: int = 5
@export var max_jump_height: int = 1  # Maximum vertical distance player can jump
@export var nDonuts: int = 5

# TileMap configuration
@export var tile_source_id: int = 0  # Source ID in the TileSet
@export var tile_top_left: Vector2i = Vector2i(0, 0)
@export var tile_top: Vector2i = Vector2i(1, 0)
@export var tile_top_right: Vector2i = Vector2i(2, 0)
@export var tile_left: Vector2i = Vector2i(0, 1)
@export var tile_fill: Vector2i = Vector2i(1, 1)
@export var tile_right: Vector2i = Vector2i(2, 1)
@export var tile_bottom_left: Vector2i = Vector2i(0, 2)
@export var tile_bottom: Vector2i = Vector2i(1, 2)
@export var tile_bottom_right: Vector2i = Vector2i(2, 2)
@export var tile_single_floor: Vector2i = Vector2i(3, 0)
@export var tile_single_wall: Vector2i = Vector2i(3, 1)
@export var tile_single_ceiling: Vector2i = Vector2i(3, 2)
@export var tile_single_left_wall: Vector2i = Vector2i(0, 3)
@export var tile_single_horizontal_wall: Vector2i = Vector2i(1, 3)
@export var tile_single_right_wall: Vector2i = Vector2i(2, 3)
@export var tile_single_cell: Vector2i = Vector2i(3, 3)

@export var goal_scene: PackedScene

var enemies: Array = []

# Constants
const WALL = false
const PASSAGE = true

# Maze representation: false = wall, true = passage
var maze: Array = []

# Offset for non-procedural maps (tilemap coordinates to maze array coordinates)
var maze_offset: Vector2i = Vector2i(0, 0)

@onready var tilemap: TileMapLayer = $TileMapLayer

# Coordinate conversion helpers
func cell_to_world(cell: Vector2i) -> Vector2:
	"""Convert maze cell coordinates to world position."""
	# Apply offset to convert maze array coordinates to tilemap coordinates
	var tilemap_cell = cell + maze_offset
	var local_pos = tilemap.map_to_local(tilemap_cell)
	var world_pos = tilemap.to_global(local_pos)
	return world_pos

func world_to_cell(world_pos: Vector2) -> Vector2i:
	"""Convert world position to maze cell coordinates."""
	var local_pos = tilemap.to_local(world_pos)
	var tilemap_cell = tilemap.local_to_map(local_pos)
	# Apply offset to convert tilemap coordinates to maze array coordinates
	return tilemap_cell - maze_offset

func raycast_cells(origin: Vector2, destination: Vector2) -> Vector2i:
	"""
	Performs ray marching from origin to destination in world coordinates.
	Returns the coordinates of the first filled (wall) cell encountered, or Vector2i(-1, -1) if no wall is hit.
	Uses DDA (Digital Differential Analyzer) algorithm for grid traversal.
	"""
	var start_cell = world_to_cell(origin)
	var end_cell = world_to_cell(destination)
	
	# Direction vector
	var dx = end_cell.x - start_cell.x
	var dy = end_cell.y - start_cell.y
	
	# Number of steps (use the larger dimension)
	var steps = maxi(absi(dx), absi(dy))
	
	if steps == 0:
		# Origin and destination are in the same cell
		if is_cell_wall(start_cell):
			return start_cell + maze_offset  # Convert back to tilemap coordinates
		return Vector2i(-1, -1)
	
	# Step increments
	var x_inc = float(dx) / float(steps)
	var y_inc = float(dy) / float(steps)
	
	# Current position (use floats for precision)
	var x = float(start_cell.x)
	var y = float(start_cell.y)
	
	# March through cells
	for i in range(steps + 1):
		var current_cell = Vector2i(roundi(x), roundi(y))
		
		# Check if this cell is a wall
		if is_cell_wall(current_cell):
			return current_cell + maze_offset  # Convert back to tilemap coordinates
		
		# Move to next position
		x += x_inc
		y += y_inc
	
	return Vector2i(-1, -1)

func is_cell_wall(cell: Vector2i) -> bool:
	"""Check if a cell is a wall (filled). Returns true for walls, false for passages or out of bounds."""
	# Out of bounds is considered not a wall (passage/empty space)
	if cell.x < 0 or cell.x >= maze_width or cell.y < 0 or cell.y >= maze_height:
		return false
	
	return maze[cell.x][cell.y] == WALL

func remove_cell(tilemap_cell: Vector2i) -> bool:
	"""
	Removes a cell (converts it to a passage) from both the internal maze matrix and the tilemap.
	Takes tilemap coordinates as input.
	Returns true if the cell was successfully removed, false if the cell is out of bounds.
	"""
	# Convert tilemap coordinates to maze array coordinates
	var maze_cell = tilemap_cell - maze_offset
	
	# Check bounds
	if maze_cell.x < 0 or maze_cell.x >= maze_width or maze_cell.y < 0 or maze_cell.y >= maze_height:
		return false
	
	# Update internal maze matrix
	maze[maze_cell.x][maze_cell.y] = PASSAGE
	
	# Remove tile from tilemap (using tilemap coordinates)
	tilemap.erase_cell(tilemap_cell)
	
	# Update neighboring tiles to reflect the change
	# Check all 8 neighbors and update their tiles if they are walls
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var neighbor_tilemap = Vector2i(tilemap_cell.x + dx, tilemap_cell.y + dy)
			var neighbor_maze = neighbor_tilemap - maze_offset
			
			# Skip if neighbor is out of bounds (including border walls)
			if neighbor_maze.x < -1 or neighbor_maze.x > maze_width or neighbor_maze.y < -1 or neighbor_maze.y > maze_height:
				continue
			
			# Update the neighbor's tile if it's a wall
			if is_wall(neighbor_maze.x, neighbor_maze.y):
				var tile = get_tile_for_position(neighbor_maze.x, neighbor_maze.y)
				tilemap.set_cell(neighbor_tilemap, tile_source_id, tile)

	maze_changed.emit()
	
	return true

func _ready():
	nDonuts = World.config_value("maze_donuts", 3)

	if procedural_generation:
		generate_maze()
		build_tilemap()
		teleport_player_to_start()
		spawn_goal()
		spawn_donuts()
		spawn_enemies()
	else:
		load_maze_from_tilemap()

func spawn_donuts() -> void:
	if donut_scene == null:
		return
	
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	# Collect all free cells (passages)
	var free_cells: Array[Vector2i] = []
	for x in range(maze_width):
		for y in range(maze_height):
			if maze[x][y] == PASSAGE:
				var cell = Vector2i(x, y)
				# Exclude start and end positions
				if not (x == 0 and y == maze_height - 1) and not (x == maze_width - 1 and y == 0):
					free_cells.append(cell)
	
	# Shuffle and pick random cells
	free_cells.shuffle()
	var spawn_count = mini(nDonuts, free_cells.size())
	
	# Spawn donuts at random free cells
	for i in range(spawn_count):
		var cell = free_cells[i]
		var world_pos = cell_to_world(cell)
		
		var donut: Node2D = donut_scene.instantiate()
		donut.global_position = world_pos
		get_parent().add_child.bind(donut).call_deferred()

func spawn_enemies() -> void:
	if enemy_scene == null:
		return

	for e in enemies:
		e.queue_free()
	enemies.clear()

	var random = RandomNumberGenerator.new()
	random.randomize()
	
	var player_start_cell = Vector2i(0, maze_height - 1)
	var min_distance = 6  # Minimum distance from player in cells
	
	# Collect all free cells (passages) that are far enough from player
	var free_cells: Array[Vector2i] = []
	for x in range(maze_width):
		for y in range(maze_height):
			if maze[x][y] == PASSAGE:
				var cell = Vector2i(x, y)
				# Exclude start and end positions
				if not (x == 0 and y == maze_height - 1) and not (x == maze_width - 1 and y == 0):
					# Check distance from player start
					var distance = abs(cell.x - player_start_cell.x) + abs(cell.y - player_start_cell.y)
					if distance >= min_distance:
						free_cells.append(cell)
	
	# Shuffle and pick random cells
	free_cells.shuffle()
	var spawn_count = mini(enemy_count, free_cells.size())
	
	# Spawn enemies at random free cells
	for i in range(spawn_count):
		var cell = free_cells[i]
		var world_pos = cell_to_world(cell)
		
		var enemy: Node2D = enemy_scene.instantiate()
		enemy.global_position = world_pos
		get_parent().add_child.bind(enemy).call_deferred()
		enemies.append(enemy)


func load_maze_from_tilemap():
	"""Load maze structure from pre-built tilemap and populate internal maze array."""
	# Get the bounds of the existing tilemap
	var used_cells = tilemap.get_used_cells()
	
	if used_cells.is_empty():
		print("Warning: No tiles found in tilemap, falling back to procedural generation")
		generate_maze()
		build_tilemap()
		return
	
	# Calculate maze bounds from used cells
	# Initialize with first cell to avoid overflow issues
	var min_x: int = used_cells[0].x
	var max_x: int = used_cells[0].x
	var min_y: int = used_cells[0].y
	var max_y: int = used_cells[0].y
	
	for cell in used_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	
	# Adjust for border walls (-1 to width, -1 to height)
	maze_width = int(max_x - min_x)  # Excludes borders
	maze_height = int(max_y - min_y)  # Excludes borders
	
	# Store offset: maze array index 0 corresponds to tilemap coordinate (min_x + 1)
	maze_offset = Vector2i(int(min_x) + 1, int(min_y) + 1)
	
	# Initialize maze array
	maze = []
	for x in range(maze_width):
		maze.append([])
		for y in range(maze_height):
			# Check if there's a tile at this position (offset by min bounds + 1 for border)
			var tile_coord = Vector2i(x + int(min_x) + 1, y + int(min_y) + 1)
			var has_tile = tilemap.get_cell_source_id(tile_coord) != -1
			
			# Tile present = WALL, no tile = PASSAGE
			maze[x].append(WALL if has_tile else PASSAGE)
	
	print("Loaded maze from tilemap successfully")
	maze_changed.emit()

func generate_maze():
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		attempts += 1
		_generate_maze_internal()
		
		if has_path_from_start_to_end():
			print("Valid maze generated on attempt %d" % attempts)
			return
		else:
			print("No path found, regenerating maze (attempt %d)" % attempts)
	
	print("Warning: Could not generate valid maze after %d attempts" % max_attempts)
	maze_changed.emit()

func _generate_maze_internal():
	# Initialize maze with all walls
	maze = []
	for x in range(maze_width):
		maze.append([])
		for y in range(maze_height):
			maze[x].append(WALL)
	
	# Prim's algorithm for maze generation
	var frontiers: Array = []
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	var x = random.randi_range(0, maze_width - 1)
	var y = random.randi_range(0, maze_height - 1)
	frontiers.append([x, y, x, y])
	
	while not frontiers.is_empty():
		var f = frontiers[random.randi_range(0, frontiers.size() - 1)]
		frontiers.erase(f)
		
		x = f[2]
		y = f[3]
		
		if maze[x][y] == WALL:
			maze[f[0]][f[1]] = PASSAGE
			maze[x][y] = PASSAGE
			
			if x >= 2 and maze[x-2][y] == WALL:
				frontiers.append([x-1, y, x-2, y])
			if y >= 2 and maze[x][y-2] == WALL:
				frontiers.append([x, y-1, x, y-2])
			if x < maze_width - 2 and maze[x+2][y] == WALL:
				frontiers.append([x+1, y, x+2, y])
			if y < maze_height - 2 and maze[x][y+2] == WALL:
				frontiers.append([x, y+1, x, y+2])
	
	# Open bottom-left corner as entry (x=0, y=maze_height-1)
	maze[0][maze_height - 1] = PASSAGE
	
	# Open top-right corner as exit (x=maze_width-1, y=0)
	maze[maze_width - 1][0] = PASSAGE

func has_path_from_start_to_end() -> bool:
	# BFS to check if there's a path from (0, maze_height-1) to (maze_width-1, 0)
	var start = Vector2i(0, maze_height - 1)
	var end = Vector2i(maze_width - 1, 0)
	
	var queue: Array = [start]
	var visited: Dictionary = {start: true}
	
	var directions = [
		Vector2i(1, 0),   # right
		Vector2i(-1, 0),  # left
		Vector2i(0, 1),   # down
		Vector2i(0, -1)   # up
	]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current == end:
			return true
		
		for dir in directions:
			var next = current + dir
			
			# Check bounds
			if next.x < 0 or next.x >= maze_width or next.y < 0 or next.y >= maze_height:
				continue
			
			# Check if already visited
			if visited.has(next):
				continue
			
			# Check if it's a passage
			if maze[next.x][next.y] == PASSAGE:
				visited[next] = true
				queue.append(next)
	
	return false

func build_tilemap():
	# Clear existing tiles
	tilemap.clear()
	
	# Build top border wall
	for x in range(-1, maze_width + 1):
		var coords := Vector2i(x, -1)
		var tile = get_tile_for_position(x, -1)
		tilemap.set_cell(coords, tile_source_id, tile)
	
	# Build bottom border wall
	for x in range(-1, maze_width + 1):
		var coords := Vector2i(x, maze_height)
		var tile = get_tile_for_position(x, maze_height)
		tilemap.set_cell(coords, tile_source_id, tile)
	
	# Build tilemap from boolean maze matrix
	for x in range(maze_width):
		for y in range(maze_height):
			var coords := Vector2i(x, y)
			
			if maze[x][y] == WALL:  # false = wall, place tile based on neighbors
				var tile = get_tile_for_position(x, y)
				tilemap.set_cell(coords, tile_source_id, tile)
			else:  # true = passage, leave empty (no tile)
				tilemap.erase_cell(coords)
	
	# Build left border wall (except bottom-left entry)
	for y in range(maze_height):
		if y == maze_height - 1:  # Skip bottom-left entry
			continue
		var coords := Vector2i(-1, y)
		var tile = get_tile_for_position(-1, y)
		tilemap.set_cell(coords, tile_source_id, tile)
	
	# Build right border wall (except top-right exit)
	for y in range(maze_height):
		if y == 0:  # Skip top-right exit
			continue
		var coords := Vector2i(maze_width, y)
		var tile = get_tile_for_position(maze_width, y)
		tilemap.set_cell(coords, tile_source_id, tile)

func get_tile_for_position(x: int, y: int) -> Vector2i:
	# Check 8 neighbors to determine which tile to use
	# Neighbors: top-left, top, top-right, left, right, bottom-left, bottom, bottom-right
	
	var has_top = is_wall(x, y - 1)
	var has_bottom = is_wall(x, y + 1)
	var has_left = is_wall(x - 1, y)
	var has_right = is_wall(x + 1, y)
	var _has_top_left = is_wall(x - 1, y - 1)
	var _has_top_right = is_wall(x + 1, y - 1)
	var _has_bottom_left = is_wall(x - 1, y + 1)
	var _has_bottom_right = is_wall(x + 1, y + 1)
	
	# Single column detection (no walls to left or right)
	var is_single_column = not has_left and not has_right
	
	if is_single_column:
		# Single column ceiling: no wall below, walls above
		if not has_bottom and has_top:
			return tile_single_ceiling
		# Single column floor: no wall above, walls below
		if not has_top and has_bottom:
			return tile_single_floor
		# Single column middle wall: walls both above and below
		if has_top and has_bottom:
			return tile_single_wall
		# Single isolated tile: no walls above or below (rare case)
		if not has_top and not has_bottom:
			return tile_single_cell  # Completely isolated single cell
	
	# Single-height floor detection (no walls above or below)
	var is_single_height = not has_top and not has_bottom
	
	if is_single_height:
		# Single height right wall: wall to the left, open to the right
		if has_left and not has_right:
			return tile_single_right_wall
		# Single height left wall: wall to the right, open to the left
		if has_right and not has_left:
			return tile_single_left_wall
		# Single height horizontal wall: walls both left and right
		if has_left and has_right:
			return tile_single_horizontal_wall
		# Single isolated cell: no walls in any direction
		if not has_left and not has_right:
			return tile_single_cell
	
	# Corner detection (no adjacent walls on two perpendicular sides)
	# Top-left corner: no wall above and no wall to the left
	if not has_top and not has_left:
		return tile_top_left
	
	# Top-right corner: no wall above and no wall to the right
	if not has_top and not has_right:
		return tile_top_right
	
	# Bottom-left corner: no wall below and no wall to the left
	if not has_bottom and not has_left:
		return tile_bottom_left
	
	# Bottom-right corner: no wall below and no wall to the right
	if not has_bottom and not has_right:
		return tile_bottom_right
	
	# Edge detection (one side open)
	# Top edge (ceiling): no wall above
	if not has_top:
		return tile_top
	
	# Bottom edge (floor): no wall below
	if not has_bottom:
		return tile_bottom
	
	# Left edge: no wall to the left
	if not has_left:
		return tile_left
	
	# Right edge: no wall to the right
	if not has_right:
		return tile_right
	
	# Fill (surrounded by walls on all cardinal directions)
	return tile_fill

func is_wall(x: int, y: int) -> bool:
	# Check if position is out of bounds (treat as empty)
	if x < -1 or x > maze_width or y < -1 or y > maze_height:
		return false
	
	# Border walls
	if x == -1 or x == maze_width or y == -1 or y == maze_height:
		# Check for entry/exit openings
		if x == -1 and y == maze_height - 1:  # Bottom-left entry
			return false
		if x == maze_width and y == 0:  # Top-right exit
			return false
		return true
	
	# Inside maze
	return maze[x][y] == WALL

func teleport_player_to_start():
	# Start cell is at (0, maze_height - 1) in maze coordinates
	var start_cell = Vector2i(0, maze_height - 1)
	
	# Convert maze coordinates to world position
	var global_pos = cell_to_world(start_cell)
	
	# Teleport the player
	World.teleport_player(global_pos)

func get_start_position() -> Vector2:
	var start_cell = Vector2i(0, maze_height - 1)
	return cell_to_world(start_cell)
	
func spawn_goal() -> void:
	if goal_scene == null:
		return

	# Goal is at upper right corner
	var exit_cell := Vector2i(maze_width - 1, 0)
	var world_pos := cell_to_world(exit_cell)
	
	var cell_size: Vector2 = tilemap.tile_set.tile_size
	world_pos.x += cell_size.x*5

	# Goal scene
	var goal: Node2D = goal_scene.instantiate()
	add_child(goal)
	goal.global_position = world_pos
