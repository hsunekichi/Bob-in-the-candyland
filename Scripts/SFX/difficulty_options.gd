extends OptionButton

func _ready():
	var diff = World.get_difficulty()

	match diff:
		"easy":
			select(0)
		"medium":
			select(1)
		"hard":
			select(2)

	item_selected.connect(_on_difficulty_selected)


func _on_difficulty_selected(index: int) -> void:
	match index:
		0:
			World.set_difficulty("easy")
		1:
			World.set_difficulty("medium")
		2:
			World.set_difficulty("hard")
