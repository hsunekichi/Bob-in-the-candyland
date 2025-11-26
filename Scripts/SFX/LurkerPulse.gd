class_name RainbowPulse
extends Node2D

@export var _duration: float = 0.5
@export var _max_scale: float = 3.0
@export var _fade_time: float = 0.15

var size_tween: Tween
var fade_tween: Tween

@onready var pulseBuffer: SpriteBackBufferCopy = $PulseBuffer
@onready var blurBuffer: SpriteBackBufferCopy = $BlurBuffer
@onready var pulse: Sprite2D = $PulseBuffer/PulseSprite

var fade_timer: Timer

func _ready() -> void:
	#visible = false
	assert(_fade_time < _duration, "EnergyPulseEffect: _fade_time must be less than _duration")
	physics_interpolation_mode = PhysicsInterpolationMode.PHYSICS_INTERPOLATION_MODE_OFF

	if _fade_time > 0:
		fade_timer = Timer.new()
		fade_timer.one_shot = true
		fade_timer.wait_time = _duration - _fade_time
		fade_timer.timeout.connect(_start_fade)
		add_child(fade_timer)

	pulseBuffer.disable()
	blurBuffer.disable()

	# Start shader parameters
	var inner = pulse.material.get_shader_parameter("inner_radius")
	var inner_fade = pulse.material.get_shader_parameter("inner_fade_radius")
	$BlurBuffer/Blur.material.set_shader_parameter("inner_radius", inner)
	$BlurBuffer/Blur.material.set_shader_parameter("inner_fade_radius", inner_fade)
	

func set_parameters(max_scale: float, duration: float, fade_time: float) -> void:
	_duration = duration
	_fade_time = fade_time
	fade_timer.wait_time = _duration - _fade_time
	_max_scale = max_scale

func start_pulse(location: Vector2) -> void:
	# cancel any existing pulse tween
	if size_tween:
		size_tween.kill()
	if fade_tween:
		fade_tween.kill()

	pulseBuffer.enable()
	blurBuffer.enable()

	global_position = location

	# Start from zero scale and make visible
	scale = Vector2.ZERO
	modulate.a = 1.0
	visible = true

	# Scale tween
	size_tween = create_tween()
	size_tween.tween_property(self, "scale", Vector2.ONE * _max_scale, _duration)
	
	# start fade in the last `_fade_time` seconds
	if _fade_time > 0:
		fade_timer.start()
		

func _start_fade() -> void:
	if _fade_time > 0:
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, _fade_time)
		fade_tween.tween_callback(end_pulse)

func end_pulse() -> void:
	visible = false
	pulseBuffer.disable()
	blurBuffer.disable()
		
