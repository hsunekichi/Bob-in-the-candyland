extends Node2D

func _ready() -> void:
    World.teleport_player(global_position)