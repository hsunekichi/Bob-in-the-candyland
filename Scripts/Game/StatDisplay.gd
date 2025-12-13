extends Control

@onready var display: HBoxContainer = $HBoxContainer  
@export var statIcon: PackedScene

# --- Sugar Rush: feedback ---
@export var no_charges_icon_scene: PackedScene
@export var no_charges_sfx_player_path: NodePath
@export var no_charges_lock_time: float = 0.35

var _no_charges_playing: bool = false
@onready var _no_charges_sfx: AudioStreamPlayer = _resolve_no_charges_sfx()

func red_animation(target) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Red flash
	tween.tween_property(target, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	# Scale up
	tween.tween_property(target, "scale", Vector2(1.3, 1.3), 0.1)
	# Rotation twitch
	tween.tween_property(target, "rotation", -0.15, 0.05).set_trans(Tween.TRANS_BOUNCE)
	
	tween.chain()
	# Twitch back
	tween.tween_property(target, "rotation", 0.1, 0.05)
	
	tween.chain()
	tween.set_parallel(true)
	# Return to normal
	tween.tween_property(target, "modulate", Color.WHITE, 0.2)
	tween.tween_property(target, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(target, "rotation", 0.0, 0.1)


func pop_in_animation(target) -> void:
	# Pop-in animation (fade in + bounce + rotation)
	target.modulate.a = 0.0
	target.position.y = -10
	target.scale = Vector2(1.3, 1.3)
	target.rotation = -0.15
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, 0.15)
	#tween.tween_property(target, "position:y", 0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#tween.tween_property(target, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	#tween.tween_property(target, "rotation", 0.0, 0.2)


func update_value(new_value: int) -> void:
	var current_value := display.get_child_count()

	if current_value > new_value:
		red_animation(display)

	# Remove excess lives
	while current_value > new_value:
		var child = display.get_child(current_value - 1)
		display.remove_child(child)
		child.queue_free()
		current_value -= 1

	# Add missing lives
	while current_value < new_value:
		var instance = statIcon.instantiate()
		display.add_child(instance)
		pop_in_animation(instance)
		current_value += 1

func _resolve_no_charges_sfx() -> AudioStreamPlayer:
	# 1) Si asignas un NodePath en el inspector, usamos ese
	if no_charges_sfx_player_path != NodePath():
		var n = get_node_or_null(no_charges_sfx_player_path)
		if n is AudioStreamPlayer:
			return n

	# 2) Alternativa: un AudioStreamPlayer hijo llamado "NoChargesSfx"
	var n2 = get_node_or_null("NoChargesSfx")
	if n2 is AudioStreamPlayer:
		return n2

	return null

func _play_no_charges_sfx() -> void:
	if _no_charges_sfx:
		_no_charges_sfx.play()

func no_charges_feedback() -> void:
	# Llamar cuando el jugador intenta usar Sugar Rush sin recargas
	if _no_charges_playing:
		return
	_no_charges_playing = true

	_play_no_charges_sfx()

	# Usa icono alternativo si lo asignas; si no, reutiliza statIcon (donut)
	var scene := no_charges_icon_scene if no_charges_icon_scene else statIcon
	if scene == null:
		# Fallback: si no hay icono, al menos flasheamos el display en rojo
		red_animation(display)
		await get_tree().create_timer(no_charges_lock_time, true, false, true).timeout
		_no_charges_playing = false
		return

	var icon = scene.instantiate()
	display.add_child(icon)

	# Arranca invisible
	if icon is CanvasItem:
		icon.modulate.a = 0.0

	# Espera un frame para que el Container lo acomode antes de animar
	await get_tree().process_frame

	if icon is CanvasItem:
		icon.modulate.a = 1.0
		red_animation(icon)

		# Desaparecer y limpiar
		var tween = create_tween()
		tween.tween_interval(0.18)
		tween.tween_property(icon, "modulate:a", 0.0, 0.22)
		await tween.finished
	else:
		await get_tree().create_timer(0.4, true, false, true).timeout

	if is_instance_valid(icon):
		icon.queue_free()

	await get_tree().create_timer(no_charges_lock_time, true, false, true).timeout
	_no_charges_playing = false
