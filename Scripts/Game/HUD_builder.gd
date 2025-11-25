@tool
extends CanvasLayer
class_name HUDBuilder

@export var duplicates_count: int = 20
@export var rotation_range_degrees: Vector2 = Vector2(-180, 180)
@export var scale_range: Vector2 = Vector2(2.0, 3.5)
@export var offset_range: Vector2 = Vector2(200, 200)

## Click this button to generate clones from the templates
@export var generate_clones: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			randomize_children()
		generate_clones = false

## Click this button to clear all generated clones
@export var clear_clones: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_clear_generated()
		clear_clones = false

var _templates: Array[Node] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func randomize_children(count: int = -1) -> void:
	_clear_generated()
	_capture_templates()

	var target := count
	if target < 0:
		target = max(duplicates_count, 0)
	if target == 0:
		return

	if _templates.is_empty():
		push_warning("HUDBuilder: no template children were available to duplicate.")
		return

	for generated in range(target):
		var template := _templates[_rng.randi_range(0, _templates.size() - 1)]
		var clone := template.duplicate(true)
		clone.set_meta("hud_builder_generated", true)
		clone.name = "%s_clone_%d" % [template.name == "" if not template else template.name, generated + 1]
		_apply_random_transform(clone)
		add_child(clone)
		if Engine.is_editor_hint():
			clone.owner = get_tree().edited_scene_root

func _capture_templates() -> void:
	_templates.clear()
	for child in $Templates.get_children():
		_templates.append(child)

func _clear_generated() -> void:
	for child in get_children().duplicate():
		if child.get_meta("hud_builder_generated", false):
			remove_child(child)
			child.queue_free()

func _apply_random_transform(clone: Node) -> void:
	var rotation_deg := _random_rotation()
	var scale_factor := _random_scale()
	var screen_position := _random_screen_position()

	if clone is Control:
		var control := clone as Control
		control.rotation = rotation_deg
		control.scale *= scale_factor
		control.position = screen_position
		return

	if clone is Node2D:
		var node2d := clone as Node2D
		node2d.rotation_degrees = rotation_deg
		node2d.scale *= scale_factor
		node2d.position = screen_position
		return

	if clone is CanvasItem:
		var item := clone as CanvasItem
		item.rotation_degrees = rotation_deg
		item.scale *= scale_factor
		if item is Node2D:
			item.position = screen_position

func _random_rotation() -> float:
	var min_rotation = min(rotation_range_degrees.x, rotation_range_degrees.y)
	var max_rotation = max(rotation_range_degrees.x, rotation_range_degrees.y)
	return _rng.randf_range(min_rotation, max_rotation)

func _random_scale() -> float:
	var min_scale = min(scale_range.x, scale_range.y)
	var max_scale = max(scale_range.x, scale_range.y)
	if min_scale == max_scale:
		return min_scale
	return _rng.randf_range(min_scale, max_scale)

func _random_screen_position() -> Vector2:
	return Vector2(
		_rng.randf_range(0, 1920),
		_rng.randf_range(0, 1080)
	)
