extends Area2D

@export var sugar_amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Player.increase_sugar(sugar_amount)
		World.donut_collected()
		queue_free()
