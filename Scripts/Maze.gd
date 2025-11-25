extends Node2D

# Maze configuration
@export var maze_width: int = 30
@export var maze_height: int = 10
@export var max_jump_height: int = 1  # Maximum vertical distance player can jump

# TileMap configuration
@export var tile_source_id: int = 0  # Source ID in the TileSet
@export var tile_atlas_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)
]  # Available tile coordinates to randomly choose from

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
		var random_tile = tile_atlas_coords[randi() % tile_atlas_coords.size()]
		tilemap.set_cell(coords, tile_source_id, random_tile)
	
	# Build bottom border wall
	for x in range(-1, maze_width + 1):
		var coords := Vector2i(x, maze_height)
		var random_tile = tile_atlas_coords[randi() % tile_atlas_coords.size()]
		tilemap.set_cell(coords, tile_source_id, random_tile)
	
	# Build tilemap from boolean maze matrix
	for x in range(maze_width):
		for y in range(maze_height):
			var coords := Vector2i(x, y)
			
			if maze[x][y] == WALL:  # false = wall, place a random tile
				var random_tile = tile_atlas_coords[randi() % tile_atlas_coords.size()]
				tilemap.set_cell(coords, tile_source_id, random_tile)
			else:  # true = passage, leave empty (no tile)
				tilemap.erase_cell(coords)
	
	# Build left border wall (except bottom-left entry)
	for y in range(maze_height):
		if y == maze_height - 1:  # Skip bottom-left entry
			continue
		var coords := Vector2i(-1, y)
		var random_tile = tile_atlas_coords[randi() % tile_atlas_coords.size()]
		tilemap.set_cell(coords, tile_source_id, random_tile)
	
	# Build right border wall (except top-right exit)
	for y in range(maze_height):
		if y == 0:  # Skip top-right exit
			continue
		var coords := Vector2i(maze_width, y)
		var random_tile = tile_atlas_coords[randi() % tile_atlas_coords.size()]
		tilemap.set_cell(coords, tile_source_id, random_tile)

func teleport_player_to_start():
	# Start cell is at (0, maze_height - 1) in maze coordinates
	var start_cell = Vector2i(0, maze_height - 1)
	
	# Convert maze coordinates to world position
	var local_pos = tilemap.map_to_local(start_cell)
	
	# Convert to global position
	var global_pos = tilemap.to_global(local_pos)
	
	# Teleport the player
	World.teleport_player(global_pos)
