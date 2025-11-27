extends CharacterBody2D

######### State Machine #########
enum State { NORMAL, SITTING, DASHING }
var current_state: State = State.NORMAL

######### Movement Parameters #########
@export var speed: float = 250.0
@export var air_speed: float = 175.0
@export var propulsor_speed: float = 256.0

@export var acceleration: float = 1000.0
@export var brake_acceleration: float = 2500.0

@export var air_acceleration: float = 750.0
@export var air_brake_acceleration: float = 1000.0

@export var propulsor_acceleration: float = 800.0

######### Physics Parameters #########
@export var MAX_FALL_SPEED: float = 500.0
var gravity: float = 15 * World.ppu

######### Sugar rush parameters #########
@export var sugar_rush_cooldown: float = 0.5
@export var sugar_rush_duration: float = 2.0
var sugarRushCooldownTimer: Timer
var sugarRushDurationTimer: Timer
var sugarPuffScene: PackedScene = preload("res://Scenes/GameAssets/SugarPuff.tscn")
var isRemovingCells: bool = false

######### Sitting Parameters #########
@export var sit_time: float = 5.0
var sit_timer: Timer

######### State Flags #########
var isPropulsing: bool = false
var health: int = 3
var sugar_level: int = 0

######### Input #########
var moveInput: Vector2 = Vector2.ZERO

######### Components #########
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var rayDestructor: RayCast2D = $RayDestructor
@onready var player_center: Node2D = $Center

######### Initialization #########
func _ready() -> void:
	# Sitting timer
	sit_timer = Timer.new()
	sit_timer.one_shot = true
	sit_timer.wait_time = sit_time
	sit_timer.timeout.connect(_enter_sitting_state)
	add_child(sit_timer)

	sugar_rush_duration = World.config_value("sugar_rush_duration", 2.0)
	sugar_rush_cooldown = World.config_value("sugar_rush_cooldown", 0.5)
	
	# Sugar rush cooldown timer
	sugarRushCooldownTimer = Timer.new()
	sugarRushCooldownTimer.one_shot = true
	sugarRushCooldownTimer.wait_time = sugar_rush_cooldown
	add_child(sugarRushCooldownTimer)

	# Sugar rush duration timer
	sugarRushDurationTimer = Timer.new()
	sugarRushDurationTimer.one_shot = true
	sugarRushDurationTimer.wait_time = sugar_rush_duration
	sugarRushDurationTimer.timeout.connect(end_sugar_rush)
	add_child(sugarRushDurationTimer)

	visible = false

	disable_propulsion()

	World.game_finished.connect(disable_input)
	sugar_level = World.config_value("starting_sugar", 0)
	health = World.config_value("starting_health", 3)
	World.sugar_level_changed(sugar_level)
	World.health_changed(health)

	

func initialize() -> void:
	health = World.config_value("starting_health", 3)
	sugar_level = World.config_value("starting_sugar", 0)
	World.health_changed(health)
	World.sugar_level_changed(sugar_level)
	
	disable_propulsion()
	current_state = State.SITTING
	animator.play("SitIdle")
	velocity = Vector2.ZERO


	enable_input()

## Returns the center of the player
func target_point() -> Vector2:
	return player_center.global_position

func disable_input() -> void:
	animator.play("Idle")
	set_process(false)
	set_physics_process(false)
func enable_input() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)

func increase_sugar(amount: int = 1) -> void:
	sugar_level += amount
	World.sugar_level_changed(sugar_level)
	World.activate_sugar_eat_effect()


######### Main Physics Loop #########
func _physics_process(delta: float) -> void:
	moveInput.x = Input.get_axis("Left", "Right")
	
	match current_state:
		State.SITTING:
			_process_sitting_state(delta)
		State.NORMAL:
			_process_normal_state(delta)

######### State: SITTING #########
func _enter_sitting_state() -> void:
	current_state = State.SITTING
	animator.play("SitStart")
	animator.queue("SitIdle")

func _process_sitting_state(delta: float) -> void:
	if moveInput.x != 0 or Input.is_action_just_pressed("Jump"):
		animator.play("SitEnd")
		animator.animation_finished.connect(
			func(_anim_name) -> void:
				current_state = State.NORMAL
				sit_timer.start()
		, CONNECT_ONE_SHOT)

	# Add gravity
	_apply_gravity(delta)

	move_and_slide()


######### State: NORMAL #########
func _process_normal_state(delta: float) -> void:
	# Reset sitting timer on movement
	if moveInput.x != 0 and is_on_floor():
		sit_timer.start()
	
	# Start sugar rush
	if Input.is_action_just_pressed("Dash") \
	   and sugarRushCooldownTimer.is_stopped() \
	   and sugarRushDurationTimer.is_stopped() \
	   and sugar_level > 0:
		start_sugar_rush()
	
	_handle_sugar_rush()
	_apply_propulsion(delta)
	_apply_gravity(delta)
	_apply_horizontal_movement(delta)
	_update_animations()

	move_and_slide()

func _handle_sugar_rush() -> void:
	var _maze = World.get_maze()
	if _maze == null or sugarRushDurationTimer.is_stopped() or isRemovingCells:
		return

	var maze := _maze as MazeGenerator

	var origin = rayDestructor.global_position
	var target = rayDestructor.to_global(rayDestructor.target_position)

	var col: Vector2i = maze.raycast_cells(origin, target)

	if col[0] != -1:
		# raycast_cells returns tilemap coordinates, convert directly to world
		var cell_pos = maze.tilemap.map_to_local(col)
		cell_pos = maze.tilemap.to_global(cell_pos)
		var sugar_puff = sugarPuffScene.instantiate()
		isRemovingCells = true
		
		sugar_puff.global_position = cell_pos
		World.add_child(sugar_puff)

		sugar_puff.cloudAtMaxSize.connect(func(): 
			maze.remove_cell(col)
			isRemovingCells = false
		, CONNECT_ONE_SHOT)

		sugar_puff.animation_finished.connect(sugar_puff.queue_free, CONNECT_ONE_SHOT)

func on_hit() -> void:
	health -= 1
	World.health_changed(health)
	if health <= 0:
		World.game_over()
	else:
		if not World.get_maze():
			return
		var maze := World.get_maze() as MazeGenerator
		maze.spawn_enemies()

		current_state = State.SITTING
		animator.play("SitIdle")
		velocity = Vector2.ZERO
		global_position = maze.get_start_position()



func start_sugar_rush() -> void:
	sugar_level -= 1
	World.sugar_level_changed(sugar_level)

	sugarRushDurationTimer.start()
	World.activate_sugar_rush_effect()

func end_sugar_rush() -> void:
	sugarRushCooldownTimer.start()
	
func _apply_propulsion(delta: float) -> void:
	if Input.is_action_pressed("Jump"):
		if not isPropulsing:
			enable_propulsion()

		var target_velocity_y := -propulsor_speed
		var accel_y := propulsor_acceleration * delta
		
		velocity.y = move_toward(velocity.y, target_velocity_y, accel_y)
	else:
		disable_propulsion()

func _apply_gravity(delta: float) -> void:
	if not isPropulsing and not is_on_floor():
		velocity.y = max(0, velocity.y + gravity * delta)
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

func _apply_horizontal_movement(delta: float) -> void:
	var target_speed: float
	var accel: float
	
	if is_on_floor():
		target_speed = moveInput.x * speed
		accel = brake_acceleration if _should_brake() else acceleration
	else:
		target_speed = moveInput.x * air_speed
		accel = air_brake_acceleration if _should_brake() else air_acceleration
	
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

func _should_brake() -> bool:
	return moveInput.x == 0 or sign(moveInput.x) != sign(velocity.x)

######### Animation #########
func _update_animations() -> void:
	if not is_on_floor(): # Fly animations
		if animator.current_animation != "Fly":
			animator.play("Fly")
		if isPropulsing:
			enable_propulsion()
	elif velocity.x != 0:
		if animator.current_animation != "Walk":
			animator.play("Walk")
	else:
		if animator.current_animation != "Idle":
			animator.play("Idle")
	
	if velocity.x != 0:
		look_to(velocity.x)

func enable_propulsion() -> void:
	$Propulsors.visible = true
	isPropulsing = true
	sit_timer.stop()

func disable_propulsion() -> void:
	$Propulsors.visible = false
	isPropulsing = false

######### Direction Helpers #########
func looking_dir_x() -> float:
	return -scale.x if abs(global_rotation) > PI/2 else scale.x

func look_to(direction: float) -> void:
	if sign(direction) != looking_dir_x():
		scale.x = -scale.x
