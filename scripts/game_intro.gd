extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$cutscene_ui/AnimationPlayer.play("fade")
	$AnimationPlayer.play("cutscene")
	await get_tree().create_timer(11.0, false).timeout  # Wait for cutscene
	$cutscene_camera.current = false
