class_name PathDisplayMarker
extends Node2D

## Marker drawing script for PathDisplay

var color: Color = Color.RED
var radius: float = 8.0
var outline_color: Color = Color.WHITE
var outline_width: float = 2.0


func _draw() -> void:
	# Draw outline circle
	if outline_width > 0:
		draw_circle(Vector2.ZERO, radius + outline_width, outline_color)
	
	# Draw main circle
	draw_circle(Vector2.ZERO, radius, color)


func _ready() -> void:
	queue_redraw()
