extends Node2D

# Maze configuration
@export var maze_width: int = 10
@export var maze_height: int = 5
@export var max_jump_height: int = 1  # Maximum vertical distance player can jump

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

@export var goal_scene: PackedScene

# Constants
const WALL = false
const PASSAGE = true

# Maze representation: false = wall, true = passage
var maze: Array = []

@onready var tilemap: TileMapLayer = $TileMapLayer

func _ready():
	generate_maze()
	build_tilemap()

	teleport_player_to_start()
	spawn_goal()

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
			return tile_single_floor  # Default to floor for isolated case
	
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
	var local_pos = tilemap.map_to_local(start_cell)
	
	# Convert to global position
	var global_pos = tilemap.to_global(local_pos)
	
	# Teleport the player
	World.teleport_player(global_pos)
	
func spawn_goal() -> void:
	if goal_scene == null:
		return

	# Goal is at upper right corner
	var exit_cell := Vector2i(maze_width - 1, 0)
	var local_pos := tilemap.map_to_local(exit_cell)
	var world_pos := tilemap.to_global(local_pos)
	
	var cell_size: Vector2 = tilemap.tile_set.tile_size
	world_pos.x += cell_size.x*5

	# Goal scene
	var goal: Node2D = goal_scene.instantiate()
	add_child(goal)
	goal.global_position = world_pos
