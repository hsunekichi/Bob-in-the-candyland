extends Area2D

func _on_body_entered(body: Node2D) -> void:
<<<<<<< HEAD
	if not body.is_in_group("Player"):
		return

	if is_locked:
		World.HUD.show_hungry_message(2.0)
		print("Goal is locked. Donuts left:", World.donuts_left)
		return

	World.game_completed()
=======
	if body.is_in_group("Player"):
		World.game_completed()
>>>>>>> parent of d1eb90c (AllDonuts)
