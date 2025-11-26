class_name HUDcontroller
extends CanvasLayer



@onready var transition: Node = $Transition

func _ready() -> void:
	var tr_nodes = transition.get_children()
	for child in tr_nodes:
		child.visible = false
	transition.visible = true
	
func enable_transition():
	var tr_nodes = transition.get_children()

	# Hide all transition nodes initially
	for child in tr_nodes:
		child.visible = false
	
	# Shuffle the children for random order
	var shuffled = tr_nodes.duplicate()
	shuffled.shuffle()
	
	# Show children with accelerating speed
	var total_children = shuffled.size()
	var initial_delay = 0.01  # Start slow
	var final_delay = 0.001   # End at 1ms
	var nChildrenToMax: int = 75
	
	var next_show_time = Time.get_ticks_usec()
	var i = 0
	
	while i < total_children:
		var current_time = Time.get_ticks_usec()
		
		# Show all nodes that should be visible by now
		while i < total_children and current_time >= next_show_time:
			shuffled[i].visible = true
			
			# Calculate delay for next node
			var delay_ms: float
			if i >= nChildrenToMax:
				delay_ms = 1.0  # 1ms between nodes
			else:
				var progress = float(i) / float(nChildrenToMax)
				# Exponential easing for acceleration
				delay_ms = lerp(initial_delay, final_delay, progress * progress) * 1000.0
			
			next_show_time += int(delay_ms * 1000.0)  # Add delay in microseconds
			i += 1
		
		# Wait for next frame only if we're not behind schedule
		if i < total_children:
			await get_tree().process_frame
	
	# Small pause when all are visible (200ms)
	var pause_end_time = Time.get_ticks_usec() + 200000  # 200ms in microseconds
	while Time.get_ticks_usec() < pause_end_time:
		await get_tree().process_frame

	# Wait for a short moment
	await get_tree().create_timer(0.5).timeout

func disable_transition():
	# Move Transition node up smoothly for 0.5 seconds
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	var start_pos = transition.position
	tween.tween_property(transition, "position", start_pos + Vector2(0, -300), 0.35)
	await tween.finished
	
	# Move all transition elements out of screen fast
	var exit_tween = create_tween()
	exit_tween.set_parallel(true)
	exit_tween.set_ease(Tween.EASE_IN)
	exit_tween.set_trans(Tween.TRANS_BACK)
	exit_tween.tween_property(transition, "position", start_pos + Vector2(0, 2300), 0.4)
	await exit_tween.finished
	
	# Reset position and hide all transition elements
	transition.position = start_pos

	var tr_nodes = transition.get_children()
	for child in tr_nodes:
		child.visible = false	