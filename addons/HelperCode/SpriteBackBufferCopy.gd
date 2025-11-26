@tool
class_name SpriteBackBufferCopy
extends BackBufferCopy

@export var target_sprite: Sprite2D = null
const pixel_padding: float = 0.1 ## Padding percentage around the sprite to avoid edge artifacts

func _ready() -> void:	
	enable()
func enable():
	if target_sprite:
		visible = true
		copy_mode = COPY_MODE_RECT
		set_process(true)
func disable():
	visible = false
	copy_mode = COPY_MODE_DISABLED
	set_process(false)

func _process(delta: float) -> void:
	if target_sprite:
		var l_rect := target_sprite.get_rect()
		var g_pos := target_sprite.to_global(l_rect.position)
		var g_size := target_sprite.global_scale * l_rect.size

		var tr_screen = get_viewport_transform()
		rect = (tr_screen * Rect2(g_pos, g_size)).grow(maxf(g_size.x, g_size.y) * pixel_padding)
