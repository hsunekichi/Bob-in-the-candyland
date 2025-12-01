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