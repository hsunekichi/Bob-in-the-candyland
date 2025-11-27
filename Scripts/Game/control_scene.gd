extends Control

func _ready() -> void:
	$CloseButton.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
	queue_free() 
