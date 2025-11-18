extends CharacterBody2D

@onready var animator: AnimationPlayer = $AnimationPlayer
var navigation: ActorNavigation
var FLY_SPEED: float = 3 * World.ppu

func _ready() -> void:
	animator.play("Fly")
	navigation = RTTstarNavigationGD.new()
	add_child(navigation)

func _physics_process(_delta: float) -> void:
	navigation.travel_to(Player.global_position)


func stop() -> void:
	velocity = Vector2.ZERO

func move_to(target: Vector2) -> void:
	var direction: Vector2 = (target - global_position).normalized()
	velocity = direction * FLY_SPEED
