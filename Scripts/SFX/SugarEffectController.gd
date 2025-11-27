extends ColorRect

@export var alpha: float = 0.31  # Target alpha value
@export var fade_duration: float = 0.3  # Duration of the fade-in effect in seconds
@export var total_duration: float = 2.0  # Total duration the effect stays enabled

var isRunning: bool = false
var timer: Timer = null

func _ready() -> void:
    visible = false

    timer = Timer.new()
    timer.one_shot = true
    timer.wait_time = total_duration
    timer.timeout.connect(disable)
    add_child(timer)

func set_duration(duration: float) -> void:
    total_duration = duration
    timer.wait_time = total_duration

func enable() -> void:
    if isRunning:
        timer.start()
        return

    var mat = material as ShaderMaterial

    visible = true

    # Remove current alpha
    mat.set_shader_parameter("alpha", 0.0)

    # Fade in from 0 to sugar_rush_alpha
    var tween = create_tween()
    tween.tween_property(mat, "shader_parameter/alpha", alpha, fade_duration)

    isRunning = true

    # Start timer to disable effect after total_duration
    timer.start()

func disable() -> void:
    var mat = material as ShaderMaterial

    # Fade out from current alpha to 0
    var tween = create_tween()
    tween.tween_property(mat, "shader_parameter/alpha", 0.0, fade_duration)  
    tween.finished.connect(func(): visible = false, CONNECT_ONE_SHOT)

    isRunning = false