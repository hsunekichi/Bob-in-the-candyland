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

######### Dash Parameters #########
@export var dash_speed: float = 800.0
@export var dash_cooldown: float = 0.5
var MAX_DASHED_DISTANCE: float = 2.0 * World.ppu
var dash_direction: Vector2 = Vector2.ZERO
var dashedDistance: float = 0.0
var insideWall: bool = false
var dash_detector: Area2D
var dashTimer: Timer

######### Sitting Parameters #########
@export var sit_time: float = 3.0
var sit_timer: Timer

######### State Flags #########
var isPropulsing: bool = false

######### Input #########
var moveInput: Vector2 = Vector2.ZERO

######### Components #########
@onready var animator: AnimationPlayer = $AnimationPlayer

######### Initialization #########
func _ready() -> void:
	# Sitting timer
	sit_timer = Timer.new()
	sit_timer.one_shot = true
	sit_timer.wait_time = sit_time
	sit_timer.timeout.connect(_enter_sitting_state)
	add_child(sit_timer)
	sit_timer.start()
	
	# Dash cooldown timer
	dashTimer = Timer.new()
	dashTimer.one_shot = true
	dashTimer.wait_time = dash_cooldown
	add_child(dashTimer)

	# Dash collision detector
	dash_detector = Area2D.new()
	dash_detector.collision_layer = 0
	dash_detector.collision_mask = 1  # Detect ground layer
	dash_detector.monitoring = false
	
	for child in get_children():
		if child is CollisionShape2D:
			var shape_copy = CollisionShape2D.new()
			shape_copy.shape = child.shape
			shape_copy.position = child.position
			dash_detector.add_child(shape_copy)
			break
	
	add_child(dash_detector)
	visible = false

	disable_propulsion()

func disable_input() -> void:
	animator.play("Idle")
	set_process(false)
	set_physics_process(false)
func enable_input() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)


######### Main Physics Loop #########
func _physics_process(delta: float) -> void:
	moveInput.x = Input.get_axis("Left", "Right")
	
	match current_state:
		State.SITTING:
			_process_sitting_state()
		State.DASHING:
			_process_dashing_state(delta)
		State.NORMAL:
			_process_normal_state(delta)

######### State: SITTING #########
func _enter_sitting_state() -> void:
	current_state = State.SITTING
	animator.play("SitStart")
	animator.queue("SitIdle")

func _process_sitting_state() -> void:
	if moveInput.x != 0:
		animator.play("SitEnd")
		animator.animation_finished.connect(
			func(_anim_name) -> void:
				current_state = State.NORMAL
				sit_timer.start()
		, CONNECT_ONE_SHOT)

	move_and_slide()

######### State: DASHING #########
func _process_dashing_state(delta: float) -> void:
	global_position += dash_direction * dash_speed * delta
	dashedDistance += dash_speed * delta
	
	var wasInsideWall = insideWall
	insideWall = dash_detector.has_overlapping_bodies()
	
	# Exit dash when out of wall or max distance reached
	if (wasInsideWall or dashedDistance >= MAX_DASHED_DISTANCE) and not insideWall:
		current_state = State.NORMAL
		dash_detector.monitoring = false
		dashTimer.start()

		if moveInput.x != 0:
			velocity = Vector2(moveInput.x * speed, 0)
		else:
			velocity = Vector2.ZERO

######### State: NORMAL #########
func _process_normal_state(delta: float) -> void:
	# Reset sitting timer on movement
	if moveInput.x != 0 and not isPropulsing:
		sit_timer.start()
	
	# Check for dash input
	if _try_start_dash():
		return
	
	_apply_propulsion(delta)
	_apply_gravity(delta)
	_apply_horizontal_movement(delta)
	_update_animations()

	move_and_slide()

func _try_start_dash() -> bool:
	if not Input.is_action_just_pressed("Dash"):
		return false
	if moveInput.x == 0 or not dashTimer.is_stopped():
		return false
	
	var dir = Vector2(sign(moveInput.x), 0)
	current_state = State.DASHING
	dash_direction = dir
	dash_detector.monitoring = true
	dashedDistance = 0.0
	sit_timer.stop()
	disable_propulsion()

	return true
	
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
