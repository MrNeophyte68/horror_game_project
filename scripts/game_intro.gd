extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$cutscene_ui/AnimationPlayer.play("fade")
	#$AnimationPlayer.play("cutscene")
	#await get_tree().create_timer(5.0, false).timeout  # Wait for cutscene
	#$cutscene_ui/AnimationPlayer.play_backwards("fade")
	#await get_tree().create_timer(6.0, false).timeout
	#$cutscene_ui/AnimationPlayer.play("fade")
	#$AnimationPlayer.play("cutscene1")
	#await get_tree().create_timer(15.0, false).timeout
	$cutscene_camera.current = false
