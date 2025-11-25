extends CharacterBody2D

@export var speed: float = 200.0
@export var sit_time: float = 3.0
@onready var animator: AnimationPlayer = $AnimationPlayer

@export var MAX_FALL_SPEED: float = 500.0

var gravity: float = 15 * World.ppu
var propulsor_velocity: float = 4 * World.ppu
var isPropulsing: bool = false

var moveInput: Vector2 = Vector2.ZERO
var moveInputX: float:
	get:
		return moveInput.x

var WALK: StringName = "Walk"
var IDLE: StringName = "Idle"

var sit_timer: Timer
var isSit: bool = false

func _ready() -> void:
	sit_timer = Timer.new()
	add_child(sit_timer)
	sit_timer.one_shot = true
	sit_timer.wait_time = sit_time
	sit_timer.timeout.connect(sit)
	sit_timer.start()

	set_propulsor_visibility(false)

func sit() -> void:
	animator.play("SitStart")
	animator.queue("SitIdle")
	isSit = true
func get_up() -> void:
	if isSit:
		animator.play("SitEnd")
		animator.animation_finished.connect(
		func(_anim_name) -> void:
			isSit = false
			sit_timer.start()
		)

func _physics_process(_delta: float) -> void:
	moveInput.x = Input.get_axis("Left", "Right")

	# Handle sitting
	if isSit: 
		if moveInputX != 0: # Finish sitting
			get_up()
		return
	if moveInput.x != 0 or not is_on_floor(): # Each movement restarts the sitting timer
		sit_timer.start()

	# Handle movement
	if is_on_floor() or isPropulsing:
		velocity.x = moveInput.x * speed

	# Jump
	if Input.is_action_pressed("Jump"):
		velocity.y = -propulsor_velocity
		isPropulsing = true
		set_propulsor_visibility(true)
	else:
		# Stop upward movement when jump is released
		isPropulsing = false
		set_propulsor_visibility(false)
	
	# Gravity
	if not isPropulsing and not is_on_floor():
		velocity.y = max(0, velocity.y + gravity * _delta)
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

	_animation_process(_delta)

	# Move the character using CharacterBody2D helper
	move_and_slide()

func set_propulsor_visibility(v: bool) -> void:
	$Propulsors.visible = v



func _animation_process(_delta: float) -> void:
	if isPropulsing:
		if animator.current_animation != "Fly":
			animator.play("Fly")
			set_propulsor_visibility(true)
		if velocity.x != 0:
			look_to(velocity.x)
		return

	if velocity.x != 0:
		if animator.current_animation != WALK:
			animator.play(WALK)
		look_to(velocity.x)
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
