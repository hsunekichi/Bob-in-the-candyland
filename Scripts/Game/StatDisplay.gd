extends Control

func red_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Red flash
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	# Scale up
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	# Rotation twitch
	tween.tween_property(self, "rotation", -0.15, 0.05).set_trans(Tween.TRANS_BOUNCE)
	
	tween.chain()
	# Twitch back
	tween.tween_property(self, "rotation", 0.1, 0.05)
	
	tween.chain()
	tween.set_parallel(true)
	# Return to normal
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", 0.0, 0.1)