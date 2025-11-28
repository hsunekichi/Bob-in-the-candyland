class_name HUDcontroller
extends CanvasLayer

@onready var transition: Node = $Transition
@onready var health_display: Node = $HealthDisplay
@onready var sugar_display: Node = $SugarDisplay
@onready var pause_menu: Control = $PauseMenu

func _ready() -> void:
	var tr_nodes = transition.get_children()
	for child in tr_nodes:
		child.visible = false
	transition.visible = true
	World.game_finished.connect(on_game_ended)

	health_display.visible = false
	sugar_display.visible = false
	pause_menu.visible = false

	$SugarRushEffect.total_duration = World.config_value("sugar_rush_duration", 2.0)
	$EatSugarEffect.total_duration = 1.0

	World.config_changed.connect(config_changed)

func config_changed() -> void:
	$SugarRushEffect.total_duration = World.config_value("sugar_rush_duration", 2.0)

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

func update_health(new_health: int) -> void:
	var lives_container := $HealthDisplay/HBoxContainer
	var lives := lives_container.get_children()

	for i in range(lives.size()):
		lives[i].visible = i < new_health

func update_sugar_level(new_value: int) -> void:
	var sugar_container := $SugarDisplay/HBoxContainer
	var sugar := sugar_container.get_children()

	for i in range(sugar.size()):
		sugar[i].visible = i < new_value

func show_hud() -> void:
	health_display.visible = true
	sugar_display.visible = true

func on_game_ended() -> void:
	health_display.visible = false
	sugar_display.visible = false
	
func open_pause() -> void:
	pause_menu.visible = true
	get_tree().paused = true

func close_pause() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			close_pause()
		else:
			open_pause()


func _on_ResumeButton_pressed():
	close_pause()

func _on_RestartButton_pressed() -> void:
	close_pause()
	await get_tree().process_frame
	World.load_maze()

func _on_HomeButton_pressed() -> void:
	close_pause()
	await get_tree().process_frame
	World.load_menu()
