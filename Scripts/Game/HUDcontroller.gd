class_name HUDcontroller
extends CanvasLayer

@onready var transition: Node = $Transition
@onready var health_display: Node = $HealthDisplay/HBoxContainer
@onready var sugar_display: Node = $SugarDisplay/HBoxContainer
@onready var pause_menu: Control = $PauseMenu
@onready var hungry_display: Node = $HungryDisplay/HungryTexture
@onready var on_game: bool = false

func _ready() -> void:
	var tr_nodes = transition.get_children()
	for child in tr_nodes:
		child.visible = false
	transition.visible = true
	World.game_finished.connect(on_game_ended)

	health_display.visible = false
	sugar_display.visible = false
	pause_menu.visible = false
	hungry_display.visible = false

	_on_viewport_size_changed()
	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)


	$SugarRushEffect.total_duration = World.config_value("sugar_rush_duration", 2.0)
	$EatSugarEffect.total_duration = 1.0
	$HealthDisplay.visible = false

	World.config_changed.connect(config_changed)
	World.sugar_rush_failed_no_charges.connect(_on_sugar_rush_failed_no_charges)

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
	await get_tree().create_timer(0.5, true, false, true).timeout

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
	on_game = true
	$HealthDisplay.update_value(new_health)
	

func update_sugar_level(new_value: int) -> void:
	$SugarDisplay.update_value(new_value)

func show_hud() -> void:
	health_display.visible = true
	sugar_display.visible = true
	$HealthDisplay.visible = true

func on_game_ended() -> void:
	on_game = false
	health_display.visible = false
	sugar_display.visible = false
	$HealthDisplay.visible = false
	
func open_pause() -> void:
	pause_menu.visible = true
	get_tree().paused = true

func close_pause() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel") and on_game == true:
		if get_tree().paused:
			close_pause()
		else:
			open_pause()

func _on_ResumeButton_pressed():
	close_pause()
	$PauseMenu/AudioStreamPlayer2.play()

func _on_RestartButton_pressed() -> void:
	close_pause()
	World.game_finished.emit()
	await get_tree().process_frame
	World.load_maze()
	$PauseMenu/AudioStreamPlayer2.play()

func _on_HomeButton_pressed() -> void:
	close_pause()
	await get_tree().process_frame
	World.game_finished.emit()
	World.load_menu()
	$PauseMenu/AudioStreamPlayer2.play()
	
func _on_mycontrol_mouse_entered():
	$PauseMenu/AudioStreamPlayer.play()

func _on_viewport_size_changed() -> void:
	transition.rescale_all(transition.get_viewport_rect().size / Vector2(1920, 1080))


func _on_sugar_rush_failed_no_charges() -> void:
	if $SugarDisplay and $SugarDisplay.has_method("no_charges_feedback"):
		$SugarDisplay.no_charges_feedback()
