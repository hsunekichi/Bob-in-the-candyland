extends CharacterBody2D

@export var speed: float = 200.0
@export var sit_time: float = 3.0
@onready var animator: AnimationPlayer = $AnimationPlayer

@export var MAX_JUMP_HEIGHT: float = 180.0
@export var TIME_TO_APEX: float = 0.45
@export var MAX_FALL_SPEED: float = 500.0

var gravity: float = 0.0
var jump_velocity: float = 0.0

var moveInput: Vector2 = Vector2.ZERO
var moveInputX: float:
	get:
		return moveInput.x

var WALK: StringName = "Walk"
var IDLE: StringName = "Idle"

var sit_timer: Timer
var isSit: bool = false

func _ready() -> void:
	# Compute gravity and jump velocity so the jump reaches MAX_JUMP_HEIGHT
	# using the kinematic formula: g = 2*h / t^2, v0 = g * t
	if TIME_TO_APEX <= 0.0:
		push_error("TIME_TO_APEX must be > 0. Using default 0.4s")
		TIME_TO_APEX = 0.4

	gravity = 2.0 * MAX_JUMP_HEIGHT / (TIME_TO_APEX * TIME_TO_APEX)
	jump_velocity = gravity * TIME_TO_APEX
	
	sit_timer = Timer.new()
	add_child(sit_timer)
	sit_timer.one_shot = true
	sit_timer.wait_time = sit_time
	sit_timer.timeout.connect(sit)

func sit() -> void:
	animator.play("SitStart")
	animator.queue("SitIdle")
	isSit = true

func _physics_process(_delta: float) -> void:
	moveInput.x = Input.get_axis("Left", "Right")

	# Handle sitting
	if isSit:
		velocity.x = 0
		if moveInputX != 0: # Finish sitting
			animator.play("SitEnd")
			animator.animation_finished.connect(
			func(_anim_name) -> void:
				isSit = false
			)
		return
	
	if moveInput.x != 0: # Each movement restarts the sitting timer
		sit_timer.start()

	# Handle movement
	velocity.x = moveInput.x * speed

	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = -jump_velocity
	elif not Input.is_action_pressed("Jump") and velocity.y < 0.0:
		# Variable jump height
		velocity.y = 0.0
	
	# Gravity
	velocity.y += gravity * _delta
	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED

	_animation_process(_delta)

	# Move the character using CharacterBody2D helper
	move_and_slide()


func _animation_process(_delta: float) -> void:
	if moveInputX != 0:
		if animator.current_animation != WALK:
			animator.play(WALK)
		look_to(moveInputX)
	else:
		if animator.current_animation != IDLE:
			animator.play(IDLE)


func looking_dir_x() -> float:
	if abs(global_rotation) > PI/2:
		return -scale.x
	else:
		return scale.x

func look_to(direction: float) -> void:
	if sign(direction) != looking_dir_x():
		scale.x = -scale.x
