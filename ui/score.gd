extends CanvasLayer

@onready var score: Label = $Score

func update_score(new_score: int):
	score.text = "$%d" % new_score
