class_name HUDcontroller
extends CanvasLayer


@export var win_screen_path: StringName = "res://Art/Screens/WinScreen.png"
var win_node: TextureRect

@onready var transition: Node = $Transition

func _ready() -> void:
    # Build win screen
	var win_screen = Image.new()
	var err = win_screen.load(win_screen_path)
	assert(err == OK)
	win_node = TextureRect.new()
	win_node.texture = ImageTexture.create_from_image(win_screen)
	win_node.visible = false
	add_child(win_node)

	var tr_nodes = transition.get_children()
	for child in tr_nodes:
		child.visible = false
	transition.visible = true


func show_win_screen() -> void:
	await play_transition(win_node)

## Plays a transition animation showing random children from Transition node,
## then displays the target screen, then hides the transition elements
func play_transition(target_screen: Node) -> void:
	var tr_nodes = transition.get_children()
	if tr_nodes.is_empty():
		if target_screen:
			target_screen.visible = true
		return

	await enable_deserts(tr_nodes)

	# Wait for a short moment
	await get_tree().create_timer(0.5).timeout

	# Show the target screen
	if target_screen:
		target_screen.visible = true
	
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
	for child in tr_nodes:
		child.visible = false

func enable_deserts(tr_nodes: Array) -> void:	
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