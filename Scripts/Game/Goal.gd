extends Area2D

var is_locked: bool = true

func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false
	print("Goal unlocked!")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	if is_locked:
		print("Goal is locked. Donuts left:", World.donuts_left)
		return

	World.game_completed()
