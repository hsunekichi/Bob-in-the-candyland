extends Button

@export var texture_0: Texture2D
@export var texture_30: Texture2D
@export var texture_70: Texture2D
@export var texture_100: Texture2D
@export var animation_duration: float = 0.3  # Duration of the fill/empty animation

var is_filled: bool = false
var _animating: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	icon = texture_0

	is_filled = World.show_navigation
	icon = texture_100 if is_filled else texture_0

func _on_pressed() -> void:
	$"../AudioStreamPlayer2".play()
	if _animating:
		return  # Prevent multiple animations at once
	
	if is_filled:
		_animate_empty()
	else:
		_animate_fill()
	
	is_filled = !is_filled

	if is_filled:
		World.show_navigation = true
	else:
		World.show_navigation = false

func _animate_fill() -> void:
	_animating = true
	icon = texture_30
	await get_tree().create_timer(animation_duration * 0.33).timeout
	icon = texture_70
	await get_tree().create_timer(animation_duration * 0.33).timeout
	icon = texture_100
	await get_tree().create_timer(animation_duration * 0.34).timeout
	_animating = false

func _animate_empty() -> void:
	_animating = true
	icon = texture_70
	await get_tree().create_timer(animation_duration * 0.33).timeout
	icon = texture_30
	await get_tree().create_timer(animation_duration * 0.33).timeout
	icon = texture_0
	await get_tree().create_timer(animation_duration * 0.34).timeout
	_animating = false

func set_filled(filled: bool, animate: bool = false) -> void:
	if animate:
		if filled != is_filled:
			_on_pressed()
	else:
		is_filled = filled
		icon = texture_100 if filled else texture_0

func get_is_filled() -> bool:
	return is_filled
