extends TextureProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate.a = 0.0

	#await get_tree().create_timer(11.0, false).timeout

	# Create a tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 2.0) # fade over 2 seconds
